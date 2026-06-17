---
id: interpretable-context-methodology
title: "Interpretable Context Methodology"
type: concept
status: active
summary: "A method (Van Clief & McDermott, 2026) that replaces framework-level AI-agent orchestration with filesystem structure: numbered folders are workflow stages, markdown CONTEXT.md files are stage contracts, local scripts do non-AI work, and one agent reads the right files at each step — applying Unix, multi-pass-compilation, and literate-programming principles to context engineering for sequential, human-reviewed workflows."
created_at: 2026-06-17
updated_at: 2026-06-17
sources:
- src-2026-06-17-interpretable-context-methodology
epistemic_status: mixed
tags:
- interpretable-context-methodology
- context-engineering
- agent-orchestration
- filesystem-architecture
- human-in-the-loop
- multi-pass-compilation
- prompt-chaining
domains:
- ai-agents
- software
- human-ai-interaction
supersedes: null
superseded_by: null
aliases:
- "Interpretable Context Methodology"
- "ICM"
- "interpretable-context-methodology"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Interpretable Context Methodology (ICM) is a method for orchestrating AI agent workflows with **filesystem structure instead of framework code**. A workspace is a folder; numbered sub-folders are workflow stages; each stage's `CONTEXT.md` is a plain-markdown contract declaring its inputs, process, and outputs; local scripts handle the mechanical work that does not need AI. One orchestrating agent reads the right files at the right moment — the folder structure supplies stage sequencing, context scoping, and state, doing the coordination a multi-agent framework would otherwise do in code. ICM is deliberately scoped to **sequential, reviewable, repeatable** workflows (content production, slide-deck generation, research/policy analysis), where its standout property is observability: every intermediate output is a plain file a human can read and edit, so the pipeline is a "glass box" by construction. It is the same context-discipline as [[progressive-disclosure|Progressive Disclosure]] — load only what a stage needs — applied at the granularity of folders. Introduced by Jake Van Clief and David McDermott (arXiv, March 2026), MIT-licensed, with the paper offering an architectural pattern plus early practitioner reports rather than a controlled evaluation.

## Key Facts

