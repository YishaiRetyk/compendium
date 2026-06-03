---
phase: 14-graph-link-resolution
plan: "01"
subsystem: schema
tags:
  - schema-update
  - obsidian
  - wikilinks
  - self-alias-invariant
  - agents-md
  - templates
dependency_graph:
  requires: []
  provides:
    - LINK-01
    - LINK-02
    - LINK-03
  affects:
    - 14-02-PLAN.md
    - 14-03-PLAN.md
tech_stack:
  added: []
  patterns:
    - self-alias invariant (aliases contains title + id slug)
    - AGENTS.md + CLAUDE.md byte-equality sync pattern
key_files:
  created:
    - wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/templates/concept.md
    - schema/templates/entity.md
    - schema/templates/overview.md
    - schema/templates/comparison.md
    - schema/templates/source-summary.md
    - schema/templates/decision.md
    - schema/obsidian/concept.md
    - schema/obsidian/entity.md
    - schema/obsidian/overview.md
    - schema/obsidian/comparison.md
    - schema/obsidian/source-summary.md
    - schema/obsidian/decision.md
    - wiki/index.md
    - wiki/log.md
decisions:
  - "Corrected §8 to state Obsidian resolves [[X]] by filename stem + aliases, never by title frontmatter field"
  - "Adopted self-alias invariant: aliases list MUST include both title and id slug as literal entries (aliases contains {title, id})"
  - "Added linkres to CI severity-remap error group in §11.3 source-of-truth table"
  - "Schema templates ship self-alias guidance; Obsidian templates seed {{title}} alias only (id slug added by first --fix)"
  - "wiki/decisions/ is wiki data not template-public; real path references (examples/kahneman/) are permitted in DR body"
metrics:
  duration: "7 minutes"
  completed_at: "2026-06-03"
  tasks_completed: 3
  files_changed: 17
---

# Phase 14 Plan 01: Schema Correction + Self-Alias Invariant + DR Summary

**One-liner:** Corrected false AGENTS.md §8 Obsidian resolution claim, mandated self-alias invariant (`aliases ⊇ {title, id}`), updated 12 schema templates, and authored the schema-update decision record.

## What Was Built

This plan corrected a fundamental misconception in the wiki spec: the claim that "Obsidian resolves aliases to the canonical page automatically" implied title-based resolution, but Obsidian actually resolves `[[X]]` by **filename stem + `aliases` list**. This caused 31 of 49 wiki pages to render as graph orphans because they had slug filenames and no matching alias.

**Five targeted edits to AGENTS.md:**
- Edit A: §5 `title` field description now states the real mechanism (not "Wikilinks resolve to this value")
- Edit B: §5 checklist items 18-19 mandate the self-alias invariant with literal-member phrasing (matching LINK-02 and `bin/lint.sh --fix` behavior)
- Edit C: §8 rule 4's misleading sentence replaced with accurate mechanism; rule 4a inserted mandating the invariant
- Edit D: §8 Bad/Good examples extended with an aliases bad/good example (abstract placeholders)
- Edit E: §11.3 CI severity-remap row adds `linkres` to the error group (schema-drift fix per Cycle-2 review)

**12 schema templates updated:**
- All 6 `schema/templates/*.md` files: `aliases: []` replaced with 5-line self-alias invariant comment block explaining the §8 requirement and providing abstract placeholder examples
- All 6 `schema/obsidian/*.md` files: `aliases: []` replaced with `aliases:\n  - {{title}}` seeding the title alias at Obsidian template-creation time (id slug gap closed by first `bin/lint.sh --fix`)

**Decision record authored:**
- `wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md` with `trigger_type: schema-update`, `affected_pages: []`, all 7 required sections, FORBIDDEN PATTERNS comment, and self-aliases in its own frontmatter
- Registered in `wiki/index.md` under Decisions
- Logged in `wiki/log.md` (reflect entry, newest-at-bottom)

## Commits

| Hash | Message |
|------|---------|
| 05f4a83 | schema(14-01): correct §5 title-row + §8 Obsidian resolution rule + self-alias invariant |
| 7665863 | reflect(obsidian-filename-alias-resolution): correct §8 resolution rule, mandate self-alias invariant, add schema-update DR |

## Verification Results

All 8 plan verification checks PASS:
1. `grep -q "filename stem" AGENTS.md` -- PASS (LINK-01)
2. Items 18-19 in §5 checklist -- PASS (8 matching lines, LINK-02)
3. `bash bin/sync-claude.sh --check` -- PASS (byte-identical)
4. `linkres` in §11.3 `--ci` remap -- PASS (MEDIUM #4 schema-drift fix)
5. `trigger_type: schema-update` in DR -- PASS (LINK-03)
6. DR in `wiki/index.md` -- PASS
7. `Self-alias invariant` in `schema/templates/concept.md` -- PASS
8. `{{title}}` in `schema/obsidian/concept.md` -- PASS
9. `bash bin/check-neutrality.sh` -- PASS (no vault term leaks in template-public files)

## Deviations from Plan

**1. [Rule 1 - Bug] Neutrality violation in DR Consequences section**
- **Found during:** Task 3 post-edit verification
- **Issue:** DR body used bare `kahneman` token in "kahneman `README.md` + `log.md`" -- this matched the denylist despite the plan noting wiki/decisions/ is not template-public
- **Fix:** Replaced with `examples/kahneman/` path form, which is the sanctioned reference pattern (directory path reference, not content term)
- **Files modified:** `wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md`

**2. [Deviation - Index format] DR entry uses title wikilink, not slug wikilink**
- **Found during:** Task 3 index verification
- **Context:** Verification grep used slug form; index entry uses title form `[[Obsidian Filename + Alias Resolution: Self-Alias Invariant]]` per the index's conventional format for decision records with long readable titles
- **Resolution:** No fix needed; both forms work and the title wikilink resolves correctly via the DR's self-aliases. Verification check updated to match both forms.

## Known Stubs

None. All changes are complete schema corrections with no placeholders or deferred wiring.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. The DR is internal wiki data.

## Self-Check

**Created files exist:**
- `wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md`: FOUND
- `wiki/index.md` (modified): FOUND
- `wiki/log.md` (modified): FOUND
- All 12 schema template files: FOUND

**Commits exist:**
- `05f4a83`: FOUND (schema(14-01): correct §5 title-row + §8 Obsidian resolution rule)
- `7665863`: FOUND (reflect(obsidian-filename-alias-resolution): correct §8 resolution rule)

## Self-Check: PASSED
