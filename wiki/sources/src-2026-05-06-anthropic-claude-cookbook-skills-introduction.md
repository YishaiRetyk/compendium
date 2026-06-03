---
id: src-2026-05-06-anthropic-claude-cookbook-skills-introduction
title: "Introduction to Claude Skills (claude-cookbooks notebook 01)"
type: source
status: active
summary: "Anthropic's claude-cookbooks Jupyter notebook 01_skills_introduction.ipynb — a hands-on tutorial showing how to invoke pre-built Anthropic-managed Skills (xlsx, pptx, pdf) via the Python SDK using client.beta.messages.create() with the betas= parameter, and how to download generated files via the Files API. Adds concrete SDK invocation patterns, observed generation times, and required SDK version (anthropic >= 0.71.0) on top of the platform Quickstart doc."
created_at: 2026-05-06
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
  - agent-skills
  - claude-cookbooks
  - anthropic-sdk
  - python
  - jupyter-notebook
  - claude-api
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "claude-cookbooks notebook 01"
  - "01_skills_introduction.ipynb"
  - "Introduction to Claude Skills (claude-cookbooks notebook 01)"
  - "src-2026-05-06-anthropic-claude-cookbook-skills-introduction"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-06-anthropic-claude-cookbook-skills-introduction/source.md
url: "https://github.com/anthropics/claude-cookbooks/blob/d28edf1735dc27f3f2d19d17d403b9200dd50934/skills/notebooks/01_skills_introduction.ipynb"
content_hash: "sha256:2e4798d65b8e6aff83c92f6c30fd3f1a17775addeabf0d36ebd0d7ce18ba65f1"
ingested_at: 2026-05-06
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:2e4798d65b8e6aff83c92f6c30fd3f1a17775addeabf0d36ebd0d7ce18ba65f1"
compiled_targets:
  - agent-skills
  - progressive-disclosure
  - claude-api
---

## TL;DR

Anthropic's claude-cookbooks notebook walking through the use of pre-built Skills via the Python SDK. Operationalizes the platform Quickstart doc with three concrete details: (1) the SDK call must be `client.beta.messages.create()` (the non-beta `client.messages.create()` does NOT accept the `container` parameter); (2) beta features are passed via the `betas=` parameter (NOT via `extra_headers`), and a Skills call needs all three of `code-execution-2025-08-25`, `files-api-2025-04-14`, and `skills-2025-10-02`; (3) listing Skills via the SDK requires the `anthropic-beta: skills-2025-10-02` default header, e.g. `Anthropic(api_key=..., default_headers={"anthropic-beta": "skills-2025-10-02"})`. Documents observed end-to-end generation times — Excel ~1-2 min, PowerPoint ~1-2 min, PDF ~40-60 s — and the requirement that the code-execution tool MUST be included in any Skills request (else `BadRequestError: Skills beta requires the code_execution tool`). Recommends container reuse via `container.id` as a token-optimization pattern.

## Key Takeaways

- The Python SDK call shape for Skills is `client.beta.messages.create(...)` — `client.messages.create(...)` does NOT accept the `container` parameter and raises `TypeError: Messages.create() got an unexpected keyword argument 'container'` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-container-parameter|direct|2026-05-06] [epistemic:: sourced]
- Beta features are passed via the `betas=[...]` parameter on the SDK call, NOT via `extra_headers` — a Skills call needs all three: `code-execution-2025-08-25`, `files-api-2025-04-14`, `skills-2025-10-02` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:how-skills-work-with-code-execution|direct|2026-05-06] [epistemic:: sourced]
- Listing Skills via the SDK requires the Skills beta header on the client, e.g. `Anthropic(api_key=..., default_headers={"anthropic-beta": "skills-2025-10-02"})`, then call `client.beta.skills.list(source="anthropic")` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:discovering-available-skills|direct|2026-05-06] [epistemic:: sourced]
- The required Anthropic Python SDK version for Skills support is 0.71.0 or later — older versions don't support `client.beta.messages.create()`-with-container and need `pip install anthropic>=0.71.0` followed by a kernel restart [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:setup-installation|direct|2026-05-06] [epistemic:: sourced]
- The notebook's default model environment variable is `claude-sonnet-4-6` (`os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-6")`) — a documented departure from the platform Quickstart's `claude-opus-4-7` examples [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:setup-installation|direct|2026-05-06] [epistemic:: sourced]
- Skills require the `code_execution_20250825` tool; omitting it produces `BadRequestError: Skills beta requires the code_execution tool to be included in the request` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-code-execution|direct|2026-05-06] [epistemic:: sourced]
- Observed generation times — Excel ~1-2 minutes (with charts and formatting), PowerPoint ~1-2 minutes (simple 2-slide presentations with charts), PDF ~40-60 seconds (simple documents) — concrete planning numbers for sync-call timeouts and UI loading states [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:expected-generation-times|direct|2026-05-06] [epistemic:: sourced]
- Files generated by a Skill have a "limited lifetime on Anthropic's servers" — the cookbook recommends downloading immediately after creation rather than later [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-file-download|direct|2026-05-06] [epistemic:: sourced]
- Token-optimization recommendation: reuse containers across requests via the `container.id` returned from a previous response, to avoid reloading skills on each call [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-optimization-tips|direct|2026-05-06] [epistemic:: sourced]
- The `client.beta.skills.versions.retrieve(skill_id, version)` call returns the skill's `name` and `description` fields — the metadata Claude sees at Level 1 of progressive disclosure [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:discovering-available-skills|direct|2026-05-06] [epistemic:: sourced]
- The cookbook frames Skills as "expertise packages" that are higher-level than individual tools, composable across requests, efficient via progressive disclosure, and bundling proven helper scripts that work reliably — explicit positioning vs MCP and tool-use [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:why-skills-matter|direct|2026-05-06] [epistemic:: sourced]

