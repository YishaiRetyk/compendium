# Phase 15: Privacy Architecture - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 19 (8 new test files, 6 tooling re-keys, 1 migration script, 1 settings artifact, 1 decision record, schema files treated as rewrite-in-place)
**Analogs found:** 18 / 19 (1 net-new artifact `.claude/settings.cloud.json` has a structural sibling, not a true analog)

This phase is **schema-rewrite + tooling-rekey + directory-migration**, NOT new feature code. Almost every "new" file is a *copy-and-modify* of an existing in-repo analog. The dominant pattern is: **re-key existing tooling** (path strings, predicate logic) and **mirror an existing test harness**. The single genuinely-new code unit is the D-09 asymmetric-link lint check, which plugs into existing `linkres` machinery.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `tests/phase-15/lib.sh` | test (harness) | file-I/O | `tests/phase-13/lib.sh` | exact (verbatim copy, mktemp prefix bump) |
| `tests/phase-15/test_decision_record.sh` | test | file-I/O | `tests/phase-09.1/test_decision_record.sh` | exact |
| `tests/phase-15/test_layout_migrated.sh` | test (smoke) | file-I/O | `tests/phase-09.1/test_decision_record.sh` (file-existence/grep idiom) | role-match |
| `tests/phase-15/test_schema_13_rewritten.sh` | test (unit/grep) | transform | `tests/phase-09.1/test_decision_record.sh` (grep-schema idiom) | role-match |
| `tests/phase-15/test_privacy_field_stripped.sh` | test (unit) | file-I/O | `tests/phase-09.1/test_decision_record.sh` (python-yaml-parse idiom) | role-match |
| `tests/phase-15/test_priv_resident_reduced.sh` | test (unit/grep) | transform | `tests/phase-09.1/test_decision_record.sh` | role-match |
| `tests/phase-15/test_lint_xtier_link.sh` | test (unit) | request-response | `tests/phase-13/test_*.sh` (make_bare_repo + write_page + assert_exit_code) | role-match |
| `tests/phase-15/test_check_privacy_rekey.sh` | test (unit) | request-response | `tests/phase-13/test_*.sh` (invoke bin/ + assert_exit_code) | role-match |
| `tests/phase-15/test_cloud_deny_profile.sh` | test (smoke + behavioral) | request-response | `tests/phase-13/lib.sh` harness; see A2 caveat (static-assert fallback) | partial (behavioral surface is net-new) |
| `bin/check-privacy.sh` | tooling (guard) | batch (tree scan) | itself (re-key in place) | exact (modify in place) |
| `bin/lib/privacy_resolve.py` | tooling (library) | transform (predicate) | itself (collapse in place) | exact (modify in place) |
| `bin/lint.sh` linkres block (D-09) | tooling (lint check) | transform (graph scan) | `bin/lint.sh` lines 1890-2025 linkres block | exact (extend in place) |
| `bin/audit-claims.sh` FAITH-04 | tooling (chokepoint) | request-response | `bin/audit-claims.sh` lines 140-142, 745-762 + `privacy_resolve.py` | exact (re-key consumer in place) |
| `bin/release.sh` allowlist | tooling (guard) | batch | `bin/release.sh` ALLOWLIST lines 18-52 | exact (re-key in place) |
| migration script (one-off, route-then-strip) | utility (migration) | file-I/O (ruamel mutate) | `schema/brownfield/migrations/02-provenance-bootstrap.sh` | role-match (apply-class ruamel mutator) |
| `.claude/settings.cloud.json` | config (enforcement artifact) | — | `.claude/settings.json` | structural-sibling (shape only) |
| `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` | decision | — | `wiki/decisions/dr-2026-06-03-uniform-piped-links.md` + `schema/templates/decision.md` | exact |
| `CLAUDE.md` ≡ `AGENTS.md` §2/§3/§5/§8/§13 | schema (rewrite) | — | self (rewrite in place) + `schema/AGENTS.template.md` byte-mirror | exact (modify in place) |
| `tests/phase-07..13/*` fixture-path updates | test (fixture) | file-I/O | each test's own current `wiki/` literals | exact (mechanical `wiki/`→`wiki-cloud/`) |

## Pattern Assignments

### `tests/phase-15/lib.sh` (test harness, file-I/O)

**Analog:** `tests/phase-13/lib.sh` — copy VERBATIM, bump mktemp prefix `phase13-` → `phase15-`.

