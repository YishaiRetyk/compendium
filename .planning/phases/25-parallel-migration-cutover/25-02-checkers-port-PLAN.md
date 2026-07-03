---
phase: 25-parallel-migration-cutover
plan: 02
type: execute
wave: 1
depends_on: [01]
files_modified:
  - src/compendium/check_neutrality.py
  - src/compendium/check_privacy.py
  - src/compendium/check_sources_cloud_safe.py
  - bin/check-neutrality.sh
  - bin/check-privacy.sh
  - bin/check-sources-cloud-safe.sh
  - tests/ported.manifest
  - tests/test_checkers_unit.py
  - tests/phase-15/test_neutrality_leak_source_rekey.sh
  - tests/phase-18/test_neutrality_covers_skills.sh
autonomous: true
requirements: [MIG-03]
---

<objective>
Port the three privacy/neutrality checkers (check-neutrality 421 lines / check-privacy
132 / check-sources-cloud-safe 141) — the smallest cluster, proving the 25-01 template
generalizes — preserving the exit-2-on-violation contract and the CI `privacy-leak` /
`neutrality` hard gates. Includes the two MANDATED impl-assertion rewrites deferred to
MIG-03 by the inventory.
</objective>

<context>
- Exit contract (shim-contract §4): **2 on violation** for all three; 0 clean; 1 usage/
  operational error. Diagnostics text is byte-load-bearing (CI greps + tests).
- Inventory rows (defer-to-MIG-03 — REWRITE IN THIS PLAN):
  - `tests/phase-15/test_neutrality_leak_source_rekey.sh:15+` — greps checker SOURCE via
    a path variable for PUBLIC_PATHS/denylist coverage → rewrite to behavior probes: run
    the checker against a fixture tree containing a leak at each covered path and assert
    exit 2 + the violation line.
  - `tests/phase-18/test_neutrality_covers_skills.sh:6` — same class (`.claude/skills`
    in PUBLIC_PATHS) → behavior probe: plant a denylisted term in a fixture
    `.claude/skills/` file, assert detection.
- check-neutrality reads `bin/check-neutrality-denylist.txt`-style config (verify actual
  denylist location at execute time) and walks PUBLIC_PATHS; check-privacy and
  check-sources-cloud-safe use common privacy predicates (import compendium.common.privacy
  where the heredocs did the equivalent).
- These checkers gate CI on every push of the public template — stderr/stdout discipline
  and violation-line formats must be byte-stable.
</context>

<tasks>
1. Baseline both legs; read the three scripts; inventory each check's walk scope,
   violation output format, and exit paths.
2. Port the three modules (manual argv dispatch, verbatim usage/error text). Shared
   walk/privacy logic imports `compendium.common`; checker-specific logic stays in each
   module (no new common/ code — frozen).
3. Rewrite the two impl-asserting tests to behavior probes (keep FILENAMES — SUITE_MANIFEST
   is frozen; both must remain PASS on both legs, and the probes must fail if coverage of
   the named paths is dropped from the port).
4. TEST-06: `tests/test_checkers_unit.py` — denylist matching, public-path scoping,
   cloud-safe source predicate edges.
5. Flip 3 shims + 3 manifest appends; three-leg parity; commit
   `feat(25): port privacy/neutrality checkers to python (MIG-03)`; SUMMARY.
</tasks>

<acceptance>
- Seeded-leak fixtures: each checker exits 2 with byte-identical violation output vs the
  oracle; clean tree exits 0.
- Rewritten phase-15/18 tests pass on both legs AND fail when a covered path is removed
  from the port (verified once by mutation).
- Three-leg parity 0/0/0; SUITE_MANIFEST match; freeze guard clean; pytest unit file green.
</acceptance>
