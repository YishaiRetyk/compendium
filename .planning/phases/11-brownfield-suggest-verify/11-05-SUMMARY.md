---
phase: 11-brownfield-suggest-verify
plan: 05
subsystem: documentation

tags: [brownfield, agents-md, schema, requirements, decision-record, phase-11-close, wr-03-closure, option-c-renumber]

# Dependency graph
requires:
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-04 final implementation of review-typing + verify (so AGENTS.md §11.5 can document them as-implemented); Plan 11-03 migration-script bodies; Plan 11-02 suggest subcommand; Plan 11-01 Wave-0 RED tests tagged EXPECTED_BY:11-05 (7 tests — test_agents_section_11_5, test_agents_template_parity_11_5, test_canonical_agents_byte_equality, test_docs_{suggest,review_typing,verify,mechanical_judgment}_section).
  - phase: 09.1-progressive-disclosure-extraction
    provides: AGENTS.md post-extraction structure + CLAUDE.md byte-sync precedent + schema/AGENTS.template.md flag-based awk parity test.
  - phase: 08-two-track-setup-wizard-manual
    provides: bin/init-wizard.sh --answers-file --render-to + canonical-answers.yaml fixture regeneration recipe (Phase 8-01 wizard render routine reused for canonical-AGENTS.md regen).
  - phase: 10-brownfield-scan-bootstrap
    provides: WR-03 open item (§5 bootstrap_stage forward-ref typo pointing at Release Workflow at §11.5) — closed opportunistically by Option C renumber.
provides:
  - AGENTS.md §11.5 Brownfield Workflow authoritative contract (D-01 apply-vs-advisory + D-15 bootstrap_stage lifecycle + D-09 stale-artifact WARN + 11.5.4 per-script applied.log shapes)
  - AGENTS.md §11.6 Release Workflow (renumbered from §11.5 — Option C per RESEARCH Pitfall 1)
  - docs/reference/brownfield.md operator runbook (suggest + review-typing + verify subsections; lifecycle walkthrough; troubleshooting table with item-4/9/11 entries)
  - wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md Tier-1 DR per D-21 — documents items 1–11 in Consequences
  - BRWN-22 new requirement (review-typing orchestrator)
  - BRWN-12 rename amendment (04-privacy-classification → 04-privacy-review)
  - Phase 11 test aggregator: 47/47 unfiltered + all --expected-by subsets pass == total
  - Phase 10 WR-03 closure verification (§5 bootstrap_stage forward-ref now correctly resolves)
affects: []  # Phase 11 closes v1.1 brownfield track; no downstream phases

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Option C section renumber: existing §11.5 Release → §11.6, new Brownfield Workflow occupies §11.5 verbatim (RESEARCH Pitfall 1 recommendation — closes Phase 10 WR-03 forward-ref typo by construction)"
    - "CLAUDE.md pre-stage sync collapses documented 2-attempt pre-commit hook path: `bash bin/sync-claude.sh && git add CLAUDE.md` BEFORE commit (Phase 9.1 R-3 precedent)"
    - "Canonical fixture regeneration via wizard render routine: `bin/init-wizard.sh --answers-file canonical-answers.yaml --render-to <tmp>` → cp to schema/fixtures/canonical-AGENTS.md (Phase 8-01 pinned recipe with WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA env vars)"
    - "Tier-1 DR with trigger_type: schema-update + affected_pages: [] is valid per AGENTS.md §4.6 (empty list for infrastructure-only records — inaugural records like dr-2026-04-14-phase6-decision-type established this precedent)"
    - "Decision-record Consequences section as natural home for review-feedback implementation details (items 1–11) rather than splitting into 11 separate DRs — they are follow-on details of the apply-vs-advisory architecture, not independent architectural choices"
    - "Cross-phase test-relaxation pattern: Phase-N test's hard-coded assertion about a stub/cap value gets updated in Phase-M (M>N) when the referenced content is populated/grows (precedent: Plan 08-04 phase-07 docs-skeleton relax; Plan 09.1-02 phase-07 reference-stubs relax; Plan 11-05 phase-07 wiki-skeleton cap raise + phase-10 docs-populated stub-marker removal)"

