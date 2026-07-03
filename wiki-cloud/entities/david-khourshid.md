---
id: david-khourshid
title: "David Khourshid"
type: entity
status: active
summary: "Creator of XState (the most popular open-source JavaScript state-machine & statecharts
  library) and founder of Stately.ai, and a longtime advocate for event-driven modeling and visual
  diagramming. In a 'Beyond the Prompt' talk he argues the cure for AI 'slop' is an explicit model
  of system behavior — determinism at the core, non-determinism at the edges."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-goodbye-slop-welcome-determinism
epistemic_status: sourced
tags:
- state-machines
- xstate
- ai-assisted-development
- software-modeling
- determinism
domains:
- software-engineering
- ai-assisted-development
supersedes: null
superseded_by: null
aliases:
- "David Khourshid"
- "David K Piano"
- "david-khourshid"
has_contradictions: false
knowledge_domain: biography
example: false
---

# David Khourshid

## TL;DR

David Khourshid is a software engineer known online as **David K Piano** (@DavidKPiano), the creator of [[xstate|XState]] — described in his talk as the most popular open-source state-machine and statecharts library — and the founder of **Stately.ai**, a company that makes state machines easier to build. He is a longtime advocate for event-driven modeling and visual diagramming as the foundation for reliable UIs and, increasingly, AI agents. In his "Beyond the Prompt" talk ("Goodbye Slop, Welcome Determinism") he argues that building well *with* AI requires the same discipline as building without it: an **explicit model** of how the system should behave, with [[deterministic-core-agentic-shell|determinism at the core and non-determinism at the edges]]. When not at a computer keyboard, he is at a piano keyboard.

## Key Facts

- Creator of [[xstate|XState]], an open-source library for state machines and statecharts he made ~10 years ago; he is building **XState v6** and the next version of the Stately editor [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:00:46-00:01:18|direct|2026-07-03] [epistemic:: tentative]
- Founder (~5 years ago) of **Stately.ai**, which aims to make state machines easier to build; other work includes XState Store v4, a graph library, a free state-machine visualizer, and a TanStack collaboration [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:00:56-00:01:58|direct|2026-07-03] [epistemic:: tentative]
- Advocates that the best way to build *with* AI is the same as without it — model thoughtfully, iterate sufficiently, and make core logic explicit [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:05:44-00:06:49|direct|2026-07-03]
- Coined/popularized in this talk the framing that **"slop code is code without a reliable model"** and that the root problem is *unstructured delegation*, not vibe coding or hallucination [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:06:49-00:09:16|direct|2026-07-03]
- Online presence: X **@DavidKPiano** (from the official video description); a longtime advocate for event-driven modeling and visual diagramming [prov:src-2026-07-03-goodbye-slop-welcome-determinism#sec:description|direct|2026-07-03] [epistemic:: tentative]

## Detail

Khourshid's contribution to this wiki is the argument that AI "slop" is a modeling failure, not a prompting failure, developed in his "Beyond the Prompt" conference talk (AG Grid + Bryntum, London). His authority on the subject is the decade he has spent on [[xstate|XState]] and Stately.ai making software behavior *explicit and visual* via state machines and statecharts — the same lens he now turns on AI agents. He frames three unchanging principles (model thoughtfully, iterate sufficiently, make core logic explicit) and diagnoses the failure mode as **unstructured delegation**: throwing judgment, structure, and even taste over the wall to an agent, which produces [[deterministic-core-agentic-shell|slop code]] — code without a reliable model that no one can fully understand, a close cousin of the wiki's [[comprehension-debt|comprehension debt]]. His prescription — an explicit model, with determinism at the core and non-determinism at the edges — is developed fully on the concept page. He stresses that state machines are only one modeling form ("you don't necessarily need state machines… you need structure") and that "modeling is not ceremony when it replaces confusion." The STT renders his handle as "David K. Piena"/"Pino"; the canonical spelling (@DavidKPiano) comes from the official video description.

## Related Pages

- [[xstate|XState]] — the state-machine library he created and used to build the talk's email-agent demo.
- [[deterministic-core-agentic-shell|Deterministic Core, Agentic Shell]] — the architectural pattern his talk argues for.
- [[comprehension-debt|Comprehension Debt]] — the closely related "code no one understands" failure his "slop code" reframes.
- [[spec-driven-development|Spec-Driven Development]] — a sibling "make intent the source of truth" movement his explicit-model thesis parallels.

## Sources

- [[src-2026-07-03-goodbye-slop-welcome-determinism|Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid]] — "Beyond the Prompt" conference talk, 2026-06-26 (YouTube transcript)
