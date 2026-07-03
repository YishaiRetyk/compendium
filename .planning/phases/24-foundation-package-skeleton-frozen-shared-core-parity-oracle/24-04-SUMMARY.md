# Plan 24-04 Summary — Characterization backfill + anti-signal rewrite (wave 3)

**Executed:** 2026-07-03. **Requirements:** TEST-03, TEST-04. **Status:** Complete. Phase-24 suite 6/6.

## What shipped

**Task 1 — goldens (28 committed 4-channel case dirs under `tests/goldens/`):**
- `validate-op/` (zero tests before): 10 cases — all 4 ops happy paths, MERGE-same-path,
  supersede/archive-already rejections, usage-noargs, bad-op, missing-target. Exit-file
  contract asserted per case (0/1). Deterministic (umask 022 in lib.sh; relative paths;
  fixed frontmatter dates).
- `search/`: 9 cases. **CHARACTERIZATION FINDING:** keyword/`--paths-only`/`--query` are
  SILENTLY BROKEN (exit 1, empty channels) on the convention-conforming PIPED index —
  `[[id|Title]]` title extraction keeps `id|Title`, the slug never resolves, and the fallback
  `grep|head` under pipefail aborts the script. **Verified live on the real wiki** (broken
  since the Phase-14 piped-link migration). Frozen as-is per the parity bar; bare-index cases
  cover the working result-formatting path; post-migration fix filed at
  `.planning/todos/pending/2026-07-03-search-keyword-broken-on-piped-index.md`.
- Error paths (D-17): `sync-claude/check-drift` exit 2 (cwd-based → through the oracle);
  `gen-skills/check-in-sync` exit 0 (worktree oracle, no false drift);
  `gen-skills/check-drift` exit 1 (MANDATORY, writable extracted tree, skill drift-injected);
  `init-wizard/already-initialized` exit 4 (extracted tree seeded with `.wizard-answers.yaml`,
  mtime frozen via `touch -d` — the message embeds the file mtime as "setup date");
  `init-wizard/preflight-missing-dep` exit 3 (python3-ONLY strip via a symlink farm keeping
  bash/git/coreutils); `checkers/check-privacy-violation` exit 2 (`--root` violating fixture);
  `lint/ci-json-malformed` exit 1 vs `lint/text-malformed` exit 0 (the dual-mode contract;
  malformed-only fixture avoids date-dependent decay math). Extracted-tree cases carry a fixed
  placeholder `tree` channel (full-repo tree varies with the baseline ref; exit/stdout/stderr
  are load-bearing).
- `ingest/mutating-scaffold` — the mutating-tool golden (file-tree channel load-bearing:
  records `sources/2026/2026-01/2026-01-02-sample-note.md` + log append). Determinism (L-1):
  PATH-injected frozen `date` shim + explicit `--contributor @fixture`; captured twice and
  `assert_parity`'d before freezing. (Plan suggested ingest/lint --fix; ingest chosen — lint's
  in-python `date.today()` cannot be frozen from outside, ingest's `date -u` can.)
- `tests/oracle-exempt.md` (+ machine-readable `tests/oracle-exempt.txt` — cycle-6 MEDIUM b):
  init-wizard exit-4 + the `$0`-relative state-dependent class + exit-3 (cross-referencing the
  shim contract test) + the gen-skills in-sync/drift split, each with the WHY.
- `tests/phase-24/{lib.sh,run.sh}` — seam-sourcing lib (umask 022, `extract_writable_tree`,
  `golden_check_or_freeze`) + glob-autodiscovery aggregator.

**Task 2 — anti-signal rewrites + the exit-3 contract test:**
- `tests/phase-11/test_hashlib_not_sha256sum.sh` REWRITTEN: asserts the emitted
  `# op_hash: sha256:<64hex>` VALUE on line 2 of the suggest-generated
  `.brownfield/migrations/01-page-typing.sh` (the CONFIRMED channel) against a reference
  computation of the documented canonicalization (strip op_hash headers + data_schema_version
  trailer). Migrations source-grep removed. Green.
- `tests/phase-20/test_pdf_extract_markers.sh` REWRITTEN: both source-greps replaced with a
  LOCAL HTTP STUB (free port; `OLLAMA_URL` + `PDF_EXTRACT_MODEL=stub-model` env knobs — the
  tool checks the model tag in `/api/tags`, discovered at execute time) asserting the EFFECT:
  POST `/api/generate` observed + response consumed into the output. Marker-count + Ollama-SKIP
  asserts kept. Green.
- `tests/phase-24/test_shim_preflight_exit3.sh` (cycle-4 #2b + cycle-6 #5): canonical
  preflight-preserving shim → exit 3 BEFORE Python with python3 stripped; bare bootstrap-shim
  → 127 not 3 (non-trivial); happy passthrough with python3 present; MANIFEST-DRIVEN loop
  (contract registry `init-wizard → strip python3 → exit 3`) proven via a WIKI_EXEC_ROOT
  scaffold (flags bare, passes canonical, no-ops on the real empty manifest). Green.

**Task 3 — the inventory + guard (HIGH#7):**
- `tests/impl-assertion-inventory.md`: 7 rows — test_lint_version (impl-asserting,
  defer-to-MIG-02), the 3 hook-form tests (shim-contract, keep — the `.sh` command forms ARE
  the surviving contract), the 2 rewritten anti-signal tests (behavioral, done), and the
  phase-10 §5 doc-content grep the guard's discovery surfaced (shim-contract doc-content).
  RB-4: phase-22/23 swept — no impl assertions there.
- `tests/phase-24/test_impl_assertion_inventory.sh`: re-runs the mechanical discovery
  (grep/sed/awk/cat with a bin script or the hook as data; invocations + `noqa: direct-bin`
  excluded) and fails on any unlisted file. It caught the phase-10 doc-grep on first run
  (pre-fix-failing behavior demonstrated live). Green.

## Verification

`bash tests/phase-24/run.sh` → 6/6; both anti-signal rewrites green standalone; all plan
acceptance spot checks pass (10 validate-op case dirs, 28 tree channels, exit goldens
4/3/1/2/0 as contracted, no source-greps remain, negative greps clean); goldens re-asserted
on second runs (byte-stable); no today-dates or unredacted tmp paths in any golden;
`git diff bin/` empty; neutrality gate exit 0.

## Deviations from plan

- Search piped-index cases freeze a LATENT BUG (exit 1/empty) — documented above + todo filed;
  bare-index companions added so the working path has coverage (plan intent: non-hollow goldens).
- Mutating tool = ingest with a PATH-injected `date` shim (case-specific frozen now, D-12
  policy) — lint --fix rejected: its `date.today()` is in-python, unfreezable externally.
- init-wizard exit-4 driver freezes the answers-file mtime (the message embeds it) —
  found by the two-run determinism check at execute time.
- lint text-mode exits 0 (report mode) vs --ci exit 1 — the dual-mode contract captured is
  exit-asymmetric by design; recorded rather than "text exit 1" as the plan sketch assumed.