- ICM replaces code-level orchestration with filesystem structure: numbered folders are stages, markdown files carry per-stage prompts/context, local scripts do non-AI mechanical work, and a single orchestrating agent reads the right files at the right moment. [prov:src-2026-06-17-interpretable-context-methodology#p1|direct|2026-06-17] [epistemic:: sourced]
- The architecture is a **five-layer context hierarchy**: Layer 0 `CLAUDE.md` (workspace identity/routing, ~800 tok), Layer 1 `CONTEXT.md` (task routing, ~300 tok), Layer 2 stage `CONTEXT.md` (stage contract, 200–500 tok), Layer 3 reference material (stable across runs — the "factory"), Layer 4 working artifacts (per-run — the "product"). [prov:src-2026-06-17-interpretable-context-methodology#p5|direct|2026-06-17] [epistemic:: sourced]
- Each stage is a three-part **contract** — Inputs / Process / Outputs — written in its `CONTEXT.md`; the Inputs table names exactly which Layer 3/4 files and sections to load, making context selection explicit, editable, and auditable. [prov:src-2026-06-17-interpretable-context-methodology#p9|direct|2026-06-17] [epistemic:: sourced]
- Layered loading keeps per-stage context typically at **2,000–8,000 tokens**, versus the 30,000–50,000 a monolithic prompt reaches when it loads every stage's instructions, all reference files, and all prior outputs — avoiding the "lost in the middle" degradation by construction rather than by after-the-fact compression. [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]
- Five design principles, each borrowed from established practice: one stage / one job (Unix + Parnas information-hiding), plain text as the interface, layered context loading, every output is an edit surface (mixed-initiative + direct manipulation), and "configure the factory, not the product." [prov:src-2026-06-17-interpretable-context-methodology#p5|direct|2026-06-17] [epistemic:: sourced]
- **Observability is a side effect, not a feature:** because every intermediate output is a plain file, the workflow is a "glass-box" system — inspectable with no logging layer or dashboard, and structurally aligned with EU AI Act human-oversight expectations (staged review, audit trails, intervention points). [prov:src-2026-06-17-interpretable-context-methodology#p14|direct|2026-06-17] [epistemic:: sourced]
- A workspace is portable by default: a folder that can be copied, committed to Git, zipped, or cloud-synced, with no server or deployment step — "infrastructure as code applied to AI workflows." [prov:src-2026-06-17-interpretable-context-methodology#p10|direct|2026-06-17] [epistemic:: sourced]
- Scope boundaries the authors draw explicitly: ICM is **not** for real-time multi-agent collaboration, high-concurrency multi-user systems, or automated mid-pipeline branching — it targets sequential, reviewable, repeatable workflows. [prov:src-2026-06-17-interpretable-context-methodology#p14|direct|2026-06-17] [epistemic:: sourced]
- The reference implementations (a 3-stage script-to-animation pipeline, a 5-stage course-deck pipeline, and a workspace-builder) were all run on Claude Code with Claude Opus 4.6 orchestrating and Claude Sonnet 4.6 sub-agents; the protocol is *designed* model-agnostic but was tested only on this family. [prov:src-2026-06-17-interpretable-context-methodology#p10|direct|2026-06-17] [epistemic:: sourced]
- The central efficacy claim — that scoped, staged context improves output quality — is **unmeasured**: the paper runs no controlled comparison against monolithic prompting and rests the claim on the "lost in the middle" literature plus a self-reported practitioner U-shape (30 of 33 community members). [prov:src-2026-06-17-interpretable-context-methodology#p13|tentative|2026-06-17] [epistemic:: tentative]

## Detail

### The core move: filesystem as orchestrator

ICM's premise is that mature agent frameworks (CrewAI, LangChain, AutoGen) solve a coordination problem — passing the right context to the right agent at the right time — that, for sequential workflows, can be solved instead by **putting the right files in the right folders**. If Agent A researches, B filters, and C writes, the framework's job is context routing; ICM achieves the same routing with one agent that reads a different `CONTEXT.md` at each numbered stage. "Stage sequencing is the folder numbering. Context scoping is the folder hierarchy. State management is the files on disk. Coordination between stages is one folder's output being another folder's input" [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]. The tradeoff is deliberate: ICM gives up a programmatic orchestrator's flexibility (dynamic branching, concurrency) for the portability, inspectability, and editability of plain files — the authors invoke Richard Gabriel's "worse is better" and Plan 9's "everything is a file" to argue that is the point, not a limitation [prov:src-2026-06-17-interpretable-context-methodology#p8|direct|2026-06-17] [epistemic:: sourced].

### The five layers and the Layer 3 / Layer 4 distinction

The hierarchy separates *structural routing* (Layers 0–2: identity, task routing, stage contract) from *content* (Layers 3–4). The content split is the subtler idea: Layer 3 reference material (voice guides, design systems, conventions) is stable across runs and should be **internalized as constraints** — "the recipe"; Layer 4 working artifacts (prior-stage output, source material) change every run and should be **processed as input** — "the ingredients." Delivering them as structurally separate context, rather than mixing persistent rules with per-run artifacts in one undifferentiated window, gives the model clearer signals about which information constrains its behavior and which it should act on [prov:src-2026-06-17-interpretable-context-methodology#p6|direct|2026-06-17] [epistemic:: sourced]. No agent reads every layer — a rendering agent may need only Layers 0–2, a script-writing agent reads down to Layer 4 — which is what keeps the per-stage window in the 2,000–8,000-token band where the authors argue models perform best [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced].

This is [[context-engineering|Context Engineering]] made structural: the same model produces different behavior at each stage purely because the folder structure changes what context it receives. And the layered-loading discipline — load only what the current stage needs, keep the always-resident layer small — is [[progressive-disclosure|Progressive Disclosure]] applied at folder granularity rather than within a single Skill or agent context.

### Stage contracts, prompt chaining, and the compiler analogy

Each stage's `CONTEXT.md` is a contract with Inputs / Process / Outputs sections; the human reviews whatever lands in the stage's `output/` folder and edits it directly before the next stage reads it. ICM frames this as **prompt chaining at the filesystem level** — Wu, Terry & Cai's "AI Chains," but with folders as the links and plain files as the intermediate representations [prov:src-2026-06-17-interpretable-context-methodology#p9|direct|2026-06-17] [epistemic:: sourced]. Because the instruction files double as human-readable documentation, the workspace is self-documenting in the spirit of Knuth's literate programming. The paper's richest analogy, developed as future work, is **multi-pass compilation**: each stage is a pass that reads the prior pass's output and emits an inspectable intermediate representation, and re-running only the stages whose declared inputs changed is incremental compilation. That analogy seeds the proposed research agenda — semantic debugging (output-provenance identifiers, a "Verify" section in stage contracts, markdown "breakpoints") and the **edit-source principle**: editing a stage's output is "patching the binary" and fixes one run, whereas editing the source fixes every future run, so recurring output edits should be treated as diagnostic signals pointing at source-level changes [prov:src-2026-06-17-interpretable-context-methodology#p17-18|direct|2026-06-17] [epistemic:: sourced].

### Evidence and limits

ICM's evidence base is explicitly informal: practitioner reports from an invite-only, self-selected community of 52, gathered through conversation rather than instrumentation. The most-cited pattern — a U-shaped human-edit curve, heavy at the first (direction-setting) and last (alignment) stages and light in the middle — was reported by 30 of 33 members, but is self-reported and unverified by controlled measurement [prov:src-2026-06-17-interpretable-context-methodology#p12|tentative|2026-06-17] [epistemic:: tentative]. Crucially, the authors run **no controlled comparison** of staged versus monolithic context, so the load-bearing efficacy claim is grounded in the "lost in the middle" literature and practitioner judgment, not measured effect sizes — and all testing used a single model family. This is why the page is graded `mixed`: the architecture is solidly described, the claims about what it *achieves* are not yet measured. Among ICM's contemporaries, the same filesystem-as-control-surface instinct animates the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] — [[gsd|GSD (Get-Shit-Done)]]'s `.planning/` artifact tree and [[spec-driven-development|Spec-Driven Development]]'s version-controlled spec are kindred moves to make agent context an inspectable file rather than hidden framework state.

## Related Pages

- [[context-engineering|Context Engineering]] — ICM is a structural realization of context engineering; the same model behaves differently per stage purely by what context the folder structure delivers.
- [[progressive-disclosure|Progressive Disclosure]] — layered context loading is progressive disclosure applied at folder granularity.
- [[subagents|Subagents]] — ICM's orchestrator delegates to sub-agents whose context is supplied by the same folder structure (Opus 4.6 → Sonnet 4.6 via Agent Teams).
- [[claude-code|Claude Code]] — the host environment for every reported ICM workspace.
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — kindred filesystem-as-control-surface approaches.
- [[gsd|GSD (Get-Shit-Done)]] — a `.planning/` artifact tree as the agent's externalized state.
- [[spec-driven-development|Spec-Driven Development]] — the spec as the version-controlled source of truth.

## Sources

- [[src-2026-06-17-interpretable-context-methodology|Interpretable Context Methodology: Folder Structure as Agent Architecture]] — Van Clief & McDermott, arXiv:2603.16021v2 [cs.AI], March 2026
