# Phase 10: Brownfield Scan + Bootstrap — Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 10 (2 new scripts + 4 new helper/config/docs + 4 modified)
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `bin/brownfield.sh` (NEW) | new script (subcommand dispatch) | frontmatter I/O + diff generation + stderr emit | `bin/release.sh` (dry-run/apply posture) + `bin/lint.sh` (`--category` dispatch + large python3 heredoc) | composite-match (no single analog has both shapes) |
| `bin/lib/brownfield_classify.py` (NEW, optional) | new python helper module | frontmatter I/O + signal-trace emit | `bin/lint.sh` python3 block (inline, no extracted helper precedent) | partial (novel) |
| `bin/lib/brownfield_yaml.py` (NEW, optional) | new python helper module | ruamel.yaml round-trip | `bin/lint.sh` `parse_frontmatter()` (PyYAML safe_load, not round-trip) | role-match only |
| `.brownfield-ignore` support (NEW parser) | config-file reader | glob-pattern matching | `bin/check-neutrality.sh` `.neutrality-denylist.txt` reader + hardcoded `PUBLIC_PATHS` array pattern | exact pattern-twin |
| `tests/phase-10/run.sh` (NEW) | test harness aggregator | subprocess + tally | `tests/phase-09/run.sh` | exact (rename 09→10) |
| `tests/phase-10/lib.sh` (NEW) | shared test helpers | fixture copy + git init | `tests/phase-09/lib.sh` + `tests/phase-08/lib.sh` (`assert_byte_equal`) | exact (merge + rename) |
| `tests/phase-10/fixtures/*/` (NEW, 6+) | test fixtures | static byte-frozen data | `schema/fixtures/canonical-AGENTS.md` + `tests/phase-09/fixtures/ci-lint-json/` | exact |
| `bin/lint.sh` (MODIFIED) | extend severity-remap + add category | env + python3 heredoc | itself — extend `CI_SEVERITY_REMAP` + `should_run()` + downgrade modifier | self-analog |
| `bin/ingest.sh` (MODIFIED) | insert BRWN-10 strip step | file read + YAML rewrite + stderr warn | `bin/ingest.sh` `resolve_contributor()` stderr-warn pattern + `bin/sync-claude.sh` byte copy | self-analog + pattern-twin |
| `AGENTS.md §5` (MODIFIED) | add 2 table rows | doc edit | AGENTS.md line 300 (`example` row — Phase 7) + line 299 (`has_contradictions`) | exact |
| `schema/AGENTS.template.md` (MODIFIED) | mirror AGENTS.md §5 edit | doc edit | line 303 same `example` row | exact (byte-mirror of AGENTS.md) |
| `docs/reference/brownfield.md` (MODIFIED) | populate scan + bootstrap sections; stub suggest + verify | doc write | `docs/reference/ci.md` (Phase 7 stub → Phase 9 populate) + `docs/reference/release.md` (runbook shape) | exact |
| `docs/quickstart.md` (MODIFIED) | add one-line ruamel.yaml prereq note | doc edit | existing line 5–7 Prerequisites section | exact |

---

## Pattern Assignments

### `bin/brownfield.sh` (new script — subcommand dispatch)

**Primary analogs:**
- `bin/release.sh` — `--dry-run` default + `--apply` pattern, allowlist/denylist hardcoded arrays, trap cleanup, manifest output
- `bin/lint.sh` — `--category`/`--skip-category` dispatch, bash→python3 heredoc with env transport, `--format text|json`

#### 1. Subcommand dispatch (NOVEL — no existing twin)

`bin/release.sh` is not subcommanded; `bin/lint.sh` uses `--category` (flag, not positional). CONTEXT.md §Claude's Discretion #1 invites planner-choice. **Recommended shape** (distilled from `bin/release.sh` lines 91–100 + `bin/lint.sh` lines 95–174):

