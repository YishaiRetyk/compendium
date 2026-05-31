# Neo4j Graph Tools vs Compendium — Comparison & Transferable Ideas

Captured 2026-05-31 from exploring two Neo4j Labs repos cloned to `/tmp` and
comparing them against compendium:

- `neo4j-labs/llm-graph-builder` — document → Neo4j knowledge-graph pipeline (FastAPI + React + LangChain + GDS). A GraphRAG product.
- `neo4j-labs/create-context-graph` — interactive scaffolder (`create-react-app`-style) that generates domain-specific agent apps; ships `neo4j-agent-memory` (NAMS) as the durable-memory layer.

**Framing.** Both share compendium's one-liner (compile sources into structured, queryable knowledge instead of re-deriving per query) but invert the architecture: they are **retrieval-optimized graph DBs** (machine-traversed, query-time GraphRAG); compendium is **reading-optimized curated markdown** (human-legible, synthesis-already-written, provenance-rich). Most of their bulk (Neo4j, embeddings, full-stack codegen, SaaS connectors) is orthogonal to a markdown-first wiki. The value is in a handful of *mechanisms* worth porting at compendium's altitude. This note is the lineage; actionable items are spun into seeds (see Disposition).

This note is exploratory substance, not a shipped surface (cf. `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md`). Promote into seeds / decision records / phase design notes as triggers fire.

---

## llm-graph-builder — six transferable learnings

### 1. Claim-faithfulness evaluation → arms Phase 13
**Source:** `backend/src/ragas_eval.py:45` (ragas `faithfulness`), `:78-87` (RougeScore + SemanticSimilarity vs reference).
**Algorithm:** decompose answer into atomic claims → per-claim entailment vs cited context → score = supported/total. Plus `context_entity_recall` (did the claim capture/invent entities?).
**Transfer:** the algorithm for `bin/audit-claims.sh`. For each sampled claim: extract cited passage via locator → LLM verdict ∈ {supports, weak, contradicts, insufficient} → review-only report. Steal specifically: (a) the **decomposition step** (atomic sub-claims catch partial-support; aligns with §10 Pass 2 "bias toward atomic"); (b) **faithfulness score per page logged over time** as a drift signal.
**Caution = design requirement:** verification needs a *mechanically bounded* passage. compendium locators (`#sec:`, `#para3`, `#p8`) are coarser than graph-builder's chunk `content_offset` (exact char range, `backend/src/make_relationships.py:79`). Page locators on markdown-native sources can't bound a passage → must degrade to an explicit `insufficient-locator` verdict, not silently audit the whole doc.
**Disposition:** ✅ filed in `phases/13-claim-faithfulness-audit/13-DESIGN-NOTES.md`.

### 2. Near-duplicate detection → MERGE candidates (compendium's weakest heuristic)
**Source:** `backend/src/graphDB_dataAccess.py:410` `get_duplicate_nodes_list`.
**Mechanism:** flag same-type pairs when ANY of — substring containment, `apoc.text.distance` (edit distance) **< 3** for ids >5 chars (`DUPLICATE_TEXT_DISTANCE`), or `vector.similarity.cosine > 0.97` (`DUPLICATE_SCORE_VALUE`). Touches: same-label-only (`:421`), order candidates by node **degree** to pick the canonical survivor (`:416`), subset-removal of clusters (`:433-440`), and human-confirms-before-merge (`get_duplicate_nodes_list` proposes; `merge_duplicate_nodes` only on confirm).
**Transfer:** compendium has NO duplicate-page detector — `Attention Mechanism` vs `Attention Mechanisms`, `Geoff Hinton` vs `Geoffrey Hinton` silently coexist. A new lint check (`category: duplicate`, warning, report-only) using the two **embedding-free** heuristics (title/alias substring + edit-distance<3) feeds the existing `MERGE` op (§9). same-label → same-`type`; order-by-degree → survivor = more inbound wikilinks. Dependency-free win.
**Disposition:** → seed `wiki-quality-heuristics.md`.

### 3. LLM-driven label/relationship consolidation → tag/domain sprawl control
**Source:** `backend/src/post_processing.py:151` `graph_schema_consolidation` + `GRAPH_CLEANUP_PROMPT`.
**Mechanism:** hand the full label/relationship vocabulary to an LLM → get a canonicalization map ("Organisation"→"Company") → rewrite graph, log "Total=N, Reduced to=M."
**Transfer:** compendium's `tags`/`domains` are free-form with no canonicalization — sprawl (`agent-skills`/`agent-skill`/`skills`, `ai-agents`/`autonomous-agents`) is inevitable past Tier 1. A reflect-tier (or lint `info`) check surfaces near-synonym tags/domains and proposes a consolidation map, applied via a logged decision record.
**Disposition:** → seed `wiki-quality-heuristics.md`.

### 4. Hierarchical community detection + summarization → smarter overview pages
**Source:** `backend/src/communities.py` — Leiden (`:236`), level hierarchy (`:47`), rank by distinct-doc-count (`community_rank`, `:66-67`), bottom-up LLM title+summary (`COMMUNITY_SYSTEM_TEMPLATE :116`, `PARENT_COMMUNITY_SYSTEM_TEMPLATE :130`).
**Transfer (two ideas):** (a) **cluster-detection as `info` lint** — find densely interlinked page clusters lacking an `overview` page and suggest one; flag overviews whose members changed since the overview's `updated_at` (stale-synthesis signal). Inverse of §14's "split pages too large." (b) **connectivity ranking** — rank pages by inbound-wikilink count as a cheap importance signal; high-fanout pages are exactly Phase 13's "high-risk claims" sampling target.
**Disposition:** cluster-detection → seed `wiki-quality-heuristics.md`; connectivity ranking → ✅ already in `13-DESIGN-NOTES.md` (FAITH-01 selector).

