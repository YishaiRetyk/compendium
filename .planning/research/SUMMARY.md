# Project Research Summary

**Project:** LLM Wiki Compiler
**Domain:** LLM-maintained personal knowledge compilation system
**Researched:** 2026-04-06
**Confidence:** MEDIUM

## Executive Summary

The LLM Wiki Compiler is a fundamentally novel system in the personal knowledge management space: not a chat interface over documents, not a RAG system, but a *compiler* that transforms curated sources into a persistent, structured wiki maintained by LLM agents. Every existing tool (NotebookLM, Khoj, Quivr, Mem, Obsidian AI plugins) treats AI as an ephemeral assistant that answers questions. This project's differentiator is that the wiki is the artifact — knowledge compounds across sessions, claims carry provenance and epistemic status, and the LLM follows a schema specification rather than improvising. The recommended implementation is file-based and local: Obsidian for reading, git for provenance and transactions, Node.js/TypeScript CLI tools for the compilation pipeline, and markdown schema files (CLAUDE.md/AGENTS.md) as the compiler specification that any capable LLM agent can follow.

The architecture follows a strict three-layer compiler model: immutable sources as input, typed wiki pages as compiled output, and a schema directory as the build configuration. The critical path is schema first, then ingestion, then cross-referencing and compilation. The Dataview plugin for Obsidian is essential infrastructure — it powers dashboards, indexes, and metadata queries without requiring a separate database. The entire stack has no servers, no databases, and no runtime services beyond the LLM API calls themselves.

The dominant risk is building too much too soon. All five critical pitfalls (hallucination, context window limits, schema drift, provenance rot, over-engineering) share a common mitigation: start minimal, validate with real use, and treat the schema as living code rather than a complete specification. Provenance tracking and epistemic status markers are not Phase 2 polish — they are foundational to the system's trustworthiness and must be in Phase 1. The project should resist the temptation to define 6 page types, 8 epistemic markers, and full automation before the first 30 pages have been ingested and validated.

## Key Findings

### Recommended Stack

This system has no application stack in the traditional sense. The "stack" is: markdown processing libraries for CLI tooling, Obsidian plugins for the reading interface, and git for persistence and provenance. Node.js with the unified/remark ecosystem is the only mature toolkit for programmatic round-trip markdown manipulation — Python alternatives are parsers only, not AST transform-and-serialize tools. TypeScript typed interfaces for frontmatter schemas catch drift at compile time, which is essential given that schema consistency is the system's primary operational challenge.

**Core technologies:**
- **unified/remark ecosystem** (Node.js): round-trip markdown AST processing — the only mature option for programmatic wiki manipulation
- **gray-matter**: frontmatter parsing — battle-tested, 25M+ weekly downloads, handles edge cases
- **Obsidian + Dataview plugin**: reading interface and metadata query engine — Dataview is non-negotiable; it replaces a database
- **TypeScript + tsx**: typed frontmatter schemas and zero-build-step CLI scripts — catches schema drift at compile time
- **git + simple-git**: version control, provenance, and transaction mechanism — git IS the database for history and rollback
- **ripgrep + index files**: search layer for v1 — structured index files plus fast CLI search; no embedding DB needed
- **CLAUDE.md / AGENTS.md schema files**: the compiler specification — natural language instructions that any LLM follows; no agent framework needed

Note: All version numbers from research (unified ~11.x, gray-matter ~4.0.3, etc.) should be verified with `npm view [package] version` before committing to package.json, as web search was unavailable during research.

### Expected Features

The fundamental distinction this system must maintain is *compilation* vs *RAG*. A RAG system re-derives answers per query from raw documents. This system builds a persistent compiled artifact that compounds knowledge, tracks provenance per claim, and explicitly handles knowledge evolution (UPDATE, MERGE, SUPERSEDE, ARCHIVE). Features that blur this distinction — chat interfaces, embedding-based search, auto-ingestion from web feeds — are anti-features.

