---
phase: 19-extension-contract-research-report-type
verified: 2026-06-11T00:00:00Z
status: gaps_found
score: 3/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Claims extracted from a research report carry support_type: derived (never direct) and a lower epistemic default (mixed/tentative), making the second-order-ness visible in every provenance marker"
    status: failed
    reason: "11 escaped-pipe markers (\\|direct\\|) citing research-report sources remain in wiki-cloud/comparisons/claude-code-orchestration-frameworks.md (1) and wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md (10). The Plan 03 sweep used an unescaped grep pattern — `|direct|` — which cannot match table-cell markers where markdown escapes the pipe as \\|. The 11 markers were never rewritten."
    artifacts:
      - path: "wiki-cloud/comparisons/claude-code-orchestration-frameworks.md"
        issue: "Line 48: 1 escaped-pipe \\|direct\\| marker citing src-2026-04-16-claude-code-frameworks-report (a research-report source)"
      - path: "wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md"
        issue: "Lines 48-52: 10 escaped-pipe \\|direct\\| markers across 5 rows (2 per row) citing src-2026-06-09-pdf-to-text-llm-ingestion-sota (a research-report source)"
    missing:
      - "Rewrite 11 table-cell markers from \\|direct\\| to \\|derived\\| in both comparison files"
      - "Correct the decision record count: 'All 103 |direct| markers' was false — pre-sweep total was 114 (103 prose + 11 table); update wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md accordingly"
  - truth: "The D-08 lint gate enforces derived-never-direct for research-report sources (PROV_RE in bin/lint.sh correctly detects support_type=direct on research-report citations)"
    status: failed
    reason: "PROV_RE captures support_type as 'direct\\' (with trailing backslash) from table-cell markers where pipes are escaped as \\|. The comparison `support_type == 'direct'` therefore never fires for these markers. Confirmed empirically: bin/lint.sh --dry-run --category provenance reports 0 errors against a tree containing 11 live D-08 violations. The same PROV_RE byte-copy in bin/audit-claims.sh carries the identical blind spot."
    artifacts:
      - path: "bin/lint.sh"
        issue: "Line 1152: `if support_type == 'direct':` never matches 'direct\\' captured from \\|direct\\| table markers; D-08 gate is silently broken for table-cell provenance markers"
      - path: "bin/audit-claims.sh"
        issue: "Lines 173-178: identical PROV_RE; the worklist's support_type field will carry 'direct\\' for table markers, making derived-report selector's audit-visibility of direct-marked citations incomplete"
    missing:
      - "Normalize escaped pipes before PROV_RE matching in bin/lint.sh provenance scan: add `.replace('\\\\|', '|')` to the mask_markdown(body) call site, OR strip trailing backslashes from captured groups (`support_type = support_type.rstrip('\\\\')`)"
      - "Apply the same normalization to the PROV_RE usage in bin/audit-claims.sh (per the script's own re-copy contract at lines 144-153)"
      - "Add a table-cell \\|direct\\| case to the D-08 hard-negative test so future regressions are caught"
deferred: []
---

# Phase 19: Extension Contract + Research-Report Type — Verification Report

