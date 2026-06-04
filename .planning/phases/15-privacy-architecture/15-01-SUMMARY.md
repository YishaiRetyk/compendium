---
phase: 15-privacy-architecture
plan: 01
subsystem: schema-migration
tags: [privacy, migration, schema, security-atomic, wiki-cloud, wiki-local]

# Dependency graph
requires: [15-00]
provides:
  - "wiki-cloud/ (54 pages): cloud-safe tier; wiki/ removed"
  - "wiki-local/maintenance/ (2 audit files): local-only tier"
  - "CLAUDE.md§13: one-line structural pointer (asymmetric two-dir model)"
  - "CLAUDE.md§5: privacy field removed from BASE_FIELDS + validation checklist"
  - "bin/lib/privacy_resolve.py: collapsed to single path-prefix structural predicate"
  - "bin/check-neutrality.sh: source_local_only_wiki() re-keyed to wiki-local/ walk"
  - "bin/check-privacy.sh: re-keyed to structural PATH guard"
  - "bin/check-sources-cloud-safe.sh: FAIL-CLOSED raw-source guard (CI-wired)"
  - "bin/audit-claims.sh: FAITH-04 keys off source SUMMARY tier + two-tier walk"
  - "bin/lint.sh: privacy removed from BASE_FIELDS + VALID_PRIVACY; audit generated-frontmatter clean"
  - "dr-2026-06-04-privacy-asymmetric-two-dir.md: execution-time DR recording 3 weighed options"
  - "pass-c-manifest.tsv: auditable 380-occurrence fixture re-key record"
affects:
  - "15-02 (Wave 2: D-09 linkres check, settings.cloud.json deny-profile, behavioral verification)"
  - "16 (Reference Extraction: §13 now in asymmetric form, PRIV-07 satisfied)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Security-atomic lockstep commit: all tasks accumulate in working tree, land in one commit (D-02)"
    - "Route-then-strip ordering: read privacy value BEFORE stripping to route correctly (D-03)"
    - "ruamel write_roundtrip for frontmatter mutation (not sed — D-04)"
    - "Manifest-driven Pass C: 380 occurrences classified into 4 buckets, no blind re-key"
    - "Path-prefix structural predicate: wiki-local/ path IS the privacy classifier"

key-files:
  created:
    - "wiki-cloud/ (54 pages, renamed from wiki/)"
    - "wiki-local/maintenance/audit-report.md"
    - "wiki-local/maintenance/audit-state.md"
    - "wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md"
    - "bin/check-sources-cloud-safe.sh"
    - "bin/migrate-privacy-dirs.sh (one-off migration helper)"
    - ".planning/phases/15-privacy-architecture/pass-c-manifest.tsv"
    - "tests/phase-09/fixtures/privacy-leak-public/docs/wiki-local/leaked.md"
  modified:
    - "CLAUDE.md / AGENTS.md (byte-equal): §2/§3/§5/§8/§13 rewritten"
    - "schema/AGENTS.template.md: semantic mirror of CLAUDE.md changes"
    - "schema/fixtures/canonical-AGENTS.md: regenerated via wizard"
    - "bin/lib/privacy_resolve.py: collapsed to path-prefix predicate"
    - "bin/lint.sh: WIKI_DIR default → wiki-cloud/, privacy removed from BASE_FIELDS/enum, generated-frontmatter stripped, audit control-plane → wiki-local/"
    - "bin/audit-claims.sh: two-tier walk, source_registry stores summary_rel_path, FAITH-04 keys off summary tier, audit control-plane → wiki-local/"
    - "bin/check-neutrality.sh: source_local_only_wiki() → wiki-local/ walk; PUBLIC_PATHS wiki → wiki-cloud"
    - "bin/check-privacy.sh: rewritten to structural PATH guard (wiki-local/ in PUBLIC_PATHS)"
    - ".github/workflows/lint.yml: privacy-leak job → check-sources-cloud-safe"
    - "schema/templates/*.md, schema/examples/*.md: privacy field stripped"
    - "examples/kahneman/**, examples/dataview-fixtures/**: privacy field stripped"
    - "schema/obsidian/*.md: privacy field stripped"
    - "docs/reference/privacy-model.md: rewritten to asymmetric model"
    - "docs/manual-setup.md, CONTRIBUTING.md: wiki/ → wiki-cloud/ references"
    - "tests/phase-07..13 (94 .sh files): Pass C manifest-driven re-key by bucket"
    - "tests/phase-13: 3 resolver tests rewritten + 7 fixture-based tests re-keyed"
    - "tests/phase-09.1/test_schema_examples_frontmatter.sh: privacy check inverted"

