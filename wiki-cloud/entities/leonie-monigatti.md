---
id: leonie-monigatti
title: "Leonie Monigatti"
type: entity
status: active
summary: "A retrieval- and search-focused practitioner at Elastic who, in an AI Engineer
  conference workshop, argued that context engineering is 'about 80% agentic search' and
  walked four search interfaces — semantic search, a general-purpose ES|QL tool, the
  shell/bash tool, and semantic-grep CLIs — toward a curated low-floor/high-ceiling tool stack."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-agentic-search-context-engineering
epistemic_status: sourced
tags:
- ai-engineer
- retrieval
- agentic-search
- elastic
- developer-advocate
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Leonie Monigatti"
- "leonie-monigatti"
has_contradictions: false
knowledge_domain: software
example: false
---

# Leonie Monigatti

## TL;DR

Leonie Monigatti works at [[elastic|Elastic]] and focuses on retrieval and search. In an AI Engineer conference workshop she made the case that [[context-engineering|Context Engineering]] is mostly a search problem — "about 80% agentic search" — and demonstrated four search interfaces over conference-session data, closing with a practical recommendation to curate a stack of low-floor specialized tools and high-ceiling general-purpose tools. She is the author of the [[agentic-search|Agentic Search]] framing this wiki draws from that talk.

## Key Facts

- Works at Elastic and says she usually likes to talk about retrieval (on X, as @helloiamleonie) [prov:src-2026-07-03-agentic-search-context-engineering#t00:00:24-00:00:38|direct|2026-07-03] [epistemic:: tentative]
- Her central thesis: context engineering is "about 80% agentic search," because the arrow from context sources into the context window is powered by search tools [prov:src-2026-07-03-agentic-search-context-engineering#t00:02:09-00:02:21|direct|2026-07-03] [epistemic:: tentative]
- Recommends curating a balanced set of search tools — low-floor specialized tools plus high-ceiling general-purpose tools — rather than seeking a single silver-bullet tool [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03] [epistemic:: sourced]
- Advocates starting with a general-purpose tool when the agent's query behavior is unknown, logging behavior, and specializing when the agent needs too many tool calls per question [prov:src-2026-07-03-agentic-search-context-engineering#t00:47:13-00:48:46|direct|2026-07-03] [epistemic:: sourced]
- Has experimented with OpenClaw's exec tool over a database, logging its behavior for three days and then asking it what patterns it saw — after which it recommended implementing specific database search tools [prov:src-2026-07-03-agentic-search-context-engineering#t00:47:56-00:48:40|direct|2026-07-03] [epistemic:: tentative]

## Detail

Monigatti's contribution is a practitioner's map of [[agentic-search|Agentic Search]]: she traces the arc from fixed-pipeline RAG through agentic RAG to search across many context sources, then grounds it in four live LangChain demos over an Elasticsearch cluster — a semantic-search tool, a general-purpose ES|QL query tool (repaired with an agent skill), the shell/bash tool over a local file system, and a semantic-grep CLI [prov:src-2026-07-03-agentic-search-context-engineering#t00:13:53-00:44:00|direct|2026-07-03]. Her synthesizing advice — no silver bullet, curate a low-floor/high-ceiling stack, start general and specialize once you have logged real query behavior — reflects [[elastic|Elastic]]'s experience helping teams build retrieval agents [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:48:46|direct|2026-07-03].

## Related Pages

- [[elastic|Elastic]] — the search company she works at.
- [[agentic-search|Agentic Search]] — the concept her talk defines and demonstrates.
- [[context-engineering|Context Engineering]] — the discipline she frames as mostly agentic search.

## Sources

- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer conference talk, 2026-05-08 (YouTube transcript)
