# Phase 11: Brownfield Suggest + Verify — Pattern Map

**Mapped:** 2026-04-20
**Files analyzed:** 20 (new + modified)
**Analogs found:** 20 / 20 (100%)

Phase 11 has the highest reuse ratio of any v1.1 phase (per RESEARCH.md line 459).
Every new file has a direct prior-phase analog — mostly from Phases 7, 8, 9, and 10.
This map catalogs the analog and the specific lines/patterns each new file should copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/brownfield/migrations/01-page-typing.sh` | new canonical migration script (apply-class) | scan -> manifest -> mutate-frontmatter | `bin/release.sh` (dry-run/apply) + `bin/brownfield.sh` bootstrap python-heredoc block | role-match (dry-run/apply pattern is exact; per-page frontmatter mutation is exact; manifest-driven application is NEW) |
| `schema/brownfield/migrations/02-provenance-bootstrap.sh` | new canonical migration script (apply-class) | scan-body -> append-inline-markers | `bin/brownfield.sh` bootstrap python-heredoc (lines 141-632) for read/roundtrip; `bin/ingest.sh` resolve_contributor for WARN phrasing | role-match (frontmatter-read / body-text-append is new surface; uses same ruamel.yaml round-trip) |
| `schema/brownfield/migrations/03-cross-link-inference.sh` | new canonical migration script (advisory) | scan-body -> write report section | `bin/brownfield.sh` scan branch (lines 688-977) | role-match (advisory scan + REPORT.md append) |
| `schema/brownfield/migrations/04-privacy-review.sh` | new canonical migration script (advisory) | regex-scan-body -> write findings yaml + REPORT section | `bin/check-privacy.sh` (regex + frontmatter-skip pattern) | role-match (scan semantics are identical; scope differs — vault body vs. public frontmatter) |
| `bin/brownfield.sh` (suggest branch) | modified subcommand dispatcher | orchestrate: byte-copy scripts + generate data files | `bin/brownfield.sh` scan branch (lines 639-977) + `bin/release.sh` ALLOWLIST copy loop (lines 142-147) | exact (subcommand wired already; new branch clones existing dispatch shape) |
| `bin/brownfield.sh` (review-typing branch) | modified subcommand dispatcher | TTY prompt loop OR large-batch prompt-file emit | `bin/init-wizard.sh` `prompt_once()` + stderr-prompt pattern (lines 448-464); isatty check is NEW | role-match |
| `bin/brownfield.sh` (verify branch) | modified subcommand dispatcher | lint-wrap; optional `--promote` page iteration | `bin/lint.sh --ci --format json` invocation + `bin/lib/brownfield_yaml.py` round-trip | role-match |
| `bin/lib/brownfield_classify.py` (cluster_by_signals) | extended library function | pure transform (classifications -> clusters) | `classify_page()` in same file (lines 31-139) | exact (same module; extends API per reserved-param convention) |
| `bin/lib/brownfield_provenance.py` (NEW — planner option) | new library module | pure function (line -> eligibility bool) + section scan | `bin/lib/brownfield_classify.py` module shape + `bin/lib/brownfield_yaml.py` `extract_h1()` regex-scan (lines 241-247) | role-match (stateless helper pattern is the established convention) |
| `bin/lib/brownfield_typing.py` (OPTIONAL — planner's call) | new library module | pure clustering + manifest I/O | `bin/lib/brownfield_classify.py` module shape | role-match |
| `.brownfield/applied.log` writer helper | inline bash function in `bin/brownfield.sh` | append-only markdown blocks | `bin/brownfield.sh` APPLIED.md `af.write(...)` block (lines 587-616) | exact (same file/same append semantics; block format is D-11-new) |
| `tests/phase-11/run.sh` | test aggregator | shell-loop + tally | `tests/phase-10/run.sh` (48 lines total) | exact (clone with 10 -> 11 rename) |
| `tests/phase-11/lib.sh` | test helpers | fixture-repo creation + byte-equal assertions | `tests/phase-10/lib.sh` (83 lines total) | exact (clone with 10 -> 11 rename + add byte-equality for canonical scripts) |
| `tests/phase-11/fixtures/*/` (5 fixtures) | test fixtures | read-only vault simulacra | `tests/phase-10/fixtures/` + fixture-date env vars | exact (shape is identical; new fixtures per D-20) |
| `tests/phase-11/test_canonical_byte_equality.sh` | byte-identity CI | cmp canonical vs .brownfield/migrations/ | `tests/phase-08/test_canonical_byte_equality.sh` (67 lines) | role-match (Phase 8 compares wizard-rendered AGENTS.md; Phase 11 compares byte-copied scripts) |
| `AGENTS.md §11.5` (Brownfield Workflow block) | schema canonical contract | none (normative prose) | `AGENTS.md §11.1` Ingest Workflow (lines 866-902) | exact (Trigger/Inputs/Outputs/Commit/Steps/Abort template) |
| `schema/AGENTS.template.md §11.5` (mirror) | template mirror | none (normative prose) | `schema/AGENTS.template.md §11.1` (line 871) | exact (Phase 9.1 template-parity test enforces byte-equivalence modulo placeholder tokens) |
| `schema/fixtures/canonical-AGENTS.md` (regen) | regenerated byte-equality fixture | wizard render output | `tests/phase-08/test_canonical_byte_equality.sh` regeneration recipe (lines 7-10, 31-34) | exact (Phase 8-01 rendering is the canonical procedure) |
| `docs/reference/brownfield.md` (suggest/review-typing/verify sections) | doc expansion | none (operator runbook) | `docs/reference/brownfield.md` existing scan section (lines 22-49) + bootstrap section (lines 51-109) | exact (same doc; clone subcommand section shape) |
| `wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md` | Tier-1 decision record | none (DR body) | `schema/templates/decision.md` + any existing `wiki/decisions/dr-*.md` | role-match (template-driven; Phase 6 shipped the type) |

## Pattern Assignments

### `schema/brownfield/migrations/01-page-typing.sh` (apply-class; discovery/review/apply)

**Analogs:**
- `bin/release.sh` for `--apply` flag / confirmation / dry-run gate pattern
- `bin/brownfield.sh` bootstrap python-heredoc for in-place frontmatter mutation
- `bin/lib/brownfield_classify.py` for the classifier call (already reserves `inbound_count=None`)

**Flag parsing + dry-run/apply gate pattern** (copy from `bin/release.sh:91-123`):
```bash
APPLY=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)   APPLY=1; shift ;;
        --dry-run) APPLY=0; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done
# ... plan output always printed ...
if [ "$APPLY" -eq 0 ]; then
    echo "(dry-run) Pass --apply to execute."
    exit 0
fi
```

**Frontmatter round-trip mutation pattern** (copy from `bin/brownfield.sh:559-632`):
- Use `from brownfield_yaml import read_fm_body, write_roundtrip` (handles ruamel.yaml typed-merge)
- Iterate `pending_writes` list, call `write_roundtrip(path, merged, body, raw_yaml)` per page
- Halt on first failure (D-11 pattern already encoded) — Phase 11 may RELAX to "log and continue" if manifest-driven apply should be resilient; planner's call per D-02 Stage-3 deterministic mandate

**Invariant (from RESEARCH §Pattern 4, §Anti-patterns):** `--apply` MUST read `.brownfield/page-typing-decisions.yaml` ONLY. Do NOT re-classify at apply time. If vault changed, user re-runs `suggest`.

**Gotcha:** Phase 10 `brownfield.sh` bootstrap branch has an idempotency skip at line 323-326 (`if fm.get('bootstrap_stage') == 'bootstrapped': continue`). `01-page-typing.sh --apply` needs the ANALOGOUS idempotency: if the page's `type:` frontmatter already matches the decision manifest's `resolved_label`, skip the write. Don't mutate for a zero-change.

---

### `schema/brownfield/migrations/02-provenance-bootstrap.sh` (apply-class; direct apply)

**Analogs:**
- `bin/brownfield.sh` bootstrap python-heredoc (lines 141-632) for ruamel.yaml round-trip frontmatter-skip detection
- `bin/ingest.sh` `resolve_contributor()` pattern (lines 96-108) for soft stderr WARN phrasing
- Prototype `is_eligible_claim_bullet()` + `section_scan()` in RESEARCH.md lines 724-793

**Soft state-based prereq WARN pattern** (copy structure from `bin/ingest.sh:96-108`, phrasing verbatim from CONTEXT D-12):
```python
if total > 0 and untyped > total / 2:
    sys.stderr.write(
        f"WARN: {untyped} bootstrapped pages still have empty type:. "
        f"02-provenance-bootstrap works best after page typing review or on pages "
        f"with existing valid type. Proceeding anyway.\n"
    )
```

**Section scan + body mutation pattern** (NEW surface, but borrows read side from `bin/brownfield.sh:296-348`):
- Use `read_fm_body(full)` to get `(fm, body, raw_yaml)` — body comes back as a string
- Run `section_scan(body, ['TL;DR', 'Key Facts'])` per RESEARCH lines 766-783
- Mutate body line-by-line (append ` [epistemic:: inferred]` to eligible lines)
- Rebuild body string; call `write_roundtrip(path, fm, new_body, raw_yaml)` — the round-trip preserves frontmatter verbatim (critical: 02 does NOT touch frontmatter, only body)

**Gotcha:** `write_roundtrip` (per `bin/lib/brownfield_yaml.py:186-227`) re-serializes frontmatter via ruamel. For 02, the `fm` dict is unchanged — round-trip still emits byte-identical YAML (comment preservation is the feature). Test this in Plan 11-03 with a `page-with-comments` fixture.

**Contract phrase** (quote verbatim in script `--help`, from CONTEXT specifics line 375):
> *"Marks top-level bullets under `## TL;DR` and `## Key Facts` with `[epistemic:: inferred]` when the bullet looks claim-like, is not already tagged, and is not a link-only, source-list, question, task, or placeholder bullet. Never touches Detail. Reports honestly when no eligible bullets are found."*

---

### `schema/brownfield/migrations/03-cross-link-inference.sh` (advisory-only)

**Analogs:**
- `bin/brownfield.sh` scan branch (lines 639-977) for walk-and-report structure
- `bin/brownfield.sh:434-487` for REPORT.md append pattern

**Vault walk + body-text scan pattern** (copy walk from `bin/brownfield.sh:842-910`):
```python
for dirpath, dirnames, filenames in os.walk(ROOT, followlinks=False):
    # ... exclusion pruning via .brownfield-ignore (lines 831-868) ...
    for fname in filenames:
        if not fname.endswith('.md'):
            continue
        # ... parse frontmatter via parse_frontmatter() ...
        # NEW Phase 11: iterate body line-by-line, run regex per target title
```

**Build-once-use-many pattern** (REUSE-pointer from RESEARCH line 449):
- Single O(N) walk collects all page titles + aliases into a resolution map
- Per source page, scan body against that map

**REPORT.md append section pattern** (copy from `bin/brownfield.sh:436-487`):
```python
rf.write("## Cross-link candidates\n\n")
if candidates:
    for c in sorted(candidates, key=...):
        rf.write(f"- `{c['source_page']}`:{c['line_number']} -> `{c['proposed_target']}` ({c['match_type']})\n")
else:
    rf.write("_No cross-link candidates found._\n")
rf.write("\n")
```

**Gotcha (from RESEARCH §Pitfall 4):** `\b<escaped-title>\b` word-boundary match, case-sensitive per AGENTS.md §8. Filter titles to ≥2 tokens OR ≥8 chars. Skip matches inside code fences + existing `[[...]]` wikilinks. Respect first-mention-only.

---

### `schema/brownfield/migrations/04-privacy-review.sh` (advisory-only; RENAMED from 04-privacy-classification)

**Analogs:**
- `bin/check-privacy.sh` (147 lines total) for regex-scan + frontmatter-skip pattern
- `bin/brownfield.sh` scan branch for walk + REPORT.md append

**Regex scan pattern** (adapt from `bin/check-privacy.sh:87-141`):
```python
# Phase 11 PATTERN SET (per RESEARCH Q7 lines 1037-1063):
EMAIL_RE = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
PHONE_RE = re.compile(r'\b(?:\+?1[-.\s]?)?\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b')
SSN_RE = re.compile(r'\b\d{3}[-\s]\d{2}[-\s]\d{4}\b')
```

**Skip-rule pattern** (adapt from `bin/check-privacy.sh:89-97` + RESEARCH Q7 skip rules):
- Skip frontmatter block (match `^---\n...^---\n` at file start)
- Skip code-fence content (```...``` state machine)
- Skip inline-backtick spans
- Skip example-TLDs (`@example.com`, `@example.org`)

**CRITICAL contract** (D-07 hard-lock; quote verbatim from CONTEXT specifics line 376):
> *"04-privacy-review classifies findings for review priority, not for frontmatter mutation. Fail-closed `privacy: local_only` is preserved; only a human (via frontmatter edit) may downgrade."*

Key difference from `bin/check-privacy.sh`: that script is scoped to `PUBLIC_PATHS` and exits 2 on any hit (it's a CI gate). 04-privacy-review scans `wiki/**` (vault content), never exits non-zero on findings, never mutates frontmatter. The scan semantics are the same; the action posture is inverted.

**Gotcha (from RESEARCH §Pitfall 7):** False-positives on code samples are the dominant noise. The code-fence state machine MUST be correct — off-by-one closes the fence too early and the whole body scans through `@example.com` strings.

---

### `bin/brownfield.sh` (suggest branch — NEW)

**Analogs:**
- `bin/brownfield.sh` existing scan branch (lines 639-977) — python-heredoc dispatcher shape
- `bin/release.sh` ALLOWLIST copy loop (lines 142-147) — byte-copy pattern for canonical scripts
- RESEARCH §Pattern 2 (lines 287-315) — hybrid generation recipe

**Subcommand wire-up pattern** (edit `bin/brownfield.sh:51-62`, per RESEARCH §Pattern 1):
```bash
# BEFORE (remove exit-2 gate):
case "$SUBCOMMAND" in
    scan|bootstrap) ;;
    suggest|verify)
        echo "ERROR: '$SUBCOMMAND' not yet implemented — see Phase 11 (BRWN-11..20)" >&2
        exit 2 ;;
    ...
esac

# AFTER:
case "$SUBCOMMAND" in
    scan|bootstrap|suggest|review-typing|verify) ;;
    *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        usage >&2; exit 1 ;;
esac
```

**Byte-copy canonical scripts pattern** (adapt from `bin/release.sh:142-147`):
```bash
SCHEMA_MIGRATIONS_DIR="$REPO_ROOT/schema/brownfield/migrations"
BF_MIGRATIONS_DIR="$BS_ROOT/.brownfield/migrations"
mkdir -p "$BF_MIGRATIONS_DIR"
for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    cp "$SCHEMA_MIGRATIONS_DIR/$script" "$BF_MIGRATIONS_DIR/$script"
    chmod +x "$BF_MIGRATIONS_DIR/$script"
done
```

Note: `bin/release.sh` uses `cp -a` for recursive preservation. Single-file migrations use plain `cp` + explicit `chmod +x` (migration scripts must be executable; canonical source in git may not be).

**Data-generation python heredoc pattern** (copy from `bin/brownfield.sh:141-173` — imports + env-var shuttle, plus lines 690-703 for scan-style classify loop):
```bash
export BROWNFIELD_ROOT="$BS_ROOT"
export BROWNFIELD_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"
export BROWNFIELD_TOOL_VERSION="1.1.0"
python3 << 'PYEOF'
import os, sys, datetime, hashlib, yaml
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_classify import classify_page, cluster_by_signals  # NEW Phase 11 func
# ... walk vault, classify, cluster, emit candidate YAMLs with D-09 metadata header ...
PYEOF
```

**Metadata header shape** (normative from CONTEXT specifics line 414-423):
```yaml
# ---
# schema_version: 1
# tool_version: <BROWNFIELD_TOOL_VERSION>
# generated_at: <UTC ISO>
# vault_root: <absolute path>
# source_script_hash: <sha256 of canonical script>
# ---
```

**op_hash computation pattern** (RESEARCH lines 669-722):
- Do NOT ship op_hash headers in canonical `schema/brownfield/migrations/*.sh` files (preserves byte-equality)
- PREPEND the computed op_hash header to `.brownfield/migrations/*.sh` at copy time
- See `compute_op_hash()` in RESEARCH §Code Examples Q2 — strip-self-reference + SHA-256

---

### `bin/brownfield.sh` (review-typing branch — NEW)

**Analogs:**
- `bin/init-wizard.sh` `prompt_once()` + stderr-prompt pattern (lines 448-464)
- RESEARCH §Pitfall 8 (lines 583-601) for isatty check
- RESEARCH §Code Examples `review_typing_tty()` / `review_typing_large_batch()` (lines 830-927)

**Stderr-prompt + stdin-capture pattern** (copy structure from `bin/init-wizard.sh:448-464`):
```bash
prompt_once() {
    local field="$1" default="$2"
    local value
    while true; do
        printf '  %s [Default: %s]: ' "$field" "$default" >&2
        if ! read -r value; then
            value=""
        fi
        if [ -z "$value" ]; then
            value="$default"
        fi
        if validate_one "$field" "$value"; then
            printf '%s\n' "$value"
            return 0
        fi
    done
}
```
Keys: prompt goes to stderr, result to stdout, EOF yields empty string (scripted-stdin CI path). Review-typing will adapt this for cluster primitives (a/r/i/o/s).

**isatty check pattern** (NEW; per RESEARCH §Pitfall 8):
```bash
if [ -t 0 ] && [ -t 1 ]; then
    TTY_MODE=1
else
    TTY_MODE=0  # Force large-batch mode even if cluster count < N
fi
```

**Branch-on-pending-count pattern** (D-04 logic):
```bash
if [ "$PENDING_CLUSTER_COUNT" -lt "$N_THRESHOLD" ] && [ "$TTY_MODE" -eq 1 ]; then
    review_typing_tty
else
    review_typing_large_batch  # writes .brownfield/review-typing-prompt.md
fi
```

**Gotcha:** CONTEXT §Claude's-Discretion says planner picks N (~20). Phase-8 `NO_COLOR` convention applies to any colorized diff output in the `inspect` sub-action.

---

### `bin/brownfield.sh` (verify branch — NEW)

**Analogs:**
- `bin/lint.sh --ci --format json` dispatcher (lines 218-249, 1748-1759)
- RESEARCH §Pattern 6 (lines 379-428) — promotion-gate per-page iteration
- `bin/lib/brownfield_yaml.py` round-trip for `bootstrap_stage` flip

**Read-only lint-wrap pattern** (wrapper — compose `bin/lint.sh` flags per D-13):
```bash
bash "$REPO_ROOT/bin/lint.sh" --ci --format json \
    --category yaml,provenance,orphan,crossref,brownfield
# NOTE: 'privacy' category NOT included — D-13 + Phase 9 D-15 boundary
```

**Promote gate pattern** (RESEARCH §Pattern 6 lines 386-428 — faithful python skeleton):
```python
import subprocess, json
from brownfield_yaml import read_fm_body, write_roundtrip

# 1. Run lint once in JSON mode
result = subprocess.run(
    ['bash', 'bin/lint.sh', '--ci', '--format', 'json',
     '--category', 'yaml,provenance,orphan,crossref,brownfield'],
    capture_output=True, text=True,
)
findings = json.loads(result.stdout)

# 2. Index findings by path (error severity only)
errors_by_path = {}
for f in findings:
    if f['severity'] == 'error':
        errors_by_path.setdefault(f['path'], []).append(f)

# 3. Per-page 5-gate check (D-14)
for page_path in find_bootstrapped_pages(root):
    fm, body, raw = read_fm_body(page_path)
    if fm.get('bootstrap_stage') != 'bootstrapped': continue   # Gate 1
    if fm.get('type') not in VALID_TYPES or fm.get('type') == '': continue  # Gate 2
    if errors_by_path.get(page_path): continue                  # Gate 3
    if fm['type'] == 'source' and not all(k in fm for k in (
            'path', 'content_hash', 'ingested_at', 'source_type')):
        continue                                                # Gate 4
    if page_in_pending_cluster(page_path): continue             # Gate 5
    fm['bootstrap_stage'] = 'verified'
    write_roundtrip(page_path, fm, body, raw)
```

**Gotcha (RESEARCH §Pitfall 6):** Gate 5 requires reading `.brownfield/page-typing-decisions.yaml` and building a set of page paths in `decision: pending` clusters. Do this ONCE at verify-start; don't re-load per page.

---

### `bin/lib/brownfield_classify.py` (NEW function: `cluster_by_signals`)

**Analog:** same module — `classify_page()` (lines 31-139) + `unknown_reason()` (lines 142-154)

**Module extension pattern (NOT replacement)** (RESEARCH line 608):
- Add new function alongside existing ones; do NOT modify `classify_page()` signature
- `inbound_count` parameter is ALREADY reserved (line 35 of current file)
- New function is pure; O(n) single pass; stdlib-only (`collections.defaultdict`)

**Signal-tuple bucketing skeleton** (RESEARCH lines 614-662):
```python
from collections import defaultdict
from typing import Iterable

def cluster_by_signals(classifications: Iterable[dict]) -> list[dict]:
    buckets = defaultdict(list)
    for c in classifications:
        s = c['signals']
        key = (
            s.get('frontmatter', 'none'),
            s.get('filename', 'none'),
            s.get('heading', 'none'),
            'inbound-heavy' if c.get('inbound_count', 0) >= 5 else 'inbound-light',
            s.get('links', 'none'),
            c['confidence'],
        )
        buckets[key].append(c['path'])
    # ... emit clusters sorted by stable key hash ...
```

**Gotcha:** Deterministic ordering is load-bearing for the candidate-YAML byte-equality fixture test (D-19). `sorted(buckets.items())` relies on the key tuple being totally orderable — all elements are strings, so sort is stable. Do NOT use `hash(key)` for cluster_id (non-deterministic across Python processes with `PYTHONHASHSEED`).

---

### `bin/lib/brownfield_provenance.py` (OPTIONAL NEW module — planner's call)

**Analog:** `bin/lib/brownfield_classify.py` module shape (154 lines, pure functions, no I/O)

**Module-docstring + pure-function pattern** (clone from `brownfield_classify.py:1-29`):
```python
"""Bullet-eligibility heuristics for 02-provenance-bootstrap (BRWN-16, D-05).

NO LLM CALLS. Pure mechanical transforms.

Consumed by:
  - schema/brownfield/migrations/02-provenance-bootstrap.sh (Phase 11)

Exports:
  - is_eligible_claim_bullet(line) -> bool
  - section_scan(body, target_sections) -> list[(lineno, line)]
"""
import re
# ... module-level compiled patterns ...
# ... pure functions with type hints ...
```

Full implementation in RESEARCH §Code Examples Q5 (lines 724-793).

**Why a separate module (per RESEARCH Q5 line 1004):** The eligibility rules are isolated from YAML round-trip, enabling unit tests that pass literal strings without constructing fixtures. Matches the `brownfield_classify.py` testability pattern.

---

### `.brownfield/applied.log` writer helper (inline bash function)

**Analog:** `bin/brownfield.sh:587-616` — APPLIED.md append pattern (exact same file, existing append semantics)

**Inline-bash-helper pattern** (RESEARCH §Code Examples Q8 lines 795-822):
```bash
append_applied_log_block() {
    local block_file="$1"
    local log_file="${BROWNFIELD_ROOT:-.}/.brownfield/applied.log"
    mkdir -p "$(dirname "$log_file")"
    cat "$block_file" >> "$log_file"
    printf '\n' >> "$log_file"   # trailing blank for block separation
}
```

**Migration-script-caller pattern** (RESEARCH lines 1104-1119):
- Each migration script builds its block in a `mktemp` temp file
- Appends via `append_applied_log_block` (inlined in the script OR sourced from `bin/brownfield.sh`)
- Apply-class blocks schema per CONTEXT §Decision D-11 (apply-block); advisory-class blocks per advisory-block schema

**Gotcha (D-11):** Apply-class appends on `--apply` only, NEVER on dry-run re-generation. Advisory-class appends when findings are produced. Plain dry-run regeneration does NOT append. This is mechanically enforced by gating the `append_applied_log_block` call behind the apply/advisory branch.

**Difference from Phase 10 APPLIED.md** (existing analog):
- APPLIED.md (Phase 10) is append-only plain-text list of file outcomes; one section per run
- applied.log (Phase 11) is append-only markdown block with STRUCTURED key-value fields
- Both live under `.brownfield/`; both use `open('a')` semantics; both are gitignored

---

### `tests/phase-11/run.sh`, `lib.sh`, fixtures

**Analog:** `tests/phase-10/` (83 lines `lib.sh` + 48 lines `run.sh` + fixtures)

**Aggregator pattern** (copy verbatim from `tests/phase-10/run.sh:1-48` — rename 10 -> 11):
```bash
#!/usr/bin/env bash
# tests/phase-11/run.sh -- Phase 11 test aggregator
set -euo pipefail
# ... identical loop shape ...
shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    TOTAL=$((TOTAL + 1))
    # ... run + tally ...
done
echo "PHASE 11 TESTS: ${PASS}/${TOTAL}"
```

**Shared helpers pattern** (copy verbatim from `tests/phase-10/lib.sh:1-83` — rename 10 -> 11):
- `make_fixture_repo` (lines 20-36) — mktemp + git init + seed commit
- `assert_byte_equal` (lines 41-53) — cmp with regeneration-recipe on failure
- `assert_exit_code`, `assert_file_exists`, `assert_grep` (lines 56-81)

**New assertion (Phase 11):** Canonical-script byte-equality after `suggest` runs (per D-19). Add to `lib.sh`:
```bash
assert_canonical_scripts_byte_identical() {
    local stage_root="$1"
    for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
        # Compare stripped-of-op_hash-headers body (header is injected per-vault; body must be identical)
        python3 -c "... strip + cmp ..." \
            "$REPO_ROOT/schema/brownfield/migrations/$script" \
            "$stage_root/.brownfield/migrations/$script" \
            || { echo "FAIL: canonical drift on $script" >&2; return 1; }
    done
}
```
See `tests/phase-08/test_canonical_byte_equality.sh:28-41` for the analogous compare-with-diff-on-fail pattern.

**Fixture-date env-var pattern** (CONTEXT §canonical_refs line 287; Phase-10 precedent):
- `BROWNFIELD_FIXTURE_TODAY` and `BROWNFIELD_FIXTURE_CREATED_AT` already shipped
- Phase 11 may need additional pins (e.g., `BROWNFIELD_TOOL_VERSION` for metadata-header determinism); set in fixtures' test harness

---

### `AGENTS.md §11.5` (Brownfield Workflow)

**Analog:** `AGENTS.md §11.1 Ingest Workflow` (lines 866-902, ~37 lines)

**Template structure** (exact shape to match — per D-16):
```markdown
### 11.5 Brownfield Workflow

```
Trigger:  <when this workflow runs>
Inputs:   <what it consumes>
Outputs:  <what it produces>
Commit:   <conventional commit format>
```

**Steps:**

1. ...
2. ...

**Abort conditions:**

- ...
```

**Key prose elements** (D-16 load-bearing content; each must appear in §11.5 body):
1. Mechanical-vs-judgment boundary (first principle)
2. Verbatim quote: *"Review may be interactive and AI-guided; apply must always be deterministic."*
3. Apply-class vs advisory-class split — name all four scripts with their class
4. `bootstrap_stage` lifecycle diagram (from CONTEXT specifics line 431-438)
5. Pointer: `See: docs/reference/brownfield.md` for operator runbook

**Numbering conflict resolution (RESEARCH §Pitfall 1 lines 478-491):** Current §11.5 is "Release Workflow." Plan 11-05 Option C (recommended): renumber Release Workflow to §11.6 and put Brownfield at §11.5. This also closes Phase 10 WR-03 forward-ref typo opportunistically.

**Gotcha:** CLAUDE.md auto-syncs via `.githooks/pre-commit` (Phase 7 D-03) — no separate maintenance. But template-parity test (Phase 9.1 R-3) requires `schema/AGENTS.template.md` mirror the edit, AND the Phase-8-01 canonical fixture must be regenerated.

---

### `schema/AGENTS.template.md §11.5` (mirror)

**Analog:** `schema/AGENTS.template.md §11.1` (line 871) — parallel structure to AGENTS.md

**Mirror requirement:** Phase 9.1 extraction-invariant test (`test_agents_template_parity_*`) enforces byte-equivalence modulo template placeholders (`{{PRIMARY_DOMAIN}}`, `{{AGENT}}`, etc.). Brownfield workflow block has NO template placeholders — it mirrors AGENTS.md §11.5 VERBATIM.

**Edit strategy:** After editing `AGENTS.md §11.5`, copy the block into `schema/AGENTS.template.md` at the same section position. If Option C renumbering applies, renumber the template's Release Workflow to §11.6 in lockstep.

---

### `schema/fixtures/canonical-AGENTS.md` (regeneration)

**Analog:** `tests/phase-08/test_canonical_byte_equality.sh:7-10, 31-34` — regeneration recipe documented in the failure message

**Regeneration command** (copy verbatim from `tests/phase-08/test_canonical_byte_equality.sh:31-33`):
```bash
bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
git add schema/fixtures/canonical-AGENTS.md && git commit -m 'fixtures: regenerate canonical-AGENTS.md after template change'
```

**Trigger:** Any edit to `schema/AGENTS.template.md` requires regeneration. Phase 11 Plan 11-05 §11.5 edits guarantee this.

**Determinism pin** (from `tests/phase-08/test_canonical_byte_equality.sh:20-21`):
```bash
export WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"
export WIZARD_TEMPLATE_SHA="<frozen-fixture>"
```
If the canonical answers fixture's `metadata.generated_at` value differs, update those pins. Tests assert byte-equality of the rendered output against this fixture.

---

### `docs/reference/brownfield.md` (suggest/review-typing/verify sections)

**Analog:** `docs/reference/brownfield.md` existing scan section (lines 22-49) + bootstrap section (lines 51-109)

**Section shape template** (clone from `## scan subcommand` / `## bootstrap subcommand`):
```markdown
## suggest subcommand

Brief one-paragraph purpose statement.

### Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--root DIR` | `.` | Vault root |
| ... | | |

### Output contract

- ...
- ...

### <Additional subsections as needed>
```

**D-17 content requirements** (CONTEXT lines 183-187):
- TTY mode cluster UX description
- Large-batch AI-handoff template reference
- Candidate-file shapes with examples
- Full lifecycle walkthrough (bootstrap -> suggest -> review-typing -> 01 apply -> 02 apply -> 03/04 advisory -> verify -> verify --promote)
- End-to-end rollback recipe (`git reset --hard` — already documented in existing `## Rollback` section lines 111-128)
- Troubleshooting table for common failure modes

**Stub replacement** (current state of file lines 170-181):
- Lines 170-174: existing stub `## suggest subcommand` placeholder — REPLACE in Plan 11-05
- Lines 176-181: existing stub `## verify subcommand` placeholder — REPLACE
- NEW: insert `## review-typing subcommand` section between them

**Gotcha:** D-17 says docs do NOT restate the §11.5 normative contract — they link to it. Cross-reference with `[§11.5](../../AGENTS.md#115-brownfield-workflow)` or equivalent anchor.

---

### `wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md` (Tier-1 DR)

**Analog:** `schema/templates/decision.md` + AGENTS.md §4.6 decision-record spec

**Template fields** (per AGENTS.md §4.6 + §5 Decision Additional Fields):
- Frontmatter: `type: decision`, `trigger_type: schema-update`, `affected_pages: [<list>]`
- Required sections: TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources
- File naming: `dr-YYYY-MM-DD-slug.md` with `dr-` prefix

**Content scope** (D-21 mandate):
1. Apply-class vs advisory-class split (D-01) + why
2. Review-manifest pattern (D-02, D-04) — why 02/03/04 do NOT adopt it
3. Design principle *"Review may be interactive and AI-guided; apply must always be deterministic."*
4. `bootstrap_stage` lifecycle gate via `verify --promote` (D-13, D-14, D-15)
5. Alternatives considered: auto-apply all / per-page prompts / scanner-driven privacy promotion — and rejection rationale

**`affected_pages` list** (per D-21 text):
- `agents-md-11-5` (new §11.5 content — if per-section IDs are used) OR the AGENTS.md page ID convention in this repo
- `docs-reference-brownfield-md`
- Each migration script as an operation reference

**Gotcha:** Decision records are `epistemic_status: sourced` (the decision itself is the source of truth per AGENTS.md §4.6). They do NOT participate in staleness tracking. `has_contradictions: false`.

---

## Shared Patterns

### Subcommand dispatch + python-heredoc (applies to all new `bin/brownfield.sh` branches)

**Source:** `bin/brownfield.sh:41-62` (dispatcher) + `:141-173` (python3 heredoc imports + env-var shuttle)
**Apply to:** `suggest`, `review-typing`, `verify` branches

```bash
# Dispatcher: validate subcommand, shift args
SUBCOMMAND="$1"; shift
case "$SUBCOMMAND" in
    scan|bootstrap|suggest|review-typing|verify) ;;
    *) echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2; exit 1 ;;
esac

# Per-branch: flag parse -> env-var export -> python3 heredoc
export BROWNFIELD_ROOT="$BS_ROOT"
export BROWNFIELD_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"
python3 << 'PYEOF'
import os, sys
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_yaml import read_fm_body, write_roundtrip
# ... logic ...
PYEOF
```

### Ruamel.yaml round-trip (applies to apply-class migrations + verify --promote)

**Source:** `bin/lib/brownfield_yaml.py:186-227` — `read_fm_body()` returns `(CommentedMap, str, str)`; `write_roundtrip` (not shown above but referenced ambiently in same module)
**Apply to:** `01-page-typing.sh --apply`, `02-provenance-bootstrap.sh --apply`, `bin/brownfield.sh verify --promote`

Contract: round-trip PRESERVES comments + key order + quoting. Do not re-implement YAML read/write.

### .brownfield-ignore exclusion (applies to all new scripts that walk the vault)

**Source:** `bin/brownfield.sh:222-245` (bootstrap branch parser) and `:772-790` (scan branch parser — functionally duplicate)
**Apply to:** `03-cross-link-inference.sh`, `04-privacy-review.sh`, `bin/brownfield.sh suggest` (vault walks)

**Reuse recommendation (RESEARCH line 450):** EXTRACT into a shared bash function or python helper. Current duplication across scan + bootstrap branches is accepted technical debt. Phase 11 should extract OR accept new duplication — planner's call. If extracting: new helper lives in `bin/lib/brownfield_ignore.py` (small pure module).

### Stderr WARN + continue (applies to soft prereq checks)

**Source:** `bin/ingest.sh:96-108` (resolve_contributor map-miss warn) — single-line stderr-warn pattern
**Apply to:** `02-provenance-bootstrap.sh` state-based prereq check (D-12)

Pattern: never exit non-zero on soft readiness failures. Emit ONE actionable-phrased line to stderr, continue.

### Hardcoded denylist + user-override config file (applies to scanning)

**Source:** `bin/check-neutrality.sh` PUBLIC_PATHS (mirror in `bin/check-privacy.sh:71`), `bin/brownfield.sh:95-102` BROWNFIELD_DEFAULT_EXCLUDES, `.brownfield-ignore` parser
**Apply to:** `04-privacy-review.sh` optional `.brownfield-privacy-terms.txt` allowlist (NEW, per CONTEXT D-07 future path); planner drafts spec

Pattern: baseline behavior is hardcoded in script; user extends via adjacent config file; changing the hardcoded list requires a PR (intentional review lever). From `bin/check-privacy.sh:67-71` comment verbatim: *"Changing this array requires a PR (intentional review lever)."*

### Fixture-date env-var pinning (applies to all new tests)

**Source:** `bin/brownfield.sh:113-117` (BROWNFIELD_FIXTURE_TODAY resolution) + `bin/lib/brownfield_yaml.py:283-297` (BROWNFIELD_FIXTURE_CREATED_AT resolution)
**Apply to:** all `tests/phase-11/test_*.sh` + fixtures per D-20

Pattern: env var pins a date that otherwise depends on wall-clock (`date -u +%Y-%m-%d`) or file mtime. Fail-loud on malformed values. Phase 11 may need analogous pins for metadata-header `generated_at` and `tool_version`.

### Byte-equality regeneration recipe in test failure message (applies to all new canonical fixtures)

**Source:** `tests/phase-10/lib.sh:41-53` (`assert_byte_equal` with regeneration hint) + `tests/phase-08/test_canonical_byte_equality.sh:29-40`
**Apply to:** `tests/phase-11/test_canonical_byte_equality.sh` (new) + any fixture golden-file comparison

Pattern: on byte-drift failure, emit the EXACT regeneration command that will update the fixture. This turns failed tests into self-healing workflows for intentional template changes.

### First-mention-only wikilink constraint (applies to 03-cross-link-inference)

**Source:** AGENTS.md §8 (rule 2 — "Link on FIRST mention only per page")
**Apply to:** `03-cross-link-inference.sh` candidate generation

Pattern: scan source page for existing `[[TargetTitle]]` before flagging a proposed link. Emit `target_already_linked_from_source: bool` field so review UI can filter.

## No Analog Found

All 20 file families have existing-code analogs. The closest thing to a "no analog" case is the **review-manifest pattern** (apply-class script emits `candidates.yaml` + `decisions.yaml`, separate review surface edits decisions, apply reads deterministically). This pattern is NEW to Phase 11 and is the subject of the Tier-1 DR per D-21.

However: even the review-manifest pattern's **shape** has analogs:
- `bin/release.sh` dry-run/apply (Phase 7) — two-stage human-in-loop flow
- `bin/lint.sh` JSON-findings + consumer (Phase 9) — structured output consumed by a downstream gate
- `bin/brownfield.sh` bootstrap APPLIED.md (Phase 10) — structured append after apply

What is NEW is:
1. The JSON/YAML manifest becomes the CONTROL SIGNAL (not just an audit log)
2. Review state is edited by a separate surface (TTY OR AI session outside CLI)
3. Apply reads the manifest AS THE AUTHORITATIVE INPUT (no re-classify at apply time)

This is covered by RESEARCH §Pattern 4 — Plan 11-01 locks the contract via RED tests; Plan 11-05 documents rationale in the Tier-1 DR.

## Metadata

**Analog search scope:**
- `bin/*.sh` — all existing shell entry points (brownfield, release, lint, check-privacy, init-wizard, ingest, sync-claude)
- `bin/lib/*.py` — brownfield_classify, brownfield_yaml
- `tests/phase-10/` — pattern-clone source for tests/phase-11/
- `tests/phase-08/` — canonical-fixture byte-equality pattern
- `schema/fixtures/` — canonical-AGENTS.md regeneration pattern
- `AGENTS.md §11.1-11.5` — workflow block template
- `schema/AGENTS.template.md` — template-parity mirror
- `docs/reference/brownfield.md` — subcommand doc section shape

**Files scanned:** ~20 existing files sampled for concrete excerpts; hundreds of lines read across `bin/brownfield.sh` (977 lines), `bin/lint.sh` (1895 lines), `bin/lib/brownfield_yaml.py` (483 lines), `bin/lib/brownfield_classify.py` (154 lines), `bin/release.sh` (196 lines), `bin/check-privacy.sh` (147 lines), `bin/init-wizard.sh` (1140 lines, targeted read).

**Key extraction principles applied:**
1. Prefer exact same-file analogs (e.g., `bin/brownfield.sh` scan branch for new suggest branch) over distant-analog patterns.
2. Cite concrete line numbers so planner can copy-paste the shape without re-reading context.
3. Flag gotchas from RESEARCH.md §Common Pitfalls inline with the analog assignment — pitfalls 1, 3, 4, 5, 6, 7, 8 all map to specific files above.
4. Shared patterns (ruamel round-trip, `.brownfield-ignore` parsing, stderr-warn) are pulled into the `## Shared Patterns` section to avoid per-file duplication.

**Pattern extraction date:** 2026-04-20
