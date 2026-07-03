# 26-04 SUMMARY — close Phase 26 + ship v1.5

**Status:** Complete (2026-07-03)

## What shipped

The milestone close for **v1.5 Python Migration**. Phase 26 (CUT-02) is the terminal phase;
finishing it ships v1.5.

- **26-VERIFICATION.md** — CUT-02 evidenced against its 3 success criteria: (1) the black-box
  + characterization suite runs on the pytest harness with the goldens still holding
  (205 files ↔ 205 manifest rows; the phase-24 characterization goldens rewired to
  direct-Python capture still byte-match); (2) a single `pytest -n auto` entrypoint (~7.4s,
  ~4× under the retired 30.46s serial bash runner); (3) the 6 required CI checks keep their
  names + workflows, `parity.yml` → `tests.yml`. The two locally-non-zero required checks
  (`lint --ci`, `setup-parity`) were traced to PRE-EXISTING, Phase-26-unrelated conditions
  (the user's wiki crossref content; the non-hermetic wizard test) and documented honestly.
- **26-REVIEW.md** — xhigh adversarial review over the whole Phase-26 diff (independent
  subagent, ~23 min, 60+ probing runs). Verdict: **safe to ship**. 5 findings: the two LOW
  in-scope cleanups (F3 stale `SUITE_MANIFEST.txt` header; F4 hook dep-probe missing `xdist`)
  were APPLIED; F2 (dead `_NORM_EXEC_ROOTS` path) retained defensively; F5 informational. The
  one HIGH catch (F1: `phase-08/test_wizard_partial_failure.sh` silently imports the LIVE
  module and promotes into the live tree) is PRE-EXISTING, off the pytest-bridge path, and
  outside the Phase-26 diff — LEDGERED for a v1.6 test-hygiene follow-on (it is a live landmine
  on the `setup-parity` CI job; the reviewer named the fix: copy `src/compendium` into the
  phase-08 scaffold).
- **CUT-02 → Complete** in REQUIREMENTS.md (18/18 v1.5 requirements Complete).
  `requirements-sync --phase 26 --strict --require-complete` and the whole-milestone
  `--strict --require-complete` both exit 0 (18/18). En route, a pre-existing data-quality
  bug was fixed: the REQUIREMENTS.md status-table rows for MIG/TEST-06/CUT carried
  descriptive parentheticals in the Phase column (`Phase 25 (Wave 1 — …)`) that broke
  `requirements-sync`'s `REQ_ROW_RE`, so only 9 of 18 rows had ever been machine-checked;
  cleaned to bare `Phase N` (notes live in the Phase-summary section). 26-VERIFICATION.md
  also got a parseable `- **CUT-02**: Complete` line so the drift cross-check is real.
- **v1.5 marked SHIPPED:** ROADMAP milestone line (🚧→✅ with date) + Phase 26 ticked + the
  phase table updated (25 and 26 were stale-Pending); MILESTONES.md v1.5 entry prepended;
  `milestones/v1.5-MILESTONE-AUDIT.md` retrospective written. STATE.md → milestone Complete
  (18/18, next = deferred backlog).
- **Memory settled:** the two operational memories Phase 26 resolved were retired —
  `precommit-parity-gate-slow-commits` (the parity gate is gone, 26-02) and
  `precommit-appends-lint-log-entry` (the clobber is fixed, 26-03) — files deleted + MEMORY.md
  index pruned. No "v1.5 shipped" memory added (it's recorded in MILESTONES.md — the repo
  already holds it).

## Milestone-close checklist (26-CONTEXT)

- [x] CUT-02 → Complete (18/18 v1.5 reqs); `requirements-sync --phase 26 --strict
      --require-complete` exits 0.
- [x] 26-VERIFICATION.md (3 criteria evidenced) + 26-REVIEW.md (xhigh) at the Phase-24/25 discipline.
- [x] v1.5 SHIPPED across ROADMAP / MILESTONES / a milestone-audit note; STATE milestone Complete.
- [x] The commit-time wiki-clobber dance is GONE (26-03) — verified: the 26-03 and 26-04
      commits ran the hook without dirtying `wiki-cloud/log.md` (the `git checkout --` strip is retired).
- [x] Memory updated (parity-gate + clobber memories retired; v1.5-shipped left to the repo).

## Verification

`pytest -n auto` = **348 passed, 10 xfailed**, stable across 5 consecutive parallel runs
(0 flakes). `requirements-sync --strict --require-complete` = 18/18 Complete, exit 0.
Tree clean throughout (only the user's concurrent `.planning/` notes untracked; pathspec-scoped commit).
