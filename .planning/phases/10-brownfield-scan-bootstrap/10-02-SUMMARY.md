---
phase: 10-brownfield-scan-bootstrap
plan: "02"
subsystem: brownfield
tags: [brownfield, scan, classifier, rule-based, gitignore-subset, fnmatch, d-16, d-17, d-18, d-19]

# Dependency graph
requires:
  - phase: 10-brownfield-scan-bootstrap/01
    provides: tests/phase-10/ harness (run.sh + lib.sh) + scan-vault-basic fixture helper pattern
  - phase: 07-neutral-template-foundation
    provides: bin/check-neutrality.sh hardcoded-array + env-transport convention (PUBLIC_PATHS twin)
  - phase: 09-collaborative-pr-workflow-ci-lint-gate
    provides: bin/lint.sh bash→python3 heredoc pattern + stderr summary banner shape
provides:
  - bin/brownfield.sh subcommand dispatcher (scan live; bootstrap stub; suggest/verify exit 2)
  - bin/lib/brownfield_classify.py D-16 4-signal classifier (reusable by Phase 11 01-page-typing.sh)
  - .brownfield-ignore parser (gitignore-like subset, fnmatch-based; no new runtime deps)
  - .brownfield/REPORT.md writer with D-04 Inventory + Excluded + Needs human judgment sections
  - tests/phase-10/fixtures/scan-vault-basic/ roster + .brownfield-ignore negation exemplar
  - 6 new tests (help, report, exclusions, confidence, unknown, ignore-parser) — total PHASE 10 TESTS: 8/8
affects:
  - 10-03 (bootstrap): inherits working subcommand dispatcher; only needs to fill the `bootstrap)` branch
  - 10-03 (bootstrap): may re-import bin/lib/brownfield_classify.py to label .brownfield/REPORT.md section (d)
  - 11 (suggest + 01-page-typing.sh): re-imports bin/lib/brownfield_classify.py with inbound_count passed

# Tech tracking
tech-stack:
  added: []  # PyYAML already in baseline; ruamel.yaml still arrives in Plan 10-03 only
  patterns:
    - "Subcommand dispatch pattern (first in the codebase): `case \"$SUBCOMMAND\" in scan|bootstrap) ;; suggest|verify) exit 2 ;; *) exit 1 ;; esac`"
    - "Hardcoded bash array + colon-join env-transport (BROWNFIELD_DEFAULT_EXCLUDES → BROWNFIELD_DEFAULT_EXCLUDES_JOINED) — PUBLIC_PATHS twin"
    - "Inline fnmatch-based glob matcher for .brownfield-ignore (gitignore-like subset) — zero new runtime deps beyond the stdlib"
    - "Extracted classifier module bin/lib/brownfield_classify.py with `inbound_count` parameter reserved for Phase 11 reuse without module modification"
    - "os.walk(followlinks=False) default preserves T-10-02-06 symlink-containment"

key-files:
  created:
    - bin/brownfield.sh
    - bin/lib/brownfield_classify.py
    - tests/phase-10/test_brownfield_scan_help.sh
    - tests/phase-10/test_brownfield_scan_report.sh
    - tests/phase-10/test_brownfield_scan_exclusions.sh
    - tests/phase-10/test_brownfield_scan_confidence.sh
    - tests/phase-10/test_brownfield_scan_unknown.sh
    - tests/phase-10/test_brownfield_ignore_parser.sh
    - tests/phase-10/fixtures/scan-vault-basic/README.md
    - tests/phase-10/fixtures/scan-vault-basic/wiki/entities/SomeEntity.md
    - tests/phase-10/fixtures/scan-vault-basic/wiki/concepts/some-concept.md
    - tests/phase-10/fixtures/scan-vault-basic/wiki/sources/src-2026-04-01-paper.md
    - tests/phase-10/fixtures/scan-vault-basic/vault/musings.md
    - tests/phase-10/fixtures/scan-vault-basic/.obsidian/workspace.json
    - tests/phase-10/fixtures/scan-vault-basic/attachments/diagram.md
    - tests/phase-10/fixtures/scan-vault-basic/.brownfield-ignore
  modified:
    - .gitignore  # +4 lines: Python bytecode cache (__pycache__/ + *.pyc)

