---
id: deterministic-core-agentic-shell
title: "Deterministic Core, Agentic Shell"
type: concept
status: active
summary: "An architectural pattern for AI-assisted software (argued by David Khourshid): put the
  deterministic, explicitly-modeled logic at the core of an application and confine non-determinism
  (LLM calls) to the edges — write programs that call LLMs, not LLMs that call programs. The remedy
  for 'slop code' (code without a reliable model) is an explicit model of system behavior, modeled
  only where it replaces confusion."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-goodbye-slop-welcome-determinism
epistemic_status: sourced
tags:
- determinism
- state-machines
- software-modeling
- ai-assisted-development
- slop-code
- separation-of-concerns
- agent-architecture
domains:
- software-engineering
- ai-assisted-development
supersedes: null
superseded_by: null
aliases:
- "Deterministic Core, Agentic Shell"
- "Deterministic Core Agentic Shell"
- "deterministic-core-agentic-shell"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

**Deterministic core, agentic shell** is an architectural pattern for building software with AI: keep the **deterministic, explicitly-modeled logic at the core** of the application and push **non-determinism (LLM calls) to the edges**. Its slogan is *write programs that call LLMs, not LLMs that call programs* — the inverse of the common design where an agent is the "air traffic controller" routing all workflow logic. [[david-khourshid|David Khourshid]] (creator of [[xstate|XState]]) argues the pattern is the cure for **"slop code"**: code without a reliable model that no one can fully understand or safely change — a failure whose root cause is **unstructured delegation** (throwing judgment, structure, and taste over the wall to an agent), *not* vibe coding or hallucination. The remedy is an **explicit model** — a structured representation of how the system should behave, to which both code and intent map — because ~90% of code, he claims, has nothing to do with behavioral intent. You don't strictly need state machines; you need *structure*, and "modeling is not ceremony when it replaces confusion," so you model only the confusing parts and start rough. The name mirrors Gary Bernhardt's "functional core, imperative shell"; Khourshid also credits Ken Wheeler's framing that deterministic workflows should have "a sprinkling of AI," not the reverse.

## Key Facts

- **The pattern:** move non-determinism to the edges and determinism to the core — "write programs that call LLMs" instead of "LLMs that call programs" (the latter trusts the agent as an air-traffic controller, which is "risky" and "a little bit lazy") [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:52-00:20:32|direct|2026-07-03]
- **Determinism** = same input → same output (like a pure function, possibly async); **non-determinism** = same input → unknown output, not necessarily random and not exclusive to LLMs; the distinction comes from DFAs vs. NFAs in finite-automata theory [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:03:35-00:04:40|direct|2026-07-03] [epistemic:: tentative]
- **Slop code = "code without a reliable model"**: code you can't fully understand or explain, with no clear domain boundaries, implicit invariants, un-inspectable state, scattered behavior, and no safe way to change it — not necessarily broken, and predating LLMs [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:08:31-00:09:16|direct|2026-07-03]
- **Root cause is unstructured delegation**, not vibe coding or hallucination — deciding to let agents own judgment, structure, implementation, and even taste [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:06:49-00:07:24|direct|2026-07-03]
- **The remedy is an explicit model**: a structured representation of how the system should behave (state machines via given-when-then are one form) combining intent and execution, to which both code and behavior map — giving "an executable description without the noise of code," since ~90% of code is not behavioral intent [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:11:22-00:14:38|direct|2026-07-03] [epistemic:: tentative]
- **Larger context windows are not a substitute for structure** — "more context does not mean more structure"; wrong agent assumptions become **compounding slop** amplified through the codebase's existing patterns [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:16:37-00:17:53|direct|2026-07-03] [epistemic:: tentative]
- **You need structure, not necessarily state machines**, and **"modeling is not ceremony when it replaces confusion"** — model only the confusing parts, start rough and iterate; AI is good at helping you build the model [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:21:18-00:23:39|direct|2026-07-03]
- **Lineage:** the name mirrors **Gary Bernhardt's "functional core, imperative shell"**, and Khourshid endorses **Ken Wheeler's** view that "agent-driven workflows with a sprinkling of deterministic tools are a fool's errand" — it should be the other way around [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:03-00:19:52|direct|2026-07-03] [epistemic:: tentative]

