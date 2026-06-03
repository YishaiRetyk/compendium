# Phase 14 — Premise Invalidated (Findings for Re-Plan)

**Status:** Phase 14 execution HALTED at the 14-03 human-verify checkpoint (LINK-10).
**Date:** 2026-06-03
**Verdict:** The phase's core premise is factually wrong. Re-plan required.

---

## TL;DR

Phase 14 (and the whole v1.1.1 "Graph Integrity" milestone) was built on this premise:

> "Obsidian resolves `[[X]]` by filename stem **+ `aliases`**, never by `title`. So adding self-aliases (`aliases ⊇ {title, id}`) will make `[[Exact Page Title]]` links resolve and connect the graph."

**This is false.** Obsidian's link resolver matches a wikilink's target **only against filenames/paths — never against the `aliases` frontmatter**. Aliases are used only for (a) Quick Switcher / autocomplete suggestions and (b) as *display text* in piped links `[[filename|Alias]]`. A bare `[[Exact Page Title]]` will **not** resolve to a note that merely lists "Exact Page Title" in its `aliases`.

Confirmed by an Obsidian moderator for **exactly the user's version (1.12.7)**: *"not a bug… it's how it has always worked and it's an intentional design decision."*
Source: https://forum.obsidian.md/t/wikilink-resolution-does-not-honor-frontmatter-aliases-1-12-7/113902
Official docs: https://obsidian.md/help/aliases ("Obsidian uses the `[[Artificial Intelligence|AI]]` link format" — alias = display text, target = filename).

Net effect: the 53 self-aliases added in 14-03 do **nothing** for graph connectivity. The ~19 multi-word-title pages remain orphans in Obsidian.

---

## Evidence chain (how this was established)

1. After full remediation, `bin/lint.sh --category linkres` reported **0 errors**, but the user's Obsidian graph still showed `domain-driven-design.md` isolated + "many orphans."
2. Faithful emulation of Obsidian resolution + strict-YAML validation proved the **data is correct**: `domain-driven-design.md` has valid frontmatter, 3 self-aliases, real body links, and 10 inbound `[[Domain-Driven Design]]` links.
3. Ruled out (each verified): stale cache (full quit + cold relaunch + mtime bump), invalid YAML, property mis-typing (no `types.json`), name collisions, **86 ghost duplicate pages in 11 abandoned `.claude/worktrees/` dirs** (cleaned up — real fix, kept), Obsidian excluded-files config, quoting.
4. **Decisive test:** clicking `[[Domain-Driven Design]]` in connected `bounded-context.md` → **unresolved/red**. A clean throwaway probe (`[[Probe Unquoted Alpha]]` + `[[Probe Quoted Beta]]` → a note aliased with both) → **neither resolved**. Quick Switcher *did* surface the alias (separate autocomplete path).
5. Orphan math: filename-only resolution → **19 orphans / 51**; filename+alias → 0. The 19 are exactly the multi-word-title pages. Obsidian is doing filename-only resolution.
6. Web research confirmed the behavior is intentional Obsidian design (sources above).

---

## What is now known to be WRONG in the shipped Phase 14 work

| Plan | What it did | Why it's wrong now |
|------|-------------|--------------------|
| 14-01 | "Corrected" AGENTS.md/CLAUDE.md §8 + §5 to say Obsidian resolves `[[X]]` by "filename stem **+ aliases**"; mandated self-alias invariant; authored DR `dr-2026-06-02-obsidian-filename-alias-resolution`; updated 12 templates | The corrected text is **still factually wrong** — it's filename/path **only**, not aliases. §8 rule 4/4a, §5 checklist 18–19, the DR, and the templates all need re-correction. |
| 14-02 | Added `linkres` lint category validating the self-alias invariant + `--fix` self-alias backfill; LINT_VERSION 1.5.0 | Validates a property that does not affect Obsidian resolution. `linkres` must be re-spec'd to check **resolvable link form** (piped or filename-matching), not self-aliases. |
| 14-03 | `--fix` backfilled 53 self-aliases across wiki/ + examples/; hand-edited 10 fixtures; reconciled one body-link variant | Self-aliases are harmless but useless for connectivity. Body links still don't resolve. |

The self-aliases themselves are harmless (valid frontmatter) and can stay or be removed during re-plan.

---

## Viable corrected approaches (the re-plan must choose one)

1. **Piped links `[[slug|Exact Page Title]]`** (recommended; no plugin).
   - Target = slug filename (resolves reliably); display = readable title.
   - Requires **inverting** §8's current "DO NOT use display aliases" rule.
   - Work: rewrite all body `[[Exact Page Title]]` → `[[slug|Exact Page Title]]` across wiki/ + examples/; rewrite §8 convention + §5 + DR + templates with the CORRECT mechanism; re-spec `linkres` to validate resolvable link form; re-run + human-verify.

2. **Bundle a small Obsidian resolver plugin** (keeps existing `[[Exact Page Title]]` + the self-alias work).
   - The forum thread documents a ~30-line plugin that injects `frontmatter.aliases` into `metadataCache.uniqueFileLookup`, making bare `[[Alias]]` resolve.
   - Adds an **unofficial/fragile** plugin dependency (may break on Obsidian updates). Note: "Obsidian plugin distribution" is already a **v1.2-deferred** item per PROJECT.md.

3. **Rename files to titles** — REJECTED in `dr-2026-06-02-obsidian-filename-alias-resolution` (breaks `id == filename`, provenance source IDs, all slug-based tooling).

---

## Recommendation for re-plan

- Re-discuss/re-spec before re-planning: the choice between **piped links** (schema convention change, no dependency) and **bundling a plugin** (no schema change, adds dependency) is a genuine architecture decision for the wiki's linking model.
- Piped links is the more robust, dependency-free path and aligns with the existing `id == filename` convention; it is the default recommendation.
- Whatever is chosen, the §8/§5 convention text, the DR, the templates, and the `linkres` check must be corrected to state the TRUE Obsidian behavior: **`[[X]]` resolves by filename/path only; aliases are display-text + autocomplete, not link targets.**

## Sources
- https://obsidian.md/help/aliases
- https://forum.obsidian.md/t/wikilink-resolution-does-not-honor-frontmatter-aliases-1-12-7/113902
- https://obsidian.md/help/settings (Files and links inventory; "Rebuild vault cache")
