#!/usr/bin/env bash
# REPO-02: bin/audit-claims.sh resolves #path: against the ## Excerpts registry
# and #commit: against ## Snapshot Metadata; missing excerpt / foreign sha ->
# insufficient-locator; D-11 dispatch order (#path: before #p) regression-guarded
# (a mis-dispatched #path: would fall into the page-range branch and NOT resolve,
# so the positive resolution below IS the order guard). Neutral fixtures.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../phase-13/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

FULL_SHA="0123456789abcdef0123456789abcdef01234567"

write_page "$REPO" "wiki-cloud/sources/src-repo.md" <<EOF
---
id: src-repo
title: "Repo Fixture"
type: source
status: active
path: sources/2026/2026-07/repo/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-07-03
source_type: repository
repo_url: "https://github.com/<owner>/<repo>"
commit_sha: "$FULL_SHA"
default_branch: main
---
EOF

write_page "$REPO" "sources/2026/2026-07/repo/source.md" <<EOF
# repo snapshot

## Snapshot Metadata

- Repository: https://github.com/<owner>/<repo>
- Commit: $FULL_SHA
- UNIQUE_METADATA_MARKER

## README

Readme prose here.

## Excerpts

### src/alpha.py:L10-L14

\`\`\`python
UNIQUE_EXCERPT_MARKER = True
\`\`\`

### docs/whole-file.md

\`\`\`markdown
UNIQUE_WHOLEFILE_MARKER
\`\`\`
EOF

write_page "$REPO" "wiki-cloud/concepts/repo-claims.md" <<'EOF'
---
id: repo-claims
title: "Repo Claims"
type: concept
status: active
---
Range claim [prov:src-repo#path:src/alpha.py:L11-L12|direct|2026-07-03]
Whole-file claim [prov:src-repo#path:docs/whole-file.md|direct|2026-07-03]
Commit claim [prov:src-repo#commit:0123456|direct|2026-07-03]
Missing excerpt [prov:src-repo#path:src/ghost.py:L1-L2|direct|2026-07-03]
Foreign sha [prov:src-repo#commit:deadbee|direct|2026-07-03]
Out-of-range [prov:src-repo#path:src/alpha.py:L90-L99|direct|2026-07-03]
EOF

set +e
wl="$(cd "$REPO" && bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "worklist run" || { echo "$wl" >&2; exit 1; }

# T1 (+D-11): contained range resolves to the excerpt passage
printf '%s' "$wl" | grep -q 'UNIQUE_EXCERPT_MARKER' || {
    echo "FAIL T1: #path:src/alpha.py:L11-L12 did not resolve to the excerpt (D-11 dispatch-order?)" >&2
    echo "$wl" >&2; exit 1; }
echo "PASS T1: contained #path range resolves against the Excerpts registry (D-11 order holds)"

# T2: whole-file excerpt heading matches a path-only request
printf '%s' "$wl" | grep -q 'UNIQUE_WHOLEFILE_MARKER' || {
    echo "FAIL T2: #path:docs/whole-file.md did not resolve to the whole-file excerpt" >&2
    echo "$wl" >&2; exit 1; }
echo "PASS T2: whole-file excerpt heading resolves a path-only request"

# T3: #commit: with a matching sha prefix resolves to the metadata section
printf '%s' "$wl" | grep -q 'UNIQUE_METADATA_MARKER' || {
    echo "FAIL T3: #commit:0123456 did not resolve to the Snapshot Metadata section" >&2
    echo "$wl" >&2; exit 1; }
echo "PASS T3: #commit prefix-match resolves to Snapshot Metadata"

# The worklist run above advanced the audit checkpoint (D-15), which would
# suppress selection on the next run — reset the control-plane for a fresh run.
rm -rf "$REPO/wiki-local/maintenance"

set +e
findings="$(cd "$REPO" && bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "findings run" || { echo "$findings" >&2; exit 1; }

python3 - <<PYEOF
import json
data = json.loads('''$(printf '%s' "$findings" | sed "s/'''/---/g")''')
items = data if isinstance(data, list) else data.get('findings', [])
def insufficient(tok):
    return any(tok in json.dumps(f) and ('insufficient' in json.dumps(f)) for f in items)
assert insufficient('src/ghost.py'), "FAIL T4: missing excerpt should be insufficient-locator"
print("PASS T4: #path with no matching excerpt degrades to insufficient-locator")
assert insufficient('deadbee'), "FAIL T5: foreign sha should be insufficient-locator"
print("PASS T5: #commit with a non-snapshot sha degrades to insufficient-locator")
assert insufficient('L90-L99'), "FAIL T6: out-of-range #path should be insufficient-locator"
print("PASS T6: #path range outside the excerpt's declared range degrades honestly")
PYEOF

echo "PASS: test_audit_path_resolver -- all 6 cases passed"
