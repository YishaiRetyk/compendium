---
phase: 5
slug: lint-quality
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-13
updated: 2026-04-15
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
| 05-01-01 | 01 | 1 | STALE-01,02,03,04 | schema | `grep -c -i 'decay' AGENTS.md` | ✅ | ✅ green |
| 05-02-01 | 02 | 1 | CNTR-01,02,03 | schema | `grep -c -i 'contradiction' AGENTS.md` | ✅ | ✅ green |
| 05-03-01 | 03 | 2 | LINT-01,02,03,04,05,GAP-01,GAP-02 | integration | `bash bin/lint.sh wiki/ --dry-run 2>&1 | tail -5` | ✅ | ✅ green |
| 05-04-01 | 04 | 2 | CLI-03,LINT-06,07 | integration | `bash bin/lint.sh --help 2>&1 | grep -c 'Usage'` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: Original draft listed 05-05 and 05-06 plans; these were consolidated into plan 04 during execution (gap detection + suggestions folded into the end-to-end validation plan).*

---

## Wave 0 Requirements

- [x] `bin/lint.sh` created in Wave 1 (972 lines, 9 checks)
- [x] `wiki/maintenance/lint-report.md` created during execution
- [x] No test framework needed — validation uses the lint tool itself and grep checks against AGENTS.md

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15

---

## Validation Audit 2026-04-15

| Metric | Count |
|--------|-------|
| Gaps found | 0 (no missing test coverage) |
| Doc-drift issues resolved | 5 (status refresh, phantom row removal, grep string fixes, Wave 0 tick, frontmatter flip) |
| Resolved | 4 (all task rows now green) |
| Escalated | 0 |

Phase already passed verification (05-VERIFICATION.md, 5/5 truths, 17/17 reqs). VALIDATION.md was a stale draft; this audit refreshed it to reflect shipped state. No new test files generated — phase-appropriate (shell-based tool with the lint script as its own test harness).