**Must have (table stakes):**
- Source ingestion with classification — without this, no input
- Summarization with claim-level source provenance — without provenance, the wiki is untrustworthy
- Cross-referencing via `[[wikilinks]]` — core Obsidian value proposition
- Incremental updates — new source updates existing pages rather than regenerating everything
- Structured index and append-only activity log — navigation and auditability
- Obsidian-compatible output — valid frontmatter, Dataview-queryable metadata, graph-friendly links
- Epistemic status markers (sourced/inferred/tentative) — the primary defense against hallucination becoming invisible

**Should have (differentiators):**
- Typed page schemas (entity, concept, source-summary, comparison) with templates
- Structured operations vocabulary (CREATE, UPDATE, SUPERSEDE, ARCHIVE) — logged after the fact, not prescribed before
- Contradiction detection across related pages
- Staleness tracking with `last_verified` dates
- Knowledge gap detection
- Progressive disclosure structure (summary + key facts + detail + sources) on every page
- Decision records / reflection when wiki structure changes

**Defer to v2+:**
- Automated compilation pipeline CLI (orchestrate ingest -> compile -> lint)
- Semantic search / embedding-based RAG layer
- Cross-system drift detection
- Category-split indexes (needed only at 200+ pages)
- Advanced lint rules

### Architecture Approach

The system is a three-layer compiler: sources (immutable input) -> compilation pipeline (diff, extract, merge, lint, index) -> wiki pages (typed compiled output). The schema directory contains the "build configuration" — page templates, workflow definitions, and operation specifications — that tells the LLM compiler how to transform sources. This mental model is operationally critical because it makes invariants clear: agents never modify sources, wiki pages are always re-derivable from sources plus schema, and the schema itself is configuration that agents follow rather than content they produce.

**Major components:**
1. **Schema layer** (CLAUDE.md/AGENTS.md + schema/ directory) — compiler specification; hub-and-spoke design with top-level overview pointing to workflow and template files
2. **Source store** (sources/ directory, immutable) — input layer; agents read only, never write
3. **Compilation pipeline** (LLM agent following schema workflows) — diff detection, claim extraction, page merging, lint, index update
4. **Wiki pages** (wiki/ directory, typed by page type) — compiled output; entity, concept, summary, comparison, guide, and meta pages
5. **Index + Log** (wiki/meta/) — index as regenerable cache of page metadata; log as append-only audit trail with in-progress/complete markers
6. **Git** — transaction mechanism, provenance, diff detection; commit after each operation cycle

**Key patterns:**
- Frontmatter-as-provenance: all metadata co-located with content for Dataview compatibility; no sidecar files, no SQLite
- Agent-agnostic schema: natural language instructions with exact examples, not code; works with Claude Code, Codex, or any future agent
- Progressive disclosure page structure: summary -> key facts -> detail -> open questions -> sources; enables index-first navigation without a database
- Operations as descriptive log entries, not prescriptive workflow gates: agent does the work, logs what happened using operation vocabulary

### Critical Pitfalls

1. **Silent hallucination** — prevent with extract-then-compile mode (verbatim extraction before synthesis), mandatory claim-level source pointers, epistemic markers from day one, and broken-link lint on every commit. Spot-check the first 10 ingestions manually.

2. **Context window collapse at scale** — prevent by designing index-first navigation from Phase 1. Never design workflows requiring the full wiki to be loaded. The index must be regenerable and maintained incrementally. Set explicit page-count thresholds in the schema.

3. **Over-engineering before validation** — start with exactly 3 page types (source summary, entity, concept), 3 epistemic markers (sourced, inferred, uncertain), and a simple ingest checklist. Review schema against actual usage after 30 pages. Prune unused features.

4. **Schema drift across agents/sessions** — prevent with exact YAML examples (not descriptions) in the schema, complete page templates with every field filled in, canonical example pages, and a frontmatter audit lint pass. Test new agents with a controlled ingest and diff against known-good output.

