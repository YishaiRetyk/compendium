---
id: geoffrey-huntley
title: Geoffrey Huntley
type: entity
status: active
summary: "Software engineer and AI-tooling commentator who originated the 'Ralph' autonomous-coding-loop technique and publishes opinionated guidance on agentic development practices."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-ralph-playbook
epistemic_status: sourced
tags:
  - person
  - ai-tooling
  - autonomous-agents
  - ralph
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "Geoffrey Huntley"
  - "ghuntley"
  - "GeoffreyHuntley"
  - "Geoff Huntley"
  - "geoffrey-huntley"
has_contradictions: false
knowledge_domain: biography
example: false
---

## TL;DR

Geoffrey Huntley is the originator of [[Ralph (Autonomous Coding Loop)]], the deliberately minimal `while :; do cat PROMPT.md | claude ; done` pattern for running agentic CLI coders autonomously. His original write-up at `ghuntley.com/ralph` plus a series of YouTube videos in late 2025 popularized the technique on AI-tooling timelines through December 2025, prompting community syntheses (notably Clayton Farr's [[The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]]) and a public counter-correction ("nah") when summaries departed from his framing.

## Key Facts

- Originated and named the "Ralph" autonomous-coding-loop technique, published at `ghuntley.com/ralph` and elaborated in YouTube videos. [prov:src-2026-05-06-ralph-playbook#para1|direct|2026-05-06]
- His framing came to dominate AI-tooling timelines in December 2025. [prov:src-2026-05-06-ralph-playbook#para1|direct|2026-05-06]
- Posts on X as `@GeoffreyHuntley`. [prov:src-2026-05-06-ralph-playbook#para1|direct|2026-05-06]
- Publicly corrected community summaries that departed from his framing — the "nah" tweet is what motivated Clayton Farr to write a closer-to-the-source playbook. [prov:src-2026-05-06-ralph-playbook#para1|direct|2026-05-06]
- Recommends `--dangerously-skip-permissions` autonomous operation gated only by sandbox isolation, framed by the maxim "It's not if it gets popped, it's when. And what is the blast radius?". [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]

## Detail

The Ralph technique attributed to Huntley reduces autonomous coding to four moving parts: a bash `while` loop that re-feeds a fixed `PROMPT.md` to a CLI agent, an `IMPLEMENTATION_PLAN.md` file persisting on disk as cross-iteration shared state, an `AGENTS.md` operational guide loaded each iteration, and a `specs/` directory acting as the contract for what to build. The loop's continuation mechanism is intentionally dumb — bash restarts the agent, the agent reads the plan from disk, picks the most important task, implements + tests + commits, then exits. Each iteration starts with a fresh context window, and the only inter-iteration state is the disk.

Beyond the loop itself, Huntley's framing emphasizes:

- **Context discipline:** advertised 200K-token windows are about 176K usable, with a 40-60% "smart zone"; tight tasks plus one task per loop drives toward 100% smart-zone utilization.
- **Backpressure:** tests, typechecks, lints, and builds are the downstream signals that reject invalid work — see [[Backpressure]].
- **Plan disposability:** regenerating `IMPLEMENTATION_PLAN.md` is cheap (one planning loop) and preferable to letting Ralph go in circles.
- **Move outside the loop:** the operator's job is to engineer the environment Ralph runs in, not to do the work in line.

Huntley's specific phrasing patterns ("study", "don't assume not implemented", "using parallel subagents", "Ultrathink", "capture the why") are themselves prescriptions, surfaced as a checklist by downstream synthesizers.

The originating posts and videos are referenced second-hand in this wiki via Clayton Farr's playbook; primary sources from `ghuntley.com/ralph` and the `youtube.com/watch?v=O2bBWDoxO4s` video have not yet been ingested directly.

## Related Pages

- [[Ralph (Autonomous Coding Loop)]] — the technique he originated.
- [[Backpressure]] — the steering mechanism his framing makes central to autonomous coding.
- [[Claude Code]] — the reference CLI agent for Ralph's invocation pattern (`claude -p --dangerously-skip-permissions --output-format=stream-json --model opus`).

## Sources

- [[The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr's synthesis explicitly built around Huntley's posts and videos (2026-05-06).
