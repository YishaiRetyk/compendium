---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 03
subsystem: testing
tags: [lint, ci, strict, escape-hatch, contributor, pr-diff, semver, bash, python3]

requires:
  - phase: 09-01
    provides: tests/phase-09/lib.sh helpers (make_fixture_repo, seed_origin_main_ref, setup_git_author, assert_json_has_finding, cleanup_fixture_repo) and 8 fixture directories
  - phase: 09-02
    provides: LINT_VERSION=1.1.0, CI_SEVERITY_REMAP dispatch table (contributor + skip-count entries pre-allocated), --format/--ci/--skip-category/--require-version flags, matches_skip helper
provides:
  - --strict flag (CI-06 quality ratchet, PR-diff-scoped per D-08)
  - --count-skips flag (D-09 aggregator, emits info/skip-count per marker)
  - EXPECT_MARKER_RE regex (D-09 escape-hatch marker parser)
  - strict_added_epistemic_claims() (unified-diff parser, PR-diff scope)
  - strict_new_pages() (D-10 status-A page detection)
  - collect_dr_affected_pages() (wiki-wide DR index via affected_pages frontmatter)
  - is_claim_excepted_by_adjacent_marker() (D-09 strict prev-line adjacency + id + non-empty reason)
  - has_origin_main() + _strict_check_fallback() (local-mode graceful degradation)
  - count_skips_aggregate() (walks wiki for every lint:expect-* marker)
  - parse_author_map() + git_author_emails() + contributor_check() (COLAB-08 / D-22)
  - PR-diff scope contract: DR-match gates ONLY claims added by this PR (pre-existing debt does NOT fail unrelated PRs — Codex HIGH resolution)
affects: [09-05, 09-06]

tech-stack:
  added: []
  patterns:
    - "Unified-diff parser pattern: python3 subprocess.run(git diff --unified=0 origin/main...HEAD) with new-side line counter advancing only on +added lines"
    - "origin/main fallback pattern: has_origin_main() probe + stderr WARN + wiki-wide scan preserves local dev ergonomics; CI always has origin/main via fetch-depth:0"
    - "DR coverage as historical union: decisions already on main are valid coverage for PR-added claims; only the SET OF CLAIMS checked is PR-scoped, the DR index is not"
    - "Escape-hatch marker strict adjacency: line N marker + line N+1 claim, blank line between invalidates (prevents stale markers drifting down)"
    - "Single-author short-circuit pattern (D-20): len(git_author_emails) <= 1 silently emits zero contributor findings — personal forks clean"
    - "Category/severity extension via pre-allocated dispatch entry: contributor + skip-count already in CI_SEVERITY_REMAP from Plan 02, Plan 03 just populates them via add_finding()"

key-files:
  created:
    - tests/phase-09/test_lint_strict_dr_match.sh
    - tests/phase-09/test_lint_strict_new_page.sh
    - tests/phase-09/test_lint_strict_escape_hatch.sh
    - tests/phase-09/test_lint_count_skips.sh
    - tests/phase-09/test_lint_contributor_check.sh
    - tests/phase-09/fixtures/strict-missing-dr/wiki/sources/src-2026-04-16-test.md
    - tests/phase-09/fixtures/strict-missing-dr/sources/src-2026-04-16-test.md
    - tests/phase-09/fixtures/strict-escape-hatch/wiki/sources/src-2026-04-16-test.md
    - tests/phase-09/fixtures/strict-escape-hatch/sources/src-2026-04-16-test.md
  modified:
    - bin/lint.sh (+~440 lines: EXPECT_MARKER_RE, STRICT_MODE/COUNT_SKIPS bash flags + env-var wiring, strict_check with PR-diff scope + fallback, count_skips_aggregate, contributor_check, parse_author_map, git_author_emails, has_origin_main, unified-diff parser, CI/strict unified exit policy, usage() docs)

