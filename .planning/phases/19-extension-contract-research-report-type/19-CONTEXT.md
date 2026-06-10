# Phase 19: Extension Contract + Research-Report Type - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Two deliverables, designed together:

1. **Source-type extension contract** — a new authoritative reference `schema/reference/source-types.md` defining the 5-dimension recipe (acquisition / locator / extraction granularity / drift / epistemic default), the primary-vs-secondary axis (primary → `direct`, secondary → `derived`), the decision rule (a new `source_type` is justified only if it changes ≥1 dimension; otherwise sub-case), a retro-fit table mapping all existing source types across the 5 dimensions, and an "Evaluated candidates" sub-case registry that Phases 20 (PDF) and 21 (video) will append to.
2. **`research-report` type** — fully implemented as the contract's worked secondary instance: frontmatter enum + Pass-0 classification, `#r<n>` reference locator, citation registry convention, `derived`-only support type with lint enforcement, lower epistemic default, Model C promotion path, audit priority, and retro-classification of the two existing AI deep-research reports (claims sweep + registry backfill).

Covers EXT-01..03 and RPT-01..06. The research-report *design* is LOCKED by `.planning/seeds/research-report-ingest.md` — this phase implements it; it does not re-litigate Model C, derived-only, or the no-web-research-operation stance.

**Out of scope:** PDF and video conventions (Phases 20/21 — the contract only provides their evaluation rule and registry slot); 999.5 external source drift detection (citation registries are its future trigger, not its implementation); `repository` source type; auto-promotion of citations (Model B); any 5th web-research operation.

</domain>

<decisions>
## Implementation Decisions

### Contract placement & routing
- **D-01:** New `schema/reference/source-types.md` is THE authoritative home for source typing: the 5-dimension contract, primary/secondary axis, decision rule, retro-fit table, worked instances, AND ownership of `source_type` enum semantics. `schema/reference/frontmatter.md` keeps its enum line but points to source-types.md for semantics; `schema/workflows/ingest.md` Pass 0 points to it for classification.
- **D-02:** source-types.md gets a row in the AGENTS.md/CLAUDE.md routing table ("Adding/evaluating a new source type → `schema/reference/source-types.md`"). Byte-equality maintained via `bin/sync-claude.sh`. Phase 18's no-new-core-lines precedent applies to pointers, not authoritative refs — every authoritative `schema/reference/*.md` has a routing row.
- **D-03:** Retro-fit table covers ALL six existing enum types (article, paper, transcript, journal, data, image) plus `research-report` as the worked 7th. While writing it, **reconcile the ingest claim-granularity table vocabulary** (report, technical doc, book-chapter, essay, meeting notes…) to enum types — sub-case names map to their parent enum type via the contract's sub-case concept.
- **D-04:** source-types.md includes an **"Evaluated candidates" sub-case registry**: one row per evaluated candidate (pdf, video, repository, …) with verdict (new type / sub-case of X), dimensions touched, link to its convention doc. Phases 20–21 append rows here instead of inventing structure.

### Citation registry shape
- **D-05:** New locator row in `schema/reference/provenance.md` Locator Types table: `Reference | #r<number> | #r7 | research-report bibliography entries`. Explicit and grep-able; claims cite `[prov:<report-src>#r7|derived|<date>]`.
- **D-06:** The citation registry lives as a **body `## References` block** in the source summary page — one entry per citation keyed `r<n>::` with URL, title, access date, and promotion status. NO new frontmatter field (avoids 30-entry YAML blobs; respects the no-provenance-blobs-in-frontmatter rule; Dataview-reachable via inline fields).
- **D-07:** Promotion mechanics (RPT-05, Model C): when a citation earns promotion, the human acquires the cited page and it gets its own normal ingest; the **earning claim is re-pointed** — `[prov:report#r7|derived]` → `[prov:new-source#locator|direct]` (an UPDATE op) — and the registry entry is marked `promoted → <new-source-id>`. Other claims citing the report stay as-is.

