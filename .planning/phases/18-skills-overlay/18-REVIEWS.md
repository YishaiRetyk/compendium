---
phase: 18
reviewers: [claude, codex, gemini]
reviewed_at: 2026-06-08T20:40:00
review_cycle: 2
plans_reviewed: [18-00-PLAN.md, 18-01-PLAN.md, 18-02-PLAN.md]
---

# Cross-AI Plan Review — Phase 18 (Skills Overlay) — Cycle 2

> Convergence loop, cycle 2. The prior cycle raised 5 HIGH concerns, addressed by
> replan commit `2b99299`. This cycle empirically verifies whether each is genuinely
> resolved and surfaces new concerns. Three reviewers participated (Claude with direct
> empirical tests, Codex, Gemini). Several falsifiable claims were **verified by direct
> test in scratch repos / bash harnesses**; results are in the Consensus Summary under
> "Verified Findings (cycle 2)."

## Claude Review

**Summary.** All five prior-cycle HIGH concerns are genuinely resolved — each was
verified by direct empirical test, not by trusting the replan prose. Codex raised two
new items it rated HIGH; on close adjudication against the SPEC's own acceptance
criteria, both are real defense-in-depth observations but land at MEDIUM (they harden
the always-run gate beyond the bar the SPEC explicitly sets, which places zero-behavior
and "exactly four" enforcement in the test-suite + desk-check layer). No unresolved HIGH
remains.

**Prior-HIGH verification (all FULLY RESOLVED):**

- **HIGH-1 (.gitignore file-glob).** Verified in a scratch git repo: with `.claude/*` +
  `!.claude/settings.cloud.json` + `!.claude/skills/` + `!.claude/skills/*/` +
  `!.claude/skills/*/SKILL.md`, `git check-ignore .claude/skills/ingest/SKILL.md` exits 1
  (trackable), `settings.cloud.json` stays trackable, and `settings.json` stays ignored
  (exit 0). Confirmed the disproof too: under the old `.claude/` DIRECTORY ignore the same
  negations are inert (SKILL.md stays ignored, exit 0). Plan 00 prescribes the correct
  file-glob form. Note: the live repo `.gitignore` still shows the old `.claude/` form —
  expected, since Plan 00 has not executed yet; the plan's prescription is correct.
- **HIGH-2 (set -e + rc=$? capture).** Verified empirically: the bare-command-then-`rc=$?`
  form aborts before the capture line under `set -e` (the success-path assertion never
  runs); the `cmd && rc=0 || rc=$?` form captures rc=1 and runs the success path. All four
  affected tests (`test_skills_git_tracked.sh`, `test_gen_skills_check_clean.sh`,
  `test_gen_skills_check_drift.sh`) use the fixed idiom.
- **HIGH-3 (DR heading).** Verified against `schema/reference/page-types.md` §4.6 (line 115
  requires `## Alternatives Considered`; line 139 fixes the full Decision section order).
  Plan 02's DR body and acceptance grep both use `## Alternatives Considered` and the exact
  section order.
- **HIGH-4 (log.md reflect entry).** Verified against `schema/workflows/reflect.md` step 6
  (line 63 mandates appending `## [YYYY-MM-DD] reflect | <scope>` to `wiki-cloud/log.md`
  on DR creation). Plan 02 Task 1 Part C appends exactly this entry and routes DR creation
  through the reflect workflow; `log.md` is in `files_modified`.
