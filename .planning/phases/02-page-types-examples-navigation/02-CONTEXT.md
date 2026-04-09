# Phase 2: Page Types, Examples & Navigation - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver concrete, fillable page type templates for all five page types, define epistemic status conventions with inline syntax, create worked example pages demonstrating every convention, and build a functional index/log system — everything needed so that Phase 3 (ingestion) has a complete output format to target.

</domain>

<decisions>
## Implementation Decisions

### Template Format & Location
- **D-01:** Separate .md template files in `schema/templates/` — one per page type (entity.md, concept.md, source-summary.md, comparison.md, overview.md). Templates are fillable operational tools with placeholder sections and comments.
- **D-02:** AGENTS.md sections 4.1-4.5 remain as the authoritative specification with worked examples. Templates in schema/templates/ are the operational counterpart — agents copy a template, fill it in.
- **D-03:** Templates include all required frontmatter fields from D-10 (Phase 1) with placeholder values and type-specific additional fields.

### Example Page Domain & Topics
- **D-04:** Example pages use the personal knowledge domain — the user's stated first use case. This validates conventions against real intended use rather than abstract/generic examples.
- **D-05:** Example topics: an entity page (a thinker or author, e.g., "Daniel Kahneman"), a concept page (e.g., "Spaced Repetition"), a source summary (e.g., an article or book chapter), a comparison page (e.g., two learning methodologies), and populated index/log files reflecting these examples.
- **D-06:** Example pages must demonstrate cross-references between each other — the entity page links to concepts, the concept links to sources, etc. The graph view should show a connected cluster.

### Epistemic Status Inline Syntax
- **D-07:** Per-claim epistemic markers use Dataview inline field syntax: `[epistemic:: sourced]`, `[epistemic:: inferred]`, `[epistemic:: tentative]`, `[epistemic:: stale]`. This is consistent with the existing Obsidian/Dataview stack (OBSD-02/04) and visible in page content (EPST-02).
- **D-08:** Page-level epistemic status stays in frontmatter (`epistemic_status` field per D-10). Inline markers are for claim-level granularity where claims within one page have different confidence levels.
- **D-09:** Epistemic status conventions documented in AGENTS.md (update existing section 6) with examples showing inline usage in context.

### Index Organization
- **D-10:** index.md uses category sections matching page types (Entities, Concepts, Sources, Comparisons, Overviews) with embedded Dataview queries for dynamic content population.
- **D-11:** Each category section has a brief description and a Dataview TABLE query that auto-populates from pages in the corresponding wiki/ subdirectory.
- **D-12:** Manual "pinned" entries allowed above the Dataview query for important pages the user wants highlighted.

### Log Entry Format
- **D-13:** Log entries use parseable format: `YYYY-MM-DDTHH:MM:SSZ <operation>: <summary>` — one line per operation.
- **D-14:** Operation types match AGENTS.md workflow names: `ingest`, `query`, `lint`, `reflect`, `schema`, `update`, `merge`, `supersede`, `archive`.
- **D-15:** Log is append-only per LOG-01. Entries added at the top (most recent first) for quick scanning.

### Claude's Discretion
- Exact example page content (specific claims, facts, provenance markers) — as long as they demonstrate all conventions
- Template comment style and helper text within templates
- Dataview query specifics (which fields to display, sort order)
- Whether to update AGENTS.md section 6 inline or add a subsection

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema Specification
- `AGENTS.md` — Complete agent schema. Sections 4.1-4.5 have worked examples for all 5 page types. Section 5 has frontmatter schema. Section 6 has provenance/epistemics/staleness. Section 7 has progressive disclosure. Section 12 has index and log conventions.

### Project Vision
- `idea.md` — Full project concept including three-layer architecture, operations, progressive disclosure rationale

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 2 requirements: PAGE-01 through PAGE-07, EPST-01 through EPST-03, EXMP-01 through EXMP-05, INDX-01 through INDX-03, LOG-01 through LOG-03

### Phase 1 Context
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — All Phase 1 decisions (D-01 through D-35) that this phase builds on

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AGENTS.md` sections 4.1-4.5 — worked examples for all 5 page types that templates and example pages should be consistent with
- `wiki/index.md` — stub with frontmatter, needs content population
- `wiki/log.md` — stub with frontmatter, needs content population

### Established Patterns
- Progressive disclosure: TL;DR → Key Facts → Detail → Related → Sources (D-19 through D-24)
- Frontmatter schema: 14 base fields defined (D-10)
- Provenance syntax: `[prov:source_id#locator]` (D-13)
- Dataview-compatible YAML frontmatter throughout

### Integration Points
- Templates in `schema/templates/` referenced by AGENTS.md section 4
- Example pages in `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`, `wiki/comparisons/`, `wiki/overviews/`
- Index and log in `wiki/index.md` and `wiki/log.md`
- AGENTS.md section 6 needs epistemic inline syntax documentation update

</code_context>

<specifics>
## Specific Ideas

- Example pages should form a mini-cluster that demonstrates the graph view value — all examples cross-reference each other
- The personal knowledge domain is the first use case — examples should feel like real personal wiki content, not textbook exercises
- Epistemic inline markers use Dataview syntax for query-ability — e.g., a Dataview query can find all `[epistemic:: tentative]` claims across the wiki

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-page-types-examples-navigation*
*Context gathered: 2026-04-09*
