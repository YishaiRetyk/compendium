---
id: symphony
title: "Symphony"
type: entity
status: active
summary: "OpenAI's spec-first service for orchestrating coding agents: a
  long-running daemon that polls an issue tracker (Linear), runs an isolated
  Codex coding-agent session per issue in a per-issue workspace, and dispatches,
  retries, and reconciles through a single-authority orchestrator — shipped as a
  language-agnostic SPEC.md you regenerate into code."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-openai-symphony-spec
epistemic_status: mixed
tags:
- symphony
- openai
- codex
- agent-orchestration
- autonomous-coding
- linear
- tooling
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Symphony"
- "openai/symphony"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Symphony is [[openai|OpenAI]]'s service for orchestrating coding agents to get project work done. It is a long-running automation daemon that continuously reads work from an issue tracker (Linear in the current spec version), creates a deterministic isolated workspace for each issue, and runs a [[codex|Codex]] app-server coding-agent session inside that workspace — dispatching, retrying, stalling out, and reconciling through a single authoritative orchestrator [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]. Its distribution model is the notable part: Symphony ships primarily as a language-agnostic `SPEC.md` (18 sections + an SSH-worker appendix) that you hand to your own coding agent to build, with an Elixir "experimental reference implementation" in-repo — a working instance of [[spec-driven-development|Spec-Driven Development]] pushed to the distribution layer [prov:src-2026-07-03-openai-symphony-spec#sec:option-1-make-your-own|direct|2026-07-03]. Where interactive dev-loop frameworks like [[gsd|GSD (Get-Shit-Done)]] help a human drive an agent through a codebase, Symphony aims one level up: an unattended fleet that turns tracker tickets into isolated implementation runs so teams "manage work instead of supervising coding agents." It is Apache-2.0, ~25,764 stars, and self-labelled an early "engineering preview."

## Key Facts

