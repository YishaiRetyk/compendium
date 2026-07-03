#!/usr/bin/env bash
# Seam self-test (REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1 + cycle-6 fix #4,
# PRE-FIX-FAILING): IT_CAPTURE_DIR per-call self-record under a COLLISION-PROOF key; two
# distinct test-file subprocesses sharing ONE IT_CAPTURE_DIR do NOT overwrite each other's
# first call; an injected one-byte divergence between two capture dirs is CAUGHT; the tree
# channel follows --root (not $PWD); the pid-stripped pairing key pairs cross-run captures.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }
CLEAN=()
trap 'rm -rf "${CLEAN[@]:-}"' EXIT

# 1. Per-call keying within one test file: numbering is PER-TOOL and FILESYSTEM-derived
#    (REVIEW FIX: a shell counter was lost inside command substitutions — the dominant
#    compat call shape — so same-tool subshell calls overwrote <tool>-001). Two direct
#    calls + one SUBSHELL call of the same tool must yield lint-001, validate-op-001,
#    lint-002 (the subshell call must NOT collide with lint-001).
export IT_CAPTURE_DIR="$(mktemp -d)"; CLEAN+=("$IT_CAPTURE_DIR")
invoke_tool lint --help
invoke_tool validate-op
out_sub="$(invoke_tool_compat lint --help)"   # subshell call — the cycle-4 collision shape
key="$(_it_capture_key)"
test -d "$IT_CAPTURE_DIR/$key/lint-001" || fail "first call not recorded under $key/lint-001"
test -d "$IT_CAPTURE_DIR/$key/validate-op-001" || fail "validate-op call not recorded under $key/validate-op-001 (per-tool numbering)"
test -d "$IT_CAPTURE_DIR/$key/lint-002" || fail "SUBSHELL lint call collided with lint-001 (fs-derived counter regressed)"
for ch in stdout stderr exit tree; do
    test -f "$IT_CAPTURE_DIR/$key/lint-001/$ch" || fail "channel $ch missing in lint-001"
    test -f "$IT_CAPTURE_DIR/$key/lint-002/$ch" || fail "channel $ch missing in lint-002"
done
echo "ok: per-call keyed self-record (per-tool numbering; subshell calls do not collide)"

# 2. CROSS-TEST-FILE collision-proofing (cycle-4 finding #1 — the core proof): two DIFFERENT
#    simulated test-file subprocesses share ONE IT_CAPTURE_DIR and both record the same tool's
#    FIRST call. Against a bare per-process counter both write <dir>/lint-001 -> silent overwrite.
export IT_CAPTURE_DIR="$(mktemp -d)"; CLEAN+=("$IT_CAPTURE_DIR")
IT_CAPTURE_KEY=fileA bash -c 'source "$REPO_ROOT/tests/lib/invoke_tool.sh"; invoke_tool lint --help'
IT_CAPTURE_KEY=fileB bash -c 'source "$REPO_ROOT/tests/lib/invoke_tool.sh"; invoke_tool lint --help'
test -d "$IT_CAPTURE_DIR/fileA/lint-001" || fail "fileA's first lint call missing (collision/overwrite)"
test -d "$IT_CAPTURE_DIR/fileB/lint-001" || fail "fileB's first lint call missing (collision/overwrite)"
echo "ok: two distinct test-file subprocesses' first calls landed in DISTINCT keyed dirs"
unset IT_CAPTURE_DIR

# 3. Divergence-caught: identical channel dirs pass; a one-byte flip is CAUGHT.
DIVROOT="$(mktemp -d)"; CLEAN+=("$DIVROOT")
mkdir -p "$DIVROOT/A/case" "$DIVROOT/B/case"
for ch in stdout stderr exit tree; do
    printf 'channel-%s\n' "$ch" > "$DIVROOT/A/case/$ch"
    printf 'channel-%s\n' "$ch" > "$DIVROOT/B/case/$ch"
done
if ! assert_parity "$DIVROOT/A/case" "$DIVROOT/B/case" >/dev/null 2>&1; then
    fail "identical captures reported as divergent"
fi
printf 'channel-stdout!\n' > "$DIVROOT/B/case/stdout"    # flip one byte region
if assert_parity "$DIVROOT/A/case" "$DIVROOT/B/case" >/dev/null 2>&1; then
    fail "injected one-byte stdout divergence NOT caught"
fi
echo "ok: injected byte divergence caught by the channel comparison"

# 4. Footprint root follows --root, not \$PWD (CYCLE-6 fix #4): cwd is NOT the fixture; the
#    recorded tree channel must reflect the --root fixture's contents.
FIXROOT="$(mktemp -d)"; CLEAN+=("$FIXROOT")
printf 'known content\n' > "$FIXROOT/knownfile.md"
export IT_CAPTURE_DIR="$(mktemp -d)"; CLEAN+=("$IT_CAPTURE_DIR")
IT_CAPTURE_KEY=rootprobe bash -c 'source "$REPO_ROOT/tests/lib/invoke_tool.sh"; invoke_tool validate-op --root "'"$FIXROOT"'"'
tree_file="$IT_CAPTURE_DIR/rootprobe/validate-op-001/tree"
test -f "$tree_file" || fail "rootprobe capture missing"
grep -q 'knownfile.md' "$tree_file" || fail "tree channel snapshotted \$PWD, not the --root fixture"
echo "ok: tree channel snapshots the --root fixture"
unset IT_CAPTURE_DIR

# 5. Cross-run pid-independent pairing (CYCLE-6 fix #4): two runs' keys differ only by -<pid>;
#    it_pairing_key strips both to the same identity so --require-parity can pair them.
[ "$(it_pairing_key lint_suite-111)" = "lint_suite" ] || fail "it_pairing_key did not strip -111"
[ "$(it_pairing_key lint_suite-222)" = "lint_suite" ] || fail "it_pairing_key did not strip -222"
[ "$(it_pairing_key lint_suite-111)" = "$(it_pairing_key lint_suite-222)" ] || fail "cross-run keys do not pair"
echo "ok: pid-stripped pairing key pairs distinct-pid runs"

echo "PASS: IT_CAPTURE_DIR contract (keyed record, collision-proof, divergence-caught, --root tree, pairing)"
