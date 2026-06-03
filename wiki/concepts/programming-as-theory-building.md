---
id: programming-as-theory-building
title: "Programming as Theory Building"
type: concept
status: active
summary: "Peter Naur's 1985 argument that the program is the theory in the programmer's head — how the parts connect and why — and the code is just its shadow."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-03-is-this-the-only-skill-left
epistemic_status: mixed
tags:
  - software-engineering
  - philosophy-of-programming
  - ai-coding
domains:
  - software-engineering
  - ai-assisted-development
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Naur's Theory Building"
  - "Theory Building"
  - "Programming as Theory Building"
  - "programming-as-theory-building"
has_contradictions: false
knowledge_domain: software
example: false
---

# Programming as Theory Building

## TL;DR

A 1985 paper by Danish computer scientist [[peter-naur|Peter Naur]] arguing that programming is fundamentally an act of building a theory of how a system works — and that theory lives in the programmers' heads, not in the code. The code, in Naur's framing, is just the shadow of the theory [prov:src-2026-05-03-is-this-the-only-skill-left#t00:00:47-00:01:21|direct|2026-05-04].

## Key Facts

- Original paper: *Programming as Theory Building*, Peter Naur, 1985 [prov:src-2026-05-03-is-this-the-only-skill-left#t00:00:47-00:00:55|direct|2026-05-04]
- Core claim: the program is what lives in the programmer's head — how the pieces connect, why they connect that way, and what happens when one is pulled out [prov:src-2026-05-03-is-this-the-only-skill-left#t00:00:55-00:01:13|direct|2026-05-04]
- The code is just the shadow of the theory [prov:src-2026-05-03-is-this-the-only-skill-left#t00:01:13-00:01:21|direct|2026-05-04]
- A program "dies" — in Naur's view — when the team that holds its theory disperses, even if the source code is intact [epistemic:: inferred]

## Detail

### The argument

Naur's 1985 paper challenged a common view of programming as text production. He argued instead that the durable, valuable artifact is a *theory*: a mental model of why the system is shaped the way it is, what its constraints are, what it would mean to change it. Source code, documentation, even tests are partial projections of that theory — useful, but not equivalent to the theory itself [prov:src-2026-05-03-is-this-the-only-skill-left#t00:00:55-00:01:21|direct|2026-05-04].

### Relevance to AI-assisted coding

[[hack-agentive-stack|Hack (Agentive Stack)]] reframes Naur's argument for the AI era: AI coding agents now generate the shadow on demand, but the program — the theory — is not gone. It still has to be built [prov:src-2026-05-03-is-this-the-only-skill-left#t00:01:13-00:01:34|direct|2026-05-04]. The risk is that humans see fast-generated code and confuse it with a theory the team actually holds. This is the conceptual root of [[comprehension-debt|Comprehension Debt]] and the motivation for [[systems-thinking|Systems Thinking]] as the AI-era core skill.

### Implications

If the program is the theory, then:

- A team that ships code without building the corresponding theory is shipping a shadow without substance.
- Onboarding is theory transfer, not code reading.
- AI-generated code is theory-free unless a human builds the theory of it after the fact.

These implications motivate the artifact-driven workflow argued in [[domain-driven-design|Domain-Driven Design]] — explicit, durable artifacts that re-inject the theory into every AI session.

## Related Pages

- [[peter-naur|Peter Naur]] — author
- [[systems-thinking|Systems Thinking]] — the practical descendent in the AI era
- [[comprehension-debt|Comprehension Debt]] — the failure mode when the theory isn't built
- [[domain-driven-design|Domain-Driven Design]] — proposed remedy via shared artifacts

## Sources

- [[src-2026-05-03-is-this-the-only-skill-left|Is this the only skill left?]] — Hack, 2026-05-03 (transcript). Note: the original Naur paper is referenced via Hack's summary; primary-source verification of specific phrasings has not been done.
