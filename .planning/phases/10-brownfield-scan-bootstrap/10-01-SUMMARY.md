---
phase: 10-brownfield-scan-bootstrap
plan: "01"
subsystem: testing
tags: [brownfield, fixtures, byte-equality, test-harness, ruamel-yaml, crlf]

# Dependency graph
requires:
  - phase: 09-collaborative-pr-workflow-ci-lint-gate
    provides: tests/phase-09/run.sh + lib.sh pattern (09→10 rename blueprint)
  - phase: 08-two-track-setup-wizard-manual
    provides: tests/phase-08/lib.sh assert_byte_equal + byte-equality fixture pattern
provides:
  - Phase 10 test aggregator (tests/phase-10/run.sh emitting 'PHASE 10 TESTS: N/M')
  - Shared test helpers library (tests/phase-10/lib.sh with 5 helpers)
  - 7 byte-frozen fixture directories (5 parseable + 2 unparseable per D-07)
  - Dual golden contract encoding (parseable = input/+expected/; unparseable = input/+expected-skipped-entry.md)
  - Canonical bootstrap field-order contract (expected/page.md defines Plan 03's output shape)
  - CRLF fixture preservation contract (.gitattributes -text exception)
  - 2 Wave-1 self-check tests (test_fixtures_exist.sh, test_harness_self_check.sh)
affects:
  - 10-02 (scan) — writes classification into REPORT.md
  - 10-03 (bootstrap) — apply must produce byte-equal expected/page.md for the 5 parseable fixtures
  - 10-04 (lint/ingest extensions) — test harness green gate for BRWN-08/09/10 coverage
  - 10-05 (docs + §5 schema rows) — same aggregator asserts docs skeleton

# Tech tracking
tech-stack:
  added: []  # No new runtime deps; ruamel.yaml arrives in Plan 10-03
  patterns:
    - "Dual golden contract (D-07): parseable fixtures carry input/+expected/; unparseable fixtures carry input/+expected-skipped-entry.md"
    - "CRLF preservation via .gitattributes -text exception for a single fixture input"
    - "Fixture date freeze (2026-04-17) to keep expected/ byte-stable across runs"
    - "Canonical field-order contract: expected/page.md is the implementation constraint on Plan 03's output rendering"

key-files:
  created:
    - tests/phase-10/run.sh
    - tests/phase-10/lib.sh
    - tests/phase-10/fixtures/README.md
    - tests/phase-10/fixtures/clean-frontmatter/input/page.md
    - tests/phase-10/fixtures/clean-frontmatter/expected/page.md
    - tests/phase-10/fixtures/no-frontmatter/input/page.md
    - tests/phase-10/fixtures/no-frontmatter/expected/page.md
    - tests/phase-10/fixtures/crlf/input/page.md
    - tests/phase-10/fixtures/crlf/expected/page.md
    - tests/phase-10/fixtures/dataview-inline/input/page.md
    - tests/phase-10/fixtures/dataview-inline/expected/page.md
    - tests/phase-10/fixtures/frontmatter-with-comments/input/page.md
    - tests/phase-10/fixtures/frontmatter-with-comments/expected/page.md
    - tests/phase-10/fixtures/tabs-in-yaml/input/page.md
    - tests/phase-10/fixtures/tabs-in-yaml/expected-skipped-entry.md
    - tests/phase-10/fixtures/duplicate-yaml-keys/input/page.md
    - tests/phase-10/fixtures/duplicate-yaml-keys/expected-skipped-entry.md
    - tests/phase-10/test_fixtures_exist.sh
    - tests/phase-10/test_harness_self_check.sh
  modified:
    - .gitattributes  # +5 lines: Phase 10 fixtures + single crlf -text exception

key-decisions:
  - "Canonical field-injection order encoded in expected/ fixtures: existing keys keep their positions; absent keys append in the D-14 grouping order (inferred → empty defaults → fixed defaults → brownfield)"
  - "CRLF fixture preserved via .gitattributes -text attribute on that single input file (git ls-files --eol confirms i/crlf w/crlf attr/-text)"
  - "tabs-in-yaml uses parse_error: {PARSE_ERROR} placeholder — actual ruamel.yaml error string is version-dependent; Plan 03 either substitutes a stable placeholder or regenerates this fixture"
  - "duplicate-yaml-keys exists in addition to tabs-in-yaml per CONTEXT.md §Specifics bullet 8 — hedge against ruamel.yaml parsing tabs permissively; guarantees the skip-artifact contract is testable"
  - "REPO_ROOT .git check uses [ -e ] not [ -d ] to accept both real-repo and git-worktree layouts (worktree .git is a file pointing to the main repo's gitdir)"

patterns-established:
  - "Dual golden contract: parseable = byte-equal transformed output; unparseable = byte-equal SKIPPED.md entry block + unmutated input. Both shapes share the same cmp -s gate."
  - "CRLF exception via .gitattributes -text: the pattern for keeping a single file byte-exact on disk when the repo defaults to LF normalization."
  - "Fixture date freeze: freezing dates to a single ISO 8601 value (2026-04-17) in expected/ keeps fixtures byte-stable across runs; Plan 03 needs a test-mode clock shim to match."
  - "Acceptance-criterion-driven wording: plan V4 forbids any 'phase-09' literal in tests/phase-10/ — README citations of prior-phase invariants must reword to 'the prior-phase fixture-seeding invariant' or similar."

requirements-completed: [BRWN-21]

# Metrics
duration: ~7min
completed: 2026-04-17
---

# Phase 10 Plan 01: Wave-0 Test Harness + Byte-Frozen Fixtures Summary

**Phase 10 test aggregator, shared helpers, and 7 byte-frozen brownfield fixtures encoding the D-07 dual golden contract for BRWN-21; `bash tests/phase-10/run.sh` emits `PHASE 10 TESTS: 2/2` today.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-04-17T08:46:00Z (approx, matches commit 5cd3c9b)
- **Completed:** 2026-04-17T08:53:00Z
- **Tasks:** 2
- **Files created:** 19
- **Files modified:** 1 (.gitattributes)

## Accomplishments

- **Test harness aggregator** (`tests/phase-10/run.sh`) cloned from `tests/phase-09/run.sh` with `09→10` rename only; emits the load-bearing `PHASE 10 TESTS: N/M` summary line consumed by Plans 02-04 assertions.
- **Shared helpers library** (`tests/phase-10/lib.sh`) exports 5 named functions: `make_fixture_repo`, `assert_byte_equal`, `assert_exit_code`, `assert_file_exists`, `assert_grep`. `assert_byte_equal` prints both the diff preview and the regeneration recipe on failure.
- **7 byte-frozen fixture directories** covering the full D-07 canonical roster plus the CONTEXT.md §Specifics bullet-8 hedge:
  - **Parseable (5):** clean-frontmatter, no-frontmatter, crlf, dataview-inline, frontmatter-with-comments — all carry `input/page.md` + `expected/page.md`.
  - **Unparseable (2):** tabs-in-yaml, duplicate-yaml-keys — all carry `input/page.md` + `expected-skipped-entry.md`.
- **CRLF preservation contract** via `.gitattributes` `-text` exception for the one file that must retain literal `\r\n` bytes on disk (`git ls-files --eol` confirms `i/crlf w/crlf attr/-text`).
- **2 Wave-1 self-check tests** validating every fixture is present with the correct sub-artifacts AND that the harness helpers themselves behave correctly.
- **Canonical field-order contract** encoded in every parseable `expected/page.md` — Plan 03's `bin/brownfield.sh bootstrap --apply` must produce byte-identical output.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create tests/phase-10/ harness (run.sh + lib.sh) + fixtures README** — `5cd3c9b` (test)
2. **Task 2: Author 7 byte-frozen fixture directories + 2 self-check tests** — `f35a5ff` (test)
3. **Rule 3 auto-fix: remove 'Phase 09-01' citation from fixtures README** — `3b8b979` (docs)

## Files Created/Modified

### Created (19 files)

- `tests/phase-10/run.sh` — Phase 10 aggregator; wraps `for t in test_*.sh` and prints the `PHASE 10 TESTS: N/M` summary.
- `tests/phase-10/lib.sh` — shared helpers (`REPO_ROOT`, `make_fixture_repo`, `assert_byte_equal`, `assert_exit_code`, `assert_file_exists`, `assert_grep`).
- `tests/phase-10/fixtures/README.md` — documents the 7-fixture roster, dual golden contract, EOL policy (incl. the `-text` exception), fixture-date freeze, and regeneration recipe.
- `tests/phase-10/fixtures/clean-frontmatter/{input,expected}/page.md` — minimal valid frontmatter; tests Class A/B preserve.
- `tests/phase-10/fixtures/no-frontmatter/{input,expected}/page.md` — bare markdown; tests the full D-14 sentinel set injection.
- `tests/phase-10/fixtures/crlf/{input,expected}/page.md` — CRLF input (literal `\r\n` bytes on disk), LF expected; tests ruamel.yaml's normalize-on-write behavior per D-03.
- `tests/phase-10/fixtures/dataview-inline/{input,expected}/page.md` — body contains Dataview `foo::` fields; asserts bootstrap leaves body untouched.
- `tests/phase-10/fixtures/frontmatter-with-comments/{input,expected}/page.md` — YAML comments between fields; tests ruamel.yaml round-trip comment preservation per BRWN-06.
- `tests/phase-10/fixtures/tabs-in-yaml/input/page.md` + `expected-skipped-entry.md` — literal tab between `type:` and `concept`; primary skip-artifact fixture.
- `tests/phase-10/fixtures/duplicate-yaml-keys/input/page.md` + `expected-skipped-entry.md` — two `type:` lines; guaranteed-reject skip-artifact fixture.
- `tests/phase-10/test_fixtures_exist.sh` — asserts all 7 fixtures present with correct sub-artifacts + crlf input contains CR bytes.
- `tests/phase-10/test_harness_self_check.sh` — asserts REPO_ROOT resolves, `assert_byte_equal` works on identical files, `make_fixture_repo` produces a working git repo.

### Modified (1 file)

- `.gitattributes` — adds 5 lines: a comment documenting the Phase 10 fixture policy plus the single `tests/phase-10/fixtures/crlf/input/page.md -text` exception that preserves the literal CRLF bytes.

## Decisions Made

### Canonical field-injection order (encoded in expected/ fixtures)

The expected/ fixtures define the order Plan 03 must produce. The order:

1. **Existing keys** retain their original positions (ruamel.yaml round-trip semantics).
2. **Absent keys** are appended in D-14 grouping order:
   - Inferred: `id`, `title`, `created_at`, `updated_at`
   - Empty defaults: `type` (`""`), `summary`, `knowledge_domain`, `sources`, `tags`, `domains`, `aliases`, `supersedes` (`null`), `superseded_by` (`null`)
   - Fixed defaults: `status` (`active`), `epistemic_status` (`tentative`), `privacy` (`local_only`), `has_contradictions` (`false`)
   - Brownfield: `bootstrap_stage` (`bootstrapped`), `bootstrap_date` (`2026-04-17`)
3. **YAML rendering:** `null` (not `~`); quoted empty strings (`''`); `[]` for empty lists; unquoted booleans.

### CRLF preservation approach

Rather than convince git to preserve the CRLF-input fixture via path-specific `eol=crlf` (which fights the repo default), I added a single `-text` attribute on the one file. `-text` disables all text/EOL processing, so git stores and checks out the bytes verbatim. Verified via `git ls-files --eol` showing `i/crlf w/crlf attr/-text` for exactly that path and `i/lf w/lf attr/text eol=lf` for everything else.

### tabs-in-yaml parse-error placeholder

The actual parse error string from ruamel.yaml is version-dependent, so the skip-artifact file uses a literal `{PARSE_ERROR}` placeholder in the `parse_error:` line. Plan 03 must either:
- (a) substitute a stable placeholder in its own `SKIPPED.md` output so this fixture stays valid, OR
- (b) regenerate this fixture with the real error message produced by the pinned ruamel.yaml version.

Plan 03's acceptance criteria should specify the resolution; this fixture documents the problem, not its solution.

### duplicate-yaml-keys as the guaranteed-reject hedge

Per CONTEXT.md §Specifics bullet 8: "Fixture 3 (tabs-in-yaml) is the canonical skip-artifact fixture — if ruamel.yaml parses it (some versions are permissive), add a second unparseable fixture (e.g., duplicate-yaml-keys or non-mapping-root) to ensure the skip-artifact contract is tested." I included both — tabs-in-yaml per D-07 roster AND duplicate-yaml-keys as the version-independent skip-artifact guarantee.

### REPO_ROOT `.git` check uses `[ -e ]` not `[ -d ]`

In a normal repo `.git` is a directory. In a git worktree `.git` is a file containing `gitdir: <path>`. The self-check test was initially written with `[ -d "$REPO_ROOT/.git" ]` and failed in the worktree during execution. Fixed to `[ -e ]` which accepts both layouts. (See Deviations below — this was caught by running the test in-place rather than a post-hoc review.)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] `test_harness_self_check.sh` incompatible with git worktrees**
- **Found during:** Task 2 (running the freshly-authored self-check in this worktree)
- **Issue:** `[ -d "$REPO_ROOT/.git" ]` fails in git-worktree checkouts because `.git` is a file (containing `gitdir: <path>`), not a directory. This would have broken every future worktree-based execution of the Phase 10 harness.
- **Fix:** Changed the check to `[ -e "$REPO_ROOT/.git" ]` which accepts both real-repo and worktree layouts. Added a code comment documenting the reason.
- **Files modified:** `tests/phase-10/test_harness_self_check.sh`
- **Verification:** `bash tests/phase-10/run.sh` goes from `1/2` → `2/2`; works in both the worktree (where the bug fired) and a hypothetical non-worktree checkout.
- **Committed in:** `f35a5ff` (bundled into Task 2 commit — the fix was made before the Task 2 commit landed)