The four core helpers (`make_bare_repo`, `assert_exit_code`, `cleanup_fixture_repo`, `write_page`) are themselves copied verbatim across phases (the phase-13 header documents this lineage from phase-12.2). Phase 15 needs only the four core helpers — the three verifier helpers (`make_fake_verifier`, etc.) are audit-specific and NOT needed unless `test_cloud_deny_profile.sh` stubs a subprocess.

**Core harness signatures to copy** (`tests/phase-13/lib.sh:14-58`):
```bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

make_bare_repo() {            # -> prints path to fresh temp repo w/ one empty commit
    local tmp
    tmp="$(mktemp -d -t phase15-XXXXXX)"   # <-- bump prefix to phase15-
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}

assert_exit_code() {          # <expected> <actual> <description>
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

cleanup_fixture_repo() {      # safe rm -rf of a /tmp mktemp dir (guards path prefix)
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

write_page() {                # <repo> <relpath>  -- body from stdin (heredoc)
    local repo="$1" relpath="$2"
    local dir="$repo/$(dirname "$relpath")"
    mkdir -p "$dir"
    cat > "$repo/$relpath"
}

export -f make_bare_repo assert_exit_code cleanup_fixture_repo write_page
```

**Note:** `write_page` lets the lint tests (`test_lint_xtier_link.sh`) build a `wiki-cloud/` page linking to a `wiki-local/` page inline, then assert `assert_exit_code 1` from `bin/lint.sh --ci`.

---

### `tests/phase-15/test_decision_record.sh` (test, file-I/O)

**Analog:** `tests/phase-09.1/test_decision_record.sh` — RESEARCH explicitly names this as the mirror. Only the DR path and `trigger_type` assertion text change.

**Full structure to copy** (`tests/phase-09.1/test_decision_record.sh:1-75`). Key excerpts:

**Setup + path** (lines 5-10) — change the DR path to the phase-15 DR under `wiki-cloud/decisions/`:
```bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DR="$REPO_ROOT/wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md"
test -f "$DR" || { echo "FAIL: $DR missing" >&2; exit 1; }
```

**Frontmatter assertion via python yaml** (lines 13-36) — assert `type: decision`, `trigger_type: schema-update`, `status: active`, `epistemic_status: sourced`. (Phase-15 DR has `affected_pages` non-empty — drop the `ap != []` exact-empty check from the phase-09.1 version, or invert it to "is a list".)

**Required sections grep** (lines 38-42) — keep verbatim (all 7 §4.6 sections):
```bash
for section in '^## TL;DR' '^## Decision' '^## Why' '^## Alternatives Considered' '^## Consequences' '^## Affected Pages' '^## Sources'; do
    grep -qE "$section" "$DR" || { echo "FAIL: DR missing section matching '$section'" >&2; exit 1; }
done
```

**Why-section + Alternatives assertions** (lines 47-73) — keep the `\b(replac|prior|previously|former|before)\b` proxy AND the `>=1 bulleted alternative` check. D-15 requires the DR record the **three options** (per-page mixed / per-vault fully separate / asymmetric two-dir) — strengthen the alternatives check to `len(bullets) >= 2` (two rejected options besides the chosen one).

---

### `tests/phase-15/test_layout_migrated.sh`, `test_schema_13_rewritten.sh`, `test_privacy_field_stripped.sh`, `test_priv_resident_reduced.sh` (test, grep/yaml-parse idioms)

**Analog:** `tests/phase-09.1/test_decision_record.sh` — reuse its two embedded idioms:

1. **File-existence + `grep -qE`** for structural assertions (lines 39-42 pattern):
   - `test_layout_migrated.sh`: assert `wiki-cloud/` and `wiki-local/maintenance/` exist, `wiki/` does NOT, and the 2 audit files landed in `wiki-local/maintenance/`.
   - `test_schema_13_rewritten.sh`: `grep` CLAUDE.md §13 for asymmetric language present + the 7-row table ABSENT (`grep -q ... && fail`).
   - `test_priv_resident_reduced.sh`: assert §13 core block reduced to one-line pointer; no precedence/inheritance prose.

2. **Embedded `python3 - "$FILE" <<'PYEOF'` yaml-parse** (lines 13-36 pattern):
   - `test_privacy_field_stripped.sh`: walk `wiki-cloud/`+`wiki-local/` pages, assert NO `privacy` key in any frontmatter; assert §5 base block + checklist item #5 removed from CLAUDE.md.

