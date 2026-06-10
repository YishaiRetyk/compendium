---
id: spec-driven-development
title: "Spec-Driven Development"
type: concept
status: active
summary: "The methodology where the specification is the primary, version-controlled
  source of truth and code is a regenerable expression of it — inverting the
  traditional relationship in which specs are throwaway scaffolding for code.
  Implemented most directly by GitHub's Spec Kit."
created_at: 2026-06-09
updated_at: 2026-06-09
sources:
- src-2026-04-16-claude-code-frameworks-report
epistemic_status: mixed
tags:
- spec-driven-development
- agentic-frameworks
- claude-code
- methodology
- spec-kit
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Spec-Driven Development"
- "SDD"
- "spec-driven-development"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Spec-Driven Development (SDD) is the methodology captured by the slogan "specifications don't serve code — code serves specifications." It inverts the traditional source of truth: instead of treating the spec as throwaway scaffolding discarded once code exists, SDD makes the specification the primary, version-controlled artifact and treats code as a regenerable expression of it. In an AI-coding context this matters because a durable, reviewable, git-diffable spec can outlive any single agent and be regenerated into code by whichever tool is in use. SDD is implemented most directly by [[spec-kit|Spec Kit]], whose constitution + spec → clarify → plan → tasks → analyze → implement workflow operationalizes it; it sits alongside the execution-discipline and context-engineering approaches of the other [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]].

## Key Facts

- Core inversion: "specifications don't serve code — code serves specifications" — the spec is the primary version-controlled artifact; code is a regenerable expression, reversing the traditional source of truth. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: sourced]
- SDD's practical payoff in AI coding is portability: a markdown spec is git-diffable and reviewable with no proprietary format, so it survives a switch of underlying agent and supports cross-agent handoff. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: sourced]
- SDD is typically enforced through non-negotiable constraints (e.g. Spec Kit's constitution articles: mandatory TDD with tests seen to fail before implementation, simplicity limits, real DBs over mocks) and templates that force `[NEEDS CLARIFICATION]` markers at phase gates. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: sourced]
- Acknowledged weaknesses of the SDD approach include verbosity ("sea of markdown"), long runtimes, and manual spec↔code reconciliation. [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: tentative]

## Detail

Spec-Driven Development reframes what the durable artifact of a software project is. In the conventional flow, a specification is written, code is produced from it, and the spec then rots while the code becomes the de facto truth. SDD inverts this: the specification is the version-controlled source of truth, and code is a regenerable downstream expression. The slogan from the Spec Kit manifesto — "specifications don't serve code — code serves specifications" — is the compact statement of the inversion [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: sourced].

The approach is especially load-bearing for AI-assisted development because it decouples intent from the agent that implements it. A reviewable, git-diffable markdown spec is portable across tools and survives both context compaction and a change of underlying agent — which is why the SDD-native [[spec-kit|Spec Kit]] treats cross-agent handoff as a first-class concern across 20+ agents. SDD is usually paired with hard constraints rather than left as a style: Spec Kit encodes a 9-article "constitution" whose articles (mandatory test-first development, simplicity limits, real databases over mocks) are enforced at phase gates, and uses templates that force explicit `[NEEDS CLARIFICATION]` markers so ambiguity surfaces before implementation [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: sourced].

SDD is one of three constraint philosophies in the [[claude-code-orchestration-frameworks|Claude Code orchestration-framework]] landscape: it constrains via the spec, where [[superpowers|Superpowers]] constrains via a mandatory TDD process and [[gsd|GSD (Get-Shit-Done)]] constrains via fresh-context-per-task. Its trade-off is verbosity and the ongoing manual work of keeping spec and code reconciled — the "sea of markdown" critique — which is why it is best suited to multi-agent teams and long-lived projects that genuinely benefit from a reviewable, portable spec artifact [prov:src-2026-04-16-claude-code-frameworks-report#sec:spec-kit|derived|2026-06-09] [epistemic:: tentative].

## Related Pages

- [[spec-kit|Spec Kit]] — the toolkit that implements SDD.
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — SDD as one of three constraint philosophies.
- [[superpowers|Superpowers]] — the process-discipline alternative.
- [[gsd|GSD (Get-Shit-Done)]] — the context-engineering alternative.

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