key-decisions:
  - "Inline fnmatch-based glob matcher chosen over pathspec import. A ~40-line inline translator (.brownfield-ignore-subset → regex) keeps the `zero new runtime deps except ruamel.yaml` invariant intact."
  - "Gitignore grammar DELIBERATELY narrowed to the subset called out in truths: supports blank/`#`/`!`/`*`/`**`; explicitly does NOT support trailing-slash directory-only, `\\` escapes, character classes. This scope is documented in the truths block and locked by test_brownfield_ignore_parser.sh."
  - "`classify_page()` signature accepts but ignores `inbound_count` in Phase 10. This lets Phase 11 01-page-typing.sh pass it (full-vault two-pass walk context) without modifying the module signature — the API contract survives the Phase 10→11 handoff unchanged (Codex BLOCKER 1 fix)."
  - "README.md at fixture root is filtered out by `make_fixture_repo` (find ! -name README.md). This means the scan tests never see fixture documentation in their Inventory — exactly the separation the Plan-01 helper established."
  - "Negation-first precedence: when a path hits both a built-in exclude (e.g., attachments) AND a `.brownfield-ignore` negation (`!attachments`), negation wins. This makes user overrides strictly additive-or-subtractive relative to the defaults, matching gitignore semantics."

patterns-established:
  - "Subcommand dispatcher (bin/brownfield.sh): first codebase instance of positional-first dispatch. Phase 11 suggest/verify and any future multi-verb script should follow this shape."
  - "Reusable classifier modules under bin/lib/: bin/lib/brownfield_classify.py is the first Python module in bin/lib/. Phase 11 01-page-typing.sh will import it; if more phase-spanning logic emerges, bin/lib/ is the home."
  - "Decision-boundary epigraph in --help: copies the CONTEXT.md §Specifics verbatim string `Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema.` directly into the usage block for at-a-glance scope framing."
  - "Fixture .brownfield-ignore files as test artifacts: the scan-vault-basic fixture carries its own `.brownfield-ignore` (`!attachments`) so the negation test is a first-class fixture contract rather than a runtime mutation inside a test."

requirements-completed: [BRWN-01, BRWN-02, BRWN-16]

# Metrics
duration: ~15min
completed: 2026-04-17
---

# Phase 10 Plan 02: bin/brownfield.sh scan + D-16 classifier Summary

**Ship the subcommand dispatcher for `bin/brownfield.sh`, the `scan` dry-run walk with rule-based classification (D-16) + `.brownfield-ignore` parser (D-19), and 6 tests locking the D-16/D-17/D-18/D-19 contracts mechanically. `PHASE 10 TESTS: 8/8` today; Plan 03 inherits a working dispatcher and only needs to fill the `bootstrap)` branch.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-17T08:55:00Z (approximately; matches `aaa6c38` authorship)
- **Completed:** 2026-04-17T09:10:00Z
- **Tasks:** 2 (+1 .gitignore auto-fix commit)
- **Files created:** 16
- **Files modified:** 1 (.gitignore)

## Accomplishments

