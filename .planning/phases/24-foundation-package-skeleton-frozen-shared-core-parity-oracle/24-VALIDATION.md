---
phase: 22
slug: foundation-package-skeleton-frozen-shared-core-parity-oracle
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
updated: 2026-07-02
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 24 BUILDS the test infrastructure the rest of v1.5 runs on (the `invoke_tool` parity seam,
> the pytest `conftest.py`, the characterization goldens, `run-all-suites.sh`), so the harness is
> assembled wave-by-wave rather than pre-existing. Every task ships with an `<automated>` verify.

---

## Test Infrastructure

Phase 24 uses TWO co-existing frameworks (both are load-bearing; parity is enforced through the bash seam, unit localization through pytest):

| Property | Bash characterization / parity suites | Pytest unit + packaging harness |
|----------|---------------------------------------|---------------------------------|
| **Framework** | POSIX bash `test_*.sh` per-suite aggregators + the `WIKI_IMPL=bash\|py` parity seam | pytest 8.4.1 (pinned in `pyproject.toml`) |
| **Config file** | none (shell); enumerated suite list hard-coded in `tests/run-all-suites.sh` (`09 09.1 10 11 12.1 12.2 13 15 18 20 22`) | `pyproject.toml` `[tool.pytest.ini_options]` (`testpaths=["tests"]`, `requires_ollama`/`requires_network` markers) |
| **Quick run command** | `bash tests/phase-24/run.sh` | `python3 -m venv /tmp/p22v && /tmp/p22v/bin/pip -q install pytest -e . && /tmp/p22v/bin/python -m pytest tests/test_packaging.py tests/test_conftest_fixtures.py -q` |
| **Full suite command** | `WIKI_IMPL=bash bash tests/run-all-suites.sh && WIKI_IMPL=py bash tests/run-all-suites.sh && WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels /tmp/bch && WIKI_IMPL=py bash tests/run-all-suites.sh --capture-channels /tmp/pch && bash tests/run-all-suites.sh --require-parity /tmp/bch /tmp/pch` | `<venv>/bin/python -m pytest tests/ -q` |
| **Estimated runtime** | ~60–120 seconds (12 suites × 2 impls + channel byte-compare) | ~30–90 seconds (venv bootstrap dominates: system python3 has NO pip, so each pytest run bootstraps a venv) |

Environment notes (load-bearing for the executor):
- **System `python3` has NO `pip`** — every pytest/`pip install -e .` step MUST bootstrap an isolated venv (`python3 -m venv`). This is asserted by `tests/test_packaging.py` and mirrored in Plans 02/03/05 verify commands.
- **`WIKI_IMPL=py` is green-by-fallthrough in Phase 24** — `tests/ported.manifest` is empty, so `py` runs the bash worktree oracle for every tool. Real bash-vs-py signal lights up per Phase-23 port.
- **GNU coreutils assumed** (`stat -c`, `sha256sum`, `readlink`) per the pinned Linux execute environment.

---

## Sampling Rate

- **After every task commit:** Run that task's `<automated>` command (the per-task map below). Max feedback latency **~120 s**.
- **After every plan wave:**
  - Waves 1–2 (Plans 01/02/03): run the bash seam self-tests (`bash tests/lib/test_*.sh`) + the venv pytest quick run.
  - Waves 3–4 (Plans 04/05): run `bash tests/phase-24/run.sh` + `WIKI_IMPL=bash bash tests/run-all-suites.sh` + `WIKI_IMPL=py bash tests/run-all-suites.sh` + the `--require-parity` channel compare.
  - Wave 5 (Plan 06): run `bash tests/phase-24/test_freeze_guard.sh` + `bash tests/phase-24/test_precommit_hooks.sh` + `bash tests/phase-24/test_staged_parity_index.sh`, then `bash bin/check-common-freeze.sh` (must exit 0 at the pinned baseline).