**Phase Goal:** The schema has a formal, reusable extension contract for adding source types, and the `research-report` type is fully implemented as the contract's worked secondary instance.
**Verified:** 2026-06-11
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | An agent reading `schema/reference/` can find a single source-type extension contract that lists the 5 dimensions and the primary-vs-secondary axis, and can use it to evaluate whether any new candidate justifies a new type or is a sub-case | VERIFIED | `schema/reference/source-types.md` exists (110 lines); contains Section 1 (5 Dimensions table), Section 2 (Primary vs Secondary Axis + decision rule), Section 4 (Evaluated Candidates registry). AGENTS.md/CLAUDE.md routing table row verified. `grep "decision rule\|justified only if" schema/reference/source-types.md` matches. |
| 2 | The contract includes a retro-fit table mapping all current source types across the 5 dimensions, so a reader can see how existing types are instances of the same contract | VERIFIED | Section 3 retro-fit table present; `grep -c "research-report" schema/reference/source-types.md` returns 9; all 7 types (6 existing + research-report) mapped. |
| 3 | An agent ingesting an AI deep-research report finds `source_type: research-report` in the frontmatter enum and Pass-0 classification, knows to preserve the bibliography in the raw source, and captures it as an addressable citation registry in the source summary | VERIFIED | `schema/reference/frontmatter.md` enum reads `article\|paper\|transcript\|journal\|data\|image\|research-report`; pointer sentence present. `schema/workflows/ingest.md` Pass 0 lists research-report with secondary-source note. Both source summary pages have `## References` blocks: 12 `r::` entries (PDF SOTA) and 15 `r::` entries (Frameworks report). |
| 4 | Claims extracted from a research report carry `support_type: derived` (never `direct`) and a lower epistemic default (`mixed`/`tentative`), making the second-order-ness visible in every provenance marker | FAILED | 11 escaped-pipe `\|direct\|` markers remain in two comparison pages, citing `source_type: research-report` sources (10 in `ocr-pipeline-vs-vlm-ingestion.md`, 1 in `claude-code-orchestration-frameworks.md`). The Plan 03 sweep targeted only unescaped `|direct|` patterns and was blind to markdown table-cell escaped pipes. Residual markers verified directly: `python3` count = 11. Additionally, the D-08 lint gate shares the same blind spot and cannot enforce the rule for these markers (see SC-5). |
| 5 | The two existing AI deep-research reports already in `sources/` have been retro-classified with `source_type: research-report` and their citation registries backfilled in their source summary pages | VERIFIED | Both source summaries confirmed: `grep "source_type: research-report"` matches both. `grep -Ec '^- r[0-9]+::'` returns 12 and 15 respectively. Source self-citations (22 + 32 `|direct|`) confirmed unchanged. wiki-cloud/log.md has 2 UPDATE entries. Decision record `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` exists with `trigger_type: schema-update`. |

**Score:** 3/5 roadmap truths verified (truths 1, 2, 3, 5 partially — SC-5 concerns retro-classification of source summaries, which is done; the remaining gap is in the dependent pages sweep (SC-4) and lint enforcement, which together constitute a BLOCKER against the phase goal).

