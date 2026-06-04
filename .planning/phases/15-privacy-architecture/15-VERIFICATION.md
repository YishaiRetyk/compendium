---
phase: 15-privacy-architecture
verified: 2026-06-04T16:55:00Z
status: passed
score: 7/7 must-haves verified (the PRIV-04+PRIV-07 wizard/template gap was closed inline post-verification — see resolution)
overrides_applied: 0
resolution: >
  The PRIV-04/PRIV-07 wizard/template gap below was closed inline by the
  orchestrator (commit cbddc06): schema/AGENTS.template.md §5/§9/§11.1/§11.2 were
  converted off the per-page-privacy model to mirror the already-converted
  AGENTS.md (structural source-summary-tier model); schema/fixtures/canonical-AGENTS.md
  was regenerated; bin/init-wizard.sh + docs/manual-setup.md no longer emit the
  removed `privacy: cloud_safe` field in the generated decision record; and
  tests/phase-08/test_wizard_decision_record.sh dropped the enforcing assertion.
  Verification of the fix: full suite 220 pass / 2 fail (same pre-existing baseline
  failures — kahneman red-link debt + skeleton-on-populated-vault, NOT phase-15
  regressions); all 28 wizard/parity/byte-equality tests green; the template now
  has 0 old-model per-page-privacy references.
  NOT done (deliberate, recorded as a separate wizard-contract decision, NOT a
  PRIV gap): the wizard's {{DEFAULT_PRIVACY}} placeholder is RETAINED — removing it
  would change the documented 4-placeholder contract (Phase 7 D-08) and cascade
  into 3 phase-07/10 placeholder tests + canonical-answers.yaml + manual-setup.
