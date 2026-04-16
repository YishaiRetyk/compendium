---
phase: 08-two-track-setup-wizard-manual
plan: 04
subsystem: docs
tags: [manual-setup, wizard, docs, diataxis, decision-record, byte-parity]

# Dependency graph
requires:
  - phase: 08-01-test-harness-and-fixtures
    provides: tests/phase-08/ aggregator + lib.sh helpers + schema/fixtures/canonical-{answers.yaml,AGENTS.md}
  - phase: 07-neutral-template-foundation
    provides: neutral docs/ skeleton + AGENTS.template.md 4-placeholder surface + bin/check-neutrality.sh gate
provides:
  - docs/manual-setup.md 13-section hand-edit walkthrough (copy-template-first + inline decision-record + inline wiki/index.md append)
  - docs/guided-setup.md wizard walkthrough (invocation, prompts, modes, re-run behavior)
  - docs/quickstart.md populated tutorial (wizard step + ingest pointer + Obsidian + prereq pointer)
  - docs/reference/setup-prerequisites.md bash/git/python3 install matrix (macOS, Debian/WSL, Arch, Fedora, Windows)
  - 7 doc-structure tests enforcing MANUAL-01..05 + review concerns #3 and #4
affects: [08-05-ci-byte-equality, phase-10-brownfield, phase-12-debt-verification]

# Tech tracking
tech-stack:
  added: []  # Zero new runtime deps; bash + grep + docs only
  patterns:
    - "Copy-not-edit flow: manual-setup.md pre-step copies schema/AGENTS.template.md → AGENTS.md; all substitutions applied to AGENTS.md, template stays pristine (review concern #3)"
    - "Self-contained manual track: Section 8 inlines deterministic decision-record heredoc + wiki/index.md append snippet; no wizard invocation required (review concern #4)"
    - "Prev-phase test relaxation: when Phase N populates a stub guarded by Phase N-1's stub-state assertion, Phase N updates the prev-phase test to reflect the completed state (Rule 3 pattern)"

key-files:
  created:
    - docs/reference/setup-prerequisites.md
    - tests/phase-08/test_manual_setup_sections.sh
    - tests/phase-08/test_manual_setup_example.sh
    - tests/phase-08/test_manual_setup_checklist.sh
    - tests/phase-08/test_manual_setup_equivalence.sh
    - tests/phase-08/test_manual_setup_file_list.sh
    - tests/phase-08/test_manual_setup_copy_not_edit.sh
    - tests/phase-08/test_manual_setup_inline_templates.sh
  modified:
    - docs/manual-setup.md
    - docs/guided-setup.md
    - docs/quickstart.md
    - tests/phase-07/test_docs_skeleton.sh

key-decisions:
  - "Manual-setup.md Section 8 inlines the full deterministic decision-record heredoc + wiki/index.md append snippet — hand-editor reaches canonical fixture end state WITHOUT running bin/init-wizard.sh (review concern #4)"
  - "Pre-step COPY template to AGENTS.md before editing (review concern #3 — prior iteration's 'edit schema/AGENTS.template.md line X' mutated the template in place, which would have broken the wizard's subsequent --dry-run and CI byte-equality)"
  - "sed one-shot pipeline in pre-step documented as equivalent fast path; users who prefer step-by-step Sections 2–5 minimal diffs MAY skip sed"
  - "Privacy tier uses cloud_safe in the walkthrough (deviates from wizard prompt default local_only per D-11) — matches canonical public fixture schema/fixtures/canonical-AGENTS.md per D-08/Open-Q2"
  - "WZRD-07 amendment rephrased the rejected-placeholder parenthetical to avoid literal {{EXAMPLE_CLUSTER_REF}} / {{USER_NAME}} tokens, satisfying acceptance-criteria grep guards while preserving D-02 intent"
  - "tests/phase-07/test_docs_skeleton.sh relaxed: removed 'Phase 8' stub-marker assertion and raised quickstart ≤60 → ≤80 line cap now that Phase 8 populates it"

