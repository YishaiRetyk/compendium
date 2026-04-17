"""Rule-based page classifier for brownfield scan (BRWN-16, D-16, D-17, D-18).

NO LLM CALLS.  This module is consumed by:
  - bin/brownfield.sh scan  (Phase 10, informs REPORT.md)
  - bin/brownfield-suggest/01-page-typing.sh  (Phase 11, authoritative typing)

The rule set lives here once so both phases use the same signals.  Phase 11
passes an `inbound_count` to combine outbound density with vault-wide inbound
wikilink counts; Phase 10 leaves `inbound_count=None` because scan does a
single-pass walk and does not build the full inbound graph.
"""
import re
from collections import Counter
from pathlib import Path

# Valid type values per AGENTS.md §4 page types.
VALID_TYPES = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}

# Filename convention patterns (D-16 signal 2).
# Anchored + character-class alternations only to avoid catastrophic backtracking.
PASCAL_CASE_RE = re.compile(r'^[A-Z][a-zA-Z0-9]*(?:-[A-Z][a-zA-Z0-9]*)*$')
DATE_PREFIX_RE = re.compile(r'^\d{4}-\d{2}-\d{2}[-_]')
SOURCE_PREFIX_RE = re.compile(r'^src-')
COMPARISON_PREFIX_RE = re.compile(r'^vs-|-vs-')

# Body parsing patterns (D-16 signals 3 + 4).
SECTION_RE = re.compile(r'^##\s+(.+?)\s*$', re.MULTILINE)
WIKILINK_RE = re.compile(r'\[\[([^\]]+)\]\]')


def classify_page(
    rel_path: str,
    frontmatter: dict | None,
    body: str,
    inbound_count: int | None = None,  # reserved for Phase 11 01-page-typing.sh reuse; unused in Phase 10 scan
) -> tuple[str, str, str]:
    """Classify a single wiki page using 4 rule-based signals (D-16).

    Returns (label, confidence, signal_trace):
      - label:      one of VALID_TYPES plus 'unknown'
      - confidence: 'high' | 'medium' | 'low' | 'unknown'
      - signal_trace: comma-separated 'key=value' slugs per D-17
                      e.g. 'frontmatter=none, filename=pascalcase, h1=entity-like, links=outbound-heavy'

    `inbound_count` is accepted (reserved for Phase 11) but IGNORED in Phase 10
    scan.  The parameter exists now so Phase 11 can pass it without modifying
    this module's signature (BRWN-16 / Phase-10 Plan 02 contract).
    """
    # ------------------------------------------------------------------ Signal 1
    # Existing frontmatter `type:` is D-17 high-confidence if valid per §4.
    fm_type: str | None = None
    if frontmatter and isinstance(frontmatter.get('type'), str):
        t = frontmatter['type'].strip()
        if t in VALID_TYPES:
            fm_type = t

    # ------------------------------------------------------------------ Signal 2
    # Filename convention.  Check in specificity order; first match wins.
    name = Path(rel_path).stem
    fn_guess: str | None = None
    if SOURCE_PREFIX_RE.match(name):
        fn_guess = 'source'
    elif COMPARISON_PREFIX_RE.search(name):
        fn_guess = 'comparison'
    elif DATE_PREFIX_RE.match(name):
        fn_guess = 'source'  # journal/source flavored
    elif PASCAL_CASE_RE.match(name):
        fn_guess = 'entity'

    # ------------------------------------------------------------------ Signal 3
    # Section-heading structure.  Order matters: test for source summary and
    # comparison shapes BEFORE the generic TL;DR + Key Facts + Detail triad.
    sections = set(SECTION_RE.findall(body or ''))
    sec_guess: str | None = None
    if 'Extracted Claims' in sections and 'Source Metadata' in sections:
        sec_guess = 'source'
    elif 'Comparison Table' in sections:
        sec_guess = 'comparison'
    elif 'TL;DR' in sections and 'Key Facts' in sections and 'Detail' in sections:
        # Ambiguous between entity and concept; signal 4 (link density)
        # disambiguates.  Default guess is 'entity' since proper-noun pages
        # are more common; concept bias comes via outbound-link density below.
        sec_guess = 'entity'

    # ------------------------------------------------------------------ Signal 4
    # Wikilink density (outbound only in Phase 10).  Phase 11 will combine
    # `outbound_links` with `inbound_count` for higher accuracy.
    outbound_links = len(WIKILINK_RE.findall(body or ''))
    link_guess: str | None = None
    if outbound_links >= 5:
        link_guess = 'concept'  # outbound-heavy abstract framing → concept

    # ------------------------------------------------------------------ D-17 map
    signals = {
        'frontmatter': fm_type,
        'filename':    fn_guess,
        'heading':     sec_guess,
        'links':       link_guess,
    }
    non_none = [v for v in signals.values() if v is not None]

    if fm_type:
        # Explicit frontmatter type is high-confidence per D-17.
        label = fm_type
        confidence = 'high'
    else:
        counter = Counter(non_none)
        if not counter:
            label, confidence = 'unknown', 'unknown'
        else:
            top_label, top_count = counter.most_common(1)[0]
            distinct_labels = set(non_none)
            # Conflict: 2+ distinct labels AND no clear majority (top is 1).
            if len(distinct_labels) >= 2 and top_count == 1:
                label, confidence = 'unknown', 'unknown'
            elif top_count >= 3:
                label, confidence = top_label, 'high'
            elif top_count == 2:
                label, confidence = top_label, 'medium'
            else:
                label, confidence = top_label, 'low'

    # ------------------------------------------------------------------ Trace
    trace_parts = []
    trace_parts.append(f"frontmatter={fm_type or 'none'}")
    trace_parts.append(f"filename={fn_guess or 'none'}")
    if sec_guess:
        trace_parts.append(f"h1={sec_guess}-like")
    else:
        trace_parts.append("h1=none")
    if link_guess == 'concept':
        trace_parts.append("links=outbound-heavy")
    elif outbound_links == 0:
        trace_parts.append("links=none")
    else:
        trace_parts.append(f"links=outbound-{outbound_links}")
    signal_trace = ", ".join(trace_parts)

    return label, confidence, signal_trace


def unknown_reason(
    rel_path: str,
    frontmatter: dict | None,
    body: str,
    signal_trace: str,
) -> str:
    """Return a concise one-line prose open-question per D-18.

    Format: ``<path>`` — <signals-listed-neutrally>. <Open question directed at user>?

    Avoids pre-filled type suggestions that would anchor user judgment.
    """
    return f"`{rel_path}` — {signal_trace}. What kind of page should this become?"