key-decisions:
  - "PR-diff scope (D-08) fixes Codex HIGH: --strict gates ONLY PR-added [inferred]/[tentative] claims via git diff --unified=0 origin/main...HEAD parser; pre-existing debt on unchanged pages does NOT fail unrelated PRs"
  - "DR index wiki-wide by design: decisions already merged to main are valid coverage for same-PR claims (avoids false-negative of legitimately merged DR failing to cover its claim). The SET OF CLAIMS checked is PR-diff-scoped; the COVERAGE INDEX is not"
  - "origin/main fallback: has_origin_main() probe + 'WARN: no origin/main; scanning all wiki pages (local mode)' stderr + wiki-wide _strict_check_fallback() walk. New-page provenance check skipped in fallback (D-10 is inherently PR-diff-scoped)"
  - "Escape-hatch marker adjacency is LOAD-BEARING (D-09): blank line between marker and claim invalidates. Prevents stale markers drifting down as pages are edited. id mismatch also invalidates; reason must be non-empty"
  - "Exempted claims ALWAYS emit as info/skip-count (both in --strict exempt path AND --count-skips aggregator); visible in JSON + text for reviewer annotation"
  - "CI + --strict unified exit policy: exit 1 iff any post-remap error-severity finding in both JSON and text modes. Plan 02's --ci exit path extended to honor STRICT_MODE"
  - "contributor category uses .git-author-map.txt two-space-arrow-two-space or tab separator convention (Plan 04 seed); case-insensitive email match; D-20 single-author short-circuit silently returns zero findings"
  - "Plan 02's pre-allocated CI_SEVERITY_REMAP entries (contributor=warning, skip-count=info) now exercised by real findings — no dispatch-table changes needed"

patterns-established:
  - "Pattern: PR-diff scope guard — when a lint check should gate only PR-added lines, use git diff --unified=0 + new-side line counter + '+'-line filter (not wiki-wide walk)"
  - "Pattern: CI-only gate with local fallback — probe ref presence, emit stderr WARN on absence, gracefully degrade to looser scan; preserves dev ergonomics without changing CI semantics"
  - "Pattern: adjacent-marker exemption — marker on line N + target on line N+1; blank line between invalidates. Load-bearing strictness prevents marker-drift"
  - "Pattern: sibling-helper check wired after main walk — count_skips_aggregate + contributor_check plug into the same filter+remap pipeline as strict_check, keeping the downstream emit path orthogonal"

requirements-completed: [CI-06, COLAB-08]

duration: 10min
completed: 2026-04-16
---

# Phase 09 Plan 03: Lint Strict + Escape Hatch + Contributor Summary

**bin/lint.sh v1.1.0 gains --strict (CI-06 quality ratchet, PR-diff-scoped per D-08), --count-skips (D-09 escape-hatch aggregator), and contributor category (COLAB-08 / D-22) as the judgment-shaped checks that ride through Plan 02's severity-remap dispatch.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-16T07:52:10Z
- **Completed:** 2026-04-16T08:02:37Z
- **Tasks:** 2 (both TDD, both green after fixture-data Rule-3 fix)
- **Files modified:** 1 existing (bin/lint.sh, +~440 lines), 5 new tests, 4 new fixture files

## Accomplishments

- `bin/lint.sh --strict` is a working CI-6 quality ratchet with **PR-diff scope** (D-08 honored). Claims ADDED by the PR (lines with `+` prefix in `git diff --unified=0 origin/main...HEAD -- wiki/`) that contain `[epistemic:: inferred]` or `[epistemic:: tentative]` must be matched by a wiki decision record whose `affected_pages` frontmatter list contains the claim-page's `id`, OR be exempted by an adjacent `<!-- lint:expect-* -->` marker. Pre-existing debt on unchanged pages does NOT fail unrelated PRs.
- `--strict` also enforces D-10 (new-page provenance): git-diff status-`A` pages under `wiki/{entities,concepts,overviews,comparisons}/` with zero `[prov:]` markers fail. Source and decision pages are exempt by design.
- `--strict` gracefully degrades when `origin/main` ref is absent: prints `WARN: no origin/main; scanning all wiki pages (local mode)` to stderr and falls back to wiki-wide scan. CI always has `origin/main` (fetch-depth: 0); local dev still useful.
- Escape-hatch marker (`<!-- lint:expect-inferred|tentative id=<page-id> reason="<one line>" -->`) honors strict adjacency contract (D-09):
  1. Must be on line IMMEDIATELY above the claim (line N → claim on N+1)
  2. Blank line between marker and claim invalidates
  3. `id` field must match containing page's frontmatter `id`
  4. `reason` field must be non-empty
  5. Exempted claims always emit as `info/skip-count` (visible in JSON + text for reviewer annotation)
