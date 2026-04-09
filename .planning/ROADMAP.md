# Roadmap: LLM Wiki Compiler

## Overview

The LLM Wiki Compiler is built foundation-up: schema and conventions first (the compiler specification), then page types and examples (the output format), then ingestion and provenance (the input pipeline), then query and structured operations (the interaction layer), then lint and quality checks (the trust layer), and finally reflection and drift detection (the maintenance layer). Each phase delivers a complete, verifiable capability that the next phase depends on.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Schema, Structure & Conventions** - Agent-agnostic schema, directory layout, Obsidian compatibility, progressive disclosure conventions, and scaling boundaries
- [ ] **Phase 2: Page Types, Examples & Navigation** - Page type templates, epistemic status markers, example pages, index system, and activity log
- [ ] **Phase 3: Ingestion & Provenance Pipeline** - Source ingestion workflow, multi-pass compilation pipeline, claim-level provenance, and ingest CLI helper
- [ ] **Phase 4: Query & Structured Operations** - Question answering with delta compilation, structured operations (UPDATE/MERGE/SUPERSEDE/ARCHIVE), and search CLI helper
- [ ] **Phase 5: Lint & Quality** - Contradiction detection, staleness tracking, knowledge gap detection, full lint workflow, and lint CLI helper
- [ ] **Phase 6: Reflection & Drift Detection** - Decision records, reflect workflow, and cross-system drift detection

## Phase Details

### Phase 1: Schema, Structure & Conventions
**Goal**: A working Obsidian vault skeleton exists with a complete agent-agnostic schema that any LLM can follow, established directory conventions, and documented scaling boundaries
**Depends on**: Nothing (first phase)
**Requirements**: SCHM-01, SCHM-02, SCHM-03, SCHM-04, SCHM-05, DIRS-01, DIRS-02, DIRS-03, DIRS-04, OBSD-01, OBSD-02, OBSD-03, OBSD-04, PROG-01, PROG-02, PROG-03, BNDY-01, BNDY-02, BNDY-03
**Success Criteria** (what must be TRUE):
  1. An LLM agent (Claude Code or Codex) can read the schema document and understand how to create, update, and organize wiki pages without additional instruction
  2. The directory structure exists with clear separation between sources/, wiki/, and schema/ layers, and git tracks the repository with documented commit conventions
  3. All wiki page conventions specify valid Obsidian wikilinks, Dataview-compatible YAML frontmatter, and graph-friendly structure
  4. The schema documents progressive disclosure structure (TL;DR -> key facts -> detail -> sources) and instructs agents to navigate shallow-first
  5. Scaling boundaries and privacy-tiered routing are documented as provisional heuristics in the schema
**Plans:** 3 plans
Plans:
- [ ] 01-01-PLAN.md — Directory skeleton and AGENTS.md sections 1-8 with worked examples per page type and negative constraints
- [ ] 01-02-PLAN.md — AGENTS.md sections 9-16 with structured workflows (trigger/inputs/outputs/commit/abort), privacy decision table, and scaling tiers
- [ ] 01-03-PLAN.md — Strengthened validation (YAML parse, structural, provenance syntax) and human review with 11 explicit pass/fail criteria

### Phase 2: Page Types, Examples & Navigation
**Goal**: Complete page type templates, epistemic status conventions, working example pages, and a functional index/log system exist -- everything needed to start ingesting real sources
**Depends on**: Phase 1
**Requirements**: PAGE-01, PAGE-02, PAGE-03, PAGE-04, PAGE-05, PAGE-06, PAGE-07, EPST-01, EPST-02, EPST-03, EXMP-01, EXMP-02, EXMP-03, EXMP-04, EXMP-05, INDX-01, INDX-02, INDX-03, LOG-01, LOG-02, LOG-03
**Success Criteria** (what must be TRUE):
  1. Templates exist for all five page types (entity, concept, source summary, comparison, overview/synthesis) with type-specific sections, frontmatter schema, and progressive disclosure structure
  2. Epistemic status markers (sourced, inferred, tentative, stale) are defined with inline syntax visible in page content, not just frontmatter, and documented in the schema
  3. Example pages demonstrate every convention: an entity page, a concept page with cross-references and epistemic markers, a source summary with provenance, a comparison page, and populated index/log files
  4. A content index (index.md) exists organized by category with links, summaries, and metadata, and an activity log exists with consistent parseable format
  5. Opening the vault in Obsidian shows working wikilinks, valid Dataview queries, and a meaningful graph view across the example pages
**Plans**: TBD

