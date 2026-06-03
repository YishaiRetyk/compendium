---
id: src-2026-05-06-ralph-playbook
title: "The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)"
type: source
status: active
summary: "Clayton Farr's opinionated synthesis of Geoffrey Huntley's 'Ralph' autonomous-coding-loop technique — a bash loop that re-feeds a fixed PROMPT.md into a CLI agent each iteration, with IMPLEMENTATION_PLAN.md on disk as the single shared-state file between fresh-context iterations. Codifies the workflow as 3 phases / 2 prompts / 1 loop, the four key principles (context is everything, steering via patterns + backpressure, let Ralph Ralph, move outside the loop), inner/outer loop control mechanics, and an enhancement track (acceptance-driven backpressure, LLM-as-judge for non-deterministic backpressure, work-scoped branches, JTBD → story map → SLC release framing)."
created_at: 2026-05-06
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
  - ralph
  - autonomous-agents
  - agentic-loops
  - claude-code
  - prompt-engineering
  - jtbd
  - backpressure
  - llm-as-judge
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)"
  - "The Ralph Playbook"
  - "how-to-ralph-wiggum"
  - "ralph-playbook"
  - "src-2026-05-06-ralph-playbook"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-06-ralph-playbook/source.md
url: "https://github.com/ghuntley/how-to-ralph-wiggum"
content_hash: "sha256:55980d420469870d88890b93f66494f309ae2e164c57d34462151ad5ed408e59"
ingested_at: 2026-05-06
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:55980d420469870d88890b93f66494f309ae2e164c57d34462151ad5ed408e59"
compiled_targets:
  - geoffrey-huntley
  - ralph-loop
  - backpressure
  - claude-code
---

## TL;DR

A long-form, opinionated playbook by Clayton Farr that distils [[geoffrey-huntley|Geoffrey Huntley]]'s "Ralph" approach to autonomous AI coding into a reusable workflow. The thesis: a brain-dead `while :; do cat PROMPT.md | claude ; done` bash loop, plus a single on-disk `IMPLEMENTATION_PLAN.md` acting as cross-iteration shared state, plus tight per-loop context allocation, will out-deliver elaborate orchestration. Three phases (define requirements → plan → build), two prompts (`PROMPT_plan.md`, `PROMPT_build.md`), one loop. Quality is steered upstream (specs, codebase patterns, deterministic context loading) and downstream (tests, typechecks, lints — "backpressure"). The playbook also catalogs five enhancement experiments: AskUserQuestion-driven planning, acceptance-driven backpressure, LLM-as-judge for subjective criteria, work-scoped branches via `plan-work` mode, and JTBD → story map → SLC release framing.

## Key Takeaways

