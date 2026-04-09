---
phase: 3
slug: ingestion-provenance-pipeline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-10
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + grep + diff (shell-based validation) |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `bash tests/validate-wiki.sh --quick` |
| **Full suite command** | `bash tests/validate-wiki.sh` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/validate-wiki.sh --quick`
- **After every plan wave:** Run `bash tests/validate-wiki.sh`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | INGST-01 | integration | `bash tests/validate-wiki.sh --pass0` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | INGST-02 | integration | `bash tests/validate-wiki.sh --pass1` | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 1 | PROV-01 | integration | `bash tests/validate-wiki.sh --provenance` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | CMPL-01 | integration | `bash tests/validate-wiki.sh --compile` | ❌ W0 | ⬜ pending |
| 03-04-01 | 04 | 2 | CLI-02 | unit | `bash bin/ingest.sh --dry-run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/validate-wiki.sh` — validation harness for wiki structure, provenance, compilation
- [ ] `tests/fixtures/` — synthetic test source documents

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM agent produces correct wiki output | INGST-03 | Requires LLM execution | Run full ingest on test source, inspect output wiki pages |
| Cross-references between related pages | CMPL-06 | Semantic correctness | Verify xrefs point to real pages with relevant content |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
