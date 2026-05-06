---
id: progressive-disclosure
title: Progressive Disclosure
type: concept
status: active
summary: "Three-level loading pattern at the heart of Anthropic Agent Skills. L1 metadata (~100 tokens/Skill) is always preloaded into the system prompt; L2 SKILL.md body (under 5k tokens) is read via bash when the Skill is triggered; L3 bundled files and scripts are accessed only as needed, with script source code never entering context."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-best-practices
  - src-2026-05-06-anthropic-claude-cookbook-skills-introduction
  - src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
epistemic_status: sourced
tags:
  - progressive-disclosure
  - context-engineering
  - agent-skills
  - prompt-engineering
  - filesystem-architecture
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Three-Level Loading
  - Three-Level Skill Loading
  - Skills Progressive Disclosure
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Progressive disclosure is the loading discipline Anthropic uses to let many Agent Skills coexist without paying full token cost upfront. Information loads in three levels: Level 1 metadata (the YAML `name` + `description`, always preloaded into the system prompt at ~100 tokens per Skill); Level 2 instructions (the SKILL.md body, read via bash when the Skill is triggered, kept under ~5k tokens); Level 3 resources (additional `.md` references, datasets, scripts — accessed only when explicitly referenced, with script source code executed via bash so it never enters context). The pattern lets a Skill bundle dozens of reference files, comprehensive API docs, or large datasets without context penalty until something is actually read.

## Key Facts

