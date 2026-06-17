---
id: src-2026-06-17-interpretable-context-methodology
title: "Interpretable Context Methodology: Folder Structure as Agent Architecture"
type: source
status: active
summary: "arXiv paper (Van Clief & McDermott, 2026) presenting Interpretable Context Methodology (ICM), a method that replaces framework-level AI-agent orchestration with filesystem structure — numbered folders as stages, markdown files as stage contracts, local scripts for non-AI work — applying Unix pipeline, modular-decomposition, multi-pass-compilation, and literate-programming principles to context engineering for sequential, human-reviewed workflows."
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
- human-oversight
- multi-pass-compilation
- prompt-chaining
- pdf-ingestion
domains:
- ai-agents
- software
- human-ai-interaction
supersedes: null
superseded_by: null
aliases:
- "Interpretable Context Methodology: Folder Structure as Agent Architecture"
- "Interpretable Context Methodology: Folder Structure as Agentic Architecture"
- "ICM (Interpretable Context Methodology) paper"
- "src-2026-06-17-interpretable-context-methodology"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-06/2026-06-17-interpretable-context-methodology/source.md
url: "https://arxiv.org/abs/2603.16021"
content_hash: "sha256:c45769a41c66807c5b215a43dd3f46fc754652bd8b2587f6cd7b2c4ba2c78fea"
ingested_at: 2026-06-17
source_type: paper
extraction_tool: pdftotext
extraction_model: "poppler-24.02.0"
extraction_date: 2026-06-17
original_asset: 2603.16021v2.pdf
compilation_status: compiled
compiled_against_hash: "sha256:c45769a41c66807c5b215a43dd3f46fc754652bd8b2587f6cd7b2c4ba2c78fea"
compiled_targets:
- interpretable-context-methodology
- context-engineering
- progressive-disclosure
---

## TL;DR

An arXiv preprint (Jake Van Clief & David McDermott, Eduba / University of Edinburgh; arXiv:2603.16021v2 [cs.AI], 18 Mar 2026) presenting **Interpretable Context Methodology (ICM)**, a method that replaces framework-level AI-agent orchestration with filesystem structure. Numbered folders represent workflow stages; plain markdown `CONTEXT.md` files carry the prompts and context that tell a single agent what role to play at each step; local scripts handle mechanical work that does not need AI. One orchestrating agent, reading the right files at the right moment, does the work a multi-agent framework would otherwise do. The protocol applies Unix pipeline design, modular decomposition, multi-pass compilation, and literate programming to the problem of structuring context for language models, and targets the specific class of **sequential, human-reviewed, repeatable** workflows. The contribution is an architectural pattern plus early practitioner reports — the paper is explicit that it contains **no controlled evaluation**, so its efficacy claims are theory- and practitioner-supported rather than measured. Open source under the MIT license.

## Key Takeaways