**2. [Rule 3 — Blocking] README.md cited "Phase 09-01" which tripped the V4 acceptance check**
- **Found during:** Post-Task-2 full verification run
- **Issue:** Plan V4 mandates `! grep -rE 'phase-09|Phase 09|PHASE 09' tests/phase-10/`. The fixtures README had a historical citation `Phase 09-01 D invariant: "All seeded .md fixtures use LF + UTF-8"`. Informationally correct, but blocks the V4 mechanical check.
- **Fix:** Reworded to `the prior-phase fixture-seeding invariant: "All seeded .md fixtures use LF + UTF-8"`. Same information content; no literal `Phase 09` string.
- **Files modified:** `tests/phase-10/fixtures/README.md`
- **Verification:** `grep -rE 'phase-09|Phase 09|PHASE 09' tests/phase-10/` returns no matches.
- **Committed in:** `3b8b979` (separate commit — the README fix is a distinct logical operation from the fixture authoring that preceded it)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes necessary. #1 prevented the test harness from running correctly in worktree mode (the very mode being used to execute this plan). #2 was a mechanical acceptance-check failure with no semantic consequence; the fix preserves the historical reference via rewording.

## Issues Encountered

- **CRLF-vs-.gitattributes interaction.** The repo's default `*.md text eol=lf` in `.gitattributes` would have normalized the `crlf/input/page.md` fixture to LF on commit, defeating its purpose. Resolved by adding a single `-text` attribute override for that one path. Verified via `git ls-files --eol` showing `i/crlf w/crlf attr/-text` in the index.
- **Field order determinism for Plan 03.** The expected/ fixtures had to encode a specific field order that Plan 03's not-yet-written bootstrap code must reproduce exactly. Decided to document this as a deliberate implementation constraint in the README (and in the fixture key-decisions) rather than treat it as a "whatever ruamel produces" contract, because the latter would make these fixtures effectively untestable.

