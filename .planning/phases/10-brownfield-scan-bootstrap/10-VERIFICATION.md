---
phase: 10-brownfield-scan-bootstrap
verified: 2026-04-18T18:40:51Z
status: gaps_found
score: 10/11 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Byte-exact fixture tests prove `bootstrap` produces identical output on sample vaults across runs (BRWN-21 dual golden contract: transformed-output + skip-artifact per D-07)"
    status: failed
    reason: >-
      Five parseable-fixture byte-equality tests (apply_clean, apply_no_fm,
      apply_crlf, apply_dataview, apply_comments) fail on any date after
      2026-04-17. Root cause: the expected/page.md fixtures pin
      `created_at: 2026-04-17`, but `created_at` is derived from file mtime
      (bin/lib/brownfield_yaml.py:250-256 `file_mtime_iso`) and
      `tests/phase-10/lib.sh:make_fixture_repo` uses plain `cp` which
      does NOT preserve mtime — copied files get today's mtime (2026-04-18
      at verification time). The `BROWNFIELD_FIXTURE_TODAY=2026-04-17`
      env override covers `updated_at` and `bootstrap_date` only, not
      `created_at`. Aggregator reports `PHASE 10 TESTS: 27/32` with the
      5 apply_* tests failing. Prior-phase regressions are clean
      (07=22/22, 08=21/21, 09=28/28, 09.1=11/11). BRWN-01..10 + BRWN-03
      (idempotency) + BRWN-21 skip-artifact contract all pass.
    artifacts:
      - path: "tests/phase-10/lib.sh"
        issue: "make_fixture_repo uses `cp` which does not preserve source file mtime; copied fixture inputs acquire today's date instead of the committed 2026-04-17 pin"
      - path: "tests/phase-10/test_brownfield_bootstrap_apply_clean.sh"
        issue: "Test exports BROWNFIELD_FIXTURE_TODAY=2026-04-17 but does not touch the copied file's mtime; created_at (derived from mtime) diverges from expected on any date > 2026-04-17"
      - path: "tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh"
        issue: "Same root cause as apply_clean"
      - path: "tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh"
        issue: "Same root cause as apply_clean"
      - path: "tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh"
        issue: "Same root cause as apply_clean"
      - path: "tests/phase-10/test_brownfield_bootstrap_apply_comments.sh"
        issue: "Same root cause as apply_clean"
    missing:
      - >-
        Pin fixture input file mtime before invoking bootstrap. Simplest
        fix: extend `make_fixture_repo` (or each apply_* test) to run
        `touch -d "2026-04-17T00:00:00Z" "$tmp/input/page.md"` after
        copying, so `file_mtime_iso` returns the pinned date regardless
        of when the test runs.
      - >-
        Alternative: add a `BROWNFIELD_FIXTURE_CREATED_AT` env override
        in bin/lib/brownfield_yaml.py so the test can pin created_at
        directly without mtime manipulation. This mirrors the existing
        BROWNFIELD_FIXTURE_TODAY override pattern and is the more
        orthogonal surface.
      - >-
        Re-run `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh`
        and confirm `PHASE 10 TESTS: 32/32` on a date ≥ 2026-04-18.
---

# Phase 10 Verification — Brownfield Scan + Bootstrap

**Phase Goal:** A user with a real existing Obsidian vault can run `bin/brownfield.sh scan` safely (no vault mutation) and `bin/brownfield.sh bootstrap` confidently (mechanical-only, idempotent, byte-exact reproducible) without corrupting frontmatter or losing content.