5. **Provenance link rot** — sources must be immutable once ingested; cite by file path plus git commit hash at ingestion time; source reorganization must be a formal operation that updates all citations; broken-citation lint on every commit.

## Implications for Roadmap

Based on research, the dependency graph is clear and the build order is bottom-up. The schema must exist before any workflow. The index must exist before scale. Provenance must be established before the wiki is trusted. Lint must exist before contradictions can be detected. Automation must wait until the manual process is validated.

### Phase 1: Foundation — Schema, Structure, and Templates

**Rationale:** Nothing else can be built without the schema, directory structure, and page templates. This is the compiler specification. All subsequent work depends on these conventions existing and being tested. Pitfalls 3 (over-engineering), 4 (schema drift), and 7 (Obsidian compatibility) are all Phase 1 risks.

**Delivers:** A working Obsidian vault with established conventions: directory structure (sources/, wiki/, schema/), 3 page type templates (source summary, entity, concept), frontmatter schema with provenance and epistemic fields, CLAUDE.md/AGENTS.md hub-and-spoke schema, activity log format, index system, and canonical example pages demonstrating every convention.

**Addresses:** Agent-agnostic schema, Obsidian compatibility, source immutability invariant, directory conventions, index and log system, git-as-transaction pattern.

**Avoids:** Over-engineering (start with 3 page types, 3 epistemic markers), schema drift (exact YAML examples, complete templates, lint from day one), Obsidian breakage (test every template in Obsidian before declaring complete).

**Research flag:** Standard patterns — this phase follows well-established Obsidian vault and compiler-design conventions. No additional research needed.

### Phase 2: Core Compilation — Ingestion and Source Summaries

**Rationale:** Once the schema exists, the first priority is getting real sources into the system and producing wiki pages from them. This is where the system starts delivering value and where hallucination risk is highest. The ingest workflow must enforce extract-then-compile mode and mandatory provenance from the first ingestion.

**Delivers:** A working ingest workflow that classifies and moves sources to sources/{type}/, extracts claims into a structured intermediate format, creates source summary pages with claim-level provenance, creates or updates entity and concept pages, updates the index, and commits everything as an atomic git operation.

**Addresses:** Source ingestion, summarization with provenance, basic cross-referencing, incremental updates (new source updates existing pages rather than regenerating), activity log, broken-link lint.

**Avoids:** Hallucination (extract-then-compile, mandatory source pointers, spot-check first 10 ingestions), provenance rot (immutability enforced, citations include source file path, lint validates on every commit), orphan state from partial failures (git-as-transaction, in-progress/complete log markers, idempotent pipeline stages).

**Research flag:** May benefit from a focused research pass on extract-then-compile prompt engineering patterns and idempotent LLM operation design. The ingest prompt structure is the highest-stakes prompt in the system.

### Phase 3: Wiki Compilation — Cross-References and Structured Operations

**Rationale:** After the first batch of sources are ingested and summarized, the compilation layer — where multiple sources synthesize into coherent entity and concept pages — becomes the focus. This is where the system diverges from simple summarization and becomes a knowledge compiler.

**Delivers:** Entity and concept pages synthesized from multiple source summaries, automatic `[[wikilink]]` generation between related pages, structured operations vocabulary fully defined and in use (CREATE, UPDATE, SUPERSEDE, ARCHIVE logged after the fact), comparison page type added when first real comparison need arises, and cross-reference lint (bidirectional link checking).

**Addresses:** Persistent compiled artifact (THE core differentiator), typed page schemas, structured operations vocabulary, progressive disclosure page structure.

**Avoids:** Structured operations as straitjacket (operations are descriptive/logged, not prescriptive/gated), broken wikilinks accumulating (lint on every ingest), page fragmentation (MERGE and SUPERSEDE when pages overlap).

