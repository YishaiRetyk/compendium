---
phase: 13-claim-faithfulness-audit
plan: 02
subsystem: tooling
tags: [audit, provenance, locator-resolution, privacy, bash, python3, lint-primitives]

# Dependency graph
requires:
  - phase: 13-01
    provides: "tests/phase-13/ harness (run.sh aggregator, lib.sh fixture + verifier helpers, fixtures/README.md fixture contract)"
provides:
  - "bin/audit-claims.sh deterministic core: FAITH-01 selectors + resolve_locator (FAITH-02 det half) + 9-key finding emitter + group-by-verdict report + checkpoint"
  - "Four priority-ranked FAITH-01 selectors (stale-source -> inferred/tentative -> recency -> high-fanout), --sample cap, no-silent-caps selected/skipped log (D-09)"
  - "resolve_locator reading the RAW source at path: (D-11): #sec slug-tolerant, #para, #t, #p via <!-- page: N --> markers (D-05), #img->skipped-nontext, degrades to insufficient-locator"
  - "Interim frontmatter-only --emit-worklist privacy partition (REVIEW HIGH-2); cloud-by-default verifier contract (HIGH-1); generated artifacts stamped privacy: local_only (HIGH-B)"
  - "16 deterministic-path tests under tests/phase-13/"
