---
id: 12-04-audit-and-verification
plan_id: 12-04
phase: 12
plan: 04
wave: 3
type: execute
depends_on:
  - 12-01-decision-record
  - 12-02-reference-doc
  - 12-03-surface-integration
files_modified:
  - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md
  - .planning/REQUIREMENTS.md
requirements:
  - BOUND-01
  - BOUND-02
  - BOUND-03
autonomous: true
must_haves:
  truths:
    - "12-VERIFICATION.md exists and records BOUND-01/02/03 as Complete with explicit file-path evidence for each."
    - "12-VERIFICATION.md contains the captured phase-base SHA used for the diff acceptance check, the verbatim audit grep command, and an annotated reviewed-match audit table where every grep hit carries verdict `negative-framing` or `positive-claim`."
    - "Zero match rows in the audit table carry the `positive-claim` verdict."
    - "REQUIREMENTS.md BOUND-01/02/03 checkboxes are flipped from [ ] to [x] and the traceability rows are updated from Pending to Complete."
    - "bin/requirements-sync.sh --strict --phase 12 exits 0 after VERIFICATION.md and REQUIREMENTS.md edits."
    - "git diff over phase-12 commits (anchored on the captured phase-base SHA) shows zero files under bin/ or schema/, and zero content edits to AGENTS.md / CLAUDE.md."
    - "find wiki -maxdepth 1 -type d returns the same set as before Phase 12 (no new top-level wiki directories)."
    - "AGENTS.md §4 page-type enum still lists exactly 6 types (entity, concept, source, comparison, overview, decision)."
  artifacts:
    - path: .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md
      provides: "Phase 12 verification artifact — REQ-ID rows + audit table + phase-base SHA"
      contains: "BOUND-01"
    - path: .planning/REQUIREMENTS.md
      provides: "Status flips for BOUND-01/02/03 (Pending → Complete in checkboxes + traceability table)"
      contains: "[x] **BOUND-01**"
  key_links:
    - from: .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md
      to: wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
      via: "evidence path for BOUND-01"
      pattern: "dr-2026-05-01-complementary-systems-boundary"
    - from: .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md
      to: docs/reference/three-layer-model.md
      via: "evidence path for BOUND-02"
      pattern: "three-layer-model.md"
---

<objective>
Capture the phase-base SHA, run the reviewed-match audit (BOUND-03), enumerate every grep hit with a `negative-framing` or `positive-claim` verdict, write the Phase 12 verification artifact, flip REQUIREMENTS.md status for BOUND-01/02/03, and prove zero `bin/` / `schema/` / `AGENTS.md` / `CLAUDE.md` content drift.

Purpose: Close BOUND-01, BOUND-02, BOUND-03 with mechanical evidence. Make `bin/requirements-sync.sh --strict --phase 12` exit 0 so the v1.1 closure gate (`CLOSE-01`) can later verify Phase 12 cleanly.
Output: One new `12-VERIFICATION.md` artifact + targeted edits to `.planning/REQUIREMENTS.md` (3 checkbox flips + 3 traceability table cell flips).
</objective>

<context>
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md
@.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md
@.planning/REQUIREMENTS.md
@.planning/phases/07-neutral-template-foundation/07-VERIFICATION.md
@.planning/phases/11-brownfield-suggest-verify/11-VERIFICATION.md
@wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md
@docs/reference/three-layer-model.md
@README.md
@docs/reference/index.md
@wiki/index.md
@wiki/log.md
</context>

<threat_model>
N/A — pure docs phase. This plan creates one new verification artifact under .planning/phases/, edits REQUIREMENTS.md status fields, and runs read-only grep audits. No executable code paths, no API surface, no new attack surface introduced.

