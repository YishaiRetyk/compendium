---
id: domain-driven-design
title: "Domain-Driven Design"
type: overview
status: active
summary: "A 2003 software-engineering methodology by Eric Evans for managing complexity by aligning code with the language and structure of the business domain — re-discovered in the AI-coding era as a remedy for context loss between sessions."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: mixed
tags:
  - software-engineering
  - architecture
  - methodology
  - ai-coding
domains:
  - software-engineering
  - ai-assisted-development
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - DDD
has_contradictions: false
knowledge_domain: software
example: false
---

# Domain-Driven Design

## TL;DR

A software-engineering methodology introduced by [[Eric Evans]] in his 2003 book *Domain-Driven Design: Tackling Complexity in the Heart of Software*. Its central thesis: software must reflect a shared understanding of the domain it serves [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:00:05-00:00:17|direct|2026-05-04]. [[Hack (Agentive Stack)]] re-frames DDD for AI-assisted development by reducing it to three artifacts — [[Ubiquitous Language]], [[Bounded Context]]s, and [[Documented Contract]]s — that re-inject shared understanding into every AI coding session [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:39-00:09:16|direct|2026-05-04].

## Key Facts

- Originated in *Domain-Driven Design: Tackling Complexity in the Heart of Software* by Eric Evans, 2003 [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:02:33-00:02:39|direct|2026-05-04]
- Thesis: software must reflect a shared understanding of the domain it serves [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:00:11-00:00:17|direct|2026-05-04]
- Hack's three-artifact reduction: ubiquitous language, bounded contexts, documented contracts [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:14:18-00:14:40|direct|2026-05-04]
- Original-DDD anti-pattern: structure without substance — e.g., 44 bounded contexts with deep nesting that nobody can navigate [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:05:47-00:06:24|direct|2026-05-04]
- Re-applicable in the AI era because AI sessions, like new hires, arrive with no context [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:11:39-00:12:03|direct|2026-05-04]

## Detail

### The original framing (2003)

Evans introduced DDD to solve a problem that pre-dates AI: how to keep code coherent in long-lived projects where the team turns over and the business domain has its own language. His prescription was to put the domain language at the center — let the words developers, domain experts, and code use be the same words — and to organize systems around bounded contexts where those words have stable meanings [epistemic:: inferred].

The full Evans framework extends well beyond what is captured in this overview, including aggregates, value objects, domain events, repositories, domain services, anti-corruption layers, and context maps. The three-artifact framing in this wiki is a deliberate pedagogical reduction by Hack, not a comprehensive rendering of Evans.

### The AI-era re-application

Hack argues that the AI-coding workflow surfaces the exact problem DDD was designed for, in a sharper form. Senior engineers historically carried domain context in their heads. AI agents do not carry anything between sessions, so every session that does not start with explicit shared context will guess — often plausibly enough to ship the wrong thing with the right name [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:03:11-00:04:31|direct|2026-05-04]. The three artifacts re-inject that context.

### The three artifacts

#### 1. Ubiquitous Language

A glossary: every important term in the system, defined in one sentence, with no ambiguity. Hack reports >50 such terms in his product Clark, organized by area [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:48-00:07:30|direct|2026-05-04]. See [[Ubiquitous Language]] for full treatment.

#### 2. Bounded Contexts

The system as a set of distinct areas, each with its own rules and data. Clark has six: analytics, experimentation, goals, SDKs, billing, organizations [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:34-00:08:00|direct|2026-05-04]. The metaphor: rooms in a building, each with different rules; you only need to know which room you're in to operate. See [[Bounded Context]].

#### 3. Documented Contracts

Where boundaries touch — the handshake written down. Example: analytics writes events; experimentation reads them; that dependency is a contract whose violation breaks the downstream system [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:42-00:09:16|direct|2026-05-04]. See [[Documented Contract]].

### Cousin practices

The three artifacts have analogues in practices that pre-date DDD's AI re-discovery [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:10:36-00:11:09|direct|2026-05-04]:

| DDD artifact | Closest classical cousin |
|---|---|
| Ubiquitous Language | PRD (Product Requirements Document) glossary |
| Bounded Contexts | Modular monolith / microservice boundaries |
| Documented Contracts | API specs, ADRs (Architecture Decision Records), interface contracts |

Hack also notes TDD (Test-Driven Development) as a cousin in spirit — defining behavior before the code is written.

### Why this isn't overhead anymore

Pre-AI, these artifacts felt like overhead because senior engineers carried equivalent context in their heads at near-zero marginal cost per session. With AI agents, the marginal cost of *not* having the artifact compounds with every session that has to re-derive context. Hack's framing: the artifacts are now "the cheapest insurance you can buy" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:11:21-00:11:27|direct|2026-05-04].

### Caveats from the source

- DDD-as-structure-without-substance is a real anti-pattern and led Hack to reject DDD for years before rediscovering it [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:05:47-00:06:39|direct|2026-05-04]
- The three-artifact reduction is presented explicitly as Hack's reduction, not Evans' framework: "DDD is three things, *if we strip it down to what actually matters when building with AI*" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:39-00:06:48|direct|2026-05-04]

## Related Pages

- [[Eric Evans]] — author of the original methodology
- [[Ubiquitous Language]] — first artifact
- [[Bounded Context]] — second artifact
- [[Documented Contract]] — third artifact
- [[Systems Thinking]] — the higher-level skill DDD operationalizes
- [[Comprehension Debt]] — the failure mode DDD prevents

## Sources

- [[Three artifacts that changed how I build with AI]] — Hack, 2026-05-04 (transcript). The Evans 2003 book is referenced through Hack's framing; primary-source verification of specific phrasings has not been done.
