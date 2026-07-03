---
id: context-engineering
title: "Context Engineering"
type: concept
status: active
summary: "The discipline of filling an LLM's context window with the right information — instructions, retrieved knowledge, memory, tool descriptions, and prior outputs — structured so the model can use them effectively; named by Karpathy (June 2025) as a broader frame than 'prompt engineering' and operationalized through strategies like write/select/compress/isolate and stage-scoped loading."
created_at: 2026-06-17
updated_at: 2026-07-03
sources:
- src-2026-06-17-interpretable-context-methodology
- src-2026-07-03-agentic-search-context-engineering
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

Context engineering is the discipline of filling a language model's context window with the **right information, in the right structure, at the right moment** — instructions, retrieved knowledge, memory, tool descriptions, and prior outputs — so the model can use them effectively. The practitioner community adopted the term to capture what building production AI systems actually involves; Andrej Karpathy gave it its clearest articulation in June 2025, arguing that "prompt engineering" understates the work by suggesting a single crafted instruction. Lance Martin (LangChain) decomposed it into four strategies — **write, select, compress, isolate** — and Simon Willison extended its scope to the entire information environment, including prior model responses and system state. The empirical pressure behind it is the "lost in the middle" finding: models degrade when relevant information is buried in long contexts, so loading less irrelevant material often beats compressing it after the fact. It is the conceptual layer beneath [[progressive-disclosure|Progressive Disclosure]], [[subagents|Subagents]], and [[interpretable-context-methodology|Interpretable Context Methodology]]. A complementary framing from practice holds that context engineering is *mostly a retrieval problem*: Leonie Monigatti (Elastic) calls it "about 80% [[agentic-search|Agentic Search]]," because the arrow that moves content from context sources into the context window is powered by search tools — so the difficulty shifts toward search-tool design over many sources (files, memory, skills, databases, the web).

## Key Facts