The reviewed-match audit (BOUND-03) is the closest analog to a threat-mitigation step in this phase — it ensures the canonical shipped surface does not assert ownership claims that would mislead operators about compendium's role inside a multi-system stack.
</threat_model>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Capture phase-base SHA, run audit grep, write 12-VERIFICATION.md, flip REQUIREMENTS.md, run requirements-sync</name>
  <files>.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md, .planning/REQUIREMENTS.md</files>
  <read_first>
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md (acceptance criteria — phase-base SHA capture, reviewed-match audit semantics, REQUIREMENTS.md status flips, requirements-sync exit 0, find wiki -maxdepth 1 invariant, AGENTS.md §4 enum invariant)
    - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md (D-12 audit grep patterns Core6 + bounded `replaces` regex; D-13 audit scope README + AGENTS.md + docs/ + wiki/decisions/; D-14 reviewed-match procedure)
    - .planning/REQUIREMENTS.md (current state of BOUND-01/02/03 — both the checkbox lines under "### Complementary Systems Boundary (BOUND)" and the traceability table rows; read these BEFORE editing so the executor sees exact line shapes to flip)
    - .planning/phases/07-neutral-template-foundation/07-VERIFICATION.md (Phase 7 contract for VERIFICATION.md REQ-ID parser — bare bullets / [x] checkboxes / **bold** REQ-IDs all tolerated; copy structural shape)
    - .planning/phases/11-brownfield-suggest-verify/11-VERIFICATION.md (most recent VERIFICATION.md — closest precedent for shape, format, evidence-row cadence)
    - wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md (must exist from Plan 12-01 — evidence path for BOUND-01)
    - docs/reference/three-layer-model.md (must exist from Plan 12-02 — evidence path for BOUND-02)
    - README.md, docs/reference/index.md, wiki/index.md, wiki/log.md (must have Plan 12-03 edits — evidence paths for BOUND-02 / BOUND-03)
  </read_first>
  <action>
**Step 1 — Capture the phase-base SHA:**

Run:

```bash
PHASE_BASE_SHA=$(git rev-parse HEAD)
echo "$PHASE_BASE_SHA"
```