key-files:
  created:
    - wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md (Tier-1 DR; 120 lines; 7 required sections + frontmatter; documents D-01 + D-15 + review items 1-11 in Consequences)
    - .planning/phases/11-brownfield-suggest-verify/deferred-items.md (pre-existing Phase-10 ruamel.yaml test failures logged per SCOPE BOUNDARY)
  modified:
    - AGENTS.md (+181 lines; §11.5 Brownfield Workflow populate + §11.6 Release Workflow renumber)
    - CLAUDE.md (+181 lines; byte-sync mirror of AGENTS.md via bin/sync-claude.sh)
    - schema/AGENTS.template.md (+181 lines; same §11.5 + §11.6 edits — Phase 9.1 template-parity test asserts byte-equivalence modulo wizard placeholders, which §11.5 + §11.6 have none of)
    - schema/fixtures/canonical-AGENTS.md (regenerated via Phase 8-01 wizard render routine; content drifts by exactly the template delta)
    - docs/reference/brownfield.md (+176 lines net; ## suggest + ## review-typing + ## verify sections populated; ## Lifecycle walkthrough + ## Troubleshooting table added)
    - .planning/REQUIREMENTS.md (BRWN-12 rename; BRWN-18/19/20 flipped Pending → Complete; BRWN-22 added; traceability + coverage: 78 → 79, Phase 11 10 → 11)
    - wiki/index.md (+1 line; ## Decisions section gains Brownfield Apply-vs-Advisory DR wikilink)
    - wiki/log.md (+4 lines; reflect entry appended at EOF per §12)
    - tests/phase-11/test_canonical_agents_byte_equality.sh (Rule 1 fix — Wave-0 python regex `[A-Z_]` never matched lowercase canonical-answers.yaml keys; replaced with Phase 8 wizard-render shape per plan's 're-use Phase 8 test shape' fallback)
    - tests/phase-07/test_wiki_skeleton.sh (Rule 3 relax — raise wiki/index.md cap from 30 to 40 lines to accommodate Phase 11 DR addition; precedent: Plan 09.1-02 earlier raise)
    - tests/phase-10/test_brownfield_docs_populated.sh (Rule 3 relax — remove `[Populated in Phase 11]` stub-marker assertion now that Phase 11 populated the sections; precedent: Plan 08-04 + Plan 09.1-02)

key-decisions:
  - "Option C renumber: §11.5 Release Workflow → §11.6 + new §11.5 Brownfield Workflow. Closes Phase 10 WR-03 forward-ref typo by construction (§5 bootstrap_stage row's 'See §11.5 Brownfield Workflow' string is now correct)."
  - "Tier-1 DR uses trigger_type: schema-update + affected_pages: [] (infrastructure record; no wiki content pages are structurally affected). The 11 review-feedback hardenings (items 1–11) are documented as Consequences implementation details, not separate DRs."
  - "canonical-AGENTS.md regeneration uses the Phase 8-01 wizard-render recipe (pinned WIZARD_GENERATED_AT=2026-04-16T00:00:00Z + WIZARD_TEMPLATE_SHA=<frozen-fixture>). The Phase 8 test_canonical_byte_equality.sh remains the primary byte-equality gate; the Phase 11 test_canonical_agents_byte_equality.sh re-uses the same wizard routine per the 11-01 plan's 're-use Phase 8 test shape' fallback."
  - "Test-as-contract Rule 1 fix: tests/phase-11/test_canonical_agents_byte_equality.sh's Wave-0 python used `re.match(r'^([A-Z_]...)')` on canonical-answers.yaml's lowercase keys → subs dict always empty → asserted template == canonical-AGENTS.md byte-equal (unsatisfiable after wizard substitution). Replaced with the wizard-render shape that the plan documented as the intent."

patterns-established:
  - "Option C renumber is safer than Option B (move Brownfield to §11.6) because it avoids touching the Phase 10 §5 forward-ref AND avoids re-regenerating canonical fixture for a numbering-only reason. The single edit (+renumber) touches all 4 parity artifacts (AGENTS.md, CLAUDE.md via sync, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md regen) in one atomic commit."
  - "When a decision affects a directory of artifacts (schema/brownfield/migrations/ + bin/ + bin/lib/ + docs/reference/brownfield.md + AGENTS.md §11.5), a single Tier-1 DR with a comprehensive Affected Pages enumeration is more navigable than 11 micro-DRs for each review-feedback item."
  - "Cross-phase test relaxation precedent extended: Phase-M (M>N) edits a Phase-N test when Phase-N's assertion references a stub/cap/count that Phase-M legitimately invalidates. Commit message cites precedents (Plan 08-04, Plan 09.1-02) and rationale (the referenced content is now populated / the cap is now too tight for natural growth)."

# Operational metadata

decisions:
  - "Preserve the §5 bootstrap_stage forward-ref text verbatim ('See §11.5 Brownfield Workflow (populated in Phase 11).'). Option C renumbering means the string is NOW CORRECT after the edit — WR-03 closed by construction rather than by an explicit text edit."
  - "BRWN-22 wording (new requirement) captures item 4 (EOF safety) + item 11 (override-label validation) in the same requirement. These are two orthogonal safety properties of the same review-typing orchestrator surface; separating them would create artificial requirement-table churn."

# Verification tallies (final Phase 11 close)

tests:
  phase_11_unfiltered: "47/47 GREEN"
  phase_11_expected_by_11_05: "7/7 GREEN"
  phase_11_expected_by_11_01: "3/3 GREEN"
  phase_11_expected_by_11_02: "7/7 GREEN"
  phase_11_expected_by_11_03: "19/19 GREEN"
  phase_11_expected_by_11_04: "11/11 GREEN"
  phase_09_1: "11/11 GREEN"
  phase_09: "28/28 GREEN"
  phase_08: "21/21 GREEN"
  phase_07: "22/22 GREEN"
  phase_10: "21/32 (11 pre-existing ruamel.yaml env-drift failures — logged in deferred-items.md; not caused by Plan 11-05; outside scope)"

metrics:
  duration_estimate_minutes: 40
  completed_date: 2026-04-20
  task_count: 2
  file_count_task_1: 5  # AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, tests/phase-11/test_canonical_agents_byte_equality.sh
  file_count_task_2: 8  # docs/reference/brownfield.md, REQUIREMENTS.md, DR, wiki/index.md, wiki/log.md, tests/phase-07/test_wiki_skeleton.sh, tests/phase-10/test_brownfield_docs_populated.sh, deferred-items.md
  total_file_count: 13
  commits_created: 2
  task_1_commit: 2c13012
  task_2_commit: f8f1929
---

# Phase 11 Plan 05: Phase 11 Close — AGENTS.md §11.5 + Docs + Tier-1 DR + Requirements Traceability Summary

Authoritative schema contract for the brownfield workflow (AGENTS.md §11.5) populated with the apply-vs-advisory architectural boundary, paired-immutable-inputs contract, root-resolution semantics, stale-artifact WARN, and per-script applied.log shapes; operator runbook in docs/reference/brownfield.md; Tier-1 DR + traceability flip close Phase 11; Phase 10 WR-03 fixed opportunistically by Option C renumber.

## Context

Phase 11 shipped the brownfield suggest / review-typing / verify subcommand surface across Plans 11-02 / 11-03 / 11-04, but without the schema-layer documentation the contract is opaque to future agents. Plan 11-05 is the close: it populates AGENTS.md §11.5 (the "sole authoritative specification" §1 authority) with the full contract; populates docs/reference/brownfield.md as the operator runbook; commits a Tier-1 decision record capturing the apply-vs-advisory architecture + 11 cross-AI review-feedback hardenings; and flips REQUIREMENTS.md BRWN-11..20 + BRWN-22 from Pending to Complete.

Option C renumber (§11.5 Release Workflow → §11.6; new §11.5 Brownfield Workflow) was chosen per RESEARCH Pitfall 1 as the safest section-numbering path — it closes Phase 10 WR-03 (the §5 bootstrap_stage forward-ref typo) by construction rather than by explicit text edit, and the existing §11.5 Release Workflow content moves to §11.6 verbatim.

## Implementation Summary

### Task 1 — AGENTS.md §11.5 populate + §11.6 renumber + mirror across CLAUDE.md / template / canonical fixture

- AGENTS.md: inserted 181 lines of §11.5 Brownfield Workflow content BEFORE the existing §11.5 Release Workflow line, then renumbered the Release line to §11.6. §11.5 body follows the §§11.1–11.4 preamble + numbered Steps + Abort conditions shape, with four subsections (11.5.1 suggest, 11.5.2 review-typing, 11.5.3 verify, 11.5.4 applied.log per-script shapes). Review-feedback anchors embedded verbatim:
  - Item 1 (root resolution): "Migration scripts do NOT default to `$(pwd)`; `BROWNFIELD_ROOT` is an explicit env-var override" + "parent of the `.brownfield/` directory containing the script".
  - Item 2 (paired immutable inputs): dedicated paragraph in §11.5.1 "**Paired immutable inputs contract:** ... Both files are required — deleting either before apply causes a hard error."
  - Item 9 (stale-artifact WARN): §11.5.3 Step 1 verbatim — "Emit a stderr WARN for each mismatch (`stale candidate artifact detected: ...`)".
  - Item 10 (per-script applied.log variance): new §11.5.4 subsection enumerating 01 paired / 02 literal-advisory / 03+04 no-inputs shapes.
- schema/AGENTS.template.md: same structural edits mirrored. §11.5 + §11.6 introduce zero wizard placeholders, so byte-equivalence holds for the Phase 9.1 parity test.
- schema/fixtures/canonical-AGENTS.md: regenerated via the Phase 8-01 wizard render routine with pinned `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z` + `WIZARD_TEMPLATE_SHA=<frozen-fixture>`; content drifts by exactly the template delta.
- CLAUDE.md: byte-synced via `bash bin/sync-claude.sh && git add CLAUDE.md` pre-commit staging (Phase 9.1 R-3 one-attempt precedent).
- §5 bootstrap_stage row text unchanged: 'See `§11.5 Brownfield Workflow` (populated in Phase 11).' — this string is NOW correct after the Option C renumber, so Phase 10 WR-03 is closed by construction.
- Rule 1 fix on tests/phase-11/test_canonical_agents_byte_equality.sh: Wave-0 python regex `^([A-Z_][A-Z0-9_]*):` never matched lowercase keys in canonical-answers.yaml, which made `subs` always empty and effectively asserted `template == canonical-AGENTS.md` byte-equal. That's unsatisfiable after wizard substitution of `{{PRIMARY_DOMAIN}}` etc. Replaced with the wizard-render shape the 11-01 plan documented as the intended fallback ("re-use Phase 8 test shape").

### Task 2 — docs runbook + REQUIREMENTS + Tier-1 DR + wiki/index + wiki/log + Rule 3 test relaxations

- docs/reference/brownfield.md: populated ## suggest (flags, output contract, scan scope, D-09 metadata header example), inserted new ## review-typing section (TTY small-batch session example + large-batch AI handoff + decision-boundary quote), populated ## verify (flags, stale-artifact WARN, 5-gate pass-list, performance note), added ## Lifecycle walkthrough + ## Troubleshooting table. Troubleshooting table covers item 4 (EOF hangs), item 9 (stale artifact WARN), item 11 (override label rejection) per 11-REVIEWS.md.
- .planning/REQUIREMENTS.md:
  - BRWN-12 wording amended: `04-privacy-classification.sh` → `04-privacy-review.sh` per D-07 rename (fail-closed preserved; advisory-only).
  - BRWN-18 / BRWN-19 / BRWN-20 flipped Pending → Complete (docs + AGENTS.md §11.5 shipped this plan).
  - BRWN-22 added as a new requirement: review-typing orchestrator dual-mode (TTY small-batch + AI handoff large-batch) + EOF safety (item 4) + label validation (item 11) + no-LLM-in-CLI (BRWN-16 hard-lock).
  - Traceability table: BRWN-11..20 + BRWN-22 rows all marked Complete.
  - Coverage summary: v1.1 requirements 78 → 79; Phase 11 mapped count 10 → 11.
- wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md: 120-line Tier-1 DR per D-21. Frontmatter uses `trigger_type: schema-update` + `affected_pages: []` (infrastructure record — no wiki content pages are structurally affected; the 15 artifacts in Affected Pages are schema/docs/code, not wiki content). Seven required sections per §4.6 (TL;DR, Decision, Why, Alternatives Considered with 11 alternatives, Consequences documenting items 1–11 with locking-test references, Affected Pages enumerating 15 artifacts, Sources citing 6 planning documents).
- wiki/index.md: new DR wikilink appended under ## Decisions section (4th entry; Obsidian resolves via the DR's `title` field per §8 exact-title rule).
- wiki/log.md: `## [2026-04-20] reflect | Phase 11 brownfield apply-vs-advisory architecture + review-feedback hardenings` entry appended at EOF per §12 newest-at-bottom convention. Entry references the DR slug + all 11 review-feedback items + 8 rejected alternatives.

### Rule 3 test relaxations

- tests/phase-07/test_wiki_skeleton.sh: raised wiki/index.md line cap from 30 to 40. Adding the Phase 11 DR pushed the index from 30 → 31 lines; the 30-line cap was set in Phase 7 when there were 3 DRs; Phase 9.1 added a DR (reached 30); Phase 11 adds another. The cap raise accommodates natural DR-section growth per the Plan 09.1-02 precedent.
- tests/phase-10/test_brownfield_docs_populated.sh: removed the `[Populated in Phase 11]` stub-marker assertion (`count ≥ 2`) now that Plan 11-05 has populated the suggest + verify sections. Plan 08-04 and Plan 09.1-02 establish the precedent of relaxing a Phase-N test when a later Phase-M populates the referenced content.

## Verification

### Tests

- `bash tests/phase-11/run.sh` — **47/47 GREEN** (unfiltered)
- `bash tests/phase-11/run.sh --expected-by 11-05` — **7/7 GREEN**
- `bash tests/phase-11/run.sh --expected-by 11-01` — **3/3 GREEN** (non-regression of Wave-0 canaries)
- `bash tests/phase-11/run.sh --expected-by 11-02` — **7/7 GREEN**
- `bash tests/phase-11/run.sh --expected-by 11-03` — **19/19 GREEN**
- `bash tests/phase-11/run.sh --expected-by 11-04` — **11/11 GREEN**
- `bash tests/phase-09.1/run.sh` — **11/11 GREEN** (template-parity + canonical-byte-equality pre-existing gates)
- `bash tests/phase-09/run.sh` — **28/28 GREEN**
- `bash tests/phase-08/run.sh` — **21/21 GREEN**
- `bash tests/phase-07/run.sh` — **22/22 GREEN** (after test_wiki_skeleton.sh cap raise)
- `bash tests/phase-10/run.sh` — **21/32** (11 pre-existing ruamel.yaml env-drift failures; logged in deferred-items.md per SCOPE BOUNDARY; not caused by Plan 11-05 — verified via `git stash` + fresh run on pre-edit tree)

### Done Criteria

- [x] AGENTS.md §11.5 Brownfield Workflow populated with item 1/2/9/10 review-feedback anchors; §11.6 Release Workflow renumbered.
- [x] `grep -c '^### 11.5 Brownfield Workflow' AGENTS.md` == 1; `grep -c '^### 11.5 Release Workflow' AGENTS.md` == 0; `grep -c '^### 11.6 Release Workflow' AGENTS.md` == 1.
- [x] schema/AGENTS.template.md mirrors AGENTS.md §11.5 + §11.6 byte-equivalent (Phase 9.1 template-parity test PASS).
- [x] schema/fixtures/canonical-AGENTS.md regenerated via wizard render routine; Phase 8 byte-equality test PASS.
- [x] CLAUDE.md byte-identical to AGENTS.md (`cmp -s` exit 0).
- [x] docs/reference/brownfield.md suggest + review-typing + verify sections populated; mechanical/judgment boundary discussed; troubleshooting table has item-4/9/11 entries.
- [x] REQUIREMENTS.md BRWN-12 amended; BRWN-22 added; traceability flipped; coverage count 78 → 79.
- [x] Tier-1 DR `dr-2026-04-20-brownfield-apply-vs-advisory` committed with valid frontmatter + 7 required sections + items 1–11 in Consequences.
- [x] wiki/index.md Decisions section lists the new DR.
- [x] wiki/log.md EOF has the `[2026-04-20] reflect | Phase 11 ...` entry.
- [x] Phase 10 WR-03 closed (§5 bootstrap_stage forward-ref resolves correctly).

## Decisions Made

- **Option C renumber** over Options A (leave §11.5 Release + put Brownfield at §11.5a — non-canonical) and B (put Brownfield at §11.6 + fix Phase 10 §5 forward-ref) per RESEARCH Pitfall 1. Option C closes WR-03 by construction and touches the fewest external references (RESEARCH confirmed only docs/reference/release.md references §11.5 Release, and that reference is a docs-page link not a section-number link).
- **Tier-1 DR with affected_pages: []** per AGENTS.md §4.6 infrastructure-record precedent (dr-2026-04-14-phase6-decision-type established this pattern). The 15 artifacts in the DR's Affected Pages body text are schema/docs/code — not wiki content pages that would take a `decision_history` back-link.
- **Single comprehensive DR over 11 micro-DRs** for review-feedback items: items 1–11 are implementation details of the apply-vs-advisory + review-manifest + lifecycle-gate architecture, not independent architectural choices. A DR-per-item would create retrieval noise and a spurious `decision_history` blob on unrelated pages.
- **BRWN-22 as a single-requirement orchestrator** rather than splitting review-typing dual-mode + EOF safety + label validation into separate BRWN entries. Traceability churn tradeoff: the item numbers stay clean (22, not 22a/22b/22c) and the requirement body enumerates the four sub-invariants.
- **Test-as-contract Rule 1 on test_canonical_agents_byte_equality.sh**: the Wave-0 test was written with a buggy regex that could never match the canonical-answers.yaml key shape. Rather than force canonical-answers.yaml into uppercase keys (which would break Phase 8's working byte-equality test), fixed the Phase 11 test to use the Phase 8 wizard-render shape. The 11-01 plan documented this exact fallback: "re-use Phase 8 test shape".

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed buggy regex in tests/phase-11/test_canonical_agents_byte_equality.sh**
- **Found during:** Task 1 verification after AGENTS.md + template + canonical fixture regeneration.
- **Issue:** The Wave-0 python script used `re.match(r"^([A-Z_][A-Z0-9_]*):\s*(.*?)\s*$", ln)` on canonical-answers.yaml, whose keys are all lowercase snake_case. The regex never matched anything, leaving `subs = {}` and effectively asserting `template == canonical-AGENTS.md` byte-equal — unsatisfiable after wizard substitution replaces `{{PRIMARY_DOMAIN}}` etc.
- **Fix:** Replaced the inline python block with the Phase 8 wizard-render shape — invokes `bin/init-wizard.sh --answers-file canonical-answers.yaml --render-to <tmp>` and compares the produced `AGENTS.md` byte-for-byte against the checked-in `schema/fixtures/canonical-AGENTS.md`. This matches the 11-01 plan's documented fallback ("re-use Phase 8 test shape").
- **Files modified:** `tests/phase-11/test_canonical_agents_byte_equality.sh`
- **Commit:** 2c13012

**2. [Rule 3 - Blocking] Raised wiki/index.md cap in tests/phase-07/test_wiki_skeleton.sh**
- **Found during:** Task 2 full-suite verification after adding the new DR wikilink to wiki/index.md.
- **Issue:** Test asserted `wiki/index.md ≤ 30 lines`. Phase 7 baseline was 30 lines with 3 DRs; Phase 9.1 added 1 DR (reached 30); Phase 11 adds another (31 lines > 30).
- **Fix:** Raised cap to 40 lines with a comment documenting the natural-growth rationale and the Plan 09.1-02 precedent. The test still asserts a "skeleton" shape (≤ 40 is a generous cap for a 3-DR + decisions-only wiki).
- **Files modified:** `tests/phase-07/test_wiki_skeleton.sh`
- **Commit:** f8f1929

**3. [Rule 3 - Blocking] Removed stub-marker assertion in tests/phase-10/test_brownfield_docs_populated.sh**
- **Found during:** Task 2 full-suite verification after populating the Phase 11 sections of docs/reference/brownfield.md.
- **Issue:** Test asserted `grep -c '\[Populated in Phase 11\]' doc ≥ 2`. Plan 11-05 populated the suggest + verify sections, so the stub markers are no longer present.
- **Fix:** Replaced the stub-marker assertion with an inline comment citing the Plan 11-05 tests (test_docs_suggest_section.sh, test_docs_review_typing_section.sh, test_docs_verify_section.sh) that now own the populated-content assertions. Precedent: Plan 08-04 relaxed phase-07 test_docs_skeleton.sh; Plan 09.1-02 relaxed phase-07 test_reference_stubs.sh.
- **Files modified:** `tests/phase-10/test_brownfield_docs_populated.sh`
- **Commit:** f8f1929

### Out-of-Scope Discoveries (Deferred)

See `.planning/phases/11-brownfield-suggest-verify/deferred-items.md` for the 11 pre-existing Phase-10 test failures (ruamel.yaml env drift in the Phase-10 fixture harness) — verified pre-existing via `git stash` + fresh run; outside Plan 11-05 scope per SCOPE BOUNDARY.

## Closing Notes

- **WR-03 closure verification:** `grep -c '§11.5 Brownfield Workflow' AGENTS.md` == 1 (the §5 bootstrap_stage row forward-ref text now points at the populated §11.5). `grep -c '§11.5 Release Workflow' AGENTS.md` == 0 (renumbered to §11.6). Phase 10 WR-03 (the only open Phase 10 regression item) is closed by construction.
- **BRWN-12 amendment diff (before/after):** "Four staged migration script classes: ..., `04-privacy-classification.sh`" → "Four staged migration script classes: ..., `04-privacy-review.sh` (renamed from `04-privacy-classification.sh` in Phase 11 per D-07 — fail-closed `privacy: local_only` preserved; script is advisory-only and never flips `privacy:` frontmatter)."
- **BRWN-22 wording (as committed):** "`bin/brownfield.sh review-typing` orchestrator resolves pending page-typing clusters with two modes: **small-batch TTY** (< threshold, default 20, and stdout is a TTY) with cluster primitives `approve all / reject all / inspect / override / skip`; **large-batch AI handoff** (≥ threshold OR non-TTY) via a static `.brownfield/review-typing-prompt.md` artifact consumed OUTSIDE the CLI. Both modes write back to `.brownfield/page-typing-decisions.yaml` via ruamel.yaml round-trip (preserves user comments). Small-batch prompt loop handles stdin EOF cleanly (aborts session without hanging). Override labels are validated against the `type:` enum at entry time. No LLM calls inside `bin/brownfield.sh` (BRWN-16 hard-lock)."
- **Tier-1 DR ID + items 1-11 documented:** `dr-2026-04-20-brownfield-apply-vs-advisory`. The Consequences section enumerates all 11 review-feedback items with their locking test-file references. The DR's Affected Pages lists 15 artifacts (AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, docs/reference/brownfield.md, 4 canonical migration scripts + README, bin/brownfield.sh, 3 new bin/lib/ modules, REQUIREMENTS.md).
- **CLAUDE.md sync confirmation:** `cmp -s AGENTS.md CLAUDE.md` exit 0 (byte-identical).

## Self-Check

Files verified to exist:
- AGENTS.md (FOUND; §11.5 Brownfield Workflow present at line 1171; §11.6 Release Workflow at line 1353)
- CLAUDE.md (FOUND; byte-identical to AGENTS.md)
- schema/AGENTS.template.md (FOUND; §11.5 + §11.6 mirrored)
- schema/fixtures/canonical-AGENTS.md (FOUND; regenerated; Phase 8 byte-equality PASS)
- docs/reference/brownfield.md (FOUND; suggest + review-typing + verify + lifecycle + troubleshooting populated)
- .planning/REQUIREMENTS.md (FOUND; BRWN-12 amended, BRWN-22 added, traceability flipped)
- wiki/decisions/dr-2026-04-20-brownfield-apply-vs-advisory.md (FOUND; 7 required sections + frontmatter)
- wiki/index.md (FOUND; 4th DR entry)
- wiki/log.md (FOUND; reflect entry at EOF)
- .planning/phases/11-brownfield-suggest-verify/deferred-items.md (FOUND)

Commits verified to exist:
- 2c13012 schema(11-05): populate AGENTS.md §11.5 Brownfield Workflow + renumber Release to §11.6 (FOUND)
- f8f1929 docs(11-05): populate brownfield runbook + DR + REQUIREMENTS traceability (FOUND)

## Self-Check: PASSED
