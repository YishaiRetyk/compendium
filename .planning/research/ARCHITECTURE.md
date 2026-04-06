# Architecture Research

**Domain:** LLM-maintained personal wiki / knowledge compilation system
**Researched:** 2026-04-06
**Confidence:** MEDIUM (novel domain -- no established reference architectures; drawing from compiler design, knowledge management systems, Obsidian conventions, and LLM agent patterns)

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     SCHEMA LAYER (Agent Instructions)            │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────┐               │
│  │ AGENTS.md│  │ Page Schemas │  │  Workflow    │               │
│  │/CLAUDE.md│  │ (templates)  │  │  Definitions │               │
│  └──────────┘  └──────────────┘  └─────────────┘               │
├─────────────────────────────────────────────────────────────────┤
│                   COMPILATION PIPELINE                           │
│                                                                  │
│  ┌────────┐   ┌─────────┐   ┌───────┐   ┌──────┐   ┌───────┐  │
│  │  DIFF  │──>│ EXTRACT │──>│ MERGE │──>│ LINT │──>│ INDEX │  │
│  └────────┘   └─────────┘   └───────┘   └──────┘   └───────┘  │
│       ^                                       │                  │
│       │            ┌───────────┐              v                  │
│       └────────────│ REFLECT   │<─────────────┘                  │
│                    └───────────┘                                  │
├─────────────────────────────────────────────────────────────────┤
│                      WIKI LAYER (Output)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │
│  │ Entity   │  │ Concept  │  │ Summary  │  │ Comparison   │    │
│  │ Pages    │  │ Pages    │  │ Pages    │  │ Pages        │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘    │
│  ┌──────────┐  ┌──────────────────────┐                         │
│  │  Index   │  │  Log (append-only)   │                         │
│  └──────────┘  └──────────────────────┘                         │
├─────────────────────────────────────────────────────────────────┤
│                    SOURCE LAYER (Input, Immutable)               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Articles │  │ Journal  │  │ Podcasts │  │ Papers   │       │
│  │          │  │ Entries  │  │ / Notes  │  │          │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### Three-Layer Architecture

The system is a **compiler**, not an application. Sources are input; the wiki is compiled output; the schema is the compiler specification. This mental model is critical because it makes the system's invariants clear:

1. **Sources are immutable.** They never change after ingest. Like source code files.
2. **Wiki pages are derived artifacts.** They can always be re-derived from sources + schema. Like compiled binaries.
3. **The schema is the build configuration.** It tells the compiler (LLM) how to transform sources into wiki pages.

This is analogous to a static site generator (sources = content, schema = config/templates, wiki = build output) but the "build step" is an LLM rather than a deterministic program.

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **Schema** | Define page types, workflows, operations, conventions | CLAUDE.md / AGENTS.md + template files |
| **Source Store** | Hold immutable raw documents | `sources/` directory with subdirectories by type |
| **Diff Engine** | Detect what changed since last compilation | Git diff on sources dir, or new-file detection |
| **Extractor** | Pull structured claims/facts from raw sources | LLM reads source, outputs structured extractions |
| **Merger** | Integrate extracted facts into existing wiki pages | LLM reads existing page + new facts, produces updated page |
| **Linter** | Check consistency, find contradictions, flag staleness | LLM reads related pages, checks against rules in schema |
| **Indexer** | Maintain catalog of all pages with metadata | LLM updates index file after page changes |
| **Reflector** | Record structural decisions, trigger reframes | LLM writes decision records when structure changes |
| **Log** | Chronological record of all operations | Append-only markdown file |
| **Wiki Pages** | The compiled knowledge artifact | Typed markdown pages with frontmatter |

## Recommended Project Structure

