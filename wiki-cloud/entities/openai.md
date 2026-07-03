---
id: openai
title: "OpenAI"
type: entity
status: active
summary: "The AI company that publishes Symphony (its spec-first coding-agent
  orchestration service) and the Codex coding agent, and that originated the
  'harness engineering' framing Symphony positions itself as the next step
  beyond. Stub — currently sourced only through the Symphony spec."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-openai-symphony-spec
epistemic_status: mixed
tags:
- openai
- codex
- symphony
- ai-agents
- organization
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "OpenAI"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

OpenAI is the organization behind [[symphony|Symphony]], the spec-first service for orchestrating coding agents, and behind [[codex|Codex]], the coding agent Symphony drives [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]. It also originated [[harness-engineering|Harness Engineering]], the practice Symphony names as its recommended prerequisite and frames itself as "the next step" beyond [prov:src-2026-07-03-openai-symphony-spec#sec:requirements|direct|2026-07-03]. This page is currently a stub sourced only through the Symphony repository; it captures OpenAI's role as it appears in that source rather than a full company profile.

## Key Facts

- Publishes Symphony under the Apache-2.0 license, with an Elixir reference implementation shipped in the same repository. [prov:src-2026-07-03-openai-symphony-spec#commit:4cbe3a9|direct|2026-07-03]
- Ships Codex, a coding agent that exposes an "app-server" mode (default `codex app-server`) which Symphony launches and drives over stdio. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- Originated the "harness engineering" framing that Symphony treats as a prerequisite and builds upon (positioning Symphony as moving from managing coding agents to managing the work itself). [prov:src-2026-07-03-openai-symphony-spec#sec:requirements|direct|2026-07-03] [epistemic:: tentative]

## Detail

Within the wiki this entity exists mainly to anchor OpenAI's coding-agent tooling — Symphony and Codex — as first-class nodes and to give the Symphony page a publisher to link to, paralleling the existing [[anthropic|Anthropic]] entity [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]. Everything recorded here so far derives from the Symphony repository snapshot; broader facts about OpenAI's products and history are not yet ingested and should be added from dedicated sources rather than assumed [epistemic:: inferred]. The "harness engineering" concept OpenAI publishes (referenced from Symphony's requirements as an external openai.com article) is a knowledge gap flagged as a red link until a source is ingested for it [prov:src-2026-07-03-openai-symphony-spec#sec:requirements|direct|2026-07-03].

## Related Pages

- [[symphony|Symphony]] — OpenAI's spec-first coding-agent orchestration service.
- [[codex|Codex]] — OpenAI's coding agent, integrated by Symphony via the app-server protocol.
- [[anthropic|Anthropic]] — the sibling AI-lab entity already in the wiki.

## Sources

- [[src-2026-07-03-openai-symphony-spec|openai/symphony — Symphony Service Specification repository snapshot]]: primary repository snapshot at commit `4cbe3a9` (July 2026)
