#!/usr/bin/env bash
# DRIFT-01..03: --network external drift checks — NETWORK-FREE test.
# git ls-remote runs against local file:// fixture repos (real code path,
# no internet); curl is a PATH-injected stub with canned per-URL statuses.
# Neutral fixtures. Self-contained temp wiki.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

TMP="$(mktemp -d -t phase23-drift-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# --- curl stub: last arg is the URL; emit "<code> <redirects>" like -w would ---
mkdir -p "$TMP/bin"
cat > "$TMP/bin/curl" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
    *dead-page*)  printf '404 0' ;;
    *gone-page*)  printf '410 0' ;;
    *moved-page*) printf '200 2' ;;
    *rot-a*|*rot-b*) printf '404 0' ;;
    *) printf '200 0' ;;
esac
EOF
chmod +x "$TMP/bin/curl"

# --- fixture upstream repos: one current, one drifted ---
mk_upstream() { # $1=dir
    mkdir -p "$1"
    (cd "$1" && git init -q -b main && git config user.email t@t && git config user.name t \
        && echo hi > f.txt && git add -A && git -c commit.gpgsign=false commit -q -m x)
    git -C "$1" rev-parse HEAD
}
CUR_SHA="$(mk_upstream "$TMP/up-current")"
DRIFT_SHA_OLD="$(mk_upstream "$TMP/up-drifted")"
(cd "$TMP/up-drifted" && echo more >> f.txt && git add -A && git -c commit.gpgsign=false commit -q -m y)

# --- fixture wiki ---
WIKI="$TMP/wiki"
mkdir -p "$WIKI/sources"
printf '# Index\n' > "$WIKI/index.md"
printf '# Log\n' > "$WIKI/log.md"

src_page() { # $1=id $2=source_type $3=extra-fm
    cat <<EOF
---
id: $1
title: "Source $1"
type: source
status: active
summary: "Drift fixture."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: software
path: sources/2026/2026-07/$1/source.md
content_hash: "sha256:abc"
ingested_at: 2026-07-03
source_type: $2
compilation_status: compiled
compiled_against_hash: "sha256:abc"
compiled_targets: []
$3
---
# Source $1
## TL;DR
Fixture.
EOF
}

src_page src-repo-current repository "repo_url: \"file://$TMP/up-current\"
commit_sha: \"$CUR_SHA\"
default_branch: main" > "$WIKI/sources/src-repo-current.md"

src_page src-repo-drifted repository "repo_url: \"file://$TMP/up-drifted\"
commit_sha: \"$DRIFT_SHA_OLD\"
default_branch: main" > "$WIKI/sources/src-repo-drifted.md"

src_page src-repo-gone repository "repo_url: \"file://$TMP/nonexistent-upstream\"
commit_sha: \"$CUR_SHA\"
default_branch: main" > "$WIKI/sources/src-repo-gone.md"

src_page src-dead-article article "url: \"https://example.invalid/dead-page\"" \
    > "$WIKI/sources/src-dead-article.md"
src_page src-moved-article article "url: \"https://example.invalid/moved-page\"" \
    > "$WIKI/sources/src-moved-article.md"
src_page src-ok-article article "url: \"https://example.invalid/fine-page\"" \
    > "$WIKI/sources/src-ok-article.md"

# video sub-case (transcript + channel): url dead but MUST be excluded (D-04/D-06)
src_page src-video transcript "url: \"https://example.invalid/dead-page\"
channel: \"<channel-name>\"
publish_date: 2026-07-01
duration: \"~10 min\"" > "$WIKI/sources/src-video.md"

