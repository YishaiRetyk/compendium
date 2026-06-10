---
phase: 19
slug: extension-contract-research-report-type
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-10
updated: 2026-06-10
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash scripts (bin/lint.sh, bin/audit-claims.sh, bin/check-neutrality.sh, bin/sync-claude.sh) — no unit test framework |
| **Config file** | none — repo scripts are the validation harness |
| **Quick run command** | `bash bin/lint.sh --ci` |
| **Full suite command** | `bash bin/lint.sh --ci && bash bin/check-neutrality.sh && bash bin/sync-claude.sh --check` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh --ci` (or targeted `--category provenance --category yaml`)
- **After every plan wave:** Run `bash bin/lint.sh --ci && bash bin/check-neutrality.sh && bash bin/sync-claude.sh --check`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-T1: Create source-types.md | 01 | 1 | EXT-01, EXT-02, EXT-03 | T-19-01-A (neutrality leak) | Abstract placeholders only in template-public file | lint + neutrality | `bash bin/check-neutrality.sh` | ❌ created by task | ⬜ pending |
| 01-T2: Wire routing + enum + ingest | 01 | 1 | EXT-01, RPT-01 | T-19-01-B (neutrality), T-19-01-C (byte-equal), T-19-01-D (dangling ref) | Routing row + file land in same commit; CLAUDE.md synced | lint + sync | `bash bin/lint.sh --category routing && bash bin/sync-claude.sh --check && bash bin/check-neutrality.sh` | ❌ edits existing | ⬜ pending |
| 02-T1: Add #r<n> to provenance.md | 02 | 1 | RPT-02, RPT-03 | T-19-02-A (neutrality) | Abstract placeholder in examples | neutrality | `bash bin/check-neutrality.sh` | ❌ edits existing | ⬜ pending |
| 02-T2: audit-claims.sh + audit.md | 02 | 1 | RPT-04, RPT-05 | T-19-02-B (nested registry), T-19-02-C (header search) | Nested source_registry access; multi-header _resolve_ref | runtime | `bash bin/audit-claims.sh --select derived-report --sample 5` | ❌ edits existing | ⬜ pending |
| 03-T1: lint.sh D-08/D-09/version | 03 | 2 | RPT-03 | T-19-03-A (flat registry), T-19-03-D (lint before sweep) | Flat source_registry access; D-08 guard on type!=source | lint version + yaml | `bash bin/lint.sh --require-version 1.9.0 && bash bin/lint.sh --category yaml` | ❌ edits existing | ⬜ pending |
| 03-T2: Sweep 97 direct→derived | 03 | 2 | RPT-06 | T-19-03-B (source sweep), T-19-03-C (over-grade) | wiki-cloud/sources/ excluded; only vlm-ocr-hallucination re-graded | lint provenance | `bash bin/lint.sh --category provenance` | ❌ edits existing | ⬜ pending |
| 04-T1: Retro-classify source summaries | 04 | 3 | RPT-02, RPT-06 | T-19-04-A (self-citation unchanged) | Source summary |direct| count unchanged | file grep | `grep -Ec '^- r[0-9]+::' wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` → 12 | ❌ edits existing | ⬜ pending |
| 04-T2: Log + index + DR + phase-final gate | 04 | 3 | RPT-05 | T-19-04-C (log format), T-19-04-D (DR fields) | UPDATE entries use compact dispatch form; DR has trigger_type: schema-update; D-08 negative test fires then reverted | full lint | `bash bin/lint.sh && bash bin/check-neutrality.sh` + residual `\|direct\|` grep → 0 | ❌ creates new DR | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No Wave 0 gaps — all infrastructure already exists. The validation harness (bin/lint.sh, bin/check-neutrality.sh, bin/sync-claude.sh, bin/audit-claims.sh) is pre-existing. New checks (D-08, D-09) are added in Plan 03 Wave 2 and must be committed in the same operation as the D-11 sweep.

**Wave 2→3 ordering (cross-AI review fix):** Plan 04 is Wave 3, `depends_on: 19-03`. D-08 fires only once Plan 04 sets `source_type: research-report`, so Plan 03's provenance check is vacuous for D-08; Plan 04's Task 2 runs the phase-final combined gate (full lint + zero-residual grep + D-08 negative test) as the non-vacuous end-to-end proof.

**Critical coupling (Pitfall 1):** Plan 03 Task 1 (lint.sh D-08 check) and Plan 03 Task 2 (97 |direct| → |derived| sweep) must be committed together or sweep-before-lint-check. Running `bash bin/lint.sh --category provenance` before the sweep will produce D-08 errors. The Per-Task Verification Map reflects this: Task 03-T1 only verifies `--category yaml` (not provenance), while Task 03-T2 verifies `--category provenance` after the sweep.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Contract readability — agent can evaluate a new candidate type | EXT-01, EXT-02 | Semantic judgment | Read schema/reference/source-types.md; walk hypothetical candidate (e.g., podcast audio) through all 5 dimensions; confirm the decision rule produces "sub-case of transcript" verdict |
| Retro-fit table completeness | EXT-03 | Semantic review | Confirm all 7 source types (article, paper, transcript, journal, data, image, research-report) have rows in the retro-fit table, each with all 5 dimension columns populated |
| Promotion path legibility | RPT-05 | Semantic judgment | Read the promotion mechanics in source-types.md § 5 (worked instance); confirm the re-pointing mechanics (derived → direct UPDATE op) are clear without referencing the planning docs |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references — N/A (no missing infrastructure)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
