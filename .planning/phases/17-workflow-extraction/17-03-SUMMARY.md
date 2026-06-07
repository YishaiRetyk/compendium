---
phase: 17-workflow-extraction
plan: "03"
subsystem: schema-extraction
tags: [schema, workflow-extraction, §N-abolition, lint, reflect, brownfield, audit, log-format]
requires: [17-02-SUMMARY.md]
provides: [schema/workflows/lint.md, schema/workflows/reflect.md, schema/workflows/brownfield.md, schema/workflows/release.md, schema/workflows/audit.md, schema/reference/log-format.md]
affects: [AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, docs/reference/agent-parity.md, docs/reference/ci.md, CONTRIBUTING.md]
tech_stack:
  added: []
  patterns: [routing-table stub, dispatch wording, §N abolition, combined lint routing row]
key_files:
  created:
    - schema/workflows/reflect.md
    - schema/workflows/brownfield.md
    - schema/workflows/release.md
    - schema/workflows/audit.md
    - schema/reference/log-format.md
  modified:
    - schema/workflows/lint.md
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - docs/reference/agent-parity.md
    - docs/reference/ci.md
    - CONTRIBUTING.md
    - schema/reference/page-types.md
    - schema/reference/frontmatter.md
    - schema/reference/provenance.md
    - schema/reference/wikilinks.md
    - schema/reference/privacy.md
decisions:
  - "Combined existing decay-only lint.md routing row with new lint-workflow row (one row, not two) to preserve the -eq 1 routing invariant (NEW-HIGH-C)"
  - "Removed orphan CI mode body + duplicate stubs from schema/AGENTS.template.md (partial replacement left both in place)"
  - "Template §N sweep scope: schema/fixtures/ and schema/brownfield/ are out of scope for this plan's §N enforcement"
metrics:
  completed_date: "2026-06-07"
  duration: "~4h (including context-switch recovery)"
  tasks_completed: 5
  files_modified: 13
---

# Phase 17 Plan 03: Workflow Extraction (§11.3–12) Summary

**One-liner:** Extracted §11.3 lint, §11.4 reflect, §11.5 brownfield (182-line), §11.6 release, §11.7 audit, and §12 log-format from AGENTS.md into six `schema/workflows/*.md` and `schema/reference/log-format.md` files; abolished all cross-file §N references across the routing corpus.

## What Was Done

### Task 0: Repoint Phase-16 §N backlinks in schema/ tree
Converted 14 `§N`-in-backlink references in the six existing Phase-16 files (`page-types.md`, `frontmatter.md`, `provenance.md`, `wikilinks.md`, `privacy.md`, `lint.md` footer) to dispatch wording ("The AGENTS.md routing table points here") and path references (`schema/workflows/lint.md`, `schema/workflows/brownfield.md`, etc.). This was the NON-NEGOTIABLE prerequisite for Plan 04's routing guard.

**Commit:** `5ec4e0b`

### Task 1: WF-05 — Merge §11.3 lint body into lint.md + repoint external referrers
Merged the full §11.3 lint workflow body (Severity Tiers, Auto-Fix Boundary, CI mode block with escape-hatch syntax, staged-mode rules, 15-step procedure, Categories, Abort conditions) INTO the existing Phase-16 `schema/workflows/lint.md` seed (which already had the decay/staleness model). The "Source of truth for Phase 9 / Phase 12.2 CI + local-gate contracts" framing line is preserved **verbatim, exactly once** in lint.md. The banner uses a paraphrase (not the verbatim phrase) to avoid duplication.

Also repointed `docs/reference/ci.md` and `CONTRIBUTING.md` §N refs to `schema/workflows/lint.md` and other schema paths.

**Commit:** `654c46e`

### Task 2: WF-06 — Extract §11.4/11.5/11.6/11.7 → four new workflow files
Created four new files:
- `schema/workflows/reflect.md` — full §11.4 body (three-tier reflect model, reflect checkpoint, periodic procedure)
- `schema/workflows/brownfield.md` — full §11.5 body (all five subcommands: scan/bootstrap/suggest/review-typing/verify, `bootstrap_stage` lifecycle, `applied.log` per-script shapes, architectural-boundary table)
- `schema/workflows/release.md` — §11.6 body (orphan-branch publish)
- `schema/workflows/audit.md` — §11.7 body + §1 audit-framing sentence folded in as intro

