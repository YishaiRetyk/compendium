---
phase: 16-reference-extraction
plan: "02"
subsystem: schema
tags:
  - reference-extraction
  - schema-refactor
  - agents-md
  - provenance
  - staleness
  - consumer-split
dependency_graph:
  requires:
    - schema-reference-page-types-md
    - schema-reference-frontmatter-md
    - agents-md-section-4-stub
    - agents-md-section-5-stub
    - neutrality-gate-green
  provides:
    - schema-reference-provenance-md
    - schema-workflows-lint-md-seed
    - agents-md-section-6-stub
    - template-mirror-ref-09-section-6
  affects:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/reference/provenance.md
    - schema/workflows/lint.md
tech_stack:
  added: []
  patterns:
    - consumer-split extraction (authoring-time vs lint-time content in separate files)
    - partial-content header for Phase-owned seed files (Phase 17 owns full lint procedure)
    - header-anchor-based §6 mutation (not absolute line numbers — cycle-2 MEDIUM fix applied)
    - per-commit template mirror obligation (REF-09)
key_files:
  created:
    - schema/reference/provenance.md
    - schema/workflows/lint.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
decisions:
  - "§6 consumer-split: provenance syntax/epistemics (authoring-time) → schema/reference/provenance.md; decay math (lint-time) → schema/workflows/lint.md"
  - "Contradiction Inline Syntax routed to provenance.md (describes a marker format, not decay math) — per RESEARCH.md seam landmarks"
  - "lint.md seeded with decay table + staleness auto-fix only; partial-content header explicitly states Phase 17 owns the full lint procedure"
  - "§6 stub located by header anchor (^## 6. → next ^## [0-9]+.) not absolute line number — 16-01 shifted §6 from line 399 to line 151"
  - "{{DECAY_PROFILE}} placeholder in template §6 removed along with decay content (moves to lint.md template copy in Phase 17)"
  - "Template mirror applied in same commit (REF-09); stubs byte-identical between AGENTS.md and schema/AGENTS.template.md"
metrics:
  duration: "~15 minutes"
  completed: 2026-06-05
  tasks_completed: 2
  files_modified: 5
---

# Phase 16 Plan 02: §6 Consumer-Split Extraction (provenance.md + lint.md seed) Summary

Extract §6 Provenance, Epistemics, and Staleness from the AGENTS.md monolith using a consumer-split: syntax/epistemics content → `schema/reference/provenance.md`; decay table and staleness auto-fix → `schema/workflows/lint.md` (seeded for Phase 17); AGENTS.md §6 replaced by 1-line requirement + 2 stub pointers; all changes mirrored into `schema/AGENTS.template.md` in the same commit (REF-09).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create schema/reference/provenance.md (§6 syntax/epistemics + Contradiction Inline Syntax) | 0121067 | schema/reference/provenance.md |
| 2 | Create schema/workflows/lint.md (decay seed); stub §6 in AGENTS.md AND schema/AGENTS.template.md; sync to CLAUDE.md; commit | 0121067 | schema/workflows/lint.md, AGENTS.md, CLAUDE.md, schema/AGENTS.template.md |

Note: Per plan instructions, Tasks 1 and 2 were committed together as one atomic commit (all 5 files staged together).

## Verification Results

All plan verification checks passed:

- `wc -l schema/reference/provenance.md` → 190 lines (≥130 minimum)
- `wc -l schema/workflows/lint.md` → 50 lines (≥30 minimum)
- `grep -q "Contradiction Inline Syntax" schema/reference/provenance.md` → PASS (correct routing)
- `! grep -q "Domain-Based Decay Rate Table" schema/reference/provenance.md` → PASS (correct exclusion)
- `grep -q "Staleness Auto-Fix Rules" schema/workflows/lint.md` → PASS (correct routing)
- `grep -q "Domain-Based Decay Rate Table" schema/workflows/lint.md` → PASS
- `grep -c "Decay Period" schema/workflows/lint.md` → 1 (≥1 required)
- `! grep -q "^## 11\.3" schema/workflows/lint.md` → PASS (Phase 17 scope not pre-empted)
- `grep -q "schema/reference/provenance.md" AGENTS.md` → PASS (§6 stub pointer present)
- `grep -q "schema/workflows/lint.md" AGENTS.md` → PASS (§6 stub pointer present)
- `grep -q "schema/reference/provenance.md" schema/AGENTS.template.md` → PASS (template mirrored)
- `grep -q "schema/workflows/lint.md" schema/AGENTS.template.md` → PASS (template mirrored)
- `diff <§6 AGENTS.md> <§6 template>` → empty (byte-identical §6 stubs)
- `bash bin/sync-claude.sh --check` → OK: AGENTS.md == CLAUDE.md
- `bash bin/check-neutrality.sh` → exit=0
- §6 stub is exactly the 5-line D-03 remnant (no orphaned decay content)
- lint.md does NOT contain "Pass 0", "## Steps:", or any §11.3 lint workflow procedure text

