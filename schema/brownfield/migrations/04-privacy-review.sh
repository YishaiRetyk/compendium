#!/usr/bin/env bash
# 04-privacy-review.sh — Advisory-only migration script (Phase 11 Plan 11-03)
# Class:  advisory-only
# Scope:  Consumes .brownfield/privacy-findings.yaml (written by suggest);
#         summarizes per D-07; NEVER flips privacy: frontmatter.
# Contract phrase (verbatim from CONTEXT.md D-07 / specifics):
#   "04-privacy-review classifies findings for review priority, not for
#    frontmatter mutation. Fail-closed `privacy: local_only` is preserved;
#    only a human (via frontmatter edit) may downgrade."
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 04-privacy-review.sh [--help]

04-privacy-review classifies findings for review priority, not for
frontmatter mutation. Fail-closed `privacy: local_only` is preserved; only
a human (via frontmatter edit) may downgrade.

Scans .brownfield/privacy-findings.yaml (produced by bin/brownfield.sh
suggest) and appends a summary to .brownfield/applied.log. The detailed
findings are in .brownfield/REPORT.md under the `## Privacy review` section.

Note on raw values (review item 12): privacy-findings.yaml retains raw
email/phone match values for operator triage — `.brownfield/` is gitignored
(TMPL-04) so these do not leak to the public template. SSN matches are
redacted ([redacted-SSN]) as an extra-sensitive class.

No --apply path: privacy classification is a judgment call owned by the
human vault maintainer.

--help     Print this help and exit 0.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)
            echo "ERROR: 04-privacy-review.sh is advisory-only; NEVER flips privacy: frontmatter." >&2
            echo "Fail-closed \`privacy: local_only\` is preserved per AGENTS.md §13. Review findings by hand." >&2
            exit 1
            ;;
        --dry-run) shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Root resolution (review item 1 fix — VERBATIM from 01/02/03) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BF_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BROWNFIELD_ROOT="${BROWNFIELD_ROOT:-$(cd "$BF_DIR/.." && pwd)}"
if [ -z "$BROWNFIELD_ROOT" ] || [ ! -d "$BROWNFIELD_ROOT" ]; then
    echo "ERROR: cannot resolve vault root from script location ($0). Set BROWNFIELD_ROOT explicitly." >&2
    exit 1
fi
if [ "$(basename "$(dirname "$SCRIPT_DIR")")" != ".brownfield" ]; then
    echo "ERROR: this script must be invoked from .brownfield/migrations/, not from schema/brownfield/migrations/." >&2
    echo "Run \`bin/brownfield.sh suggest --root <vault>\` first." >&2
    exit 1
fi

# Locate bin/lib (env > .brownfield-env breadcrumb > upward walk)
BROWNFIELD_LIB_DIR="${BROWNFIELD_LIB_DIR:-}"
if [ -z "$BROWNFIELD_LIB_DIR" ] && [ -f "$BF_DIR/.brownfield-env" ]; then
    # shellcheck disable=SC1090
    . "$BF_DIR/.brownfield-env"
fi
if [ -z "$BROWNFIELD_LIB_DIR" ]; then
    _cand="$BROWNFIELD_ROOT"
    while [ "$_cand" != "/" ]; do
        if [ -f "$_cand/bin/lib/brownfield_yaml.py" ]; then
            BROWNFIELD_LIB_DIR="$_cand/bin/lib"
            break
        fi
        _cand="$(dirname "$_cand")"
    done
fi
if [ -z "$BROWNFIELD_LIB_DIR" ] || [ ! -f "$BROWNFIELD_LIB_DIR/brownfield_yaml.py" ]; then
    echo "ERROR: cannot locate bin/lib/brownfield_yaml.py." >&2
    exit 1
fi

OP_HASH="$(awk '/^# op_hash: sha256:/ {sub(/^# op_hash: /, ""); print; exit}' "${BASH_SOURCE[0]}")"
if [ -z "$OP_HASH" ]; then
    echo "ERROR: op_hash header missing from this script — was it installed via suggest?" >&2
    exit 1
fi

APPLIED_LOG="$BF_DIR/applied.log"

append_applied_log_block() {
    local block_file="$1"
    mkdir -p "$(dirname "$APPLIED_LOG")"
    cat "$block_file" >> "$APPLIED_LOG"
    printf '\n' >> "$APPLIED_LOG"
}

FINDINGS_FILE="$BF_DIR/privacy-findings.yaml"

if [ ! -f "$FINDINGS_FILE" ]; then
    echo "ERROR: $FINDINGS_FILE not found. Run \`bin/brownfield.sh suggest\` first." >&2
    exit 1
fi

export BROWNFIELD_ROOT BROWNFIELD_LIB_DIR FINDINGS_FILE OP_HASH

python3 <<'PYEOF'
import os, sys, datetime
import yaml as pyyaml
with open(os.environ['FINDINGS_FILE']) as fh:
    lines = [ln for ln in fh if not ln.startswith('# ')]
    data = pyyaml.safe_load(''.join(lines)) or {}
findings = data.get('findings') or []
n = len(findings)
n_high = sum(1 for f in findings if f.get('risk_level') == 'high')

# Invariant: NEVER write anything to vault pages from this script (BRWN hard-lock).
# write_roundtrip is intentionally NOT imported.

sys.stderr.write(f"04-privacy-review.sh (advisory): {n} finding(s); {n_high} high-risk\n")
sys.stderr.write("See .brownfield/REPORT.md `## Privacy review` for full list.\n")
sys.stderr.write("Reminder: privacy: local_only is preserved; flips require manual frontmatter edit.\n")

ts = os.environ.get('BROWNFIELD_FIXTURE_TODAY')
if ts:
    ts = f"{ts}T00:00:00Z"
else:
    ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

pages_scanned = len({f.get('path') for f in findings}) if findings else 0
block_path = os.path.join(os.environ['BROWNFIELD_ROOT'], '.brownfield', '_advisory_block.tmp')
with open(block_path, 'w') as fh:
    fh.write(f"## 04-privacy-review.sh @ {ts}\n")
    fh.write("mode: advisory\n")
    fh.write(f"op_hash: {os.environ['OP_HASH']}\n")
    fh.write("exit_code: 0\n")
    fh.write("prereq_check: pass\n")
    fh.write("mutations: none\n")
    fh.write("report_section: REPORT.md#privacy-review\n")
    fh.write("summary:\n")
    fh.write(f"- pages_scanned: {pages_scanned}\n")
    fh.write(f"- findings: {n}\n")
    fh.write(f"- high_risk_findings: {n_high}\n")
PYEOF

if [ -f "$BF_DIR/_advisory_block.tmp" ]; then
    append_applied_log_block "$BF_DIR/_advisory_block.tmp"
    rm -f "$BF_DIR/_advisory_block.tmp"
fi

exit 0
