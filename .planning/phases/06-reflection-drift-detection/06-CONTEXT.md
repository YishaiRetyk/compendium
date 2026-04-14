# Phase 6: Reflection & Drift Detection - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver structural self-awareness for the wiki through two capabilities: (1) decision records that capture why structural changes were made, with a dedicated page type, bidirectional navigation, and a three-tier reflect workflow; (2) cross-system drift detection between wiki, raw sources, and the Obsidian vault, integrated into the existing lint pipeline. The reflect workflow described in AGENTS.md §11.4 is significantly expanded, drift detection extends §11.3 (lint), and a new `decision` page type is added to the schema.

</domain>

<decisions>
## Implementation Decisions

### Decision Record Page Type
- **D-01:** Decision records are a new dedicated page type (`type: decision`) with their own template (`schema/templates/decision.md`), directory (`wiki/decisions/`), and index category. Not overloaded onto overview pages.
- **D-02:** Six trigger types, unified by the principle *"create a decision record when future-you would reasonably ask 'why is the wiki shaped this way?'"*:
  1. Page merges/splits
  2. Schema updates
  3. Domain reorganization
  4. Significant reframing
  5. Major supersession (SUPERSEDE of a key page/concept)
  6. Contradiction-resolution decisions (structural resolution, not the contradiction itself)
- **D-03:** Structured content. Frontmatter captures trigger type, affected pages, and date. Body uses §11.4 sections: TL;DR → Decision → Why → Alternatives Considered → Consequences → Sources, plus an "Affected Pages" section with wikilinks. Parseable for auditing.
- **D-04:** `decision_history` frontmatter field on affected pages — list of decision record IDs. Always present when decisions exist, machine-readable.
- **D-05:** Visible "Decision History" section in affected page body is optional — include when the history is meaningful, omit for minor structural decisions. Clean pages by default, auditability always available via frontmatter.

### Reflect Workflow Model
- **D-06:** Three-tier reflect model:
  1. **Inline creation** — MERGE, SUPERSEDE, splits, domain reorg, schema updates, and recognized reframings produce decision records as part of the operation commit. No separate reflect pass needed for these.
  2. **Workflow recommendations** — Ingest, query, and lint emit "reflect recommended: [reason]" when they detect ambiguous signals: material framing shifts, contradiction resolution choices, novel synthesis frames, accumulated structural drift.
  3. **Manual/periodic reflect** — Safety net pass that scans log.md, recent commits, and prior reflect coverage to backfill missed records and consolidate low-grade structural evolution.
- **D-07:** Reflect discovery uses both `log.md` and `git log`. Log captures workflow intent and operations in the system's own language; git captures actual file changes and protects against incomplete logging. Neither alone is sufficient.
- **D-08:** Explicit reflect checkpoint in a state file (e.g., `wiki/maintenance/reflect-state.md`). Fields: `last_reflect_log_entry`, `last_reflect_commit`, `last_reflect_at`. This is control-plane state, not a decision record output.
- **D-09:** Periodic reflect pass procedure: (1) read checkpoint, (2) scan log.md entries since last entry, (3) inspect git changes since last commit, (4) create decision records as needed, (5) advance checkpoint. A reflect run that produces no decision records still advances the checkpoint.

### Drift Detection Scope
- **D-10:** v1 drift detection scope = wiki ↔ sources + Obsidian vault awareness. All checks are local, deterministic, file-based. No external API calls.
- **D-11:** Specific drift checks:
  - Sources in `sources/` with no corresponding wiki representation (DRFT-01)
  - Wiki pages referencing missing or moved sources (DRFT-02)
  - Broken wikilinks indicating filesystem/index mismatch
  - Malformed or missing frontmatter that breaks Dataview
  - Files in `wiki/` not tracked in `wiki/index.md`
  - Unresolved attachment/file references