```bash
# After shebang + set -euo pipefail + usage():
if [ "$#" -eq 0 ]; then usage; exit 1; fi
SUBCOMMAND="$1"
shift
case "$SUBCOMMAND" in
    scan|bootstrap) ;;
    suggest|verify)
        echo "ERROR: '$SUBCOMMAND' not yet implemented — see Phase 11 (BRWN-*)" >&2
        exit 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2; usage >&2; exit 1 ;;
esac
# Subcommand-specific flag parsing follows …
```

Exit code 2 for "not yet implemented" matches CONTEXT.md §Integration-Points Phase 8-02 precedent.

#### 2. Dry-run default + `--apply` posture — copy from `bin/release.sh:91–129`

`bin/release.sh` lines 91–100 (flag parse) and lines 120–129 (dry-run early-exit + interactive confirm):

```bash
APPLY=0
# … flag parsing …
        --apply) APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;

# … after plan output …
if [ "$APPLY" -eq 0 ]; then
    echo "(dry-run) Pass --apply to execute."
    exit 0
fi

read -r -p "Proceed with publish? [y/N] " resp
case "$resp" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
esac
```

**What to copy:** The `APPLY=0` default, flag-parse case arms, and early-exit block.
**What to change:** Drop the interactive `read -r -p` confirm per D-08 ("No `--assume-yes` / `--force` for v1.1" — but also no interactive prompt beyond the flag itself; bootstrap is CLI-friendly, not user-gated like release).

#### 3. Bash→python3 heredoc with env transport — copy from `bin/lint.sh:240–252`

```bash
export LINT_WIKI_DIR="$WIKI_DIR"
export LINT_FINDINGS_FILE="$FINDINGS_FILE"
export LINT_DRY_RUN="$DRY_RUN"
export LINT_FIX="$FIX"
export LINT_CATEGORY="$CATEGORY"
# … etc …
export LINT_REPO_ROOT="${LINT_REPO_ROOT:-$PWD}"

python3 << 'PYEOF'
import sys, os, re, yaml
# …
wiki_dir = os.environ['LINT_WIKI_DIR']
# …
PYEOF
```

**What to copy:** The exact `export BROWNFIELD_*="..."` → `python3 << 'PYEOF'` → `os.environ['BROWNFIELD_*']` triad. Single-quoted heredoc marker prevents shell expansion inside Python. `bin/check-neutrality.sh:96–107` and `bin/check-privacy.sh:74–77` are smaller-scale confirming twins.
**What to change:** Import `ruamel.yaml` (`from ruamel.yaml import YAML; yaml = YAML(typ='rt')`) instead of `import yaml` for the write path; keep PyYAML `safe_load` for the pre-flight parse-check (D-01).

#### 4. Stderr progress + summary pattern — copy from `bin/lint.sh:234, 1795–1815`

```bash
echo "Linting ${WIKI_DIR}..." >&2
# … later in python3 …
print(f"""
=== Wiki Lint Results ===
Errors:   {error_count}
Warnings: {warning_count}
Info:     {info_count}
~~~~~~~~~~~~~~~~~~~~~~~~""", file=sys.stderr)
```

**What to copy:** The `=== Banner ===` + aligned counts shape; stderr-only for progress, stdout reserved for structured output (D-09 counts list + report path).
**What to change:** Replace with brownfield counts — `parsed / would-bootstrap / collisions / schema-warnings / skipped` per D-09.

#### 5. Unified diff emission for `--verbose` — copy from `bin/init-wizard.sh:938–953`

```python
import difflib
def _diff(label, old_content, new_content):
    a = old_content.splitlines() if old_content else []
    b = new_content.splitlines() if new_content else []
    diff_iter = difflib.unified_diff(
        a, b,
        fromfile=f"a/{label}",
        tofile=f"b/{label}",
        lineterm="",
    )
    for line in diff_iter:
        print(line)
```

**What to copy:** Exact `difflib.unified_diff` call shape; stripped `lineterm=""` for clean per-line printing.
**What to change:** `label` becomes the relative file path; gate emission behind `--verbose` flag.

---

### `.brownfield-ignore` support (new parser + built-in denylist)

