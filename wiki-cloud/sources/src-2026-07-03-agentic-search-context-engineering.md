---
id: src-2026-07-03-agentic-search-context-engineering
title: "Agentic Search for Context Engineering — Leonie Monigatti, Elastic"
type: source
status: active
summary: "A conference workshop by Leonie Monigatti (Elastic) arguing that context
  engineering is mostly a search problem — 'about 80% agentic search' — tracing RAG →
  agentic RAG → agentic search over many context sources, walking four search interfaces
  (semantic search, general-purpose ES|QL query tool, shell/bash tool, semantic-grep CLIs)
  through live code demos, and recommending a curated low-floor/high-ceiling tool stack."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- agentic-search
- context-engineering
- retrieval
- rag
- agent-tools
- youtube-transcript
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Agentic Search for Context Engineering"
- "src-2026-07-03-agentic-search-context-engineering"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-agentic-search-context-engineering.md
url: "https://www.youtube.com/watch?v=ynJyIKwjonM"
content_hash: "sha256:f1a4e2c2fc4d89167aaf6f531b72397710c79bc35e5e41a3c3513e72f935bbd0"
ingested_at: 2026-07-03
source_type: transcript
channel: "AI Engineer"
publish_date: 2026-05-08
duration: "1:03:12"
extraction_tool: stt
extraction_model: "faster-whisper large-v3 (English); speaker diarization unavailable (TorchCodec missing)"
extraction_date: 2026-07-03
compilation_status: compiled
compiled_against_hash: "sha256:f1a4e2c2fc4d89167aaf6f531b72397710c79bc35e5e41a3c3513e72f935bbd0"
compiled_targets:
- agentic-search
- context-engineering
- progressive-disclosure
- agent-skills
- elastic
- leonie-monigatti
---

# Agentic Search for Context Engineering — Leonie Monigatti, Elastic

## TL;DR

A workshop-style talk by [[leonie-monigatti|Leonie Monigatti]] of [[elastic|Elastic]] at the AI Engineer conference, making the case that [[context-engineering|Context Engineering]] is mostly a *search* problem — her hot take is that it is "about 80% agentic search," because the under-credited arrow from context sources into the context window is powered by search tools. She traces the three-year arc from fixed-pipeline RAG → agentic RAG → [[agentic-search|Agentic Search]] over many context sources (local files, working memory, agent skills, databases, the web, long-term memory), enumerates the search interfaces each source needs, and highlights the shell/bash tool as a strikingly versatile universal interface. After laying out three failure modes and the primacy of tool descriptions and parameter design, she runs four live LangChain demos over conference-session data — a semantic-search tool, a general-purpose ES|QL query tool (fixed with an agent skill), the shell tool over a local file system, and a semantic-grep CLI — and closes with a practical recommendation: no silver-bullet tool; curate a set that combines low-floor specialized tools with high-ceiling general-purpose tools.

## Key Takeaways

