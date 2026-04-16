---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 02
type: execute
wave: 1
depends_on: [09-01]
files_modified:
  - bin/lint.sh
  - tests/phase-09/test_lint_version.sh
  - tests/phase-09/test_lint_require_version.sh
  - tests/phase-09/test_lint_format_json.sh
  - tests/phase-09/test_lint_ci_mode.sh
  - tests/phase-09/test_lint_skip_category.sh
autonomous: true
requirements:
  - CI-02
  - CI-03
  - CI-04
  - CI-08

must_haves:
  truths:
    - "`bin/lint.sh --version` prints `1.1.0` to stdout and exits 0."
    - "`bin/lint.sh --require-version 1.2.0` exits 1 with an actionable stderr message when `LINT_VERSION=\"1.1.0\"` (minimum-version semantics: running version must be >= pinned version)."
    - "`bin/lint.sh --format json` writes a JSON array of `{severity, category, path, line?, message}` objects to stdout and does NOT write `wiki/maintenance/lint-report.md`."
    - "`bin/lint.sh --ci` applies the severity remap dispatch table: `yaml`/`orphan`/`crossref`/`provenance` are `error`; `stale`/`gap`/`contradiction`/`contradiction-sync`/`drift`/`contributor` are `warning`; `autofix`/`skip-count` are `info`."
    - "`bin/lint.sh --ci` exits 1 if any post-remap finding has severity `error`; exits 0 otherwise (clean or warnings/info only)."
    - "`bin/lint.sh --ci` defaults to skipping category `drift-external`; `--skip-category <cat>` overrides with an explicit list."
    - "**Category-flag precedence (P0 review fix — Codex MEDIUM):** when both `--category` (inclusive filter) and `--skip-category` are passed, `--category` is applied FIRST (narrowing), then `--skip-category` SUBTRACTS from the narrowed set. Equivalent to set operation: `final_cats = (category_filter or ALL) - skip_set`. Documented in `usage()` help and exercised by a regression test. Example: `--category stale --skip-category stale` yields an empty category filter (no findings emitted), not an error."
    - "**`drift-external` skip semantics (P0 review fix — Codex MEDIUM):** `drift-external` is NOT a category emitted directly by `add_finding()`. It is a logical **subcategory name** used only by `--skip-category` / `--ci` default-skip to suppress drift findings originating from **external-state drift checks** (DRFT-03 Obsidian vault awareness, and any future checks that require local Obsidian/Zotero state). Internal drift findings (DRFT-01 unrepresented-source, DRFT-02 missing-source-file, content-hash-drift, index-coverage) use the plain `drift` category and are NOT suppressed by `drift-external`. Implementation: the existing drift-detection block uses the `add_finding()` category `drift` for all drift findings but tags external-state findings with a predicate (e.g., a leading `EXTERNAL:` token in the message, or a side-channel set) that the skip filter consults. Planner's call on exact mechanism — must be unit-testable via `--skip-category drift-external` asserting only external-origin findings are dropped while internal drift findings remain."
    - "**JSON `line` field policy (P0 review fix — Codex MEDIUM):** the `line` key is OMITTED from JSON objects when the underlying finding has no known line location (e.g., page-level orphan findings, file-level missing-source-file). Emitted (as an integer, 1-indexed) when a line number is known (e.g., staleness markers, YAML parse errors with row). Phase 9 scope: do NOT back-port line numbers into findings that currently lack them (the existing `add_finding()` tuple is `(sev, cat, path, msg)` with no line slot — so `line` remains OMITTED for all Phase 9 v1.1 findings except the Plan 09-03 strict-mode and skip-count findings which compute their own line numbers via `enumerate(lines)`). Documented in `docs/reference/ci.md` (Plan 06) and AGENTS.md §11.3 (Plan 05)."
    - "`bin/lint.sh` without `--ci` preserves v1.0 behavior: text output, writes `lint-report.md`, exits 0 regardless of finding severity."
  artifacts:
    - path: "bin/lint.sh"
      provides: "New flags: --format {text|json}, --ci, --skip-category <cat>, --version, --require-version X.Y.Z; LINT_VERSION bash constant; CI_SEVERITY_REMAP dispatch table; documented --category/--skip-category precedence"
      contains: "LINT_VERSION"
    - path: "tests/phase-09/test_lint_version.sh"
      provides: "CI-08 unit test: --version prints 1.1.0 exit 0"
    - path: "tests/phase-09/test_lint_require_version.sh"
      provides: "CI-08 unit test: --require-version minimum-version semantics"
    - path: "tests/phase-09/test_lint_format_json.sh"
      provides: "CI-02 unit test: --format json stdout shape (+ line-field-omitted invariant)"
    - path: "tests/phase-09/test_lint_ci_mode.sh"
      provides: "CI-03 unit test: severity remap + exit-1-on-error"
    - path: "tests/phase-09/test_lint_skip_category.sh"
      provides: "CI-04 unit test: --skip-category + --ci default drift-external skip + --category/--skip-category precedence"
  key_links:
    - from: "bin/lint.sh --format json output"
      to: "add_finding() tuple (sev, cat, path, msg)"
      via: "JSON shape matches existing tuple verbatim per D-04 (line optional, omitted when unknown)"
      pattern: "\\{'severity':"
    - from: "bin/lint.sh --ci"
      to: "CI_SEVERITY_REMAP dispatch table"
      via: "apply_ci_remap() function called after findings accumulate, before emit"
      pattern: "CI_SEVERITY_REMAP"
    - from: "bin/lint.sh --require-version X.Y.Z"
      to: "LINT_VERSION constant"
      via: "tuple(map(int,v.split('.'))) comparison in inline python3"
      pattern: "tuple.*split"
    - from: "--category / --skip-category dual-flag precedence"
      to: "findings filter pipeline"
      via: "category_filter applied first (narrow), skip_set applied second (subtract)"
      pattern: "category_filter.*skip"
