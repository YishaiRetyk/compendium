---
phase: 3
slug: ingestion-provenance-pipeline
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-10
audited: 2026-04-15
---

# Phase 3 -- Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline shell commands (grep, test, wc) per task `<verify>` block |
| **Config file** | none |
| **Quick run command** | Each task's `<automated>` verify block |
| **Full suite command** | Run all task verify blocks sequentially |
| **Estimated runtime** | ~5 seconds per task |

**Note:** This phase uses inline verification commands embedded in each task's `<verify><automated>` block rather than a standalone test harness. Each plan's tasks contain specific grep/test/wc commands that validate wiki structure, provenance markers, frontmatter fields, and content integrity. This approach is appropriate because the phase validates an LLM-executed pipeline (not deterministic code), and the verification targets are known file paths with known content patterns.

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verify block
- **After every plan wave:** Run all verify blocks for the wave's plans
- **Before `/gsd:verify-work`:** All task verify blocks must pass
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 03-01-01 | 01 | 1 | CMPL-01..07 | integration | `grep -c 'Claim Granularity Rules' AGENTS.md` | green |
| 03-01-02 | 01 | 1 | CMPL-01..07 | integration | `grep -c 'Append-Then-Synthesize' AGENTS.md` | green |
| 03-02-01 | 02 | 1 | CLI-02 | unit | `bash bin/ingest.sh --help` | green |
| 03-03-01 | 03 | 2 | INGST-03..06 | integration | inline verify (source creation + hash) | green |
| 03-03-02 | 03 | 2 | PROV-01..04 | integration | inline verify (provenance grep across wiki/) | green |
| 03-04-01 | 04 | 3 | INGST-03..06 | integration | inline verify (journal source creation) | green |
| 03-04-02 | 04 | 3 | PROV-01..04 | integration | inline verify (paragraph-level provenance grep) | green |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

No Wave 0 test infrastructure needed. All verification is inline within task `<verify><automated>` blocks using standard shell commands (grep, test, wc, awk). These commands require no installation or setup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM agent produces correct wiki output | INGST-03 | Requires LLM execution | Run full ingest on test source, inspect output wiki pages |
| Cross-references between related pages | CMPL-06 | Semantic correctness | Verify xrefs point to real pages with relevant content |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify blocks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No Wave 0 dependencies (inline verification only)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15

---

## Validation Audit 2026-04-15

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 7 task verify blocks re-executed; all green. Phase 03 remains nyquist-compliant. Statuses flipped `pending` → `green`. No new tests generated (no gaps).
