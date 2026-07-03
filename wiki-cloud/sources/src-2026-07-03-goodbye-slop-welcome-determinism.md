---
id: src-2026-07-03-goodbye-slop-welcome-determinism
title: "Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid"
type: source
status: active
summary: "A recorded 'Beyond the Prompt' conference talk by David Khourshid (creator of XState,
  founder of Stately.ai) arguing that the cure for AI 'slop' is not better prompting but an
  *explicit model* of how a system should behave. His thesis: put **determinism at the core and
  non-determinism at the edges** — write programs that call LLMs, not LLMs that call programs —
  because the root problem is unstructured delegation, and 'slop code' is code without a reliable
  model that no one can fully understand."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- determinism
- state-machines
- ai-assisted-development
- software-modeling
- slop-code
- separation-of-concerns
- youtube-transcript
domains:
- software-engineering
- ai-assisted-development
supersedes: null
superseded_by: null
aliases:
- "Goodbye Slop, Welcome Determinism"
- "Beyond the Prompt — David Khourshid"
- "src-2026-07-03-goodbye-slop-welcome-determinism"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-goodbye-slop-welcome-determinism.md
url: "https://youtu.be/uMvTAF280so"
content_hash: "sha256:4f858f61835eebe65c1001211a4a6f4e24038eb84bd9e86161a2dd207080a701"
ingested_at: 2026-07-03
source_type: transcript
channel: "AG Grid"
publish_date: 2026-06-26
duration: "30:27"
extraction_tool: stt
extraction_model: "faster-whisper large-v3 (English); speaker diarization unavailable (TorchCodec missing)"
extraction_date: 2026-07-03
compilation_status: compiled
compiled_against_hash: "sha256:4f858f61835eebe65c1001211a4a6f4e24038eb84bd9e86161a2dd207080a701"
compiled_targets:
- david-khourshid
- xstate
- deterministic-core-agentic-shell
- comprehension-debt
---

# Beyond the Prompt: Goodbye Slop, Welcome Determinism — David Khourshid

## TL;DR

A "Beyond the Prompt" conference talk (AG Grid + Bryntum, London) by [[david-khourshid|David Khourshid]] — creator of [[xstate|XState]] and founder of Stately.ai — arguing that the way to build good software *with* AI is the same way you should build it *without* AI: start from an **explicit model** of how the system should behave. His diagnosis inverts the usual scapegoats: the problem is **not** vibe coding, AI "taking over," or hallucination — it is **unstructured delegation**, throwing judgment, structure, and even taste over the wall to an agent. The result is **"slop code": code without a reliable model** that you can't fully understand or explain — not necessarily broken, but with no clear domain boundaries, implicit invariants, scattered behavior, and no safe way to change it (a failure mode that predates LLMs). His remedy is the [[deterministic-core-agentic-shell|deterministic core, agentic shell]] pattern: **move determinism to the core and non-determinism to the edges** — write *programs that call LLMs*, not *LLMs that call programs* — and model only the confusing parts ("modeling is not ceremony when it replaces confusion"). He demos an XState-driven email agent whose state machine makes it *impossible* to send before a draft is approved, and closes that AI made it easier to forget best practices while making them "more important now than ever." Graded `sourced` (clean single-speaker audio); proper nouns, product/version names, and figures are hedged per the video-ingestion policy.

## Key Takeaways