These are all the SAME script skeleton (`source lib.sh` → `REPO_ROOT`-relative path → grep/python assertion → `echo PASS`). No new harness needed.

---

### `tests/phase-15/test_lint_xtier_link.sh`, `test_check_privacy_rekey.sh` (test, request-response)

**Analog:** any `tests/phase-13/test_*.sh` that builds an inline fixture and invokes a `bin/` script. The pattern (from `lib.sh` usage docstring, `tests/phase-13/lib.sh:10-12`):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
repo="$(make_bare_repo)"
write_page "$repo" "wiki-cloud/concepts/foo.md" <<'EOF'
... body with [[bar|Bar]] linking to a wiki-local page ...
EOF
write_page "$repo" "wiki-local/concepts/bar.md" <<'EOF'
...
EOF
( cd "$repo" && "$REPO_ROOT/bin/lint.sh" --ci --category linkres wiki-cloud/ ); rc=$?
assert_exit_code 1 "$rc" "cloud->local link must be a linkres error"
cleanup_fixture_repo "$repo"
```
- `test_check_privacy_rekey.sh`: build a fixture where `wiki-local/` content is/ isn't reachable from a PUBLIC_PATH; invoke `bin/check-privacy.sh`; assert exit 0 (clean) vs 2 (leak).

---

### `tests/phase-15/test_cloud_deny_profile.sh` (test, behavioral — partial analog)

**Analog (harness only):** `tests/phase-13/lib.sh`. The behavioral surface (headless `claude -p --settings`) is net-new and flagged MEDIUM-risk (RESEARCH A2). **Fallback per RESEARCH:** if headless assertion is brittle, split into (a) a static `grep`/`python -c json.load` assertion that `.claude/settings.cloud.json` contains `deny: ["Read(./wiki-local/**)"]` (reuses the phase-09.1 grep idiom), plus (b) a documented manual runbook. The four surfaces to pin (RESEARCH Code Examples, D-12.4): Read tool DENIED, `cat wiki-local/x` DENIED, `python3 -c open(...)` NOT denied, `git show HEAD:wiki-local/x` NOT denied.

---

### `bin/check-privacy.sh` (tooling guard, batch — re-key in place)

**Analog:** itself. The current shape that must change (`bin/check-privacy.sh`):

**PUBLIC_PATHS array** (line 71) and **the `wiki/**` exclusion** (lines 32-33, 67) are the re-key targets:
```bash
PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)
# D-15 comment block lines 31-33: "EXPLICITLY EXCLUDED: wiki/** (local_only is valid...)"
```
**The frontmatter-grep predicate** (python heredoc lines 86-87, 121-124) is what dissolves:
```python
PRIVACY_LOCAL_ONLY_RE = re.compile(r'^privacy:\s*local_only\s*$', re.M)   # <- target is GONE post-strip
...
fm = parse_frontmatter_block(content)
m = PRIVACY_LOCAL_ONLY_RE.search(fm)   # <- re-key to structural path check
```
**Re-key direction (PRIV-05, RESEARCH check-privacy.sh re-key block):** from "grep PUBLIC_PATHS frontmatter for `privacy: local_only`" to "assert no `wiki-local/` content appears under PUBLIC_PATHS / the release stage." Preserve the CLI surface (`--root`, `--format text|json`, exit codes 0/1/2) and the env-export-to-python-heredoc idiom (lines 74-79) — only the scan predicate changes. Keep it a thin re-keyed guard (preserves the CI `privacy-leak` required-check job name).

---

### `bin/lib/privacy_resolve.py` (tooling library, transform — collapse in place)

**Analog:** itself. The current 3-level resolver (`bin/lib/privacy_resolve.py:37-87`) is the thing being **simplified, not extended** (RESEARCH "Don't Hand-Roll"). Both exported functions collapse:
- `resolve_source_privacy(source_fm, source_path)` (lines 37-61) — the explicit-frontmatter / dir-signal / fail-closed ladder dissolves.
- `resolve_effective_claim_privacy(page_fm, page_path, source_fm, raw_source_fm, source_path)` (lines 64-87) — the strictest-of-5-signals fold collapses to the **single structural predicate** (RESEARCH PRIV-05 sharpening + CONTEXT specifics): **a claim is effective-`local_only` iff its page OR any contributing source lives under `wiki-local/`.** Do NOT port the precedence ladder.

**Caller contract to preserve:** `bin/audit-claims.sh:142` imports both names (`from privacy_resolve import resolve_source_privacy, resolve_effective_claim_privacy`) and calls `resolve_effective_claim_privacy(...)` at line 745. Keep the function names + arity stable (or update the import+call site in lockstep) so the FAITH-04 chokepoint at `audit-claims.sh:745-762` keeps working. The new predicate keys off PATH (`wiki-local/` prefix), so the signature can simplify to path arguments.

---

### `bin/lint.sh` linkres block — D-09 asymmetric-link check (tooling, transform — extend in place)

**Analog:** the existing `linkres` block, `bin/lint.sh:1890-2025` (RESEARCH-confirmed line range). This is the **only genuinely-new code logic** in the phase, and it plugs into machinery that already exists.

**Existing scaffolding to reuse** (do NOT rebuild — RESEARCH "Don't Hand-Roll"):
- `known_ids` set + `norm_map` built over `all_pages` (lines 1899-1926).
- `linkres_scan` worklist of `(rel, abs_path, full_file_text)` (lines 1936-1950).
- `PIPED_LINK_RE` (line 391: `re.compile(r'\[\[([^\]|]+)\|([^\]]+)\]\]')`) scanned over `mask_markdown(raw)` (line 1970) — frontmatter + code-fence masking already correct.
- `add_finding('error', 'linkres', rel, "...")` (lines 1979-1990) — the `linkres`→`error` severity remap already exists (`bin/lint.sh:321`).

**The net-new mechanic** (RESEARCH Pattern 3, verbatim): build a parallel `page_tier[id] = 'cloud'|'local'` map from each page's path prefix during the `all_pages` walk (mirror the `known_ids` build loop at lines 1900-1907). Then inside the existing `for rel, abs_path, raw in linkres_scan:` loop (line 1969), when the *linking* file is under `wiki-cloud/` AND a resolved piped target's id maps to a `local` page:
```python
add_finding('error', 'linkres', rel,
            "cloud->local link forbidden (PRIV-05/D-09): wiki-cloud page "
            "links to a wiki-local target (would break for cloud sessions + leak existence)")
```
**Planner decision (RESEARCH Open Q3, A4):** prefer a new logical subcategory tag inside `linkres` findings (inherits the `linkres`→`error` remap, least churn). Escalate to a top-level `xtier` category ONLY if reporting clarity demands — that costs ~3 registration edits: `--category` help (lines 26-29), severity remap dict (line ~313-321), and the `should_run`/category-filter path.

**Also re-key in this same file (D-05 path churn, 25 refs):** `WIKI_DIR="${WIKI_ROOT:-wiki/}"` default (line 94) → `wiki-cloud/`; `wiki/{entities,concepts,...}` prefix checks; `git diff -- wiki/` scopes; the `wiki/maintenance/lint-report.md` report path. The `EXCLUDE_DIRS = {'maintenance', 'examples'}` (line 435) path-prefix-exemption pattern is the template for how `wiki-local/` slots into walk scoping.

---

### `bin/audit-claims.sh` FAITH-04 chokepoint (tooling, request-response — re-key consumer)

**Analog:** itself. The chokepoint already centralizes effective-privacy resolution; only the imported predicate changes.

**The import** (`bin/audit-claims.sh:140-142`):
```python
# §13 privacy resolvers (bin/lib/privacy_resolve.py -- pure, egress-free).
from privacy_resolve import resolve_source_privacy, resolve_effective_claim_privacy
```
**The partition gate** (lines 745-762) — keep this control-flow, swap the predicate underneath:
```python
effective_priv = resolve_effective_claim_privacy(...)
if effective_priv == 'local_only' and not ALLOW_LOCAL:
    add_finding('skipped-privacy', rel, line, sid, loc,
                'local_only-effective claim withheld (no --allow-local)')
    ...continue (withhold from BOTH verifier subprocess AND --emit-worklist)...
```
**Re-key:** the resolver call now returns `local_only` iff page-or-source is under `wiki-local/` (single predicate). The withhold/`skipped-privacy` semantics, `--allow-local` opt-in, and the verifier-locality model are UNCHANGED (CONTEXT: "extraction relocates and re-keys, it does not change enforcement semantics"). Also re-key the 5 `git diff -- wiki/` path scopes (~line 506) → `wiki-cloud/`.

---

### Migration script (utility, file-I/O — route-then-strip, one-off)

**Analog:** `schema/brownfield/migrations/02-provenance-bootstrap.sh` — the closest apply-class ruamel-mutator that walks pages and calls `read_fm_body`/`write_roundtrip` per page. (`01-page-typing.sh` is the secondary analog; it shows the `del`-then-write idiom.)

**Lib-resolution + import header to copy** (`02-provenance-bootstrap.sh:106-111`):
```bash
export BROWNFIELD_ROOT BROWNFIELD_LIB_DIR APPLY OP_HASH
python3 - <<'PYEOF'
import os, sys, pathlib
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_yaml import read_fm_body, write_roundtrip
```

**Per-page mutate idiom** (the D-04 strip, RESEARCH Pattern 1 — verified against `brownfield_yaml.py` API):
```python
fm, body, raw = read_fm_body(path)         # fm is a ruamel CommentedMap (preserves comments+order)
if fm is not None and 'privacy' in fm:
    del fm['privacy']                       # CommentedMap deletion preserves surrounding comments/order
    write_roundtrip(path, fm, body, raw)    # atomic tmp+rename, LF-normalized
```
**API signatures (verified, `bin/lib/brownfield_yaml.py`):**
- `read_fm_body(path) -> (CommentedMap|None, body, raw_yaml_block|None)` (line 186). Returns `(None, body, None)` for no-frontmatter; raises `DuplicateKeyError`/YAMLError/OSError.
- `write_roundtrip(path, fm, body, raw_yaml_block=None) -> None` (line 420). Atomic tmp+rename; LF-normalizes; ensures one trailing newline; existing pages already carry a leading `\n` in `body` so the `---\n<body>` join is a no-op.

**Two-pass ordering (D-03, RESEARCH Pattern 2):** Pass A reads `privacy` and `git mv`s each `wiki/**/*.md` to `wiki-cloud/` (or `wiki-local/maintenance/` for the 2 `local_only` audit files) BEFORE Pass B strips the field — stripping first destroys the routing signal. Make the per-page loop idempotent (`if 'privacy' in fm`). The script must read the field generically (not hardcode the 2 known files) so it survives a vault with other local content. **Anti-pattern (RESEARCH):** raw `sed -i '/privacy:/d'` corrupts prose `privacy:` lines in CLAUDE.md/docs — use ruamel, scoped to the `---` fences.

---

### `.claude/settings.cloud.json` (config, enforcement artifact — structural sibling)

**Sibling (shape only):** `.claude/settings.json` (current minimal):
```json
{ "enabledPlugins": { "superpowers@claude-plugins-official": true } }
```
**New artifact** (RESEARCH Code Examples, D-12):
```json
{
  "permissions": {
    "deny": ["Read(./wiki-local/**)"]
  }
}
```
Loaded via `claude --settings ./.claude/settings.cloud.json`. **Label honestly:** policy/convenience, FAIL-OPEN, single-clone low-stakes only. The deny MUST NOT go in the committed `.claude/settings.json` (deny-beats-allow precedence would also block local sessions — RESEARCH Pitfall 2). Keep `.claude/settings.json` permissive.

---

### `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` (decision)

**Analog:** `wiki/decisions/dr-2026-06-03-uniform-piped-links.md` (the DR-at-execution precedent CONTEXT names) + `schema/templates/decision.md` (canonical frontmatter + 7-section skeleton).

**Frontmatter to mirror** (from `dr-2026-06-03-uniform-piped-links.md:1-27`) — `type: decision`, `status: active`, `epistemic_status: sourced`, `trigger_type: schema-update`, `knowledge_domain: software`, `tags: [meta, schema]`, `domains: [wiki-infrastructure]`. **NOTE (D-01 coupling):** the template still carries a `privacy: cloud_safe` row (`decision.md:15`, `dr-2026-06-03:18`) — this DR is authored in the SAME commit that strips the `privacy` field, so it must OMIT the `privacy` row (and the template's row is removed in lockstep). The forbidden-patterns HTML comment block (`dr-2026-06-03:29-33`) carries over.

**Section content (D-15):** the 7 §4.6 sections. `## Why` must name what framing was **replaced** (the implicit per-page §13 precedence/inheritance). `## Alternatives Considered` must list the **three weighed options**: (1) per-page mixed, (2) per-vault fully separate, (3) asymmetric two-dir (chosen) — see `dr-2026-06-03`'s numbered-rejected-alternatives format (lines 76-93) as the template. `trigger_type: schema-update`. The DR's home is `wiki-cloud/decisions/` post-rename (it is cloud-safe schema reasoning).

