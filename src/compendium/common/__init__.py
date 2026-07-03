"""compendium.common — the frozen single-source-of-truth core (Phase 24, PKG-02, D-08).

Verbatim lifts of the five bin/lib modules (privacy resolver, YAML round-trip incl. the
make_yaml byte-exact chokepoint, vault walker, classifier, provenance section-scan) plus
page.py (the wiki-page primitives extracted from the authoritative bin/lint.sh heredoc,
retiring the lint<->audit-claims byte-copy). Phase-25 ports READ this package
(`from compendium.common import ...`) and never WRITE it (D-08; deliberate additions go
through the D-09 ownership-rebase escape hatch).
"""

from .yaml_rt import (
    make_yaml,
    split_frontmatter,
    read_fm_body,
    write_roundtrip,
    merge_sentinels,
    build_d14_sentinel_set,
    infer_id_from_filename,
    extract_h1,
    file_mtime_iso,
    DuplicateKeyError,
    FIELD_CLASS_A,
    FIELD_CLASS_B,
    VALID_ENUMS,
)
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