- **Determinism = same input, same output** (like a pure function, though it may be async); **non-determinism = same input, unknown output** — not necessarily random (could be a fixed set of choices) and not exclusive to LLMs. Khourshid learned the distinction from finite-state machines: DFAs (deterministic) vs. NFAs (non-deterministic), where converting an NFA to a DFA makes the machine more complex — "you pay for that complexity in structure" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:03:35-00:04:40|direct|2026-07-03] [epistemic:: tentative]
- The root problem is **unstructured delegation**, not vibe coding or hallucination: deciding to "throw everything over the wall" and let the agent handle judgment, structure, implementation, and sometimes taste [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:06:49-00:07:24|direct|2026-07-03]
- **"Slop code is code without a reliable model"** — code you can't fully understand or explain and can't be sure covers the edge cases; not necessarily broken or even bad, but with no clear domain boundaries, non-explicit invariants, un-inspectable state, scattered behavior, and no safe way to change it. It predates LLMs [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:08:31-00:09:16|direct|2026-07-03]
- LLMs "weren't trained on good code — they were trained on *all* our code," so they repeat and latch onto the patterns already in your codebase; more context does **not** mean more structure, and wrong agent assumptions are amplified as **compounding slop** [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:10:12-00:17:53|direct|2026-07-03] [epistemic:: tentative]
- The central remedy is an **explicit model** — a structured representation of how the system should behave (state machines being one form, via given-when-then / Gherkin), that combines intent and execution so both the code and the app's behavior map to it, giving "an executable description without all the noise of code" (~90% of code, he claims, has nothing to do with behavioral intent) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:11:22-00:14:38|direct|2026-07-03] [epistemic:: tentative]
- The architectural inversion: **determinism at the core, non-determinism at the edges** — write *programs that call LLMs* rather than *LLMs that call programs*. Khourshid credits Ken Wheeler ("agent-driven workflows with a sprinkling of deterministic tools are a fool's errand") and the "deterministic core, agentic shell" framing that mirrors Gary Bernhardt's "functional core, imperative shell" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:03-00:20:32|direct|2026-07-03] [epistemic:: tentative]
- **"Agents are very obedient, but they ironically don't have much agency"** — told to build a feature, an agent goes straight to code. But if *you* know how you want to model something, the agent will build that model for you; you don't have to write it from scratch [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:13:34-00:14:38|direct|2026-07-03] [epistemic:: tentative]
- You don't need state machines specifically — **you need structure**; "modeling is not ceremony when it replaces confusion," so model only the confusing parts and start rough, then iterate. Best practices didn't change; AI just made them easier to forget and "more important now than ever" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:21:18-00:30:18|direct|2026-07-03]

## Extracted Claims

### Speaker and framing

- The speaker is David Khourshid ("David K Piano" / @DavidKPiano online; rendered "David K. Piena" by the STT), creator of the open-source library **XState** (a library for state machines and statecharts, made ~10 years ago) and founder of **Stately.ai** (founded ~5 years ago, making state machines easier to build) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:00:36-00:01:03|direct|2026-07-03] [epistemic:: tentative]
- He is building the next version of the Stately editor and **XState v6**; he claims XState is in many critical systems and that anyone in the UK has likely interacted with something relying on it (he is "not allowed to say what") [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:01:09-00:01:41|direct|2026-07-03] [epistemic:: tentative]
- Other projects mentioned: XState Store v4, a graph library, a free open-source state-machine visualizer (rendered "stately.sketch.ai"), and a TanStack collaboration [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:01:41-00:01:58|direct|2026-07-03] [epistemic:: tentative]
- His interest in state machines began ~10 years ago with **state-and-transition explosion** — when systems get complex, states and transitions multiply everywhere; he frames the whole talk with a running analogy to raising his three-month-old (who is "embarrassingly deterministic" for the first days, then non-deterministic) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:02:39-00:03:29|direct|2026-07-03] [epistemic:: tentative]

### Determinism, non-determinism, and state machines

- **Determinism** in the simplest terms is: given the same input, you get the same output — conceptually like a pure function (not exactly, because it can be async), where you know exactly what the result will be [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:03:35-00:03:57|direct|2026-07-03]
- **Non-determinism** means: given the exact same input, you don't know exactly what will come out — but this doesn't mean fully random (it could be a fixed set of choices) and it is **not exclusive to LLMs** [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:03:57-00:04:14|direct|2026-07-03]
- He learned determinism/non-determinism through finite-state machines: **DFAs** (deterministic finite automata) and **NFAs** (non-deterministic finite automata); you can convert an NFA to a DFA, but the state machine gets much more complex — "you're paying for that complexity in structure" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:04:14-00:04:40|direct|2026-07-03] [epistemic:: tentative]
- Statecharts help *contain and reduce* that complexity and make it visual, so you can describe anything from Casio watches and microwaves to complex web apps — and, increasingly, AI agents [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:04:40-00:05:00|direct|2026-07-03] [epistemic:: tentative]

### The problem: unstructured delegation and slop

