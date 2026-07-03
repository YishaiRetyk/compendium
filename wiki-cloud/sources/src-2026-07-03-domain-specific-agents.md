---
id: src-2026-07-03-domain-specific-agents
title: "The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents"
type: source
status: active
summary: "A recorded AI Engineer talk by Justin Schroeder (StandardAgents) arguing the next
  agent architecture is *composition over inheritance*: instead of inflating one general-purpose
  agent's context with ever more tools, skills, and MCP servers, compose many small isolated
  domain-specific agents under a coordinator that talk to each other in plain English — yielding
  token efficiency, viable small models, tight capability limits, and easy scaling."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- domain-specific-agents
- multi-agent-orchestration
- composition-over-inheritance
- agent-architecture
- context-engineering
- youtube-transcript
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "The Future Is Domain-Specific Agents"
- "Domain-Specific Agents (Justin Schroeder talk)"
- "src-2026-07-03-domain-specific-agents"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-domain-specific-agents.md
url: "https://www.youtube.com/watch?v=spNAUEgq_A8"
content_hash: "sha256:5aa8d4c27a1bb7644d2059930d113df2b76981be7d3a2fdc3a216a4a5595a57b"
ingested_at: 2026-07-03
source_type: transcript
channel: "AI Engineer"
publish_date: 2026-06-29
duration: "30:38"
extraction_tool: stt
extraction_model: "faster-whisper large-v3 (English); speaker diarization unavailable (TorchCodec missing)"
extraction_date: 2026-07-03
compilation_status: compiled
compiled_against_hash: "sha256:5aa8d4c27a1bb7644d2059930d113df2b76981be7d3a2fdc3a216a4a5595a57b"
compiled_targets:
- domain-specific-agents
- justin-schroeder
- standardagents
- agent-skills
- subagents
---

# The Future Is Domain-Specific Agents — Justin Schroeder, StandardAgents

## TL;DR

An AI Engineer talk by [[justin-schroeder|Justin Schroeder]], co-founder of the stealth startup [[standardagents|StandardAgents]], making the case for [[domain-specific-agents|Domain-Specific Agents]]. His diagnosis: businesses everywhere are building custom agents to integrate their data into AI, but robust agents are hard (orchestration, durability, observability, no portability, no composability), so people retreat to bolting tools, [[agent-skills|Skills]], and MCP servers onto one big general-purpose agent — inflating its context. He names that pattern **inheritance** and argues it hits diminishing returns past a hundred-plus skills. His alternative is the old engineering maxim **composition over inheritance**: build many *small isolated agents*, each with a purpose-written system prompt, precise tools, and a tiny message history, coordinated by a top-level agent, all communicating in plain **English** (the moon-landing analogy: teams of narrow experts, not one person with every tool). He claims four payoffs — >80% token efficiency per task, viability of much cheaper small models (a "137× cheaper" DeepSeek-vs-Fable figure), strict per-agent capability limits (a security win), and near-linear scaling — and predicts a rapid rise of domain-specific-agent frameworks through late 2026, with **2027 "the year of multi-agent orchestration."** He closes with an "ideal agent" anatomy (functions / prompts / agent-as-tool, hooks, agent rules, plus a mandatory sandboxed filesystem and code-execution primitive) and recursive sub-agents. The page is graded `sourced` (clean single-speaker audio); proper nouns, model names, and the empirical percentages are hedged per the video-ingestion policy.

## Key Takeaways

