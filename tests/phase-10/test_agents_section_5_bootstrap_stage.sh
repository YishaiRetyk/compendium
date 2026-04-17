#!/usr/bin/env bash
# tests/phase-10/test_agents_section_5_bootstrap_stage.sh
# Phase 10 Plan 04 — asserts AGENTS.md §5 contains the bootstrap_stage +
# bootstrap_date field-description rows, with the D-20 wording invariants
# (enum values, PROV-01..05 contrast, ingest-strip note, §11.5 forward-ref).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

agents="$REPO_ROOT/AGENTS.md"
[ -f "$agents" ] || { echo "FAIL: AGENTS.md missing at $agents" >&2; exit 1; }

# 1) bootstrap_stage row present (regex match on table shape)
grep -qE "^\| \`bootstrap_stage\` \| enum \|" "$agents" \
    || { echo "FAIL: bootstrap_stage row missing in AGENTS.md §5" >&2; exit 1; }

# 2) Row contains the enum string
grep -qF 'raw | bootstrapped | verified' "$agents" \
    || { echo "FAIL: bootstrap_stage row missing enum 'raw | bootstrapped | verified'" >&2; exit 1; }

# 3) Row contains the PROV-01..05 contrast
grep -qF 'NOT a substitute for claim-level provenance' "$agents" \
    || { echo "FAIL: bootstrap_stage row missing PROV-01..05 contrast" >&2; exit 1; }

# 3b) Row names PROV-01..05 explicitly
grep -qF 'PROV-01..05' "$agents" \
    || { echo "FAIL: bootstrap_stage row missing 'PROV-01..05' reference" >&2; exit 1; }

# 4) Row names bin/ingest.sh strip
grep -qF 'stripped by `bin/ingest.sh`' "$agents" \
    || { echo "FAIL: bootstrap_stage row missing ingest-strip note" >&2; exit 1; }

# 4b) Row forward-refs §11.5
grep -qF '§11.5' "$agents" \
    || { echo "FAIL: bootstrap_stage row missing §11.5 forward-ref" >&2; exit 1; }

# 5) bootstrap_date row present
grep -qE "^\| \`bootstrap_date\` \| date \|" "$agents" \
    || { echo "FAIL: bootstrap_date row missing in AGENTS.md §5" >&2; exit 1; }

# 6) bootstrap_date row mentions ISO 8601
grep -qF 'ISO 8601' "$agents" \
    || { echo "FAIL: bootstrap_date row missing ISO 8601 note" >&2; exit 1; }

echo "PASS: AGENTS.md §5 bootstrap_stage + bootstrap_date rows present"