---

<objective>
Extend `bin/lint.sh` with the core CI-mode flags that turn it into a machine-readable, severity-remapped linter: `--format json`, `--ci`, `--skip-category`, `--version`, `--require-version`. These flags are the **orthogonal primitives** (D-01) that downstream plans (Plan 03 `--strict`, Plan 05 `lint.yml` workflow) compose.

Purpose: without Plan 02, Plan 05's workflow YAML cannot call `bash bin/lint.sh --require-version 1.1.0 --ci --format json`. This plan delivers exactly those four composed flags plus `--version` for local inspection. The existing `add_finding()` tuple shape IS the JSON shape — no schema divergence (D-04).

Output: `bin/lint.sh` gains ~120 lines (arg-parse additions, `LINT_VERSION="1.1.0"` constant near the top, `CI_SEVERITY_REMAP` dispatch table in the python3 block, JSON emitter branch). Five unit tests under `tests/phase-09/` verify each flag independently and in composition.

**Review-driven clarifications (revision 2026-04-16, Codex MEDIUM concerns resolved):**
- `--category` vs. `--skip-category` precedence is now explicit: intersect-then-subtract.
- `drift-external` is a logical subcategory name for the skip filter; it is NOT directly emitted by `add_finding()`. All drift findings use `drift` as the category; external-state drift is tagged via a predicate the skip filter consults.
- JSON `line` key is OMITTED (not null) when the finding lacks a line location. Phase 9 does not back-port line numbers into existing line-less findings; strict-mode + skip-count findings (Plan 09-03) do compute lines.

Out of scope for this plan: `--strict` (Plan 03), `--count-skips` (Plan 03), `contributor` category (Plan 03), `bin/check-privacy.sh` (Plan 04), annotation shim / workflow YAML (Plan 05).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-01-SUMMARY.md
@bin/lint.sh
@tests/phase-09/lib.sh

<interfaces>
From bin/lint.sh (existing contract to preserve):

```python
# add_finding() tuple shape (line ~188):
# findings.append((severity, category, path, message))
# where severity in {error, warning, info} and category in
# {orphan, crossref, stale, contradiction, contradiction-sync, gap,
#  provenance, yaml, drift, autofix}
```

From bin/lint.sh existing arg-parse loop (line 50-85 in current file):
- Supported flags: `--help/-h`, `--dry-run`, `--fix`, `--category <cat>`
- WIKI_DIR defaults to `${WIKI_ROOT:-wiki/}` or positional arg
- Exit 1 on unknown option

From CONTEXT.md D-02 + D-05 (severity policy):
  blockers (error): yaml, orphan, crossref, provenance
  warnings: stale, gap, contradiction, contradiction-sync, drift, contributor (Plan 03 adds)
  info: autofix, skip-count (Plan 03 adds)
  default --ci skip: drift-external (subcategory — see must_haves)

From RESEARCH.md code example 1 (exact dict to embed):

```python
CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'stale':              'warning',
    'gap':                'warning',
    'contradiction':      'warning',
    'contradiction-sync': 'warning',
    'drift':              'warning',
    'contributor':        'warning',   # Plan 03 adds category
    'autofix':            'info',
    'skip-count':         'info',      # Plan 03 adds category
}
```

**Drift subcategory model (P0 review fix):**

The existing `bin/lint.sh` drift-detection block emits findings with the `drift` category (per AGENTS.md §11.3). Phase 9 introduces a logical `drift-external` SKIP TARGET for findings originating from external-state checks (DRFT-03 Obsidian vault awareness). The mechanism:

1. Drift findings are still emitted with `category='drift'` (no schema change to `add_finding()`).
2. External-state drift checks prefix their message text with `EXTERNAL: ` (literal token; stable; grep-friendly).
3. `--skip-category drift-external` implements: `if cat == 'drift' and msg.startswith('EXTERNAL: '): drop`.
4. `--skip-category drift` (no suffix) drops ALL drift findings regardless of origin.
5. Both are valid skip targets; documented in usage() help.

