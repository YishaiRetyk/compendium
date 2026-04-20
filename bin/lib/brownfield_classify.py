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


# --- Phase 11 additions: cluster_by_signals() + cluster_is_autoapproveable() (BRWN-11, BRWN-14) ---
#
# These helpers are additive: classify_page() + unknown_reason() above are unchanged.
# They power bin/brownfield.sh suggest (Plan 11-02) without perturbing scan (Phase 10).
#
# Design note: classify_page() returns a tuple (label, confidence, signal_trace).
# The cluster helper consumes a RICHER dict shape that suggest builds in its Python
# heredoc — combining classify_page's output with slug-form signals (pascal/kebab/
# entity-like/inbound-heavy/etc.) derived from filename + frontmatter + body + the
# vault-wide inbound wikilink count.  The slug form is what D-03's cluster-level
# "3+ signals agree" gate operates on.

from collections import defaultdict  # noqa: E402
from typing import Iterable  # noqa: E402


# Label-hint agreement table — each label lists the signal values that point
# TOWARD that label.  Used by cluster_is_autoapproveable() to count agreement
# along the D-03 "3+ non-frontmatter signals agree" path.
_LABEL_HINTS = {
    'entity':     {'filename': {'pascal'},        'heading': {'entity-like'},     'inbound': {'inbound-heavy'}, 'links': {'outbound-light', 'none'}},
    'concept':    {'filename': {'kebab'},         'heading': {'concept-like'},    'inbound': {'inbound-light'}, 'links': {'outbound-heavy'}},
    'overview':   {'filename': {'kebab'},         'heading': {'overview-like'},   'inbound': {'inbound-heavy'}, 'links': {'outbound-heavy'}},
    'source':     {'filename': {'date-prefixed'}, 'heading': {'source-like'},     'inbound': {'inbound-light'}, 'links': {'none'}},
    'comparison': {'filename': {'kebab'},         'heading': {'comparison-like'}, 'inbound': {'inbound-light'}, 'links': {'outbound-heavy'}},
    'decision':   {'filename': {'dr-prefixed'},   'heading': {'decision-like'},   'inbound': {'inbound-light'}, 'links': {'outbound-light'}},
}
_VALID_TYPE_ENUM = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}


def _count_agreement(signals: dict, label: str | None) -> int:
    """Count how many non-frontmatter signals in `signals` agree with the
    hint table for `label`.  Returns 0 on missing label / unknown hints."""
    if not label or label == 'unknown':
        return 0
    hints = _LABEL_HINTS.get(label, {})
    if not hints:
        return 0
    count = 0
    for signal_name, accepted_values in hints.items():
        if signals.get(signal_name) in accepted_values:
            count += 1
    return count


def cluster_by_signals(classifications: Iterable[dict]) -> list[dict]:
    """Group page classifications into clusters by signal tuple.

    Input
    -----
    classifications : iterable of dicts.  Each dict has keys:
        path           -- str, relative page path
        label          -- str, one of VALID_TYPES + 'unknown'
        confidence     -- str, 'high' | 'medium' | 'low' | 'unknown'
        signals        -- dict: {frontmatter, filename, heading, inbound, links}
                          in slug form (pascal/kebab/entity-like/inbound-heavy/etc.)
        inbound_count  -- int, optional; informational only

    Output
    ------
    list[dict] with keys:
        cluster_id      -- "cluster_1", "cluster_2", ... (1-indexed, stable
                           sort by signal tuple)
        page_count      -- int
        pages           -- sorted list of paths
        signals         -- {frontmatter, filename, heading, inbound, links}
        confidence      -- 'high' | 'medium' | 'low' | 'unknown'.  Promoted to
                           'high' at cluster level when the D-03 "3+ signals
                           agree OR explicit valid frontmatter type" gate is
                           satisfied even if individual-page confidence from
                           classify_page() was lower (classify_page uses an
                           older 4-signal gate; D-03 adds inbound density as a
                           fifth cluster-level signal).
        proposed_label  -- str (first member's label — all members share it
                           by construction).

    Rationale (RESEARCH Q1):
        - O(n) single pass; stdlib only; no scipy/numpy.
        - Deterministic: sort() over string-tuple keys avoids Python hash
          randomization issues.
        - Human-reviewable cluster descriptions ("kebab filenames + entity-
          like H1 + inbound-heavy") beat opaque similarity scores.

    Invariant:
        All members of a cluster share the exact same signal tuple by
        construction.  `proposed_label` is therefore identical across members
        — the function takes it from the first member (sorted path order).
    """
    # Materialize once (iterable may be single-pass).
    classes = list(classifications)
    buckets: dict[tuple, list[str]] = defaultdict(list)
    label_of: dict[tuple, str] = {}
    page_conf: dict[tuple, str] = {}

    for c in classes:
        s = c.get('signals') or {}
        key = (
            s.get('frontmatter', 'none') or 'none',
            s.get('filename', 'none') or 'none',
            s.get('heading', 'none') or 'none',
            s.get('inbound', 'inbound-light') or 'inbound-light',
            s.get('links', 'none') or 'none',
        )
        buckets[key].append(c.get('path', ''))
        if key not in label_of:
            label_of[key] = c.get('label', 'unknown') or 'unknown'
            page_conf[key] = c.get('confidence', 'unknown') or 'unknown'

    clusters = []
    for idx, (key, pages) in enumerate(sorted(buckets.items()), start=1):
        signals_dict = {
            'frontmatter': key[0],
            'filename': key[1],
            'heading': key[2],
            'inbound': key[3],
            'links': key[4],
        }
        label = label_of[key]
        # Cluster-level confidence promotion per D-03: explicit valid
        # frontmatter type OR 3+ non-frontmatter signals agree => 'high'.
        # Otherwise retain classify_page()'s per-page confidence.
        fm = signals_dict['frontmatter']
        if fm in _VALID_TYPE_ENUM:
            cluster_conf = 'high'
        elif _count_agreement(signals_dict, label) >= 3:
            cluster_conf = 'high'
        else:
            cluster_conf = page_conf[key]
        clusters.append({
            'cluster_id': f'cluster_{idx}',
            'page_count': len(pages),
            'pages': sorted(pages),
            'signals': signals_dict,
            'confidence': cluster_conf,
            'proposed_label': label,
        })
    return clusters


def cluster_is_autoapproveable(cluster: dict) -> bool:
    """Return True iff D-03's 'high confidence' gate is satisfied for this cluster.

    D-03 verbatim (CONTEXT.md): high confidence means '3+ signals agree OR
    explicit valid frontmatter type'.  Review item 7 widened this from the
    pre-review narrow frontmatter-only interpretation.

    Auto-approve iff ALL of:
      1. cluster['confidence'] == 'high'.
      2. EITHER signals.frontmatter is a valid type enum value (the explicit
         path), OR 3+ of the 5 non-frontmatter signals agree with the
         proposed_label via the _LABEL_HINTS table.

    Conservative default: return False if required keys are missing or
    proposed_label is 'unknown' (route to review queue).
    """
    if cluster.get('confidence') != 'high':
        return False
    signals = cluster.get('signals') or {}
    fm = signals.get('frontmatter', 'none')
    if fm in _VALID_TYPE_ENUM:
        return True  # explicit valid frontmatter type
    label = cluster.get('proposed_label')
    if not label or label == 'unknown':
        return False  # no target label to check agreement against
    return _count_agreement(signals, label) >= 3
