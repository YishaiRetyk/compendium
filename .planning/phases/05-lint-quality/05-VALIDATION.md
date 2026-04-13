---
phase: 5
slug: lint-quality
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + grep/awk/sed (shell-based validation matching existing bin/*.sh pattern) |
| **Config file** | none — uses AGENTS.md as schema source of truth |
| **Quick run command** | `bash bin/lint.sh wiki/ --dry-run 2>&1 | tail -5` |
| **Full suite command** | `bash bin/lint.sh wiki/` |
| **Estimated runtime** | ~5 seconds (small wiki) |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh wiki/ --dry-run 2>&1 | tail -5`
- **After every plan wave:** Run `bash bin/lint.sh wiki/`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | STALE-01,02,03,04 | schema | `grep -c 'decay_rate' AGENTS.md` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | CNTR-01,02,03 | schema | `grep -c 'contradiction' AGENTS.md` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 2 | LINT-01,02,03,04,05 | integration | `bash bin/lint.sh wiki/ 2>&1 | grep -c 'error\|warning\|info'` | ❌ W0 | ⬜ pending |
| 05-04-01 | 04 | 2 | CLI-03 | integration | `bash bin/lint.sh --help 2>&1 | grep -c 'Usage'` | ❌ W0 | ⬜ pending |
| 05-05-01 | 05 | 3 | GAP-01,GAP-02 | integration | `bash bin/lint.sh wiki/ 2>&1 | grep -c 'gap'` | ❌ W0 | ⬜ pending |
| 05-06-01 | 06 | 3 | LINT-06,07 | manual+schema | `grep -c 'suggest' AGENTS.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing `bin/lint.sh` does not exist — Wave 1 creates it
- [ ] Existing `wiki/maintenance/` does not exist — created during execution
- [ ] No test framework needed — validation uses the lint tool itself and grep checks against AGENTS.md

*Existing infrastructure (bin/ingest.sh, bin/search.sh, bin/validate-op.sh) provides the pattern but no reusable test harness.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Contradiction inline markers readable in Obsidian | CNTR-03 | Visual rendering in Obsidian | Open affected page in Obsidian, confirm contradiction markers are visible inline |
| Lint report browsable in Obsidian | LINT-01 | Visual rendering | Open wiki/maintenance/lint-report.md in Obsidian |
| Knowledge gap suggestions are useful | LINT-06 | Subjective quality | Review suggested questions in lint output for relevance |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