---

### `CLAUDE.md` ≡ `AGENTS.md` §2/§3/§5/§8/§13 (schema rewrite — modify in place)

**Analog:** self (rewrite in place), byte-mirrored to `schema/AGENTS.template.md` (72 `wiki/` refs) and regenerated into `schema/fixtures/canonical-AGENTS.md`. The §13 rewrite content map is fully specified in RESEARCH "§13 Rewrite Content Map (PRIV-02)". **Byte-equality gate:** `bin/sync-claude.sh --check` (pre-commit) enforces CLAUDE.md ≡ AGENTS.md; `tests/phase-08/test_canonical_byte_equality.sh` gates the wizard-regen fixture. Every §2/§5/§8/§13 edit lands in all three (CLAUDE.md, AGENTS.md, template) + fixture regen in the lockstep commit.

## Shared Patterns

### Test harness (all `tests/phase-15/*.sh`)
**Source:** `tests/phase-13/lib.sh` (copy core 4 helpers) + `tests/phase-09.1/test_decision_record.sh` (grep + python-yaml assertion idioms).
**Apply to:** all 9 new test files.
**Invariant skeleton:** `set -euo pipefail` → `SCRIPT_DIR=...; source "$SCRIPT_DIR/lib.sh"` → `REPO_ROOT`-relative path → assertion (grep / python-yaml / invoke-bin-and-`assert_exit_code`) → `echo "PASS: ..."`.