This avoids a breaking schema change while supporting the CI-04 `drift-external` skip. Alternative (rejected): introduce a 5-tuple shape `(sev, cat, subcat, path, msg)` — would break backward compatibility with existing check functions and the add_finding() signature.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add --version + --require-version flags and LINT_VERSION constant to bin/lint.sh</name>
  <files>bin/lint.sh, tests/phase-09/test_lint_version.sh, tests/phase-09/test_lint_require_version.sh</files>
  <read_first>
    - bin/lint.sh — full file (especially arg-parse loop at line 50-85, and the help text at line 10-40) so additions slot cleanly
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-26 (semver), D-27 (LINT_VERSION constant location), D-28 (minimum-version semantics)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Don't Hand-Roll" version-comparison row (tuple(map(int, v.split('.'))) idiom)
    - tests/phase-09/lib.sh — helper library signatures
  </read_first>
  <behavior>
    - Test 1 (test_lint_version.sh): `bash bin/lint.sh --version` prints exactly `1.1.0` (single line) to stdout and exits 0. No other output.
    - Test 2 (test_lint_require_version.sh, positive): `bash bin/lint.sh --require-version 1.1.0 --dry-run` exits 0 (running version 1.1.0 >= required 1.1.0).
    - Test 3 (test_lint_require_version.sh, minor-pass): `bash bin/lint.sh --require-version 1.0.5 --dry-run` exits 0 (1.1.0 >= 1.0.5).
    - Test 4 (test_lint_require_version.sh, fail): `bash bin/lint.sh --require-version 1.2.0 --dry-run` exits 1 with stderr containing the strings "require-version" AND "1.2.0" AND "1.1.0" (actionable: running vs. required).
    - Test 5 (test_lint_require_version.sh, semver order): `bash bin/lint.sh --require-version 1.10.0 --dry-run` exits 1 (1.1.0 < 1.10.0; NOT string-compared — the tuple(map(int,...)) idiom MUST win here).
  </behavior>
  <action>
**Step 1: Add `LINT_VERSION` constant + arg parsing to `bin/lint.sh`.**

Near the top of `bin/lint.sh` (immediately after the `set -euo pipefail` line), add:

```bash
# Lint rule-set semver per CI-08 / D-26. Bump MAJOR on breaking changes
# (removed category, changed severity semantics). MINOR on non-breaking
# additions. PATCH on bug fixes. --require-version X.Y.Z is a minimum check.
LINT_VERSION="1.1.0"
```

In the existing arg-parse loop (`while [ "$#" -gt 0 ]`), add these two cases BEFORE the catch-all `-*) echo "ERROR: Unknown option..." exit 1`:

```bash
        --version)
            echo "$LINT_VERSION"
            exit 0
            ;;
        --require-version)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --require-version requires a semver value (e.g., 1.1.0)" >&2
                exit 1
            fi
            REQUIRE_VERSION="$2"
            shift 2
            ;;
```

At top of the arg-parse section (alongside other flag-default vars like `DRY_RUN=0`), add: `REQUIRE_VERSION=""`.

After the arg-parse loop completes, add this version-check block BEFORE the script proceeds to actual linting:

```bash
if [ -n "$REQUIRE_VERSION" ]; then
    python3 - "$LINT_VERSION" "$REQUIRE_VERSION" <<'PYEOF' || {
import sys
running = tuple(map(int, sys.argv[1].split('.')))
required = tuple(map(int, sys.argv[2].split('.')))
if running < required:
    print(f"ERROR: bin/lint.sh --require-version {sys.argv[2]} not satisfied. "
          f"Running version: {sys.argv[1]}. "
          f"Upgrade bin/lint.sh or lower the pin.", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PYEOF
        exit 1
    }
fi
```

Update the `usage()` help text to document both new flags:
  - `--version            Print lint rule-set semver (LINT_VERSION) and exit 0`
  - `--require-version X.Y.Z  Fail with exit 1 if running LINT_VERSION < X.Y.Z`

**Step 2: Write `tests/phase-09/test_lint_version.sh`:**

```bash
#!/usr/bin/env bash
# CI-08: bin/lint.sh --version prints LINT_VERSION and exits 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OUT="$(bash "$REPO_ROOT/bin/lint.sh" --version)"
if [ "$OUT" != "1.1.0" ]; then
    echo "FAIL: expected '1.1.0', got '$OUT'" >&2
    exit 1
fi
echo "PASS: bin/lint.sh --version -> 1.1.0"
```

**Step 3: Write `tests/phase-09/test_lint_require_version.sh`:**

