---
phase: 7
slug: neutral-template-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts (`bin/tests/*.sh`) + CI workflow (`.github/workflows/neutrality.yml`) |
| **Config file** | none — scripts self-contained |
| **Quick run command** | `bash bin/lint.sh` |
| **Full suite command** | `bash bin/check-neutrality.sh && bash bin/lint.sh && bash bin/requirements-sync.sh --check` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh`
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green + manual orphan-branch dry-run pass
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

*To be populated by planner — one row per task. Columns: Task ID, Plan, Wave, Requirement, Test Type, Automated Command, File Exists, Status.*

---

## Wave 0 Requirements

- [ ] `bin/check-neutrality.sh` — greps public surfaces for denylist terms (Kahneman + personal-vault terms)
- [ ] `bin/tests/test-neutrality.sh` — positive/negative fixtures for check-neutrality
- [ ] `bin/tests/test-requirements-sync.sh` — fixtures for requirements-sync drift detection
- [ ] `bin/tests/test-orphan-release.sh --dry-run` — non-destructive dry-run for orphan-branch runbook
- [ ] `.github/workflows/neutrality.yml` — CI gate wiring
- [ ] Denylist source file (e.g., `bin/denylist.txt`) populated and reviewed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Orphan-branch release produces clean history | TMPL-07, NEUT-07 | Destructive git operation; only dry-run is automated | Execute runbook on throwaway clone; verify `git log` shows single v1.1 commit |
| "Use this template" button visible on GitHub | TMPL-01 | GitHub UI, not scriptable from repo | Open repo page after repo-settings toggle; confirm button present |
| `examples/kahneman/` wikilinks render in Obsidian | TMPL-06 | Obsidian-specific rendering | Open vault, click each wikilink, confirm resolution |
| PRIVACY.md content review | TMPL-10 | Legal/policy wording | Human reads and approves |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
