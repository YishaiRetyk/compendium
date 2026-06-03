---
id: src-2026-05-04-three-artifacts-build-with-ai
title: "Three artifacts that changed how I build with AI"
type: source
status: active
summary: "Hack argues that Domain-Driven Design — stripped to three artifacts (ubiquitous language, bounded contexts, documented contracts) — is the practical method for operationalizing systems thinking when building software with AI."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
  - ai-coding
  - domain-driven-design
  - software-engineering
  - youtube-transcript
domains:
  - software-engineering
  - ai-assisted-development
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Three Artifacts Build with AI"
  - "Three artifacts that changed how I build with AI"
  - "src-2026-05-04-three-artifacts-build-with-ai"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-three-artifacts-build-with-ai.md
url: "https://www.youtube.com/watch?v=ECLDuYkzB8A"
content_hash: "sha256:29e6ef81684c56f572b33922d668c79df76de0581456b1084c3e1cd177e21b31"
ingested_at: 2026-05-04
source_type: transcript
compilation_status: compiled
compiled_against_hash: "sha256:29e6ef81684c56f572b33922d668c79df76de0581456b1084c3e1cd177e21b31"
compiled_targets:
  - domain-driven-design
  - ubiquitous-language
  - bounded-context
  - documented-contract
  - eric-evans
  - hack-agentive-stack
  - comprehension-debt
  - systems-thinking
---

# Three artifacts that changed how I build with AI

## TL;DR

A follow-up monologue by [[Hack (Agentive Stack)]] answering a how question raised by his earlier [[Is this the only skill left?]] video. He argues that **Domain-Driven Design** — written by [[Eric Evans]] in 2003 — stripped to three core artifacts is the practical method for paying down [[Comprehension Debt]] and operationalizing [[Systems Thinking]] when working with AI coding agents. The three artifacts: a [[Ubiquitous Language]] (a glossary), [[Bounded Context]]s (clear scope boundaries), and [[Documented Contract]]s (the handshakes between contexts).

## Key Takeaways

- The single biggest failure mode in AI-assisted coding is missing shared vocabulary between human and AI; the AI guesses, sometimes wrong, and ships the wrong thing with the right name [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:03:11-00:04:31|direct|2026-05-04]
- DDD's value proposition for AI is that "each AI conversation now starts from a shared understanding instead of a blank slate" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:09:29-00:09:41|direct|2026-05-04]
- The three artifacts are not new — they are cousins of PRDs, ADRs, and TDD — but the cost-benefit of producing them changed because AI carries no context between sessions [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:10:36-00:11:21|direct|2026-05-04]
- Personal anecdote: a previous DDD project with 44 bounded contexts and three layers of nesting was a counter-example — DDD-as-structure without DDD-as-substance [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:05:47-00:06:24|direct|2026-05-04]
- "Almost no one shipping serious software is letting agents write 100% of the code" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:12:52-00:13:14|direct|2026-05-04]

## Extracted Claims

### On the three artifacts

- **Artifact 1 — Ubiquitous Language:** a glossary; every important term in the system defined in one sentence with no ambiguity. Hack reports >50 terms in Clark, organized by area [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:48-00:07:30|direct|2026-05-04]
- Example glossary entries from Clark: "A visitor is a unique user identified by device ID. A session is a sequence of events bounded by 30 minutes of inactivity. A change is a persistent set of DOM mutations applied to a customer's website." [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:03-00:07:16|direct|2026-05-04]
- **Artifact 2 — Bounded Contexts:** distinct areas of the system, each with its own rules, data, and reason for existing. Clark is mapped into six (analytics, experimentation, goals, SDKs, billing, organizations) [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:07:34-00:08:00|direct|2026-05-04]
- The "rooms in a building" metaphor: kitchen has different rules than bathroom; you only need to know which room you're in, not the plumbing of every room [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:17-00:08:42|direct|2026-05-04]
- **Artifact 3 — Documented Contracts:** the handshakes where boundaries touch. If analytics writes events and experimentation reads them, that dependency is a contract; changing the event shape breaks experimentation [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:42-00:09:16|direct|2026-05-04]