- **Subcommand dispatcher** (`bin/brownfield.sh`) with 4 verbs: `scan` (live), `bootstrap` (stub exits 2 pointing at Plan 10-03), `suggest` / `verify` (exit 2 with `see Phase 11 (BRWN-11..20)` message). `--help` prints the full usage block including the D-03 decision-boundary epigraph verbatim.
- **Scan implementation** with the D-19 built-in denylist (`.obsidian`, `.trash`, `templates`, `attachments`, `.brownfield`, `.git`) + daily-note regex (`YYYY-MM-DD.md` at root or under `daily/`/`journal/`) + optional `.brownfield-ignore` user override.
- **D-04 REPORT.md writer** producing three-section output: `## Inventory` (path | label | confidence | signals table), `## Excluded` (per-rule counts; optional full list under `--list-excluded`), `## Needs human judgment` (D-18 question-framed prose per `unknown` page).
- **Extracted classifier** at `bin/lib/brownfield_classify.py` implementing the D-16 4-signal rule set (frontmatter type, filename convention, section-heading structure, outbound-wikilink density) with the D-17 confidence mapping. `classify_page()` accepts but ignores `inbound_count`, reserving the parameter for Phase 11's whole-vault inbound-graph walk.
- **`.brownfield-ignore` parser** — inline fnmatch-based gitignore-like subset (~40 LOC). Supports blank lines, `#` comments, `!` negation, `*`, `**`. Zero new runtime deps; the `pathspec` Python module was explicitly rejected to preserve the `zero new runtime deps except ruamel.yaml` invariant.
- **6 new tests** — help/report/exclusions/confidence/unknown/ignore — each asserting one D-16/D-17/D-18/D-19 contract with PASS/FAIL output and focused grep/awk assertions.
- **Scan-vault-basic fixture** — 6 vault files + `.obsidian/workspace.json` + `attachments/diagram.md` + fixture-root `.brownfield-ignore` carrying the `!attachments` negation exemplar.
- **`PHASE 10 TESTS: 8/8`** — 2 Plan-01 self-checks + 6 new scan tests, all green.

## Task Commits

1. **Task 1: Implement dispatcher + classifier + fixture** — `aaa6c38` (feat)
2. **Task 2: Author 6 scan tests** — `709ad1c` (test)
3. **Rule 2 auto-fix: gitignore Python bytecode cache** — `86cd382` (chore)

## Files Created/Modified

### Created (16 files)

**Code (2):**
- `bin/brownfield.sh` — subcommand dispatcher + `scan` implementation. 257 lines. Uses hardcoded-array env-transport for the default denylist and a Python heredoc for the walk + report writer.
- `bin/lib/brownfield_classify.py` — D-16 classifier. 150 lines. Single `classify_page()` entry point returns (label, confidence, signal_trace); companion `unknown_reason()` emits the D-18 prose open-question.

**Tests (6):**
- `tests/phase-10/test_brownfield_scan_help.sh` — --help has scan+bootstrap+decision-boundary; suggest/verify/bootstrap exit 2 with correct messages; unknown subcommand exits 1.
- `tests/phase-10/test_brownfield_scan_report.sh` — REPORT.md has all 3 sections; `wiki/entities/SomeEntity.md` in Inventory; `.obsidian/workspace.json` NOT in Inventory; SHA-256 before/after snapshot proves no vault mutation (T-10-02-01).
- `tests/phase-10/test_brownfield_scan_exclusions.sh` — without `.brownfield-ignore`, `attachments/diagram.md` is kept out of Inventory via the built-in denylist.
- `tests/phase-10/test_brownfield_scan_confidence.sh` — D-17 labels: SomeEntity `entity high`; some-concept `concept high`; src-2026-04-01-paper `source high`; musings `unknown unknown`.
- `tests/phase-10/test_brownfield_scan_unknown.sh` — D-18 `Needs human judgment` line for `vault/musings.md` ends with `?` (question-framed; no pre-filled type suggestion).
- `tests/phase-10/test_brownfield_ignore_parser.sh` — WITH `!attachments` negation, `attachments/diagram.md` appears in Inventory; WITHOUT, it returns to Excluded.

