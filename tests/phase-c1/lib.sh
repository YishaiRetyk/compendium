# tests/phase-c1/lib.sh -- C-1 ledger-emitter fallback test helpers (ADR-008
# failure handling). Source this from tests/phase-c1/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"
#
# HERMETICITY: every test in this suite pins BOTH seams of the C-1 emission
# path to per-test scratch — CC_LEDGER_ROOT (where ingest looks for the real
# emitter) and XDG_STATE_HOME (where the ADR-008 fallback file lands) — so no
# test ever writes to the developer's real ledger or real ~/.local/state.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # the tool-invocation seam

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# make_failing_emitter <fake-cc-ledger-root> — bin/emit_op_line.py exists but
# always exits nonzero (simulated emit failure: disk full, schema reject, ...).
make_failing_emitter() {
    mkdir -p "$1/bin"
    printf 'import sys\nsys.exit(1)\n' > "$1/bin/emit_op_line.py"
}

# make_recording_emitter <fake-cc-ledger-root> — bin/emit_op_line.py succeeds
# and appends its argv to <root>/calls.txt (proves the primary path ran).
make_recording_emitter() {
    mkdir -p "$1/bin"
    cat > "$1/bin/emit_op_line.py" <<'PYEOF'
import os, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with open(os.path.join(root, "calls.txt"), "a", encoding="utf-8") as f:
    f.write(" ".join(sys.argv[1:]) + "\n")
PYEOF
}

# assert_c1_line <jsonl-file> <lineno> <op> <abs-target> <session>
# The numbered line must be a plain C-1-shaped record the cc-ledger replayer
# can sweep as-is: {"v":1,"ts":ISO8601Z,"store":"knowledge","target":<abs>,
# "op":...,"agent":"compendium-ingest","session":...,"refs":[]}. refs MUST be
# [] on this side — the replayer adds ["replayed:<source>"] when sweeping.
assert_c1_line() {
    python3 - "$1" "$2" "$3" "$4" "$5" <<'PYEOF'
import json, re, sys
path, lineno, op, target, session = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5]
with open(path, encoding="utf-8") as f:
    lines = f.read().splitlines()
rec = json.loads(lines[lineno - 1])
def fail(msg):
    print("FAIL: fallback line %d: %s: %r" % (lineno, msg, rec), file=sys.stderr)
    sys.exit(1)
if sorted(rec) != ["agent", "op", "refs", "session", "store", "target", "ts", "v"]:
    fail("wrong key set")
if rec["v"] != 1: fail("v != 1")
if not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", rec["ts"]): fail("ts not ISO8601 UTC (...Z)")
if rec["store"] != "knowledge": fail("store != knowledge")
if not rec["target"].startswith("/"): fail("target not absolute")
if rec["target"] != target: fail("target != %s" % target)
if rec["op"] != op: fail("op != %s" % op)
if rec["agent"] != "compendium-ingest": fail("agent != compendium-ingest")
if rec["session"] != session: fail("session != %s" % session)
if rec["refs"] != []: fail("refs != [] (the replayer owns refs)")
PYEOF
}

# canon_dir <dir> — physical path (matches Python os.getcwd()/abspath output).
canon_dir() { (cd "$1" && pwd -P); }