- **D-12:** DRFT-03 scoped narrowly to filesystem-visible toolchain drift. Zotero/cloud reconciliation deferred to future integration layer.
- **D-13:** Explicit content-hash drift detection. Compare current source file hash against stored `content_hash` in source summary page frontmatter. This is a deterministic signal — the source literally changed — not a time-based heuristic.
- **D-14:** Hash mismatch → surface as drift finding in lint report, then update `compilation_status` to `stale` on affected source summary pages. Downstream claims compiled from that source become recompilation candidates.
- **D-15:** Content-hash drift is the *mechanism*; `compilation_status: stale` is the *resulting state*. Drift detection feeds into the compilation status system, not the other way around.

### Lint Integration
- **D-16:** v1: drift checks run as part of standard `bin/lint.sh`. One health-check entry point. No separate flags or subcommands.
- **D-17:** Drift findings appear in `wiki/maintenance/lint-report.md` under a distinct "Drift" category section, alongside structural, staleness, contradiction, and gap sections.
- **D-18:** Future scalability: if vault size makes full lint slow, add modes like `--quick`, `--full`, `--skip-hash`. Not built in v1 — just don't paint into a corner architecturally.
- **D-19:** Drift is a distinct lint category, not a replacement or superset of structural checks. Categorize findings by *why it matters*, not raw symptom. Same underlying check (e.g., broken wikilink) gets classified as structural or drift depending on context.
- **D-20:** Underlying check logic can be reused across categories. The categorization layer interprets the finding.
- **D-21:** Drift findings use tiered severity:
  - **error** — broken traceability: wiki references missing source, provenance points to nonexistent file
  - **warning** — stale compilation: content-hash drift, uncompiled sources, index/vault divergence
  - **info** — cosmetic: Dataview-friendly improvements, noncritical vault mismatches

### Claude's Discretion
- Decision record file naming convention (e.g., `dr-YYYY-MM-DD-slug.md` vs `slug.md`)
- Decision record template exact wording and helper comments
- Exact format for "reflect recommended" messages emitted by workflows
- How to restructure AGENTS.md §11.4 (major rewrite vs new subsections)
- How drift checks integrate into §11.3 step sequence (new substeps vs extending existing)
- `bin/lint.sh` internal implementation for drift checks (hash algorithm, wikilink resolution logic)
- Reflect state file location and exact format
- Whether `decision_history` uses page IDs or filenames as identifiers

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema Specification
- `AGENTS.md` §11.4 — Reflect Workflow (current 6-step skeleton). Phase 6 significantly expands this with three-tier model, decision record creation rules, and checkpoint mechanism.
- `AGENTS.md` §11.3 — Lint Workflow (12-step procedure). Phase 6 extends with drift detection checks integrated into the standard lint pass.
- `AGENTS.md` §5 — Frontmatter Schema. New fields: `decision_history` on affected pages, plus decision-type-specific frontmatter (trigger_type, affected_pages, etc.).
- `AGENTS.md` §9 — Structured Operations and Executor Model. Inline decision record creation hooks into MERGE, SUPERSEDE operations.
- `AGENTS.md` §10 — Compiler Pipeline. Content-hash drift detection relates to compilation status lifecycle.
- `AGENTS.md` §12 — Index and Log format. New "Decisions" index category. Reflect log entries follow existing format.
- `AGENTS.md` §6 — Provenance, Epistemics, and Staleness. Content-hash mechanism already defined; drift detection operationalizes it.

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 6 requirements: DCSN-01 through DCSN-03, DRFT-01 through DRFT-04

### Prior Phase Context
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — Progressive disclosure format for decision pages (D-23), commit conventions including `reflect(scope):` (D-25), provenance syntax (D-13–D-18)
- `.planning/phases/02-page-types-examples-navigation/02-CONTEXT.md` — Template design pattern: skeleton + comments in `schema/templates/` (D-12–D-15), index strategy as curated list (D-09–D-11)
- `.planning/phases/03-ingestion-provenance-pipeline/03-CONTEXT.md` — Content hash stored at ingest time (D-12), CLI helper pattern: bash, agent-agnostic, zero API deps (D-11–D-13)
- `.planning/phases/04-query-structured-operations/04-CONTEXT.md` — Compilation status fields and lifecycle (D-06–D-11), validator pattern (D-16–D-19), structured operation logging (D-20–D-21)
- `.planning/phases/05-lint-quality/05-CONTEXT.md` — Severity tiers: error/warning/info (D-17), auto-fix boundary (D-18–D-19), lint report in `wiki/maintenance/` (D-15), `bin/lint.sh` as established pattern