**Research flag:** Standard patterns — wikilink generation and cross-reference linting follow established Obsidian/remark-wiki-link patterns.

### Phase 4: Quality Layer — Epistemic Status, Contradiction Detection, and Staleness

**Rationale:** Once the wiki has 30+ pages from multiple sources, the quality layer becomes meaningful. Contradiction detection requires multiple pages covering related topics. Staleness tracking requires pages that have aged. This phase transforms the wiki from a reliable store into a *trustworthy* store.

**Delivers:** Claim-level epistemic status markers enforced on all pages (backfill earlier pages), contradiction detection lint workflow, staleness tracking with `last_verified` dates and freshness categories, knowledge gap detection ("you have 8 sources mentioning X but no concept page for X"), and Dataview dashboards for stale pages and open contradictions.

**Addresses:** Epistemic status markers, contradiction detection, staleness tracking, knowledge gap detection, decision records.

**Avoids:** Stale claims without expiry signals (freshness metadata + lint rules), context window collapse (lint scoped to related-page clusters, not full wiki scan).

**Research flag:** Contradiction detection prompt design is novel territory — no established patterns. Needs a focused research pass or empirical iteration during this phase.

### Phase 5: Structural Intelligence — Reflection and Schema Maturation

**Rationale:** After enough real use, structural patterns emerge: pages that need merging, decisions that need documenting, schema fields that were never used vs. fields that are desperately missing. This phase formalizes the patterns that emerged from Phases 1-4 and adds the reflective layer.

**Delivers:** Decision records when structural changes occur (MERGE decisions, page reorganization), schema review and pruning based on actual log usage data, MERGE operation formally tested and documented, comparison page type in regular use, and consideration of the index-split optimization if wiki has exceeded ~150 pages.

**Addresses:** Decision records / reflection, schema maturation, MERGE and SUPERSEDE operations in full use.

**Avoids:** Index bottleneck (split if needed), schema bloat (prune unused fields based on log data).

**Research flag:** Standard patterns — this phase is primarily operational refinement, not new technology.

### Phase 6: Automation (v2 Territory)

**Rationale:** Only automate what the manual process has validated. The CLI compilation pipeline should be built when the ingest workflow is so well-understood that it can be expressed as deterministic steps. Do not build this in Phase 1-2.

**Delivers:** CLI tool (Node.js/TypeScript/commander) that orchestrates ingest -> extract -> merge -> lint -> index -> commit, category-split indexes if wiki has scaled beyond 200 pages, and potentially semantic search if index-first search proves insufficient.

**Addresses:** Automated compilation pipeline, scaled index architecture, CLI tooling from STACK.md.

**Avoids:** Automating too early (the manual process must be proven first).

**Research flag:** CLI tool design follows standard patterns (commander, simple-git, glob). Semantic search layer (if needed) would require a new research pass on embedding approaches for personal-scale wikis.

### Phase Ordering Rationale

- Schema before content: no wiki page should be created before the templates and conventions are tested in Obsidian. One badly-formed template used at scale creates massive cleanup work.
- Provenance from the first ingestion: retrofitting claim-level provenance onto an existing wiki is painful; it must be established in the ingest workflow from day one.
- Manual before automated: every phase of the compilation pipeline should be manually validated before the next phase is added. Phase 6 automation should only be built when Phases 2-5 are stable.
- Quality layer after content layer: contradiction detection and staleness tracking require multiple sourced pages to be meaningful. Building the lint workflows in Phase 1 produces false comfort (no contradictions when there are no pages).
- Index-first design from day one: even though context window collapse only manifests at scale, the workflows must assume index-first navigation from Phase 1. Retrofitting is prohibitive.

### Research Flags

