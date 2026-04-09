# Phase 2: Page Types, Examples & Navigation - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver concrete, fillable page type templates for all five page types, define epistemic status conventions with inline syntax, create worked example pages demonstrating every convention, and build a functional index/log system — everything needed so that Phase 3 (ingestion) has a complete output format to target.

</domain>

<decisions>
## Implementation Decisions

### Example Page Topics
- **D-01:** Example pages use the famous thinkers/ideas domain — public, verifiable knowledge. Topics: Daniel Kahneman (entity), Cognitive Biases (concept), a chapter from Thinking Fast and Slow (source summary), System 1 vs System 2 (comparison), Decision Making (overview).
- **D-02:** Examples must cross-reference each other to demonstrate graph view value — entity links to concepts, concepts link to sources, etc. The graph should show a connected cluster.
- **D-03:** Example pages serve double duty: satisfy EXMP-01–05 requirements AND act as companion exemplars for the template files (see D-10).

### Epistemic Inline Syntax
- **D-04:** Per-claim epistemic markers use Dataview inline field syntax: `[epistemic:: sourced]`, `[epistemic:: inferred]`, `[epistemic:: tentative]`, `[epistemic:: stale]`. Queryable via Dataview — enables "find all tentative claims" queries that feed into lint (Phase 5).
- **D-05:** Provenance stays in custom `[prov:...]` syntax (Phase 1 D-13–D-18). NOT Dataview syntax. Provenance is for traceability (grep/script-parseable), epistemic is for discovery (Dataview-queryable). Different purposes, different tools.
- **D-06:** The mixed inline grammar (`[prov:...]` + `[epistemic:: ...]`) must be documented explicitly in AGENTS.md section 6 as an intentional design choice, so future agents don't "normalize" to one syntax.
- **D-07:** Page-level epistemic status stays in frontmatter (`epistemic_status` field per Phase 1 D-10). Inline markers are for claim-level granularity where claims within one page have different confidence levels.
- **D-08:** Inline pattern: `Claim text. [prov:source_id#locator|support_type] [epistemic:: status]`

### Index Strategy
- **D-09:** index.md uses a manual curated list maintained by the agent during ingest operations. Not Dataview queries — curated lists are higher signal, more navigable, portable, and better for LLM comprehension during query workflow (QURY-02).
- **D-10:** Lint rule (Phase 5) to detect index drift — compare pages existing in wiki/ subdirectories against wikilinks in index.md. Safety net for workflow discipline.
- **D-11:** Each index entry: wikilink + one-line summary. Organized by category sections matching page types (Entities, Concepts, Sources, Comparisons, Overviews).

### Template Design
- **D-12:** Two-layer pattern: primary templates (skeleton + comments) in `schema/templates/`, companion exemplars are the example pages in `wiki/`.
- **D-13:** Templates are operational — copy, fill, done. Skeleton with section headings, placeholder frontmatter, and brief comments explaining constraints (e.g., "TL;DR must be short enough for fast scanning"). No example content that could leak into real pages.
- **D-14:** Example pages are reference material — demonstrate what "good" looks like with real density, provenance chains, and epistemic markers in context. Agents can consult them for style/density guidance.
- **D-15:** One template per page type: `schema/templates/entity.md`, `concept.md`, `source-summary.md`, `comparison.md`, `overview.md`.

### Log Entry Format
- **D-16:** Claude's discretion — parseable format with ISO timestamps and operation types matching AGENTS.md workflow names. Append-only, most recent first.

### Claude's Discretion
- Exact example page content (specific claims, facts, provenance markers) — as long as they demonstrate all conventions and cross-reference each other
- Template comment wording and helper text
- Log entry exact format details
- Whether to update AGENTS.md section 6 inline or add a subsection for the mixed grammar documentation

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
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — All Phase 1 decisions (D-01 through D-35) that this phase builds on. Especially: frontmatter schema (D-10), provenance syntax (D-13–D-18), progressive disclosure format (D-19–D-24).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AGENTS.md` sections 4.1-4.5 — worked examples for all 5 page types that templates and example pages must be consistent with
- `wiki/index.md` — stub with frontmatter and empty category sections, needs content population
- `wiki/log.md` — stub with frontmatter, needs content population

### Established Patterns
- Progressive disclosure: TL;DR → Key Facts → Detail → Related → Sources (Phase 1 D-19 through D-24)
- Frontmatter schema: 14 base fields defined (Phase 1 D-10)
- Provenance syntax: `[prov:source_id#locator]` (Phase 1 D-13)
- Dataview-compatible YAML frontmatter throughout

### Integration Points
- Templates in `schema/templates/` referenced by AGENTS.md section 4
- Example pages in `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`, `wiki/comparisons/`, `wiki/overviews/`
- Index and log in `wiki/index.md` and `wiki/log.md`
- AGENTS.md section 6 needs update to document mixed inline grammar (D-06)

</code_context>

<specifics>
## Specific Ideas

- Example pages form a connected cluster: Kahneman → Cognitive Biases → Thinking Fast and Slow → System 1 vs 2 → Decision Making — validates graph view conventions
- Mixed inline grammar is intentional: `[prov:...]` for portable traceability, `[epistemic:: ...]` for Dataview queryability — document explicitly to prevent normalization by future agents
- Index drift lint rule: compare wiki/ file list against index.md wikilinks — simple, reliable safety net for manual curation

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-page-types-examples-navigation*
*Context gathered: 2026-04-09*
