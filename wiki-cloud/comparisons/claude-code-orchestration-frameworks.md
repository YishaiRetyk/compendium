---
id: claude-code-orchestration-frameworks
title: "Claude Code Orchestration Frameworks"
type: comparison
status: active
summary: "Head-to-head comparison of the three dominant Claude Code orchestration
  frameworks — Spec Kit (the spec gate), Superpowers (execution discipline), and GSD
  (context engineering) — on constraint, workflow, artifacts, context strategy,
  parallelism, and verification, plus where they agree, diverge, and compose."
created_at: 2026-06-09
updated_at: 2026-06-11
sources:
- src-2026-04-16-claude-code-frameworks-report
epistemic_status: mixed
tags:
- claude-code
- agentic-frameworks
- spec-kit
- superpowers
- gsd
- framework-comparison
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Claude Code Orchestration Frameworks"
- "Spec Kit vs Superpowers vs GSD"
- "claude-code-orchestration-frameworks"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Three frameworks dominate the Claude Code "opinionated assembly" layer, occupying different points on one axis and increasingly composing rather than competing: [[spec-kit|Spec Kit]] (GitHub — the spec gate), [[superpowers|Superpowers]] (Jesse Vincent — execution discipline), and [[gsd|GSD (Get-Shit-Done)]] (TÂCHES — context engineering). Each constrains the agent differently — Spec Kit via a version-controlled spec, Superpowers via a mandatory TDD process, GSD via fresh-context-per-task — but all converge on skills over prompts, on-disk state, [[subagents|subagent]] isolation, test-first verification, and atomic commits. The report's one-line synthesis: *Spec Kit specifies, GSD stabilizes, Superpowers executes.*

## Bottom Line

Choose by the constraint you most need: Spec Kit for mixed-tool teams and long-lived projects needing portable, reviewable specs; Superpowers for a solo developer shipping a focused feature with the strongest in-session discipline; GSD for multi-day autonomous runs across many phases where context isolation is the killer feature. For throwaway single-file prototypes, none of them — vanilla Claude Code is fine. Increasingly the frameworks are *stacked* rather than chosen. [prov:src-2026-04-16-claude-code-frameworks-report#sec:decision-guide|derived|2026-06-09] [epistemic:: sourced]

## Comparison Table

| Axis | Spec Kit | Superpowers | GSD |
|---|---|---|---|
| Origin | GitHub (official), Sep 2025 [prov:src-2026-04-16-claude-code-frameworks-report#sec:comparative-matrix\|derived\|2026-06-09] | Jesse Vincent (obra), Oct 2025 | TÂCHES, Dec 2025 |
| Primary constraint | The spec gate | Process discipline (TDD) | Context engineering |
| Mental model | Specs are truth; code is regenerable | Brainstorm → plan → TDD → review, mandatory | Fresh subagent contexts; atomic plans on disk |
| Workflow | constitution → specify → clarify → plan → tasks → analyze → implement | brainstorm → write-plan → execute-plan + ~14 skills | discuss → (ui/ai) → plan → execute → review → verify → ship |
| Artifact location | `.specify/specs/<feature>/` | In-session (skills + hooks) | `.planning/phases/<phase>/` |
| Context strategy | Specs survive sessions; agent-agnostic | SessionStart hook re-primes after compact | Every task in a fresh 200K window |
| Parallelism | Manual (per task list) | `dispatching-parallel-agents` skill | Wave-based with file-overlap rejection |
| Verification | `/speckit.analyze` read-only gate | `verification-before-completion` + code-reviewer subagent | Nyquist: requirement→test mapped before code |
| Multi-agent support | 20+ runtimes (first-class) | Claude Code primary; multi-runtime variants | 11+ runtimes |
| License | MIT | MIT | MIT |
| Sweet spot | Multi-agent teams; reviewable specs | Disciplined feature shipping with tests | Long autonomous runs across phases |
| Weakness | Verbose; manual spec/code sync | Token-heavy; rigid for small tasks | Over-structured for small work |

*(All rows sourced from the comparative matrix [prov:src-2026-04-16-claude-code-frameworks-report#sec:comparative-matrix|derived|2026-06-09]; star counts omitted from this table as point-in-time figures — see the individual entity pages, where they are marked tentative.)* [epistemic:: sourced]

## Detailed Comparison

### Where they agree

All three frameworks converge on five practices [prov:src-2026-04-16-claude-code-frameworks-report#sec:cross-cutting-themes|derived|2026-06-09] [epistemic:: sourced]: (1) **skills over prompts** — file-based, model-discoverable, composable packaging beats monolithic system prompts; (2) **externalize state to disk** — structured artifacts (specs, plans, summaries) survive context compaction and session restarts; (3) **subagent isolation matters** — code review, research, and parallel execution happen in forked contexts, a direct application of [[progressive-disclosure|Progressive Disclosure]] across agents; (4) **test-first verification is non-negotiable** — Superpowers enforces it via skill, Spec Kit via constitutional Article III, GSD via Nyquist plan-checker rejection; and (5) **atomic, traceable commits** tied to plan/task identifiers.

### Where they diverge

The frameworks differ on four axes [prov:src-2026-04-16-claude-code-frameworks-report#sec:cross-cutting-themes|derived|2026-06-09] [epistemic:: sourced]: **where the spec lives** (Spec Kit: `specs/<feature>/`; Superpowers: ephemeral in skill execution; GSD: `.planning/phases/<phase>/PLAN.md`); **who owns parallelism** (Spec Kit punts to the agent; Superpowers has an explicit skill; GSD orchestrates waves with file-conflict resolution); **auto-invocation vs explicit triggering** (Superpowers' "1% chance" rule is the most aggressive; GSD favors explicit `/gsd-*` commands; Spec Kit splits the difference with namespaced `/speckit.*` calls); and **portability ambition** (Spec Kit was designed to outlive any single agent, while Superpowers and GSD are pragmatically multi-runtime but Claude-Code-first).

### Composability

The frameworks are increasingly stacked rather than chosen: use Spec Kit for the constitution and spec artifacts (portable, reviewable), GSD for the `.planning/` orchestration and fresh-context discipline, and Superpowers for in-session execution rigor (TDD, code review). The dev.to "skills stack" pattern formalizes this combination, and the report's executive summary frames the division of labor as *gstack thinks, GSD stabilizes, Superpowers executes, Spec Kit specifies* [prov:src-2026-04-16-claude-code-frameworks-report#sec:cross-cutting-themes|derived|2026-06-09] [prov:src-2026-04-16-claude-code-frameworks-report#sec:executive-summary|derived|2026-06-09] [epistemic:: sourced].

### Decision guide

Matching situation to framework [prov:src-2026-04-16-claude-code-frameworks-report#sec:decision-guide|derived|2026-06-09] [epistemic:: sourced]: a solo developer shipping a focused feature → **Superpowers** alone (least overhead, strongest discipline); multi-day autonomous runs with many phases → **GSD** (context isolation is the killer feature); a mixed-tool team (Copilot + Claude + Cursor) → **Spec Kit** (the only one with cross-agent specs); a throwaway single-file prototype → none of these; a brownfield codebase needing mapping first → GSD's codebase-mapping/intel commands; reviewable artifacts for stakeholders → Spec Kit's markdown specs in git; frequent context compactions hurting quality → GSD (fresh contexts) or Superpowers (SessionStart hook).

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