**Analog:** `bin/check-neutrality.sh` lines 93–107 (hardcoded `PUBLIC_PATHS` array + env-transport join).

```bash
# Public control-plane paths scanned (D-06). examples/ is explicitly excluded.
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki bin)

# Join PUBLIC_PATHS with ':' for env transport
CN_PP=""
for p in "${PUBLIC_PATHS[@]}"; do
    if [ -z "$CN_PP" ]; then CN_PP="$p"; else CN_PP="$CN_PP:$p"; fi
done
export CN_PUBLIC_PATHS="$CN_PP"
```

**What to copy:** The hardcoded-bash-array + colon-join + env-transport idiom. Works at any scale.
**What to change:** Array name becomes `BROWNFIELD_DEFAULT_EXCLUDES=(.obsidian .trash templates attachments …)` per D-19. User override layer (`.brownfield-ignore`, gitignore-grammar) is a NEW extension — no existing codebase twin has a user-override config file layered on top of a hardcoded array. CONTEXT.md §Claude's Discretion #3 recommends `pathspec` Python module; planner's call — weigh against "zero new deps except ruamel.yaml" rule in CONTEXT.md §Established Patterns.

---

### `bin/lint.sh` (MODIFIED) — BRWN-08 downgrade + new `brownfield` category

#### Hook 1: Extend `CI_SEVERITY_REMAP` dispatcher — `bin/lint.sh:296–312`

```python
# Severity remap dispatch table (D-02, D-05). Any add_finding() category not
# listed here retains its original severity. Plan 03 extends this with new
# categories (`contributor`, `skip-count`) in one line each.
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
```

**What to copy:** The one-line-per-category extension shape — matches the comment's "in one line each" invariant. Precedent: Phase 9 Plan 03 added `contributor` and `skip-count` as single-line additions.
**What to change:** Add `'brownfield': 'warning'` as one new line for the BRWN-09 category. The BRWN-08 error→info DOWNGRADE MODIFIER is a NEW mechanism on top of this table (see Hook 3 below).

#### Hook 2: Add `brownfield` to `--category` enum — `bin/lint.sh:26–29, 142–154`

```bash
  --category <cat>    Run only specified category:
                        orphan, crossref, stale, contradiction, gap,
                        provenance, yaml, drift, contributor
                      Default: all categories
```

```bash
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

**What to copy:** Append `brownfield` to the usage-help list. The `--skip-category` machinery already accepts any string value ("Valid values: any add_finding() category name" per line 44–48); no code change needed there beyond the usage text refresh.
**What to change:** The new check block must call `add_finding('warning', 'brownfield', rel, ...)` — see `bin/lint.sh:1111, 1182, 1283` for reference `add_finding()` call sites (all use `(severity, category, path, message)`).

#### Hook 3: BRWN-08 downgrade modifier — NEW plug-in point BETWEEN `CI_SEVERITY_REMAP` apply and output

**Insertion site:** `bin/lint.sh:1647–1649`:

```python
if CI_MODE:
    findings = [(CI_SEVERITY_REMAP.get(cat, sev), cat, path, msg)
                for (sev, cat, path, msg) in findings]
```

**What to copy:** The in-place `findings = [...]` list comprehension shape (same as Phase 9 `SKIP_CATEGORIES` filter at line 1644–1645). The BRWN-08 downgrade is a second list comprehension after the remap (or merged into it).
**What to change:** Add a new `BROWNFIELD_BOOTSTRAPPED_PAGES` set built at page-parse time (check each page's frontmatter for `bootstrap_stage: bootstrapped`); inside the remap comprehension, if `path` is in the bootstrapped set AND `cat` is in an allowlist (likely `{'yaml', 'provenance', 'orphan'}` per D-20 / CONTEXT.md §Decisions Area 5), downgrade to `info`. CONTEXT.md §Claude's Discretion #6 gives planner latitude on exact allowlist.

#### Hook 4: New `brownfield` check block — model on Check 10 drift block (`bin/lint.sh:1497–1622`)

Reference shape for the new check (BRWN-09 30-day staleness calculation from `bootstrap_date`):

```python
if should_run('brownfield') or should_run('all'):
    import datetime
    today = date.today()
    for page_path, page_fm, page_body, page_err in all_pages:
        if page_fm is None:
            continue
        if page_fm.get('bootstrap_stage') != 'bootstrapped':
            continue
        bd = page_fm.get('bootstrap_date')
        if not bd:
            continue
        try:
            bdate = date.fromisoformat(str(bd))
        except ValueError:
            continue
        age_days = (today - bdate).days
        rel = os.path.relpath(page_path)
        if age_days > 30:
            add_finding('warning', 'brownfield', rel,
                        f'bootstrapped {age_days} days ago; consider Phase-11 suggest/verify')
