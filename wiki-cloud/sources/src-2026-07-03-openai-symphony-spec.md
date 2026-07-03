---
id: src-2026-07-03-openai-symphony-spec
title: "openai/symphony — Symphony Service Specification repository snapshot"
type: source
status: active
summary: "Curated snapshot of OpenAI's Symphony repository at commit 4cbe3a9 —
  a spec-first service that polls an issue tracker (Linear), runs an isolated
  Codex coding-agent session per issue, and reconciles via a single-authority
  orchestrator; the requested SPEC.md is embedded verbatim."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- symphony
- openai
- codex
- agent-orchestration
- autonomous-coding
- linear
- repository
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Symphony Service Specification"
- "openai/symphony"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-openai-symphony-spec/source.md
url: "https://github.com/openai/symphony/blob/main/SPEC.md"
content_hash: "sha256:520dcdcac6db1981e1e7b632b92e4fc58b39af7029008a9265a20f18feea796e"
ingested_at: 2026-07-03
source_type: repository
repo_url: "https://github.com/openai/symphony"
commit_sha: "4cbe3a9699a73b862466c0b157ceca0c1985d6d7"
default_branch: main
license: Apache-2.0
primary_language: Elixir
stars_at_ingest: 25764
compilation_status: compiled
compiled_against_hash: "sha256:520dcdcac6db1981e1e7b632b92e4fc58b39af7029008a9265a20f18feea796e"
compiled_targets:
- symphony
- openai
- codex
- spec-driven-development
---

# openai/symphony — Symphony Service Specification repository snapshot

## TL;DR

Curated `source_type: repository` snapshot of **openai/symphony** at commit `4cbe3a9` on `main`. Symphony is OpenAI's spec-first service for orchestrating coding agents: a long-running daemon that continuously reads work from an issue tracker (Linear in this spec version), creates a deterministic isolated workspace per issue, and runs a Codex app-server coding-agent session inside that workspace — dispatching, retrying, and reconciling through a single-authority orchestrator [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]. It is distributed primarily as a language-agnostic `SPEC.md` (18 numbered sections plus an SSH-worker appendix) that you regenerate into code with your own coding agent; an "experimental reference implementation" written in Elixir ships in-repo [prov:src-2026-07-03-openai-symphony-spec#sec:option-1-make-your-own|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:option-2-use-our-experimental-reference-implementation|direct|2026-07-03]. Apache-2.0, ~25,764 stars, self-labelled an early "engineering preview." The requested SPEC.md is embedded verbatim in the snapshot bundle so `#sec:` locators resolve offline.

## Key Takeaways

