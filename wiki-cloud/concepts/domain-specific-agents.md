---
id: domain-specific-agents
title: Domain-Specific Agents
type: concept
status: active
summary: "An agent-architecture pattern (championed by Justin Schroeder / StandardAgents) that
  applies 'composition over inheritance' to agents: rather than inflating one general-purpose
  agent's context with ever more tools, skills, and MCP servers, compose many small isolated
  agents — each with a purpose-written system prompt, precise tools, and a tiny message history —
  under a coordinator that communicates with them in plain English."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-domain-specific-agents
epistemic_status: sourced
tags:
- domain-specific-agents
- multi-agent-orchestration
- composition-over-inheritance
- agent-architecture
- context-engineering
- small-language-models
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Domain-Specific Agents"
- "Domain-Specific Agent"
- "domain-specific-agents"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

**Domain-specific agents** are an agent-architecture pattern that applies the old engineering maxim *composition over inheritance* to AI agents. The status-quo way to make an agent more capable is **inheritance**: keep adding tools, [[agent-skills|Skills]], and MCP servers into one general-purpose agent, all of which pile into its [[context-engineering|context]] window — a pattern that works up to a point but hits diminishing returns past a hundred-plus additions. The alternative is **composition**: build many *small isolated agents*, each a full agent (purpose-written system prompt, only the precise tools it needs, its own tiny message history and agentic loop), and coordinate them with a top-level agent, all communicating in plain **English**. The recurring analogy is the moon landing — a team of narrow experts, each excellent with a few tools, not one person holding every tool. [[justin-schroeder|Justin Schroeder]] of [[standardagents|StandardAgents]] argues this yields four payoffs from their internal use — >80% token efficiency per task, viability of much cheaper small models (a claimed "137× cheaper" DeepSeek-vs-Fable figure), strict per-agent capability limits (a security/governance win), and near-linear parallel scaling — and predicts domain-specific-agent frameworks will proliferate through late 2026, making **2027 "the year of multi-agent orchestration."** The framing is an explicit counterpoint to the "just add more skills/tools" trajectory of current agent tooling.

## Key Facts

