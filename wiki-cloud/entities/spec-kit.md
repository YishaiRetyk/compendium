---
id: spec-kit
title: "Spec Kit"
type: entity
status: active
summary: "GitHub's official spec-driven-development toolkit (CLI named Specify):
  the specification is the version-controlled source of truth and code is a
  regenerable expression. Tool-agnostic across 20+ agents, with a constitution +
  spec → clarify → plan → tasks → analyze → implement workflow."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-04-16-claude-code-frameworks-report
epistemic_status: mixed
tags:
- spec-kit
- spec-driven-development
- claude-code
- agentic-frameworks
- github
- tooling
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Spec Kit"
- "Specify"
- "spec-kit"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Spec Kit is GitHub's official toolkit for [[spec-driven-development|Spec-Driven Development]], built on the inversion "specifications don't serve code — code serves specifications." It ships a Python CLI named Specify (`uv tool install specify-cli`) that scaffolds a `.specify/` tree — a 9-article `constitution.md`, cross-platform scripts, and per-feature spec/plan/tasks markdown. Its namespaced commands run constitution → specify → clarify → plan → tasks → analyze → implement. Spec Kit's distinguishing feature among the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] is that it is tool-agnostic across 20+ agents with cross-agent handoff as a first-class concern — the spec is portable, git-diffable, and survives a switch of underlying agent. Its weaknesses are verbosity ("sea of markdown") and manual spec↔code reconciliation.

## Key Facts

- Official GitHub project led by Den Delimarsky (research lineage from John Lam), released Sep 2, 2025, MIT-licensed, ~50K stars within months. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: tentative]
- Thesis: "specifications don't serve code — code serves specifications" — the spec is the primary version-controlled artifact; code is a regenerable expression (SDD inverts the traditional source of truth). [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]
- Ships a Python CLI named Specify (`uv tool install specify-cli`); `specify init --ai claude` scaffolds `.specify/` with `memory/constitution.md` (9-article project DNA), cross-platform `scripts/{bash,powershell}/`, spec/plan/tasks templates, and per-feature `specs/NNN-feature/{spec,plan,tasks}.md`. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]
- Namespaced `/speckit.*` workflow: constitution → specify → clarify (≤5 multiple-choice disambiguation questions) → plan → tasks → analyze (read-only quality gate, severities CRITICAL/HIGH/MEDIUM/LOW) → implement. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]
- Tool-agnostic by design — works with 20+ agents (Claude, Copilot, Cursor, Gemini, Codex, Windsurf, Qwen, Junie, …) and supports switching agents mid-project without changing the spec; it is the only one of the three frameworks with cross-agent handoff as a first-class concern. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]
- Constitution articles are non-negotiable: TDD mandatory (Article III — tests written, approved, and seen to fail before implementation), simplicity (≤3 projects initially), real DBs over mocks; templates force `[NEEDS CLARIFICATION]` markers and enforce constitutional compliance at phase gates. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced]

## Detail

Spec Kit is the official GitHub entry in the Claude Code orchestration-framework landscape, led by Den Delimarsky with research lineage from John Lam. It is the concrete tooling implementation of [[spec-driven-development|Spec-Driven Development]]: rather than treating the specification as scaffolding that is discarded once code exists, Spec Kit makes the spec the primary, version-controlled artifact and the code a regenerable expression of it [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced].

The CLI (Specify) scaffolds a `.specify/` directory whose centerpiece is `memory/constitution.md`, a 9-article "project DNA" file whose articles are treated as non-negotiable constraints enforced at phase gates — most notably Article III's mandatory test-first discipline (tests must be written, approved, and *seen to fail* before implementation), echoing the same "watch the test fail" rule [[superpowers|Superpowers]] enforces via skill. Templates throughout are used as constraints: they force `[NEEDS CLARIFICATION]` markers, structure thinking via checklists, and enforce constitutional compliance. The `/speckit.analyze` step is a read-only quality gate that never mutates files — it only flags issues at CRITICAL/HIGH/MEDIUM/LOW severities [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: sourced].

Spec Kit's defining advantage is portability: it was designed to outlive any single agent, working across 20+ tools and supporting mid-project agent switches because the spec — not the agent's in-session state — is the source of truth. Markdown specs are git-diffable and reviewable with no proprietary format, which makes Spec Kit the natural choice for mixed-tool teams and for producing reviewable artifacts for stakeholders. Its acknowledged weaknesses are verbosity ("sea of markdown"), long runtimes, manual spec↔code reconciliation, and community concern about maintenance pace [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|direct|2026-06-09] [epistemic:: tentative]. Star counts, dates, and version specifics are point-in-time figures from a secondary synthesis and may have moved.

## Related Pages

- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — head-to-head comparison with Superpowers and GSD.
- [[spec-driven-development|Spec-Driven Development]] — the methodology Spec Kit implements.
- [[superpowers|Superpowers]] — the execution-discipline framework it composes with.
- [[gsd|GSD (Get-Shit-Done)]] — the context-engineering framework it composes with.
- [[claude-code|Claude Code]] — one of the 20+ agents Spec Kit targets.

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
