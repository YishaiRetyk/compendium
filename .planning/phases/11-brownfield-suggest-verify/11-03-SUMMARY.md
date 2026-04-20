---
phase: 11-brownfield-suggest-verify
plan: 03
subsystem: brownfield

tags: [brownfield, migration-scripts, page-typing, provenance-bootstrap, cross-link-inference, privacy-review, ruamel-yaml, hashlib-portable, top-level-bullets]

# Dependency graph
requires:
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-02 bin/brownfield.sh suggest — byte-copies canonical migration scripts with op_hash headers; produces 5 .brownfield/*.yaml candidate manifests (page-typing-candidates/decisions, cross-link-candidates, privacy-findings, provenance-bootstrap-report); bin/lib/brownfield_walk.py shared walker
  - phase: 11-brownfield-suggest-verify
    provides: Plan 11-01 Wave-0 RED tests tagged EXPECTED_BY:11-03 (19 tests) + canonical migration script skeletons at schema/brownfield/migrations/ + fixtures (small-vault-ambiguous, nested-bullets-vault, already-tagged-vault, privacy-sensitive-vault)
provides:
  - Four real migration-script bodies implementing the apply-class / advisory-class contract
    (01-page-typing apply-from-paired-immutable-inputs; 02-provenance-bootstrap direct-apply;
    03-cross-link-inference advisory; 04-privacy-review advisory)
  - bin/lib/brownfield_provenance.py pure helper module (is_top_level_bullet, is_eligible_claim_bullet, section_scan)
  - bin/brownfield.sh suggest now writes .brownfield/.brownfield-env breadcrumb
    (lib-dir path for migration scripts — Rule 3 blocking fix)
affects: [11-04, 11-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Root resolution from script location (${BASH_SOURCE[0]} grandparent); never $(pwd)"
    - "Paired immutable inputs: decisions.yaml (authoritative policy) + candidates.yaml (cluster-member lookup); both required; no re-classification at apply time"
    - "Python hashlib for input-file SHA-256 via pre-flight heredoc; zero shell sha256sum invocations (macOS-portable)"
    - "Top-level-bullets-only regex anchor ^-(?: |\\t) in brownfield_provenance.BULLET_TOP_LEVEL_RE — nested bullets never match"
    - "applied.log per-script variance: 01 2-line paired-input hashes; 02 1-line literal advisory; 03/04 no inputs: + mutations: none + report_section:"
    - ".brownfield/.brownfield-env breadcrumb pattern — suggest drops lib-dir path so installed migration scripts can locate bin/lib at run time"

key-files:
  created:
    - bin/lib/brownfield_provenance.py (116 lines; pure re-based helpers)
  modified:
    - schema/brownfield/migrations/01-page-typing.sh (30 → 249 lines)
    - schema/brownfield/migrations/02-provenance-bootstrap.sh (30 → 226 lines)
    - schema/brownfield/migrations/03-cross-link-inference.sh (26 → 145 lines)
    - schema/brownfield/migrations/04-privacy-review.sh (24 → 153 lines)
    - bin/brownfield.sh (+9 lines — .brownfield-env writer in suggest branch)
    - tests/phase-11/test_04_advisory_only.sh (Rule 1 auto-fix: SSN-redaction contradiction)

key-decisions:
  - "applied.log emits on 03/04 even with 0 findings (contrary to plan's 'appends only on findings' wording) — tests_applied_log_advisory_schema.sh asserts the block exists for 03 on privacy-sensitive-vault fixture which has 0 cross-link candidates; test is authoritative contract"
  - ".brownfield-env breadcrumb chosen over BROWNFIELD_LIB_DIR env-var-only because tests do NOT export that var; migration scripts must self-locate bin/lib even when tests set only PYTHONPATH"
  - "SSN redaction in privacy-findings.yaml preserved (plan must_haves line 29); test_04 expectation of raw '123-45-6789' was incompatible-with-plan bug inherited from Wave-0 RED; test updated to assert [redacted-SSN] presence AND raw SSN absence"
  - "valid_label_set excludes empty string — empty string is a valid D-14 sentinel TYPE but not a valid RESOLVED label (would be a no-op)"
  - "TASK_RE anchor fixed from \\b (broken at ]-space boundary) to (\\s|$) so '- [ ] TODO item' is correctly excluded from eligible claims"
  - "02 preserves CRLF line endings (current.endswith('\\r\\n') branch) for defensive portability even though vault fixtures are LF-only"

patterns-established:
  - "bin/lib helper-module reuse: migration scripts import pure-function helpers (is_eligible_claim_bullet from brownfield_provenance) rather than duplicating regex; single-source-of-truth enforcement"
  - "Per-script applied.log variance documented normatively (item 10); 01 has 2 hashed input lines; 02 has 1 literal advisory line; advisory blocks omit inputs: entirely and carry mutations: none + report_section:"
  - "Pre-flight python hashlib block for input hashes: Python subprocess emits KEY=value lines to stdout, bash eval's them into the current shell; preserves shebang-based macOS portability"
  - "Root-resolution pattern (copy-verbatim snippet across all 4 scripts): SCRIPT_DIR/BF_DIR/BROWNFIELD_ROOT chain + basename(dirname(SCRIPT_DIR)) == '.brownfield' gate to reject canonical-direct-invocation"

requirements-completed:
  - BRWN-12
  - BRWN-13
  - BRWN-15
  - BRWN-16

# Metrics
duration: ~35min
completed: 2026-04-21
---

# Phase 11 Plan 03: Migration-script bodies Summary

**Four canonical brownfield migration scripts get real bodies — 01-page-typing applies from paired immutable inputs via ruamel.yaml round-trip; 02-provenance-bootstrap tags eligible top-level TL;DR/Key Facts bullets with [epistemic:: inferred]; 03/04 emit advisory reports that NEVER mutate vault pages — flipping all 19 Wave-0 RED tests tagged EXPECTED_BY:11-03 to GREEN.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-20 (continued into 2026-04-21)
- **Completed:** 2026-04-21
- **Tasks:** 3 (Task 1 brownfield_provenance.py; Task 2 01+02 apply-class; Task 3 03+04 advisory-class)
- **Files created:** 1 (bin/lib/brownfield_provenance.py)
- **Files modified:** 6 (4 migration scripts + bin/brownfield.sh + 1 test)

## Accomplishments

- **19/19 Wave-0 RED tests tagged `EXPECTED_BY: 11-03` flipped to GREEN** — `bash tests/phase-11/run.sh --expected-by 11-03` reports `PHASE 11 TESTS: 19/19`.
- **7/7 EXPECTED_BY:11-02 tests still GREEN** (non-regression — suggest still produces valid candidates/decisions/cross-link/privacy YAML outputs after adding .brownfield-env breadcrumb).
- **3/3 EXPECTED_BY:11-01 tests still GREEN** including `test_hashlib_not_sha256sum.sh` (no new sha256sum added) and `test_canonical_byte_equality.sh` (schema/ vs .brownfield/ copies byte-equal post-op_hash-strip).
- **Phase 10 non-regression: 32/32** (verified with `PYTHONPATH="$HOME/.local/lib/python3/dist-packages"`).
- **11-04 + 11-05 subsets correctly remain RED** (0/11 + 1/7) — my plan didn't implement their scope.
- **Zero LLM / network calls** introduced; **zero shell `sha256sum` added**; **BRWN-15 magic-string lock** verified (no `[prov:bootstrap]`, `[epistemic:: imported]`, `[epistemic:: bootstrapped]` strings in 02).

## Task Commits

1. **Task 1: bin/lib/brownfield_provenance.py** — `6f69468` (feat)
2. **Task 2a: 01-page-typing.sh + bin/brownfield.sh .brownfield-env breadcrumb** — `9f27064` (feat)
3. **Task 2b: 02-provenance-bootstrap.sh** — `c6e6c5e` (feat)
4. **Task 3a: 03-cross-link-inference.sh** — `7a5620b` (feat)
5. **Task 3b: 04-privacy-review.sh + test_04 SSN-redaction fix** — `1eef548` (feat)

## Files Created/Modified

### Created

- **`bin/lib/brownfield_provenance.py`** (116 lines) — Pure helper module with
  `is_top_level_bullet(line) -> bool`, `is_eligible_claim_bullet(line) -> bool`,
  `section_scan(body, target_sections) -> list[(int, str)]`. BULLET_TOP_LEVEL_RE
  anchored `^-(?: |\t)(.+)$` (review item 5 — nested bullets never match). Stdlib-only.

### Modified

- **`schema/brownfield/migrations/01-page-typing.sh`** (249 lines; was 30) — Apply-class;
  reads paired immutable inputs; ruamel.yaml round-trip mutation of `type:` frontmatter;
  Python hashlib via pre-flight heredoc; applied.log 2-line inputs; root-resolved from
  script location; idempotent via current-type check.
- **`schema/brownfield/migrations/02-provenance-bootstrap.sh`** (226 lines; was 30) —
  Apply-class direct-apply; imports pure helpers from brownfield_provenance.py and
  walker from brownfield_walk.py; D-12 soft prereq WARN on majority-untyped vault;
  applied.log 1-line literal `inputs:` line per item 10; BRWN-15 magic-string lock.
- **`schema/brownfield/migrations/03-cross-link-inference.sh`** (145 lines; was 26) —
  Advisory-only; --apply exits 1 with REPORT.md pointer; always emits applied.log
  advisory block (mode: advisory; mutations: none; report_section:).
- **`schema/brownfield/migrations/04-privacy-review.sh`** (153 lines; was 24) —
  Advisory-only; --apply exits 1 with AGENTS.md §13 reference; zero write_roundtrip
  imports (BRWN hard-lock); --help notes raw email/phone retention + SSN redaction
  + gitignored scope (item 12).
- **`bin/brownfield.sh`** (+9 lines in suggest branch) — Writes
  `.brownfield/.brownfield-env` breadcrumb recording the repo's bin/lib path.
  Migration scripts source this to locate brownfield_yaml.py / brownfield_provenance.py
  / brownfield_walk.py at run-time.
- **`tests/phase-11/test_04_advisory_only.sh`** — Replaced `'123-45-6789'` expectation
  with `'pattern_type: ssn'` + `'\[redacted-SSN\]'` + raw-SSN-absence guard. Test was
  authored in Plan 11-01 before the SSN-redaction policy was locked in plan must_haves.

## Decisions Made

Documented in frontmatter `key-decisions`. Highlights:

- **applied.log unconditional emit on 03/04** (even with 0 findings) — the plan text
  "appends on findings" conflicts with `test_applied_log_advisory_schema.sh` which
  asserts 03's block on `privacy-sensitive-vault` (which has 0 cross-link candidates).
  Chose test-as-authoritative-contract per plan's "flip GREEN" success criterion.
- **`.brownfield-env` breadcrumb** over env-var-only — tests export only PYTHONPATH,
  not BROWNFIELD_LIB_DIR. Migration scripts need to self-locate bin/lib; a breadcrumb
  written at suggest time is the cleanest path that preserves the script-location root
  resolution (item 1) and zero-env-magic invocation.
- **SSN-redaction preserved** — plan must_haves / threat model / Plan 11-02 suggest
  implementation all agree: SSN is redacted to `[redacted-SSN]`. `test_04_advisory_only.sh`
  expectation `'123-45-6789'` was Wave-0 RED bug inherited before the policy was locked.
  Fixed the test (Rule 1 auto-fix). Raw email/phone preserved for operator triage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] .brownfield-env breadcrumb added to suggest**
- **Found during:** Task 2a — first integration run
- **Issue:** Migration scripts installed into `/tmp/fixture-xxx/.brownfield/migrations/`
  had no filesystem path back to the repo's `bin/lib/`; scripts could not locate
  `brownfield_yaml.py` via upward walk (test fixtures live under /tmp with no ancestor
  bin/lib directory). Tests set only `PYTHONPATH="$HOME/.local/lib/python3/dist-packages"`
  for ruamel; they do NOT export `BROWNFIELD_LIB_DIR`.
- **Fix:** Modified `bin/brownfield.sh` suggest branch (+9 lines) to write
  `.brownfield/.brownfield-env` containing `BROWNFIELD_LIB_DIR="<absolute path>"`.
  Each migration script sources the breadcrumb if `BROWNFIELD_LIB_DIR` not already set
  by explicit env override. Preserves: (a) script-location root resolution from item 1,
  (b) test env-override path (env still wins), (c) upward-walk fallback for manually
  installed scripts in repo-rooted vaults.
- **Files modified:** bin/brownfield.sh, schema/brownfield/migrations/*.sh (all 4)
- **Verification:** All 19 EXPECTED_BY:11-03 tests pass; `.brownfield-env` file present
  in suggest output; canonical byte-equality test still green.
- **Committed in:** 9f27064 (Task 2a commit)

**2. [Rule 1 - Bug] TASK_RE anchor fix in brownfield_provenance.py**
- **Found during:** Task 1 — unit smoke-test fail on `- [ ] TODO item`
- **Issue:** Original regex from plan action block used `\b` as the terminating anchor:
  `^- (\[[ xX]\]|TODO:?|FIXME:?)\b`. `\b` is a zero-width word boundary; after `]`
  and before ` ` (both non-word characters), there is no boundary, so `- [ ] TODO item`
  did NOT match. This caused `is_eligible_claim_bullet('- [ ] TODO item')` to return
  True (false eligible → false over-tag of checkbox tasks).
- **Fix:** Replaced `\b` with `(\s|$)` — explicit whitespace-or-EOL termination.
- **Files modified:** bin/lib/brownfield_provenance.py
- **Verification:** Task 1 unit smoke-test PASS (11/11 eligibility cases correct);
  `test_02_apply_eligible_bullets.sh` still PASS.
- **Committed in:** 6f69468 (Task 1 commit)

**3. [Rule 1 - Bug] test_04_advisory_only.sh raw-SSN expectation contradicted plan**
- **Found during:** Task 3b
- **Issue:** Test expected raw `'123-45-6789'` in privacy-findings.yaml, but plan
  must_haves (line 29), threat model (T-11-03-04), and Plan 11-02's already-shipped
  suggest implementation all agree SSN is redacted to `[redacted-SSN]`. Test was
  authored in Plan 11-01 before the SSN-redaction policy was locked.
- **Fix:** Updated test to assert `pattern_type: ssn` + `[redacted-SSN]` presence
  AND raw `'123-45-6789'` ABSENCE. Plan's SSN-redaction policy takes precedence
  (consistent across three specification documents).
- **Files modified:** tests/phase-11/test_04_advisory_only.sh
- **Verification:** test_04_advisory_only.sh PASS; suggest output unchanged.
- **Committed in:** 1eef548 (Task 3b commit)

**4. [Rule 1 - Bug] applied.log advisory blocks emit unconditionally (03/04)**
- **Found during:** Task 3 verification against `test_applied_log_advisory_schema.sh`
- **Issue:** Plan line 1491 ("Zero findings → no applied.log append") conflicted with
  test assertion that 03's block appears on `privacy-sensitive-vault` fixture (which
  has 0 cross-link candidates). Test would fail if we honored the plan's gate literally.
- **Fix:** Made 03/04 always emit applied.log blocks (advisory-class variance item 10
  — block always present; summary:- candidates: 0 is a legitimate audit entry).
- **Files modified:** schema/brownfield/migrations/03-cross-link-inference.sh,
  schema/brownfield/migrations/04-privacy-review.sh
- **Verification:** test_applied_log_advisory_schema.sh PASS; test_03_advisory_only.sh
  PASS; test_04_advisory_only.sh PASS.
- **Committed in:** 7a5620b, 1eef548

---

**Total deviations:** 4 auto-fixed (1 blocking, 3 bugs)

**Impact on plan:** All four deviations resolved contradictions between plan
specification and inherited Wave-0 RED tests / fixture semantics. #1 (breadcrumb) was
a necessary integration pattern invisible at plan-time. #2 was a regex correctness
bug. #3 resolved inconsistency between Plan 11-01's RED test and Plan 11-02's locked
SSN-redaction policy. #4 reconciled plan's "append on findings only" wording with the
test-authoritative contract that advisory runs always record to applied.log. No scope
creep — all changes remained within the canonical-migration-scripts concern.

## Issues Encountered

- **Pre-existing dirty working tree**: Inherited from prior sessions (files under
  `.planning/phases/07-...`, `.planning/phases/999.4-...`, and `docs/reference/...`
  pre-modified; untracked `.claude/`, `.obsidian/`, `agentic-gtd-system-with-wiki-compiler.md`,
  `idea.md`, etc.). Did NOT touch or commit these; Task commits staged explicitly by
  file path per AGENTS.md §3 (no `git add -A`).
- **`type: "concept"` vs `type: concept` quoting**: `write_roundtrip` renders the
  string with ruamel's default quoting style (DQ-preserving on empty-string-replace).
  Tests accept either form (`grep -E '^type:'` is permissive); no action needed.
- **Phase 10 32/32 only with PYTHONPATH**: Phase 10 bootstrap tests need
  `PYTHONPATH="$HOME/.local/lib/python3/dist-packages"` set to find ruamel. Pre-existing
  environment issue from Plan 11-02 (documented there); confirmed not a regression.

## User Setup Required

None — no external service configuration required.

## Next Plan Readiness

Plan 11-04 (review-typing + verify) has:

- The 11 RED tests tagged `EXPECTED_BY: 11-04` currently failing cleanly against the
  Plan 11-02 suggest stub's `"not yet implemented — Plan 11-04 pending"` message.
- All four apply/advisory scripts production-ready — 11-04 can build review-typing
  (interactive cluster approval → updates decisions.yaml) and verify (runs lint +
  promotes bootstrap_stage: bootstrapped → verified) on top of a known-good base.
- `test_end_to_end_happy_path.sh` (EXPECTED_BY:11-04) exercises the full loop:
  suggest → review-typing → 01 apply → 02 apply → verify. All four scripts it invokes
  already work; only review-typing and verify subcommands remain.
- applied.log schema is frozen (per-script variance per item 10); 11-04's verify can
  parse it without guessing shape.

Plan 11-03 success criterion verified: `bash tests/phase-11/run.sh --expected-by 11-03`
returns `PHASE 11 TESTS: 19/19`.

## TDD Gate Compliance

Plan 11-03 is a Wave-3 implementation that flips Plan 11-01's RED tests to GREEN —
this is the phase-level TDD cycle's GREEN gate for the migration-scripts subset.

- **RED** (Plan 11-01): 19 EXPECTED_BY:11-03 tests authored and failing against stub
  scripts (emitting `"not yet implemented — Plan 11-03 pending"` exit 2).
- **GREEN** (Plan 11-03, this plan): real script bodies land; tests flip to PASS
  (commits 6f69468, 9f27064, c6e6c5e, 7a5620b, 1eef548).
- **REFACTOR** (optional): no further cleanup; test_04 SSN fix was bundled into
  Task 3b's commit rather than a separate refactor pass because it was
  specification-correctness, not beautification.

Git log shows `test(11-01)` commits (fe960dd) BEFORE `feat(11-03): ...` commits from
this plan — gate order satisfied for all 19 flipped tests.

## Self-Check

Verified file existence + commit hashes post-commit:

- FOUND: bin/lib/brownfield_provenance.py (116 lines; is_top_level_bullet + is_eligible_claim_bullet + section_scan defined)
- FOUND: schema/brownfield/migrations/01-page-typing.sh (249 lines)
- FOUND: schema/brownfield/migrations/02-provenance-bootstrap.sh (226 lines)
- FOUND: schema/brownfield/migrations/03-cross-link-inference.sh (145 lines)
- FOUND: schema/brownfield/migrations/04-privacy-review.sh (153 lines)
- FOUND: bin/brownfield.sh (+9 line .brownfield-env writer in suggest)
- FOUND commit 6f69468 (Task 1: brownfield_provenance.py)
- FOUND commit 9f27064 (Task 2a: 01-page-typing + breadcrumb)
- FOUND commit c6e6c5e (Task 2b: 02-provenance-bootstrap)
- FOUND commit 7a5620b (Task 3a: 03-cross-link-inference)
- FOUND commit 1eef548 (Task 3b: 04-privacy-review + test_04 fix)
- PASS: `bash tests/phase-11/run.sh --expected-by 11-03` → 19/19
- PASS: `bash tests/phase-11/run.sh --expected-by 11-02` → 7/7
- PASS: `bash tests/phase-11/run.sh --expected-by 11-01` → 3/3
- PASS: `bash tests/phase-11/test_canonical_byte_equality.sh` (schema vs .brownfield byte-equal post-op_hash-strip)
- PASS: `bash tests/phase-11/test_hashlib_not_sha256sum.sh` (no new shell sha256sum)
- PASS: `bash tests/phase-11/test_no_llm_calls.sh` (no network/LLM invocations)
- PASS: `PYTHONPATH="$HOME/.local/lib/python3/dist-packages" bash tests/phase-10/run.sh` → 32/32

### Item contract verification

- **Item 1 (root resolution)**: All 4 scripts contain `BROWNFIELD_ROOT="${BROWNFIELD_ROOT:-$(cd "$BF_DIR/.." && pwd)}"`; `$(pwd)` default absent in all 4.
- **Item 2 (paired immutable inputs)**: 01's --help contains `PAIRED IMMUTABLE INPUTS`; deleting candidates.yaml → 01 --apply errors with "paired immutable inputs per item 2" message (test_01_paired_immutable_inputs.sh PASS).
- **Item 5 (top-level bullets only)**: 02 imports `from brownfield_provenance import is_eligible_claim_bullet, section_scan`; no duplicate regex inlined. BULLET_TOP_LEVEL_RE `^-(?: |\t)(.+)$` rejects 4 nested-bullet shapes (test_02_top_level_bullets_only.sh PASS).
- **Item 8 (hashlib not sha256sum)**: `test_hashlib_not_sha256sum.sh` PASS; zero shell `sha256sum` invocations across bin/brownfield.sh + schema/brownfield/migrations/*.sh.
- **Item 10 (applied.log per-script variance)**: 01 emits 2 hashed `inputs:` lines; 02 emits 1 literal `- (vault walk — no candidate inputs; 02 is direct-apply)` line; 03/04 emit `mutations: none` + `report_section:` + no `inputs:` field (test_applied_log_apply_schema.sh + test_applied_log_advisory_schema.sh both PASS).
- **BRWN-15 (02 magic-string lock)**: `grep -cE '\[prov:bootstrap\]|\[epistemic:: imported\]|\[epistemic:: bootstrapped\]' 02-provenance-bootstrap.sh` → 0. Only `[epistemic:: inferred]` emitted.
- **BRWN-16 (no LLM calls)**: `grep -rE '(curl|wget|openai|anthropic|gpt-|chatgpt)' schema/brownfield/migrations/*.sh` → nothing.

## Self-Check: PASSED

---
*Phase: 11-brownfield-suggest-verify*
*Completed: 2026-04-21*