```

**What to copy:** The `should_run()` gate, `for page_path, page_fm, page_body, page_err in all_pages:` loop (line 1588), `add_finding('warning', 'brownfield', ...)` signature (line 1518 is the closest 4-tuple twin).
**What to change:** All specifics — D-13 sentinel field names, 30-day threshold, message wording.

---

### `bin/ingest.sh` (MODIFIED) — BRWN-10 strip + stderr warn

**Current state:** `bin/ingest.sh` is purely a **scaffolder** — it copies the source file into `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/`, computes SHA-256, and prints instructions. It does NOT currently parse or merge frontmatter (no `yaml` imports, zero heredocs).

**Implication for BRWN-10:** The "frontmatter merge point" named in CONTEXT.md §Reusable-Assets doesn't exist as a function yet — it must be **added** as a post-copy step. The hook point is between the `cp` (line 312–313) and the hash compute (line 319), OR as a separate pass after line 319 but before the echo-instructions block (line 331).

**Analog for stderr-warn wording:** `bin/ingest.sh:96–108` `resolve_contributor()` map-miss warn block:

```bash
if [ ! -f "$map" ]; then
    echo "WARN: no .git-author-map.txt at repo root; cannot resolve $email to @handle" >&2
    echo "      Omitting contributor:: field." >&2
    echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
    echo "      Or: re-run with --contributor @your-handle" >&2
    return 0
fi
```

**What to copy:** The 3-line stderr pattern (primary message + context + actionable suggestion). Matches D-21 precedent cited in CONTEXT.md §Established-Patterns.
**What to change:** The wording per D-21 verbatim: `"Note: stripped bootstrap_stage=<value> from <path> during ingest (brownfield-scoped field; see AGENTS.md §5)."` — single-line per D-21 ("one-line stderr warning") rather than the 3-line shape `resolve_contributor` uses for fail-soft recoverability.

**Analog for the in-place YAML rewrite:** None perfect in ingest.sh. Closest is `bin/lint.sh:1566–1574` content-hash-drift auto-fix:

```python
if comp_status and comp_status != 'stale':
    try:
        content = open(sp, encoding='utf-8').read()
        content = re.sub(
            r'^(compilation_status:\s*).*$',
            r'\1stale',
            content, flags=re.MULTILINE
        )
        with open(sp, 'w', encoding='utf-8') as f:
            f.write(content)
        add_finding('info', 'autofix', rel,
                    'Set compilation_status to stale (content hash drift)')
    except Exception:
        pass
```

**What to copy:** The regex-rewrite pattern for single-field mutation inside frontmatter. Safe for narrowly-scoped strip (two fields: `bootstrap_stage`, `bootstrap_date`).
**What to change:** Strip REMOVES lines rather than rewriting them. Use `re.sub(r'^bootstrap_stage:.*\n', '', content, flags=re.MULTILINE)` for each of the two fields. Alternative: use ruamel.yaml round-trip (consistent with brownfield.sh) — planner's call; regex is lighter-weight for a 2-field strip and does not require ruamel.yaml as an ingest-path dependency.

**Note on regex-vs-yaml choice:** If BRWN-10 uses regex, `bin/ingest.sh` remains ruamel-yaml-free (preserving the "ruamel.yaml is brownfield-path-only" invariant per CONTEXT.md §Established-Patterns). Recommend regex.

---

### `tests/phase-10/run.sh` + `tests/phase-10/lib.sh` (NEW test harness)

**Analog:** `tests/phase-09/run.sh` (exact) + `tests/phase-09/lib.sh` (primary) + `tests/phase-08/lib.sh` (for `assert_byte_equal`, which Phase 09 omits but Phase 10 needs for D-07 golden-fixture contract).

#### `run.sh` — clone from `tests/phase-09/run.sh:1–49` verbatim

```bash
#!/usr/bin/env bash
# tests/phase-09/run.sh -- Phase 09 test aggregator …
set -euo pipefail

