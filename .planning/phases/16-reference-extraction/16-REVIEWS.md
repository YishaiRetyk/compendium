---
phase: 16
cycle: 2
reviewers: [claude, codex]
reviewed_at: 2026-06-04T23:40:00
plans_reviewed: [16-00-PLAN.md, 16-01-PLAN.md, 16-02-PLAN.md, 16-03-PLAN.md, 16-04-PLAN.md]
prior_cycle_high: 5
current_cycle_high: 4
---

# Cross-AI Plan Review — Phase 16: Reference Extraction (Cycle 2)

**Convergence-loop cycle 2.** The plans were revised to address 5 HIGH concerns from cycle 1
(template-mirror sequencing + broken parity tests; wizard delivery gap; 16-02 line-drift;
now-false authority language; check-privacy.sh PUBLIC_PATHS). This review judges the CURRENT
state and verifies every load-bearing claim against the live repo.

**Verdict:** 3 of 5 cycle-1 HIGHs are fully resolved; 1 is partially resolved; the wizard-delivery
HIGH is contested (resolved per Claude, carried-over per Codex). Reviewing the current plans
surfaced **2 NEW HIGHs**, both verified against the live repo and both execution-blocking
(a CI-wired byte-equality gate that goes red, and a template-parity gate that cannot pass +
carries a safety-regression hazard). Net: **4 unresolved HIGH concerns.**

---

## Claude Review

All findings verified against the live repo. Three are confirmed defects (one rated above the
cycle-1 set), and the HIGH #1 residual is cleared.

### 1. Summary

The cycle-2 revisions land the structural fixes well: per-commit template mirroring is now owned
by each editing plan (16-01/02/03), §6 mutation is header-anchored (no line-drift), the §16
deletion is gated by an explicit 10-rule Appendix-C disposition table, the REF-05 verbatim truth
is grep-gated, both PUBLIC_PATHS gaps are closed in Wave 0, and a new 16-04 Task 3 rewrites the 5
monolith-shape parity tests with real post-extraction assertions. The CI-wired suites
(phase-07/08) carry NO §4/§5/§16 shape assertions, so the deferred phase-09.1/phase-10
reconciliation creates no CI-red window — the central premise of the HIGH #1 fix holds.
**However**, verifying against the live repo surfaced a NEW HIGH: the 16-04 whole-file
template-parity gate is both mis-designed and premised on a false starting state — the live
template already diverges from AGENTS.md in *resident* sections, including a **missing §3
neutrality MUST-NOT bullet** — and the gate as written cannot pass (and invites a wrong-direction
"fix" that would strip a safety rule). Two NEW MEDIUMs (a false-negative grep guard that blocks
§16 deletion; an authority-sweep regex that misses `sole authority`) round out the actionable set.

### 2. Cycle-1 HIGH Disposition

**HIGH #1 — Template-mirror sequencing + broken parity tests → RESOLVED.**
Per-commit mirror is now explicit: 16-01 STEP B.5 (§4/§5/§7), 16-02 STEP B.5 (§6), 16-03 STEP D.5
(§8/§13/§14/§15/§16 + §3 Red Links). 16-04 Task 3 rewrites all 5 named tests to post-extraction
invariants that still assert something real (region-scoped `cmp`; moved content present in leaf;
`! grep '^## 16\.'`). Verified the residual worry is unfounded: `tests/phase-07` + `tests/phase-08`
contain no section-shape markers, so the monolith-shape tests are confined to non-CI aggregators
exactly as the plans claim. The 08-04/09-06 relaxation precedent is correctly invoked.

