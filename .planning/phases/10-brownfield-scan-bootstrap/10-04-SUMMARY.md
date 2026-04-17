---
phase: 10-brownfield-scan-bootstrap
plan: "04"
subsystem: brownfield
tags: [brownfield, schema, agents-md, lint, ingest, ci-downgrade, byte-equality, brwn-07, brwn-08, brwn-09, brwn-10]

# Dependency graph
requires:
  - phase: 10-brownfield-scan-bootstrap/01
    provides: tests/phase-10/ harness (run.sh + lib.sh) for authoring the 9 locking tests
  - phase: 07-neutral-template-foundation
    provides: CLAUDE.md byte-sync contract (bin/sync-claude.sh + .githooks/pre-commit) and schema/AGENTS.template.md mirror convention
  - phase: 08-two-track-setup-wizard-manual
    provides: schema/fixtures/canonical-AGENTS.md regeneration recipe (bin/init-wizard.sh --render-to) + byte-equality CI gate
  - phase: 09-collaborative-pr-workflow-ci-lint-gate
    provides: bin/lint.sh CI_SEVERITY_REMAP dispatch table + --ci / --format json / --skip-category plumbing (Phase 10 extends with one row + one downgrade modifier)
provides:
  - AGENTS.md §5 field-descriptions table documents bootstrap_stage + bootstrap_date (2 new rows at the tail, just before Source Summary Additional Fields)
  - CLAUDE.md byte-synced mirror
  - schema/AGENTS.template.md §5 field-descriptions table mirrors the same 2 rows (byte-equal at table scope)
  - schema/fixtures/canonical-AGENTS.md regenerated via the wizard render routine (Phase 8-01 byte-equality CI still green)
  - bin/ingest.sh BRWN-10 strip pass (frontmatter-scoped, regex + python3 heredoc, no new runtime deps) with verbatim D-21 one-line stderr warning per field
  - bin/lint.sh 'brownfield' category registered in --category --help + CI_SEVERITY_REMAP + new Check block (BRWN-09 30-day staleness + summary counts)
  - bin/lint.sh BRWN-08 --ci error->info downgrade on bootstrapped pages (I-1 scope: --ci only; text-mode unaffected)
  - 9 Phase-10 tests locking each invariant (schema rows, template parity, CLAUDE.md byte-equality, BRWN-10 strip + no-false-positive, brownfield category + 30d stale + summary, --ci downgrade + no-downgrade)
affects:
  - 10-05 (docs): docs/reference/brownfield.md can now cite a fully-documented bootstrap_stage field in AGENTS.md §5 and reference the --ci-only scope of the BRWN-08 downgrade
  - 11 (suggest + verify): future suggest workflow inherits the strip behavior and lint category as-is
  - Any phase touching AGENTS.md §5: the same regen + byte-sync recipe applies

# Tech tracking
tech-stack:
  added: []  # Zero new runtime deps. python3 heredoc inside bin/ingest.sh (python3 was already required by the resolve_contributor helper). ruamel.yaml remains brownfield-bootstrap-path-only per CONTEXT.md.
  patterns:
    - "Dual-commit TDD per task (RED test + fixture → GREEN impl) preserves the RED/GREEN provenance in git log for Tasks 2 and 3"
    - "Frontmatter-scoped in-place mutation via python3 heredoc (BRWN-10 strip): walk lines, locate first --- / second --- frontmatter boundary, drop matching-field lines, rewrite file only if lines were dropped"
    - "BRWN-08 downgrade modifier inside 'if CI_MODE:' block (I-1 scope): a second list-comprehension after the CI_SEVERITY_REMAP pass that demotes allowlist-category findings on bootstrapped pages from error to info"
    - "BROWNFIELD_BOOTSTRAPPED_PAGES set built once from parsed frontmatter, immediately after all_pages is assembled — O(1) per finding downgrade check"
    - "Phase-10 byte-equality template parity scoped to the §5 `### Field Descriptions` table (NOT full §5) — the template's illustrative yaml example block legitimately differs from AGENTS.md because it embeds {{PLACEHOLDER}} tokens per Phase 07 D-08"

