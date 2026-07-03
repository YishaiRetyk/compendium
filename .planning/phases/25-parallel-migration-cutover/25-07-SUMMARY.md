# 25-07 SUMMARY — cutover fan-in (CUT-01)

**Status:** Complete (2026-07-04)

## What shipped

- **Task 0 — template functionality fix (the migration's ONE deliberate behavior
  change):** the release ALLOWLIST gains `src`, `pyproject.toml`, `tests/lib` — a
  released template without `src/` would ship 16 broken shims; `tests/lib` because
  the shipped phase-07/18 suites are seam-routed. `tests/ported.manifest` +
  `tests/freeze-baseline.sha` deliberately NOT shipped: verified in
  `_oracle_baseline_ref` that their absence makes the seam's HEAD-fallback legal on a
  template checkout (HEAD = shims + src → the checkout's own Python runs).
  The golden-locked `release/dry-run-plan` was re-frozen from the post-cutover
  implementation; the delta is exactly the three new INCLUDES lines.
  **N-7 record:** this commit used `PARITY_GATE_SKIP=1` (the all-bash oracle can
  never emit the new INCLUDES lines — a definitionally expected divergence) and
  `FREEZE_ALLOW_REBASE=1` (golden change), immediately followed by the baseline
  re-pin and a full three-leg certification run that replaces the skipped gate.
- **Decision record:** `wiki-cloud/decisions/dr-2026-07-04-python-migration.md`
  (reflect workflow; trigger_type schema-update) + index and log entries;
  `validate-op UPDATE` and `lint --category linkres` clean. The DR ships in the
  template (decisions/ is allowlisted) — written placeholder-clean.
- **Reference census:** 228 `bin/*.sh` references across 18 names in schema/, docs/,
  AGENTS.md/CLAUDE.md, .github/, .claude/settings.local.json — ALL resolve
  post-migration except ONE pre-existing stale reference (`bin/upgrade.sh`, an
  aspirational v1.2 promise that was never built): fixed in
  `docs/reference/release.md` (which also still said `wiki/`, pre-dating the tier
  split). Zero references to the retired `migrate-privacy-dirs.sh`.
  `AGENTS.md ≡ CLAUDE.md` byte-equality holds (no AGENTS edit was needed).
- **Contract-doc correction:** the shim-contract §4 exit table overgeneralized
  "checkers exit 2"; `check-sources-cloud-safe` exits **1** on violation (its real,
  test-pinned contract) — table split accordingly (25-02 finding).
- **Final certification:** full three-leg parity run at the re-pinned baseline +
  `pytest` full run + freeze guard — results recorded below at execution.

## Oracle-model note (recorded for the review)

With the cutover baseline re-pinned past the flips, the `WIKI_IMPL=bash` lane now
runs the certified post-migration state (shims → Python) rather than original bash.
Equivalence to the original bash remains proven TRANSITIVELY: each cluster's flip
commit was gated against the then-all-bash oracle; the oracle's job after cutover is
regression-guarding the certified state. The milestone-brief's "bash lane is always
bash" phrasing described the migration window, which is now closed.
