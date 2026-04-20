---
phase: 11-brownfield-suggest-verify
plan: 04
subsystem: brownfield

tags: [brownfield, review-typing, verify, promote, ruamel-yaml, eof-safe-prompt, stale-artifact-detection, 5-gate-pass-list]

# Dependency graph
requires:
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-03 migration-script bodies (01 apply-from-paired-inputs; 02 direct-apply; 03/04 advisory) — the full chain runs to completion so review-typing + verify + verify --promote have a real end-state to assert against.
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-02 bin/brownfield.sh suggest — generates 5 .brownfield/*.yaml candidate manifests with D-09 metadata headers (verify reads source_script_hash for item-9 stale-artifact detection).
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-01 Wave-0 RED tests tagged EXPECTED_BY:11-04 (11 tests) + fixtures (small-vault-ambiguous, large-vault-ambiguous, pre-typed-vault) + per-plan gate split via `# EXPECTED_BY:` tag.
  - phase: 10-brownfield-scan-bootstrap
    provides: bin/lib/brownfield_yaml.py VALID_ENUMS + read_fm_body + write_roundtrip — verify --promote's 5-gate pass-list reuses these.
  - phase: 09-collaborative-pr-workflow-ci-lint-gate
    provides: bin/lint.sh --ci --format json --category X,Y contract (Phase 9 D-28 severity-remap + categories) — verify wraps this.
provides:
  - bin/brownfield.sh review-typing subcommand (D-04 orchestrator — small-batch TTY prompts with EOF-safe loop + override-label validation + NO_COLOR convention; large-batch AI-handoff prompt.md)
  - bin/brownfield.sh verify subcommand (D-13 read-only lint wrapper + REVIEWS item 9 stale-artifact WARN on source_script_hash drift)
  - bin/brownfield.sh verify --promote (D-14 5-gate per-page pass-list: bootstrapped + valid-type + zero-lint-errors + type-specific-required-fields + no-pending-review)
  - tests/phase-11/fixtures/end-to-end-golden/ — byte-frozen final-state vault for test_end_to_end_happy_path.sh diff -rq compare
affects: [11-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stdin pre-peek buffer (sys.stdin.read() at startup when not a TTY) → distinguishes scripted-input (small-batch) from immediate-EOF (large-batch fallback); prevents CI hangs per REVIEWS item 4"
    - "Process substitution `python3 <(cat <<'PYEOF' ... PYEOF)` preserves sys.stdin for the Python block when a bash heredoc would otherwise consume it (load-bearing for review-typing small-batch scripted-stdin)"
    - "_EOF_SENTINEL + _MAX_REPROMPTS_PER_CLUSTER bounded-loop pattern: zero-byte readline → abort cleanly; empty-string-with-newline → re-prompt bounded at 5 to prevent accidental interactive lockups"
    - "NO_COLOR / CLR_DIM / CLR_BOLD suppression (Phase 8 D-20): emit ANSI only when stderr.isatty() AND NO_COLOR env unset"
    - "VALID_ENUMS['type'] validated at entry time (REVIEWS item 11) — invalid override labels rejected with clear stderr message, cluster-level decision unchanged, user can retry"
    - "Stale-artifact detection: compare source_script_hash from D-09 metadata header against current body-post-op_hash-strip sha256 of byte-copy (REVIEWS item 9 — operational D-09 enforcement)"
    - "5-gate promotion uses mechanical `continue` statements in a Python for-loop; each gate is independent and failing gate-N never falls through to gate-N+1"
    - "verify --promote performance: O(n) single vault walk + indexed O(1) lint-error-per-path lookup + O(1) pending-page lookup → 500 pages promoted in ~1.5s (RESEARCH Q9 budget of <20s met by a wide margin)"
    - "Golden-fixture byte-compare pattern (test_end_to_end_happy_path.sh): conditional `diff -rq` when expected/ exists — fixture presence is the run-this-compare gate, absence is the Wave-0 fallback"

key-files:
  created:
    - tests/phase-11/fixtures/end-to-end-golden/README.md (regeneration recipe; env-var pins; fixture-layout contract)
    - tests/phase-11/fixtures/end-to-end-golden/expected/wiki/concepts/attention-mechanism.md (post-happy-path; bootstrap_stage: verified; type: concept; eligible bullets tagged [epistemic:: inferred])
    - tests/phase-11/fixtures/end-to-end-golden/expected/wiki/concepts/Transformer.md
    - tests/phase-11/fixtures/end-to-end-golden/expected/wiki/entities/geoffrey-hinton.md
    - tests/phase-11/fixtures/end-to-end-golden/expected/wiki/overviews/deep-learning.md
  modified:
    - bin/brownfield.sh (+736 lines; review-typing branch + verify branch + dispatcher update + usage expansion)
    - tests/phase-10/test_brownfield_scan_help.sh (-9 lines; relax verify stub-exit-2 assertion per prev-phase-test-obsoleted-by-Phase-11-04 precedent)

key-decisions:
  - "Stdin pre-peek buffer at startup to distinguish scripted-input from immediate-EOF: plan spec was ambiguous between `tty_stdout=0 → force large-batch` and `scripted-stdin → small-batch`. Reading stdin up front and checking for data resolves the ambiguity deterministically: test_review_typing_tty_small + validates_override_label (scripted stdin with `>/dev/null`) flow through small-batch; test_review_typing_ai_handoff + eof_handling (`</dev/null`) flow through large-batch. Both paths pass their respective tests."
  - "Process substitution `python3 <(cat <<'PYEOF' ... PYEOF)` replaces `python3 <<'PYEOF' ... PYEOF` in review-typing (suggest + verify keep heredoc because they don't read stdin). The heredoc form makes the script text the Python process's stdin, so any attempt to read caller stdin returns empty. Process substitution writes the script to a named-pipe FD, preserving the caller's stdin."
  - "VALID_TYPE_ENUM for review-typing override excludes the empty-string sentinel: `VALID_ENUMS['type']` contains `''` (D-14 scaffolding marker for no-frontmatter pages), but that is not a valid RESOLVED override label. Filter explicitly: `{t for t in VALID_ENUMS.get('type', set()) if t}`."
  - "verify reads WIKI_ROOT=<vault>/wiki when that subdir exists, otherwise WIKI_ROOT=<vault>: fixtures have a wiki/ subdir so lint scopes correctly; the fallback prevents a bare 'no such directory' error on vaults that ARE their own wiki directory (edge case)."
  - "Stale-artifact comparison semantics: suggest records `sha256_file(canonical_path)` as source_script_hash — the canonical has NO op_hash header. The byte-copy under .brownfield/migrations/ has op_hash prepended on lines 2-3. To compare: strip op_hash lines from the copy THEN sha256 — this reproduces the canonical body bytes whose sha256 IS the recorded value. On divergence, suggest must re-run."
  - "verify --promote performance: single lint subprocess + single O(n) os.walk over the vault + O(1) indexed lookups. Avoiding per-page subprocess spawn keeps the 500-page budget well under 20s (measured: ~1.5s)."
  - "End-to-end-golden fixture built from small-vault-ambiguous/input (4 pages → 4 clusters; all approve via scripted `a\\n` input). Deterministic regeneration verified: two back-to-back runs with pinned env vars produce byte-identical trees."

patterns-established:
  - "bin/brownfield.sh dispatcher-staging completion: scan|bootstrap|suggest|review-typing|verify ALL accepted; no exit-2 gates remaining. Plan 11-02's `'$SUBCOMMAND' not yet implemented — Plan 11-04 pending` message is gone."
  - "Review-typing orchestrator D-04 as implemented: small-batch (pending < N + usable stdin) = cluster-by-cluster TTY primitives; large-batch (pending >= N OR no stdin) = static AI-handoff prompt.md. Both paths write the same decisions.yaml via ruamel round-trip. CLI NEVER invokes an LLM."
  - "verify two-phase pattern: Phase 1 always runs (lint subprocess + stale-artifact check) and prints summary; Phase 2 runs only with --promote flag and flips bootstrap_stage on passing pages. Read-only default is intentional — operator audits findings before promoting."
  - "Test-as-contract pattern (inherited from Plan 11-03): EXPECTED_BY-tagged RED tests define the contract. This plan's 11 tests flip GREEN together without test-file edits — implementation alone satisfies the locked contract."

requirements-completed:
  - BRWN-13
  - BRWN-14
  - BRWN-16
  - BRWN-17
  - BRWN-22

# Metrics
duration: ~70min
completed: 2026-04-20
---

# Phase 11 Plan 04: review-typing + verify (+ --promote) subcommands Summary

**`bin/brownfield.sh review-typing` lands with an EOF-safe cluster-review loop (TTY small-batch + AI-handoff large-batch), and `verify` / `verify --promote` lands as a read-only lint wrapper plus a 5-gate `bootstrapped → verified` promotion pass — closing the Phase 11 code-side feature loop and flipping all 11 `EXPECTED_BY: 11-04` RED tests GREEN.**

## Performance

- **Duration:** ~70 min
- **Started:** 2026-04-20
- **Completed:** 2026-04-20
- **Tasks:** 2 (Task 1 review-typing; Task 2 verify + golden fixture)
- **Files created:** 5 (4 golden-fixture wiki pages + README.md)
- **Files modified:** 2 (bin/brownfield.sh, tests/phase-10/test_brownfield_scan_help.sh)

## Accomplishments

- **11/11 Wave-0 RED tests tagged `EXPECTED_BY: 11-04` flipped to GREEN** — `bash tests/phase-11/run.sh --expected-by 11-04` reports `PHASE 11 TESTS: 11/11 (expected-by 11-04)`.
- **Non-regression on 11-01/02/03 + Phase 10 + Phase 09:** all previously-green tiers stay green (3/3 + 7/7 + 19/19 + 32/32 + 28/28).
- **11-05 subset stays RED at 1/7** (AGENTS §11.5 + docs/AGENTS-parity + canonical-AGENTS byte-equality + 3 docs sections) — THIS IS EXPECTED per REVIEWS item-6 per-plan gate split; Plan 11-05 will flip these.
- **end-to-end-golden fixture committed** at `tests/phase-11/fixtures/end-to-end-golden/expected/wiki/`; deterministic regeneration verified; `test_end_to_end_happy_path.sh` byte-compare branch now resolves GREEN.
- **BRWN-16 hard-lock enforced**: zero `curl|wget|anthropic|openai|claude|chatgpt|gpt-` mentions across bin/brownfield.sh + bin/lib/brownfield_*.py + schema/brownfield/migrations/*.sh (verified by test_no_llm_calls.sh).
- **RESEARCH Q9 performance budget met by wide margin**: `verify --promote` on a synthetic 500-page vault completes in ~1.5s (budget: <20s).

## Task Commits

1. **Task 1+2 implementation: review-typing + verify branches** — `d54c1ec` (feat)
2. **Task 2b: end-to-end-golden fixture** — `2e0f1b0` (test)

## Files Created/Modified

### Created

- **`tests/phase-11/fixtures/end-to-end-golden/README.md`** — Fixture documentation with env-var pins (`BROWNFIELD_FIXTURE_TODAY=2026-04-20`, `BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20`, `BROWNFIELD_TOOL_VERSION=1.1.0`) and full regeneration recipe.
- **`tests/phase-11/fixtures/end-to-end-golden/expected/wiki/concepts/attention-mechanism.md`** — Post-happy-path state: `type: concept`, `bootstrap_stage: verified`, eligible bullets tagged `[epistemic:: inferred]`.
- **`tests/phase-11/fixtures/end-to-end-golden/expected/wiki/concepts/Transformer.md`** — Same.
- **`tests/phase-11/fixtures/end-to-end-golden/expected/wiki/entities/geoffrey-hinton.md`** — Same (`type: entity`).
- **`tests/phase-11/fixtures/end-to-end-golden/expected/wiki/overviews/deep-learning.md`** — Same (`type: overview`).

### Modified

- **`bin/brownfield.sh`** (+736 lines, -20 lines):
  - Dispatcher: `scan|bootstrap|suggest|review-typing|verify` all accepted; the Plan-11-02 exit-2 gate for `review-typing|verify` removed.
  - Usage header + `usage()` block: review-typing + verify promoted from "NOT YET IMPLEMENTED" to full-options documentation.
  - **New review-typing branch** (~270 lines Python + ~80 lines bash wrapper):
    - stdin pre-peek buffer at startup distinguishes scripted-input vs immediate-EOF.
    - Small-batch TTY prompt loop with a/r/i/o/s primitives.
    - Large-batch AI-handoff writes `.brownfield/review-typing-prompt.md` (static heredoc; CLI never invokes an LLM).
    - EOF-safe `prompt()` helper returns `_EOF_SENTINEL` on zero-byte readline; `_MAX_REPROMPTS_PER_CLUSTER = 5` bounds accidental interactive lockups.
    - Override sub-action validates label against `VALID_ENUMS['type']` (excluding empty-string sentinel) before writing.
    - ruamel.yaml `YAML(typ='rt')` round-trip load/dump preserves D-09 metadata header + user-authored comments.
    - CLR_DIM / CLR_BOLD / NO_COLOR inheritance from Phase 8 D-20.
  - **New verify branch** (~200 lines Python + ~50 lines bash wrapper):
    - Stale-artifact detection: for each of 5 candidate YAMLs mapped to its canonical script, compare `source_script_hash` in the D-09 metadata header vs current body-post-op_hash-strip sha256 of the byte-copy.
    - Lint subprocess: `bash bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield` (no `privacy` — handled by `bin/check-privacy.sh` per Phase 9 D-15).
    - JSON findings indexed by relative path → `errors_by_path` + `warnings_by_path`.
    - Read-only default: print summary + optional error-per-page list; exit 0 regardless of findings.
    - `--promote`: 5-gate pass-list per page (bootstrapped + valid-type-enum + zero-lint-errors + type-specific-required-fields + not-in-pending-cluster). Gates are mechanical `continue` statements; failing pages never fall through to the write.
- **`tests/phase-10/test_brownfield_scan_help.sh`** — Relaxed the `verify` stub-exit-2 assertion to `verify --help` exit-0 check (prev-phase-test-obsoleted-by-this-plan-populate; same precedent as Plan 10-02/11-02 bootstrap/suggest relaxations). Required for Phase-10 32/32 non-regression.

## Decisions Made

All decisions tracked in frontmatter `key-decisions`. Highlights:

- **Stdin pre-peek buffer resolves the "scripted stdin vs TTY" ambiguity.** The plan's force-large-batch spec said "otherwise pending >= N OR stdout not a TTY → large-batch", but the test fixtures require small-batch with scripted stdin + non-TTY stdout. Reading stdin up front (`sys.stdin.read()`) when `not sys.stdin.isatty()` and checking whether any bytes were received lets us distinguish scripted input (small-batch) from `</dev/null` (large-batch). Both test clusters pass with this implementation.
- **Process substitution `python3 <(cat <<'PYEOF' ...)`** replaces the standard heredoc in review-typing — the heredoc form makes the script text become Python's stdin, which breaks the small-batch prompt loop. suggest + verify keep the standard heredoc form because they don't read stdin.
- **VALID_TYPE_ENUM excludes empty string.** `brownfield_yaml.VALID_ENUMS['type']` contains `''` (a D-14 scaffolding sentinel), but empty-string is not a valid RESOLVED override label. Filter: `{t for t in ... if t}`.
- **Stale-artifact comparison strips op_hash lines before sha256.** suggest records `sha256(canonical_body)` as `source_script_hash`. The byte-copy has op_hash prepended on lines 2-3. To reproduce the canonical sha256 from the copy, strip op_hash lines first.
- **verify --promote uses a single lint subprocess.** Per RESEARCH Q9 budget <20s on 500 pages. Measured: 500-page synthetic vault completes in ~1.5s — margin to spare.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Heredoc consumed stdin; review-typing small-batch never received scripted input**
- **Found during:** Task 1 test-pass verification (test_review_typing_tty_small.sh + test_review_typing_validates_override_label.sh both FAIL despite correct logic).
- **Issue:** `python3 <<'PYEOF' ... PYEOF` in bash makes the heredoc text become Python's stdin. So `sys.stdin.read()` inside the Python block returns the script text (or, after read, empty). Scripted user input piped from `echo -n "a\na\n"` is ignored.
- **Fix:** Changed review-typing's Python invocation to `python3 <(cat <<'PYEOF' ... PYEOF)` (process substitution). The script text is now a file, and Python's stdin remains connected to the caller's stdin. suggest + verify keep the heredoc form because they don't read stdin.
- **Files modified:** bin/brownfield.sh (review-typing branch only).
- **Verification:** test_review_typing_tty_small.sh + test_review_typing_validates_override_label.sh both PASS after the change.
- **Committed in:** d54c1ec (Task 1+2 commit).

**2. [Rule 3 - Blocking] Stdin pre-peek distinguishes scripted-input from immediate-EOF**
- **Found during:** Task 1 initial implementation.
- **Issue:** Plan spec said `force_large_batch = (not tty_stdout) or (len(pending) >= n_thresh)`, but test_review_typing_tty_small.sh + test_review_typing_validates_override_label.sh require small-batch with scripted stdin + non-TTY stdout (tests redirect stdout `>/dev/null`). Meanwhile test_review_typing_ai_handoff.sh requires large-batch with `</dev/null` + non-TTY stdout. Both share "non-TTY stdout", so stdout-TTY alone can't discriminate.
- **Fix:** Added stdin pre-peek: when `not sys.stdin.isatty()`, call `sys.stdin.read()` at startup and buffer the lines. Branch condition becomes `(pending >= N) OR not (stdin_is_tty OR has_scripted_stdin)`. Scripted input → small-batch; `</dev/null` → large-batch. The `prompt()` helper consumes from the buffer when non-TTY, else reads fresh from stdin.
- **Files modified:** bin/brownfield.sh (review-typing Python block).
- **Verification:** All 5 review-typing tests PASS; ai_handoff path still routes to large-batch on `</dev/null`.
- **Committed in:** d54c1ec (Task 1+2 commit).

**3. [Rule 1 - Bug] Test_no_llm_calls.sh regex-matched "Claude" in my own comment**
- **Found during:** Post-implementation Phase-11 aggregator run.
- **Issue:** test_no_llm_calls.sh greps case-insensitively for `claude|anthropic|openai|gpt-|chatgpt|curl|wget`. My inline comment `# CONTEXT §Claude's-Discretion` matched `claude`. Pre-existing `# Note: only *calls* are forbidden, not the word in comments` tolerance is not implemented — the test is literal-match on the word.
- **Fix:** Reworded the comment to `# CONTEXT planner default`. Semantics preserved.
- **Files modified:** bin/brownfield.sh (1 comment line).
- **Verification:** test_no_llm_calls.sh PASS.
- **Committed in:** d54c1ec (Task 1+2 commit).

**4. [Rule 3 - Blocking] Phase-10 test_brownfield_scan_help.sh hardcoded verify exit-2**
- **Found during:** Task 1 dispatcher update.
- **Issue:** Phase-10's `test_brownfield_scan_help.sh` asserts `verify` exits 2 with the "Plan 11-04 pending" stub message. My dispatcher change removes that stub, so the Phase-10 test would regress.
- **Fix:** Relaxed the assertion to `verify --help` exit-0 check. Same precedent as Plan 10-02's bootstrap relaxation and Plan 11-02's suggest relaxation (both documented in the test file itself).
- **Files modified:** tests/phase-10/test_brownfield_scan_help.sh (-9 lines, +5 lines).
- **Verification:** Phase-10 32/32 still passes.
- **Committed in:** d54c1ec (Task 1+2 commit).

---

**Total deviations:** 4 auto-fixed (2 blocking, 1 bug, 1 prev-phase-test-obsoleted relaxation).

**Impact on plan:** All fixes were necessary for acceptance-criterion compliance. #1 + #2 are load-bearing integration patterns not made explicit in the plan spec but required for test-contract satisfaction; #3 is a surface-level wording fix; #4 is the documented precedent pattern for previous-phase tests invalidated by populate-plan implementations. No scope creep.

## Issues Encountered

- **Pre-existing dirty working tree** (inherited from prior sessions): files under `.planning/phases/07-.../07-VERIFICATION.md`, `.planning/phases/999.4-.../CONTEXT-NOTES.md`, `docs/reference/setup-prerequisites.md` pre-modified plus untracked `.claude/`, `.obsidian/`, `agentic-gtd-system-with-wiki-compiler.md`, `idea.md`, etc. Did NOT touch or commit these — task commits staged explicitly by file path (no `git add -A`).
- **`bin/brownfield.sh` reached 2278 lines** (up from 1570). Suggest + review-typing + verify now account for ~60% of the file. This remains the single-source-of-truth dispatcher per Phase-10 architecture. No refactor planned for Plan 11-05; if file size becomes a review concern it can be split in v1.2.

## User Setup Required

None — no external service configuration required.

## Review-Item Verification

All 4 REVIEWS items targeted by this plan pass their contract tests:

- **Item 4 (EOF hang)**: test_review_typing_eof_handling.sh PASS. `echo -n "" | bash bin/brownfield.sh review-typing` exits in <3s with "aborting session cleanly" on stderr. `_EOF_SENTINEL` + `_MAX_REPROMPTS_PER_CLUSTER=5` bounded-loop enforcement confirmed.
- **Item 9 (stale artifact)**: test_verify_stale_artifact_warn.sh PASS. Appending `# drift-simulation-comment` to a `.brownfield/migrations/01-page-typing.sh` byte-copy triggers stderr WARN `stale candidate artifact detected: page-typing-candidates.yaml ... re-run \`bin/brownfield.sh suggest\` to refresh`. Exit code stays 0.
- **Item 11 (override label validation)**: test_review_typing_validates_override_label.sh PASS. Scripted stdin with `o\nwiki/concepts/attention-mechanism.md\nbadlabel\n` produces stderr `invalid label: 'badlabel'; must be one of ['comparison', 'concept', 'decision', 'entity', 'overview', 'source']. Override discarded.` and the string `badlabel` never appears in decisions.yaml.
- **Item 14 (CLR_DIM/CLR_BOLD NO_COLOR)**: Manually verified. `NO_COLOR=1 bash bin/brownfield.sh review-typing --root <fixture>` produces stderr with no ANSI escapes. Default TTY stderr includes the dim/bold escape sequences.

## Performance Measurements

- **review-typing small-batch on 4 clusters** (scripted `a\n` input): <200ms end-to-end.
- **review-typing large-batch on 25-page vault** (11 clusters, `</dev/null`): writes prompt.md in <300ms; no vault mutation.
- **verify (read-only) on small-vault-ambiguous**: ~800ms (lint subprocess dominated).
- **verify --promote on small-vault-ambiguous** (4 pages promoted): ~900ms.
- **verify --promote on 500-page synthetic vault** (all promoted): ~1.5s — well under the RESEARCH Q9 <20s budget.

## Threshold Calibration

N=20 threshold (CONTEXT §planner-default + RESEARCH Q3 recommendation) proved correct for the Phase 11 fixture set:

| Fixture | Pending clusters | Branch |
|---------|-----------------:|--------|
| small-vault-ambiguous | 3 | small-batch (scripted stdin path) |
| large-vault-ambiguous | 8 | small-batch in principle; pushed to large-batch by `</dev/null` stdin (no scripted input) |

Both tests' expected branches are reachable under the implemented rule `(pending >= N) OR (no usable stdin)`. No N-value change needed.

## End-to-End Golden Regeneration Timestamp

Fixture regenerated at 2026-04-20 with:
```
BROWNFIELD_FIXTURE_TODAY=2026-04-20
BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
BROWNFIELD_TOOL_VERSION=1.1.0
```

Deterministic regeneration verified: two back-to-back runs produce byte-identical `wiki/**` trees.

## Test Tally

```
PHASE 11 TESTS: 41/47 (unfiltered — 6 11-05 tests RED as expected)
  11-01: PHASE 11 TESTS: 3/3  (expected-by 11-01)   ← non-regression
  11-02: PHASE 11 TESTS: 7/7  (expected-by 11-02)   ← non-regression
  11-03: PHASE 11 TESTS: 19/19 (expected-by 11-03)  ← non-regression
  11-04: PHASE 11 TESTS: 11/11 (expected-by 11-04)  ← THIS PLAN
  11-05: PHASE 11 TESTS: 1/7  (expected-by 11-05)   ← Plan 11-05 targets
```

**11-05 subset still RED (6 tests):** test_agents_section_11_5.sh, test_agents_template_parity_11_5.sh, test_canonical_agents_byte_equality.sh, test_docs_review_typing_section.sh, test_docs_suggest_section.sh, test_docs_verify_section.sh. Per REVIEWS item-6 per-plan gate split, this is EXPECTED; Plan 11-05 (docs + AGENTS §11.5 + canonical-AGENTS byte-equality) flips these.

Non-regression on sibling test suites:
- Phase 10: 32/32 PASS
- Phase 9: 28/28 PASS
- Phase 9.1: unchanged (no Phase-11 dependencies)

## Next Plan Readiness

Plan 11-05 (AGENTS.md §11.5 + docs + canonical-AGENTS byte-equality) has:

- All 6 remaining RED tests tagged `EXPECTED_BY: 11-05` waiting for docs + AGENTS §11.5 + schema/AGENTS.template.md parity + schema/fixtures/canonical-AGENTS.md regeneration.
- Full Plan-11-04 code-side feature loop production-ready: review-typing + verify + verify --promote operational on all 7 Phase-11 fixtures.
- end-to-end-golden fixture stable — any 11-05 changes that accidentally perturb the end-to-end flow will break test_end_to_end_happy_path.sh at once.

Plan 11-05 success criterion is directly verifiable: `bash tests/phase-11/run.sh --expected-by 11-05` returns `PHASE 11 TESTS: 7/7`.

## TDD Gate Compliance

Plan 11-04 is a Wave-4 implementation that flips Plan 11-01's RED tests to GREEN — this is the phase-level TDD cycle's GREEN gate for the review-typing + verify surface.

- **RED** (Plan 11-01): 11 EXPECTED_BY:11-04 tests authored and failing against the Plan 11-02 dispatcher stub (commits fe960dd, 6e3cab5, dede63b).
- **GREEN** (Plan 11-04, this plan): review-typing + verify branches land; tests flip to PASS (commits d54c1ec, 2e0f1b0).
- **REFACTOR** (optional): no further cleanup; the `bin/brownfield.sh` file is large but functionally partitioned. Split-if-needed deferred to v1.2.

Git log shows `test(11-01): ...` commits (fe960dd, 6e3cab5) BEFORE `feat(11-04): ...` commits from this plan — gate order satisfied for all 11 flipped tests.

## Self-Check

Verified file existence + commit hashes post-commit:

- FOUND: bin/brownfield.sh (2278 lines; review-typing branch at ~1328; verify branch at ~1702; no "not yet implemented — Plan 11-04 pending" string)
- FOUND: tests/phase-11/fixtures/end-to-end-golden/README.md
- FOUND: tests/phase-11/fixtures/end-to-end-golden/expected/wiki/ (4 .md files)
- FOUND commit d54c1ec (Task 1+2: review-typing + verify branches)
- FOUND commit 2e0f1b0 (Task 2b: end-to-end-golden fixture)
- PASS: `bash tests/phase-11/run.sh --expected-by 11-04` → 11/11
- PASS: `bash tests/phase-11/run.sh --expected-by 11-03` → 19/19
- PASS: `bash tests/phase-11/run.sh --expected-by 11-02` → 7/7
- PASS: `bash tests/phase-11/run.sh --expected-by 11-01` → 3/3
- EXPECTED RED: `bash tests/phase-11/run.sh --expected-by 11-05` → 1/7 (per item-6 per-plan gate split)
- PASS: `PYTHONPATH="$HOME/.local/lib/python3/dist-packages" bash tests/phase-10/run.sh` → 32/32
- PASS: `bash tests/phase-09/run.sh` → 28/28

## Self-Check: PASSED

---
*Phase: 11-brownfield-suggest-verify*
*Completed: 2026-04-20*
