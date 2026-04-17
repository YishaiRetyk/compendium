"""ruamel.yaml round-trip helpers for brownfield bootstrap (Phase 10 Plan 03).

Encodes the D-02 typed-merge policy + D-14 empty-value sentinel set, with
comment/key-order preservation via ruamel.yaml's round-trip mode.

NO LLM CALLS.  Pure mechanical transforms (BRWN-16).

Exports:
  - FIELD_CLASS_A        — safe-additive field names (preserve existing; inject if absent).
  - FIELD_CLASS_B        — schema-authoritative field names (never overwrite; warn on noncanonical).
  - VALID_ENUMS          — enum value sets for Class-B validation.
  - DuplicateKeyError    — raised by pre-scan on detectable duplicate top-level YAML keys.
  - split_frontmatter()  — line-oriented parser; returns (yaml_block, body) or (None, text).
  - read_fm_body()       — read file; pre-flight parse; return (parsed_fm, body, raw_yaml_block).
  - merge_sentinels()    — apply D-02 typed-merge on a CommentedMap (not a plain dict!).
  - write_roundtrip()    — atomic write with ruamel round-trip.
  - build_d14_sentinel_set() — assemble D-14 sentinel dict for a given page.
  - infer_id_from_filename()  — filename → kebab-case id.
  - extract_h1()         — first `# ...` H1 from body, if any.
  - file_mtime_iso()     — file mtime as YYYY-MM-DD (UTC).
  - make_yaml()          — factory for a pre-configured ruamel.yaml.YAML instance.
"""
from __future__ import annotations

import datetime
import os
import re
import tempfile
from typing import Any

# Pre-flight parse guard (D-01).  PyYAML catches most lexical errors (tabs,
# malformed YAML) before we hand off to ruamel.yaml.  ruamel still emits its
# own richer error via DuplicateKeyError on detectable duplicate keys.
import yaml as pyyaml

try:
    from ruamel.yaml import YAML
    from ruamel.yaml.compat import StringIO
    from ruamel.yaml.comments import CommentedMap
    from ruamel.yaml.scalarstring import SingleQuotedScalarString
    from ruamel.yaml.error import YAMLError as RuamelYAMLError
except ImportError as exc:  # pragma: no cover — surfaced by bootstrap entrypoint
    raise ImportError(
        "ruamel.yaml is required for brownfield bootstrap. "
        "Install: pip install ruamel.yaml "
        "(see docs/reference/brownfield.md)."
    ) from exc


# D-02 Class A — safe-additive: preserve existing value, inject only where absent.
FIELD_CLASS_A: set[str] = {'tags', 'aliases', 'sources', 'status'}

# D-02 Class B — schema-authoritative: preserve existing value; NEVER overwrite.
# Noncanonical existing values are warned about but retained.  Semantic
# correction is `suggest`/`lint`'s job.
FIELD_CLASS_B: set[str] = {
    'type', 'epistemic_status', 'knowledge_domain', 'privacy', 'bootstrap_stage',
}

# Allowed enum values for Class-B validation.  An empty string in `type` is
# accepted because D-14 scaffolding for no-frontmatter pages writes ``type: ''``
# — Phase 11 `suggest/01-page-typing.sh` fills it in.  Same for knowledge_domain.
VALID_ENUMS: dict[str, set[str]] = {
    'type': {'entity', 'concept', 'source', 'comparison', 'overview', 'decision', ''},
    'epistemic_status': {'sourced', 'mixed', 'tentative', 'stale'},
    'knowledge_domain': {'software', 'science', 'biography', 'personal-goals', ''},
    'privacy': {'local_only', 'cloud_safe'},
    'bootstrap_stage': {'raw', 'bootstrapped', 'verified'},
    'status': {'active', 'stale', 'superseded', 'archived'},
}


class DuplicateKeyError(Exception):
    """Raised by split_frontmatter / read_fm_body when top-level YAML keys repeat.

    Duplicate keys are D-02 Class C (structural hard failure) — the page
    routes to SKIPPED.md, never mutated.  The human-readable message is
    intentionally terse so SKIPPED.md entries stay scannable.
    """


# ---------------------------------------------------------------------------
# Line-oriented frontmatter split (Codex review fix #1).
# Regex-based split (``^---\n(.*?)^---\n?``, DOTALL) is brittle because literal
# block scalars can contain ``---`` on a line and would split the block
# prematurely.  This implementation scans line-by-line and only treats a line
# whose STRIPPED content equals ``---`` as a delimiter.
# ---------------------------------------------------------------------------