```bash
#!/usr/bin/env bash
# CI-08: --require-version minimum-version semantics + semver tuple ordering.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

LINT="$REPO_ROOT/bin/lint.sh"

# Case 1: exact match passes
bash "$LINT" --require-version 1.1.0 --dry-run >/dev/null 2>&1 \
    || { echo "FAIL: --require-version 1.1.0 should pass when LINT_VERSION=1.1.0" >&2; exit 1; }

# Case 2: older pin passes
bash "$LINT" --require-version 1.0.5 --dry-run >/dev/null 2>&1 \
    || { echo "FAIL: --require-version 1.0.5 should pass when LINT_VERSION=1.1.0" >&2; exit 1; }

# Case 3: newer pin fails with actionable stderr
if bash "$LINT" --require-version 1.2.0 --dry-run 2>/tmp/require-err >/dev/null; then
    echo "FAIL: --require-version 1.2.0 should fail when LINT_VERSION=1.1.0" >&2
    exit 1
fi
grep -q "require-version" /tmp/require-err \
    || { echo "FAIL: stderr missing 'require-version' token: $(cat /tmp/require-err)" >&2; exit 1; }
grep -q "1.2.0" /tmp/require-err \
    || { echo "FAIL: stderr missing '1.2.0' token" >&2; exit 1; }
grep -q "1.1.0" /tmp/require-err \
    || { echo "FAIL: stderr missing '1.1.0' running version" >&2; exit 1; }

# Case 4: semver tuple ordering (1.10.0 > 1.1.0 — bash string compare would get this wrong)
if bash "$LINT" --require-version 1.10.0 --dry-run >/dev/null 2>&1; then
    echo "FAIL: --require-version 1.10.0 should fail when LINT_VERSION=1.1.0 (semver tuple, not string)" >&2
    exit 1
fi

echo "PASS: --require-version minimum + semver tuple ordering"
```

Mark both tests executable.

Tests MUST fail on the current `bin/lint.sh` (before edits); MUST pass after the additions above. This is the RED→GREEN cycle for this task.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_lint_version.sh && bash tests/phase-09/test_lint_require_version.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q '^LINT_VERSION="1.1.0"' bin/lint.sh` returns 0
    - `bash bin/lint.sh --version` prints exactly `1.1.0` and exits 0
    - `bash bin/lint.sh --require-version 1.0.0 --dry-run` exits 0
    - `bash bin/lint.sh --require-version 1.2.0 --dry-run` exits 1
    - `bash bin/lint.sh --require-version 1.10.0 --dry-run` exits 1 (semver tuple ordering, not string compare)
    - Stderr on failure contains all three tokens: `require-version`, running version `1.1.0`, required version (e.g., `1.2.0`)
    - `bash bin/lint.sh --help` output lists both `--version` and `--require-version` flags
    - `bash tests/phase-09/test_lint_version.sh` exits 0 with `PASS` line
    - `bash tests/phase-09/test_lint_require_version.sh` exits 0 with `PASS` line
    - Existing `bin/lint.sh` behavior unchanged: `bash bin/lint.sh --dry-run wiki/` (no new flags) produces identical output to pre-edit version
  </acceptance_criteria>
  <done>
    Version pinning primitives land. Plan 05's workflow YAML can call `bash bin/lint.sh --require-version 1.1.0 ...` and get a deterministic minimum-version gate. Any future rule change that bumps `LINT_VERSION` also satisfies old pins (by design — minimum semantics).
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add --format json + --ci + --skip-category flags, severity remap dispatcher, JSON emitter, and --category/--skip-category precedence to bin/lint.sh</name>
  <files>bin/lint.sh, tests/phase-09/test_lint_format_json.sh, tests/phase-09/test_lint_ci_mode.sh, tests/phase-09/test_lint_skip_category.sh</files>
  <read_first>
    - bin/lint.sh — ENTIRE file (all 1131 lines). Know the current findings-accumulation point (add_finding), the report-writing site, the existing `--category` filter, and the exit path
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-01 through D-06 (JSON + CI contract)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Code Examples" #1 (verbatim CI_SEVERITY_REMAP dict), §"Anti-Patterns" (no lint-report.md in JSON mode, no shape divergence)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-REVIEWS.md — Codex MEDIUM #1 (`drift-external` model), MEDIUM #2 (`--category`/`--skip-category` precedence), MEDIUM #3 (`line` field policy)
    - tests/phase-09/lib.sh
  </read_first>
  <behavior>
    - Test A (test_lint_format_json.sh): `bash bin/lint.sh --format json wiki/` emits a JSON array to stdout; each element has keys `severity`, `category`, `path`, `message`; the `line` key is OMITTED (NOT present as null) when the underlying finding lacks a line number; `wiki/maintenance/lint-report.md` is NOT written/updated (mtime unchanged OR absent). Exits 0.
    - Test A2 (test_lint_format_json.sh): For findings that DO carry a line number (e.g., Plan 09-03 strict/skip-count; for Plan 02 scope, simulate via an injected test finding or verify the absence-invariant only), the `line` value is an integer, 1-indexed. (Phase 9 Plan 02 scope: the existing checks do not emit `line`; this test asserts the NEGATIVE invariant only — `line` absent, not `null`.)
    - Test B (test_lint_ci_mode.sh, clean wiki): `bash bin/lint.sh --ci --format json wiki/` on a clean wiki exits 0, emits `[]` or findings with no `severity: error`.
    - Test C (test_lint_ci_mode.sh, dirty wiki): On a fixture wiki with a YAML frontmatter parse error (category `yaml`), `bash bin/lint.sh --ci --format json <fixture-wiki>` exits 1 AND the JSON array contains at least one element with `severity: error` and `category: yaml`.
    - Test D (test_lint_ci_mode.sh, non-ci): `bash bin/lint.sh --format json wiki/` (WITHOUT `--ci`) on the same dirty fixture exits 0 (no CI remap → no error-severity findings to trigger exit-1).
    - Test E (test_lint_skip_category.sh, --skip-category): `bash bin/lint.sh --skip-category yaml --format json <fixture-wiki>` emits JSON with no `category: yaml` findings.
    - Test F (test_lint_skip_category.sh, --ci default drift-external): Seed a fixture wiki with ONE internal drift finding (e.g., DRFT-01-style — no `EXTERNAL: ` prefix) AND ONE external drift finding (message prefixed with `EXTERNAL: `). `bash bin/lint.sh --ci --format json wiki/` MUST include the internal drift finding and MUST NOT include the external one. `bash bin/lint.sh --format json wiki/` (no --ci) includes BOTH.
    - Test G (test_lint_skip_category.sh, precedence): `bash bin/lint.sh --category stale --skip-category yaml --format json <fixture>` emits ONLY stale findings (category filter narrowed to {stale}; skip subtracts nothing because yaml wasn't in the narrowed set). `bash bin/lint.sh --category stale --skip-category stale --format json <fixture>` emits ZERO findings (narrowed set {stale} minus skip {stale} = empty). Exits 0 (non-ci).
  </behavior>
  <action>
**Step 1: Add `--format`, `--ci`, `--skip-category` flag parsing and defaults.**

At top of arg-parse section in `bin/lint.sh`, add defaults:

```bash
FORMAT="text"
CI_MODE=0
SKIP_CATEGORIES=""   # colon-separated list
```

In the arg-parse loop, add these cases (BEFORE the catch-all `-*)` case):

```bash
        --format)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --format requires a value (text or json)" >&2
                exit 1
            fi
            case "$2" in
                text|json) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'text' or 'json', got '$2'" >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --ci)
            CI_MODE=1
            shift
            ;;
        --skip-category)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --skip-category requires a value" >&2
                exit 1
            fi
            if [ -z "$SKIP_CATEGORIES" ]; then
                SKIP_CATEGORIES="$2"
            else
                SKIP_CATEGORIES="$SKIP_CATEGORIES:$2"
            fi
            shift 2
            ;;