**Verified:** 2026-04-18T18:40:51Z
**Status:** gaps_found
**Plans:** 5 plans (10-01 harness, 10-02 scan, 10-03 bootstrap, 10-04 schema/lint/ingest wiring, 10-05 docs + VERIFICATION)
**Re-verification:** No — initial verification (prior 10-VERIFICATION.md lacked YAML frontmatter; this is the first machine-readable verification artifact for the phase)

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | `bin/brownfield.sh scan` writes `.brownfield/REPORT.md` with inventory, confidence labels, and signal traces without mutating vault content (BRWN-01) | VERIFIED | `tests/phase-10/test_brownfield_scan_report.sh` passes (SHA-256 snapshot before/after proves no mutation); `tests/phase-10/test_brownfield_scan_confidence.sh` passes; `bin/brownfield.sh:scan` code path is PyYAML-only with no write outside `.brownfield/REPORT.md` |
| 2  | `scan` REPORT.md lists unclassifiable pages under "Needs human judgment" with prose open-questions (BRWN-02) | VERIFIED | `tests/phase-10/test_brownfield_scan_unknown.sh` passes; asserts section header present + question-framed prose ending with `?` |
| 3  | `bootstrap --apply` is idempotent — two runs produce zero-byte diff (BRWN-03) | VERIFIED | `tests/phase-10/test_brownfield_bootstrap_idempotent.sh` passes — runs --apply twice on multi-file vault, asserts recursive SHA-256 set matches; per-file sentinel-check (bootstrap_stage: bootstrapped) at bin/brownfield.sh:324 provides mechanical gate |
| 4  | `bootstrap` touches only mechanical transforms (sentinel frontmatter, SHA hashing, skeleton files, YAML normalization) (BRWN-04) | VERIFIED | Body-preservation assertions in every `test_brownfield_bootstrap_apply_*.sh` (even those that fail byte-equality on the full file); `bin/brownfield.sh` contains no LLM calls (grep confirms no curl/wget/anthropic/openai); typed-merge policy in bin/lib/brownfield_yaml.py:354-391 enforces preservation |
| 5  | `bootstrap` preserves page bodies verbatim (BRWN-05) | VERIFIED | Body-preservation python block in each apply test extracts post-`---` body bytes and asserts equality with original input; this check runs BEFORE the byte-equality assertion that fails on the frontmatter date fields, so body-preservation is separately confirmed |
| 6  | `bootstrap` uses ruamel.yaml round-trip preserving comments + key order (BRWN-06) | VERIFIED | `bin/lib/brownfield_yaml.py` imports `from ruamel.yaml import YAML` with `typ='rt'`; `test_brownfield_bootstrap_apply_comments.sh` exists and validates frontmatter-with-comments; while the full byte-equality assertion fails on created_at alone, the comments-preservation semantics are independently locked by ruamel's documented round-trip contract |
| 7  | `bootstrap_stage` enum (`raw \| bootstrapped \| verified`) documented in AGENTS.md §5 as narrowly-scoped brownfield onboarding sentinel, NOT a substitute for claim-level provenance (BRWN-07) | VERIFIED | `tests/phase-10/test_agents_section_5_bootstrap_stage.sh` passes; `tests/phase-10/test_agents_template_parity_section_5.sh` passes; `tests/phase-10/test_claude_sync_byte_equal.sh` passes; manual grep confirms AGENTS.md:302 and CLAUDE.md:302 contain the row with all 5 required phrases |
| 8  | `bin/lint.sh --ci` downgrades allowlist findings from error to info when `bootstrap_stage: bootstrapped` (scope: `--ci` mode only per I-1) (BRWN-08) | VERIFIED | `tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh` passes (asserts severity=info); `tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh` passes (asserts no false-positive); `bin/lint.sh:1709-1713` locates the downgrade inside `if CI_MODE:` |
| 9  | `bin/lint.sh` new `brownfield` category reports bootstrapped-page counts + warns on pages bootstrapped > 30 days ago (BRWN-09) | VERIFIED | `tests/phase-10/test_lint_brownfield_category_help.sh` passes; `tests/phase-10/test_lint_brownfield_stale_30d.sh` passes |
| 10 | `bin/ingest.sh` strips `bootstrap_stage` + `bootstrap_date` on normal ingest with D-21 verbatim stderr warning (emitted as a single line per W-6) (BRWN-10) | VERIFIED | `tests/phase-10/test_ingest_strip_bootstrap_stage.sh` passes (includes W-6 combined-line grep asserting single-line emission); `tests/phase-10/test_ingest_strip_no_warn_when_absent.sh` passes; `bin/ingest.sh:316-374` contains the BRWN-10 block between `cp` and `compute_hash` |
| 11 | Byte-exact fixture tests prove `bootstrap` produces identical output on sample vaults across runs (dual golden contract per D-07) (BRWN-21) | **FAILED** | 5 parseable-fixture byte-equality tests (`apply_clean`, `apply_no_fm`, `apply_crlf`, `apply_dataview`, `apply_comments`) fail at system date 2026-04-18 because `created_at` derives from file mtime (not pinned by `BROWNFIELD_FIXTURE_TODAY`) and `make_fixture_repo` does not preserve mtime. Skip-artifact contract side of D-07 (`test_brownfield_bootstrap_skip_tabs.sh`, `test_brownfield_bootstrap_skip_dupkeys.sh`) passes. Idempotency test passes. The byte-exact guarantee is not maintained "across runs" on different calendar dates — this is a genuine hole in the contract. |

