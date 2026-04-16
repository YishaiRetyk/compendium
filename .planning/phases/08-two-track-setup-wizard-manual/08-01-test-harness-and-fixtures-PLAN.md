---
phase: 08-two-track-setup-wizard-manual
plan: 01
type: execute
wave: 0
depends_on: []
files_modified:
  - tests/phase-08/run.sh
  - tests/phase-08/lib.sh
  - tests/phase-08/fixtures/.gitkeep
  - schema/fixtures/canonical-answers.yaml
  - schema/fixtures/canonical-AGENTS.md
  - schema/fixtures/README.md
  - .gitattributes
autonomous: true
requirements:
  - WZRD-01
  - WZRD-07
  - MANUAL-06
must_haves:
  truths:
    - "Test aggregator tests/phase-08/run.sh exists, mirrors phase-07 contract, and exits 0 on empty/skipped suite"
    - "schema/fixtures/canonical-answers.yaml exists with the 6-answer canonical set per RESEARCH.md Example 2 + Open Question 2 resolution"
    - "schema/fixtures/canonical-AGENTS.md exists as the byte-frozen expected render of canonical-answers.yaml against schema/AGENTS.template.md (0 leftover {{...}} tokens)"
    - "schema/fixtures/README.md exists documenting the cloud_safe fixture-vs-local_only-wizard-default deviation (review concern #1) and the template-mtime→fixture-regeneration rule (review concern #13)"
    - ".gitattributes pins schema/fixtures/canonical-AGENTS.md and schema/fixtures/canonical-answers.yaml to eol=lf to prevent CRLF drift on Windows clones"
  artifacts:
    - path: tests/phase-08/run.sh
      provides: "Phase-08 test aggregator (mirrors tests/phase-07/run.sh contract)"
      contains: "PHASE 08 TESTS:"
    - path: tests/phase-08/lib.sh
      provides: "Shared bash test helpers (mktemp_repo, cleanup trap, assert_eq, assert_grep)"
    - path: schema/fixtures/canonical-answers.yaml
      provides: "Canonical YAML answer set used by MANUAL-06 byte-equality test"
    - path: schema/fixtures/canonical-AGENTS.md
      provides: "Byte-frozen expected wizard render output"
    - path: schema/fixtures/README.md
      provides: "Rationale for cloud_safe fixture tier and fixture-regeneration rule"
      contains: "cloud_safe"
    - path: .gitattributes
      provides: "EOL pinning for byte-equality fixtures"
      contains: "schema/fixtures/canonical-AGENTS.md text eol=lf"
  key_links:
    - from: schema/fixtures/canonical-answers.yaml
      to: schema/fixtures/canonical-AGENTS.md
      via: "wizard render (Plan 02 + 03 will produce this; Plan 01 commits the expected output by pre-rendering with python3)"
      pattern: "knowledge_domain: \"personal-knowledge\""
    - from: schema/fixtures/README.md
      to: bin/release.sh
      via: "documents the privacy-leak regex that motivates cloud_safe fixture choice"
      pattern: "release\\.sh"
---

<objective>
Wave-0 test infrastructure for Phase 8: aggregator script mirroring tests/phase-07/run.sh, shared helpers, the two byte-equality fixtures (`schema/fixtures/canonical-answers.yaml` + `schema/fixtures/canonical-AGENTS.md`), a fixtures README documenting the `cloud_safe` deviation + regeneration rule, and `.gitattributes` EOL pinning. This plan establishes the test harness and the fixture pair that all subsequent plans verify against.

Purpose: Establish the deterministic byte-equality contract upfront so Plans 02–05 cannot accidentally drift the wizard output away from the manual-setup target. Per RESEARCH.md Pitfall 1 (M-1/M-3) the byte-equality CI test is the drift mitigation; per Pitfall 2 the .gitattributes pin prevents CRLF surprises across platforms.

Output: tests/phase-08/ harness skeleton + 2 schema fixtures + fixtures README + .gitattributes entry, all committed and ready for Plans 02–05 to wire tests into.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md
@.planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md
@schema/AGENTS.template.md
@tests/phase-07/run.sh

<interfaces>
<!-- Pre-existing test aggregator contract (Phase 7) — Plan 01 mirrors this exactly -->

From tests/phase-07/run.sh:
- Iterates tests/phase-NN/test_*.sh via shopt -s nullglob
- Per-test: echo "--- Running NAME ---", bash $t, echo "--- PASS|FAIL NAME ---"
- Final: "PHASE NN TESTS: PASS/TOTAL", non-zero exit if any FAIL
- --full flag accepted as no-op (P1 reservation)

