"""Wiki-page primitives — the ONE canonical copy (Phase 24 Plan 02, PKG-02).

Extracted verbatim from the AUTHORITATIVE copy in the bin/lint.sh python3 heredoc
(LINT_VERSION 1.12.0 at extraction, 2026-07-03), plus the in-memory
parse_frontmatter_str variant from bin/audit-claims.sh. This retires the
lint<->audit-claims byte-copy: Phase-25 ports import from here instead of
duplicating these primitives. Regex strings and error messages are preserved
character-for-character (behavior parity bar). The lint.sh/audit-claims.sh
heredocs keep their inline copies until the Phase-25 MIG-02 port (lift, never
move); tests/test_common_extraction.py asserts source-identity with lint.sh.
"""

import re

import yaml

__all__ = [
    'parse_frontmatter',
    'parse_frontmatter_str',
    'mask_markdown',
    'PROV_RE',
    'EPISTEMIC_INLINE_RE',
    'WIKILINK_RE',
    'PIPED_LINK_RE',
    'BARE_LINK_RE',
    'EXCLUDE_FILES',
    'EXCLUDE_DIRS',
]

WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

# Distinguishing regexes: used by linkres scan (Step C) AND orphan inbound scan (Step D).
# BARE_LINK_RE: matches bare [[target]] (no pipe). Note: BARE_LINK_RE naively also matches
# the target side of a piped link; caller must subtract piped spans (see _in_piped helper).
PIPED_LINK_RE = re.compile(r'\[\[([^\]|]+)\|([^\]]+)\]\]')  # (target, display)
BARE_LINK_RE  = re.compile(r'\[\[([^\]|\n]+)\]\]')           # bare target, no pipe

_FENCE_OPEN_RE = re.compile(r'(`{3,}|~{3,})')
_HTMLCOM_RE = re.compile(r'<!--.*?-->', re.DOTALL)
_INLINE_RE  = re.compile(r'`[^`\n]*`')
_FM_RE      = re.compile(r'\A---\n.*?\n---\n', re.DOTALL)

def _mask_fences(text):
    """Length-preserving blank-out of fenced code blocks, line-based per the
    CommonMark rules the masker cares about (Phase 14 review WR-02/WR-03):
    an opening fence is a column-0 run of >=3 backticks or tildes (info string
    allowed after it); the block closes ONLY at a column-0 run of the SAME
    char, at least opener-length long, followed by nothing but spaces/tabs --
    an info string on a would-be closer means the line does NOT close (WR-03);
    an unclosed fence extends to end-of-file (WR-02). Column-0 anchoring
    (no 0-3 space indent tolerance) deliberately matches the prior behavior."""
    out = []
    fence_char = None
    fence_len = 0
    for line in text.split('\n'):
        if fence_char is None:
            m = _FENCE_OPEN_RE.match(line)
            if m:
                fence_char = m.group(1)[0]
                fence_len = len(m.group(1))
                out.append(' ' * len(line))
            else:
                out.append(line)
        else:
            stripped = line.rstrip(' \t')
            if stripped and set(stripped) == {fence_char} and len(stripped) >= fence_len:
                fence_char = None
            out.append(' ' * len(line))
    return '\n'.join(out)

def mask_markdown(text):
    """Return a length-preserving copy of `text` with YAML frontmatter, fenced code,
    HTML comments, and inline code replaced by spaces (newlines kept). Offsets are
    preserved so positional --fix can map masked-match spans back to the real content.
    Order matters: frontmatter and fences first (they may contain <!-- / backticks),
    then HTML comments, then inline code."""
    def _blank(m):
        return ''.join('\n' if c == '\n' else ' ' for c in m.group(0))
    masked = _FM_RE.sub(_blank, text)
    masked = _mask_fences(masked)
    masked = _HTMLCOM_RE.sub(_blank, masked)
    masked = _INLINE_RE.sub(_blank, masked)
    return masked

PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')

# Files to exclude from lint candidate list
EXCLUDE_FILES = {'index.md', 'log.md'}
EXCLUDE_DIRS = {'maintenance', 'examples'}

def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page."""
    try:
        content = open(filepath, encoding='utf-8').read()
    except Exception as e:
        return None, '', str(e)
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'

def parse_frontmatter_str(content):
    """Like parse_frontmatter but over an in-memory string (the raw source text
    already read by read_raw_source). Returns (fm|None, body, error). fm is None
    when the text has no leading --- fence (no new file open -> no new egress)."""
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        if not isinstance(fm, dict):
            fm = None
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'