**IMPORTANT:** This SHA must be captured BEFORE writing 12-VERIFICATION.md. The captured SHA is the anchor for the diff acceptance check (SPEC requirement #6 / AC #14). The repo has `branching_strategy: none` (per `.planning/config.json`), so Phase 12 commits land directly on `main`. The SHA captured here is the "phase-base SHA" referenced in 12-VERIFICATION.md.

Note: At plan time, HEAD is the SPEC commit `ef3afecf` (commit hash `ef3afec61fe211c88f3b965b83e96d67dd0b609d`). At execute-phase time, HEAD may be one or more commits ahead if Plans 12-01 / 12-02 / 12-03 have already committed. The executor MUST capture HEAD AT THE START of Plan 12-04 execution — that is the SHA *before* any Plan 12-04 commit lands. Record both the long form (40-char) and short form (7+ char) so future operators can reproduce the diff.

If at execute time the executor wants to re-anchor to the original SPEC-commit SHA (the safer / more conservative anchor that captures every Plan 12-01..12-03 file as part of the diff), use:

```bash
PHASE_BASE_SHA=$(git log --format=%H -n 1 -- .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md)
```

The decision between the two anchors is operator discretion — the second form is more conservative (captures the full Phase 12 diff including this plan's predecessors) and is recommended.

**Step 2 — Run the reviewed-match audit grep (per D-12 + D-14):**

Run this command verbatim and capture every matching line:

```bash
grep -rEni 'all-in-one|task manager|task backend|reminder system|calendar app|inbox interface|(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)' README.md AGENTS.md docs/ wiki/decisions/
```

Save the full raw output (path:line:text triples) so it can be reproduced verbatim.

For each match, annotate with verdict:
- **`negative-framing`** — the match appears inside an Anti-features / Alternatives-Considered / boundary-clarification context, OR explicitly disclaims compendium IS such a system, OR appears inside the new BOUND-01 DR's Alternatives Considered section, OR appears inside the new BOUND-02 doc's Anti-features section, OR appears in a quoted/cited rejection.
- **`positive-claim`** — the match asserts compendium IS such a system (e.g., "compendium is a task manager", "compendium replaces your calendar"). PHASE FAILS if any row carries this verdict.

**Step 3 — Write 12-VERIFICATION.md** at `.planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` with the following structure:

```markdown
# Phase 12 Verification — Complementary Systems Boundary + GTD Alignment

**Phase:** 12-complementary-systems-boundary-gtd-alignment
**Status:** Complete
**Verified:** 2026-05-01
**Phase-base SHA (anchor for diff acceptance check):** `<PHASE_BASE_SHA short-form>` (full: `<PHASE_BASE_SHA long-form>`)

## REQ-ID Verification

- [x] **BOUND-01** — Decision record exists capturing the complementary-systems boundary.
  - Evidence: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (type: decision; trigger_type: schema-update; affected_pages: []; 7 required sections present; passes `bin/lint.sh --category yaml,provenance`).
  - Acceptance: SPEC requirement 1, AC #1 + AC #2.

- [x] **BOUND-02** — Reference doc explains the 3-layer model and routing rules.
  - Evidence: `docs/reference/three-layer-model.md` (3-layer model section names task / working-memory / wiki-compiler layers; routing table contains 4 verbs `capture / clarify / organize / review`; `## Anti-features` section has explicit bullets for inbox, next-action execution, calendar, reminders, rapid transactional, high-churn waiting-for, Slack/ticket/event-stream).
  - Evidence: `docs/reference/index.md` (lists the new ref doc).
  - Evidence: `wiki/index.md` Decisions section (lists the BOUND-01 DR).
  - Acceptance: SPEC requirement 2, AC #3 + AC #4 + AC #6.

- [x] **BOUND-03** — Surface consistency: README pointer + reviewed-match audit + zero new wiki page types / taxonomies.
  - Evidence: `README.md` (single new contextual pointer sentence under "What this is" section pointing at `docs/reference/three-layer-model.md`; locked D-10 wording confirmed verbatim).
  - Evidence: Reviewed-match audit (below) — every grep hit verdicted `negative-framing`; zero `positive-claim` rows.
  - Evidence: `find wiki -maxdepth 1 -type d` invariant — same set before / after Phase 12 (`wiki`, `wiki/decisions`, `wiki/maintenance`).
  - Evidence: AGENTS.md §4 page-type enum unchanged — still 6 types (entity, concept, source, comparison, overview, decision).
  - Evidence: `wiki/log.md` reflect entry recorded.
  - Acceptance: SPEC requirement 3, AC #5 + AC #7 + AC #8 + AC #9 + AC #10.

## Reviewed-Match Audit (BOUND-03)

**Audit command (reproducible — paste into a shell at the repo root):**

```bash
grep -rEni 'all-in-one|task manager|task backend|reminder system|calendar app|inbox interface|(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)' README.md AGENTS.md docs/ wiki/decisions/
```

**Audit scope:** README.md, AGENTS.md, docs/ (recursive), wiki/decisions/ (recursive). Excludes `.planning/`, `examples/`, `wiki/concepts/`, `wiki/entities/`, etc. — per D-13.

**Patterns:** Core 6 (`all-in-one`, `task manager`, `task backend`, `reminder system`, `calendar app`, `inbox interface`) + bounded regex `(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)` per D-12.

**Results:**

| # | Path:Line | Match text (excerpt) | Context | Verdict |
|---|-----------|----------------------|---------|---------|
| 1 | <path>:<line> | <verbatim excerpt> | <Anti-features section / Alternatives Considered / boundary-clarification / etc.> | negative-framing |
| ... | ... | ... | ... | ... |

(Populate this table from the actual grep output run during Step 2. Every match becomes a row; columns are populated from the path:line:text triple. Add a "Context" column that explains where the match sits — e.g., "docs/reference/three-layer-model.md ## Anti-features bullet", "wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md ## Alternatives Considered first bullet". Verdict is `negative-framing` or `positive-claim`.)

**Total matches:** N (where N = the number of grep hits).
**Negative-framing rows:** N (must equal total).
**Positive-claim rows:** 0 (PASS condition; phase fails if > 0).

**Audit verdict:** PASS — zero `positive-claim` rows.

## Diff Scope Verification (SPEC requirement #6 / AC #14)

**Phase-base SHA:** `<PHASE_BASE_SHA>` (captured at Plan 12-04 execute-time; recorded above).

**Diff command (reproducible):**

```bash
git diff --name-only <PHASE_BASE_SHA>..HEAD
```

**Expected files-modified set:** Some subset of these allowed paths only:
- `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (BOUND-01)
- `docs/reference/three-layer-model.md` (BOUND-02)
- `docs/reference/index.md` (BOUND-02 surface)
- `README.md` (BOUND-03 surface)
- `wiki/index.md` (Decisions section entry per AGENTS.md §11.4 step 5)
- `wiki/log.md` (single reflect entry per AGENTS.md §11.4 step 6 / §12)
- `.planning/REQUIREMENTS.md` (status flips)
- `.planning/phases/12-complementary-systems-boundary-gtd-alignment/*` (planning artifacts including this VERIFICATION.md and the 4 PLAN.md files)
- `.planning/STATE.md` (state snapshot — optional, may be touched by orchestrator)

**Forbidden paths:** zero files under `bin/`, zero files under `schema/`, zero content edits to `AGENTS.md` or `CLAUDE.md`.

**Verification commands:**

```bash
# No bin/ or schema/ edits:
git diff --name-only <PHASE_BASE_SHA>..HEAD | grep -E '^(bin|schema)/' | wc -l   # expect 0

# AGENTS.md and CLAUDE.md content unchanged (path may appear in --name-only if any related-file commit touched them, but content diff must be empty):
git diff <PHASE_BASE_SHA>..HEAD -- AGENTS.md CLAUDE.md | wc -l                  # expect 0
```

**Verdict:** PASS — zero `bin/` or `schema/` files in the diff; zero content changes to AGENTS.md / CLAUDE.md.

## Wiki Taxonomy Invariant (BOUND-03)

**Command:**

```bash
find wiki -maxdepth 1 -type d
```

**Pre-Phase-12 set:** `wiki`, `wiki/decisions`, `wiki/maintenance`.
**Post-Phase-12 set:** `wiki`, `wiki/decisions`, `wiki/maintenance` (identical — no new top-level wiki directories added).
**Verdict:** PASS.

## AGENTS.md §4 Page-Type Enum Invariant (BOUND-03)

**Pre-Phase-12 enum:** entity, concept, source, comparison, overview, decision (6 types).
**Post-Phase-12 enum:** entity, concept, source, comparison, overview, decision (6 types — unchanged).
**Verdict:** PASS.

## requirements-sync Verification

**Command:**

```bash
bash bin/requirements-sync.sh --strict --phase 12
```

**Exit code:** 0
**Output:** zero drift between `REQUIREMENTS.md` BOUND-01/02/03 status and this VERIFICATION.md.

## Notes

- Phase 12 ships zero `bin/` changes, zero schema changes, zero new page types, zero new wiki taxonomies. Pure docs + decision record + surface integration.
- The reviewed-match audit is **not** an automated CI gate; it is a one-time inline shell command captured here for reproducibility. If future drift becomes a recurring issue, promote `bin/check-boundary.sh` from the Deferred Ideas list (CONTEXT.md) to a v1.2 phase.
- `bin/check-neutrality.sh` was NOT used as boundary-framing evidence (per D-14 note — it scans for creator-specific terms, not framing patterns; it may run independently as a public-surface sanity check but is not load-bearing for BOUND-03).
- Subsequent phases (12.1, 12.2, 13, 13.1, 13.2) reference Phase 12's boundary as a settled fact; no Phase 12 amendment is expected.

---

*Phase: 12-complementary-systems-boundary-gtd-alignment*
*Verified: 2026-05-01*
*Phase-base SHA: `<PHASE_BASE_SHA>`*
```

**Step 4 — Flip REQUIREMENTS.md status (3 edits + 3 table cells):**

Read `.planning/REQUIREMENTS.md` first to confirm exact current shape. The current state (per the file as of plan time):

- Section "### Complementary Systems Boundary (BOUND)" lists three items with `- [ ] **BOUND-0X**: ...` shape.
- Traceability table rows at lines 273–275 read:
  ```
  | BOUND-01 | Phase 12 | Pending |
  | BOUND-02 | Phase 12 | Pending |
  | BOUND-03 | Phase 12 | Pending |
  ```

Apply these EXACT edits using a precise file edit (NOT a global sed):

1. Find each line matching `^- \[ \] \*\*BOUND-0[123]\*\*:` and change `[ ]` to `[x]`. (Three lines total in the BOUND section.)
2. Find each traceability table row matching `^\| BOUND-0[123] \| Phase 12 \| Pending \|$` and change `Pending` to `Complete`. (Three rows total.)

Do NOT touch any other REQUIREMENTS.md content. Do NOT touch the `## Coverage:` summary lines (those describe phase mappings, not status counts).

**Step 5 — Run requirements-sync:**

```bash
bash bin/requirements-sync.sh --strict --phase 12
echo "exit=$?"
```

This MUST exit 0. If it exits non-zero, inspect the drift output and fix the discrepancy (most likely: a typo in 12-VERIFICATION.md REQ-ID rows that the parser cannot match, or a missing checkbox flip). After the fix, re-run until exit 0.

**Step 6 — Final pre-commit checks (read-only, do NOT edit):**

```bash
# Verify no AGENTS.md / CLAUDE.md content drift since the captured SHA:
git diff <PHASE_BASE_SHA>..HEAD -- AGENTS.md CLAUDE.md | wc -l   # expect 0

# Verify no bin/ or schema/ files in the diff:
git diff --name-only <PHASE_BASE_SHA>..HEAD | grep -E '^(bin|schema)/' | wc -l   # expect 0

# Verify wiki taxonomy invariant:
find wiki -maxdepth 1 -type d | sort   # expect wiki / wiki/decisions / wiki/maintenance only

# Verify AGENTS.md §4 page-type enum unchanged:
grep -E 'entity|concept|source|comparison|overview|decision' AGENTS.md | head -20   # spot-check; full check is the diff above

# Verify the reviewed-match audit grep produces non-empty output AND zero positive-claim rows (operator review):
grep -rEni 'all-in-one|task manager|task backend|reminder system|calendar app|inbox interface|(replaces|replacement for) (a |an |your )?(task|gtd|todo|reminder|calendar|inbox)' README.md AGENTS.md docs/ wiki/decisions/
```

If any check fails, do NOT commit — investigate and fix the underlying issue. The orchestrator (gsd-execute-phase) will commit only on full pass.
  </action>
  <verify>
    <automated>test -f .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md && grep -c '^- \[x\] \*\*BOUND-0[123]\*\*' .planning/REQUIREMENTS.md | grep -q '^3$' && grep -cE '^\| BOUND-0[123] \| Phase 12 \| Complete \|$' .planning/REQUIREMENTS.md | grep -q '^3$' && bash bin/requirements-sync.sh --strict --phase 12 >/dev/null 2>&1</automated>
  </verify>
  <acceptance_criteria>
    - 12-VERIFICATION.md exists: `test -f .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns exit 0.
    - 12-VERIFICATION.md contains REQ-ID rows for all three BOUND requirements: `grep -cE '\*\*BOUND-0[123]\*\*' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 3.
    - 12-VERIFICATION.md records the captured phase-base SHA: `grep -cE 'Phase-base SHA' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 1, AND the SHA value is a valid git ref: `SHA=$(grep -oE '[0-9a-f]{7,40}' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md | head -1) && git cat-file -e $SHA` exits 0.
    - 12-VERIFICATION.md contains the verbatim audit grep command: `grep -cE 'grep -rEni .*all-in-one.*task manager.*task backend' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 1.
    - 12-VERIFICATION.md contains the audit results table with at least 1 row: `grep -cE '^\| [0-9]+ \|.*\| (negative-framing|positive-claim) \|$' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 1.
    - 12-VERIFICATION.md has zero `positive-claim` verdicts: `grep -cE '\| positive-claim \|' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns exactly 0.
    - 12-VERIFICATION.md cites the BOUND-01 DR by file path: `grep -c 'wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 1.
    - 12-VERIFICATION.md cites the BOUND-02 ref doc by file path: `grep -c 'docs/reference/three-layer-model.md' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md` returns at least 1.
    - REQUIREMENTS.md BOUND-01/02/03 checkboxes flipped: `grep -cE '^- \[x\] \*\*BOUND-0[123]\*\*' .planning/REQUIREMENTS.md` returns exactly 3.
    - REQUIREMENTS.md still has zero `[ ] **BOUND-0[123]**` lines (nothing left Pending in BOUND section): `grep -cE '^- \[ \] \*\*BOUND-0[123]\*\*' .planning/REQUIREMENTS.md` returns exactly 0.
    - REQUIREMENTS.md traceability table rows flipped: `grep -cE '^\| BOUND-0[123] \| Phase 12 \| Complete \|$' .planning/REQUIREMENTS.md` returns exactly 3.
    - REQUIREMENTS.md traceability table has zero remaining `BOUND-0[123].*Pending` rows: `grep -cE '^\| BOUND-0[123] \| Phase 12 \| Pending \|$' .planning/REQUIREMENTS.md` returns exactly 0.
    - bin/requirements-sync.sh strict-phase-12 exits 0: `bash bin/requirements-sync.sh --strict --phase 12; echo $?` returns 0.
    - Wiki taxonomy invariant holds: `find wiki -maxdepth 1 -type d | sort | tr '\n' ',' ` equals `wiki,wiki/decisions,wiki/maintenance,` exactly.
    - Diff over phase-12 commits contains zero bin/ or schema/ files (anchored to the captured SHA in VERIFICATION.md): `SHA=$(grep -oE '[0-9a-f]{7,40}' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md | head -1) && git diff --name-only ${SHA}..HEAD | grep -cE '^(bin|schema)/'` returns 0.
    - AGENTS.md / CLAUDE.md content diff is empty since the phase-base SHA: `SHA=$(grep -oE '[0-9a-f]{7,40}' .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-VERIFICATION.md | head -1) && git diff ${SHA}..HEAD -- AGENTS.md CLAUDE.md | wc -l` returns 0.
    - AGENTS.md §4 page-type enum still lists exactly 6 types: `awk '/^## 4\. Page Types/,/^## 5\. /' AGENTS.md | grep -cE '^### 4\.' ` returns at least 6.
    - The reviewed-match audit produces matches inside the BOUND-01 DR's Alternatives Considered section (sanity check that the grep is correctly scoped and the DR is being scanned): `awk '/^## Alternatives Considered$/,/^## Consequences$/' wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md | grep -Eic 'all-in-one|task' ` returns at least 1.
    - The reviewed-match audit produces matches inside the BOUND-02 ref doc's Anti-features section: `awk '/^## Anti-features$/,/^## See also$/' docs/reference/three-layer-model.md | grep -Eic 'inbox|calendar|reminder|task' ` returns at least 1.
  </acceptance_criteria>
  <done>
    12-VERIFICATION.md exists at the locked path with REQ-ID rows for BOUND-01/02/03, captured phase-base SHA, full reproducible audit grep command, annotated reviewed-match audit table with zero `positive-claim` rows, diff-scope verification, wiki-taxonomy invariant confirmation, and AGENTS.md §4 enum invariant confirmation. REQUIREMENTS.md has BOUND-01/02/03 checkboxes flipped to `[x]` and traceability table cells flipped to `Complete`. `bash bin/requirements-sync.sh --strict --phase 12` exits 0.
  </done>
</task>

</tasks>

<verification>
- 12-VERIFICATION.md exists with all SPEC-required content (REQ-ID rows, phase-base SHA, audit table with zero positive-claim rows, diff-scope verification).
- REQUIREMENTS.md BOUND-01/02/03 status flipped in both the checkbox list and traceability table.
- `bin/requirements-sync.sh --strict --phase 12` exits 0.
- Wiki-taxonomy and AGENTS.md §4 enum invariants both hold.
- Diff over the captured phase-base SHA shows zero bin/ or schema/ edits, zero AGENTS.md/CLAUDE.md content edits.
</verification>

<success_criteria>
- All 14 SPEC acceptance criteria verifiable from this artifact's evidence + the predecessor plans' deliverables.
- Phase 12 closes cleanly: `requirements-sync --strict --phase 12` is the canonical "phase done" signal and it exits 0.
- The captured phase-base SHA + audit grep + diff command are reproducible by anyone re-running them at any future point.
- The verification artifact is consumable by Phase 13.2's CLOSE-01 closure gate (which runs `requirements-sync.sh --strict` across all v1.1 phases).
</success_criteria>

<output>
After completion, this verification artifact is consumed by:
- Phase 13.2 CLOSE-01 (final v1.1 closure gate runs `bin/requirements-sync.sh --strict` across all v1.1 phases including Phase 12).
- Phase 13.2 CLOSE-04 (final scope-leak check — Phase 12's reviewed-match audit is the canonical evidence that no task-engine / reminder / calendar / GTD-dashboard framing has entered v1.1).
- Future operators auditing the boundary at any point — the captured grep command + phase-base SHA make the audit reproducible without re-deriving the patterns or scope.

Phase 12 is COMPLETE after this plan ships. STATE.md and ROADMAP.md will be updated by the orchestrator (gsd-execute-phase) to reflect Phase 12 closure.
</output>