- `bin/lint.sh --count-skips` walks the wiki emitting one `info/skip-count` finding per `lint:expect-*` marker encountered, plus stderr grand total `--count-skips: N skipped findings across M pages`. Designed for human review, not automated enforcement.
- `bin/lint.sh` `contributor` category (COLAB-08 / D-22) warns on each `contributor:: @handle` in `wiki/log.md` whose email (via `.git-author-map.txt` reverse lookup) does NOT appear in `git log --all --format='%ae'`. Single-author repos short-circuit silently (D-20). Map two-space-arrow-two-space or tab separator accepted; comments via `#`; case-insensitive email match.
- All new categories ride through Plan 02's existing filter pipeline: `--skip-category contributor` suppresses, `--ci` applies the pre-allocated `contributor=warning`, `skip-count=info` severity remap, `--format json` serializes in the standard 4-tuple shape.
- Codex HIGH review concern resolved: the PR-scope guard test (Test B2 in `test_lint_strict_dr_match.sh`) asserts a feature-branch making an unrelated change does NOT cause `--strict` to fail on pre-existing `[inferred]` claims.

## Task Commits

Each task was committed atomically (TDD red-then-green):

1. **Task 1 RED: failing tests for --strict** — `fc523f3` (test)
   - `test_lint_strict_dr_match.sh`: Test A (PR-added claim without DR → fail), Test B (matching DR added → pass), Test B2 (pre-existing debt → pass — scope guard), Test B3 (no origin/main → WARN stderr + loose scan)
   - `test_lint_strict_new_page.sh`: fail on new concept without `[prov:]`, exempt when type flipped to source
   - `test_lint_strict_escape_hatch.sh`: marker honored, blank line invalidates, id mismatch invalidates, skip-count info finding in JSON

2. **Task 1 GREEN: --strict + escape-hatch** — `5633caa` (feat)
   - `STRICT_MODE` bash flag + `--strict` CLI parse case + env-var export to python3 block
   - `EXPECT_MARKER_RE` regex (strict form: `^<!--\s*lint:expect-(inferred|tentative)\s+id=...\s+reason="..."\s*-->\s*$`)
   - `has_origin_main()` probe + `_strict_check_fallback()` loose wiki-wide scan with stderr WARN
   - `strict_added_epistemic_claims()` unified-diff parser: `git diff --unified=0 origin/main...HEAD -- wiki/`, processes `+++ b/<path>` file headers + `@@ -A,B +C,D @@` hunk headers + `+added` content lines; new-side line counter advances only on `+added` (not removed/context)
   - `strict_new_pages()`: `git diff --name-status origin/main...HEAD` status-`A` filter for `wiki/{entities,concepts,overviews,comparisons}/*.md`
   - `collect_dr_affected_pages()`: walks `wiki/decisions/` for `type: decision` pages, unions `affected_pages` lists into coverage set
   - `is_claim_excepted_by_adjacent_marker()`: reads working-tree file, matches `EXPECT_MARKER_RE` on line `claim_line_no - 2` (0-indexed), verifies `id` + non-empty `reason`
   - `strict_check()` dispatcher: (a) origin/main probe → fallback or PR-diff path, (b) DR-match loop over added claims with skip-count emission for exempted, error for unmatched, (c) new-page provenance loop over status-A paths
   - Fixture source summary pages added to both `strict-missing-dr` and `strict-escape-hatch` fixtures (`wiki/sources/src-2026-04-16-test.md` + `sources/src-2026-04-16-test.md`) to avoid unrelated provenance errors tainting --strict exit
   - `test_lint_strict_new_page.sh` updated to inject SOURCE_EXTRA_FIELDS + `--category provenance` isolation when flipping type to source (isolates D-10 exempt behavior from unrelated yaml errors)
   - `usage()` documents `--strict` with origin/main fallback note

