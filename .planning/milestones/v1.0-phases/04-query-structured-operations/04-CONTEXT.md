# Phase 4: Query & Structured Operations - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a working query workflow (question answering with cited answers compiled back into durable wiki pages, including delta compilation of uncompiled sources) and a deterministic structured operations layer (UPDATE/MERGE/SUPERSEDE/ARCHIVE with bash-enforced validation). Also deliver a CLI search helper. The query workflow described in AGENTS.md §11.2 becomes operational, the executor model in §9 gets deterministic enforcement, and the wiki gains its interaction layer.

</domain>

<decisions>
## Implementation Decisions

### Query Write-Back Scope
- **D-01:** Write-back decision uses page ownership, not origin. If an existing page clearly owns the topic, UPDATE it. If no single page cleanly owns the synthesis, or the output is a distinct reusable artifact (comparison, overview, reflection), create a new page.
- **D-02:** Do not create query-specific page types. Pages are typed by semantic role (entity, concept, comparison, overview, source summary), never by workflow origin.
- **D-03:** Mandatory write-back triggers on **novel or durable synthesis** — not every query. Write back when the answer produces at least one of:
  - A new claim not already captured in the wiki
  - A new connection between existing pages/sources
  - A meaningful reframing or synthesis of existing material
  - A reusable artifact (comparison, overview, decision note)
  - A correction to an existing page's framing or status
- **D-04:** Do NOT write back for: pure lookups of facts already present, reformatted restatements of one existing page, transient conversational answers with no durable value.
- **D-05:** Log the write-back decision in the query log entry — structured and terse, stating which trigger was met or why write-back was skipped. Enables auditing.

### Delta Compilation
- **D-06:** Primary detection mechanism: explicit compilation status fields on source summary pages in frontmatter:
  - `compilation_status`: `pending | partial | compiled | stale`
  - `compiled_against_hash`: SHA-256 hash of source content at time of last compilation
  - `compiled_targets`: list of wiki page IDs that received compiled claims from this source
- **D-07:** Secondary verification: provenance gap validation — check whether source claims actually appear in target topic pages via provenance markers.
- **D-08:** New sources land with `compilation_status: pending`. The ingest merge pass sets status to `compiled` (or `partial` if only some claims were merged). When `content_hash` changes on re-ingest, status resets to `stale`.
- **D-09:** Query-time delta compilation is **query-scoped by default**: compile only claims from uncompiled sources relevant to the current question. Log remaining uncompiled material for later pickup.
- **D-10:** Full-source compilation is the exception — only when the source is central to many pages, query-scoped extraction would be wasteful, or the user explicitly requests a fuller refresh.
- **D-11:** Ingest workflow (AGENTS.md §11.1) must be updated to set compilation status fields after merge pass. This is a retroactive addition to the ingest spec.

### CLI Search Helper
- **D-12:** Dual-mode `bin/search.sh` — bash script, agent-agnostic, zero API dependencies. Same philosophy as `bin/ingest.sh`.
- **D-13:** Default mode: index lookup (parse `wiki/index.md` for keyword matches) + optional full-text grep across `wiki/`. Prints matching page paths with TL;DR snippets.
- **D-14:** Query mode (`--query "question"`): prompt scaffolder that finds relevant pages and emits a ready-to-paste LLM prompt with page paths and progressive-disclosure instructions.
- **D-15:** Default output format: path + TL;DR (first line of TL;DR section). Optional flags: `--paths-only`, `--frontmatter`, `--json` (deferred to later if needed).

### Operations Executor
- **D-16:** Two-layer enforcement: AGENTS.md §9 rules as the LLM-facing spec (policy), `bin/validate-op.sh` bash script as deterministic enforcement.
- **D-17:** Validator script performs 5 mechanical checks:
  1. Target page exists (for UPDATE, SUPERSEDE, ARCHIVE)
  2. YAML frontmatter parses correctly
  3. Provenance references resolve to known source IDs in `wiki/sources/`
  4. Privacy flags are respected (no `local_only` content in cloud-bound operations)
  5. MERGE-specific: both source pages exist and are distinct
- **D-18:** Batch validation before apply: LLM proposes full operation set for a workflow, validates all operations, aborts the entire batch on any hard failure. Optional per-op re-validation for destructive operations (MERGE, SUPERSEDE, ARCHIVE).
- **D-19:** Direct CLI invocation: `bin/validate-op.sh UPDATE wiki/entities/kahneman.md` — takes operation type + target path(s), prints PASS or FAIL with reasons.

### Structured Operations Logging
- **D-20:** Structured prefix + terse rationale format for all operation log entries. Parseable for scripts and audit tooling, readable in markdown.
- **D-21:** Log entry format:
  ```
  ## [YYYY-MM-DD] OPERATION | target_page
  source: source_id
  result: what changed (e.g., "added 3 claims, refreshed TL;DR")
  reason: one-line rationale
  ```

