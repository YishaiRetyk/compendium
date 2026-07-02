#!/usr/bin/env bash
# REPO-02: bin/audit-claims.sh resolves #path: against the ## Excerpts registry
# and #commit: against the '- Commit:' line of ## Snapshot Metadata; missing
# excerpt / foreign sha / inverted range / whole-file-vs-range -> honest
# insufficient-locator; D-11 dispatch order (#path: before #p) regression-
# guarded (a mis-dispatched #path: would fall into the page-range branch and
# NOT resolve, so the positive resolutions below ARE the order guard).
# Fence-awareness is exercised across ALL resolvers via the shared
# _fence_mask_lines helper (Phase 22 review): nested 4-backtick fences, tilde
# fences, quoted '## '/'### ' headings inside excerpt bodies, and #sec:
# refusing to bind to quoted headings. Neutral fixtures.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../phase-13/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

FULL_SHA="0123456789abcdef0123456789abcdef01234567"
PARENT_SHA="fedcba9876543210fedcba9876543210fedcba98"

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

# Raw snapshot: metadata (incl. a FOREIGN parent sha), README prose section,
# and an Excerpts registry whose bodies quote markdown headings inside fences
# (nested 4-backtick + tilde variants), plus single-line and whole-file entries.
write_page "$REPO" "sources/2026/2026-07/repo/source.md" <<EOF
# repo snapshot

## Snapshot Metadata

- Repository: https://github.com/<owner>/<repo>
- Commit: $FULL_SHA
- Supersedes snapshot at commit $PARENT_SHA
- UNIQUE_METADATA_MARKER

## Real Prose Section

UNIQUE_PROSE_MARKER prose that a #sec: claim can legitimately cite.

## Excerpts

### src/alpha.py:L10-L14

\`\`\`python
UNIQUE_EXCERPT_MARKER = True
\`\`\`

### docs/whole-file.md

\`\`\`markdown
UNIQUE_WHOLEFILE_MARKER
\`\`\`

### docs/guide.md:L5-L9

\`\`\`\`markdown
## Quoted Heading Alpha (must not truncate or match #sec:)
\`\`\`bash
## quoted-inside-nested-fence
\`\`\`
### Nor This Deeper One
\`\`\`\`

### docs/tilde.md:L1-L4

~~~markdown
## Quoted Heading Beta inside a tilde fence
~~~

### docs/one-line.md:L7

\`\`\`markdown
UNIQUE_ONELINE_MARKER
\`\`\`

### docs/after-fenced-heading.md:L1-L3

\`\`\`markdown
UNIQUE_AFTERFENCE_MARKER
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
Whole-file path-only claim [prov:src-repo#path:docs/whole-file.md|direct|2026-07-03]
Commit claim [prov:src-repo#commit:0123456|direct|2026-07-03]
Single-line claim [prov:src-repo#path:docs/one-line.md:L7|direct|2026-07-03]
After-fence claim [prov:src-repo#path:docs/after-fenced-heading.md:L1-L2|direct|2026-07-03]
Real section claim [prov:src-repo#sec:real-prose-section|direct|2026-07-03]
Missing excerpt [prov:src-repo#path:src/ghost.py:L1-L2|direct|2026-07-03]
Foreign sha [prov:src-repo#commit:fedcba9|direct|2026-07-03]
Out-of-range [prov:src-repo#path:src/alpha.py:L90-L99|direct|2026-07-03]
Inverted range [prov:src-repo#path:src/alpha.py:L12-L11|direct|2026-07-03]
Range vs whole-file [prov:src-repo#path:docs/whole-file.md:L500-L510|direct|2026-07-03]
Quoted-heading sec [prov:src-repo#sec:quoted-heading-alpha|direct|2026-07-03]
EOF

set +e
wl="$(cd "$REPO" && bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "worklist run" || { echo "$wl" >&2; exit 1; }
# Write once, grep the file — `printf | grep -q` under pipefail dies of
# SIGPIPE on an early match once output outgrows the pipe buffer.
WL_FILE="$REPO/.worklist.json"
printf '%s' "$wl" > "$WL_FILE"

expect_present() { # $1=marker $2=test-label $3=description
    grep -q "$1" "$WL_FILE" || {
        echo "FAIL $2: $3 (marker $1 absent)" >&2; exit 1; }
    echo "PASS $2: $3"
}
expect_absent() { # $1=marker $2=test-label $3=description
    ! grep -q "$1" "$WL_FILE" || {
        echo "FAIL $2: $3 (marker $1 leaked into a passage)" >&2; exit 1; }
    echo "PASS $2: $3"
}

expect_present UNIQUE_EXCERPT_MARKER  T1 "contained #path range resolves (D-11 dispatch order holds)"
expect_present UNIQUE_WHOLEFILE_MARKER T2 "whole-file excerpt resolves a PATH-ONLY request"
expect_present UNIQUE_METADATA_MARKER T3 "#commit prefix-match against the '- Commit:' line resolves"
expect_present UNIQUE_AFTERFENCE_MARKER T4 "excerpts after nested/tilde fenced-heading excerpts still resolve (registry not truncated)"
expect_present UNIQUE_ONELINE_MARKER  T5 "single-line excerpt heading ':L<n>' is addressable"
expect_present UNIQUE_PROSE_MARKER    T6 "#sec: still resolves real (non-fenced) sections"

# --- Findings run (fresh audit state: the worklist run advanced the D-15 checkpoint) ---
rm -rf "$REPO/wiki-local/maintenance"
set +e
findings="$(cd "$REPO" && bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "findings run" || { echo "$findings" >&2; exit 1; }
FIND_FILE="$REPO/.findings.json"
printf '%s' "$findings" > "$FIND_FILE"

python3 - "$FIND_FILE" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
items = data if isinstance(data, list) else data.get('findings', [])

def verdict_for(loc_token):
    hits = [f for f in items if loc_token in f.get('locator', '')]
    return hits[0].get('verdict') if hits else None

cases = [
    ('src/ghost.py',              'T7',  '#path with no matching excerpt'),
    ('fedcba9',                   'T8',  '#commit with a non-Commit-line sha (foreign/parent sha rejected)'),
    ('L90-L99',                   'T9',  '#path range outside the excerpt declared range'),
    ('L12-L11',                   'T10', 'inverted #path range'),
    ('L500-L510',                 'T11', 'range request against a whole-file excerpt (no declared range to contain it)'),
    ('sec:quoted-heading-alpha',  'T12', '#sec: matching ONLY a heading quoted inside a fenced excerpt'),
]
for token, label, desc in cases:
    v = verdict_for(token)
    assert v == 'insufficient-locator', (
        f"FAIL {label}: {desc} should be insufficient-locator, got verdict={v!r}")
    print(f"PASS {label}: {desc} degrades honestly to insufficient-locator")
PYEOF

echo "PASS: test_audit_path_resolver -- all 12 cases passed"
