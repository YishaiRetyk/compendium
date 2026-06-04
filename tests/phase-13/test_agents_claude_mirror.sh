#!/usr/bin/env bash
# tests/phase-13/test_agents_claude_mirror.sh -- Plan 13-04 Task 2.
# Asserts the Audit is documented as a review-only workflow in AGENTS.md
# (four-operation framing preserved, no new page type) with:
#   - the D-08 reflect-tier "audit recommended" suggestion,
#   - the D-10 human-approved contradicts->marker handoff,
#   - the FAITH-04 privacy contract described as EFFECTIVE CLAIM privacy
#     (strictest-of set, NOT bare "source privacy"),
#   - the explicit verifier-locality model (allow-local + cloud-by-default),
#   - the partitioned --emit-worklist egress,
# and that CLAUDE.md byte-mirrors AGENTS.md and schema/AGENTS.template.md carries
# the same Audit-workflow heading. Also re-asserts the canonical byte-equality gate.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENTS="$REPO_ROOT/AGENTS.md"
CLAUDE="$REPO_ROOT/CLAUDE.md"
TEMPLATE="$REPO_ROOT/schema/AGENTS.template.md"

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Audit documented as review-only with D-08 + D-10 + skipped-privacy.
grep -qi 'review-only' "$AGENTS"        || fail "AGENTS.md missing 'review-only'"
grep -qi 'audit recommended' "$AGENTS"  || fail "AGENTS.md missing D-08 'audit recommended' reflect-tier note"
grep -qi 'contradicts' "$AGENTS"        || fail "AGENTS.md missing 'contradicts' handoff"
grep -qi 'skipped-privacy' "$AGENTS"    || fail "AGENTS.md missing 'skipped-privacy'"

# 2. Verifier-locality model (HIGH-1) + partitioned worklist (HIGH-2).
grep -qi 'allow-local' "$AGENTS"        || fail "AGENTS.md missing 'allow-local' verifier-locality flag"
grep -qiE 'cloud.*default|never infer|treated as cloud' "$AGENTS" \
    || fail "AGENTS.md missing cloud-by-default / never-infer-locality prose"
grep -qi 'emit-worklist' "$AGENTS"      || fail "AGENTS.md missing partitioned --emit-worklist egress"

# 3. Effective claim privacy (MEDIUM 13-04), NOT bare "source privacy".
# Phase 15: the strictest-of ladder was replaced by the structural wiki-local/ predicate.
grep -qi 'effective claim privacy' "$AGENTS" \
    || fail "AGENTS.md privacy prose must say 'effective claim privacy' (not bare 'source privacy')"
# Phase 15: 'wiki-local/' path-prefix predicate replaces 'strictest of {raw-source/...}'
grep -qiE 'wiki-local|source-summary' "$AGENTS" \
    || fail "AGENTS.md missing Phase 15 structural predicate prose (wiki-local/ or source-summary tier)"

# 4. Four-operation framing preserved (Audit is NOT a 5th operation).
grep -qi 'four operations' "$AGENTS"    || fail "AGENTS.md no longer says 'four operations'"

# 5. CLAUDE.md byte-mirrors AGENTS.md; template carries the Audit heading.
cmp -s "$AGENTS" "$CLAUDE" || fail "CLAUDE.md not byte-equal to AGENTS.md (run bin/sync-claude.sh)"
grep -qi '11.7 Audit Workflow' "$TEMPLATE" || fail "schema/AGENTS.template.md missing the Audit-workflow heading"
grep -qi 'effective claim privacy' "$TEMPLATE" \
    || fail "schema/AGENTS.template.md missing mirrored 'effective claim privacy' prose"

# 6. The Audit-workflow subsection is byte-identical between AGENTS.md and template
#    (schema-mirror neutrality guard; check-neutrality.sh PUBLIC_PATHS excludes schema/).
#    mawk-safe extractor: start at the §11.7 heading, stop at the next ## or ### heading.
extract_audit() {
    awk 'f && /^###? /{exit} /^### 11\.7 Audit Workflow$/{f=1} f' "$1"
}
if ! diff <(extract_audit "$AGENTS") <(extract_audit "$TEMPLATE") >/dev/null; then
    echo "FAIL: §11.7 Audit Workflow subsection diverges between AGENTS.md and template" >&2
    diff <(extract_audit "$AGENTS") <(extract_audit "$TEMPLATE") >&2 || true
    exit 1
fi
[ -n "$(extract_audit "$AGENTS")" ] || fail "§11.7 extractor matched nothing"

# 7. The canonical byte-equality gate still passes after the template edit + regen.
bash "$REPO_ROOT/tests/phase-08/test_canonical_byte_equality.sh" >/dev/null 2>&1 \
    || fail "canonical byte-equality gate red after §11.7 template edit (regenerate fixture)"

echo "PASS: Audit documented as review-only workflow; CLAUDE/template mirror byte-equal; privacy=effective-claim"
exit 0