```
life/                              # Repository root
├── CLAUDE.md                      # Agent schema (symlink or canonical)
├── AGENTS.md                      # Agent schema (symlink or canonical)
│
├── sources/                       # IMMUTABLE input layer
│   ├── articles/                  # Web articles, blog posts
│   ├── books/                     # Book notes, highlights
│   ├── journal/                   # Personal journal entries
│   ├── podcasts/                  # Podcast/video notes
│   ├── papers/                    # Academic papers, studies
│   ├── conversations/             # Chat logs, interview notes
│   └── _inbox/                    # Unsorted incoming sources
│
├── wiki/                          # COMPILED output layer
│   ├── entities/                  # People, orgs, products, places
│   ├── concepts/                  # Ideas, frameworks, mental models
│   ├── summaries/                 # Per-source digests
│   ├── comparisons/               # X vs Y analysis pages
│   ├── guides/                    # How-to, process pages
│   ├── meta/                      # Pages about the wiki itself
│   │   ├── INDEX.md               # Master catalog of all pages
│   │   ├── LOG.md                 # Append-only activity log
│   │   └── decisions/             # Structural decision records
│   └── _staging/                  # Pages under construction
│
├── schema/                        # COMPILER CONFIGURATION
│   ├── workflows/                 # Step-by-step agent instructions
│   │   ├── ingest.md              # How to process new sources
│   │   ├── query.md               # How to answer questions
│   │   ├── lint.md                # How to check consistency
│   │   └── reflect.md             # How to record decisions
│   ├── templates/                 # Page type templates
│   │   ├── entity.md              # Entity page template
│   │   ├── concept.md             # Concept page template
│   │   ├── summary.md             # Source summary template
│   │   └── comparison.md          # Comparison page template
│   └── operations.md             # UPDATE/MERGE/SUPERSEDE/ARCHIVE specs
│
└── .planning/                     # Project planning (not wiki content)
```

### Structure Rationale

- **`sources/` separate from `wiki/`:** Enforces immutability boundary. Sources never modified by agents. Clear input/output separation like a compiler.
- **`wiki/` subdivided by page type:** Enables targeted operations ("lint all entity pages"), keeps directory sizes manageable, matches Obsidian vault organization conventions.
- **`schema/` as its own directory:** Schema is neither source nor output -- it's configuration. Separating it makes the three-layer architecture explicit and avoids agents accidentally modifying their own instructions during wiki operations.
- **`_inbox/` in sources:** Drop zone for unprocessed sources. The ingest workflow moves classified sources to their proper subdirectory.
- **`_staging/` in wiki:** Pages that are being constructed but not yet ready for the main wiki. Prevents half-built pages from appearing in searches and index.
- **`meta/` in wiki:** Index, log, and decision records are wiki-adjacent but not knowledge content. Grouping them keeps the main wiki directories clean.

## Architectural Patterns

### Pattern 1: Frontmatter-as-Provenance (use this, not sidecar files)

**What:** Store all metadata -- provenance, epistemic status, page type, sources, timestamps -- in YAML frontmatter within each markdown file.

**When to use:** Always for v1. This is the right default.

**Why frontmatter over alternatives:**

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Frontmatter** | Co-located with content; Obsidian Dataview compatible; git-trackable; no sync issues; agents see metadata when reading file | Frontmatter can grow large for heavily-sourced pages; YAML parsing edge cases | **Use this** |
| **Sidecar files** (page.md + page.meta.yaml) | Separates concerns; metadata can grow independently | Double the files; sync issues (rename page, forget sidecar); agents must read two files; Obsidian doesn't natively surface sidecar data | Don't use |
| **SQLite** | Fast queries; relational joins; handles scale well | Not human-readable; merge conflicts in binary; breaks git diffing; agents can't easily read/write; Obsidian integration requires plugin | Don't use for v1 |
| **Inline markers** (<!-- source: ... -->) | Zero frontmatter overhead | Not queryable by Dataview; fragile parsing; mixes metadata with content | Don't use |

**Frontmatter schema example:**

