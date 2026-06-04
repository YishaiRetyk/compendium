---
id: src-2026-05-06-anthropic-claude-cookbook-skills-custom-development
title: "Building Custom Skills for Claude (claude-cookbooks notebook 03)"
type: source
status: active
summary: "Anthropic's claude-cookbooks Jupyter notebook 03_skills_custom_development.ipynb
  — a hands-on tutorial showing how to author, upload, version, compose, and delete
  custom Agent Skills via the Skills API. Documents the client.beta.skills.create()
  / files_from_dir() upload flow, the display_title workspace-uniqueness constraint,
  the type: 'custom' container.skills discriminator, and skill composition (custom
  + Anthropic skills together in one request)."
created_at: 2026-05-06
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
- agent-skills
- custom-skills
- claude-cookbooks
- anthropic-sdk
- python
- jupyter-notebook
- claude-api
- skill-versioning
domains:
- ai-agents
- software
supersedes: null
superseded_by: null
aliases:
- "claude-cookbooks notebook 03"
- "03_skills_custom_development.ipynb"
- "Building Custom Skills for Claude (claude-cookbooks notebook 03)"
- "src-2026-05-06-anthropic-claude-cookbook-skills-custom-development"
has_contradictions: false
knowledge_domain: software
example: false
path: 
  sources/2026/2026-05/2026-05-06-anthropic-claude-cookbook-skills-custom-development/source.md
url: "https://github.com/anthropics/claude-cookbooks/blob/d28edf1735dc27f3f2d19d17d403b9200dd50934/skills/notebooks/03_skills_custom_development.ipynb"
content_hash: "sha256:46b0a7f41b29bb5e7995c0ffcdb6288e3b6e00e163a519c6566c3e5304a3e261"
ingested_at: 2026-05-06
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:46b0a7f41b29bb5e7995c0ffcdb6288e3b6e00e163a519c6566c3e5304a3e261"
compiled_targets:
- agent-skills
- progressive-disclosure
- claude-api
---

## TL;DR

Anthropic's claude-cookbooks notebook walking through end-to-end custom-Skill authoring against the Skills API. Pins the upload pattern (`client.beta.skills.create(display_title=..., files=files_from_dir(skill_path))` from the `anthropic.lib` helper), the container discriminator (`type: "custom"` vs `"anthropic"`), the workspace-level uniqueness constraint on `display_title` ("cannot reuse an existing display_title"), and the versioning lifecycle via `client.beta.skills.versions.create() / .list() / .delete()`. Documents skill composition: a single `container.skills: [...]` array can mix custom + Anthropic Skills (e.g., a custom brand-guidelines skill + the pre-built `pptx` skill in one request). Reinforces that ALL `.md` files in a Skill's top-level directory are loaded at L2 — not just `SKILL.md` and `REFERENCE.md` — making multi-file documentation a first-class organization pattern.

## Key Takeaways

- Custom Skills are uploaded via `client.beta.skills.create(display_title=..., files=files_from_dir(skill_path))`, where `files_from_dir` is imported from `anthropic.lib` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:api-workflow|direct|2026-05-06] [epistemic:: sourced]
- The `display_title` is workspace-unique — a duplicate raises an error containing the substring "cannot reuse an existing display_title"; remediation is either delete the existing skill or pick a different title [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:financial-ratio-calculator|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills are referenced in `container.skills` with `type: "custom"` (vs `"anthropic"` for Anthropic-managed pre-built Skills) — the discriminator routes the SDK to the right registry [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:api-workflow|direct|2026-05-06] [epistemic:: sourced]
- A single `container.skills` array may mix custom and Anthropic Skills in one request, e.g. `[{"type": "custom", "skill_id": brand_skill_id, "version": "latest"}, {"type": "anthropic", "skill_id": "pptx", "version": "latest"}]` — Skill composition is supported at the API surface, not just at authoring time [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:brand-guidelines|direct|2026-05-06] [epistemic:: sourced]
- The custom-Skill versioning lifecycle is `client.beta.skills.versions.create(skill_id, files=files_from_dir(...))` to create a new version, `versions.list(skill_id=...)` to enumerate, `versions.delete(skill_id, version)` to remove a version, and `client.beta.skills.delete(skill_id)` to remove the skill itself; deletion of a Skill requires deleting all its versions first [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:creating-new-versions|direct|2026-05-06] [epistemic:: sourced]
- A Skill directory contains exactly one required file (`SKILL.md`); everything else (additional `.md` files, `scripts/`, `resources/`) is optional [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:skill-structure|direct|2026-05-06] [epistemic:: sourced]
- ALL `.md` files in the skill's top-level directory are loaded into context when the skill is loaded — not just `SKILL.md` and `REFERENCE.md` — so multi-file documentation (`REFERENCE.md`, `EXAMPLES.md`, `TROUBLESHOOTING.md`, `CHANGELOG.md`, etc.) is a first-class organization pattern at Level 2 [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:additional-documentation-files|direct|2026-05-06] [epistemic:: sourced]
- The cookbook's three example custom Skills illustrate distinct patterns: a calculation skill (Financial Ratio Analyzer with `interpret_ratios.py`), an organizational-standards skill (Corporate Brand Guidelines, demonstrating composition with `pptx`), and a multi-file modeling skill (Financial Modeling Suite with `dcf_model.py`, `sensitivity_analysis.py`, Monte Carlo) [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:financial-modeling|direct|2026-05-06] [epistemic:: sourced]
- Custom Skills are listed via `client.beta.skills.list(source="custom")` (analogous to `source="anthropic"` for pre-built); the response objects expose `id`, `display_title`, `latest_version`, `created_at`, `updated_at`, and `source` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:skill-management-versioning|direct|2026-05-06] [epistemic:: sourced]
- The cookbook's production-tip table for performance optimization recommends: minimal frontmatter (`name` ≤64 chars, `description` ≤1024 chars), lazy loading of reference files, skill composition over a "mega-skill", and container reuse for caching effects [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:performance-optimization|direct|2026-05-06] [epistemic:: sourced]
- Security guidance specific to custom Skills: never hardcode credentials, don't include sensitive data in skill files, Skills are workspace-scoped (so workspace membership is the access boundary), sanitize inputs in scripts, and log skill usage for compliance [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:security-considerations|direct|2026-05-06] [epistemic:: sourced]

