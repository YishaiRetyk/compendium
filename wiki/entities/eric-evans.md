---
id: eric-evans
title: "Eric Evans"
type: entity
status: active
summary: "American software engineer; author of the 2003 book *Domain-Driven Design: Tackling Complexity in the Heart of Software*, which originated the DDD methodology."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: mixed
tags:
  - person
  - software-engineer
  - author
  - domain-driven-design
domains:
  - software-engineering
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Eric Evans (DDD)
has_contradictions: false
knowledge_domain: biography
example: false
---

# Eric Evans

## TL;DR

Author of the 2003 book *Domain-Driven Design: Tackling Complexity in the Heart of Software*, which introduced the [[Domain-Driven Design]] methodology [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:02:33-00:02:39|direct|2026-05-04]. His original book remains, in [[Hack (Agentive Stack)]]'s words, "probably a solid starting point" for the methodology [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:09:23-00:09:29|direct|2026-05-04].

## Key Facts

- Author of *Domain-Driven Design: Tackling Complexity in the Heart of Software*, published 2003 [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:02:33-00:02:39|direct|2026-05-04]
- The book introduced the vocabulary that Hack's three-artifact reduction draws from: ubiquitous language, bounded contexts, and (less directly) documented contracts [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:39-00:09:16|direct|2026-05-04]
- The methodology pre-dates AI-assisted development by ~20 years but has been re-discovered as relevant to it [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:01:39-00:01:43|direct|2026-05-04]

## Detail

### Contribution

Evans' book argued that complex business software must be organized around the language and structure of the domain it serves — not the language of the underlying technology stack. The book introduced a vocabulary that has since become standard in enterprise software architecture: ubiquitous language, bounded contexts, aggregates, value objects, domain events, repositories, anti-corruption layers, context maps.

### Relevance to AI-assisted development

The methodology was originally designed to keep complex systems coherent across team turnover — i.e., across a sequence of humans whose mental models of the system do not naturally line up. AI coding agents present the same problem in a sharpened form: each session is a new "team member" with no carry-over context. This is the connection [[Hack (Agentive Stack)]] draws on to argue that DDD is more relevant now than it has been in years [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:11:39-00:12:03|direct|2026-05-04].

### Note on the source

The wiki currently has only secondary attestation of Evans' work, via Hack's framing. Direct quotation or primary-source citation from the 2003 book has not been done.

## Related Pages

- [[Domain-Driven Design]] — the methodology he introduced
- [[Ubiquitous Language]] — core concept from his book
- [[Bounded Context]] — core concept from his book
- [[Documented Contract]] — Hack's simplification of related Evans concepts

## Sources

- [[Three artifacts that changed how I build with AI]] — Hack, 2026-05-04 (transcript)
