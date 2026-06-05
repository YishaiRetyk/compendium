---
phase: 16-reference-extraction
verified: 2026-06-05T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
resolution: "Both human_needed items resolved in commit 14c8c75 (fix(16): CR-01 + WR-01/02/04). User decision: 'accept drop + clean up'. CR-01 — wizard placeholder drop accepted as intentional (privacy structural per Phase 15; decay recorded as answer, not rendered); dead .replace() no-ops removed from bin/init-wizard.sh; docs/manual-setup.md Sections 4/5 converted to 'File to edit: None'; placeholder test tightened to exact-set; REF-10 DR records the drop. WR-02 — Section 7 ref fixed to 'Section 3 LLM Navigation Rule' across AGENTS.md/CLAUDE.md/template/canonical fixture. WR-04 — leaf §5/§6 cross-refs re-pointed at their leaf-file home. All gates green; phase-08 reconciled to 21/21."
resolved_human_verification:
  - test: "Assess whether the dead wizard no-ops for {{DEFAULT_PRIVACY}} and {{DECAY_PROFILE}} constitute an acceptable loss or require re-homing the carrier lines into the leaf files"
    resolution: "RESOLVED — accepted as intentional drop and cleaned up (Phase 15 made privacy structural so privacy_default: is obsolete; decay profile remains a recorded answer in .wizard-answers.yaml + DR, not rendered). Dead no-ops removed; exact-set placeholder test added; REF-10 DR updated."
  - test: "Confirm that the dangling 'Section 7' cross-reference at AGENTS.md:947 (and CLAUDE.md:947) is an acceptable minor defect or must be fixed before phase close"
    resolution: "RESOLVED — fixed to '(per Section 3 LLM Navigation Rule)' in AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, and schema/fixtures/canonical-AGENTS.md."
---

# Phase 16: Reference Extraction Verification Report

