---
id: bounded-context
title: "Bounded Context"
type: concept
status: active
summary: "A distinct area of a system with its own rules, data, and reason for existing — within which a given term has a single, stable meaning."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: sourced
tags:
  - domain-driven-design
  - architecture
  - ai-coding
  - software-engineering
domains:
  - software-engineering
  - ai-assisted-development
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Bounded Contexts
  - Context Boundary
has_contradictions: false
knowledge_domain: software
example: false
---

# Bounded Context

## TL;DR

A core artifact of [[Domain-Driven Design]]: a distinct area of a system with its own rules, its own data, and its own reason for existing [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:34-00:07:52|direct|2026-05-04]. Within a bounded context, a term in the [[Ubiquitous Language]] has one stable meaning. Across contexts, the same word may legitimately mean different things — and the contexts make that explicit.

## Key Facts

- One of three artifacts Hack identifies as the practical core of DDD for AI-assisted development [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:34-00:07:41|direct|2026-05-04]
- The system is not one monolithic thing; it has several distinct areas, each with own rules and data [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:34-00:07:47|direct|2026-05-04]
- Clark is mapped into six bounded contexts: analytics, experimentation, goals, SDKs, billing, organizations [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:47-00:08:00|direct|2026-05-04]
- The metaphor: rooms in a building — kitchen has different rules than bathroom; you only need to know which room you're in [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:17-00:08:31|direct|2026-05-04]

## Detail

### What contexts give the AI

When Hack tells his AI agent "we're working in experimentation today," the agent knows the scope is A/B tests, variants, and statistical analysis — and explicitly *not* billing, auth, or event ingestion [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:01-00:08:13|direct|2026-05-04]. The boundary is therefore a scoping device for AI sessions: the model does not need to understand the entire system at once, only the current context's slice [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:31-00:08:42|direct|2026-05-04].

### Anti-pattern: structure without substance

Hack recounts a previous DDD project on a 10-engineer healthcare platform that defined 44 bounded contexts with separate modules for things like "invoice" and "invoices" and three layers of nesting per context [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:05:47-00:06:18|direct|2026-05-04]. The architecture was technically beautiful but unnavigable, which "kind of misses the point of DDD" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:18-00:06:24|direct|2026-05-04]. Bounded contexts are useful when the count reflects real domain boundaries, not when they reflect over-zealous decomposition.

### Sizing heuristic

There is no "correct" number of bounded contexts. The pragmatic test in Hack's framing: a context is well-sized if a developer (or AI session) can hold its rules in working memory without consulting the rest of the system. Six is workable for a complex SaaS like Clark; 44 was not workable for the healthcare platform.

## Related Pages

- [[Domain-Driven Design]] — parent methodology
- [[Ubiquitous Language]] — sibling artifact; bounded contexts give the language its scope
- [[Documented Contract]] — sibling artifact; documents how contexts interact at their edges
- [[Systems Thinking]] — the broader skill that judges where boundaries should fall

## Sources

- [[Three artifacts that changed how I build with AI]] — Hack, 2026-05-04 (transcript)