- AI made it "a lot easier to skip engineering" and go straight to prompting; going to a prototype is easy, going to production is hard — he has "15 to 20 unfinished side projects" as a result [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:05:00-00:05:44|direct|2026-07-03] [epistemic:: tentative]
- His thesis: the best way to build *with* AI is the same way we should build *without* AI — the principles are unchanged: **model thoughtfully** (structure, shared vocabulary, blueprints before building), **iterate sufficiently**, and **make core logic explicit** (clear, not scattered across the codebase) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:05:44-00:06:49|direct|2026-07-03]
- The **root problem is not vibe coding, not AI "taking over," not even AI hallucinating — it is unstructured delegation**: deciding to throw everything over the wall and let the agents take care of judgment, structure, implementation, and sometimes even taste [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:06:49-00:07:24|direct|2026-07-03]
- "Out comes slop, but the slop works, so who cares?" — the spoiler is that users *do* care when code slowly rots from the inside out, features take longer to maintain, or you get big security holes [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:07:24-00:07:53|direct|2026-07-03]
- Slop is not new and not AI-exclusive: the "looks good to me" skim-and-accept of a giant PR (the "button is rewritten in Rust" and you just deal with it), or the "crazy bash command" you approve with "go for it, dude — I don't know what this does, but I'm sure it's fine" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:07:53-00:08:28|direct|2026-07-03] [epistemic:: tentative]

### Slop code defined

- **"Slop code is code without a reliable model"** — code you can't fully understand or explain, where you're not sure whether all the edge cases are covered or whether it works; it might look like it works on the surface but you can't be sure [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:08:31-00:08:57|direct|2026-07-03]
- It does **not** mean broken code and might not even be bad code, but slop code has properties: **no clear domain boundaries, invariants not explicit, states you can't inspect, behavior scattered throughout the app, and no safe way to change it** — and this existed even before LLMs [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:08:57-00:09:16|direct|2026-07-03]
- The "**slop machine**" triple pun (state machine / slot machine / slop machine): the practice is addictive — if the code or behavior isn't quite right, you "pull the lever again" and regenerate, which is how slop permeates the whole codebase [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:09:27-00:10:01|direct|2026-07-03] [epistemic:: tentative]

### Why AI won't fix it, and the two sources of truth

- AI is not simply "better than you at coding": LLMs **weren't trained on good code — they were trained on *all* our code**, so they repeat our patterns and latch onto whatever already exists in the codebase [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:10:01-00:10:36|direct|2026-07-03] [epistemic:: tentative]
- The industry keeps behavior/structure in two places: (1) **markdown files** — skills, CLAUDE.md, agents.md, plans — a natural-language way to describe intent; and (2) **code**, but code is a "noisy source of truth" because intent is mixed with architecture and boilerplate — he claims **~90% of code has nothing to do with the behavioral intent** you try to explain in the markdown [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:10:36-00:11:35|direct|2026-07-03] [epistemic:: tentative]
- This points to a hidden third layer and the talk's central theme: an **explicit model** — a combination of intent and execution that is *structured* (can still contain natural language), to which both the code and the app's intended behavior map directly [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:11:35-00:12:11|direct|2026-07-03]

### The explicit model

- A **model** (not a large language model — modeling software) is "an explicit representation of how the system should behave"; state machines describe behavior with **given-when-then** statements (a.k.a. Gherkin / Cucumber): given a state, when an event happens, then a new state — mapping to states, events, and transitions on a graph [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:12:11-00:12:53|direct|2026-07-03] [epistemic:: tentative]
- State machines aren't the only way to model, nor the only modelable aspect: logical flows can use state machines, BPMN, statecharts, or flowcharts; data can be modeled with domain-driven design (he notes Matt Pocock will cover that later) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:12:53-00:13:17|direct|2026-07-03] [epistemic:: tentative]
- Why doesn't AI reach for models on its own? **"Agents are very obedient, but they ironically don't have much agency"** — told to build a feature, an agent goes straight to code and iterates on the noisy artifact [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:13:22-00:13:57|direct|2026-07-03]
- You don't have to create models from scratch: if you know how you want to model something, **AI will help create the model**, and using that shared understanding you build the feature; when you refine, you update the model and reference it in the code — "an executable description of our codebase without all the noise of code" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:13:57-00:14:38|direct|2026-07-03] [epistemic:: tentative]

### Failure modes that exclude models

