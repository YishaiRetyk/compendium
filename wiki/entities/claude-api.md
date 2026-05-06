---
id: claude-api
title: Claude API
type: entity
status: active
summary: "Anthropic's HTTP API surface (Messages API + Skills API). Supports both pre-built Anthropic-managed Agent Skills (pptx/xlsx/docx/pdf) and custom uploaded Skills via /v1/skills, invoked by passing skill_id in the Messages API container parameter alongside the code_execution_20250825 tool. Three required betas; no network access; pre-installed packages only."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-quickstart
epistemic_status: sourced
tags:
  - claude-api
  - anthropic
  - agent-skills
  - messages-api
  - code-execution
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Anthropic API
  - Claude HTTP API
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Claude API is Anthropic's HTTP API surface, including the Messages API and the Skills API (`/v1/skills` endpoints). Skills are invoked by passing `container.skills: [{type, skill_id, version}]` to the Messages API alongside the `code_execution_20250825` tool. Both pre-built Anthropic-managed Skills (`pptx`, `xlsx`, `docx`, `pdf`) and custom uploaded Skills are supported. Calls require three beta headers — `code-execution-2025-08-25`, `skills-2025-10-02`, and (for downloading generated files) `files-api-2025-04-14`. Skills run in a code-execution container with NO network access and no runtime package installation. Custom Skills are workspace-wide.

## Key Facts

- Skills on the Claude API are invoked by passing `container.skills` to the Messages API alongside `tools: [{type: "code_execution_20250825", name: "code_execution"}]` — code execution is required for Skills [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-2-create-a-presentation|direct|2026-05-06] [epistemic:: sourced]
- Each entry in `container.skills` is `{type, skill_id, version}` where `type: "anthropic"` indicates an Anthropic-managed pre-built Skill and `version: "latest"` pins the most recently published version [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-2-create-a-presentation|direct|2026-05-06] [epistemic:: sourced]
- The required beta headers for an API Skills call are `code-execution-2025-08-25` and `skills-2025-10-02`; downloading generated files additionally requires `files-api-2025-04-14` [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-api|direct|2026-05-06] [epistemic:: sourced]
- Skills are uploaded as Custom Skills via the Skills API (`/v1/skills` endpoints) and are shared workspace-wide: all members of the workspace can use them [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:claude-api|direct|2026-05-06] [epistemic:: sourced]
- Pre-built Anthropic-managed Skills available are `pptx`, `xlsx`, `docx`, and `pdf`, listed via `GET /v1/skills?source=anthropic` [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-1-list-available-skills|direct|2026-05-06] [epistemic:: sourced]
- Skills running on the Claude API have NO network access — they cannot make external API calls or access the internet — and cannot install new packages at runtime; only pre-configured dependencies are available [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:runtime-environment-constraints|direct|2026-05-06] [epistemic:: sourced]
- Skill-generated files live inside the code-execution container; their `file_id` is returned in `code_execution` tool-use result blocks and downloaded via `GET /v1/files/{file_id}/content` [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-3-download-the-created-file|direct|2026-05-06] [epistemic:: sourced]
- The Messages API model identifier used in all Skills quickstart examples is `claude-opus-4-7` [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-2-create-a-presentation|direct|2026-05-06] [epistemic:: sourced]

## Detail

Skills on the Claude API are a layered request shape: the operator picks a model, a max-tokens budget, a list of beta headers, a `container.skills` array, and the `code_execution_20250825` tool. The model decides — at runtime, from the user message — which Skill (if any) to load. Listing the API (`GET /v1/skills?source=anthropic`) returns only Skill metadata (name + description), implementing the first level of [[Progressive Disclosure]]: Claude knows what Skills exist without paying the token cost of their full instructions.

When a request comes in, Claude matches the user task to a Skill's metadata, reads the SKILL.md body via bash inside the code-execution container (Level 2), and accesses bundled scripts and reference files only as needed (Level 3). Bundled scripts execute via bash, so script source code never enters the model's context — only stdout/stderr does.

The container's runtime constraints are deliberately tight. With no network access and no runtime package installation, API Skills must be self-contained: they can rely only on packages pre-configured in the code-execution image, and their input data has to arrive via the Messages API (uploaded files, text content) rather than be fetched mid-execution. This is the key difference from [[Claude Code]], where Skills run on the user's actual machine with full network access. The same Skill SKILL.md body can run on both surfaces — but Skills that depend on `pip install requests`, `npm install <pkg>`, or live HTTP calls only work on Claude Code or (per admin settings) Claude.ai, not on the Claude API.

Generated files are returned via a two-step flow: the Messages API response includes `code_execution` tool-use result blocks containing `file_id`s for each artifact written inside the container; the operator then downloads each file via `GET /v1/files/{file_id}/content` with the `files-api-2025-04-14` beta header [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-3-download-the-created-file|direct|2026-05-06] [epistemic:: sourced]

Custom Skills on the API are workspace-wide rather than per-user, which is the inverse of [[Anthropic]]'s Claude.ai sharing model and a more stringent boundary than [[Claude Code]]'s personal-vs-project filesystem split.

## Related Pages

- [[Anthropic]]
- [[Agent Skills]]
- [[Progressive Disclosure]]
- [[Claude Code]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview]]: "Anthropic Agent Skills Overview" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-quickstart]]: "Anthropic Agent Skills Quickstart" (2026-05-06)