key-files:
  created:
    - tests/phase-10/test_agents_section_5_bootstrap_stage.sh
    - tests/phase-10/test_agents_template_parity_section_5.sh
    - tests/phase-10/test_claude_sync_byte_equal.sh
    - tests/phase-10/test_ingest_strip_bootstrap_stage.sh
    - tests/phase-10/test_ingest_strip_no_warn_when_absent.sh
    - tests/phase-10/test_lint_brownfield_category_help.sh
    - tests/phase-10/test_lint_brownfield_stale_30d.sh
    - tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh
    - tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh
    - tests/phase-10/fixtures/bootstrapped-vault/wiki/entities/ingest-target.md
    - tests/phase-10/fixtures/bootstrapped-vault/wiki/concepts/bootstrapped-old.md
    - tests/phase-10/fixtures/bootstrapped-vault/wiki/concepts/bootstrapped-fresh.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/fixtures/canonical-AGENTS.md
    - bin/ingest.sh
    - bin/lint.sh

key-decisions:
  - "D-20 wording landed verbatim as written: the bootstrap_stage row names the enum `raw | bootstrapped | verified`, carries the PROV-01..05 contrast in bold, cites `bin/ingest.sh` strip, and forward-refs §11.5"
  - "bin/ingest.sh strip uses python3 heredoc (frontmatter-scoped) rather than pure sed because (a) sed in-place flags differ between GNU and BSD, (b) we must NOT touch body text containing the token inside code blocks. python3 was already a runtime requirement via resolve_contributor."
  - "D-21 stderr template emitted as a single line per field (one `echo ... >&2` call per stripped field) — locked by the W-6 combined-line grep in test_ingest_strip_bootstrap_stage.sh"
  - "BRWN-08 downgrade scope: --ci mode only (I-1). Text-mode `bin/lint.sh` on a bootstrapped vault still emits full-severity findings — the downgrade is a CI-gate pragmatic, not a universal severity change"
  - "Phase-10 template parity test scoped to `### Field Descriptions` table (NOT full §5 section) because the template's illustrative yaml example block intentionally differs from AGENTS.md per Phase 07 D-08 {{PLACEHOLDER}} convention"
  - "Fresh-fixture bootstrap_date rewritten to `date -u +%Y-%m-%d` inside test_lint_brownfield_stale_30d.sh (via python3 sed-style substitution on the tmp copy) so the test remains stable regardless of calendar advance — the fixture file itself keeps the 2026-04-10 literal for documentation"

patterns-established:
  - "§5 field-descriptions row insertion: add row at the tail of the table (just before ### Source Summary Additional Fields), mirror into schema/AGENTS.template.md at the same table position, regenerate canonical-AGENTS.md in the same commit, and byte-sync CLAUDE.md. Locked by 3 tests (row-shape + template-parity + CLAUDE-sync)"
  - "Frontmatter-scoped regex mutation in bash shell scripts: grep pre-filter → python3 heredoc scoped to the first `---`..`---` block → write-only-if-changed + return stripped count via stdout → bash conditional on the count. Pattern reusable by any future bin/*.sh that must surgically edit frontmatter without touching body text"
  - "CI-only severity downgrade modifier: append to the `if CI_MODE:` block as a second list-comprehension AFTER the CI_SEVERITY_REMAP pass. Document the --ci-only scope in a CODE COMMENT + a DOCS COMMENT + a test pair (downgrade + no-downgrade) to prevent future refactors from accidentally widening the scope to text-mode"

requirements-completed: [BRWN-07, BRWN-08, BRWN-09, BRWN-10]

# Metrics
duration: ~45min
completed: 2026-04-17
---