Placeholder set in schema/AGENTS.template.md (per RESEARCH.md WZRD-07 row, verified):
- Line 32:  This file (`{{AGENT_FILENAME}}`) ...
- Line 56:  ├── AGENTS.template.md          # Wizard source ({{PRIMARY_DOMAIN}} etc.)
- Line 588: knowledge_domain: "{{PRIMARY_DOMAIN}}"
- Line 589: privacy_default: {{DEFAULT_PRIVACY}}
- Line 848: The default staleness decay profile is `{{DECAY_PROFILE}}` ...

Canonical answer set (from RESEARCH.md §Specifics + Example 2, with Open Question 2 resolution):
- maintainer_name: "Template Maintainer"
- primary_domain: "personal-knowledge"
- agent: "claude-code" → resolves AGENT_FILENAME to "CLAUDE.md"
- default_privacy: "cloud_safe"   # CHANGED from local_only per Open Q2 to avoid release.sh privacy-leak regex on rendered fixture
- decay_profile: "default"
- obsidian: true
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create tests/phase-08/ harness (run.sh + lib.sh + fixtures/.gitkeep)</name>
  <files>tests/phase-08/run.sh, tests/phase-08/lib.sh, tests/phase-08/fixtures/.gitkeep</files>
  <read_first>
    - tests/phase-07/run.sh (canonical aggregator to mirror byte-for-byte except phase number string)
    - bin/sync-claude.sh (zero-dep bash idiom reference for set -euo pipefail + cmp -s usage)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Validation Architecture (lines 633–681)
  </read_first>
  <action>
1. Create `tests/phase-08/run.sh` as a byte-for-byte structural copy of `tests/phase-07/run.sh` with these exact differences:
   - Replace the comment header `# tests/phase-07/run.sh -- Phase 07 test aggregator (Wave 0 harness).` with `# tests/phase-08/run.sh -- Phase 08 test aggregator (Wave 0 harness for wizard + manual track tests).`
   - Replace `Usage: tests/phase-07/run.sh` with `Usage: tests/phase-08/run.sh`
   - Replace the final `echo "PHASE 07 TESTS: ${PASS}/${TOTAL}"` with `echo "PHASE 08 TESTS: ${PASS}/${TOTAL}"`
   - All other lines (set -euo pipefail, FULL=0 flag handling, SCRIPT_DIR resolution, shopt -s nullglob loop, FAILED_TESTS array, per-test echo banners, exit-code propagation) MUST be identical.
2. `chmod +x tests/phase-08/run.sh`
3. Create `tests/phase-08/lib.sh` (sourced by future test_*.sh files) with these exported helpers:
   - `set -euo pipefail` at top
   - `REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"`
   - `mktemp_repo()` — creates a tempdir, registers cleanup via trap, echoes the path. Caller does `WORK=$(mktemp_repo)`.
   - `cleanup_tempdirs()` — removes registered tempdirs. Tracked via `TEMP_DIRS=()` global array.
   - `assert_eq()` — `assert_eq <expected> <actual> <message>`; echoes "ASSERT FAIL: $3 (expected: $1 / got: $2)" and exits 1 on mismatch.
   - `assert_grep()` — `assert_grep <pattern> <file> <message>`; runs `grep -qE "$1" "$2"` and exits 1 with message on no match.
   - `assert_no_grep()` — inverse: exits 1 if pattern matches.
   - `assert_file_exists()` — exits 1 if `[ ! -f "$1" ]`.
   - `assert_byte_equal()` — uses `cmp -s "$1" "$2"`; on mismatch echoes `diff -u "$1" "$2"` head -50 then exits 1.
   - Trap registration: `trap 'cleanup_tempdirs' EXIT INT TERM`
