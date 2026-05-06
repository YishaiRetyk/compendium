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
  - src-2026-05-06-anthropic-claude-cookbook-skills-introduction
  - src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
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
  - Claude API
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
- The Python SDK call shape for Skills is `client.beta.messages.create(...)` (the non-beta `client.messages.create(...)` does NOT accept the `container` parameter and raises `TypeError: Messages.create() got an unexpected keyword argument 'container'`) [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-container-parameter|direct|2026-05-06] [epistemic:: sourced]
- Beta features are passed via the `betas=[...]` parameter on the SDK call, NOT via `extra_headers`; a Skills call needs all three of `code-execution-2025-08-25`, `files-api-2025-04-14`, `skills-2025-10-02` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:how-skills-work-with-code-execution|direct|2026-05-06] [epistemic:: sourced]
- Listing Skills requires the Skills beta on the client itself, e.g. `Anthropic(api_key=..., default_headers={"anthropic-beta": "skills-2025-10-02"})`; then `client.beta.skills.list(source="anthropic")` returns Anthropic-managed Skills and `source="custom"` returns the workspace's custom Skills [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:discovering-available-skills|direct|2026-05-06] [epistemic:: sourced]
- The required Anthropic Python SDK version for Skills support is 0.71.0 or later — older versions don't support `client.beta.messages.create()`-with-`container` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:setup-installation|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills are uploaded via `client.beta.skills.create(display_title=..., files=files_from_dir(skill_path))` (the `files_from_dir` helper is imported from `anthropic.lib`) [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:api-workflow|direct|2026-05-06] [epistemic:: sourced]
- `display_title` is workspace-unique — a duplicate raises an error containing `cannot reuse an existing display_title`; remediation is either delete the existing skill or pick a different title [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:financial-ratio-calculator|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills are referenced in `container.skills` with `type: "custom"` (vs `"anthropic"` for pre-built); a single `container.skills` array may mix custom + Anthropic Skills in the same request, e.g. `[{"type": "custom", "skill_id": brand_skill_id, ...}, {"type": "anthropic", "skill_id": "pptx", ...}]` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:brand-guidelines|direct|2026-05-06] [epistemic:: sourced]
- Custom Skill versioning lifecycle: `client.beta.skills.versions.create(skill_id, files=files_from_dir(...))` for new versions, `versions.list(skill_id=...)` to enumerate, `versions.delete(skill_id, version)` to remove a version, and `client.beta.skills.delete(skill_id)` to remove the skill — but Skill deletion requires deleting all versions first [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:creating-new-versions|direct|2026-05-06] [epistemic:: sourced]
- Container reuse is the API-level token-optimization pattern: pass `container.id` from a previous response to subsequent requests to avoid reloading skills [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-optimization-tips|direct|2026-05-06] [epistemic:: sourced]
- Files generated by a Skill have a "limited lifetime" on Anthropic's servers — download them immediately after creation rather than later [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-file-download|direct|2026-05-06] [epistemic:: sourced]

## Detail

Skills on the Claude API are a layered request shape: the operator picks a model, a max-tokens budget, a list of beta headers, a `container.skills` array, and the `code_execution_20250825` tool. The model decides — at runtime, from the user message — which Skill (if any) to load. Listing the API (`GET /v1/skills?source=anthropic`) returns only Skill metadata (name + description), implementing the first level of [[Progressive Disclosure]]: Claude knows what Skills exist without paying the token cost of their full instructions.

When a request comes in, Claude matches the user task to a Skill's metadata, reads the SKILL.md body via bash inside the code-execution container (Level 2), and accesses bundled scripts and reference files only as needed (Level 3). Bundled scripts execute via bash, so script source code never enters the model's context — only stdout/stderr does.

The container's runtime constraints are deliberately tight. With no network access and no runtime package installation, API Skills must be self-contained: they can rely only on packages pre-configured in the code-execution image, and their input data has to arrive via the Messages API (uploaded files, text content) rather than be fetched mid-execution. This is the key difference from [[Claude Code]], where Skills run on the user's actual machine with full network access. The same Skill SKILL.md body can run on both surfaces — but Skills that depend on `pip install requests`, `npm install <pkg>`, or live HTTP calls only work on Claude Code or (per admin settings) Claude.ai, not on the Claude API.

