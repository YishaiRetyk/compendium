---
id: subagents
title: "Subagents"
type: concept
status: active
summary: "Isolated Claude instances with their own context window, tool allowlist,
  and optional model. The defining benefit is context isolation — a subagent can
  process 100K tokens and return a distilled ~500-token summary while the parent
  context stays clean — making them the substrate for research, code review, and
  parallel execution in Claude Code frameworks."
created_at: 2026-06-09
updated_at: 2026-07-03
sources:
- src-2026-04-16-claude-code-frameworks-report
- src-2026-07-03-domain-specific-agents
epistemic_status: mixed
tags:
- subagents
- claude-code
- context-engineering
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Subagents"
- "Subagent"
- "Sub-agents"
- "subagents"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Subagents (`.claude/agents/<name>.md`) are isolated Claude instances, each with its own context window, tool allowlist, and optionally its own model. Their defining benefit is context isolation: a research subagent can churn through 50 files / 100K tokens and return a ~500-token distilled summary, so the parent's context stays clean — a direct application of [[progressive-disclosure|Progressive Disclosure]] across agents. Routing to a subagent depends on its description; the markers "Use PROACTIVELY" and "MUST BE USED" markedly increase auto-delegation, so descriptions should read as routing rules, not capability summaries. Subagents are the shared substrate beneath the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] — [[gsd|GSD (Get-Shit-Done)]]'s fresh-context-per-task and [[superpowers|Superpowers]]' fresh-context code review both rest on them. The same isolation primitive is generalized at the architecture level by [[domain-specific-agents|Domain-Specific Agents]], where sub-agents are *recursive, full agents exposed as tools* — an agent that calls a sub-agent that calls further sub-agents — rather than only context-compression workers.

## Key Facts

- Subagents (`.claude/agents/<name>.md`) are isolated Claude instances with their own context window, tool allowlist, and optionally their own model. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced]
- The killer feature is context isolation: a research subagent can process 50 files / 100K tokens and return a ~500-token distilled summary, keeping the parent context clean. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced]
- Routing depends on the description; "Use PROACTIVELY" and "MUST BE USED" dramatically increase auto-delegation — write descriptions as routing rules, not capability summaries. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced]
- Best practices: single responsibility with self-contained prompts (subagents see no parent history); least-privilege tools per role (read-only auditors get Read/Grep/Glob, researchers add web tools, implementers add Write/Edit/Bash); explicit output schemas (or agents return one-sentence verdicts); the Explore → Plan → Execute three-phase pipeline is the most reliable pattern. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced]
- Pitfalls: agent sprawl dilutes routing; subagents are black boxes with no mid-stream interaction; over-parallelization wastes tokens; rejected subagent output cannot be iterated — the parent spawns a fresh copy with no internal state. [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced]
- Beyond Claude Code's `.claude/agents/*.md`, the sub-agent generalizes to an *agent-as-a-tool* composition primitive: an ideal agent's tools can include functions, prompts, or *another full agent*, so sub-agents nest recursively (a coordinator → a Salesforce agent → a Google Workspace agent, etc.), each keeping a small, minimal context window — the mechanism behind domain-specific agents [prov:src-2026-07-03-domain-specific-agents#t00:24:17-00:30:07|direct|2026-07-03] [epistemic:: tentative]

## Detail

A subagent is a forked Claude instance: it carries its own context window, its own tool allowlist, and optionally its own model, and it does not see the parent conversation's history. That isolation is the whole point. The canonical use is research fan-out-and-compress — a subagent can read 50 files or 100K tokens of material and hand back a ~500-token distilled summary, so the expensive intermediate context never pollutes the parent. This is the same principle as [[progressive-disclosure|Progressive Disclosure]] applied across agents rather than within a single context: pay the token cost in a disposable context, and let only the compressed result cross back [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced].

Because subagents see no parent history, their prompts must be self-contained, and because routing is driven by the description rather than by the parent reasoning about capabilities, the description should be written as a routing rule — the markers "Use PROACTIVELY" and "MUST BE USED" are documented to dramatically increase auto-delegation. Each subagent should have a single responsibility and least-privilege tools for its role: read-only auditors get `Read, Grep, Glob`; researchers add web tools; implementers add `Write, Edit, Bash`. Without an explicitly defined output schema, subagents tend to return terse one-sentence verdicts, so the schema must be specified. The most reliable composition is the Explore → Plan → Execute three-phase pipeline [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced].

The failure modes are the mirror image of the benefits. Too many subagents dilute routing (agent sprawl). Each is a black box — there is no mid-stream interaction, so the parent cannot course-correct a running subagent. Over-parallelization wastes tokens. And rejected output cannot be iterated: there is no internal state to resume from, so the parent must spawn a fresh copy and start over. Subagents are the substrate beneath the orchestration frameworks — [[gsd|GSD (Get-Shit-Done)]] runs every task in a fresh subagent context to defeat context rot, and [[superpowers|Superpowers]] runs code review in a fresh subagent context to avoid contamination — which is why their isolation properties and pitfalls show up identically across all three [prov:src-2026-04-16-claude-code-frameworks-report#sec:subagents|derived|2026-06-09] [epistemic:: sourced].

## Related Pages

- [[progressive-disclosure|Progressive Disclosure]] — subagent isolation is progressive disclosure applied across agents.
- [[claude-code|Claude Code]] — the host CLI where subagents live as `.claude/agents/*.md`.
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — all three rest on subagent isolation.
- [[gsd|GSD (Get-Shit-Done)]] — fresh subagent context per task.
- [[superpowers|Superpowers]] — fresh subagent context for code review.
- [[domain-specific-agents|Domain-Specific Agents]] — generalizes sub-agents into recursive, full agents composed as tools.

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]]: comparative synthesis report (April 2026)
- [[src-2026-07-03-domain-specific-agents|The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents]]: AI Engineer talk, 2026-06-29 (YouTube transcript)