All cross-file §N references converted to paths. No YAML frontmatter on any file. All use dispatch-wording headers.

**Commit:** `2686b92`

### Task 3: WF-07 — Extract §12 → schema/reference/log-format.md
Created `schema/reference/log-format.md` with the full §12 content (index.md format, log.md format, structured-operation extended log entries + examples, contributor inline field + Dataview block). Added the reciprocal note (review HIGH #3): the blockquote stating the multi-line `source:` / `result:` / `reason:` form is the ONE canonical structured-operation log entry, and the compact core form is a dispatch summary of it. All §N refs converted to paths.

**Commit:** `eab1c4b`

### Task 4: Reduce core §11.3–12 to stubs; delete scaffold; repoint agent-parity; mirror template
- Replaced all §11.3–11.7 and §12 bodies in AGENTS.md with bare-pointer stubs
- Deleted the routing-table scaffold block ("STILL INLINE in §11 until Phase 17")
- Combined the existing decay-only lint.md routing row with the new lint-workflow row (one combined row)
- Added routing-table rows for reflect/structured-operations/brownfield/release/audit/log-format
- Core §N sweep: converted §1 L30/L32 and §2 L67/L98 to paths/prose (zero §N remaining)
- Repointed `docs/reference/agent-parity.md` §4/§5/§6/§11.1/§11.7/§13 to schema/ paths
- Fixed `schema/AGENTS.template.md` (removed orphan CI mode body + duplicate stubs from partial earlier edit)
- Ran `bin/sync-claude.sh` → CLAUDE.md byte-identical to AGENTS.md

**Commit:** `07edea9`

## §N → Path Repoints (complete list)

### AGENTS.md/CLAUDE.md core (Task 4)
| Location | Before | After |
|----------|--------|-------|
| §1 L30 | "defined in Section 11 of this document" | "defined in the workflow files under `schema/workflows/` (see the routing table)" |
| §1 L32 | "(`bin/audit-claims.sh`, Section 11.7)" | "(`bin/audit-claims.sh`, see `schema/workflows/audit.md`)" |
| §2 L67 | "(cloud-safe-only; see §13)" | "(cloud-safe-only; see `schema/reference/privacy.md`)" |
| §2 L98 | "(see `example: true` in Section 5)" | "(see `example: true` in `schema/reference/frontmatter.md`)" |

### Phase-16 schema/ files (Task 0)
All 14 `§N` backlinks in `page-types.md`, `frontmatter.md`, `provenance.md`, `wikilinks.md`, `privacy.md`, `lint.md` converted to dispatch wording and paths.

### External referrers (Tasks 1, 4)
- `docs/reference/ci.md`: §11.3 → `schema/workflows/lint.md`; §6 → `schema/reference/provenance.md`; §13 → `schema/reference/privacy.md`; §4.6/§4.3 → `schema/reference/page-types.md`
- `CONTRIBUTING.md`: §11.3 → `schema/workflows/lint.md`; §11.1 → `schema/workflows/ingest.md`; §13 → `schema/reference/privacy.md`
- `docs/reference/agent-parity.md`: §4/§5/§6/§11.1/§11.7/§13 → respective schema/ paths

### Workflow files (Tasks 2, 3) — cross-file §N in relocated bodies
All "Section N" and `§N` refs in the extracted bodies converted to schema/ file paths. Key conversions: "Section 11.4 Tier-2" → `schema/workflows/reflect.md` Tier-2; "§13 structural predicate" → `schema/reference/privacy.md`; "Lint mechanics (Section 11.3)" → `schema/workflows/lint.md`; "(query-workflow format, §11.2)" → `schema/workflows/query.md`; "(see §11.1 step 9a)" → `schema/workflows/ingest.md` step 9a.

## Final Routing Table Row Inventory

| File | Row count in AGENTS.md/CLAUDE.md |
|------|----------------------------------|
| `schema/workflows/lint.md` | 1 (combined: lint workflow + decay/staleness + CI contract) |
| `schema/workflows/ingest.md` | 1 |
| `schema/workflows/query.md` | 1 |
| `schema/workflows/reflect.md` | 1 |
| `schema/workflows/structured-operations.md` | 1 |
| `schema/workflows/brownfield.md` | 1 |
| `schema/workflows/release.md` | 1 |
| `schema/workflows/audit.md` | 1 |
| `schema/reference/log-format.md` | 1 |
| `schema/reference/page-types.md` | 1 |
| `schema/reference/frontmatter.md` | 1 |
| `schema/reference/provenance.md` | 1 |
| `schema/reference/wikilinks.md` | 1 |
| `schema/reference/privacy.md` | 1 |
| `docs/reference/scaling.md` | 1 |
| `docs/reference/tooling.md` | 1 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Template had orphan CI mode body + duplicate stubs**
- **Found during:** Task 4
- **Issue:** An earlier partial stub replacement in `schema/AGENTS.template.md` left the old CI mode body (flags table, escape-hatch syntax, staged-mode rules, lint steps 1-15) as orphan content after the §11.3 stub, plus a second full set of stubs (§11.4-§12 + `## 13`) as a duplicate. The section structure was: correct stubs at lines 235-261, orphan body at lines 264-339, duplicate stubs at lines 341-365.
- **Fix:** Deleted the orphan block in a single targeted Edit, leaving only the correct stub sequence (§11.3-§15) followed directly by `## 14. Scaling Boundaries`.
- **Files modified:** `schema/AGENTS.template.md`
- **Commit:** `07edea9` (included in Task 4 commit)

## Verification Results

- `bash bin/sync-claude.sh --check` → **exit 0** (AGENTS.md == CLAUDE.md)
- `bash bin/check-neutrality.sh` → **exit 0** (no vault terms in template-public files)
- Corpus §N sweep: `grep -rnE '§[0-9]|Section [0-9]' AGENTS.md CLAUDE.md schema/reference/ schema/workflows/` → **0 lines**
- External referrers: `grep -rn '§[0-9]' docs/reference/ci.md CONTRIBUTING.md docs/reference/agent-parity.md` → **0 lines**
- `grep -c 'Source of truth for Phase 9 / Phase 12.2 CI' schema/workflows/lint.md` → **1** (exact count)
- All 9 workflow/reference routing-table rows: each → **exactly 1** (no duplicates, no missing)
- `grep -c 'Three-Tier Reflect Model' CLAUDE.md` → **0** (§11.4 body moved out)
- `grep -c 'STILL INLINE in §11 until Phase 17' CLAUDE.md` → **0** (scaffold deleted)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 0 | `5ec4e0b` | Repoint Phase-16 §N backlinks in schema/ tree |
| Task 1 | `654c46e` | WF-05 — merge §11.3 lint body + repoint external referrers |
| Task 2 | `2686b92` | WF-06 — extract §11.4/11.5/11.6/11.7 → workflow files |
| Task 3 | `eab1c4b` | WF-07 — extract §12 → log-format.md |
| Task 4 | `07edea9` | Reduce §11.3-12 to stubs; delete scaffold; repoint; mirror |

## Known Stubs

None. All stubs created in AGENTS.md/CLAUDE.md intentionally point to their extracted authoritative files. No stub prevents the plan's goal from being achieved.

## Threat Flags

None. The relocated brownfield/audit bodies contain abstract schema/tooling prose only; `check-neutrality.sh` exits 0.

## Self-Check: PASSED

- `schema/workflows/lint.md` → FOUND
- `schema/workflows/reflect.md` → FOUND
- `schema/workflows/brownfield.md` → FOUND
- `schema/workflows/release.md` → FOUND
- `schema/workflows/audit.md` → FOUND
- `schema/reference/log-format.md` → FOUND
- All 5 task commits exist in git log (5ec4e0b, 654c46e, 2686b92, eab1c4b, 07edea9)
- AGENTS.md == CLAUDE.md (sync-claude --check exit 0)
- Zero §N in corpus (grep returns 0 lines)