# Phase 10 Plan 04: Schema + Lint + Ingest Wiring for Brownfield Sentinel Summary

**AGENTS.md §5 documents `bootstrap_stage` + `bootstrap_date` (2 rows), CLAUDE.md byte-synced, `schema/AGENTS.template.md` mirrored, canonical fixture regenerated; `bin/ingest.sh` strips both fields on normal ingest with verbatim D-21 stderr; `bin/lint.sh` gains a `brownfield` category (BRWN-09 30-day staleness + summary counts) and a `--ci`-only allowlist error→info downgrade on bootstrapped pages (BRWN-08); all 9 new Phase-10 tests + 61 prior-phase regression tests green (17/17 Phase-10, 22/22 Phase-07, 21/21 Phase-08, 28/28 Phase-09, 11/11 Phase-09.1).**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-17T08:34:00Z (approx — matches commit 141122e authorship)
- **Completed:** 2026-04-17T09:19:00Z
- **Tasks:** 3 (5 commits: 1 Task 1 atomic, 2 per-task RED/GREEN pairs for Tasks 2 and 3)
- **Files created:** 12 (9 tests + 3 fixture pages)
- **Files modified:** 6 (AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, bin/ingest.sh, bin/lint.sh)

## Accomplishments

- **Schema documentation (Task 1):** AGENTS.md §5 field-descriptions table gained 2 rows — `bootstrap_stage` (enum `raw | bootstrapped | verified`) with the explicit PROV-01..05 contrast + ingest-strip note + §11.5 forward-ref, and `bootstrap_date` (ISO 8601 date) with the BRWN-09 staleness reference. CLAUDE.md auto-synced byte-equal; `schema/AGENTS.template.md` mirrored the same 2 rows at the same table position; `schema/fixtures/canonical-AGENTS.md` regenerated via `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen` so Phase 8-01's byte-equality CI stays green.
- **Ingest pollution prevention (Task 2, BRWN-10):** `bin/ingest.sh` gained a ~55-line strip pass between the `cp` block and the hash compute. For each of `bootstrap_stage` / `bootstrap_date` present in the first `---`..`---` frontmatter block, the field line is removed from the DEST_FILE and a single-line D-21 stderr warning is emitted: `Note: stripped <field>=<value> from <path> during ingest (brownfield-scoped field; see AGENTS.md §5).`. Body text containing the token (e.g., inside a code block) is preserved verbatim. Zero new runtime deps — python3 was already a bin/ingest.sh requirement.
- **Lint extensions (Task 3, BRWN-08 + BRWN-09):**
  - `bin/lint.sh --help --category` enum gains `brownfield`.
  - `CI_SEVERITY_REMAP` gains `'brownfield': 'warning'` (single-line addition matching the Phase 9 convention).
  - `BROWNFIELD_BOOTSTRAPPED_PAGES` set built once from parsed frontmatter immediately after `all_pages` is assembled; `BROWNFIELD_ALLOWLIST = {yaml, provenance, orphan}` documents the downgrade surface.
  - `if CI_MODE:` block now includes a second list-comprehension that downgrades allowlist-category findings on bootstrapped pages from `error` to `info`. **Scope (I-1): --ci mode only.** Text-mode `bin/lint.sh` is untouched and still emits full severities on bootstrapped vaults.
  - New Check block gated on `should_run('brownfield')` iterates `all_pages`, flags pages whose `bootstrap_date` is >30 days old as `warning/brownfield` with age-in-days phrasing, and emits a summary `info/brownfield` finding `bootstrapped pages: X; stale (>30d): Y` when at least one bootstrapped page exists.
- **9 new tests** lock each invariant mechanically; all pass in isolation AND through the Phase-10 aggregator; 4 prior-phase harnesses (07/08/09/09.1) continue green.

## Task Commits

Each task committed atomically (with RED/GREEN separation for TDD tasks):