4. Create `tests/phase-08/fixtures/` directory with an empty `.gitkeep` file (needed for git to track the empty dir; future plans may add fixture repo skeletons).
5. Verify aggregator runs cleanly with zero tests: `bash tests/phase-08/run.sh` must exit 0 and print `PHASE 08 TESTS: 0/0` (Phase 7 aggregator behavior on empty test set — confirm via reading Phase 7 source).
  </action>
  <verify>
    <automated>bash tests/phase-08/run.sh && test -x tests/phase-08/run.sh && bash -n tests/phase-08/lib.sh && grep -q "PHASE 08 TESTS" tests/phase-08/run.sh && test -f tests/phase-08/fixtures/.gitkeep</automated>
  </verify>
  <acceptance_criteria>
    - `tests/phase-08/run.sh` exists, is executable (`test -x`), and exits 0 with stdout containing `PHASE 08 TESTS: 0/0` when no test_*.sh files present.
    - `tests/phase-08/lib.sh` syntax-clean (`bash -n` exits 0) and defines all 7 helpers (grep -qE for `^(mktemp_repo|cleanup_tempdirs|assert_eq|assert_grep|assert_no_grep|assert_file_exists|assert_byte_equal)\(\)` matches all 7).
    - `tests/phase-08/fixtures/.gitkeep` exists.
    - run.sh diff vs phase-07: only header-comment, usage-string, and final "PHASE 0N TESTS:" line differ (SEMANTIC PARITY per review concern #12 — no exact line-count pin). Verify with: `diff tests/phase-07/run.sh tests/phase-08/run.sh | grep -E '^[<>]' | grep -v -E '(phase-07|phase-08|PHASE 07|PHASE 08)' | wc -l` returns `0` (i.e., every differing line contains one of the four expected tokens).
  </acceptance_criteria>
  <done>Phase-08 test harness exists, mirrors Phase 7 contract, lib.sh helpers defined, empty aggregator passes.</done>
</task>

<task type="auto">
  <name>Task 2: Commit canonical fixtures + fixtures README + .gitattributes EOL pin</name>
  <files>schema/fixtures/canonical-answers.yaml, schema/fixtures/canonical-AGENTS.md, schema/fixtures/README.md, .gitattributes</files>
  <read_first>
    - schema/AGENTS.template.md (full file — needed to produce the byte-frozen render at lines 32, 56, 588, 589, 848)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Open Questions Q2 (privacy fixture rationale) and §Code Examples Example 2 (.wizard-answers.yaml shape)
    - .planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md §Specifics (canonical-answers fixture contents — but apply Open Q2 override: privacy → cloud_safe)
    - bin/release.sh (read the privacy-leak regex `^privacy:[[:space:]]*local_only` to confirm canonical-AGENTS.md will not match AND to cite the exact regex in schema/fixtures/README.md)
  </read_first>
  <action>
1. Write `schema/fixtures/canonical-answers.yaml` with EXACTLY this content (UTF-8, LF line endings, trailing newline):
```
# Canonical answer set for Phase 8 byte-equality CI test (MANUAL-06).
# Used by: bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml
# Expected render: schema/fixtures/canonical-AGENTS.md (byte-equal)
# See schema/fixtures/README.md for the cloud_safe-vs-local_only rationale.
# DO NOT EDIT without regenerating canonical-AGENTS.md and updating tests.
wizard_version: "1.1.0"
generated_at: "2026-04-16T00:00:00Z"
template_sha: "<frozen-fixture>"
answers:
  maintainer_name: "Template Maintainer"
  primary_domain: "personal-knowledge"
  agent: "claude-code"
  default_privacy: "cloud_safe"
  decay_profile: "default"
  obsidian: true
```
   Rationale for `default_privacy: "cloud_safe"` (NOT `local_only` from CONTEXT.md §Specifics) is documented in `schema/fixtures/README.md` (step 3 below) per review concern #1.

2. Produce `schema/fixtures/canonical-AGENTS.md` by deterministically rendering `schema/AGENTS.template.md` with these 4 substitutions (literal `str.replace` in this exact order):
   - `{{AGENT_FILENAME}}` → `CLAUDE.md` (because answers.agent == "claude-code")
   - `{{PRIMARY_DOMAIN}}` → `personal-knowledge`
   - `{{DEFAULT_PRIVACY}}` → `cloud_safe`
   - `{{DECAY_PROFILE}}` → `default`
   Use this exact one-shot python3 command (run once during plan execution to generate the fixture):
   ```
   python3 -c '
   import sys
   src = open("schema/AGENTS.template.md", encoding="utf-8").read()
   subs = {
     "{{AGENT_FILENAME}}":  "CLAUDE.md",
     "{{PRIMARY_DOMAIN}}":  "personal-knowledge",
     "{{DEFAULT_PRIVACY}}": "cloud_safe",
     "{{DECAY_PROFILE}}":   "default",
   }
   for k, v in subs.items():
     src = src.replace(k, v)
   import re
   leftover = re.findall(r"\{\{[A-Z_]+\}\}", src)
   if leftover:
     sys.exit(f"ERROR: leftover placeholders: {leftover}")
   open("schema/fixtures/canonical-AGENTS.md", "w", encoding="utf-8", newline="\n").write(src)
   '
   ```
   File MUST end with exactly one `\n` matching the source template's terminator.

   **IMPORTANT (review concern #13):** The canonical-answers→canonical-AGENTS render routine used here MUST match the wizard's Plan 02 render routine byte-for-byte. When Plan 02 ships, a downstream check verifies `cmp -s` holds between (a) this pre-rendered fixture and (b) `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to <tmp>` output. If the two routines diverge, Plan 02 CI fails and this fixture must be regenerated via the wizard's render routine (not this inline python3 block).

3. Create `schema/fixtures/README.md` (NEW file — review concern #1 + #13) with this exact content:
```markdown
# schema/fixtures/ — Canonical Byte-Equality Fixtures

These files are the byte-frozen contract between the **wizard track** (`bin/init-wizard.sh`) and the **manual track** (`docs/manual-setup.md`). CI (`.github/workflows/setup-parity.yml`) enforces byte-equality between the wizard's render and `canonical-AGENTS.md`.

## Files

- **`canonical-answers.yaml`** — the 6-answer input set
- **`canonical-AGENTS.md`** — the byte-frozen expected render of `schema/AGENTS.template.md` with `canonical-answers.yaml` applied

## Why `default_privacy: cloud_safe` (not `local_only`)

The wizard's **default** for the privacy tier prompt is `local_only` (per D-11, matching the schema's conservative privacy posture). This fixture intentionally uses `cloud_safe` instead.

**Reason:** `bin/release.sh` contains a neutrality/privacy-leak regex that rejects any file shipped in the public release containing `^privacy:[[:space:]]*local_only`. Since `canonical-AGENTS.md` ships publicly (it is the template-repo fixture), rendering it with `local_only` would make the release script reject the repo's own fixture.

Keeping the fixture at `cloud_safe` lets the public template release without contortion while preserving the wizard's `local_only` default for end users' own private repos.

**This is a deliberate deviation from the wizard default.** Hand-editors following `docs/manual-setup.md` who want byte-parity with this fixture MUST use `cloud_safe`. Hand-editors personalizing for a private repo should substitute `local_only` and accept that their output will differ from this fixture (which is fine — their repo's CI is their own).

See also: `bin/release.sh` (the `^privacy:[[:space:]]*local_only` regex near the neutrality-check block).

## Regeneration Rule

Whenever `schema/AGENTS.template.md` changes, `canonical-AGENTS.md` MUST be regenerated so the fixture stays in sync with the template.

**Regeneration command (same render routine as the wizard):**

```bash
bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
git add schema/fixtures/canonical-AGENTS.md
git commit -m "fixtures: regenerate canonical-AGENTS.md after template change"
```

**Mechanical enforcement (CI):** If `schema/AGENTS.template.md` is modified in a commit without a matching regeneration of `schema/fixtures/canonical-AGENTS.md`, the `.github/workflows/setup-parity.yml` byte-equality job fails. This is the drift-prevention gate.

## EOL Pinning

`.gitattributes` pins both files to `eol=lf` to prevent CRLF drift on Windows checkouts. See RESEARCH.md Pitfall 2 (M-2 mitigation).
```

4. Append to (or create) `.gitattributes` at repo root with these exact lines (preserve any existing content; append idempotently). Also add `schema/fixtures/README.md` so the README itself is LF-pinned:
```
# Phase 8 byte-equality fixtures — pin LF to prevent CRLF drift on Windows checkouts (M-2 mitigation).
schema/fixtures/canonical-AGENTS.md text eol=lf
schema/fixtures/canonical-answers.yaml text eol=lf
schema/fixtures/README.md text eol=lf
```
   If `.gitattributes` already exists, check first that these lines are not already present (idempotent).

5. After writing, verify: zero leftover `{{...}}` tokens in canonical-AGENTS.md (`! grep -E '\{\{[A-Z_]+\}\}' schema/fixtures/canonical-AGENTS.md`); no `^privacy:[[:space:]]*local_only` match in canonical-AGENTS.md (release.sh regex); the rendered file's `knowledge_domain:` line equals `knowledge_domain: "personal-knowledge"` exactly; `schema/fixtures/README.md` contains literal strings `cloud_safe`, `local_only`, and `Regeneration Rule`.

6. Run the existing neutrality + Phase 7 suites to confirm no regression: `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh`.
  </action>
  <verify>
    <automated>test -f schema/fixtures/canonical-answers.yaml && test -f schema/fixtures/canonical-AGENTS.md && test -f schema/fixtures/README.md && ! grep -qE '\{\{[A-Z_]+\}\}' schema/fixtures/canonical-AGENTS.md && ! grep -qE '^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$' schema/fixtures/canonical-AGENTS.md && grep -q 'knowledge_domain: "personal-knowledge"' schema/fixtures/canonical-AGENTS.md && grep -q 'This file (`CLAUDE.md`)' schema/fixtures/canonical-AGENTS.md && grep -q 'schema/fixtures/canonical-AGENTS.md text eol=lf' .gitattributes && grep -q 'schema/fixtures/canonical-answers.yaml text eol=lf' .gitattributes && grep -q 'schema/fixtures/README.md text eol=lf' .gitattributes && grep -q 'cloud_safe' schema/fixtures/README.md && grep -q 'Regeneration Rule' schema/fixtures/README.md && grep -q 'release\.sh' schema/fixtures/README.md && bash bin/check-neutrality.sh && bash tests/phase-07/run.sh</automated>
  </verify>
  <acceptance_criteria>
    - `schema/fixtures/canonical-answers.yaml` exists, contains literal lines `maintainer_name: "Template Maintainer"`, `primary_domain: "personal-knowledge"`, `agent: "claude-code"`, `default_privacy: "cloud_safe"`, `decay_profile: "default"`, `obsidian: true`.
    - `schema/fixtures/canonical-AGENTS.md` exists, has zero `{{...}}` tokens (grep returns 1 = no match).
    - `schema/fixtures/canonical-AGENTS.md` does NOT match `^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$` (release.sh leak regex passes).
    - `schema/fixtures/canonical-AGENTS.md` contains `knowledge_domain: "personal-knowledge"` (line 588 substitution verified) and `This file (\`CLAUDE.md\`) is the canonical agent spec` (line 32 substitution verified).
    - `schema/fixtures/README.md` exists, contains literals `cloud_safe`, `local_only`, `Regeneration Rule`, and `release.sh` (review concern #1 + #13 addressed).
    - `.gitattributes` contains all 3 new `text eol=lf` entries (idempotent append).
    - `bash bin/check-neutrality.sh` exits 0 (no Kahneman/personal-content tokens introduced).
    - `bash tests/phase-07/run.sh` exits 0 (no regression).
    - File ends with exactly one trailing newline: `[ "$(tail -c 1 schema/fixtures/canonical-AGENTS.md | xxd -p)" = "0a" ]`.
  </acceptance_criteria>
  <done>Byte-frozen canonical fixtures committed; fixtures README documents cloud_safe deviation + regeneration rule; .gitattributes pinned LF; neutrality + Phase 7 suites still green; future Plans 02–05 have a stable comparison target.</done>
</task>

</tasks>

<verification>
After both tasks:
1. `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 0/0`.
2. `cmp -s schema/fixtures/canonical-AGENTS.md <python3 re-render from current schema/AGENTS.template.md with the 4 fixture substitutions>` — zero diff (idempotent regen).
3. `bash bin/check-neutrality.sh` exits 0.
4. `bash tests/phase-07/run.sh` exits 0.
5. Git status shows: tests/phase-08/run.sh, tests/phase-08/lib.sh, tests/phase-08/fixtures/.gitkeep, schema/fixtures/canonical-answers.yaml, schema/fixtures/canonical-AGENTS.md, schema/fixtures/README.md, .gitattributes.
</verification>

<success_criteria>
- Phase-08 aggregator parity with Phase 07 contract (verified by semantic diff — review concern #12).
- Two canonical fixtures committed and pass neutrality + privacy-leak regex checks.
- `schema/fixtures/README.md` documents the cloud_safe deviation and regeneration rule (review concerns #1 + #13).
- `.gitattributes` prevents CRLF byte drift on cross-platform checkouts (M-2 mitigation).
- All later plans (02–05) can `cmp -s` against `schema/fixtures/canonical-AGENTS.md` as the immovable contract.
</success_criteria>

<output>
After completion, create `.planning/phases/08-two-track-setup-wizard-manual/08-01-SUMMARY.md` capturing: rendered fixture line count, the 4 substitutions verified at lines 32/56/588/589/848, .gitattributes append confirmation, neutrality regex pass-through, and the schema/fixtures/README.md rationale block.
</output>
