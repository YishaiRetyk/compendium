---
id: documented-contract
title: "Documented Contract"
type: concept
status: active
summary: "A written-down handshake between bounded contexts — the shape of the data and the dependency that one context relies on from another."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: sourced
tags:
  - domain-driven-design
  - architecture
  - ai-coding
  - documentation
domains:
  - software-engineering
  - ai-assisted-development
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Documented Contracts"
  - "Context Contract"
  - "Documented Contract"
  - "documented-contract"
has_contradictions: false
knowledge_domain: software
example: false
---

# Documented Contract

## TL;DR

A core artifact of [[domain-driven-design|Domain-Driven Design]] in [[hack-agentive-stack|Hack (Agentive Stack)]]'s reduction: the explicit written record of how two [[bounded-context|Bounded Context]]s interact at their boundary [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:42-00:09:16|direct|2026-05-04]. If context A produces data and context B consumes it, the shape of that data — and the fact of the dependency — is the contract. Changing the contract without updating both sides breaks the system.

## Key Facts

- The third of three artifacts in Hack's DDD-for-AI reduction [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:42-00:08:49|direct|2026-05-04]
- Located "where the boundaries touch" — at the seams between contexts [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:42-00:08:49|direct|2026-05-04]
- Worked example: in Clark, analytics writes events to a database; experimentation reads them to determine A/B test winners. That dependency is a contract; changing event shape breaks experimentation [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:08:49-00:09:06|direct|2026-05-04]
- Hack frames it as the written-down answer to the [[systems-thinking|Systems Thinking]] question "what breaks if I delete this?" [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:09:06-00:09:16|direct|2026-05-04]

## Detail

### Why writing it down matters

The dependency between two contexts always exists; documentation does not create it. What changes when the contract is documented is *who can see it without running the code* — including the AI agent in the next session. Without the documented contract, a coding agent modifying analytics has no signal that experimentation depends on the event shape, and may quietly break it [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:09:00-00:09:16|direct|2026-05-04].

### Relationship to existing practices

The closest classical cousins are:

- **API specs / interface definitions** — schemas, OpenAPI documents, type definitions
- **Architecture Decision Records (ADRs)** — capture not just the contract but why this shape was chosen [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:10:50-00:11:02|direct|2026-05-04]
- **Anti-corruption layers / context maps** in Evans' canonical DDD vocabulary [epistemic:: inferred]

Hack's "documented contract" framing is a deliberate simplification of Evans' more granular vocabulary (context maps, published languages, conformist relationships, anti-corruption layers); the simplification is useful as an on-ramp.

### Operational discipline

Hack's stated discipline [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:09:58-00:10:17|direct|2026-05-04]:

> "For the parts that matter — architecture, contracts, data, anything that future me or future AI or future teammates will need to read — I slow down. I open the glossary. I check the boundary. I update the doc when something changes."

The contract decays when it is not updated; the AI session that reads a stale contract is in worse shape than one that reads no contract.

## Related Pages

- [[domain-driven-design|Domain-Driven Design]] — parent methodology
- [[ubiquitous-language|Ubiquitous Language]] — defines the terms that appear in contracts
- [[bounded-context|Bounded Context]] — what contracts connect
- [[systems-thinking|Systems Thinking]] — contracts answer the "what breaks if I delete this?" question

## Sources

- [[src-2026-05-04-three-artifacts-build-with-ai|Three artifacts that changed how I build with AI]] — Hack, 2026-05-04 (transcript)
