#!/usr/bin/env bash
# tests/phase-10/test_agents_section_5_bootstrap_stage.sh
# Phase 10 Plan 04 — POST-EXTRACTION (Phase 16): asserts bootstrap_stage +
# bootstrap_date field-description rows with D-20 wording invariants are
# present in schema/reference/frontmatter.md (not AGENTS.md §5, which is now
# a 2-line stub per Phase 16 Plan 01 extraction).
#
# Phase 08-04 / 09-06 / 13.1 / 16 precedent: when a successor plan changes
# the location of content, the prior-phase tests are relaxed to assert the
# NEW invariant (content is in the leaf file, not AGENTS.md §5).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

frontmatter="$REPO_ROOT/schema/reference/frontmatter.md"
[ -f "$frontmatter" ] || { echo "FAIL: schema/reference/frontmatter.md missing at $frontmatter" >&2; exit 1; }

# 1) bootstrap_stage row present in frontmatter.md (regex match on table shape)
grep -qE "^\| \`bootstrap_stage\` \| enum \|" "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing from schema/reference/frontmatter.md" >&2; exit 1; }

# 2) Row contains the enum string
grep -qF 'raw | bootstrapped | verified' "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing enum 'raw | bootstrapped | verified' in frontmatter.md" >&2; exit 1; }

# 3) Row contains the PROV-01..05 contrast
grep -qF 'NOT a substitute for claim-level provenance' "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing PROV-01..05 contrast in frontmatter.md" >&2; exit 1; }

# 3b) Row names PROV-01..05 explicitly
grep -qF 'PROV-01..05' "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing 'PROV-01..05' reference in frontmatter.md" >&2; exit 1; }

# 4) Row names bin/ingest.sh strip
grep -qF 'stripped by `bin/ingest.sh`' "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing ingest-strip note in frontmatter.md" >&2; exit 1; }

# 4b) Row forward-refs §11.5
grep -qF '§11.5' "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing §11.5 forward-ref in frontmatter.md" >&2; exit 1; }

# 5) bootstrap_date row present in frontmatter.md
grep -qE "^\| \`bootstrap_date\` \| date \|" "$frontmatter" \
    || { echo "FAIL: bootstrap_date row missing from schema/reference/frontmatter.md" >&2; exit 1; }

# 6) bootstrap_date row mentions ISO 8601
grep -qF 'ISO 8601' "$frontmatter" \
    || { echo "FAIL: bootstrap_date row missing ISO 8601 note in frontmatter.md" >&2; exit 1; }

# SANITY: confirm AGENTS.md §5 is now a stub (no bootstrap_stage table row)
agents="$REPO_ROOT/AGENTS.md"
# Extract §5 only (from ## 5. to ## 6.)
s5=$(awk '/^## 6\./{exit} /^## 5\./{in5=1} in5{print}' "$agents")
echo "$s5" | grep -qE "^\| \`bootstrap_stage\` \| enum \|" \
    && { echo "FAIL: AGENTS.md §5 still contains bootstrap_stage table row (should be in frontmatter.md now)" >&2; exit 1; } || true

echo "PASS: schema/reference/frontmatter.md has bootstrap_stage + bootstrap_date rows with D-20 wording invariants"
