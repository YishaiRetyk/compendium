---
phase: 10
slug: brownfield-scan-bootstrap
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
reconstructed_from: SUMMARY.md + 10-VERIFICATION.md (State B)
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Reconstructed retroactively from completed-phase artifacts (no VALIDATION.md
> existed during execution). All 11 requirements (BRWN-01..10 + BRWN-21) are
> automated; the aggregator emits `PHASE 10 TESTS: 32/32`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash test scripts (project convention; no pytest/jest layer) |
| **Config file** | `tests/phase-10/run.sh` (per-phase aggregator) + `tests/phase-10/lib.sh` (shared helpers) |
| **Quick run command** | `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh` |
| **Full suite command** | `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh` (Phase 10 alone — no `--full` mode shipped in v1.1) |
| **Estimated runtime** | ~30s (32 bash tests, several invoke fixture I/O via ruamel.yaml round-trip) |
| **Runtime prerequisite** | Python 3 + `ruamel.yaml` on `PYTHONPATH` (the single new v1.1 dependency, scoped to the brownfield path; see `docs/reference/brownfield.md`) |
| **CI integration** | `bin/lint.sh --ci` is the GitHub Actions hard gate (`.github/workflows/lint.yml`); per-phase test aggregators are run locally and during agent verification, not (yet) inside the CI workflow |

---

## Sampling Rate

