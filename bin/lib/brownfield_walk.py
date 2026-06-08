"""Shared vault-walk helper honoring .brownfield-ignore + hardcoded excludes.

Consumed by:
  - bin/brownfield.sh scan branch (Phase 10 — refactored to import from here)
  - bin/brownfield.sh suggest branch (Phase 11 Plan 11-02)

Per REVIEWS item 3 contract: do NOT fork this logic.  The single source of
truth for brownfield-scope vault walking lives in this module so scan and
suggest cannot drift.

Semantics (mirrors Phase 10 scan's inline walker):
  - os.walk(root, followlinks=False) prevents symlink escape.
  - Hardcoded exclusion set (.obsidian, .trash, templates, attachments,
    .brownfield, .git) is always pruned before descent.
  - .brownfield-ignore at <root>/.brownfield-ignore uses a gitignore-like
    subset: blank lines + '#' comments + '!' negation + '*' / '**' globs.
  - Negation ('!pattern') un-excludes directories or files that would
    otherwise be pruned — including entries in the hardcoded denylist.
  - Daily-note pattern (YYYY-MM-DD.md at root or under daily/ journal/)
    is excluded by default unless negated.  NOTE: this is NOT enforced in
    this walker — callers that need daily-note exclusion apply it in
    their per-file loop.  Scan does this; suggest does NOT (suggest only
    cares about bootstrapped pages, and daily notes are unlikely to carry
    bootstrap_stage).
"""
import os
import re
from typing import Iterator


# Always-excluded directory basenames — D-19 + Phase 10 parity.
HARDCODED_EXCLUDES = {
    '.obsidian',
    '.trash',
    'templates',
    'attachments',
    '.brownfield',
    '.git',
}


# ---------------------------------------------------------------------------
# .brownfield-ignore parser (gitignore-like subset, regex-based).
# Cloned VERBATIM from bin/brownfield.sh scan branch so behavior is byte-
# identical — see also the scan branch below which imports these helpers.
# ---------------------------------------------------------------------------

def _translate_pattern_to_regex(pat: str) -> re.Pattern:
    """Convert a gitignore-like subset glob to a regex.

    Handles '**' (match anything including '/'), '*' (match anything except
    '/'), and literal characters.  Anchored at the start; allows optional
    trailing '/...' so 'attachments' matches both 'attachments' and
    'attachments/diagram.md'.
    """
    if pat.startswith('/'):
        pat = pat[1:]
    had_trailing_slash = pat.endswith('/')
    if had_trailing_slash:
        pat = pat[:-1]

    out: list[str] = ['^']
    i = 0
    while i < len(pat):
        c = pat[i]
        if c == '*':
            if i + 1 < len(pat) and pat[i + 1] == '*':
                out.append('.*')
                i += 2
                if i < len(pat) and pat[i] == '/':
                    i += 1
                continue
            out.append('[^/]*')
            i += 1
        elif c == '?':
            out.append('[^/]')
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    out.append(r'(?:/.*)?$')
    return re.compile(''.join(out))


def load_brownfield_ignore(root: str) -> tuple[list[re.Pattern], list[re.Pattern]]:
    """Load <root>/.brownfield-ignore if present.

    Returns (exclude_patterns, negate_patterns) as lists of compiled regexes.
    """
    path = os.path.join(root, '.brownfield-ignore')
    exclude: list[re.Pattern] = []
    negate: list[re.Pattern] = []
    if not os.path.isfile(path):
        return exclude, negate
    with open(path, 'r', encoding='utf-8') as fh:
        for raw in fh:
            line = raw.strip()
            if not line or line.startswith('#'):
                continue
            if line.startswith('!'):
                body = line[1:].strip()
                if body:
                    negate.append(_translate_pattern_to_regex(body))
            else:
                exclude.append(_translate_pattern_to_regex(line))
    return exclude, negate


def any_match(patterns: list[re.Pattern], rel: str) -> bool:
    """Return True if rel matches any of the patterns."""
    for pat in patterns:
        if pat.match(rel):
            return True
    return False


def walk_vault_respecting_ignore(
    root: str,
    extra_ignores: list[str] | None = None,
) -> Iterator[str]:
    """Yield absolute paths of .md files under root, honoring exclusions.

    Exclusion order:
      1. HARDCODED_EXCLUDES (dir basenames).
      2. <root>/.brownfield-ignore exclude patterns (dir + file).
      3. extra_ignores (caller-provided; dir + file).

    Negation ('!pattern' in .brownfield-ignore) un-excludes matches at any
    level above.

    This helper intentionally does NOT apply the daily-note exclusion —
    callers that need it must filter yielded paths themselves (scan does,
    suggest doesn't need to).
    """
    bf_exclude, bf_negate = load_brownfield_ignore(root)
    extra_patterns = [_translate_pattern_to_regex(p) for p in (extra_ignores or [])]
    all_excludes = bf_exclude + extra_patterns

    root_abs = os.path.abspath(root)
    for dirpath, dirnames, filenames in os.walk(root_abs, followlinks=False):
        rel_dir = os.path.relpath(dirpath, root_abs)
        if rel_dir == '.':
            rel_dir = ''

        # Prune dirnames in-place so os.walk doesn't descend into excluded
        # trees.  Negation checked against bf_negate so users can re-enable
        # directories in the hardcoded list.
        keep = []
        for d in dirnames:
            rel_sub = os.path.join(rel_dir, d) if rel_dir else d
            rel_sub_norm = rel_sub.replace(os.sep, '/')
            if d in HARDCODED_EXCLUDES:
                if any_match(bf_negate, rel_sub_norm):
                    keep.append(d)
                    continue
                continue
            if any_match(all_excludes, rel_sub_norm) and not any_match(bf_negate, rel_sub_norm):
                continue
            keep.append(d)
        dirnames[:] = keep

        for fname in filenames:
            if not fname.endswith('.md'):
                continue
            rel = os.path.join(rel_dir, fname) if rel_dir else fname
            rel_norm = rel.replace(os.sep, '/')
            if any_match(all_excludes, rel_norm) and not any_match(bf_negate, rel_norm):
                continue
            yield os.path.join(dirpath, fname)
