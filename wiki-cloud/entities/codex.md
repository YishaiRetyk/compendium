---
id: codex
title: "Codex"
type: entity
status: active
summary: "OpenAI's coding agent, integrated by host tools through an 'app-server'
  protocol: a stdio subprocess (default launch `codex app-server`) that runs a
  thread-and-turn session model with pass-through approval/sandbox config. Stub —
  documented here as targeted by the Symphony spec."
created_at: 2026-07-03
updated_at: 2026-07-03
sources:
- src-2026-07-03-openai-symphony-spec
epistemic_status: mixed
tags:
- codex
- openai
- symphony
- coding-agent
- tooling
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "Codex"
- "Codex app-server"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Codex is [[openai|OpenAI]]'s coding agent. Host systems integrate it through an **app-server** mode — a subprocess (default launch `codex app-server`, invoked via `bash -lc`) that speaks a protocol over stdio, organized as a *thread* containing one or more *turns* [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]. [[symphony|Symphony]] is the wiki's first ingested consumer of this interface: it launches Codex per issue, runs the first turn with a full prompt and continuation turns on the same live thread, and reads back usage/rate-limit telemetry [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]. This page documents Codex as targeted by the Symphony spec; a dedicated Codex source has not yet been ingested.

## Key Facts

- Exposes an app-server mode launched as `codex app-server` (a stdio subprocess); the targeted app-server version's protocol is the source of truth for message shapes, framing, and method names — where a host spec conflicts with it, the Codex protocol wins. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- Session model is thread + turn: a host extracts `thread_id` and `turn_id` from the protocol and composes a session id as `<thread_id>-<turn_id>`, reusing one thread across continuation turns. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]
- Carries pass-through configuration for `approval_policy` (`AskForApproval`), `thread_sandbox` (`SandboxMode`), and `turn_sandbox_policy` (`SandboxPolicy`); the installed schema is inspectable via `codex app-server generate-json-schema`. [prov:src-2026-07-03-openai-symphony-spec#sec:5-workflow-specification-repository-contract|direct|2026-07-03]
- Emits streaming turn events (e.g. `session_started`, `turn_completed`, `turn_failed`, approval and token-usage signals) that a host consumes for orchestration and observability. [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]

## Detail

Everything recorded here is drawn from how the Symphony specification targets Codex, not from Codex's own documentation, which has not yet been ingested — the spec itself points implementers at the official app-server docs (`developers.openai.com/codex/app-server/`) and generated JSON schema rather than treating Symphony's prose as the protocol definition [prov:src-2026-07-03-openai-symphony-spec#sec:10-agent-runner-protocol-coding-agent-integration|direct|2026-07-03]. The app-server design is what lets an external orchestrator own the session lifecycle (workspace selection, prompt construction, continuation, timeouts, and telemetry extraction) while delegating the actual coding work to Codex — the same separation Symphony's SSH-worker appendix relies on when it launches Codex over remote SSH stdio instead of a local subprocess [prov:src-2026-07-03-openai-symphony-spec#sec:appendix-a-ssh-worker-extension-optional|direct|2026-07-03] [epistemic:: inferred]. As a coding agent driven by an external harness, Codex is the OpenAI-side counterpart to Anthropic's [[claude-code|Claude Code]] in the wiki's tooling graph [epistemic:: inferred].

## Related Pages

- [[openai|OpenAI]] — the publisher of Codex.
- [[symphony|Symphony]] — the orchestrator that drives Codex via the app-server protocol.
- [[claude-code|Claude Code]] — the Anthropic-side externally-driven coding agent it parallels.

## Sources

- [[src-2026-07-03-openai-symphony-spec|openai/symphony — Symphony Service Specification repository snapshot]]: primary repository snapshot at commit `4cbe3a9` (July 2026)
