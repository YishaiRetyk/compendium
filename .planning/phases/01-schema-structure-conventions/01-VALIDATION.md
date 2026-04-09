---
phase: 1
slug: schema-structure-conventions
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-09
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell scripts + grep-based validation (no test framework — this phase produces markdown/YAML, not code) |
| **Config file** | none — no test framework needed |
| **Quick run command** | `bash .planning/phases/01-schema-structure-conventions/validate.sh quick` |
| **Full suite command** | `bash .planning/phases/01-schema-structure-conventions/validate.sh full` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick validation (structure checks)
- **After every plan wave:** Run full validation suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | SCHM-01 | file-exists + content | `test -f AGENTS.md && grep -q "## 1. Overview" AGENTS.md` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DIRS-01 | dir-exists | `test -d sources/` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DIRS-02 | dir-exists | `test -d wiki/` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | OBSD-01 | content-grep | `grep -r '\[\[' wiki/ 2>/dev/null` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | OBSD-02 | yaml-parse | `head -1 wiki/index.md \| grep -q '^---'` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PROG-01 | content-grep | `grep -q '## TL;DR' AGENTS.md` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BNDY-01 | content-grep | `grep -q 'Scaling' AGENTS.md` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | BNDY-02 | content-grep | `grep -q 'privacy' AGENTS.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs will be filled after planning creates PLAN.md files.*

---

## Wave 0 Requirements

- [ ] `validate.sh` — shell script for structural validation of AGENTS.md, directory layout, and frontmatter
- [ ] Validation checks: file existence, required sections present, YAML frontmatter parseable, wikilink syntax valid

*No test framework install needed — shell scripts and grep are sufficient for validating markdown/YAML artifacts.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM can follow schema | SCHM-01 | Requires LLM comprehension test | Have an LLM read AGENTS.md and attempt to create a wiki page following instructions |
| Graph-friendly structure | OBSD-03 | Requires Obsidian visual inspection | Open vault in Obsidian, check graph view shows meaningful connections |
| Dataview compatibility | OBSD-04 | Requires Obsidian + Dataview plugin | Run a Dataview query against wiki pages to verify frontmatter is queryable |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
