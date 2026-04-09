# Phase 3: Ingestion & Provenance Pipeline - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a working end-to-end ingestion pipeline: source classification, multi-pass compilation (classify → diff → extract → merge → lint), claim-level provenance tracking, a CLI ingest helper, and validation through real source ingestion. The pipeline described in AGENTS.md §10–11.1 becomes operational — real sources go in, properly provenanced wiki pages come out, existing pages update incrementally.

</domain>

<decisions>
## Implementation Decisions

### Claim Extraction Granularity
- **D-01:** Adaptive granularity by source type. Source classification (AGENTS.md §10 Pass 0) drives extraction depth.
- **D-02:** Per-type defaults:
  - Papers, articles, reports, technical docs: mostly atomic claims (one provenance marker per distinct assertion)
  - Book chapters, essays: atomic for important factual/conceptual claims, paragraph-level for broader interpretive passages
  - Transcripts, meeting notes, journal entries: paragraph-level or utterance-level clusters
  - Image-heavy or mixed media: claim granularity tied to specific image, caption, or observation
- **D-03:** Bias toward atomic for durable factual/conceptual claims across all types. Heuristic: "the smallest unit that preserves meaningful provenance without making the page unreadable."
- **D-04:** Split when a paragraph contains multiple independently important assertions. Keep grouped when a passage is only useful as one bundled observation.
- **D-05:** Encode these rules directly in AGENTS.md §10 Pass 2 (Extract), at the point where type-appropriate extraction is described.

### Incremental Update Strategy
- **D-06:** Append-then-synthesize as the default update policy for living wiki pages (entities, concepts, overviews, comparisons).
- **D-07:** Operational rule:
  1. Add new claims into appropriate detail sections, preserving existing material unless explicitly superseded
  2. Mark old claims as superseded or stale when warranted — never silently delete
  3. Re-synthesize TL;DR and Key Facts so the summary layer reflects the new overall state
  4. If new material changes a page's framing, record that in a decision/reflection entry rather than hiding the shift inside prose
- **D-08:** Full section rewrite reserved for exceptional cases: severe page drift, duplication, or fundamentally broken earlier structure.
- **D-09:** Strict append-only reserved for logs and source summary pages only — these are records, not living synthesis.
- **D-10:** Encode in AGENTS.md §10 Pass 3 (Merge) and reference from §9 (Structured Operations).

### CLI Ingest Helper
- **D-11:** Bash scaffold script (not Node.js, not a full LLM orchestrator). Agent-agnostic, zero API dependencies.
- **D-12:** Script responsibilities: (1) accept source file path + optional slug, (2) create dated directory structure (sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/), (3) copy/move file in, (4) compute content_hash, (5) print ready-to-ingest instructions with the command/prompt to give the LLM agent.
- **D-13:** The LLM agent runs the actual pipeline. The CLI handles file bookkeeping only.

### Pipeline Validation
- **D-14:** Phase 3 includes two real source ingestions to validate the pipeline end-to-end.
- **D-15:** First ingest: an article in the Kahneman/decision-making domain. Tests atomic claim extraction AND incremental updates to existing Phase 2 example pages.
- **D-16:** Second ingest: a journal entry. Tests coarser paragraph-level extraction and a different source type path through the pipeline.
- **D-17:** Both ingests must produce: source summary page with provenance, updated/new wiki pages, updated index, updated log, valid git commit.

### Claude's Discretion
- Exact content of validation test sources (as long as they exercise the pipeline as specified)
- CLI script internal implementation details (argument parsing, hash algorithm, output formatting)
- Exact wording of AGENTS.md updates (as long as decisions D-01 through D-10 are faithfully encoded)
- Whether to update AGENTS.md sections incrementally per plan or batch at the end

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema Specification
- `AGENTS.md` §10 — Compiler Pipeline conceptual model (passes 0-4 + optional follow-ons). This is what Phase 3 makes operational.
- `AGENTS.md` §11.1 — Ingest Workflow (10-step procedure + abort conditions). The step-by-step recipe to implement.
- `AGENTS.md` §9 — Structured Operations and Executor Model (UPDATE, MERGE, SUPERSEDE, ARCHIVE). Used during Pass 3 (Merge).
- `AGENTS.md` §5 — Frontmatter Schema. All pages created/updated must conform.
- `AGENTS.md` §6 — Provenance, Epistemics, and Staleness. Claim-level provenance syntax and epistemic inline markers.

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 3 requirements: INGST-01 through INGST-06, CMPL-01 through CMPL-07, PROV-01 through PROV-05, CLI-02

### Prior Phase Context
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — Provenance syntax (D-13–D-18), source registry (D-17), privacy routing (D-29–D-31), commit conventions (D-25–D-26)
- `.planning/phases/02-page-types-examples-navigation/02-CONTEXT.md` — Epistemic inline syntax (D-04–D-08), index strategy (D-09–D-11), template design (D-12–D-15)

### Existing Assets
- `schema/templates/` — All 5 page type templates (entity, concept, source-summary, comparison, overview)
- `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` — Existing example source summary page (reference for format)
- `wiki/index.md` — Current index (will be updated by ingests)
- `wiki/log.md` — Current log (will be appended to by ingests)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `schema/templates/source-summary.md` — Template for source summary pages created during Extract pass
- `schema/templates/entity.md`, `concept.md`, `overview.md`, `comparison.md` — Templates for pages created/updated during Merge pass
- `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` — Working example of a source summary page with frontmatter and provenance
- Phase 2 example pages (Kahneman domain) — existing wiki pages that the validation article ingest should update incrementally

### Established Patterns
- Progressive disclosure: TL;DR → Key Facts → Detail → Related → Sources (Phase 1 D-19–D-24)
- Provenance syntax: `[prov:source_id#locator]` with extended form (Phase 1 D-13–D-16)
- Epistemic inline markers: `[epistemic:: status]` (Phase 2 D-04–D-08)
- Frontmatter: 14+ base fields, type-specific additions for source pages (Phase 1 D-10–D-12)
- Commit convention: `ingest(<source-slug>): <one-line summary>` (Phase 1 D-25)
- Index: manually curated list, not Dataview queries (Phase 2 D-09)
- Log: append-only, parseable format with ISO timestamps (Phase 2 D-16)

### Integration Points
- AGENTS.md §10 and §11.1 need updates to encode claim granularity rules (D-01–D-05) and incremental update policy (D-06–D-10)
- CLI script placed alongside or within the repo (location TBD by planner)
- Validation ingests will modify existing Phase 2 example pages — planner should account for merge conflicts with in-progress work

</code_context>

<specifics>
## Specific Ideas

- Claim granularity heuristic: "the smallest unit that preserves meaningful provenance without making the page unreadable" — encode verbatim in AGENTS.md §10 Pass 2
- Incremental update mantra: "append in the detail layer, synthesize in the summary layer, supersede explicitly when needed"
- The validation article should touch the Kahneman/decision-making domain so it tests incremental updates against existing Phase 2 example pages — not just greenfield ingestion
- CLI script computes content_hash upfront so duplicate detection works from the very first ingest

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-ingestion-provenance-pipeline*
*Context gathered: 2026-04-10*
