---
phase: 10-brownfield-scan-bootstrap
verified: 2026-04-18T19:30:00Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 10/11
  gaps_closed:
    - "Byte-exact fixture tests prove `bootstrap` produces identical output on sample vaults across runs (BRWN-21 dual golden contract: transformed-output + skip-artifact per D-07)"
  gaps_remaining: []
  regressions: []
  closure_commits:
    - "8b7d5b4 fix(phase-10): pin created_at in fixture tests via BROWNFIELD_FIXTURE_CREATED_AT override"
    - "db9a22a docs(10-06): complete fixture-created-at-override plan"
---

# Phase 10 Verification — Brownfield Scan + Bootstrap

**Phase Goal:** A user with a real existing Obsidian vault can run `bin/brownfield.sh scan` safely (no vault mutation) and `bin/brownfield.sh bootstrap` confidently (mechanical-only, idempotent, byte-exact reproducible) without corrupting frontmatter or losing content.

**Verified:** 2026-04-18T19:30:00Z
**Status:** passed
**Plans:** 6 plans (10-01 harness, 10-02 scan, 10-03 bootstrap, 10-04 schema/lint/ingest wiring, 10-05 docs + VERIFICATION, 10-06 fixture-created-at-override gap closure)
**Re-verification:** Yes — BRWN-21 gap closed via plan 10-06 (commits 8b7d5b4, db9a22a). Prior verification on 2026-04-18T18:40:51Z returned `gaps_found` with score 10/11 on the transformed-output byte-equality contract; this re-verification confirms the gap is closed and no regressions introduced.

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | `bin/brownfield.sh scan` writes `.brownfield/REPORT.md` with inventory, confidence labels, and signal traces without mutating vault content (BRWN-01) | VERIFIED | `tests/phase-10/test_brownfield_scan_report.sh` passes (SHA-256 snapshot before/after proves no mutation); `tests/phase-10/test_brownfield_scan_confidence.sh` passes; `bin/brownfield.sh:scan` code path is PyYAML-only with no write outside `.brownfield/REPORT.md` |
| 2  | `scan` REPORT.md lists unclassifiable pages under "Needs human judgment" with prose open-questions (BRWN-02) | VERIFIED | `tests/phase-10/test_brownfield_scan_unknown.sh` passes; asserts section header present + question-framed prose ending with `?` |
| 3  | `bootstrap --apply` is idempotent — two runs produce zero-byte diff (BRWN-03) | VERIFIED | `tests/phase-10/test_brownfield_bootstrap_idempotent.sh` passes — runs --apply twice on multi-file vault, asserts recursive SHA-256 set matches; per-file sentinel-check (bootstrap_stage: bootstrapped) at bin/brownfield.sh:324 provides mechanical gate |
| 4  | `bootstrap` touches only mechanical transforms (sentinel frontmatter, SHA hashing, skeleton files, YAML normalization) (BRWN-04) | VERIFIED | Body-preservation assertions in every `test_brownfield_bootstrap_apply_*.sh`; `bin/brownfield.sh` contains no LLM calls (grep confirms no curl/wget/anthropic/openai); typed-merge policy in bin/lib/brownfield_yaml.py:354-391 enforces preservation |
| 5  | `bootstrap` preserves page bodies verbatim (BRWN-05) | VERIFIED | Body-preservation python block in each apply test extracts post-`---` body bytes and asserts equality with original input; now further confirmed by full-file byte-equality passing at calendar date 2026-04-18 (all 5 apply_* tests PASS) |
| 6  | `bootstrap` uses ruamel.yaml round-trip preserving comments + key order (BRWN-06) | VERIFIED | `bin/lib/brownfield_yaml.py` imports `from ruamel.yaml import YAML` with `typ='rt'`; `test_brownfield_bootstrap_apply_comments.sh` PASS (byte-equal against fixture) — semantic AND byte-exact comment preservation both verified |
| 7  | `bootstrap_stage` enum (`raw \| bootstrapped \| verified`) documented in AGENTS.md §5 as narrowly-scoped brownfield onboarding sentinel, NOT a substitute for claim-level provenance (BRWN-07) | VERIFIED | `tests/phase-10/test_agents_section_5_bootstrap_stage.sh` passes; `tests/phase-10/test_agents_template_parity_section_5.sh` passes; `tests/phase-10/test_claude_sync_byte_equal.sh` passes; manual grep confirms AGENTS.md:302 and CLAUDE.md:302 contain the row with all 5 required phrases |
| 8  | `bin/lint.sh --ci` downgrades allowlist findings from error to info when `bootstrap_stage: bootstrapped` (scope: `--ci` mode only per I-1) (BRWN-08) | VERIFIED | `tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh` passes (asserts severity=info); `tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh` passes (asserts no false-positive); `bin/lint.sh:1709-1713` locates the downgrade inside `if CI_MODE:` |
| 9  | `bin/lint.sh` new `brownfield` category reports bootstrapped-page counts + warns on pages bootstrapped > 30 days ago (BRWN-09) | VERIFIED | `tests/phase-10/test_lint_brownfield_category_help.sh` passes; `tests/phase-10/test_lint_brownfield_stale_30d.sh` passes |
| 10 | `bin/ingest.sh` strips `bootstrap_stage` + `bootstrap_date` on normal ingest with D-21 verbatim stderr warning (emitted as a single line per W-6) (BRWN-10) | VERIFIED | `tests/phase-10/test_ingest_strip_bootstrap_stage.sh` passes (includes W-6 combined-line grep asserting single-line emission); `tests/phase-10/test_ingest_strip_no_warn_when_absent.sh` passes; `bin/ingest.sh:316-374` contains the BRWN-10 block between `cp` and `compute_hash` |
| 11 | Byte-exact fixture tests prove `bootstrap` produces identical output on sample vaults across runs (dual golden contract per D-07) (BRWN-21) | **VERIFIED** (gap closed) | All 5 parseable-fixture byte-equality tests PASS at system date 2026-04-18 after plan 10-06 added `BROWNFIELD_FIXTURE_CREATED_AT` env override inside `bin/lib/brownfield_yaml.py::build_d14_sentinel_set` (lines 278-291). Fail-loud ValueError on malformed ISO-date inputs confirmed (`OK-fail-loud` sentinel: `BROWNFIELD_FIXTURE_CREATED_AT must be YYYY-MM-DD, got: 'not-a-date'`). Five test files (apply_clean, apply_no_fm, apply_crlf, apply_dataview, apply_comments) export `BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"` adjacent to `BROWNFIELD_FIXTURE_TODAY`. Skip-artifact contract side (test_brownfield_bootstrap_skip_tabs.sh, test_brownfield_bootstrap_skip_dupkeys.sh) continues to pass. Idempotency test continues to pass. Aggregator output: `PHASE 10 TESTS: 32/32`. |

