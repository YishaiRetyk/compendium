# Feature Landscape

**Domain:** LLM-maintained personal wiki / knowledge compilation system
**Researched:** 2026-04-06
**Confidence:** MEDIUM (based on training data through early 2025; web search unavailable for verification of latest features)

## Competitive Landscape Context

The analysis draws from these existing systems:

- **NotebookLM** (Google): Upload sources, get AI-generated summaries, Q&A grounded in your sources, audio overviews. Hosted, closed-source, ephemeral (no persistent compiled artifact).
- **Mem** (Mem.ai): AI-first note-taking with auto-organization, semantic search, related note surfacing. Cloud-hosted SaaS.
- **Khoj**: Open-source personal AI assistant. Indexes notes (Obsidian, logseq, etc.), answers questions with citations. Primarily a RAG search layer, not a compilation system.
- **Quivr**: Open-source "second brain" focused on document ingestion and chat. RAG-based Q&A over uploaded documents.
- **Obsidian + AI plugins** (Smart Connections, Copilot, Text Generator): Bolt-on AI features for existing Obsidian vaults. Semantic search, chat with notes, AI writing assistance.
- **Reflect Notes**, **Notion AI**, **Logseq + AI**: Various PKM tools with AI features bolted on.

**Key insight:** Every existing tool treats AI as an assistant that answers questions about your notes. None treat AI as the *maintainer* of a persistent, compiled knowledge artifact. This is the fundamental differentiator of the LLM Wiki Compiler.

---

## Table Stakes

Features users expect. Missing = the system feels broken or incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Source ingestion | Without it, the system has no input. Every competitor does this. | Medium | Must handle diverse formats: articles, PDFs, journal entries, podcast notes, images. Classification + extraction pipeline. |
| Summarization | The baseline value proposition of every AI knowledge tool. NotebookLM's core feature. | Low | Per-source summaries are expected. The differentiator is what happens *after* summarization. |
| Question answering with citations | NotebookLM, Khoj, Quivr all do this. Users expect to ask questions and get sourced answers. | Medium | Must cite specific sources/claims, not just generate plausible text. |
| Search across all content | Every PKM tool has search. Khoj and Smart Connections do semantic search. | Low | Index-first approach (as specified in PROJECT.md) is fine for v1. Semantic search is a v2 enhancement. |
| Cross-referencing / linking | Obsidian's entire value proposition. Roam, Logseq, all PKM tools center on this. | Medium | Auto-generated wikilinks between related pages. Graph view compatibility. |
| Obsidian compatibility | The project's chosen interface. Must work seamlessly. | Low | Valid frontmatter, wikilinks, Dataview-compatible metadata, graph-friendly structure. |
| Source provenance | "Where did this claim come from?" Users of NotebookLM expect grounded answers; a wiki must do the same persistently. | Medium | Every wiki claim should trace back to source(s). This is table stakes because without it, the wiki is untrustworthy. |
| Incremental updates | Adding a new source should update existing pages, not require regenerating everything. | High | This is what makes it a "compilation" system rather than a "generation" system. Critical for the core value proposition of compounding knowledge. |
| Human-readable output | The wiki must be browseable and useful without the LLM running. Plain markdown. | Low | Already ensured by the Obsidian-first constraint. |
| Activity log | Users need to know what the system did. Every CI/CD system, every automation tool provides logs. | Low | Append-only, parseable log of all operations. |

## Differentiators

