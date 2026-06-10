---
phase: 19-extension-contract-research-report-type
plan: "02"
subsystem: schema-provenance-audit
tags:
  - provenance
  - audit
  - research-report
  - selector
  - locator
dependency_graph:
  requires:
    - 19-01-PLAN (source-types.md contract — provides context, but this plan's files are independent)
  provides:
    - "#r<n> locator syntax documented in schema/reference/provenance.md"
    - "derived-report audit selector in bin/audit-claims.sh (RANK 5)"
    - "_resolve_ref helper for bibliography section resolution"
    - "derived-report documented in schema/workflows/audit.md"
  affects:
    - "bin/audit-claims.sh consumers: agents running claim-faithfulness audits"
    - "schema/reference/provenance.md consumers: agents authoring research-report claims"
    - "schema/workflows/audit.md consumers: agents running or reading about the audit workflow"
tech_stack:
  added: []
  patterns:
    - "Extend resolve_locator per-scheme dispatcher with #r<n> case"
    - "Add _resolve_ref helper using header search + positional bullet extraction"
    - "Extend RANK dict + selector_active loop for 5th priority tier"
    - "Graceful-degradation note pattern from #p page-marker precedent"
key_files:
  created: []
  modified:
    - schema/reference/provenance.md
    - bin/audit-claims.sh
    - schema/workflows/audit.md
decisions:
  - "derived-report as the CLI token for the 5th selector (matches source_type value with -report suffix for clarity)"
  - "_resolve_ref searches 4 candidate headers (Source Citations, Sources by Topic, Sources, References) in order — first match wins, covering both existing reports"
  - "Positional numbering sequential across topic groups (not per-group) per RESEARCH.md A1 assumption"
  - "Usage example in provenance.md uses abstract placeholder <report-slug> (template-public neutrality)"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-10T20:42:24Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 19 Plan 02: Provenance Locator + Audit Selector Summary

**One-liner:** `#r<n>` bibliography locator added to provenance.md with graceful-degradation note; `derived-report` 5th audit selector + `_resolve_ref` helper added to `bin/audit-claims.sh`; selector documented in `schema/workflows/audit.md`.

## What Was Built

### Task 1: #r<n> Locator Row in schema/reference/provenance.md (commit c05e66d)

Three targeted edits to `schema/reference/provenance.md`:

1. **Locator Types table** — added Reference row: `| Reference | #r<number> | #r7 | research-report bibliography entries |`
2. **Graceful-degradation note** — added paragraph after the `#p` page-marker fallback text: when no bibliography section exists, `#r<n>` resolves to `insufficient-locator` (NOT an error), matching the `#p` precedent
3. **Examples in Context block** — added `- Research synthesis claim: \`[prov:<report-slug>#r7|derived|<date>]\`` using abstract placeholder (template-public, neutrality-safe)

### Task 2: derived-report Selector + _resolve_ref Helper (commit 4ee3b86)

Four edits to `bin/audit-claims.sh`:

1. **SELECT default** changed from `stale,epistemic,recency,fanout` to `stale,epistemic,recency,fanout,derived-report`
2. **RANK dict** extended with `'derived-report': 5`
3. **Selector branch** added after `fanout`: uses nested `entry.get('fm', {})` access (matches audit-claims.sh's `{'fm': sfm}` structure, NOT the flat lint.sh pattern), checks `source_type == 'research-report'`
4. **`_resolve_ref` helper** added before `resolve_locator`: searches `## Source Citations`, `## Sources by Topic`, `## Sources`, `## References` headers in order (first match); returns Nth 1-indexed positional bullet; positional count is sequential across topic groups
5. **`#r<n>` dispatch** added in `resolve_locator` inside the `try:` block before final fallthrough: `loc.startswith('#r') and loc[2:].isdigit()` guard prevents collision with `#rec:` etc.

One edit to `schema/workflows/audit.md`:

- Added **Priority selectors (FAITH-01)** paragraph documenting all 5 selectors including `derived-report`, its purpose (anti-epistemic-laundering), CLI usage `--select derived-report`, and the note that `direct` markers on research-report sources are a defect that lint flags independently.

## Verification

All acceptance criteria passed:

- `grep '#r<number>' schema/reference/provenance.md` — match found
- `grep 'Reference' schema/reference/provenance.md` — row present in locator table
- `grep 'Graceful degradation.*#r\|#r.*insufficient-locator' schema/reference/provenance.md` — match found
- `grep 'report-slug\|#r7' schema/reference/provenance.md` — usage example found
- `grep "derived-report" bin/audit-claims.sh | wc -l` — 4 matches
- `grep "_resolve_ref" bin/audit-claims.sh | wc -l` — 2 matches (definition + call)
- `grep "Source Citations\|Sources by Topic" bin/audit-claims.sh` — both in header_re
- `grep "derived-report" schema/workflows/audit.md` — 1 match
- `bash bin/audit-claims.sh --select derived-report --sample 5` — exits 0 ("Selected 0, skipped 0" — no research-report sources yet exist)
- `bash bin/check-neutrality.sh` — exits 0

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None introduced by this plan. The pre-existing "verifier not run" stub in `bin/audit-claims.sh` is from Phase 13 (the verifier dispatch stub documented in 13-RESEARCH.md). Not a new stub.

## Self-Check: PASSED

Files exist:
- [x] `schema/reference/provenance.md` — modified, verified via grep
- [x] `bin/audit-claims.sh` — modified, verified via grep + runtime test
- [x] `schema/workflows/audit.md` — modified, verified via grep

Commits exist:
- [x] c05e66d — `feat(19-02): add #r<n> locator row to schema/reference/provenance.md`
- [x] 4ee3b86 — `feat(19-02): add derived-report selector and #r<n> resolver to bin/audit-claims.sh; document in audit.md`
