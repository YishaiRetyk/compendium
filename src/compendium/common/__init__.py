"""compendium.common — the frozen single-source-of-truth core (Phase 24, PKG-02, D-08).

Verbatim lifts of the five bin/lib modules (privacy resolver, YAML round-trip incl. the
make_yaml byte-exact chokepoint, vault walker, classifier, provenance section-scan) plus
page.py (the wiki-page primitives extracted from the authoritative bin/lint.sh heredoc,
retiring the lint<->audit-claims byte-copy). Phase-25 ports READ this package
(`from compendium.common import ...`) and never WRITE it (D-08; deliberate additions go
through the D-09 ownership-rebase escape hatch).

D-09 rebase (2026-07-03, Phase 25 review — finding C1): the yaml_rt re-exports are LAZY
(PEP 562 module `__getattr__`). yaml_rt is the ONLY ruamel.yaml consumer; importing the
lightweight tools (lint / audit-claims / checkers, which touch only common.page and
common.privacy) must NOT transitively require ruamel. ruamel is a brownfield-only
dependency (docs/quickstart.md: "Not needed for greenfield users"), yet the pre-commit
hook runs bin/lint.sh on EVERY commit — an eager `from .yaml_rt import ...` here blocked
every greenfield commit with a "brownfield bootstrap" ImportError. The public API is
unchanged: `from compendium.common import make_yaml` still resolves (via __getattr__,
which imports yaml_rt on first access); only the import TIMING moved.
"""

from .privacy import resolve_source_privacy, resolve_effective_claim_privacy
from .walk import walk_vault_respecting_ignore, load_brownfield_ignore, any_match
from .classify import classify_page, unknown_reason
from .provenance import section_scan
from .page import (
    parse_frontmatter,
    parse_frontmatter_str,
    mask_markdown,
    PROV_RE,
    EPISTEMIC_INLINE_RE,
    WIKILINK_RE,
    PIPED_LINK_RE,
    BARE_LINK_RE,
    EXCLUDE_FILES,
    EXCLUDE_DIRS,
)

# yaml_rt (the sole ruamel.yaml consumer) is re-exported LAZILY — see the module docstring.
_YAML_RT_EXPORTS = frozenset({
    "make_yaml",
    "split_frontmatter",
    "read_fm_body",
    "write_roundtrip",
    "merge_sentinels",
    "build_d14_sentinel_set",
    "infer_id_from_filename",
    "extract_h1",
    "file_mtime_iso",
    "DuplicateKeyError",
    "FIELD_CLASS_A",
    "FIELD_CLASS_B",
    "VALID_ENUMS",
})


def __getattr__(name):  # PEP 562 — deferred yaml_rt (ruamel) import
    if name in _YAML_RT_EXPORTS:
        from . import yaml_rt
        return getattr(yaml_rt, name)
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def __dir__():
    return sorted(set(globals()) | _YAML_RT_EXPORTS)
