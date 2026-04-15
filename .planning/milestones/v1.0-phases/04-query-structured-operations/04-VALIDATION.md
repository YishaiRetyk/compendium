---
phase: 4
slug: query-structured-operations
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-12
validated: 2026-04-15
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + grep/diff assertions (no test framework — phase delivers bash scripts and markdown specs) |
| **Config file** | none — validation is script-exit-code and content-check based |
| **Quick run command** | `bash bin/validate-op.sh UPDATE wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md && bash bin/search.sh test` |
| **Full suite command** | `bash bin/validate-op.sh UPDATE wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md && bash bin/search.sh test && bash bin/search.sh --query "test query"` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick validation command on affected scripts/specs
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | SOPS-01 | content | `grep -c "validate-op" AGENTS.md` | ✅ | ✅ green |
| 04-01-02 | 01 | 1 | SOPS-02 | content | `grep -E "UPDATE\|MERGE\|SUPERSEDE\|ARCHIVE" AGENTS.md` | ✅ | ✅ green |
| 04-02-01 | 02 | 1 | SOPS-03 | script | `bash bin/validate-op.sh UPDATE wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` | ✅ | ✅ green |
| 04-02-02 | 02 | 1 | SOPS-04 | content | `grep "compilation_status" AGENTS.md` | ✅ | ✅ green |
| 04-03-01 | 03 | 2 | CLI-01 | script | `bash bin/search.sh test` | ✅ | ✅ green |
| 04-04-01 | 04 | 2 | QURY-01 | content | `grep -E "index.first" AGENTS.md` | ✅ | ✅ green |
| 04-04-02 | 04 | 2 | QURY-02 | content | `grep "write-back" AGENTS.md` | ✅ | ✅ green |
| 04-04-03 | 04 | 2 | QURY-03 | content | `grep "compilation_status" AGENTS.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No test framework needed — bash scripts self-validate via exit codes
- [ ] Existing wiki structure provides test fixtures (source pages, index, log)

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Query workflow end-to-end | QURY-01 | Requires LLM agent execution | Run a query against wiki using AGENTS.md §11.2 workflow, verify cited answer |
| Write-back decision logic | QURY-02 | Requires LLM judgment | After query, verify write-back was triggered or skipped with logged rationale |
| Delta compilation trigger | QURY-03 | Requires uncompiled source state | Add source with `compilation_status: pending`, query related topic, verify compilation fires |
| Batch validation abort | SOPS-05 | Requires multi-op workflow | Propose batch with one invalid op, verify entire batch aborts |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15

---

## Validation Audit 2026-04-15

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

**Resolved gaps:**
- **04-02-01 (SOPS-03):** Test command referenced nonexistent fixture `wiki/sources/test.md` → updated to existing `src-2026-04-09-thinking-fast-and-slow-part1.md`. Verified exit 0.
- **04-04-01 (QURY-01):** `grep "index-first"` (hyphenated) found 0 matches; actual AGENTS.md phrasing is `"index first"`. Updated pattern to `grep -E "index.first"`. Verified green.

All 8 automated verify commands now run green. `nyquist_compliant: true`.
