# Phase 25 Adversarial Review — Parallel Migration + Cutover

**Reviewed:** 2026-07-03 (xhigh recall; range 16f01df..HEAD ≈ the whole Phase-25 diff).
**Method:** 10 finder angles (5 correctness + reuse/simplification/efficiency/altitude/
conventions) × up to 8 candidates → dedup → verify (direct evidence on the checkable
mechanicals) → ReportFindings (15, correctness-first) → this ledger. Angle B
(removed-behavior) sub-delegated and timed out with no findings; the other nine gave
dense coverage.

## Fixed this review (commit bb5ba7f + the conventions cleanup commit)

| # | Finding | Severity | Fix |
|---|---------|----------|-----|
| C1 | `common/__init__.py` eager `from .yaml_rt import` made EVERY ported tool transitively require ruamel.yaml; the pre-commit hook runs `bin/lint.sh`, so a greenfield user (PyYAML only, per docs) had **every commit blocked** with a "brownfield bootstrap" ImportError. | **CRITICAL** | yaml_rt re-exports made LAZY (PEP 562 `__getattr__`); public API unchanged; verified lint/audit/checkers import without ruamel. |
| D6 | `normalize.sh` `for _root in ${_NORM_EXEC_ROOTS}` (unquoted) glob-expanded each split field → a checkout path with a shell metachar could corrupt the `<EXEC_ROOT>` sed program and **fabricate a parity divergence** in my own D-09 seam. | High | Split via `IFS=: read -a` (no glob). Verified a `[x]`-containing root now normalizes correctly. |
| D1/D2 | `release.py` / `gen_skills.py` translated bash `cd` into a process-global `os.chdir` with no restore → poisons in-process callers (pytest importing `main()` is left rebased on the live repo, or in a deleted dir). | Med | Both restore cwd in `finally`. Verified `gen_skills.main()` leaves cwd unchanged. |
| C2 | `check_sources_cloud_safe` printed the stale bash-era "bin/lib not found / set LIB_DIR" on the (reachable) missing-ruamel path. | Low | Message now names the real fix (`pip install ruamel.yaml`). |
| C3 | The shipped `parity.yml` ran the unshipped `tests/run-all-suites.sh` → **permanently red CI on every template fork**. | Med | Both suite-running jobs neutral-skip when the harness is absent (same guard as `check-staged-parity.sh`). |
| F14 | Migration DR + log/index dated **2026-07-04** — the actual date is 2026-07-03 (machine clock + SessionStart); the reflect entry sorted above later 07-03 ingests. | Med (ships in template) | DR renamed `dr-2026-07-03-python-migration`; frontmatter/index/log dates + wikilink targets corrected; `.planning` 07-04 mislabels swept (one legit future-date in 16-RESEARCH.md preserved). |
| F15 | Commit 455994b (which staged log.md) captured a pre-commit hook-clobber `lint \| findings: 0` entry contradicting the committed report (92 findings). | Low | The 0-findings clobber entry removed from log.md. (The clobber BUG itself remains filed — todo 2026-07-03-hook-lint-clobbers-wiki-report.) |

**N-7:** the C1 + D6 fixes touched frozen surface (`common/__init__.py`, `normalize.sh`)
→ `FREEZE_ALLOW_REBASE=1` on bb5ba7f, baseline re-pinned at bb5ba7f in 74589a0; the
full three-leg gate passed (PARITY OK 238 pairs — the lazy import + cwd restore are
byte-transparent to parity).

## Deferred — faithfully-lifted / parity-neutral / untested-path (parity bar holds)

These are real but reproduce the retired bash behavior byte-for-byte, or bite only on
paths NO test exercises; changing them is a post-migration behavior decision, not a
parity fix. Recorded for the SHIMOUT/future-hardening pass:

- **search.py byte-vs-char** word-length skip (`len(encode()) <= 3` vs bash `${#word}`)
  — diverges only for multibyte query words in a UTF-8 locale; search keyword/query is
  already the documented-broken-since-Phase-14 surface.
