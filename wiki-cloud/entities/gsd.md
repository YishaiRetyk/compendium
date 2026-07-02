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
updated_at: 2026-07-03
sources:
- src-2026-04-16-claude-code-frameworks-report
- src-2026-07-03-gsd-core-repo
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
- "GSD Core"
has_contradictions: false
knowledge_domain: software
example: false
decision_history:
- dr-2026-07-03-repository-source-type
---

## TL;DR

GSD (Get-Shit-Done) is the Claude Code orchestration framework — originated by TÂCHES, now continued as **GSD Core** (`open-gsd/gsd-core`, npm `@opengsd/gsd-core`) under the OpenGSD org after the original `gsd-build/get-shit-done` repo was archived — whose organizing thesis is that the dominant failure mode in long agent sessions is context rot, so every heavy task runs in a *fresh* 200K-token [[subagents|subagent]] context, giving Task 50 the same quality budget as Task 1. The framework's own docs now state this first-party: fresh-context subagents are "a structural solution", not a workaround. Work is coordinated through a `.planning/` artifact tree on disk, with a five-step per-phase loop (Discuss → Plan → Execute → Verify → Ship), "plans are prompts, not documents," wave-based parallelism, per-agent model profiles, and goal-backward "Nyquist" verification. Among the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] it is the context-engineering specialist — strongest for multi-day autonomous runs across many phases, at the cost of feeling over-structured for small work. Now multi-runtime: the installer targets Claude Code, OpenCode, Gemini CLI, Codex, Cursor, and more.

## Key Facts