FULL=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --full) FULL=1; shift ;;
        --help|-h) cat <<'EOF'
Usage: tests/phase-09/run.sh [--full]
  --full   Reserved for future full-suite runs (no-op in P1).
EOF
            exit 0 ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; TOTAL=0; FAILED_TESTS=()

shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    TOTAL=$((TOTAL + 1))
    name="$(basename "$t")"
    echo "--- Running $name ---"
    if bash "$t"; then
        PASS=$((PASS + 1)); echo "--- PASS $name ---"
    else
        FAIL=$((FAIL + 1)); FAILED_TESTS+=("$name"); echo "--- FAIL $name ---"
    fi
done
echo ""
echo "PHASE 09 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
```

**What to copy:** All 49 lines verbatim.
**What to change:** Replace every `phase-09` / `Phase 09` / `PHASE 09` literal with `phase-10` / `Phase 10` / `PHASE 10`. Nothing else.

#### `lib.sh` — merge `tests/phase-09/lib.sh` + `tests/phase-08/lib.sh:63–72` (`assert_byte_equal`)

From `tests/phase-09/lib.sh:13–29`:

```bash
# make_fixture_repo <fixture-name>  -> prints path to a fresh temp repo
make_fixture_repo() {
    local fixture="$1"
    local src="$REPO_ROOT/tests/phase-09/fixtures/$fixture"
    if [ ! -d "$src" ]; then
        echo "ERROR: fixture not found: $src" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d -t phase09-fixture-XXXXXX)"
    # Copy all non-README content (README.md is documentation of the fixture, not part of the repo under test)
    (cd "$src" && find . -type f ! -name README.md -print0) | while IFS= read -r -d '' f; do
        mkdir -p "$tmp/$(dirname "$f")"
        cp "$src/$f" "$tmp/$f"
    done
    (cd "$tmp" && git init -q -b main && git config user.email "fixture@example.com" && git config user.name "Fixture" && git add -A && git -c commit.gpgsign=false commit -q --allow-empty -m "fixture seed")
    echo "$tmp"
}
```

From `tests/phase-08/lib.sh:63–72` (add for D-07 byte-equality contract):

```bash
assert_byte_equal() {
    # assert_byte_equal <expected_file> <actual_file> [message]
    local expected="$1" actual="$2" msg="${3:-files differ}"
    if ! cmp -s "$expected" "$actual"; then
        echo "ASSERT FAIL: $msg" >&2
        echo "--- diff (first 50 lines) ---" >&2
        diff -u "$expected" "$actual" | head -50 >&2 || true
        exit 1
    fi
}
```

**What to copy:** `make_fixture_repo`, `cleanup_fixture_repo`, `assert_exit_code` (from phase-09); `assert_byte_equal`, `assert_file_exists`, `assert_grep` (from phase-08).
**What to change:** Replace `phase-09` with `phase-10` in fixture path + mktemp template. Skip `setup_git_author`, `seed_origin_main_ref`, `assert_json_has_finding` — Phase 10 tests don't exercise multi-author git history or `--format json` (BRWN tests exercise file-system mutation, not lint's JSON mode).

#### `tests/phase-10/fixtures/*/` — byte-equality golden contract (D-07)

**Analog:** `schema/fixtures/canonical-AGENTS.md` (per `tests/phase-08/test_canonical_byte_equality.sh:23–41`):

```bash
bash "$REPO_ROOT/bin/init-wizard.sh" \
    --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" \
    --render-to "$WORK"

# 1. AGENTS.md byte-equal to fixture
if ! cmp -s "$WORK/AGENTS.md" "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"; then
    echo "FAIL: canonical-AGENTS.md drift detected." >&2
    echo "" >&2
    echo "To regenerate the fixture (intentional drift after template change):" >&2
    echo "  bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen" >&2
    echo "  cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md" >&2
    echo "  …" >&2
    diff -u "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md" "$WORK/AGENTS.md" | head -50 >&2
    exit 1
fi
```

**What to copy:** The `cmp -s` gate + regenerate-recipe-on-failure stderr block + `diff -u … | head -50` excerpt. Users hitting fixture drift see both the failure and the exact regeneration command.
**What to change:** Adapt for 6 fixtures (per D-07) with BOTH shapes:
1. **Transformed-output path** — parseable fixtures (e.g., `clean-frontmatter`, `no-frontmatter`, `CRLF`, `Dataview-inline`, `frontmatter-with-comments`): run `bin/brownfield.sh bootstrap --apply`, compare result to `expected/`.
2. **Skip/report-artifact path** — unparseable fixtures (e.g., `tabs-in-yaml`, potentially `duplicate-yaml-keys`): assert the file is UNCHANGED from input (`cmp -s input/$f output/$f`) AND `.brownfield/SKIPPED.md` contains the expected entry block.

See also CONTEXT.md §Specifics bullet 8 — planner may need to add a second unparseable fixture if ruamel.yaml parses tabs permissively.

---

### `AGENTS.md §5` MODIFIED — add 2 field rows

**Analog:** Line 300 (`example`) — Phase 7 D-03 precedent per CONTEXT.md §Decisions Area 5.

Exact table-row excerpt from `AGENTS.md:298–304`:

```markdown
| `aliases` | list | Alternative names for Obsidian automatic resolution. Obsidian resolves `[[Alias]]` to the canonical page. |
| `has_contradictions` | boolean | `true` when any claim on the page has a `[contradiction:...]` marker. Independent of `epistemic_status` -- a `sourced` page can have contradictions. May be set by lint workflow OR by any workflow that inserts contradiction markers (ingest, query). The lint mechanically syncs this field: if `[contradiction:]` markers exist in the body, `has_contradictions` MUST be `true`; if no markers exist, it MUST be `false`. |
| `example` | boolean | Optional (default `false`). When `true`, the page is a reference-only example (e.g., pages under `examples/kahneman/`). Lint MUST skip these pages for health checks so illustrative content does not trigger warnings. Applies anywhere in the tree, not just under `examples/`. |
| `knowledge_domain` | string | Primary knowledge domain for staleness decay rate calculation. This is the **staleness policy bucket**, distinct from the `domains` field which is a topical classification list. A page may have `domains: [psychology, economics]` but `knowledge_domain: science` because both topics decay at the science rate. Maps to the decay rate table in Section 6. One of: `software`, `science`, `biography`, `personal-goals`, or a custom domain. Empty string if not yet classified. |
```

**What to copy:** The `| field_name | type | description-with-scope-caveat-and-cross-reference |` four-part row shape. Study the `example` row in particular — single-row, dense prose, ends with an "Applies anywhere in the tree" scope caveat. This is the target shape for `bootstrap_stage`.
**What to change:** Insert two new rows (position: after `knowledge_domain`, before `### Source Summary Additional Fields`). Wording per D-20:
- Name narrow scope: "Brownfield onboarding sentinel."
- State the enum: `raw | bootstrapped | verified`.
- Explicit contrast: "NOT a substitute for claim-level provenance (see §6 PROV-01..05)."
- BRWN-10 hook: "Stripped by `bin/ingest.sh` on normal ingest."
- Forward-ref: optionally point to §11.5 (stubbed in Phase 10, populated Phase 11).

Second row for `bootstrap_date` — similar dense shape, call out ISO 8601 per AGENTS.md §3 date policy (CONTEXT.md §Specifics last bullet).

**Post-edit obligation:** `bin/sync-claude.sh` must be run (or pre-commit hook fires automatically per `.githooks/pre-commit` — see `bin/sync-claude.sh:32` and the hook text). Also update `schema/AGENTS.template.md:303` in lockstep (same row inserted at same table position). Byte-equality CI in `tests/phase-08/test_canonical_byte_equality.sh` will fail until `schema/fixtures/canonical-AGENTS.md` is regenerated per `schema/fixtures/README.md:22–33` — **planner must include fixture regeneration in the same commit as the §5 edit.**

---

### `docs/reference/brownfield.md` MODIFIED — populate scan + bootstrap

**Analog:** `docs/reference/release.md` (exact same genre — runbook for a bin/ script; 111 lines). Also `docs/reference/ci.md` for the "stubbed in earlier phase → populated in later phase" pattern per CONTEXT.md §Decisions Area 7 D-22.

Structure to mirror from `docs/reference/release.md:1–45`:

```markdown
# Release Runbook (Orphan Branch)

This runbook is the maintainer-invoked path for publishing …

## Prerequisites

- Clean working tree (no uncommitted changes).
- Target public remote configured …
- Neutrality gate green: `bash bin/check-neutrality.sh` exits 0.
- AGENTS.md / CLAUDE.md byte-equality: `bash bin/sync-claude.sh --check` exits 0.
- All Phase 7 tests green: `bash tests/phase-07/run.sh`.

## What the script publishes

…

## Dry-run first

```bash
bash bin/release.sh --remote … --dry-run
```

The script prints:
…

## Apply

```bash
bash bin/release.sh --remote … --apply
```
```

**What to copy:** The per-section shape: Prerequisites → What the script does → Dry-run first → Apply → Post-invocation → Rollback.
**What to change:** Content specifics per D-22. Also include the verbatim "Decision boundary one-liner" from CONTEXT.md §Specifics: *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."* This should appear as a pull-quote or section-header summary. Stubbed sections (suggest + verify + 4 staged migrations) get one paragraph each with `[Populated in Phase 11]` marker — mirror the current brownfield.md stub approach (line 3: `> Status: stub — populated in v1.1 Phase 10/11.`).

---

### `docs/quickstart.md` MODIFIED — single prereq line

**Analog:** Lines 5–7 of current file:

```markdown
## 0. Prerequisites

You need `bash >= 4`, `git`, and `python3`. See [reference/setup-prerequisites.md](reference/setup-prerequisites.md) for platform-specific install instructions (macOS, Debian/Ubuntu, Arch, Fedora, WSL, Windows).
```

**What to copy:** The one-sentence terse style + link-to-reference pattern.
**What to change:** Add a second paragraph or appended sentence per CONTEXT.md §Canonical-Refs: *"Brownfield onboarding requires Python 3 with `ruamel.yaml` installed (`pip install ruamel.yaml` or distro package). Not needed for greenfield users."* Consider forward-linking to `docs/reference/brownfield.md`.

---

## Shared Patterns

### Stderr-warn for observable-but-non-blocking events
**Source:** `bin/ingest.sh:96–108` (`resolve_contributor()` map-miss); Phase 9 D-21 pattern.
**Apply to:** `bin/ingest.sh` BRWN-10 strip warn (1-line variant); `bin/brownfield.sh scan` exclusion-count summary; `bin/brownfield.sh bootstrap` collision logs → REPORT.md progress mirror.

```bash
echo "WARN: no mapping for $email in .git-author-map.txt; omitting contributor:: field" >&2
echo "      Fix: add line '$email  ->  @your-handle' to .git-author-map.txt" >&2
echo "      Or: re-run with --contributor @your-handle" >&2
```

**Usage rule:** Primary message first; context/rationale indented; actionable fix last. Single-line OK for brief warns (D-21 BRWN-10 case); multi-line for recoverable-setup-error guidance (COLAB-04 case).

### Hardcoded array + user-override config-file
**Source:** `bin/check-neutrality.sh:94` (`PUBLIC_PATHS`); `bin/release.sh:18–38` (`ALLOWLIST` + `DENYLIST_PATHS`); CONTEXT.md §Established-Patterns.
**Apply to:** `.brownfield-ignore` denylist defaults (built-in hardcoded bash array) + optional user-supplied `.brownfield-ignore` file at repo root.

**Invariant:** Hardcoded arrays require a PR to change — this IS the review lever. User overrides go in a separate, repo-root, gitignore-grammar file.

### Bash→Python3 heredoc env transport
**Source:** `bin/lint.sh:240–252`; `bin/check-neutrality.sh:96–107`; `bin/check-privacy.sh:74–77`.
**Apply to:** `bin/brownfield.sh` scan + bootstrap Python blocks. Ingestion of flags (`--apply`, `--verbose`, `--list-excluded`), paths (`--root`), and config (`.brownfield-ignore` contents if pre-parsed in bash) via `BROWNFIELD_*` env vars.

### Self-analog pattern for lint.sh extension
**Source:** `bin/lint.sh:296–312` (CI_SEVERITY_REMAP) — Phase 9 Plan 03 added `contributor` + `skip-count` as single-line additions with `# Plan 03 populates` comments. Add `brownfield` similarly with a `# Phase 10 populates` comment.

### Byte-equality golden-file contract with regeneration escape hatch
**Source:** `tests/phase-08/test_canonical_byte_equality.sh:28–41` + `schema/fixtures/README.md:22–33`.
**Apply to:** All 6 `tests/phase-10/fixtures/*/` — every test must print the regeneration command on failure. D-07 dual-contract (transformed-output + skip-artifact) both use the same `cmp -s` gate.

### Pre-commit hook auto-sync for AGENTS.md/CLAUDE.md
**Source:** `.githooks/pre-commit`; `bin/sync-claude.sh`.
**Apply to:** Any commit touching `AGENTS.md §5` or `schema/AGENTS.template.md`. The hook auto-stages `CLAUDE.md` — planner should explicitly sequence `canonical-AGENTS.md` fixture regen into the same plan/commit to avoid a trailing CI failure per §5 edit.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `bin/brownfield.sh` subcommand dispatch | shell dispatch | flag parse | No existing `bin/*.sh` is subcommanded; Phase 10 is the first. Pattern must be composed from `case` idiom + CONTEXT.md recommendation. |
| ruamel.yaml round-trip write | YAML round-trip | fs write | PyYAML `safe_load` (used in `bin/lint.sh`, `bin/check-*.sh`) is the only YAML idiom in the codebase. ruamel.yaml is the first preserving-roundtrip user. Consult <https://yaml.readthedocs.io/en/latest/> per CONTEXT.md §External-Specs. |
| `.brownfield-ignore` gitignore-grammar parser | config parse | glob match | No existing `.gitignore`-style user-config parser in the codebase. CONTEXT.md §Claude's-Discretion-#3 recommends `pathspec` Python module; otherwise inline implementation. |
| Typed-merge policy (Class A/B/C) | YAML transform | merge logic | Fully novel per CONTEXT.md §Established-Patterns. No prior decision-tree-over-per-field-class precedent. Must be encoded fresh from D-02 spec. |

---

## Metadata

**Analog search scope:** `/home/yishai/Documents/compendium/bin/`, `/home/yishai/Documents/compendium/tests/phase-07..09/`, `/home/yishai/Documents/compendium/schema/fixtures/`, `/home/yishai/Documents/compendium/docs/reference/`, `/home/yishai/Documents/compendium/AGENTS.md §5`, `/home/yishai/Documents/compendium/.githooks/`.
**Files scanned:** ~35 (11 `bin/*.sh`, 3 test harnesses + 8 fixture dirs, 4 reference docs, AGENTS.md, schema template, pre-commit hook).
**Pattern extraction date:** 2026-04-17.
