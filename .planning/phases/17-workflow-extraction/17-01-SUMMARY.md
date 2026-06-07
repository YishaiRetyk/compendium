---
phase: "17"
plan: "01"
subsystem: schema
tags: [workflow-extraction, structured-operations, ingest, stub-replacement, sync-claude]
dependency_graph:
  requires: []
  provides:
    - schema/workflows/structured-operations.md
    - schema/workflows/ingest.md (seeded; plan 02 adds step-by-step procedure)
  affects:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
tech_stack:
  added: []
  patterns:
    - D-05 abolish-§N: all cross-file §N/Section N refs converted to file paths
    - D-01: solo structured-op commit prefixes (update:/merge:/supersede:/archive:)
    - Extracted-file skeleton: H1 header + blockquote "this file wins" banner + body + See Also footer
key_files:
  created:
    - schema/workflows/structured-operations.md
    - schema/workflows/ingest.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
decisions:
  - "sync direction is AGENTS.md → CLAUDE.md (not the reverse); edits go to AGENTS.md first"
  - "ingest.md seeded with only the two folded §10 blocks; pass-narrative intentionally excluded (WF-02)"
  - "§13 references in §11 (Workflows section) are intra-file and are allowed; only §9/§10 cross-file refs converted"
metrics:
  duration_minutes: 90
  completed_date: "2026-06-07"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 3
---

# Phase 17 Plan 01: Workflow Extraction (Wave 1 Seeds) Summary

Extract §9 (Structured Operations) and two §10 blocks (Claim Granularity + Append-Then-Synthesize) out of AGENTS.md/CLAUDE.md into dedicated `schema/workflows/` files; replace core sections with compact stubs; verify byte-equality.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Extract §9 body → schema/workflows/structured-operations.md | dc8686e | schema/workflows/structured-operations.md (created) |
| 2 | Fold two §10 blocks → schema/workflows/ingest.md | 1af61ec | schema/workflows/ingest.md (created) |
| 3a | Stub schema/AGENTS.template.md §9/§10 | 769d1ea | schema/AGENTS.template.md (modified) |
| 3b | Stub AGENTS.md + CLAUDE.md §9/§10; sync-claude --check | b8db1ab | AGENTS.md, CLAUDE.md (modified) |

## What Was Built

**schema/workflows/structured-operations.md** (102 lines)
- Relocated verbatim §9 body: Operation Definitions (UPDATE/MERGE/SUPERSEDE/ARCHIVE), Executor Model (5 validation checks), Deterministic Enforcement (validate-op.sh), Per-Op Preconditions/Postconditions
- All cross-file §N references converted per D-05:
  - "Section 10 Pass 3 (Append-Then-Synthesize)" → `schema/workflows/ingest.md`
  - "Section 11.4, Tier 1" → `schema/workflows/reflect.md`, Tier 1
  - "Section 5 validation checklist" → `schema/reference/frontmatter.md`
  - "(§13 asymmetric model)" → `schema/reference/privacy.md`
  - "See Section 12 for log format" → `schema/reference/log-format.md`
  - "see Section 13 and query workflow Section 11.2 privacy rules" → `schema/reference/privacy.md` and `schema/workflows/query.md`
- Header: `# Structured Operations and Executor Model` + "this file wins" blockquote
- Footer: `## See Also` with back-links to AGENTS.md + sibling workflow files

**schema/workflows/ingest.md** (42 lines)
- Seeded with two folded §10 blocks as top-level `##` sections:
  - `## Claim Granularity Rules`: heuristic quote + 4-row granularity table + bias-toward-atomic guidance
  - `## Incremental Update Policy: Append-Then-Synthesize`: 4-point policy + Exceptions + Mantra
- Pass-narrative (Pass 0/1/2/3/4 headers and prose) intentionally excluded per WF-02
- Cross-file §N conversions: "(see Section 6)" → `schema/reference/provenance.md`; "(see Section 11.4)" → `schema/workflows/reflect.md`
- Bridging note marks this as plan-01 seed file (plan 02 adds step-by-step procedure)
- Footer: `## See Also` with back-links to AGENTS.md + sibling workflow files

**AGENTS.md + CLAUDE.md §9 stub** (lines 189-212)
- Ops-vocab table (resident per plan requirement)
- `bin/validate-op.sh` enforcement paragraph (no full executor model)
- Solo-op log compact shape: `## [YYYY-MM-DD] OPERATION | target_page` + one-liner `source: | result: | reason:`; dispatch pointer to `schema/reference/log-format.md`
- D-01 solo-op commit-prefix line: `update(<page>): …` / `merge(<page>): …` / `supersede(<page>): …` / `archive(<page>): …`
- Arrow: `→ Full operation definitions... schema/workflows/structured-operations.md`

**AGENTS.md + CLAUDE.md §10 stub** (lines 214-221)
- Pipeline diagram: `Source -> [Classify] -> [Diff] -> [Extract] -> [Merge] -> [Lint] -> Wiki`
- Arrow: `→ Claim-granularity rules and the Append-Then-Synthesize incremental-update policy live in schema/workflows/ingest.md`

## Deviations from Plan

### Auto-fixed Issues

None - plan executed as written with one clarification.

### Clarification: Sync Direction

The plan said "run bin/sync-claude.sh to mirror CLAUDE.md → AGENTS.md" but the script syncs AGENTS.md → CLAUDE.md. Discovery: `bin/sync-claude.sh` has `SRC=AGENTS.md, DST=CLAUDE.md`. The correct flow is: edit AGENTS.md first, then run `bin/sync-claude.sh` to push to CLAUDE.md. An initial attempt to edit CLAUDE.md directly was undone by the sync. Corrected by applying the stub to AGENTS.md first, then syncing.

## Verification Results

- `bin/sync-claude.sh --check`: `OK: AGENTS.md == CLAUDE.md` (exit 0)
- `bin/check-neutrality.sh`: exit 0 (no private vault terms in template-public files)
- No cross-file §N / Section N refs in §9-§10 stub area of AGENTS.md
- No `### Operation Definitions` heading remaining in AGENTS.md/CLAUDE.md
- No `### Pass 0` heading remaining in AGENTS.md/CLAUDE.md
- `schema/workflows/structured-operations.md` has no cross-file §N refs
- `schema/workflows/ingest.md` has no cross-file §N refs

## Known Stubs

**schema/workflows/ingest.md** is intentionally seeded with only the two reference blocks. The step-by-step ingest procedure (the full §11.1 workflow content) is added by Plan 02 of this phase. The bridging note in the file documents this explicitly.

## Commits

| Hash | Message |
|------|---------|
| dc8686e | feat(17-01): extract §9 body → schema/workflows/structured-operations.md |
| 1af61ec | feat(17-01): seed schema/workflows/ingest.md with folded §10 blocks |
| 769d1ea | feat(17-01): reduce §9 to stub + §10 to diagram; mirror to AGENTS.md + template |
| b8db1ab | chore(17-01): stub §9/§10 in AGENTS.md+CLAUDE.md, confirm sync-claude --check passes |

## Self-Check: PASSED

- schema/workflows/structured-operations.md: FOUND (102 lines)
- schema/workflows/ingest.md: FOUND (42 lines)
- Commit dc8686e: FOUND in git log
- Commit 1af61ec: FOUND in git log
- Commit 769d1ea: FOUND in git log
- Commit b8db1ab: FOUND in git log
- bin/sync-claude.sh --check: exit 0
- bin/check-neutrality.sh: exit 0
