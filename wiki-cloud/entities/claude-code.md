---
id: claude-code
title: Claude Code
type: entity
status: active
summary: "Anthropic's CLI for Claude — available in the terminal, desktop apps, the
  claude.ai/code web app, and IDE extensions. Supports custom Agent Skills only (no
  pre-built); Skills are filesystem-based at ~/.claude/skills/ (personal) or .claude/skills/
  (project) and distributable via Claude Code Plugins."
created_at: 2026-05-06
updated_at: 2026-06-09
sources:
- src-2026-05-06-anthropic-agent-skills-overview
- src-2026-05-06-anthropic-agent-skills-best-practices
- src-2026-05-06-ralph-playbook
- src-2026-04-16-claude-code-frameworks-report
epistemic_status: mixed
tags:
- claude-code
- cli
- agent-skills
- anthropic
- developer-tools
- slash-commands
- subagents
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- Claude Code
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
- Claude Code is the reference CLI for the [[ralph-loop|Ralph (Autonomous Coding Loop)]] pattern; the canonical autonomous invocation is `claude -p --dangerously-skip-permissions --output-format=stream-json --model opus --verbose`, fed by a bash `while` loop reading a fixed `PROMPT.md` from stdin [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06] [epistemic:: sourced]
- Running with `--dangerously-skip-permissions` bypasses Claude Code's permission system entirely, so a sandbox (Docker, E2B, Fly Sprites) is the only remaining security boundary for autonomous loops on this CLI [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06] [epistemic:: sourced]
- Beyond Skills, Claude Code's building blocks are slash commands (`.claude/commands/<name>.md`), [[subagents|subagents]] (`.claude/agents/<name>.md`), and CLAUDE.md/AGENTS.md memory files — all assembled around progressive disclosure [prov:src-2026-04-16-claude-code-frameworks-report#sec:executive-summary|derived|2026-06-09] [epistemic:: sourced]
- As of v2.1.101 (April 11, 2026), slash commands and Skills were merged: both `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` create `/deploy`, with Skills taking precedence on conflict; Skills are now the recommended form (directory support + richer frontmatter) [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|derived|2026-06-09] [epistemic:: tentative]
- Slash-command security knob: set `disable-model-invocation: true` on side-effectful commands (`/commit`, `/deploy`) or the SlashCommand tool can auto-trigger them; allowlist tools tightly (`Bash(git diff:*)`, not `Bash(*)` — CVE-2025-66032 was a wide-allowlist bypass) [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|derived|2026-06-09] [epistemic:: tentative]
- CLAUDE.md loads on every session and every turn; length is the single most important variable (community ceiling <300 lines, ~60 as the gold standard), and the router pattern keeps it a thin index pointing to deeper docs via `@path` imports — Anthropic's diagnostic: "If Claude keeps doing something despite a rule against it, the file is probably too long" [prov:src-2026-04-16-claude-code-frameworks-report#sec:claude-md|derived|2026-06-09] [epistemic:: sourced]
- Claude Code does not yet read the cross-tool `AGENTS.md` open standard natively (issue #6235), so teams symlink `CLAUDE.md → AGENTS.md` as the workaround [prov:src-2026-04-16-claude-code-frameworks-report#sec:claude-md|derived|2026-06-09] [epistemic:: tentative]

## Detail

Claude Code is the surface where filesystem-based [[agent-skills|Agent Skills]] are most native: a Skill is just a directory the operator creates locally — no API call, no upload, no opaque container. This makes Claude Code the natural home for Skills that need real-machine network access (calling internal APIs, fetching from package registries, hitting the user's own services) and for Skills that wrap a project's existing scripts and conventions.

The two install locations encode a personal-vs-project boundary: `~/.claude/skills/` holds Skills the user wants available across every project they work in (personal helpers, terminology preferences, recurring code-review patterns); `.claude/skills/` holds Skills checked into a repository so every contributor and every Claude session that opens that repo gets the same set. Plugins handle the third case — Skills shared across an organization or a community without per-user manual installation.

Because Claude Code's runtime is the user's actual machine, Skills here can do things that would be impossible on the [[claude-api|Claude API]] (which runs in a network-isolated container with no runtime package install). The tradeoff is the security model from [[anthropic|Anthropic]]'s authoring guidance applies more sharply: Skills are like installed software and should only come from trusted sources, because a malicious Skill can drive Claude to invoke tools or execute code in ways that don't match the Skill's stated purpose [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:security-considerations|direct|2026-05-06] [epistemic:: sourced]

The existing [[anthropic-financial-services|Anthropic Financial Services]] plugin marketplace is a production-scale example of Claude Code Plugins distributing Skills: each plugin packages Skills (DCF, LBO, merger-model, etc.) plus supporting Python validators and Excel templates, mounted into Claude Code via Plugin distribution rather than per-user file copy.

Claude Code is also the reference CLI for [[geoffrey-huntley|Geoffrey Huntley]]'s autonomous-coding pattern: a bash `while :; do cat PROMPT.md | claude -p --dangerously-skip-permissions --output-format=stream-json --model opus --verbose ; done` loop, with an `IMPLEMENTATION_PLAN.md` file on disk acting as cross-iteration shared state. The same loop pattern works with other CLI agents (`amp`, `codex`, `opencode`), but Opus + Claude Code is the documented baseline. The `-p` (headless) and `--output-format=stream-json` flags are what make Claude Code suitable as a non-interactive bash-loop component; `--dangerously-skip-permissions` is what makes the loop autonomous, at the explicit cost of relocating the security boundary from Claude Code's permission prompts to the surrounding sandbox.

### Building blocks beyond Skills

The [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks report]] frames Claude Code as a small set of building blocks assembled around progressive disclosure: Agent Skills, **slash commands**, **subagents**, and **CLAUDE.md/AGENTS.md memory files**. Slash commands are markdown files at `.claude/commands/<name>.md` with optional YAML frontmatter (`description`, `allowed-tools`, `argument-hint`, `model`, `disable-model-invocation`), supporting `$ARGUMENTS`/`$1`/`$2` expansion, pre-prompt shell via `` !`cmd` ``, and `@path` file references. A notable 2026 change (v2.1.101, April 11) merged commands and Skills — both `.claude/commands/deploy.md` and `.claude/skills/deploy/SKILL.md` create `/deploy`, with Skills winning on conflict and now being the recommended form [prov:src-2026-04-16-claude-code-frameworks-report#sec:slash-commands|derived|2026-06-09] [epistemic:: tentative]. The security guidance is sharp: side-effectful commands should set `disable-model-invocation: true` (otherwise the SlashCommand tool can auto-trigger them), and tool allowlists should be narrow (`Bash(git diff:*)` not `Bash(*)`, after the CVE-2025-66032 wide-allowlist bypass).

Subagents (`.claude/agents/<name>.md`) are isolated Claude instances with their own context window and tool allowlist — the basis for research fan-out, fresh-context code review, and parallel execution. Memory files are governed by length: CLAUDE.md loads every session and every turn, so the community keeps it under ~300 lines (~60 as a gold standard) and uses the router pattern (a thin index that defers detail to `@`-imported docs and skill folders). Because Claude Code does not yet read the cross-tool `AGENTS.md` standard natively (issue #6235), teams symlink `CLAUDE.md → AGENTS.md` [prov:src-2026-04-16-claude-code-frameworks-report#sec:claude-md|derived|2026-06-09] [epistemic:: sourced]. These primitives are what the [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] (Spec Kit, Superpowers, GSD) assemble into opinionated workflows.

## Related Pages

- [[anthropic|Anthropic]]
- [[agent-skills|Agent Skills]]
- [[progressive-disclosure|Progressive Disclosure]]
- [[claude-api|Claude API]]
- [[anthropic-financial-services|Anthropic Financial Services]]
- [[hack-agentive-stack|Hack (Agentive Stack)]]
- [[ralph-loop|Ralph (Autonomous Coding Loop)]]
- [[geoffrey-huntley|Geoffrey Huntley]]
- [[backpressure|Backpressure]]
- [[subagents|Subagents]]
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview|Anthropic Agent Skills Overview]] — Anthropic platform docs, 2026-05-06
- [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] — Anthropic platform docs, 2026-05-06
- [[src-2026-05-06-ralph-playbook|The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr's synthesis, 2026-05-06
- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]] — comparative synthesis report, April 2026
