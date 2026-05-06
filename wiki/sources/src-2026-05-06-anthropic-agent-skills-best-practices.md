---
id: src-2026-05-06-anthropic-agent-skills-best-practices
title: "Anthropic Agent Skills Best Practices"
type: source
status: active
summary: "Anthropic's authoring guide for Agent Skills: keep SKILL.md under 500 lines, write descriptions in third person with what+when, structure references one level deep, match degrees of freedom (high/medium/low) to task fragility, build evals before docs, and iterate using one Claude to write Skills used by another."
created_at: 2026-05-06
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
  - agent-skills
  - anthropic-docs
  - authoring-guide
  - prompt-engineering
  - progressive-disclosure
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Agent Skills Best Practices Doc
  - Skill Authoring Best Practices
  - platform.claude.com Agent Skills best practices
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-06-anthropic-agent-skills-best-practices.md
url: "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices"
content_hash: "sha256:9399ea95fc40fb7b0416269170ea774bdda5883bb5fd1c9688984ea184b578a9"
ingested_at: 2026-05-06
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:9399ea95fc40fb7b0416269170ea774bdda5883bb5fd1c9688984ea184b578a9"
compiled_targets:
  - agent-skills
  - progressive-disclosure
  - anthropic
---

## TL;DR

Authoring guidance for SKILL.md files. Default assumption: Claude is already smart, so cut anything Claude already knows. Keep the SKILL.md body under 500 lines and split into separate files when approaching that limit. Write descriptions in third person with both what the Skill does and when to use it. Match "degrees of freedom" to task fragility — high freedom (text instructions) for context-dependent decisions, low freedom (specific scripts, fixed flags) for fragile operations. Reference files one level deep from SKILL.md so Claude reads complete files; nest deeper and Claude may use `head -100` previews and miss content. Build at least three evaluations BEFORE writing extensive documentation. Develop iteratively: use one Claude instance ("Claude A") to author Skills used by another instance ("Claude B"); observe Claude B's behavior and feed gaps back to Claude A.

## Key Takeaways

- Keep SKILL.md body under 500 lines for optimal performance; split into separate files via progressive disclosure patterns when the limit approaches [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]
- Always write the `description` field in third person — the description is injected into the system prompt and inconsistent point-of-view causes discovery problems; "Processes Excel files and generates reports" is good, "I can help you process Excel files" is wrong [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06] [epistemic:: sourced]
- Match degrees of freedom to task: high freedom (text-based instructions) when multiple approaches are valid; medium freedom (pseudocode + parameterized scripts) when a preferred pattern exists; low freedom (specific scripts, few/no parameters) when operations are fragile and consistency is critical [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:set-appropriate-degrees-of-freedom|direct|2026-05-06] [epistemic:: sourced]
- The "narrow bridge vs open field" analogy: provide specific guardrails on the bridge, give general direction in the field — concrete heuristic for picking degrees of freedom [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:set-appropriate-degrees-of-freedom|direct|2026-05-06] [epistemic:: sourced]
- Keep references one level deep from SKILL.md; deeper nesting causes Claude to use `head -100` previews and miss content past the read window [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:avoid-deeply-nested-references|direct|2026-05-06] [epistemic:: sourced]
- For reference files longer than 100 lines, include a table of contents at the top so Claude sees the full scope even when previewing partially [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:structure-longer-reference-files-with-table-of-contents|direct|2026-05-06] [epistemic:: sourced]
- Build at least three evaluations BEFORE writing extensive documentation; baseline Claude's performance without the Skill, then iterate against the eval set [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:build-evaluations-first|direct|2026-05-06] [epistemic:: sourced]
- Use the Claude-A/Claude-B pattern: one Claude instance helps design and refine the Skill, another fresh instance tests it on real tasks; bring observations from B back to A for revisions [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:develop-skills-iteratively-with-claude|direct|2026-05-06] [epistemic:: sourced]
- Three progressive-disclosure patterns: Pattern 1 high-level guide with references (SKILL.md links to FORMS.md, REFERENCE.md, EXAMPLES.md); Pattern 2 domain-specific organization (per-domain reference files like `reference/finance.md`, `reference/sales.md`); Pattern 3 conditional details (basic content inline, advanced via links) [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]
- Use forward-slash paths everywhere — `scripts/helper.py`, never `scripts\helper.py` — because Unix paths work cross-platform but Windows paths fail on Unix [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:avoid-windows-style-paths|direct|2026-05-06] [epistemic:: sourced]
- Use the gerund form for Skill names when possible: `processing-pdfs`, `analyzing-spreadsheets`, `managing-databases`; avoid vague names like `helper`, `utils`, `tools` [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:naming-conventions|direct|2026-05-06] [epistemic:: sourced]
- Workflows for complex tasks should include a copyable checklist that Claude can paste into its response and check off — both research-synthesis (no code) and PDF-form-filling (with code) examples are documented [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:use-workflows-for-complex-tasks|direct|2026-05-06] [epistemic:: sourced]
- Implement feedback loops: run validator → fix errors → repeat; validators can be deterministic scripts (validate.py) or human-readable rubrics (STYLE_GUIDE.md the Skill consults) [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:implement-feedback-loops|direct|2026-05-06] [epistemic:: sourced]
- For Skills with executable code: solve errors in scripts, don't punt to Claude; document magic numbers ("voodoo constants") with reasons; prefer pre-made utility scripts over having Claude regenerate equivalent code on the fly [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:advanced-skills-with-executable-code|direct|2026-05-06] [epistemic:: sourced]
- The plan-validate-execute pattern (analyze → create plan file → validate plan → execute → verify) catches errors early on batch operations, destructive changes, and high-stakes operations [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:create-verifiable-intermediate-outputs|direct|2026-05-06] [epistemic:: sourced]
- MCP tool references in SKILL.md must use fully qualified `ServerName:tool_name` form (e.g., `BigQuery:bigquery_schema`) to avoid "tool not found" errors when multiple MCP servers are available [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:mcp-tool-references|direct|2026-05-06] [epistemic:: sourced]
- Avoid time-sensitive content like "Before August 2025, use the old API" because it goes stale; instead, document the current method and put deprecated material in a collapsed "Old patterns" section [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:avoid-time-sensitive-information|direct|2026-05-06] [epistemic:: sourced]
- Test Skills with Haiku, Sonnet, and Opus — what works for Opus may need more detail for Haiku; effectiveness depends on the underlying model [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:test-with-all-models-you-plan-to-use|direct|2026-05-06] [epistemic:: sourced]

