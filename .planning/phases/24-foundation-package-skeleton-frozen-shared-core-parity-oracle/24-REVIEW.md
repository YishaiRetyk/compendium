# Phase 24 Code Review — adversarial multi-angle pass (2026-07-03)

**Scope:** `a1b7568..9f1093d` (all six plans + re-baseline). **Method:** 5 parallel finder
agents (10 angles: line-scan, removed-behavior, cross-file, bash/python pitfalls,
oracle/parity-guarantee deep-dive, reuse, simplification, efficiency, altitude, conventions +
goldens-determinism), candidates deduped and verified — several empirically reproduced by the
finders or by direct execution — then fixed and re-verified (seam self-tests, phase-24 suite,
both run-all legs, pytest, divergence test all re-run green).

## Confirmed findings — FIXED (21)

| # | Finding (evidence) | Fix |
|---|--------------------|-----|
| 1 | **Routing gate red at HEAD** — `no-direct-bin-calls.sh` flagged Plan-06's `cp "$REPO_ROOT/bin/…"` scaffold lines (no noqa); every `run-all-suites.sh` invocation FATALed (verified by execution) | Context exclusions (`cp `/`echo`/`printf` argument lines are not invocations) + the two offending files pass without markers |
| 2 | **Local hooks disabled since April** — `core.hooksPath` pointed at the empty `.git/hooks`; the ENTIRE pre-commit chain (sync-claude → gen-skills → freeze → parity → lint --staged) never ran on any local commit for months, so 24-06's "gate ran live at commit" claim was FALSE | `bin/install-hooks.sh` run (core.hooksPath=.githooks); 24-06-SUMMARY + 24-VERIFICATION corrected honestly; the real gated E2E ran at this review's fix commit |
| 3 | **Subshell capture-key collision (verified)** — `_IT_CALL_N`/`$$` don't survive `$(…)` subshells (the dominant compat shape), so same-tool substitution calls overwrote `<tool>-001` — silent parity-coverage loss | Filesystem-derived per-tool counter (counts existing capture dirs — subshell-safe, deterministic cross-run); self-test extended with an explicit subshell-collision case |
| 4 | **GIT_INDEX_FILE leakage (corruption reproduced)** — pre-commit exports an absolute temp-index path; suite fixtures' `git add/commit` inside the gate then READ/WRITE the parent repo's commit index ("Error building trees" / fixture blobs in the real commit) | The gate scrubs `GIT_INDEX_FILE/GIT_DIR/GIT_WORK_TREE/GIT_PREFIX` (via `env -u`) for all suite runs, after the staged detection + checkout-index consumed the hook's index |
| 5 | **Oracle worktree failure modes (verified)** — `git worktree add` errors swallowed (stale /tmp-cleaned registrations → permanent misleading 127s); a MUTATED cached worktree was silently reused as the "held-fixed" oracle (HEAD-sha check only) | `ensure_oracle_worktree`: cleanliness check on reuse (`status --porcelain`), `worktree prune` before add, loud ORACLE FATAL + return 1 on add failure |
| 6 | **CI oracle unpinned** — parity-suites/parity-equivalence used depth-1 checkouts; the pinned baseline SHA is unreachable → silent HEAD-fallback today, hard N-4 FATAL on every job at the first Phase-25 manifest append | `fetch-depth: 0` on both jobs (common-freeze already had it) |
| 7 | **Golden breaks tomorrow (verified)** — lint text-mode writes `lint-report.md` with TODAY'S dates; the golden's tree channel byte-pinned its hash (reproducible only on 2026-07-03) | Tree channel narrowed to the input page dir (stdout/stderr/exit stay load-bearing); re-frozen; goldens swept for today-dates (clean) |
| 8 | **TZ/locale-dependent goldens** — init-wizard exit-4 stderr embeds the answers-file mtime rendered in LOCAL time; the extracted-tree drivers bypassed the seam's env pins; skill selection collation-dependent | `LC_ALL=C TZ=UTC` pinned on all extracted-tree drivers + `LC_ALL=C ls`; capture-pipeline `sort` pinned to C collation; re-frozen |
| 9 | **Ambient env guts the gate** — a leftover exported `WIKI_PARITY_ONLY_SUITES` would silently narrow the ONLY private-branch parity gate to one suite | The gate unsets the ambient knobs; sanctioned narrowing only via gate-scoped `WIKI_PARITY_GATE_ONLY_SUITES`, loudly logged (self-tests migrated) |
| 10 | **3 missed direct-call sites** — relative-form `bash bin/sync-claude.sh` ×2, escaped-quote nested `bash -c "bash \"$REPO_ROOT/bin/brownfield.sh\"…"`; the gate's patterns blind to both shapes | Sites routed through the seam; gate patterns extended (relative form for the 16 in-scope tools + escaped-quote form) |
| 11 | **Golden self-certification** — a missing golden dir (forgotten `git add`, rebase loss, path typo) silently auto-froze CURRENT behavior and passed green in CI forever | `GOLDEN_FREEZE=1` now required to create; missing golden without it = loud FAIL with the recipe |
| 12 | **Freeze-guard --staged block loop** — staged mode diffed the whole index vs the OLD baseline: after any sanctioned ALLOW landing, every later commit re-flagged; the remediation text was unsatisfiable (a commit cannot contain its own SHA) | Staged mode = index vs HEAD over frozen paths ("does THIS commit touch it"); remediation rewritten as the two-step follow-up-commit recipe |
| 13 | **Template-public breakage** — shipped `bin/check-staged-parity.sh` + hook hard-depend on the unshipped tests harness → template users' bin/ commits permanently blocked | Neutral missing-harness skip at the top of the gate |
| 14 | **Silent test deletion** — a deleted pinned test vanished from the net with every gate green | run-all fails loudly on manifest rows whose test file no longer exists |
| 15 | conftest Ollama probe ran at collection on EVERY pytest run, ignored NO_NETWORK, hardcoded the port | NO_NETWORK short-circuit + `OLLAMA_URL` env; `test_packaging` gains `requires_network` |
| 16 | `--root=<dir>` footprint spelling unchecked → a nonexistent root killed capture-leg tests under set -e (unreproducible in plain runs) | Existence check on both spellings + deterministic placeholder tree for missing roots |
| 17 | Divergence-test double-`trap EXIT` dropped the first trap's cleanup during the early window | Single trap installed once (deferred expansion covers the late-bound worktree path) |
| 18 | `timeout … tests/phase-24/test_precommit_hooks.sh` cwd-relative → phantom cwd-dependent failure | Absolute `$REPO_ROOT` path |
| 19 | AGENTS.md §2 tree diagram omitted `src/`, `tests/`, `pyproject.toml` (inconsistent with the amended permitted list) | Tree updated; byte-twin re-synced |
| 20 | Gate ran the py leg + comparison even with an EMPTY staged manifest (green by construction — pure fallthrough) | Definitionally-sound short-circuit: skip py leg + comparison when the STAGED manifest has zero ported tools (auto-reactivates on the first append), halving Phase-24 gate cost |
| 21 | `normalize` blind to non-`/tmp` TMPDIRs (goldens/parity break on TMPDIR hosts) | Dynamic sed-escaped `${TMPDIR}` redaction alongside the literal `/tmp` pattern |

