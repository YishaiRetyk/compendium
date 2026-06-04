---
phase: 16
cycle: 3
reviewers: [claude, codex]
reviewed_at: 2026-06-05T00:00:00
plans_reviewed: [16-00-PLAN.md, 16-01-PLAN.md, 16-02-PLAN.md, 16-03-PLAN.md, 16-04-PLAN.md]
prior_cycle_high: 4
current_cycle_high: 2
---

# Cross-AI Plan Review — Phase 16: Reference Extraction (Cycle 3)

**Convergence-loop cycle 3.** The plans were revised (commit `1c2ba88`) to address the 4 HIGH
concerns from cycle 2: (1) canonical fixture regeneration ownership; (2) brittle whole-file
`grep -v '{{'` parity gate → region-scoped + direction-pinned reconciliation; (3) authority sweep
broadened to catch `sole authority` (line 38); (4) wizard delivery documented + tested release.sh
ALLOWLIST invariant. This review verifies every cycle-2 fix against the **live repo** and
re-scans for new defects.

**Verdict:** All 4 cycle-2 HIGHs are **FULLY RESOLVED** (both reviewers, repo-verified). However,
running the actual gate suite against the current tree surfaced **2 NEW HIGHs**, both repo-verified:
(a) `bin/check-neutrality.sh` **exits 2 (FAIL) on the current committed tree** — Phase 16 gates
every wave on this exiting 0, and no plan clears the pre-existing `wiki-cloud/` content hits; and
(b) a **filename-level neutrality leak** — `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md`
ships under the release ALLOWLIST with a denylisted term in its name. Net: **2 unresolved HIGH.**

---

## Claude Review

All findings verified against the live repo. The 4 cycle-2 fixes hold; running the gate suite
exposed a pre-existing red gate that the plans assume is green.

### 1. Summary

The cycle-3 revisions land all 4 cycle-2 HIGH fixes cleanly and verifiably: the canonical fixture
is owned + in `files_modified` + regenerated via the exact documented frozen-env render routine; the
unsound whole-file parity diff is replaced by a region-scoped resident-range check plus a
direction-pinned guardrail that provably cannot delete the §3 neutrality bullet; the authority sweep
now includes the bare phrase `sole authority` and runs across all 4 surfaces; and wizard delivery is
documented as ALLOWLIST wholesale-copy with a tested invariant. The two MEDIUM carry-overs (C5
backtick-tolerant grep, C6 next-header awk terminator) are also fixed and live-verified. **But**
executing `bash bin/check-neutrality.sh` on the current tree returns exit 2 — a load-bearing
precondition that 16-00 Task 1 and every gate step in 16-04 assert is exit 0. This was not caught in
cycles 1–2 because neither cycle ran the gate against the live tree.

### 2. Cycle-2 HIGH Disposition (all repo-verified)

**HIGH #1 — Canonical fixture not regenerated → phase-08 byte-equality goes RED → FULLY RESOLVED.**
16-04 Task 2 STEP C.5 regenerates `schema/fixtures/canonical-AGENTS.md` via
`bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to <dir>` — the
exact routine documented in `tests/phase-08/test_canonical_byte_equality.sh`. Verified: init-wizard
supports both flags; the frozen env (`WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"`,
`WIZARD_TEMPLATE_SHA="<frozen-fixture>"`) **matches** `canonical-answers.yaml` metadata exactly; the
fixture is in `files_modified`; STEP C.5 runs in Task 2 BEFORE STEP D's phase-08 run; the regen is
asserted in Task 2 `<verify>`. The "DO NOT hand-edit" discipline keeps the gate a genuine drift
detector.

