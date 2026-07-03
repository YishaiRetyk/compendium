# 25-06 SUMMARY — lint + audit-claims port (MIG-02, the long pole)

**Status:** Complete (2026-07-04)

## What shipped

- `src/compendium/lint.py` (2,887 lines, LINT_VERSION 1.12.0) + `audit_claims.py`
  (1,266 lines): the pair ported TOGETHER onto `compendium.common.page` — **the
  lint↔audit byte-copy is retired** (zero re-declared common.page symbols in either
  module, grep-verified; `_FENCE_OPEN_RE` imported, not re-declared).
- Audit-side intentional differences preserved per RB-3: `_fence_mask_lines` (distinct
  (lines, flags) API) ported INTO audit_claims.py; `parse_frontmatter_str` via common;
  the page-walk byte-compare verdict was **divergent — kept separate** (audit walks
  BOTH tiers with a registry keyed for FAITH-04; lint walks wiki_dir only) — documented
  in the module docstring, NOT unified (parity bar).
- Contracts preserved: `--ci --format json` schema (byte-matches the committed golden),
  dual-mode exit tiers, `--staged` hook mode (`--strict --staged --category provenance`
  — the hook shape), `--fix` apply/dry incl. the known Check-5 fix-without-frontmatter
  bug (ported faithfully); Check 10g `--network` drift functions with curl/git
  subprocess + file:// upstream parity; audit `--verifier` STDIN-only + `shell=False`
  (behaviorally proven: injected `; touch pwned` never executes; argv-recording stub
  sees flags but never claim/passage).
- Two shim flips + 2 manifest appends. The hook's lint step is now Python end-to-end.
- The three MANDATED impl-assertion rewrites (inventory rows → done, committed here
  with the index-split from 25-02 resolved): `test_lint_version.sh` (module-constant +
  semver shape), `test_lint_required_field_dropped.sh` + 
  `test_generated_frontmatter_clean.sh` (negative proofs re-pointed at the Python
  modules, non-vacuity guards added). All three mutation-verified (constant bump /
  BASE_FIELDS reintroduction / template privacy-line reintroduction each flip red).
- `tests/test_packaging.py` re-pointed from the stub-sentinel to the side-effect-free
  `--version` probe (the old bare-run assertion would lint the caller's cwd and write
  report/log side effects post-port — observed appending junk to the live log during
  pytest; restored via git checkout).
- TEST-06: `tests/test_lint_audit_unit.py` (39 tests — mask_markdown edges, PROV_RE
  shapes, decay boundary math (90d fresh / 91d stale), --fix insertion, orphan
  classes, every audit locator family incl. fence boundaries, verifier security).
- Port-agent self-verification: 100+ four-channel cases across both tools; full
  enumerated suites green on a shim-flipped CLONE under WIKI_IMPL=py with red/green
  routing proofs (breaking each module flipped its tests red, restore → green);
  `pytest tests/` 149 passed.

## Notes

- Faithful-ported known bugs (NOT fixed): text-mode report/log writes on the hook
  path (the clobber todo), Check-5 `--fix` body-without-frontmatter write.
- `LINT_NETWORK` env → `--network` flag handling is internal-parameter shape only;
  observable contract unchanged.