### Existing Assets
- `bin/lint.sh` — Existing lint CLI helper. Drift checks extend this script.
- `bin/validate-op.sh`, `bin/ingest.sh`, `bin/search.sh` — Established CLI helper patterns.
- `wiki/maintenance/lint-report.md` — Existing lint report page. Gains new "Drift" section.
- `wiki/index.md` — Page inventory. Gains new "Decisions" category.
- `wiki/log.md` — Activity log. Reflect entries appended here.
- `wiki/overviews/decision-making.md`, `wiki/overviews/personal-decision-patterns.md` — Existing overview pages (decision records are a separate type, not overviews).
- `schema/templates/` — Existing template directory. Gains `decision.md` template.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/lint.sh` — Primary integration point for drift checks. Existing Python block architecture supports adding new check categories.
- `bin/validate-op.sh` — Pattern for deterministic file-based validation. Drift checks follow similar approach.
- `schema/templates/` — Five existing templates. Decision template follows the same skeleton + comments pattern.
- `wiki/maintenance/lint-report.md` — Existing report structure organized by severity and category. Drift section extends this.
- Provenance markers `[prov:source_id#locator]` across wiki pages — parseable for drift checks (missing source detection).
- `content_hash` fields on source summary pages — direct input for content-hash drift detection.

### Established Patterns
- CLI helpers: bash, agent-agnostic, zero API deps, file bookkeeping only (Phases 3–5)
- Lint categories: structural, staleness, contradiction, gap — drift extends this family
- Severity tiers: error (must fix), warning (should fix), info (nice to know)
- Log format: `## [YYYY-MM-DD] reflect | <scope>` with structured entries
- Commit convention: `reflect(<scope>): <one-line summary>`
- Template pattern: skeleton + comments in `schema/templates/`, companion exemplars in `wiki/`
- Page-type directories: `wiki/entities/`, `wiki/concepts/`, etc. — `wiki/decisions/` follows same pattern
- Index categories: Entities, Concepts, Sources, Comparisons, Overviews — Decisions added

### Integration Points
- AGENTS.md §11.4 needs major expansion: three-tier reflect model, inline creation rules, workflow recommendation triggers, periodic reflect procedure, checkpoint mechanism
- AGENTS.md §11.3 needs drift checks added to lint workflow steps
- AGENTS.md §5 needs new frontmatter: decision page type fields + `decision_history` field on all page types
- AGENTS.md §9 needs inline decision record creation hooks for MERGE and SUPERSEDE operations
- AGENTS.md §12 needs "Decisions" index category
- `bin/lint.sh` needs drift check implementations (source/wiki mismatch, content-hash, wikilink resolution, index coverage, Dataview frontmatter)
- `wiki/maintenance/` needs reflect-state file for checkpoint mechanism
- Existing wiki page templates may need `decision_history` field added to frontmatter

</code_context>

<specifics>
## Specific Ideas

- Decision record unifying principle: "create a decision record when future-you would reasonably ask 'why is the wiki shaped this way?'"
- Three-tier reflect keeps decision records flowing without making any single mechanism a bottleneck — inline for obvious events, recommendations for ambiguous signals, periodic sweep as safety net
- Content-hash drift is mechanism, compilation_status: stale is state — drift detection feeds into compilation status, not the reverse
- Drift categorization by interpretation, not symptom — same broken wikilink can be structural or drift depending on why it matters
- Back-link design balances auditability (always in frontmatter) with clean pages (visible section only when meaningful)
- Reflect checkpoint makes periodic passes deterministic — no guessing where the last scan ended, even when a pass produces no decision records

</specifics>

<deferred>
## Deferred Ideas

- Zotero/cloud drift reconciliation — requires toolchain-specific integration, deferred to future integration layer after v1 wiki compiler is stable
- Lint performance modes (`--quick`, `--full`, `--skip-hash`) — not needed at v1 scale, but architecture should not preclude them

</deferred>

---

*Phase: 06-reflection-drift-detection*
*Context gathered: 2026-04-14*
