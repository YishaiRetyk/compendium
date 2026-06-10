---
phase: 19
slug: extension-contract-research-report-type
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-10
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash scripts (bin/lint.sh, bin/audit-claims.sh) — no unit test framework |
| **Config file** | none — repo scripts are the validation harness |
| **Quick run command** | `bash bin/lint.sh --ci` |
| **Full suite command** | `bash bin/lint.sh --ci && bash bin/check-neutrality.sh` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh --ci`
- **After every plan wave:** Run `bash bin/lint.sh --ci && bash bin/check-neutrality.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements (bin/lint.sh and bin/check-neutrality.sh already exist; phase adds checks to them).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Contract readability — agent can evaluate a new candidate type | EXT-01 | Semantic judgment | Read schema/reference/source-types.md and walk a hypothetical candidate through the 5 dimensions |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
