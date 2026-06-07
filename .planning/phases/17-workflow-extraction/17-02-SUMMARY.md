---
phase: 17-workflow-extraction
plan: "02"
subsystem: schema-architecture
tags: [workflow-extraction, ingest, query, routing-table, claude-md, agents-md]
dependency_graph:
  requires: [17-01]
  provides: [schema/workflows/ingest.md, schema/workflows/query.md]
  affects: [CLAUDE.md, AGENTS.md, schema/AGENTS.template.md]
tech_stack:
  added: []
  patterns: [extracted-reference-file, routing-stub, dispatch-pointer, verbatim-relocation, §N-to-path-conversion]
key_files:
  created:
    - schema/workflows/query.md
  modified:
    - schema/workflows/ingest.md
    - CLAUDE.md
    - AGENTS.md
    - schema/AGENTS.template.md
decisions:
  - WF-03 ingest.md completed: full §11.1 procedure prepended above Plan-01 folded §10 blocks; bridging note removed
  - WF-04 query.md created: full §11.2 body relocated verbatim; write-back-mandatory line kept as sole §11.2 resident
  - Routing table promoted: ingest + query rows moved from STILL-INLINE scaffold to main Resolvable References table (blockquote-prefixed)
  - §N-to-path conversions applied throughout both workflow files (zero cross-file §N remain)
metrics:
  duration: "~15min"
  completed: "2026-06-07"
  tasks: 3
  files_modified: 5
---

# Phase 17 Plan 02: Workflow Extraction (Ingest + Query) Summary

Full §11.1 ingest workflow and §11.2 query workflow extracted into `schema/workflows/ingest.md` and `schema/workflows/query.md`; core §11.1/§11.2 reduced to pointer stubs; routing table promoted; CLAUDE.md ≡ AGENTS.md ≡ template.

## What Was Done

### Task 1: Complete schema/workflows/ingest.md

The Plan-01 seed file (`schema/workflows/ingest.md`) held only the two folded §10 reference blocks and a bridging note. This task prepended the full §11.1 ingest workflow procedure above those blocks:

- **Removed** the Plan-01 bridging note ("> **Note:** The step-by-step ingest procedure is added by Plan 02...")
- **Inserted** the full §11.1 body: `Trigger/Inputs/Outputs/Commit` fenced block + steps 1–10 (including 6a compilation-tracking sub-bullets and 9a contributor-attribution sub-block) + Abort conditions
- **§N conversions applied:**
  - "claim granularity rules from Section 10 Pass 2" → "claim granularity rules in this file (see Claim Granularity Rules below)"
  - "(or `wiki-local/sources/` if content derives from a local source -- §13)" → "(see `schema/reference/privacy.md`)"
  - "UPDATE operations (Section 9)" → "(see `schema/workflows/structured-operations.md`)"
  - "append-then-synthesize policy (Section 10 Pass 3)" → "(see Incremental Update Policy below)"
  - "Generate wikilinks on first mention" → "(see `schema/reference/wikilinks.md`)"
  - "(see §12)" in step 9a → "(see `schema/reference/log-format.md`)"
- Updated See Also footer to add `schema/reference/log-format.md`
- Ordering verified: `Trigger:` line precedes `## Claim Granularity Rules` (line 7 < line 42)
- Commit: `de736d8`

### Task 2: Extract §11.2 → schema/workflows/query.md

Created new `schema/workflows/query.md` (no YAML frontmatter):

- **Header**: dispatch wording per unified §N policy (no `§11.2` token)
- **Body**: full §11.2 query workflow relocated verbatim from CLAUDE.md — steps 1–10, Write-Back Rules, Privacy Tier for Write-Back, Delta Compilation, Query Log Entry Format (bare format kept inline per WF-07), Ordering, Abort conditions, and Worked Example (including the sanctioned `examples/kahneman/...` pointer line)
- **§N conversions applied:**
  - "structured operations (Section 9)" → "(see `schema/workflows/structured-operations.md`)"
  - "(§13 asymmetric model)" → "(see `schema/reference/privacy.md` asymmetric model)"
  - "`compilation_status` field (Section 5)" → "(see `schema/reference/frontmatter.md`)"