Features that set this system apart from existing tools. Not expected (because nothing does them well), but extremely valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Persistent compiled artifact** | NotebookLM re-derives answers per query. This system builds a wiki that persists and compounds. Knowledge accumulates rather than being re-derived. | High | THE core differentiator. The wiki is the product, not the chat interface. |
| **Epistemic status markers** | No competitor tracks confidence per-claim. "Sourced from 3 studies" vs "inferred from one blog post" vs "tentative, contradicted by newer source." | Medium | Per-claim markers: sourced, inferred, tentative, stale. Transforms the wiki from "AI wrote this" to "here's how trustworthy this is." |
| **Contradiction detection** | No PKM tool flags when Source A says X and Source B says Y. Humans discover contradictions manually. | High | Lint workflow that surfaces contradictions across the wiki. Requires comparing claims across pages and sources. |
| **Structured operations (UPDATE, MERGE, SUPERSEDE, ARCHIVE)** | Instead of raw file rewrites, the system has a vocabulary for knowledge evolution. Enables audit trails and reasoning about how knowledge changed. | Medium | Makes the compilation pipeline principled rather than ad-hoc. Enables "why did this page change?" |
| **Typed page schemas** | Entity pages, concept pages, source summaries, comparisons -- each with type-specific templates. No competitor has this. | Medium | Gives the wiki consistent structure. An entity page (person, tool, topic) has different sections than a comparison page or a source summary. |
| **Knowledge gap detection** | "You have 12 sources on nutrition but none on sleep, despite sleep being mentioned in 8 sources." Proactive identification of missing knowledge. | High | No competitor does this. Requires understanding the wiki's coverage and identifying holes. |
| **Staleness tracking** | Claims age. A nutrition recommendation from 2019 should be flagged differently than one from 2024. Sources have publication dates; claims inherit temporal relevance. | Medium | Freshness metadata on claims. Lint workflow flags stale claims for review. |
| **Decision records / reflection** | The system explains its own reasoning: "I merged these two pages because they covered the same concept" or "I created a comparison page because sources disagreed." | Medium | Meta-cognition about wiki structure. Enables the human to understand and override LLM decisions. |
| **Progressive disclosure** | Shallow summaries for navigation, drill-down for detail. TL;DR at top, full synthesis below, source details at bottom. | Low | Simple to implement with consistent page templates. High usability impact. |
| **Agent-agnostic schema** | Works with Claude Code, Codex, or any future agent. No lock-in. | Medium | The schema (CLAUDE.md / AGENTS.md) is the product, not any specific agent integration. |
| **Compilation pipeline (diff-based)** | New source arrives -> system computes what changed -> extracts new knowledge -> merges into existing pages -> lints for consistency. Not "regenerate everything." | High | This is what makes it a compiler rather than a generator. Analogous to incremental compilation in software. |
| **Cross-system drift detection** | Detects when the wiki, raw sources, and any external tools (Obsidian, other notes) have drifted apart. | Medium | Unique to a system that treats the wiki as a compiled artifact that should be consistent with its sources. |

## Anti-Features

Features to explicitly NOT build. These are tempting but wrong for this system.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Chat interface / conversational AI** | NotebookLM already does chat-over-sources well. Building another chat UI is undifferentiated work. The wiki IS the interface. | Use the wiki as the primary artifact. Q&A queries should compile answers back into the wiki (delta compilation), not just return ephemeral chat responses. |
| **Embedding-based RAG infrastructure** | Heavy infrastructure dependency (vector DB, embedding models, chunking strategies). The project explicitly scopes this out for v1. Index-first search is simpler and sufficient. | Use structured index files + Obsidian search + Dataview queries for v1. Semantic search is a v2 enhancement if needed. |
| **Real-time collaboration** | This is a personal system. Multi-user adds enormous complexity (conflict resolution, permissions, real-time sync) for zero value. | Single-user, local-first. Git for version history. |
| **Web application / hosted service** | Adds deployment, auth, hosting complexity. Obsidian is the interface. | File-based, local-only. Obsidian for browsing. CLI for operations. |
| **Auto-ingestion from web feeds** | Tempting but dangerous. Unfiltered ingestion creates noise. The human's curation role is essential -- it's what makes the wiki valuable, not just voluminous. | Human selects and adds sources deliberately. The LLM processes what the human curates. |
| **AI-generated "insights" / unsolicited suggestions** | "Based on your notes, you might be interested in..." is a notification-spam anti-pattern. The wiki should be a quiet, reliable artifact, not a chatty assistant. | The system processes when asked. Lint workflow surfaces issues on demand, not as push notifications. |
| **Complex permission / access control** | Local personal system. Auth is overhead with no benefit. | No auth. File system permissions are sufficient. |
| **Mobile app** | Obsidian mobile exists for reading. Building a separate mobile app is scope creep. | Use Obsidian mobile for reading the wiki. Ingest/compile operations are desktop-only. |
| **Source editing / annotation** | Raw sources should be immutable. The wiki is the compiled layer; don't mix source modification into the system. | Sources go in as-is. The wiki interprets and compiles them. If a source is wrong, add a new source that corrects it. |
| **Automatic external API calls** | Fetching live data, checking URLs, pulling updates from the web. Adds network dependencies and unpredictable behavior to a local system. | Sources are explicitly added by the human. The system works offline except for LLM API calls during compilation. |

## Feature Dependencies

