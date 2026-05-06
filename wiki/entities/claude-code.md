---
id: claude-code
title: Claude Code
type: entity
status: active
summary: "Anthropic's CLI for Claude — available in the terminal, desktop apps, the claude.ai/code web app, and IDE extensions. Supports custom Agent Skills only (no pre-built); Skills are filesystem-based at ~/.claude/skills/ (personal) or .claude/skills/ (project) and distributable via Claude Code Plugins."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-best-practices
epistemic_status: sourced
tags:
  - claude-code
  - cli
  - agent-skills
  - anthropic
  - developer-tools
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - claude-code
  - Claude Code CLI
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Claude Code is Anthropic's developer-facing Claude — distributed as a CLI, desktop apps for Mac and Windows, the claude.ai/code web app, and IDE extensions for VS Code and JetBrains. It supports custom Agent Skills only (no pre-built Anthropic-managed Skills are auto-mounted). Skills live as plain directories on disk: `~/.claude/skills/` for the user's personal Skills, `.claude/skills/` for project-scoped Skills checked into the repository. They can also be distributed via Claude Code Plugins. Skills running here have full network access and the same filesystem reach as any other program on the user's machine.

## Key Facts

- Claude Code is available as a CLI in the terminal, as desktop apps for Mac and Windows, as the web app at claude.ai/code, and as IDE extensions for VS Code and JetBrains [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-code|direct|2026-05-06] [epistemic:: sourced]
- Claude Code supports only Custom Skills — pre-built Anthropic-managed Skills (`pptx`, `xlsx`, `docx`, `pdf`) are NOT auto-mounted on Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-code|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills in Claude Code are filesystem-based and don't require API uploads; the operator simply places a directory at `~/.claude/skills/` (personal) or `.claude/skills/` (project) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-code|direct|2026-05-06] [epistemic:: sourced]
- Skills in Claude Code can also be shared via Claude Code Plugins, which is the supported distribution mechanism beyond per-user/per-project file copying [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:sharing-scope|direct|2026-05-06] [epistemic:: sourced]
- Skills running in Claude Code have full network access — the same network access as any other program on the user's computer — and can install local packages, though global package installation is discouraged to avoid interfering with the user's environment [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:runtime-environment-constraints|direct|2026-05-06] [epistemic:: sourced]
- Anthropic bundles its open-source Claude API skill (up-to-date API reference + SDK documentation for 8 programming languages) with Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:open-source-skills|direct|2026-05-06] [epistemic:: sourced]

## Detail

Claude Code is the surface where filesystem-based [[Agent Skills]] are most native: a Skill is just a directory the operator creates locally — no API call, no upload, no opaque container. This makes Claude Code the natural home for Skills that need real-machine network access (calling internal APIs, fetching from package registries, hitting the user's own services) and for Skills that wrap a project's existing scripts and conventions.

The two install locations encode a personal-vs-project boundary: `~/.claude/skills/` holds Skills the user wants available across every project they work in (personal helpers, terminology preferences, recurring code-review patterns); `.claude/skills/` holds Skills checked into a repository so every contributor and every Claude session that opens that repo gets the same set. Plugins handle the third case — Skills shared across an organization or a community without per-user manual installation.

Because Claude Code's runtime is the user's actual machine, Skills here can do things that would be impossible on the [[Claude API]] (which runs in a network-isolated container with no runtime package install). The tradeoff is the security model from [[Anthropic]]'s authoring guidance applies more sharply: Skills are like installed software and should only come from trusted sources, because a malicious Skill can drive Claude to invoke tools or execute code in ways that don't match the Skill's stated purpose [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:security-considerations|direct|2026-05-06] [epistemic:: sourced]

The existing [[Anthropic Financial Services]] plugin marketplace is a production-scale example of Claude Code Plugins distributing Skills: each plugin packages Skills (DCF, LBO, merger-model, etc.) plus supporting Python validators and Excel templates, mounted into Claude Code via Plugin distribution rather than per-user file copy.

## Related Pages

- [[Anthropic]]
- [[Agent Skills]]
- [[Progressive Disclosure]]
- [[Claude API]]
- [[Anthropic Financial Services]]
- [[Hack (Agentive Stack)]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview]]: "Anthropic Agent Skills Overview" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-best-practices]]: "Anthropic Agent Skills Best Practices" (2026-05-06)
