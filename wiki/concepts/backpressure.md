---
id: backpressure
title: Backpressure
type: concept
status: active
summary: "Downstream rejection signals — tests, typechecks, lints, builds, and LLM-as-judge gates — that block invalid agent output from being committed, providing the steering mechanism that makes autonomous coding loops converge."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-ralph-playbook
epistemic_status: sourced
tags:
  - autonomous-agents
  - agentic-loops
  - testing
  - llm-as-judge
  - prompt-engineering
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Backpressure
  - agentic backpressure
  - loop backpressure
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Backpressure, in the agentic-loop sense, is the set of downstream gates — tests, typechecks, lints, builds, and (for subjective criteria) LLM-as-judge reviews — that reject invalid agent output before it reaches a commit. It is the "downstream" half of the steering pair: upstream steering shapes what the agent generates (via deterministic context loading and existing code patterns), backpressure rejects what comes out the other end. The general-purpose prompt says "run tests"; project-specific `AGENTS.md` files name the actual commands. Without backpressure, autonomous loops drift toward placeholders, broken builds, and "seems done?" ambiguity.

## Key Facts

- The mechanism: tests, typechecks, lints, and builds reject invalid or unacceptable work before commit, forcing the agent to fix issues before exiting an iteration. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The prompt is generic ("run tests"); the project-specific commands live in `AGENTS.md`, which is how backpressure gets wired in per project. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- Backpressure is paired with upstream steering — deterministic context loading and existing-code patterns shape what the agent generates; backpressure rejects what comes out. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- For subjective criteria (creative quality, aesthetics, UX feel) that resist programmatic validation, the playbook recommends LLM-as-judge tests with binary pass/fail, accepting natural review variance as the loop iterates to convergence. [prov:src-2026-05-06-ralph-playbook#sec:key-principles|direct|2026-05-06]
- The playbook's reference LLM-as-judge fixture is a single function `createReview({ criteria, artifact, intelligence })` returning `{ pass, feedback? }`, with `intelligence: "fast" | "smart"` (default `fast`) and automatic text-vs-vision dispatch by file extension. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]
- The proposed acceptance-driven extension derives required tests during planning from acceptance criteria in specs ("Required tests derived from acceptance criteria must exist and pass before committing"), preventing the agent from claiming completion without programmatic verification. [prov:src-2026-05-06-ralph-playbook#sec:enhancements|direct|2026-05-06]

## Detail

### Why backpressure is the steering mechanism

In an autonomous coding loop like [[Ralph (Autonomous Coding Loop)]], the operator is not in-line. The agent picks the task, decides the implementation approach, runs tests, and commits. The only thing standing between a hallucinated function and a `git push` is whatever rejects invalid work. That rejection layer — collectively, "backpressure" — is what makes the loop converge instead of drift.

Without backpressure, autonomous loops produce three predictable failure modes:

- **Placeholders pretending to be done.** Stubs, `TODO`s, and minimal implementations that "pass" because nothing checked.
- **Broken builds shipped.** Tests-not-run or tests-skipped means breakage is committed and propagates.
- **"Seems done?" ambiguity.** Without a clear pass/fail signal, the agent and operator both lose the ability to tell when a task is finished.

### Programmatic backpressure

The standard layer:

- **Tests** — both targeted (the unit of code just changed) and full-suite when appropriate.
- **Typechecks** — language-native (`tsc`, `mypy`, `cargo check`) catch shape mismatches before runtime.
- **Lints** — style and bug-pattern detectors.
- **Builds** — the ultimate "can this artifact ship" gate.

The general prompt says "run tests" and "fix issues before committing"; the project-specific commands belong in `AGENTS.md` (e.g. `npm test`, `pytest -x`, `cargo test`). Bloating `AGENTS.md` with status notes pollutes every iteration's context, so it stays operational-only.

### Non-deterministic backpressure (LLM-as-judge)

Some acceptance criteria resist programmatic validation:

- **Creative quality** — writing tone, narrative flow, engagement.
- **Aesthetic judgments** — visual harmony, design balance, brand consistency.
- **UX quality** — intuitive navigation, clear information hierarchy.
- **Content appropriateness** — context-aware messaging, audience fit.

The proposed solution is LLM-as-judge tests with binary pass/fail. A reference fixture `createReview({ criteria, artifact, intelligence })` returns `{ pass, feedback? }`. Both `fast` (e.g. Gemini 3.0 Flash class) and `smart` (e.g. GPT 5.1 class) tiers use multimodal models; artifact type detection is automatic — strings ending in `.png`/`.jpg`/`.jpeg` route to vision input, everything else routes to text input. Reviews run until pass, accepting natural variance as the loop iterates.

The framing: "deterministically bad in an undeterministic world" — individual reviews may disagree across runs, but the loop provides eventual consistency through repetition.

### Acceptance-driven backpressure (proposed extension)

Geoff's Ralph implicitly connects specs → implementation → tests through emergent iteration. The acceptance-driven extension makes the connection explicit by deriving test requirements during planning, creating a direct line from "what success looks like" to "what verifies it":

- **Acceptance criteria** (in specs) describe behavioral outcomes — what success looks like.
- **Test requirements** (in `IMPLEMENTATION_PLAN.md`) are verification points derived from those criteria — what to check.
- **Implementation approach** (up to Ralph) covers the technical decisions about how to achieve it.

The key distinction: specify *what* to verify (outcomes), not *how* to implement (approach). This preserves "let Ralph Ralph" — the agent still decides implementation details — while providing clear completion signals.

A guardrail like `999. Required tests derived from acceptance criteria must exist and pass before committing. Tests are part of implementation scope, not optional.` makes this binding.

### Upstream-versus-downstream steering

Backpressure is the downstream half of a pair:

- **Upstream:** deterministic context loading (`PROMPT.md` + `AGENTS.md` + `specs/*` in the same order every iteration), and existing-code patterns shape what the agent generates. If Ralph generates wrong patterns, add utilities and example code so it discovers the right ones.
- **Downstream:** backpressure rejects invalid output before commit.

The prompt should also remind Ralph to *create* backpressure when implementing — e.g. "When authoring documentation, capture the why — tests and implementation importance." Backpressure is not just consumed by the agent; the agent is responsible for adding it as it goes.

## Related Pages

- [[Ralph (Autonomous Coding Loop)]] — backpressure is the steering mechanism that makes Ralph converge.
- [[Geoffrey Huntley]] — whose framing makes backpressure central to autonomous coding.
- [[Comprehension Debt]] — backpressure is what catches AI-generated code that the team would otherwise not understand and not test.

## Sources

- [[The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr's synthesis of Geoffrey Huntley's Ralph technique, including the acceptance-driven and LLM-as-judge extensions (2026-05-06).