3. **Task 2 RED: failing tests for --count-skips + contributor** — `c6d3eef` (test)
   - `test_lint_count_skips.sh`: 2-page fixture (attention.md + other.md) with 3 total markers; expects 3+ skip-count findings + stderr grand total
   - `test_lint_contributor_check.sh`: multi-author case (@bob unmapped → warning → map fix clears), single-author case (@anyone in log, zero findings due to D-20 short-circuit)

4. **Task 2 GREEN: --count-skips + contributor_check** — `9aa98bf` (feat)
   - `COUNT_SKIPS` bash flag + `--count-skips` CLI parse case + env-var export
   - `count_skips_aggregate()`: walks wiki for every `EXPECT_MARKER_RE` match, emits one `info/skip-count` per marker, stderr grand total `--count-skips: N skipped findings across M pages`
   - `parse_author_map()`: reads `.git-author-map.txt` with two-space-arrow-two-space OR tab separator, comment-aware (#-prefix), case-insensitive email key, `@handle` value validated
   - `git_author_emails()`: `git log --all --format='%ae'` lowercased set
   - `contributor_check()`: scans `wiki/log.md` for `contributor:: @handle` patterns, reverse-lookup via map, emits `warning/contributor` on mismatch OR unmapped handle; D-20 single-author short-circuit via `len(git_emails) <= 1` guard
   - All three invoked before Plan 02 filter pipeline so findings ride through `--skip-category` + `--ci` remap
   - `usage()` extends category list with `contributor`; `--count-skips` documented

## Files Created/Modified

- **`bin/lint.sh`** — +~440 lines total across Tasks 1+2. `STRICT_MODE`, `COUNT_SKIPS`, `LINT_REPO_ROOT` env vars wired through bash→python3. Eleven new python helpers. Unified exit-code policy: `if CI_MODE or STRICT_MODE: exit 1 iff any post-remap error-severity finding`.
- **`tests/phase-09/test_lint_strict_dr_match.sh`** (+174 lines) — PR-scoped DR match happy path, matching-DR-clears path, pre-existing-debt scope guard, origin/main fallback WARN stderr path.
- **`tests/phase-09/test_lint_strict_new_page.sh`** (+74 lines) — new-concept-without-prov fail path, type-source-exempt path. Uses `--category provenance` to isolate D-10 check from unrelated yaml errors.
- **`tests/phase-09/test_lint_strict_escape_hatch.sh`** (+65 lines) — adjacent-marker honored path, blank-line invalidates path, id mismatch invalidates path, skip-count info finding emission verified via `assert_json_has_finding`.
- **`tests/phase-09/test_lint_count_skips.sh`** (+74 lines) — 2-page / 3-marker aggregator path, stderr grand-total verification.
- **`tests/phase-09/test_lint_contributor_check.sh`** (+90 lines) — unmapped @handle → warning, map fix → clears, single-author → no findings (D-20).
- **Fixture source pages added:**
  - `tests/phase-09/fixtures/strict-missing-dr/wiki/sources/src-2026-04-16-test.md` (source summary frontmatter resolving the attention.md prov ref)
  - `tests/phase-09/fixtures/strict-missing-dr/sources/src-2026-04-16-test.md` (raw source file resolving DRFT-02)
  - `tests/phase-09/fixtures/strict-escape-hatch/wiki/sources/src-2026-04-16-test.md` + matching raw file

## EXPECT_MARKER_RE Regex

```python
EXPECT_MARKER_RE = re.compile(
    r'^<!--\s*lint:expect-(?P<kind>inferred|tentative)\s+'
    r'id=(?P<id>[a-z0-9-]+)\s+'
    r'reason="(?P<reason>[^"]+)"\s*-->\s*$'
)
```

Strictness rules (D-09):
1. Marker must appear on line IMMEDIATELY above the claim (line N, claim on line N+1)
2. Blank line between marker and claim INVALIDATES exemption
3. `id` field MUST match the containing page's frontmatter `id` (case-sensitive)
4. `reason` is required and non-empty after strip
5. Exempted claims emit as severity `info`, category `skip-count`

## PR-Diff Scope Contract (D-08 Interpretation)

"The new claim" = a line ADDED by the PR (a line starting with `+` in `git diff --unified=0 origin/main...HEAD`, excluding the `+++` file header). The DR-match rule applies to this narrow set, not all inferred/tentative claims in the wiki. Pre-existing claims on unchanged pages are pre-existing debt; they do not gate unrelated PRs.

Parser details:
- `--unified=0` means no context lines — we see only `+added` and `-removed` lines
- `+++ b/<path>` file headers establish `current_path`; `/dev/null` resets to None
- `@@ -A,B +C,D @@` hunk headers reset `current_new_lineno` to `C`
- `+added` lines advance `current_new_lineno` after extracting any `EPISTEMIC_INFERRED_RE` match
- `-removed` lines do NOT advance the new-side counter
- Result: list of `(path, line_no, kind)` tuples where `line_no` is the new-side 1-indexed line number of the added claim

DR index scope (intentionally loose): `collect_dr_affected_pages()` walks ALL `wiki/decisions/*.md` in the working tree, not just PR-diff DRs. Rationale: merged decisions that already cover a claim should not trigger a false-negative failure. The SET OF CLAIMS checked is PR-diff-scoped; the COVERAGE INDEX is historical.

## origin/main Fallback Behavior

```python
def has_origin_main():
    # Probes refs/remotes/origin/main via git show-ref --verify --quiet
    ...

def strict_check(wiki_root):
    if not STRICT_MODE: return
    if not has_origin_main():
        print("WARN: no origin/main; scanning all wiki pages (local mode)", file=sys.stderr)
        _strict_check_fallback(wiki_root)  # wiki-wide walk, pre-revision semantics
        return
    # ... PR-diff-scoped path ...
```

- CI always has `origin/main` (fetch-depth: 0 in checkout action), so CI always exercises the PR-diff-scoped path
- Local dev without a remote (`git init` + commit) exercises the fallback: wiki-wide walk of all epistemic claims, with the WARN banner making the looseness visible
- New-page provenance check (D-10) is SKIPPED in fallback: D-10 requires `git diff --name-status` status-`A`, which is inherently PR-diff-scoped. No sensible local equivalent exists.

## contributor Category Contract

`.git-author-map.txt` format:

```
# Comments start with #
alice@example.com  ->  @alice
bob@example.com	@bob
```

Two separators accepted: `"  ->  "` (two-space-arrow-two-space) OR a literal tab. Email match is case-insensitive. Parser tolerates blank lines.

Check algorithm:
1. If `wiki/log.md` missing → silent return
2. Collect `git_author_emails` via `git log --all --format='%ae'`
3. D-20 single-author short-circuit: `len(git_emails) <= 1` → silent return
4. For each unique `contributor:: @handle` in `wiki/log.md`:
   - Reverse-lookup email via map (`@handle.lower()` key)
   - If no mapping: `warning/contributor` "@handle has no mapping in .git-author-map.txt"
   - Elif mapped email NOT in `git_emails`: `warning/contributor` "@handle mapped to <email> but email not in git commit authors"
   - Else: silent (happy path)
5. Plan 02's CI_SEVERITY_REMAP preserves `contributor=warning` in `--ci` mode

## Function Signatures

```python
# Task 1 (strict + escape-hatch)
def has_origin_main() -> bool
def strict_added_epistemic_claims(base_ref='origin/main') -> list[tuple[str, int, str]]
def strict_new_pages(base_ref='origin/main') -> list[str]
def collect_dr_affected_pages(wiki_root: str) -> set[str]
def page_id_for_path(path: str) -> str
def is_claim_excepted_by_adjacent_marker(path: str, claim_line_no: int, page_id: str) -> bool
def parse_fm_from_text(content: str) -> dict | None
def _strict_check_fallback(wiki_root: str) -> None
def strict_check(wiki_root: str) -> None

# Task 2 (count-skips + contributor)
def count_skips_aggregate(wiki_root: str) -> None
def parse_author_map(root: str) -> dict[str, str]   # {email_lc: @handle}
def git_author_emails(root: str) -> set[str]
def contributor_check(wiki_root: str, repo_root: str) -> None
```

## Test Assertion Coverage

| Test file | Assertion coverage |
|-----------|-------------------|
| `test_lint_strict_dr_match.sh` | A: PR-added [inferred] no DR → exit 1; B: matching DR added → exit 0; B2: pre-existing debt + unrelated change → exit 0 (scope guard); B3: no origin/main → `WARN: no origin/main` stderr |
| `test_lint_strict_new_page.sh` | status-A concept without [prov:] → exit 1 + stderr/stdout mentions "prov"; flipping to type:source (with SOURCE_EXTRA_FIELDS injected) → exit 0 under --category provenance |
| `test_lint_strict_escape_hatch.sh` | adjacent marker honored → exit 0 + JSON has skip-count info finding (asserted via assert_json_has_finding); blank line inserted between marker and claim → exit 1; id corrupted to wrong-id → exit 1 |
| `test_lint_count_skips.sh` | 3 markers across 2 pages → `sum(1 for i in data if i['category']=='skip-count') >= 3`; stderr contains "skip" |
| `test_lint_contributor_check.sh` | multi-author @bob unmapped → warning in JSON; add map entry → re-lint JSON has NO contributor category; single-author fixture with @anyone in log → NO contributor category (D-20 short-circuit) |

## Decisions Made

- **PR-diff scope fixes Codex HIGH review concern.** Earlier spec had `strict_check()` walking ALL wiki pages for `[epistemic:: inferred|tentative]`, which would block an unrelated PR on pre-existing debt. Revised to `strict_added_epistemic_claims()` using `git diff --unified=0` unified-diff parser.
- **DR index wiki-wide by intent.** The plan could have restricted coverage checking to DR files in the PR diff, but that creates a false-negative: a legitimately-merged DR covering a new PR-added claim would fail the check because the DR file isn't in the diff. We accept the looser interpretation.
- **origin/main fallback preserves local ergonomics.** Without this, every local `--strict` invocation outside CI would fail with a cryptic git error. The stderr WARN makes the looseness visible so nobody is surprised.
- **New-page check skipped in fallback.** D-10 is intrinsically PR-diff-scoped (requires status A). There's no sensible local equivalent, so the fallback runs only the DR-match scan.
- **Escape-hatch marker strictness is load-bearing.** Adjacent-line placement + blank-line-invalidates is explicitly designed to prevent stale markers drifting away from their claims as pages are edited. Documented in AGENTS.md §11.3 (Plan 05).
- **Exempted claims always emit skip-count info.** This is the reviewer-visible trail: grep-ing JSON for `skip-count` findings in a PR shows exactly which inferred/tentative claims were bypassed and why.
- **Single-author short-circuit silent.** D-20 — personal forks shouldn't see any "missing contributor" noise. Zero findings emitted, zero warnings in CI output.
- **Fixture data fix vs. test harness fix.** The attention.md fixture referenced a nonexistent `src-2026-04-16-test` source, which triggered `error/provenance` findings that tainted --strict's exit code (Plan 02 behavior: exit 1 on any error). Added minimal source summary + raw source files to the `strict-missing-dr` and `strict-escape-hatch` fixtures. This is Rule 3 (blocking issue fix): the test setup needs the source to exist for orthogonal checks to pass. Alternative (use --skip-category) was rejected as less transparent.
- **test_lint_strict_new_page.sh isolates via --category provenance.** Flipping `type: concept` → `type: source` triggers a yaml error because source pages require SOURCE_EXTRA_FIELDS. Rather than coupling the test to all wiki yaml correctness, we inject the required fields AND scope the test to the provenance category only. This is the cleanest way to assert "source pages are D-10 exempt" without accidentally gating on yaml.

## Deviations from Plan

1. **[Rule 3 - Blocking Issue] Added fixture source pages to strict-missing-dr and strict-escape-hatch.** The fixtures' attention.md referenced a nonexistent source `src-2026-04-16-test` in prov markers. Under --strict, which exits 1 on any error-severity finding (including Plan 02's existing `error/provenance` "broken prov ref" check), this tainted the DR-match-clears happy path. Fixed by adding minimal source summary pages (`wiki/sources/src-2026-04-16-test.md`) and raw source files (`sources/src-2026-04-16-test.md`) to both fixtures. Path in source summary is `sources/src-2026-04-16-test.md`; DRFT-02 check resolves against `project_root/<path>`. Files: 4 new markdown stubs. Commit: `5633caa`.
2. **[Rule 2 - Missing Critical Functionality] test_lint_strict_new_page.sh uses `--category provenance` + SOURCE_EXTRA_FIELDS injection.** Plan's original test flipped `type: concept` → `type: source` and expected --strict to exit 0, but the yaml check errors when source pages lack `path`, `content_hash`, `ingested_at`, `source_type`, `compilation_status`. Added python3 block to inject those fields alongside the type flip, plus `--category provenance` to isolate the D-10 check. This ensures the test assertion ("source pages are D-10 exempt") is what's actually verified, not an accidental yaml-error pass. Files: `test_lint_strict_new_page.sh`. Commit: `5633caa`.

