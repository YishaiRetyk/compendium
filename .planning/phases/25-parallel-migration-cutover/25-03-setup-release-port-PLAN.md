---
phase: 25-parallel-migration-cutover
plan: 03
type: execute
wave: 1
depends_on: [01]
files_modified:
  - src/compendium/gen_skills.py
  - src/compendium/sync_claude.py
  - src/compendium/release.py
  - bin/gen-skills.sh
  - bin/sync-claude.sh
  - bin/release.sh
  - tests/ported.manifest
  - tests/test_setup_release_unit.py
autonomous: true
requirements: [MIG-04]
---

<objective>
Port the non-wizard setup/release trio — gen-skills (199 lines), sync-claude (34),
release (209); all pure bash, zero heredocs (the first full rewrites rather than heredoc
extractions). Preserves sync-claude `--check` exit **2** on drift, gen-skills `--check`
exit **1** on drift, and the pre-commit hot-path behavior: after this plan's flip, EVERY
local commit runs the Python sync-claude + gen-skills for real. init-wizard is
deliberately excluded (own plan, 25-05) per the brief's recommendation.
</objective>

<context>
- **Hot-path stakes:** `.githooks/pre-commit` runs `bash bin/sync-claude.sh` →
  `bash bin/gen-skills.sh` → lint, in that order (phase-18 ordering test = shim-contract,
  keep green unchanged). A broken flip bricks local commits — recovery documented in
  25-CONTEXT (checkout the baseline shim).
- **Oracle-exempt class:** the four gen-skills tests
  (`tests/phase-18/test_gen_skills_{check_clean,check_drift,creates_files,idempotent}.sh`)
  call the tool DIRECTLY with `# noqa: direct-bin` against the LIVE repo (`$0`-relative
  REPO_ROOT). After the flip they exercise the py impl through the shim with NO bash
  pairing — they must pass as plain behavior tests. They MUTATE `.claude/skills/` and
  regenerate; leave the live tree clean afterward (Phase-24 lesson: verify with
  `git status` post-run).
- **sync-claude**: byte-copies AGENTS.md → CLAUDE.md (+ `--check` compare). Trivial logic,
  zero tolerance: the AGENTS≡CLAUDE byte-equality gate rides on it.
- **release**: the orphan-branch template publisher (allowlist-driven). It runs REAL git
  against the repo (branch creation) — its tests/goldens (release ×5, incl. the no-args
  error path: REAL exit 1) characterize the safe surfaces. Known review-deferred item:
  release-allowlist golden freeze interplay (24-REVIEW deferred) — do not renegotiate
  goldens here; match them. git stays subprocess.
- gen-skills regenerates `.claude/skills/*/SKILL.md` from schema workflows +
  `--check` drift mode (exit 1). Deterministic output — byte-stable generation order.
</context>

<tasks>
1. Baseline both legs (phase-07 sync-claude tests, phase-18 skills tests, release
   suite/goldens). Read all three scripts.
2. Port sync_claude.py first (smallest; hot-path #1), then gen_skills.py, then
   release.py. Verbatim usage/error/drift-diagnostic text; identical generation ordering
   (LC_ALL=C sort equivalents where bash relied on glob/sort order).
3. TEST-06: `tests/test_setup_release_unit.py` — skills rendering determinism,
   sync-claude drift detection, release allowlist filtering (pure parts).
4. Flip 3 shims + manifest appends. Run the gen-skills quartet directly and confirm the
   live repo is left clean.
5. Three-leg parity; then a REAL hook exercise: make a trivial docs-file commit and
   confirm the hook chain (py sync-claude → py gen-skills → bash lint) passes.
6. Commit `feat(25): port setup/release trio to python (MIG-04 partial)`; SUMMARY (note
   MIG-04 completes in 25-05).
</tasks>

<acceptance>
- `bash bin/sync-claude.sh --check` exits 2 on a seeded drift, 0 clean — byte-identical
  diagnostics; gen-skills `--check` exits 1 on drift, 0 clean.
- Gen-skills quartet passes post-flip; `git status` clean after.
- Release no-args exits 1 (the PIPESTATUS artifact from Phase 24 stays understood — assert
  the REAL exit); golden release ×5 cases byte-match on the py leg.
- Three-leg parity 0/0/0; SUITE_MANIFEST match; freeze guard clean; live hook commit
  succeeds through the ported hot path.
</acceptance>