## Consumer-Split Seam Compliance

| Content | Destination | Routed Correctly |
|---------|-------------|-----------------|
| Inline Provenance Syntax | provenance.md | PASS |
| Locator Types table | provenance.md | PASS |
| Page-marker convention | provenance.md | PASS |
| Support Types table | provenance.md | PASS |
| Checked At | provenance.md | PASS |
| Examples in Context | provenance.md | PASS |
| Bad vs. Good Provenance Examples | provenance.md | PASS |
| Source Registry | provenance.md | PASS |
| Provenance Validation Rules | provenance.md | PASS |
| Inline Epistemic Markers | provenance.md | PASS |
| Page-Level vs Claim-Level | provenance.md | PASS |
| Mixed Inline Grammar | provenance.md | PASS |
| **Contradiction Inline Syntax** | **provenance.md** | **PASS (critical seam check)** |
| Domain-Based Decay Rate Table | lint.md | PASS |
| Epistemic Status Modifiers | lint.md | PASS |
| Hash override (D-09) | lint.md | PASS |
| Date fallback chain | lint.md | PASS |
| Staleness Auto-Fix Rules | lint.md | PASS |

## Deviations from Plan

None — plan executed exactly as written. The header-anchor approach (`awk 'f && /^## [0-9]+\./{exit} /^## 6\./{f=1} f'`) correctly located §6 at its shifted position (line 151, shifted from baseline line 399 after 16-01 collapsed §4/§5 and dissolved §7). The generic next-header terminator stopped at `## 8.` since `## 7.` no longer exists (cycle-2 MEDIUM fix applied correctly).

Template §6 replacement used Python regex with `re.DOTALL` to handle the multiline §6 block containing `{{DECAY_PROFILE}}` placeholder — the placeholder was correctly removed along with all decay content. A missing blank line between stub and `## 8.` was corrected with a targeted Edit before committing.

## Known Stubs

None. Both new schema files contain full verbatim content extracted from §6. The AGENTS.md §6 stub is intentional (the D-03 remnant pattern — the full content now lives in the two schema files).

## Threat Flags

All threat mitigations applied as specified in plan threat model:

| Flag | File | Status |
|------|------|--------|
| T-16-02-01 (Information Disclosure) | schema/reference/provenance.md | MITIGATED — bin/check-neutrality.sh exits 0 |
| T-16-02-02 (Tampering — Contradiction Inline Syntax mis-routed) | seam check | MITIGATED — grep confirms provenance.md has it, lint.md does not |
| T-16-02-03 (Tampering — AGENTS.md byte equality) | AGENTS.md/CLAUDE.md | MITIGATED — bin/sync-claude.sh --check exits 0 |
| T-16-02-04 (Tampering — lint.md scope creep) | schema/workflows/lint.md | MITIGATED — no "Pass 0", "## Steps:", or §11.3 procedure text found |

## Self-Check: PASSED

- Commit `0121067` exists: confirmed
- Files created: schema/reference/provenance.md (190 lines), schema/workflows/lint.md (50 lines)
- Files modified: AGENTS.md, CLAUDE.md, schema/AGENTS.template.md
- No file deletions in commit (only additions and in-place modifications)
- `bash bin/sync-claude.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0
- Template §6 stub matches AGENTS.md §6 stub exactly (diff empty)
- lint.md has partial-content header noting Phase 17 adds full procedure