- **One-shotting** — going straight from a prompt to the result; popular in early AI apps, but most apps shouldn't work this way because iteration and human input still matter [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:14:38-00:15:07|direct|2026-07-03]
- **Prose control flow** — skills are useful for important knowledge, but a skill that says "you must do this, you should never do this, only do this when X, then do step 1/2/3" tries to represent **control flow in natural language** and just hopes the agent follows it, which sometimes it won't [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:15:07-00:15:40|direct|2026-07-03]
- **Agents as the system** — throwing more agents at the problem is "just asking for more chaos if we don't constrain the system" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:15:40-00:15:59|direct|2026-07-03]
- **Entanglement of concerns** — AI is good at "getting the job done" and declaring "goal complete," with the same result as a junior developer who forgets separation of concerns and mixes everything together [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:16:06-00:16:37|direct|2026-07-03] [epistemic:: tentative]
- **Larger context windows are not the fix**: "more context does not mean more structure"; you can't keep shoving instructions and "you must follow this workflow exactly" into context — it just gets noisier, and bigger context doesn't mean better performance ("many, many studies on this") [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:16:37-00:17:11|direct|2026-07-03] [epistemic:: tentative]
- **Compounding slop**: agents make assumptions and "fill in the gaps with what they think is best," some of which are wrong; because AI follows existing patterns, wrong assumptions are amplified and get worse throughout the codebase [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:17:11-00:17:53|direct|2026-07-03] [epistemic:: tentative]
- A missing model is a **missing blueprint**: like building a house one wall at a time with no design — it might look fine from outside but you wouldn't want to live in it; the React "useState for everything" pattern that expands into a mess is his concrete example (AI just follows the patterns already there) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:17:53-00:19:01|direct|2026-07-03] [epistemic:: tentative]

### The inversion: deterministic core, agentic shell

- **Ken Wheeler** recently tweeted that "agent-driven workflows with a sprinkling of deterministic tools are a fool's errand" — it should be the other way around: **deterministic workflows with a sprinkling of AI**, letting each do what it's actually good at [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:03-00:19:28|direct|2026-07-03] [epistemic:: tentative]
- He cites a recent article's term **"deterministic core, agentic shell,"** which mirrors **Gary Bernhardt's "functional core, imperative shell"**; the article "called him out" by name [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:28-00:19:52|direct|2026-07-03] [epistemic:: tentative]
- Two types of apps are emerging: (1) **LLMs that call programs** — all workflow logic lives in the LLM, trusting the agent as an "air traffic controller" (risky and "a little bit lazy"); and (2) the inversion he advocates, **programs that call LLMs** — "move the non-determinism to the edges and move the determinism to the core" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:19:52-00:20:32|direct|2026-07-03]
- Modern AI apps aren't one-shot; they need **iteration steps in the middle**, and inside that iteration lives the deterministic structure — well-defined workflows with AI at the nodes/edges [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:20:37-00:21:07|direct|2026-07-03] [epistemic:: tentative]
- **"Modeling is not ceremony when it replaces confusion"**: you don't have to model everything formally — only the confusing parts — and AI is good at helping you model, so you start rough and iterate (like rough UX prototyping) rather than writing a formal spec up front [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:21:18-00:22:09|direct|2026-07-03]

### Stately example, separation of concerns, and the email demo

- The next-version Stately editor is one of the most complex apps he's worked on; because its core logic is represented (in his case as state machines), it's easy to let AI help with feature development without mixing concerns, because AI has a clear picture of the core logic [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:22:11-00:23:00|direct|2026-07-03] [epistemic:: tentative]
- **Separation of concerns** is still relevant: AI will avoid "slopping up" your codebase if concerns are explicit and well-separated [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:23:00-00:23:19|direct|2026-07-03]
- You **don't necessarily need state machines** — "the important thing is that you need structure"; agents work well in structure, so you help yourself and the agents at once [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:23:19-00:23:39|direct|2026-07-03]
- **Email-agent demo (built with XState):** a state machine that first gathers requirements, then (once complete) creates a draft, then iterates on the draft with the user, and only then sends it — instead of throwing the whole task to the LLM [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:23:39-00:24:58|direct|2026-07-03] [epistemic:: tentative]
- The deterministic constraints make invalid states unreachable: it should be **impossible to send the email without approving a draft**, and **impossible to create a draft without all the requirements satisfied**; the non-deterministic (fuzzy) parts — is the email missing anything, drafting the email — live at the edges, while the deterministic parts ensure the right state at the right time [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:26:06-00:26:53|direct|2026-07-03]
- "This structure works for most things" — even building your own Cursor is "exactly this type of while loop" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:26:56-00:27:28|direct|2026-07-03] [epistemic:: tentative]