## Extracted Claims

- "The context window is a public good. Your Skill shares the context window with everything else Claude needs to know, including: The system prompt; Conversation history; Other Skills' metadata; Your actual request." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:concise-is-key|direct|2026-05-06]
- "Default assumption: Claude is already very smart. Only add context Claude doesn't already have." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:concise-is-key|direct|2026-05-06]
- "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06]
- "Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06]
- "Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:token-budgets|direct|2026-05-06]
- "Keep references one level deep from SKILL.md. All reference files should link directly from SKILL.md to ensure Claude reads complete files when needed." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:avoid-deeply-nested-references|direct|2026-05-06]
- "Create evaluations BEFORE writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined ones." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:build-evaluations-first|direct|2026-05-06]
- "Work with one instance of Claude ('Claude A') to create a Skill that is used by other instances ('Claude B'). Claude A helps you design and refine instructions, while Claude B tests them in real tasks." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:develop-skills-iteratively-with-claude|direct|2026-05-06]
- "Narrow bridge with cliffs on both sides: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). ... Open field with no hazards: Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom)." [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:set-appropriate-degrees-of-freedom|direct|2026-05-06]

## Notes

This source is the canonical authoring guide for [[Agent Skills]]. Compiled into [[Agent Skills]], [[Progressive Disclosure]], and the entity pages [[Anthropic]] and [[Claude Code]].

The doc echoes themes already present in the wiki: the "Claude is already smart, cut what it knows" principle aligns with [[Comprehension Debt]] (don't pad with redundant context); the Claude-A-writes-for-Claude-B iteration loop is structurally similar to the [[Documented Contract]] pattern from DDD where one party writes a contract that another consumes; "build evals before docs" is functionally an evaluation-driven development pattern.

The doc explicitly distinguishes between **executing** and **reading** scripts: "Run analyze_form.py" (execute, doesn't load source into context) vs "See analyze_form.py for the algorithm" (read, loads source). This dual usage pattern is unique to the Skills filesystem-and-bash architecture.

## Source Metadata

- **Source type:** article (Anthropic platform documentation, MDX-rendered as markdown)
- **Authors:** Anthropic (platform documentation team)
- **Published:** rolling — captured 2026-05-06; documents practices for the Skills feature launched October 2025 per the `skills-2025-10-02` beta
- **Path:** `sources/2026/2026-05/2026-05-06-anthropic-agent-skills-best-practices.md`
- **URL:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
