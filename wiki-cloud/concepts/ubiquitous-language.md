---
id: ubiquitous-language
title: "Ubiquitous Language"
type: concept
status: active
summary: "A shared, unambiguous vocabulary for a software project — every important
  term defined in one sentence — used by humans, the codebase, and (in AI-coding workflows)
  the AI agent."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
- src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: sourced
tags:
- domain-driven-design
- ai-coding
- documentation
- software-engineering
domains:
- software-engineering
- ai-assisted-development
supersedes: null
superseded_by: null
aliases:
- "Shared Language"
- "Project Glossary"
- "Ubiquitous Language"
- "ubiquitous-language"
has_contradictions: false
knowledge_domain: software
example: false
---

# Ubiquitous Language

## TL;DR

A core artifact of [[domain-driven-design|Domain-Driven Design]]: a glossary of every important term in the system, defined clearly in one sentence with no ambiguity, used consistently by humans, code, and AI agents [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:48-00:07:30|direct|2026-05-04]. In [[hack-agentive-stack|Hack (Agentive Stack)]]'s framing, it functions as "a contract between you and your AI" — the shared understanding that prevents AI from building the wrong thing with the right name.

## Key Facts

- One of three artifacts Hack identifies as the practical core of DDD for AI-assisted development [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:39-00:06:54|direct|2026-05-04]
- Each term: one sentence, what it is and what it does, no ambiguity [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:54-00:07:20|direct|2026-05-04]
- Hack's product Clark has >50 terms, organized by area [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:54-00:07:03|direct|2026-05-04]
- Without it, every AI coding session "would build the wrong thing on the wrong assumption of meaning" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:20-00:07:30|direct|2026-05-04]

## Detail

### The drift problem it solves

A single English word can carry multiple incompatible meanings within one product. Hack's examples from Clark [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:03:33-00:04:13|direct|2026-05-04]:

- **"Change"** — could mean a code commit, a feature request, or (in Clark) a persistent set of DOM mutations applied to a customer's website. Clark's definition is the third one.
- **"User"** — could mean the visitor being tracked, the developer installing the SDK, or the admin in the dashboard. Three completely different concepts.

When the AI guesses, it sometimes guesses wrong, and "wrong" looks correct enough to pass review for a week before the bug surfaces.

### Example glossary entries

From Clark [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:03-00:07:16|direct|2026-05-04]:

> **Visitor** — a unique user identified by device ID.
>
> **Session** — a sequence of events bounded by 30 minutes of inactivity.
>
> **Change** — a persistent set of DOM mutations applied to a customer's website.

The form is consistent: noun, en-dash, single sentence, ends with the discriminating attribute. Each entry resolves to one concept and rules out adjacent ones.

### Operational role

The ubiquitous language functions as a session-prefix artifact: at the start of each AI session, it re-establishes the shared vocabulary that the session would otherwise have to re-derive (or guess). Hack's framing: it is "a contract between you and your AI, and your teammates after all too" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:25-00:07:34|direct|2026-05-04].

### Cousin practices

The closest pre-DDD cousin is the glossary section of a PRD (Product Requirements Document). The DDD-specific spin is that the glossary is **load-bearing** — it dictates the names used in code, not just in product specs.

## Related Pages

- [[domain-driven-design|Domain-Driven Design]] — parent methodology
- [[bounded-context|Bounded Context]] — sibling artifact, defines where each term's meaning holds
- [[documented-contract|Documented Contract]] — sibling artifact, formalizes inter-context handshakes
- [[comprehension-debt|Comprehension Debt]] — the failure mode this artifact prevents

## Sources

- [[src-2026-05-04-three-artifacts-build-with-ai|Three artifacts that changed how I build with AI]] — Hack, 2026-05-04 (transcript)
