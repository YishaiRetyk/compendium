#!/usr/bin/env bash
# tests/phase-08/test_wizard_idempotent.sh -- WZRD-05: re-run refuses with
# exit 4 + D-04 message when .wizard-answers.yaml exists at repo root, but
# --dry-run is always allowed (D-06).
#
# Uses a mktemp_repo skeleton (copy of wizard + template) so we can touch
# .wizard-answers.yaml at the fake repo root without mutating the real repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: re-run refusal with exit 4 + D-06 dry-run bypass (WZRD-05)"

WORK="$(mktemp_repo)"
mkdir -p "$WORK/bin" "$WORK/schema"
cp "$REPO_ROOT/bin/init-wizard.sh" "$WORK/bin/init-wizard.sh"
cp "$REPO_ROOT/schema/AGENTS.template.md" "$WORK/schema/AGENTS.template.md"
chmod +x "$WORK/bin/init-wizard.sh"

# Scaffold its OWN compendium module so the shim's PYTHONPATH=$WORK/src anchors the wizard's
# REPO_ROOT on $WORK (init_wizard.py:865, via __file__), not the installed/live module (which
# resolves to the REAL repo). Without it the sentinel below is invisible — the wizard checks
# the LIVE repo's .wizard-answers.yaml, so this test passed only when the live repo happened to
# be already-initialized (e.g. left dirty by another wizard test), and its real-ish run could
# touch the live tree (26-REVIEW F1, same root cause as test_wizard_partial_failure).
# init_wizard is self-contained; mirrors tests/test_init_wizard_unit.py::make_scaffold.
mkdir -p "$WORK/src/compendium" "$WORK/wiki-cloud"
cp "$REPO_ROOT/src/compendium/__init__.py" "$REPO_ROOT/src/compendium/init_wizard.py" "$WORK/src/compendium/"
printf '# Index\n\n## Decisions\n\n- seed entry\n' > "$WORK/wiki-cloud/index.md"

# Create the sentinel at the fake repo root.
touch "$WORK/.wizard-answers.yaml"

WIZARD="$WORK/bin/init-wizard.sh"
STDERR_FILE="$WORK/stderr.log"

# ---- Case A: real run refused with exit 4 ----
set +e
bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK/out-A" 2>"$STDERR_FILE" >/dev/null
RC=$?
set -e

assert_eq 4 "$RC" "re-run should refuse with exit 4"
assert_grep 'already initialized' "$STDERR_FILE" "stderr must contain 'already initialized'"
assert_grep 'delete \.wizard-answers\.yaml and AGENTS\.md' "$STDERR_FILE" \
    "stderr must mention deleting .wizard-answers.yaml and AGENTS.md"

# ---- Case B: --dry-run always allowed (D-06) ----
set +e
bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --dry-run >"$WORK/dry-stdout.log" 2>"$WORK/dry-stderr.log"
RC_DRY=$?
set -e

assert_eq 0 "$RC_DRY" "--dry-run must succeed (D-06) even when .wizard-answers.yaml exists"
assert_grep '^--- a/AGENTS\.md' "$WORK/dry-stdout.log" "--dry-run stdout must contain AGENTS.md diff header"

echo "PASS: real run refused with exit 4 + D-04 message; --dry-run bypasses (D-06)"
exit 0