- **HIGH-5 (zero-behavior, mechanical not line-count-only).** Verified by running the
  body-thin gate logic on a real generated body and on an injected procedural body
  (`Run classify then merge.`): the exact-pointer regex matches the legitimate body and
  rejects the procedural one, and the independent procedural-imperative grep also catches
  the `Run`/`Merge` verbs. This is genuine mechanical enforcement. Per the SPEC's own
  SKILL-02 acceptance (line 69: "a verifier desk-check **plus grep for imperative/procedural
  verbs in bodies**"), this satisfies the stated bar.

**Concerns (new this cycle):**

- **MEDIUM — durable gate (`gen-skills.sh --check`) does not carry the zero-behavior
  grep that the phase test carries.** The exact-pointer regex + procedural-imperative grep
  live only in `tests/phase-18/test_skill_body_thin.sh`, which pre-commit and CI do NOT
  run (they run only `bash bin/gen-skills.sh --check`). `--check` asserts ≤3 body lines,
  pointer-target-exists, dir-purity, no-first-person, YAML-safe description, and
  no-disable-model-invocation — but NOT "the body line is exactly the pointer." A one-line
  procedural body added to the generator's `body_for()` heredoc (e.g. `Run classify then
  merge.`) would pass regenerate-diff (committed == fattened template), pass the ≤3-line
  count, and pass CI. Rated MEDIUM not HIGH: the SPEC (line 69) deliberately places
  zero-behavior verification in the desk-check + grep (test) layer, which exists and works;
  this is hardening beyond the SPEC bar. **Sub-finding (LOW, doc accuracy):** Plan 01's
  threat-register row T-18-01-02 claims "≤3 body lines, no imperative verbs guard" inside
  `--check` — the "no imperative verbs guard" is NOT in the `--check` spec as written; the
  text overstates the durable gate. Either add the grep to `--check` or correct the row.
- **MEDIUM — durable gate does not reject a fifth skill dir.** `gen-skills.sh --check`
  loops the fixed `OPS=(ingest query lint reflect)` quartet and never enumerates the actual
  contents of `.claude/skills/`. A committed `.claude/skills/audit/SKILL.md` would be
  model-invocable and pass `--check`. It IS caught by `test_gen_skills_creates_files.sh`
  (`find … -name SKILL.md | wc -l` must equal 4), but that test is not in the always-run
  gate. Rated MEDIUM: "exactly four" is a SPEC boundary, and the test layer enforces it;
  moving a root-purity assert into `--check` would close it in CI too.
- **LOW — internal inconsistency in staging guidance.** Plan 01's pre-commit hook
  deliberately exact-stages the four named SKILL.md files (to avoid auto-staging strays),
  but Plan 01's manual step (line 407) and Plan 02's `docs/reference/skills.md` (line 374)
  both tell the human/adopter to run blanket `git add .claude/skills/`. Low real risk (the
  dir-purity assert rejects strays at the gate), but the messaging contradicts the hook's
  own rationale. Recommend the docs say "stage the four generated files, or run
  `gen-skills.sh --check` before any blanket add."

**Suggestions.** (1) Lift the exact-pointer + procedural-verb grep from
`test_skill_body_thin.sh` into `gen-skills.sh --check` so the durable gate enforces
zero-behavior, then correct/keep threat row T-18-01-02. (2) Add a root-purity assert to
`--check`: reject any `.claude/skills/*` dir not in the fixed op list. (3) Align the docs
staging guidance with the exact-staging rationale. None of these block the phase.

**Risk Assessment: LOW.** Every SPEC acceptance criterion is met by some layer of the
plan; the new findings are defense-in-depth that move enforcement from the test layer into
the always-run gate. No HIGH blocker.

---

## Codex Review

**Summary.** Four of the five prior HIGHs look genuinely resolved in the plan text. Codex
rated HIGH-5 only partially resolved and raised two further HIGH-rated items, both
concerning the durable CI/pre-commit gate.

**Strengths**

- `.gitignore` fix is correct: `.claude/*` plus intermediate negations avoids the
  ignored-directory trap.
- `set -e` exit capture is fixed with `cmd && rc=0 || rc=$?`.
- Decision record heading now matches schema: `## Alternatives Considered`.
- Plan 02 now appends the required `wiki-cloud/log.md` reflect entry.
- Pre-commit exact-stages the four generated `SKILL.md` files rather than blanket-staging.

**Concerns**

- **HIGH (Codex) — SKILL-02 not enforced by the actual CI/pre-commit gate.** The exact
  pointer regex + imperative grep are in `test_skill_body_thin.sh`, but CI/pre-commit run
  only `bin/gen-skills.sh --check`, which checks line count / pointer-target / dir-purity /
  first-person / YAML-safe / model-invocation — not the exact pointer body. A one-line
  procedural body could be added to the generator and pass `skills-check`.
  *(Claude adjudication: real, but MEDIUM vs the SPEC's desk-check+grep acceptance bar.)*
- **HIGH (Codex) — extra skill directories not rejected by `--check`.** The check loops the
  fixed quartet and never asserts `.claude/skills/` contains only the four ops; a fifth
  `audit/SKILL.md` would pass `--check`, violating "exactly four."
  *(Claude adjudication: real, but caught by the phase test; MEDIUM.)*
- **MEDIUM — `test_skills_git_tracked.sh` proves "not gitignored," not "tracked."**
  `git check-ignore` nonzero only means trackable; recommends `git ls-files
  --error-unmatch`. *(Claude note: Plan 01's verification block does include
  `git ls-files .claude/skills/`, so tracking is verified at plan level — slight overstate.)*
- **MEDIUM — docs recommend blanket `git add .claude/skills/`, conflicting with the
  exact-staging mitigation.**

**Suggestions.** Move the exact body regex + nonblank-line assertion into
`gen-skills.sh --check`; add root purity (reject any non-op dir and any top-level file
under `.claude/skills/`); switch the tracked test to `git ls-files --error-unmatch`;
align the docs staging guidance.

**Risk Assessment: HIGH** (Codex's own rating) — "close, but the durable gate still does
not fully enforce zero-behavior bodies and exactly four routers." *(Claude adjudication
downgrades to LOW/MEDIUM against the SPEC's stated acceptance layer.)*

---

## Gemini Review

**Summary.** The plan is comprehensive and meticulously addresses generation, management,
and documentation of the skill routers, with a thorough RED test harness.

**Strengths.** All five prior HIGH concerns are explicitly resolved: HIGH-1 (file-glob +
negations with `git check-ignore` rationale), HIGH-2 (`cmd && rc=0 || rc=$?` + trap
cleanup), HIGH-3 (`## Alternatives Considered`), HIGH-4 (log.md reflect entry per reflect.md
step 6), HIGH-5 (`test_skill_body_thin.sh` exact-pointer regex + imperative grep + single
non-blank-line assertion, plus the structural assertions in `gen-skills.sh`). Notes the
robust testing strategy, reuse of `sync-claude.sh` as structural twin, and the layered
verification (regenerate-diff + structural assertions + CI hard-fail + neutrality).

**Concerns.** None — "the plan is exceptionally well-structured and anticipates potential
issues with defensive measures and thorough testing."

**Suggestions.** None significant; praises the `case`-based description lookup for bash 3.2
compatibility.

**Risk Assessment: LOW.**

---

## Consensus Summary

### Verified Findings (cycle 2, by direct test)

1. **HIGH-1 resolved.** Scratch-repo test confirms `.claude/*` form makes SKILL.md
   trackable, keeps `settings.cloud.json` trackable, keeps `settings.json` ignored; and
   confirms the old `.claude/` directory form leaves the negations inert. (Live `.gitignore`
   still on old form — expected pre-execution.)
2. **HIGH-2 resolved.** Bash harness confirms the `cmd && rc=0 || rc=$?` idiom captures the
   success-path rc under `set -e` where the bare form aborts. All affected tests use it.
3. **HIGH-3 resolved.** `page-types.md` §4.6 requires `## Alternatives Considered` + the
   exact Decision section order; Plan 02 conforms.
4. **HIGH-4 resolved.** `reflect.md` step 6 mandates the log.md reflect entry; Plan 02
   Task 1 Part C appends it.
5. **HIGH-5 resolved.** Body-thin gate logic, run on real and adversarial bodies, rejects
   procedural content via exact-pointer regex AND imperative-verb grep. Meets the SPEC's
   SKILL-02 acceptance (desk-check + grep).

### Agreed Strengths (2+ reviewers)

- `.gitignore` file-glob fix is correct (all three).
- `set -e` rc-capture fix is correct (Claude, Codex, Gemini).
- DR heading and log.md reflect entry now schema-conformant (all three).
- Strong, layered verification: regenerate-diff + structural assertions + CI hard-fail +
  neutrality gate (Codex, Gemini).
- `sync-claude.sh` reused as the structural twin idiom (Gemini, Claude).

### Agreed Concerns (priority)

- **Durable-gate coverage gap (Codex HIGH → consensus MEDIUM).** Zero-behavior body
  enforcement (exact-pointer / imperative grep) and "exactly four routers" enforcement live
  in the phase test suite, not in `gen-skills.sh --check`, so pre-commit and CI do not
  enforce them. Real and worth closing by lifting those asserts into `--check`; rated MEDIUM
  because the SPEC (line 69, line 81) places these in the desk-check + test layer, which
  exists and works. Gemini did not flag it.
- **Doc/staging inconsistency (Codex MEDIUM, Claude LOW).** Hook exact-stages four files;
  docs and Plan 01's manual step say blanket `git add .claude/skills/`.

### Divergent Views

- **Severity of the durable-gate gap.** Codex rates it HIGH (gate does not enforce the two
  most important invariants); Claude rates it MEDIUM (SPEC acceptance is satisfied by the
  test + desk-check layer; this is defense-in-depth); Gemini sees no concern at all. Net
  adjudication: MEDIUM — genuine hardening opportunity, not a SPEC-acceptance failure, so
  not a convergence blocker.
- **`test_skills_git_tracked.sh` "tracked" vs "not gitignored."** Codex flags it MEDIUM;
  Claude notes Plan 01's verification block already runs `git ls-files .claude/skills/`, so
  tracking is verified at plan level — downgrade to LOW.

### Cycle-2 disposition

- Prior HIGHs 1–5: **FULLY RESOLVED** (each verified by direct test).
- New HIGH-rated items (Codex): adjudicated to **MEDIUM** against the SPEC's stated
  acceptance layer; recommended as hardening, not blockers.
- **Unresolved HIGH count: 0.** The convergence loop has converged on HIGH severity.
  Remaining work is optional MEDIUM/LOW hardening (lift zero-behavior + root-purity asserts
  into `gen-skills.sh --check`; align doc staging guidance; correct threat row T-18-01-02).