### ruamel frontmatter mutation (migration script)
**Source:** `bin/lib/brownfield_yaml.py` (`read_fm_body` line 186, `write_roundtrip` line 420); caller idiom from `schema/brownfield/migrations/02-provenance-bootstrap.sh:106-179`.
**Apply to:** the `privacy`-field strip migration.
**Rule:** `read_fm_body` → `del fm['privacy']` → `write_roundtrip` — NEVER `sed`. Idempotent (`if 'privacy' in fm`). Comment/key-order/quoting preserved; atomic write.

### linkres machinery (D-09 + lint re-key)
**Source:** `bin/lint.sh:1890-2025` (`known_ids`, `norm_map`, `linkres_scan`, `PIPED_LINK_RE` line 391, `mask_markdown` line 1970, `add_finding(...'linkres'...)`).
**Apply to:** the cloud→local asymmetric-link check. Reuse all of it; add only the `page_tier` map + the cross-tier finding. `linkres`→`error` remap (line 321) already exists.

### Path-prefix exemption / EXCLUDE_DIRS (walk scoping)
**Source:** `bin/lint.sh:435` (`EXCLUDE_DIRS = {'maintenance', 'examples'}`) + check-privacy `PUBLIC_PATHS` array + release `ALLOWLIST`.
**Apply to:** how `wiki-cloud/` and `wiki-local/` slot into every tree-walking tool. Both new dirs follow the SAME established path-prefix pattern (CONTEXT "Established Patterns").