**Score:** 11/11 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/brownfield.sh` | Subcommand dispatcher + scan + bootstrap | VERIFIED | Executable; contains `case "$SUBCOMMAND"` dispatch with scan/bootstrap/suggest(exit 2)/verify(exit 2) branches; --help advertises scan + bootstrap + decision-boundary epigraph; no LLM/network calls |
| `bin/lib/brownfield_classify.py` | Rule-based classifier (D-16) | VERIFIED | Exports `classify_page(rel_path, frontmatter, body, inbound_count=None)` and `unknown_reason()`; `inbound_count` parameter reserved for Phase 11 reuse |
| `bin/lib/brownfield_yaml.py` | ruamel.yaml round-trip helpers + BROWNFIELD_FIXTURE_CREATED_AT override | VERIFIED | Exports `read_fm_body`, `merge_sentinels`, `write_roundtrip`, `FIELD_CLASS_A`, `FIELD_CLASS_B`, `VALID_ENUMS`, `build_d14_sentinel_set` (now with env-var override lines 278-291), `split_frontmatter`, `infer_id_from_filename`, `extract_h1`, `file_mtime_iso`; imports `ruamel.yaml.YAML(typ='rt')`; module docstring updated to reference override |
| `bin/ingest.sh` | BRWN-10 strip pass | VERIFIED | Line 316 contains `# BRWN-10: strip brownfield-scoped fields`; strip block is between `cp` and `compute_hash`; python3 heredoc scopes to first `---...---` block; D-21 stderr single-line emission verified by W-6 combined-line grep |
| `bin/lint.sh` | BRWN-08 downgrade + brownfield category + 30-day staleness | VERIFIED | Contains `BROWNFIELD_ALLOWLIST = {'yaml', 'provenance', 'orphan'}` (line 882); `BROWNFIELD_BOOTSTRAPPED_PAGES` set built from frontmatter; `_bf_downgrade` helper inside `if CI_MODE:`; brownfield check block gates on `should_run('brownfield')` |
| `AGENTS.md` | §5 bootstrap_stage + bootstrap_date rows | VERIFIED | Lines 302-303 contain both rows with all mandated phrases; byte-synced with CLAUDE.md |
| `CLAUDE.md` | Byte-synced mirror of AGENTS.md | VERIFIED | `cmp -s AGENTS.md CLAUDE.md` exits 0 |
| `schema/AGENTS.template.md` | Template mirrors AGENTS.md §5 edit | VERIFIED | `test_agents_template_parity_section_5.sh` passes (extracts §5 from both files, cmp-equal) |
| `schema/fixtures/canonical-AGENTS.md` | Regenerated canonical fixture | VERIFIED | Contains `bootstrap_stage` + `bootstrap_date` rows; Phase 8-01 byte-equality test (`tests/phase-08/test_canonical_byte_equality.sh`) continues to pass (21/21) |
| `docs/reference/brownfield.md` | Full runbook (≥194 lines) + fixture env-var docs | VERIFIED | 207 lines; contains D-02 decision-boundary verbatim; Class A/B/C taxonomy present; `git reset --hard` rollback recipe present; `[Populated in Phase 11]` stubs ≥2; documents `--ci`-only scope (I-1); uses `gitignore-like patterns` wording (not `gitignore-grammar`); NEW `## Fixture testing environment variables` section at lines 188-199 documents BROWNFIELD_FIXTURE_TODAY + BROWNFIELD_FIXTURE_CREATED_AT with scope warning |
| `docs/quickstart.md` | ruamel.yaml prereq note | VERIFIED | Contains `pip install ruamel.yaml` + `brownfield onboarding` scope qualifier + forward link to `reference/brownfield.md` |
| Test harness: `tests/phase-10/run.sh`, `lib.sh`, 7 fixtures | D-07 dual golden contract scaffolding | VERIFIED | All harness files exist; aggregator emits `PHASE 10 TESTS: 32/32`; all 5 previously-failing apply_* tests now PASS on 2026-04-18 after BROWNFIELD_FIXTURE_CREATED_AT export added |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `bin/brownfield.sh` | `bin/lib/brownfield_classify.py` | python3 heredoc with `sys.path.insert(0, $BROWNFIELD_LIB_DIR)` | WIRED | Import works; classify_page exercised by scan code path |
| `bin/brownfield.sh` | `bin/lib/brownfield_yaml.py` | python3 heredoc import | WIRED | merge_sentinels + write_roundtrip called from bootstrap branch |
| `bin/brownfield.sh scan` | `.brownfield/REPORT.md` | python writes via `REPORT_PATH` | WIRED | test_brownfield_scan_report.sh confirms file written |
| `bin/brownfield.sh bootstrap` | `.brownfield/APPLIED.md` | append on each --apply run | WIRED | test_brownfield_bootstrap_applied_manifest.sh passes |
| `bin/brownfield.sh bootstrap` | `.brownfield/SKIPPED.md` | write on parse-failure | WIRED | test_brownfield_bootstrap_skip_tabs.sh + skip_dupkeys.sh pass |
| `bin/ingest.sh` | `bootstrap_stage` strip | post-cp regex pass | WIRED | test_ingest_strip_bootstrap_stage.sh passes (including W-6 single-line stderr) |
| `bin/lint.sh` | `BROWNFIELD_BOOTSTRAPPED_PAGES` | page-parse phase reads frontmatter | WIRED | test_lint_ci_downgrade_bootstrapped.sh passes |
| `AGENTS.md §5` | `CLAUDE.md §5` | `.githooks/pre-commit` sync-claude | WIRED | test_claude_sync_byte_equal.sh passes |
| `tests/phase-10/test_brownfield_bootstrap_apply_*.sh` | `bin/lib/brownfield_yaml.py::build_d14_sentinel_set` | `BROWNFIELD_FIXTURE_CREATED_AT` env var (new, plan 10-06) | WIRED | 5 test files export `BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"` adjacent to `BROWNFIELD_FIXTURE_TODAY`; build_d14_sentinel_set reads `os.environ.get('BROWNFIELD_FIXTURE_CREATED_AT')` and branches to `datetime.date.fromisoformat()` with fail-loud ValueError on malformed values |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `bin/brownfield.sh scan` REPORT.md | `rows` | `classify_page()` output for each page walked via `os.walk` | YES — real vault pages produce real classification rows | FLOWING |
| `bin/brownfield.sh bootstrap` APPLIED.md | `applied_entries` | per-page write success tracked after `write_roundtrip` | YES — flush after writes, confirmed by applied_manifest test | FLOWING |
| `bin/brownfield.sh bootstrap` SKIPPED.md | `skipped_list` | `read_fm_body` exception handler + duplicate-key pre-scan | YES — tabs-in-yaml + duplicate-yaml-keys fixtures both produce real entries | FLOWING |
| `bin/lint.sh` brownfield findings | `add_finding('warning','brownfield',...)` | `all_pages` walk reading `bootstrap_stage` + `bootstrap_date` from real frontmatter | YES — test_lint_brownfield_stale_30d.sh confirms age-based flagging | FLOWING |
| `build_d14_sentinel_set` `created_at` field | `created_at` | `os.environ.get('BROWNFIELD_FIXTURE_CREATED_AT')` when set, else `file_mtime_iso(path)` | YES — env override path exercised by 5 apply_* tests; production path exercised by all non-fixture callers | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase-10 aggregator | `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh` | `PHASE 10 TESTS: 32/32` | PASS |
| Prior phase: 07 | `bash tests/phase-07/run.sh` | `PHASE 07 TESTS: 22/22` | PASS |
| Prior phase: 08 (canonical byte-equality) | `PYTHONPATH=... bash tests/phase-08/run.sh` | `PHASE 08 TESTS: 21/21` | PASS |
| Prior phase: 09 (lint CI) | `PYTHONPATH=... bash tests/phase-09/run.sh` | `PHASE 09 TESTS: 28/28` | PASS |
| Prior phase: 09.1 (template parity) | `PYTHONPATH=... bash tests/phase-09.1/run.sh` | `PHASE 09.1 TESTS: 11/11` | PASS |
| Individual apply_clean | `bash tests/phase-10/test_brownfield_bootstrap_apply_clean.sh` | `PASS: bootstrap apply clean-frontmatter` | PASS |
| Individual apply_no_fm | `bash tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh` | `PASS: bootstrap apply no-frontmatter` | PASS |
| Individual apply_crlf | `bash tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh` | `PASS: bootstrap apply crlf` | PASS |
| Individual apply_dataview | `bash tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh` | `PASS: bootstrap apply dataview-inline` | PASS |
| Individual apply_comments | `bash tests/phase-10/test_brownfield_bootstrap_apply_comments.sh` | `PASS: bootstrap apply frontmatter-with-comments` | PASS |
| Override semantic: pinned | `BROWNFIELD_FIXTURE_CREATED_AT=2026-04-17 python3 -c "...build_d14_sentinel_set(...)"` | `OK-override: created_at = 2026-04-17 updated_at = 2026-04-18` | PASS |
| Override semantic: fallback | `unset BROWNFIELD_FIXTURE_CREATED_AT; python3 -c "...build_d14_sentinel_set(...)"` | `OK-fallback: created_at = 2026-04-18` | PASS |
| Override semantic: fail-loud | `BROWNFIELD_FIXTURE_CREATED_AT=not-a-date python3 -c "..."` | `OK-fail-loud: BROWNFIELD_FIXTURE_CREATED_AT must be YYYY-MM-DD, got: 'not-a-date'` | PASS |
| Scan --help advertises scan + bootstrap | `bash bin/brownfield.sh --help \| grep -c scan` | matches | PASS |
| AGENTS.md ↔ CLAUDE.md byte-equal | `cmp -s AGENTS.md CLAUDE.md` | exit 0 | PASS |
| No LLM network calls in brownfield.sh | `grep -E 'curl\|wget\|anthropic\|openai' bin/brownfield.sh` | no match | PASS |
| bootstrap dry-run trailing line | `bash bin/brownfield.sh bootstrap --root /tmp/empty 2>&1 \| grep -F '(dry-run) Pass --apply to execute.'` | matches | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| BRWN-01 | 10-02, 10-05 | scan writes REPORT.md with inventory + confidence + no vault mutation | SATISFIED | test_brownfield_scan_report.sh (SHA-256 no-mutation snapshot); test_brownfield_scan_confidence.sh |
| BRWN-02 | 10-02, 10-05 | scan lists unknown pages under "Needs human judgment" with open questions | SATISFIED | test_brownfield_scan_unknown.sh |
| BRWN-03 | 10-03, 10-05 | bootstrap --apply idempotent (2 runs = 0-byte diff) | SATISFIED | test_brownfield_bootstrap_idempotent.sh passes |
| BRWN-04 | 10-03, 10-05 | bootstrap touches only mechanical transforms | SATISFIED | No LLM calls; typed-merge Class A/B/C preservation verified in test_brownfield_bootstrap_typed_merge.sh; body-preservation checks pass in all apply tests |
| BRWN-05 | 10-03, 10-05 | bootstrap preserves bodies verbatim | SATISFIED | Body-preservation python block in apply_* tests passes; now additionally, full-file byte-equality passes |
| BRWN-06 | 10-03, 10-05 | ruamel.yaml round-trip preserves comments + key order | SATISFIED | `bin/lib/brownfield_yaml.py` uses `YAML(typ='rt')`; test_brownfield_bootstrap_apply_comments.sh PASS (byte-equal against fixture with inline comments) |
| BRWN-07 | 10-04, 10-05 | bootstrap_stage documented in AGENTS.md §5 (not claim-level provenance substitute) | SATISFIED | test_agents_section_5_bootstrap_stage.sh passes; template parity + CLAUDE sync tests pass |
| BRWN-08 | 10-04, 10-05 | lint --ci downgrades allowlist findings on bootstrapped pages | SATISFIED | test_lint_ci_downgrade_bootstrapped.sh + test_lint_ci_no_downgrade_when_absent.sh |
| BRWN-09 | 10-04, 10-05 | lint brownfield category + 30-day staleness | SATISFIED | test_lint_brownfield_category_help.sh + test_lint_brownfield_stale_30d.sh |
| BRWN-10 | 10-04, 10-05 | ingest strips bootstrap_stage + bootstrap_date with D-21 single-line stderr | SATISFIED | test_ingest_strip_bootstrap_stage.sh (W-6 combined-line grep) + test_ingest_strip_no_warn_when_absent.sh |
| BRWN-21 | 10-01, 10-03, 10-05, **10-06** | Byte-exact fixture tests across runs (dual golden contract) | SATISFIED | Skip-artifact side (2 unparseable fixtures) passes. Transformed-output side (5 parseable fixtures) now passes on any calendar date after plan 10-06 added `BROWNFIELD_FIXTURE_CREATED_AT` override. Idempotency test passes. Aggregator: 32/32. |