- Authored by TÂCHES (solo dev), first commit Dec 2025, MIT-licensed; a v2 rewrite (gsd-2) is underway as a standalone CLI on the Pi SDK for direct harness control. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: tentative] *(Superseded in part: the project's continuation materialized as GSD Core under the OpenGSD org — see the 2026-07-03 claims below.)*
- The project was renamed to `@opengsd/gsd-core`: the legacy `get-shit-done-cc`/`get-shit-done-redux` package lineage (versions 1.0.0→1.42.x) is retired to an archive, and the new version stream restarts at 1.0.0. The old `gsd-build/get-shit-done` repo is an archived redirect. [prov:src-2026-07-03-gsd-core-repo#path:CHANGELOG.md:L482-L488|direct|2026-07-03]
- Current package (snapshot 2026-07-03, branch `next`): `@opengsd/gsd-core` v1.7.0-rc.1, MIT, author "OpenGSD" — an org line, no longer solo-attributed. [prov:src-2026-07-03-gsd-core-repo#path:package.json:L1-L5|direct|2026-07-03] [prov:src-2026-07-03-gsd-core-repo#path:package.json:L38-L40|direct|2026-07-03]
- The context-rot thesis is stated first-party in the framework's docs: quality degrades silently as the window fills ("the model does not fail loudly"), and fresh-context subagents are "a structural solution", not a workaround. [prov:src-2026-07-03-gsd-core-repo#path:docs/explanation/context-engineering.md:L7-L13|direct|2026-07-03]
- At the snapshot commit the repo ships 34 agent definitions and 69 command files, and the npx installer compiles them per-runtime (Claude Code, OpenCode, Gemini CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf); copying `agents/`/`commands/` directly is unsupported. [prov:src-2026-07-03-gsd-core-repo#commit:69fef7c0|direct|2026-07-03] [prov:src-2026-07-03-gsd-core-repo#sec:quickstart|direct|2026-07-03]
- GSD Core self-describes as "light-weight" — a capability claim from its own README. [prov:src-2026-07-03-gsd-core-repo#sec:readme|direct|2026-07-03] [epistemic:: tentative]
- Thesis: the dominant failure mode in long sessions is context rot (quality degrades past ~50% context fill); the fix is to run every task in a fresh 200K-token subagent context so Task 50 has the same quality budget as Task 1. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Architecture: 35+ specialized agents and 50+ slash commands orchestrated around a `.planning/` artifact tree (PROJECT/REQUIREMENTS/ROADMAP/STATE; research/codebase/intel; phases/XX-name/ with CONTEXT/RESEARCH/PLAN/SUMMARY/VERIFICATION/VALIDATION; seeds/threads/todos/debug/workstreams). [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced] *(Counts superseded: the 2026-07-03 snapshot measures 34 agent definitions and 69 command files — see the snapshot claims below; the artifact-tree architecture itself is unchanged.)*
- Phase workflow: discuss-phase → (ui-phase or ai-integration-phase, optional) → plan-phase → execute-phase → code-review → verify-work → ship. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Distinctive moves: "plans are prompts, not documents" (PLAN.md written to be executable by a fresh subagent); target ~50% context fill not 80%; atomic per-task commits with phase/plan IDs; wave-based parallelism with strict file-overlap rejection; goal-backward "Nyquist" verification mapping every requirement to a test command before code is written (plan-checker rejects plans without verify commands); per-agent model profiles (quality/balanced/budget/inherit); 11+ runtimes. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]
- Strength: keeps agents on-track for hours of autonomous work, resumable across sessions and machines; weakness: rigid atomicity feels over-structured for small tasks. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced]

## Detail

GSD, by the solo developer TÂCHES, is the context-engineering entry among the Claude Code orchestration frameworks. Its load-bearing claim is that long agent sessions fail through context rot — output quality degrades once the context window is more than roughly half full — and that the cure is architectural: never let a single context accumulate. Every task executes in its own fresh 200K-token subagent context, so the last task in a long run has the same clean budget as the first. This is the inverse of the usual instinct to fill the window; GSD explicitly targets ~50% utilization rather than 80% [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced].

What makes fresh-context-per-task work is that all durable state lives on disk in a `.planning/` artifact tree rather than in any one conversation: requirements, roadmap, and per-phase folders holding context, research, atomic plans (2–3 tasks each), summaries, and verification/validation records. The maxim "plans are prompts, not documents" captures the discipline — a PLAN.md is written to be executed by a fresh subagent that has none of the authoring context, so it must be self-sufficient. Parallelism is wave-based with strict file-overlap rejection (no two concurrent agents may touch the same file), and verification is goal-backward: the "Nyquist" check maps every requirement to an automated test command *before* code is written, and the plan-checker rejects any plan lacking verify commands [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: sourced].

This architecture is why the report's decision guide recommends GSD for multi-day autonomous runs across many phases and for brownfield work (its codebase-mapping and intel commands are called out as uniquely strong), and notes its weakness for small tasks where the rigid atomicity is overhead. GSD composes with the other frameworks — it provides the orchestration and fresh-context discipline while [[spec-kit|Spec Kit]] supplies portable specs and [[superpowers|Superpowers]] supplies in-session execution rigor. Star count (~35–48K), version (v1.36.0, Apr 14 2026, ~1,693 commits), and the gsd-2 rewrite status are point-in-time figures from a secondary synthesis and are treated as tentative. [prov:src-2026-04-16-claude-code-frameworks-report#sec:gsd|derived|2026-06-09] [epistemic:: tentative]

As of the 2026-07-03 repository snapshot, the project's evolution is confirmed by primary evidence: development moved from `gsd-build/get-shit-done` (now an archived redirect) to the OpenGSD org as **GSD Core**, with the legacy package lineage (`get-shit-done-cc`/`get-shit-done-redux`, 1.0.0→1.42.x) rolled into an archive and a fresh `@opengsd/gsd-core` version stream restarting at 1.0.0 [prov:src-2026-07-03-gsd-core-repo#path:CHANGELOG.md:L482-L488|direct|2026-07-03]. The five-step per-phase loop (Discuss → Plan → Execute in parallel waves with clean 200k-token executor contexts → Verify → Ship) is now the README's canonical workflow description [prov:src-2026-07-03-gsd-core-repo#sec:how-it-works|direct|2026-07-03], and the context-rot framing the April report attributed to the project is verifiable in the framework's own explanation docs [prov:src-2026-07-03-gsd-core-repo#path:docs/explanation/context-engineering.md:L27-L31|direct|2026-07-03]. This page's earlier report-derived claims about the framework's *core mechanics* (fresh-context subagents, the `.planning/` artifact tree, wave parallelism, goal-backward verification) remain consistent with the primary source; its point-in-time *project facts* (solo authorship, version, repo home, and the agent/command counts — 35+/50+ then, 34/69 at the snapshot) are superseded by the snapshot claims above.

## Related Pages

- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — head-to-head comparison with Spec Kit and Superpowers.
- [[spec-kit|Spec Kit]] — the spec-gate framework it composes with.
- [[superpowers|Superpowers]] — the execution-discipline framework it composes with.
- [[subagents|Subagents]] — the fresh-context-per-task primitive GSD is built on.
- [[claude-code|Claude Code]] — the primary host CLI (one of 11+ supported runtimes).

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
- [[src-2026-07-03-gsd-core-repo|open-gsd/gsd-core — GSD Core repository snapshot]]: primary repository snapshot at commit `69fef7c0` (July 2026)