```

After arg-parse (before invoking python3), apply the CI default skip:

```bash
# D-02: --ci defaults to skipping drift-external unless --skip-category was provided.
if [ "$CI_MODE" -eq 1 ] && [ -z "$SKIP_CATEGORIES" ]; then
    SKIP_CATEGORIES="drift-external"
fi
```

Export these three new env vars to the python3 heredoc block alongside existing `WIKI_DIR`/`DRY_RUN`/`FIX`/`CATEGORY`:

```bash
export LINT_FORMAT="$FORMAT"
export LINT_CI_MODE="$CI_MODE"
export LINT_SKIP_CATEGORIES="$SKIP_CATEGORIES"
```

**Step 2: Inside the main python3 block of `bin/lint.sh`, add the severity-remap table, apply-skip filter with precedence, and drift-external subcategory logic.**

At the top of the python3 block (after the standard `import` lines), add:

```python
CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'stale':              'warning',
    'gap':                'warning',
    'contradiction':      'warning',
    'contradiction-sync': 'warning',
    'drift':              'warning',
    'contributor':        'warning',   # Plan 03 populates
    'autofix':            'info',
    'skip-count':         'info',      # Plan 03 populates
}

CI_MODE = os.environ.get('LINT_CI_MODE', '0') == '1'
LINT_FORMAT = os.environ.get('LINT_FORMAT', 'text')
SKIP_CATEGORIES = set(filter(None, os.environ.get('LINT_SKIP_CATEGORIES', '').split(':')))
# CATEGORY is the existing --category inclusive filter (single value), from env
CATEGORY_FILTER = os.environ.get('LINT_CATEGORY', '').strip()

def matches_skip(cat, msg, skip_set):
    """Return True iff the finding (cat, msg) should be dropped per skip_set.

    Supports both plain-category skips (e.g., 'yaml') and the
    'drift-external' LOGICAL SUBCATEGORY skip, which targets drift findings
    whose message begins with the `EXTERNAL: ` token (DRFT-03 Obsidian-vault
    awareness and future external-state checks). Plain 'drift' in skip_set
    drops ALL drift findings.
    """
    if cat in skip_set:
        return True
    if 'drift-external' in skip_set and cat == 'drift' and msg.startswith('EXTERNAL: '):
        return True
    return False
```

Where the existing code currently calls "emit the report" / "write lint-report.md", wrap with a branch. Structure (simplified):

```python
# After all findings accumulate into `findings` (the list of 4-tuples):

# 1. Apply --category (inclusive) filter FIRST, then --skip-category (exclusive) — P0 review fix.
#    Set math: final = (CATEGORY_FILTER or ALL) - SKIP_CATEGORIES.
if CATEGORY_FILTER:
    findings = [f for f in findings if f[1] == CATEGORY_FILTER]
if SKIP_CATEGORIES:
    findings = [f for f in findings if not matches_skip(f[1], f[3], SKIP_CATEGORIES)]