- The pattern applies **composition over inheritance** to agents: *inheritance* = layering more tools/skills/MCP onto one agent (which inflates its context and eventually yields diminishing returns); *composition* = many small isolated agents coordinated together [prov:src-2026-07-03-domain-specific-agents#t00:12:11-00:13:34|direct|2026-07-03] [epistemic:: tentative]
- Each domain-specific agent is a **full agent** — a purpose-written system prompt, only its precise tools, and its own small message history and agentic loop — not merely a tool server; a **coordinator** sits above the set and they communicate in **plain English** [prov:src-2026-07-03-domain-specific-agents#t00:13:34-00:14:43|direct|2026-07-03] [epistemic:: tentative]
- Working definition of an agent used throughout: **"deterministic software that harnesses the non-deterministic results produced by models in pursuit of some desired objective"**; the agent-vs-harness distinction is treated as pedantic [prov:src-2026-07-03-domain-specific-agents#t00:02:25-00:03:10|direct|2026-07-03]
- Motivating problem: robust general-purpose agents are hard (loop orchestration, durable execution, observability) and are neither **portable** nor **composable**, so bolting on tools (via MCP) and [[agent-skills|Skills]] is "not enough" — "we didn't land a man on the moon by giving one guy a ton of tools" [prov:src-2026-07-03-domain-specific-agents#t00:05:15-00:09:17|direct|2026-07-03] [epistemic:: tentative]
- Four claimed benefits (from StandardAgents' internal use): **>80% token efficiency** per task; small/cheaper models become viable (a "**137× cheaper** per task" DeepSeek-V4-Flash-vs-Fable-5 comparison); **strict per-agent capability limits** (agents can only do what is explicitly approved — a governance/security win); and **excellent parallel scaling** (each agent is its own small execution environment) [prov:src-2026-07-03-domain-specific-agents#t00:16:52-00:20:54|direct|2026-07-03] [epistemic:: tentative]
- **Prediction:** domain-specific agents barely exist publicly today but will proliferate through late 2026, with **2027 "basically the year of multi-agent orchestration"**; Vercel's just-released "Eve" framework is cited as early evidence [prov:src-2026-07-03-domain-specific-agents#t00:20:54-00:22:34|direct|2026-07-03] [epistemic:: tentative]
- Supporting economics: contrary to the "cost of intelligence is falling" consensus, Schroeder says token cost *rose* in 2026 (StandardAgents tracks it) — up ~29–30% IQ-adjusted and ~76% unadjusted so far — sharpening the incentive to route narrow tasks to cheaper models and to put only affordable agents in front of customers [prov:src-2026-07-03-domain-specific-agents#t00:22:34-00:24:17|direct|2026-07-03] [epistemic:: tentative]

## Detail

### The problem: everyone builds custom agents, and it's hard

Schroeder observes that businesses everywhere — from a local real-estate agency to Fortune 500s — are building their own custom agents, driven by **integration**: they want their data wired into AI to capture business gains, and a custom agent is one of the first mechanisms they reach for [prov:src-2026-07-03-domain-specific-agents#t00:03:54-00:05:15|direct|2026-07-03] [epistemic:: tentative]. But robust agents are hard: you must carefully orchestrate the agentic loop, manage provider abstractions (he credits the Vercel AI SDK), get durable execution for fault recovery, and handle many validations and stop conditions. Home-built agents "work as a demo but not much more," observability is hard at scale, and — critically — agents are neither **portable** (env/runtime differences break them on other machines) nor **composable** (a chatbot built for one purpose is hard to reuse) [prov:src-2026-07-03-domain-specific-agents#t00:05:15-00:07:35|direct|2026-07-03] [epistemic:: tentative].

The common retreat is to stop building agents and instead bolt capabilities onto a big general-purpose agent (Claude, ChatGPT) via MCP and [[agent-skills|Skills]]. Schroeder's critique is that this is insufficient: on the MCP client-support matrix only the **tools** column is filled all the way down, so MCP has become a de-facto *tool-distribution* mechanism rather than a source of broader value; and while a skill is a useful markdown "documentation" file, he claims research shows that using *too many* skills makes an agent substantially worse [prov:src-2026-07-03-domain-specific-agents#t00:07:35-00:09:57|direct|2026-07-03] [epistemic:: tentative]. His point with the moon metaphor: tools and documentation help, but they are "not the fundamental problem."

### Inheritance vs. composition

The reason bolting-on falls short is structural. An agent's runtime stack — model, system prompt, tools, skills, MCP, then all the conversation messages — is *almost entirely context* [prov:src-2026-07-03-domain-specific-agents#t00:09:57-00:10:55|direct|2026-07-03]. Every capability you add to one agent adds to its context load. Schroeder names this **inheritance** (the OOP move of adding attributes/layers to one object so it gains more properties); it works, which is why it's everywhere, but past some scale — five skills is fine, a thousand is not — you hit diminishing returns from more context [prov:src-2026-07-03-domain-specific-agents#t00:11:22-00:13:34|direct|2026-07-03] [epistemic:: tentative].

**Composition** is the alternative. Instead of loading (say) Figma capability into the main agent, you build a tiny agent whose *system prompt is written specifically to be a Figma agent* — it knows Figma's API and the right actions — carrying only the precise tools it needs and a small Figma-only message history. Each such unit is a *separate isolated full agent* (its own message history and agentic loop), and a **coordinator** agent sits above them. The communication mechanism is *just English*: the coordinator asks the Gmail agent for any trip emails, the answer funnels back up, and it then asks the travel agent to make bookings [prov:src-2026-07-03-domain-specific-agents#t00:13:34-00:15:23|direct|2026-07-03] [epistemic:: tentative]. This overlaps with — and generalizes — the [[subagents|Subagents]] idea already in the wiki: sub-agents here are recursive, full domain-specific agents composed as tools, not just context-isolation workers.

The **moon-landing analogy** carries the argument: we reached the moon with *teams of narrow experts*, not one person with every tool. An Apollo mission-control operator is, in Schroeder's reading, an agent — brain as the LLM, the console's instruments as his (only) tools, his mouth as the messages — who had just those tools and was excellent with them. Composition is "almost a form of biomimicry for the agentic world" [prov:src-2026-07-03-domain-specific-agents#t00:15:23-00:16:37|direct|2026-07-03] [epistemic:: tentative]. Schroeder notes he did not coin "domain-specific agents."

### The four claimed benefits

Drawing on [[standardagents|StandardAgents]]' internal experience (he stresses he is not announcing a product), Schroeder claims four payoffs [prov:src-2026-07-03-domain-specific-agents#t00:16:37-00:20:54|direct|2026-07-03] [epistemic:: tentative]:

1. **Token efficiency (>80% per task).** A sub-agent needs only its system message, its tools, and the single inbound instruction (e.g. "get that last email from Debbie") — not the whole conversation — so it does its narrow job with minimal context. **Portability** falls out of the same isolation: you can "squeeze up" a Gmail agent and hand it to someone else, enabling a share-and-reuse ecosystem.
2. **Cheaper/smaller models become viable.** He contrasts DeepSeek V4 Flash with Fable 5 and claims the cheaper model is "137× cheaper per task." A weak model failing repeatedly would negate that, but a domain-specific agent gives it only narrowly chosen tasks with minimal context, which it can execute faithfully — and you can even use non-language models (image-generation, diffusion) for suitable subtasks.
3. **Strict capability limits (security/governance).** Today everyone is "flying close to the sun," bypassing permissions because a big-model coding agent can do anything. Small domain-specific agents can only do what has been explicitly approved, so you opt into a controlled ecosystem (reassuring for IT/compliance) while still allowing permission dialogs.
4. **Excellent scaling.** Each agent is its own small execution environment: parallelizable, cloud-deployable without a giant VPC, runnable as thousands of instances across regions with no geographic co-location needed.

### The "ideal agent" anatomy and recursive sub-agents

Schroeder sketches an ideal agent by breaking the tool layer into three kinds of tool — **functions** (executable actions, e.g. write a file), **prompts** (smaller injected sub-prompts, "a tool that's a prompt," which can themselves call an LLM — e.g. invoke an image model like "nano banana" while a different model is primary), and **another full agent exposed as a tool** — plus **hooks** (mechanisms that mutate state or fire side effects; his example: injecting an artificial message/tool-call so the LLM "knows" the current time) and **agent rules** (per-agent governance such as a maximum turn/step budget, or whether tool calls must be validated) [prov:src-2026-07-03-domain-specific-agents#t00:24:17-00:26:57|direct|2026-07-03] [epistemic:: tentative]. He argues two primitives are still missing from most agents and should be baked in: a **sandboxed file system** per agent and a **sandboxed code-execution** location per agent (write and run files safely without exfiltration or higher-level OS access) [prov:src-2026-07-03-domain-specific-agents#t00:26:57-00:27:57|direct|2026-07-03] [epistemic:: tentative].

The "agent as a tool" makes sub-agents **recursive**: an agent calls a sub-agent that calls further sub-agents. His worked tree: a coordinator → a Salesforce agent (knows the API, holds credentials) → a Google Workspace agent (builds spreadsheets like "top salespeople this year"); the Salesforce agent also owns an asset-generation sub-agent (image/SVG generation with its own reflection/QA); and the coordinator owns a legal-team agent whose sub-agents include a GDPR-compliance agent ("we don't want 45 megabytes of context just on GDPR") and an OSHA-compliance agent. The result is many highly efficient small agents cooperating while each keeps a small, minimal context window [prov:src-2026-07-03-domain-specific-agents#t00:27:57-00:30:07|direct|2026-07-03] [epistemic:: tentative].

### Predictions and the token-cost reversal

Schroeder frames the timing as an inflection: domain-specific agents barely exist publicly, but he predicts a rapid rise of them and of frameworks around them through the back half of 2026, with **2027 "basically the year of multi-agent orchestration"**; he cites Vercel's just-released "Eve" ("the framework for building agents: build a company brain, personal assistant, or domain-specific agent") as the term reflecting back at him [prov:src-2026-07-03-domain-specific-agents#t00:20:54-00:22:34|direct|2026-07-03] [epistemic:: tentative]. A supporting economic argument: against the consensus that intelligence keeps getting cheaper, he claims that trend *reversed* in 2026 (StandardAgents tracks token cost on a website) — up ~29–30% IQ-adjusted and ~76% unadjusted so far this year, partly a "memory crunch" — which strengthens the case for routing narrow tasks to cheaper models. It also matters for **customer-facing** AI: you can't put an expensive frontier model in front of a customer unless their lifetime value is huge, so efficacy-with-efficiency (i.e. domain-specific agents) is the path to customer-facing products [prov:src-2026-07-03-domain-specific-agents#t00:22:34-00:24:17|direct|2026-07-03] [epistemic:: tentative].

**Epistemic note.** This concept rests on a single opinionated conference talk. The architectural framing is recorded as sourced, but the empirical percentages (>80% token efficiency, 137× cheaper, the 2026 token-cost figures) come from unpublished internal StandardAgents measurements and the timeline claims are predictions — all hedged `tentative`. Model and product names (DeepSeek V4 Flash, Fable 5, GLM 5.2, "nano banana," Vercel "Eve") are as-heard from a speech-to-text transcript.

## Related Pages

- [[justin-schroeder|Justin Schroeder]] — proponent of the pattern and speaker of the source talk.
- [[standardagents|StandardAgents]] — the stealth startup building a domain-specific-agent ecosystem.
- [[agent-skills|Agent Skills]] — the "just add more skills" trajectory this pattern is posed against.
- [[subagents|Subagents]] — the context-isolation primitive that recursive domain-specific agents generalize.
- [[context-engineering|Context Engineering]] — the discipline whose "context is the scarce resource" premise the pattern optimizes by keeping each agent's window minimal.

## Sources

- [[src-2026-07-03-domain-specific-agents|The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