Generated files are returned via a two-step flow: the Messages API response includes `code_execution` tool-use result blocks containing `file_id`s for each artifact written inside the container; the operator then downloads each file via `GET /v1/files/{file_id}/content` with the `files-api-2025-04-14` beta header [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-3-download-the-created-file|direct|2026-05-06] [epistemic:: sourced]

Custom Skills on the API are workspace-wide rather than per-user, which is the inverse of [[Anthropic]]'s Claude.ai sharing model and a more stringent boundary than [[Claude Code]]'s personal-vs-project filesystem split.

### SDK invocation pattern

The Python SDK distinguishes the regular Messages API (`client.messages.create(...)`) from the beta Messages API (`client.beta.messages.create(...)`). Only the beta path accepts the `container` parameter — calling Skills via the non-beta path raises `TypeError: Messages.create() got an unexpected keyword argument 'container'`. Beta features are activated via the `betas=[...]` parameter on the call, not via `extra_headers={"anthropic-beta": "..."}` as in older Anthropic beta features. A Skills call therefore looks like [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:how-skills-work-with-code-execution|direct|2026-05-06] [epistemic:: sourced]:

```python
response = client.beta.messages.create(
    model="claude-opus-4-7",
    max_tokens=4096,
    container={"skills": [{"type": "anthropic", "skill_id": "xlsx", "version": "latest"}]},
    tools=[{"type": "code_execution_20250825", "name": "code_execution"}],
    messages=[{"role": "user", "content": "..."}],
    betas=["code-execution-2025-08-25", "files-api-2025-04-14", "skills-2025-10-02"],
)
```

The minimum SDK version is `anthropic >= 0.71.0`; older versions don't expose `client.beta.messages.create()` with `container` support [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:setup-installation|direct|2026-05-06] [epistemic:: sourced]

### Custom Skill lifecycle

Uploading a custom Skill is a single call: `client.beta.skills.create(display_title=..., files=files_from_dir(skill_path))`, where `files_from_dir` is the bundled helper from `anthropic.lib` that walks a directory and converts it into the API's expected file-payload shape. The returned object exposes `id` (auto-generated, used as `skill_id` in subsequent calls), `display_title`, `latest_version`, and `created_at`. A new version of an existing Skill is `client.beta.skills.versions.create(skill_id, files=files_from_dir(...))` — same body, just under the versions namespace. Listing is `client.beta.skills.list(source="custom")` and `client.beta.skills.versions.list(skill_id=...)`. Deletion is staged: `versions.delete(skill_id, version)` per version, then `skills.delete(skill_id)` for the Skill envelope itself; the Skill cannot be deleted while it still has versions [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:creating-new-versions|direct|2026-05-06] [epistemic:: sourced]

`display_title` is the operator-facing label and is workspace-unique. Two engineers in the same workspace cannot independently upload Skills with the same `display_title`; the second `create()` call returns an error containing `cannot reuse an existing display_title`. Remediation is either to delete the existing Skill or pick a different label [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:financial-ratio-calculator|direct|2026-05-06] [epistemic:: sourced]. This is operationally important for team workflows where multiple people iterate on the same Skill — it forces explicit collaboration around Skill naming rather than allowing silent shadowing.

### Skill composition

A single `container.skills` array may carry both `type: "custom"` and `type: "anthropic"` entries in the same request. The cookbook's brand-guidelines example combines a custom brand-rules Skill with the pre-built `pptx` Skill so Claude applies the brand on top of the generic presentation generator [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:brand-guidelines|direct|2026-05-06] [epistemic:: sourced]. This is the API-surface confirmation of the composition principle — Skills are designed to stack, not just to substitute for one another.

## Related Pages

- [[Anthropic]]
- [[Agent Skills]]
- [[Progressive Disclosure]]
- [[Claude Code]]

## Sources

- [[Anthropic Agent Skills Overview]] — Anthropic platform docs, 2026-05-06
- [[Anthropic Agent Skills Quickstart]] — Anthropic platform docs, 2026-05-06
- [[Introduction to Claude Skills (claude-cookbooks notebook 01)]] — Anthropic claude-cookbooks, 2026-05-06
- [[Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks, 2026-05-06
