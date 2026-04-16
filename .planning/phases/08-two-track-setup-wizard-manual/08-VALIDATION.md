---
phase: 8
slug: two-track-setup-wizard-manual
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
audited: 2026-04-16
---

# Phase 8 — Validation Strategy

> Per-phase validation contract. Audited 2026-04-16 against delivered artifacts.
> Pivot note: pre-execution plan assumed bats-core + `tests/manual-setup-equality.sh`; phase delivered shell aggregator under `tests/phase-08/` (mirrors phase-07 contract). Map below reflects actual implementation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash shell aggregator (`tests/phase-08/run.sh`) + python3 stdlib + PyYAML + `cmp -s` byte-equality |
| **Config file** | `tests/phase-08/lib.sh` (shared helpers: `mktemp_repo`, cleanup trap, `assert_eq`, `assert_grep`) |
| **Quick run command** | `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz && cmp -s /tmp/wz/AGENTS.md schema/fixtures/canonical-AGENTS.md` |
| **Full suite command** | `bash tests/phase-08/run.sh` |
| **CI invocation** | `.github/workflows/setup-parity.yml` (PR hard gate + push advisory) |
| **Estimated runtime** | ~10 seconds (21 tests) |
| **Current status** | `PHASE 08 TESTS: 21/21` green |

---

## Sampling Rate

- **After every task commit:** Run quick command (wizard render + `cmp -s` fixture)
- **After every plan wave:** Run `bash tests/phase-08/run.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds (actual: ~10s)

---

## Per-Task Verification Map

| Plan | Wave | Requirement | Test File | Status |
|------|------|-------------|-----------|--------|
| 08-01 | 0 | WZRD-01, WZRD-07, MANUAL-06 (infra) | `tests/phase-08/run.sh`, `tests/phase-08/lib.sh`, `schema/fixtures/canonical-answers.yaml`, `schema/fixtures/canonical-AGENTS.md`, `schema/fixtures/README.md`, `.gitattributes` | ✅ green |
| 08-02 | 1 | WZRD-01 | `test_wizard_exists.sh` | ✅ green |
| 08-02 | 1 | WZRD-02 | `test_wizard_semantic_groups.sh` | ✅ green |
| 08-02 | 1 | WZRD-03 | `test_wizard_answers_yaml.sh` | ✅ green |
| 08-02 | 1 | WZRD-04 | `test_wizard_validation.sh` | ✅ green |
| 08-02 | 1 | WZRD-05 | `test_wizard_idempotent.sh` | ✅ green |
| 08-02 | 1 | WZRD-07 | `test_wizard_template_render.sh` | ✅ green |
| 08-02 | 1 | WZRD-08 | `test_wizard_summary.sh` | ✅ green |
| 08-02 | 1 | WZRD-09 | `test_wizard_preflight.sh` | ✅ green |
| 08-02 | 1 | WZRD-11 | `test_wizard_dryrun.sh` | ✅ green |
| 08-02 | 1 | (staging-dir recovery) | `test_wizard_partial_failure.sh` | ✅ green |
| 08-03 | 2 | WZRD-06 (answers-file) | `test_wizard_answers_yaml.sh` | ✅ green |
| 08-03 | 2 | WZRD-06 (sync-claude) | `test_wizard_sync_claude.sh` | ✅ green |
| 08-03 | 2 | WZRD-10 | `test_wizard_decision_record.sh` | ✅ green |
| 08-03 | 2 | (index.md append) | `test_wizard_index_md.sh` | ✅ green |
| 08-04 | 2 | MANUAL-01 | `test_manual_setup_sections.sh` | ✅ green |
| 08-04 | 2 | MANUAL-02 | `test_manual_setup_example.sh` | ✅ green |
| 08-04 | 2 | MANUAL-03 | `test_manual_setup_checklist.sh` | ✅ green |
| 08-04 | 2 | MANUAL-04 | `test_manual_setup_equivalence.sh` | ✅ green |
| 08-04 | 2 | MANUAL-05 | `test_manual_setup_file_list.sh` | ✅ green |
| 08-04 | 2 | (copy-not-edit) | `test_manual_setup_copy_not_edit.sh` | ✅ green |
| 08-04 | 2 | (inline templates) | `test_manual_setup_inline_templates.sh` | ✅ green |
| 08-05 | 3 | MANUAL-06 | `test_canonical_byte_equality.sh` + `.github/workflows/setup-parity.yml` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Coverage:** 17/17 Phase-8 REQ-IDs have automated verification. 21/21 tests pass locally and in CI.

---

## Wave 0 Artifacts (Delivered)

- [x] `tests/phase-08/run.sh` — aggregator (mirrors phase-07 contract, exits non-zero on any failure)
- [x] `tests/phase-08/lib.sh` — shared bash helpers (`mktemp_repo`, cleanup trap, `assert_eq`, `assert_grep`)
- [x] `schema/fixtures/canonical-answers.yaml` — 6-answer canonical set with metadata
- [x] `schema/fixtures/canonical-AGENTS.md` — byte-frozen expected render (1723 lines, 0 leftover `{{...}}`)
- [x] `schema/fixtures/README.md` — documents `cloud_safe` fixture-tier rationale + regeneration rule
- [x] `.gitattributes` — `text eol=lf` pin on `canonical-AGENTS.md`, `canonical-answers.yaml`, `README.md` (CRLF drift guard)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Interactive prompt UX (readable grouping, clear error text) | WZRD-02, WZRD-05 | Interactive TTY UX cannot be asserted beyond exit codes + explainer-line presence | Run `bin/init-wizard.sh` in a real terminal; confirm 6 grouped prompts (Domain → Agent → Privacy → Obsidian); confirm invalid input produces clear inline error and re-prompts |
| Diff summary readability | WZRD-03, WZRD-08 | Human-legible formatting | Run wizard end-to-end; confirm final summary lists every written file with +/- line counts |
| `docs/manual-setup.md` completeness when followed by a human | MANUAL-01..05 | Prose completeness check (automated tests verify structural sections + byte-equality, not reading flow) | New contributor follows section-by-section without running the wizard; confirms they land at canonical fixture state |
| CI branch-protection wiring | MANUAL-06 | GitHub UI action outside repo control surface | Operator adds `setup-parity` to `main` branch-protection required-status-checks list post-merge on public template repo |

---

## Validation Sign-Off

- [x] All requirements have automated verification (17/17 REQ-IDs covered)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 artifacts delivered (6/6)
- [x] No watch-mode flags
- [x] Feedback latency < 30s (actual: ~10s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-04-16

---

## Validation Audit 2026-04-16

| Metric | Count |
|--------|-------|
| Requirements audited | 17 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 0 |
| Framework pivot reconciled | bats-core → `tests/phase-08/*.sh` aggregator |

**Audit method:** Cross-referenced each REQ-ID (WZRD-01..11, MANUAL-01..06) against tagged tests in `tests/phase-08/`. Re-ran `bash tests/phase-08/run.sh` → 21/21 green. Cross-checked against `08-VERIFICATION.md` (status: passed, 5/5 success criteria verified, all 17 REQ-IDs SATISFIED).

**Manual-only additions:** CI branch-protection wiring (`MANUAL-06` post-merge UI action) — documented in `08-05-SUMMARY.md` as an operator action outside repo control.
