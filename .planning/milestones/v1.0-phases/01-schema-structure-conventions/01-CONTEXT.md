# Phase 1: Schema, Structure & Conventions - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the foundational specification layer for the LLM Wiki Compiler: an agent-agnostic schema document (AGENTS.md), directory layout, Obsidian-compatible conventions, progressive disclosure rules, provenance syntax, wikilink conventions, commit conventions, and scaling boundary heuristics. Everything downstream agents and LLMs need to create, update, and organize wiki pages correctly.

</domain>

<decisions>
## Implementation Decisions

### Schema Document Shape
- **D-01:** Single monolithic AGENTS.md file at repo root containing all rules, conventions, and workflows. Optional supporting files for templates/examples in schema/ directory.
- **D-02:** Named AGENTS.md (not CLAUDE.md) — agent-agnostic so any LLM can discover and follow it.
- **D-03:** Prescriptive step-by-step workflows in the schema itself. The schema is the sole authoritative source — no dependency on external skills or tool-specific wrappers.
- **D-04:** All four workflows (ingest, query, lint, reflect) defined in Phase 1 even though they aren't built until later phases. The schema is the spec — complete upfront.

### Directory Layout
- **D-05:** Three siblings at root: `sources/`, `wiki/`, and `AGENTS.md`. Optional `schema/` for templates/examples.
- **D-06:** Wiki organized by page type subdirectories: `wiki/entities/`, `wiki/concepts/`, `wiki/sources/`, `wiki/comparisons/`, `wiki/overviews/`. Categories/topics represented via frontmatter fields (tags, domains), wikilinks, and Dataview views — not filesystem hierarchy.
- **D-07:** `index.md` and `log.md` live inside `wiki/` (they are LLM-maintained wiki-layer artifacts).
- **D-08:** Sources organized chronologically with directory nesting: `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/`. Per-source bundle folder when assets exist (source.md + attachments together). Single file for text-only sources. Optional global `sources/assets/` only for genuinely shared or tool-managed assets.
- **D-09:** Source metadata (type, topic, privacy) stored as metadata in the source file, not as primary directory structure.

### Frontmatter & Provenance Syntax
- **D-10:** Required base frontmatter fields for every wiki page: `id`, `title`, `type`, `status`, `summary`, `created_at`, `updated_at`, `sources`, `epistemic_status`, `tags`, `domains`, `supersedes`, `superseded_by`, `privacy`. These cover identity, lifecycle, summary, source linkage, and retrieval.
- **D-11:** No `confidence` field — `epistemic_status` (sourced, mixed, tentative, stale) is sufficient at page level.
- **D-12:** Detailed provenance blobs, relation fields, decay settings, decision metadata, comparison dimensions, and source URLs belong in type-specific schemas, not the base.
- **D-13:** Inline provenance syntax: `[prov:<source_id>#<locator>]`. Extended form: `[prov:<source_id>#<locator>|<support_type>|<checked_at>]`.
- **D-14:** Locator types: `#p12-14` (page range), `#sec:introduction` (section), `#para3` (paragraph), `#t00:12:10-00:12:48` (timestamp for transcripts), `#img2` (image reference).
- **D-15:** Support types: `direct`, `inferred`, `tentative`, `derived` (optional, for synthesis distinct from weaker inference).
- **D-16:** `checked_at` / `verified_at` field (not generic date) — records when the provenance link was last verified.
- **D-17:** Source registry (frontmatter or sidecar file) mapping source IDs to: `source_id`, `path`, `title`, `source_type`, `url` (if applicable), `content_hash`, `ingested_at`.
- **D-18:** Validation rules: every `prov:` reference must resolve to a known source; every locator must be syntactically valid; optional stronger check — if source `content_hash` has changed, mark linked claims stale.

### Progressive Disclosure Format
- **D-19:** Standard shallow-to-deep section order for all pages. Top optimized for fast scanning, bottom for verification.
- **D-20:** Entity/concept pages: `## TL;DR` (1 short paragraph or 2-4 bullets) → `## Key Facts` (compact bullets with inline provenance) → `## Detail` (full narrative, synthesis, caveats) → `## Related Pages` (wikilinks) → `## Sources` (human-readable source list).
- **D-21:** Source summary pages: TL;DR → Key Takeaways → Extracted Claims → Notes → Source Metadata.
- **D-22:** Comparison pages: TL;DR → Bottom Line → Comparison Table → Detailed Comparison → Sources.
- **D-23:** Decision pages: TL;DR → Decision → Why → Alternatives Considered → Consequences → Sources.
- **D-24:** TL;DR must be short enough that an LLM can scan many pages quickly. Key Facts must be skimmable and citation-friendly. Nuance and long prose go in Detail. Sources at the bottom.