```yaml
---
type: entity                    # Page type: entity|concept|summary|comparison|guide
title: "Huberman Lab Protocols"
aliases: [huberman protocols]
created: 2026-04-06
updated: 2026-04-06
sources:
  - path: sources/podcasts/huberman-sleep-2024.md
    claims: [sleep-timing, light-exposure]
  - path: sources/articles/examine-melatonin.md
    claims: [melatonin-dosing]
epistemic_status: sourced       # sourced|inferred|tentative|stale
confidence: high                # high|medium|low
tags: [health, sleep, protocols]
supersedes: []                  # Pages this replaced
---
```

**Scaling concern:** When a page has 50+ source references, frontmatter gets long. Mitigation: keep `sources` as a list of paths with claim IDs; the claim details live in the page body with inline markers like `[sourced: sleep-timing]`. This keeps frontmatter as an index and body as the detail.

### Pattern 2: Structured Operations (not raw file rewrites)

**What:** Define a vocabulary of operations (UPDATE, MERGE, SUPERSEDE, ARCHIVE) that agents use instead of arbitrary file edits. Each operation has preconditions, steps, and post-conditions defined in `schema/operations.md`.

**When to use:** Every time an agent modifies the wiki.

**Trade-offs:** Adds overhead to every operation (agent must check preconditions, follow steps, update log). But prevents the primary failure mode: agents silently losing information during rewrites.

**Operations vocabulary:**

| Operation | When | What Happens |
|-----------|------|-------------|
| **UPDATE** | New information for existing page | Read page, merge new claims, preserve existing claims, bump `updated`, log |
| **MERGE** | Two pages cover the same topic | Create unified page, SUPERSEDE both originals, update all inbound links |
| **SUPERSEDE** | Page replaced by another | Add `superseded_by` to frontmatter, move to archive, update index |
| **ARCHIVE** | Page no longer relevant | Add `archived: true` and `archive_reason`, remove from active index |
| **CREATE** | New topic identified | Check for existing page first, use template, add to index, log |

**Key rule:** No operation should silently drop claims. UPDATE must preserve existing sourced claims unless explicitly contradicted by a newer source (in which case the contradiction is noted, not silently resolved).

### Pattern 3: Progressive Disclosure via Page Structure

**What:** Every wiki page follows a consistent structure that supports both quick scanning and deep reading. The pattern is: **summary line -> key facts -> detailed sections -> provenance**.

**When to use:** All wiki pages.

**Template:**

```markdown
---
(frontmatter)
---

# Title

> **Summary:** One-sentence summary of this page's core content.

## Key Facts
- Fact 1 [sourced: claim-id-1]
- Fact 2 [sourced: claim-id-2]
- Fact 3 [inferred]

## Detail Sections
(Full content organized by topic)

### Subtopic A
Content with [[wikilinks]] to related pages...

## Open Questions
- Unresolved question 1
- Unresolved question 2

## Sources
- [[source-summary-1]] -- claims: claim-id-1, claim-id-2
- [[source-summary-2]] -- claims: claim-id-3
```

**Rationale:** The summary + key facts section serves as the "shallow" layer for navigation and index-first search. An agent answering a question can read just frontmatter + key facts from many pages before deciding which to read in full. This is how progressive disclosure works without a database or API -- it's structural.

### Pattern 4: Agent-Agnostic Schema Design

**What:** The schema (CLAUDE.md / AGENTS.md) must be a specification, not code. It tells any LLM what to do using natural language instructions, page templates with examples, and explicit operation definitions. No agent-specific tool calls, no framework-specific syntax.

**Design principles:**

1. **Instruction, not implementation.** Say "read the source file and extract claims in this format" not "call the extract_claims() function."
2. **Examples over rules.** Show a before/after of an UPDATE operation rather than listing abstract rules.
3. **One canonical file, symlinked.** Maintain one `schema/AGENTS.md` and symlink to `CLAUDE.md` at root. Avoids drift between agent-specific copies.
4. **Workflow references, not inline workflows.** The main schema file points to `schema/workflows/ingest.md` etc. This keeps the top-level file navigable and lets workflows be independently updated.
5. **Test with the dumbest agent.** If the schema works with a less capable model, it works with all of them. Write instructions that are unambiguous without requiring sophisticated reasoning.