### byte-equality coupling (schema edits)
**Source:** `bin/sync-claude.sh --check` (pre-commit) + `tests/phase-08/test_canonical_byte_equality.sh`.
**Apply to:** every §2/§3/§5/§8/§13 edit — must land in CLAUDE.md, AGENTS.md, AND `schema/AGENTS.template.md`, with `schema/fixtures/canonical-AGENTS.md` regenerated. The byte-equality test failing until regen is the intended guard (RESEARCH Pitfall 4).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.claude/settings.cloud.json` | config (enforcement) | — | No prior cloud-scoped deny-profile exists in the repo. `.claude/settings.json` provides the JSON *shape* but not the `permissions.deny` pattern — that comes from RESEARCH Code Examples (Claude Code docs), not an in-repo analog. The behavioral *verification* of this artifact (`test_cloud_deny_profile.sh`) is likewise the one test with no behavioral analog (only a harness analog). |

## Metadata

**Analog search scope:** `tests/phase-09.1/`, `tests/phase-13/`, `bin/` (check-privacy.sh, lint.sh, audit-claims.sh, release.sh, lib/privacy_resolve.py, lib/brownfield_yaml.py), `schema/brownfield/migrations/`, `schema/templates/decision.md`, `wiki/decisions/`, `.claude/`.
**Files scanned:** 13 read in full or targeted-range; ~10 more inspected via grep for signatures/line-anchors.
**Pattern extraction date:** 2026-06-04