- **After every task commit:** Run the targeted test file (e.g., `bash tests/phase-10/test_brownfield_scan_report.sh`) for the task's primary REQ.
- **After every plan wave:** Run `bash tests/phase-10/run.sh` (the full Phase 10 aggregator).
- **Before `/gsd-verify-work`:** Aggregator must emit `PHASE 10 TESTS: 32/32` AND prior-phase aggregators (07/08/09/09.1) must remain green.
- **Max feedback latency:** ~30s per full Phase 10 run.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | BRWN-21 (scaffold) | T-10-01-01..04 | Aggregator + lib.sh write to `$TMPDIR` only; never mutate vault | smoke | `bash tests/phase-10/test_harness_self_check.sh` | ✅ | ✅ green |
| 10-01-02 | 01 | 1 | BRWN-21 | T-10-01-04 | 7 byte-frozen fixtures present; SHA-256 stable across runs | unit | `bash tests/phase-10/test_fixtures_exist.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-01 | T-10-02-01 | `scan` does not mutate vault; `--help` advertises subcommand surface | smoke | `bash tests/phase-10/test_brownfield_scan_help.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-01 | T-10-02-02 | REPORT.md inventory + signal trace; SHA-256 vault snapshot before/after equal | integration | `bash tests/phase-10/test_brownfield_scan_report.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-01 | — | Confidence labels (high/medium/low) emitted per page | integration | `bash tests/phase-10/test_brownfield_scan_confidence.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-02 | — | Unknown pages listed under "Needs human judgment" with `?`-terminated prose | integration | `bash tests/phase-10/test_brownfield_scan_unknown.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-16 / BRWN-01 | T-10-02-04 | Default Obsidian-quirk dir exclusions honored | integration | `bash tests/phase-10/test_brownfield_scan_exclusions.sh` | ✅ | ✅ green |
| 10-02-01 | 02 | 2 | BRWN-16 | — | `.brownfield-ignore` (gitignore-subset) parser extends/negates exclusions | unit | `bash tests/phase-10/test_brownfield_ignore_parser.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-03 | T-10-03-02 | `bootstrap --apply` twice → zero-byte diff (idempotency) | integration | `bash tests/phase-10/test_brownfield_bootstrap_idempotent.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 / BRWN-05 / BRWN-06 / BRWN-21 | T-10-03-03 | clean-frontmatter fixture: typed-merge produces byte-equal output; body verbatim | integration | `bash tests/phase-10/test_brownfield_bootstrap_apply_clean.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 / BRWN-05 / BRWN-21 | — | no-frontmatter fixture: scaffolds sentinel block; body verbatim | integration | `bash tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-05 / BRWN-21 | — | CRLF body fixture: line endings preserved verbatim | integration | `bash tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-05 / BRWN-21 | — | Dataview-inline body fixture: `[field:: value]` markers preserved | integration | `bash tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-06 / BRWN-21 | T-10-03-03 | YAML comments-between-fields preserved via ruamel.yaml round-trip; byte-equal | integration | `bash tests/phase-10/test_brownfield_bootstrap_apply_comments.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | Tabs-in-yaml fixture: parse failure routed to SKIPPED.md (skip-artifact contract) | integration | `bash tests/phase-10/test_brownfield_bootstrap_skip_tabs.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | Duplicate-keys fixture: pre-scan rejects → SKIPPED.md | integration | `bash tests/phase-10/test_brownfield_bootstrap_skip_dupkeys.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | Typed-merge Class A/B/C policy enforced (existing values preserved per class) | unit | `bash tests/phase-10/test_brownfield_bootstrap_typed_merge.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | APPLIED.md manifest: per-page write success entries appended | integration | `bash tests/phase-10/test_brownfield_bootstrap_applied_manifest.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | Dry-run is default; trailing reminder line emitted | smoke | `bash tests/phase-10/test_brownfield_bootstrap_dryrun.sh` | ✅ | ✅ green |
| 10-03-01 | 03 | 3 | BRWN-04 | — | `--help` documents bootstrap surface | smoke | `bash tests/phase-10/test_brownfield_bootstrap_help.sh` | ✅ | ✅ green |
| 10-04-01 | 04 | 3 | BRWN-07 | T-10-04-01 | AGENTS.md §5 row contains all 5 mandated phrases (enum, sentinel, NOT-PROV, ingest-strip, §11.5 ref) | integration | `bash tests/phase-10/test_agents_section_5_bootstrap_stage.sh` | ✅ | ✅ green |
| 10-04-01 | 04 | 3 | BRWN-07 | — | `schema/AGENTS.template.md` §5 byte-equal to `AGENTS.md` §5 | integration | `bash tests/phase-10/test_agents_template_parity_section_5.sh` | ✅ | ✅ green |
| 10-04-01 | 04 | 3 | BRWN-07 | — | `cmp -s AGENTS.md CLAUDE.md` returns 0 (sync hook intact) | integration | `bash tests/phase-10/test_claude_sync_byte_equal.sh` | ✅ | ✅ green |
| 10-04-02 | 04 | 3 | BRWN-10 | T-10-04-02 | `bin/ingest.sh` strips `bootstrap_stage` + `bootstrap_date` from frontmatter; D-21 single-line stderr emitted | integration | `bash tests/phase-10/test_ingest_strip_bootstrap_stage.sh` | ✅ | ✅ green |
| 10-04-02 | 04 | 3 | BRWN-10 | — | No false-positive: ingest with no brownfield fields emits no warn | integration | `bash tests/phase-10/test_ingest_strip_no_warn_when_absent.sh` | ✅ | ✅ green |
| 10-04-03 | 04 | 3 | BRWN-08 | T-10-04-03 | `--ci` mode downgrades allowlist findings to `info` on bootstrapped pages | integration | `bash tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh` | ✅ | ✅ green |
| 10-04-03 | 04 | 3 | BRWN-08 | — | No-downgrade for non-bootstrapped pages (false-positive guard) | integration | `bash tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh` | ✅ | ✅ green |
| 10-04-03 | 04 | 3 | BRWN-09 | — | `--category brownfield` registered in `--help` enum | smoke | `bash tests/phase-10/test_lint_brownfield_category_help.sh` | ✅ | ✅ green |
| 10-04-03 | 04 | 3 | BRWN-09 | — | 30-day staleness warning on pages bootstrapped > 30 days ago | integration | `bash tests/phase-10/test_lint_brownfield_stale_30d.sh` | ✅ | ✅ green |
| 10-05-02 | 05 | 4 | BRWN-01..10, BRWN-21 (docs) | — | `docs/reference/brownfield.md` populated with required sections + 5 keywords | integration | `bash tests/phase-10/test_brownfield_docs_populated.sh` | ✅ | ✅ green |
| 10-05-02 | 05 | 4 | BRWN-04 (docs) | — | D-02 typed-merge decision boundary documented verbatim in brownfield.md | integration | `bash tests/phase-10/test_brownfield_docs_decision_boundary.sh` | ✅ | ✅ green |
| 10-05-02 | 05 | 4 | BRWN-06 (docs) | — | `docs/quickstart.md` §0 surfaces `pip install ruamel.yaml` prereq | integration | `bash tests/phase-10/test_quickstart_brownfield_prereq.sh` | ✅ | ✅ green |
| 10-06-01 | 06 | gap | BRWN-21 (transformed-output side) | — | `BROWNFIELD_FIXTURE_CREATED_AT` override pins `created_at` for byte-exact fixture replay; fail-loud on malformed input | covered-by | (covered by 5 apply_* tests above + plan 10-06's 3 in-line python sentinels reproduced in VERIFICATION) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Aggregator gate:** `PHASE 10 TESTS: 32/32` (verified 2026-04-18 + re-confirmed 2026-04-30 during this validation reconstruction).

---

## Wave 0 Requirements

Wave 0 (test scaffold) was executed under Plan 10-01:

- [x] `tests/phase-10/run.sh` — per-phase aggregator (auto-discovers `test_*.sh` via `shopt -s nullglob`)
- [x] `tests/phase-10/lib.sh` — shared helpers (tempdir, fixture path resolution, SHA-256 snapshot)
- [x] `tests/phase-10/fixtures/` — 7 byte-frozen fixtures (5 parseable + 2 unparseable) encoding the D-07 dual golden contract for BRWN-21
- [x] `tests/phase-10/test_harness_self_check.sh` + `test_fixtures_exist.sh` — meta-tests proving the scaffold itself is healthy

No outstanding Wave 0 backfill — all infrastructure shipped under 10-01 before downstream plans landed.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

The phase-goal observables (idempotency, body-preservation, ruamel.yaml round-trip, lint downgrade, ingest strip, schema documentation) are all mechanically asserted under `tests/phase-10/`. Per `10-VERIFICATION.md` §"Human Verification Required": *"None. All 11 must-haves are mechanically verified."*

The three deferred-warning items from `10-REVIEW.md` (WR-01 orphan-raw-sources walk, WR-02 idempotency-skip narrowness, WR-03 Obsidian table-cell rendering) are explicitly documented as non-goal-blocking and tracked for later phases — not manual-verification debt.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (32/32 aggregator)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every plan task maps to ≥1 named test file)
- [x] Wave 0 covers all MISSING references (no MISSING references — all requirements COVERED at phase close)
- [x] No watch-mode flags (`run.sh` is one-shot; `--full` reserved for future use, currently no-op)
- [x] Feedback latency < 60s (~30s observed)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-30 (retroactive — phase verified 2026-04-18 with 11/11 must-haves verified; this VALIDATION.md reconstructs the contract from shipped artifacts per workflow State B).

---

## Validation Audit 2026-04-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Tests existing | 32 |
| Requirements covered | 11/11 (BRWN-01..10 + BRWN-21) |

**Auditor:** none spawned — no gaps detected. State B reconstruction relied on cross-referencing per-task PLAN names against the test-file → REQ-ID map already documented in `10-VERIFICATION.md`. Aggregator re-run during this validation pass confirmed `PHASE 10 TESTS: 32/32`.
