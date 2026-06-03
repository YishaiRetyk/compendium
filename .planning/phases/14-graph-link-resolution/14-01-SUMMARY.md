---
phase: 14-graph-link-resolution
plan: "01"
subsystem: schema
tags:
  - schema-update
  - wikilink-convention
  - obsidian
  - piped-links
dependency_graph:
  requires: []
  provides:
    - corrected-CLAUDE.md-§8-piped-link-convention
    - corrected-AGENTS.md-byte-identical
    - schema-templates-piped-link-guidance
    - DR-dr-2026-06-03-uniform-piped-links
  affects:
    - wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution
    - wiki/index.md
    - wiki/log.md
tech_stack:
  added: []
  patterns:
    - "uniform piped links [[id|Title]] (target=id, display=title)"
    - "§5 validation checklist item 18: piped-link mandate"
    - "FORBIDDEN PATTERNS comments updated in all 12 templates"
key_files:
  created:
    - wiki/decisions/dr-2026-06-03-uniform-piped-links.md
  modified:
    - CLAUDE.md
    - AGENTS.md
    - schema/AGENTS.template.md
    - schema/templates/entity.md
    - schema/templates/concept.md
    - schema/templates/overview.md
    - schema/templates/comparison.md
    - schema/templates/source-summary.md
    - schema/templates/decision.md
    - schema/obsidian/entity.md
    - schema/obsidian/concept.md
    - schema/obsidian/overview.md
    - schema/obsidian/comparison.md
    - schema/obsidian/source-summary.md
    - schema/obsidian/decision.md
    - wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md
    - wiki/index.md
    - wiki/log.md
decisions:
  - "Removed self-alias invariant (items 18-19 in §5 checklist); replaced with single piped-link mandate (new item 18)"
  - "Updated §8 rules to mandate [[id|Exact Title]] and correctly state filename/path ONLY resolution"
  - "New DR dr-2026-06-03-uniform-piped-links supersedes dr-2026-06-02 (wrong premise)"
  - "All literal [[...]] examples in live wiki/ prose are backtick-wrapped (Step E scanner passes)"
metrics:
  duration: "12 minutes"
  completed: "2026-06-03"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 18
---

# Phase 14 Plan 01: Correct Obsidian Link Resolution Convention Summary

Corrects CLAUDE.md/AGENTS.md §8/§5 from the false "filename stem + aliases" premise to the real Obsidian resolution mechanism (filename/path ONLY), mandates uniform piped links `[[id|Title]]`, removes the self-alias invariant, and supersedes the wrong-premise decision record.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Correct CLAUDE.md §8/§5 to piped-link convention | c857259 | CLAUDE.md |
| 2 | Mirror §5/§8 edits into schema/AGENTS.template.md + all templates + sync AGENTS.md | daf6f2d | 14 files (AGENTS.md, AGENTS.template.md, 6 schema/templates, 6 schema/obsidian) |
| 3 | Author superseding DR and mark old DR superseded | 053c58b | 4 files (new DR, old DR, index.md, log.md) |

## What Was Built

**CLAUDE.md / AGENTS.md corrections (§3, §5, §8, §15, §16):**
- §3 MUST NOT list: `DO NOT write bare [[Title]]` with `ALWAYS write [[id|Exact Title]]` mandate
- §5 `title` field description: corrected resolution claim to "filename/path ONLY"
- §5 `aliases` field description: marked OPTIONAL, no longer a resolution mechanism
- §5 checklist: removed self-alias invariant items 18-19; added piped-link mandate as item 18
- §8 rules: replaced 8 old rules (with self-alias invariant rule 4a) with 8 new rules mandating `[[id|Title]]`
- §8 bad/good examples: piped form is GOOD, bare `[[Title]]` is BAD; all examples use fictional slugs or abstract placeholders
- §8 graph implications: updated to reflect piped-link architecture
- §15 Obsidian section: Graph View and Aliases bullets corrected
- §16 quick reference item 3: updated to piped form

**Schema template updates (12 files):**
- All 6 `schema/templates/*.md`: removed self-alias comment block in `aliases:` frontmatter; FORBIDDEN PATTERNS updated to piped-link mandate; Related Pages/Sources comments updated
- All 6 `schema/obsidian/*.md`: FORBIDDEN PATTERNS updated to piped-link mandate; Sources comments updated

**Decision record lifecycle:**
- New DR `dr-2026-06-03-uniform-piped-links.md` created with all 7 required sections, `trigger_type: schema-update`, `supersedes: dr-2026-06-02-obsidian-filename-alias-resolution`
- Old DR `dr-2026-06-02-obsidian-filename-alias-resolution.md`: `status: superseded`, `superseded_by` set, redirect note added with correctly backtick-wrapped literal `[[X]]` example
- `wiki/index.md`: new DR added with backtick-wrapped literal `[[id|Title]]` in summary prose

