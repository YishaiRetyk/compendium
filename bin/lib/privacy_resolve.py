"""§13 Privacy Routing resolver for bin/audit-claims.sh (Phase 13).

NO LLM CALLS. NO NETWORK EGRESS. Pure mechanical §13 precedence.

This is the FIRST mechanical implementation of the AGENTS.md/CLAUDE.md §13
three-level privacy precedence in the repo (bin/check-privacy.sh only greps
PUBLIC_PATHS for leaks; it has no dir-default / stricter-wins / fail-closed
logic). Both functions are pure: no file I/O, no subprocess, no network, no
imports beyond stdlib. Frontmatter (claim page, source summary, raw source)
arrives ALREADY-PARSED from the caller.

Consumed by:
  - bin/audit-claims.sh (Plan 13-03 privacy chokepoint, gated BEFORE any egress)

Exports:
  - resolve_source_privacy(source_fm, source_path) -> 'local_only'|'cloud_safe'
        §13 three-level precedence: explicit frontmatter `privacy` wins if a
        valid enum; else enclosing-dir signal (`/local-only/`, `/cloud-safe/`);
        else system default `local_only`. Stricter wins when both signals are
        present; unknown -> `local_only` (fail-closed, §13 Decision Table row 6).
  - resolve_effective_claim_privacy(page_fm, page_path, source_fm,
        raw_source_fm, source_path) -> 'local_only'|'cloud_safe'
        REVIEW HIGH-A (Cycle 2): FAITH-04 governs local_only CLAIMS, not only
        local_only source passages. Folds the STRICTEST of {claim-page privacy,
        source-summary privacy, raw-source privacy, enclosing-dir signal,
        fail-closed default}. A single local_only on ANY input forces
        local_only. This is the function the audit worklist partition gates on
        -- NOT resolve_source_privacy alone.

See CLAUDE.md §13 (Privacy Routing -- three-level precedence, stricter-wins,
fail-closed default) for the precedence spec this implements verbatim.
"""

_VALID = ('local_only', 'cloud_safe')


def resolve_source_privacy(source_fm, source_path):
    """§13 three-level precedence, fail-closed. Returns 'local_only'|'cloud_safe'.

    1. Explicit frontmatter `privacy` wins if it is a valid enum value.
    2. Else the enclosing-dir signal (`/local-only/` or `local-only/` prefix ->
       local_only; `/cloud-safe/` -> cloud_safe).
    3. Else system default `local_only` (fail-closed, §13 row 6).
    When BOTH an explicit and a dir signal exist, the stricter (local_only) wins.
    Any unknown/missing value resolves to local_only.
    """
    fm_priv = (source_fm or {}).get('privacy')
    explicit = fm_priv if fm_priv in _VALID else None

    path = source_path or ''
    dir_priv = None
    if '/local-only/' in path or path.startswith('local-only/'):
        dir_priv = 'local_only'
    elif '/cloud-safe/' in path:
        dir_priv = 'cloud_safe'

    candidates = [p for p in (explicit, dir_priv) if p]
    if not candidates:
        return 'local_only'  # fail-closed default (§13 row 6)
    # stricter wins: any local_only forces local_only
    return 'local_only' if 'local_only' in candidates else 'cloud_safe'


def resolve_effective_claim_privacy(page_fm, page_path, source_fm,
                                    raw_source_fm, source_path):
    """Strictest-wins effective-claim privacy (REVIEW HIGH-A).

    Folds the STRICTEST of every privacy signal touching this claim:
      (1) the wiki page that OWNS the claim (its frontmatter + its own dir),
      (2) the source summary page (its frontmatter + the raw-source path dir),
      (3) the RAW source file's own frontmatter (REVIEW MEDIUM -- was ignored).
    Any local_only among them forces local_only; resolve_source_privacy already
    fail-closes unknowns. raw_source_fm may be None (raw file has no frontmatter)
    -- then only the page + summary signals apply, still fail-closed.

    Returns 'local_only'|'cloud_safe'.
    """
    signals = []
    # (1) the wiki page that owns the claim -- its frontmatter privacy + its dir
    signals.append(resolve_source_privacy(page_fm, page_path))
    # (2) the source summary page's privacy + the raw-source path dir signal
    signals.append(resolve_source_privacy(source_fm, source_path))
    # (3) the RAW source file's own frontmatter privacy, when present
    if raw_source_fm is not None:
        signals.append(resolve_source_privacy(raw_source_fm, source_path))
    # stricter wins; any local_only -> local_only
    return 'local_only' if 'local_only' in signals else 'cloud_safe'