- **Before `/gsd-verify-work`:** Full bash parity suite green under both impls AND the `--require-parity` channel compare green AND the venv pytest suite green.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | PKG-01 | T-24-01 / T-24-04 | Stubs exit nonzero sentinel 70 (a missed port fails loudly, never silently 0) | unit | `python3 -c "import tomllib; assert len(tomllib.load(open('pyproject.toml','rb'))['project']['scripts'])==15"` | ✅ W2 (Plan 01 creates) | ⬜ pending |
| 24-01-02 | 01 | 1 | PKG-01, PKG-03 | T-24-02 | `AGENTS.md ≡ CLAUDE.md` byte-equality held after §2 edit; ported.manifest empty | integration | `bash bin/sync-claude.sh --check && python3 -m venv /tmp/p22v && /tmp/p22v/bin/pip -q install pytest -e . && /tmp/p22v/bin/python -m pytest tests/test_packaging.py -q` | ✅ W2 | ⬜ pending |
| 24-01-03 | 01 | 1 | PKG-03 | T-24-04b | Shim doc locks worktree oracle + shim-owns-bootstrap; `bin/` untouched | doc/grep | `test -f docs/reference/python-shim-contract.md && grep -q 'git worktree' docs/reference/python-shim-contract.md && ! grep -qi 'COMMITTED COPY' docs/reference/python-shim-contract.md && [ "$(git diff --name-only HEAD -- bin/ | wc -l)" = 0 ]` | ✅ W2 | ⬜ pending |
| 24-02-01 | 02 | 2 | PKG-02, TEST-06 | T-24-05 (make_yaml chokepoint) | `make_yaml` round-trip byte-exact after verbatim lift | unit | `python3 -m venv /tmp/p22v2 && /tmp/p22v2/bin/pip -q install pytest -e . && /tmp/p22v2/bin/python -m pytest tests/test_common_extraction.py -q` | ✅ W2 | ⬜ pending |
| 24-02-02 | 02 | 2 | PKG-02, TEST-06 | T-24-06 (byte-copy retired) | `audit-claims ≡ lint.sh` precondition holds; `common/page.py` single source | unit | `/tmp/p22v2/bin/python -m pytest tests/test_common_extraction.py -q` | ✅ W2 | ⬜ pending |
| 24-03-01 | 03 | 2 | TEST-01 | T-22-09/26/35/43/55/56/64/65/66/67 | Seam returns 0 (set-e-safe); worktree oracle; py-via-shim; per-lane root knobs; footprint follows `--root`; pid-stripped pairing; manifest-driven shim bootstrap | integration | `chmod +x tests/lib/*.sh; bash tests/lib/test_normalize.sh && bash tests/lib/test_invoke_tool_seterm.sh && bash tests/lib/test_oracle_scriptrelative.sh && bash tests/lib/test_capture_dir.sh && bash tests/lib/test_shim_smoke.sh && bash tests/lib/test_invoke_tool_selfparity.sh` | ✅ W2 (Plan 03 creates seam) | ⬜ pending |
| 24-03-02 | 03 | 2 | TEST-05 | T-22-11 (baseline drift) | `conftest.py` fixtures behaviorally == `make_*_repo`; fresh tmp per call | unit | `python3 -m venv /tmp/p22v3 && /tmp/p22v3/bin/pip -q install pytest -e . && /tmp/p22v3/bin/python -m pytest tests/test_conftest_fixtures.py -q` | ✅ W2 | ⬜ pending |
| 24-04-01 | 04 | 3 | TEST-03 | T-22-13/47/48/49/57/37 | 4-channel goldens frozen through the oracle; exit-4/exit-3/gen-skills-drift error paths from a writable extracted tree; oracle-exempt.md + machine-readable .txt | characterization | `chmod +x tests/phase-24/*.sh && bash tests/phase-24/run.sh` | ❌ W3 (Plan 04 creates `tests/phase-24/`) | ⬜ pending |
| 24-04-02 | 04 | 3 | TEST-04 | T-22-14/15/58 | hashlib asserts hash VALUE from confirmed channel; pdf-extract local HTTP stub; exit-3 shim contract bound to real shims via manifest-driven loop | behavioral | `bash tests/phase-11/test_hashlib_not_sha256sum.sh && bash tests/phase-20/test_pdf_extract_markers.sh && bash tests/phase-24/test_shim_preflight_exit3.sh` | ❌ W3 | ⬜ pending |
| 24-04-03 | 04 | 3 | TEST-04 | T-22-38 | Every impl-asserting test inventoried + classified; guard fails on any unclassified one | guard | `chmod +x tests/phase-24/test_impl_assertion_inventory.sh && bash tests/phase-24/test_impl_assertion_inventory.sh` | ❌ W3 | ⬜ pending |
| 24-05-01 | 05 | 4 | TEST-01, TEST-02 | T-22-31/32/39/50/59/68/69/70 | Direct bin calls routed through the seam; per-test no-regression; pid-independent `--require-parity`; TEST-level exclusion knob; behavioral per-tool coverage; machine-readable exempt | integration | `chmod +x tests/phase-15/run.sh tests/run-all-suites.sh tests/lib/no-direct-bin-calls.sh tests/test_routed_parity_divergence.sh && bash tests/lib/no-direct-bin-calls.sh && bash tests/test_routed_parity_divergence.sh && WIKI_IMPL=bash bash tests/run-all-suites.sh && WIKI_IMPL=py bash tests/run-all-suites.sh` | ❌ W4 (Plan 05 creates run-all) | ⬜ pending |
| 24-05-02 | 05 | 4 | PKG-04, TEST-01, TEST-02 | T-22-17/19/20/30/40 | 6 required-check names unchanged, no matrix; skills-check installs package; `WIKI_IMPL` matrix + channel-equivalence job; phase-24 in suite list | ci-introspection | `python3 -c "import yaml; [yaml.safe_load(open(f)) for f in ['.github/workflows/lint.yml','.github/workflows/neutrality.yml','.github/workflows/setup-parity.yml','.github/workflows/parity.yml']]" && python3 -m venv /tmp/p22v5 && /tmp/p22v5/bin/pip -q install pytest pyyaml -e . && /tmp/p22v5/bin/python -m pytest tests/test_ci_required_checks.py -q` | ❌ W4 | ⬜ pending |
| 24-06-01 | 06 | 5 | PKG-04, TEST-02 | T-22-21/22/33/54 | Freeze guard: explicit surface, `^{commit}` deref, tag==SHA (N-4), skip-not-pass (exit 3), non-circular pre-Plan-06 baseline | guard | `chmod +x bin/check-common-freeze.sh tests/phase-24/test_freeze_guard.sh && test -f tests/freeze-baseline.sha && bash bin/check-common-freeze.sh && bash tests/phase-24/test_freeze_guard.sh` | ❌ W5 | ⬜ pending |
| 24-06-02 | 06 | 5 | PKG-04, TEST-02 | T-22-42/52/53/61/62/63/64/65 | Staged-parity gate via consumed seam knobs (`WIKI_EXEC_ROOT`/`WIKI_ORACLE_GIT_ROOT`); ONLY recursive hook self-tests excluded (`--exclude-test`); bounded termination; seeded-manifest negative test | behavioral | `chmod +x bin/check-staged-parity.sh tests/phase-24/test_precommit_hooks.sh tests/phase-24/test_staged_parity_index.sh && bash bin/check-staged-parity.sh && bash tests/phase-24/test_precommit_hooks.sh && bash tests/phase-24/test_staged_parity_index.sh` | ❌ W5 | ⬜ pending |
| 24-06-03 | 06 | 5 | PKG-04, TEST-02 | T-22-23/24/41 | Correct `if cmd; then rc=0; else rc=$?; fi` hook exit-capture; local-only freeze tag == committed SHA (`^{commit}`); tag never pushed | integration | `bash -n .githooks/pre-commit && grep -q 'check-common-freeze' .githooks/pre-commit && grep -q 'check-staged-parity' .githooks/pre-commit && python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/parity.yml')); assert 'common-freeze' in d['jobs']" && git rev-parse -q --verify 'phase-24-freeze^{commit}' && diff <(git rev-parse 'phase-24-freeze^{commit}') <(cat tests/freeze-baseline.sha)` | ❌ W5 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*File Exists column: ✅ = the harness the task needs exists before the task runs; ❌ Wn = the task itself CREATES the infrastructure in wave n (Phase 24 is the harness-building phase — there is no pre-existing phase-24 suite, seam, or goldens; each is created in-wave by the plan that owns it, which is why `wave_0_complete: false`).*