Both deviations are scope-bounded: they touch fixtures + a test script, not the behavior contract. The five behavior-contract tests (DR-match positive/negative/scope-guard/fallback, new-page pass/fail, escape-hatch positive/blank-invalidates/id-invalidates, count-skips aggregation, contributor mismatch/fix/short-circuit) all verify exactly what the plan's `<acceptance_criteria>` requires.

## Issues Encountered

1. **Fixture provenance coupling.** The plan's fixtures contained forward references to a source_id that didn't have a corresponding source page. Pre-Plan-03, this was a benign `error/provenance` finding with no exit-code impact (Plan 02's --ci would fail on it, but Plan 03's --strict without --ci also fails, so the fixtures need to be internally consistent). Solved by adding source stubs.
2. **Source page yaml requirements.** Flipping type to source without adding SOURCE_EXTRA_FIELDS triggers yaml error. Documented in the updated test with a python3 injection block.

No issues with:
- Unified-diff parser (correct handling of `+++ b/`, `@@ -A,B +C,D @@`, and `+`/`-`/` ` content lines on first pass)
- origin/main fallback probe (works on local and CI)
- Adjacent-marker regex (strict pattern matches design intent)
- Single-author short-circuit (len check cleanly returns)

## Verification Results

All 5 new tests pass:

