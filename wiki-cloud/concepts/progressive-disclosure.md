---
id: progressive-disclosure
title: Progressive Disclosure
type: concept
status: active
summary: "Three-level loading pattern at the heart of Anthropic Agent Skills. L1 metadata
  (~100 tokens/Skill) is always preloaded into the system prompt; L2 SKILL.md body
  (under 5k tokens) is read via bash when the Skill is triggered; L3 bundled files
  and scripts are accessed only as needed, with script source code never entering
  context."
created_at: 2026-05-06
updated_at: 2026-07-03
sources:
- src-2026-05-06-anthropic-agent-skills-overview
- src-2026-05-06-anthropic-agent-skills-best-practices
- src-2026-05-06-anthropic-claude-cookbook-skills-introduction
- src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
- src-2026-05-06-ralph-playbook
- src-2026-04-16-claude-code-frameworks-report
- src-2026-06-17-interpretable-context-methodology
- src-2026-07-03-agentic-search-context-engineering
- src-2026-07-03-building-great-agent-skills
epistemic_status: mixed
tags:
- progressive-disclosure
- context-engineering
- agent-skills
- prompt-engineering
- filesystem-architecture
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Progressive Disclosure"
- "Three-Level Loading"
- "Three-Level Skill Loading"
- "Skills Progressive Disclosure"
- "progressive-disclosure"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Progressive disclosure is the loading discipline Anthropic uses to let many Agent Skills coexist without paying full token cost upfront. Information loads in three levels: Level 1 metadata (the YAML `name` + `description`, always preloaded into the system prompt at ~100 tokens per Skill); Level 2 instructions (the SKILL.md body, read via bash when the Skill is triggered, kept under ~5k tokens); Level 3 resources (additional `.md` references, datasets, scripts — accessed only when explicitly referenced, with script source code executed via bash so it never enters context). The pattern lets a Skill bundle dozens of reference files, comprehensive API docs, or large datasets without context penalty until something is actually read. The same discipline is a general context-engineering principle, not a Skills-only mechanism: the [[src-2026-05-06-ralph-playbook|The Ralph Playbook]] applies it to autonomous coding loops by keeping its always-loaded `AGENTS.md` minimal and deferring status/detail to a separate on-demand file. More broadly, progressive disclosure — originally a Jakob Nielsen UX pattern (1995) — has become the architectural backbone of Claude Code itself, spanning a full load hierarchy from always-loaded CLAUDE.md down to forked [[subagents|subagent]] contexts, and is the unifying principle behind all three [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]]. [[interpretable-context-methodology|Interpretable Context Methodology]] pushes the same discipline down to folder granularity — each numbered workflow stage loads only the context layers it needs — making it a structural instance of [[context-engineering|Context Engineering]] rather than a within-context loading trick. A practitioner account from [[agentic-search|Agentic Search]] adds the mirror-image step the Skills docs leave implicit: long-running agents must not only load skills on demand but *offload* them as the context moves on, applying the same load-then-evict discipline to compaction.

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
- The same disclosure discipline appears outside Agent Skills: the Ralph Playbook keeps its `AGENTS.md` loop file concise (~60 lines, operational-only) and pushes mutable status/progress into a separate `IMPLEMENTATION_PLAN.md`, so the always-loaded file stays small while detail is deferred to a file read only when needed — the same L1-stays-small / detail-loads-on-demand split that governs Skills' three levels [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-06-01] [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-06-01] [epistemic:: inferred]
- Progressive disclosure originated as a Jakob Nielsen UX pattern (1995); Anthropic elevated it to the architectural backbone of Claude Code — for humans it improves learnability, for LLMs it is an architectural necessity given context rot, attention dilution, and cache economics [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: sourced]
- The Claude-Code-wide load hierarchy runs top to bottom: enterprise policy → `~/.claude/CLAUDE.md` (always) → `./CLAUDE.md` (always) → subdir CLAUDE.md (lazy on file access) → skill metadata (always, ~100 tokens each) → skill body (on trigger, <5K) → bundled references/scripts (on demand, unbounded) → subagent contexts (forked, compressed on return) [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: sourced]
- Key anti-pattern — over-reliance on auto-activation: Vercel found skills were never invoked in 56% of test cases, and explicit "IMPORTANT: read X" pointers outperformed pure auto-discovery; other anti-patterns are bloated CLAUDE.md, monolithic mega-prompts, eager `Read all of docs/`, and accepting context rot instead of externalizing state [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: tentative]
- The discipline generalizes beyond Claude Code: Interpretable Context Methodology applies it at folder granularity, where each numbered workflow stage loads only the context layers it needs, keeping per-stage context at ~2,000–8,000 tokens versus 30,000–50,000 for a monolithic prompt that loads everything. [prov:src-2026-06-17-interpretable-context-methodology#p7|direct|2026-06-17] [epistemic:: sourced]
- An independent instance from Elastic's agentic-search practice: an agent that must write an ES|QL query loads a skill whose name and description sit in the system prompt while its body (the ES|QL syntax rules) loads into context only when the query tool is about to be used — progressive disclosure supplying just-in-time documentation to fix tool-parameter generation; Elastic also *offloads* a skill once the context moves past it, extending the same load-then-evict discipline to compaction. [prov:src-2026-07-03-agentic-search-context-engineering#t00:28:17-00:30:24|direct|2026-07-03] [prov:src-2026-07-03-agentic-search-context-engineering#t01:00:26-01:02:25|direct|2026-07-03] [epistemic:: tentative]
- The authoring-side restatement of the same discipline is [[matt-pocock|Matt Pocock]]'s **context pointer**: a skill's description is a pointer sitting in the agent's context that names a file (its `SKILL.md`) the agent can read for more; the advice "keep `SKILL.md` as small as possible" and "hide branch-specific reference behind context pointers to bundled files" is the three-level model expressed as heuristics an author applies by hand [prov:src-2026-07-03-building-great-agent-skills#t00:04:26-00:11:39|direct|2026-07-03] [epistemic:: tentative]

## Detail

The pattern's load-bearing claim is that the context window is a public good. A Skill's tokens compete with the system prompt, conversation history, other Skills' metadata, and the user's actual request, so the goal is to defer loading anything that isn't directly needed. Level 1 commits Claude to ~100 tokens per Skill *forever* in the system prompt — that's the price of even knowing the Skill exists. Levels 2 and 3 only pay tokens when relevant.

This shapes authoring choices in concrete ways. The `description` field carries the entire load of skill discovery: Claude uses it to pick which Skill (out of potentially 100+) to load from a request, so it must include both *what* the Skill does and *when* to use it, written in third person, in 1024 characters or fewer [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06] [epistemic:: sourced]. SKILL.md should not re-explain things Claude already knows ("PDFs are a common file format... pdfplumber is a library...") — that wastes tokens once the file is loaded. And references to additional files should be one level deep so that when Claude does follow a reference, it reads the *complete* file rather than a `head -100` preview that may miss critical content.

Script execution gets a special treatment: when an instruction file references a utility script, Claude has two distinct usage modes — **execute** (`Run analyze_form.py to extract fields`, where only output enters context) or **read as reference** (`See analyze_form.py for the extraction algorithm`, where source enters context). The authoring guide recommends being explicit about which mode is intended; "for most utility scripts, execution is preferred because it's more reliable and efficient" [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:provide-utility-scripts|direct|2026-05-06] [epistemic:: sourced]

Three concrete patterns operationalize the discipline at SKILL.md scale [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]:

- **Pattern 1 — high-level guide with references**: SKILL.md gives a quick start, then links to FORMS.md, REFERENCE.md, EXAMPLES.md for advanced material. Claude reads each only when a task needs it.
- **Pattern 2 — domain-specific organization**: a Skill spanning multiple domains keeps SKILL.md as a navigation hub (e.g., "Finance: see reference/finance.md; Sales: see reference/sales.md") so that a query about sales metrics doesn't pull in finance schemas.
- **Pattern 3 — conditional details**: basic content is inlined in SKILL.md; advanced features (tracked changes, OOXML internals, etc.) live in dedicated files Claude only reads when the user's request triggers them.

The same disciplined load pattern shows up in [[agent-skills|Agent Skills]] usage at the [[claude-api|Claude API]] surface — listing Skills via `GET /v1/skills?source=anthropic` returns only metadata, not bodies — and in this wiki's own navigation rule: scan `## TL;DR` and `## Key Facts` first, drill into `## Detail` only when the shallow material is insufficient.

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

### Progressive disclosure as a shared design principle (Agent Skills and the Ralph loop)

Progressive disclosure is not unique to Agent Skills; it is a general context-engineering discipline, and the Ralph Playbook is an independent instance of the same pattern applied to autonomous coding loops. Two structural choices in Ralph map directly onto the Skills three-level model:

- **The always-loaded file is kept small, detail is deferred to on-demand files.** Ralph treats `AGENTS.md` as "the heart of the loop" — concise (~60 lines), operational only (how to build/run/validate), explicitly *not* a changelog or progress diary — while status, progress, and planning live in a separate `IMPLEMENTATION_PLAN.md` that is read only when an iteration needs it [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-06-01] [epistemic:: sourced]. This is the same separation Skills draw between Level 1 metadata (always in the system prompt, kept tiny) and Levels 2–3 (loaded only when triggered) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-06-01] [epistemic:: sourced]. In both systems the load-bearing rule is identical: bloating the always-resident layer pollutes every future unit of work, so detail must be pushed down to a layer that is paid for only on demand.