---

## Wave 0 Requirements

Phase 24 has NO separate "Wave 0" scaffolding step — the phase's entire purpose IS to build the test infrastructure, so the scaffolding is distributed across the plans and gated by the wave graph:

- [ ] `pyproject.toml` + venv-installable package (Plan 01, wave 1) — enables every `pip install -e .` / pytest step (system python3 has no pip).
- [ ] `tests/lib/invoke_tool.sh` + `tests/lib/oracle-worktree.sh` + `tests/lib/normalize.sh` (Plan 03, wave 2) — the parity seam every later suite routes through; INCLUDES the `WIKI_EXEC_ROOT`/`WIKI_ORACLE_GIT_ROOT` per-lane root knobs + `it_pairing_key` that Plans 05/06 consume.
- [ ] `tests/conftest.py` (Plan 03, wave 2) — the pytest fixture harness for Phase-23 TEST-06 unit growth.
- [ ] `tests/phase-24/` suite + `tests/goldens/**` + `tests/oracle-exempt.{md,txt}` (Plan 04, wave 3) — the frozen characterization references.
- [ ] `tests/run-all-suites.sh` + `tests/SUITE_MANIFEST.txt` + `tests/lib/no-direct-bin-calls.sh` (Plan 05, wave 4) — the aggregate parity runner with the `--exclude-test` knob + pid-independent `--require-parity`.
- [ ] `tests/freeze-baseline.sha` + `phase-24-freeze` tag (Plan 06, wave 5) — the pinned frozen baseline the seam's oracle and the freeze guard read.

**Nyquist compliance:** every task in the per-task map has a concrete `<automated>` command; there are no MISSING-test placeholders. `nyquist_compliant: true`. `wave_0_complete` stays `false` because the scaffolding lands in-wave (waves 1–5), not in a dedicated Wave 0 before execution.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub branch-protection required-check names remain the same 6 (`lint`, `privacy-leak`, `strict`, `skills-check`, `neutrality`, `setup-parity`) after CI wiring | PKG-04 | The required-check contract lives in the GitHub repo settings UI, not in the tree; `test_ci_required_checks.py` asserts the job KEYS exist + carry no matrix, but the branch-protection binding is a one-time UI fact | After Plan 05 lands, confirm in the (private) repo settings that no required-check name changed and that the new `parity-*`/`common-freeze` jobs are NOT added as required (they are additive lanes). CI itself never runs on the private migration branches (origin is the public template) — this is a settings-only check. |

*All executable phase behaviors have automated verification; the single manual item is a GitHub-settings fact outside the tree.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (distributed in-wave; documented above)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-02 (cycle-6 replan — synchronized with the revised Plans 03/04/05/06)
