---
phase: 25-parallel-migration-cutover
plan: 06
type: execute
wave: 1
depends_on: [01]
files_modified:
  - src/compendium/lint.py
  - src/compendium/audit_claims.py
  - bin/lint.sh
  - bin/audit-claims.sh
  - tests/ported.manifest
  - tests/test_lint_audit_unit.py
  - tests/phase-09/test_lint_version.sh
  - tests/phase-15/test_lint_required_field_dropped.sh
  - tests/phase-15/test_generated_frontmatter_clean.sh
autonomous: true
requirements: [MIG-02]
---

<objective>
Port `lint.sh` (2,988 lines, LINT_VERSION 1.12.0, 7 heredocs) and `audit-claims.sh`
(1,282 lines, 2 heredocs) TOGETHER onto `compendium.common.page` — the long pole, and the
port that actually retires the lint↔audit byte-copy (PKG-02's purpose). Preserves the
`lint --ci --format json` schema (golden-locked, consumed by json-to-annotations.py),
dual-mode exit semantics, and the audit `--verifier` STDIN-only / `shell=False` egress
security contract VERBATIM. Includes the three MANDATED impl-assertion rewrites deferred
to MIG-02.
</objective>

<context>
- `common/page.py` already holds the single frozen copy of parse_frontmatter, PROV_RE,
  EPISTEMIC_INLINE_RE, WIKILINK/PIPED/BARE regexes, `_FENCE_OPEN_RE` + `_mask_fences` +
  `mask_markdown`, EXCLUDE sets (lifted verbatim from lint.sh 1.12.0). Both ports import
  it; NEITHER re-declares those symbols (that would resurrect the byte-copy).
- Audit-side intentional differences (RB-3, documented in common-api-inventory.md):
  `_fence_mask_lines` (:314; returns (lines, fenced-flags) — a DISTINCT API from lint's
  length-preserving mask) ports INTO audit_claims.py as its own function; do NOT touch
  frozen common/. `parse_frontmatter_str` (:204, in-memory variant) likewise ports into
  audit_claims.py. The audit page-walk + source-registry copy (:224, "COPIED from lint.sh")
  retires onto common walk/classify imports where byte-parity holds.
- lint Check 10g external-drift functions (Phase 23, `--network`) are lint-only: port
  within lint.py; network calls stay subprocess/HTTP; phase-23 suite characterizes the
  offline/skip paths.
- Inventory rows (defer-to-MIG-02 — REWRITE IN THIS PLAN, keep filenames):
  - `tests/phase-09/test_lint_version.sh` — sed-extracts `LINT_VERSION="…"` from bash
    source (returns empty post-flip → false-fail). Rewrite: assert `--version` output
    SHAPE (`lint <semver>`) + equality with the constant read from
    `src/compendium/lint.py`.
  - `tests/phase-15/test_lint_required_field_dropped.sh` — negative source assertion
    (per-page `privacy` validation REMOVED); re-express against src/compendium/lint.py
    source, preserving the negative-proof intent.
  - `tests/phase-15/test_generated_frontmatter_clean.sh` — template-heredoc negative
    greps; re-express against the two Python modules (behavioral core already covered by
    its later checks — keep those untouched).
- `--version` output must remain byte-identical ("1.12.0" constant carried into Python).
- Exit semantics: text mode vs `--ci --format json` differ (dual-mode) — goldens lock
  both; severity tiers + staged-gate (`--staged`) behavior per schema/workflows/lint.md.
  The staged gate runs inside the pre-commit hook: after this flip the hook's lint step
  is Python — the hook lint-clobber todo behavior will reproduce identically (same
  report-writing behavior, ported faithfully; do NOT fix it here).
- audit-claims: `--verifier` subprocess must remain STDIN-only with `shell=False`
  (security contract named in MIG-02); AUDIT_LIB_DIR unconditional export (:123) and
  `--help` early exit (:83) characterized by goldens. Audit writes to
  `wiki-local/maintenance/` — the tool touches local tier by design; tests use fixtures.
</context>

<tasks>
1. Baseline both legs (phase-09/12.2/13/15/22/23 lint+audit surfaces, goldens: lint
   trees + checkers + the json schema case). Read both scripts fully; per-check inventory
   of lint's numbered checks and audit's resolver pipeline.
2. Port lint.py first (checks as functions, common.page imports, dual-mode output
   assembly, --staged mode, Check 10g), then audit_claims.py (resolvers incl. Phase-22
   `#path:`/`#commit:` fence-aware ones, verifier egress contract, report writer).
3. The three test rewrites (above); verify each still FAILS when its invariant is
   violated (one mutation check each).
4. TEST-06: `tests/test_lint_audit_unit.py` — mask_markdown edge cases via common,
   per-check unit probes (orphan detection, provenance resolution, decay math),
   audit locator resolution incl. fence boundaries.
5. Flip both shims + 2 manifest appends; three-leg parity (expect iteration — this is
   4,270 lines of diagnostics-heavy bash; use the capture dirs channel-by-channel);
   commit `feat(25): port lint + audit-claims to python (MIG-02)`; restore clobbered
   wiki files; SUMMARY.
</tasks>

<acceptance>
- `lint --ci --format json` byte-matches its golden; text mode + exit tiers match; the
  staged gate works inside a REAL hook run (make a wiki-touching commit and observe).
- audit-claims sample run byte-matches oracle (report content modulo the run-date fields
  the goldens already normalize); verifier subprocess demonstrably shell=False/STDIN-only
  (unit-level assert on the call).
- Rewritten tests green on both legs + mutation-verified; LINT_VERSION consistency test
  passes reading the Python constant.
- Three-leg parity 0/0/0; SUITE_MANIFEST match on both legs; freeze guard clean
  (common/ untouched); unit file green.
</acceptance>
