---
id: src-2026-05-06-anthropic-agent-skills-overview
title: "Anthropic Agent Skills Overview"
type: source
status: active
summary: "Anthropic's platform documentation page introducing Agent Skills as filesystem-based
  directories of instructions and resources that Claude loads on demand via three-level
  progressive disclosure across the Claude API, Claude Code, and Claude.ai."
created_at: 2026-05-06
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
- agent-skills
- anthropic-docs
- progressive-disclosure
- claude-api
- claude-code
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Agent Skills Overview Doc"
- "platform.claude.com Agent Skills overview"
- "Anthropic Agent Skills Overview"
- "src-2026-05-06-anthropic-agent-skills-overview"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-06-anthropic-agent-skills-overview.md
url: "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview"
content_hash: "sha256:c11e87b812f7a846b6e4ef6736e1e73cdb7b4d3763f836016b863a82734350c0"
ingested_at: 2026-05-06
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:c11e87b812f7a846b6e4ef6736e1e73cdb7b4d3763f836016b863a82734350c0"
compiled_targets:
- agent-skills
- progressive-disclosure
- anthropic
- claude-code
- claude-api
---

## TL;DR

Agent Skills are filesystem-based directories that package instructions, optional code, and reference materials Claude can load on demand. Each Skill ships a `SKILL.md` file with YAML frontmatter (`name`, `description`); Claude pre-loads only the metadata at startup, reads the body when a request matches, and accesses bundled files (additional `.md` references, scripts, datasets) only as needed. This three-level progressive disclosure model lets organizations install many Skills without context penalty, and makes Skills work across the Claude API (pre-built + custom via the Skills API), Claude Code (custom only, filesystem-based at `~/.claude/skills/` or `.claude/skills/`), and Claude.ai (pre-built + uploaded zips on Pro/Max/Team/Enterprise).

## Key Takeaways

- A Skill is a directory containing a SKILL.md file with YAML frontmatter providing `name` (required, ≤64 chars, lowercase/hyphens, no XML, no reserved words `anthropic`/`claude`) and `description` (required, ≤1024 chars, no XML) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:skill-structure|direct|2026-05-06] [epistemic:: sourced]
- Progressive disclosure operates at three levels: Level 1 metadata is always loaded into the system prompt at startup (~100 tokens per Skill); Level 2 SKILL.md body is read via bash when the Skill is triggered (under 5k tokens); Level 3+ bundled resources are accessed only when referenced and never load script source code into context [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Skills run inside Claude's code-execution environment with filesystem access; Claude reads SKILL.md and additional files via bash, and bundled scripts execute via bash so only their stdout/stderr consumes tokens [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:the-skills-architecture|direct|2026-05-06] [epistemic:: sourced]
- Pre-built Anthropic-managed Skills available across Claude.ai and the API are `pptx` (PowerPoint), `xlsx` (Excel), `docx` (Word), and `pdf` (PDF); custom Skills are user/organization-supplied [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:available-skills|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills do NOT sync across surfaces: API uploads are not available on Claude.ai, Claude.ai uploads are not available via the API, and Claude Code Skills are filesystem-based and separate from both [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:cross-surface-availability|direct|2026-05-06] [epistemic:: sourced]
- API Skills require three beta headers: `code-execution-2025-08-25`, `skills-2025-10-02`, and `files-api-2025-04-14` [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-api|direct|2026-05-06] [epistemic:: sourced]
- Claude Code Skills are personal at `~/.claude/skills/` or project-based at `.claude/skills/` and can be distributed via Claude Code Plugins; Claude Code supports custom Skills only (no pre-built) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-code|direct|2026-05-06] [epistemic:: sourced]
- Agent Skills are not eligible for Zero Data Retention; data is retained per Anthropic's standard data retention policy [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:data-retention|direct|2026-05-06] [epistemic:: sourced]
- Runtime environment differs by surface: Claude API has no network access and no runtime package installation; Claude Code has full network access (with global package installation discouraged); Claude.ai network access varies by user/admin settings [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:runtime-environment-constraints|direct|2026-05-06] [epistemic:: sourced]
- Sharing scope differs: Claude.ai custom Skills are individual-user only (no centralized admin distribution); API Skills are workspace-wide; Claude Code Skills are personal or project-based and shareable via Plugins [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:sharing-scope|direct|2026-05-06] [epistemic:: sourced]
- Anthropic publishes an open-source Skill called Claude API in the public skills repository, providing up-to-date API reference material, SDK documentation, and best practices for 8 programming languages; bundled with Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:open-source-skills|direct|2026-05-06] [epistemic:: sourced]
- Security guidance: Skills should only come from trusted sources; malicious Skills can direct Claude to invoke tools or execute code outside the Skill's stated purpose, with risks including data exfiltration and unauthorized system access [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:security-considerations|direct|2026-05-06] [epistemic:: sourced]

## Extracted Claims

- "Skills run in a code execution environment where Claude has filesystem access, bash commands, and code execution capabilities." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:the-skills-architecture|direct|2026-05-06]
- "Claude loads this metadata at startup and includes it in the system prompt. This lightweight approach means you can install many Skills without context penalty; Claude only knows each Skill exists and when to use it." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:level-1-metadata|direct|2026-05-06]
- "When Claude runs validate_form.py, the script's code never loads into the context window. Only the script's output (like 'Validation passed' or specific error messages) consumes tokens." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:the-skills-architecture|direct|2026-05-06]
- "Skills uploaded to Claude.ai must be separately uploaded to the API ... Skills uploaded via the API are not available on Claude.ai ... Claude Code Skills are filesystem-based and separate from both Claude.ai and API." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:cross-surface-availability|direct|2026-05-06]
- "name: Maximum 64 characters; Must contain only lowercase letters, numbers, and hyphens; Cannot contain XML tags; Cannot contain reserved words: 'anthropic', 'claude'." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:skill-structure|direct|2026-05-06]
- "description: Must be non-empty; Maximum 1024 characters; Cannot contain XML tags." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:skill-structure|direct|2026-05-06]
- "Claude.ai does not currently support centralized admin management or org-wide distribution of custom Skills." [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:sharing-scope|direct|2026-05-06]

## Notes

This source defines the canonical model for Agent Skills and is the upstream reference for the [[agent-skills|Agent Skills]] overview, [[progressive-disclosure|Progressive Disclosure]] concept, and entity pages [[anthropic|Anthropic]], [[claude-code|Claude Code]], and [[claude-api|Claude API]]. Compiled into those pages alongside [[src-2026-05-06-anthropic-agent-skills-quickstart|Anthropic Agent Skills Quickstart]] and [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] (the two companion docs covered by this ingest).

The doc establishes that Skills are deliberately *not* prompts — prompts apply to one conversation, while Skills are reusable filesystem-based assets that load on demand. It also draws an explicit "onboarding guide for a new team member" analogy for the SKILL.md + bundled files structure.

Adjacent existing wiki content: [[anthropic-financial-services|Anthropic Financial Services]] is a concrete case of Skills in production (Claude Code plugin marketplace shipping `SKILL.md` prompts plus Python validators and Excel templates) — its existing claims about "populated SKILL.md prompts" and "Claude Code plugin" become directly groundable in this source's definitional vocabulary.

## Source Metadata

- **Source type:** article (Anthropic platform documentation, MDX-rendered as markdown)
- **Authors:** Anthropic (platform documentation team)
- **Published:** rolling — captured 2026-05-06; references the `skills-2025-10-02` beta header indicating Skills launched October 2025
- **Path:** `sources/2026/2026-05/2026-05-06-anthropic-agent-skills-overview.md`
- **URL:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