- ICM replaces code-level orchestration with filesystem structure: numbered folders are stages, markdown files carry per-stage prompts/context, local scripts do the non-AI mechanical work, and a single orchestrating agent reads the right files at the right moment instead of a multi-agent framework coordinating in code. [prov:src-2026-06-17-interpretable-context-methodology#p1|direct|2026-06-17] [epistemic:: sourced]
- The architecture is a **five-layer context hierarchy** (Layer 0 workspace identity → Layer 1 task routing → Layer 2 stage contract → Layer 3 reference material → Layer 4 working artifacts); each agent loads only the layers a stage needs, keeping per-stage context typically in the 2,000–8,000-token range versus 30,000–50,000 for a monolithic prompt. [prov:src-2026-06-17-interpretable-context-methodology#p5|direct|2026-06-17] [epistemic:: sourced]
- ICM is positioned for **sequential, reviewable, repeatable** workflows and is explicitly *not* a replacement for frameworks in real-time multi-agent collaboration, high-concurrency multi-user systems, or workflows needing automated mid-pipeline branching. [prov:src-2026-06-17-interpretable-context-methodology#p14|direct|2026-06-17] [epistemic:: sourced]
- The headline benefit the authors emphasize is **observability as a side effect**: because every intermediate output is a plain file, the pipeline is a "glass-box" workflow — inspectable, editable, and aligned with EU AI Act human-oversight expectations (staged review, audit trails, intervention points) without an added explanation layer. [prov:src-2026-06-17-interpretable-context-methodology#p14|direct|2026-06-17] [epistemic:: sourced]
- All reported workspaces were built and run on **Claude Code with Claude Opus 4.6** as the orchestrating agent, delegating sub-tasks to **Claude Sonnet 4.6** via Agent Teams; the same folder hierarchy that is the human's control surface also supplies the context the primary agent uses to brief its sub-agents ("doing double duty"). The protocol is *designed* to be model-agnostic but was tested only on this one model family. [prov:src-2026-06-17-interpretable-context-methodology#p10|direct|2026-06-17] [epistemic:: sourced]
- The empirical base is **informal**: observations come from an invite-only, self-selected practitioner community of 52, gathered through conversation rather than instrumented measurement. The most-cited finding — 30 of 33 practitioners reporting a U-shaped human-edit pattern (heavy at first/last stages, light in the middle) — is self-reported, and the paper runs **no controlled comparison** of staged vs. monolithic context. These claims are reported as practitioner experience, not measured results. [prov:src-2026-06-17-interpretable-context-methodology#p13|tentative|2026-06-17] [epistemic:: tentative]

## Extracted Claims

### Core thesis and framing

- Current agent-orchestration frameworks (CrewAI, LangChain, AutoGen) handle multi-step orchestration, memory, tool use, and error recovery well, but adjusting their structure (reorder steps, swap a prompt, add/remove a stage) typically requires editing code, understanding abstractions, and redeploying — overhead the authors argue sequential human-reviewed workflows do not need. [prov:src-2026-06-17-interpretable-context-methodology#p1|direct|2026-06-17] [epistemic:: sourced]
- Central observation: if the prompts and context for each stage already exist as files in a well-organized folder hierarchy, no coordination framework is needed — one orchestrating agent reads the right files at the right moment, and if it delegates sub-tasks the same folder structure determines what context those sub-agents receive. The coordination logic lives in the filesystem, not in application code. [prov:src-2026-06-17-interpretable-context-methodology#p1|direct|2026-06-17] [epistemic:: sourced]
- ICM "trades the flexibility of a programmatic orchestrator for the portability, inspectability, and editability of plain files" — invoking Richard Gabriel's "worse is better" argument that simpler-to-implement systems survive and spread, and Plan 9's "everything is a file" extension of Unix. [prov:src-2026-06-17-interpretable-context-methodology#p8|direct|2026-06-17] [epistemic:: sourced]
- A control-surface comparison table contrasts the two approaches: changing stage order is "edit orchestration code, redeploy" (framework) vs. "rename or reorder folders" (ICM); modifying a prompt is "edit agent configuration in code" vs. "edit a markdown file"; "who can make changes" is "developer" vs. "anyone with a text editor" — while frameworks retain advantages in error recovery, conditional branching, and concurrent execution. [prov:src-2026-06-17-interpretable-context-methodology#p2|direct|2026-06-17] [epistemic:: sourced]

### Design principles and the five-layer hierarchy

- ICM rests on five design principles, each borrowed from established practice: (1) **one stage, one job** (McIlroy's Unix principle + Parnas information-hiding); (2) **plain text as the interface** (markdown/JSON only, per Kernighan & Pike); (3) **layered context loading** (load only what the stage needs — prevention rather than compression); (4) **every output is an edit surface** (Horvitz mixed-initiative + Shneiderman direct manipulation); (5) **configure the factory, not the product** (set the workspace up once, then each run reuses the configuration). [prov:src-2026-06-17-interpretable-context-methodology#p5|direct|2026-06-17] [epistemic:: sourced]
- The five context layers: Layer 0 (`CLAUDE.md`, ~800 tokens) is global identity/routing ("Where am I?"); Layer 1 (`CONTEXT.md`, ~300 tokens) is workspace-level task routing ("Where do I go?"); Layer 2 (stage `CONTEXT.md`, 200–500 tokens) is the per-stage contract ("What do I do?"); Layer 3 (reference material, 500–2,000 tokens) is the stable "factory"; Layer 4 (working artifacts, varies) is the per-run "product." [prov:src-2026-06-17-interpretable-context-methodology#p5|direct|2026-06-17] [epistemic:: sourced]
- The Layer 3 / Layer 4 split is load-bearing: Layer 3 (voice guides, design systems, conventions) should be **internalized as constraints** and is stable across runs (the "recipe"); Layer 4 (prior-stage output, source material) should be **processed as input** and changes every run (the "ingredients"). Delivering them as structurally separate context, rather than mixed in one undifferentiated prompt, gives the model clearer signals about what constrains its behavior versus what to act on. [prov:src-2026-06-17-interpretable-context-methodology#p6|direct|2026-06-17] [epistemic:: sourced]
- Layer 2 is "the control point of the entire system": each stage contract includes an **Inputs table** specifying exactly which Layer 3/4 files (and which sections) to load, making context selection explicit, editable, and auditable rather than leaving the agent to load everything or guess. [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]
- "The filesystem doing the work that a framework would otherwise do in code": stage sequencing is the folder numbering, context scoping is the folder hierarchy, state management is the files on disk, and coordination between stages is one folder's output being another folder's input. [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]
- Token economics: Layers 0–2 contribute roughly 1,300–1,600 tokens of identity/routing/stage instruction; Layer 3 adds 500–2,000 scoped reference tokens; total per-stage context typically ranges 2,000–8,000 tokens — "well within the range where current models perform at their best" — whereas a monolithic prompt loading all stages' instructions, all reference files, and all prior outputs can reach 30,000–50,000 tokens, pushing into the degradation range documented by the "lost in the middle" work. [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]

### Stage contracts, handoffs, and compiler analogy

- Each stage defines a three-part contract in its `CONTEXT.md` — **Inputs** (what it reads), **Process** (what it does), **Outputs** (what it writes) — and at each stage boundary the human can inspect and edit the output before the next stage runs. [prov:src-2026-06-17-interpretable-context-methodology#p9|direct|2026-06-17] [epistemic:: sourced]
- ICM "implements prompt chaining at the filesystem level": it realizes Wu, Terry & Cai's AI Chains (transparent, controllable multi-step LLM workflows where each step's output is the next step's input), but the chain is a sequence of folders and the links are plain files; the stage outputs serve as inspectable intermediate representations. [prov:src-2026-06-17-interpretable-context-methodology#p9|direct|2026-06-17] [epistemic:: sourced]
- The instruction files double as documentation in the spirit of Knuth's literate programming — the markdown that instructs the agent simultaneously tells a human what the stage does, making the workspace self-documenting; a new team member can read the `CONTEXT.md` files top to bottom and understand the whole pipeline without running it. [prov:src-2026-06-17-interpretable-context-methodology#p9|direct|2026-06-17] [epistemic:: sourced]
- The authors propose multi-pass compilation as the closest analogy (closer than Unix pipelines or Make): each ICM stage is like a compiler pass reading the previous pass's output, transforming it, and writing an inspectable intermediate representation; "incremental compilation" maps onto re-running only the stages whose declared inputs changed. [prov:src-2026-06-17-interpretable-context-methodology#p16|direct|2026-06-17] [epistemic:: sourced]

### Portability and working implementations

- A workspace is just a folder: it can be copied to another machine, committed to Git, emailed as a zip, or cloud-synced; it carries its own prompts, context structure, and stage definitions, with no server to configure and no deployment step. Every prompt edit and stage output is diffable and reversible — "infrastructure as code applied to AI workflows." [prov:src-2026-06-17-interpretable-context-methodology#p10|direct|2026-06-17] [epistemic:: sourced]
- The first ICM workspace is a three-stage **script-to-animation pipeline** (research → script → production) that produces working Remotion animation code, running in a single Claude Code session where Opus 4.6 orchestrates and delegates sub-tasks to Sonnet 4.6 — the delegation itself driven by each stage's `CONTEXT.md`. [prov:src-2026-06-17-interpretable-context-methodology#p10|direct|2026-06-17] [epistemic:: sourced]
- A second workspace is a five-stage **course-deck production** pipeline (content extraction → structural planning → slide drafting → visual design spec → final assembly) that turns unstructured source material into PowerPoint decks, surfacing the structural plan as an editable file before any slides are drafted. [prov:src-2026-06-17-interpretable-context-methodology#p11|direct|2026-06-17] [epistemic:: sourced]
- ICM includes a **workspace-builder**: a five-stage workspace whose output is a new workspace (discovery → stage mapping → scaffolding → questionnaire design → validation); it follows ICM conventions itself, so the workspaces it produces are structurally consistent and practitioners can create new domains without learning the conventions in detail. [prov:src-2026-06-17-interpretable-context-methodology#p11|direct|2026-06-17] [epistemic:: sourced]
- ICM workspaces have been adopted outside the authors' organization — the University of Edinburgh's Neuropolitics Lab, ICR Research, and the Academy of International Affairs in Bonn — across academic research, policy analysis, and content production, though details are limited by NDAs and a structured study of these deployments is named as a clear next step. [prov:src-2026-06-17-interpretable-context-methodology#p11-12|tentative|2026-06-17] [epistemic:: tentative]

### Practitioner experience and threats to validity

- Observations are drawn from an invite-only practitioner community of 52 members (AI engineers through business owners and academics) via ongoing conversation, "not from formal data collection protocols," and the authors say they should be read as practitioner reports rather than controlled findings. [prov:src-2026-06-17-interpretable-context-methodology#p12|direct|2026-06-17] [epistemic:: sourced]
- The most consistent reported observation is a **U-shaped human-intervention pattern**: across 33 community members using multi-stage workspaces, 30 reported heavy editing at stage 1 (direction-setting, creative judgment), light editing in the middle stages, and heavy editing again at the final stage (alignment work, closer to debugging); the remaining 3 reported roughly equal editing. Figure 5 gives approximate edit frequencies of ~92% (stage 1), ~30% (middle), ~78% (final). These are self-reported through conversation, not instrumented measurement. [prov:src-2026-06-17-interpretable-context-methodology#p12|tentative|2026-06-17] [epistemic:: tentative]
- Reported accessibility signal: non-technical users modified stage behavior by editing markdown `CONTEXT.md` files (tone tweaks, added constraints like "keep scripts under 90 seconds"), and three community members with no coding experience and no prior Claude Code exposure used the workspace-builder to create and run workspaces that produced ten-minute animated videos. The authors flag this as "a single data point from a small group." [prov:src-2026-06-17-interpretable-context-methodology#p13|tentative|2026-06-17] [epistemic:: tentative]
- The authors enumerate threats to validity directly: data collection is informal; the community is invite-only and self-selected (selection + enthusiasm bias); the U-shape figures are unverified by controlled measurement; all testing used a single model family (Opus 4.6 / Sonnet 4.6); and **no controlled comparison** was run between ICM's staged loading and a monolithic prompt, so the "scoped context improves output quality" claim rests on the "lost in the middle" literature and practitioner judgment, not measured effect sizes. [prov:src-2026-06-17-interpretable-context-methodology#p13|direct|2026-06-17] [epistemic:: sourced]

### Future directions

- The authors sketch **semantic debugging** for AI workflows by analogy to debuggers/source maps: output provenance via lightweight identifiers linking output sections back to the instruction or reference file that produced them; cross-stage trace verification via a proposed "Verify" section in stage contracts (generalizing an existing audit-file pattern that re-checks stage-_n_ output against stage-_n_−2); and speculative "breakpoints" in markdown that pause a stage for inspection. [prov:src-2026-06-17-interpretable-context-methodology#p17|direct|2026-06-17] [epistemic:: sourced]
- The proposed **edit-source principle**: editing a stage's output is "patching the binary" — it fixes one run, whereas editing the source (voice guide, stage contract, prior stage) "fixes every future run"; recurring output edits are diagnostic, and a future ICM could track edits across runs and surface source-level changes, turning one-off fixes into durable system improvements. The authors note creative content is fuzzier than compiled code, so some output edits are legitimately human value, not bugs. [prov:src-2026-06-17-interpretable-context-methodology#p17-18|direct|2026-06-17] [epistemic:: sourced]

## Notes

- **Document tier:** born-digital, clean (arXiv GenPDF, machine-typeset LaTeX, not a scan). Per the tiered epistemic policy (`schema/reference/pdf-ingestion.md`), born-digital input keeps the parent type's normal `sourced` default with no spot-verification mandate.
- **Extraction note:** extracted with `pdftotext` (poppler 24.02.0) in a per-page loop that prepends `<!-- page: N -->` markers — the PDF runbook's tool-agnostic generic contract (D-04), not the olmOCR worked instance. For a born-digital PDF the embedded text layer is authoritative, so a VLM OCR pass would add hallucination risk for no benefit; `pdftotext` reads the actual glyph stream and was verified to preserve single-column reading order with no column interleaving. The `extraction_model` field records the poppler version because the four PDF extraction fields are lint-required when `original_asset` is a `*.pdf` and `pdftotext` has no model tag.
- **Page-level epistemic is `mixed` by design:** the architectural description (five principles, five layers, token budgets, stage contracts, portability) is directly stated and graded `sourced`; the practitioner-experience claims (52-member community, the 30/33 U-shape, the three no-coding users, external NDA-limited deployments) are self-reported through conversation and graded `tentative`; the central efficacy claim that scoped context improves output quality is explicitly unmeasured by the authors.
- **What ICM is *not*, per the authors:** not a replacement for multi-agent frameworks in real-time agent collaboration, high-concurrency multi-user systems, or automated mid-pipeline branching — the claim is bounded to a "large and common class" of sequential, reviewable, repeatable workflows.
- **Relationship to MCP:** the paper positions ICM as complementary to, not competing with, Anthropic's Model Context Protocol — MCP standardizes how a model reaches external tools/data; ICM structures *what context* an agent receives across a multi-stage workflow, and an ICM stage may use MCP connections while its folder structure scopes the tool definitions loaded.
- **Title variant:** the rendered cover-page title and every running header read "Folder Structure as Agent Architecture"; the embedded PDF metadata `Title` reads "…as Agentic Architecture." The rendered form is used as canonical here, with the metadata variant kept as an alias for search.

## Source Metadata

- **Type:** academic preprint (arXiv, cs.AI)
- **Title:** Interpretable Context Methodology: Folder Structure as Agent Architecture
- **Authors:** Jake Van Clief, David McDermott (Eduba; University of Edinburgh)
- **Identifier:** arXiv:2603.16021v2 [cs.AI], submitted 18 Mar 2026
- **License / code:** open source under the MIT license; reference implementation at `https://github.com/RinDig/Interpretable-Context-Methodology-ICM`
- **Source file:** `sources/2026/2026-06/2026-06-17-interpretable-context-methodology/source.md`
- **Original asset:** `2603.16021v2.pdf` (co-located in the bundle)
- **Content hash:** `sha256:c45769a41c66807c5b215a43dd3f46fc754652bd8b2587f6cd7b2c4ba2c78fea`
- **Ingested:** 2026-06-17