## User Setup Required

None — no external service configuration needed. The `ruamel.yaml` runtime dep arrives in Plan 10-03 (bootstrap implementation), not here.

## Handoff Notes

### To Plan 10-02 (`bin/brownfield.sh scan`)

- **REPORT.md section structure** per CONTEXT.md §D-04: four sections for parseable files (`bootstrapped-successfully`, `bootstrapped-with-preserved-collisions`, `bootstrapped-with-schema-warnings`, `Needs human judgment`). Scan writes the `Needs human judgment` tail with the confidence/signal-trace shape per D-17/D-18.
- The `tabs-in-yaml` and `duplicate-yaml-keys` fixtures will be YAML-parse targets during scan too — scan should emit its own per-file classification trace and not write them to SKIPPED.md (that's bootstrap's job per D-05).

### To Plan 10-03 (`bin/brownfield.sh bootstrap --apply`)

- **Byte-equality contract:** For each of the 5 parseable fixtures, running `bin/brownfield.sh bootstrap --apply` on `tests/phase-10/fixtures/<name>/input/` MUST produce output byte-identical to `tests/phase-10/fixtures/<name>/expected/page.md`. The `assert_byte_equal` helper in `tests/phase-10/lib.sh` prints a regeneration recipe on failure.
- **Date freeze:** The expected/ fixtures hardcode `2026-04-17` for `created_at`, `updated_at`, and `bootstrap_date`. Plan 03 needs a test-mode clock shim — either a `BROWNFIELD_TODAY=2026-04-17` env var, a `--today` flag, or an injectable `date.today()` — so the fixtures stay byte-stable on non-2026-04-17 runs.
- **Canonical field order:** Plan 03's injection order must match the documented order in this plan (existing keys keep their positions; absent keys append in D-14 grouping order).
- **CRLF normalization:** The `crlf` fixture's input is literal `\r\n` bytes; the expected is LF. ruamel.yaml normalizes CRLF to LF on write per D-03. Plan 03 must not attempt to preserve CRLF in the output.
- **Skip-artifact contract:** For `tabs-in-yaml` and `duplicate-yaml-keys`, running bootstrap MUST leave `input/page.md` unchanged (byte-equal to pre-run) AND emit a SKIPPED.md entry block byte-equal to `expected-skipped-entry.md`.
- **`{PARSE_ERROR}` placeholder:** The `tabs-in-yaml/expected-skipped-entry.md` uses a literal `{PARSE_ERROR}` placeholder because the actual ruamel.yaml error string is version-dependent. Plan 03 must either substitute a stable placeholder in its emitted `SKIPPED.md` or regenerate this fixture with the pinned-version error string.

