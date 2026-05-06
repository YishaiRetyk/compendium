---
id: agent-skills
title: Agent Skills
type: overview
status: active
summary: "Anthropic's Agent Skills are filesystem-based capability packages — directories of SKILL.md (instructions) plus optional bundled code and reference materials — that Claude loads on demand via three-level progressive disclosure across the Claude API, Claude Code, and Claude.ai. Distinguishes Skills (reusable, on-demand, persisted on filesystem) from prompts (one-conversation instructions)."
created_at: 2026-05-06
updated_at: 2026-05-06
sources:
  - src-2026-05-06-anthropic-agent-skills-overview
  - src-2026-05-06-anthropic-agent-skills-quickstart
  - src-2026-05-06-anthropic-agent-skills-best-practices
epistemic_status: sourced
tags:
  - agent-skills
  - anthropic
  - claude
  - progressive-disclosure
  - filesystem-architecture
  - prompt-engineering
domains:
  - ai-agents
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Anthropic Agent Skills
  - Agent Skill
  - Skill (Anthropic)
  - SKILL.md
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Agent Skills are filesystem-based capability packages: a directory containing a `SKILL.md` instructions file with YAML frontmatter (`name`, `description`) plus optional bundled scripts and reference materials. Claude pre-loads only the metadata into the system prompt at startup (~100 tokens per Skill) and reads the body and bundled files via bash when a request matches the description. This three-level progressive-disclosure model lets Skills include comprehensive references, large datasets, and many utility scripts without context penalty until something is actually read. Skills work across three Anthropic surfaces — the Claude API, Claude Code, and Claude.ai — with surface-specific runtime, sharing, and pre-built/custom rules. Anthropic ships four pre-built Skills (`pptx`, `xlsx`, `docx`, `pdf`) and supports custom Skills via uploads (API, Claude.ai) or filesystem placement (Claude Code).

## Key Facts

