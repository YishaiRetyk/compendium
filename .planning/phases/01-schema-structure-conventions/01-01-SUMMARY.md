---
phase: 01-schema-structure-conventions
plan: 01
subsystem: schema
tags: [agents-md, obsidian, dataview, frontmatter, provenance, wikilinks, progressive-disclosure]

# Dependency graph
requires: []
provides:
  - "Directory skeleton: sources/, wiki/{entities,concepts,sources,comparisons,overviews}/, schema/templates/"
  - "wiki/index.md and wiki/log.md with Dataview-compatible frontmatter"
  - "AGENTS.md sections 1-8: directory structure, global rules, page types with worked examples, frontmatter schema, provenance syntax, progressive disclosure, wikilink conventions"
affects: [01-schema-structure-conventions, 02-workflows-operations-templates, 03-ingest-pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-authority schema in AGENTS.md"
    - "Frontmatter-driven taxonomy (tags, domains, type, status)"
    - "Body links, frontmatter IDs pattern"
    - "Inline provenance syntax: [prov:source_id#locator|support|checked_at]"
    - "Progressive disclosure: TL;DR -> Key Facts -> Detail -> Sources"
    - "First-mention wikilink convention"

key-files:
  created:
    - AGENTS.md
    - sources/.gitkeep
    - wiki/entities/.gitkeep
    - wiki/concepts/.gitkeep
    - wiki/sources/.gitkeep
    - wiki/comparisons/.gitkeep
    - wiki/overviews/.gitkeep
    - wiki/index.md
    - wiki/log.md
    - schema/templates/.gitkeep
  modified: []

key-decisions:
  - "Source registry uses frontmatter on wiki/sources/ pages (Dataview-native, no separate registry file)"
  - "snake_case for all frontmatter field names (Dataview compatibility)"
  - "16 base frontmatter fields including aliases for Obsidian resolution"
  - "Extended provenance syntax with optional support type and checked_at date"

patterns-established:
  - "Progressive disclosure section ordering per page type"
  - "Negative constraints (DO NOT list) in schema"
  - "Bad/good example pairs for provenance and wikilink conventions"
  - "Worked example per page type showing complete frontmatter + all sections"

requirements-completed: [DIRS-01, DIRS-02, DIRS-03, DIRS-04, SCHM-01, SCHM-03, SCHM-04, OBSD-01, OBSD-02, OBSD-03, OBSD-04, PROG-01, PROG-02, PROG-03]

# Metrics
duration: 6min
completed: 2026-04-09
---

# Phase 1 Plan 01: Directory Skeleton and AGENTS.md Sections 1-8 Summary

**Vault directory skeleton with 7 subdirectories, stub index/log files, and 710-line AGENTS.md covering directory structure, page types with 5 worked examples, frontmatter schema with validation checklist, provenance syntax, progressive disclosure, and wikilink conventions**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-09T10:10:03Z
- **Completed:** 2026-04-09T10:16:31Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Created complete directory skeleton with 7 subdirectories (sources/, wiki/entities/, wiki/concepts/, wiki/sources/, wiki/comparisons/, wiki/overviews/, schema/templates/) and Dataview-compatible index.md and log.md stubs
- Wrote AGENTS.md sections 1-8 (710 lines) as the sole authoritative wiki specification, covering directory structure, global rules (including 10 negative constraints), 5 page types each with a fully worked example, frontmatter schema with 16 base fields and validation checklist, inline provenance syntax with locator types and bad/good examples, progressive disclosure rules, and wikilink/graph conventions with bad/good examples

## Task Commits

Each task was committed atomically:

1. **Task 1: Create directory skeleton with stub files** - `7914bef` (feat)
2. **Task 2: Write AGENTS.md sections 1-8 with worked examples and negative constraints** - `0d5d2eb` (feat)

## Files Created/Modified

- `sources/.gitkeep` - Raw sources directory marker
- `wiki/entities/.gitkeep` - Entity pages directory
- `wiki/concepts/.gitkeep` - Concept pages directory
- `wiki/sources/.gitkeep` - Source summary pages directory
- `wiki/comparisons/.gitkeep` - Comparison pages directory
- `wiki/overviews/.gitkeep` - Overview pages directory
- `wiki/index.md` - Content index with Dataview-compatible frontmatter and type-based sections
- `wiki/log.md` - Activity log with Dataview-compatible frontmatter
- `schema/templates/.gitkeep` - Templates directory for page type templates
- `AGENTS.md` - Sole authoritative schema document, sections 1-8 (710 lines)

## Decisions Made

- Source registry implemented via frontmatter on wiki/sources/ pages (Dataview-native approach, avoids sync issues with separate registry file)
- All frontmatter field names use snake_case per Dataview compatibility research
- 16 base frontmatter fields defined including aliases for Obsidian automatic resolution
- Extended provenance syntax includes optional support type (direct/inferred/tentative/derived) and checked_at date for staleness detection
- Deep Learning overview example intentionally uses one display alias `[[Transformer Architecture|Transformers]]` to demonstrate real-world usage (noted as edge case in conventions)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - wiki/index.md and wiki/log.md are intentionally empty scaffolds (their purpose is to be populated as sources are ingested).

## Next Phase Readiness

- Directory skeleton ready for page creation
- AGENTS.md sections 1-8 provide complete specification for page types, frontmatter, provenance, progressive disclosure, and wikilinks
- Plan 01-02 will add sections 9-16 (structured operations, compiler pipeline, workflows, index/log, privacy routing, scaling boundaries, tooling, appendices)

---
*Phase: 01-schema-structure-conventions*
*Completed: 2026-04-09*

## Self-Check: PASSED

All 10 created files verified present. Both task commits (7914bef, 0d5d2eb) verified in git log.