```
Source Ingestion -----> Summarization
       |                     |
       v                     v
  Source Provenance --> Cross-referencing / Linking
       |                     |
       v                     v
  Epistemic Status --> Contradiction Detection
       |                     |
       v                     v
  Staleness Tracking    Knowledge Gap Detection
       
Typed Page Schemas ---> Progressive Disclosure
       |
       v
Structured Operations (UPDATE/MERGE/SUPERSEDE/ARCHIVE)
       |
       v
Compilation Pipeline (diff -> extract -> merge -> lint)
       |
       v
Decision Records / Reflection

Activity Log (independent -- supports all operations)
Index System (independent -- supports search and navigation)
Agent-agnostic Schema (foundational -- must exist before any workflow)
```

**Critical path:** Agent-agnostic Schema -> Source Ingestion -> Summarization + Provenance -> Cross-referencing -> Incremental Updates -> Lint Workflows

**Foundation layer (build first):**
1. Agent-agnostic schema (CLAUDE.md / AGENTS.md)
2. Directory structure conventions
3. Typed page schemas + templates
4. Activity log format
5. Index system

**Core compilation layer (build second):**
1. Source ingestion workflow
2. Summarization with provenance
3. Cross-referencing / auto-linking
4. Incremental update pipeline

**Quality layer (build third):**
1. Epistemic status markers
2. Contradiction detection
3. Staleness tracking
4. Knowledge gap detection
5. Decision records

## What "Knowledge Compilation" Needs That RAG Does Not

This distinction is critical for understanding the feature set:

| Capability | RAG System | Knowledge Compilation System |
|------------|-----------|------------------------------|
| **Persistence** | Ephemeral answers per query | Persistent wiki pages that accumulate knowledge |
| **Synthesis** | Retrieves relevant chunks, generates answer | Merges knowledge from multiple sources into coherent pages |
| **Contradiction handling** | May retrieve contradicting chunks, LLM improvises | Explicitly detects and flags contradictions |
| **Knowledge evolution** | Re-derives from scratch each time | Tracks how knowledge changed over time (SUPERSEDE, ARCHIVE) |
| **Provenance** | "Based on your documents" (vague) | Claim-level attribution to specific sources |
| **Confidence** | Binary (retrieved or not) | Graduated (sourced, inferred, tentative, stale) |
| **Structure** | Flat document chunks | Typed pages with schemas (entity, concept, comparison) |
| **Maintenance** | None needed (re-derive on query) | Active: lint, detect drift, flag staleness |
| **Offline value** | Zero (needs LLM to answer) | Full (wiki is readable markdown) |
| **Compounding** | Each query starts fresh | Each source enriches existing pages |

The compilation features (incremental updates, structured operations, lint workflows, epistemic status) are what transform this from "AI that answers questions about your files" into "AI that maintains a knowledge base."

## MVP Recommendation

**Phase 1 -- Foundation (must have to be usable at all):**
1. Agent-agnostic schema with all conventions documented
2. Directory structure (raw sources, wiki pages, index, log)
3. Typed page templates (entity, concept, source summary, comparison)
4. Source ingestion workflow with basic provenance
5. Index and log system
6. Example wiki pages demonstrating all conventions

**Phase 2 -- Core Compilation (the differentiating value):**
1. Cross-referencing / auto-linking between pages
2. Incremental updates (new source updates existing pages)
3. Structured operations vocabulary (UPDATE, MERGE, SUPERSEDE, ARCHIVE)
4. Basic lint workflow (orphan pages, missing cross-references)

**Phase 3 -- Quality and Trust:**
1. Epistemic status markers per claim
2. Contradiction detection
3. Staleness tracking
4. Knowledge gap detection
5. Decision records

**Defer to v2 (future software tool):**
- Automated compilation pipeline (CLI that orchestrates ingest -> compile -> lint)
- Semantic search / embeddings
- Cross-system drift detection
- Advanced lint rules

## Sources

- NotebookLM feature analysis: based on training data (MEDIUM confidence -- product evolves rapidly)
- Khoj, Quivr feature analysis: based on training data through early 2025 (MEDIUM confidence)
- Obsidian plugin ecosystem: based on training data (MEDIUM confidence -- plugins change frequently)
- Mem.ai features: based on training data (LOW confidence -- may have changed significantly)
- "Knowledge compilation" vs RAG distinction: synthesis from first principles based on PROJECT.md requirements and general knowledge of RAG systems (HIGH confidence for the conceptual framework)
- Feature categorization: based on analysis of PROJECT.md requirements against competitive landscape (HIGH confidence)

**Note:** Web search was unavailable during this research session. Feature lists for specific competitors (especially NotebookLM, which iterates rapidly) should be validated against current product pages before finalizing the roadmap.