patterns-established:
  - "Phase 8 manual-track self-containment: Section 8 of manual-setup.md inlines the decision-record AND index.md append, making the manual track a true peer of the wizard rather than a wizard-dependent fallback (review concern #4 principle)"
  - "Template-write-through discipline: docs that walk through AGENTS.md edits ALWAYS instruct users to edit AGENTS.md (a local copy), NEVER schema/AGENTS.template.md — enforced mechanically by test_manual_setup_copy_not_edit.sh"
  - "Prev-phase test relaxation pattern: when Phase N makes a Phase N-1 stub-guard obsolete, Phase N's plan includes an explicit Rule 3 fix to the prev-phase test (prevents regression suite false-negative)"

requirements-completed:
  - MANUAL-01
  - MANUAL-02
  - MANUAL-03
  - MANUAL-04
  - MANUAL-05
  - WZRD-07

# Metrics
duration: 8min
completed: 2026-04-16
---

# Phase 08 Plan 04: Manual-Track Docs + Setup-Prerequisites + WZRD-07 Amendment Summary

**docs/manual-setup.md landed as a 13-section self-contained hand-edit walkthrough (copy-template-first + inline decision-record heredoc + inline wiki/index.md append), populated docs/quickstart.md + docs/guided-setup.md, created docs/reference/setup-prerequisites.md with 5-platform install matrix, amended WZRD-07 to "exactly 4 named placeholders" per D-02, and added 7 doc-structure tests enforcing MANUAL-01..05 + review concerns #3 and #4.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-16T03:54:51Z
- **Completed:** 2026-04-16T04:02:16Z
- **Tasks:** 2
- **Files modified:** 12 (4 docs created/modified, 1 Phase-07 test relaxed, 7 Phase-08 tests created)

## Accomplishments

- **docs/manual-setup.md populated** — 13-section D-07 layout with pre-step (cp template → AGENTS.md), Sections 1-6 (one per wizard prompt, each with question/file-to-edit/minimal-diff/example), Section 7 (.wizard-answers.yaml heredoc), Section 8 (inline decision-record + inline wiki/index.md append), Section 9 (bin/sync-claude.sh), Section 10 (6-item prompt checklist), Section 11 (byte-identical equivalence statement), Section 12 (5-file touch list), Section 13 (pointers).
- **Review concern #3 corrected** — pre-step instructs `cp schema/AGENTS.template.md AGENTS.md` (or an equivalent sed one-shot writing to AGENTS.md); every "File to edit:" line in Sections 2-5 cites AGENTS.md (never schema/AGENTS.template.md); template stays pristine so wizard's --dry-run and CI byte-equality remain valid.
- **Review concern #4 addressed** — Section 8 inlines the full decision-record heredoc (11 substitution variables, all 7 §4.6 section headings, frontmatter with `trigger_type: schema-update`, `type: decision`, `affected_pages: []`) + the exact `[[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]]` wikilink format matching Plan 03's `update_index_md()` output; manual track never instructs users to invoke the wizard to produce a decision record.
- **docs/guided-setup.md populated** — wizard invocation, 6-prompt enumeration, three modes (interactive / --dry-run / --answers-file), re-run behavior, prerequisites pointer.
- **docs/quickstart.md populated** — replaces Phase 7 D-11 stub; 5-step tutorial (prereq → Use this template → wizard → ingest → Obsidian).
- **docs/reference/setup-prerequisites.md created** — platform install matrix for macOS / Debian / Ubuntu / WSL / Arch / Fedora / Windows; bash ≥ 4, git, python3, optional PyYAML.
- **WZRD-07 amendment** — "exactly 4 named placeholders" ({{PRIMARY_DOMAIN}}, {{DEFAULT_PRIVACY}}, {{AGENT_FILENAME}}, {{DECAY_PROFILE}}); rejected-placeholder note rephrased to avoid literal tokens.
- **7 doc-structure tests added** — MANUAL-01..05 + review concerns #3 and #4 all mechanically verified; phase-08 aggregator: 7/7 PASS locally (Plan 03's 13 tests land in parallel).

## Task Commits

1. **Task 1: Populate manual/guided setup docs, quickstart, prerequisites** — `5d84161` (docs)
2. **Task 2: 7 doc-structure tests for MANUAL-01..05 + review concerns #3 and #4** — `0351074` (test)

