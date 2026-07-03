#!/usr/bin/env bash
# Seam self-test (REVIEWS HIGH#2, PRE-FIX-FAILING): under set -euo pipefail, the EXACT call-site
# form `invoke_tool <nonzero-tool>; rc=$IT_EXIT; echo after` must reach the after-line with rc
# holding the real nonzero code. Against a seam ending in `return "$IT_EXIT"`, set -e aborts the
# caller BEFORE rc is read — the after-line is never printed and this test fails.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cat > "$T/child.sh" <<EOF
set -euo pipefail
source "$REPO_ROOT/tests/lib/invoke_tool.sh"
invoke_tool validate-op           # no args -> usage/error exit (a known-nonzero invocation)
rc=\$IT_EXIT
echo "after rc=\$rc"              # this line MUST be reached (caller NOT aborted by set -e)
EOF

out="$(bash "$T/child.sh")" || fail "set -e caller aborted (seam did not return 0)"
echo "$out" | grep -q '^after rc=' || fail "after-line never reached: $out"
rc_val="$(echo "$out" | sed -n 's/^after rc=//p')"
[ "$rc_val" != "0" ] || fail "IT_EXIT lost the real nonzero exit (got 0)"
[ "$rc_val" = "1" ] || fail "expected validate-op usage exit 1, got $rc_val"

echo "PASS: set -e caller survived; IT_EXIT=$rc_val captured"