1. **Task 1 (atomic): AGENTS.md §5 + CLAUDE.md sync + schema/AGENTS.template.md mirror + schema/fixtures/canonical-AGENTS.md regen + 3 tests** — `141122e` (feat) — 7 files, +142 LOC.
2. **Task 2 RED: BRWN-10 strip tests + ingest-target fixture** — `0b71778` (test) — 3 files, +140 LOC.
3. **Task 2 GREEN: bin/ingest.sh BRWN-10 strip impl** — `6f83128` (feat) — 1 file, +63 LOC.
4. **Task 3 RED: brownfield lint tests + 2 concept fixtures** — `6d59b12` (test) — 6 files, +239 LOC.
5. **Task 3 GREEN: bin/lint.sh brownfield category + BRWN-08 downgrade impl** — `d0a40d4` (feat) — 1 file, +70/-1 LOC.

Worktree-scoped — orchestrator handles final metadata commit (STATE.md, ROADMAP.md) after the wave merges.

## Files Created/Modified

### Created (12 files)

**Tests (9):**
- `tests/phase-10/test_agents_section_5_bootstrap_stage.sh` — asserts AGENTS.md §5 row-shape for both fields + 5 wording invariants (enum, PROV contrast, ingest-strip note, §11.5 forward-ref, ISO 8601).
- `tests/phase-10/test_agents_template_parity_section_5.sh` — byte-equal assertion on the `### Field Descriptions` table extract from AGENTS.md vs schema/AGENTS.template.md (scoped narrower than full §5 because the template's yaml example block legitimately differs).
- `tests/phase-10/test_claude_sync_byte_equal.sh` — `cmp -s AGENTS.md CLAUDE.md` with regeneration recipe on failure.
- `tests/phase-10/test_ingest_strip_bootstrap_stage.sh` — W-6 strictening: 2 substring greps PLUS a combined-line regex that binds the D-21 prefix + parenthetical suffix on one line per field; asserts DEST_FILE has no `^bootstrap_stage:` / `^bootstrap_date:` remaining + body line `Entity body` survives.
- `tests/phase-10/test_ingest_strip_no_warn_when_absent.sh` — no-false-positive: greenfield source → no `Note: stripped` stderr.
- `tests/phase-10/test_lint_brownfield_category_help.sh` — `bin/lint.sh --help | grep -q 'brownfield'`.
- `tests/phase-10/test_lint_brownfield_stale_30d.sh` — asserts flag/no-flag distinction + summary counts line; rewrites fresh fixture's `bootstrap_date` to `$(date -u +%Y-%m-%d)` in the tmp copy for calendar-stability.
- `tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh` — `--ci --format json`; asserts yaml-category finding on bootstrapped-old.md has `severity: info` (downgraded from error).
- `tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh` — `--ci --format json`; asserts yaml-category finding on a greenfield page retains `severity: error`.

**Fixtures (3):**
- `tests/phase-10/fixtures/bootstrapped-vault/wiki/entities/ingest-target.md` — 2026-04-17 bootstrap, entity body to test strip isolation.
- `tests/phase-10/fixtures/bootstrapped-vault/wiki/concepts/bootstrapped-old.md` — `bootstrap_date: 2026-01-01` (>30 days), `type: ""` (yaml-error trigger for downgrade test).
- `tests/phase-10/fixtures/bootstrapped-vault/wiki/concepts/bootstrapped-fresh.md` — `bootstrap_date: 2026-04-10` (documentation literal; rewritten to today by the stale test harness for calendar stability).

### Modified (6 files)

- `AGENTS.md` — 2 new rows in §5 field-descriptions table (lines 302-303).
- `CLAUDE.md` — byte-synced via `bash bin/sync-claude.sh`.
- `schema/AGENTS.template.md` — same 2 rows mirrored at lines 305-306.
- `schema/fixtures/canonical-AGENTS.md` — regenerated via `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen` then `cp`d back.
- `bin/ingest.sh` — +63 lines (BRWN-10 strip block between cp at L309-313 and HASH at L382); regex-only frontmatter-scoped strip with one-line D-21 stderr per field.
- `bin/lint.sh` — +70/-1 lines: `brownfield` added to --category enum + CI_SEVERITY_REMAP; BROWNFIELD_BOOTSTRAPPED_PAGES built once after all_pages assembly; BRWN-08 downgrade inside `if CI_MODE:`; Check: brownfield block gated on `should_run('brownfield')` (30-day staleness + summary counts).

## Decisions Made

### D-20 row wording landed verbatim
Both rows use the exact prose from the plan's Step A / Step B. Notable load-bearing strings: `raw | bootstrapped | verified`, `**NOT a substitute for claim-level provenance (see §6 PROV-01..05)**`, `` stripped by `bin/ingest.sh` ``, `§11.5`, `ISO 8601`. Each is explicitly asserted by test_agents_section_5_bootstrap_stage.sh.

### Canonical fixture regeneration recipe
Used exactly the command from `schema/fixtures/README.md:22-33`:
```
export WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"
export WIZARD_TEMPLATE_SHA="<frozen-fixture>"
bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
```
Regeneration timestamp: 2026-04-17T09:10 UTC (part of commit 141122e). Phase 8-01's `test_canonical_byte_equality.sh` confirmed green post-regen.

### CLAUDE.md sync method
Manual pre-stage (`bash bin/sync-claude.sh && git add CLAUDE.md`) because the parallel-execution directive forbids pre-commit-hook execution (`--no-verify`). The hook would have auto-fired in a normal-mode commit; pre-staging collapsed the hook's 2-attempt flow to 1 commit.

### BRWN-08 downgrade scope (I-1)
The downgrade lives INSIDE `if CI_MODE:` and is documented via (a) a code comment citing `I-1`, (b) a DOCS comment in the SUMMARY/PLAN, and (c) a test pair (downgrade + no-downgrade) that would fail if a future refactor accidentally widened the scope to text-mode. Per the plan's Output block, Plan 05's `docs/reference/brownfield.md` §"Interaction with lint and ingest" must include a sentence noting this `--ci`-only scope so users running local lint after `bin/brownfield.sh bootstrap` aren't surprised by full-severity findings.

### D-21 stderr one-line emission (W-6)
The BRWN-10 strip uses a single `echo "... ${BF_FIELD}=${BF_VALUE} from ${BF_REL_PATH} ... (brownfield-scoped field; see AGENTS.md §5)." >&2` call per field. test_ingest_strip_bootstrap_stage.sh locks this with a combined-line regex that fails if the two halves are split across lines (e.g., `echo prefix; echo suffix`). This is the W-6 strictening over the plan's two original substring greps, both of which are kept for defense-in-depth.

### §5 template parity scoped to Field Descriptions table
The template's yaml example block (lines 255-281) legitimately differs from AGENTS.md because it contains `{{PRIMARY_DOMAIN}}` / `{{DEFAULT_PRIVACY}}` wizard placeholders per Phase 07 D-08. Scoping the parity assertion to the `### Field Descriptions` table extract (from that heading to the line before `### Source Summary Additional Fields`) preserves the table-level byte-mirror contract without fighting the intentional §5 yaml-block divergence. Documented with a scope-note comment in test_agents_template_parity_section_5.sh.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] test_agents_template_parity_section_5.sh initially scoped to full §5, which fails on intentional Phase 07 D-08 placeholder divergence**
- **Found during:** Task 1 post-GREEN verification (the freshly-authored test failed even though AGENTS.md ↔ schema/AGENTS.template.md §5 TABLE rows are byte-identical).
- **Issue:** My first extraction awk range was `## 5. Frontmatter Schema` → `## 6.` which captured the entire §5 INCLUDING the yaml example block. The template's yaml block (lines 277-278) contains `{{PRIMARY_DOMAIN}}` and `{{DEFAULT_PRIVACY}}` placeholders per Phase 07 D-08 — by design, this is where the wizard substitutes user answers. AGENTS.md has the resolved neutral form `knowledge_domain: ""` without the second row. Byte-equality on the full §5 was WRONG; it should only hold on the field-descriptions table.
- **Fix:** Narrowed the awk range to `### Field Descriptions` → `### Source Summary Additional Fields`. Added a scope-note comment in the test explaining why. Re-ran — test passes, and AGENTS.md ↔ template §5 field-descriptions table is genuinely byte-mirrored including my 2 new rows.
- **Files modified:** `tests/phase-10/test_agents_template_parity_section_5.sh` (inline fix before the Task 1 commit landed — no separate commit).
- **Verification:** `bash tests/phase-10/test_agents_template_parity_section_5.sh` passes.
- **Committed in:** `141122e` (bundled into Task 1 atomic commit).

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug; wrong test scope).
**Impact on plan:** No scope creep. The fix made the test actually enforce the plan's intent (byte-mirror on the TABLE rows, where Phase 07 D-08 guarantees byte-equality) rather than the wrong target (full §5, where D-08 guarantees intentional divergence).

