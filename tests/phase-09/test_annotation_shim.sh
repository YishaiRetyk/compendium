#!/usr/bin/env bash
# CI-05: JSON -> GitHub annotations shim.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SHIM="$REPO_ROOT/.github/scripts/json-to-annotations.py"
test -x "$SHIM" || { echo "FAIL: shim not executable" >&2; exit 1; }

# 1. Error finding -> ::error
cat > /tmp/ann1.json <<'J'
[{"severity":"error","category":"yaml","path":"wiki-cloud/x.md","line":5,"message":"bad YAML"}]
J
OUT="$(python3 "$SHIM" /tmp/ann1.json)"
echo "$OUT" | grep -q "^::error file=wiki-cloud/x.md" \
    || { echo "FAIL: expected ::error file=wiki-cloud/x.md in: $OUT" >&2; exit 1; }
echo "$OUT" | grep -q "line=5" || { echo "FAIL: expected line=5" >&2; exit 1; }

# 2. Warning -> ::warning
cat > /tmp/ann2.json <<'J'
[{"severity":"warning","category":"stale","path":"wiki-cloud/y.md","message":"stale claim"}]
J
OUT2="$(python3 "$SHIM" /tmp/ann2.json)"
echo "$OUT2" | grep -q "^::warning file=wiki-cloud/y.md" \
    || { echo "FAIL: expected ::warning in: $OUT2" >&2; exit 1; }

# 3. Info -> ::notice (NOT ::info)
cat > /tmp/ann3.json <<'J'
[{"severity":"info","category":"skip-count","path":"wiki-cloud/z.md","message":"exempted"}]
J
OUT3="$(python3 "$SHIM" /tmp/ann3.json)"
echo "$OUT3" | grep -q "^::notice file=wiki-cloud/z.md" \
    || { echo "FAIL: info must map to ::notice, not ::info. Got: $OUT3" >&2; exit 1; }
if echo "$OUT3" | grep -q "^::info"; then
    echo "FAIL: ::info is not a valid GitHub workflow command" >&2; exit 1
fi

# 4. Annotation cap: 15 errors -> 10 ::error lines + 1 trailing ::notice "more"
python3 - <<'PY'
import json
data = [{"severity":"error","category":"yaml","path":f"wiki-cloud/f{i}.md","line":i+1,"message":f"err {i}"} for i in range(15)]
json.dump(data, open("/tmp/ann4.json", "w"))
PY
OUT4="$(python3 "$SHIM" /tmp/ann4.json)"
COUNT_ERR="$(echo "$OUT4" | grep -c '^::error' || true)"
if [ "$COUNT_ERR" -gt 10 ]; then
    echo "FAIL: expected <= 10 ::error lines, got $COUNT_ERR" >&2; exit 1
fi
echo "$OUT4" | grep -q "more" || { echo "FAIL: missing 'N more' trailing notice" >&2; exit 1; }

# 5. Missing file -> exit 1 with clear stderr, not stack trace
if python3 "$SHIM" /tmp/does-not-exist.json 2>/tmp/ann5.err; then
    echo "FAIL: missing input file should exit 1" >&2; exit 1
fi
grep -q "not found" /tmp/ann5.err \
    || { echo "FAIL: stderr missing 'not found': $(cat /tmp/ann5.err)" >&2; exit 1; }
if grep -q "Traceback" /tmp/ann5.err; then
    echo "FAIL: should not emit python Traceback" >&2; exit 1
fi

echo "PASS: annotation shim (error/warning/notice mapping + cap + error handling)"
