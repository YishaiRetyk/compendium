#!/usr/bin/env bash
# I-7: AGENTS.md §16 Appendix A has pointer to docs/reference/dataview-queries.md AND
#      the former A content (TABLE summary... Dataview block) is absent.
# I-8: AGENTS.md §16 Appendix B has pointer to docs/reference/commit-examples.md AND
#      the former B content (reflect(q1-review) commit example) is absent.
# I-9: AGENTS.md §16 Appendix C retains all 10 numbered QRC rules verbatim.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"

# Extract just §16 body (from '## 16.' to EOF) to scope the absence-of-old-content checks.
# Without this, the absence checks would false-fail on pre-existing inline content elsewhere
# (e.g., the `reflect(q1-review): restructure AI safety domain` example also appears in the
# §3 commit-conventions table at line ~99 and is unrelated to §16 Appendix B).
S16=$(awk '/^## 16\. Appendices and Examples/{inside=1} inside==1{print}' "$A")

# I-7: Appendix A pointer present, former content absent (§16-scoped)
grep -q 'docs/reference/dataview-queries\.md' "$A" \
    || { echo "FAIL: §16 missing docs/reference/dataview-queries.md pointer" >&2; exit 1; }
echo "$S16" | grep -q 'TABLE summary, epistemic_status, updated_at' \
    && { echo "FAIL: §16 still contains former Appendix A Dataview block" >&2; exit 1; } || true

# I-8: Appendix B pointer present, former content absent (§16-scoped)
grep -q 'docs/reference/commit-examples\.md' "$A" \
    || { echo "FAIL: §16 missing docs/reference/commit-examples.md pointer" >&2; exit 1; }
echo "$S16" | grep -q 'reflect(q1-review): restructure AI safety domain' \
    && { echo "FAIL: §16 still contains former Appendix B commit example" >&2; exit 1; } || true

# I-9: Appendix C preserved verbatim. R7 review consensus: use grep -F fixed-string matches
# (no regex metachars) to pin the EXACT literal text from AGENTS.md §16. Brittle regex-based
# greps (e.g. 'Read .wiki-cloud/index\.md. first, always') risked false positives/negatives because
# the literal text includes backticks and asterisks that regex treats as metachars.
grep -F -q '**Read `wiki-cloud/index.md` first, always.**' "$A" \
    || { echo "FAIL: §16 Appendix C rule 1 ('Read wiki-cloud/index.md first, always.') missing or modified" >&2; exit 1; }
grep -F -q '**Operations: UPDATE, MERGE, SUPERSEDE, ARCHIVE.**' "$A" \
    || { echo "FAIL: §16 Appendix C rule 9 ('Operations: UPDATE, MERGE, SUPERSEDE, ARCHIVE.') missing or modified" >&2; exit 1; }
grep -F -q 'See Section 3 "What Agents Must NOT Do"' "$A" \
    || { echo "FAIL: §16 Appendix C rule 10 ('See Section 3 What Agents Must NOT Do') missing or modified" >&2; exit 1; }

# Appendix C heading itself — line-anchored, no regex metachars in target literal
grep -F -q '### Appendix C: Quick Reference Card' "$A" \
    || { echo "FAIL: §16 Appendix C heading missing" >&2; exit 1; }

# CLAUDE.md sync check (defense in depth; pre-commit hook auto-syncs but verify local state)
(cd "$REPO_ROOT" && bash bin/sync-claude.sh --check) \
    || { echo "FAIL: CLAUDE.md drifted from AGENTS.md after §16 edit" >&2; exit 1; }

echo "PASS: AGENTS.md §16 A/B extracted; C preserved; CLAUDE.md synced"