**HIGH #2 — Unsound whole-file `grep -v '{{'` parity gate + safety-regression hazard → FULLY RESOLVED.**
Verified the premise on the live repo: the §3 neutrality bullet "DO NOT use real slugs…" is present
in AGENTS.md (`grep -c` → 1) and **missing from the template** (`grep -c` → 0); the resident-range
diff (`awk '/^## 4\./{exit}' … | grep -v '{{'`) is non-empty (`138d138` missing bullet + a stray
`33a34` blank line). 16-04 STEP E.5 now uses the region-scoped `awk … | grep -v '{{'` form (not
whole-file); STEP E.3 reconciles drift **direction-pinned into the template**; the GUARDRAIL +
Task 1 `<verify>` assert `grep -q 'DO NOT use real slugs'` passes on **both** AGENTS.md (never
deleted) and the template (added by E.3). The old whole-file gate now appears ONLY inside comments
that describe it as removed/unsound. The wrong-direction "make-the-diff-empty" hazard is closed.

**HIGH #3 — Authority sweep missed `sole authority` (line 38) → FULLY RESOLVED.**
Verified line 38 `├── AGENTS.md   # This file (sole authority)` is present in all 4 surfaces
(AGENTS.md, CLAUDE.md, template, fixture). The broadened term set
(`sole authoritative|sole source of truth|sole authority|No other file|does NOT contain rules|does NOT contain conventions`)
catches line 38 plus the other now-false hits (lines 3, 5, 13, 87, 130). STEP A.5 and the final
`<verification>` run this set across all 4 surfaces with a historical-DR exemption.

**HIGH #4 — Wizard delivery not a tested ship-the-tree invariant → FULLY RESOLVED.**
Verified `bin/release.sh` ALLOWLIST contains `"schema"` (line 29) and `"docs"` (line 30); F.7's grep
patterns (`^\s*"schema"`, `^\s*"docs"`) match; `init-wizard.sh` does NOT render schema/reference or
schema/workflows (confirming the documented wholesale-copy delivery model); the `INCLUDES:` dry-run
output exists (line 114). STEP F.7's tested invariant (ALLOWLIST carries both dirs + every delivered
leaf lives under them) is sound and durable against a future ALLOWLIST edit.

**MEDIUM carry-overs C5 / C6 — both FIXED + live-verified.**
C5: 16-03 rule-6 grep corrected to `-E 'DO NOT read .?wiki-local/.? from a cloud session'` — matches
live AGENTS.md line 137; the old pattern `DO NOT read .wiki-local. …` confirmed NO-MATCH (the
false-negative was real). C6: 16-02 uses the generic next-header terminator
`awk 'f && /^## [0-9]+\./{exit} /^## 6\./{f=1} f'` everywhere; no bare `/^## 7\./{exit}` remains.

### 3. Strengths

- **Every cycle-2 fix is backed by a runnable gate, not prose.** The fixture regen, the region-scoped
  parity, the broadened sweep, and the ALLOWLIST invariant each terminate in a `<verify>` assertion
  that fails loudly if the fix regresses.
- **The direction-pinned guardrail is the right shape.** Asserting the §3 bullet in BOTH files after
  edits makes a wrong-direction "fix" impossible to pass — exactly the safety property cycle-2 asked for.
- **Frozen-env reproducibility for the fixture** keeps phase-08 a genuine drift detector rather than a
  rubber stamp.

### 4. Concerns

- **HIGH — NEW — `bin/check-neutrality.sh` exits 2 on the current committed tree; no plan clears it.**
  `wiki-cloud/` is in `PUBLIC_PATHS` (line 94). Three committed files carry the denylisted terms
  `kahneman` / `personal-decision-journal` outside a sanctioned `examples/kahneman/` path:
  - `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md:30,92` — references the DR id
    `dr-2026-04-15-kahneman-to-examples`
  - `wiki-cloud/log.md:344,345` — narrates a past `--fix` run
  - `wiki-cloud/maintenance/lint-report.md:86,87` — lists raw source paths
  These are committed at HEAD, not working-tree noise. This **directly contradicts** 16-00 Task 1
  `<done>` ("`bash bin/check-neutrality.sh` exits 0 on the current repo") and every Phase 16 gate
  step that asserts it exits 0 (16-04 STEP G, Task 2 STEP D, the final `<verification>`). The only
  exemptions in the scanner are sanctioned `examples/kahneman/` path refs, the `SELF_REFERENTIAL_EXEMPT`
  set, and `neutrality_exempt: true` frontmatter — none apply to these files. As written, the FIRST
  plan to run the neutrality gate will go red for reasons unrelated to the extraction, blocking the
  wave (or tempting an executor to "fix" unrelated committed content). **Fix:** add a Wave-0 pre-task
  that neutralizes the current `wiki-cloud/` content hits (e.g., `neutrality_exempt: true` on the
  privacy DR + lint-report, and reword/exempt the log narration) so the gate is green BEFORE any
  extraction commit gates on it.

