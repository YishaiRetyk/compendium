# Requirements: LLM Wiki Compiler

**Defined:** 2026-04-06
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Schema & Conventions

- [ ] **SCHM-01**: Agent-agnostic schema document (CLAUDE.md / AGENTS.md) that tells any LLM how to maintain the wiki
- [ ] **SCHM-02**: Schema covers all workflows: ingest, query, lint, reflect
- [ ] **SCHM-03**: Schema defines page type conventions and when to use each type
- [ ] **SCHM-04**: Schema defines frontmatter fields and their semantics
- [ ] **SCHM-05**: Schema defines structured operations vocabulary (UPDATE, MERGE, SUPERSEDE, ARCHIVE)

### Directory Structure

- [ ] **DIRS-01**: Raw sources directory for immutable input documents
- [ ] **DIRS-02**: Wiki directory for LLM-maintained markdown pages
- [ ] **DIRS-03**: Clear separation between source layer and wiki layer
- [ ] **DIRS-04**: Git-tracked repository with meaningful commit conventions

### Page Templates

- [ ] **PAGE-01**: Entity page template (person, tool, topic) with type-specific sections
- [ ] **PAGE-02**: Concept page template for ideas, theories, frameworks
- [ ] **PAGE-03**: Source summary page template with extraction and provenance
- [ ] **PAGE-04**: Comparison page template for contrasting sources or viewpoints
- [ ] **PAGE-05**: Overview/synthesis page template for high-level topic summaries
- [ ] **PAGE-06**: All templates include frontmatter schema (type, title, sources, epistemic status, dates)
- [ ] **PAGE-07**: All templates use progressive disclosure (TL;DR → key facts → detail → sources)

### Index & Log

- [ ] **INDX-01**: Content index (index.md) cataloging all wiki pages with links, summaries, and metadata
- [ ] **INDX-02**: Index organized by category (entities, concepts, sources, comparisons, etc.)
- [ ] **INDX-03**: Index updated on every ingest operation
- [ ] **LOG-01**: Chronological activity log (log.md) recording all operations
- [ ] **LOG-02**: Log entries are parseable with consistent prefix format
- [ ] **LOG-03**: Log covers operational events (ingests, queries, lint passes) — structural reasoning lives in decision records (DCSN-*), not the log

### Example Pages

- [ ] **EXMP-01**: Example entity page demonstrating all conventions
- [ ] **EXMP-02**: Example concept page with cross-references and epistemic markers
- [ ] **EXMP-03**: Example source summary with provenance chain
- [ ] **EXMP-04**: Example comparison page contrasting multiple sources
- [ ] **EXMP-05**: Example populated index and log files

### Claim-Level Provenance

- [ ] **PROV-01**: Provenance attaches to individual claims/propositions, not just pages
- [ ] **PROV-02**: Each claim links to the specific source passage(s) that support it
- [ ] **PROV-03**: Provenance metadata includes source ID, passage reference, and extraction date
- [ ] **PROV-04**: Source hash/version stored with claims so that when a source changes, dependent claims can be detected and marked stale automatically
- [ ] **PROV-05**: Provenance conventions documented in schema with inline syntax (e.g. Dataview inline fields)

### Compiler Pipeline

- [ ] **CMPL-01**: Multi-pass compilation pipeline: diff → extract → merge → lint
- [ ] **CMPL-02**: Diff pass — identify what new information a source adds relative to existing wiki state
- [ ] **CMPL-03**: Extract pass — pull claims, entities, and relationships from source with provenance
- [ ] **CMPL-04**: Merge pass — integrate extracted knowledge into existing wiki pages, creating new pages where needed
- [ ] **CMPL-05**: Lint pass — verify consistency, cross-references, and integrity after merge
- [ ] **CMPL-06**: Optional follow-on passes for summaries, images, or restructuring
- [ ] **CMPL-07**: Pipeline documented step-by-step in schema as the canonical ingest workflow

### Ingestion

- [ ] **INGST-01**: Source classification (article, paper, journal entry, transcript, image-heavy, data file)
- [ ] **INGST-02**: Type-appropriate extraction logic per source classification
- [ ] **INGST-03**: Per-source summary page created with claim-level provenance (per PROV-01/02)
- [ ] **INGST-04**: Existing wiki pages updated when new source adds relevant information
- [ ] **INGST-05**: Cross-references (wikilinks) generated between related pages
- [ ] **INGST-06**: Index and log updated after each ingest

### Query & Delta Compilation

- [ ] **QURY-01**: Question answering against the wiki with citations to specific pages and sources
- [ ] **QURY-02**: Index-first search — LLM reads index to find relevant pages, then drills into them
- [ ] **QURY-03**: Delta compilation at query time — compare current wiki coverage against relevant sources, compile only the missing synthesis exposed by the query
- [ ] **QURY-04**: Mandatory write-back — useful query outputs become durable wiki updates (new or updated pages), not ephemeral chat
- [ ] **QURY-05**: Query workflow documented step-by-step in schema

### Structured Operations & Executor

- [ ] **SOPS-01**: UPDATE operation — modify existing page with new information, preserving provenance
- [ ] **SOPS-02**: MERGE operation — combine two pages covering the same concept
- [ ] **SOPS-03**: SUPERSEDE operation — mark a claim or page as replaced by newer information
- [ ] **SOPS-04**: ARCHIVE operation — move outdated content out of active wiki while preserving history
- [ ] **SOPS-05**: All operations logged with rationale
- [ ] **SOPS-06**: Deterministic executor/validator that applies structured operations (LLM proposes, executor validates and applies)

### Epistemic Status

