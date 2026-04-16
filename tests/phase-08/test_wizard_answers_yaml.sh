#!/usr/bin/env bash
# tests/phase-08/test_wizard_answers_yaml.sh -- WZRD-03 + WZRD-06:
# .wizard-answers.yaml is written with the correct shape (3 metadata keys
# + 6 answer keys), parses as YAML, and is byte-identical across two runs
# with the same WIZARD_GENERATED_AT / WIZARD_TEMPLATE_SHA env vars.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: .wizard-answers.yaml shape + key set + deterministic write (WZRD-03, WZRD-06)"

WORK="$(mktemp_repo)"

WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK" >/dev/null

assert_file_exists "$WORK/.wizard-answers.yaml" ".wizard-answers.yaml must exist in render-to dir"

# Parse + shape check.
python3 - "$WORK/.wizard-answers.yaml" <<'PYEOF'
import sys

path = sys.argv[1]
try:
    import yaml
except ImportError:
    print("SKIP: PyYAML not available; parser shape check skipped", file=sys.stderr)
    sys.exit(0)

with open(path, "r", encoding="utf-8") as f:
    d = yaml.safe_load(f)

assert d["wizard_version"] == "1.1.0", f"wizard_version mismatch: {d.get('wizard_version')!r}"
assert d["generated_at"] == "2026-04-16T12:00:00Z", f"generated_at mismatch: {d.get('generated_at')!r}"
assert d["template_sha"] == "fixed-sha", f"template_sha mismatch: {d.get('template_sha')!r}"
answers = d["answers"]
expected = {"maintainer_name", "primary_domain", "agent", "default_privacy", "decay_profile", "obsidian"}
got = set(answers.keys())
assert got == expected, f"answer keys mismatch: {got} vs {expected}"
assert answers["obsidian"] is True, f"obsidian expected True, got {answers['obsidian']!r}"
assert answers["primary_domain"] == "personal-knowledge", f"primary_domain mismatch: {answers['primary_domain']!r}"
assert answers["maintainer_name"] == "Template Maintainer", f"maintainer_name mismatch: {answers['maintainer_name']!r}"
print("YAML shape OK")
PYEOF

# Determinism: re-run wizard into a second tmpdir with identical env vars,
# assert both .wizard-answers.yaml files are byte-identical.
WORK2="$(mktemp_repo)"
WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK2" >/dev/null

assert_byte_equal "$WORK/.wizard-answers.yaml" "$WORK2/.wizard-answers.yaml" \
    "two wizard runs with identical env vars must produce byte-identical .wizard-answers.yaml"

echo "PASS: .wizard-answers.yaml shape verified + deterministic across runs"
exit 0