decisions:
  - "Pass 0 option (b): helper ignores its own file in the clean-tree precheck (D-02 cycle-2 MEDIUM)"
  - "brownfield fixture tests reverted from Pass C re-key: they scan pre-Phase-15 vaults with wiki/ structure, not wiki-cloud/"
  - "test_kahneman_moved.sh §5 assertion updated: wiki-cloud/maintenance/ EXISTS (holds lint-report.md) — audit control-plane audit checks instead"
  - "CLAUDE.md edited directly first; then sync_claude wiped it; all subsequent edits on AGENTS.md (source of truth for sync)"
  - "schema/obsidian/*.md stripped via raw string manipulation (ruamel can't parse {{Obsidian placeholders}})"
  - "pass-c-manifest.tsv created at .planning/... (auditable fixture re-key record per cycle-2 MEDIUM)"

# Metrics
duration: 44min
completed: 2026-06-04
---

# Phase 15 Plan 01: Asymmetric Two-Directory Privacy Migration Summary

**One security-atomic commit converting per-page `privacy` frontmatter to structural wiki-cloud/ + wiki-local/ directory-tier enforcement, re-keying every privacy predicate atomically so no intermediate has a dead guard.**

## Performance

- **Duration:** ~44 min
- **Started:** 2026-06-04T14:15:47Z
- **Completed:** 2026-06-04T14:58:51Z
- **Tasks:** 6 (1=Route+Strip+PassC, 2=Schema rewrite, 3=Bin/CI path re-key, 4=Templates+DR+Commit, 5=Phase-13 resolver test rewrites, 6=Predicate re-keys)
- **Files modified:** 208 (one security-atomic commit)

## Accomplishments

### Task 1: Route-then-strip + Pass C
- Created `bin/migrate-privacy-dirs.sh` (one-off migration helper)
- Pass A: `git mv` 56 pages: 54 cloud_safe → `wiki-cloud/`, 2 local_only → `wiki-local/maintenance/`
- Pass B: ruamel strip of `privacy` field from all 56 moved pages (idempotent, never sed)
- Pass C: 380-occurrence manifest-driven re-key across 9 phase dirs (94 .sh files classified into 4 buckets: cloud/local-maint/resolver-test/git-history)

### Task 2: Schema rewrite (CLAUDE.md ≡ AGENTS.md byte-equal)
- §1: wiki → wiki-cloud/ + wiki-local/ in overview
- §2: Full directory structure rewritten (two-tier model, D-06/D-07/D-08 documented)
- §3: DO NOT rule: structural boundary replaces agent-remembered per-turn rule
- §5: `privacy` field removed from BASE_FIELDS, field descriptions, validation checklist (renumbered 5→4, ..., 17→16)
- §8: D-09 asymmetric cross-tier link rule added (wiki-cloud→wiki-local FORBIDDEN)
- §13: Rewritten to one-line structural pointer (full machinery removed, not relocated — D-16/PRIV-07)
- All wiki/ path references throughout §6-§12 updated to wiki-cloud/ (or wiki-local/ for audit control-plane)
- `schema/AGENTS.template.md`: semantic mirror (§11.7 Audit section byte-equal; {{PLACEHOLDER}} tokens preserved)
- `schema/fixtures/canonical-AGENTS.md`: regenerated via wizard