- Progressive disclosure has three loading levels: L1 metadata always loaded at startup; L2 instructions loaded when triggered; L3 resources loaded as needed [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Level 1 metadata is the YAML frontmatter `name` and `description` from each Skill's SKILL.md, included in the system prompt at startup; budget approximately 100 tokens per Skill [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Level 2 is the SKILL.md body — read via bash when a request matches the Skill's description; should be kept under 5k tokens (and Anthropic recommends under 500 lines for optimal performance) [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:token-budgets|direct|2026-05-06] [epistemic:: sourced]
- Level 3+ resources are bundled files (additional markdown, scripts, data) accessed only when referenced; budget effectively unlimited because content does not consume context until actually read [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Bundled scripts execute via bash with only stdout/stderr consuming tokens — script source code never enters the context window — making scripts strictly more efficient than having Claude regenerate equivalent code on the fly [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:the-skills-architecture|direct|2026-05-06] [epistemic:: sourced]
- Anthropic recommends keeping reference files one level deep from SKILL.md; deeper nesting causes Claude to use `head -100` previews and miss content past the read window [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:avoid-deeply-nested-references|direct|2026-05-06] [epistemic:: sourced]
- For reference files longer than 100 lines, including a table of contents at the top ensures Claude sees the full scope of available information even when previewing partially [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:structure-longer-reference-files-with-table-of-contents|direct|2026-05-06] [epistemic:: sourced]
- Three documented progressive-disclosure patterns: high-level guide with references (SKILL.md + FORMS.md/REFERENCE.md/EXAMPLES.md), domain-specific organization (per-domain reference files), and conditional details (basic content inline, advanced via links) [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]
- Level 2 loads ALL `.md` files in the Skill's top-level directory — not just `SKILL.md` and `REFERENCE.md` — so multi-file documentation (`REFERENCE.md`, `EXAMPLES.md`, `TROUBLESHOOTING.md`, `CHANGELOG.md`, etc.) is a first-class organization pattern; the ~5k token budget recommendation applies to the *sum* of top-level markdown, not just SKILL.md [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:additional-documentation-files|direct|2026-05-06] [epistemic:: sourced]
- The "98% savings" framing for Skills tokens applies to the *initial context only* — Level 1 metadata is essentially free; once Level 2 fires for a given request, the full ~5k tokens of instructions load and are paid for that request [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-usage-optimization|direct|2026-05-06] [epistemic:: sourced]
- Container reuse via `container.id` (passing the id from a previous response into subsequent requests) is the API-level token-optimization pattern that lets Skills stay loaded across calls without re-paying L2 [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-optimization-tips|direct|2026-05-06] [epistemic:: sourced]

## Detail

The pattern's load-bearing claim is that the context window is a public good. A Skill's tokens compete with the system prompt, conversation history, other Skills' metadata, and the user's actual request, so the goal is to defer loading anything that isn't directly needed. Level 1 commits Claude to ~100 tokens per Skill *forever* in the system prompt — that's the price of even knowing the Skill exists. Levels 2 and 3 only pay tokens when relevant.

This shapes authoring choices in concrete ways. The `description` field carries the entire load of skill discovery: Claude uses it to pick which Skill (out of potentially 100+) to load from a request, so it must include both *what* the Skill does and *when* to use it, written in third person, in 1024 characters or fewer [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06] [epistemic:: sourced]. SKILL.md should not re-explain things Claude already knows ("PDFs are a common file format... pdfplumber is a library...") — that wastes tokens once the file is loaded. And references to additional files should be one level deep so that when Claude does follow a reference, it reads the *complete* file rather than a `head -100` preview that may miss critical content.

Script execution gets a special treatment: when an instruction file references a utility script, Claude has two distinct usage modes — **execute** (`Run analyze_form.py to extract fields`, where only output enters context) or **read as reference** (`See analyze_form.py for the extraction algorithm`, where source enters context). The authoring guide recommends being explicit about which mode is intended; "for most utility scripts, execution is preferred because it's more reliable and efficient" [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:provide-utility-scripts|direct|2026-05-06] [epistemic:: sourced]

Three concrete patterns operationalize the discipline at SKILL.md scale [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]:

- **Pattern 1 — high-level guide with references**: SKILL.md gives a quick start, then links to FORMS.md, REFERENCE.md, EXAMPLES.md for advanced material. Claude reads each only when a task needs it.
- **Pattern 2 — domain-specific organization**: a Skill spanning multiple domains keeps SKILL.md as a navigation hub (e.g., "Finance: see reference/finance.md; Sales: see reference/sales.md") so that a query about sales metrics doesn't pull in finance schemas.
- **Pattern 3 — conditional details**: basic content is inlined in SKILL.md; advanced features (tracked changes, OOXML internals, etc.) live in dedicated files Claude only reads when the user's request triggers them.

The same disciplined load pattern shows up in [[Agent Skills]] usage at the [[Claude API]] surface — listing Skills via `GET /v1/skills?source=anthropic` returns only metadata, not bodies — and in this wiki's own navigation rule: scan `## TL;DR` and `## Key Facts` first, drill into `## Detail` only when the shallow material is insufficient.

### Level 2 includes all top-level markdown, not just SKILL.md

The cookbook's custom-Skills documentation makes a refinement that's easy to miss in the platform-doc framing: Level 2 loads ALL `.md` files in the Skill's top-level directory, not just `SKILL.md` (and not even just `SKILL.md` + `REFERENCE.md` as one might infer from the example bundles). A Skill organized as [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:additional-documentation-files|direct|2026-05-06] [epistemic:: sourced]:

```
skill_name/
├── SKILL.md           # required entry point
├── REFERENCE.md       # optional: API reference
├── EXAMPLES.md        # optional: usage examples
├── TROUBLESHOOTING.md # optional: common issues
└── CHANGELOG.md       # optional: version history
```

… loads ALL of those `.md` files at L2. So the ~5k token budget recommendation effectively applies to the *sum* of top-level markdown, not just the SKILL.md body in isolation. Subdirectory markdown (`scripts/foo.md`, `resources/notes.md`) is L3 — pulled in only when explicitly referenced.

### "98% savings" disambiguation

The cookbook's token math frames Skills as offering "98% savings" vs manual prompt-engineered instructions. This is true *for the initial context* — Level 1 metadata is ~100 tokens per Skill rather than the ~5,000-10,000 tokens of an inline instruction prompt. But once Level 2 fires for a given request, the full ~5k tokens load and are paid for that request [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-usage-optimization|direct|2026-05-06] [epistemic:: sourced]. The value of progressive disclosure is therefore in *amortization across many requests*: 100 Skills installed cost ~10k tokens of metadata permanently, but only the few that actually fire on a given request pay the L2 cost on that request.

The API-level lever for amortizing further is container reuse — pass `container.id` from a previous response into subsequent requests so Skills stay loaded across calls in the same container, avoiding re-paying L2 for already-resident Skills [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-optimization-tips|direct|2026-05-06] [epistemic:: sourced]

## Related Pages

- [[Agent Skills]]
- [[Anthropic]]
- [[Claude API]]
- [[Claude Code]]

## Sources

- [[Anthropic Agent Skills Overview]] — Anthropic platform docs, 2026-05-06
- [[Anthropic Agent Skills Best Practices]] — Anthropic platform docs, 2026-05-06
- [[Introduction to Claude Skills (claude-cookbooks notebook 01)]] — Anthropic claude-cookbooks, 2026-05-06
- [[Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks, 2026-05-06