**Score:** 10/11 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/brownfield.sh` | Subcommand dispatcher + scan + bootstrap | VERIFIED | 37568 bytes, executable; contains `case "$SUBCOMMAND"` dispatch with scan/bootstrap/suggest(exit 2)/verify(exit 2) branches; --help advertises scan + bootstrap + decision-boundary epigraph; no LLM/network calls |
| `bin/lib/brownfield_classify.py` | Rule-based classifier (D-16) | VERIFIED | 6441 bytes; exports `classify_page(rel_path, frontmatter, body, inbound_count=None)` and `unknown_reason()`; `inbound_count` parameter reserved for Phase 11 reuse |
| `bin/lib/brownfield_yaml.py` | ruamel.yaml round-trip helpers | VERIFIED | 18897 bytes; exports `read_fm_body`, `merge_sentinels`, `write_roundtrip`, `FIELD_CLASS_A`, `FIELD_CLASS_B`, `VALID_ENUMS`, `build_d14_sentinel_set`, `split_frontmatter`, `infer_id_from_filename`, `extract_h1`, `file_mtime_iso`; imports `ruamel.yaml.YAML(typ='rt')` |
| `bin/ingest.sh` | BRWN-10 strip pass | VERIFIED | Line 316 contains `# BRWN-10: strip brownfield-scoped fields`; strip block is between `cp` and `compute_hash`; python3 heredoc scopes to first `---...---` block; D-21 stderr single-line emission verified by W-6 combined-line grep |
| `bin/lint.sh` | BRWN-08 downgrade + brownfield category + 30-day staleness | VERIFIED | Contains `BROWNFIELD_ALLOWLIST = {'yaml', 'provenance', 'orphan'}` (line 882); `BROWNFIELD_BOOTSTRAPPED_PAGES` set built from frontmatter; `_bf_downgrade` helper inside `if CI_MODE:`; brownfield check block gates on `should_run('brownfield')` |
| `AGENTS.md` | §5 bootstrap_stage + bootstrap_date rows | VERIFIED | Lines 302-303 contain both rows with all mandated phrases; byte-synced with CLAUDE.md |
| `CLAUDE.md` | Byte-synced mirror of AGENTS.md | VERIFIED | `cmp -s AGENTS.md CLAUDE.md` exits 0 |
| `schema/AGENTS.template.md` | Template mirrors AGENTS.md §5 edit | VERIFIED | `test_agents_template_parity_section_5.sh` passes (extracts §5 from both files, cmp-equal) |
| `schema/fixtures/canonical-AGENTS.md` | Regenerated canonical fixture | VERIFIED | Contains `bootstrap_stage` + `bootstrap_date` rows; Phase 8-01 byte-equality test (`tests/phase-08/test_canonical_byte_equality.sh`) continues to pass (22/22) |
| `docs/reference/brownfield.md` | Full runbook (≥150 lines) | VERIFIED | 194 lines; contains D-02 decision-boundary verbatim; Class A/B/C taxonomy present; `git reset --hard` rollback recipe present; `[Populated in Phase 11]` stubs ≥2; documents `--ci`-only scope (I-1); uses `gitignore-like patterns` wording (not `gitignore-grammar`); no `## Needs summary` section |
| `docs/quickstart.md` | ruamel.yaml prereq note | VERIFIED | Contains `pip install ruamel.yaml` + `brownfield onboarding` scope qualifier + forward link to `reference/brownfield.md` |
| Test harness: `tests/phase-10/run.sh`, `lib.sh`, 7 fixtures | D-07 dual golden contract scaffolding | PARTIAL | All harness files exist; aggregator emits `PHASE 10 TESTS: 27/32` at verification time (not `N/N`); 5 apply_* tests fail on `created_at` mtime derivation per Gap 1 |

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

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `bin/brownfield.sh scan` REPORT.md | `rows` | `classify_page()` output for each page walked via `os.walk` | YES — real vault pages produce real classification rows | FLOWING |
| `bin/brownfield.sh bootstrap` APPLIED.md | `applied_entries` | per-page write success tracked after `write_roundtrip` | YES — flush after writes, confirmed by applied_manifest test | FLOWING |
| `bin/brownfield.sh bootstrap` SKIPPED.md | `skipped_list` | `read_fm_body` exception handler + duplicate-key pre-scan | YES — tabs-in-yaml + duplicate-yaml-keys fixtures both produce real entries | FLOWING |
| `bin/lint.sh` brownfield findings | `add_finding('warning','brownfield',...)` | `all_pages` walk reading `bootstrap_stage` + `bootstrap_date` from real frontmatter | YES — test_lint_brownfield_stale_30d.sh confirms age-based flagging | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase-10 aggregator | `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh` | `PHASE 10 TESTS: 27/32` (5 apply_* byte-equality tests fail on `created_at` mtime drift) | FAIL |
| Prior phase: 07 | `bash tests/phase-07/run.sh` | `PHASE 07 TESTS: 22/22` | PASS |
| Prior phase: 08 (canonical byte-equality) | `PYTHONPATH=... bash tests/phase-08/run.sh` | `PHASE 08 TESTS: 21/21` | PASS |
| Prior phase: 09 (lint CI) | `PYTHONPATH=... bash tests/phase-09/run.sh` | `PHASE 09 TESTS: 28/28` | PASS |
| Prior phase: 09.1 (template parity) | `PYTHONPATH=... bash tests/phase-09.1/run.sh` | `PHASE 09.1 TESTS: 11/11` | PASS |
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
| BRWN-05 | 10-03, 10-05 | bootstrap preserves bodies verbatim | SATISFIED | Body-preservation python block in apply_* tests passes even when full-file byte-equality fails on the date field |
| BRWN-06 | 10-03, 10-05 | ruamel.yaml round-trip preserves comments + key order | SATISFIED (semantic) / PARTIAL (byte-exact) | `bin/lib/brownfield_yaml.py` uses `YAML(typ='rt')`; test_brownfield_bootstrap_apply_comments.sh currently fails ONLY on `created_at` date drift, not on comment preservation. The semantic requirement is satisfied; the byte-exact CI gate is blocked by the Gap 1 mtime issue. |
| BRWN-07 | 10-04, 10-05 | bootstrap_stage documented in AGENTS.md §5 (not claim-level provenance substitute) | SATISFIED | test_agents_section_5_bootstrap_stage.sh passes; template parity + CLAUDE sync tests pass |
| BRWN-08 | 10-04, 10-05 | lint --ci downgrades allowlist findings on bootstrapped pages | SATISFIED | test_lint_ci_downgrade_bootstrapped.sh + test_lint_ci_no_downgrade_when_absent.sh |
| BRWN-09 | 10-04, 10-05 | lint brownfield category + 30-day staleness | SATISFIED | test_lint_brownfield_category_help.sh + test_lint_brownfield_stale_30d.sh |
| BRWN-10 | 10-04, 10-05 | ingest strips bootstrap_stage + bootstrap_date with D-21 single-line stderr | SATISFIED | test_ingest_strip_bootstrap_stage.sh (W-6 combined-line grep) + test_ingest_strip_no_warn_when_absent.sh |
| BRWN-21 | 10-01, 10-03, 10-05 | Byte-exact fixture tests across runs (dual golden contract) | **BLOCKED** | Skip-artifact side (2 unparseable fixtures) passes. Idempotency test passes. **Transformed-output side (5 parseable fixtures) is broken on any date > 2026-04-17** because `created_at` is derived from file mtime and the test harness doesn't pin mtime. The BRWN-21 contract "identical output on sample vaults across runs" is not satisfied when "runs" span calendar days. |

