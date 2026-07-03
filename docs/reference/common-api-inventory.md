# `compendium.common` API Inventory (Phase 24 Plan 02 — "over-extract to completion" evidence)

> Demonstrates PKG-02 completeness: every module's stable public API, plus every OTHER place a
> shared-looking privacy/frontmatter primitive appears — each classified as a Phase-25 switch
> target or an intentionally distinct implementation with rationale. Tooling reference; uses
> abstract placeholders only.

## 1. The frozen modules and their stable public APIs

| Module | Lifted from | Stable public names |
|--------|-------------|---------------------|
| `common/privacy.py` | `bin/lib/privacy_resolve.py` (verbatim) | `resolve_source_privacy`, `resolve_effective_claim_privacy`, `_is_local` (fail-closed `wiki-local/` predicate) |
| `common/yaml_rt.py` | `bin/lib/brownfield_yaml.py` (verbatim) | `make_yaml` (the byte-exact canonicalization chokepoint), `split_frontmatter`, `read_fm_body`, `write_roundtrip`, `merge_sentinels`, `build_d14_sentinel_set`, `infer_id_from_filename`, `extract_h1`, `file_mtime_iso`, `DuplicateKeyError`, `FIELD_CLASS_A`, `FIELD_CLASS_B`, `VALID_ENUMS` |
| `common/walk.py` | `bin/lib/brownfield_walk.py` (verbatim) | `walk_vault_respecting_ignore`, `load_brownfield_ignore`, `any_match` (+ module-level `HARDCODED_EXCLUDES`) |
| `common/classify.py` | `bin/lib/brownfield_classify.py` (verbatim) | `classify_page`, `unknown_reason` (+ `cluster_by_signals`, `cluster_is_autoapproveable` at module level) |
| `common/provenance.py` | `bin/lib/brownfield_provenance.py` (verbatim) | `section_scan` (+ eligibility helpers per its `__all__`) |
| `common/page.py` | `bin/lint.sh` heredoc (authoritative copy) + the in-memory variant from `bin/audit-claims.sh` | `parse_frontmatter`, `parse_frontmatter_str`, `mask_markdown` (+ `_mask_fences`/`_FENCE_OPEN_RE` internals), `PROV_RE`, `EPISTEMIC_INLINE_RE`, `WIKILINK_RE`, `PIPED_LINK_RE`, `BARE_LINK_RE`, `EXCLUDE_FILES`, `EXCLUDE_DIRS` |

`bin/lib/*.py` stays in place (lift, never move): the bash heredocs still import it until the
Phase-25 ports switch to `compendium.common`.

## 2. Shared-looking primitives NOT folded in Phase 24 — classification

| Location | What it is | Classification |
|----------|------------|----------------|
| `bin/audit-claims.sh` inline `PROV_RE` / `EPISTEMIC_INLINE_RE` / `WIKILINK_RE` / `parse_frontmatter` / `parse_frontmatter_str` | The known "(COPIED from lint.sh)" byte-copy | **(a) Phase-25 switch target** (MIG-02 imports `common.page`); byte-identity with lint.sh is gated by `tests/test_common_extraction.py::test_0` |
| `bin/audit-claims.sh` `_fence_mask_lines` | Same CommonMark fence rules as lint's `_mask_fences` but a deliberately different API: returns `(lines, fenced-flags)` for boundary-scanning resolvers, vs the length-preserving text mask | **(b) intentionally distinct in Phase 24** (behavior-parity bar forbids unifying now); MIG-02 consolidation candidate onto `common.page` internals |
| `bin/audit-claims.sh` page-walk + source-registry block ("COPIED from lint.sh page walk classifier") | A second lint-derived copy beyond the 4 named symbols | **(a) Phase-25 switch target** (MIG-02) — inventoried so the port retires it too |
| `bin/validate-op.sh` `validate_frontmatter()` heredoc | Its own frontmatter parse with CHECK-ORIENTED semantics: prints `FAIL:` lines per finding and exits per-check (`Unterminated frontmatter` shares the error STRING, not the function shape); provenance extraction is a bash `grep -oP` pipeline, not `PROV_RE` | **(b) intentionally distinct**: validator output contract (PASS/FAIL lines, exit 1) is a user-facing format the parity bar freezes; MIG-05 may reuse `common.page` internally ONLY if the emitted bytes stay identical |
| `bin/check-neutrality.sh` `parse_frontmatter_block()` | Returns the RAW frontmatter string (no YAML load) — used only for the `neutrality_exempt: true` probe | **(b) intentionally distinct**: not a YAML parse; loading YAML here would change failure behavior on malformed files |
| `bin/check-privacy.sh` | Pure PATH-substring scan for the local-tier prefix in public surfaces; no frontmatter/YAML at all | **(b) intentionally distinct**: different predicate class (path leak, not tier resolution); does not belong in `common.privacy` |
| `bin/check-sources-cloud-safe.sh` | Directory-placement checks; messages mention the local tier but no shared parsing logic | **(b) intentionally distinct** (no primitive to extract) |
| `bin/brownfield.sh` `parse_frontmatter(text)` (heredoc, ~:2089) | An in-memory 2-tuple `(fm, body)` variant predating `common.page.parse_frontmatter_str` (3-tuple) | **(a) Phase-25 switch target** (MIG-01) — the port adopts `common.page.parse_frontmatter_str` ONLY if output bytes hold, else keeps a module-local shim; inventoried either way |
| `bin/lint.sh` Check 10g external-drift helpers (`--network`, Phase 23) | lint-only network checks | **(b) lint-internal** — not shared, no extraction |

## 3. Freeze posture

`src/compendium/common/**` is FROZEN after Phase 24 (D-08). Phase-25 plans import it read-only;
a genuine gap goes through the D-09 ownership-rebase escape hatch (one plan lands the addition +
bumps the baseline; others rebase and re-verify parity).
