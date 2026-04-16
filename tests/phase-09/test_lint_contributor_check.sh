#!/usr/bin/env bash
# COLAB-08 / D-22: contributor category warns on @handle without matching
# .git-author-map.txt entry or git-log author. Single-author repo short-circuits.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Multi-author fixture
FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Add alice commit + bob commit
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

# Seed wiki/log.md with contributor:: @bob (who is NOT in the map — only alice is mapped)
mkdir -p wiki wiki/decisions
cat > wiki/log.md <<'LOG'
# Log

## [2026-04-16] ingest | test

contributor:: @bob

Some rationale.
LOG

# Seed a minimal wiki/index.md so lint has structure
echo "# Index" > wiki/index.md

git add . && git -c commit.gpgsign=false commit -q -m "seed log"

LINT_REPO_ROOT="$FIXTURE" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb.json 2>/dev/null || true
# Expect at least one contributor warning for @bob (no mapping)
if ! assert_json_has_finding /tmp/ctrb.json contributor warning; then
    echo "FAIL: expected contributor warning for @bob" >&2
    cat /tmp/ctrb.json >&2
    popd >/dev/null; exit 1
fi

# Add @bob to map → re-lint, no contributor findings
echo "bob@example.com  ->  @bob" >> .git-author-map.txt
git add . && git -c commit.gpgsign=false commit -q -m "map bob"

LINT_REPO_ROOT="$FIXTURE" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb2.json 2>/dev/null || true
python3 - <<'PYEOF'
import json, sys
data = json.load(open('/tmp/ctrb2.json'))
for item in data:
    if item.get('category') == 'contributor':
        print(f"FAIL: unexpected contributor finding after map fix: {item}", file=sys.stderr)
        sys.exit(1)
print("PASS: @bob mapped; no contributor warnings")
PYEOF

popd >/dev/null
cleanup_fixture_repo "$FIXTURE"
trap - EXIT

# Single-author fixture → no contributor warnings even with a @handle in log
FIXTURE2="$(make_fixture_repo contributor-single)"
trap 'cleanup_fixture_repo "$FIXTURE2"' EXIT
pushd "$FIXTURE2" >/dev/null
mkdir -p wiki wiki/decisions
echo "# Index" > wiki/index.md
cat > wiki/log.md <<'LOG'
# Log

## [2026-04-16] ingest | test

contributor:: @anyone

Body.
LOG
git add . && git -c commit.gpgsign=false commit -q -m "seed single-author log"

LINT_REPO_ROOT="$FIXTURE2" bash "$REPO_ROOT/bin/lint.sh" --category contributor --format json wiki/ > /tmp/ctrb3.json 2>/dev/null || true
python3 - <<'PYEOF'
import json, sys
data = json.load(open('/tmp/ctrb3.json'))
for item in data:
    if item.get('category') == 'contributor':
        print(f"FAIL: single-author should short-circuit, got: {item}", file=sys.stderr)
        sys.exit(1)
print("PASS: single-author short-circuit honored (D-20)")
PYEOF

popd >/dev/null
echo "PASS: contributor category check (mismatch warns, map fix clears, single-author short-circuits)"
