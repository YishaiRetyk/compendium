---
phase: 11
slug: brownfield-suggest-verify
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
reconstructed_from: artifacts (state B — phase already executed)
---

# Phase 11 — Validation Strategy

> Reconstructed retroactively after phase completion. All 12 BRWN-11..22
> requirements have automated test coverage; 48/48 phase-11 tests GREEN.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + python3 (stdlib + ruamel.yaml + PyYAML) |
| **Config file** | `tests/phase-11/run.sh` (aggregator) + `tests/phase-11/lib.sh` (helpers) |
| **Quick run command** | `bash tests/phase-11/run.sh --expected-by 11-XX` (per-plan filter) |
| **Full suite command** | `bash tests/phase-11/run.sh` |
| **Estimated runtime** | ~30–60 seconds (48 shell tests) |

**Per-plan gating** uses `# EXPECTED_BY: 11-XX` headers (Plan 11-04 review item 6 contract).

---

## Sampling Rate

- **After every task commit:** Run `bash tests/phase-11/run.sh --expected-by 11-{plan}`
- **After every plan wave:** Run full `bash tests/phase-11/run.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Plan | Wave | Requirement | Test File | Status |
|------|------|-------------|-----------|--------|
| 11-01 | 1 | (test harness — no req) | `test_migration_script_names.sh` | ✅ green |
| 11-01 | 1 | BRWN-16 | `test_no_llm_calls.sh` | ✅ green |
| 11-01 | 1 | BRWN-14 | `test_hashlib_not_sha256sum.sh` | ✅ green |
| 11-02 | 2 | BRWN-11 | `test_suggest_byte_copies_migrations.sh` | ✅ green |
| 11-02 | 2 | BRWN-11 | `test_suggest_candidate_metadata_header.sh` | ✅ green |
| 11-02 | 2 | BRWN-11 | `test_suggest_respects_brownfield_ignore.sh` | ✅ green |
| 11-02 | 2 | BRWN-14 | `test_canonical_byte_equality.sh` | ✅ green |
| 11-02 | 2 | BRWN-14 | `test_op_hash_header_shape.sh` | ✅ green |
| 11-02 | 2 | BRWN-14 | `test_op_hash_stable.sh` | ✅ green |
| 11-02 | 2 | BRWN-11 | `test_01_highconf_multisignal_autoapprove.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_01_apply_reads_decisions_only.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_01_paired_immutable_inputs.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_01_root_resolution.sh` | ✅ green |
| 11-03 | 3 | BRWN-13 | `test_01_dryrun_default.sh` | ✅ green |
| 11-03 | 3 | BRWN-13 | `test_01_idempotent.sh` | ✅ green |
| 11-03 | 3 | BRWN-15 | `test_02_apply_eligible_bullets.sh` | ✅ green |
| 11-03 | 3 | BRWN-15 | `test_02_no_magic_strings.sh` | ✅ green |
| 11-03 | 3 | BRWN-15 | `test_02_skips_already_tagged.sh` | ✅ green |
| 11-03 | 3 | BRWN-13 | `test_02_dryrun_default.sh` | ✅ green |
| 11-03 | 3 | BRWN-13 | `test_02_idempotent.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_02_top_level_bullets_only.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_02_honest_no_eligible.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_02_soft_prereq_warn.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_03_advisory_only.sh` | ✅ green |
| 11-03 | 3 | BRWN-12 | `test_04_advisory_only.sh` | ✅ green |
| 11-03 | 3 | BRWN-18 | `test_04_never_flips_privacy.sh` | ✅ green |
| 11-03 | 3 | BRWN-14 | `test_applied_log_apply_schema.sh` | ✅ green |
| 11-03 | 3 | BRWN-14 | `test_applied_log_advisory_schema.sh` | ✅ green |
| 11-03 | 3 | BRWN-14 | `test_applied_log_dryrun_no_append.sh` | ✅ green |
| 11-04 | 4 | BRWN-22 | `test_review_typing_tty_small.sh` | ✅ green |
| 11-04 | 4 | BRWN-22 | `test_review_typing_ai_handoff.sh` | ✅ green |
| 11-04 | 4 | BRWN-22 | `test_review_typing_decisions_roundtrip.sh` | ✅ green |
| 11-04 | 4 | BRWN-22 | `test_review_typing_eof_handling.sh` | ✅ green |
| 11-04 | 4 | BRWN-22 | `test_review_typing_validates_override_label.sh` | ✅ green |
| 11-04 | 4 | BRWN-17 | `test_verify_lint_wrapper.sh` | ✅ green |
| 11-04 | 4 | BRWN-17 | `test_verify_readonly_default.sh` | ✅ green |
| 11-04 | 4 | BRWN-17 | `test_verify_promote_5_gates.sh` | ✅ green |
| 11-04 | 4 | BRWN-17 | `test_verify_promote_gate5_pending.sh` | ✅ green |
| 11-04 | 4 | BRWN-17 | `test_verify_stale_artifact_warn.sh` | ✅ green |
| 11-04 | 4 | BRWN-17, BRWN-22 | `test_end_to_end_happy_path.sh` | ✅ green |
| 11-05 | 5 | BRWN-20 | `test_agents_section_11_5.sh` | ✅ green |
| 11-05 | 5 | BRWN-20 | `test_agents_template_parity_11_5.sh` | ✅ green |
| 11-05 | 5 | BRWN-20 | `test_canonical_agents_byte_equality.sh` | ✅ green |
| 11-05 | 5 | BRWN-18 | `test_docs_mechanical_judgment.sh` | ✅ green |
| 11-05 | 5 | BRWN-18 | `test_docs_suggest_section.sh` | ✅ green |
| 11-05 | 5 | BRWN-19 | `test_docs_review_typing_section.sh` | ✅ green |
| 11-05 | 5 | BRWN-19 | `test_docs_verify_section.sh` | ✅ green |
| 11-05 | 5 | BRWN-19 | `test_docs_rollback_git_reset_recipe.sh` | ✅ green (gap-fill) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Requirement Coverage Summary

| Requirement | Tests | Status |
|-------------|-------|--------|
| BRWN-11 (suggest writes REPORT.md + migrations) | 3 tests | ✅ COVERED |
| BRWN-12 (four migration script names + classes) | 7 tests | ✅ COVERED |
| BRWN-13 (dry-run default, --apply, idempotent) | 4 tests | ✅ COVERED |
| BRWN-14 (op_hash header + applied.log) | 6 tests | ✅ COVERED |
| BRWN-15 (02 uses existing epistemic vocab) | 3 tests | ✅ COVERED |
| BRWN-16 (no LLM calls inside brownfield.sh) | 1 test | ✅ COVERED |
| BRWN-17 (verify thin lint wrapper) | 6 tests | ✅ COVERED |
| BRWN-18 (mechanical-vs-judgment boundary doc'd) | 3 tests | ✅ COVERED |
| BRWN-19 (git reset canonical undo recipe) | 3 tests | ✅ COVERED |
| BRWN-20 (AGENTS.md §11.5 populated) | 3 tests | ✅ COVERED |
| BRWN-22 (review-typing two modes + EOF + label) | 6 tests | ✅ COVERED |

BRWN-21 (byte-exact fixture tests) was completed in Phase 10.

---

## Wave 0 Requirements

Plan 11-01 served as Wave 0: created `tests/phase-11/run.sh`, `lib.sh`, 7 fixture
directories, and the full RED-test contract suite for Plans 11-02..11-05 to flip
GREEN as they landed.

- [x] `tests/phase-11/run.sh` — aggregator with `--expected-by` filter
- [x] `tests/phase-11/lib.sh` — `make_fixture_repo`, assertion helpers
- [x] `tests/phase-11/fixtures/` — 7 fixture vaults
- [x] All 47 RED tests written in 11-01 — flipped GREEN by 11-02..11-05
- [x] One gap-fill test added retroactively (BRWN-19)

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have automated tests (48/48 GREEN)
- [x] Sampling continuity: per-plan filter via `# EXPECTED_BY:` headers
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-30 (retroactive reconstruction; phase UAT
already passed 2026-04-30 commit d39f75c — 3 manual scenarios + 0 issues)

---

## Validation Audit 2026-04-30

| Metric | Count |
|--------|-------|
| Tests discovered | 47 |
| Requirements covered | 11 (BRWN-11..20, 22) |
| Gaps found | 1 (BRWN-19 partial — no recipe-content assertion) |
| Resolved | 1 (added `test_docs_rollback_git_reset_recipe.sh`) |
| Escalated to manual-only | 0 |
| Final test count | 48 GREEN |
