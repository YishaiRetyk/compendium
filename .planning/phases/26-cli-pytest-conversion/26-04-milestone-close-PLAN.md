---
phase: 26-cli-pytest-conversion
plan: 04
type: execute
wave: 2
depends_on: [03]
requirements: [CUT-02]
files_modified:
  - .planning/REQUIREMENTS.md (CUT-02 → Complete)
  - .planning/phases/26-cli-pytest-conversion/26-VERIFICATION.md (new)
  - .planning/phases/26-cli-pytest-conversion/26-REVIEW.md (new)
  - .planning/ROADMAP.md (Phase 26 ✓; v1.5 milestone → SHIPPED)
  - .planning/STATE.md (milestone complete)
  - .planning/MILESTONES.md (v1.5 shipped)
  - .planning/RETROSPECTIVE.md or a milestones/v1.5-MILESTONE-AUDIT.md (retrospective)
autonomous: true
---

<objective>
Close Phase 26 and SHIP v1.5. CUT-02 verified, adversarial review at the Phase-24/25
discipline, milestone marked shipped, retrospective captured, memory settled.
</objective>

<context>
- CUT-02 success criteria (brief): (1) black-box suite runs on the pytest harness
  reproducing the behavioral assertions; (2) single parallel `pytest` entrypoint, bash
  runner retired; (3) CI green with the required-check contract preserved. 26-01/02
  deliver these; this plan evidences them.
- Milestone shape: v1.5 = Phases 24 (foundation) + 25 (migration+cutover) + 26 (this).
  Finishing 26 ships v1.5. Follow the established close ritual (see how v1.4 closed:
  ROADMAP milestone line 🚧→✅ with date, MILESTONES.md entry, a milestones/
  v1.5-MILESTONE-AUDIT.md or RETROSPECTIVE.md note).
- Adversarial review: xhigh, range = the Phase-26 diff. Apply the confirmed fixes; ledger
  the rest (26-REVIEW.md), same as 24-REVIEW/25-REVIEW.
- Memory: the parity-gate-slow-commits + precommit-clobber memories are now RESOLVED by
  26-02/26-03 — update or retire them; add a "v1.5 shipped" project note if non-obvious.
</context>

<tasks>
1. 26-VERIFICATION.md: evidence each CUT-02 criterion (pytest entrypoint + parallel
   wall-clock; manifest baseline reproduced; 6 required checks green; hook lightened).
2. xhigh adversarial review over the Phase-26 diff → apply confirmed fixes → 26-REVIEW.md.
3. Flip CUT-02 → Complete in REQUIREMENTS.md (18/18 v1.5 reqs Complete). Requirements-sync
   `--phase 26 --strict --require-complete` exits 0.
4. Mark v1.5 SHIPPED: ROADMAP milestone line + Phase 26 tick; MILESTONES.md; a v1.5
   retrospective/audit note (what shipped, the 5 D-09 rebases, the review catches, the
   deferred SHIMOUT/LIBSWAP/full-rewrite items).
5. STATE.md → milestone complete; next = the deferred backlog (SHIMOUT / LIBSWAP / the
   optional full idiomatic test rewrite / the remaining 25-REVIEW behavior items).
6. Update memory (retire the two resolved operational memories; note v1.5 shipped).
7. Commit `docs(26): close Phase 26 + ship v1.5 — CUT-02 complete, milestone shipped`.
   Final state: clean tree (modulo the user's concurrent ingest), pytest green.
</tasks>

<acceptance>
- CUT-02 Complete; 18/18 v1.5 requirements Complete; requirements-sync --phase 26 strict
  exits 0.
- `pytest -n auto` is the single green entrypoint; 6 required CI checks green; hook is
  light and clobber-free.
- v1.5 marked SHIPPED across ROADMAP/MILESTONES/STATE; 26-VERIFICATION + 26-REVIEW +
  retrospective written; memory settled.
</acceptance>