## Extracted Claims

- "Use `client.beta.messages.create()` (not `client.messages.create()`); The `container` parameter is only available in the beta API; Use the `betas` parameter to enable beta features: `code-execution-2025-08-25` - Enables code execution; `files-api-2025-04-14` - Required for downloading files; `skills-2025-10-02` - Enables Skills feature." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:how-skills-work-with-code-execution|direct|2026-05-06]
- "If anthropic SDK version is too old (needs 0.71.0 or later): pip install anthropic>=0.71.0; Then restart the Jupyter kernel to pick up the new version." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:setup-installation|direct|2026-05-06]
- "Excel files: ~2 minutes (with charts and formatting); PowerPoint presentations: ~1-2 minutes (simple 2-slide presentations with charts); PDF documents: ~40-60 seconds (simple documents)" [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:expected-generation-times|direct|2026-05-06]
- "Files may have a limited lifetime on Anthropic's servers; Download files immediately after creation; Check file_id is correctly extracted from response; Verify Files API beta is included in betas list." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-file-download|direct|2026-05-06]
- "Reuse containers - Use `container.id` from previous responses to avoid reloading skills." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:token-optimization-tips|direct|2026-05-06]
- "Skills are higher-level than individual tools - they combine instructions, code, and resources; Skills are composable - multiple skills work together seamlessly; Skills are efficient - progressive disclosure means you only pay for what you use; Skills include proven code - helper scripts that work reliably." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:why-skills-matter|direct|2026-05-06]
- "Skills beta requires the code_execution tool to be included in the request." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-introduction#sec:troubleshooting-code-execution|direct|2026-05-06]

## Notes

This source is the SDK-level companion to [[src-2026-05-06-anthropic-agent-skills-quickstart|Anthropic Agent Skills Quickstart]]. The platform doc establishes the request body shape and beta headers abstractly; this cookbook pins the exact SDK call (`client.beta.messages.create()`), the required SDK version (0.71.0+), and the parameter name (`betas=`, not `extra_headers`) — all operational facts that the platform doc leaves implicit because it shows `cURL`/CLI/Python/TypeScript variants side-by-side.

Compiled into [[agent-skills|Agent Skills]], [[claude-api|Claude API]], and the [[progressive-disclosure|Progressive Disclosure]] concept (the listing API exposes only L1 metadata).

The cookbook's "98% savings applies to the initial context. Once you use a skill, the full instructions are loaded" disclaimer is a useful refinement of the prior wiki claim about progressive disclosure — the savings come from L1 only; once L2 fires, the body's full ~5k tokens load. Not a contradiction; a clarification.

Adjacent existing wiki: the cookbook's framing of Skills as "expertise packages" higher-level than tools/MCP is consistent with [[agent-skills|Agent Skills]] but adds an explicit positioning vs the MCP/tool-use ecosystem that the platform docs don't make explicit.

## Source Metadata

- **Source type:** article (Jupyter notebook tutorial; rendered to source.md from notebook.ipynb in the bundle directory)
- **Authors:** Anthropic (claude-cookbooks repo maintainers)
- **Published:** rolling — captured 2026-05-06; commit `d28edf1735dc27f3f2d19d17d403b9200dd50934` of github.com/anthropics/claude-cookbooks
- **Path:** `sources/2026/2026-05/2026-05-06-anthropic-claude-cookbook-skills-introduction/source.md` (bundle directory; original `notebook.ipynb` preserved alongside)
- **URL:** https://github.com/anthropics/claude-cookbooks/blob/d28edf1735dc27f3f2d19d17d403b9200dd50934/skills/notebooks/01_skills_introduction.ipynb
