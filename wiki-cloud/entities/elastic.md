---
id: elastic
title: "Elastic"
type: entity
status: active
summary: "The search company behind Elasticsearch and its piped query language ES|QL;
  helps internal and external teams build agents that retrieve over Elasticsearch data,
  publishes official Elasticsearch agent skills, and frames search-tool design around a
  'low floor / high ceiling' balance of specialized and general-purpose tools."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-agentic-search-context-engineering
epistemic_status: sourced
tags:
- search
- elasticsearch
- vector-search
- agent-tools
- retrieval
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Elastic"
- "Elasticsearch"
- "elastic"
has_contradictions: false
knowledge_domain: software
example: false
---

# Elastic

## TL;DR

Elastic is the search company behind Elasticsearch and its query language ES|QL. In [[leonie-monigatti|Leonie Monigatti]]'s AI Engineer talk it appears as both the platform the demos run on and a source of practical guidance on [[agentic-search|Agentic Search]]: Elastic helps internal and external teams build agents that retrieve over Elasticsearch data, ships official Elasticsearch agent skills, and frames search-tool design around a "low floor / high ceiling" balance — pairing specialized tools that work out of the box with general-purpose tools that handle the unexpected.

## Key Facts

- Elastic is the company behind Elasticsearch [prov:src-2026-07-03-agentic-search-context-engineering#t00:00:24-00:00:38|direct|2026-07-03] [epistemic:: tentative]
- ES|QL (the Elastic Search Query Language) is a piped query language for filtering, transforming, and analyzing data — reminiscent of SQL but with different syntax and capabilities (e.g. `*`, not `%`, as its wildcard) [prov:src-2026-07-03-agentic-search-context-engineering#t00:24:42-00:25:01|direct|2026-07-03] [epistemic:: tentative]
- Elastic helps a lot of internal and external teams build agents that interact with Elasticsearch data [prov:src-2026-07-03-agentic-search-context-engineering#t00:09:22-00:09:36|direct|2026-07-03] [epistemic:: tentative]
- Official Elasticsearch agent skills are available for teams to use [prov:src-2026-07-03-agentic-search-context-engineering#t00:29:00-00:29:17|direct|2026-07-03] [epistemic:: tentative]
- Elastic frames search-tool design around a "low floor / high ceiling" balance (a concept borrowed from user experience): specialized tools that an agent can use out of the box, plus general-purpose tools that handle complex or unexpected queries [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:47:13|direct|2026-07-03] [epistemic:: sourced]
- Elastic's internal testing found that a more powerful model substantially reduces the parameter-error rate for general-purpose search tools, though a strong model still does not guarantee zero errors [prov:src-2026-07-03-agentic-search-context-engineering#t00:49:20-00:50:09|direct|2026-07-03] [epistemic:: tentative]

## Detail

Elastic serves two roles in the talk. As a **platform**, its Elasticsearch cluster and ES|QL query language back the code demos: a semantic-search tool over an Elasticsearch vector store, and a general-purpose "execute ES|QL query" tool that the agent drives to filter and aggregate conference-session data [prov:src-2026-07-03-agentic-search-context-engineering#t00:23:35-00:25:01|direct|2026-07-03]. As a **practitioner voice**, Elastic contributes design guidance drawn from helping many teams build retrieval agents — the "low floor / high ceiling" tool-curation framing, the observation that model strength materially lowers parameter-generation errors on general-purpose tools, and official Elasticsearch agent skills teams can adopt [prov:src-2026-07-03-agentic-search-context-engineering#t00:44:37-00:50:09|direct|2026-07-03]. In the same talk Monigatti uses a Jina embeddings model and refers to Jina as "our own" when introducing its grep CLI, which hints at an Elastic–Jina relationship, but the talk does not state one explicitly, so none is asserted here [prov:src-2026-07-03-agentic-search-context-engineering#t00:41:26-00:44:00|direct|2026-07-03] [epistemic:: tentative].

## Related Pages

- [[leonie-monigatti|Leonie Monigatti]] — the Elastic speaker who gave the talk.
- [[agentic-search|Agentic Search]] — the retrieval discipline the demos illustrate on Elasticsearch.
- [[agent-skills|Agent Skills]] — Elastic ships official Elasticsearch skills and uses one to fix ES|QL generation.
- [[context-engineering|Context Engineering]] — the broader frame Elastic positions search within.

## Sources

- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer conference talk, 2026-05-08 (YouTube transcript)
