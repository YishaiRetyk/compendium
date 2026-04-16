---
title: Progressive Disclosure Refactor — Framework Comparison
date: 2026-04-16
topic: progressive-disclosure-refactor-scoping
---

# Progressive Disclosure Refactor — Framework Comparison

## 1. Matrix: 5 frameworks × 3 buckets

| Framework | Always-loaded core rules | Portable deep reference docs | Runtime-specific skills/commands |
|---|---|---|---|
| **Claude Code Skills** | Only SKILL.md *frontmatter* (name + description, capped ~1,536 chars/entry) stays in context; body loads on invoke | `references/`, `examples/`, and per-skill sibling `.md` files referenced from SKILL.md body ("see reference.md"); plain markdown — portable if copied | `SKILL.md` with `allowed-tools`, `disable-model-invocation`, `paths` globs, `context: fork`, `$ARGUMENTS`; lives under `~/.claude/skills/<name>/` (Claude Code only) |
| **GSD (in-repo)** | `SKILL.md` frontmatter only (~50 lines; see `/home/yishai/.claude/skills/gsd-plan-phase/SKILL.md`) | `workflows/plan-phase.md` (1,288 lines) + `references/*.md` (`context-budget.md`, `agent-contracts.md`, `gate-prompts.md`, etc.) — included via `@path` directives inside SKILL body; pure markdown, Codex can `Read` them | The SKILL.md wrapper + `bin/gsd-tools.cjs` init calls; Claude-only slash invocation, but the body content is portable |
| **SpecKit** | `.specify/memory/constitution.md` (always loaded) | `.specify/templates/*.md` (spec/plan/tasks templates) and generated `.specify/specs/<feature>/{spec,plan,tasks,research}.md` — plain markdown | `/speckit.specify`, `/speckit.plan`, `/speckit.tasks` slash commands + `.specify/scripts/*.sh` — agent-specific per-runtime install |
| **Superpowers** | `README.md` as pointer-index ("Skills Library" lists skill name + one-line description) + runtime-shim docs (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `docs/README.codex.md`, `docs/README.opencode.md`) | `skills/<skill>/SKILL.md` bodies — plain markdown, loaded on demand by any runtime | None required; skills are markdown. Runtime shims exist so Codex/OpenCode/Gemini read the same skill files |
| **Cursor Rules** | `.cursor/rules/*.mdc` with `alwaysApply: true` | Same directory, `.mdc` with `alwaysApply: false` + `description` (agent-requested) or `@rule-name` manual | `.mdc` with `globs: [...]` for path-scoped auto-attach — Cursor-only engine |

## 2. Cross-framework synthesis

**Pattern A — Pointer-index + on-demand bodies.** Superpowers' README and Claude Code's frontmatter-only-in-context model converge: the always-loaded layer is a *catalog* (names + one-line descriptions), bodies load when invoked. GSD implements this too — SKILL.md is 53 lines, the real content is in `@`-referenced workflow/reference files.

**Pattern B — Plain-markdown references are universal; runtime wrappers are thin.** SpecKit templates, GSD references, Superpowers skills, and Claude Code `references/*.md` are all plain markdown with no runtime dependency. Runtime-specific wrapping (SKILL.md frontmatter, `.mdc` globs, slash commands) is a thin shell around portable content. This is the Codex-parity escape hatch.

**Contradiction — auto-load scope.** Cursor's `alwaysApply` + `globs` auto-attach contradicts Claude Code/Superpowers' "body never auto-loads, only the pointer does." SpecKit's `constitution.md` sides with Cursor (always in context). **For Codex parity, the Cursor/SpecKit "always-apply" model is hostile**: Codex has no globs engine. Prefer the pointer-index model.

## 3. Recommendation for this repo

**Move to reference docs FIRST (portable, low-risk, high token-savings):**

1. **§4 worked examples** (entity/concept/source/comparison/overview/decision) — extract to `schema/examples/*.md` or reuse existing `examples/kahneman/`. These are ~300+ lines of pure illustration. Replace with one-line references in §4: *"See `schema/examples/entity.md` for a filled-in instance."* Wizard render unaffected (examples sit outside the 4 placeholders).
2. **§16 Appendix A Dataview queries** — extract to `docs/reference/dataview-queries.md`. Pure reference; no agent ever needs them inline.
3. **§16 Appendix B commit examples** — extract to `docs/reference/commit-examples.md`.

These three cuts are ~400–500 lines, preserve §1's "sole authoritative specification" framing (deeper docs exist, the spec stays canonical), survive the wizard (no placeholders touched), survive the pre-commit byte-equality hook (sync applies to whatever `CLAUDE.md`/`AGENTS.md` end up being), and require zero Codex-only or Claude-only runtime.

**Skills LATER (defer):** Do not extract workflows (§11) or operations (§9) into skills yet. GSD's pattern works because `gsd-tools.cjs` exists as a runtime; this repo has no equivalent portable mirror. Phase 12's Codex-parity gate would block any Claude-only skill extraction. Revisit post-v1.2 if a plain-markdown `workflows/*.md` mirror is warranted.

**Sizing:** **Phase-sized.** Fits inside v1.1 Shareability as a new phase 9.5 or bundled into phase 10/11. Three file extractions + §4/§16 edits + doc-link verification is a single-commit-per-extraction ingest, well under a milestone. Does NOT invite re-architecture.

## Open questions

- Does the wizard's placeholder rendering touch §4 example blocks? If yes, examples must stay inline until placeholders are verified non-overlapping.
- Is there a byte-count target driving this (e.g., ~500 lines below current 1,718)? Determines whether §16 alone suffices or §4 examples must go too.
