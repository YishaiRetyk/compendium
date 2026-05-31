# Phase 13: Claim Faithfulness Audit - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 11 (NEW: 6 code/data + tests dir; MODIFY: 3 mirror files; REFERENCE: 1)
**Analogs found:** 10 / 11 (1 greenfield with grounding source — privacy_resolve.py)

> All line numbers below are quoted from the LIVE files this session (lint.sh is 2058 lines, `LINT_VERSION="1.3.0"` — the CONTEXT's "1895 lines" is stale, as RESEARCH flagged). Quote the live code, not CONTEXT line numbers.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `bin/audit-claims.sh` (NEW) | utility/CLI | batch (select→resolve→route→emit) | `bin/lint.sh` | role+flow match (copy, not import) |
| `bin/lib/privacy_resolve.py` (NEW) | utility/lib module | transform (pure fn) | `bin/lib/brownfield_provenance.py` (shape) + `bin/check-privacy.sh` (regex) | shape-match; LOGIC is greenfield |
| `tests/phase-13/run.sh` (NEW) | test | batch aggregator | `tests/phase-12.2/run.sh` | exact |
| `tests/phase-13/lib.sh` (NEW) | test | helper | `tests/phase-12.2/lib.sh` | exact (+ 2 new helpers) |
| `tests/phase-13/test_*.sh` (NEW) | test | request-response (per-scenario) | `tests/phase-12.2/test_staged_*.sh` | exact |
| `tests/phase-13/fixtures/` (NEW) | test fixture | file-I/O | (none — built inline via `write_page`, per RESEARCH) | greenfield, grounded in fixture-realism note |
| `wiki/maintenance/audit-report.md` (NEW, generated) | config/report artifact | file-I/O (write) | `wiki/maintenance/lint-report.md` (on disk) | exact |
| `wiki/maintenance/audit-state.md` (NEW, generated) | config/checkpoint | file-I/O (write) | AGENTS.md §11.4 `reflect-state.md` spec (NOT on disk) | spec-only model |
| `AGENTS.md` §6 (MODIFY) | config/schema | — | §6 locator table (line 410-418) | exact insertion point |
| `schema/AGENTS.template.md` + `CLAUDE.md` (MODIFY) | config mirror | — | `bin/sync-claude.sh` byte-copy + `.githooks/pre-commit` | exact 3-way mirror |
| `bin/check-privacy.sh` (REFERENCE) | utility/CLI | — | (is itself the reference) | pattern source only |

---

## Pattern Assignments

### `bin/audit-claims.sh` (utility/CLI, batch)

**Analog:** `bin/lint.sh` (2058 lines). The audit is a NEW bash-arg-parse → single python3 heredoc script that mirrors lint's structure. **COPY** the embedded primitives — lint's python is one monolithic `python3 << 'PYEOF'` heredoc, NOT an importable module (RESEARCH Assumption A1).

**Imports / version pin pattern** (lint.sh:1-13):
```bash
#!/usr/bin/env bash
set -euo pipefail
LINT_VERSION="1.3.0"   # audit: define AUDIT_VERSION; --version/--require-version semver pin optional
```
Copy: the shebang, `set -euo pipefail`, a `*_VERSION` semver const. Change: rename to `AUDIT_VERSION`; the audit is review-only so a `--require-version` pin is optional (lint needs it for CI).

**Bash arg-parse loop** (lint.sh:105-159 — `while [ "$#" -gt 0 ]; do case "$1" in`):
```bash
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --category)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --category requires a value" >&2; exit 1
            fi
            CATEGORY="$2"; shift 2 ;;
        --format)
            case "$2" in
                text|json) FORMAT="$2" ;;
                *) echo "ERROR: --format must be 'text' or 'json', got '$2'" >&2; exit 1 ;;
            esac
            shift 2 ;;
        --ci) CI_MODE=1; shift ;;
```
Copy: the `case "$1"` dispatch, the `[ "$#" -lt 2 ]` "requires a value" guard idiom, the `--format text|json` validated enum. Change: add audit flags — `--since`, `--sample N`, `--select`, `--emit-worklist`, `--apply-verdicts <f>`, `--verifier <cmd>`, `--allow-local` (names are Claude's discretion; semantics fixed by D-01/D-02/D-09).

**bash→python env export + heredoc handoff** (lint.sh:254-280, and the simpler `set +e; python3 - <<'PYEOF' ... PYEOF; PYRC=$?; set -e; exit "$PYRC"` form at check-privacy.sh:78-147):
```bash
export LINT_WIKI_DIR="$WIKI_DIR"
export LINT_FORMAT="$FORMAT"
export LINT_CATEGORY="$CATEGORY"
export LINT_REPO_ROOT="${LINT_REPO_ROOT:-$PWD}"

python3 << 'PYEOF'
import sys, os, re, yaml
from datetime import date, timedelta
from pathlib import Path
wiki_dir = os.environ['LINT_WIKI_DIR']
category_filter = os.environ['LINT_CATEGORY']
LINT_FORMAT = os.environ.get('LINT_FORMAT', 'text')
REPO_ROOT = os.environ.get('LINT_REPO_ROOT', os.getcwd())
```
Copy: the `export AUDIT_*=...` block, the `python3 << 'PYEOF'` quoted-heredoc (single-quote the delimiter so bash does NOT interpolate `$`), `os.environ[...]` reads at the top. **Prefer check-privacy.sh's `set +e / PYRC=$? / set -e / exit "$PYRC"` wrapper** (check-privacy.sh:78,145-147) so the python exit code propagates cleanly — RESEARCH Pattern 1 cites exactly this.

**`parse_frontmatter` — COPY VERBATIM** (lint.sh:406-422):
```python
def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page."""
    try:
        content = open(filepath, encoding='utf-8').read()
    except Exception as e:
        return None, '', str(e)
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'
```
Copy verbatim. Used for both page loading AND source-summary loading (registry build below).

**`PROV_RE` + `EPISTEMIC_INLINE_RE` + `SOURCE_EXTRA_FIELDS` + `EXCLUDE_DIRS` — COPY VERBATIM** (lint.sh:382-395):
```python
SOURCE_EXTRA_FIELDS = ['path', 'content_hash', 'ingested_at', 'source_type', 'compilation_status']
PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')
EXCLUDE_FILES = {'index.md', 'log.md'}
EXCLUDE_DIRS = {'maintenance', 'examples'}
```
Copy: all four. `PROV_RE.findall(body)` yields `(source_id, locator, support_type, checked_at)` tuples — exactly the FAITH-02 src/locator extraction + FAITH-01 stale-selector input. `EPISTEMIC_INLINE_RE` captures `inferred`/`tentative` for the FAITH-01 epistemic selector (D-13: reuse, invent no new vocabulary). `EXCLUDE_DIRS`/`EXCLUDE_FILES` for the page walk; also honor `example: true` skip (lint.sh:971: `if isinstance(fm, dict) and fm.get('example') is True: continue`).

**Page walk + source-registry build — COPY** (lint.sh:960-981):
```python
        fm, body, err = parse_frontmatter(fpath)
        if isinstance(fm, dict) and fm.get('example') is True:
            continue
        all_pages.append((fpath, fm, body, err))
        if fm and fm.get('type') == 'source':
            source_pages.append((fpath, fm, body))

# Build source registry: source_id -> source fm
source_registry = {}
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        source_registry[sfm['id']] = sfm
```
Copy: the walk classification (`type == 'source'` → `source_pages`) and the `source_registry[id] = fm` dict. This is the D-11 resolution anchor — `source_registry[source_id]['path']` is the repo-root-relative path to the RAW source. **Change (the FAITH-02 crux, D-11):** after resolving, open the RAW file at `repo_root/path`, NEVER the summary page body (RESEARCH Pattern 2):
```python
sfm = source_registry.get(source_id)
raw_path = os.path.join(repo_root, sfm['path'])      # sources/2026/.../source.md
raw_text = open(raw_path, encoding='utf-8').read()   # NOT the wiki/sources/*.md summary
passage = resolve_locator(raw_text, locator)         # None -> insufficient-locator
```
Guard a missing raw file gracefully (examples cluster ships summaries but not raw files — verified) → `insufficient-locator`, never crash. Guard `..`-escaping `path:` (Security: path traversal) → reject/skip.

**Stale-source selector (hash drift) — COPY the predicate** (lint.sh:1224-1239):
```python
for src_id, sfm in source_registry.items():
    content_hash = sfm.get('content_hash', '')
    compiled_hash = sfm.get('compiled_against_hash', '')
    comp_status = sfm.get('compilation_status', '')
    if content_hash and compiled_hash and content_hash != compiled_hash and comp_status != 'stale':
        # ... find pages with prov markers referencing this source
```
Copy: the `content_hash != compiled_against_hash` drift predicate → the D-09 **stale-source** selector (highest-priority rank). Change: instead of emitting a `stale` finding, use it to flag the claims for sampling.

**High-fanout selector (inbound-link map) — COPY** (lint.sh:1106-1121):
```python
inbound_links = {}  # page_id -> set of linking page_ids
for pid in page_ids:
    inbound_links[pid] = set()
for fpath, fm, body, err in all_pages:
    if fm is None or body is None:
        continue
    linker_id = fm.get('id', '')
    wikilinks = WIKILINK_RE.findall(body)
    for target in wikilinks:
        target_lower = target.strip().lower()
        resolved_ids = resolution_map.get(target_lower, set())
        for rid in resolved_ids:
            if rid != linker_id:
                inbound_links.setdefault(rid, set()).add(linker_id)
```
Copy: the inbound-link map build (needs `WIKILINK_RE` lint.sh:384 + the lowercase `resolution_map` from lint.sh:1082-1104). `len(inbound_links[pid])` = fanout → the D-09 **high-fanout** selector (lowest-priority rank). Change: this is downstream of selection; per D-09 it ranks last.

**Recency selector (git diff) — COPY the subprocess shape** (lint.sh:463-490 `strict_added_epistemic_claims`):
```python
result = subprocess.run(
    ['git', 'diff', '--unified=0', f'{base_ref}...HEAD', '--', 'wiki/'],
    cwd=REPO_ROOT, check=True, capture_output=True, text=True,
)
```
Copy: the `subprocess.run(['git','diff', ...'wiki/'], cwd=REPO_ROOT, ...)` pattern. Change: use the audit checkpoint ref (`last_audit_commit` from audit-state.md) as `base_ref`, falling back to a wiki-wide scan when no checkpoint exists (mirror lint's origin/main fallback at lint.sh:455-460). This is the D-09 **recently-modified** selector (3rd-priority rank).

**Finding dict + JSON emitter — EXTEND, do not fork** (lint.sh:403-404, 1911-1922):
```python
# lint's tuple has NO line slot (RESEARCH fact #2):
def add_finding(severity, category, path, message):
    findings.append((severity, category, path, message))
# ... JSON emit:
payload.append({
    'severity': sev, 'category': cat, 'path': path, 'message': msg,
})
sys.stdout.write(json.dumps(payload, indent=2) + '\n')
```
Copy: the JSON emit shape (`json.dumps(payload, indent=2)` to stdout). **Change (D-14, RESEARCH fact #2):** lint's 4-tuple has no `line` slot — the audit needs its OWN richer 9-key finding dict that is a JSON-SUPERSET of lint's 4 keys (SC-6 = "shares `severity/category/path/message`, adds more"):
```python
finding = {
    "severity": "warning",        # contradicts->warning; else info (D-14); NEVER error
    "category": "faithfulness",
    "path": "wiki/concepts/foo.md",
    "message": rationale_one_line,
    "line": 42,
    "source_id": "src-2026-04-15-x",
    "locator": "#sec:intro",
    "verdict": "weak",            # supports|weak|contradicts|insufficient|insufficient-locator|skipped-privacy|skipped-nontext
    "rationale": rationale_one_line,
}
```

**Report writer — COPY the `format_findings` grouper + frontmatter template** (lint.sh:1937-2006):
```python
def format_findings(sev):
    items = [f for f in findings if f[0] == sev]
    if not items: return '(none)\n'
    from collections import OrderedDict
    cats = OrderedDict()
    for s, cat, path, msg in items:
        cats.setdefault(cat, []).append((path, msg))
    lines = []
    for cat, entries in cats.items():
        lines.append(f'### {cat.title()}')
        for path, msg in entries:
            lines.append(f'- **{path}** | {msg}')
        lines.append('')
    return '\n'.join(lines) + '\n'
```
Copy: the group-by + section-render. Change: group by **verdict** (D-14) instead of severity-then-category; preserve `created_at` from existing report (lint.sh:1942-1953). See audit-report.md assignment below.

---

### `bin/lib/privacy_resolve.py` (utility/lib module, transform)

**Analog (SHAPE only):** `bin/lib/brownfield_provenance.py` — a small pure-python helper consumed by a `.sh` heredoc. **Analog (REGEX/exit-code only):** `bin/check-privacy.sh`. **The §13 precedence LOGIC is greenfield** — RESEARCH fact #1: no §13 resolver exists; check-privacy.sh is a leak-grep, not a precedence resolver.

**Module docstring/contract shape** (brownfield_provenance.py:1-21):
```python
"""Bullet-eligibility heuristics for 02-provenance-bootstrap.sh.
NO LLM CALLS. Pure mechanical transforms (BRWN-16 hard-lock).
Consumed by:
  - schema/brownfield/migrations/02-provenance-bootstrap.sh
Exports:
  - is_top_level_bullet(line) -> bool
See AGENTS.md §11.5 for the brownfield workflow contract...
"""
import re
```
Copy: the docstring shape (purpose / "NO LLM CALLS / NO EGRESS" lock / "Consumed by: bin/audit-claims.sh" / "Exports:" / "See AGENTS.md §13"). The privacy resolver is pure-local and must egress nothing — state that explicitly per Pitfall 3.

**How a `.sh` heredoc imports a `bin/lib/` module** (schema/brownfield/migrations/01-page-typing.sh:120-126):
```bash
export BROWNFIELD_LIB_DIR DECISIONS_FILE ...
python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_yaml import read_fm_body, write_roundtrip, VALID_ENUMS
```
Copy: the `sys.path.insert(0, <lib_dir>)` then `from privacy_resolve import resolve_source_privacy` idiom. `audit-claims.sh` exports the lib dir (e.g. `AUDIT_LIB_DIR="$(dirname "$0")/lib"`) and the heredoc inserts it on `sys.path`. NOTE: lint.sh itself does NOT import from bin/lib (it's self-contained) — the brownfield migration scripts are the precedent for the import-from-lib pattern.

**The §13 resolver body — BUILD NEW** (grounded in AGENTS.md §13 Decision Table; RESEARCH Code Examples):
```python
def resolve_source_privacy(source_fm, source_path):
    fm_priv = (source_fm or {}).get('privacy')
    explicit = fm_priv if fm_priv in ('local_only', 'cloud_safe') else None
    dir_priv = None
    if '/local-only/' in source_path or source_path.startswith('local-only/'):
        dir_priv = 'local_only'
    elif '/cloud-safe/' in source_path:
        dir_priv = 'cloud_safe'
    candidates = [p for p in (explicit, dir_priv) if p]
    if not candidates:
        return 'local_only'                      # fail-closed default (§13 row 6)
    return 'local_only' if 'local_only' in candidates else 'cloud_safe'  # stricter wins
```
Change from check-privacy.sh: that file only greps `^privacy:\s*local_only\s*$` (check-privacy.sh:87) inside a frontmatter block — it has no dir-default and no stricter-wins resolution. Build the full 3-level precedence here. **This module is the single FAITH-04 chokepoint** — `audit-claims.sh` calls it BEFORE the verdict step and partitions `local_only` out of the cloud worklist (D-02).

**Reusable frontmatter-block extractor (if not importing lint's)** (check-privacy.sh:89-97) is a lighter alternative to `parse_frontmatter` if the resolver only needs the `privacy:` field.

---

### `tests/phase-13/run.sh` (test, aggregator)

**Analog:** `tests/phase-12.2/run.sh` — COPY near-verbatim (verified lines 27-40).

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; TOTAL=0; FAILED_TESTS=()
shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    TOTAL=$((TOTAL + 1))
    name="$(basename "$t")"
    echo "--- Running $name ---"
    if bash "$t"; then PASS=$((PASS + 1)); echo "--- PASS $name ---"
    else FAIL=$((FAIL + 1)); FAILED_TESTS+=("$name"); echo "--- FAIL $name ---"; fi
done
echo ""; echo "PHASE 12.2 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then echo "Failed: ${FAILED_TESTS[*]}" >&2; exit 1; fi
exit 0
```
Copy: the `shopt -s nullglob` glob loop, pass/fail tally, non-zero exit on any failure. Change: rename header to `PHASE 13 TESTS`; the `--full` flag (run.sh:6-19) is optional (12.2 keeps it a no-op).

---

### `tests/phase-13/lib.sh` (test, helper)

**Analog:** `tests/phase-12.2/lib.sh` — COPY `make_bare_repo` / `write_page` / `assert_exit_code` / `cleanup_fixture_repo` verbatim (verified lines 15-69), then ADD `make_fake_verifier` + `make_recording_verifier`.

```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

make_bare_repo() {
    local tmp; tmp="$(mktemp -d -t phase13-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2; return 1; fi
}
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then rm -rf "$path"; fi
}
write_page() {
    local repo="$1" relpath="$2"
    mkdir -p "$repo/$(dirname "$relpath")"
    cat > "$repo/$relpath"   # body from stdin (heredoc)
}
export -f make_bare_repo assert_exit_code cleanup_fixture_repo write_page
```
Copy: all four helpers + the `REPO_ROOT` derivation + the `export -f` line. Change: bump mktemp prefix to `phase13-`; `write_page` is used to write BOTH the `wiki/sources/<id>.md` summary AND the raw `sources/**/source.md` file (fixture-realism note — fixtures must be self-contained). **ADD** the fake-verifier helpers (RESEARCH Validation Architecture, verified shape):
```bash
make_fake_verifier() {   # $1=repo $2=verdict $3=rationale
    cat > "$1/fake-verifier.sh" <<EOF
#!/usr/bin/env bash
read -r _input
printf '{"verdict":"%s","rationale":"%s","sub_claims":[]}\n' "$2" "$3"
EOF
    chmod +x "$1/fake-verifier.sh"; echo "$1/fake-verifier.sh"
}
# make_recording_verifier appends every stdin passage to "$repo/verifier-saw.log"
# (for the load-bearing fail-closed partition negative test, D-02).
```

---

### `tests/phase-13/test_*.sh` (test, per-scenario)

**Analog:** `tests/phase-12.2/test_staged_blocks_concept_no_prov.sh` (representative — verified full file).

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
...
---
Foo concept body without any provenance markers.
EOF
(cd "$REPO" && git add wiki/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" >/tmp/out.$$ 2>/tmp/err.$$)
rc=$?
set -e

if ! assert_exit_code 1 "$rc" "blocked: greenfield concept without [prov:]"; then
    cat /tmp/out.$$ /tmp/err.$$ >&2 || true; rm -f /tmp/out.$$ /tmp/err.$$; exit 1
fi
if ! grep -qi "prov" /tmp/out.$$ /tmp/err.$$; then
    echo "FAIL: error output should mention provenance" >&2; ...; exit 1
fi
rm -f /tmp/out.$$ /tmp/err.$$
echo "PASS: blocked: greenfield concept without [prov:]"
```
Copy per-scenario: the `source lib.sh` → `REPO=$(make_bare_repo)` → `trap cleanup` → `write_page` heredoc → `git add` → `set +e; <run>; rc=$?; set -e` → `assert_exit_code` → `grep` on captured output → `echo PASS`. Change per test: invoke `bin/audit-claims.sh` instead of `bin/lint.sh`; seed self-contained source+raw fixtures; use `make_fake_verifier`/`make_recording_verifier` to make the non-deterministic verdict step reproducible. One test per Req→Test row (RESEARCH Validation Architecture table — ~23 tests). The **load-bearing negative test** (`test_privacy_partition_fail_closed.sh`) asserts the recording verifier's log NEVER contains the `local_only` source's marker text (D-02 mechanical enforcement).

---

### `wiki/maintenance/audit-report.md` (generated report)

**Analog:** `wiki/maintenance/lint-report.md` (ON DISK — verified, 13KB). Pattern-twin frontmatter + body.

**Frontmatter template** (lint-report.md:1-22, generated by lint.sh:1975-1996):
```yaml
---
id: lint-report
title: Lint Report
type: overview
status: active
summary: "Wiki health-check findings from most recent lint run."
created_at: 2026-04-30
updated_at: 2026-05-07
sources: []
epistemic_status: sourced
tags:
  - meta
  - maintenance
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Lint Report
has_contradictions: false
knowledge_domain: ""
---
```
Copy: the full base-field frontmatter (`type: overview`, `tags: [meta, maintenance]`, `privacy: cloud_safe`, preserve `created_at`). Change: `id: audit-report`, `title: Audit Report`, summary references the faithfulness audit. Body header `**Last run:** / **Total findings:** / **Auto-fixes applied:**` → adapt to `**Sample size:** / **Selected/Skipped:**` (D-09 honest-sampling counts). **Group by verdict** (D-14), not severity-then-category — reuse the `format_findings` grouper (lint.sh:1958-1973) keyed on `verdict`. This file is under `EXCLUDE_DIRS={'maintenance',...}` (lint.sh:395) so the audit never recursively audits its own report — same as lint.

---

### `wiki/maintenance/audit-state.md` (generated checkpoint)

**Analog:** AGENTS.md §11.4 `reflect-state.md` spec (AGENTS.md:1158-1183). **NOTE: `reflect-state.md` does NOT exist on disk** (verified — only `lint-report.md` is present) — model from the spec, not a live file (RESEARCH).

**Checkpoint field spec** (AGENTS.md:1161-1163):
```
- last_reflect_log_entry: full heading line of last log entry scanned
- last_reflect_commit:     short SHA of last git commit inspected
- last_reflect_at:         ISO 8601 date of last reflect pass
```
Copy: the frontmatter-checkpoint pattern (3 tracking fields), the "control-plane, NOT in index.md" placement (AGENTS.md:1165), and the "advances even on a no-finding run" invariant (AGENTS.md:1183). Change (D-15): fields are `last_audit_commit`, `last_audit_at`, `last_sample_size`. Reuse lint's report frontmatter shape (above) for the base fields; reuse the `created_at`-preservation read (lint.sh:1942-1953) when re-writing the checkpoint.

---

### `AGENTS.md` §6 + `schema/AGENTS.template.md` + `CLAUDE.md` (3-way mirror, MODIFY)

**Insertion point** (AGENTS.md:410-418 — the §6 Locator Types table):
```markdown
### Locator Types

| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | `#p12-14`, `#p8` | PDFs, papers |
| Section | `#sec:<name>` | `#sec:introduction` | Markdown sections |
| Paragraph | `#para<number>` | `#para3` | Specific paragraphs |
| Timestamp | `#t<start>-<end>` | `#t00:12:10-00:12:48` | Audio/video transcripts |
| Image | `#img<number>` | `#img2` | Figures, diagrams |
```
Change: add a "Page-marker convention" subsection immediately AFTER this table (RESEARCH Open Q3) documenting `<!-- page: N -->` (D-05): HTML comment at page boundaries, Obsidian-invisible, grep-able, NO `[prov:]` grammar change; `#p8` slices `page: 8` marker → `page: 9` marker; `#p12-14` spans `page: 12` → `page: 15` (exclusive); optional, absent → `insufficient-locator` (D-06). **Use abstract placeholders only** (`<source-id>`, `<YYYY-MM-DD-slug>`) per CLAUDE.md §3 neutrality rule — verify with `bin/check-neutrality.sh`.

**The 3-way mirror mechanism:**
1. `bin/sync-claude.sh` (sync-claude.sh:33-34) byte-copies AGENTS.md → CLAUDE.md:
   ```bash
   cp "$SRC" "$DST"   # SRC=AGENTS.md, DST=CLAUDE.md
   cmp -s "$SRC" "$DST" || { echo "ERROR: post-copy byte-mismatch" >&2; exit 1; }
   ```
2. `.githooks/pre-commit` (pre-commit:6-12) enforces byte-equality, AUTO-syncs + re-stages on drift:
   ```bash
   if ! bash bin/sync-claude.sh --check 2>/dev/null; then
       echo "CLAUDE.md drift detected. Auto-syncing..." >&2
       bash bin/sync-claude.sh; git add CLAUDE.md
       echo "CLAUDE.md resynced and re-staged. Re-run commit." >&2; exit 1
   fi
   ```
   → **CLAUDE.md is auto-handled** — edit AGENTS.md, the hook (or `bash bin/sync-claude.sh`) propagates byte-equal to CLAUDE.md. Do NOT hand-edit CLAUDE.md.
3. `schema/AGENTS.template.md` is the wizard source with `{{PLACEHOLDER}}` tokens (e.g. `{{PRIMARY_DOMAIN}}`, template.md:277) — mirror the §6 addition here MANUALLY (it's not byte-copied; it carries wizard placeholders). CONTEXT canonical-refs also note the Phase 11-05 canonical-fixture regenerate path may need updating.

**Prior 3-way precedent:** every §6/§11.3/§13 schema amendment that landed since Phase 9 used this exact AGENTS.md → (sync-claude byte-copy) → CLAUDE.md + manual template mirror. The pre-commit hook makes the CLAUDE.md leg mechanical.

---

## Shared Patterns

### Bash arg-parse → single python3 heredoc (deterministic core)
**Source:** `bin/lint.sh:105-280` + `bin/check-privacy.sh:45-147`
**Apply to:** `bin/audit-claims.sh`
- `while [ "$#" -gt 0 ]; do case "$1" in` with `[ "$#" -lt 2 ]` "requires a value" guards.
- `export AUDIT_*=...` → `python3 - <<'PYEOF'` (single-quoted delimiter) → `os.environ[...]`.
- check-privacy's exit-propagation wrapper: `set +e; python3 - <<'PYEOF' ... PYEOF; PYRC=$?; set -e; exit "$PYRC"`.

### Copy-not-import lint primitives
**Source:** `bin/lint.sh` (monolithic heredoc — not importable; RESEARCH A1)
**Apply to:** `bin/audit-claims.sh` python block
- `parse_frontmatter` (406-422), `PROV_RE` (385-390), `EPISTEMIC_INLINE_RE` (391), `SOURCE_EXTRA_FIELDS` (382), `EXCLUDE_DIRS`/`EXCLUDE_FILES` (394-395), `example: true` skip (971), source-registry build (977-981), hash-drift predicate (1224-1239), inbound-link map (1106-1121), git-diff subprocess (463-490). Copy verbatim into the audit heredoc.

### bin/lib import-from-heredoc
**Source:** `schema/brownfield/migrations/01-page-typing.sh:120-126`
**Apply to:** `bin/audit-claims.sh` importing `bin/lib/privacy_resolve.py`
- `export AUDIT_LIB_DIR` → heredoc `sys.path.insert(0, os.environ['AUDIT_LIB_DIR']); from privacy_resolve import resolve_source_privacy`.

### JSON-superset finding (SC-6 compatibility)
**Source:** `bin/lint.sh:403-404, 1911-1922` (4-tuple, NO line slot)
**Apply to:** the audit's emitter
- Keep lint's 4 keys (`severity/category/path/message`); ADD `line/source_id/locator/verdict/rationale` (D-14). `json.dumps(payload, indent=2)` to stdout. Severity: `contradicts`→warning, else info, NEVER error.

### Control-plane checkpoint + report (not indexed)
**Source:** `wiki/maintenance/lint-report.md` (on disk) + AGENTS.md §11.4 `reflect-state.md` spec
**Apply to:** `audit-report.md` (group-by-verdict) + `audit-state.md` (3 checkpoint fields, advances on no-finding run)
- `EXCLUDE_DIRS={'maintenance'}` keeps these out of the audit's own scan; not listed in `wiki/index.md`.

### Test harness (bash-is-the-framework)
**Source:** `tests/phase-12.2/run.sh` + `lib.sh` + `test_staged_*.sh`
**Apply to:** all of `tests/phase-13/`
- `run.sh` nullglob loop + tally; `lib.sh` `make_bare_repo`/`write_page`/`assert_exit_code`/`cleanup_fixture_repo` (copy verbatim) + NEW `make_fake_verifier`/`make_recording_verifier`; per-test `source lib.sh → make_bare_repo → trap → write_page → set +e/rc=$?/set -e → assert_exit_code`.

### 3-way schema mirror
**Source:** `bin/sync-claude.sh` + `.githooks/pre-commit`
**Apply to:** the §6 page-marker edit
- Edit AGENTS.md; sync-claude byte-copies → CLAUDE.md (hook-enforced); hand-mirror to `schema/AGENTS.template.md`; abstract placeholders only (`bin/check-neutrality.sh`).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `bin/lib/privacy_resolve.py` (LOGIC) | utility/lib | transform | RESEARCH fact #1: no §13 three-level precedence resolver exists in-repo. `check-privacy.sh` is a leak-grep (greps `privacy: local_only` in PUBLIC_PATHS), NOT a precedence resolver. SHAPE is borrowed from `bin/lib/brownfield_provenance.py`; the resolution LOGIC is greenfield, grounded in AGENTS.md §13 Decision Table. This is the file that needs the most tests. |
| `tests/phase-13/fixtures/` (content) | test fixture | file-I/O | Per RESEARCH fixture-realism note: `examples/kahneman/` summaries point at raw files NOT on disk, so fixtures must be self-contained — each test writes BOTH the `wiki/sources/<id>.md` summary AND the raw `sources/**/source.md` (with real `## headings`, blank-line paragraphs, `<!-- page: N -->` markers) inline via `write_page`. No copy-from-existing-fixture analog. |
| `wiki/maintenance/audit-state.md` (live model) | checkpoint | file-I/O | Pattern-twin `reflect-state.md` is NOT on disk — model from AGENTS.md §11.4 spec (fields + invariants), not a live file. |

---

## Metadata

**Analog search scope:** `bin/` (lint.sh, check-privacy.sh, sync-claude.sh, lib/), `tests/phase-12.2/`, `schema/brownfield/migrations/`, `schema/AGENTS.template.md`, `.githooks/`, `wiki/maintenance/`, `AGENTS.md §6/§11.4/§13`.
**Files scanned:** ~14 (live code + spec sections).
**Key corrections vs CONTEXT (confirmed live this session):** lint.sh is **2058 lines / `LINT_VERSION=1.3.0`** (not 1895); `bin/lib/` already exists (brownfield modules); `wiki/maintenance/lint-report.md` IS on disk; `reflect-state.md` is NOT on disk (spec-model only); lint's finding tuple is a **4-tuple with no `line` slot** (audit needs its own 9-key superset).
**Pattern extraction date:** 2026-05-31