**HIGH #2 — Wizard delivery gap → RESOLVED (with minor lean).**
16-04 STEP F.5 adds the missing post-render stub-integrity check. Actual delivery rides the
pre-existing `bin/release.sh` ALLOWLIST (`schema` confirmed present), so files ship wholesale
without new render logic; F.5 proves they exist in the source tree to be shipped. The named
concern (`--dry-run` doesn't verify pointers resolve) is closed.
*(Codex disputes — rates this carried-over HIGH; see Divergent Views.)*

**HIGH #3 — 16-02 line-drift → RESOLVED.**
16-02 now pins the AGENTS.md mutation to a header anchor, retains absolute line numbers only as
source-content identity, and repeats the "NEVER edit by literal line 399" warning in three places.
Robust.

**HIGH #4 — Now-false authority language → PARTIALLY RESOLVED.**
16-04 STEP A.5 adds the repo-wide sweep and pre-lists the right hits. Confirmed the sweep regex
catches lines 3, 5, 13, 87, 130. **But it misses line 38**: the §2 directory-tree comment
`├── AGENTS.md   # This file (sole authority)`. The term set
(`sole authoritative|sole source of truth|No other file|does NOT contain rules|does NOT contain conventions`)
does not include the bare phrase `sole authority`, and `grep -q` confirms line 38 escapes — it is
exactly the "now-false authority language beyond line 3" class this HIGH targets, surviving into
shipped AGENTS.md. One-line fix, but unfixed as written.

**HIGH #5 — check-privacy.sh PUBLIC_PATHS → RESOLVED.**
16-00 Task 2 adds `schema` to line 76 + syncs the help-text scope line + re-runs
`test_check_privacy_rekey.sh`. Closes the release-ALLOWLIST ↔ path-guard asymmetry. Verified safe
(check-privacy is a structural path guard, not a content grep).

### 3. Strengths

- **Disposition tables instead of soft "audits."** The §7 dissolution table (16-01) and the
  10-rule Appendix-C table (16-03) each map every dropped fragment to a named home with a
  programmatic confirmation, and explicitly STOP on any miss.
- **Direction-pinned safety guards.** The §7 STEP A.5 guard greps §3 for the 3 nav steps *before*
  dropping the §7 duplicate — content-loss is gated, not assumed.
- **Header-anchored edits throughout** 16-02/16-03. Line-drift class is genuinely eliminated.
- **Verbatim-truth gates are real:** `grep -q 'filename/path ONLY'` + `grep -q 'for ALL intra-wiki'`
  against wikilinks.md — a paraphrase fails the gate.
- **affected_pages: [] is the correct call**, well-justified against DRFT-04 and the §4.6
  infra-record precedent.

### 4. Concerns

- **HIGH — NEW — 16-04 whole-file template-parity gate is broken AND premised on a false starting
  state, with a safety-regression hazard.** STEP E / the Task 1 `<verify>` run
  `diff <(grep -v '{{' AGENTS.md) <(grep -v '{{' schema/AGENTS.template.md)` and require it empty.
  Ran on the *current* files: it is non-empty by construction.
  - (a) *One-sided placeholder filter:* core retains placeholders that STAY resident
    (`{{AGENT_FILENAME}}` §1, `{{PRIMARY_DOMAIN}}` §2). `grep -v '{{'` strips the template's `{{`
    lines but keeps AGENTS.md's *rendered* counterparts, so those lines always diff.
  - (b) *Pre-existing resident drift:* the live template is genuinely **missing the §3 MUST-NOT
    bullet** "DO NOT use real slugs, page IDs, or terms…" (diff hunk `138d138`) — a neutrality
    safety rule present in AGENTS.md but never mirrored to the template (Phase-12.1-era drift).
    The live diff also shows the template missing `knowledge_domain`, the asymmetric cross-tier
    link rule, multiple `wiki-local/sources/` qualifiers, and `FROM "wiki"` vs `FROM "wiki-cloud"`.
    §1/§2/§3 are resident in Phase 16, so these will fail STEP E.
  - The Task 3 region-scoped `cmp` tests only compare the *extracted* stub regions and will pass,
    masking this. As written, STEP E cannot go green; worse, an executor told "make the diff empty"
    could resolve it in the wrong direction — deleting the §3 bullet from AGENTS.md to match the
    deficient template — silently dropping a safety MUST-NOT. **Fix:** scope the parity check to
    per-section stub regions, and add a separate, direction-pinned step that reconciles pre-existing
    resident drift *into the template* (template gains the §3 bullet; AGENTS.md never loses it).

- **MEDIUM — NEW — 16-03 Task 2 STEP C rule-6 grep is a false-negative that blocks §16 deletion.**
  The guard `grep -q "DO NOT read .wiki-local. from a cloud session" AGENTS.md` does not match the
  actual text ``DO NOT read `wiki-local/` from a cloud session`` — the single `.` after
  `wiki-local` consumes the `/` but not the closing backtick, so " from a cloud session" never
  aligns. Confirmed `grep -q` returns no match. Since STEP C says "if ANY confirmation fails, STOP —
  do not delete §16," this halts §16 deletion on a present rule. Fix the pattern.

- **MEDIUM — NEW — authority-sweep regex omits `sole authority` (line 38).** See HIGH #4. Add
  `sole authority` to the term set; reconcile line 38 to router framing.

- **LOW — NEW — content-preservation verification is shallow.** Extraction verifies 1–3 headers +
  `min_lines`; it does not reconcile all subsections. A dropped mid-section subsection within the
  line budget would not be caught. RESEARCH recommended a first/last-distinctive-sentence-per-section
  check; the plans didn't adopt it as a gate.

- **LOW — NEW — 16-04 STEP F.5 scans the whole AGENTS.md**, including still-inline §9–§12, for
  `schema|docs/reference` paths and asserts `test -f`. A pre-existing reference to a not-yet-created
  doc would surface as a false failure. Worth scoping the grep to Phase-16-added stubs + table.

- **LOW — CARRIED-OVER/RESIDUAL — phase-08 masks template drift** for the resident §3 bullet (the
  byte-equality test compares wizard-render-vs-fixture, not render-vs-AGENTS.md). Ties into the
  NEW HIGH. *(See Codex's NEW HIGH for the separate fixture-staleness break.)*

### 5. Suggestions

1. **Replace STEP E's whole-file diff** with the region-scoped `cmp` approach Task 3 already uses,
   and add a one-time resident-drift reconciliation task that pins direction: template brought up
   to AGENTS.md in §1/§2/§3 (add the missing §3 "DO NOT use real slugs" bullet to the template),
   never the reverse.
2. **Add `sole authority` to the STEP A.5 sweep** and reconcile line 38.
3. **Fix the rule-6 grep** in 16-03 STEP C.
4. **Add a content-preservation gate** per RESEARCH: first + last distinctive sentence per section.
5. **Scope F.5's path grep** to the Phase-16 stub/routing-table region.

### 6. Risk Assessment — MEDIUM

HIGH #1/#2/#3/#5 are fully resolved and HIGH #4 is 95% there (one regex term). What keeps risk at
MEDIUM is the NEW HIGH: the final wiring plan's central template-parity gate cannot pass as written,
rests on a verified-false assumption, and carries a concrete safety-regression path. Every finding
is localized to verification logic / scope and fixable without rethinking the extraction design.

---

## Codex Review

### Summary

The revised plans resolve the main extraction sequencing problems and are much stronger on
per-commit template mirroring, content-loss disposition, and routing-table safety. However, the
wizard delivery HIGH is still only partially handled, and there are new gate risks around the
Phase 08 canonical wizard fixture and the proposed template parity check. I would not approve
execution as-is until those are fixed.

### Cycle-1 HIGH Disposition

1. **Template-mirror sequencing + broken parity tests: FULLY RESOLVED.** Plans 16-01/02/03 require
   the template to mirror each section's stub/deletion in the same commit; 16-04 Task 3 rewrites
   and runs the five named phase-09.1/phase-10 tests against the post-extraction shape.

2. **Wizard delivery gap: PARTIALLY RESOLVED.** 16-04 adds post-render stub-integrity checks, but
   no plan modifies `bin/init-wizard.sh`, and `files_modified` omits it. The wizard still renders
   only the five artifacts; the plan checks live-repo path existence, not that generated output
   contains `schema/reference/*`, `schema/workflows/lint.md`, or the new `docs/reference/*` files.

3. **16-02 line-drift: FULLY RESOLVED.** §6 mutation is header-anchored, not line-addressed.

4. **Now-false authority language: PARTIALLY RESOLVED.** 16-04 Task 1 adds the AGENTS.md sweep and
   calls out the §2 false sentence, but the command runs only over AGENTS.md (template handled
   manually), and misses active generated fixtures unless separately added.

5. **check-privacy.sh PUBLIC_PATHS: FULLY RESOLVED.** 16-00 Task 2 adds `schema` to PUBLIC_PATHS
   and help text and verifies both check-privacy.sh and the phase-15 privacy test.

### Strengths

- Per-commit template mirroring is now owned in the plans that mutate each section.
- The routing table cleanly separates resolvable references from Phase-17 workflow placeholders.
- The §7 and Appendix C disposition tables are concrete enough to prevent silent deletion.
- REF-05 is grep-gated with the exact `filename/path ONLY` and `for ALL intra-wiki` phrases.
- The §6 consumer split keeps contradiction syntax in provenance rather than lint.
- `affected_pages: []` for the DR is the right call given the infra-record precedent.

### Concerns

- **HIGH, CARRIED-OVER:** Wizard delivery is still not fixed. 16-04 F.5 validates pointer existence
  in the source repo, but does not make wizard-generated output contain the referenced files. Add
  an explicit `bin/init-wizard.sh` change or a documented invariant plus tests proving generated
  projects include the reference tree.

- **HIGH, NEW:** Phase 08 will likely go red because `schema/AGENTS.template.md` changes but
  `schema/fixtures/canonical-AGENTS.md` is not listed or regenerated. Existing phase-08 tests
  compare rendered wizard output byte-for-byte against that fixture. Plan 16-04 says phase-08
  passes, but the `files_modified` list omits the fixture.

- **MEDIUM, NEW:** The template parity check `diff <(grep -v '{{' AGENTS.md) <(grep -v '{{' template)`
  is not a sound comparison. Removing placeholder lines only from the template leaves the rendered
  AGENTS.md counterpart lines in place, so this can fail even when the template is correct.

- **MEDIUM, CARRIED-OVER:** The authority-language sweep is not actually repo-wide. It should cover
  AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, and public
  docs/templates, with explicit exemptions for historical decision records.

- **MEDIUM, NEW:** Plan 16-02 still shows an extraction example using
  `awk '/^## 6\./{f=1} /^## 7\./{exit} f'`. After 16-01 deletes §7, that command overcaptures to
  EOF. The mutation step is correct, but the example should be a true "next heading" extractor.

- **MEDIUM, NEW:** Placeholder migration into extracted leaf files is ambiguous. The plans mention
  `{{PRIMARY_DOMAIN}}` and `{{DECAY_PROFILE}}` moving with extracted content, but init-wizard.sh
  does not render reference files. Add a no-leftover-placeholder scan over all delivered reference
  files, or keep those examples non-personalized.

- **LOW, NEW:** scaling.md and tooling.md link to `docs/reference/index.md`; verify it exists
  (it does) — or remove the See Also link if not.

### Suggestions

- Add a Plan 16 task to update `bin/init-wizard.sh` so output includes the new reference/doc files,
  or explicitly constrain wizard usage to an already-complete template checkout and test that.
- **Regenerate and commit `schema/fixtures/canonical-AGENTS.md` after template changes.**
- Replace the `grep -v '{{'` parity check with a rendered-template comparison or targeted
  section-stub comparisons.
- Use `rg` for the authority sweep across public/template surfaces with a documented exemption list.
- Replace all `^## 7\.` extraction terminators with "next `^## [0-9]+\.` header" logic.

### Risk Assessment: HIGH

The extraction design is mostly sound, but as written the plans can still leave the wizard path
broken and Phase 08 red. Once wizard delivery, canonical fixture regeneration, and the parity diff
check are fixed, residual risk drops to LOW-MEDIUM.

---

## Consensus Summary

Both reviewers agree the cycle-2 revisions are strong on the structural axes (per-commit template
mirror ownership, header-anchored edits, disposition tables, verbatim grep gates, both PUBLIC_PATHS
fixes). Both independently flag that the **template/fixture/wizard layer is still not
execution-clean**, and both rate at least one NEW HIGH. Every finding was verified against the live
repo by the orchestrator.

### Agreed Strengths

- Per-commit template mirroring is now owned by each editing plan (16-01/02/03) — HIGH #1 structural
  fix landed.
- §6 mutation is header-anchored; the line-drift class (HIGH #3) is genuinely eliminated.
- §7 + Appendix-C disposition tables map every dropped fragment to a named home with a STOP-on-miss
  programmatic check.
- REF-05 verbatim truth is grep-gated (paraphrase fails).
- check-privacy.sh PUBLIC_PATHS fix (HIGH #5) is correct and safe.
- `affected_pages: []` is the right DR call.

### Agreed Concerns (highest priority — both reviewers)

1. **[HIGH] The template-parity gate `diff <(grep -v '{{' AGENTS.md) <(grep -v '{{' template)` is
   unsound.** Both reviewers independently flag the one-sided placeholder filter (Claude rates the
   combined defect HIGH because the live template ALSO has pre-existing resident drift incl. a
   missing §3 neutrality MUST-NOT bullet + a safety-regression hazard; Codex rates the comparison-logic
   half MEDIUM). **Verified:** the live whole-file diff is non-empty by construction (placeholder
   asymmetry + `138d138` missing §3 bullet + `knowledge_domain` line + asymmetric cross-tier link
   rule + `wiki-local/sources/` qualifiers + `FROM "wiki"` all absent from the template). The gate
   in 16-04 STEP E and the Task 1 `<verify>` block cannot pass as written.

2. **[HIGH] Wizard / fixture delivery is not execution-clean.** Codex pins the sharpest, verified
   form: `tests/phase-08/test_canonical_byte_equality.sh` (CI-wired) renders the wizard from
   `schema/AGENTS.template.md` and asserts byte-equality against the committed
   `schema/fixtures/canonical-AGENTS.md` (115 KB full monolith). The moment 16-01 mutates the
   template, this fixture goes stale and **phase-08 goes red** — yet 16-04 Task 2 STEP D asserts
   phase-08 must PASS, no plan lists the fixture in `files_modified`, and no plan regenerates it.
   Claude's narrower wizard-delivery point (stub-integrity) is resolved by F.5; the fixture-staleness
   break is separate and unaddressed.

3. **[HIGH-partial] Authority-language sweep misses hits.** Both: the sweep is not truly repo-wide.
   Claude verified line 38 `# This file (sole authority)` escapes the regex term set; Codex notes the
   command runs only over AGENTS.md and omits the canonical fixture + template + docs surfaces.

### Divergent Views

- **Wizard delivery (cycle-1 HIGH #2) status.** Claude rates **RESOLVED** — actual delivery rides
  the release.sh ALLOWLIST wholesale copy (verified `schema` present), and F.5 closes the named
  stub-resolution gap. Codex rates **PARTIALLY RESOLVED / carried-over HIGH** — no init-wizard.sh
  change and F.5 checks source-repo existence, not generated output. **Resolution path:** both agree
  F.5 is necessary but not a delivery mechanism; the durable fix is either an init-wizard.sh change
  or a documented+tested invariant that release ships the reference tree. Counted as one unresolved
  HIGH given the residual ambiguity + Codex's stricter read.

- **Template-parity-gate severity.** Claude HIGH (because of the compound resident-drift +
  safety-regression hazard, repo-verified); Codex MEDIUM (comparison-logic only). **Resolution
  path:** adopt the higher severity — the verified missing §3 neutrality bullet + the wrong-direction
  "fix" hazard make this a HIGH, not a cosmetic gate bug.

### NEW MEDIUM / LOW worth fixing in the next replan

- 16-03 STEP C rule-6 grep is a false-negative (backtick-sensitive `.` pattern) that would STOP §16
  deletion on a present rule (Claude, verified).
- 16-02's `awk '…/^## 7\./{exit}…'` example overcaptures to EOF after §7 is deleted; use a generic
  "next `^## [0-9]+\.`" terminator (Codex).
- No-leftover-placeholder scan over delivered reference leaf files ({{PRIMARY_DOMAIN}},
  {{DECAY_PROFILE}} migration) (Codex).
- Content-preservation gate is shallow (headers + min_lines only); add first/last distinctive
  sentence per extracted section (Claude).
- F.5 path grep scans whole AGENTS.md incl. still-inline §9–§12; scope to Phase-16 region (Claude).

### Unresolved HIGH count this cycle: 4

1. **NEW** — Template-parity gate (`grep -v '{{'` whole-file diff) cannot pass + resident-drift +
   safety-regression hazard (missing §3 neutrality bullet). [repo-verified]
2. **NEW** — `schema/fixtures/canonical-AGENTS.md` not regenerated → CI-wired phase-08
   byte-equality test goes red, contradicting 16-04's stated success condition. [repo-verified]
3. **PARTIAL (carried-over #4)** — Authority-language sweep misses `sole authority` (line 38) and
   does not cover the canonical fixture / template / docs surfaces. [repo-verified]
4. **PARTIAL (carried-over #2)** — Wizard delivery: no init-wizard.sh change or tested
   ship-the-reference-tree invariant; F.5 checks source-repo existence, not generated output.
   (Contested: Claude RESOLVED, Codex carried-over HIGH.)
