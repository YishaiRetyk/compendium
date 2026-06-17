---
id: context-engineering
title: "Context Engineering"
type: concept
status: active
summary: "The discipline of filling an LLM's context window with the right information — instructions, retrieved knowledge, memory, tool descriptions, and prior outputs — structured so the model can use them effectively; named by Karpathy (June 2025) as a broader frame than 'prompt engineering' and operationalized through strategies like write/select/compress/isolate and stage-scoped loading."
created_at: 2026-06-17
updated_at: 2026-06-17
sources:
- src-2026-06-17-interpretable-context-methodology
epistemic_status: mixed
tags:
- context-engineering
- prompt-engineering
- llm-agents
- context-window
- lost-in-the-middle
domains:
- ai-agents
- software
- human-ai-interaction
supersedes: null
superseded_by: null
aliases:
- "Context Engineering"
- "context-engineering"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Context engineering is the discipline of filling a language model's context window with the **right information, in the right structure, at the right moment** — instructions, retrieved knowledge, memory, tool descriptions, and prior outputs — so the model can use them effectively. The practitioner community adopted the term to capture what building production AI systems actually involves; Andrej Karpathy gave it its clearest articulation in June 2025, arguing that "prompt engineering" understates the work by suggesting a single crafted instruction. Lance Martin (LangChain) decomposed it into four strategies — **write, select, compress, isolate** — and Simon Willison extended its scope to the entire information environment, including prior model responses and system state. The empirical pressure behind it is the "lost in the middle" finding: models degrade when relevant information is buried in long contexts, so loading less irrelevant material often beats compressing it after the fact. It is the conceptual layer beneath [[progressive-disclosure|Progressive Disclosure]], [[subagents|Subagents]], and [[interpretable-context-methodology|Interpretable Context Methodology]].

## Key Facts

- Context engineering is "the broader discipline of filling the context window with the right information: instructions, retrieved knowledge, memory, tool descriptions, and prior outputs, all structured so the model can use them effectively." [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Andrej Karpathy gave the term its clearest articulation in June 2025, arguing "prompt engineering" understates the work — prompt engineering suggests crafting a single instruction, whereas context engineering is the broader discipline. [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Lance Martin (LangChain) formalized a taxonomy of four strategies: **write** (author instructions), **select** (choose relevant context), **compress** (reduce token waste), and **isolate** (keep unrelated context separate). [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Simon Willison argued the entire information environment — including previous model responses and system state — is part of the context that needs engineering. [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- The "lost in the middle" finding (Liu et al.) is the load-bearing motivation: LLMs perform significantly worse when relevant information is buried in the middle of long contexts, and more irrelevant material in the window degrades performance on the material that matters. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Prevention can beat compression: prompt compression can reach ~20× token reduction with minimal performance loss (Jiang et al.), but simply not loading irrelevant context in the first place avoids the problem rather than treating it after the fact. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Tool-definition scoping is a context-engineering lever: loading all tool definitions upfront into the context window slows agents and increases costs (Jones & Kelly, Anthropic), so scoping tool definitions to the current step is more efficient. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Context engineering is distinct from the Model Context Protocol (MCP): MCP standardizes how a model *reaches* external tools and data; context engineering concerns how to *structure and deliver* context to the model — the two are complementary. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]

## Detail

The term reframes a shift in where the difficulty of building AI systems actually lives. "Prompt engineering" frames the task as authoring one good instruction; context engineering frames it as managing the whole window — what goes in, in what structure, and when. Current agentic frameworks (LangChain, AutoGen, CrewAI) handle this through code-level abstractions: agents as objects, conversations as message arrays, orchestration as programmatic control flow, which suits dynamic multi-agent collaboration and complex branching [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]. But the same end — the right context reaching the right step — can be reached structurally rather than programmatically, which is the bridge from context engineering to [[interpretable-context-methodology|Interpretable Context Methodology]] and to filesystem-native patterns generally.

The empirical backbone is the **"lost in the middle"** result: retrieval and reasoning quality fall when the relevant span sits in the middle of a long context, and adding irrelevant material actively hurts. That finding splits the field's responses into two camps — *compress* what is loaded (Lance Martin's "compress," the LLMLingua line of work) versus *select* less to begin with (load only what the step needs). Much of the practical art is choosing prevention over compression: avoid loading irrelevant context rather than shrinking it after the fact [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced].

This concept is the shared root of several patterns already in this wiki. [[progressive-disclosure|Progressive Disclosure]] is context engineering as a loading discipline — keep the always-resident layer tiny, defer detail to on-demand reads. [[subagents|Subagents]] are context engineering across agents — pay a large context cost in a disposable window and let only a compressed summary cross back. Interpretable Context Methodology is context engineering as filesystem structure — the same model produces different behavior at each stage purely because the folder hierarchy changes what context it receives. Within [[claude-code|Claude Code]] and frameworks like [[gsd|GSD (Get-Shit-Done)]], the recurring move is the same: treat the context window as a scarce public good and engineer what occupies it.

**Epistemic note.** This page is currently anchored in a single source's literature framing (the ICM paper's §2.2), so the attributions to Karpathy, Martin, and Willison are as that paper characterizes them; it is graded `mixed` and is a natural candidate for enrichment from primary sources (the Karpathy post, the LangChain and Simon Willison essays, and the Liu et al. paper) on future ingests.

## Related Pages

- [[interpretable-context-methodology|Interpretable Context Methodology]] — context engineering realized as filesystem structure.
- [[progressive-disclosure|Progressive Disclosure]] — context engineering as a tiered loading discipline.
- [[subagents|Subagents]] — context engineering applied across isolated agent contexts.
- [[claude-code|Claude Code]] — the environment where these context-engineering patterns are exercised.
- [[gsd|GSD (Get-Shit-Done)]] — an orchestrator built around externalizing agent context into files.

## Sources

- [[src-2026-06-17-interpretable-context-methodology|Interpretable Context Methodology: Folder Structure as Agent Architecture]] — Van Clief & McDermott, arXiv:2603.16021v2 [cs.AI], March 2026 (§2.2 Context Engineering and Agentic AI)