### Commit Conventions
- **D-25:** Conventional commit format with wiki operation types: `ingest(source-slug):`, `query(topic):`, `lint(scope):`, `reflect(scope):`, `schema:`.
- **D-26:** One commit per logical operation (not per file, not per pipeline pass). A single ingest touching 10-15 files is one commit. Rule: if the change answers "what happened?" with one sentence, it's one commit.

### Scaling Boundary Heuristics
- **D-27:** Named tiers with approximate heuristics, explicitly labeled as heuristics not hard boundaries. Indicative scaling triggers and recommended upgrades using signal-based language ("when the index becomes slow to navigate", "when full lint becomes too expensive to run routinely") alongside approximate numbers as starting points.
- **D-28:** Approximate starting heuristics: split index around a few hundred pages; incremental lint when full lint discourages use; DB-backed metadata when provenance/search/concurrency become awkward in markdown.

### Privacy Routing
- **D-29:** Layered privacy model with fail-closed semantics. Three-level precedence: (1) explicit frontmatter on the item, (2) enclosing directory default, (3) system default = `local_only`.
- **D-30:** Directory-level defaults for operational convenience (e.g., `sources/local-only/`, `sources/cloud-safe/`). Frontmatter is the authoritative item-level declaration when present. If directory and frontmatter conflict, prefer the stricter setting.
- **D-31:** Routing logic must never send `local_only` content to cloud models. Unresolved items default to `local_only`.

### Wikilink & Graph Conventions
- **D-32:** Link on first mention per page. Subsequent mentions are plain text. Standard wiki convention.
- **D-33:** Red links allowed — link to pages that don't exist yet. Obsidian shows these as unresolved; lint workflow uses them to detect knowledge gaps (GAP-01).
- **D-34:** Exact title match for wikilinks — `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`. Use `aliases` frontmatter field for alternate names that Obsidian resolves automatically.

### Schema Document Outline
- **D-35:** AGENTS.md follows a 16-section outline: (1) Overview & Principles, (2) Directory Structure, (3) Global Rules, (4) Page Types & Templates, (5) Frontmatter Schema, (6) Provenance, Epistemics, and Staleness, (7) Progressive Disclosure, (8) Wikilink & Graph Conventions, (9) Structured Operations and Executor Model, (10) Compiler Pipeline, (11) Workflows (11.1 Ingest, 11.2 Query, 11.3 Lint, 11.4 Reflect), (12) Index and Log, (13) Privacy Routing, (14) Scaling Boundaries, (15) Tooling / Integrations, (16) Appendices / Examples.

### Claude's Discretion
- Template file format and exact content within schema/ directory
- Exact wording of scaling tier descriptions
- Internal structure of workflow subsections (as long as they are prescriptive step-by-step)
- Source registry implementation detail (frontmatter vs sidecar file — pick based on what works best with Dataview)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Vision
- `idea.md` — Full project concept: architecture (three layers), operations (ingest/query/lint/reflect), indexing/logging conventions, progressive disclosure rationale, privacy routing, scaling considerations

### Requirements
- `.planning/REQUIREMENTS.md` — All 19 Phase 1 requirements (SCHM-01 through SCHM-05, DIRS-01 through DIRS-04, OBSD-01 through OBSD-04, PROG-01 through PROG-03, BNDY-01 through BNDY-03)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project with no existing code.

### Established Patterns
- None — this phase establishes the patterns.

### Integration Points
- The schema (AGENTS.md) is the primary integration point for all downstream phases. Every subsequent phase reads it to know how to operate.
- Obsidian is the human interface — all conventions must produce valid Obsidian rendering (wikilinks, Dataview frontmatter, graph view).

</code_context>

<specifics>
## Specific Ideas

- Source bundles use chronological directory nesting: `YYYY/YYYY-MM/YYYY-MM-DD-slug/` with `source.md` as the main file and assets co-located
- Provenance syntax designed for script validation: every `prov:` reference must resolve, content_hash changes trigger stale marking
- Privacy routing is fail-closed by design — if classification is ambiguous, treat as `local_only`
- The user explicitly rejected skills/slash-commands as the primary workflow mechanism because it would break agent-agnosticism

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-schema-structure-conventions*
*Context gathered: 2026-04-09*