### Enforcement depth
- **D-08:** Lint mechanically enforces derived-never-direct (RPT-03): new check in the provenance category — `[prov:<research-report-src>#…|direct]` is an **error**. This is the anti-laundering defense; convention-only would silently regress. LINT_VERSION bumps 1.8.0 → 1.9.0.
- **D-09:** Lint also validates `source_type` enum VALUES (currently presence-only): unknown values are an error; the valid set is defined once, matching source-types.md. Closes the typo-bypass hole in D-08 (`research_report` / `report` would otherwise skip the check).
- **D-10:** `bin/audit-claims.sh` gets BOTH thin additions for RPT-04: (a) a **5th priority selector** (research-report/derived claims) alongside stale/epistemic/recency/fanout; (b) `resolve_locator` learns to resolve `#r<n>` **positionally** against the report's bibliography section, so prioritized claims return real passages instead of `insufficient-locator`.

### Retro-classification depth (RPT-06)
- **D-11:** Full claims sweep: all **168 existing `direct` markers across 14 wiki pages** citing the two reports are rewritten `direct → derived`. Locators stay unchanged (they point at report sections — still valid; `#r<n>` is for bibliography-specific cites). Lint goes green by fixing data, not by grandfathering.
- **D-12:** Page-level `epistemic_status` is re-graded in the same sweep: dependent pages whose provenance-backed claims are now mostly derived drop to `mixed` (per existing page-level rules); `updated_at` bumped.
- **D-13:** Full registry backfill for both reports with **positional numbering**: `r<n>` = nth entry top-to-bottom in the raw source's bibliography section (raw sources are immutable — numbering is never added to the source files). The summary page's `## References` registry records the complete mapping (~12 entries for the PDF-SOTA report's "## Source Citations", ~18 for the frameworks report's "## Sources by Topic") with URL/title/status.
- **D-14:** Retro-classification is NOT a re-ingest: summary pages get `source_type: research-report` + registry; claims get the D-11/D-12 sweep; no re-extraction of new claims.

### Claude's Discretion
- Exact section structure/wording of source-types.md (contract prose, table layouts) — must use neutral placeholders in template-public surfaces per the MUST-NOT list.
- The reconciled granularity-table vocabulary mapping (which loose names map to which enum parents).
- Whether the frameworks report's topic-grouped "## Sources by Topic" numbers positionally across groups or per-group (pick one, document it in the registry convention).
- Epistemic default wording: seed says `mixed` (or `tentative`) — pick the default and when each applies.
- Audit selector name and CLI `--select` token for the 5th selector.
- Whether the sweep is scripted (one-off) or hand-applied — one commit per logical operation either way.
- Decision-record authoring for the schema change (a `reflect`-tier DR in `wiki-cloud/decisions/` is the established pattern for schema updates — Phase 18 D-09 precedent).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design lineage (the WHY and the locked design)
- `.planning/seeds/research-report-ingest.md` — **LOCKED design** for the research-report type: Model C hybrid provenance, ingest mechanics, epistemic-laundering threat model, out-of-scope list. The phase implements this seed.
- `.planning/seeds/primary-source-type-extensions.md` — the 5-dimension decision framework the contract formalizes (EXT-01/02 derive from its "Decision framework" section); repos/video analysis feeding the retro-fit table and sub-case registry.
- `.planning/notes/2026-05-31-milestone-grouping-proposal.md` — "Source Ingestion" cluster: unify the design, not the deliverable.

### Schema surfaces this phase edits
- `schema/reference/frontmatter.md` — `source_type` enum line (source-summary fields block); validation checklist.
- `schema/reference/provenance.md` — Locator Types table (gains `#r<n>` row); Support Types table (`derived` already defined); provenance validation rules.
- `schema/workflows/ingest.md` — Pass 0 classify step (gains research-report); claim-granularity table (vocabulary reconciliation per D-03).
- `schema/workflows/audit.md` — audit workflow doc (selector addition is documented here).
- `AGENTS.md` + `CLAUDE.md` — routing table row (D-02); byte-equality via `bin/sync-claude.sh --check`.

### Tooling this phase edits
- `bin/lint.sh` — `PROV_RE` at ~line 448 already captures support_type; `SOURCE_EXTRA_FIELDS` at ~line 406; LINT_VERSION at line 13 (1.8.0 → 1.9.0). New checks per D-08/D-09.
- `bin/audit-claims.sh` — FAITH-01 selectors (~line 490), `resolve_locator` (~line 423, unknown forms → `insufficient-locator`), `--select` CSV (line 50). Additions per D-10.