```
PASS: --strict DR-match (PR-scoped + pre-existing-debt safe + origin/main fallback WARN)
PASS: --strict new-page provenance + source-type exempt
PASS: escape-hatch marker (adjacent + blank-line-invalidates + id-match) with PR-diff scope
PASS: --count-skips enumeration + grand total
PASS: contributor category check (mismatch warns, map fix clears, single-author short-circuits)
```

Acceptance-criteria greps:

```
EXPECT_MARKER_RE: FOUND
strict_check: FOUND
strict_added_epistemic_claims: FOUND
collect_dr_affected_pages: FOUND
strict_new_pages: FOUND
has_origin_main: FOUND
WARN: no origin/main: FOUND
STRICT_MODE bash default: FOUND
count_skips_aggregate: FOUND
contributor_check: FOUND
parse_author_map: FOUND
git_author_emails: FOUND
COUNT_SKIPS bash default: FOUND
--help lists --strict, --count-skips, contributor: FOUND
```

Regression (all green):

```
bash bin/lint.sh --dry-run wiki/     # exit 0, v1.0 text behavior unchanged
bash tests/phase-07/run.sh           # PHASE 07 TESTS: 22/22
bash tests/phase-08/run.sh           # PHASE 08 TESTS: 21/21
bash tests/phase-09/run.sh           # PHASE 09 TESTS: 19/19
```