- Context engineering is "the broader discipline of filling the context window with the right information: instructions, retrieved knowledge, memory, tool descriptions, and prior outputs, all structured so the model can use them effectively." [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Andrej Karpathy gave the term its clearest articulation in June 2025, arguing "prompt engineering" understates the work — prompt engineering suggests crafting a single instruction, whereas context engineering is the broader discipline. [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Lance Martin (LangChain) formalized a taxonomy of four strategies: **write** (author instructions), **select** (choose relevant context), **compress** (reduce token waste), and **isolate** (keep unrelated context separate). [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- Simon Willison argued the entire information environment — including previous model responses and system state — is part of the context that needs engineering. [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]
- The "lost in the middle" finding (Liu et al.) is the load-bearing motivation: LLMs perform significantly worse when relevant information is buried in the middle of long contexts, and more irrelevant material in the window degrades performance on the material that matters. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Prevention can beat compression: prompt compression can reach ~20× token reduction with minimal performance loss (Jiang et al.), but simply not loading irrelevant context in the first place avoids the problem rather than treating it after the fact. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Tool-definition scoping is a context-engineering lever: loading all tool definitions upfront into the context window slows agents and increases costs (Jones & Kelly, Anthropic), so scoping tool definitions to the current step is more efficient. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- Context engineering is distinct from the Model Context Protocol (MCP): MCP standardizes how a model *reaches* external tools and data; context engineering concerns how to *structure and deliver* context to the model — the two are complementary. [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced]
- A practitioner framing holds that context engineering is mostly *agentic search* — "about 80%" — because the choice of what moves from context sources into the context window is made by search tools, and that choice often matters more than the model itself. [prov:src-2026-07-03-agentic-search-context-engineering#t00:01:39-00:02:21|direct|2026-07-03] [epistemic:: tentative]
- The context to be engineered is spread across many sources at once — local files, working memory (a scratchpad / `plan.md`), agent skills, databases, the web, and long-term memory — each reached by its own search tool, so context engineering in practice includes curating a stack of search interfaces. [prov:src-2026-07-03-agentic-search-context-engineering#t00:04:31-00:06:33|direct|2026-07-03] [epistemic:: sourced]

## Detail

The term reframes a shift in where the difficulty of building AI systems actually lives. "Prompt engineering" frames the task as authoring one good instruction; context engineering frames it as managing the whole window — what goes in, in what structure, and when. Current agentic frameworks (LangChain, AutoGen, CrewAI) handle this through code-level abstractions: agents as objects, conversations as message arrays, orchestration as programmatic control flow, which suits dynamic multi-agent collaboration and complex branching [prov:src-2026-06-17-interpretable-context-methodology#p3|direct|2026-06-17] [epistemic:: sourced]. But the same end — the right context reaching the right step — can be reached structurally rather than programmatically, which is the bridge from context engineering to [[interpretable-context-methodology|Interpretable Context Methodology]] and to filesystem-native patterns generally.

The empirical backbone is the **"lost in the middle"** result: retrieval and reasoning quality fall when the relevant span sits in the middle of a long context, and adding irrelevant material actively hurts. That finding splits the field's responses into two camps — *compress* what is loaded (Lance Martin's "compress," the LLMLingua line of work) versus *select* less to begin with (load only what the step needs). Much of the practical art is choosing prevention over compression: avoid loading irrelevant context rather than shrinking it after the fact [prov:src-2026-06-17-interpretable-context-methodology#p4|direct|2026-06-17] [epistemic:: sourced].

This concept is the shared root of several patterns already in this wiki. [[progressive-disclosure|Progressive Disclosure]] is context engineering as a loading discipline — keep the always-resident layer tiny, defer detail to on-demand reads. [[subagents|Subagents]] are context engineering across agents — pay a large context cost in a disposable window and let only a compressed summary cross back. Interpretable Context Methodology is context engineering as filesystem structure — the same model produces different behavior at each stage purely because the folder hierarchy changes what context it receives. Within [[claude-code|Claude Code]] and frameworks like [[gsd|GSD (Get-Shit-Done)]], the recurring move is the same: treat the context window as a scarce public good and engineer what occupies it.

A second, retrieval-centric reading comes from practice. Where the ICM framing treats context engineering as *structuring* what has already been selected, Leonie Monigatti's AI Engineer talk emphasizes the *selection* itself: the under-credited step is the search that decides which of many context sources contributes to the window, and that step is increasingly agentic — the agent chooses which tool to call, with what parameters, and whether to search again. On this reading context engineering is "about 80%" agentic search, and much of its practical difficulty is search-tool design (tool descriptions, parameter complexity, and combining specialized and general-purpose tools) rather than prompt or layout design [prov:src-2026-07-03-agentic-search-context-engineering#t00:01:39-00:04:15|direct|2026-07-03] [epistemic:: tentative]. The two readings are complementary: agentic search is how the right context is *found*, and the compress/isolate/structure strategies are how it is *arranged* once found.

**Epistemic note.** This page now draws on two sources: the ICM paper's §2.2 literature framing (so the attributions to Karpathy, Martin, and Willison are as that paper characterizes them) and Monigatti's practitioner talk (a primary source whose proper nouns and figures carry claim-level `tentative` hedges on the speech-to-text failure surface). It is graded `mixed` and remains a natural candidate for enrichment from primary sources (the Karpathy post, the LangChain and Simon Willison essays, and the Liu et al. paper) on future ingests.

## Related Pages

- [[agentic-search|Agentic Search]] — the retrieval mechanism a practitioner framing calls ~80% of context engineering.
- [[interpretable-context-methodology|Interpretable Context Methodology]] — context engineering realized as filesystem structure.
- [[progressive-disclosure|Progressive Disclosure]] — context engineering as a tiered loading discipline.
- [[subagents|Subagents]] — context engineering applied across isolated agent contexts.
- [[claude-code|Claude Code]] — the environment where these context-engineering patterns are exercised.
- [[gsd|GSD (Get-Shit-Done)]] — an orchestrator built around externalizing agent context into files.

## Sources

- [[src-2026-06-17-interpretable-context-methodology|Interpretable Context Methodology: Folder Structure as Agent Architecture]] — Van Clief & McDermott, arXiv:2603.16021v2 [cs.AI], March 2026 (§2.2 Context Engineering and Agentic AI)
- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer conference talk, 2026-05-08 (YouTube transcript)
