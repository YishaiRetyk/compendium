#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_canonical_agents_byte_equality.sh — MANUAL-06 /
# TMPL-byte-equality: Plan 11-05 re-renders the canonical AGENTS.md
# (schema/fixtures/canonical-AGENTS.md) using Plan 08-01's python3
# render routine after §11.5 lands; this test asserts the re-rendered
# fixture is byte-equal to the checked-in fixture.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

CANON="$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"
ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"
TEMPLATE="$REPO_ROOT/schema/AGENTS.template.md"

assert_file_exists "$CANON"
assert_file_exists "$ANSWERS"
assert_file_exists "$TEMPLATE"

# Re-render the canonical AGENTS.md via the Plan 08-01 python3 str.replace
# routine and compare against the checked-in fixture.
python3 - "$ANSWERS" "$TEMPLATE" "$CANON" <<'PYEOF'
import sys, pathlib, re
answers_path, template_path, canon_path = map(pathlib.Path, sys.argv[1:4])
answers_text = answers_path.read_text()
template_text = template_path.read_text()
canon_text    = canon_path.read_text()
subs = {}
for ln in answers_text.splitlines():
    m = re.match(r"^([A-Z_][A-Z0-9_]*):\s*(.*?)\s*$", ln)
    if not m: continue
    subs[m.group(1)] = m.group(2)
rendered = template_text
for k, v in subs.items():
    rendered = rendered.replace("{{" + k + "}}", v)
if rendered != canon_text:
    print("FAIL: re-rendered canonical AGENTS.md differs from checked-in schema/fixtures/canonical-AGENTS.md", file=sys.stderr)
    # dump a short diff for triage
    import difflib
    diff = list(difflib.unified_diff(canon_text.splitlines(keepends=True)[:200],
                                    rendered.splitlines(keepends=True)[:200],
                                    fromfile="canonical-AGENTS.md",
                                    tofile="re-rendered"))
    sys.stderr.writelines(diff[:60])
    sys.exit(1)
PYEOF

echo "PASS $NAME"; exit 0
