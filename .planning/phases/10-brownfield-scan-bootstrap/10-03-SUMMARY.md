---
phase: 10-brownfield-scan-bootstrap
plan: "03"
subsystem: brownfield
tags: [brownfield, bootstrap, ruamel-yaml, typed-merge, sentinel-frontmatter, d-02, d-07, d-14, byte-equality, brwn-03, brwn-04, brwn-05, brwn-06, brwn-07, brwn-21]

# Dependency graph
requires:
  - phase: 10-brownfield-scan-bootstrap/01
    provides: byte-frozen fixture roster (5 parseable + 2 unparseable) + dual golden D-07 contract + canonical field order encoded in expected/page.md
  - phase: 10-brownfield-scan-bootstrap/02
    provides: bin/brownfield.sh subcommand dispatcher + .brownfield-ignore parser + D-19 default-exclude model (reused verbatim by bootstrap walk)
  - phase: 07-neutral-template-foundation
    provides: bin/release.sh --dry-run/--apply + APPLIED.md manifest pattern (structural precedent for bootstrap --apply)
  - phase: 09-collaborative-pr-workflow-ci-lint-gate
    provides: bash→python3 env-transport heredoc pattern + stderr summary banner shape
provides:
  - bin/brownfield.sh bootstrap subcommand (D-08 dry-run default; --apply/--verbose/--root; 5 count labels; (dry-run) invite string)
  - bin/lib/brownfield_yaml.py (ruamel.yaml round-trip + D-02 typed-merge + D-14 sentinel set + DuplicateKeyError pre-scan + atomic write)
  - 12 new tests (5 parseable byte-equality + 2 unparseable skip-artifact + help/dry-run/idempotent/applied-manifest/typed-merge)
  - .brownfield/REPORT.md writer with all 4 D-04 sections (orphan raw sources folded into section (d) "Needs human judgment" per W-4 fix)
  - .brownfield/SKIPPED.md writer (D-05 parse-failure + unsafe-structure)
  - .brownfield/APPLIED.md append-only execution manifest (D-06)
  - BRWN-04 skeletons: wiki/index.md and wiki/log.md created if absent (--apply only)
  - D-15 source-file hashing: content_hash updated on existing wiki/sources/*.md summary pages; orphan raw sources logged for Phase 11
affects:
  - 10-04 (lint/ingest extensions): downstream plan needs `bootstrap_stage: bootstrapped` / `bootstrap_date` field semantics written by this plan; ingest BRWN-10 strip targets both fields
  - 10-05 (docs + §5 schema rows): docs/reference/brownfield.md needs typed-merge taxonomy + git-reset undo recipe + §"Orphan raw sources" described as falling under existing "Needs human judgment" section (not a fifth section)

# Tech tracking
tech-stack:
  added:
    - "ruamel.yaml (python runtime dep, accepted scope per STATE.md blockers — single new v1.1 dep)"
  patterns:
    - "D-02 three-class typed-merge: Class A safe-additive (preserve non-empty existing, inject if absent/empty), Class B schema-authoritative (never overwrite), Class C structural skip"
    - "ruamel.yaml CommentedMap merge — merge_sentinels() operates on and returns CommentedMap (NOT plain dict) so comment placement and key ordering survive round-trip (Codex fix #2)"
    - "Line-oriented split_frontmatter() — literal-block-scalars containing `---` on a line no longer split the block prematurely (Codex fix #1)"
    - "Distinct datetime.date instances for created_at / updated_at / bootstrap_date to avoid ruamel.yaml anchor/alias emission (&id001 / *id001) when the same Python object appears at multiple positions"
    - "Atomic write_roundtrip: tmp file in same directory + os.replace for power-loss safety"
    - "Repo-root detection walk (while ancestor exists check for .git) so --root can point at a vault subdirectory while D-15 source hashing resolves source `path:` frontmatter against the repo root (Codex fix #7)"
    - "W-2 test isolation: all bootstrap tests root at $tmp/input (never $tmp) to avoid walking the expected/ subtree and depending on D-10 idempotency as a secondary guardrail"
    - "Body leading-newline normalization: write_roundtrip ensures body starts with `\\n` so `---\\n<body>` renders as `---\\n\\n<body>` per fixture convention"

key-files:
  created:
    - bin/lib/brownfield_yaml.py
    - tests/phase-10/test_brownfield_bootstrap_help.sh
    - tests/phase-10/test_brownfield_bootstrap_dryrun.sh
    - tests/phase-10/test_brownfield_bootstrap_apply_clean.sh
    - tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh
    - tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh
    - tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh
    - tests/phase-10/test_brownfield_bootstrap_apply_comments.sh
    - tests/phase-10/test_brownfield_bootstrap_skip_tabs.sh
    - tests/phase-10/test_brownfield_bootstrap_skip_dupkeys.sh
    - tests/phase-10/test_brownfield_bootstrap_idempotent.sh
    - tests/phase-10/test_brownfield_bootstrap_applied_manifest.sh
    - tests/phase-10/test_brownfield_bootstrap_typed_merge.sh
  modified:
    - bin/brownfield.sh   # bootstrap stub replaced with full implementation; help block extended
    - tests/phase-10/test_brownfield_scan_help.sh   # Rule 3 relax: drop now-obsolete bootstrap-stub exit-2 assertion

key-decisions:
  - "EOL handling on CRLF input: LF-normalized on write (matches Plan 01's crlf expected/page.md fixture). ruamel.yaml always emits LF regardless of input EOL; no attempt to preserve CRLF. Plan 01's fixture needs no regeneration."
  - "SKIPPED.md parse-error string: library-version-dependent for tabs-in-yaml fixture (uses pyyaml ScannerError message verbatim; first non-empty line only). Test asserts structural match ('## Skipped due to parse failure' header + 'page.md' path reference) not byte-exact match of Plan 01's {PARSE_ERROR} placeholder entry. For duplicate-yaml-keys the DuplicateKeyError pre-scan emits a deterministic 'duplicate YAML key 'type' in frontmatter block' message — tested literally."
  - "Orphan raw-source entries emitted under D-04 section (d) '## Needs human judgment' (NOT a fifth '## Needs summary' section). Matches D-04 four-section structure exactly — acceptance criterion `! grep -q '## Needs summary' bin/brownfield.sh` passes."
  - "merge_sentinels() no-frontmatter case creates a fresh CommentedMap() and iterates sentinel_set.items() in insertion order — D-14 canonical field order is encoded by the sentinel_set dict's Python-3.7+ insertion-order guarantee + the order declared in build_d14_sentinel_set()."
  - "None-representer: custom ruamel.yaml representer emits literal 'null' (not bare blank) so `supersedes: null` matches fixture expected byte-for-byte."
  - "SingleQuotedScalarString('') for empty-string scaffolding fields renders as `type: ''` (matches fixture) while regular 'active' / 'tentative' strings render unquoted."
  - "Per-file idempotency (D-10) via bootstrap_stage sentinel: if fm.get('bootstrap_stage') == 'bootstrapped' the page is skipped silently (neither pending-write nor skip-artifact). Counts show in the 'Parsed:' total but contribute zero to 'Would bootstrap:'."
  - "Halt-on-first-write-failure (D-11): APPLIED.md records success-before + failure + untouched-remainder; exit 1. No auto-rollback (git is the canonical backup per D-06)."
  - "Test isolation W-2 rule: bootstrap tests root at `$tmp/input` (not `$tmp`) — avoids walking `expected/` subtree and makes test assertions independent of D-10 idempotency. Both parseable and unparseable fixtures use the same rule for test-file readability."

patterns-established:
  - "ruamel.yaml round-trip idioms for Phase-10 surface: YAML(typ='rt') + preserve_quotes=True + None-representer + SingleQuotedScalarString('') + distinct datetime.date instances. This cluster is the reference implementation for any future Python module that needs byte-stable YAML output against a fixture."
  - "make_yaml() factory in brownfield_yaml.py — centralizes the rt-mode settings so tests and bootstrap share exactly one configuration (prevents drift via separate YAML() instantiations)."
  - "D-02 typed-merge taxonomy encoded as 3 module-level constants (FIELD_CLASS_A, FIELD_CLASS_B, VALID_ENUMS) — importable by any downstream module; phase-11 suggest and lint both reuse this mapping."
  - "Duplicate-key pre-scan via regex over top-level YAML keys + DuplicateKeyError exception — catches a D-02 Class C structural failure even on ruamel versions that might silently accept duplicates in the future."
  - "Atomic file writes in the same directory via tempfile.mkstemp + os.replace — inherited from bin/release.sh allowlist staging pattern; applied to per-file writes at vault scale."

requirements-completed: [BRWN-03, BRWN-04, BRWN-05, BRWN-06, BRWN-07, BRWN-21]

# Metrics
duration: ~90min
completed: 2026-04-17
---

# Phase 10 Plan 03: bin/brownfield.sh bootstrap + typed-merge + ruamel round-trip Summary

**Ship `bin/brownfield.sh bootstrap` with dry-run-default + `--apply` opt-in, the D-02 typed-merge policy + D-14 sentinel set, ruamel.yaml round-trip preserving comments and key order, D-15 source-file hashing, and BRWN-04 index.md/log.md skeletons. `PHASE 10 TESTS: 20/20` today; all 7 Plan 01 fixtures produce their golden outputs (5 byte-equal expected/page.md + 2 unmutated input + SKIPPED.md entry).**

## Performance

- **Duration:** ~90 min
- **Started:** 2026-04-17 (approx; matches commit 120a1c7 authorship)
- **Completed:** 2026-04-17
- **Tasks:** 2 (both TDD-shaped around the fixture-byte-equality contract)
- **Files created:** 13 (1 Python module + 12 test scripts)
- **Files modified:** 2 (bin/brownfield.sh + tests/phase-10/test_brownfield_scan_help.sh Rule 3 relax)

## Accomplishments

- **`bin/lib/brownfield_yaml.py`** — 12 exported names: 3 constants (`FIELD_CLASS_A`, `FIELD_CLASS_B`, `VALID_ENUMS`), 1 exception (`DuplicateKeyError`), 8 functions (`split_frontmatter`, `read_fm_body`, `merge_sentinels`, `write_roundtrip`, `build_d14_sentinel_set`, `infer_id_from_filename`, `extract_h1`, `file_mtime_iso`, `make_yaml`). Each function docstring states its D-clause anchor + the invariant it upholds. The module is importable without dragging in any bin/brownfield.sh env state.
- **`bin/brownfield.sh bootstrap` branch** — 400+ LOC Python heredoc with the full walk → parse → classify → merge → write pipeline. Honors the D-19 default-exclude denylist (`.obsidian`, `.trash`, `templates`, `attachments`, `.brownfield`, `.git`) + daily-note patterns + user `.brownfield-ignore` (shared gitignore-subset parser mirroring scan). Emits all 5 stderr count labels (`Parsed:`, `Would bootstrap:`, `Collisions:`, `Schema warnings:`, `Skipped:`) on both dry-run and apply paths.
- **D-02 typed-merge encoded mechanically** — Class A safe-additive preserves non-empty existing values (`tags: [manual]` stays); Class B schema-authoritative NEVER overwrites (`type: concept` + `privacy: cloud_safe` survive the sentinel's `type: ''` + `privacy: local_only`); Class C routes to `.brownfield/SKIPPED.md` with a terse pre-scan message.
- **D-14 sentinel set matches Plan 01 fixture byte-for-byte** — ruamel.yaml serialization verified against all 5 parseable `expected/page.md` files. Key decisions captured in the fixture preamble: `null` (not `~`), single-quoted empty strings (`''`), `[]` for empty lists, unquoted dates via `datetime.date`, lowercase booleans, distinct date instances to avoid anchor pairs.
- **D-15 source-file hashing** — walks existing `wiki/sources/*.md` summary pages under ROOT; resolves the `path:` frontmatter field against the **repo root** (not `--root` — Codex fix #7) so bootstrap can be pointed at a subdirectory without mutating source summaries elsewhere. Orphan raw sources (files under `sources/` with no corresponding summary) are logged under D-04 section (d) "Needs human judgment" as a prose open-question (Phase 11 `suggest/01-page-typing.sh` handoff).
- **BRWN-04 skeletons** — `wiki/index.md` and `wiki/log.md` are created with a one-paragraph "Populated by wiki workflows per AGENTS.md §12" / "Newest entries appended at bottom per AGENTS.md §12" stub if absent. Only runs on `--apply`, inside `<root>/wiki/`.
- **12 new tests** — 5 parseable-fixture byte-equality + 2 unparseable-fixture skip-artifact + help + dry-run shape + multi-file idempotency + APPLIED.md append + typed-merge unit test. Each test is single-purpose, emits `PASS: <name>`, and uses `make_fixture_repo` for isolation.
- **`PHASE 10 TESTS: 20/20`** — 2 Plan 01 self-checks + 6 Plan 02 scan tests + 12 new Plan 03 tests, all green.

## Task Commits

Each task was committed atomically:

1. **Task 1 — Implement bin/lib/brownfield_yaml.py + bootstrap branch** — `120a1c7` (feat)
2. **Task 2 — Author 12 bootstrap tests + Rule 3 relax Plan 02 scan-help bootstrap stub check** — `d07d064` (test)

## Files Created/Modified

### Created (13 files)

**Code (1):**
- `bin/lib/brownfield_yaml.py` — 460 LOC; the ruamel round-trip + D-02 typed-merge + D-14 sentinel set helper module. Exports 3 constants, 1 exception, 8 functions. Single `make_yaml()` factory ensures consistent rendering settings across tests, bootstrap, and any future caller.

**Tests (12):**
- `tests/phase-10/test_brownfield_bootstrap_help.sh` — all 4 flags advertised.
- `tests/phase-10/test_brownfield_bootstrap_dryrun.sh` — 5 count labels + trailing invite string + REPORT.md written + APPLIED.md absent + input/expected unchanged (W-2).
- `tests/phase-10/test_brownfield_bootstrap_apply_clean.sh` — clean-frontmatter byte-equality + body preservation + idempotency + W-2.
- `tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh` — no-frontmatter full D-14 injection + post-frontmatter body byte-equal to original input + idempotency + W-2.
- `tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh` — CRLF normalization to LF + no CR bytes in output + idempotency + W-2.
- `tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh` — Dataview inline fields (`domain::`, `author::`) preserved verbatim in body + idempotency + W-2.
- `tests/phase-10/test_brownfield_bootstrap_apply_comments.sh` — YAML round-trip preserves both comments (`# Set by user 2025-12-01`, `# Last reviewed: 2025-12-15`) + idempotency + W-2.
- `tests/phase-10/test_brownfield_bootstrap_skip_tabs.sh` — input unchanged + SKIPPED.md header + path reference.
- `tests/phase-10/test_brownfield_bootstrap_skip_dupkeys.sh` — same + literal `duplicate YAML key 'type'` message from the pre-scan.
- `tests/phase-10/test_brownfield_bootstrap_idempotent.sh` — multi-file vault (clean + no-fm) recursive SHA-256 set-equality after 2 runs.
- `tests/phase-10/test_brownfield_bootstrap_applied_manifest.sh` — 2 `--apply` runs → 2 `## Run ` headers (with `sleep 1` to distinguish UTC timestamps).
- `tests/phase-10/test_brownfield_bootstrap_typed_merge.sh` — custom vault; Class B preserved, Class A collision recorded in REPORT.md, no schema warning for canonical `type: concept`.

### Modified (2 files)

- `bin/brownfield.sh` — replaced the `SUBCOMMAND == "bootstrap"` stub (exits 2 with "Plan 10-03 populates" message) with the full bootstrap branch. Usage block extended with 5 new flag-documentation lines under a dedicated `bootstrap options:` heading. Module-header comment updated to list BRWN-01..07/16/21 instead of just BRWN-01/02/16.
- `tests/phase-10/test_brownfield_scan_help.sh` — Rule 3 relax: dropped the now-obsolete assertion that bootstrap exits 2 with "Plan 10-03 populates". Bootstrap-specific exit behaviour is now covered by the 12-test bootstrap suite. Pattern precedent: Phase 08-04 relaxing phase-07 `test_docs_skeleton.sh` (see STATE.md).

## Decisions Made

### EOL handling for CRLF fixture (LF-normalize-on-write per D-03)

ruamel.yaml always emits LF regardless of the input file's EOL shape. For the `crlf` fixture, the input has literal `\r\n` bytes (preserved via `.gitattributes -text`) but the expected output is LF-only. Bootstrap LF-normalizes on write — this is the documented ruamel.yaml round-trip behaviour and matches Plan 01's expected fixture. **Plan 01's `crlf/expected/page.md` needs no regeneration.**

### SKIPPED.md parse-error string handling (placeholder vs pinned)

Per Plan 01's handoff, the `tabs-in-yaml/expected-skipped-entry.md` uses a `{PARSE_ERROR}` placeholder because the actual ruamel.yaml / pyyaml error string is version-dependent. Plan 03's test does **not** assert byte-exact match against that placeholder file — it asserts structural match:

- `## Skipped due to parse failure` header present
- `page.md` path reference present

For `duplicate-yaml-keys`, the custom `DuplicateKeyError` pre-scan emits a version-independent message (`duplicate YAML key 'type' in frontmatter block`) so that test asserts the literal string. The expected-skipped-entry file's `parse_error: duplicate YAML key 'type' in frontmatter block` line now matches byte-for-byte should anyone want to tighten the test to `assert_byte_equal`.

### Orphan raw-source entries → D-04 section (d) "Needs human judgment" (W-4 fix)

D-04 mandates exactly four REPORT.md sections. Initial bootstrap drafts tempted a fifth `## Needs summary` section but W-4 fix explicitly forbids this — orphan raw sources are a form of unclassifiable-needs-user-judgment and belong in the existing (d) section. The prose tone mirrors D-18 scan's "unknown" framing — question-framed, never overconfident, with an explicit Phase 11 handoff:

```
- `sources/2026/2026-04/<file>.md` — raw source has no corresponding `wiki/sources/*.md` summary page.
  Should a source summary be created (handoff to Phase 11 `suggest/01-page-typing.sh`)?
```

Acceptance criterion `! grep -q '## Needs summary' bin/brownfield.sh` passes.

### ruamel.yaml anchor/alias emission — distinct date instances

ruamel emits YAML anchors (`&id001` / `*id001`) when the same Python object appears at multiple positions in a mapping. Building the D-14 sentinel with `'created_at': today, 'updated_at': today, 'bootstrap_date': today` (same `datetime.date` instance three times) produced output like:

```yaml
created_at: 2026-04-17
updated_at: &id001 2026-04-17
...
bootstrap_date: *id001
```

**Fix:** `build_d14_sentinel_set()` creates three distinct `datetime.date(today.year, today.month, today.day)` instances for `updated_at` and `bootstrap_date`. This is a subtle but load-bearing change for byte-equality against the fixtures.

### Body leading-newline normalization in write_roundtrip

The fixture convention is `---\n<yaml>\n---\n\n<body>` — one blank line between closing delimiter and content. For existing-frontmatter pages `split_frontmatter` returns a body already prefixed with `\n` (from the input's own blank line). For **no-frontmatter** pages the body is the raw input starting with `# H1`. Without normalization, output would run `---\n# H1` together.

`write_roundtrip` now ensures the body starts with `\n` before concatenation — a no-op for the existing-frontmatter path, a necessary prepend for the no-frontmatter path. Documented inline with the rationale.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Plan 10-02 `test_brownfield_scan_help.sh` asserted bootstrap stub exit-2**

- **Found during:** First run of `bash tests/phase-10/run.sh` after Task 1 commit.
- **Issue:** Plan 10-02 Task 2 Test 1 asserts `bootstrap` exits 2 with "Plan 10-03 populates". Plan 10-03 **replaces** that stub with the full implementation — the assertion is structurally obsolete.
- **Fix:** Dropped the bootstrap stub assertion from `test_brownfield_scan_help.sh`. Left a comment noting the Phase 08-04 precedent for relaxing prior-phase tests when a successor plan populates the stub. Bootstrap-specific exit behaviour is covered by the 12 new bootstrap tests.
- **Files modified:** `tests/phase-10/test_brownfield_scan_help.sh`
- **Verification:** `PHASE 10 TESTS: 19/20` → `20/20` after the relax.
- **Committed in:** `d07d064` (bundled into Task 2 commit — the relax is a direct consequence of the 12 new tests that replace its coverage)

**2. [Rule 1 — Bug] `test_brownfield_bootstrap_typed_merge.sh` `grep -qF "- manual"` tripped grep's leading-hyphen flag parsing**

- **Found during:** First full test run after Task 2 commit (19/20; typed-merge the only red).
- **Issue:** `grep -qF "- manual" file` interprets `- manual` as a flag because the string starts with `-`. Exit 2 (usage error) on every invocation.
- **Fix:** Added `--` to all such greps: `grep -qF -- "- manual" file`. This is the POSIX-endorsed way to signal "end of flags, pattern follows".
- **Files modified:** `tests/phase-10/test_brownfield_bootstrap_typed_merge.sh`
- **Verification:** Single-file re-run PASS; full suite 20/20.
- **Committed in:** `d07d064` (same commit as Task 2 authoring — bug discovered and fixed inside the commit window before the commit landed, per the test-authoring feedback loop)

---

**Total deviations:** 2 auto-fixed (1 Rule 3 blocking — prev-phase test obsoleted by populate; 1 Rule 1 bug — grep flag-parsing).

## Issues Encountered

- **ruamel.yaml anchor emission.** Building the sentinel with one shared `today` date produced unexpected YAML anchors. Took ~10 minutes to isolate by comparing fixture diffs line-by-line. Resolution documented in Decisions above and encoded as distinct-instance construction in `build_d14_sentinel_set()`.
- **Body leading-newline mismatch for no-frontmatter.** First pass of `write_roundtrip` concatenated `---\n` with the raw body directly, producing `---\n# My Page` instead of `---\n\n# My Page`. Caught by the no-frontmatter fixture byte-equality test on first run. Fixed by normalizing the body to always start with `\n`.
- **`type: entity` fixture has `id: page` in expected/page.md.** The `dataview-inline` fixture's input has `type: entity` + no `id:`, so bootstrap infers `id: page` from the filename (`page.md` → `page`). The expected fixture encodes `id: page` — my first glance thought this looked wrong (the H1 is `Vaswani`), but it's consistent with D-14's rule: `id` is derived from filename, `title` is derived from H1.
- **pycache generated on first import.** `bin/lib/__pycache__/brownfield_yaml.cpython-312.pyc` appeared after the first Python run. Already gitignored by Plan 02's `86cd382` commit; no new action required.

## User Setup Required

**`pip install ruamel.yaml`** — bootstrap exits 1 with an actionable stderr message if the import fails:

```
ERROR: ruamel.yaml is required for brownfield bootstrap. Install: pip install ruamel.yaml (see docs/reference/brownfield.md).
```

This dep is documented in Plan 05's `docs/quickstart.md` prerequisite note + `docs/reference/brownfield.md` Setup section; users who don't intend to run brownfield onboarding don't need ruamel installed.

In the Plan 10-03 execution environment the package was unavailable via `pip` (system Python), so ruamel.yaml was extracted from the Ubuntu `python3-ruamel.yaml` + `python3-ruamel.yaml.clib` `.deb` packages and installed to `~/.local/lib/python3/dist-packages`. `PYTHONPATH="$HOME/.local/lib/python3/dist-packages" bash tests/phase-10/run.sh` is the test-invocation used during development — on a system with a normal `pip install ruamel.yaml` the PYTHONPATH prefix is unnecessary.

## Handoff Notes

### To Plan 10-04 (lint/ingest extensions)

- **Sentinel field names + values written by this plan:** `bootstrap_stage: bootstrapped` + `bootstrap_date: YYYY-MM-DD` (both as unquoted YAML scalars — date as unquoted `datetime.date`, stage as bare `bootstrapped`). Plan 04's `bin/lint.sh` BRWN-08 downgrade auto-detect can grep for either field; the strip pattern in `bin/ingest.sh` (BRWN-10) must match **both** fields together (they always appear as a pair).
- **bootstrap_stage enum:** `raw | bootstrapped | verified`. Plan 03 only writes `bootstrapped`; `raw` is a user / external-tool signal; `verified` is reserved for Plan 11 `verify` subcommand.
- **BRWN-08 downgrade scope:** error→info on the allowlist when `bootstrap_stage: bootstrapped`. The allowlist lives in the Phase 9 severity-remap dispatcher (see `bin/lint.sh`); Plan 04 adds a modifier rather than inventing a new mechanism.
- **`brownfield` category in lint:** Plan 04 adds a new `brownfield` category for BRWN-09 (30-day staleness from `bootstrap_date`). Severity: warning. Reads `bootstrap_date` deterministically; compares to `--today` / current UTC date.
- **Parse-guard sharing:** Plan 04's lint can reuse `bin/lib/brownfield_yaml.py::read_fm_body` OR stay PyYAML-only (sufficient for read-side). Either is fine — lint doesn't write, so the round-trip cost is not required.

### To Plan 10-05 (docs + §5 schema rows)

- **docs/reference/brownfield.md § Typed-merge policy:** quote verbatim from the plan: *"Brownfield bootstrap preserves existing parseable frontmatter values, injects only absent required sentinel fields, and logs any collisions or noncanonical existing values for later review. It skips only files whose frontmatter cannot be parsed safely or whose structure makes mechanical injection unsafe."*
- **docs/reference/brownfield.md § Decision boundary:** also verbatim from the plan: *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."* Both strings appear in `bin/brownfield.sh --help` already (Plan 02 precedent).
- **docs/reference/brownfield.md § Class A/B/C taxonomy:** mirrors this plan's Decisions section. Three classes, with one-paragraph explanations each + a bullet list of which fields belong to which class (imported from `bin/lib/brownfield_yaml.py::FIELD_CLASS_A` / `FIELD_CLASS_B`).
- **docs/reference/brownfield.md § Git-reset undo recipe (D-06):** canonical undo is `git reset --hard <pre-bootstrap-sha>`. APPLIED.md records every touched file so the user can inspect the blast radius before resetting.
- **docs/reference/brownfield.md §"Orphan raw sources":** describe as appearing under the existing "Needs human judgment" section (the 4-section D-04 structure), NOT as a separate section header. Match the same four-section structure that scan uses.
- **AGENTS.md §5 rows for `bootstrap_stage` + `bootstrap_date`:** Plan 05 adds them per D-20. Description wording should call out "Brownfield onboarding sentinel", the enum `raw | bootstrapped | verified`, the explicit contrast "NOT a substitute for claim-level provenance (see §6 PROV-01..05)", and the BRWN-10 strip note.

### To Phase 11 (suggest/verify)

- **`bin/lib/brownfield_yaml.py` re-use:** Phase 11 `suggest/01-page-typing.sh` can import `read_fm_body` + `write_roundtrip` + `merge_sentinels` + `FIELD_CLASS_A` / `FIELD_CLASS_B` / `VALID_ENUMS`. The merge helper is Phase-10-scoped (only mutates D-14 sentinel fields); Phase 11 typing mutations need their own merge shape but the read/write primitives are reusable as-is.
- **`bootstrap_stage: verified` usage:** Plan 11's `verify` subcommand flips `bootstrapped` → `verified` after a successful lint pass. The `VALID_ENUMS['bootstrap_stage']` set already includes `verified` so Plan 11 can re-import this module unchanged.
- **Orphan raw-source handoff:** `.brownfield/REPORT.md` section (d) "Needs human judgment" lists orphan raw sources with an explicit Phase 11 handoff question. Phase 11 `01-page-typing.sh` reads this section and proposes summary-page scaffolds.

## Next Phase Readiness

- **Plan 10-03 complete.** All truths in the plan frontmatter hold: dry-run default, `--apply` opt-in, typed-merge preservation, ruamel round-trip with comments + key order, body preservation, SKIPPED.md for unparseable, sentinel-check idempotency, APPLIED.md append-only, skeletons created, source-file hashing, orphan-source logging under "Needs human judgment", 9 tests green (12 authored; acceptance criterion of "9 new tests green" over-met).
- **Requirements satisfied:** BRWN-03 (idempotency), BRWN-04 (mechanical-only transforms + skeletons), BRWN-05 (body preserved), BRWN-06 (ruamel round-trip preserves comments), BRWN-07 (bootstrap_stage sentinel), BRWN-21 (byte-exact fixture suite).
- **No blockers** for Plan 10-04 (lint/ingest extensions) or Plan 10-05 (docs + §5 schema rows). Plan 10-04 can be rebased against `d07d064` for the final sentinel-field semantic; Plan 10-05 can reference the typed-merge taxonomy, decision-boundary one-liner, and git-reset undo recipe documented above.
- **`PHASE 10 TESTS: 20/20`** — 2 Plan 01 self-checks + 6 Plan 02 scan tests + 12 new Plan 03 bootstrap tests, all green.

## Self-Check: PASSED

Verified post-SUMMARY that all claimed files exist and all claimed commits are in git history:

- `bin/lib/brownfield_yaml.py`: FOUND
- `bin/brownfield.sh` (bootstrap branch populated): FOUND
- All 12 new test files in `tests/phase-10/test_brownfield_bootstrap_*.sh`: FOUND
- `tests/phase-10/test_brownfield_scan_help.sh` (Rule 3 relaxed): FOUND
- Commit `120a1c7` (feat 10-03 Task 1): FOUND
- Commit `d07d064` (test 10-03 Task 2 + scan-help relax): FOUND
- `PHASE 10 TESTS: 20/20`: CONFIRMED
- Acceptance check `! grep -q 'Plan 10-03 populates' bin/brownfield.sh`: PASS
- Acceptance check `grep -q 'brownfield_yaml' bin/brownfield.sh`: PASS
- Acceptance check `! grep -q '## Needs summary' bin/brownfield.sh`: PASS
- No network calls in bootstrap code path: `grep -rE 'curl|wget|anthropic|openai|requests|urllib' bin/brownfield.sh bin/lib/*.py` returns no non-comment matches (BRWN-16 + T-10-03-04 mitigation).

---
*Phase: 10-brownfield-scan-bootstrap*
*Completed: 2026-04-17*
