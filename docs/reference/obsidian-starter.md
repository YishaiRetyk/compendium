# Obsidian Starter

> Reference documentation for the minimal Obsidian page-creation starter: six token-ized page-type templates under `schema/obsidian/`, what auto-fills on insert, and the one-time vault setup.

## TL;DR

- Ships six plain-markdown page-type templates under `schema/obsidian/` (`entity`, `concept`, `source-summary`, `comparison`, `overview`, `decision`) — token-ized counterparts of the canonical `schema/templates/` siblings, with zero field or section drift.
- Uses Obsidian's built-in **Templates *core*** plugin (no community-plugin install). On insert, `title`, `created_at`, and `updated_at` auto-fill via the `{{title}}` / `{{date:YYYY-MM-DD}}` tokens.
- You still hand-type `id`, `summary`, `tags`, `privacy`, and `epistemic_status` (plus the source/decision-specific fields).
- **Page-creation ergonomics ONLY.** No dashboards, Dataview views, hotkey bundles, or custom CSS/themes ship here.
- The starter never edits your `.obsidian/` config — you wire the template folder once in your own vault.

> **Source of truth:** The authoritative Obsidian tooling guidance lives in [AGENTS.md §15](../../AGENTS.md) (Obsidian integration) and the frontmatter schema in [AGENTS.md §5](../../AGENTS.md). This page reproduces them for ergonomic reference — if you find a discrepancy, §15 / §5 win and this page is the bug.

## Setup (once)

The starter is files-only: it ships the markdown templates under `schema/obsidian/` and this doc. It does **not** mutate your committed `.obsidian/` config (no `core-plugins.json` edit, no template-folder setting). You point Obsidian at the folder once, in your own vault:

1. Open **Settings → Core plugins** and enable **Templates** (the built-in core plugin — not the community "Templater" plugin).
2. Open **Settings → Templates** and set **Template folder location** to `schema/obsidian`.
3. (Optional) Bind a hotkey to **Templates: Insert template** under **Settings → Hotkeys**, or use the command palette.

To create a schema-correct page: create a new note, give it the page title, then **Insert template** and pick the page type. The `{{title}}` and `{{date:YYYY-MM-DD}}` tokens resolve on insert. Fill the remaining hand-typed fields (below).

This works identically for a fresh-starter vault and a brownfield vault with existing content — because the starter presumes nothing about your folder layout, the wiring is a one-time per-vault step rather than pre-baked config (D-03).

## What auto-fills vs what you type

**Auto-fills on insert (via Templates-core tokens):**

| Field | Token | Notes |
|-------|-------|-------|
| `title` | `{{title}}` | Resolves to the note's filename/title. |
| `created_at` | `{{date:YYYY-MM-DD}}` | ISO 8601 date, pinned per AGENTS.md §3. |
| `updated_at` | `{{date:YYYY-MM-DD}}` | Same insert-date default; bump on later edits. |

**You hand-type (left empty in the template):**

- `id` — kebab-case identifier, must match the filename without `.md` (AGENTS.md §5).
- `summary` — one-sentence index/scan description.
- `tags` — flat list for Dataview queries.
- `privacy` — `local_only` or `cloud_safe` (fail-closed: when in doubt, `local_only`).
- `epistemic_status` — `sourced` / `mixed` / `tentative` / `stale`.

**Source-summary and decision specifics:**

- `source-summary.md` carries the source tail (`path`, `url`, `content_hash`, `ingested_at`, `source_type`, `compilation_status`, `compiled_against_hash`, `compiled_targets`). These are populated by the ingest workflow, **not** at template-insert time, so they are not token-ized.
- `decision.md` is the only template with non-empty defaults (`epistemic_status: sourced`, `privacy: cloud_safe`) and the extra fields `has_contradictions`, `knowledge_domain`, `trigger_type`, `affected_pages`. You fill `trigger_type` and `affected_pages` per the decision you are recording (AGENTS.md §4.6).

## Scope

This starter is page-creation ergonomics **only**. It deliberately does **not** ship:

- dashboards or home/index notes,
- workflow-specific Dataview surfaces or saved views,
- hotkey bundles,
- custom CSS snippets or themes,
- prescribed review workflows (GTD or otherwise).

Those are out of scope (OBSID-03) and deferred to backlog Phase 999.6 (Observed GTD Review Patterns) until observed practice justifies them. The templates contain only empty fields, the two auto-fill tokens, and the canonical guidance comments — no concrete content.

## See also

- [AGENTS.md](../../AGENTS.md) — canonical schema (§5 frontmatter, §15 Obsidian tooling).
- [../README.md](../README.md) — project entry point.
- [index.md](index.md) — reference-doc catalog.
