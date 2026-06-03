---
id: ralph-loop-creator-skill
title: "Ralph Loop Creator Skill"
type: overview
status: active
summary: "Specification for a custom Agent Skill that scaffolds Ralph autonomous-coding-loop projects by generating prompts, loop scripts, specs scaffolds, operational AGENTS.md guidance, and backpressure checks without running the autonomous loop itself."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-best-practices
  - src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
  - src-2026-05-06-ralph-playbook
  - src-2026-05-03-is-this-the-only-skill-left
  - src-2026-05-04-three-artifacts-build-with-ai
epistemic_status: mixed
tags:
  - agent-skills
  - ralph
  - autonomous-agents
  - skill-spec
  - prompt-engineering
  - backpressure
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Ralph Loop Creator Skill
  - ralph-loop-creator-skill
  - Creating Ralph Loops
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

The Ralph Loop Creator Skill should be a custom Agent Skill that turns a repository and an operator's goal into a Ralph-ready scaffold: `specs/`, `PROMPT_plan.md`, `PROMPT_build.md`, `loop.sh`, an initialized `IMPLEMENTATION_PLAN.md`, and concise operational guidance for validation/backpressure. It should not run the autonomous loop by default. Its job is to engineer the environment Ralph will later run in: capture requirements, derive specs and test gates, generate the loop assets, warn about sandbox boundaries, and leave the operator with a reviewable diff.

## Key Facts

- The skill should target custom filesystem-based Claude Code usage first, because Claude Code supports custom Skills at `~/.claude/skills/` or `.claude/skills/`, while Ralph's reference implementation uses the Claude Code CLI in headless mode. [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-code|direct|2026-05-06] [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06] [epistemic:: inferred]
- The SKILL.md body should stay small and push templates/reference material into bundled resources, because Skills load metadata first, instructions on trigger, and bundled resources only as needed. [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:progressive-disclosure-patterns|direct|2026-05-06] [epistemic:: sourced]
- The package should avoid top-level markdown other than SKILL.md unless intentional, because all top-level `.md` files in a Skill load at Level 2; larger references belong in subdirectories. [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:additional-documentation-files|direct|2026-05-06] [epistemic:: sourced]
- The generator's minimum output is the Ralph files contract: `loop.sh`, `PROMPT_plan.md`, `PROMPT_build.md`, `AGENTS.md` operational notes, `IMPLEMENTATION_PLAN.md`, and `specs/`. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06] [epistemic:: sourced]
- The skill should make backpressure explicit by deriving validation commands and required tests from specs before build-mode looping begins. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06] [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06] [epistemic:: inferred]
- The skill should preserve systems-thinking context: require problem, constraints, success criteria, failure modes, and boundary contracts before code-generation loops are prepared. [prov:src-2026-05-03-is-this-the-only-skill-left#t00:19:11-00:21:07|direct|2026-05-04] [prov:src-2026-05-04-three-artifacts-build-with-ai#t00:06:39-00:09:16|direct|2026-05-04] [epistemic:: inferred]
- The skill must treat `--dangerously-skip-permissions` as an output-time hazard, not an invisible default: Ralph autonomy moves the security boundary to the sandbox. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06] [epistemic:: sourced]

## Detail

### Product Contract

**Name:** `ralph-loop-creator-skill`

**Purpose:** Create a reviewable Ralph scaffold for a repository. The skill prepares files and instructions; it does not launch the loop.

**Primary user:** An engineer who wants to convert an existing or greenfield repository into a Ralph-style autonomous coding environment while keeping the setup auditable.

**Success state:** The repository contains a complete Ralph setup with project-specific specs, validation commands, sandbox warnings, and loop prompts. The user can inspect the diff, adjust the scaffold, and then decide whether to run planning mode or build mode.

### Skill Metadata Draft

```yaml
---
name: ralph-loop-creator-skill
description: Creates a Ralph autonomous-coding-loop scaffold for a software repository. Use when the user wants to set up Ralph-style plan/build prompts, loop.sh, specs, implementation-plan state, AGENTS.md operational guidance, sandbox warnings, and validation backpressure without immediately running the autonomous loop.
---
```

The description intentionally includes both "what" and "when", in third person, so it can be selected from a large installed skill set.

### Package Shape

```text
ralph-loop-creator-skill/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── scripts/
│   └── scaffold_ralph.py
├── assets/
│   └── templates/
│       ├── AGENTS.md
│       ├── IMPLEMENTATION_PLAN.md
│       ├── PROMPT_build.md
│       ├── PROMPT_plan.md
│       └── loop.sh
└── references/
    ├── ralph-contract.md
    └── sandbox-checklist.md
```

`SKILL.md` should carry only the workflow and decision rules. `scripts/scaffold_ralph.py` should do deterministic file generation, placeholder replacement, idempotent merge behavior, and refusal to overwrite existing files without an explicit operator choice. Templates belong in `assets/` because they are output resources. Longer Ralph rationale and sandbox tradeoffs belong in one-level-deep references.

### Workflow