### On the meaning-drift problem

- "Change" in Clark means a DOM mutation applied to a customer's website — not a code commit or a feature request — but the AI does not know that without explicit instruction every session [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:03:33-00:03:53|direct|2026-05-04]
- "User" can mean three different things in Clark: the visitor, the developer installing the SDK, or the admin in the dashboard [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:03:58-00:04:13|direct|2026-05-04]
- "AI feels most impressive in the areas where you know the least" — the gaps in your knowledge become its free space to drift [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:04:35-00:04:46|direct|2026-05-04]

### On the analogy to existing practices

- The three artifacts are cousins of: PRDs (product requirements documents), ADRs (architecture decision records), and TDD (test-driven development) [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:10:36-00:11:09|direct|2026-05-04]
- Senior devs historically carried this context in their heads, so the artifacts felt like overhead. AI carries no context between sessions, so the overhead is now the cheapest insurance [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:11:09-00:11:27|direct|2026-05-04]

### On the broader argument

- "DDD was designed for a problem more relevant now than ever — how to maintain a coherent mental model of a complex system when the people working on it keep changing. Back then, new hires; today, a new AI session every time." [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:11:39-00:12:03|direct|2026-05-04]
- Hack hedges: he is not saying DDD is *the* solution, only that it is *a* solution that has worked for him — "we're all still figuring this out as we craft" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:12:28-00:12:46|direct|2026-05-04]
- "Quality becomes the differentiator. Craft is what separates you from the vibe-coded slop." [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:14:46-00:15:03|direct|2026-05-04]

## Notes

**Validity assessment:**

- The DDD attribution is correct: *Domain-Driven Design: Tackling Complexity in the Heart of Software* by [[Eric Evans]], 2003. The three concepts named (ubiquitous language, bounded contexts, contracts/context maps) are core Evans concepts.
- However, the framing of DDD as "three artifacts" is Hack's pedagogical reduction. The full Evans framework includes many more concepts: aggregates, value objects, domain events, repositories, domain services, anti-corruption layers, context maps. "Documented contracts" in Hack's framing is most directly the descendant of Evans' **Context Map** + **Published Language** concepts; calling it a "contract" is a useful but non-canonical simplification.
- The healthcare-project anecdote ("44 bounded contexts, three layers of nesting") illustrates a real and well-known DDD anti-pattern: structure without substance. Cannot be independently verified, but is internally consistent.
- The PRD / ADR / TDD analogies are reasonable. PRDs are the closest cousin to ubiquitous-language documents; ADRs map to part of the documented-contracts artifact; TDD is more orthogonal but shares the spec-before-code spirit.
- Hack's claim that "almost no one shipping serious software is letting agents write 100% of the code" is presented as personal observation rather than data. Plausible but not load-bearing.

**Pedagogical strengths:** the reduction of DDD to three artifacts is an effective on-ramp for developers who would otherwise be intimidated by Evans' full framework. The Clark examples (visitor / session / change) are concrete and memorable.

**Pedagogical caveats:** the simplification risks giving readers the impression that DDD = three artifacts. A reader proceeding to Evans' book will encounter substantially more conceptual machinery. The video acknowledges this ("of course there are many more things to dive into") but the framing leans heavy.

## Source Metadata

- **Author:** Hack (Agentive Stack)
- **Publication:** YouTube
- **URL:** https://www.youtube.com/watch?v=ECLDuYkzB8A
- **Recorded date:** 2026-05-04 (file mtime; actual publication date not verified)
- **Source type:** transcript
- **Length:** ~15 minutes
- **Path:** `sources/2026/2026-05/2026-05-04-three-artifacts-build-with-ai.md`
- **Predecessor:** [[Is this the only skill left?]] (referenced explicitly as "the previous video")