- **HIGH — NEW (Codex-led, confirmed) — filename-level neutrality leak under the release ALLOWLIST.**
  `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md` exists; `wiki-cloud/decisions` is in
  `bin/release.sh`'s ALLOWLIST (line 33). `check-neutrality.sh` scans file *content*, not path names,
  so the denylisted term in the filename ships publicly unscanned. Not execution-blocking (the content
  gate won't catch it), but it is a genuine public-release leak the project should resolve
  (rename/move/exclude the file, or add path-name scanning with an explicit policy).

- **MEDIUM — 16-04 STEP E.3 conflates resident vs. extracted drift in its enumeration.** E.3 says it
  covers ONLY resident sections, yet its bullet list names §5 `knowledge_domain`, the §8 asymmetric
  cross-tier link rule, `wiki-local/sources/` qualifiers, and `FROM "wiki-cloud"` — content that
  16-01/02/03 EXTRACT to leaf files. An executor could re-add extracted content back into the template
  resident range. The region-scoped E.5 gate (`awk '/^## 4\./{exit}'`) bounds the risk to the §1→§4
  range, but the prose should clarify these belong in leaf-file validation, not the template resident
  range.

- **LOW — STEP E.3 prose only handles `<` lines (add-to-template), not `>` lines.** The live
  resident-range diff has a `>` (extra blank line in template at `33a34`). E.5's empty-diff gate is
  self-enforcing, so this resolves at execution, but the E.3 instruction is incomplete as written.

- **LOW — F.5 scoping prose diverges from its verify command.** STEP F.5 says scope the path grep to
  the routing-table/stub region; the Task 1 `<verify>` greps all of AGENTS.md. Harmless after §16
  deletion but should match the stated invariant.

### 5. Suggestions

1. **Add a Wave-0 pre-task** that makes `bin/check-neutrality.sh` exit 0 on the current tree before
   any extraction commit gates on it (neutrality_exempt on the privacy DR + lint-report; reword/exempt
   the log narration). Re-verify with a clean `bash bin/check-neutrality.sh; echo $?`.
2. **Resolve the filename leak** for `dr-2026-04-15-kahneman-to-examples.md` (rename to an abstract
   slug + update inbound references, or exclude from the release ALLOWLIST, or add path scanning).
3. **Clarify E.3 scope** — extracted-section content is validated in leaf files, not re-added to the
   template resident range.
4. **Align F.5's verify command** with its scoped-grep prose.

### 6. Risk Assessment — HIGH (until neutrality is pre-cleared)

The extraction design and all 4 cycle-2 fixes are solid and repo-verified. Risk is HIGH only because
Phase 16 execution will hit a red `check-neutrality.sh` on the first gated wave — a pre-existing
condition the plans assume away. Both new HIGHs are localized and fixable with a small Wave-0 pre-task
plus a filename cleanup; neither requires rethinking the extraction.

---

## Codex Review

### 1. Summary

Cycle-2 fixes mostly hold. The revised plans now correctly own fixture regeneration, region-scoped
parity, broadened authority sweep, and release-allowlist delivery checks. But the new neutrality
finding is a real execution-blocking HIGH. Phase 16 repeatedly gates on `bash bin/check-neutrality.sh`,
and the current tree already has denylist hits in scanned `wiki-cloud` files that no Phase 16 plan
clears. Task 16-00 only adds `schema` to `PUBLIC_PATHS`; it cannot make existing `wiki-cloud` hits
disappear.

### 2. Cycle-2 HIGH Disposition

1. **Canonical fixture regeneration: FULLY RESOLVED.** 16-04 Task 2 Step C.5 owns regeneration of
   `schema/fixtures/canonical-AGENTS.md`, includes the fixture in `files_modified`, and uses the
   documented `init-wizard.sh --answers-file … --render-to …` flow. The phase-08 test and fixture
   metadata match the frozen env values.
2. **Unsound whole-file parity gate: FULLY RESOLVED for the HIGH.** The plan replaces the whole-file
   `grep -v '{{'` diff with resident-range parity plus explicit safety guardrails. Live repo confirms
   `AGENTS.md` has the `DO NOT use real slugs` bullet and `schema/AGENTS.template.md` does not, so the
   direction-pinned "template up to AGENTS" fix is necessary and correctly guarded.
3. **Authority sweep missed `sole authority`: FULLY RESOLVED.** The broadened term set includes
   `sole authority` and covers AGENTS, CLAUDE, template, fixture, plus docs structural claims. It
   catches the live directory-tree line and the other old-framing hits.
4. **Wizard/reference-tree delivery: FULLY RESOLVED.** `bin/release.sh` allowlists both `schema` and
   `docs`; the plan documents that `init-wizard.sh` renders only personalized artifacts and that
   release allowlist copy is the delivery path. The added invariant is adequate for the original HIGH.

### 3. New Neutrality Finding — HIGH, execution-blocking

Confirmed hits outside sanctioned `examples/kahneman/**`:
- `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md:30` — `dr-2026-04-15-kahneman-to-examples`
- `wiki-cloud/log.md:344` — old run narrative includes `kahneman`
- `wiki-cloud/maintenance/lint-report.md:86` — raw source paths include `kahneman` and `personal-decision-journal`

There is no general decision-record/log narration exemption in `check-neutrality.sh`. The only
relevant exemptions are sanctioned `examples/kahneman/...` path snippets, scanner self-reference, and
markdown frontmatter `neutrality_exempt: true`. The affected privacy DR, log, and lint report are not
exempt. This is not just stale committed output: `bin/lint.sh` emits raw source paths into findings
and writes `wiki-cloud/maintenance/lint-report.md`, so 16-04 Task 2's own `bash bin/lint.sh --ci` can
regenerate the denylisted report immediately before the neutrality gate.

### 4. Other Concerns

- **HIGH: filename-level neutrality leak is not scanned.** `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md`
  exists under a release-allowlisted directory. `check-neutrality.sh` scans file contents, not path
  names. Even if content hits are cleared, the public release path can still leak the denylisted term
  unless the plan renames/moves/excludes it or adds path scanning with an explicit policy.
- **MEDIUM: Step E.3 mixes resident and extracted drift.** 16-04 Step E.3 says it only covers resident
  sections, but it also lists §5 `knowledge_domain`, §8 cross-tier link rules, `wiki-local/sources/`
  qualifiers, and `FROM "wiki-cloud"`, which are extracted/stubbed by 16-01/02/03. Clarify that those
  must be validated in leaf files, not re-added into `schema/AGENTS.template.md`.
- **LOW: F.5 scoping prose and verify command diverge.** The plan says the stub path scan is scoped to
  the routing-table/stub region, but the final verify command greps all of `AGENTS.md`. Likely harmless
  after §16 deletion, but use an awk-bounded region or exact Phase-16 leaf whitelist to match the
  stated invariant.

### 5. Overall Risk — HIGH until neutrality is pre-cleared

The cycle-2 fixes are solid, but Phase 16 execution will hit a red `check-neutrality.sh` gate unless a
new pre-task neutralizes current `wiki-cloud` content hits and handles the filename/path leak.

---

## Consensus Summary

Both reviewers independently agree that **all 4 cycle-2 HIGH fixes are FULLY RESOLVED and
repo-verified**, and both independently surfaced the same **NEW execution-blocking HIGH**: the
neutrality gate is already red on the current tree, and Phase 16 gates every wave on it being green.
Codex additionally pinned a second **NEW HIGH** (filename-level leak under the release ALLOWLIST),
which Claude confirmed. Both rate overall risk HIGH **only** because of these two new, localized,
pre-existing-condition findings — not because of any defect in the extraction design or the cycle-2 fixes.

### Agreed Strengths

- Canonical fixture regeneration is owned, in `files_modified`, and uses the exact documented
  frozen-env render routine — phase-08 byte-equality stays green and a genuine drift detector.
- The region-scoped resident-range parity + direction-pinned guardrail provably preserves the §3
  neutrality MUST-NOT bullet (verified: present in AGENTS.md, missing from template — the reconciliation
  is necessary and correctly one-way).
- The authority sweep now catches `sole authority` (line 38) across all 4 surfaces.
- Wizard delivery is correctly documented as ALLOWLIST wholesale-copy with a tested ship-the-tree
  invariant; init-wizard.sh is correctly left unmodified.
- C5 (backtick-tolerant grep) and C6 (next-header awk terminator) MEDIUM carry-overs both fixed and
  live-verified.

### Agreed Concerns (highest priority — both reviewers)

1. **[HIGH — execution-blocking] `bin/check-neutrality.sh` exits 2 on the current committed tree.**
   `wiki-cloud/` is in PUBLIC_PATHS; three committed files (privacy DR, log.md, lint-report.md) carry
   `kahneman` / `personal-decision-journal` outside a sanctioned `examples/kahneman/` path. No Phase 16
   plan clears these, yet 16-00 Task 1 `<done>` and every 16-04 gate step assert the gate exits 0.
   16-00 only adds `schema` to PUBLIC_PATHS — it cannot clear pre-existing `wiki-cloud/` hits. Codex
   notes `bin/lint.sh --ci` (run in 16-04 Task 2) regenerates the denylisted lint-report, so the
   failure is live, not merely stale. **Fix:** a Wave-0 pre-task that makes the gate green first.

2. **[HIGH] Filename-level neutrality leak under the release ALLOWLIST.**
   `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md` ships via the `wiki-cloud/decisions`
   ALLOWLIST entry; check-neutrality scans content, not path names, so the denylisted term in the
   filename leaks publicly. Not execution-blocking, but a real release leak. **Fix:** rename/move/exclude
   or add path-name scanning.

### Divergent Views

None material. Both reviewers reached the same disposition on all 4 cycle-2 HIGHs (fully resolved) and
the same two new HIGHs. The only nuance: Claude classifies the filename leak as HIGH-but-not-
execution-blocking (content gate won't catch it) while the neutrality-gate-red is HIGH-and-blocking;
Codex groups both as HIGH. Same remediation set either way.

### NEW MEDIUM / LOW worth fixing in the next replan

- MEDIUM (both) — 16-04 STEP E.3 enumeration conflates resident vs. extracted drift; clarify that §5
  `knowledge_domain` / §8 cross-tier rule / `wiki-local/sources/` / `FROM "wiki-cloud"` are validated in
  leaf files, not re-added to the template resident range.
- LOW (Claude) — STEP E.3 prose handles only `<` lines (add-to-template), not the `>` extra-blank-line
  case; E.5's empty-diff gate self-enforces it but the instruction is incomplete.
- LOW (both) — F.5 scoping prose (routing-table region) diverges from its whole-file verify grep.

### Unresolved HIGH count this cycle: 2

1. **NEW** — `bin/check-neutrality.sh` exits 2 on the current tree (committed `wiki-cloud/` content
   hits); no Phase 16 plan clears it, contradicting 16-00 Task 1 + every 16-04 gate step. [repo-verified, both reviewers]
2. **NEW** — Filename-level neutrality leak: `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md`
   ships under the release ALLOWLIST with a denylisted term in its name (content scanner doesn't catch
   path names). [repo-verified, Codex-led, Claude-confirmed]

All 4 cycle-2 HIGHs are FULLY RESOLVED.