### Call to action and close

- Practical exercise: pick one confusing workflow in an existing app and **model it explicitly** — which might mean decoupling UI from core logic, or codifying a workflow currently handed entirely to an agent [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:27:28-00:28:02|direct|2026-07-03]
- Guiding questions: **what can be deterministic** (don't let AI agents do deterministic things), **where is iteration useful** (human-in-the-loop refinement), and **where can logic be separated from the UI** (good advice with or without AI) [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:28:02-00:28:34|direct|2026-07-03]
- In short: **non-determinism at the edges, determinism at the core** — and stop one-shotting, putting control flow in natural language, letting agents and sub-agents run amok, and mixing concerns [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:28:34-00:28:58|direct|2026-07-03]
- Closing analogy: a baby's complexity doesn't go away, but books, family, and resources provide a **model** that makes the complexity "survivable"; "your codebase is your baby," and the model is for future-you, your team, and **especially for your agents** so they stop producing slop [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:28:58-00:29:54|direct|2026-07-03] [epistemic:: tentative]
- **"The model is how collaboration survives the speed"** — the ~10× speeds of building with AI [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:29:54-00:30:03|direct|2026-07-03]
- Final line: the best practices didn't change; AI made it easier to *forget* them, but they've "become more important now than ever" [prov:src-2026-07-03-goodbye-slop-welcome-determinism#t00:30:03-00:30:18|direct|2026-07-03]

## Notes

**Validity assessment:**

- The audio is clean, single-speaker, studio-recorded conference narration, so the page is graded `sourced`. Per-claim `[epistemic:: tentative]` hedges are applied across the STT failure surface per the video-ingestion tiered-epistemic policy: proper nouns, product/version names, technical terms, and numbers.
- **Names mended from the official video description (via `yt-dlp`, not the STT):** the speaker is **David Khourshid**, handle **@DavidKPiano** ("David K Piano"; the STT renders "David K. Piena" at 0:00:36 and "David K. Pino" at 0:19:46). He is the **founder of Stately.ai** and **creator of XState** (the STT renders it "Xstate"). The description confirms the title word "determinism" (STT: "Terminism," 0:00:17).
- **Terms and names as-heard, treated as tentative:** "**Ken Wheeler**" (tweet on agent-driven vs. deterministic workflows), "**Gary Bernhardt**" ("functional core, imperative shell"; STT: "Cary Bernhardt," 0:19:36), "**useState**" (STT: "use dates," 0:18:40), "Gherkin/Cucumber," "BPMN," "DFA/NFA," "TanStack," "Casio," and the visual-editor URL rendered "stately.sketch.ai" (0:01:52). "Claude" is rendered "clod"/"clods" (0:07:19, 0:07:26). The "deterministic core, agentic shell" article and the person who "called him out" are not named in the transcript.
- **Figures are the speaker's own rhetorical estimates, recorded as his claims, not verified fact:** "~90% of code has nothing to do with behavioral intent," "15–20 unfinished side projects," "five skills vs. a thousand," and "10× speeds." The "many studies" on context length and the "research/patterns" claims are cited without references.
- **Speaker labels:** automatic diarization did not run (the pipeline's TorchCodec dependency was missing), so the committed raw transcript carries no `SPEAKER:` labels. The talk is single-speaker throughout, so labels are not required.

## Source Metadata

- **Speaker:** David Khourshid (creator of XState; founder of Stately.ai)
- **Channel:** AG Grid
- **Publication:** YouTube
- **URL:** https://youtu.be/uMvTAF280so
- **Publish date:** 2026-06-26
- **Duration:** 30:27
- **Event:** "Beyond the Prompt" conference (AG Grid + Bryntum, London, 2026)
- **Speaker links:** X https://x.com/DavidKPiano
- **Source type:** transcript (video sub-case)
- **Path:** `sources/2026/2026-07/2026-07-03-goodbye-slop-welcome-determinism.md`

The video fields (title, channel, publish date, duration, speaker bio) were sourced from the
`yt-dlp` metadata and official description pulled during acquisition. The committed transcript is
the durable record; the `url` is a courtesy pointer that may rot.
