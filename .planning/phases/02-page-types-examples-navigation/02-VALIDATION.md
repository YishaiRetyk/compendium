---
phase: 02
slug: page-types-examples-navigation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-09
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell scripts (bash) — no test framework needed for markdown validation |
| **Config file** | none — validation scripts created in Wave 0 |
| **Quick run command** | `bash schema/validate.sh` |
| **Full suite command** | `bash schema/validate.sh --full` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash schema/validate.sh`
- **After every plan wave:** Run `bash schema/validate.sh --full`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | PAGE-01–07 | structural | `bash schema/validate.sh templates` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | EPST-01–03 | grep | `grep -c 'epistemic::' wiki/entities/*.md` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 2 | EXMP-01–04 | YAML+links | `bash schema/validate.sh examples` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 2 | INDX-01–03, LOG-01–03 | structural | `bash schema/validate.sh index-log` | ❌ W0 | ⬜ pending |
| 02-03-01 | 03 | 3 | EXMP-05 | grep | `grep -c '\\[\\[' wiki/entities/*.md wiki/concepts/*.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `schema/validate.sh` — validation script for YAML frontmatter parsing, section structure, wikilink syntax, epistemic marker presence
- [ ] Python 3 `yaml` module available (for YAML parse validation)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Obsidian graph view shows connected cluster | Success Criterion 5 | Requires Obsidian GUI | Open vault in Obsidian, check graph view for connected nodes |
| Dataview queries render correctly | Success Criterion 5 | Requires Obsidian + Dataview plugin | Open index.md in Obsidian, verify Dataview tables populate |
| Wikilinks resolve (no broken links) | OBSD-01 | Obsidian link resolution | Open any example page, click wikilinks, verify they navigate |

*These are human verification items — automated checks confirm syntax, Obsidian confirms rendering.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
