---
phase: 13-claim-faithfulness-audit
plan: 04
subsystem: docs
tags: [agents-md, schema-mirror, provenance, page-marker, audit-workflow, privacy, neutrality]

# Dependency graph
requires:
  - phase: 13-01
    provides: tests/phase-13/ harness (run.sh, lib.sh) that the two new tests plug into
provides:
  - "AGENTS.md §6 <!-- page: N --> page-marker convention (D-04/D-05/D-06/D-07): optional, Obsidian-invisible, grep-able, #p slice semantics (inclusive lower / exclusive next-page upper), insufficient-locator fallback"
  - "AGENTS.md §11.7 Audit Workflow documentation: review-only, four-operation framing preserved, D-08 reflect-tier suggestion (lint-hosted), D-10 contradicts→marker handoff, EFFECTIVE CLAIM privacy gate, HIGH-C metadata redaction, verifier cloud-by-default + --allow-local model, D-15 audit-state.md checkpoint"
  - "3-way mirror kept consistent: AGENTS.md ≡ CLAUDE.md (byte) + schema/AGENTS.template.md (verbatim subsection mirror) + regenerated schema/fixtures/canonical-AGENTS.md"
  - "tests/phase-13/test_page_marker_convention.sh + test_agents_claude_mirror.sh (mirror + neutrality-by-verbatim guards)"
