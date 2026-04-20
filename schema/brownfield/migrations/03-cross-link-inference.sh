#!/usr/bin/env bash
# 03-cross-link-inference.sh — Advisory-only migration script (Phase 11 Plan 11-03)
# Class:  advisory-only
# Scope:  Consumes .brownfield/cross-link-candidates.yaml (written by suggest);
#         summarizes per D-06; NEVER mutates vault pages.
# Design principle: Review may be interactive and AI-guided; apply must always be deterministic.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: 03-cross-link-inference.sh [--help]

Advisory-only: scans .brownfield/cross-link-candidates.yaml (produced by
bin/brownfield.sh suggest) and appends a summary to .brownfield/applied.log.
The detailed findings are already in .brownfield/REPORT.md under the
`## Cross-link candidates` section.

No --apply path: cross-link addition requires human judgment per AGENTS.md §8
first-mention-only. Apply by hand (open REPORT.md, inspect each candidate,
edit the source page to insert [[Target]] as appropriate).

--help     Print this help and exit 0.
EOF
}

# Flag parse — apply is an error; dry-run is a silent pass-through.
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)
            echo "ERROR: 03-cross-link-inference.sh is advisory-only; there is no --apply path." >&2
            echo "Open .brownfield/REPORT.md (## Cross-link candidates section) and apply by hand per AGENTS.md §8." >&2
            exit 1
            ;;
        --dry-run) shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Root resolution (review item 1 fix — VERBATIM from 01/02) ---
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

# Locate bin/lib (env > .brownfield-env breadcrumb > upward walk) — used for consistency even though
# 03 does not import brownfield_yaml; keeping the pattern uniform with 01/02/04.
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

CANDIDATES_FILE="$BF_DIR/cross-link-candidates.yaml"

if [ ! -f "$CANDIDATES_FILE" ]; then
    echo "ERROR: $CANDIDATES_FILE not found. Run \`bin/brownfield.sh suggest\` first." >&2
    exit 1
fi

export BROWNFIELD_ROOT BROWNFIELD_LIB_DIR CANDIDATES_FILE OP_HASH

python3 <<'PYEOF'
import os, sys, datetime
import yaml as pyyaml
with open(os.environ['CANDIDATES_FILE']) as fh:
    # Strip D-09 metadata header lines before parse
    lines = [ln for ln in fh if not ln.startswith('# ')]
    data = pyyaml.safe_load(''.join(lines)) or {}
candidates = data.get('candidates') or []
n = len(candidates)
n_already_linked = sum(1 for c in candidates if c.get('target_already_linked_from_source'))

sys.stderr.write(
    f"03-cross-link-inference.sh (advisory): {n} candidate(s); "
    f"{n_already_linked} target already linked from source\n"
)
sys.stderr.write("See .brownfield/REPORT.md `## Cross-link candidates` for full list.\n")

ts = os.environ.get('BROWNFIELD_FIXTURE_TODAY')
if ts:
    ts = f"{ts}T00:00:00Z"
else:
    ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

# Item 10 per-script variance: advisory blocks have no `inputs:` field;
# mutations: none + report_section: are the advisory anchors.
# Always emit (even with 0 candidates) so the audit trail records the run.
block_path = os.path.join(os.environ['BROWNFIELD_ROOT'], '.brownfield', '_advisory_block.tmp')
with open(block_path, 'w') as fh:
    fh.write(f"## 03-cross-link-inference.sh @ {ts}\n")
    fh.write("mode: advisory\n")
    fh.write(f"op_hash: {os.environ['OP_HASH']}\n")
    fh.write("exit_code: 0\n")
    fh.write("prereq_check: pass\n")
    fh.write("mutations: none\n")
    fh.write("report_section: REPORT.md#cross-link-candidates\n")
    fh.write("summary:\n")
    fh.write(f"- candidates: {n}\n")
    fh.write(f"- already_linked: {n_already_linked}\n")
PYEOF

if [ -f "$BF_DIR/_advisory_block.tmp" ]; then
    append_applied_log_block "$BF_DIR/_advisory_block.tmp"
    rm -f "$BF_DIR/_advisory_block.tmp"
fi

exit 0