## Deferred (documented, deliberate)

- Freeze-guard baseline resolution duplicates the oracle's (both updated together here; the
  guard sits OFF the frozen surface — asymmetry noted for the MIG-02-era cleanup).
- `--require-parity` pairing is O(n²) with per-key awk spawns — fine at today's scale; perf
  debt noted for Phase 25 (single-pass join).
- Per-call `IT_STDOUT`/`IT_STDERR` mktemp files are never deleted (small, tmpfs-cleared;
  fixed-path reuse risks caller aliasing — revisit with the pytest conversion).
- The canonical shim heredoc exists as 3 self-test copies and no single template — Phase 25's
  first port should extract THE template the real shims are generated from.
- `hook_freeze_step` in the self-test mirrors (not executes) the hook's stanza; hook content
  is separately grep-asserted. Full hook-execution test deferred.
- `release` dry-run golden freezes the live allowlist — a Phase-25 allowlist edit will
  require a deliberate D-09 re-freeze (cost acknowledged in-test).
- run-all defaults `PDF_EXTRACT_SKIP_LIVE=1` while `tests/phase-20/run.sh` does not
  (entry-point split-brain documented; the manifest pins the run-all environment).
- `docs/reference/python-shim-contract.md` carries locked rules outside the AGENTS.md routing
  table — referenced by the Phase-25 plans/PROJECT.md; consider a routing-table row at CUT-01.
- Conftest `import conftest` monkeypatch is import-mode-sensitive (prepend-mode only).
- `oracle-exempt.txt` requires literal TABs (format documented in-file; repo-controlled).
- The staged gate reads tests/goldens from the working tree by design (cycle-6 reviewed
  shape); tool bodies are the staged surface — limitation documented.

## Frozen-surface handling (D-09 / N-7 ledger)

The fixes touch frozen files (`invoke_tool.sh`, `oracle-worktree.sh`, `normalize.sh`,
`run-all-suites.sh`, `conftest.py`, re-frozen goldens). Applied via the documented
ownership-rebase flow: fix commit lands under `FREEZE_ALLOW_REBASE=1`, then
`tests/freeze-baseline.sha` + `phase-24-freeze` re-pinned to the landed SHA in the follow-up
commit. Both recorded here (N-7). `PARITY_GATE_SKIP` was NOT used — the fix commit ran the
full staged-parity gate live through the freshly-installed hook.