### Anti-Patterns Found

Inherited from `10-REVIEW.md` (ran by gsd-code-reviewer on 2026-04-17T00:00:00Z); reproduced here for context. None of the 3 Warnings block the phase goal as stated, but WR-01 touches an edge case of idempotency.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `bin/brownfield.sh` | 366-400 | Orphan-raw-sources walk uses `pending_writes` only; already-bootstrapped source summaries are excluded, so their raw sources become false-positive orphans on re-runs (WR-01) | Warning | REPORT.md user-visible flip between runs — documented idempotency contract says "zero-byte diff" for vault files; REPORT.md does change. Not goal-blocking for vault integrity but undermines user trust. |
| `bin/brownfield.sh` | 324 | Idempotency skip only fires on `bootstrap_stage == 'bootstrapped'`; pages with `raw` or `verified` are re-written on every run (WR-02) | Warning | Unnecessary disk writes on raw/verified pages. Not yet reachable in Phase 10 (no caller writes those values) but a latent regression once Phase 11 ships |
| `AGENTS.md:302` (+ CLAUDE/template/fixture mirrors) | 302 | Code-span `|` in table cell may mis-render in Obsidian live preview; forward-reference to §11.5 points at Release Workflow, not Brownfield Workflow (WR-03) | Warning | Documentation clarity on Obsidian; not goal-blocking — the field IS documented, the test passes. Future-phase cleanup. |
| `bin/brownfield.sh` + `bin/lint.sh` | various | 5 Info items (code duplication, UTC/local-date mix, ingest pwd assumption, tab-heuristic looseness, non-atomic skeleton write) | Info | None goal-blocking; see 10-REVIEW.md for full write-up |

