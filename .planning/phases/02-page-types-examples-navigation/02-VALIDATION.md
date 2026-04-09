---
phase: 02
slug: page-types-examples-navigation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-09
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline grep/test commands — no external test framework needed for markdown validation |
| **Config file** | none — all validation is inline |
| **Quick run command** | Per-task grep commands in `<automated>` blocks |
| **Full suite command** | Run all task `<automated>` blocks sequentially |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run task's `<automated>` verify block
- **After every plan wave:** Run all `<automated>` blocks from the wave
- **Before `/gsd:verify-work`:** All automated checks must pass
- **Max feedback latency:** 1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 02-01-T1 | 01 | 1 | PAGE-01, PAGE-02, PAGE-06, PAGE-07 | grep structural | `grep -c "^---" schema/templates/entity.md && grep "^type:" schema/templates/entity.md && grep -c "## TL;DR" schema/templates/entity.md` | ⬜ pending |
| 02-01-T2 | 01 | 1 | PAGE-03, PAGE-04, PAGE-05 | grep structural | `grep -c "^---" schema/templates/source-summary.md && grep "^type:" schema/templates/comparison.md && grep "## Comparison Table" schema/templates/comparison.md` | ⬜ pending |
| 02-02-T1 | 02 | 2 | EXMP-01, EXMP-02, EPST-01, EPST-02 | test + grep | `test -f wiki/entities/daniel-kahneman.md && grep -c "\[epistemic::" wiki/entities/daniel-kahneman.md && grep -c "\[prov:" wiki/concepts/cognitive-biases.md` | ⬜ pending |
| 02-02-T2 | 02 | 2 | EXMP-03, EXMP-04 | test + grep | `test -f wiki/sources/src-*thinking-fast*.md && grep -c "\[\[" wiki/comparisons/system-1-vs-system-2.md && grep "## Comparison Table" wiki/comparisons/system-1-vs-system-2.md` | ⬜ pending |
| 02-03-T1 | 03 | 3 | EXMP-05, INDX-01, INDX-02, INDX-03, LOG-01, LOG-02, LOG-03 | grep + wc | `grep -c "\[\[" wiki/index.md && grep -P "^\d{4}-\d{2}-\d{2}" wiki/log.md && grep "^## " wiki/index.md` | ⬜ pending |
| 02-03-T2 | 03 | 3 | EPST-03, PAGE-06 | grep | `grep "### Inline Epistemic Markers" AGENTS.md && grep "### Mixed Inline Grammar" AGENTS.md` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. All validation uses inline grep/test commands — no test framework or validation scripts needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Obsidian graph view shows connected cluster | Success Criterion 5 | Requires Obsidian GUI | Open vault in Obsidian, check graph view for connected nodes between example pages |
| Dataview frontmatter renders in Obsidian | OBSD-02 | Requires Obsidian + Dataview plugin | Open any example page, verify frontmatter fields appear in Dataview |
| Wikilinks resolve (no broken links) | OBSD-01 | Obsidian link resolution | Open any example page, click wikilinks, verify navigation |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 2s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-09