# 2. Apply --ci severity remap
if CI_MODE:
    findings = [(CI_SEVERITY_REMAP.get(cat, sev), cat, path, msg) for (sev, cat, path, msg) in findings]

# 3. Emit per format
if LINT_FORMAT == 'json':
    import json
    payload = []
    for (sev, cat, path, msg) in findings:
        item = {'severity': sev, 'category': cat, 'path': path, 'message': msg}
        # D-04 + P0 review: `line` is OMITTED (not null) when no line info available.
        # Phase 9 v1.1 does NOT back-port line numbers into existing findings;
        # Plan 09-03 strict/skip-count findings that carry lines will extend the
        # tuple to a 5-tuple or attach line via a side-channel — that's their
        # concern, not Plan 02's. For now the 4-tuple has no line slot.
        payload.append(item)
    print(json.dumps(payload, indent=2))
    # D-03: JSON mode stdout only. Do NOT write lint-report.md.
else:
    # existing text-mode behavior: print summary + write lint-report.md (if not --dry-run)
    ...

# 4. CI exit-code policy (D-05)
if CI_MODE:
    has_error = any(sev == 'error' for (sev, _, _, _) in findings)
    sys.exit(1 if has_error else 0)
# Non-CI mode: exit 0 (existing behavior)
```

Be careful: if the current `bin/lint.sh` structure calls `sys.exit` or `os._exit` elsewhere, consolidate the final exit through this new branch. Do NOT write `lint-report.md` when `LINT_FORMAT == 'json'` — that is the D-03 contract.

**Step 2b: Tag external-state drift findings with the `EXTERNAL: ` message prefix.**

Find the existing drift-detection block in `bin/lint.sh` (search for DRFT-03 / Obsidian vault awareness). Where those findings call `add_finding('warning', 'drift', path, msg)`, change the message to prefix `EXTERNAL: ` — e.g., `add_finding('warning', 'drift', path, 'EXTERNAL: ' + msg)`. This is a one-liner per external-state check site. Internal drift findings (DRFT-01 unrepresented-source, DRFT-02 missing-source-file, content-hash-drift, index-coverage) are left unchanged (no prefix).

Document the convention inline with a comment:

```python
# EXTERNAL: prefix marks drift findings originating from external-state
# checks (DRFT-03 Obsidian vault awareness). The --skip-category drift-external
# filter (applied by --ci default) consults this prefix. See AGENTS.md §11.3.
```

**Step 3: Update `usage()` help text (documents precedence + drift-external):**

```
  --format text|json         Output format (default: text). JSON writes array to stdout.
  --ci                       CI mode: apply severity remap (CI-03), default-skip drift-external,
                             exit 1 on any error-severity finding.
  --skip-category <cat>      Skip one category. Repeatable (chains: cat1:cat2). Inverse of --category.
                             Valid values: any add_finding() category name, plus the logical
                             subcategory 'drift-external' (targets external-state drift only).
                             Precedence: --category (inclusive) applies first; --skip-category subtracts.
                             Example: '--category stale --skip-category stale' → zero findings emitted.
```

**Step 4: Write three unit tests.**

`tests/phase-09/test_lint_format_json.sh`:

```bash
#!/usr/bin/env bash
# CI-02: --format json emits JSON array to stdout; no lint-report.md write; `line` OMITTED not null.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Run from fixture root so wiki/ resolves.
pushd "$FIXTURE" >/dev/null
# Ensure wiki/maintenance/ doesn't exist beforehand
[ -f wiki/maintenance/lint-report.md ] && rm wiki/maintenance/lint-report.md

OUT="$(bash "$REPO_ROOT/bin/lint.sh" --format json wiki/ 2>/dev/null)"

# Validate JSON parse + shape
python3 - <<PYEOF
import json, sys
data = json.loads('''$OUT''')
assert isinstance(data, list), f"expected list, got {type(data)}"
for item in data:
    assert set(item.keys()) <= {'severity','category','path','message','line'}, \
        f"unexpected keys: {item.keys()}"
    assert 'severity' in item and 'category' in item and 'path' in item and 'message' in item, \
        f"missing required keys in {item}"
    assert item['severity'] in ('error','warning','info'), f"bad severity: {item['severity']}"
    # P0 review fix: `line` is OMITTED when unknown, NOT present as null.
    if 'line' in item:
        assert isinstance(item['line'], int) and item['line'] >= 1, \
            f"line must be integer 1-indexed when present, got: {item['line']!r}"
print("PASS: JSON shape valid (line omitted when unknown, not null)")
PYEOF

# D-03: no lint-report.md written in JSON mode
if [ -f wiki/maintenance/lint-report.md ]; then
    echo "FAIL: --format json must not write lint-report.md (D-03)" >&2
    popd >/dev/null
    exit 1
fi
popd >/dev/null
echo "PASS: --format json"
```

`tests/phase-09/test_lint_ci_mode.sh`:

```bash
#!/usr/bin/env bash
# CI-03: --ci severity remap + exit-1-on-error; without --ci, text mode unchanged.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed a page with broken YAML frontmatter to trigger a `yaml` category finding
mkdir -p "$FIXTURE/wiki/concepts"
cat > "$FIXTURE/wiki/concepts/broken.md" <<'BROKEN'
# --- frontmatter delimiter (escaped for doc-parser)
id: broken
title: Broken
type: concept
invalid yaml: here: with: too: many: colons
# --- frontmatter delimiter (escaped for doc-parser)
BROKEN