## Data Flow

### Ingest Flow (New Source Arrives)

```
Human drops file in sources/_inbox/
    |
    v
[DIFF] Agent detects new file in _inbox/
    |
    v
[CLASSIFY] Agent reads source, determines type
    |         (article/journal/podcast/etc.)
    |
    v
[MOVE] Source moved to sources/{type}/
    |
    v
[EXTRACT] Agent reads source, produces:
    |        - Structured claims with IDs
    |        - Identified entities, concepts
    |        - Cross-references to existing wiki pages
    |
    v
[ROUTE] For each extracted item, determine target:
    |     - Existing page? -> UPDATE
    |     - New topic? -> CREATE
    |     - Overlapping pages? -> MERGE candidate
    |
    v
[MERGE/CREATE/UPDATE] Execute operations on wiki pages
    |
    v
[INDEX] Update wiki/meta/INDEX.md
    |
    v
[LOG] Append to wiki/meta/LOG.md
    |
    v
[LINT] (optional follow-on) Check affected pages for:
         - Contradictions with other pages
         - Missing cross-references
         - Stale claims
```

### Query Flow (Human Asks a Question)

```
Human asks question
    |
    v
[INDEX SEARCH] Agent reads INDEX.md to find relevant pages
    |             (progressive disclosure: metadata first)
    |
    v
[SHALLOW READ] Agent reads frontmatter + Key Facts
    |             from candidate pages
    |
    v
[DEEP READ] Agent reads full content of most relevant pages
    |
    v
[SYNTHESIZE] Agent composes answer with citations
    |            to wiki pages (which cite sources)
    |
    v
[DELTA CHECK] Did synthesis reveal new knowledge?
    |            - New connections between concepts?
    |            - Gaps in existing pages?
    |
    v
[COMPILE BACK] (optional) UPDATE wiki pages with
                 newly synthesized knowledge
```

### Lint Flow (Consistency Check)

```
Triggered by: schedule, post-ingest, human request
    |
    v
[SCOPE] Determine lint scope:
    |     - Single page? Set of pages? Full wiki?
    |
    v
[READ] Load pages in scope + their declared sources
    |
    v
[CHECK] For each page, verify:
    |     - All source references still valid?
    |     - Claims consistent across related pages?
    |     - Cross-references bidirectional?
    |     - Epistemic statuses current?
    |     - Any orphan pages (no inbound links)?
    |
    v
[REPORT] Produce lint report:
    |      - Contradictions found
    |      - Stale claims flagged
    |      - Missing links identified
    |      - Orphan pages listed
    |
    v
[FIX] (optional) Auto-fix safe issues:
       - Add missing backlinks
       - Update stale timestamps
       - Flag (but don't resolve) contradictions
```

## Scaling Considerations

| Scale | Pages | Architecture Adjustments |
|-------|-------|--------------------------|
| **Small** | ~50 | Single INDEX.md works fine. Agent can read entire index in one pass. Lint can scan all pages. No performance concerns. |
| **Medium** | ~200-500 | INDEX.md needs categories/sections. Agent should use progressive disclosure (read index, then frontmatter, then full pages). Lint should be scoped to recently-changed pages or specific categories. |
| **Large** | ~1000+ | INDEX.md should become a directory of index files by category. Consider a generated `_catalog.json` for fast programmatic search (v2). Lint must be incremental -- only pages changed since last lint run. May need a dependency graph to know which pages to re-lint when a source changes. |

### Scaling Priorities

1. **First bottleneck: Index size.** At ~200 pages, a single INDEX.md becomes too large for an agent to process in one pass. **Fix:** Split into category indexes (e.g., `wiki/meta/index/health.md`, `wiki/meta/index/psychology.md`). The main INDEX.md becomes a table of contents pointing to category indexes.