- [ ] **EPST-01**: Per-claim epistemic markers: sourced (directly from source), inferred (synthesized), tentative (weak evidence), stale (likely outdated)
- [ ] **EPST-02**: Markers visible in page content (not just frontmatter)
- [ ] **EPST-03**: Epistemic status conventions documented in schema

### Contradiction Detection

- [ ] **CNTR-01**: Lint rule that identifies when sources disagree on the same claim
- [ ] **CNTR-02**: Contradictions surfaced with both sides cited
- [ ] **CNTR-03**: Contradictions flagged in affected wiki pages

### Staleness & Temporal Decay

- [ ] **STALE-01**: Claims inherit temporal relevance from source publication dates
- [ ] **STALE-02**: Lint rule flags claims older than a configurable threshold
- [ ] **STALE-03**: Different knowledge types decay at different rates (e.g. scientific findings vs. software versions vs. personal goals)
- [ ] **STALE-04**: Decay rate conventions documented in schema per knowledge domain

### Knowledge Gaps

- [ ] **GAP-01**: Lint rule identifies topics mentioned frequently but lacking dedicated pages
- [ ] **GAP-02**: Lint rule identifies categories with sparse source coverage relative to others

### Decision Records

- [ ] **DCSN-01**: Reflection entries recording why structural changes were made to the wiki
- [ ] **DCSN-02**: Decision records capture what framing was adopted, what it replaced, and alternatives considered
- [ ] **DCSN-03**: Reflect workflow documented in schema

### Lint & Maintenance

- [ ] **LINT-01**: Lint workflow that health-checks the wiki on demand
- [ ] **LINT-02**: Detect orphan pages (no inbound links)
- [ ] **LINT-03**: Detect missing cross-references (related pages not linked)
- [ ] **LINT-04**: Detect stale claims (per STALE-01/02)
- [ ] **LINT-05**: Detect contradictions (per CNTR-01/02/03)
- [ ] **LINT-06**: Suggest new questions to investigate and new sources to look for
- [ ] **LINT-07**: Lint workflow documented step-by-step in schema

### Cross-System Drift Detection

- [ ] **DRFT-01**: Detect when raw sources exist but have no corresponding wiki pages
- [ ] **DRFT-02**: Detect when wiki pages reference sources that no longer exist
- [ ] **DRFT-03**: Detect drift between wiki and broader toolchain (Obsidian vault state, Zotero libraries, cloud/local file divergence)
- [ ] **DRFT-04**: Drift check integrated into lint workflow

### Progressive Disclosure

- [ ] **PROG-01**: All wiki pages start with TL;DR / key facts section
- [ ] **PROG-02**: Detail sections follow progressive depth (summary → analysis → raw data/sources)
- [ ] **PROG-03**: Schema instructs LLM to read shallow summaries first, drill down only where needed

### CLI Helpers

- [ ] **CLI-01**: Search tool for querying wiki pages (index-based or text search)
- [ ] **CLI-02**: Ingest helper that scaffolds the ingest workflow
- [ ] **CLI-03**: Lint helper that runs all lint rules and reports findings

### Obsidian Integration

- [ ] **OBSD-01**: All wiki pages use valid Obsidian wikilinks for cross-references
- [ ] **OBSD-02**: All wiki pages have Dataview-compatible YAML frontmatter
- [ ] **OBSD-03**: Wiki structure is graph-view friendly (meaningful links, not noise)
- [ ] **OBSD-04**: Frontmatter supports Dataview queries for dynamic tables and lists

### Privacy & Scaling Boundaries

- [ ] **BNDY-01**: Schema distinguishes markdown-first baseline (v1) from optional scale upgrades (SQLite metadata, split indexes)
- [ ] **BNDY-02**: Privacy-tiered routing: schema supports marking sources/pages as local-only (never sent to cloud models) vs. cloud-safe
- [ ] **BNDY-03**: Scaling boundary documented as provisional heuristics: approximate thresholds for splitting index, incremental lint, and optional DB — to be validated through use

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Automated Pipeline

- **PIPE-01**: CLI pipeline that orchestrates full ingest → compile → lint automatically
- **PIPE-02**: Batch ingestion of multiple sources with minimal supervision
- **PIPE-03**: Scheduled lint/maintenance runs

### Advanced Search

- **SRCH-01**: Semantic search with embeddings over wiki pages
- **SRCH-02**: Integration with qmd or similar local search engine
- **SRCH-03**: MCP server for native tool access from LLM agents

### Scale

- **SCLE-01**: Category-based index splitting when wiki exceeds ~200 pages
- **SCLE-02**: Incremental lint (only check pages affected by recent changes)
- **SCLE-03**: SQLite metadata store for provenance queries at scale

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Chat interface / conversational UI | NotebookLM already does this; the wiki is the interface |
| Embedding-based RAG infrastructure | Heavy infra dependency; index-first search sufficient for v1 |
| Real-time collaboration / multi-user | Personal system; complexity for zero value |
| Web application / hosted service | Local, file-based system; Obsidian is the interface |
| Auto-ingestion from web feeds | Human curation is essential; unfiltered ingestion creates noise |
| AI-generated unsolicited suggestions | Wiki should be quiet and reliable, not a chatty assistant |
| Mobile app | Obsidian mobile exists for reading |
| Source editing / annotation | Raw sources are immutable by design |
| Automatic external API calls | System works offline except for LLM API calls |
| OAuth / authentication | Local personal system; file system permissions sufficient |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (populated by roadmapper) | | |

**Coverage:**
- v1 requirements: 70 total
- Mapped to phases: 0
- Unmapped: 70 ⚠️

---
*Requirements defined: 2026-04-06*
*Last updated: 2026-04-06 after initial definition*
