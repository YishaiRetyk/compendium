---
id: agentic-search
title: "Agentic Search"
type: concept
status: active
summary: "Retrieval in which an agent decides at run time which search tool to call, with
  what parameters, and whether to search again — the evolution from fixed-pipeline RAG through
  agentic RAG to search across many context sources (files, databases, memory, the web). Framed
  by Leonie Monigatti (Elastic) as the mechanism that does most of the work of context
  engineering ('about 80% agentic search'), delivered through a curated stack of low-floor
  specialized tools and high-ceiling general-purpose tools (semantic search, query languages,
  the shell/bash tool, and semantic-grep CLIs)."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-agentic-search-context-engineering
epistemic_status: sourced
tags:
- agentic-search
- context-engineering
- retrieval
- rag
- agent-tools
- search
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Agentic Search"
- "Agentic Retrieval"
- "agentic-search"
has_contradictions: false
knowledge_domain: software
example: false
---

# Agentic Search

## TL;DR

Agentic search is retrieval driven by the agent itself: rather than a fixed pipeline that always runs one query, the agent decides *at run time* which search tool to call, with what parameters, whether the results are relevant, and whether to search again. It is the mechanism underneath [[context-engineering|Context Engineering]] — [[leonie-monigatti|Leonie Monigatti]] of [[elastic|Elastic]] frames context engineering as "about 80% agentic search," because the under-credited arrow that moves content from context sources into the context window is powered by search tools. The lineage runs from fixed-pipeline RAG → agentic RAG (an agent that chooses whether and when to retrieve) → agentic search over many context sources (local files, working memory, [[agent-skills|Agent Skills]], databases, the web, long-term memory). Because good search is genuinely hard, there is no silver-bullet tool: the practical discipline is curating a stack that pairs *low-floor* specialized tools (simple, efficient, usable out of the box) with *high-ceiling* general-purpose tools (a query-language tool or the shell/bash tool that can handle anything but may need more iterations), and getting tool descriptions and parameter design right so the agent picks the right tool and calls it correctly.

## Key Facts

