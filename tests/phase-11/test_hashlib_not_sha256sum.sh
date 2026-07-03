#!/usr/bin/env bash
# EXPECTED_BY: 11-01
# tests/phase-11/test_hashlib_not_sha256sum.sh — REWRITTEN (Phase 24 Plan 04, TEST-04/D-16).
# WAS: a source-grep over bin/brownfield.sh + schema/brownfield/migrations/*.sh for the
# literal 'sha256sum' — an IMPLEMENTATION assertion that false-fails a correct Python
# port (anti-signal). NOW: an impl-agnostic BEHAVIOR assertion on the CONFIRMED hash
# emission channel — `brownfield suggest` byte-copies each canonical migration script and
# injects `# op_hash: sha256:<64hex>` on line 2 of the copy (.brownfield/migrations/).
# The test computes the expected op_hash with the DOCUMENTED canonicalization (canonical
# body minus `# op_hash:`/`# op_hash_scope:` header lines + the data_schema_version
# trailer) and asserts the EMITTED VALUE matches — true for sha256sum, hashlib, or any
# implementation; a wrong/truncated hash fails.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
NAME="$(basename "${BASH_SOURCE[0]}")"

# The canonical script the oracle's suggest run byte-copies (use the ORACLE's tree so
# the expected value matches the code actually executed).
WT="$(ensure_oracle_worktree)"
CANONICAL="$WT/schema/brownfield/migrations/01-page-typing.sh"
[ -f "$CANONICAL" ] || { echo "FAIL: canonical migration script missing: $CANONICAL" >&2; exit 1; }

# Reference computation of the documented op_hash contract (the test's own reference —
# independent of the tool's implementation language).
expected="$(python3 - "$CANONICAL" <<'PYEOF'
import hashlib, pathlib, sys
body = pathlib.Path(sys.argv[1]).read_bytes()
stripped = [ln for ln in body.split(b'\n')
            if not ln.startswith(b'# op_hash:')
            and not ln.startswith(b'# op_hash_scope:')]
h = hashlib.sha256()
h.update(b'\n'.join(stripped))
h.update('\n# data_schema_version: 1\n'.encode())
print('sha256:' + h.hexdigest())
PYEOF
)"

# Tiny vault; run suggest THROUGH the seam.
VAULT="$(mktemp -d)"
trap 'rm -rf "$VAULT"' EXIT
printf -- '---\ntitle: A Note\n---\n\nSome text.\n' > "$VAULT/note-one.md"
invoke_tool brownfield suggest --root "$VAULT"
rc=$IT_EXIT
[ "$rc" = "0" ] || { echo "FAIL: brownfield suggest exited $rc" >&2; cat "$IT_STDERR" >&2; exit 1; }

# The CONFIRMED channel: line 2 of the byte-copied migration script.
COPY="$VAULT/.brownfield/migrations/01-page-typing.sh"
[ -f "$COPY" ] || { echo "FAIL: suggest did not write $COPY" >&2; exit 1; }
got="$(grep -m1 -oE '^# op_hash: sha256:[0-9a-f]{64}' "$COPY" | sed 's/^# op_hash: //')"
[ -n "$got" ] || { echo "FAIL: no op_hash sha256: line emitted in $COPY" >&2; exit 1; }

[ "$got" = "$expected" ] || {
    echo "FAIL: emitted op_hash $got != expected $expected (wrong hash VALUE)" >&2
    exit 1
}

echo "PASS $NAME"; exit 0
