#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_end_to_end_happy_path.sh — BRWN-17 + BRWN-22:
# full suggest -> review-typing -> 01 --apply -> 02 --apply -> 03 (advisory)
# -> 04 (advisory) -> verify -> verify --promote chain succeeds; applied.log
# accumulates the expected per-script blocks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

# 1. suggest
if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# 2. review-typing (approve-all via scripted stdin)
approve_input=""
for _ in $(seq 1 20); do approve_input+="a"$'\n'; done
if ! echo -n "$approve_input" | invoke_tool_compat brownfield review-typing --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh review-typing not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

# 3. 01 --apply
if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 01 --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# 4. 02 --apply
if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02 --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# 5. 03 (advisory)
if ! bash "$TMP/.brownfield/migrations/03-cross-link-inference.sh" >/dev/null 2>&1; then
    echo "FAIL: 03 advisory not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# 6. 04 (advisory)
if ! bash "$TMP/.brownfield/migrations/04-privacy-review.sh" >/dev/null 2>&1; then
    echo "FAIL: 04 advisory not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# 7. verify (read-only)
if ! invoke_tool_compat brownfield verify --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: verify not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

# 8. verify --promote
if ! invoke_tool_compat brownfield verify --promote --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: verify --promote not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

# applied.log should have at least 4 blocks (01 apply + 02 apply + 03 advisory + 04 advisory).
LOG="$TMP/.brownfield/applied.log"
assert_file_exists "$LOG"
blocks=$(grep -cE '^## 0[1234]-' "$LOG" || true)
if [ "$blocks" -lt "4" ]; then
    echo "FAIL: applied.log contains $blocks 01/02/03/04 blocks (expected ≥4)" >&2
    cat "$LOG" >&2
    exit 1
fi

# If an end-to-end-golden fixture exists, byte-compare the final vault
# against it.  Plan 11-04 populates this directory; its absence is a
# legitimate Wave-0 state, so skip the byte-equality path here.
if [ -d "$REPO_ROOT/tests/phase-11/fixtures/end-to-end-golden" ]; then
    diff -rq \
        "$TMP/wiki/" \
        "$REPO_ROOT/tests/phase-11/fixtures/end-to-end-golden/expected/wiki/" \
        || {
            echo "FAIL: end-to-end final state does not match golden" >&2
            exit 1
        }
fi

echo "PASS $NAME"; exit 0