### Anti-Patterns Found

Inherited from `10-REVIEW.md` (ran by gsd-code-reviewer on 2026-04-17T00:00:00Z); reproduced here for context. These are pre-existing observations unchanged by plan 10-06 (which touched only `build_d14_sentinel_set`, the five apply_* tests, and docs/reference/brownfield.md). None of the 3 Warnings block the phase goal as stated; all are deferred per the review disposition.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `bin/brownfield.sh` | 366-400 | Orphan-raw-sources walk uses `pending_writes` only; already-bootstrapped source summaries are excluded, so their raw sources become false-positive orphans on re-runs (WR-01) | Warning | REPORT.md user-visible flip between runs — documented idempotency contract says "zero-byte diff" for vault files; REPORT.md does change. Not goal-blocking for vault integrity but undermines user trust. |
| `bin/brownfield.sh` | 324 | Idempotency skip only fires on `bootstrap_stage == 'bootstrapped'`; pages with `raw` or `verified` are re-written on every run (WR-02) | Warning | Unnecessary disk writes on raw/verified pages. Not yet reachable in Phase 10 (no caller writes those values) but a latent regression once Phase 11 ships |
| `AGENTS.md:302` (+ CLAUDE/template/fixture mirrors) | 302 | Code-span `|` in table cell may mis-render in Obsidian live preview; forward-reference to §11.5 points at Release Workflow, not Brownfield Workflow (WR-03) | Warning | Documentation clarity on Obsidian; not goal-blocking — the field IS documented, the test passes. Future-phase cleanup. |
| `bin/brownfield.sh` + `bin/lint.sh` | various | 5 Info items (code duplication, UTC/local-date mix, ingest pwd assumption, tab-heuristic looseness, non-atomic skeleton write) | Info | None goal-blocking; see 10-REVIEW.md for full write-up |