### Phase 3: Ingestion & Provenance Pipeline
**Goal**: Real sources can be ingested into the wiki through a documented multi-pass pipeline that creates properly provenanced wiki pages and updates existing pages incrementally
**Depends on**: Phase 2
**Requirements**: INGST-01, INGST-02, INGST-03, INGST-04, INGST-05, INGST-06, CMPL-01, CMPL-02, CMPL-03, CMPL-04, CMPL-05, CMPL-06, CMPL-07, PROV-01, PROV-02, PROV-03, PROV-04, PROV-05, CLI-02
**Success Criteria** (what must be TRUE):
  1. A user can drop a source document (article, paper, journal entry) into sources/ and an LLM agent can classify it, run the multi-pass pipeline (diff -> extract -> merge -> lint), and produce wiki pages with claim-level provenance
  2. Each claim in a wiki page links to the specific source passage(s) that support it, with source ID, passage reference, and extraction date
  3. Ingesting a second source on a related topic updates existing wiki pages with new information rather than creating duplicates, and new cross-references are generated between related pages
  4. The index and activity log are updated after each ingest, and source hashes are stored so stale claims can be detected when sources change
  5. A CLI ingest helper exists that scaffolds the ingest workflow for the user
**Plans**: TBD

### Phase 4: Query & Structured Operations
**Goal**: Users can ask questions against the wiki and get cited answers that compile back into durable wiki pages, and all wiki mutations use a structured operations vocabulary that is logged with rationale
**Depends on**: Phase 3
**Requirements**: QURY-01, QURY-02, QURY-03, QURY-04, QURY-05, SOPS-01, SOPS-02, SOPS-03, SOPS-04, SOPS-05, SOPS-06, CLI-01
**Success Criteria** (what must be TRUE):
  1. A user can ask a question and the LLM reads the index first to find relevant pages, drills into them, and returns an answer with citations to specific pages and sources
  2. Query answers that produce useful synthesis are written back to the wiki as new or updated pages (mandatory write-back), not left as ephemeral chat
  3. Delta compilation works: querying a topic where new sources exist but haven't been fully compiled triggers compilation of only the missing synthesis
  4. Wiki mutations use UPDATE, MERGE, SUPERSEDE, and ARCHIVE operations, each logged with rationale, and a deterministic executor/validator applies them
  5. A CLI search helper exists for querying wiki pages via index-based or text search
**Plans**: TBD

### Phase 5: Lint & Quality
**Goal**: The wiki has a comprehensive health-check system that detects contradictions, stale claims, orphan pages, missing cross-references, and knowledge gaps on demand
**Depends on**: Phase 4
**Requirements**: CNTR-01, CNTR-02, CNTR-03, STALE-01, STALE-02, STALE-03, STALE-04, GAP-01, GAP-02, LINT-01, LINT-02, LINT-03, LINT-04, LINT-05, LINT-06, LINT-07, CLI-03
**Success Criteria** (what must be TRUE):
  1. Running the lint workflow detects orphan pages, missing cross-references, stale claims, and contradictions, and reports them in a structured format
  2. When two sources disagree on a claim, the contradiction is surfaced with both sides cited and flagged in the affected wiki pages
  3. Claims inherit temporal relevance from source dates, different knowledge types decay at configurable rates, and the lint flags claims older than their threshold
  4. The lint identifies topics mentioned frequently but lacking dedicated pages, and categories with sparse source coverage
  5. A CLI lint helper exists that runs all lint rules and reports findings, and the lint workflow is documented step-by-step in the schema
**Plans**: TBD

### Phase 6: Reflection & Drift Detection
**Goal**: The wiki maintains structural self-awareness through decision records that capture why changes were made, and detects drift between the wiki, raw sources, and external tools
**Depends on**: Phase 5
**Requirements**: DCSN-01, DCSN-02, DCSN-03, DRFT-01, DRFT-02, DRFT-03, DRFT-04
**Success Criteria** (what must be TRUE):
  1. When structural changes occur (page merges, reorganizations, schema updates), a decision record captures what changed, what framing was adopted, what it replaced, and alternatives considered
  2. The reflect workflow is documented in the schema and produces decision records that are navigable in Obsidian
  3. The system detects when raw sources have no wiki pages, when wiki pages reference missing sources, and when drift exists between wiki and broader toolchain (Obsidian vault, Zotero, cloud/local)
  4. Drift detection is integrated into the lint workflow so it runs as part of regular health checks
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Schema, Structure & Conventions | 0/3 | Planning complete | - |
| 2. Page Types, Examples & Navigation | 0/TBD | Not started | - |
| 3. Ingestion & Provenance Pipeline | 0/TBD | Not started | - |
| 4. Query & Structured Operations | 0/TBD | Not started | - |
| 5. Lint & Quality | 0/TBD | Not started | - |
| 6. Reflection & Drift Detection | 0/TBD | Not started | - |