def split_frontmatter(text: str) -> tuple[str | None, str]:
    """Split a markdown file into (yaml_block, body).

    - Opening ``---`` must be on line 1 (after an optional UTF-8 BOM).
    - Closing ``---`` is the next line whose STRIPPED content is exactly ``---``.
    - Text after the closing delimiter is the body (verbatim).

    Returns (None, text) if no frontmatter block is present.
    """
    # Strip a leading UTF-8 BOM if present (some editors emit one).
    if text.startswith('\ufeff'):
        text = text[1:]

    # Split preserving line terminators so we can rebuild the body faithfully.
    # We use splitlines(keepends=True) to keep \n / \r\n, then scan.
    lines = text.splitlines(keepends=True)
    if not lines:
        return None, text

    first = lines[0].rstrip('\r\n')
    if first.strip() != '---':
        return None, text

    # Scan for the closing delimiter.
    close_idx: int | None = None
    for i in range(1, len(lines)):
        if lines[i].rstrip('\r\n').strip() == '---':
            close_idx = i
            break
    if close_idx is None:
        # Malformed: opening delim without a closing one.  Treat as no frontmatter.
        return None, text

    yaml_lines = lines[1:close_idx]
    body_lines = lines[close_idx + 1:]

    yaml_block = ''.join(yaml_lines)
    body = ''.join(body_lines)
    return yaml_block, body


# Regex for duplicate-key pre-scan.  Matches top-level (no leading whitespace)
# YAML mapping keys.  We intentionally exclude indented lines because those
# are nested mapping keys where duplicates are legal (they belong to different
# parent mappings).  This catches the common Obsidian-vault mistake of a user
# accidentally writing two top-level ``type:`` lines.
TOP_LEVEL_KEY_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*:', re.MULTILINE)


def _pre_scan_duplicate_keys(yaml_block: str) -> None:
    """Raise DuplicateKeyError if any top-level key appears more than once.

    ruamel.yaml also detects duplicate keys natively, but the pre-scan gives
    us a terse, consistent message for SKIPPED.md regardless of ruamel version.
    """
    seen: dict[str, int] = {}
    # Strip comment-only lines so we don't mistake a commented key for a real one.
    for raw in yaml_block.splitlines():
        stripped = raw.lstrip()
        if stripped.startswith('#'):
            continue
        if raw != stripped:  # leading whitespace → nested; skip
            continue
        m = TOP_LEVEL_KEY_RE.match(raw)
        if m:
            key = m.group(1)
            seen[key] = seen.get(key, 0) + 1
    dups = [k for k, v in seen.items() if v > 1]
    if dups:
        # Stable first-found order.
        first = dups[0]
        raise DuplicateKeyError(f"duplicate YAML key '{first}' in frontmatter block")


def make_yaml() -> YAML:
    """Return a pre-configured ruamel.yaml.YAML(typ='rt') instance.

    Centralized so callers don't drift on rendering settings.  Key choices:
      - typ='rt' (round-trip) — preserves comments, key order, quoting.
      - preserve_quotes=True  — Dataview-friendly: keeps ``'value'`` as-is.
      - default_flow_style=False — explicit block-style by default; empty
        lists still render as ``[]`` because PyYAML/ruamel special-case them.
      - None representer → literal ``null`` — matches the D-14 sentinel
        rendering pinned by the fixture expected/ files.
    """
    y = YAML(typ='rt')
    y.preserve_quotes = True
    y.default_flow_style = False

    def _represent_none(self: Any, data: Any) -> Any:  # noqa: ARG001
        return self.represent_scalar('tag:yaml.org,2002:null', 'null')

    y.representer.add_representer(type(None), _represent_none)
    return y


def read_fm_body(path: str) -> tuple[CommentedMap | None, str, str | None]:
    """Read a markdown file and return (parsed_fm, body, raw_yaml_block).

    Returns (None, body, None) when the file has no frontmatter block.

    Raises:
      - DuplicateKeyError — detectable duplicate top-level YAML keys (D-02 Class C).
      - pyyaml.YAMLError / ruamel.yaml errors — parse failures (D-01).
      - OSError / UnicodeDecodeError — unreadable file.

    The two-stage parse (pyyaml pre-flight → ruamel round-trip) is deliberate:
    PyYAML's safe_load is a faster fail-gate, and its error messages are
    often terser for SKIPPED.md.  If safe_load succeeds, the ruamel parse
    rarely fails.
    """
    with open(path, 'r', encoding='utf-8') as fh:
        text = fh.read()

    yaml_block, body = split_frontmatter(text)
    if yaml_block is None:
        return None, body, None

    # Duplicate-key pre-scan (D-02 Class C structural hard failure).
    _pre_scan_duplicate_keys(yaml_block)

    # PyYAML pre-flight parse (D-01).  Any scanner/parser error is surfaced
    # verbatim to the caller for SKIPPED.md; bootstrap does NOT attempt repair.
    fm_preflight = pyyaml.safe_load(yaml_block)
    if fm_preflight is not None and not isinstance(fm_preflight, dict):
        # Non-mapping frontmatter → D-02 Class C.
        raise pyyaml.YAMLError("frontmatter is not a YAML mapping (D-02 Class C)")

    # ruamel.yaml round-trip parse preserves comments + key order for write.
    y = make_yaml()
    fm = y.load(yaml_block)
    if fm is None:
        # Empty frontmatter block (``---\n---\n``); treat like no-frontmatter.
        return None, body, yaml_block
    if not isinstance(fm, CommentedMap):
        raise RuamelYAMLError("frontmatter parsed but is not a mapping (D-02 Class C)")

    return fm, body, yaml_block