- **Deterministic, budgeted up-front context loading.** Ralph's "context is everything" principle steers each iteration by loading a bounded, deterministic slice up front — the playbook's heuristic reserves roughly the "first ~5,000 tokens for specs" and targets a 40–60% context-utilization "smart zone" rather than filling the window [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-06-01] [epistemic:: sourced]. That ~5k budget for the steering layer is strikingly close to the Skills guidance that a triggered Level 2 body stay under ~5k tokens — both treat the context window as a public good and cap the eagerly-loaded layer at a similar order of magnitude.

The connection is interpretive rather than a claim either source makes about the other: neither the Ralph playbook nor the Agent Skills docs reference each other [epistemic:: inferred]. What they share is the underlying principle — *defer loading anything not immediately needed, and keep the always-resident layer minimal* — which is why this wiki files both under progressive disclosure rather than treating them as unrelated token-optimization tricks.

### An independent instance: agent skills for search-tool parameters, with an explicit eviction step (Elastic)

A third independent instance appears in [[leonie-monigatti|Leonie Monigatti]]'s agentic-search talk, where progressive disclosure solves a *tool-parameter* problem rather than a documentation-volume one. When an agent must write an entire ES|QL query and keeps getting the syntax wrong, the fix is an agent skill whose name and description live in the system prompt while its body — the ES|QL syntax rules, including the correct wildcard — loads into the context window only when the query tool is about to be used [prov:src-2026-07-03-agentic-search-context-engineering#t00:28:17-00:30:24|direct|2026-07-03] [epistemic:: tentative]. Monigatti's [[elastic|Elastic]] colleague Joe described the *eviction* half of the same discipline, which the Anthropic docs leave implicit: skills are exposed as names, descriptions, and a location in a file store, loaded when needed and offloaded as the context progresses, with the same load-then-evict logic applied to compaction and to re-fetching previous tool results from the file store [prov:src-2026-07-03-agentic-search-context-engineering#t01:00:26-01:02:25|direct|2026-07-03] [epistemic:: tentative]. This closes a loop the Skills documentation frames one-directionally: it specifies how a skill's levels *load*, whereas the Elastic account is explicit that a long-running agent must also *unload* resident skills to keep the window small — the same L1-stays-small / detail-on-demand principle, now with a deliberate eviction step.

### The authoring-side view: context pointers and a minimal SKILL.md

The Anthropic and Elastic accounts describe how progressive disclosure *behaves at runtime*. [[matt-pocock|Matt Pocock]]'s [[skill-checklist|Skill Checklist]] talk restates the same discipline as *authoring heuristics*, which is where the mechanism turns into day-to-day decisions. His unit is the **context pointer**: text resident in the agent's context that points to another file the agent may read for more context [prov:src-2026-07-03-building-great-agent-skills#t00:04:26-00:04:42|direct|2026-07-03] [epistemic:: tentative]. A skill's description is a context pointer to its `SKILL.md`; a bundled "external reference" file is a context pointer one level deeper. Two rules fall out:

- **Keep `SKILL.md` as small as possible.** Fewer words are cheaper to maintain and audit, and every word shaved is tokens shaved from the skill's per-request cost — the L1/L2 economics stated as a maintainer's discipline rather than a platform behavior [prov:src-2026-07-03-building-great-agent-skills#t00:08:52-00:09:33|direct|2026-07-03] [epistemic:: tentative].
- **Hide branch-specific reference behind context pointers.** Reference material used in only one of a skill's branches should move out of the main file into a bundled file behind a pointer, so a given run pays for only what it needs. His single-branch "2PRD" keeps its reference inline (every run uses it); his multi-branch "domain modeling" pushes its ADR and glossary templates behind pointers [prov:src-2026-07-03-building-great-agent-skills#t00:09:33-00:11:39|direct|2026-07-03] [epistemic:: tentative].

This is the same "defer loading anything not immediately needed, keep the always-resident layer minimal" principle that governs the three-level model — only now aimed at the human deciding what to inline versus what to leave behind a pointer.

### Progressive disclosure as the architectural backbone of Claude Code

Beyond Skills and the Ralph loop, the [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks report]] frames progressive disclosure as *the* architectural backbone of Claude Code as a whole, with a precise lineage and rationale. The pattern began as a Jakob Nielsen UX principle in 1995 (show only what's needed, reveal advanced options on demand); Anthropic adopted it not merely for human learnability but as an architectural necessity for LLMs, driven by three forces: context rot (quality degrades as the window fills), attention dilution (more loaded context means weaker focus on any part), and cache economics (stable prefixes are cheaper) [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: sourced].

Seen this way, the three-level Skills model is one slice of a longer load hierarchy that runs from enterprise policy and the always-loaded `~/.claude/CLAUDE.md` and `./CLAUDE.md`, through lazily-loaded subdirectory CLAUDE.md files, skill metadata (~100 tokens each, always) and skill bodies (<5K, on trigger), down to on-demand bundled references and, at the bottom, forked subagent contexts that are compressed on return. The same patterns recur at every level — lazy loading, just-in-time references, summary-first/detail-on-demand, index-then-fetch, script-as-tool (only stdout enters context), and subagent fan-out / compress-on-return [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: sourced].

The report is equally explicit about anti-patterns, the most consequential being over-reliance on auto-activation: Vercel reported that skills were never invoked in 56% of test cases, and that explicit `IMPORTANT: read X` pointers outperformed pure auto-discovery — a caution that the always-resident layer sometimes *should* name what to load rather than trusting the model to discover it [prov:src-2026-04-16-claude-code-frameworks-report#sec:progressive-disclosure|derived|2026-06-09] [epistemic:: tentative]. This same principle, applied across agents, is what makes subagent isolation work and is the shared backbone of all three Claude Code orchestration frameworks.

## Related Pages

- [[agent-skills|Agent Skills]]
- [[anthropic|Anthropic]]
- [[claude-api|Claude API]]
- [[claude-code|Claude Code]]
- [[subagents|Subagents]]
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]]
- [[context-engineering|Context Engineering]] — the broader discipline this loading pattern serves.
- [[interpretable-context-methodology|Interpretable Context Methodology]] — the same discipline applied at folder granularity.
- [[agentic-search|Agentic Search]] — an agent-skill instance of the pattern (load ES|QL docs on demand, offload when done).
- [[skill-checklist|Skill Checklist]] — restates the discipline as authoring heuristics (context pointers, minimal `SKILL.md`).

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview|Anthropic Agent Skills Overview]] — Anthropic platform docs, 2026-05-06
- [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] — Anthropic platform docs, 2026-05-06
- [[src-2026-05-06-anthropic-claude-cookbook-skills-introduction|Introduction to Claude Skills (claude-cookbooks notebook 01)]] — Anthropic claude-cookbooks, 2026-05-06
- [[src-2026-05-06-anthropic-claude-cookbook-skills-custom-development|Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks, 2026-05-06
- [[src-2026-05-06-ralph-playbook|The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr / Geoffrey Huntley, 2026-05-06
- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]] — comparative synthesis report, April 2026
- [[src-2026-06-17-interpretable-context-methodology|Interpretable Context Methodology: Folder Structure as Agent Architecture]] — Van Clief & McDermott, arXiv, March 2026
- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer conference talk, 2026-05-08 (YouTube transcript)
- [[src-2026-07-03-building-great-agent-skills|Building Great Agent Skills: The Missing Manual — Matt Pocock]] — AI Engineer talk, 2026-06-29 (YouTube transcript)
