"""Bullet-eligibility heuristics for 02-provenance-bootstrap.sh.

NO LLM CALLS. Pure mechanical transforms (BRWN-16 hard-lock).

Consumed by:
  - schema/brownfield/migrations/02-provenance-bootstrap.sh (Phase 11 Plan 11-03)

Exports:
  - is_top_level_bullet(line) -> bool       # review item 5: top-level only
  - is_eligible_claim_bullet(line) -> bool
  - section_scan(body, target_sections) -> list[(lineno, line)]

See AGENTS.md §11.5 for the brownfield workflow contract and CONTEXT.md D-05
for the eligibility-rule specification. Contract phrase (verbatim in the
canonical migration script --help):

    "Marks top-level bullets under `## TL;DR` and `## Key Facts` with
    [epistemic:: inferred] when the bullet looks claim-like, is not already
    tagged, and is not a link-only, source-list, question, task, or
    placeholder bullet. Never touches Detail. Reports honestly when no
    eligible bullets are found."

Review item 5 (MEDIUM): the BULLET_TOP_LEVEL_RE regex rejects ANY leading
whitespace. The pre-review pattern ``^(\\s*)-\\s+(.+)$`` matched nested
bullets; that is now explicitly BANNED.
"""
import re

# --- Regex patterns (compile once) ---

# Top-level bullet ONLY: `-` at column 0, followed by a single space or tab.
# REJECTS:
#   `  - nested` (2-space indent)
#   `    - deeply nested` (4-space indent)
#   `\t- tab-indented nested`
# ACCEPTS:
#   `- claim one`
#   `-\tclaim two` (rare but valid markdown)
BULLET_TOP_LEVEL_RE = re.compile(r'^-(?: |\t)(.+)$')

# Patterns applied to the line (whole-line) to reject non-claim bullets.
WIKILINK_ONLY_RE = re.compile(r'^- \[\[[^\]]+\]\]\s*$')
QUESTION_RE = re.compile(r'\?\s*$')
TASK_RE = re.compile(r'^- (\[[ xX]\]|TODO:?|FIXME:?)(\s|$)', re.IGNORECASE)
SOURCE_ID_RE = re.compile(r'^- src-\d{4}-\d{2}-\d{2}-')
PLACEHOLDER_RE = re.compile(r'^- (TBD|TBC|pending|placeholder)\b', re.IGNORECASE)
EPISTEMIC_PRESENT_RE = re.compile(r'\[epistemic::')
PROVENANCE_PRESENT_RE = re.compile(r'\[prov:')
SECTION_HDR_RE = re.compile(r'^##\s+(.+?)\s*$')


def is_top_level_bullet(line: str) -> bool:
    """Return True iff line is a top-level bullet (col 0 `-` + space/tab).

    Review item 5 contract: nested bullets (any leading whitespace) return False.
    """
    return bool(BULLET_TOP_LEVEL_RE.match(line))


def is_eligible_claim_bullet(line: str) -> bool:
    """Return True if ``line`` is an eligible TOP-LEVEL claim bullet per D-05.

    Applied per D-05 to top-level bullets under '## TL;DR' and '## Key Facts'
    only. Callers scope via section_scan(); this function is line-local.

    Eligibility requires top-level (review item 5) AND no exclusion trigger.
    """
    if not is_top_level_bullet(line):
        return False  # nested / indented / non-bullet — NEVER eligible (item 5)
    if WIKILINK_ONLY_RE.match(line):
        return False  # link-only bullet — navigational, not a claim
    if QUESTION_RE.search(line):
        return False  # question — not a claim
    if TASK_RE.match(line):
        return False  # task/checklist — not a claim
    if SOURCE_ID_RE.match(line):
        return False  # source-list bullet — not a claim
    if PLACEHOLDER_RE.match(line):
        return False  # placeholder — not a claim
    if EPISTEMIC_PRESENT_RE.search(line):
        return False  # already tagged
    if PROVENANCE_PRESENT_RE.search(line):
        return False  # already has provenance marker; presumed sourced
    return True


def section_scan(body: str, target_sections: list) -> list:
    """Return list of (line_number, line) for eligible TOP-LEVEL bullets under target sections.

    Walks body line-by-line tracking the current '## ' section header. A
    bullet is emitted iff the current section title (after strip) is in
    ``target_sections`` AND passes is_eligible_claim_bullet (which enforces
    top-level-only per review item 5). '### ' and deeper headers do NOT
    reset target-section state — we stay 'in' the target until the next
    '## ' header.

    line_number is 1-indexed.
    """
    eligible = []
    in_target = False
    for lineno, line in enumerate(body.splitlines(), start=1):
        m = SECTION_HDR_RE.match(line)
        if m:
            in_target = m.group(1).strip() in target_sections
            continue
        if in_target and is_eligible_claim_bullet(line):
            eligible.append((lineno, line))
    return eligible


__all__ = [
    'BULLET_TOP_LEVEL_RE',
    'is_top_level_bullet',
    'is_eligible_claim_bullet',
    'section_scan',
]
