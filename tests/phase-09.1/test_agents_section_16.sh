#!/usr/bin/env bash
# I-7/I-8/I-9 (POST-EXTRACTION): §16 "Appendices and Examples" is DELETED from
# AGENTS.md (Phase 16 Plan 03). The Appendix C QRC rules are absorbed into
# their respective resident sections (§3); the Appendix A/B docs still exist on disk.
#
# Phase 08-04 / 09-06 / 13.1 precedent: when a successor plan changes the shape,
# the prior-phase tests are relaxed to assert the NEW invariant.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"

# ASSERTION 1: §16 section header ABSENT (section deleted in Phase 16-03)
! grep -q '^## 16\. Appendices' "$A" \
    || { echo "FAIL: §16 'Appendices and Examples' header found in AGENTS.md — should be deleted (Phase 16-03)" >&2; exit 1; }

# ASSERTION 2: QRC rule homes survive in resident sections
# Rule 1: read index.md first → §3 LLM Navigation Rule
grep -q 'wiki-cloud/index.md' "$A" \
    || { echo "FAIL: AGENTS.md §3 missing 'wiki-cloud/index.md' (QRC rule 1 home)" >&2; exit 1; }

# Rule 3: ISO 8601 dates → §3 Date Format
grep -qF 'ISO 8601' "$A" \
    || { echo "FAIL: AGENTS.md §3 missing 'ISO 8601' (QRC rule 7 home)" >&2; exit 1; }

# Rule 8: snake_case → §3 Frontmatter Field Names
grep -q 'snake_case' "$A" \
    || { echo "FAIL: AGENTS.md §3 missing 'snake_case' (QRC rule 8 home)" >&2; exit 1; }

# Rule 10: What Agents Must NOT Do → §3
grep -q 'What Agents Must NOT Do' "$A" \
    || { echo "FAIL: AGENTS.md §3 missing 'What Agents Must NOT Do' (QRC rule 10 home)" >&2; exit 1; }

# Rule 5: one commit per operation → §3 Commit Conventions
grep -q 'One commit per logical operation\|one commit per logical operation' "$A" \
    || { echo "FAIL: AGENTS.md §3 missing one-commit rule (QRC rule 5 home)" >&2; exit 1; }

# Rule 6: Privacy default wiki-local/ → schema/reference/privacy.md
grep -q 'Privacy default' "$REPO_ROOT/schema/reference/privacy.md" \
    || { echo "FAIL: schema/reference/privacy.md missing 'Privacy default' (QRC rule 6 home)" >&2; exit 1; }

# ASSERTION 3: Appendix A/B docs still exist on disk (reachable via docs/ tree)
test -f "$REPO_ROOT/docs/reference/dataview-queries.md" \
    || { echo "FAIL: docs/reference/dataview-queries.md missing (Appendix A target)" >&2; exit 1; }
test -f "$REPO_ROOT/docs/reference/commit-examples.md" \
    || { echo "FAIL: docs/reference/commit-examples.md missing (Appendix B target)" >&2; exit 1; }

# ASSERTION 4: CLAUDE.md sync check
(cd "$REPO_ROOT" && invoke_tool_compat sync-claude --check) \
    || { echo "FAIL: CLAUDE.md drifted from AGENTS.md" >&2; exit 1; }

echo "PASS: §16 absent; QRC rule homes verified in §3 + privacy.md; Appendix A/B docs on disk; CLAUDE.md synced"