**Fixture (8):**
- `tests/phase-10/fixtures/scan-vault-basic/README.md` — documents the page roster and expected classification.
- `tests/phase-10/fixtures/scan-vault-basic/wiki/entities/SomeEntity.md` — `type: entity` frontmatter + single outbound wikilink.
- `tests/phase-10/fixtures/scan-vault-basic/wiki/concepts/some-concept.md` — `type: concept` + TL;DR/Key Facts/Detail section set + 5 outbound wikilinks.
- `tests/phase-10/fixtures/scan-vault-basic/wiki/sources/src-2026-04-01-paper.md` — `type: source` + Extracted Claims + Source Metadata section signature.
- `tests/phase-10/fixtures/scan-vault-basic/vault/musings.md` — no frontmatter, no structure; deliberate `unknown` case.
- `tests/phase-10/fixtures/scan-vault-basic/.obsidian/workspace.json` — built-in exclude exemplar.
- `tests/phase-10/fixtures/scan-vault-basic/attachments/diagram.md` — negation target for `.brownfield-ignore` testing.
- `tests/phase-10/fixtures/scan-vault-basic/.brownfield-ignore` — user-override file carrying `!attachments` negation.

### Modified (1 file)

- `.gitignore` — added 4 lines: `__pycache__/` + `*.pyc` with a comment noting the bin/lib/*.py modules generate this cache on import.

## Decisions Made

### Gitignore-grammar parser: inline vs pathspec

The planner offered three options: (a) full gitignore grammar via the `pathspec` PyPI module (adds a runtime dep), (b) narrowed subset with an inline fnmatch-based matcher, (c) full gitignore grammar via a hand-rolled parser. I chose (b) — inline fnmatch-based — because:

- **CONTEXT.md §Established Patterns invariant:** "Zero new runtime deps except ruamel.yaml." Adding `pathspec` would break this.
- **Truths-block scope:** The plan's truths explicitly narrow the grammar to `gitignore-like subset: glob patterns with *, **, ! negation; no directory-only trailing-slash or other advanced gitignore features`. A 40-line inline translator is sufficient.
- **Testability:** The inline implementation is in-repo and lint-linkable (no mystery external behavior); the negation contract is locked by `test_brownfield_ignore_parser.sh`.

The inline matcher compiles each pattern to a regex: `*` → `[^/]*`, `**` → `.*`, literal characters → `re.escape(c)`, and anchors `^...(?:/.*)?$` so `attachments` matches both `attachments` and `attachments/diagram.md`.

### Phase 10 signal 4 scope (Codex review fix #3)

Per the plan's explicit guidance, Phase 10 implements outbound-wikilink density only. Inbound-count computation requires a whole-vault two-pass walk (build a target→source map, then look up each page's inbound count) which is not part of the scan code path. The classifier's `inbound_count` parameter is accepted with a default of `None` and ignored in the signal-4 branch; Phase 11 `01-page-typing.sh` will populate it. This contract is locked by the plan's acceptance-criterion "`classify_page()` signature includes the optional `inbound_count` parameter" and tested by the `inspect.signature` check.

### Negation-first precedence

Walking the directory tree, when a directory name matches a default exclude (`attachments`) AND a user negation (`!attachments`) exists, the negation wins — the directory is kept in the walk. Symmetrically for file-level excludes. This matches gitignore semantics (later patterns override earlier; negation un-excludes) and is the intuitive mental model for users: "I want the defaults except for these specific paths."

### README.md fixture-root filtering

The `make_fixture_repo` helper from Plan 01 `find . -type f ! -name README.md` explicitly excludes per-fixture README files from the temp repo copy. This means running `scan` against the fixture never sees the fixture's own documentation — important because otherwise `scan-vault-basic/README.md` would show up in the Inventory table as noise. The implication for my fixture: I can freely document the fixture's roster and expected classifications in `README.md` without polluting test output.

### Footer timestamp in REPORT.md

Scan's `REPORT.md` ends with a trailing `*Generated by bin/brownfield.sh scan at <ISO-8601>*` line. This is a human-review aid — the report's generation time is captured in-file rather than requiring the user to cross-check file mtimes — and costs nothing in terms of test stability because tests grep for section headers and row content, never for the footer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing critical functionality] `__pycache__/` not in `.gitignore`**
- **Found during:** Post-Task-1 git-status check (after running the classifier import smoke test which generates `bin/lib/__pycache__/`).
- **Issue:** `bin/lib/brownfield_classify.py` generates `__pycache__/*.pyc` on import. The existing `.gitignore` did not cover these files, so every future Phase 10/11 run that imports the classifier would leave an untracked `bin/lib/__pycache__/` directory in the working tree.
- **Fix:** Added `__pycache__/` + `*.pyc` entries to `.gitignore` with an inline comment explaining the cause. Verified `git status` is clean after re-running the classifier import.
- **Files modified:** `.gitignore`
- **Commit:** `86cd382`

**2. [Rule 1 — Bug] Ruamel mention in scan script initially tripped strict acceptance check**
- **Found during:** Task 1 post-implementation verification (`! grep -q 'ruamel' bin/brownfield.sh`).
- **Issue:** My initial comments in `bin/brownfield.sh` mentioned "ruamel.yaml" in two header comments explaining that scan is PyYAML-only. The plan's acceptance criterion is a strict literal `! grep -q 'ruamel'` check — even the word in a comment fails it. This is a deliberate strictness from the plan: it wants the scan code path to be textually ruamel-free so there is zero chance the dep creeps in.
- **Fix:** Reworded both comments to avoid the literal string while preserving the information ("scan uses PyYAML only; the round-trip write path arrives with Plan 10-03 for bootstrap"; "The preserving-roundtrip YAML writer arrives with Plan 10-03 bootstrap").
- **Files modified:** `bin/brownfield.sh` (inline fix, no separate commit — rolled into `aaa6c38` before landing).
- **Verification:** `grep -q 'ruamel' bin/brownfield.sh` returns non-zero.

---

**Total deviations:** 2 auto-fixed (1 missing critical functionality, 1 bug).

## Issues Encountered

- **README.md leakage into Inventory on first smoke test.** My first smoke test ran `scan` against the fixture directly (not via `make_fixture_repo`), and the fixture's own `README.md` landed in the Inventory. Once I ran via the helper, the README was filtered out as expected. Lesson: always use `make_fixture_repo` in tests; direct-fixture invocation is for local debugging only.
- **Classifier gives `entity, low` for PascalCase filenames with no other signals.** This is correct per D-16 signal-2 (PascalCase → entity, only one signal → `low` confidence). I initially misremembered `attachments/diagram.md` as PascalCase — it's lowercase, so it correctly classifies as `unknown`. I fixed the fixture README row to reflect the actual classification.

## User Setup Required

None. `ruamel.yaml` is still Plan 10-03's concern; scan uses only the stdlib + PyYAML (already in the baseline).

## Handoff Notes

### To Plan 10-03 (`bin/brownfield.sh bootstrap --apply`)

- **Dispatcher is ready.** The subcommand `case` statement in `bin/brownfield.sh` already has a `scan|bootstrap) ;;` arm that passes through to subcommand-specific code. The current stub is a single-block `if [ "$SUBCOMMAND" = "bootstrap" ]; then ... exit 2; fi` (lines 57-61 of `bin/brownfield.sh`). Plan 10-03 replaces that stub with the full bootstrap implementation; it does NOT need to rewrite the dispatcher.
- **Bootstrap shares the `BROWNFIELD_LIB_DIR` export pattern.** The scan path exports `BROWNFIELD_LIB_DIR=$(cd "$(dirname "$0")/lib" && pwd)` and then does `sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])` inside its Python heredoc. Plan 10-03 should do the same if it re-imports the classifier.
- **Classifier re-import is optional.** Plan 10-03 MAY import `from brownfield_classify import classify_page` to label the `.brownfield/REPORT.md` section-(d) "Needs human judgment" tail during bootstrap, but this is not strictly required — bootstrap's REPORT.md responsibility is section (a)/(b)/(c) per D-04, and scan already wrote the (d) tail when users ran `scan` earlier.
- **`ruamel.yaml` is Plan 10-03's dep alone.** `bin/brownfield.sh` is textually ruamel-free in Phase 10 (no literal "ruamel" string). Plan 10-03 introduces ruamel.yaml in a new Python heredoc under the `bootstrap)` branch; scan remains untouched.
- **PyYAML pre-flight parse is already staged.** Scan already uses `yaml.safe_load` to pre-flight parse frontmatter before classification. Bootstrap will need the same pre-flight (D-01) before attempting ruamel round-trip; the pattern is in `parse_frontmatter()` inside `bin/brownfield.sh`.

### To Plan 10-04 (lint/ingest extensions)

- `tests/phase-10/run.sh` already reports `PHASE 10 TESTS: 8/8`. Plan 10-04 adds BRWN-08/09/10 test scripts under the same directory; the `shopt -s nullglob for t in test_*.sh` loop picks them up automatically, and the PHASE 10 TESTS line auto-updates.

### To Phase 11 (`bin/brownfield-suggest/01-page-typing.sh`)

- **Classifier API contract:** `classify_page(rel_path, frontmatter, body, inbound_count=None)`. Phase 11 passes `inbound_count` (built from a whole-vault two-pass walk); Phase 10 passes it as `None` which is ignored. The signal-4 branch in the current implementation handles ONLY outbound-density; Phase 11 should extend it to combine outbound density with inbound_count without modifying the module signature. A clean extension point is the `link_guess = None` block after the outbound-count check — Phase 11 can add an `elif inbound_count is not None and inbound_count >= N: link_guess = 'entity'` arm.

## Next Phase Readiness

- **Plan 10-02 complete.** All truths asserted by the plan frontmatter hold: `bin/brownfield.sh scan` writes `.brownfield/REPORT.md` without mutation; pages classify into the 6 valid types + `unknown` with signal-trace; `unknown` pages get prose open-questions; Obsidian-quirk dirs are excluded by default; `.brownfield-ignore` (gitignore-subset) extends/negates; `--help` prints usage; unknown subcommand exits 1; `suggest`/`verify` exit 2 with the Phase-11 message; `bootstrap` exits 2 with the Plan-10-03 message; no LLM calls (BRWN-16).
- **Requirements satisfied:** BRWN-01 (scan), BRWN-02 (unknown framing), BRWN-16 (rule-based, no LLM).
- **No blockers** for Plan 10-03 (bootstrap) or Plan 10-04 (lint/ingest extensions). The dispatcher scaffold is in place; the classifier is reusable; the test harness reports 8/8 green.

## Self-Check: PASSED

Verified post-SUMMARY that all claimed files exist and all claimed commits are in git history:

- `bin/brownfield.sh`: FOUND
- `bin/lib/brownfield_classify.py`: FOUND
- `tests/phase-10/test_brownfield_scan_help.sh`: FOUND
- `tests/phase-10/test_brownfield_scan_report.sh`: FOUND
- `tests/phase-10/test_brownfield_scan_exclusions.sh`: FOUND
- `tests/phase-10/test_brownfield_scan_confidence.sh`: FOUND
- `tests/phase-10/test_brownfield_scan_unknown.sh`: FOUND
- `tests/phase-10/test_brownfield_ignore_parser.sh`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/README.md`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/.brownfield-ignore`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/wiki/entities/SomeEntity.md`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/wiki/concepts/some-concept.md`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/wiki/sources/src-2026-04-01-paper.md`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/vault/musings.md`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/.obsidian/workspace.json`: FOUND
- `tests/phase-10/fixtures/scan-vault-basic/attachments/diagram.md`: FOUND
- `.gitignore` with Python cache entries: FOUND
- Commit `aaa6c38` (feat 10-02 dispatcher+classifier+fixture): FOUND
- Commit `709ad1c` (test 10-02 6 scan tests): FOUND
- Commit `86cd382` (chore 10-02 gitignore pycache): FOUND
- `bash tests/phase-10/run.sh` emits `PHASE 10 TESTS: 8/8`: CONFIRMED

---
*Phase: 10-brownfield-scan-bootstrap*
*Completed: 2026-04-17*
