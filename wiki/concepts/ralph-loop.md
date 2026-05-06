---
id: ralph-loop
title: Ralph (Autonomous Coding Loop)
type: concept
status: active
summary: "A deliberately minimal autonomous-coding pattern by Geoffrey Huntley: a bash `while` loop re-feeds a fixed PROMPT.md into a CLI agent each iteration, with IMPLEMENTATION_PLAN.md on disk as the only cross-iteration shared state."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-ralph-playbook
epistemic_status: sourced
tags:
  - autonomous-agents
  - agentic-loops
  - prompt-engineering
  - claude-code
  - ralph
  - bash
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Ralph
  - The Ralph Loop
  - Ralph Wiggum
  - ralph technique
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Ralph is a four-part autonomous-coding pattern: (1) a brain-dead bash `while` loop that re-feeds a fixed `PROMPT.md` to a CLI agent, (2) an on-disk `IMPLEMENTATION_PLAN.md` as the only cross-iteration shared state, (3) an `AGENTS.md` operational guide and a `specs/` directory loaded deterministically every iteration, and (4) project-specific [[Backpressure]] (tests, typechecks, lints, builds) that rejects invalid work before commit. Each iteration runs in a fresh context window — the agent reads the plan from disk, picks the most important task, implements + tests + commits, and exits. The mantra is "3 phases, 2 prompts, 1 loop": Phase 1 defines requirements as `specs/*.md`; Phases 2/3 swap `PROMPT_plan.md` and `PROMPT_build.md` against the same loop.

## Key Facts