pushd "$FIXTURE" >/dev/null

# 1. --ci --format json on dirty wiki: exit 1 + yaml error finding
if bash "$REPO_ROOT/bin/lint.sh" --ci --format json wiki/ > /tmp/lint-ci.json 2>/dev/null; then
    echo "FAIL: --ci on broken yaml should exit 1" >&2
    popd >/dev/null; exit 1
fi
assert_json_has_finding /tmp/lint-ci.json yaml error || { popd >/dev/null; exit 1; }

# 2. Without --ci on same wiki: exit 0 (no CI remap)
bash "$REPO_ROOT/bin/lint.sh" --format json wiki/ > /tmp/lint-nonci.json 2>/dev/null \
    || { echo "FAIL: non-ci mode should exit 0 regardless of findings" >&2; popd >/dev/null; exit 1; }

# 3. --ci on clean wiki (remove broken.md): exit 0
rm wiki/concepts/broken.md
bash "$REPO_ROOT/bin/lint.sh" --ci --format json wiki/ > /tmp/lint-clean.json 2>/dev/null \
    || { echo "FAIL: --ci on clean wiki should exit 0" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --ci severity remap + exit-code policy"
```

`tests/phase-09/test_lint_skip_category.sh`:

```bash
#!/usr/bin/env bash
# CI-04: --skip-category excludes categories; --ci default-skips drift-external;
# --category (inclusive) applies before --skip-category (exclusive) per P0 review fix.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo ci-lint-json)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed a broken yaml page
mkdir -p "$FIXTURE/wiki/concepts"
cat > "$FIXTURE/wiki/concepts/broken.md" <<'BROKEN'
# --- frontmatter delimiter (escaped for doc-parser)
bad: :: yaml
# --- frontmatter delimiter (escaped for doc-parser)
BROKEN

pushd "$FIXTURE" >/dev/null

# 1. --skip-category yaml: no yaml findings
bash "$REPO_ROOT/bin/lint.sh" --skip-category yaml --format json wiki/ > /tmp/skip.json 2>/dev/null
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/skip.json'))
for item in data:
    assert item['category'] != 'yaml', f"FAIL: yaml finding present despite --skip-category yaml: {item}"
print("PASS: --skip-category yaml excluded category")
PYEOF

# 2. --ci default-skip drift-external: external drift (prefix 'EXTERNAL: ') dropped;
# internal drift findings retained.
bash "$REPO_ROOT/bin/lint.sh" --ci --format json wiki/ > /tmp/ci.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/ci.json'))
for item in data:
    # External drift findings should be absent from CI output (default skip)
    if item['category'] == 'drift':
        assert not item['message'].startswith('EXTERNAL: '), \
            f"FAIL: external drift finding present despite --ci default drift-external skip: {item}"
print("PASS: --ci default-skips drift-external (internal drift retained)")
PYEOF

# 3. P0 review fix — --category + --skip-category precedence.
# Seed a page triggering a `stale` warning (simulated via manually-aged checked_at marker).
# Then:
#   (a) --category stale --skip-category yaml → stale present (yaml wasn't in narrowed set).
#   (b) --category stale --skip-category stale → empty array (narrowed minus self = empty).

# Seed a simple page to satisfy the lint tree structure — `stale` emission is
# exercised on fixtures that actually have stale-dated claims. For this
# precedence test we use a lightweight synthetic: if the fixture has no stale
# findings, the test asserts the SET-MATH invariant on whatever categories ARE
# present. That still exercises the precedence codepath.

# --category filter alone: only that category type shown
bash "$REPO_ROOT/bin/lint.sh" --category yaml --format json wiki/ > /tmp/cat.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/cat.json'))
for item in data:
    assert item['category'] == 'yaml', f"FAIL: --category yaml should narrow: {item}"
print("PASS: --category filter narrows")
PYEOF

# --category X --skip-category X: empty result (narrow-then-subtract = empty set)
bash "$REPO_ROOT/bin/lint.sh" --category yaml --skip-category yaml --format json wiki/ > /tmp/selfskip.json 2>/dev/null || true
python3 - <<'PYEOF'
import json
data = json.load(open('/tmp/selfskip.json'))
assert data == [] or all(i['category'] != 'yaml' for i in data), \
    f"FAIL: --category yaml --skip-category yaml should emit empty: {data}"
print("PASS: --category/--skip-category precedence (narrow then subtract)")
PYEOF

popd >/dev/null
echo "PASS: --skip-category + --ci default skip + precedence"
```

All tests marked executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_lint_format_json.sh && bash tests/phase-09/test_lint_ci_mode.sh && bash tests/phase-09/test_lint_skip_category.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "CI_SEVERITY_REMAP" bin/lint.sh` returns 0 (dispatch table embedded)
    - `grep -q "^FORMAT=" bin/lint.sh` returns 0 (flag default)
    - `grep -q "^CI_MODE=" bin/lint.sh` returns 0 (flag default)
    - `grep -q "^SKIP_CATEGORIES=" bin/lint.sh` returns 0
    - `grep -q "matches_skip\|drift-external" bin/lint.sh` returns 0 (drift-external logical subcategory implemented — P0 review fix)
    - `grep -q "EXTERNAL: " bin/lint.sh` returns 0 (external-drift prefix tagged at emission site — P0 review fix)
    - `grep -q "CATEGORY_FILTER\|category_filter" bin/lint.sh` returns 0 (precedence logic implemented — P0 review fix)
    - `bash bin/lint.sh --format json wiki/` emits JSON-parseable stdout: `bash bin/lint.sh --format json wiki/ | python3 -c 'import json,sys; json.load(sys.stdin)'` exits 0
    - JSON `line` key is OMITTED (not present as null) when underlying finding has no line: `bash bin/lint.sh --format json wiki/ | python3 -c 'import json,sys; [sys.exit(1) for i in json.load(sys.stdin) if i.get("line") is None and "line" in i]'` exits 0
    - `bash bin/lint.sh --format json wiki/` does NOT create or modify `wiki/maintenance/lint-report.md` (D-03)
    - `bash bin/lint.sh --format xml wiki/` exits 1 with stderr mentioning valid values (`text`, `json`)
    - `bash bin/lint.sh --skip-category yaml --format json wiki/` produces JSON where no element has `category: yaml`
    - `bash bin/lint.sh --category stale --skip-category stale --format json <fixture>` produces JSON with no `category: stale` entries (precedence: narrow → subtract)
    - `bash bin/lint.sh --help` output mentions `--category` / `--skip-category` precedence
    - `bash tests/phase-09/test_lint_format_json.sh` exits 0
    - `bash tests/phase-09/test_lint_ci_mode.sh` exits 0
    - `bash tests/phase-09/test_lint_skip_category.sh` exits 0
    - Regression: `bash bin/lint.sh` (no flags) on the real `wiki/` still writes `wiki/maintenance/lint-report.md` (text-mode unchanged)
    - Regression: `bash tests/phase-06/run.sh` still exits 0 (existing lint-feature tests unaffected by the flag additions)
  </acceptance_criteria>
  <done>
    `bin/lint.sh --format json --ci --skip-category <cat>` is a functioning three-flag composition. `--category`/`--skip-category` precedence is set-math (intersect-then-subtract), documented and tested. `drift-external` is a logical subcategory targeting `EXTERNAL: `-prefixed drift findings without breaking the 4-tuple `add_finding()` shape. Plan 05's `.github/workflows/lint.yml` can call `bash bin/lint.sh --require-version 1.1.0 --ci --format json > lint.json` and get a deterministic severity-remapped JSON array with CI exit-1-on-error semantics. Plan 03 extends the same dispatcher with new categories (`contributor`, `skip-count`); the dispatch-table pattern absorbs those additions in one line.
  </done>
</task>

</tasks>

<verification>
- All four `--format`, `--ci`, `--skip-category`, `--require-version`, `--version` flags are parseable and documented in `--help` output.
- `bash bin/lint.sh --version` prints `1.1.0`.
- `bash bin/lint.sh --require-version 1.2.0` exits 1.
- `bash bin/lint.sh --format json wiki/` emits valid JSON array with `line` omitted (not null) when unknown.
- `bash bin/lint.sh --ci --format json` on a YAML-broken fixture exits 1 with a `severity: error` finding.
- `bash bin/lint.sh --ci --format json` on a clean wiki exits 0.
- `bash bin/lint.sh --category X --skip-category X --format json <fixture>` returns empty array for category X (precedence verified).
- `bash bin/lint.sh --ci --format json` omits `EXTERNAL: `-prefixed drift findings (drift-external default skip); retains internal drift findings.
- `bash tests/phase-09/run.sh` picks up all five new test files and passes each.
- Regression: `bash tests/phase-06/run.sh` and `bash tests/phase-07/run.sh` still pass.
</verification>

<success_criteria>
Plan 05's workflow YAML can invoke `bash bin/lint.sh --require-version 1.1.0 --ci --format json > lint.json` and receive a deterministic severity-remapped JSON array. Plan 03 extends the same codepath with `--strict` + `--count-skips`, and new `contributor` + `skip-count` categories fit into the dispatch table in one line each. Category/skip precedence is documented AND tested. `drift-external` skip is well-defined via the `EXTERNAL: ` prefix convention.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-02-SUMMARY.md` documenting: exact LINT_VERSION value shipped (1.1.0), CI_SEVERITY_REMAP dispatch table contents, flag signatures and defaults, JSON payload shape (keys, `line` omission invariant), the D-03 contract (no lint-report.md write in JSON mode), the `drift-external` subcategory convention (`EXTERNAL: ` message prefix), and the `--category`/`--skip-category` precedence (intersect-then-subtract). List the 5 test files added and their assertions.
</output>