- Monigatti's central thesis is that context engineering is "about 80% agentic search": the arrow that moves content from context sources into the context window is powered by search tools, and that choice often matters more than the model [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:09-00:02:21|direct|2026-07-03] [epistemic:: tentative]
- The field evolved from fixed-pipeline RAG (retrieve once, whether needed or not) to agentic RAG (an agent decides *whether* to call a search tool and *whether to search again*), which then generalizes to agentic search across many context sources [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:29-00:04:15|direct|2026-07-03]
- The shell/bash tool (LangChain's "shell tool," Anthropic's "bash tool," OpenClaw's "exec tool") is an unusually versatile search interface: it lets the agent run `ls`/`grep`, drive database CLIs, `curl` HTTP endpoints, and write ad-hoc scripts — one tool that reaches many context sources [prov:src-2026-07-03-agentic-search-context-engineering#t00:06:27-00:07:50|direct|2026-07-03] [epistemic:: tentative]
- Good search is genuinely hard, so a single "silver-bullet" tool is the wrong goal; the recommendation is to curate a stack combining *specialized* tools (low floor — usable out of the box, simple parameters, efficient) with *general-purpose* tools (high ceiling — handle complex/unexpected queries but may need more iterations) [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03]
- When a general-purpose tool trips the agent up (e.g. writing an entire ES|QL query), an agent skill loaded via progressive disclosure can supply just-in-time syntax documentation and fix parameter generation — better than piling per-error "band-aids" into the system prompt [prov:src-2026-07-03-agentic-search-context-engineering#t00:28:17-00:32:38|direct|2026-07-03] [epistemic:: tentative]

## Extracted Claims

### Thesis: context engineering is mostly agentic search

- Context engineering is the art/engineering of deciding, out of all possible context sources, what goes into the context window so the LLM can generate the best response [prov:src-2026-07-03-agentic-search-context-engineering#t00:01:20-00:01:39|direct|2026-07-03]
- The commonly-drawn "context curation" arrow from context sources to the context window is under-credited: what powers that arrow is the search tool (or tools) that decide what actually moves across [prov:src-2026-07-03-agentic-search-context-engineering#t00:01:39-00:02:09|direct|2026-07-03]
- Monigatti's personal "hot take": context engineering is about 80% agentic search [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:09-00:02:21|direct|2026-07-03] [epistemic:: tentative]

### From RAG to agentic RAG to agentic search

- The original RAG design was a fixed retrieval pipeline: the user message (more or less verbatim) becomes a vector-search query that pulls chunks from a database, and the chunks plus the message go into the context window and then to the LLM [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:29-00:03:01|direct|2026-07-03]
- A fixed pipeline has two limitations: it retrieves whether or not context is needed (which can confuse the LLM), and it retrieves only once, which fails multi-hop questions where the first results reveal that a second search is needed [prov:src-2026-07-03-agentic-search-context-engineering#t00:03:03-00:03:42|direct|2026-07-03]
- Agentic RAG replaces the fixed pipeline with a search *tool* the agent decides whether to call, so the agent can judge whether it needs information, whether the retrieved chunks are relevant, and whether to retrieve again or rewrite the query [prov:src-2026-07-03-agentic-search-context-engineering#t00:03:42-00:04:15|direct|2026-07-03]

### The multi-source context landscape

- In real context engineering the context lives in many places: local files (e.g. a coding agent's project files), working memory (a scratchpad / `plan.md`), agent skills (usually a local folder), databases (enterprise data), the web, and long-term memory (whose storage location she flags as an active, unsettled debate) [prov:src-2026-07-03-agentic-search-context-engineering#t00:04:31-00:05:39|direct|2026-07-03] [epistemic:: tentative]
- Each source tends to have its own native search tool: a file-search tool for local files, a skill-loading tool for skills, a semantic-search tool (or a more general SQL-style query tool) for databases, a web-search tool for the web, and a dedicated memory tool for long-term memory [prov:src-2026-07-03-agentic-search-context-engineering#t00:05:44-00:06:33|direct|2026-07-03]

### The shell/bash tool as a universal search interface

- The same "run commands in the terminal" tool goes by different names across ecosystems — LangChain's "shell tool," Anthropic's "bash tool," and OpenClaw's "exec tool" — and its terminal access makes it very versatile [prov:src-2026-07-03-agentic-search-context-engineering#t00:06:27-00:06:51|direct|2026-07-03] [epistemic:: tentative]
- Through a shell tool an agent can `ls`/`grep` the local file system, drive a database's custom CLI, write a from-scratch script to connect and query a database, `curl` an HTTPS-exposed database, and even run web searches via `curl` — one general interface reaching many context sources [prov:src-2026-07-03-agentic-search-context-engineering#t00:06:51-00:07:50|direct|2026-07-03]
- The core "take-home" is that doing good search is incredibly difficult, which is why there are many techniques — vector search, keyword search, and within vector search dense, sparse, and multi-vector embeddings, plus many indexing techniques — so teams must curate their own stack of search tools to fit their search and latency requirements [prov:src-2026-07-03-agentic-search-context-engineering#t00:08:04-00:08:43|direct|2026-07-03]

### Fundamentals: failure modes, tool descriptions, parameter design

- Three common agentic-search failure modes: (1) the agent calls no tool at all and answers from parametric knowledge; (2) the agent calls the wrong tool; and (3) the agent generates the wrong search parameters [prov:src-2026-07-03-agentic-search-context-engineering#t00:09:38-00:10:34|direct|2026-07-03]
- The tool description is the single most important lever for correct tool selection, yet it is usually given the least effort (one throwaway sentence); build it up as needed — start from a core purpose, add trigger conditions (when to use / when not to use), add relationships (e.g. "first call this skill / get confirmation before using this tool"), and if the agent still misfires, reinforce the guidance in the system prompt [prov:src-2026-07-03-agentic-search-context-engineering#t00:10:40-00:11:57|direct|2026-07-03]
- Parameter complexity is itself a failure mode along a gradient: simple parameters (e.g. `get_customer_by_id`, or a semantic-search string) are easy for the agent; adding filters and a `top_k` makes it harder; and asking the agent to write an entire ES|QL/SQL query from scratch is hardest [prov:src-2026-07-03-agentic-search-context-engineering#t00:11:57-00:13:34|direct|2026-07-03] [epistemic:: tentative]

### Demo 1 — semantic search, and where it breaks

- The demos use LangChain over a local Elasticsearch cluster of conference-session data; the first tool is a semantic-search tool built from a Jina embeddings v5 model and a `similarity_search` call limited to `top_k` = 3, and LangChain's `@tool` decorator turns a Python function into an agent tool (function name → tool name, docstring → tool description) [prov:src-2026-07-03-agentic-search-context-engineering#t00:16:01-00:19:28|direct|2026-07-03] [epistemic:: tentative]
- The semantic-search tool works for a semantic query ("regulatory constraints") but breaks on a specific keyword ("GEPA"): semantic search returns unrelated results (a DeepMind Gemma talk, a harness-engineering talk) because the term is not semantically retrievable and the tool exposes no keyword filter — showing a single semantic tool is useful only for a narrow scope [prov:src-2026-07-03-agentic-search-context-engineering#t00:21:56-00:23:19|direct|2026-07-03] [epistemic:: tentative]

### Demo 2 — a general-purpose ES|QL tool, fixed with an agent skill

- Replacing the fixed semantic tool with a general-purpose "execute query" tool lets the agent write an entire ES|QL query (Elastic's piped query language); she switches to a more powerful model (GPT 5.4 mini rather than nano) and wraps the tool in a try/except so a bad query returns the error to the agent, letting it self-correct rather than crashing the system [prov:src-2026-07-03-agentic-search-context-engineering#t00:23:35-00:26:50|direct|2026-07-03] [epistemic:: tentative]
- The general-purpose tool's first attempt fails because the agent uses SQL's `%` wildcard instead of ES|QL's `*`, so it searches for a literal `%GPA%` and returns zero results — prompting the design question of whether zero results is a valid answer or a failure mode [prov:src-2026-07-03-agentic-search-context-engineering#t00:27:05-00:28:02|direct|2026-07-03] [epistemic:: tentative]
- The fix is an agent skill loaded by progressive disclosure: only the skill's name and description are injected into the system prompt, and the body (basic ES|QL syntax rules, including the correct wildcard) is loaded into the context window when needed; the tool description then gets a relationship ("always use the Elasticsearch ES|QL skill to generate the query before using this tool"), reinforced in the system prompt, after which the agent produces valid ES|QL and finds the right session [prov:src-2026-07-03-agentic-search-context-engineering#t00:28:17-00:32:38|direct|2026-07-03] [epistemic:: tentative]
- The general-purpose tool also enables aggregations: asked how many sessions are on April 8th, the agent writes an ES|QL filter-plus-count query and returns 27 — outsourcing the calculation to the search tool, which is more efficient than listing all rows because LLMs are notoriously bad at counting and the full list would fill the context window [prov:src-2026-07-03-agentic-search-context-engineering#t00:32:52-00:34:24|direct|2026-07-03] [epistemic:: tentative]

### Demo 3 — the shell tool over a local file system, and semantic grep

- Over a local file system (session data laid out as per-type folders with one file per session), the shell tool with GPT 5.4 nano lets the agent `ls` and `grep` to find and read the right session file — but the shell tool is risky (it can delete files), so she recommends running it in a sandbox and notes LangChain's shell tool ships with no safeguards by default [prov:src-2026-07-03-agentic-search-context-engineering#t00:34:42-00:39:01|direct|2026-07-03] [epistemic:: tentative]
- Agents can "cheat at semantic search" with bash: for "regulatory constraints" the agent chains a bunch of synonyms into `grep` (regulation, compliance, GDPR, governance, constraints…) and succeeds — it works, but chaining synonyms is not an efficient way to do semantic retrieval [prov:src-2026-07-03-agentic-search-context-engineering#t00:39:01-00:41:23|direct|2026-07-03]
- Semantic-grep CLIs close that gap as drop-in `grep` alternatives — LlamaIndex's "semtools," LightOn's colBERT/multi-vector "colgrep," and Jina's "ginagrep" (jina grep); telling the agent it has the Jina grep CLI and when to prefer it (semantic/fuzzy queries) versus plain `grep` (exact matches) lets it retrieve the right session on the first try with `top_k` = 10 [prov:src-2026-07-03-agentic-search-context-engineering#t00:41:26-00:44:00|direct|2026-07-03] [epistemic:: tentative]

### Practical recommendations

- There is no single silver-bullet search tool; because good search is hard, you should curate the right *set* of tools for your agent's search behaviors, combining specialized tools (a "low floor" — usable out of the box, simple parameters, efficient, no need for a powerful LLM) with general-purpose tools (a "high ceiling" — able to handle unexpected or complex queries, at the cost of sometimes needing more iterations); "low floor / high ceiling" is borrowed from user-experience design [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03]
- If you don't yet know your agent's query behavior, start with a general-purpose tool and log the agent's behavior; ~4–5 tool calls per question is a signal the tool is too hard to use, at which point you scope out a more specialized tool — she did exactly this with OpenClaw's exec tool, logging its database interactions for three days and then asking it what patterns it saw, whereupon it recommended implementing specific database search tools [prov:src-2026-07-03-agentic-search-context-engineering#t00:47:13-00:48:46|direct|2026-07-03] [epistemic:: tentative]

### Q&A

- On model strength: Elastic's internal testing found that a more powerful model substantially reduces the parameter-error rate for general-purpose tools, but a strong model still does not guarantee zero errors [prov:src-2026-07-03-agentic-search-context-engineering#t00:49:20-00:50:09|direct|2026-07-03] [epistemic:: tentative]
- On latency: agentic RAG costs more latency than simple RAG, and Monigatti has no clean recipe for routing between a fast simple-RAG path and an agentic path (the routing itself would need agentic logic); she stresses that RAG, though "killed many times," remains very effective for many use cases [prov:src-2026-07-03-agentic-search-context-engineering#t00:50:20-00:51:52|direct|2026-07-03]
- On patching errors: you *can* fix the wildcard mistake with a one-line system-prompt instruction (it worked in her demo), but per-error "band-aids" accumulate and don't generalize to the next edge case, so they are not how you'd build something robust [prov:src-2026-07-03-agentic-search-context-engineering#t00:52:16-00:54:24|direct|2026-07-03]
- On hybrid tools: she cites a Vercel blog post ("is bash all you need") that benchmarked a bash-tool agent, a file-search-tool agent, and a database-tool agent, and found the hybrid bash-plus-database agent achieved the highest accuracy on analytical queries by using the database tool first and then verifying the results with the shell tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:54:36-00:56:51|direct|2026-07-03] [epistemic:: tentative]
- On retrieval thresholds: modern agents reason over relevance and are much better at weeding out irrelevant search results, so a hard similarity threshold is less necessary — but in long-running conversations irrelevant retrieved results linger in the context window and can confuse the agent over time [prov:src-2026-07-03-agentic-search-context-engineering#t00:57:04-00:58:41|direct|2026-07-03]
- On subagents: Monigatti has not used subagents for search herself, but notes that Claude Code reportedly uses a subagent to answer niche questions about itself, outsourcing that specific expertise [prov:src-2026-07-03-agentic-search-context-engineering#t00:58:58-00:59:57|direct|2026-07-03] [epistemic:: tentative]
- On evicting loaded skills (answered by her Elastic colleague Joe): Elastic implements progressive disclosure of skills — exposing skill names, descriptions, and their location in a file store, loading a skill into the context window when needed and offloading it as the context progresses, applying the same approach to compaction, and generally advising teams to lean on the file store (including for retrieving previous tool results) rather than keeping everything resident [prov:src-2026-07-03-agentic-search-context-engineering#t01:00:26-01:02:25|direct|2026-07-03] [epistemic:: tentative]

## Notes

**Validity assessment:**

- The audio is clean, single-speaker conference-stage spoken word, so the page is graded `sourced`; per-claim `[epistemic:: tentative]` hedges are applied across the STT failure surface (proper nouns, product/tool names, model versions, and numbers), per the video-ingestion tiered-epistemic policy.
- Named entities are the main transcription risk and several were mended from context: **Jina** (the embeddings vendor and its "jina grep"/`ginagrep` CLI) is rendered "Gina"/"Gina grab"/"Gina Grap" by the STT and even in the video's own chapter titles; **GEPA** (the prompt-optimization method the speaker herself is unsure how to pronounce, also comparing it to JEPA) is rendered "GPA" throughout; **LightOn**'s "colgrep" and **LlamaIndex**'s "semtools" are as-heard; and the audience-speaker name "Bilge/Birgit" is inconsistent in the audio. Treat all of these as tentative.
- Model names ("GPT 5.4 nano"/"GPT 5.4 mini") and numeric details (the "80%" hot take, `top_k` = 3 and 10, the 27-session count, "last three years") are recorded as spoken and hedged tentative — STT can mangle version numbers and figures.
- **Speaker labels:** automatic diarization did not run (the pipeline's TorchCodec dependency was missing), so the committed raw transcript carries no `SPEAKER:` labels. The main talk (through 0:49:16) is single-speaker, so labels are not required there; in the Q&A, audience questions, Monigatti's answers, and one answer from her Elastic colleague Joe are attributed inline in the claims above from content, not from diarization.
- One relationship is stated hedged: Monigatti refers to Jina as "our own" when introducing its grep CLI, which suggests an Elastic–Jina relationship, but the talk does not state one explicitly, so no such relationship is asserted as fact on the [[elastic|Elastic]] page.

## Source Metadata

- **Speaker:** Leonie Monigatti (Elastic)
- **Channel:** AI Engineer
- **Publication:** YouTube
- **URL:** https://www.youtube.com/watch?v=ynJyIKwjonM
- **Publish date:** 2026-05-08
- **Duration:** 1:03:12
- **Workshop repo:** https://github.com/iamleonie/workshop-agentic-search
- **Source type:** transcript (video sub-case)
- **Path:** `sources/2026/2026-07/2026-07-03-agentic-search-context-engineering.md`

The video fields (title, channel, publish date, duration) were sourced from the `yt-dlp`
metadata pulled during acquisition. The committed transcript is the durable record; the `url`
is a courtesy pointer that may rot.
