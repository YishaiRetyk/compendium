---
id: xstate
title: "XState"
type: entity
status: active
summary: "Open-source JavaScript library for state machines and statecharts, created by David
  Khourshid ~10 years ago and commercialized through Stately.ai. Described in his 'Beyond the
  Prompt' talk as the most popular library of its kind; used to make application (and increasingly
  AI-agent) control flow explicit, visual, and deterministic."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-goodbye-slop-welcome-determinism
epistemic_status: sourced
tags:
- state-machines
- statecharts
- javascript
- software-modeling
- determinism
domains:
- software-engineering
- ai-assisted-development
supersedes: null
superseded_by: null
aliases:
- "XState"
- "Stately.ai"
- "xstate"
has_contradictions: false
knowledge_domain: software
example: false
---

# XState

## TL;DR

XState is an open-source JavaScript library for building **state machines and statecharts**, created by [[david-khourshid|David Khourshid]] roughly ten years ago and, in his "Beyond the Prompt" talk, described as the most popular library of its kind. Its purpose is to make an application's control flow **explicit, visual, and deterministic** — modeling behavior as states, events, and transitions rather than scattering it across the codebase. It is commercialized through **Stately.ai** (Khourshid's company, which makes state machines easier to build, with a visual editor), and in the talk it is the tool behind an email-agent demo that enforces [[deterministic-core-agentic-shell|determinism at the core and non-determinism at the edges]]. Khourshid claims XState underpins many critical systems, including something most UK residents have interacted with.

## Key Facts

- Open-source library for **state machines and statecharts**, created by [[david-khourshid|David Khourshid]] ~10 years ago; framed in the talk as the most popular library of its kind [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:00:46-00:00:56|direct|2026-07-03] [epistemic:: tentative]
- Commercialized through **Stately.ai** (founded ~5 years ago) which makes state machines easier to build; a free open-source state-machine visualizer is part of the ecosystem [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:00:56-00:01:58|direct|2026-07-03] [epistemic:: tentative]
- **XState v6** and the next Stately editor were in active development at talk time, alongside XState Store v4, a graph library, and a TanStack collaboration [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:01:09-00:01:58|direct|2026-07-03] [epistemic:: tentative]
- Claimed to be part of many critical systems and "very useful for complex application logic" — Khourshid says anyone in the UK has likely interacted with something relying on it (he is "not allowed to say what") [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:01:18-00:01:41|direct|2026-07-03] [epistemic:: tentative]
- Describes behavior with **given-when-then** statements (a.k.a. Gherkin / Cucumber) that map to states, events, and transitions on a graph, containing the "state-and-transition explosion" of complex systems [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:12:23-00:12:53|direct|2026-07-03] [epistemic:: tentative]
- In the talk's demo, an XState state machine makes invalid states unreachable: **impossible to send an email without an approved draft, impossible to draft without satisfied requirements** [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:23:39-00:26:53|direct|2026-07-03] [epistemic:: tentative]

## Detail

XState exists to solve the problem Khourshid calls **state-and-transition explosion**: as systems get complex, states and transitions multiply everywhere, and behavior becomes impossible to reason about. Statecharts (which XState implements) *contain and reduce* that complexity and make it visual, so the same tool can describe a Casio watch, a microwave, a complex web app, or — increasingly — an AI agent's control flow [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:02:39-00:05:00|direct|2026-07-03] [epistemic:: tentative]. In the talk, XState is the concrete embodiment of the [[deterministic-core-agentic-shell|deterministic core, agentic shell]] pattern: the email-agent demo uses a state machine as the deterministic core (requirements → draft → iterate → send), invoking the LLM only at the fuzzy, non-deterministic edges, so the machine guarantees the right state at the right time.

Khourshid is careful that XState is not the point — "you don't necessarily need state machines… the important thing is that you need structure" — but it is his preferred way to make core logic explicit rather than scattered, which is what lets an AI agent help with feature development without mixing concerns. The commercial layer, **Stately.ai**, provides a visual editor (the STT renders a URL as "stately.sketch.ai") to author these machines. Version and product names here (XState v6, XState Store v4) are as-heard from the transcript and hedged accordingly.

## Related Pages

- [[david-khourshid|David Khourshid]] — creator of XState and founder of Stately.ai.
- [[deterministic-core-agentic-shell|Deterministic Core, Agentic Shell]] — the pattern XState is used to implement in the talk's demo.
- [[systems-thinking|Systems Thinking]] — the reasoning discipline that making control flow explicit supports.

## Sources

- [[src-2026-07-03-goodbye-slop-welcome-determinism|Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid]] — "Beyond the Prompt" conference talk, 2026-06-26 (YouTube transcript)