### Human Verification Required

None. All must-haves are mechanically testable; the one failing truth (BRWN-21) is failing mechanically on a deterministic cause that can be fixed mechanically (pin fixture mtime). No visual/UX/real-time behavior requires human judgment for this phase.

### Gaps Summary

Phase 10 ships all five plans (10-01 through 10-05) and the full feature surface: `bin/brownfield.sh scan + bootstrap` with typed-merge Class A/B/C, ruamel.yaml round-trip, APPLIED.md/SKIPPED.md manifests, BRWN-08 --ci downgrade, BRWN-09 brownfield category, BRWN-10 ingest strip, schema wiring across AGENTS/CLAUDE/template/fixture, and a 194-line user runbook. The code substantive-ness and wiring are solid — no stubs, no placeholder returns, no missing integrations. 10 of 11 must-haves are cleanly verified against real tests.

**The one gap:** BRWN-21's byte-exact transformed-output contract is broken on calendar days after the fixture freeze date (2026-04-17). Five apply_* tests fail today (2026-04-18) because `created_at` is sourced from file mtime — `make_fixture_repo` uses plain `cp` (no `-p` / mtime preservation), and `BROWNFIELD_FIXTURE_TODAY` pins only `updated_at` + `bootstrap_date`, not `created_at`. This is a latent regression that would have hit CI on the first workday after fixture commit regardless of code quality.

The fix is small and mechanical: either (a) `touch -d "2026-04-17T00:00:00Z"` the copied input file inside `make_fixture_repo` or each apply_* test, or (b) add a `BROWNFIELD_FIXTURE_CREATED_AT` override in `bin/lib/brownfield_yaml.py:build_d14_sentinel_set` mirroring the existing `BROWNFIELD_FIXTURE_TODAY` pattern. Approach (b) is more orthogonal and keeps the fix in the same file where the date policy is authored.

No contradicting evidence suggests an alternative implementation that achieves BRWN-21 differently; the fixture-byte-equality path IS the contract. This is a genuine gap, not an override candidate.

### Deferred Items

No items from this verification are deferred to later phases. Phase 11 covers suggest/verify (BRWN-11..20) which is orthogonal to this mtime issue. Phase 12 covers DEBT-01/02/04 (Obsidian render, agent parity, write-back scenario) which are also orthogonal. The fixture-mtime regression must be fixed inside Phase 10's scope.

---

_Verified: 2026-04-18T18:40:51Z_
_Verifier: Claude (gsd-verifier)_
