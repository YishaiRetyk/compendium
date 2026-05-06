---
id: anthropic
title: Anthropic
type: entity
status: active
summary: "AI safety company that builds Claude (Opus, Sonnet, Haiku model family) and ships three product surfaces — the Claude API, Claude Code CLI, and Claude.ai — plus a pre-built and Custom Agent Skills ecosystem with an open-source skills repository."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-quickstart
  - src-2026-05-06-anthropic-agent-skills-best-practices
epistemic_status: sourced
tags:
  - ai-safety
  - llm-vendor
  - claude
  - agent-skills
  - anthropic
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Anthropic PBC
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Anthropic is the AI safety company that builds Claude. It ships three product surfaces — the Claude API, Claude Code, and Claude.ai — and an Agent Skills ecosystem of filesystem-based capability packages that work across all three. Pre-built Anthropic-managed Skills (`pptx`, `xlsx`, `docx`, `pdf`) are available on the API and Claude.ai; custom Skills can be uploaded via the API, the Claude.ai settings panel, or dropped on disk for Claude Code. Anthropic also publishes an open-source skills repository.

## Key Facts

- Anthropic ships three Claude product surfaces — the Claude API, Claude Code, and Claude.ai — and Agent Skills work across all three with surface-specific availability and sharing rules [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:where-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Anthropic publishes four pre-built ("Anthropic-managed") Agent Skills for document tasks: `pptx` (PowerPoint), `xlsx` (Excel), `docx` (Word), and `pdf` (PDF) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:available-skills|direct|2026-05-06] [epistemic:: sourced]
- Anthropic publishes an open-source skills repository at github.com/anthropics/skills, which includes a Claude API skill providing up-to-date API reference material and SDK documentation for 8 programming languages, bundled with Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:open-source-skills|direct|2026-05-06] [epistemic:: sourced]
- The reserved Skill name words `anthropic` and `claude` cannot appear in custom Skill `name` fields — Anthropic protects these identifiers in the Skill namespace [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:skill-structure|direct|2026-05-06] [epistemic:: sourced]
- Agent Skills are NOT covered by Anthropic's Zero Data Retention arrangements; Skill definitions and execution data are retained per Anthropic's standard data retention policy [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:data-retention|direct|2026-05-06] [epistemic:: sourced]
- Anthropic's authoring guidance for Skills explicitly recommends testing across the Claude Haiku, Sonnet, and Opus model tiers because Skill effectiveness depends on the underlying model [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:test-with-all-models-you-plan-to-use|direct|2026-05-06] [epistemic:: sourced]

## Detail

Anthropic's Skills strategy is filesystem-first and progressive-disclosure-driven (see [[Progressive Disclosure]]). A Skill is a directory containing a `SKILL.md` instructions file plus optional bundled scripts and reference materials. Claude pre-loads only Skill metadata (the `name` and `description` from each SKILL.md's YAML frontmatter) into the system prompt at startup, then reads the body and bundled files on demand via bash when a request matches. This makes installing many Skills cheap.

Anthropic ships Skills across three surfaces with different rules:

- **[[Claude API]]** supports both pre-built Anthropic-managed Skills and custom uploaded Skills via the `/v1/skills` endpoints. Skills run inside the code-execution container with NO network access and no runtime package installation — only pre-configured dependencies. Custom Skills are workspace-wide.
- **[[Claude Code]]** supports custom Skills only (no pre-built). Skills are filesystem-based at `~/.claude/skills/` (personal) or `.claude/skills/` (project). Skills here have the same network access as any other program on the user's machine. They can be distributed via Claude Code Plugins.
- **Claude.ai** supports both pre-built Skills (used automatically when creating documents) and custom Skills uploaded as zip files through Settings → Features on Pro, Max, Team, and Enterprise plans. Custom Skills are individual to each user — Claude.ai does not currently support centralized admin management or org-wide distribution [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:sharing-scope|direct|2026-05-06] [epistemic:: sourced]

Skills are deliberately not synced across surfaces: a Skill uploaded to Claude.ai must be separately uploaded to the API; Skills uploaded via the API are not visible on Claude.ai; Claude Code Skills are filesystem-only and separate from both [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:cross-surface-availability|direct|2026-05-06] [epistemic:: sourced]

Anthropic's authoring guidance treats Skills like onboarding guides for new team members: organize by domain, keep references one level deep so Claude reads complete files, and ship pre-made utility scripts rather than asking Claude to regenerate equivalent code on the fly [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:provide-utility-scripts|direct|2026-05-06] [epistemic:: sourced]. The recommended development loop uses one Claude instance ("Claude A") to author Skills used by another instance ("Claude B"), with observations from B feeding back to A [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:develop-skills-iteratively-with-claude|direct|2026-05-06] [epistemic:: sourced]

Anthropic's existing Claude Code plugin marketplace [[Anthropic Financial Services]] is a concrete production deployment of Skills: it ships populated SKILL.md prompts (DCF, comps, 3-statement, LBO, merger model, initiating coverage, earnings analysis, model update, tear-sheet) alongside Python validators and Excel templates — implementing the bundle-everything-the-skill-needs pattern from the authoring guide.

## Related Pages

- [[Agent Skills]]
- [[Progressive Disclosure]]
- [[Claude Code]]
- [[Claude API]]
- [[Anthropic Financial Services]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview]]: "Anthropic Agent Skills Overview" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-quickstart]]: "Anthropic Agent Skills Quickstart" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-best-practices]]: "Anthropic Agent Skills Best Practices" (2026-05-06)