affects: [13-02 resolve_locator (#p slice contract), 13-03 audit privacy/verifier contract, phase-13 verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "3-way doc mirror: edit AGENTS.md → bin/sync-claude.sh byte-copy to CLAUDE.md → verbatim manual mirror to schema/AGENTS.template.md → regenerate canonical fixture"
    - "Schema-mirror neutrality-by-verbatim-copy guard (check-neutrality.sh PUBLIC_PATHS excludes schema/, so the test asserts subsection byte-identity instead)"

key-files:
  created:
    - tests/phase-13/test_page_marker_convention.sh
    - tests/phase-13/test_agents_claude_mirror.sh
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/fixtures/canonical-AGENTS.md

key-decisions:
  - "Audit documented as a review-only workflow (§11.7), NOT a 5th top-level operation — four-operation framing preserved per 13-CONTEXT.md deferred default"
  - "Privacy gate documented as EFFECTIVE CLAIM privacy (strictest of claim-page/source-summary/raw-source/dir/fail-closed), not bare 'source privacy' — mirrors Plan 03 HIGH-A contract"
  - "Test subsection extractor uses mawk-safe /^###? / terminator instead of the plan's /^#{2,3} / (mawk 1.3.4 lacks ERE interval support); preserves the body-byte-identity intent"

patterns-established:
  - "Page-marker convention: <!-- page: N --> HTML comment at raw-source page boundaries; #p8 = [page:8, page:9), #p12-14 = [page:12, page:15)"

requirements-completed: [FAITH-02, FAITH-04]

# Metrics
duration: ~25min
completed: 2026-06-01
---

# Phase 13 Plan 04: Page-Marker Convention + Audit Workflow Documentation Summary

**Shipped the optional `<!-- page: N -->` §6 page-marker convention (D-04/D-05/D-06/D-07) and the §11.7 review-only Audit workflow (D-08/D-10/D-15, effective-claim-privacy gate) across all three mirror files plus a regenerated canonical fixture, with two mirror/neutrality guard tests.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-01 (this session)
- **Completed:** 2026-06-01
- **Tasks:** 2
- **Files modified:** 4 (+ 2 test files created)

## Accomplishments
- AGENTS.md §6 now documents the optional `<!-- page: N -->` HTML-comment page-marker convention immediately after the Locator Types table, with abstract placeholders only: Obsidian-invisible, grep-able, no `[prov:]` grammar change, `#p8` slices `page:8`→`page:9`, `#p12-14` spans `page:12`→`page:15` (exclusive upper), optional with `insufficient-locator` fallback, document-now/helper-later (D-07).
- AGENTS.md §11.7 documents the Audit as a review-only workflow (four-operation framing preserved, no new wiki page type): D-08 non-binding lint-hosted `audit recommended` note, D-10 human-approved `contradicts`→`[contradiction:]`/`[epistemic:: tentative]` handoff, EFFECTIVE CLAIM privacy gate (strictest of claim-page/source-summary/raw-source/dir/fail-closed — not bare "source privacy"), HIGH-C local-only metadata redaction to a bare count on cloud-facing `--emit-worklist`, verifier cloud-by-default + `--allow-local` locality model, and the D-15 `audit-state.md` checkpoint.
- CLAUDE.md kept byte-equal to AGENTS.md via `bin/sync-claude.sh`; schema/AGENTS.template.md carries the verbatim subsection mirrors; schema/fixtures/canonical-AGENTS.md regenerated twice so the phase-08/09.1 byte-equality gates stay green.
- Two new phase-13 tests added and passing; full suite 22/22.

## Task Commits

1. **Task 1: §6 page-marker convention + mirror + fixture regen** - `d79276f` (docs)
2. **Task 2: §11.7 Audit review-only workflow + mirror + fixture regen** - `fe19c1f` (docs)

## Files Created/Modified
- `AGENTS.md` - §1 Audit-as-workflow note; §6 `### Page-marker convention` subsection; §11.7 Audit Workflow subsection
- `CLAUDE.md` - byte-equal mirror of AGENTS.md (via bin/sync-claude.sh)
- `schema/AGENTS.template.md` - verbatim mirror of the §6 + §11.7 additions (wizard `{{PLACEHOLDER}}` tokens preserved elsewhere)
- `schema/fixtures/canonical-AGENTS.md` - regenerated wizard render so the byte-equality CI gate matches the edited template
- `tests/phase-13/test_page_marker_convention.sh` - asserts marker text + mirror coverage + AGENTS↔template subsection byte-identity
- `tests/phase-13/test_agents_claude_mirror.sh` - asserts Audit workflow prose (review-only, audit-recommended, contradicts, skipped-privacy, allow-local, cloud-by-default, emit-worklist, effective-claim-privacy), CLAUDE byte-mirror, template heading, and canonical byte-equality
- `.planning/phases/13-claim-faithfulness-audit/deferred-items.md` - records the pre-existing out-of-scope neutrality leak

## Decisions Made
- **Audit placement:** new `### 11.7 Audit Workflow` after §11.6 Release (existing subsections not renumbered), with a §1 note that Audit is a review-only workflow layered on the four mutation operations — four-operation framing intact, no 5th operation, no new page type.
- **Privacy wording:** documented as EFFECTIVE CLAIM privacy (strictest-of set) per MEDIUM 13-04, explicitly rejecting bare "source privacy" gating, because the worklist payload carries the wiki page's own claim text.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test subsection extractor adapted for mawk (no ERE interval support)**
- **Found during:** Task 1 (page-marker subsection byte-identity assertion)
- **Issue:** The plan's prescribed extractor `awk 'f&&/^#{2,3} /{exit} ...'` relies on the `{2,3}` ERE interval quantifier. The system `awk` is mawk 1.3.4, which does NOT support interval expressions, so the terminator `/^#{2,3} /` never matched `### Support Types` and the extraction ran to EOF — picking up a downstream `{{DECAY_PROFILE}}` template placeholder and producing a false "subsection diverges" diff.
- **Fix:** Used the mawk-safe alternation `/^###? /` as the terminator (matches a level-2 `## ` or level-3 `### ` heading without intervals). This correctly bounds the subsection at the next heading and preserves the acceptance criterion's INTENT (the Page-marker / Audit subsection body is byte-identical between AGENTS.md and the template). Both new tests also assert the extractor is non-empty and does not overshoot into the following heading, guarding against the tautology the plan warned about.
- **Files modified:** tests/phase-13/test_page_marker_convention.sh, tests/phase-13/test_agents_claude_mirror.sh (documented inline)
- **Verification:** `diff` of the mawk-safe-extracted subsections is empty for both §6 and §11.7; both tests pass.
- **Committed in:** d79276f (Task 1), fe19c1f (Task 2)

---

**Total deviations:** 1 auto-fixed (1 blocking — environment tooling adaptation).
**Impact on plan:** No scope change. The documented additions are byte-identical between AGENTS.md and the template as the plan requires; only the test's extraction mechanism was adapted to the local awk. No real vault terms introduced.

## Issues Encountered
- **Pre-existing, out-of-scope neutrality failure:** `bash bin/check-neutrality.sh` exits 2 due to real vault terms (`kahneman`, `personal-decision-journal`) in the generated `wiki/maintenance/lint-report.md` (lines 82–83, `### Drift` section). Verified this failure is PRESENT ON HEAD (stashing all 13-04 edits leaves exit 2 unchanged), so it is NOT introduced by this plan. This plan's four edited template-public files are byte-clean of every denylist term (0 hits in a scoped scan, with sanctioned `examples/kahneman/` path references scrubbed exactly as the scanner does). `lint-report.md` is not in this plan's `files_modified`; the fix (e.g. `neutrality_exempt: true` frontmatter or report regeneration) is logged in `deferred-items.md` for a follow-up lint-hygiene change. The plan's neutrality intent — no real vault terms in the §6/§11 edits (threat T-13-12) — is satisfied.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The §6 `#p` slice semantics documented here are the read-side contract Plan 02's `resolve_locator` implements (both cite 13-CONTEXT.md D-05) — `tests/phase-13/test_resolve_p_marked.sh` already passes against marked sources.
- The §11.7 Audit workflow privacy/verifier/handoff prose matches the Plan 03 implementation contract; phase-13 verification can cite these mirror files for FAITH-02 / FAITH-04 doc evidence.
- Blocker for a fully-green `check-neutrality.sh`: the pre-existing `lint-report.md` leak (deferred), unrelated to this plan.

---
*Phase: 13-claim-faithfulness-audit*
*Completed: 2026-06-01*

## Self-Check: PASSED

- All 8 created/modified files verified present on disk.
- Both task commits (d79276f, fe19c1f) verified in git history.