## Verification Results

All acceptance criteria met:

- `grep -c "filename/path ONLY" CLAUDE.md` = 4 (>= 3 required) ✓
- `grep -c "self-alias invariant" CLAUDE.md` = 0 ✓
- `grep -c "title is a literal member of aliases" CLAUDE.md` = 0 ✓
- `grep -c "id slug is a literal member of aliases" CLAUDE.md` = 0 ✓
- `grep -c "DO NOT use display aliases" CLAUDE.md` = 0 ✓
- `grep -c "DO NOT write bare" CLAUDE.md` = 1 ✓
- `grep -c "bounded-context|hack-agentive-stack" CLAUDE.md` = 0 ✓ (no real vault slugs in template-public prose)
- `bash bin/sync-claude.sh --check` exits 0 — AGENTS.md byte-identical ✓
- `bash tests/phase-10/test_agents_template_parity_section_5.sh` exits 0 ✓
- `bash tests/phase-09.1/test_template_parity.sh` exits 0 ✓
- `grep -r "Self-alias invariant" schema/templates/ schema/obsidian/` = 0 hits ✓
- `awk '/^---$/{c++} c==1 && /\[\[/{print}' wiki/decisions/dr-2026-06-03-uniform-piped-links.md` = 0 lines (no wikilinks in frontmatter) ✓
- `grep -F '`[[X]]`' wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md` >= 1 ✓ (literal backtick-wrapped)
- `grep -F '`[[id|Title]]`' wiki/index.md` = 1 ✓ (literal backtick-wrapped in DR summary)
- Step E unmasked-literal scanner over DR files and index = no findings ✓

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CLAUDE.md overwritten by sync-claude.sh during Task 2**
- **Found during:** Task 2 Step D (sync AGENTS.md)
- **Issue:** `bin/sync-claude.sh` copies AGENTS.md → CLAUDE.md (not the reverse). Running it without first copying CLAUDE.md → AGENTS.md overwrote the Task 1 edits with the old AGENTS.md content.
- **Fix:** Restored CLAUDE.md from the Task 1 commit using `git show c857259:CLAUDE.md`, then manually copied CLAUDE.md → AGENTS.md before re-running the sync check.
- **Files modified:** CLAUDE.md, AGENTS.md
- **Commit:** daf6f2d

**2. [Rule 2 - Missing critical functionality] FORBIDDEN PATTERNS comments in DR bodies needed backtick-wrapping**
- **Found during:** Task 3 Step E unmasked-literal scanner
- **Issue:** The `No bare [[Title]] links: ALWAYS write [[id|Exact Title]]` FORBIDDEN PATTERNS comment text in both DRs contained literal `[[Title]]` and `[[id|Exact Title]]` that matched the scanner's pattern for unmasked examples.
- **Fix:** Wrapped these HTML comment examples in backticks: `[[Title]]` → `` `[[Title]]` `` and `[[id|Exact Title]]` → `` `[[id|Exact Title]]` ``.
- **Files modified:** wiki/decisions/dr-2026-06-03-uniform-piped-links.md, wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md

**Pre-existing out-of-scope issue:** `wiki/log.md` line 287 contains an unbackticked `[[X]]` in a historical log entry from the prior Phase 14 run. This is pre-existing content that this plan did not author; modifying historical log entries violates the append-only rule (§10 Pass 3 "Logs and source summary pages: Strict append-only"). Documented here for Wave 2 awareness.

## Known Stubs

None. All content is complete and wired.

## Threat Flags

None. No new network endpoints, auth paths, or trust-boundary changes introduced.

## Self-Check: PASSED

Files verified:
- CLAUDE.md: exists ✓
- AGENTS.md: exists, byte-identical to CLAUDE.md ✓
- schema/AGENTS.template.md: exists, §5 parity passes ✓
- wiki/decisions/dr-2026-06-03-uniform-piped-links.md: exists ✓
- wiki/decisions/dr-2026-06-02-obsidian-filename-alias-resolution.md: updated ✓
- wiki/index.md: has new DR entry ✓
- wiki/log.md: has new reflect entry ✓

Commits verified:
- c857259: schema(14-01): correct CLAUDE.md §8/§5 to piped-link convention ✓
- daf6f2d: schema(14-01): mirror §5/§8 piped-link edits into template + sync AGENTS.md ✓
- 053c58b: reflect(14-01): add superseding DR for piped-link convention; mark old DR superseded ✓