### Task 3: Bin/ and CI path re-key
- `bin/lint.sh`: WIKI_DIR default → wiki-cloud/; privacy removed from BASE_FIELDS + VALID_PRIVACY enum; lint-report template privacy stripped; all wiki/ refs updated
- `bin/audit-claims.sh`: two-tier walk (wiki-cloud/ + wiki-local/); audit control-plane → wiki-local/maintenance/ via LOCAL_MAINT; FAITH-04 now receives summary_rel_path (not raw sources/ path); generated-frontmatter privacy stripped
- `bin/check-neutrality.sh`: PUBLIC_PATHS `wiki` → `wiki-cloud`; comments updated; predicate re-key in Task 6
- `bin/release.sh`: ALLOWLIST wiki/* → wiki-cloud/*; wiki-local confirmed excluded
- `bin/init-wizard.sh`, `bin/brownfield.sh`, `bin/search.sh`, `bin/ingest.sh`, `bin/validate-op.sh`: wiki/ → wiki-cloud/ path strings
- `.github/workflows/lint.yml`: privacy-leak job comment updated; `bin/check-sources-cloud-safe.sh` wired in

### Task 5: Phase-13 resolver tests rewritten (review HIGH #1)
- `test_privacy_resolve_precedence.sh`: 7-row Decision Table assertions → structural path-prefix contract
- `test_claim_page_privacy.sh`: page under wiki-local/ (not privacy: local_only frontmatter) drives local tier
- `test_raw_source_privacy.sh`: cloud page citing wiki-local/sources/ summary → local (source-tier privacy survives)
- 7 additional phase-13 fixture-based tests re-keyed (local source summaries moved to wiki-local/sources/)
- `test_agents_claude_mirror.sh` updated: "strictest of {raw-source/...}" → "wiki-local/ or source-summary tier"

### Task 6: Predicate re-keys (review HIGH #6 — D-02 atomicity)
- `bin/lib/privacy_resolve.py`: collapsed to `_is_local(path)` predicate; both functions use path-prefix only; raw-source structural rule documented in module docstring
- `bin/check-neutrality.sh` `source_local_only_wiki()`: walk `wiki-local/` dir; drop dead `privacy:\s*local_only` regex; keep `os.path.isdir` early-return
- `bin/check-privacy.sh`: completely rewritten to structural PATH guard (wiki-local/ path component in PUBLIC_PATHS → exit 2); honest scope limitation documented
- `bin/check-sources-cloud-safe.sh` (NEW): FAIL-CLOSED guard; browfield_yaml for frontmatter parse (not grep); exits non-zero if raw source carries `privacy: local_only` OR `sources/local-only/` exists; wired into CI privacy-leak job
- `bin/audit-claims.sh`: source_registry stores `{'fm': sfm, 'summary_rel_path': rel}`; FAITH-04 chokepoint passes `summary_path` to collapsed resolver; claim-page walk includes `wiki-local/`

### Task 4: Templates + DR + GREEN GATE + Commit
- `schema/templates/*.md`, `schema/examples/*.md`, `examples/kahneman/**`, `examples/dataview-fixtures/**`, `schema/obsidian/*.md`: all `privacy` fields stripped (ruamel + string manipulation for {{placeholder}} templates)
- Decision record authored: `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` (trigger_type: schema-update; 3 weighed options recorded; asymmetric model rationale)
- wiki-cloud/index.md: DR added under Decisions
- wiki-cloud/log.md: `## [2026-06-04] reflect | privacy asymmetric two-dir` appended
- Additional test/doc fixes: `tests/phase-07/test_kahneman_moved.sh`, `test_kahneman_readme.sh` (privacy field stripped assertion); `tests/phase-09.1/test_schema_examples_frontmatter.sh`; `tests/phase-09/test_check_privacy_leak.sh`; `tests/phase-10/test_brownfield_scan_report.sh` (brownfield fixture re-key reverted); `tests/phase-11` (brownfield tests reverted from incorrect wiki-cloud/ re-key); `docs/manual-setup.md`, `CONTRIBUTING.md`

## Task Commits

All tasks landed in ONE security-atomic commit per D-02:

| Task | Commit | Description |
|------|--------|-------------|
| 1, 2, 3, 4, 5, 6 | `1db4fc3` | schema: asymmetric two-dir privacy (wiki/→wiki-cloud/+wiki-local/), strip per-page privacy field, re-key all privacy predicates |

## Verification Results

### Wave-1 Phase-15 Tests (all GREEN)
- `test_layout_migrated`: PASS
- `test_schema_13_rewritten`: PASS
- `test_privacy_field_stripped`: PASS
- `test_priv_resident_reduced`: PASS
- `test_decision_record`: PASS
- `test_resolver_structural`: PASS
- `test_neutrality_leak_source_rekey`: PASS
- `test_generated_frontmatter_clean`: PASS
- `test_lint_required_field_dropped`: PASS
- `test_raw_sources_cloud_safe_guard`: PASS
- `test_check_privacy_rekey`: PASS

### Wave-2 Tests (deferred to Plan 15-02, remain RED)
- `test_lint_xtier_link`: RED (D-09 linkres check not yet implemented)
- `test_cloud_deny_profile`: RED (.claude/settings.cloud.json not yet created)

### Phase-13 Audit Suite (all 33 tests GREEN, review HIGH #1 satisfied)
All 33 phase-13 tests pass. The 3 resolver tests were rewritten to the structural path-prefix contract; 7 fixture-based tests updated to use wiki-local/sources/ for local source summaries.

### Prior-Phase Regression (phases 07-13, all GREEN)
All 9 prior-phase suites GREEN after manifest-driven Pass C re-key + targeted fixes for brownfield fixtures (correctly reverted to wiki/ structure) and phase-09/09.1 test updates.

### Lint Gate
`bash bin/lint.sh wiki-cloud/` → 0 errors, 56 warnings (pre-existing, not regressions), 0 info — exits 0. D-02 lockstep invariant satisfied.

## Deviations from Plan

### Deviation 1: CLAUDE.md vs AGENTS.md edit direction
**Found during:** Task 2
**Issue:** Edited CLAUDE.md first; running `bin/sync-claude.sh` (which copies AGENTS.md → CLAUDE.md) wiped all CLAUDE.md changes.
**Fix:** All subsequent edits applied to AGENTS.md (the source of truth for sync). Corrective: all changes reapplied to AGENTS.md via Python script; synced to CLAUDE.md.
**Files modified:** AGENTS.md (primary), CLAUDE.md (via sync)

### Deviation 2: schema/obsidian/*.md ruamel parse failure
**Found during:** Task 4
**Issue:** `read_fm_body()` cannot parse files with `{{Obsidian placeholder}}` syntax in frontmatter — these are Obsidian template files with double-brace tokens.
**Fix:** Applied raw string manipulation (Python pathlib) to remove `privacy:` lines from frontmatter block. Idempotent and correct since these are template files not wiki pages.

### Deviation 3: brownfield Phase-11 tests incorrectly re-keyed by Pass C
**Found during:** Regression testing
**Issue:** Pass C classified `wiki/` references in phase-11 brownfield tests as bucket-1 (cloud page reference) and re-keyed them to `wiki-cloud/`. But these tests operate on brownfield fixture repos that have the OLD `wiki/` structure (they're testing migration FROM old vaults). The migration scripts write back to whatever structure exists.
**Fix:** Reverted the incorrect re-keys in 6 phase-11 brownfield test files back to `wiki/`.
**Rule:** Deviation Rule 1 (auto-fix bug in Pass C classification).

### Deviation 4: test_brownfield_scan_report.sh assertion incorrectly re-keyed
**Found during:** Regression testing
**Issue:** Same as Deviation 3 — brownfield scan fixture has `wiki/entities/SomeEntity.md` and the assertion was incorrectly changed to `wiki-cloud/`.
**Fix:** Reverted assertion to `wiki/entities/SomeEntity.md`.

### Deviation 5: Multiple additional test files required updating beyond Pass C scope
**Found during:** Regression testing
**Issue:** Several tests not covered by Pass C (phase-07 `test_kahneman_moved.sh`/`test_kahneman_readme.sh`, phase-09 `test_check_privacy_leak.sh`, phase-09.1 `test_schema_examples_frontmatter.sh`) required updates because they referenced the old per-page privacy model.
**Fix:** Updated each test to reflect the Phase 15 structural model.

### Deviation 6: wiki/.obsidian/ moved to wiki-cloud/.obsidian/
**Found during:** Task 1
**Issue:** `wiki/.obsidian/` directory (untracked) remained after all wiki/*.md files were moved, preventing removal of the empty `wiki/` dir (test_layout_migrated checks `test ! -d wiki`).
**Fix:** Moved `wiki/.obsidian/` to `wiki-cloud/.obsidian/` (it's the new wiki root). `rmdir wiki` then succeeded. Untracked files are not in git history so no git mv needed.

## Known Stubs

None — all wiki content migrated. No placeholder text or empty-data flows in the new wiki-cloud/ pages.

## Threat Flags

None beyond what was planned:
- `wiki-cloud/` is the new public surface (replaces `wiki/` in PUBLIC_PATHS for check-neutrality and the release allowlist)
- `wiki-local/` is the new local-only surface (structural boundary, not a new trust boundary type)
- `bin/check-sources-cloud-safe.sh` is a new CI-wired guard script (closes the cycle-2 HIGH raw-sources hole)

## Self-Check: PASSED

Files exist:
- wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md: FOUND
- wiki-local/maintenance/audit-state.md: FOUND
- wiki-cloud/index.md: FOUND
- CLAUDE.md: FOUND
- bin/check-sources-cloud-safe.sh: FOUND
- bin/lib/privacy_resolve.py: FOUND
- .planning/phases/15-privacy-architecture/pass-c-manifest.tsv: FOUND

Commits exist:
- 1db4fc3 (security-atomic migration): FOUND
- 8939c17 (Wave-0 scaffold): FOUND

All 11 Wave-1 phase-15 tests: GREEN
All 33 phase-13 audit suite tests: GREEN
All prior-phase regression suites (phase-07..13): GREEN
bin/lint.sh wiki-cloud/ exits 0: VERIFIED
bin/sync-claude.sh --check exits 0: VERIFIED
test_canonical_byte_equality exits 0: VERIFIED
git log --oneline -2 shows exactly one migration commit on top of Wave-0 scaffold: VERIFIED