## Detail

### The problem: unstructured delegation and slop code

Khourshid's diagnosis reframes the usual scapegoats. The problem with AI-assisted development is **not** vibe coding, AI "taking over," or even hallucination — it is **unstructured delegation**: deciding to "throw everything over the wall" and let the agents handle judgment, structure, implementation, and sometimes taste [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:06:49-00:07:24|direct|2026-07-03]. The output is **slop**, and "the slop works, so who cares?" — until users care, when the code rots from the inside out, features take longer to maintain, or security holes open up [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:07:24-00:07:53|direct|2026-07-03].

He defines the term precisely: **"slop code is code without a reliable model"** — code you can't fully understand or explain, and can't be sure covers the edge cases. It is not necessarily broken and might not even be *bad* code, but it has telltale properties: no clear domain boundaries, invariants that aren't explicit, states you can't inspect, behavior scattered throughout the app, and no safe way to change it [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:08:31-00:09:16|direct|2026-07-03]. Crucially this predates LLMs — it is the old "looks good to me" PR skim, now industrialized by the **"slop machine"** (his triple pun on state machine / slot machine): if the output isn't quite right you just "pull the lever again" and regenerate, and slop permeates the codebase [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:09:27-00:10:01|direct|2026-07-03] [epistemic:: tentative]. This is the same failure the wiki records as [[comprehension-debt|comprehension debt]] — code the team never internalized — reached from the modeling side rather than the team-knowledge side.

### Why more AI or more context doesn't fix it

AI won't rescue you from this because **LLMs "weren't trained on good code — they were trained on *all* our code"**, so they repeat and latch onto whatever patterns already exist in your codebase [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:10:01-00:10:36|direct|2026-07-03] [epistemic:: tentative]. And bigger context windows don't help: "more context does not mean more structure" — you can't keep shoving "you must follow this workflow exactly" into the prompt; the context just gets noisier, and larger context doesn't mean better performance [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:16:37-00:17:11|direct|2026-07-03] [epistemic:: tentative]. Worse, agents "fill in the gaps with what they think is best," and some assumptions are wrong; because AI follows existing patterns, those wrong assumptions are amplified into **compounding slop** [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:17:11-00:17:53|direct|2026-07-03] [epistemic:: tentative]. A missing model is a **missing blueprint** — like building a house one wall at a time with no design.

### The remedy: an explicit model

The industry keeps behavioral truth in two noisy places: **markdown** (skills, CLAUDE.md, agents.md, plans — natural-language intent) and **code** (a "noisy source of truth" where intent is buried under architecture and boilerplate — he claims ~90% of code has nothing to do with behavioral intent) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:10:36-00:11:35|direct|2026-07-03] [epistemic:: tentative]. The hidden third layer, and the talk's central theme, is an **explicit model**: a *structured* representation of how the system should behave (it can still contain natural language) that combines intent and execution, so that both the code and the app's intended behavior map directly to it [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:11:35-00:12:11|direct|2026-07-03].

State machines are Khourshid's preferred modeling form — behavior as **given-when-then** (Gherkin/Cucumber) mapping to states, events, and transitions on a graph — but not the only one: logical flows can use BPMN, statecharts, or flowcharts, and data can be modeled with domain-driven design [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:12:11-00:13:17|direct|2026-07-03] [epistemic:: tentative]. Why doesn't AI reach for models on its own? Because **"agents are very obedient, but they ironically don't have much agency"** — told to build a feature, an agent goes straight to code. The move is to supply the modeling intent: if you know how you want to model something, AI will *build that model for you*, and you refine by updating the model and referencing it in code — an executable description without the noise [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:13:22-00:14:38|direct|2026-07-03] [epistemic:: tentative].

### The failure modes that exclude models

Khourshid enumerates the ways projects skip the model, each of which the pattern is meant to prevent [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:14:38-00:16:37|direct|2026-07-03] [epistemic:: tentative]:

- **One-shotting** — prompt straight to result, when most apps need iteration and human input.
- **Prose control flow** — a skill that says "you must do this, never do this, do step 1/2/3" tries to encode control flow in natural language and just *hopes* the agent follows it (sometimes it won't). This is a direct critique of the imperative-skill style catalogued in the [[skill-checklist|skill checklist]].
- **Agents as the system** — throwing more agents at the problem "is just asking for more chaos if we don't constrain the system," a caution that sits alongside the [[domain-specific-agents|domain-specific agents]] and [[subagents|subagents]] multi-agent approaches.
- **Entanglement of concerns** — AI optimizes for "goal complete" and mixes everything together like a junior developer who forgets separation of concerns.

### The inversion and how to apply it

The solution is to **invert control**. Two app shapes are emerging: *LLMs that call programs* (all workflow logic in the LLM, trusting it as traffic controller — risky and lazy) and *programs that call LLMs* (deterministic core, non-deterministic edges) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:52-00:20:32|direct|2026-07-03]. Modern apps aren't one-shot; they need iteration steps in the middle, and *inside* those steps lives the deterministic structure with AI only at the nodes/edges [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:20:37-00:21:07|direct|2026-07-03] [epistemic:: tentative]. The canonical demo is an **XState email agent**: a state machine gathers requirements, then drafts, then iterates with the user, then sends — and the deterministic constraints make invalid states unreachable (impossible to send without an approved draft; impossible to draft without satisfied requirements), while the fuzzy parts (is anything missing? drafting the prose) are the non-deterministic edges [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:23:39-00:26:53|direct|2026-07-03] [epistemic:: tentative]. "This structure works for most things" — even building your own Cursor is "exactly this type of while loop."

The pattern is deliberately lightweight: **"modeling is not ceremony when it replaces confusion,"** so you model only the confusing parts and start rough (like UX prototyping), and **separation of concerns** still matters because AI won't slop up a codebase whose concerns are explicit and well separated [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:21:18-00:23:19|direct|2026-07-03]. The actionable exercise: pick one confusing workflow and model it explicitly, asking *what can be deterministic*, *where is iteration useful* (human-in-the-loop), and *where can logic be separated from the UI* [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:27:28-00:28:34|direct|2026-07-03].

### Lineage and framing

The name **"deterministic core, agentic shell"** comes from a recent article (unnamed in the talk) and consciously mirrors **Gary Bernhardt's "functional core, imperative shell"**; Khourshid also endorses **Ken Wheeler's** tweet that "agent-driven workflows with a sprinkling of deterministic tools are a fool's errand" — the deterministic workflow should be primary, with AI the sprinkling [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:03-00:19:52|direct|2026-07-03] [epistemic:: tentative]. His closing thesis: best practices didn't change; AI made them *easier to forget* and "more important now than ever," and "the model is how collaboration survives the speed" of building with AI [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:29:54-00:30:18|direct|2026-07-03].

**Epistemic note.** This concept rests on a single opinionated conference talk with clean audio (`sourced`). The named lineage (Ken Wheeler, Gary Bernhardt, "deterministic core, agentic shell" article), the technical terms (DFA/NFA, Gherkin/Cucumber, BPMN, useState), and the rhetorical figures (~90% of code, "10× speeds") are hedged `tentative`, as they are as-heard from a speech-to-text transcript or the speaker's own estimates.

## Related Pages

- [[david-khourshid|David Khourshid]] — the speaker and originator of the "slop code" framing.
- [[xstate|XState]] — his state-machine library, used to implement the pattern's demo.
- [[comprehension-debt|Comprehension Debt]] — the "code no one understands" failure that "slop code" restates from the modeling angle.
- [[spec-driven-development|Spec-Driven Development]] — the sibling "make an explicit artifact the source of truth" movement; the explicit model is spec-like for behavior.
- [[skill-checklist|Skill Checklist]] — the imperative-skill style whose "prose control flow" this pattern critiques.
- [[systems-thinking|Systems Thinking]] — the reasoning discipline the explicit model operationalizes.

## Sources

- [[src-2026-07-03-goodbye-slop-welcome-determinism|Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid]] — "Beyond the Prompt" conference talk, 2026-06-26 (YouTube transcript)
