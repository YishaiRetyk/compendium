#!/usr/bin/env bash
# CI-02: --format json emits JSON array to stdout; no lint-report.md write;
# `line` key is OMITTED (not null) when the underlying finding lacks line info.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed a minimal wiki so the fixture has at least an index.md / source page set;
# the ci-lint-json fixture template ships as an empty wiki dir, and 09-01's
# delta to populate it may arrive independently. We provide minimal content
# here so --format json exercises the emit branch even if the fixture is bare.
mkdir -p "$FIXTURE/wiki"
cat > "$FIXTURE/wiki-cloud/index.md" <<'IDX'
# Index

## Concepts

IDX
cat > "$FIXTURE/wiki-cloud/log.md" <<'LOG'
# Activity Log
LOG

pushd "$FIXTURE" >/dev/null

# Ensure no stale report before the run
[ -f wiki-cloud/maintenance/lint-report.md ] && rm wiki-cloud/maintenance/lint-report.md

OUT="$(bash "$REPO_ROOT/bin/lint.sh" --format json wiki-cloud/ 2>/dev/null)"

# Write output to a temp file so python can read it cleanly (avoids shell-quoting hell)
JSON_TMP="$(mktemp)"
printf '%s' "$OUT" > "$JSON_TMP"

# Validate JSON parse + shape
python3 - "$JSON_TMP" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
assert isinstance(data, list), f"expected list, got {type(data)}"
allowed_keys = {'severity', 'category', 'path', 'message', 'line'}
required_keys = {'severity', 'category', 'path', 'message'}
for item in data:
    keys = set(item.keys())
    extra = keys - allowed_keys
    assert not extra, f"unexpected keys in {item}: {extra}"
    missing = required_keys - keys
    assert not missing, f"missing required keys in {item}: {missing}"
    assert item['severity'] in ('error', 'warning', 'info'), f"bad severity: {item['severity']}"
    # P0 review fix: `line` is OMITTED when unknown, NOT present as null.
    if 'line' in item:
        assert isinstance(item['line'], int) and item['line'] >= 1, \
            f"line must be integer 1-indexed when present, got: {item['line']!r}"
print("PASS: JSON shape valid (line omitted when unknown, not null)")
PYEOF

# D-03: no lint-report.md written in JSON mode
if [ -f wiki-cloud/maintenance/lint-report.md ]; then
    echo "FAIL: --format json must not write lint-report.md (D-03)" >&2
    popd >/dev/null
    exit 1
fi

rm -f "$JSON_TMP"
popd >/dev/null
echo "PASS: --format json"
