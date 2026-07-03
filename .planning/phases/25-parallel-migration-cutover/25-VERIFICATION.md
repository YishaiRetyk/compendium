# Phase 25 Verification — Parallel Migration + Cutover

**Verified:** 2026-07-03, against the cutover-certified baseline (455994b, re-pinned 6461046).
**Method:** per-requirement evidence from the gated flip commits (each ran the full
three-leg staged-parity gate: bash-oracle leg, live py leg, 4-channel byte comparison
over 238 paired routed calls) + the post-cutover certification run + the TEST-06
pytest layer.

## MIG-01 — brownfield cluster

Status: Complete

Evidence: commit ad0e821 (gate: RUN-ALL OK ×2 legs + PARITY OK 238 pairs).
`src/compendium/brownfield.py` (5 subcommands, heredocs mechanically verbatim,
imports compendium.common); byte-exact YAML/REPORT via the make_yaml chokepoint
(phase-10/11 fixture suites green both legs: 31/32 + 47/48 = pinned manifest state);
op_hash line-2 value asserted by the rewritten behavioral test. 45/45 agent
channel-diff cases. tests/test_brownfield_unit.py (8).

## MIG-02 — lint + audit-claims

Status: Complete

Evidence: commit 814c1aa (gate green). Byte-copy RETIRED onto common.page (zero
re-declared symbols, grep-verified); --ci json golden byte-match; dual-mode exits;
--staged hook mode ran live in the very commit; audit --verifier STDIN-only +
shell=False behaviorally proven; the three deferred impl-assertion rewrites landed
mutation-verified. tests/test_lint_audit_unit.py (39).

## MIG-03 — checkers

Status: Complete

Evidence: commit 81ca50d (gate green, first try). Exit contracts preserved
(neutrality 2 / privacy 2 / sources-cloud-safe 1 — its real pinned contract; the
shim-contract table corrected at CUT-01); both deferred impl-assertion rewrites
landed mutation-verified; live-repo runs of all three CI gates green through Python.
tests/test_checkers_unit.py (13).

## MIG-04 — setup/release family

Status: Complete

Evidence: commits e1cdb3f (trio) + 6064c6c (init-wizard). sync-claude --check exit 2
/ gen-skills --check exit 1 preserved; the pre-commit hot path ran Python live from
e1cdb3f onward; release full-publish parity against local bare remotes; init-wizard
exit-3 preflight IN THE SHIM (contract test green unmodified), exit-4 in the module,
setup-parity byte-equality verified (canonical render == fixture).
tests/test_setup_release_unit.py (24) + tests/test_init_wizard_unit.py (14).

## MIG-05 — wiki-ops family

Status: Complete

Evidence: commit 2b5db31 (gate green). Six tools incl. repo-snapshot (RB-1 #16);
external boundaries stay subprocess/HTTP (PATH-shim goldens green on the py leg);
search's piped-index bug ported faithfully (goldens pin it); all applicable goldens
byte-matched (validate-op ×10, search ×9, requirements-sync, ingest mutating).
tests/test_wiki_ops_unit.py (31).

## MIG-06 — retirements

Status: Complete

Evidence: commit 2b5db31 — bin/migrate-privacy-dirs.sh deleted (census: zero
references; history preserves it); install-hooks.sh left bash. Both recorded in
25-04-SUMMARY.md + the migration DR.

## TEST-06 — net-new pytest unit layer

Status: Complete

Evidence: 129 net-new module-level tests across six cluster files (8+13+24+31+14+39)
plus the Phase-24 seed layer; full pytest run green in the certification pass.

## CUT-01 — cutover documentation + reference verification

Status: Complete

Evidence: commit 455994b + re-pin 6461046. Migration DR
(dr-2026-07-03-python-migration) authored via reflect, indexed + logged, validate-op
+ linkres clean; census 228 bin/*.sh refs / 18 names all accurate (1 pre-existing
stale upgrade.sh ref fixed); AGENTS.md ≡ CLAUDE.md byte-equality held (cmp clean);
template allowlist ships src + pyproject.toml + tests/lib (HEAD-fallback verified
legal without manifest/baseline); dry-run golden re-frozen (+3 INCLUDES lines
exactly); the one PARITY_GATE_SKIP recorded per N-7 and replaced by the full
three-leg post-cutover certification run.

## Phase gates

- All 7 plans complete (SUMMARYs 25-01 … 25-07); Wave-1 flips each landed through
  the full staged-parity gate; Wave-2 certified post-hoc as documented.
- Freeze guard clean at the final baseline; SUITE_MANIFEST per-test states pinned
  and matching on both legs throughout.