All three strict test files source `lib.sh` and call `seed_origin_main_ref` at least once (verified via grep).

## Self-Check: PASSED

All created files exist:
- `bin/lint.sh` — FOUND (contains EXPECT_MARKER_RE, strict_check, count_skips_aggregate, contributor_check, parse_author_map, git_author_emails, has_origin_main, "WARN: no origin/main", "^STRICT_MODE=", "^COUNT_SKIPS=")
- `tests/phase-09/test_lint_strict_dr_match.sh` — FOUND
- `tests/phase-09/test_lint_strict_new_page.sh` — FOUND
- `tests/phase-09/test_lint_strict_escape_hatch.sh` — FOUND
- `tests/phase-09/test_lint_count_skips.sh` — FOUND
- `tests/phase-09/test_lint_contributor_check.sh` — FOUND
- `tests/phase-09/fixtures/strict-missing-dr/wiki/sources/src-2026-04-16-test.md` — FOUND
- `tests/phase-09/fixtures/strict-missing-dr/sources/src-2026-04-16-test.md` — FOUND
- `tests/phase-09/fixtures/strict-escape-hatch/wiki/sources/src-2026-04-16-test.md` — FOUND
- `tests/phase-09/fixtures/strict-escape-hatch/sources/src-2026-04-16-test.md` — FOUND