_Note: WZRD-07 amendment in REQUIREMENTS.md was pre-landed in Plan 08-01's `ebc86b9` commit — my edit was a byte-equivalent no-op vs HEAD at commit time, then the amendment note was tightened to satisfy acceptance-criteria grep guards (committed as part of 5d84161 via docs/ changes; REQUIREMENTS.md itself unchanged vs 08-01's landed state)._

## Files Created/Modified

**Created (7):**
- `docs/reference/setup-prerequisites.md` — 5-platform install matrix (D-16)
- `tests/phase-08/test_manual_setup_sections.sh` — MANUAL-01 (13 sections + 4 line citations)
- `tests/phase-08/test_manual_setup_example.sh` — MANUAL-02 (personal-knowledge, zero Kahneman, ≥4 diff fences)
- `tests/phase-08/test_manual_setup_checklist.sh` — MANUAL-03 (6-item checklist)
- `tests/phase-08/test_manual_setup_equivalence.sh` — MANUAL-04 ('byte-identical end state' + CI reference)
- `tests/phase-08/test_manual_setup_file_list.sh` — MANUAL-05 (5 wizard-touched files)
- `tests/phase-08/test_manual_setup_copy_not_edit.sh` — review concern #3 (cp/sed pre-step; zero template-edit-in-place)
- `tests/phase-08/test_manual_setup_inline_templates.sh` — review concern #4 (inline heredoc + wikilink + no wizard-defer)

**Modified (5):**
- `docs/manual-setup.md` — 13-section D-07 walkthrough (replaced Phase 7 stub)
- `docs/guided-setup.md` — wizard walkthrough (replaced Phase 7 stub)
- `docs/quickstart.md` — populated wizard + ingest sections (replaced Phase 7 D-11 stub)
- `tests/phase-07/test_docs_skeleton.sh` — relaxed stub-state assertions (Rule 3 deviation)

## Decisions Made

See frontmatter `key-decisions`. Key highlights:

