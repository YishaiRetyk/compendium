# gsd-core — repository snapshot

## Snapshot Metadata

- Repository: https://github.com/open-gsd/gsd-core
- Commit: 69fef7c00e277b6e1e17fe15e530304c1d6bb5e3
- Default branch: next
- License: MIT
- Primary language: JavaScript
- Retrieved: 2026-07-02

## README

# GSD Core

**Git. Ship. Done.**

**A light-weight meta-prompting, context engineering, and spec-driven development system for Claude Code, OpenCode, Gemini CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf, and more.**

<!-- curator note: badge block trimmed (npm/downloads/tests/discord/stars/license shields) -->

---

## What is GSD Core

GSD Core is a context-engineering and spec-driven development framework that drives AI coding agents (Claude Code, Codex, Gemini CLI, Kimi CLI, Copilot, Cursor, and more) through a disciplined phase loop. It solves [context rot](docs/explanation/context-engineering.md) — the quality degradation that accumulates as an AI fills its context window — by running all heavy research, planning, and execution work in fresh-context subagents while keeping your main session lean.

---

## How it works

Each milestone repeats the same five-step loop, one phase at a time:

1. **Discuss** — capture implementation decisions before anything is planned
2. **Plan** — research, decompose, and verify the plan fits a fresh context window
3. **Execute** — run plans in parallel waves; each executor starts with a clean 200k-token context
4. **Verify** — walk through what was built; diagnose and fix before declaring done
5. **Ship** — create the PR, archive the phase, repeat for the next one

---

## Quickstart

```bash
npx @opengsd/gsd-core@latest
```

The installer prompts for your runtime (Claude Code, OpenCode, Gemini CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf, and more) and whether to install globally or locally. The installer is required for cross-runtime compatibility — do not copy files from `agents/` or `commands/` directly.

On another runtime or without Node.js? See [Install on your runtime](docs/how-to/install-on-your-runtime.md).

Once installed, start your first project:

```bash
/gsd-new-project
```

New here? Follow [Your first project](docs/tutorials/your-first-project.md) for a guided walkthrough from install to first shipped phase.

---

## Documentation

**Tutorials** — learning by doing:
- [Your first project](docs/tutorials/your-first-project.md)
- [Onboarding an existing codebase](docs/tutorials/onboarding-an-existing-codebase.md)

**How-to guides** — task-focused recipes:
- [Install on your runtime](docs/how-to/install-on-your-runtime.md)
- [Plan a phase](docs/how-to/plan-a-phase.md)
- [Verify and ship](docs/how-to/verify-and-ship.md)
- … [see all how-to guides](docs/README.md#how-to-guides)

**Reference** — authoritative facts:
- [Commands](docs/COMMANDS.md)
- [Configuration](docs/CONFIGURATION.md)
- [CLI tools](docs/CLI-TOOLS.md)

**Explanation** — concepts and design decisions:
- [Context engineering](docs/explanation/context-engineering.md)
- [The phase loop](docs/explanation/the-phase-loop.md)
- [Architecture](docs/ARCHITECTURE.md)

Full index: [docs/README.md](docs/README.md). Other languages: [日本語](README.ja-JP.md) · [한국어](README.ko-KR.md) · [Português](README.pt-BR.md) · [简体中文](README.zh-CN.md).

---

## Why it works

Most AI-coding setups fail at scale because context bloat silently degrades output quality, there is no shared memory between sessions, and nothing verifies that code actually works. GSD Core solves all three: heavy work runs in fresh subagents, structured artifacts like `STATE.md` and `CONTEXT.md` survive session boundaries, and the verify step walks through what was built and generates fix plans before a phase is declared done. See [docs/explanation/context-engineering.md](docs/explanation/context-engineering.md) for the full reasoning.

Troubleshooting? See [docs/how-to/recover-and-troubleshoot.md](docs/how-to/recover-and-troubleshoot.md).

---

## Community

| Project | Platform |
|---------|----------|
| [gsd-opencode](https://github.com/rokicool/gsd-opencode) | Original OpenCode port |
| [Discord](https://discord.gg/mYgfVNfA2r) | Community support |

---

## License

MIT License. See [LICENSE](LICENSE) for details.

<!-- curator note: Star History embed and closing tagline div trimmed -->

## Excerpts

<!-- Curator-selected code excerpts. Each entry heading is '### <path/to/file>'
     or '### <path/to/file>:L<n>-L<m>'; body is a fenced code block quoting the
     lines at the snapshot commit (69fef7c0). #path: locators resolve against
     these headings (schema/reference/repository-ingestion.md). -->

### package.json:L1-L5

```json
{
  "name": "@opengsd/gsd-core",
  "version": "1.7.0-rc.1",
  "description": "GSD Core is a meta-prompting, context engineering, and spec-driven development system for AI coding agents.",
  "main": ".opencode/plugins/gsd-core.js",
```

### package.json:L38-L40

```json
  "author": "OpenGSD",
  "license": "MIT",
  "repository": {
```

### CHANGELOG.md:L482-L488

```markdown
## Legacy Release History

Release notes for every version published before the project was renamed to `@opengsd/gsd-core` — the retired `get-shit-done-cc` / `get-shit-done-redux` lineage, versions `1.0.0` → `1.42.x` plus pre-release and canary builds — have been rolled up into a single archive:

➡️ **[docs/RELEASE-NOTES-LEGACY.md](docs/RELEASE-NOTES-LEGACY.md)**

Those legacy `1.x` numbers belong to the previous package line and predate the current `@opengsd/gsd-core` versioning, which restarts at `1.0.0`. They are preserved verbatim-in-spirit (condensed) in the archive and intentionally kept out of this file so the two version streams cannot collide.
```

### docs/explanation/context-engineering.md:L7-L13

```markdown
## The problem: context rot

Every AI coding session starts fresh. The model reads your question, reasons over it, and replies. But a session is rarely one exchange. You ask follow-up questions, paste error messages, iterate on code, redirect the model when it drifts. Each turn adds tokens to the context window — the finite buffer of text the model can "see" at once.

As that window fills, something subtle happens. The model does not fail loudly. It keeps answering. But the quality of its answers quietly degrades. Early instructions get pushed towards the edge of what it can attend to. Nuance from the first few exchanges — the constraints you stated, the architecture you agreed on, the edge cases you flagged — competes for attention against everything that came later. Researchers call this **context rot**.

Context rot manifests in several ways:
```

### docs/explanation/context-engineering.md:L27-L31

```markdown

GSD Core's central insight is that *most* of the work in a coding session does not need to happen in the main context at all. Research, planning, code writing, and verification are each discrete, bounded tasks. Each can be handed to a specialised subagent that starts with a clean, carefully scoped context window — and reports its result back to a thin orchestrator that stays lean.

This is not a workaround for context rot. It is a structural solution.
```