affects: [13-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "bash arg-parse -> single egress-free python3 heredoc (mirrors bin/lint.sh)"
    - "copy-not-import of lint primitives (PROV_RE, EPISTEMIC_INLINE_RE, parse_frontmatter, hash-drift, inbound_links, git-diff) with a COPIED-FROM manifest comment"
    - "9-key finding dict as a JSON superset of lint's 4-key tuple (SC-6)"

key-files:
  created:
    - bin/audit-claims.sh
    - tests/phase-13/test_select_stale_source.sh
    - tests/phase-13/test_select_epistemic.sh
    - tests/phase-13/test_select_recency.sh
    - tests/phase-13/test_select_high_fanout.sh
    - tests/phase-13/test_sampling_cap_logging.sh
    - tests/phase-13/test_resolve_sec.sh
    - tests/phase-13/test_resolve_para.sh
    - tests/phase-13/test_resolve_p_marked.sh
    - tests/phase-13/test_resolve_p_unmarked.sh
    - tests/phase-13/test_resolve_img.sh
    - tests/phase-13/test_resolve_missing_raw.sh
    - tests/phase-13/test_no_circular_verify.sh
    - tests/phase-13/test_output_schema.sh
    - tests/phase-13/test_json_lint_compat.sh
    - tests/phase-13/test_no_page_mutation.sh
    - tests/phase-13/test_checkpoint_advance.sh
    - tests/phase-13/test_report_privacy_local_only.sh
    - tests/phase-13/test_resolve_locator_edges.sh
    - tests/phase-13/test_path_traversal.sh
    - tests/phase-13/test_worklist_privacy_partition.sh
  modified: []

key-decisions:
  - "Symmetric --emit-worklist / --apply-verdicts worklist exchange (research Open-Q1 recommendation)"
  - "Verifier locality is explicit-only: --local-verifier <cmd> is sugar for --verifier <cmd> --allow-local; no implicit locality inference (HIGH-1)"
  - "Multi-run tests pin selection via committed fixtures + explicit --since SEED so a prior run's checkpoint cannot suppress recency-based selection (deviation Rule 3)"

patterns-established:
  - "resolve_locator returns (passage|None, verdict_override|None) so #img/#p degrades stay first-class without exceptions"
  - "Generated control-plane artifacts (audit-report.md, audit-state.md) default to privacy: local_only to avoid mislabeling slug-/rationale-bearing output as cloud-safe"

requirements-completed: [FAITH-01, FAITH-02, FAITH-03]

# Metrics
duration: 40min
completed: 2026-06-01
---

# Phase 13 Plan 02: Claim Faithfulness Audit — Deterministic Core Summary

**`bin/audit-claims.sh` deterministic core: four priority-ranked FAITH-01 selectors, a raw-source `resolve_locator` (D-11) for every locator type, and a 9-key superset finding emitter with a group-by-verdict report + checkpoint — zero network/subprocess egress, verdict left as a declared-enum `insufficient` stub for Plan 03.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-06-01
- **Completed:** 2026-06-01
- **Tasks:** 2
- **Files modified:** 22 (1 script created, 20 tests created, 1 canary removed)

## Accomplishments
- `bin/audit-claims.sh` (859 lines): bash arg-parse mirroring lint.sh → single egress-free python3 heredoc.
- FAITH-01: four selectors (stale-source, inferred/tentative, recency, high-fanout) unioned, deduped, priority-ranked (stale → epistemic → recency → fanout), capped at `--sample`, with a `selected=N skipped=M` no-silent-caps info finding (D-09).
- FAITH-02 deterministic half: `resolve_locator` reads the RAW file at the source page's `path:` (D-11, proven by `test_no_circular_verify`), handling `#sec:` (slug/case/space tolerant), `#para` (frontmatter/heading-skipping, fenced-code-as-one-unit), `#t` timestamp, `#p`/`#p-a-b` via `<!-- page: N -->` markers (D-05), `#img` → `skipped-nontext`, and graceful `insufficient-locator` for missing-raw / unknown-source / malformed-locator / unmarked-`#p` / path-traversal.
- FAITH-03: 9-key finding dict (JSON superset of lint's 4 keys, SC-6), group-by-verdict `audit-report.md`, and `audit-state.md` checkpoint that advances on no-finding runs (D-15). Both artifacts stamped `privacy: local_only` (HIGH-B). No wiki content page mutated (SC-5).
- Interim frontmatter-only `--emit-worklist` privacy partition (HIGH-2): `local_only` passages withheld absent `--allow-local`; cloud-by-default verifier contract with explicit-only locality (HIGH-1).
- All 20 phase-13 tests pass: `PHASE 13 TESTS: 20/20`.

## Task Commits

1. **Task 1: audit-claims.sh skeleton + FAITH-01 selectors** — `f1c5bb0` (feat)
2. **Task 2: resolve_locator + 9-key emitter + report + checkpoint** — `d77496f` (feat)

## Files Created/Modified
- `bin/audit-claims.sh` — the deterministic core (selectors, resolver, emitter, report, checkpoint).
- `tests/phase-13/test_select_*.sh` + `test_sampling_cap_logging.sh` — FAITH-01 selector + cap-logging tests.
- `tests/phase-13/test_resolve_*.sh`, `test_no_circular_verify.sh`, `test_resolve_locator_edges.sh`, `test_path_traversal.sh` — FAITH-02 locator + security tests.
- `tests/phase-13/test_output_schema.sh`, `test_json_lint_compat.sh`, `test_no_page_mutation.sh`, `test_checkpoint_advance.sh`, `test_report_privacy_local_only.sh`, `test_worklist_privacy_partition.sh` — FAITH-03 + privacy tests.
- `tests/phase-13/test_harness_red_canary.sh` — REMOVED (Wave-0 canary; its purpose was fulfilled once `bin/audit-claims.sh` exists; Rule-3 prior-test-obsolescence per the plan).

## Decisions Made
- Worklist exchange is symmetric `--emit-worklist` / `--apply-verdicts <file>` with the merge key pinned to `(path, line, source_id, locator)` so Plan 03 slots in without rework.
- Locator captured by `PROV_RE` lacks its leading `#`; `resolve_locator` and the tuple builder canonicalize to the `#`-prefixed form so either shape resolves.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Multi-run tests suppressed by the prior run's checkpoint**
- **Found during:** Task 2 (tests that invoke the audit twice in one fixture repo)
- **Issue:** The first invocation writes `audit-state.md` with `last_audit_commit`; the second invocation reads it and runs the recency selector as `git diff <checkpoint>...HEAD`. Because the fixtures were uncommitted, that diff was empty, so no claim was selected on the second run — yielding an empty worklist/findings that broke `test_worklist_privacy_partition`, `test_path_traversal`, and `test_resolve_locator_edges`.
- **Fix:** Those multi-run tests now commit their fixtures and pass an explicit `--since <SEED>` (the pre-fixture seed commit), making recency selection deterministic and checkpoint-independent. This is a test-harness correctness fix, not a change to the script's documented selection semantics.
- **Files modified:** tests/phase-13/test_worklist_privacy_partition.sh, test_path_traversal.sh, test_resolve_locator_edges.sh, test_json_lint_compat.sh
- **Verification:** `bash tests/phase-13/run.sh` → `PHASE 13 TESTS: 20/20`, stable across 3 consecutive runs.
- **Committed in:** d77496f (Task 2 commit)

**2. [Rule 3 - Blocking] Inline-Python `\"` escapes broke the test heredocs**
- **Found during:** Task 2 (`test_json_lint_compat`, `test_output_schema`)
- **Issue:** `f"...{f[\"key\"]}..."` inside a bash single-quoted `python3 -c '...'` block left a literal backslash before the quote, raising `SyntaxError: unexpected character after line continuation character`.
- **Fix:** Replaced the f-string interpolations with `"..." + str(f["key"])` concatenation (no backslash-escaped quotes).
- **Files modified:** tests/phase-13/test_json_lint_compat.sh, test_output_schema.sh
- **Verification:** Both tests pass.
- **Committed in:** d77496f (Task 2 commit)

**3. [Rule 1 - Bug] Acceptance grep `! grep -q 'pending-verifier'` tripped by explanatory comments**
- **Found during:** Task 2 acceptance-criteria check
- **Issue:** Two comments contained the literal token `pending-verifier` while explaining we deliberately do NOT use it; the acceptance grep forbids the literal string anywhere.
- **Fix:** Reworded both comments to "placeholder token", preserving the meaning without the forbidden literal.
- **Files modified:** bin/audit-claims.sh
- **Verification:** `grep -q 'pending-verifier' bin/audit-claims.sh` → absent; tests still 20/20.
- **Committed in:** d77496f (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 bug, 1 blocking)
**Impact on plan:** All fixes were test-harness or comment hygiene; the script's documented behavior is unchanged. No scope creep.

## Issues Encountered
None beyond the deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Deterministic core is complete and fully tested; the genuinely-new 20% (full §13 three-level privacy resolver + verdict/verifier dispatch + FAITH-04 egress redaction) is isolated for Plan 03.
- Plan 03 hooks are pre-pinned: `--apply-verdicts` merge key `(path, line, source_id, locator)`; cloud-by-default verifier contract; the interim frontmatter-only worklist guard to be upgraded (not relaxed) into the full precedence resolver; the HIGH-C redaction of local-only `skipped-privacy` metadata on cloud-facing stdout.
- The verdict stub (`insufficient` / "verifier not run") stays inside the declared enum so `test_output_schema` and downstream JSON consumers remain valid at the plan boundary.

## Self-Check: PASSED

- `bin/audit-claims.sh` exists (859 lines ≥ 250), contains `def resolve_locator`, no egress primitives.
- Both task commits present: `f1c5bb0`, `d77496f`.
- All test files present; canary removed.
- `bash tests/phase-13/run.sh` → `PHASE 13 TESTS: 20/20`.

---
*Phase: 13-claim-faithfulness-audit*
*Completed: 2026-06-01*
