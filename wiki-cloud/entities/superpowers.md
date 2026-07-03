---
id: superpowers
title: "Superpowers"
type: entity
status: active
summary: "Jesse Vincent's Claude Code framework that enforces execution discipline:
  a mandatory brainstorm → plan → implement → review progression hard-wired into
  ~14 composable skills, plus a SessionStart hook that re-primes after clear/compact.
  Built to stop stock agents skipping steps and lying about success."
created_at: 2026-06-09
updated_at: 2026-07-03
sources:
- src-2026-04-16-claude-code-frameworks-report
- src-2026-07-03-building-great-agent-skills
epistemic_status: mixed
tags:
- superpowers
- claude-code
- agentic-frameworks
- test-driven-development
- tooling
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Superpowers"
- "obra/superpowers"
- "superpowers"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Superpowers (obra/superpowers) is Jesse Vincent's opinionated Claude Code framework whose thesis is that stock agents skip steps and lie about success. Its remedy is execution discipline: a mandatory brainstorm → plan → implement → review progression hard-wired into ~14 composable [[agent-skills|Agent Skills]], with skills constraining which skill may run next, code review run in a fresh [[subagents|subagent]] context, and a SessionStart hook that re-injects priming after `clear`/`compact`. Among the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] it is the execution-rigor specialist — strongest for disciplined feature shipping with tests, at the cost of being token-heavy and rigid for trivial tasks (Simon Willison: "like riding your bike in a higher gear — faster but more effort").

## Key Facts

- Authored by Jesse Vincent (Prime Radiant; creator of Request Tracker); released v1 on Oct 9, 2025 — the same day Anthropic shipped the plugin system — and accepted into Anthropic's official marketplace Jan 15, 2026. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: tentative]
- Thesis: stock agents skip steps and lie about success; the fix is to force a mandatory brainstorm → plan → implement → review progression by hard-wiring it into ~14 composable skills. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: sourced]
- Architecture: ~14 skills (brainstorming, writing-plans, executing-plans, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review, using-git-worktrees, dispatching-parallel-agents, …) + 3 commands (/brainstorm, /write-plan, /execute-plan) + 1 code-reviewer subagent + a SessionStart hook re-injecting priming after clear/compact. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: sourced]
- Distinctive moves: "invoke a skill whenever there's even a 1% chance one applies — not negotiable"; hard-coded priority (user instructions → Superpowers skills → default behavior); TDD enforcement ("if you didn't watch the test fail, you don't know if it tests the right thing"); skills constrain which skill runs next (brainstorming → writing-plans only); code review in a fresh subagent context; git worktrees for parallel-agent isolation; zero-dependency by design. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: sourced]
- Strength is disciplined execution; weakness is token-heaviness and redundancy for trivial tasks — Simon Willison likened it to "riding your bike in a higher gear — faster but more effort"; the project advertised a 94% PR rejection rate to deter low-effort agent contributions. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: tentative]
- [[matt-pocock|Matt Pocock]] characterizes Superpowers as "primarily model-invoked skills" (it "gives the agent superpowers"), contrasting it with his own mostly user-invoked skill set — the trade being that model invocation maximizes flexibility and agent autonomy at the cost of higher context load and the unpredictability of whether the agent invokes a skill at the right time. [prov:src-2026-07-03-building-great-agent-skills#t00:06:02-00:07:15|direct|2026-07-03] [epistemic:: tentative]

## Detail

Superpowers, by Jesse Vincent (Prime Radiant; creator of Request Tracker), is the execution-discipline entry among the Claude Code orchestration frameworks. Where [[spec-kit|Spec Kit]] constrains via the spec and [[gsd|GSD (Get-Shit-Done)]] constrains via fresh context, Superpowers constrains via *process*: it hard-wires a mandatory brainstorm → plan → implement → review progression into ~14 composable skills so the agent cannot skip the steps a careful engineer would take. Skills are sequenced — brainstorming can hand off only to writing-plans — and the most aggressive rule in the landscape is its "1% chance" directive: invoke a skill whenever there's even a 1% chance one applies, non-negotiable [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: sourced].

Its test-first stance is identical in spirit to Spec Kit's constitutional Article III: "if you didn't watch the test fail, you don't know if it tests the right thing." Code review happens in a fresh subagent context to avoid contamination from the implementing context, and parallel work is isolated via git worktrees. A SessionStart hook re-injects the framework's priming after a `clear` or `compact`, so the discipline survives context resets — Superpowers' answer to the same context-continuity problem that GSD solves with on-disk artifacts. The framework is zero-dependency by design [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: sourced].

The cost of this rigor is tokens and ceremony: Superpowers is heavyweight and can be redundant for trivial tasks, which is why the report's decision guide recommends it for solo developers shipping a focused feature with strong discipline, and recommends composing it with the other frameworks (Superpowers for in-session execution rigor, GSD for orchestration, Spec Kit for portable specs) rather than using it for throwaway work. Star count (~156K, reported by a single secondary source), version (v5.0.7, Mar 2026), and dates are point-in-time figures and treated as tentative — the ~156K figure in particular is unusually high and unverified against a primary source. [prov:src-2026-04-16-claude-code-frameworks-report#sec:superpowers|derived|2026-06-09] [epistemic:: tentative]

## Related Pages

- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — head-to-head comparison with Spec Kit and GSD.
- [[spec-kit|Spec Kit]] — the spec-gate framework it composes with.
- [[gsd|GSD (Get-Shit-Done)]] — the context-engineering framework it composes with.
- [[agent-skills|Agent Skills]] — the building block Superpowers is assembled from.
- [[subagents|Subagents]] — used for isolated code review and parallel agents.
- [[claude-code|Claude Code]] — the host CLI; distributed via the Anthropic marketplace and obra/superpowers-marketplace.
- [[matt-pocock|Matt Pocock]] — contrasts his user-invoked skills with Superpowers' model-invoked design.

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
- [[src-2026-07-03-building-great-agent-skills|Building Great Agent Skills: The Missing Manual — Matt Pocock]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
