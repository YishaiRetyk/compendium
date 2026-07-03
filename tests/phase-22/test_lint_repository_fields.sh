#!/usr/bin/env bash
# REPO-05: lint accepts source_type: repository (D-09 enum) and conditionally
# requires repo_url + commit_sha + default_branch; malformed commit_sha errors;
# unknown source_type still rejected (enum regression). Neutral fixtures.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

TMP="$(mktemp -d -t phase22-lint-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
WIKI="$TMP/wiki"
mkdir -p "$WIKI/sources"
printf '# Index\n' > "$WIKI/index.md"
printf '# Log\n' > "$WIKI/log.md"

src_page() {
    # $1 = id; $2 = source_type; $3 = extra frontmatter lines (may be empty)
    cat <<EOF
---
id: $1
title: "Source $1"
type: source
status: active
summary: "Repository lint fixture."
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
path: sources/2026/2026-07/2026-07-03-$1/source.md
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

FULL_SHA="0123456789abcdef0123456789abcdef01234567"

src_page src-repo-valid repository "repo_url: \"https://github.com/<owner>/<repo>\"
commit_sha: \"$FULL_SHA\"
default_branch: main" > "$WIKI/sources/src-repo-valid.md"

src_page src-repo-missing repository "" > "$WIKI/sources/src-repo-missing.md"

src_page src-repo-badsha repository "repo_url: \"https://github.com/<owner>/<repo>\"
commit_sha: \"abc123\"
default_branch: main" > "$WIKI/sources/src-repo-badsha.md"

src_page src-bogus floppy "" > "$WIKI/sources/src-bogus.md"

invoke_tool_compat lint --category yaml --format json "$WIKI" \
    > "$TMP/out.json" 2>/dev/null || true

python3 - "$TMP/out.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
yaml_errs = [d for d in data if d['category'] == 'yaml' and d['severity'] == 'error']

def errs_for(stem):
    return [d for d in yaml_errs if d['path'].endswith(stem + '.md')]

# T1: valid repository source -> ZERO yaml errors (enum accepts + fields satisfied)
v = errs_for('src-repo-valid')
assert not v, f"FAIL T1: valid repository source should have 0 yaml errors, got {[d['message'] for d in v]}"
print("PASS T1: valid repository source passes (enum + required fields)")

# T2: missing repo fields -> error naming all three
m = [d for d in errs_for('src-repo-missing') if 'missing required fields' in d['message']]
assert m and all(f in m[0]['message'] for f in ('repo_url', 'commit_sha', 'default_branch')), (
    f"FAIL T2: expected missing-required-fields error naming all three, got "
    f"{[d['message'] for d in errs_for('src-repo-missing')]}"
)
print("PASS T2: repository source missing repo_url/commit_sha/default_branch errors")

# T3: malformed commit_sha -> 40-hex error
b = [d for d in errs_for('src-repo-badsha') if '40-hex' in d['message']]
assert b, f"FAIL T3: expected 40-hex commit_sha error, got {[d['message'] for d in errs_for('src-repo-badsha')]}"
print("PASS T3: short/malformed commit_sha errors (full 40-hex required)")

# T4: unknown source_type still rejected (enum regression) and lists repository as valid
g = [d for d in errs_for('src-bogus') if 'Invalid source_type' in d['message']]
assert g, f"FAIL T4: bogus source_type must still error, got {[d['message'] for d in errs_for('src-bogus')]}"
assert 'repository' in g[0]['message'], (
    f"FAIL T4: enum error message should list 'repository' among valid values, got {g[0]['message']}"
)
print("PASS T4: unknown source_type rejected; enum message includes repository")
PYEOF

echo "PASS: test_lint_repository_fields -- all 4 cases passed"