## Issues Encountered

- **Phase-10 test count mismatch.** The plan's acceptance criterion cites `PHASE 10 TESTS: 29/29` (2 from Plan 01 + 6 from Plan 02 + 12 from Plan 03 + 9 from this plan). In this worktree, Plan 03 has NOT yet shipped (it runs in a parallel wave-2 worktree), so the local aggregator reports `17/17` (8 baseline from Plans 01-02 + 9 new from this plan). The orchestrator will reconcile to 29/29 when merging all wave outputs. This was expected per the parallel-execution model; documented here so reviewers don't mistake it for a regression.
- **Parallel-execution hook bypass.** The parent execute-plan directive mandates `--no-verify` on all commits, which skips `.githooks/pre-commit`. That hook would normally auto-sync CLAUDE.md on any AGENTS.md commit and re-stage; bypassing it required manual `bash bin/sync-claude.sh && git add CLAUDE.md` before the Task 1 commit. Handled cleanly — `cmp -s AGENTS.md CLAUDE.md` passes, and test_claude_sync_byte_equal.sh confirms the invariant at test time (independent of hook execution).

## User Setup Required

None — all changes are mechanical (schema rows, sync-claude, wizard regen, script edits, tests). No external service configuration. `ruamel.yaml` remains brownfield-bootstrap-path-only (Plan 10-03's concern); this plan adds zero new runtime dependencies.

## Handoff Notes

### To Plan 10-05 (docs + phase docs)

- **Fully-documented sentinel.** `docs/reference/brownfield.md` can cite `AGENTS.md §5` directly for `bootstrap_stage` and `bootstrap_date`. No forward-reference dance required.
- **MANDATORY doc note for BRWN-08 scope.** Plan 05 MUST include a sentence in `docs/reference/brownfield.md` §"Interaction with lint and ingest" stating: *"The BRWN-08 allowlist error→info downgrade is scoped to `bin/lint.sh --ci` mode only. Users running text-mode `bin/lint.sh` locally on a bootstrapped vault will still see full-severity `yaml` / `provenance` / `orphan` findings — this is intentional per I-1 so local lint never masks an error."* This is the I-1 clarification surfaced in the plan's `<output>` block.
- **Test harness anchor unchanged.** `bash tests/phase-10/run.sh` continues to be the green gate for BRWN-07..10 coverage. Plan 05 docs-skeleton tests (if any) land in the same `tests/phase-10/` directory and are auto-discovered by the `shopt -s nullglob` loop.

### To the Phase 10 orchestrator

- **9 new tests, all green.** Combined worktree total (if all waves land cleanly): `PHASE 10 TESTS: 29/29` (8 from Plans 01-02 already in base + 12 expected from Plan 03 + 9 from this plan).
- **No shared-file mutations.** As instructed, `.planning/STATE.md` and `.planning/ROADMAP.md` were NOT touched. The orchestrator owns those after wave merge.
- **No conflict risk with Plan 03.** My 6 modified files (AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, bin/ingest.sh, bin/lint.sh) and 12 created files do not overlap with Plan 03's expected surface (new files under `bin/brownfield.sh` bootstrap branch, `schema/templates/brownfield-*`, and `tests/phase-10/test_brownfield_bootstrap_*.sh`). If Plan 03 happens to touch AGENTS.md (unlikely per its scope) a merge will need to reconcile — but 10-03 is bootstrap implementation and should not modify §5.

### To Plan 11 (suggest + verify)

- **bootstrap_stage is now a first-class schema field.** Phase 11's `suggest` and `verify` can set the sentinel to `verified` (per the enum documented in §5) after user-applied migrations pass. `bin/lint.sh` 30-day staleness warning will continue to fire on bootstrapped pages until the `verified` transition happens — giving users a nudge toward completion.
- **BRWN-08 downgrade remains in place** for any pages stuck at `bootstrapped` while their schema issues get hand-reviewed. No Phase-11 work needed on the lint side.

## Next Phase Readiness

- **Task deliverables green.** `bash tests/phase-10/run.sh` reports `PHASE 10 TESTS: 17/17`; `tests/phase-07/run.sh` 22/22; `tests/phase-08/run.sh` 21/21; `tests/phase-09/run.sh` 28/28; `tests/phase-09.1/run.sh` 11/11. No regressions in any prior phase.
- **Requirements closed:** BRWN-07 (schema rows), BRWN-08 (--ci downgrade), BRWN-09 (30-day staleness + summary), BRWN-10 (ingest strip + D-21 stderr). All four REQ-IDs surfaced by this plan's frontmatter `requirements:` field.
- **No blockers** for Plan 10-05 or Plan 11.

## Self-Check: PASSED

Verified post-SUMMARY that every claimed file exists and every claimed commit is in git history:

- `AGENTS.md`: FOUND, §5 contains both bootstrap_stage + bootstrap_date rows
- `CLAUDE.md`: FOUND, byte-equal to AGENTS.md (`cmp -s` exits 0)
- `schema/AGENTS.template.md`: FOUND, §5 field-descriptions table mirrors AGENTS.md
- `schema/fixtures/canonical-AGENTS.md`: FOUND, regenerated, contains the new rows, phase-08 byte-equality still passes
- `bin/ingest.sh`: FOUND, BRWN-10 block at line 316 (between cp line 309 and HASH line 382)
- `bin/lint.sh`: FOUND, BROWNFIELD_BOOTSTRAPPED_PAGES + BROWNFIELD_ALLOWLIST + brownfield category + CI_MODE downgrade all present
- 9 new test files: all FOUND and executable
- 3 new fixture pages: all FOUND
- Commit `141122e` (feat Task 1): FOUND in `git log`
- Commit `0b71778` (test Task 2 RED): FOUND
- Commit `6f83128` (feat Task 2 GREEN): FOUND
- Commit `6d59b12` (test Task 3 RED): FOUND
- Commit `d0a40d4` (feat Task 3 GREEN): FOUND
- `bash tests/phase-10/run.sh` → `PHASE 10 TESTS: 17/17`: CONFIRMED
- `bash tests/phase-08/test_canonical_byte_equality.sh` → PASS: CONFIRMED
- `bash tests/phase-09/run.sh` → `PHASE 09 TESTS: 28/28`: CONFIRMED (no regression on non-brownfield pages)
- `bash tests/phase-09.1/run.sh` → `PHASE 09.1 TESTS: 11/11`: CONFIRMED (no extraction-invariant regression on §5 edit)

---
*Phase: 10-brownfield-scan-bootstrap*
*Completed: 2026-04-17*
