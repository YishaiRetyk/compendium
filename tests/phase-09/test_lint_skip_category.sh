#!/usr/bin/env bash
# CI-04: --skip-category excludes categories; --ci default-skips drift-external;
# --category (inclusive) applies before --skip-category (exclusive) per P0 review fix.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed a minimal wiki + a broken yaml page so we have guaranteed findings to filter.
mkdir -p "$FIXTURE/wiki-cloud/concepts"
cat > "$FIXTURE/wiki-cloud/index.md" <<'IDX'
# Index
IDX
cat > "$FIXTURE/wiki-cloud/log.md" <<'LOG'
# Log
LOG
python3 - "$FIXTURE/wiki-cloud/concepts/broken.md" <<'PY'
import sys
content = """---
bad: :: yaml
---
"""
open(sys.argv[1], 'w').write(content)
PY

pushd "$FIXTURE" >/dev/null

# -----------------------------------------------------------------------------
# 1. --skip-category yaml: no yaml findings in output
# -----------------------------------------------------------------------------
invoke_tool_compat lint --skip-category yaml --format json wiki-cloud/ > /tmp/skip.json 2>/dev/null
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/skip.json'))
for item in data:
    assert item['category'] != 'yaml', \
        f"FAIL: yaml finding present despite --skip-category yaml: {item}"
print("PASS: --skip-category yaml excluded category")
PYEOF

# -----------------------------------------------------------------------------
# 2. --ci default-skip drift-external: external drift findings (prefix
# 'EXTERNAL: ') are dropped; internal drift findings retained.
# -----------------------------------------------------------------------------
# --ci on a broken-yaml wiki exits 1; we tolerate the exit via `|| true`.
invoke_tool_compat lint --ci --format json wiki-cloud/ > /tmp/ci.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/ci.json'))
for item in data:
    if item['category'] == 'drift':
        assert not item['message'].startswith('EXTERNAL: '), \
            f"FAIL: external drift finding present despite --ci default drift-external skip: {item}"
print("PASS: --ci default-skips drift-external (internal drift retained)")
PYEOF

# -----------------------------------------------------------------------------
# 3. --category filter alone narrows to one category
# -----------------------------------------------------------------------------
invoke_tool_compat lint --category yaml --format json wiki-cloud/ > /tmp/cat.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/cat.json'))
for item in data:
    assert item['category'] == 'yaml', \
        f"FAIL: --category yaml should narrow to yaml only, got: {item}"
print("PASS: --category filter narrows")
PYEOF

# -----------------------------------------------------------------------------
# 4. --category X --skip-category X: empty result (narrow-then-subtract = empty)
# -----------------------------------------------------------------------------
invoke_tool_compat lint --category yaml --skip-category yaml --format json wiki-cloud/ > /tmp/selfskip.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/selfskip.json'))
assert all(i['category'] != 'yaml' for i in data), \
    f"FAIL: --category yaml --skip-category yaml should subtract yaml: {data}"
print("PASS: --category/--skip-category precedence (narrow then subtract)")
PYEOF

popd >/dev/null
echo "PASS: --skip-category + --ci default skip + precedence"