- A Skill is a directory containing a `SKILL.md` file with required YAML frontmatter `name` (≤64 chars, lowercase letters/numbers/hyphens, no XML tags, no reserved words `anthropic`/`claude`) and `description` (≤1024 chars, non-empty, no XML tags) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:skill-structure|direct|2026-05-06] [epistemic:: sourced]
- Skills load via three levels of progressive disclosure: L1 metadata always loaded into the system prompt; L2 SKILL.md body read via bash when triggered; L3 bundled files and scripts accessed only when referenced (script source code never enters context, only stdout/stderr) — see [[Progressive Disclosure]] [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:how-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Skills are different from prompts: prompts are conversation-level instructions for one task, Skills are reusable filesystem-based assets that load on demand and eliminate the need to repeatedly provide the same guidance [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:why-use-skills|direct|2026-05-06] [epistemic:: sourced]
- Pre-built Anthropic-managed Skills available are `pptx` (PowerPoint), `xlsx` (Excel), `docx` (Word), and `pdf` (PDF); they are usable on Claude.ai and the Claude API but not auto-mounted in Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:available-skills|direct|2026-05-06] [epistemic:: sourced]
- Surface differences: [[Claude API]] supports pre-built and custom Skills (workspace-wide), invoked via Messages API `container.skills` with three required betas; [[Claude Code]] supports custom Skills only, mounted at `~/.claude/skills/` or `.claude/skills/` and distributable via Plugins; Claude.ai supports pre-built (auto-used for documents) and custom (uploaded as zip via Settings on Pro/Max/Team/Enterprise) [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:where-skills-work|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills do NOT sync across surfaces: API uploads aren't visible on Claude.ai, Claude.ai uploads aren't visible on the API, and Claude Code Skills are filesystem-only and separate from both [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:cross-surface-availability|direct|2026-05-06] [epistemic:: sourced]
- Anthropic publishes an open-source skills repository at github.com/anthropics/skills, including a Claude API skill providing up-to-date API reference material and SDK documentation for 8 programming languages, bundled with Claude Code [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:open-source-skills|direct|2026-05-06] [epistemic:: sourced]
- Authoring guidance: keep SKILL.md body under 500 lines, write `description` in third person with both what+when, keep references one level deep, build at least three evaluations BEFORE writing extensive documentation, and iterate using one Claude instance to author Skills tested by another instance [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:checklist-for-effective-skills|direct|2026-05-06] [epistemic:: sourced]
- Match degrees of freedom to task: high freedom (text-based instructions) when multiple approaches work, medium freedom (parameterized scripts) when a preferred pattern exists, low freedom (specific scripts with no/few flags) when consistency is critical or operations are fragile — analogy: open field vs narrow bridge with cliffs [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:set-appropriate-degrees-of-freedom|direct|2026-05-06] [epistemic:: sourced]
- Agent Skills are NOT covered by Anthropic's Zero Data Retention; data is retained per Anthropic's standard data retention policy [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:data-retention|direct|2026-05-06] [epistemic:: sourced]
- Security guidance: Skills should only come from trusted sources because malicious Skills can direct Claude to invoke tools or execute code outside their stated purpose, with risks including data exfiltration and unauthorized system access; treat Skills like installing software [prov:src-2026-05-06-anthropic-agent-skills-overview#sec:security-considerations|direct|2026-05-06] [epistemic:: sourced]

## Detail

Agent Skills compose three claims into one architecture: (1) a Skill's instructions live as a file on a filesystem (not as a prompt the operator pastes per request); (2) Claude pays attention to a Skill only via [[Progressive Disclosure]] (metadata up front, body on demand, bundled files only as referenced); and (3) the same Skill works the same way across [[Anthropic]]'s three surfaces, modulated only by surface-specific runtime and sharing rules.

### What's in a Skill

The minimum Skill is one `SKILL.md` file:

```yaml
---
name: pdf-processing
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
---

# PDF Processing
...instructions in markdown...
```

A more elaborate Skill bundles additional files: domain-specific reference markdown (FORMS.md, REFERENCE.md), utility scripts (`scripts/fill_form.py`), and reference assets (schemas, datasets, examples). Claude reads bundled markdown via bash on demand, and runs bundled scripts via bash so their source never enters context — only their stdout/stderr does. This is what makes the "no practical limit on bundled content" claim hold: a Skill with comprehensive API documentation, dozens of examples, or a large schema file pays no token cost for content that isn't accessed in a given session.

### Surface differences

The three surfaces deliver Skills differently:

- **Claude API** (see [[Claude API]]): Skills are passed to the Messages API via `container.skills: [{type, skill_id, version}]` alongside `tools: [{type: "code_execution_20250825", name: "code_execution"}]`. Three betas required: `code-execution-2025-08-25`, `skills-2025-10-02`, and `files-api-2025-04-14` (for downloading generated files). Pre-built `skill_id`s are `pptx`, `xlsx`, `docx`, `pdf`; custom Skills are uploaded via `/v1/skills` and shared workspace-wide. Runtime: NO network access, no runtime package installation, only pre-installed packages. Generated files come back as `file_id`s in tool-result blocks and are downloaded via `GET /v1/files/{file_id}/content` [prov:src-2026-05-06-anthropic-agent-skills-quickstart#sec:step-3-download-the-created-file|direct|2026-05-06] [epistemic:: sourced]
- **Claude Code** (see [[Claude Code]]): Custom Skills only. Mounted as plain directories at `~/.claude/skills/` (personal) or `.claude/skills/` (project). Full network access, local package installation. Distributable via Claude Code Plugins. The bundled open-source `claude-api` skill ships here.
- **Claude.ai**: Pre-built Skills work behind the scenes when Claude creates documents. Custom Skills are uploaded as zip files via Settings → Features on Pro, Max, Team, and Enterprise plans with code execution enabled. Custom Skills are individual to each user — no centralized admin or org-wide distribution. Network access varies by user/admin settings.

The non-syncing-across-surfaces rule is operationally important: an organization that wants a Skill available everywhere has to upload it to the API, upload it to Claude.ai, and ship it via a Claude Code Plugin (or per-user filesystem). There's no single source of truth that fans out automatically.

### Authoring (what makes a good Skill)

The authoring guide ([[Anthropic Agent Skills Best Practices]]) is opinionated. Distilled rules:

- **Concise**: cut anything Claude already knows. The body must justify each token because it competes with conversation history and other context.
- **Description does the discovery work**: write in third person, include both what and when, ≤1024 chars. Claude uses it to pick this Skill from potentially 100+ available [prov:src-2026-05-06-anthropic-agent-skills-best-practices#sec:writing-effective-descriptions|direct|2026-05-06] [epistemic:: sourced]
- **Body under 500 lines**: split into bundled files past that. Use one of three progressive-disclosure patterns (high-level-with-references, domain-organization, conditional-details).
- **References one level deep**: never SKILL.md → file-A → file-B chains. Claude may `head -100` deep references and miss content.
- **Match degrees of freedom**: high freedom for code reviews and other context-dependent decisions; low freedom (specific scripts, no flags) for fragile operations like database migrations.
- **Pre-made scripts > regenerated code**: scripts are deterministic, save tokens, save time. Make execution intent explicit: "Run X" vs "See X for the algorithm."
- **Build evals first**: at least three test scenarios before writing extensive docs. Baseline performance without the Skill, then iterate.
- **Avoid time-sensitive content**: instead of "Before August 2025...", document the current method and put deprecated material in a collapsed "Old patterns" section.
- **Use the Claude-A/Claude-B loop**: one Claude instance authors the Skill, another fresh instance tests it on real tasks; observations from B feed back to A.
- **MCP tools need fully-qualified names**: write `BigQuery:bigquery_schema`, not just `bigquery_schema`, to avoid "tool not found" when multiple MCP servers are mounted.
- **Forward slashes only**: `scripts/helper.py`, never `scripts\helper.py`. Unix paths work everywhere.

### Production example

[[Anthropic Financial Services]] is a concrete production-scale Skills deployment: it's a Claude Code plugin marketplace shipping populated SKILL.md prompts (DCF, comps, 3-statement, LBO, merger model, initiating coverage, earnings analysis, model update, tear-sheet) alongside Python validators (e.g., `validate_dcf.py`), Excel templates (e.g., `examples/LBO_Model.xlsx`), and Office-JS integration via `claude-in-office`. It implements the bundle-everything-the-Skill-needs pattern from the authoring guide and uses the [[Claude Code]] surface (with Plugins distribution) rather than the API.

## Related Pages

- [[Anthropic]]
- [[Progressive Disclosure]]
- [[Claude Code]]
- [[Claude API]]
- [[Anthropic Financial Services]]

## Sources

- [[src-2026-05-06-anthropic-agent-skills-overview]]: "Anthropic Agent Skills Overview" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-quickstart]]: "Anthropic Agent Skills Quickstart" (2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-best-practices]]: "Anthropic Agent Skills Best Practices" (2026-05-06)
