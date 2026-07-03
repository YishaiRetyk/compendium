# 25-01 SUMMARY — brownfield port (MIG-01)

**Status:** Complete (2026-07-03)
**Commits:** D-09 seam rebase (K1) + baseline re-pin (K2) + the port commit (see git log `fix(25):` / `chore(25):` / `feat(25): port brownfield`)

## What shipped

- `src/compendium/brownfield.py` (2,230 lines): full port of the 2,259-line bash
  orchestrator — 5 subcommands, the 5 heredocs extracted MECHANICALLY (generator over
  byte-exact line ranges) with only the sanctioned transforms: import mapping
  (`brownfield_* → compendium.common.*`, sys.path lines dropped), env-handoff assignments
  in `main()`, heredoc `sys.exit` retained. My independent verbatim-sampling: 209/214
  sampled non-comment heredoc lines found byte-identical in the module; the 5 misses are
  exactly the sanctioned import-rewrite lines.
- `bin/brownfield.sh` → canonical exec-shim (contract §1); `brownfield` appended to
  `tests/ported.manifest` (first entry — the py parity leg is now LIVE for every
  subsequent commit).
- `tests/test_brownfield_unit.py` (TEST-06): 8 tests through the public dispatch +
  tmp-fixture bootstrap/scan runs.
- Port-agent self-verification: 45/45 four-channel cases (dispatch/scan/bootstrap/
  suggest/review-typing/verify + ruamel-missing, EOF paths, TTY-absent branches).

## The headline: the first live channel comparison found a Phase-24 harness gap (D-09 rebase)

This plan's parity run was the FIRST execution ever of the cross-run channel comparison
(Phase 24's staged gate short-circuits on an empty manifest by design; CI parity never
runs on private commits). It failed on 78 tree channels — and the failure class was
**bash-vs-bash reproducible**, i.e. a harness defect, not a port defect:

1. `capture_footprint` hashed file contents RAW, but written artifacts embed
   second-granularity wall-clock run stamps (`REPORT.md` footer, `APPLIED.md` run header)
   — two legs minutes apart can never match.
2. Tools embed their own checkout root (`.brownfield-env`'s `BROWNFIELD_LIB_DIR`):
   oracle-worktree path vs staged-index path vs repo path — three spellings of "here".
3. Repo-root footprints picked up `__pycache__`/`.pytest_cache` churn.

**Fix (frozen-surface, sanctioned D-09 ownership-rebase; N-7 record):**
- `tests/lib/invoke_tool.sh`: tree hashes now computed over NORMALIZED content (same
  treatment stdout/stderr always had); `__pycache__`/`.pytest_cache` pruned like `.git`;
  the seam exports `_NORM_EXEC_ROOTS` (worktree:exec-root:git-root) at capture time.
- `tests/lib/normalize.sh`: each exec root → one `<EXEC_ROOT>` token (before the `<TMP>`
  patterns); the space-separated `YYYY-MM-DD HH:MM:SS UTC` stamp form joins the `<TS>`
  class. Hash/bare-date redaction remains deliberately absent.
- `tests/oracle-exempt.txt`/`.md`: ONE scoped key exemption —
  `11/test_end_to_end_happy_path/brownfield-00[34]` (e2e verify tree captures).
  `applied.log` records the sha256 of suggest outputs that embed `GENERATED_AT`
  stamps: second-order volatility that hash redaction must not mask. Verify's
  4-channel parity is owned by the 5 dedicated `test_verify_*.sh` tests.
- All 38 golden case dirs were regenerated from the (still all-bash) oracle under the
  new hashing as a validation step — and came out BYTE-IDENTICAL to the committed
  goldens (Phase 24's per-case determinism engineering had already kept every volatile
  class out of the golden captures), so K1 ships ZERO golden changes; a plain re-run
  after regeneration was 10/10.
- `FREEZE_ALLOW_REBASE=1` used on K1 (this note is the required N-7 record);
  `tests/freeze-baseline.sha` + `phase-24-freeze` tag (LOCAL-ONLY, never pushed)
  re-pinned at K1 in K2 — K1's tree still has ALL-BASH `bin/` bodies, so the oracle
  remains a pure bash reference for every remaining Phase-25 flip.

**Validation of the fix:** two full WIKI_IMPL=bash capture runs of phase-10/11 +
`--require-parity` → `PARITY OK: 81 paired routed calls byte-identical` (with the two
documented EXEMPT lines). This bash-vs-bash proof isolates the harness fix from the port.

## Second gate finding: fixture trees were not cross-run deterministic (commit 4b2fc1f)

The first FULL gate run then blocked on 50 more tree/stdout divergences — ALL of them
fixture volatility, zero implementation divergence (44 of the keys were audit-claims
invocations where BOTH legs ran the identical bash oracle): runtime-born fixture git
SHAs (unpinned commit dates) leaking into audit-state/repo-snapshot/drift output;
nanosecond+RANDOM seed filenames; verifier scripts baking mktemp paths into committed
content; a mktemp basename embedded in traversal fixture page content. Fixed in the
test helpers (`test(25):` commit 4b2fc1f); full-suite bash-vs-bash proof went
50 → 0 real failures. Residual noise class documented: PWD-fallback (live-repo)
footprint captures diverge if ANYTHING edits the working tree between the gate's two
capture legs.

## Third gate finding: live-repo footprints are concurrent-edit-prone by construction
(commits bd1bf24 + 6a7d2c0 — D-09 rebase #3, N-7 record)

The next gate run blocked on 3 keys whose ONLY delta was a planning note the human
saved mid-gate (all three: `607a608`-class additions of the same live-tree file; both
legs identical bash). Deep fix instead of retry-and-hope: `capture_footprint` now
emits the fixed-placeholder tree treatment (precedent: extracted-tree goldens) whenever
the footprint root IS the live repo — the tree channel is only meaningful over
per-test fixture roots. Fixture-rooted tests keep full tree capture; golden suite
unaffected (10/10, zero re-freeze); working-tree edits during gates are now harmless.
FREEZE_ALLOW_REBASE=1 used on bd1bf24; baseline+tag re-pinned at bd1bf24 in 6a7d2c0.

## Deviations / notes

- Plan-doc deviation (recorded in 25-CONTEXT): Wave-1 drafting ran as SIX parallel
  port agents (fan-out per the milestone brief) with flips/commits serialized by the
  coordinator, instead of strictly sequential single-agent execution.
- `BROWNFIELD_TODAY` uses `datetime.now(timezone.utc)` rather than subprocess `date -u`
  (the PATH-shim parity rule was derived AFTER this port's brief): acceptable for
  brownfield specifically — no brownfield test or golden pins dates via PATH shim; the
  suites pin via `BROWNFIELD_FIXTURE_TODAY`, which the port honors identically.
- Unhandled-traceback texts differ (`File "<stdin>"` vs module path) — unfixable for any
  port; all HANDLED error paths byte-match; no suite test exercises an unhandled path.
- Interactive-TTY small-batch review-typing branch not byte-verified (no TTY in the
  harness); the code is verbatim and the scripted-stdin + non-TTY branches are covered.