2. **Second bottleneck: Lint scope.** At ~500 pages, full-wiki lint becomes impractical (too many LLM calls). **Fix:** Incremental linting. Track "last linted" timestamp per page in frontmatter. Only lint pages modified since last lint, plus their direct neighbors (pages they link to or that link to them).

3. **Third bottleneck: Agent context window.** At ~1000+ pages, even reading frontmatter from all pages exceeds context. **Fix:** Two-stage search. First, scan category indexes (small files with page titles + one-line summaries). Second, read frontmatter of matched pages. This is the progressive disclosure pattern applied to the agent's own search process.

4. **Fourth bottleneck (v2 territory): Compilation time.** When a source touches 20+ pages, the ingest flow takes many LLM calls. **Fix:** Parallelizable operations. The extract step is independent per source. The merge step can be parallelized per target page (as long as two sources don't target the same page simultaneously). This is where CLI tooling and a job queue would help.

## Anti-Patterns

### Anti-Pattern 1: Monolithic Agent Instructions

**What people do:** Put everything -- all workflows, all templates, all rules, all examples -- in a single massive CLAUDE.md file.

**Why it's wrong:** LLM context is precious. A 5000-line instruction file means the agent spends most of its context window on instructions rather than content. Also makes updates error-prone.

**Do this instead:** Use a hub-and-spoke schema. The main CLAUDE.md/AGENTS.md is a ~200-line overview with explicit references to `schema/workflows/*.md` and `schema/templates/*.md`. The agent reads the top-level file first, then loads only the workflow relevant to the current task.

### Anti-Pattern 2: Treating Wiki Pages as Append-Only

**What people do:** Always add new information to the bottom of a page, never restructure.

**Why it's wrong:** Pages become incoherent over time. Contradictions accumulate. The page stops being a useful compilation and becomes a chronological dump.

**Do this instead:** Every UPDATE operation should re-synthesize the affected sections, not just append. The agent reads the existing section, integrates the new claim, and rewrites the section to be coherent. The chronological record belongs in the LOG, not in the page.

### Anti-Pattern 3: Storing Provenance Separately from Content

**What people do:** Keep a separate provenance database or sidecar files that map claims to sources.

**Why it's wrong:** Provenance drifts from content. When the page is edited, the provenance file is forgotten. Two-file sync is the most common failure mode in document systems.

**Do this instead:** Inline claim markers (`[sourced: claim-id]`) next to the actual claims, with the source mapping in frontmatter. Everything travels together. If you move text, the marker moves with it.

### Anti-Pattern 4: Over-Engineering the Schema Before Using It

**What people do:** Spend weeks designing the perfect ontology, page type hierarchy, and metadata schema before writing a single wiki page.

**Why it's wrong:** You don't know what metadata you actually need until you've ingested 20+ sources and written 30+ pages. Premature schema design leads to fields nobody uses and missing fields you desperately need.

**Do this instead:** Start with minimal frontmatter (type, title, created, updated, sources). Add fields when you discover a concrete need. The schema is a living document -- treat it like code that gets refactored, not a specification that must be complete before implementation.

### Anti-Pattern 5: Letting Agents Modify Sources

**What people do:** Allow agents to "clean up" or "standardize" source documents.

**Why it's wrong:** Sources are the ground truth. If an agent modifies a source, you lose the ability to re-derive the wiki from original sources. You also lose the ability to audit whether the agent's extraction was accurate.

**Do this instead:** Sources are read-only for agents. If a source needs cleanup, the human does it. The agent's job is extraction and compilation, not source editing.

## Integration Points

### Obsidian Integration

| Feature | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Graph view** | Use `[[wikilinks]]` for all cross-references | Graph view works automatically. Entity/concept pages become natural graph hubs. |
| **Dataview** | Structured frontmatter with consistent field names | Enables queries like "all entity pages updated in last 7 days" or "all pages with epistemic_status: stale" |
| **Search** | Progressive disclosure structure (summary + key facts at top) | Obsidian search results show first lines -- make sure they're informative |
| **Tags** | Use `tags:` in frontmatter, not inline #tags | Cleaner, queryable via Dataview, doesn't clutter body text |
| **Marp** | Guide pages can include Marp slide separators | Only for presentation-oriented pages, not all pages |

### Git Integration

| Feature | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Change tracking** | Commit after each ingest/lint cycle | Git history serves as an audit trail of all wiki changes |
| **Diff detection** | `git diff sources/` to detect new/changed sources | The DIFF step in the pipeline can use git rather than custom tracking |
| **Branching** | Not needed for v1 | Single-user system; linear history is fine |

### LLM Agent Integration

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Human -> Agent | Natural language commands + file drops in _inbox | No structured API needed for v1 |
| Agent -> Wiki | File reads and writes following operation specs | Agent reads schema, follows workflows, writes files |
| Agent -> Log | Append-only writes to LOG.md | Every operation logged with timestamp, operation type, affected pages |

## Build Order (Dependency Graph)

The system has clear dependency layers. Build bottom-up:

```
Phase 1: Foundation
  [Directory Structure] + [Minimal Schema] + [Page Templates]
  No dependencies. Must exist before anything else.

Phase 2: Core Pipeline
  [Ingest Workflow] depends on: templates, directory structure
  [Source Summaries] depends on: ingest workflow
  Needs Phase 1. This is where the system starts producing value.

Phase 3: Wiki Compilation
  [Entity/Concept Pages] depends on: source summaries, templates
  [Cross-references] depends on: multiple wiki pages existing
  [Index] depends on: wiki pages existing
  Needs Phase 2. This is where compilation (not just summarization) begins.

Phase 4: Quality Layer
  [Lint Workflow] depends on: wiki pages with provenance
  [Epistemic Status] depends on: claims having source references
  [Contradiction Detection] depends on: multiple pages covering related topics
  Needs Phase 3. Cannot lint what doesn't exist yet.

Phase 5: Structural Intelligence
  [Reflect Workflow] depends on: enough history to reflect on
  [MERGE/SUPERSEDE/ARCHIVE ops] depends on: pages that need restructuring
  [Decision Records] depends on: structural decisions being made
  Needs Phase 4. Structural operations emerge from experience, not upfront design.

Phase 6: Scale & Automation (v2)
  [Category Indexes] depends on: enough pages to categorize
  [Incremental Lint] depends on: lint workflow + scale pressure
  [CLI Helpers] depends on: stable workflows to automate
  Needs Phase 5. Don't automate until the manual process is proven.
```

**Critical path:** Phase 1 -> Phase 2 -> Phase 3. Get sources in, get summaries out, get cross-referenced pages built. Everything else is refinement.

**Parallel opportunities:** Within Phase 2, the ingest workflow for different source types (articles vs journal vs podcasts) can be developed independently. Within Phase 3, entity pages and concept pages can be developed in parallel.

## Sources

- Compiler architecture principles (input -> transform -> output pipeline; separation of specification from implementation)
- Static site generator patterns (content + config -> build output; Hugo, Jekyll, Astro)
- Obsidian community conventions for vault organization, frontmatter schemas, Dataview usage
- Knowledge management system design (Zettelkasten principles of atomicity and cross-referencing; Andy Matuschak's evergreen notes pattern)
- LLM agent design patterns (hub-and-spoke instruction design; progressive context loading; structured output formats)
- Note: All sources are from training data. No live verification was possible (web search unavailable). Confidence is MEDIUM -- the architectural patterns are well-established in adjacent domains but this specific combination (LLM + compiler + personal wiki) is novel.

---
*Architecture research for: LLM Wiki Compiler*
*Researched: 2026-04-06*