- **See Also footer**: structured-operations.md, privacy.md, log-format.md
- Neutrality confirmed: `examples/kahneman/` path ref is SANCTIONED_PATH_RE-exempt in `bin/check-neutrality.sh`
- Commit: `dbdcb52`

### Task 3: Reduce §11.1/§11.2 stubs; promote routing table; mirror

Changes to AGENTS.md (then synced → CLAUDE.md + applied to schema/AGENTS.template.md):

**§11.1 stub** (full body replaced):
```
→ See `schema/workflows/ingest.md` for the full ingest procedure (classify, diff, extract with provenance, merge, lint, log, commit) and the claim-granularity rules.
```

**§11.2 stub** (full body replaced; write-back-mandatory line retained):
```
**Write-back is mandatory** when a query produces novel or durable synthesis — a new claim, a new connection, a meaningful reframing, or a reusable artifact MUST be compiled back into the wiki (it is not optional).

→ See `schema/workflows/query.md` for the full query procedure, write-back rules, privacy-tier routing, and delta compilation.
```

**Routing table promotion** (Resolvable References table, blockquote-prefixed):
```
> | Ingesting a new source (classify → extract → merge) | `schema/workflows/ingest.md` |
> | Answering a question + write-back rules | `schema/workflows/query.md` |
```

**Scaffold block**: Ingest and Query rows removed; Lint and Reflect remain (for Plan 03 to promote).

**Sync and mirror**:
- `bin/sync-claude.sh` (AGENTS.md → CLAUDE.md): byte-equality verified
- `schema/AGENTS.template.md`: same three edits applied manually (same routing table, same §11.1 stub, same §11.2 stub)

**Verification**: `bin/sync-claude.sh --check` exits 0; `bin/check-neutrality.sh` exits 0

- Commit: `0ce27ba`

## Line Ranges Relocated

| Content | From (CLAUDE.md pre-plan) | To |
|---------|--------------------------|-----|
| §11.1 ingest procedure (steps 1–10 + abort conditions) | L226–L262 | `schema/workflows/ingest.md` lines 6–41 |
| §11.2 query workflow (all subsections) | L264–L374 | `schema/workflows/query.md` lines 6–122 |

## §N → Path Conversions Applied

| Old Reference | New Path | File |
|--------------|----------|------|
| Section 10 Pass 2 (granularity rules) | intra-file "see Claim Granularity Rules below" | ingest.md |
| §13 (privacy) | `schema/reference/privacy.md` | ingest.md |
| Section 9 (UPDATE ops) | `schema/workflows/structured-operations.md` | ingest.md |
| Section 10 Pass 3 (append-then-synthesize) | intra-file "see Incremental Update Policy below" | ingest.md |
| §12 (log format) | `schema/reference/log-format.md` | ingest.md |
| Section 9 (structured ops, write-back) | `schema/workflows/structured-operations.md` | query.md |
| §13 (asymmetric model) | `schema/reference/privacy.md` asymmetric model | query.md |
| Section 5 (compilation_status field) | `schema/reference/frontmatter.md` | query.md |

## Routing Table Rows Added

Both rows added to the "Resolvable references" section (blockquote-prefixed `> | … | \`path\` |` format):
- `> | Ingesting a new source (classify → extract → merge) | \`schema/workflows/ingest.md\` |`
- `> | Answering a question + write-back rules | \`schema/workflows/query.md\` |`

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `bash bin/sync-claude.sh --check` exits 0 (AGENTS.md == CLAUDE.md byte-equality)
- `bash bin/check-neutrality.sh` exits 0 (schema/workflows files pass neutrality gate)
- `schema/workflows/ingest.md` and `schema/workflows/query.md` both start with `# H1` (no frontmatter)
- No cross-file §N survives in either workflow file
- Core §11.2 retains exactly one resident write-back-mandatory statement
- Ingest procedure precedes Claim Granularity Rules section in ingest.md (line 7 < line 42)

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `schema/workflows/ingest.md` exists | FOUND |
| `schema/workflows/query.md` exists | FOUND |
| `17-02-SUMMARY.md` exists | FOUND |
| Commit de736d8 (ingest.md Task 1) | FOUND |
| Commit dbdcb52 (query.md Task 2) | FOUND |
| Commit 0ce27ba (§11 stubs Task 3) | FOUND |