def infer_id_from_filename(path: str) -> str:
    """filename.md → kebab-cased id (stem lowercased, spaces → hyphens)."""
    stem = os.path.splitext(os.path.basename(path))[0]
    # Preserve case if already kebab / PascalCase so `page` → `page`, but spaces
    # and underscores turn into hyphens, and the whole thing lowercases.
    slug = re.sub(r'[\s_]+', '-', stem).lower()
    # Strip anything that isn't alnum or hyphen to be safe.
    slug = re.sub(r'[^a-z0-9-]+', '', slug)
    return slug or 'page'


H1_RE = re.compile(r'^#\s+(.+?)\s*$', re.MULTILINE)


def extract_h1(body: str) -> str | None:
    """Return the first H1 heading from a page body, or None if absent."""
    m = H1_RE.search(body or '')
    return m.group(1).strip() if m else None


def file_mtime_iso(path: str) -> datetime.date:
    """File mtime as a ``datetime.date`` for unquoted YAML date rendering.

    UTC per AGENTS.md §3 + Phase 3 D-11 precedent.
    """
    stat = os.stat(path)
    return datetime.datetime.fromtimestamp(stat.st_mtime, tz=datetime.timezone.utc).date()


def build_d14_sentinel_set(
    path: str,
    body: str,
    today: datetime.date,
) -> dict[str, Any]:
    """Assemble the D-14 sentinel dict for a single page.

    - Inferred (mechanical): id, title, created_at, updated_at.
    - Empty defaults (scaffolding):   type, summary, knowledge_domain, sources,
                                      tags, domains, aliases, supersedes, superseded_by.
    - Fixed defaults:                 status, epistemic_status, privacy, has_contradictions.
    - Brownfield-specific:            bootstrap_stage, bootstrap_date.

    Empty strings are wrapped in SingleQuotedScalarString so ruamel renders
    them as ``''`` (matches fixture expected/ shape).
    """
    inferred_id = infer_id_from_filename(path)
    h1 = extract_h1(body)
    inferred_title = h1 if h1 else inferred_id
    try:
        created_at = file_mtime_iso(path)
    except OSError:
        # New / unreadable mtime; fall back to today (never fails the bootstrap).
        created_at = datetime.date(today.year, today.month, today.day)

    # Create DISTINCT date instances — ruamel.yaml emits anchor/alias pairs
    # (``&id001`` / ``*id001``) when the same Python object appears at multiple
    # positions in the mapping.  Fresh instances produce clean bare dates.
    updated_at = datetime.date(today.year, today.month, today.day)
    bootstrap_date = datetime.date(today.year, today.month, today.day)

    return {
        # Inferred (mechanical).
        'id': inferred_id,
        'title': inferred_title,
        'created_at': created_at,
        'updated_at': updated_at,
        # Empty defaults — scaffolding, NOT interpretation (D-14 rule).
        'type': SingleQuotedScalarString(''),
        'summary': SingleQuotedScalarString(''),
        'knowledge_domain': SingleQuotedScalarString(''),
        'sources': [],
        'tags': [],
        'domains': [],
        'aliases': [],
        'supersedes': None,
        'superseded_by': None,
        # Fixed defaults.
        'status': 'active',
        'epistemic_status': 'tentative',
        'privacy': 'local_only',
        'has_contradictions': False,
        # Brownfield-specific.
        'bootstrap_stage': 'bootstrapped',
        'bootstrap_date': bootstrap_date,
    }