- Minimal form is a single bash line: `while :; do cat PROMPT.md | claude ; done`. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- The same loop runs both PLANNING (gap analysis only, no commits) and BUILDING (implement + test + commit) modes — only the prompt file changes. [prov:src-2026-05-06-ralph-playbook#sec:workflow|direct|2026-05-06]
- `IMPLEMENTATION_PLAN.md` persists on disk between iterations and is the single shared state across otherwise-isolated executions; the agent reads it, picks the most important task, updates it on completion, and the next iteration reads the updated version. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- Each iteration deterministically loads the same files (`PROMPT.md` + `AGENTS.md` + `specs/*`), so the model starts every run from a known state. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The reference CLI invocation is `claude -p --dangerously-skip-permissions --output-format=stream-json --model opus --verbose`; the same loop pattern works with other CLI agents (`amp`, `codex`, `opencode`). [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- Inner-loop control has no hard technical limit — scope discipline ("one task" + "commit when tests pass" in `PROMPT.md`), backpressure (failing tests block commits), and natural completion (agent exits after a successful commit) are the only governors. [prov:src-2026-05-06-ralph-playbook#sec:loop-mechanics|direct|2026-05-06]
- The plan is disposable: regenerate `IMPLEMENTATION_PLAN.md` (cost = one planning loop) when Ralph drifts, when the plan is stale, or when completed-item clutter accumulates. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Autonomy requires `--dangerously-skip-permissions`, which means a sandbox (Docker, E2B, Fly Sprites) is the only security boundary — "It's not if it gets popped, it's when. And what is the blast radius?". [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]

## Detail

### Three phases, two prompts, one loop

Ralph is a funnel of three phases driven by two prompt files and one bash loop:

- **Phase 1 — Define Requirements (LLM conversation, not a loop iteration):** human + LLM identify Jobs-to-be-Done (JTBD), break each into "topics of concern" (one sentence without "and"), then a subagent writes one `specs/FILENAME.md` per topic. Cardinalities: 1 JTBD → many topics → one spec each → many tasks per spec.
- **Phase 2 — Planning loop (`PROMPT_plan.md`):** subagents study `specs/*` and `src/`, perform gap analysis, and create or refresh `IMPLEMENTATION_PLAN.md` as a prioritized bullet list. No implementation, no commits.
- **Phase 3 — Building loop (`PROMPT_build.md`):** orient on specs, read the plan, pick the most important task, investigate `src/` ("don't assume not implemented"), implement with parallel subagents, validate with one subagent for build/tests, update the plan with discoveries, update `AGENTS.md` if there are operational learnings, commit, exit. The next iteration starts fresh.

### Why a dumb bash loop wins

The continuation mechanism is intentionally dumb: bash restarts the agent → fresh context reads `IMPLEMENTATION_PLAN.md` → agent picks one task → implements + commits + exits → loop restarts. No sophisticated orchestration, no daemons, no state machines. The disk is the durable substrate; the agent is stateless across iterations. This composes cleanly with [[Progressive Disclosure]] (the same files are always loaded in the same order) and avoids the failure modes of long-lived agent sessions (context pollution, drift, lost-in-the-middle effects).

### Context discipline

Ralph's effectiveness depends on tight context budgeting. The framing puts advertised 200K-token windows at ~176K truly usable, with 40-60% utilization as the "smart zone". Tight tasks plus one task per loop yields 100% smart-zone utilization. Concrete moves:

- Use the main agent as a scheduler — delegate expensive work to subagents (each gets ~156kb that's garbage collected) rather than allowing it into the main context.
- Allocate the first ~5,000 tokens to specs so the model is grounded before reading the plan.
- Prefer Markdown over JSON for both work definition and tracking — verbose inputs degrade determinism and Markdown is more token-efficient.

### Bidirectional steering

Ralph is steered from two directions:

- **Upstream:** deterministic context loading (`PROMPT.md` + `AGENTS.md` + `specs/*`), and existing-code patterns shape what the agent generates. If Ralph generates wrong patterns, add or update utilities and example code so it discovers the right ones.
- **Downstream:** [[Backpressure]] from tests, typechecks, lints, and builds rejects invalid output before commit. `AGENTS.md` is where project-specific commands wire backpressure in (the prompt says "run tests" generically; `AGENTS.md` says how).

For criteria that resist programmatic checks (creative quality, aesthetics, UX feel), the playbook proposes an LLM-as-judge fixture (`llm-review.ts`) returning binary `{ pass, feedback }` results, with `intelligence: "fast" | "smart"` selecting model tier and automatic text-vs-vision dispatch by file extension.

### "Let Ralph Ralph"

The operator's job is to engineer the environment, not to do the work in-line. Ralph picks tasks, decides implementation approach, and updates the plan. Eventual consistency is achieved through iteration: Ralph can go in circles, ignore instructions, or take wrong turns — these are expected and surface as guardrails to add to `PROMPT.md` or `AGENTS.md`, or as code utilities to add to `src/lib/`. The plan itself is disposable: regeneration costs one planning loop, which is cheap compared to letting Ralph spin.

### Files contract

The canonical project layout is `loop.sh`, `PROMPT_build.md`, `PROMPT_plan.md`, `AGENTS.md`, `IMPLEMENTATION_PLAN.md`, `specs/`, `src/`, `src/lib/`. `AGENTS.md` is the "heart of the loop" — concise (~60 lines), operational only (build/run/test commands + operational learnings). Status, progress, and planning belong in `IMPLEMENTATION_PLAN.md`; bloating `AGENTS.md` with status pollutes every future iteration's context.

Prompt files use 999...-numbering for guardrails, where higher numbers signal more critical instructions (e.g. `99999. Important: When authoring documentation, capture the why`, `9999999. As soon as there are no build or test errors create a git tag`).

### Enhancement track

Clayton Farr's playbook catalogs five proposed extensions (not yet validated by the author):

- **AskUserQuestion-driven Phase 1** — use Claude's `AskUserQuestionTool` for systematic JTBD/edge-case interviews before writing specs.
- **Acceptance-driven backpressure** — derive required tests during planning from acceptance criteria in specs, making the link from "what success looks like" to "what verifies it" explicit.
- **Non-deterministic backpressure** — an `llm-review.ts` fixture with binary pass/fail and `fast`/`smart` intelligence levels.
- **Ralph-Friendly Work Branches** — a `plan-work "natural language description"` mode that creates a scoped `IMPLEMENTATION_PLAN.md` per branch so Ralph keeps "pick most important" without semantic filtering at runtime.
- **JTBD → Story Map → SLC Release** — reframe topics of concern as activities (verbs in a journey), arrange them into a User Story Map, take horizontal slices as candidate releases, and apply Jason Cohen's Simple-Lovable-Complete criteria.

## Related Pages

- [[Geoffrey Huntley]] — originator of the technique.
- [[Backpressure]] — the downstream steering mechanism Ralph depends on.
- [[Claude Code]] — the reference CLI agent for the canonical invocation.
- [[Progressive Disclosure]] — Ralph's deterministic per-iteration file loading is a progressive-disclosure pattern at the project level.
- [[Comprehension Debt]] — Ralph's plan-disposability and "let Ralph Ralph" framing pushes against operator comprehension; backpressure and `AGENTS.md` discipline are the counterweights.

## Sources

- [[The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr's synthesis of Geoffrey Huntley's Ralph technique (2026-05-06).