- The core thesis is **composition over inheritance** for agents: rather than layering more tools/skills/MCP onto one general-purpose agent (inheritance, which inflates context and hits diminishing returns), compose many small isolated **domain-specific agents** under a coordinator [prov:src-2026-07-03-domain-specific-agents#t00:12:11-00:13:34|direct|2026-07-03] [epistemic:: tentative]
- Schroeder's working definition: **an agent is deterministic software that harnesses the non-deterministic results produced by models in pursuit of some desired objective**; he treats the agent-vs-harness distinction as pedantic and conflates the two [prov:src-2026-07-03-domain-specific-agents#t00:02:25-00:03:10|direct|2026-07-03]
- Each domain-specific agent is a *full* agent — purpose-written system prompt, precise tools, its own message history and agentic loop — not just a tool server; a top-level coordinator and the sub-agents communicate in **plain English**, like a team of humans [prov:src-2026-07-03-domain-specific-agents#t00:13:34-00:14:55|direct|2026-07-03] [epistemic:: tentative]
- Claimed benefits from StandardAgents' internal use: **>80% token efficiency** per task, small models made viable (a "**137× cheaper** per task" DeepSeek-V4-Flash-vs-Fable-5 comparison), strict per-agent capability limits (a security/governance win), and excellent parallel scaling [prov:src-2026-07-03-domain-specific-agents#t00:16:52-00:20:54|direct|2026-07-03] [epistemic:: tentative]
- Bolting on **tools (via MCP) and Skills is "not enough"**: MCP has become a de-facto tool-distribution mechanism (only the "tools" column of the MCP client matrix is filled), and research shows using *too many* skills makes an agent substantially worse — "we didn't land a man on the moon by giving one guy a ton of tools" [prov:src-2026-07-03-domain-specific-agents#t00:08:14-00:09:57|direct|2026-07-03] [epistemic:: tentative]
- **Prediction:** domain-specific agents barely exist publicly today but will rise rapidly through the back half of 2026, with **2027 "basically the year of multi-agent orchestration"**; he cites Vercel's just-released "Eve" framework as the term reflecting back at him [prov:src-2026-07-03-domain-specific-agents#t00:20:54-00:22:34|direct|2026-07-03] [epistemic:: tentative]
- A supporting economic claim: contrary to the "cost of intelligence is falling" consensus, **StandardAgents tracks token cost as rising in 2026** — up ~29–30% IQ-adjusted and ~76% unadjusted so far this year — which raises the payoff of routing narrow tasks to cheaper models [prov:src-2026-07-03-domain-specific-agents#t00:22:34-00:23:47|direct|2026-07-03] [epistemic:: tentative]

## Extracted Claims

### Framing — the agentic Industrial Revolution and the speaker

- The talk is about domain-specific agents, which Schroeder argues will play an important role in the future of AI and of how we build agents [prov:src-2026-07-03-domain-specific-agents#t00:00:02-00:00:16|direct|2026-07-03] [epistemic:: tentative]
- The speaker is Justin Schroeder (rendered "Justin Schrader" by the STT), reachable on X as @jpschroeder ("JPSchrader" as-heard); he works at a small stealth-mode company called StandardAgents [prov:src-2026-07-03-domain-specific-agents#t00:00:16-00:00:37|direct|2026-07-03] [epistemic:: tentative]
- He is known for open-source projects including dmux (described as a "great multiplexer for all of your coding agents") and ArrowJS (rendered "Aero.js"; described as a UI framework "sort of like React for the agentic era") [prov:src-2026-07-03-domain-specific-agents#t00:00:37-00:00:56|direct|2026-07-03] [epistemic:: tentative]
- Framing: this moment resembles an accelerated Industrial Revolution; that revolution's catalyst was learning to *harness energy with machines*, and this era is learning to *harness intelligence with agents* — the agent is "the machine of yesteryear," the thing that uses the intelligence [prov:src-2026-07-03-domain-specific-agents#t00:00:56-00:01:52|direct|2026-07-03] [epistemic:: tentative]

### No agreed definition; everyone is building custom agents; the driver is integration

- We have not coalesced on a shared definition of "agent" even though we are well into the agentic era [prov:src-2026-07-03-domain-specific-agents#t00:01:52-00:02:25|direct|2026-07-03]
- His definition: agents are **deterministic software that harness the non-deterministic results produced by models in pursuit of some desired objective**; the distinction between an "agent" and a "harness" is pedantic and can be conflated for this talk [prov:src-2026-07-03-domain-specific-agents#t00:02:25-00:03:10|direct|2026-07-03]
- Most people can name at most Claude or Codex as agents; almost nobody outside the field would name OpenClaw or Hermes, and many would not even recognize Claude as an agent — these systems are not well understood [prov:src-2026-07-03-domain-specific-agents#t00:03:10-00:03:54|direct|2026-07-03] [epistemic:: tentative]
- Despite that, everybody is building custom agents — he cites a local real-estate agency, independent private insurance brokers, and many Fortune 500 companies all building their own [prov:src-2026-07-03-domain-specific-agents#t00:03:54-00:04:26|direct|2026-07-03] [epistemic:: tentative]
- The reason businesses build custom agents even though AI is already everywhere is **integration**: they want their data properly integrated into AI to capture dramatic business gains, and a custom agent is one of the first mechanisms they discover for doing it [prov:src-2026-07-03-domain-specific-agents#t00:04:26-00:05:15|direct|2026-07-03]

### Agents are hard — orchestration, durability, observability, portability, composability

- Building agents is really hard: you must carefully orchestrate the agentic loop, juggle many provider abstractions (he credits the Vercel AI SDK as a good emerging tool), get durable execution for fault recovery, and handle many validations and stop conditions — hard especially at scale [prov:src-2026-07-03-domain-specific-agents#t00:05:15-00:05:58|direct|2026-07-03] [epistemic:: tentative]
- Home-built custom agents typically "work as a demo but not much more"; robust agents are "an absolute nightmare," and there is "actually no defined way to build an agent right now" — the closest thing he names is Vercel's "Eve" [prov:src-2026-07-03-domain-specific-agents#t00:05:58-00:06:34|direct|2026-07-03] [epistemic:: tentative]
- Telemetry and observability — knowing exactly what is transmitted on every step of every turn so you can diagnose and tune the agent — is very hard, especially at scale [prov:src-2026-07-03-domain-specific-agents#t00:06:34-00:06:52|direct|2026-07-03]
- Agents are **not portable**: an agent that works on your machine often will not run on someone else's because of environment-variable configuration, system requirements, and runtimes [prov:src-2026-07-03-domain-specific-agents#t00:06:52-00:07:19|direct|2026-07-03]
- Agents are **not composable**: a good chatbot built for one purpose (e.g. a university) is very hard to reuse or share for another purpose [prov:src-2026-07-03-domain-specific-agents#t00:07:19-00:07:35|direct|2026-07-03]

### The retreat to MCP and Skills — "tools are not enough"

- After a short pursuit of agents, people back off and "do the MCP thing" instead; Model Context Protocol does work to shove corporate information into a large pre-existing general-purpose agent like Claude or ChatGPT [prov:src-2026-07-03-domain-specific-agents#t00:07:35-00:08:14|direct|2026-07-03] [epistemic:: tentative]
- On the MCP website's client-support matrix, only one column — **tools** — is filled all the way down; MCP has become a de-facto *tool-distribution* mechanism for agents and has not proven great at providing other value yet [prov:src-2026-07-03-domain-specific-agents#t00:08:14-00:08:53|direct|2026-07-03] [epistemic:: tentative]
- Tools alone are not enough: "we didn't land a man on the moon by giving one guy a ton of tools" — that is not a realistic way to get a very large project done [prov:src-2026-07-03-domain-specific-agents#t00:08:53-00:09:17|direct|2026-07-03]
- Skills are useful — fundamentally a skill is a markdown file that works as documentation — but there is research showing that using *very many* of them makes an agent substantially worse; skills help but are "not the fundamental problem" (the moon analogy: handing the astronaut a ton of documentation) [prov:src-2026-07-03-domain-specific-agents#t00:09:17-00:09:57|direct|2026-07-03] [epistemic:: tentative]

### The agent stack is almost all context

- A basic agent stack layers, in order: a **model**, a **system prompt** (its role/objective), **tools** (the effects it can take), **skills**, then **MCP**, then finally all the **conversation messages** — roughly the information passed within an agent's runtime [prov:src-2026-07-03-domain-specific-agents#t00:09:57-00:10:41|direct|2026-07-03] [epistemic:: tentative]
- Almost all of that stack is **context**: the system prompt, tools, and skills all end up in the agent's context window [prov:src-2026-07-03-domain-specific-agents#t00:10:41-00:10:55|direct|2026-07-03]
- Consequently people try to solve the integration problem by working on the **context** or the **model**, and nearly every new technology or protocol (skills, MCP) shows up in those two areas [prov:src-2026-07-03-domain-specific-agents#t00:10:55-00:11:22|direct|2026-07-03] [epistemic:: tentative]

### Inheritance — inflating one agent's context

- The everyday pattern is to install more and more into one agent's context: travel MCPs, Figma, Playwright, Gmail MCPs, Google Sheets, React fixers/linters, "Matt's grill me skill," a GitHub skill — all accreting in the context layer [prov:src-2026-07-03-domain-specific-agents#t00:11:22-00:12:11|direct|2026-07-03] [epistemic:: tentative]
- He names this pattern **inheritance** (the OOP idea of taking an object and adding attributes/layers so one object gains more properties); adding extra layers so an agent can do things it previously couldn't is exactly inheritance, and it does work — that is why these setups exist [prov:src-2026-07-03-domain-specific-agents#t00:12:11-00:12:56|direct|2026-07-03] [epistemic:: tentative]
- But inheritance breaks down: five skills on Claude works fine, but at a hundred or a thousand skills there is a point of diminishing returns from adding more context [prov:src-2026-07-03-domain-specific-agents#t00:12:56-00:13:34|direct|2026-07-03] [epistemic:: tentative]

### Composition — small isolated agents under a coordinator, talking in English

- The alternative is **composition over inheritance**: instead of loading Figma capability into the main agent's context, build a tiny agent whose *system prompt is written specifically to be a Figma agent* — it knows Figma's API, the right actions to take — with only the precise tools it needs and a small Figma-only message history [prov:src-2026-07-03-domain-specific-agents#t00:13:34-00:14:19|direct|2026-07-03] [epistemic:: tentative]
- Each such unit is a **separate isolated full agent** — its own message history and agentic loop, not just a server with tools — and above the set of them sits a **coordinator** agent [prov:src-2026-07-03-domain-specific-agents#t00:14:19-00:14:43|direct|2026-07-03] [epistemic:: tentative]
- The communication mechanism between the small agents and the coordinator is **just English**: they talk to each other the way humans do (the coordinator asks the Gmail agent for any trip emails, the answer funnels back up, then it asks the travel agent to make bookings) [prov:src-2026-07-03-domain-specific-agents#t00:14:43-00:15:23|direct|2026-07-03] [epistemic:: tentative]
- The **moon-landing analogy**: this worked to get to the moon because there were teams of narrow experts; an Apollo mission-control operator *is* an agent — his brain is the LLM, the tools on his console are his (only those) tools, and his mouth is the messages; he had just those tools and was very good at them. It is "almost a form of biomimicry for the agentic world" [prov:src-2026-07-03-domain-specific-agents#t00:15:23-00:16:18|direct|2026-07-03] [epistemic:: tentative]
- He calls these **domain-specific agents** — agents targeted to a very specific domain — while noting he was not the first to use the term or have the idea [prov:src-2026-07-03-domain-specific-agents#t00:16:18-00:16:37|direct|2026-07-03] [epistemic:: tentative]

### The four claimed benefits (from StandardAgents' internal use)

- StandardAgents has been building this domain-specific-agent ecosystem for some time and uses it daily; Schroeder is not announcing a product but offers a "peek" [prov:src-2026-07-03-domain-specific-agents#t00:16:37-00:16:52|direct|2026-07-03] [epistemic:: tentative]
- **(1) Token efficiency:** domain-specific agents are far more token-efficient — StandardAgents "regularly see over 80% token efficiency for any given task" — because a sub-agent needs only its system message, its tools, and the one inbound instruction (e.g. the coordinator asking Gmail to "get that last email from Debbie"), not the whole conversation context [prov:src-2026-07-03-domain-specific-agents#t00:16:52-00:18:08|direct|2026-07-03] [epistemic:: tentative]
- **Portability** falls out of the same isolation: you can "squeeze up" a Gmail agent and send it to someone else, enabling an ecosystem where teams don't each have to rebuild every skill/capability [prov:src-2026-07-03-domain-specific-agents#t00:17:03-00:17:28|direct|2026-07-03] [epistemic:: tentative]
- **(2) Small models become viable:** he contrasts DeepSeek V4 Flash with Fable 5 and claims the cheaper model is "**137 times cheaper** per task"; a small model failing repeatedly would negate that, but a domain-specific agent only asks it to do narrowly picked tasks with minimal context, which it can execute faithfully — and you can likewise use non-language models (image-generation and diffusion models) for smaller tasks [prov:src-2026-07-03-domain-specific-agents#t00:18:08-00:19:29|direct|2026-07-03] [epistemic:: tentative]
- **(3) Strict capability limits (security/governance):** today everyone is "flying close to the sun," bypassing permissions because a big-model coding agent can do anything; small domain-specific agents can only do what has been explicitly approved for them, so you opt into a much more controlled ecosystem — reassuring "Doug in IT" — while still allowing permission dialogs [prov:src-2026-07-03-domain-specific-agents#t00:19:29-00:20:26|direct|2026-07-03] [epistemic:: tentative]
- **(4) Excellent scaling:** because each agent is its own small execution environment, you can parallelize them, deploy them to the cloud without a giant VPC, and run thousands of instances across regions with no need for geographic co-location [prov:src-2026-07-03-domain-specific-agents#t00:20:26-00:20:54|direct|2026-07-03] [epistemic:: tentative]

### They barely exist yet — predictions and the token-cost reversal

- The downside: domain-specific agents "don't really exist" in a big public way yet; StandardAgents works with them internally daily but they are not out in public much [prov:src-2026-07-03-domain-specific-agents#t00:20:54-00:21:22|direct|2026-07-03] [epistemic:: tentative]
- **Prediction:** from mid-2026 to the end of 2026 there will be a dramatic uptick in people building domain-specific agents and frameworks around them; it will accelerate rapidly and become one of the main players in the agentic ecosystem [prov:src-2026-07-03-domain-specific-agents#t00:21:22-00:21:55|direct|2026-07-03] [epistemic:: tentative]
- He predicts **2027 will be "basically the year of multi-agent orchestration"** [prov:src-2026-07-03-domain-specific-agents#t00:21:55-00:22:09|direct|2026-07-03] [epistemic:: tentative]
- He cites Vercel's just-released "Eve" — "the framework for building agents: build a company brain, personal assistant, or domain-specific agent" — as the first time he saw the term he had been evangelizing come back to him [prov:src-2026-07-03-domain-specific-agents#t00:22:09-00:22:34|direct|2026-07-03] [epistemic:: tentative]
- Contrary to the common belief that the **cost of intelligence is falling**, he says that trend reversed in 2026 (StandardAgents tracks it on a website): tokens are getting more expensive — up ~29–30% this year *even adjusted for IQ*, partly due to a "memory crunch," though the ~10-year trend may still be downward [prov:src-2026-07-03-domain-specific-agents#t00:22:34-00:23:26|direct|2026-07-03] [epistemic:: tentative]
- **Unadjusted for IQ, tokens are up 76% this year** — almost a 100% increase, and not even halfway through the year — so anything that brings token cost down (especially for large businesses) matters [prov:src-2026-07-03-domain-specific-agents#t00:23:26-00:23:52|direct|2026-07-03] [epistemic:: tentative]
- **Customer-facing AI:** you cannot put an expensive frontier model (he names Fable) in front of a customer unless that customer has massive lifetime value — it is too expensive — so you need high efficacy *and* efficiency, which domain-specific agents provide [prov:src-2026-07-03-domain-specific-agents#t00:23:52-00:24:17|direct|2026-07-03] [epistemic:: tentative]

### The "ideal agent" anatomy

- Breaking the tool layer apart, an ideal agent's tools are of three kinds: **functions** (actual executable functions, e.g. write a file to the filesystem), **prompts** (smaller injected sub-prompts — "a tool that's a prompt" — that can themselves call an LLM, e.g. use "nano banana" to generate an image while "GLM 5.2" is the primary model), and **another full-blown agent as a tool** (a complete other domain-specific agent exposed as one of the tools) [prov:src-2026-07-03-domain-specific-agents#t00:24:17-00:25:33|direct|2026-07-03] [epistemic:: tentative]
- **Hooks** are mechanisms that can harness, change, mutate, or perform side effects; example: LLMs don't know the current time, so a good trick is to inject an artificial message or tool call into the message history so it looks like someone asked the time and got a reply ("it's 6:45 PM Pacific"), or to fire off a side effect [prov:src-2026-07-03-domain-specific-agents#t00:25:33-00:26:25|direct|2026-07-03] [epistemic:: tentative]
- **Agent rules** are per-agent governance settings — e.g. how many turns or steps one side may take before its turn is up (he floats 10,000), or whether a tool call must be validated [prov:src-2026-07-03-domain-specific-agents#t00:26:25-00:26:57|direct|2026-07-03] [epistemic:: tentative]
- Bundling model + system prompt + tools + hooks + rules gives "an agent," but two primitives are still missing: every agent should have its own **sandboxed file system** (ChatGPT/Claude/Codex already store generated files this way — the big labs realized a chat interface needs a filesystem) and its own **sandboxed code-execution location** (write files, run them safely without exfiltration or higher-level OS access); both should be baked in as primitives of every domain-specific agent [prov:src-2026-07-03-domain-specific-agents#t00:26:57-00:27:57|direct|2026-07-03] [epistemic:: tentative]

### Recursive sub-agents and close

- The "agent as a tool" is a **sub-agent**, and these can be **recursive**: an agent can call a sub-agent that calls further sub-agents, with one or many at each level [prov:src-2026-07-03-domain-specific-agents#t00:27:57-00:28:17|direct|2026-07-03] [epistemic:: tentative]
- Worked example of a recursive tree: a top **coordinator** → a **Salesforce agent** (knows the Salesforce API and holds the credentials) → a **Google Workspace agent** (builds spreadsheets, e.g. "who are my top salespeople this year"); the Salesforce agent also has an **asset-generation sub-agent** (using "nano banana," an SVG generator, and its own reflection/QA); and the coordinator has a **legal-team agent** whose sub-agents include a **GDPR-compliance agent** ("we don't want 45 megabytes of context just on GDPR") and an **OSHA-compliance agent** [prov:src-2026-07-03-domain-specific-agents#t00:28:17-00:29:49|direct|2026-07-03] [epistemic:: tentative]
- The result is many highly efficient small agents working together while each maintains a small, minimal context window throughout — the idea behind domain-specific agents [prov:src-2026-07-03-domain-specific-agents#t00:29:49-00:30:07|direct|2026-07-03] [epistemic:: tentative]
- Close: StandardAgents is at standardagents.ai (early-access sign-up), reachable at info@standardagents, and he asks for a follow at @jpschroeder [prov:src-2026-07-03-domain-specific-agents#t00:30:07-00:30:33|direct|2026-07-03] [epistemic:: tentative]

## Notes

**Validity assessment:**

- The audio is clean, single-speaker, studio-recorded conference narration, so the page is graded `sourced`. Per-claim `[epistemic:: tentative]` hedges are applied across the STT failure surface per the video-ingestion tiered-epistemic policy: proper nouns, product/model names, coined terms, and numbers.
- **Names mended from the official video description (via `yt-dlp`, not the STT):** the speaker is **Justin Schroeder** (STT: "Justin Schrader"), X handle **@jpschroeder** (STT: "JPSchrader"), company **StandardAgents** at `standardagents.ai` (STT: "Standard Agents"). His open-source projects per the description are **dmux, ArrowJS, FormKit, AutoAnimate, Tempo, zodown**; the STT renders "ArrowJS" as "Aero.js." GitHub `github.com/justin-schroeder`, LinkedIn `/in/jpschroeder`.
- **Model and product names are as-heard and tentative:** "DeepSeek V4 Flash," "Fable 5" (spoken "Fable five"), "GLM 5.2," "nano banana" (an image-generation model), Vercel's "**Eve**" agent framework, the "Vercel AI SDK," and the agents named as recognizable examples — "OpenClaw" and "Hermes" alongside Claude and Codex. These should be treated as tentative pending confirmation of exact spelling/version.
- **Numbers are the speaker's own figures, mostly from unpublished internal StandardAgents measurements, and are recorded as his claims, not verified fact:** ">80% token efficiency," the "**137× cheaper** per task" DeepSeek-vs-Fable comparison, token cost "up 29–30% IQ-adjusted / 76% unadjusted" in 2026, "10,000 turns," and "45 megabytes of GDPR context" (rhetorical). The 2026 token-cost-reversal and the 2027-multi-agent-orchestration line are **predictions/opinions**, hedged accordingly.
- **Attribution of third-party items:** "Matt's grill me skill" refers to a skill by [[matt-pocock|Matt Pocock]] (see [[skill-checklist|Skill Checklist]]); it is recorded as Schroeder's example, not asserted independently. The "research shows too many skills make an agent worse" claim is cited without a reference and is recorded as his assertion.
- **Speaker labels:** automatic diarization did not run (the pipeline's TorchCodec dependency was missing), so the committed raw transcript carries no `SPEAKER:` labels. The talk is single-speaker throughout, so labels are not required.

## Source Metadata

- **Speaker:** Justin Schroeder (co-founder, StandardAgents)
- **Channel:** AI Engineer
- **Publication:** YouTube
- **URL:** https://www.youtube.com/watch?v=spNAUEgq_A8
- **Publish date:** 2026-06-29
- **Duration:** 30:38
- **Company:** https://standardagents.ai
- **Speaker links:** X https://x.com/jpschroeder · GitHub https://github.com/justin-schroeder · LinkedIn https://www.linkedin.com/in/jpschroeder/
- **Source type:** transcript (video sub-case)
- **Path:** `sources/2026/2026-07/2026-07-03-domain-specific-agents.md`

The video fields (title, channel, publish date, duration, speaker bio) were sourced from the
`yt-dlp` metadata and official description pulled during acquisition. The committed transcript is
the durable record; the `url` is a courtesy pointer that may rot.
