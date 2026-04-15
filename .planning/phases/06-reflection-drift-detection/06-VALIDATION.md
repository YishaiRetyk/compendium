---
phase: 6
slug: reflection-drift-detection
status: validated
nyquist_compliant: partial
wave_0_complete: true
created: 2026-04-14
audited: 2026-04-15
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
| 06-01-01 | 01 | 1 | DCSN-01, DCSN-02 | structural | `grep -l "type: decision" schema/templates/decision.md` | ✅ | ✅ green |
| 06-01-02 | 01 | 1 | DCSN-01, DCSN-02 | structural | `grep -c "4.6 Decision" AGENTS.md && grep -c "## Decisions" wiki/index.md` | ✅ | ✅ green |
| 06-02-01 | 02 | 2 | DRFT-01 | integration | `bin/lint.sh \| grep -i "Check 10a"` | ✅ | ✅ green |
| 06-02-02 | 02 | 2 | DRFT-02 | integration | `bin/lint.sh \| grep -i "Check 10b"` | ✅ | ✅ green |
| 06-02-03 | 02 | 2 | DRFT-03 | integration | `bin/lint.sh \| grep -i "Check 10e"` | ✅ | ✅ green |
| 06-02-04 | 02 | 2 | DRFT-04 | integration | `bin/lint.sh \| grep -E "### (stale\|drift\|yaml)"` | ✅ | ✅ green |
| 06-03-01 | 03 | 3 | DCSN-03 | structural | `grep -c "Three-Tier Reflect Model" AGENTS.md && grep -c "DRFT-01" AGENTS.md` | ✅ | ✅ green |
| 06-03-02 | 03 | 3 | DCSN-03 | structural | `test -f wiki/maintenance/reflect-state.md && grep -c "last_reflect_commit" wiki/maintenance/reflect-state.md` | ✅ | ✅ green |
| 06-03-03 | 03 | 3 | DCSN-01, DCSN-02, DCSN-03 | manual | human verification (Task 3 approved) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `schema/templates/decision.md` — decision record page type template
- [x] `wiki/decisions/` — decision record directory (with inaugural `dr-2026-04-14-phase6-decision-type.md`)
- [x] `wiki/maintenance/reflect-state.md` — reflect checkpoint file

*Existing bin/lint.sh infrastructure covers drift detection extension; Check 10a-10e integrated.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Decision records navigable in Obsidian | DCSN-02 | Requires Obsidian graph view inspection | Open vault, verify decision pages appear in graph with wikilink connections to affected pages |
| Reflect workflow produces correct decision records | DCSN-01 | Requires LLM agent execution of reflect workflow | Run reflect workflow against recent changes, verify decision record content matches §11.4 spec |
| Three-tier reflect model executes as documented | DCSN-03 | Requires LLM agent running Tier 1/2/3 hooks | Trigger MERGE + SUPERSEDE, confirm inline decision records created; run Tier 3 periodic pass from checkpoint |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s (measured: ~5s)
- [ ] `nyquist_compliant: true` — set to `partial`: structural/integration coverage complete, behavioral LLM-execution checks remain manual-only by design

**Approval:** validated 2026-04-15 — structural and integration coverage verified green; behavioral LLM-execution verifications remain manual by necessity.

---

## Validation Audit 2026-04-15

| Metric | Count |
|--------|-------|
| Tasks audited | 9 |
| Requirements mapped | 7 (DCSN-01, DCSN-02, DCSN-03, DRFT-01..04) |
| Gaps found | 3 (stale mapping: 06-01-02 incorrectly attributed to DCSN-03; missing rows for 06-03-01/02/03; all statuses still ⬜ pending after execution) |
| Resolved | 3 (corrected mapping, added plan-03 rows, flipped statuses to ✅ green via re-run of automated commands) |
| Escalated to manual-only | 1 (DCSN-03 behavioral execution) |

**Automated command re-run results (all PASS):**
- `grep -l "type: decision" schema/templates/decision.md` → found
- `grep -c "4.6 Decision" AGENTS.md` → non-zero
- `bin/lint.sh` → exit 0, Check 10a-10e all present, report grouped by category
- `grep -c "Three-Tier Reflect Model" AGENTS.md` → 1
- `test -f wiki/maintenance/reflect-state.md` → present