**Note on SC-5:** The retro-classification of the two source summary pages (SC-5) is verified as complete. SC-4 (derived-never-direct in dependent pages) fails, and the D-08 lint gate that was intended to enforce SC-4 is broken for table markers. These two failures are the blockers.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `schema/reference/source-types.md` | 5-dimension contract, retro-fit table (7 types), evaluated candidates registry, worked instance | VERIFIED | 110 lines; all 6 sections present; 9 occurrences of "research-report" |
| `schema/reference/frontmatter.md` | `research-report` in enum, pointer to source-types.md | VERIFIED | Enum line updated; pointer sentence present |
| `schema/workflows/ingest.md` | research-report in Pass 0, granularity table row, informal labels reconciled | VERIFIED | Pass 0 step updated; granularity table has research-report row; sub-case labels added |
| `AGENTS.md` / `CLAUDE.md` | Routing table row for source-types.md; byte-equal | VERIFIED | Row present in both files; `bin/sync-claude.sh --check` exits 0 |
| `schema/reference/provenance.md` | `#r<number>` locator row, graceful-degradation note, usage example | VERIFIED | Reference row in Locator Types table; degradation note present; abstract placeholder usage example present |
| `bin/audit-claims.sh` | derived-report selector (RANK 5), `_resolve_ref` helper, `#r<n>` dispatch | VERIFIED | 4 occurrences of "derived-report"; `_resolve_ref` defined + called; `#r<n>` dispatch before fallthrough |
| `schema/workflows/audit.md` | derived-report selector documented | VERIFIED | Priority selectors (FAITH-01) paragraph present |
| `bin/lint.sh` | LINT_VERSION 1.9.0, VALID_SOURCE_TYPES, D-08 check, D-09 check | PARTIAL — BLOCKER | Version 1.9.0 confirmed; VALID_SOURCE_TYPES present (3 occurrences); D-09 present; D-08 code present but silently broken for table-cell markers — `support_type == 'direct'` never matches `'direct\\'` |
| `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` | source_type: research-report; 12 r:: entries | VERIFIED | Confirmed |
| `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md` | source_type: research-report; 15 r:: entries | VERIFIED | Confirmed |
| `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` | trigger_type: schema-update; epistemic-laundering rationale | VERIFIED | File exists; required fields confirmed |
| `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md` | All report-citing markers use `\|derived\|` | FAILED | Lines 48-52: 10 escaped-pipe `\|direct\|` markers citing src-2026-06-09-pdf-to-text-llm-ingestion-sota remain |
| `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md` | All report-citing markers use `\|derived\|` | FAILED | Line 48: 1 escaped-pipe `\|direct\|` marker citing src-2026-04-16-claude-code-frameworks-report remains |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| AGENTS.md routing table | `schema/reference/source-types.md` | routing table row | WIRED | `> \| Adding/evaluating a new source type \| \`schema/reference/source-types.md\` \|` |
| `schema/reference/frontmatter.md` | `schema/reference/source-types.md` | pointer sentence after enum | WIRED | "Semantics for each `source_type` value and the extension decision rule → `schema/reference/source-types.md`." |
| `schema/workflows/ingest.md` Pass 0 | `schema/reference/source-types.md` | See pointer in classify step | WIRED | "See `schema/reference/source-types.md` for type definitions and the extension decision rule." |
| `bin/lint.sh` PROV_RE loop | D-08 derived-never-direct check | `support_type == 'direct'` comparison | BROKEN | Code exists but never fires for `\|direct\|` table-cell markers — PROV_RE captures `'direct\\'`, not `'direct'` |
| 14 dependent wiki pages | swept provenance markers | `\|derived\|` replacement | PARTIAL | Prose markers correctly swept (0 unescaped `|direct|` residual grep). Table-cell markers missed: 11 `\|direct\|` remain in 2 comparison pages |
| `bin/audit-claims.sh` RANK dict | derived-report selector branch | `selector_active('derived-report')` | WIRED | 4 occurrences; nested `entry.get('fm', {})` access confirmed correct |
| `bin/audit-claims.sh` resolve_locator | `_resolve_ref` helper | `loc.startswith('#r') and loc[2:].isdigit()` | WIRED | `_resolve_ref` defined before `resolve_locator`; dispatch present inside `try:` block |

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers schema reference documents, CLI tools, and wiki content pages. No UI components or dynamic data rendering involved.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| D-08 lint gate fires on simulated violation (per Plan 04 phase-final gate) | Inject `\|direct\|` marker → `bin/lint.sh --category provenance` | SUMMARY claims "Epistemic laundering" was emitted — but the negative test injected an UNESCAPED `|direct|` into a prose line, which DOES work. The blind spot is specifically table-cell escaped-pipe markers. | PARTIAL — prose path works; table-cell path does not |
| Residual unescaped `|direct|` markers citing research-report sources | `grep -r "\|direct\|" entities/ concepts/ comparisons/ overviews/ \| grep "src-2026-06-09\|src-2026-04-16" \| wc -l` | 0 | PASS |
| Residual escaped-pipe `\|direct\|` markers citing research-report sources | `python3` count on comparison files | 11 | FAIL |
| `bin/lint.sh --dry-run --category provenance` reports D-08 violations | Run against current tree | 0 errors (silently hides 11 violations) | FAIL |
| `bin/audit-claims.sh --select derived-report --sample 5` exits 0 | Runtime smoke test | Exits 0 (no crash) | PASS |
| AGENTS.md == CLAUDE.md byte-equal | `bin/sync-claude.sh --check` | "OK: AGENTS.md == CLAUDE.md" | PASS |
| No real vault slugs in template-public files | `bin/check-neutrality.sh` | exit 0 | PASS |
| Full lint green | `bin/lint.sh` | Errors: 0 | PASS (but D-08 silently passes — not a true green for all violations) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| EXT-01 | 19-01 | 5-dimension contract in schema/reference/ with primary-vs-secondary axis | SATISFIED | `schema/reference/source-types.md` exists with all required sections |
| EXT-02 | 19-01 | Decision rule: new source_type justified only if it changes at least one dimension | SATISFIED | Decision rule present in Section 2 of source-types.md |
| EXT-03 | 19-01 | Existing types retro-fit as contract instances; research-report as worked secondary instance | SATISFIED | 7-type retro-fit table in Section 3; research-report worked instance in Section 5 |
| RPT-01 | 19-01 | `source_type: research-report` in frontmatter enum and ingest Pass-0 classification | SATISFIED | Enum updated; Pass 0 step updated; ingest.md granularity table row present |
| RPT-02 | 19-02, 19-04 | Bibliography preserved; citation registry in source summary as addressable registry | SATISFIED | Both source summaries have `## References` blocks with 12 and 15 `r::` entries |
| RPT-03 | 19-02, 19-03 | Claims carry `support_type: derived` (never `direct`) | PARTIALLY SATISFIED — BLOCKER | `#r<n>` locator documented; D-08 lint check present but broken for table-cell markers; 11 live `\|direct\|` markers remain in dependent wiki pages |
| RPT-04 | 19-01, 19-02 | Lower epistemic default (`mixed`/`tentative`), flagged as audit priority | SATISFIED | source-types.md documents `mixed`/`tentative` defaults; `derived-report` 5th audit selector implemented and documented in audit.md |
| RPT-05 | 19-01, 19-04 | Citation registry entry promotable to first-class source (Model C) | SATISFIED | Promotion path documented in source-types.md Section 5; `status: registry` fields in both registries ready for promotion update |
| RPT-06 | 19-03, 19-04 | Two existing reports retro-classified with citation registries backfilled | PARTIALLY SATISFIED — BLOCKER | Source summary frontmatter and `## References` registries: DONE. Dependent page marker sweep: INCOMPLETE — 11 table-cell `\|direct\|` markers remain in 2 comparison pages |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md` | 48-52 | 10 `\|direct\|` markers citing `src-2026-06-09-pdf-to-text-llm-ingestion-sota` (a research-report source) | BLOCKER | Live epistemic-laundering defects — claims from a secondary source appear to be direct citations; D-08 does not detect these |
| `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md` | 48 | 1 `\|direct\|` marker citing `src-2026-04-16-claude-code-frameworks-report` (a research-report source) | BLOCKER | Same as above |
| `bin/lint.sh` | 1141, 1152 | PROV_RE captures support_type as `'direct\\'` from table markers; `support_type == 'direct'` comparison always false for these | BLOCKER | The anti-laundering enforcement gate silently passes on the exact case it was built to catch |
| `bin/audit-claims.sh` | 173-178 | Same PROV_RE — worklist support_type field carries `'direct\\'` for table markers | WARNING | derived-report audit selector's direct-marker visibility is incomplete for table-cell citations |
| `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` | ~70 | "All 103 `|direct|` markers … were rewritten" — pre-sweep total was 114 | WARNING | Decision record contains a factually incorrect count |

### Human Verification Required

None — all gaps are mechanically verifiable and confirmed through code inspection and grep.

### Gaps Summary

Two blockers, both rooted in the same blind spot: markdown table cells escape pipe characters as `\|`, so provenance markers inside table cells appear as `[prov:source-id#locator\|direct\|date]`. The Plan 03 sweep's sed and grep patterns targeted `|direct|` (unescaped), and the D-08 lint check's PROV_RE regex captures the support type as `'direct\'` (with trailing backslash) rather than `'direct'`, so neither the sweep nor the enforcement gate operates on table-cell markers.

**Gap 1 (content):** 11 `\|direct\|` markers remain live in two comparison pages, constituting epistemic-laundering defects under the phase's own D-08 rule. The phase's stated acceptance criterion ("residual = 0") was verified with the same blind-spot grep and therefore was satisfied vacuously.

**Gap 2 (enforcement):** The D-08 lint gate in `bin/lint.sh` (and its byte-copy in `bin/audit-claims.sh`) cannot detect these markers. Lint returns 0 errors against a tree with 11 live violations. The gate the phase installed to make the anti-laundering guarantee mechanical is silently broken for table-cell provenance markers.

Both gaps share a single root cause and can be closed together: normalize `\|` → `|` before PROV_RE matching, and fix the 11 markers in the two comparison files.

---

_Verified: 2026-06-11_
_Verifier: Claude (gsd-verifier)_
