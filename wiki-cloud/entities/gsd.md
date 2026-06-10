---
id: gsd
title: "GSD (Get-Shit-Done)"
type: entity
status: active
summary: "TÂCHES' Claude Code orchestration framework built around context
  engineering: every task runs in a fresh 200K-token subagent context to defeat
  context rot, coordinated through a .planning/ artifact tree on disk, with
  goal-backward Nyquist verification mapping each requirement to a test before code
  is written."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-04-16-claude-code-frameworks-report
epistemic_status: mixed
tags:
- gsd
- claude-code
- agentic-frameworks
- context-engineering
- subagents
- tooling
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "GSD (Get-Shit-Done)"
- "GSD"
- "Get-Shit-Done"
- "get-shit-done"
- "gsd"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

GSD (Get-Shit-Done, gsd-build/get-shit-done) is TÂCHES' Claude Code orchestration framework whose organizing thesis is that the dominant failure mode in long agent sessions is context rot — quality degrades past ~50% context fill — so every task runs in a *fresh* 200K-token [[subagents|subagent]] context, giving Task 50 the same quality budget as Task 1. Work is coordinated through a `.planning/` artifact tree on disk (requirements, roadmap, per-phase plans and summaries), with "plans are prompts, not documents," wave-based parallelism, per-agent model profiles, and goal-backward "Nyquist" verification that maps every requirement to an automated test command before code is written. Among the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] it is the context-engineering specialist — strongest for multi-day autonomous runs across many phases, at the cost of feeling over-structured for small work.

## Key Facts

- Authored by TÂCHES (solo dev), first commit Dec 2025, MIT-licensed; a v2 rewrite (gsd-2) is underway as a standalone CLI on the Pi SDK for direct harness control. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: tentative]
- Thesis: the dominant failure mode in long sessions is context rot (quality degrades past ~50% context fill); the fix is to run every task in a fresh 200K-token subagent context so Task 50 has the same quality budget as Task 1. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Architecture: 35+ specialized agents and 50+ slash commands orchestrated around a `.planning/` artifact tree (PROJECT/REQUIREMENTS/ROADMAP/STATE; research/codebase/intel; phases/XX-name/ with CONTEXT/RESEARCH/PLAN/SUMMARY/VERIFICATION/VALIDATION; seeds/threads/todos/debug/workstreams). [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Phase workflow: discuss-phase → (ui-phase or ai-integration-phase, optional) → plan-phase → execute-phase → code-review → verify-work → ship. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Distinctive moves: "plans are prompts, not documents" (PLAN.md written to be executable by a fresh subagent); target ~50% context fill not 80%; atomic per-task commits with phase/plan IDs; wave-based parallelism with strict file-overlap rejection; goal-backward "Nyquist" verification mapping every requirement to a test command before code is written (plan-checker rejects plans without verify commands); per-agent model profiles (quality/balanced/budget/inherit); 11+ runtimes. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Strength: keeps agents on-track for hours of autonomous work, resumable across sessions and machines; weakness: rigid atomicity feels over-structured for small tasks. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]

## Detail

GSD, by the solo developer TÂCHES, is the context-engineering entry among the Claude Code orchestration frameworks. Its load-bearing claim is that long agent sessions fail through context rot — output quality degrades once the context window is more than roughly half full — and that the cure is architectural: never let a single context accumulate. Every task executes in its own fresh 200K-token subagent context, so the last task in a long run has the same clean budget as the first. This is the inverse of the usual instinct to fill the window; GSD explicitly targets ~50% utilization rather than 80% [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced].

What makes fresh-context-per-task work is that all durable state lives on disk in a `.planning/` artifact tree rather than in any one conversation: requirements, roadmap, and per-phase folders holding context, research, atomic plans (2–3 tasks each), summaries, and verification/validation records. The maxim "plans are prompts, not documents" captures the discipline — a PLAN.md is written to be executed by a fresh subagent that has none of the authoring context, so it must be self-sufficient. Parallelism is wave-based with strict file-overlap rejection (no two concurrent agents may touch the same file), and verification is goal-backward: the "Nyquist" check maps every requirement to an automated test command *before* code is written, and the plan-checker rejects any plan lacking verify commands [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced].

This architecture is why the report's decision guide recommends GSD for multi-day autonomous runs across many phases and for brownfield work (its codebase-mapping and intel commands are called out as uniquely strong), and notes its weakness for small tasks where the rigid atomicity is overhead. GSD composes with the other frameworks — it provides the orchestration and fresh-context discipline while [[spec-kit|Spec Kit]] supplies portable specs and [[superpowers|Superpowers]] supplies in-session execution rigor. Star count (~35–48K), version (v1.36.0, Apr 14 2026, ~1,693 commits), and the gsd-2 rewrite status are point-in-time figures from a secondary synthesis and are treated as tentative. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: tentative]

## Related Pages

- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — head-to-head comparison with Spec Kit and Superpowers.
- [[spec-kit|Spec Kit]] — the spec-gate framework it composes with.
- [[superpowers|Superpowers]] — the execution-discipline framework it composes with.
- [[subagents|Subagents]] — the fresh-context-per-task primitive GSD is built on.
- [[claude-code|Claude Code]] — the primary host CLI (one of 11+ supported runtimes).

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