- Ralph is a funnel of "3 Phases, 2 Prompts, 1 Loop": Phase 1 defines requirements (`specs/*.md`), Phases 2/3 run the same loop with `PROMPT_plan.md` (gap analysis only, no code) or `PROMPT_build.md` (implement + test + commit). [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- The continuation mechanism is intentionally dumb: bash restarts the agent each iteration; the agent reads `IMPLEMENTATION_PLAN.md` from disk, picks the most important task, implements it, updates the plan, commits, exits — and the loop restarts with a fresh context window. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- Each iteration deterministically loads the same files (`PROMPT.md` + `AGENTS.md` + `specs/*`) so the model starts every run from a known state. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Context discipline drives everything else: 200K-advertised ≈ 176K usable, 40-60% utilization is the "smart zone", so tight tasks + 1 task per loop = 100% smart-zone utilization. Use the main agent as a scheduler; spawn subagents for memory extension. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- "Backpressure" — tests, typechecks, lints, builds, and LLM-as-judge gates — is the downstream steering mechanism that rejects invalid work; `AGENTS.md` provides the project-specific commands that wire backpressure in. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The reference invocation is `cat PROMPT.md | claude -p --dangerously-skip-permissions --output-format=stream-json --model opus --verbose` — running outside the permission system means the sandbox is the only security boundary ("It's not if it gets popped, it's when. And what is the blast radius?"). [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The plan is disposable: regenerate `IMPLEMENTATION_PLAN.md` (cost = one planning loop) when Ralph is going off track, the plan feels stale, or completed-item clutter has accumulated. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Five proposed enhancements are catalogued, not yet validated by the author: AskUserQuestion-driven Phase 1, acceptance-driven backpressure (test requirements derived from acceptance criteria during planning), non-deterministic backpressure via an `llm-review.ts` fixture (binary pass/fail with `fast`/`smart` intelligence levels), work-scoped branches via a `plan-work` mode, and a JTBD → activities → user-story-map → SLC-release planning pipeline. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]

## Extracted Claims

### Workflow structure

- Ralph is a funnel of three phases (define requirements / plan / build), two prompts (`PROMPT_plan.md` for gap analysis, `PROMPT_build.md` for implementation), and one loop mechanism shared by both modes. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- Phase 1 (Define Requirements) is an LLM conversation, not a loop iteration: human + LLM identify Jobs-to-be-Done (JTBD), break each JTBD into topics of concern, then a subagent writes one `specs/FILENAME.md` per topic. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- Topics of concern pass a "one sentence without 'and'" scope test; if conjunctions are needed to describe what it does, it's probably multiple topics. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- Cardinalities: 1 JTBD → many topics of concern; 1 topic of concern → 1 spec; 1 spec → many tasks. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- PLANNING-mode loop: subagents study `specs/*` and `/src`, perform gap analysis, create or update `IMPLEMENTATION_PLAN.md` as a prioritized bullet list, and stop without implementing or committing. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- BUILDING-mode loop has 10 documented sub-steps: orient on specs, read the plan, select the most important task, investigate `/src` ("don't assume not implemented"), implement with N subagents for file ops, validate with 1 subagent for build/tests, update the plan with discoveries, update `AGENTS.md` if there are operational learnings, commit, then end so the next iteration starts fresh. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]

### Loop mechanics

- The minimal Ralph loop is one bash line: `while :; do cat PROMPT.md | claude ; done`. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- The same bash-loop pattern works with other CLI agents (`amp`, `codex`, `opencode`, etc.); Claude is the reference but not a hard dependency. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- The continuation chain is: bash loop runs → feeds `PROMPT.md` → agent picks one task from `IMPLEMENTATION_PLAN.md` → implements + commits + exits → bash restarts immediately → fresh context reads the updated plan. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- `IMPLEMENTATION_PLAN.md` persists on disk between iterations and acts as shared state between otherwise isolated loop executions. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- A single task execution has no hard technical limit; control relies on scope discipline ("one task" + "commit when tests pass" in `PROMPT.md`), backpressure (test/build failures force fixes before commit), and natural completion (agent exits after a successful commit). [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- The enhanced reference `loop.sh` adds mode selection (`plan` vs `build`), a max-iterations argument, and `git push` after each iteration; the canonical Claude flags are `-p` (headless), `--dangerously-skip-permissions`, `--output-format=stream-json`, `--model opus`, `--verbose`. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- Opus is recommended as the primary loop model for task selection and prioritization; Sonnet may be substituted in build mode for speed when tasks are clear and well-defined. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]

### Key principles

- Context budget heuristic: 200K-advertised tokens ≈ 176K truly usable, with 40-60% utilization as the "smart zone"; tight tasks plus one task per loop yields 100% smart-zone utilization. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The main agent should act as a scheduler — expensive work is delegated to subagents (each gets ~156kb that's garbage collected) to avoid polluting main context. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The playbook prefers Markdown over JSON for both work definition and tracking, citing token efficiency. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Steering is bidirectional: upstream via deterministic context loading and existing-code patterns ("first ~5,000 tokens for specs"), downstream via test/typecheck/lint/build gates that reject invalid output. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Backpressure can extend beyond programmatic checks via LLM-as-judge tests for subjective criteria (creative quality, aesthetics, UX feel) using binary pass/fail. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- "Let Ralph Ralph" — leaning into LLM self-identification, self-correction, and self-improvement, including for plan ownership and task prioritization, with eventual consistency achieved through iteration. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- `--dangerously-skip-permissions` is required for autonomous operation; this means a sandbox (Docker/E2B/Fly Sprites) is the only security boundary, framed by the maxim "It's not if it gets popped, it's when. And what is the blast radius?". [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- "Move Outside the Loop": the operator's job is to engineer the environment that lets Ralph succeed, not to do the work; signs Ralph can discover include prompt guardrails, `AGENTS.md` operational notes, and utilities/patterns added to the codebase. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The plan is disposable: regenerate when Ralph is going off track, when the plan is stale, when completed-item clutter accumulates, after significant spec changes, or when the operator is unsure of true status; regeneration cost is one planning loop. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]

### Files contract

- The canonical project layout is: `loop.sh`, `PROMPT_build.md`, `PROMPT_plan.md`, `AGENTS.md`, `IMPLEMENTATION_PLAN.md`, `specs/`, `src/`, `src/lib/`. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- `AGENTS.md` is the "heart of the loop" — concise (~60 lines), operational only, describing how to build/run/validate the project; it is not a changelog or progress diary. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- Status, progress, and planning belong in `IMPLEMENTATION_PLAN.md`; bloating `AGENTS.md` with status pollutes every future loop's context. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- Geoff's specific phrasing patterns are surfaced as a checklist: "study" (not "read"/"look at"), "don't assume not implemented", "using parallel subagents", "only 1 subagent for build/tests", "Think extra hard" (now "Ultrathink"), "capture the why", "keep it up to date", "if functionality is missing then it's your job to add it", "resolve them or document them". [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- Prompt structure uses 999...-numbering for guardrails and invariants, with higher numbers signalling more critical instructions. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- `IMPLEMENTATION_PLAN.md` has no pre-specified template — Ralph/the LLM dictates the format that works best for it, and the file can be regenerated from PLANNING mode whenever needed. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]
- `specs/*` files are the source of truth for what should be built, one per topic of concern; they are created during the Requirements phase and consumed by both PLANNING and BUILDING modes. [prov:src-2026-05-06-ralph-playbook#sec:files|direct|2026-05-06]

### Enhancements (proposed by the author, not part of canonical Ralph)

- Use Claude's `AskUserQuestionTool` during Phase 1 (Define Requirements) for systematic JTBD/edge-case/acceptance-criteria interviews before writing specs; no code or prompt changes needed. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- Acceptance-driven backpressure: derive required tests during planning from acceptance criteria in specs, making the connection from "what success looks like" to "what verifies it" explicit; phrased as "Required tests derived from acceptance criteria must exist and pass before committing". [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- Non-deterministic backpressure via an `llm-review.ts` / `llm-review.test.ts` fixture pair in `src/lib/`; binary `{ pass, feedback }` API with `intelligence: "fast" | "smart"` (defaults to `fast`) and automatic text-vs-vision dispatch by file extension. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- Ralph-Friendly Work Branches: scope plans at planning time, not at runtime — a `plan-work "natural language description"` mode creates a scoped `IMPLEMENTATION_PLAN.md` per branch so Ralph keeps "pick most important" without semantic filtering at build time. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- JTBD → Story Map → SLC Release pipeline: reframe topics of concern as activities (verbs in a journey), arrange them into a User Story Map, take horizontal slices through the map as candidate releases, and apply Jason Cohen's Simple-Lovable-Complete criteria so each release is a coherent, shippable slice. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- The SLC enhancement introduces an `AUDIENCE_JTBD.md` artifact as a single source of truth for "who we're building for and why", referenced during both spec creation and SLC planning. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]

## Notes

- Authorship: README authored by Clayton Farr (`contact@claytonfarr.com`); the underlying Ralph technique is Geoffrey Huntley's, originally published at `ghuntley.com/ralph` and discussed in Huntley's recent videos. The repo is hosted under github.com/ghuntley/ but the README is signed "(I'm Clayton)" and points readers to ClaytonFarr.github.io for a formatted version.
- Last upstream commit at ingest time: `88d488a` (2026-01-10, "formatting"). The repo has a single commit on `main`, suggesting Geoff merged Clayton's playbook in a single squash.
- Repo layout beyond the README itself: `files/AGENTS.md` (template stub), `files/IMPLEMENTATION_PLAN.md` (placeholder), `files/PROMPT_build.md` and `files/PROMPT_plan.md` (canonical prompt templates), `files/loop.sh` (the enhanced bash loop), `references/sandbox-environments.md` (Docker/E2B sandbox guidance — "the sandbox is the security boundary"), `references/ralph-diagram.png` and `references/nah.png` (figures referenced inline). Bundle preserves all of these except the redundant 138 KB `index.html` (rendered README).
- The "nah" reference is Geoff Huntley's tweeted reaction to community summaries that didn't capture the technique faithfully — the playbook is partly motivated by trying to "RTFM as closely as possible from the person who not only captured this approach but also has had the most ass-time in the seat".
- Cross-references in the README that did NOT become entity pages on this ingest: `@mattpocockuk`, `@ryancarson`, Thariq (`@trq212`), Jason Cohen (Simple-Lovable-Complete coiner), and the NN/g User Story Mapping article. None are recurring figures in the wiki yet; revisit if future sources cite them.
- Privacy: `cloud_safe`. Public GitHub repo, no PII or proprietary content; the playbook itself is intended for wide circulation.

## Source Metadata

- **Author:** Clayton Farr (`contact@claytonfarr.com`)
- **Originating technique:** Geoffrey Huntley (ghuntley.com/ralph)
- **Repository:** github.com/ghuntley/how-to-ralph-wiggum
- **Last commit at ingest:** `88d488a148af97e4a3f22b11b4c3598c79d6a577` (2026-01-10, "formatting")
- **Source file:** `sources/2026/2026-05/2026-05-06-ralph-playbook/source.md` (rendered from `README.md`, 1226 lines, 62 KB)
- **Bundle contents:** `source.md`, `AGENTS.md`, `IMPLEMENTATION_PLAN.md`, `PROMPT_build.md`, `PROMPT_plan.md`, `loop.sh`, `references/sandbox-environments.md`, `references/ralph-diagram.png`, `references/nah.png`
- **Content hash (source.md):** `sha256:55980d420469870d88890b93f66494f309ae2e164c57d34462151ad5ed408e59`
- **Ingested:** 2026-05-06