- **validate_op.py / check_privacy.py `open()` without `encoding=`** inside `except
  Exception` → bare FAIL on a non-ASCII page under LC_ALL=C. Parity-neutral (both legs
  behave identically under the seam's C locale); latent in the original heredoc too.
- **release.py `finally` vs bash `trap ... TERM`** — SIGTERM during `--apply` leaks the
  staged temp dir (Python `finally` doesn't run on default SIGTERM). Rare, manual path.
- **lint.py `--fix` `except Exception: pass`** swallows write failures + the
  has_contradictions branch reports a no-op fix. Faithful to the bash `--fix`; the
  report/log-write-on-hook-path clobber is the separately-filed known bug.
- **audit_claims.py locator dispatcher `except Exception: return None,None`** masks
  resolver errors as insufficient-locator. Faithful to the bash resolver.
- **init-wizard.sh phantom `bash>=4` preflight** — the 1100-line bash body that needed
  bash 4 is gone, but the preflight is preserved verbatim (parity with the retired
  body); relaxing it (so stock-macOS 3.2 `--help` works) is a behavior change.
- **datetime.now() vs `date -u`** in init_wizard summary + brownfield bootstrap/scan
  stamps — breaks PATH-`date`-shim interception on untested env combos; consciously
  accepted for these parity-exempt/fixture-pinned tools (25-01/25-05 SUMMARYs) since no
  test pins their dates via PATH shim.
- **init_wizard BSD-`stat` fallback dropped** — macOS setup-date stderr divergence
  (the port keeps only `stat -c`); wizard is parity-exempt.
- **console_scripts repo_root wrong on non-editable/wheel install** — the advertised
  `compendium-<tool>` entry points anchor repo_root three dirs above `__file__`, valid
  only for the src-layout checkout. SHIMOUT-adjacent; the `.sh` shims (the supported
  interface) are correct.
- **test_neutrality_covers_skills.sh cleanup guard `/tmp/*`** vs `mktemp -t` honoring
  `$TMPDIR` — orphan fixtures on non-/tmp TMPDIR hosts (test hygiene, no correctness
  impact on the assertion).

## Deferred — coverage / altitude (worth a future pass, not blocking)

- **live-repo placeholder erases write-parity signal** for the PWD-fallback class (a py
  port that writes different bytes to the live wiki report/log than the oracle passes
  the tree channel by construction). The deliberate trade to kill concurrent-edit false
  divergences; the assumption "those tools' write-behavior is owned by fixture-rooted
  tests" is currently unenforced — a future guard should assert every live-repo-rooted
  writer also has a fixture-rooted write test.
- **capture_footprint direct-call vs seam-call normalize asymmetry** — `_NORM_EXEC_ROOTS`
  is set only at the seam's capture; a direct `capture_footprint` call (characterization
  tests) normalizes the same tree differently. Latent golden mismatch across entry points.
- **exec-root token collapses all three roots to one `<EXEC_ROOT>`** — blinds parity to
  a genuine wrong-checkout root-resolution bug. The residual risk of the D-09 unification.
- **16 hand-written exec-shims, no form-conformance gate** — a `gen-skills --check`-style
  drift test rendering the §1 template per tool would catch a forked shim.
- **GIT date-pin copy-pasted at 4 sites** + clock determinism per-call-site — a single
  `_now()` honoring the fixture env, and one shared pin in the seam, would prevent the
  next tool port from rediscovering the same cross-run-divergence class.
- **verbatim ALLOWLIST/DENYLIST tuple assertions** are change-detectors (already broke
  once at CUT-01); assert the load-bearing invariants (must-ship / must-never-ship) and
  let the golden own the exact list.

## Deferred — cleanup (mechanical, non-observable)

Nine private `_err`/`_out`/`_reconfigure_streams`/`_rc_of` helper clusters across the
ported modules; three sha256 variants + the op_hash strip duplicated in brownfield; a
dead `parse_frontmatter` twin in check_neutrality; a dead `run_main` in
test_brownfield_unit; the write-only findings temp file in lint.py; dead
BROWNFIELD_LIB_DIR/BF_TTY_STDIN env writes; the 5-way `--root` arg copy-paste; the
in-process CN_/CP_/CSG_ env round-trip. All non-observable → a `compendium/_cli.py`
shared-helper consolidation is the natural home, deferrable to the CUT-02 pytest pass.

## Deferred — efficiency (measured, migration window closing)

Per-file `normalize | sha256sum` fork chain in capture_footprint (~25ms/file, ~10×
reducible); the bash leg is a pure function of the frozen baseline (cacheable → ~halves
gate time); O(N²) `--require-parity` pairing; `find|wc` per-call counter; ingest/search
subprocess chains whose PATH-shim rationale only truly applies to `date`. Real, but the
gate runs on few remaining commits; the CUT-02 pytest conversion supersedes most of this
harness. Recorded, not applied.