gaps:
  - truth: "PRIV-04: the per-page `privacy` frontmatter field is REMOVED everywhere; the directory is the sole classifier. PRIV-07: the fail-closed/precedence/inheritance machinery is REMOVED rather than relocated."
    status: resolved
    reason: >
      The creator's resident schema (CLAUDE.md ≡ AGENTS.md, byte-equal) is fully
      converted: zero old-model residue, §13 reduced to a structural pointer, the
      `privacy` field stripped from §5 base fields and from all 55 wiki-cloud pages.
      BUT the wizard-rendered distribution layer was NOT converted off the old
      per-page-privacy model. `schema/AGENTS.template.md` (the source `bin/init-wizard.sh`
      renders into a NEW adopter's AGENTS.md) and its golden fixture
      `schema/fixtures/canonical-AGENTS.md` still teach the REMOVED per-page-privacy
      model in three places, and the wizard itself still EMITS the removed `privacy`
      field into the generated decision record — locked in by a green test. A fresh
      `bin/init-wizard.sh` run therefore produces a schema whose §13 teaches the new
      structural model while §5/§9/§11.2 teach the removed precedence/inheritance model:
      internally contradictory and a direct re-introduction of the field PRIV-04 removed.
      The code review caught this as WR-01 (Warning); unlike CR-01/WR-02/WR-03 (fixed in
      commit 780ee06), WR-01 was left unfixed at HEAD.
    artifacts:
      - path: "schema/AGENTS.template.md:286"
        issue: "`privacy_default: {{DEFAULT_PRIVACY}}` in the §5 base-field yaml example, with comment 'see `privacy` above for the actual enum field' — but the `privacy` field no longer exists above (stripped from AGENTS.md). Dangling reference + re-introduced per-page concept."
      - path: "schema/AGENTS.template.md:796"
        issue: "§9 UPDATE Privacy rule still keyed on old per-source `local_only`/`cloud_safe` field STOP-rule. AGENTS.md line 793 was converted to the structural 'wiki-local/ sources -> wiki-local/ target' rule; the template retains the old wording."
      - path: "schema/AGENTS.template.md:990-996"
        issue: "§11.2 'Privacy Inheritance for Write-Back' retains the full per-page precedence machinery ('If ANY source ... has `privacy: local_only` ... Check each source's `privacy` field'). AGENTS.md line 994-1001 was rewritten to 'Privacy Tier for Write-Back' (structural). This is the exact machinery PRIV-07 says must be REMOVED, not relocated."
      - path: "schema/fixtures/canonical-AGENTS.md:286,992"
        issue: "The wizard-rendered golden fixture carries the same residue (privacy_default: cloud_safe; the §11.2 per-page-privacy rule), confirming a fresh wizard render reproduces the contradiction."
      - path: "bin/init-wizard.sh:717"
        issue: "render_decision_record() hard-codes `privacy: cloud_safe` into the generated dr-<TODAY>-initial-setup.md frontmatter — the SINGLE page in a freshly-initialized vault carrying the removed field. Wizard also still prompts for `default_privacy` (lines 322-324/487-489) and threads `{{DEFAULT_PRIVACY}}` into the template."
      - path: "tests/phase-08/test_wizard_decision_record.sh:29"
        issue: "`assert_grep '^privacy: cloud_safe$'` ACTIVELY ENFORCES the removed field — the test suite locks in the old model, so any fix must update this test in lockstep."
    missing:
      - "Strip the per-page `privacy` model residue from schema/AGENTS.template.md §5 (line 286 privacy_default / {{DEFAULT_PRIVACY}}), §9 (line 796), and §11.2 (lines 990-996) to mirror the already-converted AGENTS.md §5/§9/§11.2."
      - "Remove the `privacy: cloud_safe` emission from bin/init-wizard.sh render_decision_record() (line 717); reassess the `default_privacy` prompt + {{DEFAULT_PRIVACY}} token (remove or repurpose to a directory-tier choice)."
      - "Update tests/phase-08/test_wizard_decision_record.sh:29 to assert ABSENCE of `privacy:` in the generated DR (currently asserts presence)."
      - "Regenerate schema/fixtures/canonical-AGENTS.md after the template + wizard fixes."
deferred:
  - truth: "Structural §13 extracted to schema/reference/privacy.md (the resident pointer currently targets docs/reference/privacy-model.md)."
    addressed_in: "Phase 16"
    evidence: "REF-06 success criterion: 'Extract §13 in its Phase-0 asymmetric form -> schema/reference/privacy.md; the 7-row precedence table is removed, not relocated (depends on PRIV-02, PRIV-07).' Phase 15's §13 pointer to docs/reference/privacy-model.md is the correct interim target."
---

# Phase 15: Privacy Architecture Verification Report

**Phase Goal:** Cloud-session privacy enforcement becomes STRUCTURAL — enforced by directory layout (`wiki-cloud/` cloud-safe + `wiki-local/` local-only) and harness permissions, NOT by a resident per-turn agent rule and NOT by a per-page `privacy` frontmatter field. Replaces the old §13 three-level precedence model. Gates Phase 16.
**Verified:** 2026-06-04T16:55:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (PRIV) | Status | Evidence |
|---|--------------|--------|----------|
| 1 | PRIV-01: two-dir layout `wiki-cloud/` + `wiki-local/`; `wiki/` migrated; 2 audit files on local side | ✓ VERIFIED | `wiki/` absent; `wiki-cloud/` (55 md) + `wiki-local/` (2 md) exist; `wiki-local/maintenance/audit-{report,state}.md` present; §2 of CLAUDE.md documents the two-tier model |
| 2 | PRIV-02: §13 rewritten to asymmetric per-vault model; 7-row precedence table removed | ✓ VERIFIED | CLAUDE.md §13 = structural pointer; `Three-Level Precedence`=0, `Privacy Decision Table`=0, `fail-closed`=0 in body; §3/§8 carry the one-way-permeability + D-09 rules |
| 3 | PRIV-03: concrete harness-permission enforcement artifact (not prose) | ✓ VERIFIED | `.claude/settings.cloud.json` = `{permissions:{deny:["Read(./wiki-local/**)"]}}`, valid JSON, git-tracked via `!.claude/settings.cloud.json` exception; `bin/check-sources-cloud-safe.sh` fail-closed guard CI-wired in lint.yml |
| 4 | PRIV-04: per-page `privacy` field removed (directory is classifier) | ⚠️ PARTIAL | Creator vault: 0/55 wiki-cloud pages carry `privacy`; removed from CLAUDE.md/AGENTS.md §5 + checklist + lint BASE_FIELDS/enum. **GAP:** `schema/AGENTS.template.md` + canonical fixture re-introduce `privacy_default`/old model; `bin/init-wizard.sh:717` emits `privacy: cloud_safe` |
| 5 | PRIV-05: tooling on structural model, no behavioral regression | ✓ VERIFIED | `privacy_resolve.py` collapsed to path-prefix predicate (case-safe); `check-privacy.sh` keys on `wiki-local/` path; `audit-claims.sh` FAITH-04 keys off summary tier; `lint.sh` D-09 cloud→local check (LINT_VERSION 1.7.0); CI privacy-leak job updated; `validate-op.sh` re-keyed (CR-01 fix, commit 780ee06) |
| 6 | PRIV-06: execution-time DR `dr-2026-06-04-privacy-asymmetric-two-dir` (schema-update; 3 options) | ✓ VERIFIED | DR exists under `wiki-cloud/decisions/`; `type: decision`, `trigger_type: schema-update`, `status: active`, `epistemic_status: sourced`, non-empty `affected_pages`; all 7 sections present; 3 options recorded; listed in index |
| 7 | PRIV-07: §13 resident obligation reduced to one-line pointer; machinery removed not relocated | ⚠️ PARTIAL | Creator core: §13 is a single structural pointer; machinery removed. **GAP:** the wizard-rendered template §11.2 still RELOCATES (retains) the full per-page precedence/inheritance machinery |

**Score:** 6.5/7 truths verified (PRIV-04 + PRIV-07 fully met for the creator vault; partially met at the wizard/template distribution layer)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | §13 extracted to `schema/reference/privacy.md` (interim pointer targets `docs/reference/privacy-model.md`) | Phase 16 | REF-06 success criterion explicitly extracts §13 to `schema/reference/privacy.md`; Phase 15's docs/ pointer is the correct interim |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wiki-cloud/` (55 md) | cloud-safe tier | ✓ VERIFIED | renamed from wiki/; content present |
| `wiki-local/maintenance/audit-{report,state}.md` | local-only audit control-plane | ✓ VERIFIED | both files present on local side |
| `.claude/settings.cloud.json` | deny-read on wiki-local | ✓ VERIFIED | valid JSON, tracked, correct deny rule |
| `bin/check-sources-cloud-safe.sh` | fail-closed raw-source guard | ✓ VERIFIED | exists, CI-wired; review-verified fail-closed |
| `bin/lib/privacy_resolve.py` | structural path-prefix predicate | ✓ VERIFIED | `_is_local`; case-safe; source-tier survives |
| `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` | PRIV-06 DR | ✓ VERIFIED | full DR, 7 sections, 3 options |
| `bin/validate-op.sh` | structural-tier op validator | ✓ VERIFIED | re-keyed; runs clean on wiki-cloud page (exit 0) |
| `schema/AGENTS.template.md` | mirror of AGENTS.md new model | ✗ STALE | §5/§9/§11.2 retain old per-page-privacy model |
| `bin/init-wizard.sh` | render new-model schema | ✗ STALE | emits `privacy: cloud_safe`; threads {{DEFAULT_PRIVACY}} |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| CLAUDE.md §13 | docs/reference/privacy-model.md | "See ... privacy-model.md" pointer | ✓ WIRED | doc exists with fail-direction table, raw-source rule, forward-ref |
| bin/lint.sh D-09 | wiki-local/ tier walk | two-root known_ids + tier-set | ✓ WIRED | cloud→local link fires linkres error (test_lint_xtier_link GREEN) |
| .github/workflows/lint.yml | bin/check-sources-cloud-safe.sh | privacy-leak job run | ✓ WIRED | invoked at lint.yml:69 |
| bin/init-wizard.sh | schema/AGENTS.template.md | TEMPLATE_PATH render | ⚠️ PARTIAL | renders, but template carries stale old-privacy model |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite | `find tests -name 'test_*.sh'` (all) | 220 pass / 2 fail | ✓ PASS (2 fails pre-existing baseline, not phase-15) |
| Phase-15 suite | `tests/phase-15/test_*.sh` | 13/13 green | ✓ PASS |
| FAITH-04 resolver | `resolve_source_privacy(...)` | wiki-local→local_only; wiki-cloud→cloud_safe; CASE→local_only | ✓ PASS |
| validate-op structural | `bin/validate-op.sh UPDATE wiki-cloud/index.md` | exit 0 | ✓ PASS |
| Deny profile | `python3 json.load` | deny=["Read(./wiki-local/**)"] | ✓ PASS |
| Wizard DR emission | `grep 'privacy:' bin/init-wizard.sh` | emits `privacy: cloud_safe` | ✗ FAIL (re-introduces removed field) |

The 2 baseline failures (`tests/phase-07/test_kahneman_moved.sh` = kahneman in-cluster red-link debt; `tests/phase-07/test_wiki_skeleton.sh` = asserts clean skeleton, red on any populated vault) are pre-existing and unrelated to the privacy model — both already re-keyed to wiki-cloud/, failing for non-privacy reasons.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| PRIV-01 | 15-00/01 | ✓ SATISFIED | two-dir layout migrated, audit files local-side |
| PRIV-02 | 15-00/01 | ✓ SATISFIED | §13 asymmetric; 7-row table removed |
| PRIV-03 | 15-00/02 | ✓ SATISFIED | settings.cloud.json + fail-closed source guard |
| PRIV-04 | 15-00/01 | ⚠️ PARTIAL | removed from vault + core; re-introduced by wizard/template |
| PRIV-05 | 15-00/01/02 | ✓ SATISFIED | all named tooling re-keyed structurally |
| PRIV-06 | 15-00/01 | ✓ SATISFIED | DR authored with 3 options |
| PRIV-07 | 15-00/01 | ⚠️ PARTIAL | core pointer-only; template §11.2 relocates (retains) machinery |

No orphaned requirements: all 7 PRIV IDs appear in plan frontmatter (`requirements: [PRIV-01..07]` in 15-00) and map to REQUIREMENTS.md (all marked Complete there — but that table over-reports PRIV-04/PRIV-07 given the template/wizard residue).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| schema/AGENTS.template.md | 286 | `privacy_default` referencing removed `privacy` field | ⚠️ Warning | Dangling ref; re-introduces per-page concept into adopter schema |
| schema/AGENTS.template.md | 796 | old per-source local_only/cloud_safe STOP rule | ⚠️ Warning | Adopter §9 teaches removed model |
| schema/AGENTS.template.md | 990-996 | full per-page privacy-inheritance machinery | ⚠️ Warning | PRIV-07 violation: machinery relocated to template, not removed |
| bin/init-wizard.sh | 717 | emits `privacy: cloud_safe` into generated DR | ⚠️ Warning | Fresh vault's only page with the removed field |
| tests/phase-08/test_wizard_decision_record.sh | 29 | asserts presence of removed field | ⚠️ Warning | Locks the old model in green CI |

### Human Verification Required

None required for automated determination — the gap is fully observable in code. (The cloud-deny harness behavior — that a real cloud `claude -p --settings` session is actually denied `Read(./wiki-local/**)` — was documented by the plan as a MANUAL/headless spike; the static artifact + fail-direction table are verified, which satisfies the success criterion's "concrete enforcement artifact exists" wording.)

### Gaps Summary

The privacy/security core is sound and the phase goal is achieved **for the creator's vault**: directory-tier enforcement, harness deny-profile, fail-closed source guard, structural resolver, D-09 cross-tier link check, and the schema-update decision record are all in place and test-green (13/13 phase-15 tests, 220/2 suite with the 2 baseline failures unrelated). The orchestrator's CR-01 BLOCKER (validate-op) was correctly fixed.

The single gap is a confirmed, code-verified incompleteness in the **wizard/template distribution layer**, isolated to PRIV-04 and PRIV-07:

- `schema/AGENTS.template.md` (the source `bin/init-wizard.sh` renders into a NEW adopter's AGENTS.md) and its golden fixture `schema/fixtures/canonical-AGENTS.md` still teach the REMOVED per-page-privacy model at §5 (`privacy_default`, dangling ref to a deleted field), §9 (old STOP rule), and §11.2 (the full precedence/inheritance machinery — exactly what PRIV-07 says to remove, not relocate). The §5/§9/§11.2 spots in AGENTS.md itself were correctly converted; only the template is stale.
- `bin/init-wizard.sh:717` emits the removed `privacy: cloud_safe` field, and `tests/phase-08/test_wizard_decision_record.sh:29` enforces it — locking the old model in green CI.

Existing parity tests cannot catch this: `test_template_parity.sh` only checks §4/§16, and `test_agents_template_parity_section_5.sh` explicitly exempts the yaml example block where `privacy_default` lives.

The code review classified this as WR-01 (Warning). It was NOT among the items fixed in commit 780ee06. A fresh adopter would receive a schema whose §13 teaches the new structural model while §5/§9/§11.2 teach the removed precedence model — internally contradictory and a literal re-introduction of the field PRIV-04 abolished. No later phase has an explicit success criterion to scrub this residue (Phase 16 REF-09 mirrors routing stubs and requires `init-wizard --dry-run` to pass, but does not mandate removing the old privacy MODEL from §9/§11.2; §9/§11.2 extraction is Phase 17), so it is reported as a real gap rather than deferred.

**Recommendation for the human/planner:** This is a WARNING-class gap, not a creator-vault BLOCKER. Two acceptable resolutions: (a) close it now with a small template/wizard/test scrub (4 edits listed in `missing`), or (b) accept it as a known deviation and explicitly fold the template scrub into a Phase 16/17 success criterion so it cannot silently propagate into the extracted reference/workflow files. If accepted as intentional, add an `overrides:` entry.

---

_Verified: 2026-06-04T16:55:00Z_
_Verifier: Claude (gsd-verifier)_