### Retro-classification targets
- `sources/2026/2026-06/2026-06-09-pdf-to-text-llm-ingestion-sota.md` — raw report; bibliography = "## Source Citations" (unnumbered bullets, ~12 entries).
- `sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md` — raw report; bibliography = "## Sources by Topic" (~18 links, topic-grouped).
- `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` + `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md` — summary pages to retro-classify (both currently `source_type: article`).
- 14 dependent wiki pages with 168 `direct` markers (entities: claude-code, spec-kit, gsd, superpowers, omnidocbench, olmocr; concepts: vlm-ocr-hallucination, subagents, progressive-disclosure, spec-driven-development; comparisons: ocr-pipeline-vs-vlm-ingestion, claude-code-orchestration-frameworks; overviews: agent-skills, pdf-text-extraction-for-llm-ingestion).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/lint.sh` provenance machinery: `PROV_RE` already captures `(source_id, locator, support_type, checked_at)` per marker, and lint already loads summary-page frontmatter — the derived-never-direct check composes existing pieces.
- `bin/audit-claims.sh` selector architecture: 4 selectors yield claim tuples and rank into `--sample N`; a 5th selector follows the exact same shape. `resolve_locator` has per-scheme resolvers (`#sec:`, `#p`, `#t`, `#para`) — `#r<n>` adds one more, slicing the bibliography section positionally.
- `<!-- page: N -->` page-marker precedent in provenance.md: "document-now / helper-later", optional-with-graceful-degradation — the same posture the `#r<n>` convention should take for sources without bibliographies.
- `bin/sync-claude.sh --check` + `bin/check-neutrality.sh` + `bin/gen-skills.sh --check` — existing gates; the routing-table edit (D-02) must pass all three (pre-commit + CI).

### Established Patterns
- v1.2 extraction conventions: one authoritative file per concern under `schema/reference/`; routing-table rows in the resident core; bare-pointer stubs (no reproduced content — Phase 16 D-01).
- Lint `routing` category (LINT_VERSION 1.8.0) validates path-ref integrity of the routing table — the new row must point at an existing file in the same commit.
- Compilation-tracking fields on source summary pages are the precedent for type-specific frontmatter — but D-06 deliberately puts the registry in the body instead.
- Template-public neutrality: source-types.md, provenance.md, ingest.md edits must use abstract placeholders (`<source-id>`, `<concept-slug>`), never real vault slugs. The retro-classification work itself touches `wiki-cloud/` (not template-public), where real slugs are fine.
- One commit per logical operation; solo structured ops get per-op prefixes; this phase's work is `schema:` / `lint(scope):` / ingest-adjacent commits per the conventions table.

### Integration Points
- `wiki-cloud/log.md` — the retro-classification is a logged wiki mutation (UPDATE ops on summary pages + dependent pages).
- `wiki-cloud/index.md` — summary-page entries may need re-description after retro-classification.
- `.github/workflows/` CI lint gate — picks up the new lint checks automatically once LINT_VERSION bumps; the sweep (D-11) must land with or before the lint check so CI never goes red between commits.

</code_context>

<specifics>
## Specific Ideas

- The seed's framing is binding: "separate *performing* research from *ingesting* a research artifact" — the contract doc should carry this distinction forward.
- The registry preview agreed during discussion: `- r7:: [olmOCR-Bench](https://…) — accessed 2026-06-09 — status: registry | promoted → <source-id>`.
- Ordering note for the planner: D-08's lint error and D-11's sweep are coupled — land the sweep in the same plan-step sequence as (or before) the lint check so the repo never lints red.

</specifics>

<deferred>
## Deferred Ideas

- **999.5 External Source Drift detection** — citation registries (D-06/D-13) are its natural trigger; explicitly out of this milestone.
- **`repository` source type** — gets a sub-case-registry row only if evaluated; implementation stays backlog (pairs with 999.5).
- **Web-assist inside query workflow** (controlled live-fetch variant in the seed) — noted in the seed as "likely out of scope even when this seed promotes"; do not build.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` — "Harden bin/lint.sh mask_markdown for fence edge cases" (Phase 14 review residue). Reviewed and NOT folded: an unrelated behavioral lint change; keyword-only match. Stays in backlog (also reviewed-not-folded in Phase 17).

</deferred>

---

*Phase: 19-extension-contract-research-report-type*
*Context gathered: 2026-06-10*