- Agentic search replaces RAG's fixed retrieval pipeline with a search *tool* the agent decides whether to call — so the agent judges whether it needs context, whether the retrieved chunks are relevant, and whether to retrieve again or rewrite the query [prov:src-2026-07-03-agentic-search-context-engineering#t00:03:42-00:04:15|direct|2026-07-03] [epistemic:: sourced]
- The motivating limitation of fixed-pipeline RAG is that it retrieves whether or not context is needed (which can confuse the LLM) and retrieves only once, failing multi-hop questions where the first results reveal that a second search is needed [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:29-00:03:42|direct|2026-07-03] [epistemic:: sourced]
- Monigatti's thesis is that context engineering is "about 80% agentic search": the arrow from context sources into the context window is powered by search tools, and that choice often matters more than the model [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:09-00:02:21|direct|2026-07-03] [epistemic:: tentative]
- Real agentic search spans many context sources — local files, working memory (a scratchpad / `plan.md`), agent skills, databases, the web, and long-term memory — each with its own native search tool (file search, skill loading, semantic search / SQL-style query, web search, memory) [prov:src-2026-07-03-agentic-search-context-engineering#t00:04:31-00:06:33|direct|2026-07-03] [epistemic:: sourced]
- The shell/bash tool is a uniquely versatile search interface — LangChain's "shell tool," Anthropic's "bash tool," OpenClaw's "exec tool" — letting the agent `ls`/`grep` files, drive database CLIs, `curl` HTTP endpoints, and write ad-hoc scripts, reaching many context sources through one tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:06:27-00:07:50|direct|2026-07-03] [epistemic:: tentative]
- Three recurring failure modes: the agent calls no tool and answers from parametric knowledge; the agent calls the wrong tool; or the agent generates the wrong search parameters [prov:src-2026-07-03-agentic-search-context-engineering#t00:09:38-00:10:34|direct|2026-07-03] [epistemic:: sourced]
- The tool description is the most important lever for correct tool selection: start from a core purpose, then add trigger conditions (when to use / not use), then relationships (e.g. "call this skill first"), then reinforce in the system prompt if the agent still misfires [prov:src-2026-07-03-agentic-search-context-engineering#t00:10:40-00:11:57|direct|2026-07-03] [epistemic:: sourced]
- Parameter complexity is a failure gradient: simple parameters (an ID, a semantic-search string) are easy; adding filters and `top_k` is harder; asking the agent to write an entire query-language statement from scratch is hardest [prov:src-2026-07-03-agentic-search-context-engineering#t00:11:57-00:13:34|direct|2026-07-03] [epistemic:: tentative]
- Pure semantic search fails on specific keywords: a `top_k`-limited semantic tool with no keyword filter returns unrelated results for a term like "GEPA," which is useful only for a narrow scope of queries [prov:src-2026-07-03-agentic-search-context-engineering#t00:21:56-00:23:19|direct|2026-07-03] [epistemic:: tentative]
- Agents can "cheat at semantic search" with the shell tool by chaining synonyms into `grep` (regulation, compliance, GDPR, governance…) — it works but is inefficient, which is why semantic-grep CLIs (LlamaIndex `semtools`, LightOn's colBERT-based `colgrep`, Jina's `ginagrep`) exist as drop-in `grep` alternatives [prov:src-2026-07-03-agentic-search-context-engineering#t00:39:01-00:44:00|direct|2026-07-03] [epistemic:: tentative]
- No silver-bullet tool exists; curate a stack combining *specialized* tools (a "low floor" — simple parameters, efficient, no powerful LLM needed) with *general-purpose* tools (a "high ceiling" — handle complex or unexpected queries at the cost of more iterations), a framing borrowed from UX design [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03] [epistemic:: sourced]
- When the agent's query behavior is unknown, start with a general-purpose tool and log behavior: ~4–5 tool calls per question signals the tool is too hard, and you then scope out a more specialized tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:47:13-00:48:46|direct|2026-07-03] [epistemic:: tentative]

## Detail

Agentic search names the shift from *retrieval as a fixed step* to *retrieval as a decision the agent makes*. In the original RAG design, the user message became a vector-search query more or less verbatim, pulled a fixed set of chunks, and both went into the context window — regardless of whether any retrieval was warranted, and with no chance to retrieve a second time when the first results hinted at a follow-up query [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:29-00:03:42|direct|2026-07-03]. Agentic RAG hands that control to the agent: the search tool becomes something the model *chooses* to invoke, so it can skip retrieval when its parametric knowledge suffices, judge relevance, and iterate [prov:src-2026-07-03-agentic-search-context-engineering#t00:03:42-00:04:15|direct|2026-07-03]. Agentic search is the generalization of that idea beyond a single database to the whole context landscape — the reason it is the operative mechanism of [[context-engineering|Context Engineering]] rather than a niche RAG variant. (RAG itself, [[retrieval-augmented-generation|Retrieval-Augmented Generation]], remains an unwritten prerequisite page in this wiki.)

### The context landscape and the tools that reach it

Once context is understood to live in many places at once — local files, a scratchpad or `plan.md` working memory, agent-skill folders, enterprise databases, the web, and long-term memory — each source implies its own search interface: a file-search tool, a skill-loading tool, a semantic-search or SQL-style query tool, a web-search tool, a memory tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:04:31-00:06:33|direct|2026-07-03]. Cutting across all of them is the **shell/bash tool**, which is unusually powerful precisely because it is unspecialized: with terminal access an agent can `ls`/`grep` a file system, drive a database's CLI, `curl` an HTTPS endpoint, or write a from-scratch script to connect and query [prov:src-2026-07-03-agentic-search-context-engineering#t00:06:51-00:07:50|direct|2026-07-03]. The tension this sets up — one general tool versus many specialized ones — is the talk's throughline, and its resolution is that "doing good search is incredibly difficult" (vector, keyword, dense/sparse/multi-vector embeddings, many indexing strategies), so no single interface is adequate and teams must curate a stack [prov:src-2026-07-03-agentic-search-context-engineering#t00:08:04-00:08:43|direct|2026-07-03].

### Making the agent call the right tool correctly

Three failure modes structure the design problem: the agent calls no tool (answering from parametric knowledge), calls the wrong tool, or generates wrong parameters [prov:src-2026-07-03-agentic-search-context-engineering#t00:09:38-00:10:34|direct|2026-07-03]. The first two are addressed mostly through the **tool description** — the highest-leverage and most-neglected surface — built up incrementally from a core purpose to trigger conditions to inter-tool relationships, and reinforced in the system prompt only if needed [prov:src-2026-07-03-agentic-search-context-engineering#t00:10:40-00:11:57|direct|2026-07-03]. The third scales with **parameter complexity**: an ID or a semantic string is easy, filters and `top_k` are harder, and writing an entire query-language statement from scratch is hardest [prov:src-2026-07-03-agentic-search-context-engineering#t00:11:57-00:13:34|direct|2026-07-03].

The demos make these abstract points concrete. A plain semantic-search tool (Jina embeddings v5, `top_k` = 3) answers a semantic query but fails on the specific keyword "GEPA," returning unrelated talks because it has no keyword filter [prov:src-2026-07-03-agentic-search-context-engineering#t00:21:56-00:23:19|direct|2026-07-03]. Replacing it with a general-purpose ES|QL "execute query" tool raises the ceiling but also the parameter difficulty: the agent's first query uses SQL's `%` wildcard instead of ES|QL's `*` and returns zero results [prov:src-2026-07-03-agentic-search-context-engineering#t00:27:05-00:28:02|direct|2026-07-03]. The fix is an [[agent-skills|Agent Skill]] loaded by [[progressive-disclosure|Progressive Disclosure]] — the skill's name and description sit in the system prompt while its body (ES|QL syntax rules, including the wildcard) loads on demand — plus a tool-description relationship that makes the agent consult the skill before querying [prov:src-2026-07-03-agentic-search-context-engineering#t00:28:17-00:32:38|direct|2026-07-03]. A general-purpose query tool also unlocks aggregations (an ES|QL count returns "27 sessions on April 8th"), which is more reliable than making the LLM count rows itself and cheaper than loading every row into context [prov:src-2026-07-03-agentic-search-context-engineering#t00:32:52-00:34:24|direct|2026-07-03].

### Shell retrieval, semantic grep, and the curated stack

Over a local file system the shell tool lets the agent `ls` and `grep` its way to the right file, at the cost of real risk (it can delete files — run it sandboxed; LangChain's shell tool has no safeguards by default) [prov:src-2026-07-03-agentic-search-context-engineering#t00:34:42-00:39:01|direct|2026-07-03]. Agents even approximate semantic search by chaining synonyms into `grep`, which works but is wasteful — the gap that semantic-grep CLIs (LlamaIndex `semtools`, LightOn `colgrep`, Jina `ginagrep`) fill by adding embedding-based matching to a `grep`-shaped interface the agent already knows how to drive [prov:src-2026-07-03-agentic-search-context-engineering#t00:39:01-00:44:00|direct|2026-07-03].

The synthesizing recommendation is that no single tool wins. Curate a stack that pairs **low-floor** specialized tools (usable out of the box, simple parameters, efficient, no powerful model required) with **high-ceiling** general-purpose tools (the shell tool or a query-execution tool, able to handle the unexpected but sometimes needing more iterations) [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03]. When the agent's query distribution is still unknown, start general and log: ~4–5 tool calls per question is the tell that a tool is too hard and a specialized interface is worth building [prov:src-2026-07-03-agentic-search-context-engineering#t00:47:13-00:48:46|direct|2026-07-03]. The Q&A reinforced the "combine tools" conclusion with a cited Vercel benchmark ("is bash all you need"), where a hybrid bash-plus-database agent scored highest on analytical queries by querying with the database tool and then verifying with the shell tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:54:36-00:56:51|direct|2026-07-03] [epistemic:: tentative].

**Epistemic note.** This page is anchored in a single practitioner talk with clean audio, so it is graded `sourced`; proper nouns, tool/model names, and figures carry claim-level `tentative` hedges because they sit on the speech-to-text failure surface (the talk itself renders Jina as "Gina" and GEPA as "GPA"). It is a natural candidate for enrichment from primary sources — the tools' own docs (Jina, LightOn, LlamaIndex), the cited Vercel post, and the RAG literature — on future ingests.

## Related Pages

- [[context-engineering|Context Engineering]] — the broader discipline agentic search is the operative mechanism of.
- [[progressive-disclosure|Progressive Disclosure]] — the loading discipline that makes the ES|QL agent-skill fix work.
- [[agent-skills|Agent Skills]] — used here as just-in-time documentation to fix tool-parameter generation.
- [[elastic|Elastic]] — the search company whose Elasticsearch / ES|QL stack the demos run on.
- [[leonie-monigatti|Leonie Monigatti]] — the speaker who framed the "80% agentic search" thesis.
- [[claude-code|Claude Code]] — cited for using subagents to answer niche search questions.
- [[subagents|Subagents]] — raised in the Q&A as a possible search decomposition Monigatti has not yet used.

## Sources

- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer conference talk, 2026-05-08 (YouTube transcript)