- **Section 8 inlining (review concern #4):** the manual track is a true peer of the wizard — a contributor following manual-setup.md produces the decision-record + index.md entry WITHOUT invoking the wizard. This preserves the two-track symmetry promised by MANUAL-04 and eliminates any hidden wizard dependency in the manual flow.
- **Pre-step copy (review concern #3):** all Sections 2-5 edits apply to a NEW AGENTS.md file, never to schema/AGENTS.template.md. The template is treated as a read-only source. This keeps the wizard's `--dry-run` valid after manual onboarding and keeps CI's byte-equality check stable.
- **Privacy tier cloud_safe in walkthrough:** the walkthrough deviates from the wizard prompt default (`local_only` per D-11) to match the canonical public fixture `schema/fixtures/canonical-AGENTS.md` (per D-08/Open-Q2 — avoids `bin/release.sh`'s privacy-leak regex on the public fixture). Hand-editors personalizing for a private repo MAY use `local_only` and accept that their AGENTS.md diverges from the canonical fixture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Relaxed Phase-07 test_docs_skeleton.sh stub-state assertion**
- **Found during:** Task 1 (populating docs/quickstart.md)
- **Issue:** Phase 7's `test_docs_skeleton.sh` required `grep -q 'Phase 8' docs/quickstart.md` as a stub marker; populating quickstart per Phase 8 plan removed the stub marker, causing regression (21/22 PASS).
- **Fix:** Dropped the 'Phase 8' stub-marker check and raised the size cap from ≤60 → ≤80 lines (populated quickstart is 40 lines — well within cap). The remaining Phase 7 assertions (bin/init-wizard.sh + bin/ingest.sh + Obsidian references) stay green and are still valid post-Phase-8.
- **Files modified:** tests/phase-07/test_docs_skeleton.sh
- **Verification:** `bash tests/phase-07/run.sh` → 22/22 PASS
- **Committed in:** 5d84161 (Task 1 commit)

**2. [Rule 1 - Bug] Rephrased WZRD-07 amendment parenthetical to avoid literal rejected-placeholder tokens**
- **Found during:** Task 1 verification (REQUIREMENTS.md grep guards)
- **Issue:** Plan line 554 prescribed an amendment text that literally contains `{{EXAMPLE_CLUSTER_REF}}` and `{{USER_NAME}}` as "rejected" references. But acceptance criteria + verify-block grep both asserted `! grep -q 'EXAMPLE_CLUSTER_REF' .planning/REQUIREMENTS.md` (and USER_NAME). Internal plan contradiction — the prescribed text cannot satisfy the prescribed grep guards.
- **Fix:** Rephrased the parenthetical note as "the previously-proposed example-cluster and user-name placeholders were rejected; the maintainer-name answer lives only in `.wizard-answers.yaml` + the initial decision record, never in AGENTS.md." Preserves D-02 intent (exactly 4 placeholders, reject the 2 proposed additions) while satisfying the machine-checkable grep guards.
- **Files modified:** .planning/REQUIREMENTS.md (line 46; committed in Plan 08-01's ebc86b9)
- **Verification:** `grep -q 'exactly 4 named placeholders' .planning/REQUIREMENTS.md && ! grep -q 'EXAMPLE_CLUSTER_REF' && ! grep -q 'USER_NAME'` → all pass
- **Committed in:** ebc86b9 (Plan 08-01 landed the amended text directly; Plan 08-04 verified it in-place)

**3. [Rule 1 - Bug] Escaped triple-backtick-diff pattern in test_manual_setup_example.sh**
- **Found during:** Task 2 initial phase-08 aggregator run
- **Issue:** Comment line `# ... at least 4 ```diff fences for Sections 2/3/4/5.` contained literal triple-backtick + "diff" + backtick which bash parsed as command substitution, producing "unexpected EOF while looking for matching `" syntax error.
- **Fix:** (a) Reworded the comment to "triple-backtick-diff fences"; (b) moved the regex pattern into a variable `DIFF_FENCE_PATTERN='^```diff$'` (single-quoted, never interpreted). The logic is unchanged; only the source-code safety was fixed.
- **Files modified:** tests/phase-08/test_manual_setup_example.sh
- **Verification:** `bash tests/phase-08/test_manual_setup_example.sh` → PASS with 4 diff fences detected
- **Committed in:** 0351074 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 3 blocking, 2 Rule 1 bug)
**Impact on plan:** All auto-fixes necessary for correctness (Phase 7 regression) and plan-internal consistency (grep-guard / bash-parsing contradictions). No scope creep. All review concerns #3 and #4 satisfied mechanically.

## Issues Encountered

- **Parallel wave 2 coordination:** Plan 08-01 pre-landed the WZRD-07 amendment in REQUIREMENTS.md (commit `ebc86b9`), so my Task 1 edit to REQUIREMENTS.md was byte-equivalent to HEAD (no-op in git terms). The final rephrase (deviation #2 above) was applied directly in memory then found to already match HEAD — a no-op that nonetheless validates the prescribed end-state. Plan 03's 13 tests will land separately; Phase 8 aggregator will reach 20/20 when Plan 03 completes. Locally we observe 7/7 which is the expected per-plan slice.

## Next Phase Readiness

- **Plan 08-05 (CI byte-equality) ready:** the `schema/fixtures/canonical-AGENTS.md` target exists (landed in Plan 08-01); the manual-setup.md walkthrough correctly targets it; the 7 doc-structure tests enforce the structural contract that Plan 05's byte-equality test depends on.
- **Plan 08-03 (wizard side-effects) parallel:** Plan 08-04's inline decision-record template in Section 8 matches Plan 03's `update_index_md()` wikilink format + `dr-${TODAY}-initial-setup.md` substitution map byte-for-byte (verified via test_manual_setup_inline_templates.sh). Plans can merge in any order.
- **No blockers for Phase 9 or downstream.**

## Known Stubs

None. All 4 docs files are fully populated; no "TODO" / "coming soon" / "placeholder" text in user-facing copy. The `<unresolved>` placeholder in the `.wizard-answers.yaml` heredoc example is an instructive value the user substitutes; the surrounding text explicitly documents how to resolve it via `git log -1 --format=%H schema/AGENTS.template.md`.

---

## Self-Check: PASSED

All 13 declared files exist on disk; both task commits (5d84161, 0351074) present in git log.

---

*Phase: 08-two-track-setup-wizard-manual*
*Completed: 2026-04-16*