### Human Verification Required

None. All 11 must-haves are mechanically verified and pass on 2026-04-18. No visual/UX/real-time behavior requires human judgment for this phase.

### Gaps Summary

Phase 10 is fully closed. All six plans (10-01 through 10-05 for the primary feature surface, plus 10-06 for the BRWN-21 gap closure) have shipped and all 11 must-haves are VERIFIED.

**Gap-closure verification (plan 10-06):**

- The `BROWNFIELD_FIXTURE_CREATED_AT` env-var override was added to `bin/lib/brownfield_yaml.py::build_d14_sentinel_set` (lines 278-291), mirroring the existing `BROWNFIELD_FIXTURE_TODAY` precedent.
- The override has three observable modes: (1) set to valid ISO date → pins `created_at`; (2) unset → falls through to `file_mtime_iso()` / today fallback unchanged; (3) set to malformed value → raises `ValueError` containing the variable name (fail-loud, matches mechanical-only brownfield contract D-11).
- Five apply_* test files (`apply_clean`, `apply_no_fm`, `apply_crlf`, `apply_dataview`, `apply_comments`) export the new variable adjacent to the existing `BROWNFIELD_FIXTURE_TODAY` export.
- Seven other `BROWNFIELD_FIXTURE_TODAY`-using tests were deliberately left untouched per the plan's per-test audit (skip-path tests, inline-vault tests, dryrun, help, applied_manifest, idempotent). Each non-touch is documented in 10-06-PLAN.md Task 3.
- Documentation landed in `docs/reference/brownfield.md` under a new `## Fixture testing environment variables` section with a scope warning blockquote (file length: 194 → 207 lines).