Commits verified:
- `fc523f3` — FOUND (Task 1 RED: failing --strict tests)
- `5633caa` — FOUND (Task 1 GREEN: --strict + escape-hatch)
- `c6d3eef` — FOUND (Task 2 RED: failing --count-skips + contributor tests)
- `9aa98bf` — FOUND (Task 2 GREEN: --count-skips + contributor_check)

## Next Phase Readiness

- Plan 05's `strict` CI job invokes `bash bin/lint.sh --require-version 1.1.0 --strict` and gets:
  - exit 1 on any PR-added `[inferred]`/`[tentative]` claim lacking a matching DR (unless exempted via `lint:expect-*`)
  - exit 1 on any new (status A) entity|concept|overview|comparison page lacking `[prov:]`
  - exit 0 otherwise — including full PR-diff scope (pre-existing debt does not gate)
- Plan 05's AGENTS.md §11.3 amendments can reference concrete code: EXPECT_MARKER_RE regex, PR-diff-scoped unified-diff parser, affected_pages DR-match loop, origin/main fallback with WARN
- Plan 05's `.github/workflows/lint.yml` must configure `actions/checkout@v4` with `fetch-depth: 0` so `origin/main` ref is available for `--strict` PR-diff-scoped path (without fetch-depth: 0, --strict would fall back to local-mode wiki-wide scan)
- Plan 06's CONTRIBUTING.md can reference the `lint:expect-inferred id=<page> reason="..."` escape-hatch syntax verbatim; grep-friendly in code review
- `contributor` and `skip-count` categories are now fully exercised by real findings; CI_SEVERITY_REMAP's pre-allocated entries (from Plan 02) validated
- Codex HIGH review concern resolved: test_lint_strict_dr_match.sh Test B2 explicitly asserts pre-existing debt does NOT fail unrelated PRs

---
*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Plan: 03*
*Completed: 2026-04-16*
