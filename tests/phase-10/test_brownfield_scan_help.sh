#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 1: --help output + stub-subcommand exit codes.
# Asserts:
#   - `--help` mentions both `scan` and `bootstrap`
#   - `--help` contains the decision-boundary epigraph (D-03 / CONTEXT.md §Specifics)
#   - `suggest` exits 2 with the "not yet implemented — see Phase 11" message
#   - `verify` exits 2 with the same message
#   - `bootstrap` exits 2 with the Plan 10-03 stub message
#   - unknown subcommand exits 1 with "unknown subcommand" on stderr
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

out=$(bash "$REPO_ROOT/bin/brownfield.sh" --help)
[[ "$out" == *"scan"* ]]      || { echo "FAIL: --help missing scan" >&2; exit 1; }
[[ "$out" == *"bootstrap"* ]] || { echo "FAIL: --help missing bootstrap" >&2; exit 1; }
[[ "$out" == *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."* ]] \
    || { echo "FAIL: --help missing decision-boundary epigraph" >&2; exit 1; }

# suggest / verify / bootstrap stubs
set +e
bash "$REPO_ROOT/bin/brownfield.sh" suggest >/dev/null 2>sug.err
sug_exit=$?
set -e
[ "$sug_exit" -eq 2 ]                                 || { echo "FAIL: suggest exit=$sug_exit (want 2)" >&2; cat sug.err >&2; rm -f sug.err; exit 1; }
grep -q "not yet implemented — see Phase 11" sug.err  || { echo "FAIL: suggest missing exit-2 message" >&2; cat sug.err >&2; rm -f sug.err; exit 1; }
rm -f sug.err

set +e
bash "$REPO_ROOT/bin/brownfield.sh" verify >/dev/null 2>ver.err
ver_exit=$?
set -e
[ "$ver_exit" -eq 2 ]                                 || { echo "FAIL: verify exit=$ver_exit (want 2)" >&2; rm -f ver.err; exit 1; }
grep -q "not yet implemented — see Phase 11" ver.err  || { echo "FAIL: verify missing exit-2 message" >&2; rm -f ver.err; exit 1; }
rm -f ver.err

# NOTE: Plan 10-03 populates bootstrap; the Plan 10-02 stub-exit-2 assertion is
# relaxed here (pattern: Phase 08-04 relaxing phase-07 test_docs_skeleton on
# populate).  Bootstrap-specific behaviour is covered by the
# test_brownfield_bootstrap_*.sh suite authored in Plan 10-03.

# unknown subcommand exits 1 with "unknown subcommand"
set +e
bash "$REPO_ROOT/bin/brownfield.sh" notARealSubcmd >/dev/null 2>unk.err
unk_exit=$?
set -e
[ "$unk_exit" -eq 1 ]                                  || { echo "FAIL: unknown-subcmd exit=$unk_exit (want 1)" >&2; rm -f unk.err; exit 1; }
grep -q "unknown subcommand" unk.err                   || { echo "FAIL: unknown-subcmd missing 'unknown subcommand' message" >&2; rm -f unk.err; exit 1; }
rm -f unk.err

echo "PASS: scan help & stub messages"