def merge_sentinels(
    existing_fm: CommentedMap | None,
    sentinel_set: dict[str, Any],
    file_path: str,
) -> tuple[CommentedMap, list[dict[str, Any]], list[dict[str, Any]]]:
    """Apply the D-02 typed-merge policy and return (merged, class_a_collisions, class_b_warnings).

    - No-frontmatter case (``existing_fm is None``): return a fresh
      CommentedMap built from sentinel_set (preserves insertion order → D-14
      canonical field layout).
    - Otherwise: iterate sentinel_set in insertion order, preserving the
      existing map's key order for keys it already has.  Keys absent from the
      existing map are appended in sentinel_set order.

    Collision policy:
      - Class A field WITH non-empty existing value → record collision; PRESERVE.
      - Class A field with empty value (``''``, ``[]``, ``None``) → inject sentinel.
      - Class B field with existing value → validate against VALID_ENUMS.  If
        invalid, record a schema-warning.  PRESERVE in BOTH cases (never
        overwrite Class B per D-02).
      - Class B field missing → inject sentinel.
      - Other fields (base scaffolding) → inject only if absent.

    CRITICAL: returns a CommentedMap, not a plain dict — comment placement and
    key ordering must survive the round-trip back to disk.
    """
    class_a_collisions: list[dict[str, Any]] = []
    class_b_warnings: list[dict[str, Any]] = []

    if existing_fm is None:
        merged: CommentedMap = CommentedMap()
        for k, v in sentinel_set.items():
            merged[k] = v
        return merged, class_a_collisions, class_b_warnings

    merged = existing_fm  # Work in-place; the caller owns the reference.

    for field, sentinel_value in sentinel_set.items():
        present = field in merged
        existing_value = merged.get(field)

        if field in FIELD_CLASS_A:
            # Safe-additive: preserve non-empty existing; inject sentinel if
            # absent or "empty" (treat ``''``, ``[]``, ``None`` as empty).
            if present and _is_nonempty(existing_value):
                class_a_collisions.append({
                    'path': file_path,
                    'field': field,
                    'existing_value': existing_value,
                    'sentinel_value': sentinel_value,
                })
                continue
            merged[field] = sentinel_value
            continue

        if field in FIELD_CLASS_B:
            if present:
                # Never overwrite Class B.  Validate and warn if noncanonical.
                allowed = VALID_ENUMS.get(field)
                if allowed is not None and existing_value not in allowed:
                    class_b_warnings.append({
                        'path': file_path,
                        'field': field,
                        'value': existing_value,
                        'reason': 'noncanonical enum value; lint/suggest will triage',
                    })
                continue
            merged[field] = sentinel_value
            continue

        # Base-field scaffolding — inject only if absent.
        if not present:
            merged[field] = sentinel_value

    return merged, class_a_collisions, class_b_warnings


def _is_nonempty(value: Any) -> bool:
    """Treat ``''``, ``[]``, ``{}``, and ``None`` as empty for Class-A merge."""
    if value is None:
        return False
    if isinstance(value, str) and value == '':
        return False
    if isinstance(value, (list, dict, tuple, set)) and len(value) == 0:
        return False
    return True


def write_roundtrip(
    path: str,
    fm: CommentedMap,
    body: str,
    raw_yaml_block: str | None = None,  # noqa: ARG001 — kept for API compatibility
) -> None:
    """Atomically write ``path`` with ``---\\n<yaml>\\n---\\n<body>``.

    Uses ruamel.yaml round-trip to preserve comments, key order, and quoting.
    LF-normalized on write (D-03); CRLF inputs become LF outputs because
    ruamel always emits LF regardless of the input file's EOL shape.
    Atomic: writes to a tmp file in the same directory, then ``os.rename``.
    """
    y = make_yaml()
    buf = StringIO()
    y.dump(fm, buf)
    yaml_out = buf.getvalue()
    # ruamel always terminates its output with a newline; ensure no extra.
    if not yaml_out.endswith('\n'):
        yaml_out += '\n'

    # Normalize body to always start with a newline so ``---\n<body>`` reads
    # as ``---\n\n<body>`` (fixture convention: one blank line between the
    # closing frontmatter delimiter and the body content).  This matters for
    # the no-frontmatter case where the original file content starts with
    # ``# H1`` — without this, the output would run ``---\n# H1`` together.
    # Existing-frontmatter pages already have a leading ``\n`` from
    # split_frontmatter so this is a no-op for them.
    if body and not body.startswith('\n'):
        body = '\n' + body

    out = f"---\n{yaml_out}---\n{body}"

    # Atomic replacement: tmp file → rename.
    target_dir = os.path.dirname(os.path.abspath(path)) or '.'
    fd, tmp_path = tempfile.mkstemp(prefix='.brownfield-write-', dir=target_dir)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(out)
        os.replace(tmp_path, path)
    except Exception:
        # Best-effort cleanup of the tmp file on any write error.
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


__all__ = [
    'FIELD_CLASS_A',
    'FIELD_CLASS_B',
    'VALID_ENUMS',
    'DuplicateKeyError',
    'split_frontmatter',
    'read_fm_body',
    'merge_sentinels',
    'write_roundtrip',
    'build_d14_sentinel_set',
    'infer_id_from_filename',
    'extract_h1',
    'file_mtime_iso',
    'make_yaml',
]