**Phase Goal:** Every static reference section (page-type definitions, frontmatter schema, provenance syntax, wikilink conventions, privacy model, scaling, tooling) lives in its own standalone markdown file under `schema/reference/` or `docs/reference/`, with the core replaced by routing stubs; §16 is deleted.
**Verified:** 2026-06-05
**Status:** passed (both human_needed items resolved in commit 14c8c75)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | Every section in the Extraction Map (§4,§5,§6,§7,§8,§13,§14,§15,§16) is present as a standalone file at its target path OR explicitly dissolved/deleted | ✓ VERIFIED | All 8 target files exist; §16 deleted (0 occurrences in AGENTS.md); §7 dissolved (0 occurrences) |
| 2   | The IMPORTANT:-flagged routing table is at the top of AGENTS.md core, mapping every extracted operation/topic to its target file | ✓ VERIFIED | Routing table at line 34 (between §1 and §2); all 8 resolvable rows point to existing files; Phase-17 rows marked "do NOT dereference yet" |
| 3   | The v1.1.1 uniform-piped-link truth carried verbatim into wikilinks.md; §4/§7 section-ordering dedupe in place; §7 dissolved | ✓ VERIFIED | `filename/path ONLY` appears 2× in wikilinks.md; page-types.md has both "Per-Type Section Ordering" and "Authoring Conventions"; §7 dissolved from AGENTS.md |
| 4   | AGENTS.md byte-identical to CLAUDE.md; schema/AGENTS.template.md mirrors all routing stubs; bin/sync-claude.sh --check AND bin/init-wizard.sh --dry-run both pass | ✓ VERIFIED | AGENTS.md ≡ CLAUDE.md (diff empty). All stubs mirrored in template. sync-claude --check exits 0. init-wizard --dry-run exits 0 with no leftover {{...}}. CR-01 resolved (commit 14c8c75): the dead {{DEFAULT_PRIVACY}}/{{DECAY_PROFILE}} no-ops were removed (intentional drop — privacy structural per Phase 15; decay recorded as answer not rendered); placeholder test tightened to exact-set; byte-equality (template render == canonical) still passes |
| 5   | All CI gates green (lint 3-job, neutrality, setup-parity, check-privacy.sh, check-neutrality.sh) over the new schema/reference/*.md tree | ✓ VERIFIED | check-neutrality exits 0; check-privacy exits 0; init-wizard --dry-run exits 0; phase-08 21/21; phase-09.1 11/11; phase-10 32/32; phase-07 20/22 (2 pre-existing failures in test_kahneman_moved.sh and test_wiki_skeleton.sh, documented as pre-existing in the SUMMARY and unrelated to Phase 16) |

**Score:** 5/5 truths verified (SC4 resolved in commit 14c8c75 — see frontmatter `resolution`)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | --------- | ------ | ------- |
| `schema/reference/page-types.md` | §4 page type rules + §7 section orderings merged | ✓ VERIFIED | 154 lines; contains "Per-Type Section Ordering" and "Authoring Conventions"; all 6 type subsections present |
| `schema/reference/frontmatter.md` | §5 frontmatter schema + validation checklist | ✓ VERIFIED | 149 lines; contains "Frontmatter Validation Checklist" |
| `schema/reference/provenance.md` | §6 syntax/epistemics including Contradiction Inline Syntax | ✓ VERIFIED | 190 lines; contains "Contradiction Inline Syntax"; does NOT contain "Domain-Based Decay Rate Table" (correct split) |
| `schema/workflows/lint.md` | §6 decay table + staleness auto-fix (Phase 16 seed only) | ✓ VERIFIED | 50 lines; contains "Domain-Based Decay Rate Table" and "Staleness Auto-Fix Rules"; Phase-17 ownership note at top; no §11.3 procedure content |
| `schema/reference/wikilinks.md` | §8 wikilink conventions + v1.1.1 uniform-piped-link truth | ✓ VERIFIED | 62 lines; contains "filename/path ONLY" (×2) and "for ALL intra-wiki"; Red Links section present |
| `schema/reference/privacy.md` | §13 asymmetric tier model (Phase-15 form) | ✓ VERIFIED | 24 lines; structural rule, one-way permeability, privacy default present |
| `docs/reference/scaling.md` | §14 Scaling Boundaries | ✓ VERIFIED | 53 lines; all 4 tier subsections present |
| `docs/reference/tooling.md` | §15 Tooling and Integrations | ✓ VERIFIED | 31 lines; all 3 subsections present |
| `AGENTS.md` | §4/§5/§6/§8/§13/§14/§15 stubs + §16 deleted + routing table | ✓ VERIFIED | All stubs present; §16 count=0; §7 count=0; routing table at line 34 |
| `CLAUDE.md` | Byte-identical to AGENTS.md | ✓ VERIFIED | diff AGENTS.md CLAUDE.md = empty |
| `schema/AGENTS.template.md` | All stubs mirrored; routing table present | ✓ VERIFIED | All 6 stubs mirrored; routing table present (1 hit); §7 dissolved; §16 deleted |
| `schema/fixtures/canonical-AGENTS.md` | Regenerated from post-extraction template | ✓ VERIFIED | Contains "IMPORTANT — Reference Routing Table"; no §16 header; phase-08 21/21 |
| `wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md` | REF-10 DR with trigger_type: schema-update, affected_pages: [] | ✓ VERIFIED | trigger_type: schema-update; affected_pages: []; all 7 required sections present |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| AGENTS.md §4 stub | schema/reference/page-types.md | bare pointer | ✓ WIRED | Pattern "schema/reference/page-types.md" present in AGENTS.md |
| AGENTS.md §5 stub | schema/reference/frontmatter.md | Option-B pointer | ✓ WIRED | Pattern "schema/reference/frontmatter.md" present |
| AGENTS.md §6 stub | schema/reference/provenance.md | bare pointer | ✓ WIRED | Pattern "schema/reference/provenance.md" present |
| AGENTS.md §6 stub | schema/workflows/lint.md | bare pointer | ✓ WIRED | Pattern "schema/workflows/lint.md" present |
| AGENTS.md §8 stub | schema/reference/wikilinks.md | bare pointer | ✓ WIRED | Pattern "schema/reference/wikilinks.md" present |
| AGENTS.md §13 stub | schema/reference/privacy.md | structural pointer | ✓ WIRED | Pattern "schema/reference/privacy.md" present |
| AGENTS.md §14 stub | docs/reference/scaling.md | stub | ✓ WIRED | Pattern "docs/reference/scaling.md" present |
| AGENTS.md §15 stub | docs/reference/tooling.md | stub | ✓ WIRED | Pattern "docs/reference/tooling.md" present |
| schema/AGENTS.template.md | all routing stubs | parallel mirror | ✓ WIRED | All 6 stub patterns confirmed in template |
| routing table | 8 resolvable targets | existence check | ✓ WIRED | All 8 leaf files exist on disk; Phase-17 rows intentionally not existence-checked |
| bin/init-wizard.sh lines 657-658 | {{DEFAULT_PRIVACY}}/{{DECAY_PROFILE}} in template | replace() substitution | ✗ DEAD NO-OP | Both placeholders deleted from template; replace() calls are silent no-ops; no leftover {{...}} because tokens don't exist |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces documentation files, not components that render dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Neutrality gate covers schema/ | `bash bin/check-neutrality.sh` | exit=0 | ✓ PASS |
| Privacy gate covers schema/ | `bash bin/check-privacy.sh` | exit=0 | ✓ PASS |
| AGENTS.md byte-identical to CLAUDE.md | `diff AGENTS.md CLAUDE.md` | empty | ✓ PASS |
| init-wizard --dry-run passes | `bash bin/init-wizard.sh --dry-run` | exit=0, no leftover {{...}} | ✓ PASS |
| Phase-08 canonical fixture test | `bash tests/phase-08/run.sh` | 21/21 | ✓ PASS |
| Phase-09.1 parity tests | `bash tests/phase-09.1/run.sh` | 11/11 | ✓ PASS |
| Phase-10 parity tests | `bash tests/phase-10/run.sh` | 32/32 | ✓ PASS |
| Phase-07 tests | `bash tests/phase-07/run.sh` | 20/22 | ✓ PASS (2 pre-existing failures unrelated to Phase 16) |
| Wizard placeholder dead no-ops | `grep -n "DEFAULT_PRIVACY\|DECAY_PROFILE" bin/init-wizard.sh` | Lines 657-658 call replace() on tokens absent from template | ✗ ISSUE — silent no-ops |
| Section 7 cross-reference | `grep "Section 7" AGENTS.md` | Line 947: "per Section 3 and Section 7" | ✗ ISSUE — dangling ref to dissolved §7 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| REF-01 | 16-01 | §4 page types → schema/reference/page-types.md; §4↔§7 dedupe | ✓ SATISFIED | page-types.md exists (154 lines); §7 ordering table merged in; "Authoring Conventions" section present |
| REF-02 | 16-01 | §5 frontmatter → schema/reference/frontmatter.md; Option-B pointer only | ✓ SATISFIED | frontmatter.md exists (149 lines); AGENTS.md §5 is a 2-line Option-B pointer |
| REF-03 | 16-02 | §6 consumer-split: syntax → provenance.md; decay → lint.md | ✓ SATISFIED | provenance.md has Contradiction Inline Syntax (not in lint.md); lint.md has decay table + staleness rules (not in provenance.md) |
| REF-04 | 16-01 | §7 dissolves; no standalone file | ✓ SATISFIED | §7 count=0 in AGENTS.md; §7 nav rules covered by §3; ordering table in page-types.md |
| REF-05 | 16-03 | §8 wikilinks → wikilinks.md; verbatim v1.1.1 truth | ✓ SATISFIED | wikilinks.md has "filename/path ONLY" (×2) and "for ALL intra-wiki" |
| REF-06 | 16-03 | §13 in Phase-15 asymmetric form → privacy.md; precedence table removed not relocated | ✓ SATISFIED | privacy.md exists with structural rule; no 7-row precedence table present |
| REF-07 | 16-03 | §14 → docs/reference/scaling.md; §15 → docs/reference/tooling.md; §16 deleted | ✓ SATISFIED | Both docs/reference files exist; §16 count=0 in AGENTS.md |
| REF-08 | 16-04 | IMPORTANT:-flagged routing table at top of core | ✓ SATISFIED | Routing table at line 34; two-axis (resolvable + Phase-17 workflow rows); all 8 resolvable targets exist |
| REF-09 | 16-01/02/03/04 | Mirror every routing stub into schema/AGENTS.template.md; AGENTS.md ≡ CLAUDE.md | ✓ SATISFIED (with wizard no-op caveat) | All stubs mirrored; sync-claude --check exits 0; two wizard placeholder replacements are dead no-ops |
| REF-10 | 16-04 | Decision record with trigger_type: schema-update for extraction + D-09 framing | ✓ SATISFIED | DR exists; trigger_type: schema-update; affected_pages: []; all 7 required sections; D-09 router framing updated in AGENTS.md preamble and §3 MUST-NOT |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `bin/init-wizard.sh` | 657-658 | Dead no-ops: `.replace("{{DEFAULT_PRIVACY}}", DEFAULT_PRIVACY)` and `.replace("{{DECAY_PROFILE}}", DECAY_PROFILE)` — placeholders deleted from template, replace calls now silent | ⚠️ Warning | Chosen privacy tier and decay profile no longer appear anywhere in the rendered AGENTS.md; wizard prompts and captures these values (in .wizard-answers.yaml DR) but produces no rendered output for them; docs/manual-setup.md still documents 4 substitutions including these two |
| `AGENTS.md` | 947 | Dangling cross-reference: "per Section 3 and Section 7" — §7 no longer exists | ⚠️ Warning | Agent following "Section 7" finds nothing; WR-02 from review confirmed |
| `CLAUDE.md` | 947 | Same dangling cross-reference as AGENTS.md | ⚠️ Warning | Both files are byte-identical so the defect is in both |
| `schema/reference/frontmatter.md` | 29, 54 | AGENTS.md-relative "Section 6" labels: "maps to Section 6 decay table" / "Maps to the decay rate table in Section 6" | ℹ️ Info | Section 6 is now a 4-line stub pointing to lint.md; navigability degraded for leaf-file readers |
| `docs/reference/tooling.md` | 10 | AGENTS.md-relative "Section 5" label: "All frontmatter fields defined in Section 5 are queryable" | ℹ️ Info | Section 5 is now a 1-line pointer; readers in tooling.md cannot follow "Section 5" to actual field definitions |
| `tests/phase-07/test_agents_template_placeholders.sh` | 31-45 | Exact-set assertion replaced with presence check + non-failing WARN for removed placeholders; rogue `{{FOO}}` tokens now pass silently | ⚠️ Warning | Test no longer gates against typo'd or unapproved placeholder insertion; the approved-set enforcement (D-08) is absent |
| `tests/phase-09.1/test_agents_section_4_residue.sh` | 16-19 | §4 type-name grep runs whole-file on common words (entity, source, concept, overview, comparison) | ℹ️ Info | Assertions cannot fail for any plausible §4 mutation since these words appear throughout AGENTS.md; WR-03 from review confirmed |

### Human Verification Required

#### 1. Wizard Placeholder Dead No-ops (CR-01 — Functional Regression Assessment)

**Test:** Run `bash bin/init-wizard.sh` (interactive or with `--answers-file`) and verify whether the rendered AGENTS.md contains any trace of the user's chosen privacy tier or decay profile.

**Expected:** Either (a) the carrier lines are restored in the leaf files (`privacy_default: {{DEFAULT_PRIVACY}}` in schema/reference/frontmatter.md and the decay-profile sentence in schema/workflows/lint.md), the replace() calls are extended to operate on those files, and the init-wizard render surfaces the values; OR (b) an explicit decision is recorded in the DR that these two placeholders were intentionally dropped (Phase 15 made privacy structural so `privacy_default:` is legitimately obsolete; the decay-profile prose line was illustrative only), and docs/manual-setup.md is updated to remove the two now-invalid substitutions from its 4-substitution instruction.

**Why human:** SC4's stated criterion ("init-wizard --dry-run passes") is technically satisfied — exit=0, no leftover `{{...}}` tokens. The functional question — whether the silent loss of wizard-rendered privacy/decay spec content is acceptable — requires an authorial decision about intent that cannot be resolved programmatically.

#### 2. Dangling Section 7 Cross-Reference (WR-02 — Broken Internal Pointer)

**Test:** Read AGENTS.md:947 (and CLAUDE.md:947): "The LLM reads this FIRST when searching for information (per Section 3 and Section 7)." Confirm that §7 no longer exists in AGENTS.md.

**Expected:** Line 947 updated to remove "and Section 7" (e.g., "per Section 3 LLM Navigation Rule") in both AGENTS.md and CLAUDE.md (then sync-claude.sh re-run to keep them identical). This is a one-line fix.

**Why human:** The fix is trivial and unambiguous, but it involves a content change to AGENTS.md/CLAUDE.md that requires a commit. Automated verification confirms the defect exists; the decision to fix now versus defer is human's.

### Gaps Summary

No hard blockers were found — all 8 leaf files exist, all stubs are present, the routing table is wired, §16 is deleted, and every CI gate runs green. The phase goal is structurally achieved.

Two items require human decision before full closure:

**CR-01 (Wizard dead no-ops):** The `{{DEFAULT_PRIVACY}}` and `{{DECAY_PROFILE}}` placeholders were deleted from the template without being relocated. `init-wizard.sh` lines 657-658 are now silent no-ops. The init-wizard --dry-run passes (SC4 criterion met), but the wizard no longer renders the user's chosen privacy/decay values into AGENTS.md. This is a functional regression in the wizard pipeline that was masked by the test reconciliation weakening (WR-01). The orchestrator's context note that Phase 15 made privacy structural (so `privacy_default:` may be legitimately obsolete) provides a plausible justification for intentional removal, but it must be explicitly decided and recorded.

**WR-02 (Dangling Section 7 reference):** AGENTS.md:947 and CLAUDE.md:947 reference "Section 7" which no longer exists. This is a one-line fix but requires a commit.

Three additional warnings are lower-urgency but notable:

- **WR-01:** The placeholder test's exact-set assertion was removed; rogue `{{FOO}}` tokens now pass silently.
- **WR-03/WR-04:** §4 residue test uses whole-file grep on common words (trivially passes any plausible mutation); leaf files carry stale "Section 6"/"Section 5" AGENTS.md-relative labels that no longer resolve to content.

---

_Verified: 2026-06-05_
_Verifier: Claude (gsd-verifier)_