- Symphony is a long-running automation service that continuously reads work from an issue tracker (Linear in this spec version), creates an isolated workspace per issue, and runs a coding-agent session inside that workspace. [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]
- Published by OpenAI; Apache-2.0 licensed; the in-repo reference implementation is written in Elixir; ~25,764 GitHub stars at the 2026-07-03 snapshot. [prov:src-2026-07-03-openai-symphony-spec#commit:4cbe3a9|direct|2026-07-03]
- Distribution is spec-first: the README's primary path is "tell your favorite coding agent to build Symphony" from SPEC.md in a language of your choice; the Elixir build is a secondary "experimental reference implementation." [prov:src-2026-07-03-openai-symphony-spec#sec:option-1-make-your-own|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:option-2-use-our-experimental-reference-implementation|direct|2026-07-03]
- Scope boundary: Symphony is a scheduler/runner and tracker **reader** — ticket writes (state, comments, PR links) are done by the coding agent via its own tools, and a successful run can end at a workflow-defined handoff state (e.g. `Human Review`), not necessarily `Done`. [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]
- Runtime behavior lives in-repo in a `WORKFLOW.md` contract (YAML front matter + prompt body) that is hot-reloaded without restart; the orchestrator is the single authority over scheduling state and recovers from tracker + filesystem alone (no persistent DB). [prov:src-2026-07-03-openai-symphony-spec#sec:5-workflow-specification-repository-contract|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:7-orchestration-state-machine|direct|2026-07-03]
- The coding agent is integrated over the OpenAI Codex **app-server** protocol (stdio; default launch `codex app-server`); the first turn gets the full rendered issue prompt and continuation turns get only continuation guidance on the same live thread, up to `agent.max_turns` (default 20). [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- The "most important portability constraint" is a set of filesystem safety invariants: the agent runs only when `cwd == workspace_path`, the workspace path MUST stay under the workspace root, and the workspace key is sanitized to `[A-Za-z0-9._-]`. [prov:src-2026-07-03-openai-symphony-spec#sec:95-safety-invariants|direct|2026-07-03]
- Security posture is deliberately implementation-defined — the spec mandates no single approval/sandbox/confirmation policy, requires each implementation to document its trust boundary, and treats harness hardening as core rather than optional. [prov:src-2026-07-03-openai-symphony-spec#sec:15-security-and-operational-safety|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:155-harness-hardening-guidance|direct|2026-07-03]
- Self-description: "turns project work into isolated, autonomous implementation runs, allowing teams to manage work instead of supervising coding agents"; explicitly "a low-key engineering preview for testing in trusted environments." [prov:src-2026-07-03-openai-symphony-spec#sec:readme|direct|2026-07-03] [epistemic:: tentative]

## Detail

Symphony's architecture is a small set of layered components (Section 3 of the spec): a `Workflow Loader` and typed `Config Layer` that parse `WORKFLOW.md`, an `Issue Tracker Client` that normalizes tracker payloads, the `Orchestrator` that owns the poll tick and all scheduling state, a `Workspace Manager` that maps issue identifiers to sanitized per-issue directories, and an `Agent Runner` that wraps workspace + prompt + Codex app-server session; observability (structured logs, an optional status surface) rounds it out [prov:src-2026-07-03-openai-symphony-spec#sec:3-system-overview|direct|2026-07-03]. Each poll tick reconciles running issues, revalidates config, fetches candidates by active state, sorts them (priority ascending, then oldest first), and dispatches while global and per-state concurrency slots remain; the default poll interval is 30 s and the default global concurrency cap is 10 agents [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]. Failure-driven retries use exponential backoff (`min(10000 * 2^(attempt-1), max_retry_backoff_ms)`, capped at 5 min by default), while a *clean* worker exit schedules only a ~1 s continuation retry so the orchestrator can re-check whether the issue is still active and needs another session [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03].

The reconciliation loop is what makes it a daemon rather than a script runner: every tick it does stall detection (kill and retry a worker idle longer than `codex.stall_timeout_ms`) and a tracker state refresh (a now-terminal issue stops its worker and cleans the workspace; a still-active one updates the in-memory snapshot; a neither-active-nor-terminal state stops the worker without cleanup) [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]. Operators steer the system mostly by editing `WORKFLOW.md` (hot-reloaded) or by changing issue states in the tracker, and the OPTIONAL surfaces — an HTTP dashboard with a JSON REST API under `/api/v1/*`, and the Appendix A extension that runs workers on remote hosts over SSH while the orchestrator stays the single source of truth — are explicitly non-required for conformance [prov:src-2026-07-03-openai-symphony-spec#sec:18-implementation-checklist-definition-of-done|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:appendix-a-ssh-worker-extension-optional|direct|2026-07-03].

Positioned against the wiki's existing agent-workflow landscape, Symphony occupies a different point in the design space than the interactive dev-loop tools. GSD, Ralph, and the other [[claude-code-orchestration-frameworks|Claude Code orchestration frameworks]] optimize a *human-in-the-loop* session — context engineering, phase discipline, spec gates — whereas Symphony targets *unattended* operation: a persistent service converting a queue of tracker tickets into isolated agent runs with no per-issue supervision [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03] [epistemic:: inferred]. It shares the Ralph-style pattern of a fixed prompt driving repeated autonomous turns, but externalizes the work queue to the issue tracker and the durable state to per-issue workspaces rather than to on-disk plan files [prov:src-2026-07-03-openai-symphony-spec#sec:5-workflow-specification-repository-contract|direct|2026-07-03] [epistemic:: inferred]. The demo narrative — agents that produce "proof of work" (CI status, PR review feedback, complexity analysis, walkthrough videos) before landing a PR — is a form of [[backpressure|backpressure]] gating autonomous output, though that pipeline is workflow-defined rather than part of the core spec [prov:src-2026-07-03-openai-symphony-spec#sec:readme|direct|2026-07-03] [epistemic:: tentative]. Symphony names [[harness-engineering|Harness Engineering]] as its recommended prerequisite and frames itself as "the next step" beyond it [prov:src-2026-07-03-openai-symphony-spec#sec:requirements|direct|2026-07-03] [epistemic:: tentative]. Maturity should be read conservatively: this is spec-attested behavior labelled a "Draft v1" spec and an "engineering preview," not a battle-tested product.

## Related Pages

- [[openai|OpenAI]] — the publisher; also the origin of the "harness engineering" framing Symphony builds on.
- [[codex|Codex]] — the coding agent Symphony drives via the app-server protocol.
- [[spec-driven-development|Spec-Driven Development]] — the methodology Symphony instantiates by shipping a spec-you-regenerate-into-code.
- [[gsd|GSD (Get-Shit-Done)]] — an interactive dev-loop orchestration framework, contrasted with Symphony's unattended daemon model.
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — the human-in-the-loop framework landscape Symphony sits adjacent to.
- [[backpressure|Backpressure]] — the downstream-rejection pattern the demo's "proof of work" gating illustrates.

## Sources

- [[src-2026-07-03-openai-symphony-spec|openai/symphony — Symphony Service Specification repository snapshot]]: primary repository snapshot at commit `4cbe3a9` (July 2026)
