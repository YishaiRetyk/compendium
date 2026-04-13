# Phase 5: Lint & Quality - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a comprehensive wiki health-check system that detects contradictions, stale claims, orphan pages, missing cross-references, and knowledge gaps on demand. Includes a CLI lint helper (`bin/lint.sh`), a persistent lint report page, severity-tiered findings, and a documented lint workflow in AGENTS.md. The lint workflow described in AGENTS.md §11.3 becomes fully operational with concrete detection rules, decay rates, and auto-fix policies.

</domain>

<decisions>
## Implementation Decisions

### Contradiction Detection
- **D-01:** v1 contradiction = provenance-backed source-level disagreement. Two different sources assert conflicting claims about the same subject/attribute. The system surfaces "Source A says X, Source B says Y" with both citations — it does not decide which is correct.
- **D-02:** Semantic conflict (arbitrary prose contradictions without provenance grounding) is out of scope for v1 strict contradiction rules. A lighter "tension" or "possible_conflict" category may be added in a future phase.
- **D-03:** Contradictions are flagged with inline markers on the affected claims, consistent with existing provenance and epistemic inline syntax. Pattern: `[contradiction:src_a#locator vs src_b#locator]` (exact syntax to be finalized by planner).
- **D-04:** Secondary aggregation: contradictions are also listed in the centralized lint report and navigable from there.
- **D-05:** New page-level frontmatter field `has_contradictions: true` added to pages containing contradiction-flagged claims. This is independent of `epistemic_status` — sourced pages can have contradictions without changing their epistemic status.
- **D-06:** Contradictions are severity: **warning** (source disagreement is expected, not a system failure).

### Staleness Thresholds & Decay Rates
- **D-07:** Primary decay category = knowledge domain. Each page declares a `knowledge_domain` frontmatter field that maps to a decay rate table in AGENTS.md §6.
- **D-08:** Secondary modifier = epistemic status. Tentative or inferred claims decay faster than their domain default.
- **D-09:** Override = source hash change. If a source's `content_hash` changes, all linked claims are marked stale regardless of decay window.
- **D-10:** Example domain decay rates (to be refined in AGENTS.md §6):
  - software/tech: ~6 months
  - scientific findings: ~2 years
  - biographical facts: ~5+ years
  - personal goals: ~3 months
- **D-11:** Decay rate definitions live in AGENTS.md §6 (Provenance, Epistemics, and Staleness section), centralized and authoritative.
- **D-12:** Lint auto-fixes claim-level stale markers when claims cross their decay threshold. This is a mechanical, deterministic, reversible operation.
- **D-13:** Page-level `epistemic_status` is only auto-updated to `stale` when the rollup clearly warrants it (e.g., all material is stale, or the TL;DR/summary is materially stale). Default: do not auto-change page-level status.
- **D-14:** All auto-fix staleness changes are logged in the lint report and `wiki/log.md`.

### Lint Report Format & Fix Policy
- **D-15:** Lint produces a persistent wiki page at `wiki/maintenance/lint-report.md` (operational state, not topic synthesis — separate from `wiki/overviews/`). Updated on each lint run.
- **D-16:** CLI `bin/lint.sh` prints a compact summary to stdout: counts by finding type, top critical findings, whether auto-fixes were applied.
- **D-17:** Three severity tiers, explicitly defined in AGENTS.md:
  - **error** — must fix: broken provenance references, missing sources, YAML parse failures
  - **warning** — should fix: stale claims, orphan pages, contradictions, missing cross-references
  - **info** — nice to know: knowledge gaps, sparse coverage, suggested questions
- **D-18:** Auto-fix boundary: **mechanical fixes only** — deterministic and reversible. Auto-fix includes: adding missing cross-references where the link target exists, updating stale claim markers (per D-12), fixing broken provenance refs where the correct source is unambiguous. "Obvious" is defined narrowly for provenance repair — any ambiguity means report-only.
- **D-19:** Report-only (no auto-fix): contradictions, knowledge gaps, orphan pages (may be intentional), page restructuring, any fix requiring judgment.

### Knowledge Gap Detection
- **D-20:** Red link (unresolved wikilink) flagging rule: flag when a red link appears on 2+ distinct pages. Exception: red links in TL;DR or Key Facts sections are always flagged regardless of frequency.
- **D-21:** Sparse source coverage measured relative to other domains (comparative heuristic). Flag a domain when it has materially fewer sources than the median/top domains.
- **D-22:** Maturity guardrail: sparse coverage detection only runs when the wiki has enough domains and sources for the comparison to be meaningful. Do not flag on day one when every domain is equally thin.
- **D-23:** Lint suggests investigative questions for gaps (per LINT-06), not specific sources. E.g., "Health domain has 1 source vs 8 in psychology. Consider: What are your current health goals?"