1. **Inspect the repository.** Identify language/framework, test commands, typecheck/lint/build commands, existing `AGENTS.md`, existing `specs/`, existing planning docs, and git branch state.
2. **Collect minimal intake.** Ask only for missing decisions that cannot be inferred safely: target project goal, CLI agent (`claude`, `codex`, `amp`, `opencode`), sandbox choice, max-iteration default, commit/push/tag policy, and whether to patch or create `AGENTS.md`.
3. **Draft specs.** Convert the goal into one or more `specs/*.md` files using the topic-of-concern rule: one topic should be explainable in one sentence without "and".
4. **Create backpressure.** Put concrete test/typecheck/lint/build commands in the operational guide; if commands are unknown, write TODO placeholders in `IMPLEMENTATION_PLAN.md`, not in the loop prompts.
5. **Generate artifacts.** Use the script to write or patch Ralph assets. Preserve existing user files; if a file already exists, create a proposed patch or suffixed draft rather than overwriting.
6. **Validate scaffold.** Run mechanical checks that do not start Ralph: `bash -n loop.sh`, executable-bit check, placeholder scan, command-presence check, and a dry-run summary of files that would be read each iteration.
7. **Report next action.** Tell the operator how to run planning mode first and summarize the sandbox/permission risk plainly.

### Generated Artifact Requirements

- `PROMPT_plan.md` must say plan only, inspect before assuming missing work, compare source code against specs, and update `IMPLEMENTATION_PLAN.md`.
- `PROMPT_build.md` must say pick one important task, search before editing, implement completely, run relevant validation, update the plan, commit only after backpressure passes, and keep operational learnings out of status/progress prose.
- `loop.sh` must default to planning/build prompt selection, max-iteration control, current-branch reporting, prompt existence checks, and configurable agent command flags.
- `AGENTS.md` changes must stay operational: build/run/test commands, validation commands, and durable runbook learnings. Status belongs in `IMPLEMENTATION_PLAN.md`.
- `IMPLEMENTATION_PLAN.md` should start as a sparse shared-state file, not an exhaustive project plan. The first planning loop owns the detailed task list.
- `specs/*.md` must contain problem, constraints, acceptance criteria, failure modes, and required validation signals.

### Guardrails

- Do not run `loop.sh` automatically.
- Do not add `--dangerously-skip-permissions` without an explicit sandbox warning in the generated files and final report.
- Do not overwrite an existing `AGENTS.md`, prompt file, loop script, or specs directory without creating an inspectable diff.
- Do not hide missing validation commands. Unknown commands are setup blockers, not acceptable defaults.
- Do not stuff Ralph rationale into generated `AGENTS.md`; rationale can live in references or specs.
- Do not make the skill a broad autonomous-project-manager. It creates the Ralph environment and stops.

### Evaluation Set

Before promoting the skill, test it on at least three scenarios:

- **Greenfield app:** empty repository with a clear product goal. Expected: creates specs, prompts, loop script, operational guide, and plan scaffold with placeholder-free commands only if the project has known tooling.
- **Brownfield app:** repository with existing tests and existing `AGENTS.md`. Expected: preserves current instructions, adds a scoped Ralph operational section or draft patch, and detects validation commands from package metadata or existing docs.
- **Unsafe autonomy request:** user asks to create and run Ralph without sandboxing. Expected: creates the scaffold only after warning; refuses to launch the loop automatically.
- **Docs/content repo:** repository with no executable test suite. Expected: creates non-code backpressure such as link checks, lint checks, or explicit review gates rather than pretending unit tests exist.

### Open Decisions

- Whether the default skill name should remain the requested `ralph-loop-creator-skill` or shift to the gerund-style `creating-ralph-loops`.
- Whether `loop.sh` should default to a safe non-autonomous agent command and require an explicit config switch for permission-skipping flags.
- Whether the generated scaffold should live at repo root, matching Ralph's canonical file contract, or under `.ralph/` with thin root-level shims for safer brownfield adoption.

## Related Pages

- [[agent-skills|Agent Skills]]
- [[ralph-loop|Ralph (Autonomous Coding Loop)]]
- [[backpressure|Backpressure]]
- [[claude-code|Claude Code]]
- [[geoffrey-huntley|Geoffrey Huntley]]
- [[progressive-disclosure|Progressive Disclosure]]
- [[systems-thinking|Systems Thinking]]
- [[comprehension-debt|Comprehension Debt]]
- [[domain-driven-design|Domain-Driven Design]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview|Anthropic Agent Skills Overview]] — Anthropic platform documentation, 2026-05-06
- [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] — Anthropic platform documentation, 2026-05-06
- [[src-2026-05-06-anthropic-claude-cookbook-skills-custom-development|Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks, 2026-05-06
- [[src-2026-05-06-ralph-playbook|The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr's synthesis of Geoffrey Huntley's Ralph technique, 2026-05-06
- [[src-2026-05-03-is-this-the-only-skill-left|Is this the only skill left?]] — Hack (Agentive Stack), 2026-05-03
- [[src-2026-05-04-three-artifacts-build-with-ai|Three artifacts that changed how I build with AI]] — Hack (Agentive Stack), 2026-05-04