# research-report with a registry: 2 of 4 sampled URLs dead -> warning (>=50%)
{
    src_page src-report research-report ""
    cat <<'EOF'

## References

- r1:: [A](https://example.invalid/rot-a) — accessed 2026-07-01 — status: registry
- r2:: [B](https://example.invalid/rot-b) — accessed 2026-07-01 — status: registry
- r3:: [C](https://example.invalid/fine-1) — accessed 2026-07-01 — status: registry
- r4:: [D](https://example.invalid/fine-2) — accessed 2026-07-01 — status: registry
EOF
} > "$WIKI/sources/src-report.md"

run_lint() { # $1=extra flags -> writes JSON to $2
    # shellcheck disable=SC2086
    PATH="$TMP/bin:$PATH" invoke_tool_compat lint --dry-run --category drift \
        --format json $1 "$WIKI" > "$2" 2>/dev/null || true
}

run_lint ""          "$TMP/no-network.json"
run_lint "--network" "$TMP/network.json"

python3 - "$TMP/no-network.json" "$TMP/network.json" <<'PYEOF'
import json, sys
no_net = json.load(open(sys.argv[1]))
net = json.load(open(sys.argv[2]))

def ext(findings):
    return [f for f in findings if f['message'].startswith('EXTERNAL: ') and (
        'repository' in f['message'] or 'source url' in f['message'] or 'link-rot' in f['message'])]

# T1 (DRIFT-01): without --network, ZERO external network findings
assert not ext(no_net), f"FAIL T1: no-flag run must have zero network findings, got {[f['message'] for f in ext(no_net)]}"
print("PASS T1: without --network, no network checks run (no new findings)")

msgs = {f['path'].split('/')[-1]: [] for f in net}
for f in net:
    msgs.setdefault(f['path'].split('/')[-1], []).append((f['severity'], f['message']))

def has(page, sev, token):
    return any(s == sev and token in m for s, m in msgs.get(page, []))

# T2 (DRIFT-02): drifted repo -> warning; current repo -> silence; unreachable -> warning
assert has('src-repo-drifted.md', 'warning', 'upstream drifted'), f"FAIL T2a: {msgs.get('src-repo-drifted.md')}"
assert not any('EXTERNAL' in m for _, m in msgs.get('src-repo-current.md', [])), \
    f"FAIL T2b: current repo must be silent, got {msgs.get('src-repo-current.md')}"
assert has('src-repo-gone.md', 'warning', 'unreachable'), f"FAIL T2c: {msgs.get('src-repo-gone.md')}"
print("PASS T2: repository HEAD drift — drifted=warning, current=silent, unreachable=warning")

# T3 (DRIFT-03): dead url -> warning; moved -> info; fine -> silence
assert has('src-dead-article.md', 'warning', 'unreachable'), f"FAIL T3a: {msgs.get('src-dead-article.md')}"
assert has('src-moved-article.md', 'info', 'moved'), f"FAIL T3b: {msgs.get('src-moved-article.md')}"
assert not any('EXTERNAL' in m for _, m in msgs.get('src-ok-article.md', [])), \
    f"FAIL T3c: reachable url must be silent, got {msgs.get('src-ok-article.md')}"
print("PASS T3: url reachability — dead=warning, moved=info, fine=silent")

# T4 (D-04): video sub-case excluded even with a dead url
assert not any('EXTERNAL' in m for _, m in msgs.get('src-video.md', [])), \
    f"FAIL T4: video source must be excluded, got {msgs.get('src-video.md')}"
print("PASS T4: video sub-case (transcript + channel) excluded per the link-rot stance")

# T5 (DRIFT-03): registry link-rot 2/4 dead -> warning with ratio
assert has('src-report.md', 'warning', 'link-rot 2/4'), f"FAIL T5: {msgs.get('src-report.md')}"
print("PASS T5: citation-registry link-rot ratio (2/4 dead -> warning)")
PYEOF

# T6 (DRIFT-01): --ci still default-skips drift-external even WITH --network
PATH="$TMP/bin:$PATH" invoke_tool_compat lint --dry-run --ci --category drift \
    --format json --network "$WIKI" > "$TMP/ci-network.json" 2>/dev/null || true
python3 - "$TMP/ci-network.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
leaked = [f for f in d if f['message'].startswith('EXTERNAL: ')]
assert not leaked, f"FAIL T6: --ci must default-skip drift-external, got {[f['message'] for f in leaked]}"
print("PASS T6: --ci default-skips drift-external even when --network is passed")
PYEOF

echo "PASS: test_network_drift -- all 6 cases passed"
