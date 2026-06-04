"""Phase 15 structural privacy resolver for bin/audit-claims.sh.

NO LLM CALLS. NO NETWORK EGRESS. Pure mechanical path-prefix predicate.

Phase 15 COLLAPSE: The §13 three-level fail-closed precedence ladder and the
per-page `privacy` frontmatter field are GONE. Privacy is now structural --
determined entirely by which directory tier a page lives under.

Raw-source structural rule (Phase 15, cycle-2 HIGH):
  `sources/` is cloud-safe-only. A source that must be local lives as its
  source-summary page under `wiki-local/sources/`. The resolver keys off
  the SUMMARY PAGE PATH (not the raw sources/ path -- raw sources/ is
  cloud-safe-only by structural rule enforced by bin/check-sources-cloud-safe.sh).

FAITH-04 contract (D-02 lockstep):
  A claim is effective-local_only iff its claim-page OR any contributing
  source-summary lives under wiki-local/. This is the SINGLE structural predicate
  that replaced the previous multi-level stricter-wins ladder.

Consumed by:
  - bin/audit-claims.sh (Phase 13 FAITH-04 chokepoint, re-keyed Phase 15)

Exports (STABLE NAMES -- callers must not change import statements):
  - resolve_source_privacy(summary_rel_path) -> 'local_only'|'cloud_safe'
        Structural predicate: summary_rel_path under wiki-local/ -> local_only.
        summary_rel_path is the SUMMARY PAGE path (not the raw sources/ path).
  - resolve_effective_claim_privacy(page_fm, page_path, source_fm,
        raw_source_fm, source_summary_path) -> 'local_only'|'cloud_safe'
        FAITH-04 predicate: local_only iff page_path OR source_summary_path
        is under wiki-local/.

See CLAUDE.md §13 (Privacy Routing -- asymmetric two-dir model) for the
structural rule this implements.
"""

_WIKI_LOCAL_PREFIX = 'wiki-local/'


def _is_local(path):
    """Return True iff the path lives under the local-only tier."""
    if not path:
        return False
    # Normalise: strip leading './' or '/' so relative paths compare cleanly
    p = str(path).lstrip('./')
    return p.startswith(_WIKI_LOCAL_PREFIX) or ('/' + _WIKI_LOCAL_PREFIX) in ('/' + p)


def resolve_source_privacy(summary_rel_path):
    """Structural predicate: returns 'local_only' iff the source SUMMARY page
    lives under wiki-local/; else 'cloud_safe'.

    summary_rel_path MUST be the repo-relative path of the SOURCE SUMMARY PAGE
    (e.g. 'wiki-local/sources/src-2026-04-10-personal.md' or
    'wiki-cloud/sources/src-2026-03-15-vaswani.md'). Do NOT pass the raw
    sources/ path here -- raw sources/ is cloud-safe-only by structural rule.
    """
    return 'local_only' if _is_local(summary_rel_path) else 'cloud_safe'


def resolve_effective_claim_privacy(page_fm, page_path, source_fm,
                                    raw_source_fm, source_summary_path):
    """FAITH-04 effective-claim privacy predicate (Phase 15 collapse).

    A claim is effective-local_only iff:
      (a) the wiki page that owns the claim lives under wiki-local/, OR
      (b) any contributing source-summary page lives under wiki-local/.

    Parameters
    ----------
    page_fm : dict or None
        Frontmatter of the claim-owning wiki page. IGNORED (field removed).
    page_path : str or None
        Repo-relative path of the claim-owning wiki page. The structural
        predicate keys off this path.
    source_fm : dict or None
        Frontmatter of the source-summary page. IGNORED (field removed).
    raw_source_fm : dict or None
        Frontmatter of the raw source file. IGNORED (sources/ is cloud-safe-only).
    source_summary_path : str or None
        Repo-relative path of the SOURCE SUMMARY page (not the raw sources/ path).
        The structural predicate keys off this path.

    Returns
    -------
    'local_only' | 'cloud_safe'
    """
    # (a) Claim page is under wiki-local/
    if _is_local(page_path):
        return 'local_only'
    # (b) Source-summary is under wiki-local/
    if _is_local(source_summary_path):
        return 'local_only'
    # Both are cloud-safe tier
    return 'cloud_safe'