### 5. Embeddings as an optional derived index → semantic missing-link & dedup
**Source:** entity embeddings = `id + " " + description` (`backend/src/post_processing.py:134`); `SIMILAR` edges above `KNN_MIN_SCORE = 0.8` (`graphDB_dataAccess.py:157`); cosine index powers retrieval + the 0.97 dedup.
**Transfer:** compendium's missing-cross-reference check is purely lexical (shared tags/domains) — conceptually-adjacent pages sharing no tags are invisible. A `bin/`-computed embedding index (markdown stays source of truth; index regenerable) enables "semantically near but unlinked → suggest cross-ref" and strengthens the #2 dedup check. This is the natural content of §14 Tier 4's SQLite/derived layer.
**Privacy constraint (non-negotiable, §13):** `local_only` pages must NEVER hit a cloud embedding API → route them through a local model (graph-builder uses `sentence-transformers`/HuggingFace locally). Gate behind local-model availability; not a default.
**Disposition:** → seed `wiki-quality-heuristics.md` as a Tier-4-gated extension.

### 6. Explicit local-vs-global retrieval routing → query workflow framing
**Source:** chat-mode spectrum `backend/src/shared/constants.py:708` — `vector` (local) … `global_vector` (GraphRAG global: map-reduce over community summaries), default `graph_vector_fulltext`.
**Transfer:** §11.2 query workflow has one (inherently *local*) retrieval path (index → TL;DR → Key Facts → Detail). Broad "what are the themes?" questions are better served by reading `overview` page TL;DRs (a *global* layer) than deep-reading many entity pages. Cheap refinement: classify question local-vs-global; for global, read overview TL;DRs first. No new deps.
**Disposition:** lightest item; noted in seed `wiki-quality-heuristics.md` as a query-workflow refinement (may not need a full phase).

---

## create-context-graph — three additional learnings

### 7. LLM-generated ontology from plain-English domain → greenfield wizard enhancement (net-new)
**Source:** `src/create_context_graph/custom_domain.py`. `--custom-domain "veterinary clinic management"` → LLM generates a *complete, validated* ontology (entity types, relationships, doc templates, agent tools, system prompt) behind a **3-retry validation loop** (truncation / schema-parse / completeness checks: ≥3 entity types, system prompt present, …).
**Transfer:** beyond compendium's `init-wizard.sh` (which prompts for a domain and fills `AGENTS.template.md` placeholders). Let the LLM *draft a starter knowledge scaffold* from a plain-English description — suggested `domains`/`tags` vocabulary, `knowledge_domain` decay-bucket assignments, candidate entity/concept page stubs — behind the same completeness-validation loop, human-confirmed. "Describe it in English → LLM drafts the conventions," applied to frontmatter/taxonomy. New vs llm-graph-builder (pre-baked schemas).
**Disposition:** → seed `llm-drafted-domain-scaffold.md`.

### 8. `ccg-edges` block → validates the "typed edges as data" idea
**Source:** NAMS REST lacks `add_relationship`, so typed relationships are encoded as a fenced YAML block embedded in the entity's description:
```
```ccg-edges
- type: DIAGNOSED_WITH
  target: Pneumonia
  target_label: Diagnosis
```
```
**Transfer:** a real-world reference syntax for the "typed-relationship layer beyond prose wikilinks" idea — a fenced block in the page body, parsed by lint, graph-queryable, without leaving markdown. They independently landed on "embed a structured edge block in the entity body."
**Disposition:** ✅ referenced in `seeds/agent-memory-interface.md`; deeper typed-relations work would be its own future seed.

### 9. NAMS = inverse of compendium's durable-memory thesis (philosophical mirror)
**Detail:** `neo4j-agent-memory` is the closest sibling to compendium's "knowledge compounds across sessions" claim — but **automatic** (NLP entity extraction from every conversation turn, graph grows silently, agent-maintained, machine-queried) vs compendium's **curated** (human sources, LLM compiles with provenance/contradictions/decision records, human-legible markdown). Automatic optimizes recall throughput; curated optimizes fidelity and auditability.
**Disposition:** → one subsection in `agentic-gtd-system-with-wiki-compiler.md` ("Personal Assistant Memory" section); it's a competing memory layer for exactly that doc's agent stack.

---

## Disposition summary

| Idea | Home |
|------|------|
| #1 faithfulness, #4 connectivity ranking, locator precision | ✅ `phases/13-…/13-DESIGN-NOTES.md` |
| Agent-memory interface, #8 typed-edges | ✅ `seeds/agent-memory-interface.md` |
| #2 dedup, #3 tag/domain consolidation, #4 cluster/overview, #5 embedding index, #6 local/global routing | `seeds/wiki-quality-heuristics.md` |
| #7 LLM-drafted domain scaffold | `seeds/llm-drafted-domain-scaffold.md` |
| #9 NAMS automatic-vs-curated contrast | `agentic-gtd-system-with-wiki-compiler.md` |

## Reference clones (ephemeral)
- `/tmp/llm-graph-builder` (~30 MB), `/tmp/create-context-graph` (~23 MB) — cloned 2026-05-31 for this comparison. Not committed; re-clone from `github.com/neo4j-labs/{llm-graph-builder,create-context-graph}` if needed.