### Claude's Discretion
- Exact implementation details of `bin/search.sh` (argument parsing, grep invocation, TL;DR extraction method)
- Exact implementation details of `bin/validate-op.sh` (YAML parsing approach, provenance resolution logic)
- How to structure the AGENTS.md §11.2 update to incorporate write-back decision rules
- Whether to update AGENTS.md sections incrementally per plan or batch at the end
- Exact wording of compilation status field documentation in AGENTS.md §5

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema Specification
- `AGENTS.md` §9 — Structured Operations and Executor Model (UPDATE, MERGE, SUPERSEDE, ARCHIVE definitions and validation rules). Phase 4 adds deterministic enforcement via bash validator.
- `AGENTS.md` §10 — Compiler Pipeline conceptual model. Phase 4 extends with delta compilation status tracking.
- `AGENTS.md` §11.2 — Query Workflow (9-step procedure). Phase 4 makes this operational and adds write-back decision rules.
- `AGENTS.md` §5 — Frontmatter Schema. New compilation status fields must be added for source summary pages.
- `AGENTS.md` §6 — Provenance, Epistemics, and Staleness. Provenance resolution is a validator check.
- `AGENTS.md` §12 — Log format. Operations logging format updated per D-20/D-21.

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 4 requirements: QURY-01 through QURY-05, SOPS-01 through SOPS-06, CLI-01

### Prior Phase Context
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — Provenance syntax, source registry, privacy routing, commit conventions
- `.planning/phases/02-page-types-examples-navigation/02-CONTEXT.md` — Epistemic inline syntax, index strategy, template design
- `.planning/phases/03-ingestion-provenance-pipeline/03-CONTEXT.md` — Claim granularity rules, append-then-synthesize policy, CLI ingest helper pattern, pipeline validation approach

### Existing Assets
- `bin/ingest.sh` — CLI ingest helper (reference for search helper design pattern)
- `wiki/index.md` — Current index (search helper parses this)
- `wiki/log.md` — Current log (operations logging appends here)
- `wiki/sources/` — Source summary pages (compilation status fields added here)
- `schema/templates/` — All 5 page type templates (query write-back creates pages using these)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/ingest.sh` — Established CLI helper pattern: bash, agent-agnostic, zero API dependencies, file bookkeeping only. Search helper and validator script follow same pattern.
- `schema/templates/` — All 5 page type templates. Query write-back uses these when creating new pages (type by semantic role, not origin).
- `wiki/sources/` — Source summary pages with existing `content_hash` field. New compilation status fields extend this frontmatter.
- `wiki/index.md` — Manually curated index. Search helper parses this for keyword lookup.

### Established Patterns
- Progressive disclosure: TL;DR -> Key Facts -> Detail -> Sources (search helper extracts TL;DR for output)
- Provenance syntax: `[prov:source_id#locator]` (validator checks provenance resolution)
- Append-then-synthesize: update policy for living wiki pages (query write-back follows same policy)
- Log format: `## [YYYY-MM-DD] workflow | scope` with structured entries (operations logging extends this)
- Commit convention: `query(<topic>): <one-line summary>` already defined in AGENTS.md §11.2

### Integration Points
- AGENTS.md §11.2 needs updates to encode write-back decision rules (D-01 through D-05) and delta compilation mechanics (D-06 through D-11)
- AGENTS.md §11.1 (ingest workflow) needs retroactive update to set compilation status fields after merge pass (D-11)
- AGENTS.md §5 (frontmatter schema) needs new fields: `compilation_status`, `compiled_against_hash`, `compiled_targets`
- AGENTS.md §9 (executor model) needs reference to `bin/validate-op.sh` as enforcement layer
- AGENTS.md §12 (log format) needs updated operation logging format per D-20/D-21

</code_context>

<specifics>
## Specific Ideas

- Write-back decision principle: "type by semantic role, not by origin" — no query-result page type, ever
- Page ownership heuristic: "existing page owner -> update; no clear owner or synthesis is a distinct artifact -> new page"
- Write-back threshold: "novel or durable synthesis" — broader than just "novel claims," captures comparisons, reframings, and decision notes
- Compilation status is a workflow boundary marker, not just a boolean: `pending | partial | compiled | stale` captures the full lifecycle
- Validator is enforcement, AGENTS.md rules are policy — two layers that serve different purposes
- Batch validation matches the pipeline's batch-shaped workflow: propose all, validate all, apply all or abort all
- Search helper is useful as a standalone primitive for lint, debugging, and manual inspection — not just a query preprocessor

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-query-structured-operations*
*Context gathered: 2026-04-12*
