#!/usr/bin/env bash
# tests/phase-08/test_wizard_validation.sh -- WZRD-04: --answers-file
# validation rejects bad slug / agent / privacy with D-17 error shape
# `Invalid <field> "<value>". Must match <rule>. Try: <example>.`
# and returns exit 5.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: --answers-file validation fails-closed with D-17 error shape (WZRD-04)"

WORK="$(mktemp_repo)"

make_bad() {
    # make_bad <out-path> <field-key> <bad-value>
    local out="$1" field="$2" value="$3"
    # Start from the canonical answers file and replace the one field.
    python3 - "$CANONICAL" "$out" "$field" "$value" <<'PYEOF'
import sys
src = open(sys.argv[1], "r", encoding="utf-8").read()
out = []
field = sys.argv[3]
value = sys.argv[4]
for line in src.splitlines():
    stripped = line.strip()
    if stripped.startswith(f"{field}:"):
        # Preserve leading whitespace; write bad value quoted.
        indent = line[: len(line) - len(line.lstrip())]
        out.append(f'{indent}{field}: "{value}"')
    else:
        out.append(line)
open(sys.argv[2], "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
PYEOF
}

run_case() {
    # run_case <label> <bad-file> <expected-substr>
    local label="$1" badfile="$2" expected="$3"
    local stderr_file="$WORK/stderr-$label.log"
    local rc=0
    set +e
    bash "$WIZARD" --answers-file "$badfile" --render-to "$WORK/out-$label" 2>"$stderr_file" >/dev/null
    rc=$?
    set -e
    assert_eq 5 "$rc" "$label: expected exit 5 (validation)"
    if ! grep -qF "$expected" "$stderr_file"; then
        echo "ASSERT FAIL: $label stderr missing expected substring" >&2
        echo "Expected: $expected" >&2
        echo "--- stderr ---" >&2
        cat "$stderr_file" >&2
        echo "--- end stderr ---" >&2
        exit 1
    fi
}

# Bad domain
make_bad "$WORK/bad-domain.yaml" "primary_domain" "BadDomain!"
run_case "bad-domain" "$WORK/bad-domain.yaml" \
    'Invalid primary_domain "BadDomain!". Must match ^[a-z0-9-]+$. Try: personal-knowledge.'

# Bad agent
make_bad "$WORK/bad-agent.yaml" "agent" "vim"
run_case "bad-agent" "$WORK/bad-agent.yaml" \
    'Invalid agent "vim". Must match one of {claude-code, codex, other}. Try: claude-code.'

# Bad privacy
make_bad "$WORK/bad-privacy.yaml" "default_privacy" "secret"
run_case "bad-privacy" "$WORK/bad-privacy.yaml" \
    'Invalid default_privacy "secret". Must match one of {local_only, cloud_safe}. Try: local_only.'

echo "PASS: all 3 bad --answers-file cases fail with exit 5 + D-17 error shape"
exit 0
