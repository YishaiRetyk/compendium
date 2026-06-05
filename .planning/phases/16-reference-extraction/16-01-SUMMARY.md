---
phase: 16-reference-extraction
plan: "01"
subsystem: schema
tags:
  - reference-extraction
  - schema-refactor
  - agents-md
  - page-types
  - frontmatter
dependency_graph:
  requires:
    - neutrality-gate-green
    - schema-in-public-paths-check-neutrality
  provides:
    - schema-reference-page-types-md
    - schema-reference-frontmatter-md
    - agents-md-section-4-stub
    - agents-md-section-5-stub
    - agents-md-section-7-dissolved
    - template-mirror-ref-09
  affects:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/reference/page-types.md
    - schema/reference/frontmatter.md
tech_stack:
  added: []
  patterns:
    - agent-authoritative reference files in schema/reference/ (inverted SSOT lede)
    - bare pointer stub form for extracted sections (D-01)
    - per-commit template mirror obligation (REF-09)
    - bottom-up edit order to avoid line-number drift
key_files:
  created:
    - schema/reference/page-types.md
    - schema/reference/frontmatter.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
decisions:
  - "§4 extracted verbatim to page-types.md; §7 ordering table merged into page-types.md as Per-Type Section Ordering section; §7 bullets 4-7 absorbed as Authoring Conventions"
  - "§5 extracted verbatim to frontmatter.md; template placeholder lines ({{PRIMARY_DOMAIN}}, {{DEFAULT_PRIVACY}}) replaced with rendered values in AGENTS.md/CLAUDE.md — these only appeared in template"
  - "§7 dissolved entirely with no stub; nav rules confirmed present in §3 LLM Navigation Rule before deletion"
  - "Template mirror applied in same commit (REF-09); stubs byte-identical between AGENTS.md and schema/AGENTS.template.md"
  - "Bottom-up edit order used (§7 then §5 then §4) to prevent line-number drift during sequential replacements"
metrics:
  duration: "~25 minutes"
  completed: 2026-06-05
  tasks_completed: 2
  files_modified: 5
---

# Phase 16 Plan 01: §4 Page Types + §5 Frontmatter Extraction; §7 Dissolution Summary

Extract §4 (page types) and §5 (frontmatter schema) from the AGENTS.md monolith into standalone reference files; dissolve §7 Progressive Disclosure; mirror all stubs into schema/AGENTS.template.md in the same commit (REF-09).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create schema/reference/page-types.md (§4 content + §7 ordering table merged) | 22feddf | schema/reference/page-types.md |
| 2 | Create schema/reference/frontmatter.md; stub §4/§5/§7 in AGENTS.md AND schema/AGENTS.template.md; sync to CLAUDE.md; commit | 22feddf | schema/reference/frontmatter.md, AGENTS.md, CLAUDE.md, schema/AGENTS.template.md |

Note: Per plan instructions, Tasks 1 and 2 were committed together as one atomic commit.

## Verification Results

All plan verification checks passed:

- `wc -l schema/reference/page-types.md` → 154 lines (≥100 minimum)
- `wc -l schema/reference/frontmatter.md` → 149 lines (≥130 minimum)
- `grep "schema/reference/page-types.md" AGENTS.md` → §4 stub pointer present
- `grep "schema/reference/frontmatter.md" AGENTS.md` → §5 stub pointer present
- `grep "Progressive Disclosure" AGENTS.md` → NOT FOUND (§7 dissolved)
- `grep "schema/reference/page-types.md" schema/AGENTS.template.md` → template §4 stub mirrored
- `grep "schema/reference/frontmatter.md" schema/AGENTS.template.md` → template §5 stub mirrored
- `grep "Progressive Disclosure" schema/AGENTS.template.md` → NOT FOUND (template §7 dissolved)
- `bash bin/sync-claude.sh --check` → OK: AGENTS.md == CLAUDE.md
- `bash bin/check-neutrality.sh` → exit=0
- `grep "Authoring Conventions" schema/reference/page-types.md` → present (§7 bullets 4-7 absorbed)
- `grep "Per-Type Section Ordering" schema/reference/page-types.md` → present (§7 ordering table merged)
- `grep "Frontmatter Validation Checklist" schema/reference/frontmatter.md` → present
- §3 "LLM Navigation Rule" 3 steps confirmed present before §7 deletion (disposition guard verified)

## §7 Disposition Table Compliance

Every dissolved §7 subsection has a named destination:

| §7 subsection | Destination |
|---------------|-------------|
| "## 7. Progressive Disclosure" intro | DROPPED — restated by §3 LLM Navigation Rule + AGENTS.md preamble |
| "### Rules for LLM Agents" bullets 1-3 | DROPPED — duplicate of §3 "LLM Navigation Rule" 3 numbered steps (confirmed present) |
| "### Rules for LLM Agents" bullets 4-7 | MERGED → schema/reference/page-types.md "### Authoring Conventions" |
| "### Per-Type Section Ordering" table | MERGED → schema/reference/page-types.md "## Per-Type Section Ordering" |
| "### Why This Matters" | DROPPED — illustrative narrative, redundant with §1 principle |

## Deviations from Plan

None — plan executed exactly as written. Both tasks committed in a single atomic commit (22feddf) as required by plan: "all FIVE files (incl. schema/AGENTS.template.md) staged and committed in one commit".

## Known Stubs

None. Both new schema/reference/*.md files contain full verbatim content from §4 and §5, not stubs.

## Threat Flags

All threat mitigations applied as specified in plan threat model:

| Flag | File | Status |
|------|------|--------|
| T-16-01-01 (Information Disclosure) | schema/reference/page-types.md | MITIGATED — bin/check-neutrality.sh exits 0 |
| T-16-01-02 (Information Disclosure) | schema/reference/frontmatter.md | MITIGATED — bin/check-neutrality.sh exits 0 |
| T-16-01-03 (Tampering — AGENTS.md byte equality) | AGENTS.md/CLAUDE.md | MITIGATED — bin/sync-claude.sh --check exits 0 |

## Self-Check: PASSED

- Commit `22feddf` exists: confirmed (git rev-parse --short HEAD)
- Files created: schema/reference/page-types.md (154 lines), schema/reference/frontmatter.md (149 lines)
- Files modified: AGENTS.md, CLAUDE.md, schema/AGENTS.template.md
- No file deletions in commit (only insertions and modifications)
- `bash bin/sync-claude.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0
- Template §4 stub matches AGENTS.md §4 stub exactly (diff empty)
- §7 gone from both AGENTS.md and schema/AGENTS.template.md