### Claude's Discretion
- Exact inline syntax for contradiction markers (as long as it's consistent with provenance/epistemic patterns and captures both source references)
- Exact decay rate numbers per domain (as long as the layered model — domain base + epistemic modifier + hash override — is implemented)
- CLI `bin/lint.sh` internal implementation details (argument parsing, output formatting)
- Lint report page structure and Dataview frontmatter (as long as it's organized by severity and category)
- Maturity threshold for sparse coverage detection (as long as it prevents false alarms on young wikis)
- Whether to create `wiki/maintenance/` as a new directory or integrate it into existing structure

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Schema Specification
- `AGENTS.md` §6 — Provenance, Epistemics, and Staleness. Staleness/decay rules to be extended with domain-based decay rate table. Core reference for claim-level provenance syntax, `checked_at` field, epistemic markers.
- `AGENTS.md` §5 — Frontmatter Schema. New fields to add: `has_contradictions`, `knowledge_domain`. Existing fields relevant: `epistemic_status`, `content_hash`, `checked_at`.
- `AGENTS.md` §11.3 — Lint Workflow (12-step skeleton). Phase 5 makes this fully operational with concrete detection rules, severity tiers, and auto-fix policies.
- `AGENTS.md` §10 — Compiler Pipeline. Lint pass (Pass 4) context.
- `AGENTS.md` §12 — Index and Log format. Lint log entries follow existing format.

### Requirements
- `.planning/REQUIREMENTS.md` — Phase 5 requirements: CNTR-01 through CNTR-03, STALE-01 through STALE-04, GAP-01, GAP-02, LINT-01 through LINT-07, CLI-03

### Prior Phase Context
- `.planning/phases/01-schema-structure-conventions/01-CONTEXT.md` — Provenance syntax (D-13–D-18), source registry, privacy routing, commit conventions
- `.planning/phases/02-page-types-examples-navigation/02-CONTEXT.md` — Epistemic inline syntax (D-04–D-08), template design
- `.planning/phases/03-ingestion-provenance-pipeline/03-CONTEXT.md` — Claim granularity rules (D-01–D-05), stale/supersede wording deferred contradiction semantics to Phase 5 (D-10 note)
- `.planning/phases/04-query-structured-operations/04-CONTEXT.md` — Compilation status fields (D-06–D-11), validator pattern (D-16–D-19), structured operation logging (D-20–D-21)

### Existing Assets
- `bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh` — Established CLI helper pattern (bash, agent-agnostic, zero API deps). `bin/lint.sh` follows same pattern.
- `wiki/index.md` — Page inventory for orphan detection and cross-reference checks
- `wiki/log.md` — Activity log, lint appends entries here
- `wiki/sources/` — Source summary pages with `compilation_status` and `content_hash` fields (staleness detection input)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/validate-op.sh` — Closest pattern for `bin/lint.sh`: bash script with structured checks, PASS/FAIL output, deterministic validation. Lint helper follows same architecture.
- `bin/search.sh` — Index parsing logic reusable for orphan detection (page inventory from `wiki/index.md`).
- `wiki/index.md` — Full page inventory with links, summaries, and metadata. Primary input for orphan detection and cross-reference analysis.
- Provenance markers across wiki pages — Parseable `[prov:source_id#locator]` syntax enables mechanical staleness and contradiction checks.
- Epistemic inline markers — Existing `[epistemic:: status]` syntax, lint updates these when marking claims stale.

### Established Patterns
- CLI helpers: bash, agent-agnostic, zero API deps, file bookkeeping only (Phases 3, 4)
- Inline markers: provenance `[prov:]`, epistemic `[epistemic::]` — contradiction markers extend this family
- Progressive disclosure: TL;DR → Key Facts → Detail → Sources (red link salience rule uses this structure)
- Log format: `## [YYYY-MM-DD] lint | <scope>` with structured entries (already defined in §11.3 step 11)
- Commit convention: `lint(<scope>): <one-line summary>` (already defined in §11.3 step 12)

### Integration Points
- AGENTS.md §6 needs extension: domain-based decay rate table, epistemic-status modifiers, hash override rule
- AGENTS.md §5 needs new fields: `has_contradictions`, `knowledge_domain`
- AGENTS.md §11.3 needs fleshing out: severity tiers, auto-fix boundary, contradiction detection rules, gap heuristics
- New directory `wiki/maintenance/` for lint report (operational state separate from content)
- Existing wiki pages may need `knowledge_domain` field backfilled in frontmatter

</code_context>

<specifics>
## Specific Ideas

- Contradiction detection mantra: "surface conflicts, not pretend to resolve them automatically"
- v1 contradiction = "provenance-backed source disagreement on the same claim slot" — no semantic guesswork
- Keep `epistemic_status` and `has_contradictions` as orthogonal dimensions — do not overload `mixed` for contradiction state
- Auto-fix boundary heuristic: "deterministic + reversible = auto-fix; judgment required = report only"
- Staleness layering: domain base → epistemic modifier → hash override. Three clean layers.
- Red link salience rule: TL;DR/Key Facts mentions are always reportable (high-visibility locations signal important gaps)
- Sparse coverage is inherently comparative — don't flag until the wiki has enough data for the comparison to mean something
- Lint report is operational state, not topic synthesis — lives in `wiki/maintenance/`, not `wiki/overviews/`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-lint-quality*
*Context gathered: 2026-04-13*