Phases needing deeper research during planning:
- **Phase 2 (Ingest workflow):** Extract-then-compile prompt engineering is the highest-stakes prompt in the system. A focused research pass on structured claim extraction prompts and idempotent LLM operation patterns is recommended before finalizing the ingest workflow specification.
- **Phase 4 (Contradiction detection):** No established patterns for automated contradiction detection in personal knowledge wikis. Needs empirical iteration or targeted research.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Obsidian vault conventions, hub-and-spoke schema design, and frontmatter patterns are well-documented.
- **Phase 3 (Cross-references):** remark-wiki-link and Obsidian wikilink conventions are standard.
- **Phase 5 (Structural intelligence):** Operational refinement, no new technology.
- **Phase 6 (Automation):** commander/simple-git CLI patterns are standard; semantic search research only if index-first proves insufficient.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Core technologies (unified, gray-matter, Obsidian/Dataview, git) are HIGH confidence. Exact package versions unverified — web search unavailable; run `npm view [package] version` before committing to package.json. |
| Features | MEDIUM | Competitive landscape analysis (NotebookLM, Khoj, Quivr) is based on training data through early 2025 and may be outdated. The RAG vs. compilation conceptual distinction is HIGH confidence. Feature prioritization is HIGH confidence based on the project's stated goals. |
| Architecture | MEDIUM | Three-layer compiler model and component design are well-reasoned from adjacent domains (static site generators, compilers, Obsidian conventions). Novel combination — no direct reference architecture exists. Patterns need validation through use. |
| Pitfalls | HIGH | Core pitfalls (hallucination, context limits, schema drift, over-engineering, provenance rot) are extensively documented in LLM system design and knowledge management literature. Specific mitigation strategies are MEDIUM confidence pending validation. |

**Overall confidence:** MEDIUM — sufficient for roadmap creation. The architecture and pitfalls are well-understood; the specific schema design and prompt engineering details need empirical validation.

### Gaps to Address

- **Package versions:** All npm package versions are from training data (cutoff mid-2025). Verify with `npm view [package] version` before writing package.json. See STACK.md version verification table.
- **Dataview inline field syntax:** The exact ergonomics of Obsidian Dataview's inline field syntax (`[key::value]` vs `field:: value`) for claim-level annotation need hands-on testing. This affects how provenance markers work in page bodies.
- **remark-wiki-link maintenance status:** Should be verified before committing to it. If the package is stale, a custom wikilink regex (3 lines) is a viable fallback.
- **Ingest prompt design:** The extract-then-compile prompt for claim extraction is the most consequential prompt in the system. No established reference prompts exist — this needs empirical testing in Phase 2.
- **Contradiction detection approach:** No established patterns for automated contradiction detection across a personal wiki. Phase 4 should treat this as exploratory, not as implementation of a known pattern.
- **Competitor feature currency:** NotebookLM and other tools iterated rapidly in 2025-2026. The competitive landscape analysis may be outdated. Validate against current product pages before finalizing differentiator messaging.

## Sources

### Primary (HIGH confidence)
- Obsidian Dataview plugin — https://github.com/blacksmithgu/obsidian-dataview — dominant Obsidian plugin, core infrastructure
- ripgrep — https://github.com/BurntSushi/ripgrep — standard CLI search tool
- git — version control, transaction mechanism, provenance

### Secondary (MEDIUM confidence)
- unified/remark ecosystem — https://unifiedjs.com/ — markdown AST processing; versions unverified
- gray-matter — https://github.com/jonschlinkert/gray-matter — frontmatter parsing
- markdownlint-cli2 — https://github.com/DavidAnson/markdownlint-cli2 — markdown linting
- NotebookLM feature analysis — training data through early 2025
- Khoj, Quivr feature analysis — training data through early 2025
- Compiler architecture principles, static site generator patterns, Zettelkasten/evergreen notes patterns — general knowledge

### Tertiary (LOW confidence)
- Mem.ai features — training data, may have changed significantly
- Obsidian plugin ecosystem — plugin versions and features change frequently; validate specific plugin capabilities in current Obsidian version

---
*Research completed: 2026-04-06*
*Ready for roadmap: yes*