## Extracted Claims

- "Skills cannot have duplicate display titles, so you have three options: 1. Delete existing skills (recommended for testing) - Clean slate approach; 2. Use different display titles - Add timestamps or version numbers to names; 3. Update existing skills with new versions" [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:financial-ratio-calculator|direct|2026-05-06]
- "Multiple .md files allowed - You can have any number of markdown files in the top-level folder; All .md files are loaded - Not just SKILL.md and REFERENCE.md, but any .md file you include; Organize as needed - Use multiple .md files to structure complex documentation" [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:skill-structure|direct|2026-05-06]
- "First delete all versions ... Then delete the skill itself" — the `delete_skill` helper iterates over `versions.list().data`, calls `versions.delete(skill_id, version.version)` on each, then calls `skills.delete(skill_id)` last [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:skill-management-versioning|direct|2026-05-06]
- "Combine brand skill with Anthropic's pptx skill" via `container={"skills": [{"type": "custom", "skill_id": brand_skill_id, ...}, {"type": "anthropic", "skill_id": "pptx", ...}]}` [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:brand-guidelines|direct|2026-05-06]
- "Custom skills are specialized expertise packages you create to teach Claude your organization's unique workflows, domain knowledge, and best practices ... Codify organizational knowledge ... Ensure consistency ... Automate complex workflows ... Maintain intellectual property." [prov:src-2026-05-06-anthropic-claude-cookbook-skills-custom-development#sec:introduction-setup|direct|2026-05-06]

## Notes

This source is the SDK-level companion to [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] for the *uploading* and *managing* path, where best-practices is silent. Specifically: best-practices covers SKILL.md authoring (what to write); this notebook covers Skills API operations (how to ship it).

Compiled into [[agent-skills|Agent Skills]] (composition + multi-md-files claims), [[claude-api|Claude API]] (Skills API endpoints, display_title uniqueness, custom-skill type discriminator, versioning lifecycle), and [[progressive-disclosure|Progressive Disclosure]] (the "all .md files load at L2" refinement).

The "all .md files in top-level dir load at L2" claim is a meaningful refinement: the prior wiki Progressive Disclosure page describes Level 2 as "the SKILL.md body" full stop. After this ingest, Level 2 is "all top-level `.md` files in the Skill directory" — SKILL.md is the entry point but not the whole story. The ~5k token budget recommendation thus applies to the *sum* of top-level markdown, not just SKILL.md.

The `display_title` uniqueness constraint is workspace-scoped, which interacts with Skills' workspace-wide sharing (per [[src-2026-05-06-anthropic-agent-skills-overview|Anthropic Agent Skills Overview]]) — two engineers in one workspace cannot upload Skills with the same display_title independently. This is operationally important for team workflows.

The composition pattern (`[custom, anthropic]` in `container.skills`) is the API-level confirmation that Skills are designed to compose, not just to substitute. [[anthropic-financial-services|Anthropic Financial Services]] is a Plugins-distribution example of the same pattern at a different scale.

## Source Metadata

- **Source type:** article (Jupyter notebook tutorial; rendered to source.md from notebook.ipynb in the bundle directory)
- **Authors:** Anthropic (claude-cookbooks repo maintainers)
- **Published:** rolling — captured 2026-05-06; commit `d28edf1735dc27f3f2d19d17d403b9200dd50934` of github.com/anthropics/claude-cookbooks
- **Path:** `sources/2026/2026-05/2026-05-06-anthropic-claude-cookbook-skills-custom-development/source.md` (bundle directory; original `notebook.ipynb` preserved alongside)
- **URL:** https://github.com/anthropics/claude-cookbooks/blob/d28edf1735dc27f3f2d19d17d403b9200dd50934/skills/notebooks/03_skills_custom_development.ipynb