### To Plan 10-04 (lint/ingest extensions)

- The aggregator `tests/phase-10/run.sh` is the green gate for BRWN-08 (lint downgrade), BRWN-09 (brownfield category 30-day staleness), BRWN-10 (ingest strip). Drop `test_brwn08_*.sh`, `test_brwn09_*.sh`, `test_brwn10_*.sh` files; the `shopt -s nullglob for t in test_*.sh` loop picks them up automatically.

### To Plan 10-05 (AGENTS.md §5 + docs)

- Same aggregator continues to wrap docs skeleton tests; no test-harness changes needed in 10-05.

## Next Phase Readiness

- **Wave 1 deliverable complete.** `bash tests/phase-10/run.sh` emits `PHASE 10 TESTS: 2/2` and exits 0.
- **BRWN-21 scaffolding is in place.** Byte-frozen fixtures + dual golden contract + self-check tests form the mechanical green/red gate for Plans 02-04.
- **No blockers** for Plan 02 (scan) or Plan 03 (bootstrap). Both plans can write tests against these fixtures without modifying the harness aggregator.

## Self-Check: PASSED

Verified post-SUMMARY that all claimed files exist and all claimed commits are in git history:

- `tests/phase-10/run.sh`: FOUND
- `tests/phase-10/lib.sh`: FOUND
- `tests/phase-10/fixtures/README.md`: FOUND
- `tests/phase-10/test_fixtures_exist.sh`: FOUND
- `tests/phase-10/test_harness_self_check.sh`: FOUND
- All 14 fixture files: FOUND (verified earlier via structural acceptance check)
- `.gitattributes` with new -text line: FOUND
- Commit `5cd3c9b`: FOUND
- Commit `f35a5ff`: FOUND
- Commit `3b8b979`: FOUND
- `bash tests/phase-10/run.sh` emits `PHASE 10 TESTS: 2/2`: CONFIRMED

---
*Phase: 10-brownfield-scan-bootstrap*
*Completed: 2026-04-17*
