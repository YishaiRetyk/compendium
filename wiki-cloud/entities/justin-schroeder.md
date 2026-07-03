---
id: justin-schroeder
title: "Justin Schroeder"
type: entity
status: active
summary: "Co-founder of the stealth startup StandardAgents and a prolific open-source builder
  (dmux, ArrowJS, FormKit, AutoAnimate, Tempo, zodown) who argues in an AI Engineer talk that the
  future of agent architecture is domain-specific agents — many small isolated agents composed
  under a coordinator, 'composition over inheritance' applied to AI."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-domain-specific-agents
epistemic_status: sourced
tags:
- ai-engineer
- domain-specific-agents
- multi-agent-orchestration
- agent-architecture
- open-source
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Justin Schroeder"
- "justin-schroeder"
has_contradictions: false
knowledge_domain: biography
example: false
---

# Justin Schroeder

## TL;DR

Justin Schroeder is a software engineer and co-founder of [[standardagents|StandardAgents]], a stealth-mode startup building an ecosystem of [[domain-specific-agents|Domain-Specific Agents]]. He is a prolific open-source author — creator of dmux (a multiplexer for coding agents), ArrowJS (a UI framework "like React for the agentic era"), FormKit, AutoAnimate, Tempo, and zodown. In an AI Engineer talk ("The Future Is Domain-Specific Agents") he argues that the dominant way to make agents more capable — piling tools, [[agent-skills|Skills]], and MCP into one general-purpose agent's context — is *inheritance* that hits diminishing returns, and that the better path is *composition over inheritance*: many small isolated agents, each purpose-built, coordinated in plain English. He is reachable as @jpschroeder on X.

## Key Facts

- Co-founder of [[standardagents|StandardAgents]], which he describes as a small company still "in stealth mode" [prov:src-2026-07-03-domain-specific-agents#t00:00:23-00:00:30|direct|2026-07-03] [epistemic:: tentative]
- Creator of a large set of open-source projects: **dmux, ArrowJS, FormKit, AutoAnimate, Tempo, zodown** (per the video description); in the talk he highlights dmux as "a great multiplexer for all of your coding agents" and ArrowJS as a UI framework "sort of like React for the agentic era" [prov:src-2026-07-03-domain-specific-agents#sec:description|direct|2026-07-03] [prov:src-2026-07-03-domain-specific-agents#t00:00:37-00:00:56|direct|2026-07-03] [epistemic:: tentative]
- Proponent of **domain-specific agents** and of applying "composition over inheritance" to agent architecture; he notes he did not coin the term "domain-specific agents" [prov:src-2026-07-03-domain-specific-agents#t00:12:56-00:16:37|direct|2026-07-03] [epistemic:: tentative]
- Offers a working definition of an agent as "deterministic software that harnesses the non-deterministic results produced by models in pursuit of some desired objective," treating "agent" and "harness" as interchangeable [prov:src-2026-07-03-domain-specific-agents#t00:02:25-00:03:10|direct|2026-07-03]
- Predicts a rapid rise of domain-specific-agent frameworks through late 2026 and that **2027 will be "the year of multi-agent orchestration"** [prov:src-2026-07-03-domain-specific-agents#t00:21:22-00:22:09|direct|2026-07-03] [epistemic:: tentative]
- Online presence: X **@jpschroeder**, GitHub `github.com/justin-schroeder`, LinkedIn `/in/jpschroeder` (from the video description) [prov:src-2026-07-03-domain-specific-agents#sec:description|direct|2026-07-03] [epistemic:: tentative]

## Detail

Schroeder's contribution to this wiki is the architectural argument for [[domain-specific-agents|Domain-Specific Agents]], delivered at an AI Engineer event. He grounds it in a builder's frustration: businesses everywhere are trying to build custom agents for data integration, but robust agents are hard and are neither portable nor composable, so teams retreat to bolting tools (via MCP) and [[agent-skills|Skills]] onto a big general-purpose agent — which he reframes as *inheritance* that inflates the agent's [[context-engineering|context]] and degrades past scale [prov:src-2026-07-03-domain-specific-agents#t00:03:54-00:13:34|direct|2026-07-03] [epistemic:: tentative]. His prescription — small isolated agents composed under a coordinator, communicating in English, with a claimed >80% token efficiency and much cheaper small models made viable — is developed fully on the concept page. His open-source track record (dmux, ArrowJS, and the pre-AI web tooling FormKit / AutoAnimate) situates him as a framework author now turning that lens on the "agentic era." The STT renders his surname as "Schrader" and his handle as "JPSchrader"; the canonical spellings here come from the official video description.

## Related Pages

- [[domain-specific-agents|Domain-Specific Agents]] — the architecture pattern he advocates.
- [[standardagents|StandardAgents]] — the company he co-founded to build it.
- [[agent-skills|Agent Skills]] — the "add more skills" approach he contrasts his pattern with.
- [[subagents|Subagents]] — the composition primitive his recursive domain-specific agents build on.

## Sources

- [[src-2026-07-03-domain-specific-agents|The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
