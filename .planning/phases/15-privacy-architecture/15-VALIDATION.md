---
phase: 15
slug: privacy-architecture
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash `test_*.sh` scripts under `tests/phase-15/`, sourcing `tests/phase-15/lib.sh` (`make_bare_repo`, `assert_exit_code`, `write_page`) |
| **Config file** | none — convention-based; each phase dir self-contained |
| **Quick run command** | `bash tests/phase-15/test_<name>.sh` |
| **Full suite command** | `for t in tests/phase-15/test_*.sh; do bash "$t"; done` (plus re-run prior phases' suites to confirm no regression from the rename) |
| **Estimated runtime** | ~30–60 seconds (bash smoke/unit scripts) |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/phase-15/test_<touched>.sh` + `bash bin/sync-claude.sh --check`
- **After every plan wave:** Run full `tests/phase-15/*` + `bash bin/lint.sh wiki-cloud/` (must be green — D-02 lockstep invariant)
- **Before `/gsd-verify-work`:** Full suite (phase-15 + regression of phase-07..13 fixture-updated tests) + byte-equality + CI `lint`/`privacy-leak`/`strict` green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-W0   | 00   | 0    | (infra)     | —          | Test scaffold + fixture updates land before structural change | infra | `bash tests/phase-15/lib.sh` (sourced) | ❌ W0 | ⬜ pending |
| 15-PRIV-01 | TBD | 1 | PRIV-01 | — | `wiki-cloud/`+`wiki-local/` exist; 2 audit files under `wiki-local/maintenance/`; no `wiki/` dir remains | smoke | `bash tests/phase-15/test_layout_migrated.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-02 | TBD | 1 | PRIV-02 | — | §13 contains asymmetric language; 7-row table absent; per-page precedence narrative gone | unit (grep schema) | `bash tests/phase-15/test_schema_13_rewritten.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-03 | TBD | 2 | PRIV-03 | T-15-leak | `.claude/settings.cloud.json` exists with `deny: Read(./wiki-local/**)`; verification test pins Read/Bash/git-show fail-direction | smoke + behavioral | `bash tests/phase-15/test_cloud_deny_profile.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-04 | TBD | 1 | PRIV-04 | — | No `privacy:` key in any page frontmatter; §5 base block + checklist item #5 removed | unit | `bash tests/phase-15/test_privacy_field_stripped.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-05a | TBD | 2 | PRIV-05 | T-15-leak | cloud→local link = `error` in lint | unit | `bash tests/phase-15/test_lint_xtier_link.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-05b | TBD | 2 | PRIV-05 | T-15-leak | check-privacy re-keyed (no `wiki-local/` in PUBLIC_PATHS/release) | unit | `bash tests/phase-15/test_check_privacy_rekey.sh` | ❌ W0 | ⬜ pending |
| 15-PRIV-05c | TBD | 2 | PRIV-05 | — | audit FAITH-04 predicate collapse — no regression | regression | `bash tests/phase-13/*` (audit suite) re-run green | ✅ exists | ⬜ pending |
| 15-PRIV-06 | TBD | 3 | PRIV-06 | — | DR at `wiki-cloud/decisions/dr-*-privacy-asymmetric-two-dir.md`, `trigger_type: schema-update`, records 3 options | unit | `bash tests/phase-15/test_decision_record.sh` | ❌ W0 (mirror phase-09.1 exists) | ⬜ pending |
| 15-PRIV-07 | TBD | 1 | PRIV-07 | — | core §13 = one-line pointer; no precedence/inheritance machinery in core | unit | `bash tests/phase-15/test_priv_resident_reduced.sh` | ❌ W0 | ⬜ pending |
| 15-XEQ | TBD | 1 | (cross) | — | `CLAUDE.md` ≡ `AGENTS.md` byte-equal; wizard regen byte-equal to canonical fixture | unit | `bash bin/sync-claude.sh --check`; `bash tests/phase-08/test_canonical_byte_equality.sh` | ✅ exists | ⬜ pending |
| 15-REG | TBD | 1 | (cross) | — | No regression: full lint suite + prior-phase tests green over renamed tree | regression | `bash bin/lint.sh wiki-cloud/`; re-run `tests/phase-07..13/*` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/phase-15/lib.sh` — copy from `tests/phase-13/lib.sh` (bump mktemp prefix to `phase15-`)
- [ ] `tests/phase-15/test_layout_migrated.sh` — PRIV-01
- [ ] `tests/phase-15/test_schema_13_rewritten.sh` — PRIV-02
- [ ] `tests/phase-15/test_cloud_deny_profile.sh` — PRIV-03 (the D-12.4 three-surface verification test: Read tool, Bash read, `git show HEAD:wiki-local/…`)
- [ ] `tests/phase-15/test_privacy_field_stripped.sh` — PRIV-04
- [ ] `tests/phase-15/test_lint_xtier_link.sh` + `test_check_privacy_rekey.sh` — PRIV-05
- [ ] `tests/phase-15/test_decision_record.sh` — PRIV-06 (mirror `tests/phase-09.1/test_decision_record.sh`)
- [ ] `tests/phase-15/test_priv_resident_reduced.sh` — PRIV-07
- [ ] **Fixture update task:** ~40 prior-phase `test_*.sh` files asserting `wiki/` paths must be updated to `wiki-cloud/` IN the lockstep commit (else the regression suite goes red — this is itself a validation gate, not optional cleanup)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live cloud-session `claude --settings .claude/settings.cloud.json` is actually blocked from reading `wiki-local/` | PRIV-03 | Headless `claude -p --settings` assertion may not be automatable in CI (depends on harness version; research flagged a plan-time spike). If automatable in `test_cloud_deny_profile.sh`, this row is retired. | Launch a cloud-profile session; attempt `Read(./wiki-local/maintenance/audit-state.md)`, a Bash `cat`, and `git show HEAD:wiki-local/maintenance/audit-state.md`; confirm Read+Bash blocked, document that `git show` is NOT blocked (fail-open — the honest fail-direction table) |

*Automated portion (static assertions on `settings.cloud.json` shape + the documented fail-direction table) lives in `test_cloud_deny_profile.sh`; the live three-surface behavioral check is the manual fallback if the headless spike fails.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