- Symphony is a long-running automation service that continuously reads work from an issue tracker (Linear in this specification version), creates an isolated workspace for each issue, and runs a coding-agent session for that issue inside the workspace. [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]
- Distribution is **spec-first**: the README's primary path ("Option 1. Make your own") is to tell your coding agent to build Symphony from SPEC.md in a language of your choice; the in-repo Elixir build is offered as a secondary "experimental reference implementation." [prov:src-2026-07-03-openai-symphony-spec#sec:option-1-make-your-own|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:option-2-use-our-experimental-reference-implementation|direct|2026-07-03]
- Important boundary: Symphony is a scheduler/runner and tracker **reader** — ticket writes (state transitions, comments, PR links) are performed by the coding agent via its own tools, and a successful run can end at a workflow-defined handoff state (for example `Human Review`), not necessarily `Done`. [prov:src-2026-07-03-openai-symphony-spec#sec:1-problem-statement|direct|2026-07-03]
- Runtime behavior is repository-owned through a `WORKFLOW.md` contract (YAML front matter for tracker/polling/workspace/hooks/agent/codex config + a Markdown prompt body); dynamic reload is REQUIRED — `WORKFLOW.md` changes are re-applied live without restart. [prov:src-2026-07-03-openai-symphony-spec#sec:5-workflow-specification-repository-contract|direct|2026-07-03]
- The orchestrator is the single authority that mutates scheduling state; recovery is tracker-driven and filesystem-driven with no persistent database (in-memory scheduler state is not restored across restarts). [prov:src-2026-07-03-openai-symphony-spec#sec:2-goals-and-non-goals|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:7-orchestration-state-machine|direct|2026-07-03]
- Coding-agent integration targets the **OpenAI Codex app-server** protocol over stdio (default launch `codex app-server`); the spec explicitly defers protocol shape/transport to the targeted Codex version and controls only orchestration, workspace selection, prompt construction, and observability. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- Project facts at the snapshot commit: Apache-2.0 licensed, Elixir primary language, ~25,764 GitHub stars, with the reference implementation under `elixir/` and the spec as the top-level `SPEC.md`. [prov:src-2026-07-03-openai-symphony-spec#commit:4cbe3a9|direct|2026-07-03]
- Self-description: Symphony "turns project work into isolated, autonomous implementation runs, allowing teams to manage work instead of supervising coding agents," and is explicitly labelled "a low-key engineering preview for testing in trusted environments." [prov:src-2026-07-03-openai-symphony-spec#sec:readme|direct|2026-07-03] [epistemic:: tentative]

## Extracted Claims

- Main components: `Workflow Loader`, `Config Layer`, `Issue Tracker Client`, `Orchestrator`, `Workspace Manager`, `Agent Runner`, plus an OPTIONAL `Status Surface` and structured `Logging`. [prov:src-2026-07-03-openai-symphony-spec#sec:3-system-overview|direct|2026-07-03]
- The orchestrator's internal issue claim-states — `Unclaimed`, `Claimed`, `Running`, `RetryQueued`, `Released` — are explicitly distinct from tracker states (`Todo`, `In Progress`, …). [prov:src-2026-07-03-openai-symphony-spec#sec:7-orchestration-state-machine|direct|2026-07-03]
- Poll loop default interval is `30000 ms`; each tick reconciles running issues, runs dispatch preflight validation, fetches candidates by active states, sorts by dispatch priority, and dispatches while slots remain. [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]
- Concurrency is capped globally (`agent.max_concurrent_agents`, default `10`) and optionally per tracker-state (`max_concurrent_agents_by_state`); candidates sort by `priority` ascending, then oldest `created_at`, then `identifier`; a `Todo` issue with any non-terminal blocker is not dispatched. [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]
- Retry/backoff: a clean worker exit schedules a short ~`1000 ms` continuation retry (to re-check whether the issue is still active); failure-driven retries use `delay = min(10000 * 2^(attempt - 1), agent.max_retry_backoff_ms)`, capped by the configured max (default `300000 ms` / 5 min). [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]
- Reconciliation runs every tick in two parts — stall detection (terminate + retry when `elapsed_ms > codex.stall_timeout_ms`) and tracker state refresh (terminal state → terminate worker and clean workspace; still-active → update snapshot; neither → terminate without workspace cleanup). [prov:src-2026-07-03-openai-symphony-spec#sec:8-polling-scheduling-and-reconciliation|direct|2026-07-03]
- Safety invariants — called "the most important portability constraint": (1) launch the agent only when `cwd == workspace_path`; (2) the workspace path MUST stay inside the workspace root (absolute-normalized prefix check, reject otherwise); (3) the workspace key is sanitized so only `[A-Za-z0-9._-]` remain. [prov:src-2026-07-03-openai-symphony-spec#sec:95-safety-invariants|direct|2026-07-03]
- Agent runner: subprocess launched via `bash -lc <codex.command>` (default `codex app-server`) with the per-issue workspace as cwd; the first turn sends the full rendered issue prompt while continuation turns send only continuation guidance on the same live thread, up to `agent.max_turns` (default `20`); `session_id` is composed as `<thread_id>-<turn_id>`. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- An OPTIONAL client-side tool, `linear_graphql`, lets the agent execute exactly one raw GraphQL operation per call against Linear using Symphony's configured tracker auth (rather than reading tokens from disk); unsupported tool calls return a failure without stalling the session. [prov:src-2026-07-03-openai-symphony-spec#sec:105-approval-tool-calls-and-user-input-policy|direct|2026-07-03]
- Linear tracker contract: GraphQL endpoint `https://api.linear.app/graphql`, project filtered via `project: { slugId: { eq: $projectSlug } }`, pagination REQUIRED (default page size `50`), `30000 ms` network timeout; three REQUIRED adapter operations — `fetch_candidate_issues()`, `fetch_issues_by_states()`, `fetch_issue_states_by_ids()`. [prov:src-2026-07-03-openai-symphony-spec#sec:11-issue-tracker-integration-contract-linear-compatible|direct|2026-07-03]
- Security posture is deliberately implementation-defined: the spec does NOT mandate a single approval, sandbox, or operator-confirmation policy; each implementation MUST document its trust boundary and treat harness hardening (tighter Codex approvals/sandbox, OS/container/VM isolation, scoped tracker access) as part of the core safety model, not an afterthought. [prov:src-2026-07-03-openai-symphony-spec#sec:15-security-and-operational-safety|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:155-harness-hardening-guidance|direct|2026-07-03]
- Conformance is layered: Section 18 splits a REQUIRED core checklist from RECOMMENDED extensions — the OPTIONAL HTTP server (dashboard `/` + JSON REST API under `/api/v1/*`) and the Appendix A SSH-worker extension (run workers on remote hosts over SSH while the orchestrator remains the single source of truth). [prov:src-2026-07-03-openai-symphony-spec#sec:18-implementation-checklist-definition-of-done|direct|2026-07-03] [prov:src-2026-07-03-openai-symphony-spec#sec:appendix-a-ssh-worker-extension-optional|direct|2026-07-03]
- Prerequisite framing: Symphony "works best in codebases that have adopted harness engineering" and is positioned as "the next step — moving from managing coding agents to managing work that needs to get done." [prov:src-2026-07-03-openai-symphony-spec#sec:requirements|direct|2026-07-03] [epistemic:: tentative]

## Notes

- **Epistemic split** per `schema/reference/repository-ingestion.md`: spec-behavior, architecture, and project-fact claims (`#sec:`, `#commit:`) are `sourced`/`direct` — the spec is the fact of what it defines. Self-descriptive capability/marketing claims (the "manage work, not agents" thesis; the "harness engineering" prerequisite) carry claim-level `[epistemic:: tentative]`.
- **Maturity caveat:** the repo self-labels "a low-key engineering preview for testing in trusted environments" and the SPEC is "Draft v1 (language-agnostic)." Behavior here is *spec-attested*, not observed in production; dependent pages inherit `mixed` where their identity leans on the pitch rather than on a verifiable code/metadata fact.
- **Spec-as-primary-artifact:** the spec is the shipped product and code is explicitly regenerable from it (build-it-yourself Option 1; Elixir build labelled a *reference* implementation) — a concrete instance of spec-driven development taken to the distribution layer. Compiled into the `spec-driven-development` concept page.
- **Curation:** the full `SPEC.md` is embedded verbatim in the snapshot so `#sec:` locators resolve offline; the README is embedded with its H1 demoted to a comment and the demo-video poster-image embed trimmed (the Vimeo demo link is retained in prose). No code `## Excerpts` registry is present — this ingest anchors prose via `#sec:` and project facts via `#commit:`, so no `#path:` locators are used.
- **Classification rationale:** the user pointed at `SPEC.md` specifically, but it was ingested as `source_type: repository` (not a standalone article) so the commit SHA anchors external drift detection and the project facts (license/language/stars/tree) are captured — consistent with the wiki's first repository source, `src-2026-07-03-gsd-core-repo`.

## Source Metadata

- Repository: <https://github.com/openai/symphony>
- Requested file: `SPEC.md` — "Symphony Service Specification", Status: Draft v1 (language-agnostic)
- Commit: `4cbe3a9699a73b862466c0b157ceca0c1985d6d7` (branch `main`)
- License: Apache-2.0; Primary language: Elixir; Stars at snapshot: 25,764
- Homepage: <https://openai.com/index/open-source-codex-orchestration-symphony/>
- Retrieved: 2026-07-03 (UTC); ingested 2026-07-03
- Acquisition: `git clone --depth 1` → metadata harvest (`git rev-parse HEAD` + GitHub REST API for stars/license/language) → README + SPEC embedded verbatim into the snapshot `source.md`