**Regression check:** Prior-phase aggregators remain green at their committed totals (07=22/22, 08=21/21, 09=28/28, 09.1=11/11). No unintended side effects from the gap-closure commit.

**Summary claim audit (10-06-SUMMARY.md):** Summary accurately describes the executed work. File count (7 changed: 2 code/doc + 5 tests) matches plan; all sentinel outputs (`OK-override`, `OK-fallback`, `OK-fail-loud`) reproduced independently during re-verification; commit hash `8b7d5b4` matches the single-commit constraint; seven-test audit table matches plan Task 3 rationale; all self-check items confirmed independently.

### Deferred Items

No items from this verification are deferred to later phases. Phase 11 covers suggest/verify (BRWN-11..20) which is orthogonal to the BRWN-21 fixture-date issue that is now closed. Phase 12 covers DEBT-01/02/04 (Obsidian render, agent parity, write-back scenario) which are also orthogonal. The three WR-01/WR-02/WR-03 warnings from `10-REVIEW.md` remain deferred per the review's explicit disposition.

---

_Re-verified: 2026-04-18T19:30:00Z_
_Prior verification: 2026-04-18T18:40:51Z (status: gaps_found, score: 10/11)_
_Gap closure commits: 8b7d5b4, db9a22a (plan 10-06)_
_Verifier: Claude (gsd-verifier)_
