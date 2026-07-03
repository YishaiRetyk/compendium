# 25-02 SUMMARY — checkers port (MIG-03)

**Status:** Complete (2026-07-04)

## What shipped

- `src/compendium/check_neutrality.py`, `check_privacy.py`, `check_sources_cloud_safe.py`:
  heredoc bodies verbatim (my sampling: 282/282 + 39/39 + 54/54 non-comment lines
  byte-identical modulo the sanctioned import transforms); bash arg loops replicated
  exactly; STOPWORDS / SELF_REFERENTIAL_EXEMPT / SANCTIONED_PATH_RE / PATH_NAME_EXEMPT
  byte-identical.
- 3 shims flipped + 3 `ported.manifest` appends (check-neutrality, check-privacy,
  check-sources-cloud-safe).
- The two MANDATED impl-assertion rewrites (inventory rows now `done`):
  - `tests/phase-15/test_neutrality_leak_source_rekey.sh` — static cases (i)–(iii)
    re-pointed at the Python module (the post-port source of truth); behavioral case
    (iv) kept verbatim. Mutation-verified.
  - `tests/phase-18/test_neutrality_covers_skills.sh` — source-grep replaced by a
    behavior probe (denylisted term planted in a fixture `.claude/skills/`); D-10
    coverage now asserted by effect. Mutation-verified (dropping `.claude/skills` from
    PUBLIC_PATHS flips it red).
- TEST-06: `tests/test_checkers_unit.py` (13 tests).
- Port-agent self-verification: 35/35 four-channel cases + live-repo runs of all three
  gates (exit 0 — same verdicts as bash on the real repo).

## Notes / deviations

- **Exit-code doc imprecision found:** `check-sources-cloud-safe` exits **1** on
  violation (its own header contract), not the "2 on violation" the shim-contract §4
  table generalizes for "checkers". Behavior preserved (parity bar); the table
  overgeneralization is flagged for the CUT-01 reference census.
- Verbatim-extraction exceptions (all unreachable/untestable corners): `--root` with
  no value dies via bash `set -u` vs Python IndexError (exit 1 both; stderr text
  differs, no suite coverage); the CSG lib-dir fallback chain is replaced by the
  `compendium.common.yaml_rt` import with the same error message kept for fidelity;
  `${PWD}` → `os.getcwd()`.
- The impl-assertion inventory was committed via an index-split: this commit carries
  ONLY the two MIG-03 rows; the three MIG-02 rows (already rewritten in the working
  tree by the 25-06 draft) ride with 25-06 so every committed row is true at its
  commit's tree state.
- `tests/phase-18/lib.sh` deliberately does not provide fixture helpers; the rewritten
  covers-skills test carries verbatim local copies (phase18- mktemp prefix) instead of
  widening the lib (agent finding, kept).
