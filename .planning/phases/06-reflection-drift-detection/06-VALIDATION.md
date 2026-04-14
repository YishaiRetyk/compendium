---
phase: 6
slug: reflection-drift-detection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + python3 inline (same as bin/lint.sh) |
| **Config file** | none — extends existing bin/lint.sh |
| **Quick run command** | `bin/lint.sh --category drift` |
| **Full suite command** | `bin/lint.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/lint.sh --category drift`
- **After every plan wave:** Run `bin/lint.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | DCSN-01, DCSN-02 | structural | `grep -l "type: decision" schema/templates/decision.md` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | DCSN-03 | structural | `grep -c "11.4" AGENTS.md` | ✅ | ⬜ pending |
| 06-02-01 | 02 | 2 | DRFT-01 | integration | `bin/lint.sh \| grep -i drift` | ✅ | ⬜ pending |
| 06-02-02 | 02 | 2 | DRFT-02 | integration | `bin/lint.sh \| grep -i drift` | ✅ | ⬜ pending |
| 06-02-03 | 02 | 2 | DRFT-03 | integration | `bin/lint.sh \| grep -i "vault\|index\|frontmatter"` | ✅ | ⬜ pending |
| 06-02-04 | 02 | 2 | DRFT-04 | integration | `bin/lint.sh \| grep -i drift` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `schema/templates/decision.md` — decision record page type template
- [ ] `wiki/decisions/` — decision record directory

*Existing bin/lint.sh infrastructure covers drift detection extension.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Decision records navigable in Obsidian | DCSN-02 | Requires Obsidian graph view inspection | Open vault, verify decision pages appear in graph with wikilink connections to affected pages |
| Reflect workflow produces correct decision records | DCSN-01 | Requires LLM agent execution of reflect workflow | Run reflect workflow against recent changes, verify decision record content matches §11.4 spec |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
