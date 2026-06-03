# Phase 14: Graph Link Resolution — Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 7 (2 create, 5 modify)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/lint.sh` (add `linkres` category) | utility/CLI | transform (file scan → findings) | `bin/lint.sh` duplicate block (lines 1620-1768) | exact — same file, same category addition pattern |
| `tests/phase-09/test_lint_linkres.sh` | test | batch (fixture wiki → assertion) | `tests/phase-09/test_lint_duplicate.sh` | exact — same harness, same inline-Python assertion pattern |
| `tests/phase-09/test_lint_require_version.sh` (modify) | test | request-response | itself (lines 10-27) | exact — version-assertion update only |
| `wiki/decisions/dr-2026-06-02-<slug>.md` | decision | request-response | `wiki/decisions/dr-2026-04-14-phase6-decision-type.md` | exact — same `trigger_type: schema-update`, same `affected_pages: []` shape |
| `CLAUDE.md` §5 + §8 + `AGENTS.md` (sync) | config/schema | transform | `CLAUDE.md` §11.3 (CI mode section) + `bin/sync-claude.sh` | role-match — prose edit + mechanical byte-copy sync |
| `schema/templates/*.md` + `schema/obsidian/*.md` (12 files) | config/template | transform | `schema/templates/concept.md` + `schema/obsidian/concept.md` | exact — same `aliases: []` block that needs self-alias comment |
| `wiki/` + `examples/` page frontmatter (`aliases:` backfill) | wiki content | batch (65 pages) | `wiki/entities/anthropic.md` | exact — canonical self-alias shape |

---

## Pattern Assignments

### `bin/lint.sh` — add `linkres` category

**Analog:** `bin/lint.sh` lines 1620-1768 (`duplicate` category) and lines 1430-1468 (`has_contradictions` auto-fix)

**Why this analog:** `duplicate` is the most recently added category (quick task 260602-d6a, LINT_VERSION 1.4.0). It is self-contained, uses `should_run('duplicate')`, emits via `add_finding()`, and establishes the structural pattern `linkres` must mirror. The `has_contradictions` block is the canonical `--fix` idempotent-regex pattern.

**LINT_VERSION bump pattern** (line 13):
```bash
LINT_VERSION="1.4.0"
```
Change to `"1.5.0"` — MINOR bump (non-breaking new category). Must be atomic with category addition and `test_lint_require_version.sh` update.

**Usage string update** (lines 27-31) — add `linkres` to the `--category` list:
```
  --category <cat>    Run only specified category:
                        orphan, crossref, stale, contradiction, gap,
                        provenance, yaml, drift, duplicate, contributor,
                        brownfield, linkres
```

**CI_SEVERITY_REMAP insertion** (lines 316-330) — add `linkres` alongside `orphan`:
```python
CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'linkres':            'error',    # <-- ADD: high-confidence graph defects gate CI
    'stale':              'warning',
    'gap':                'warning',
    ...
}
```

**`should_run()` guard pattern** (from line 1657 of `duplicate` block):
```python
if should_run('duplicate'):
    print("  Checking for near-duplicate pages...", file=sys.stderr)
    # ... self-contained block
```
Mirror for `linkres`:
```python
if should_run('linkres'):
    print("  Checking Obsidian-accurate link resolution (linkres)...", file=sys.stderr)
    # ... self-contained block
```

**`add_finding()` call pattern** (from lines 1765-1768):
```python
add_finding('warning', 'duplicate', loser['path'],
            f'possible duplicate of "{survivor["title"]}" '
            f'({survivor["id"]}); same type={t}; consider MERGE (§9). '
            f'Survivor by inbound-link count ({n_loser} vs {n_survivor}).')
```
Mirror for `linkres` error:
```python
add_finding('error', 'linkres', rel,
            f"title '{title}' not reachable via filename or aliases "
            f"(Obsidian will not resolve [[{title}]]); "
            f"run --fix to add self-alias")
```

**Resolution map builder that needs reconciliation** (lines 1083-1105):
```python
# Build resolution map: lowercase variant -> page id
resolution_map = {}  # lowercase name -> set of page ids
page_ids = set()

for fpath, fm, body, err in all_pages:
    if fm is None:
        continue
    pid = fm.get('id', '')
    if not pid:
        continue
    page_ids.add(pid)

    variants = set()
    variants.add(pid.lower())
    if fm.get('title'):
        variants.add(fm['title'].lower())    # <-- PROBLEM: adds title, Obsidian ignores title
    for alias in (fm.get('aliases') or []):
        if alias:
            variants.add(str(alias).lower())

    for v in variants:
        resolution_map.setdefault(v, set()).add(pid)
```
After reconciliation (D-03), the `orphan` block switches to `obsidian_map` (stem+alias only) and the `gap` block's reuse guard at line 1481 (`if 'resolution_map' not in dir():`) must also update to match. The `linkres` check builds a separate `norm_map` using the normalization helper.

**`normalize_link()` helper placement** — define just above the `orphan` block (~line 1076), before any check that needs it:
```python
# ---------------------------------------------------------------------------
# Shared normalization helper (D-02: for linkres + reconciled orphan/gap)
# ---------------------------------------------------------------------------

_PLURAL_MAP = {
    'contexts': 'context',
    'policies': 'policy',
    'contracts': 'contract',
}
_PUNCT_RE = re.compile(r'[^\w\s]')   # strips parens, hyphens, punctuation
_WS_RE    = re.compile(r'\s+')

def normalize_link(text):
    """D-02: casefold, strip punctuation chars (parens stripped as chars NOT
    content), collapse whitespace, apply small plural map.
    'Hack (Agentive Stack)' -> 'hack agentive stack' (NOT 'hack').
    'Bounded Contexts' -> 'bounded context'."""
    s = text.casefold()
    s = _PUNCT_RE.sub(' ', s)   # parens/hyphen/punct -> space
    s = s.replace('_', ' ')     # re \w includes underscore; handle separately
    s = _WS_RE.sub(' ', s).strip()
    words = [_PLURAL_MAP.get(w, w) for w in s.split()]
    return ' '.join(words)
```
Litmus test: `normalize_link('Hack (Agentive Stack)')` → `'hack agentive stack'` (NOT `'hack'`).

**`--fix` auto-fix pattern** (lines 1434-1468 — canonical `has_contradictions` pattern):
```python
if do_fix and not dry_run:
    try:
        content = open(fpath, encoding='utf-8').read()
        content = re.sub(
            r'^(has_contradictions:\s*)false\s*$',
            r'\g<1>true',
            content, flags=re.MULTILINE
        )
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        add_finding('info', 'autofix', rel,
                    'Set has_contradictions to true')
    except Exception:
        pass
```
The self-alias fix is structurally identical but must: (1) parse `fm.get('aliases') or []` for existing entries; (2) compute what needs to be added; (3) use regex on the raw content to replace the `aliases:` block; (4) emit one `autofix` finding per page (not per alias), matching `has_contradictions` precedent. The `_apply_self_alias_fix()` helper from RESEARCH.md section 8 provides the exact implementation. Key regex:
```python
ALIASES_RE = re.compile(r'^aliases:.*?(?=^\w|\Z)', re.MULTILINE | re.DOTALL)
```
**Pitfall:** apply this regex only within the frontmatter section (up to the second `---`) to prevent matching `aliases:` in page body text.

**`gap` block reuse guard that needs update** (lines 1481-1498):
```python
# Reuse the resolution_map from orphan detection if available, otherwise rebuild
if 'resolution_map' not in dir():    # <-- update to match new variable name
    resolution_map = {}
    for fpath, fm, body, err in all_pages:
        ...
```
After D-03 reconciliation, update this guard and rebuild to use Obsidian-accurate stem+alias only (removing `fm['title']`).

---

### `tests/phase-09/test_lint_linkres.sh` (create)

**Analog:** `tests/phase-09/test_lint_duplicate.sh`

**Why this analog:** `test_lint_duplicate.sh` is the most recent category test (quick task 260602-d6a), self-contained (no `lib.sh` needed — builds its own temp wiki inline), uses `--format json` + inline `python3 -` JSON assertions, and covers positive/negative/exclusion cases. `linkres` needs the same structure with different fixture content.

**Overall test structure** (lines 1-11 of `test_lint_duplicate.sh`):
```bash
#!/usr/bin/env bash
# [test description]
# Self-contained (no git needed -- the [category] check is pure file inspection).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TMP="$(mktemp -d -t lint-[category]-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

WIKI="$TMP/wiki"
mkdir -p "$WIKI/entities"    # or relevant subdirs
cat > "$WIKI/index.md" <<'IDX'
# Index
IDX
cat > "$WIKI/log.md" <<'LOG'
# Log
LOG
```

**Fixture page frontmatter pattern** (from `test_lint_duplicate.sh` lines 36-57 — minimal base fields):
```bash
cat > "$WIKI/entities/my-concept.md" <<'PA'
---
id: my-concept
title: "My Concept"
type: entity
status: active
summary: "Summary."
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags: [test]
domains: [test]
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []           # <-- start empty, linkres errors if title not here
has_contradictions: false
knowledge_domain: science
example: false
---
# My Concept
Body with [[Another Page]] link.
PA
```

**Run + JSON parse pattern** (from `test_lint_duplicate.sh` lines 240-246):
```bash
EXIT=0
bash "$REPO_ROOT/bin/lint.sh" --category linkres --format json "$WIKI" \
    > "$TMP/out.json" 2>/dev/null || EXIT=$?
if [ "$EXIT" -ne 0 ]; then
    echo "FAIL: lint --category linkres exited $EXIT (expected 0, report-only)" >&2
    exit 1
fi
```

**Inline Python assertion pattern** (from `test_lint_duplicate.sh` lines 248-286):
```python
WIKI="$WIKI" python3 - "$TMP/out.json" <<'PYEOF'
import json, os, sys
data = json.load(open(sys.argv[1]))

lr = [d for d in data if d['category'] == 'linkres']

# 1. Title-unreachable: expect one error for the page with aliases: []
title_errs = [d for d in lr if d['severity'] == 'error' and 'my-concept' in d['path']]
assert len(title_errs) >= 1, f"FAIL: expected title-unreachable error, got {lr}"
print("PASS: title-unreachable error detected")

# 2. After --fix: no more errors
# ... (run --fix in a bash sub-step and re-assert)
PYEOF
```

**Required test cases** (8, from RESEARCH.md §Validation Architecture):
1. Title-unreachable error (`aliases: []`, `title` not reachable)
2. After `--fix`: title-unreachable becomes OK (aliases added, re-run exits 0)
3. Unique-normalized-match error (link text normalizes to unique page under D-02)
4. Multi-match warning (two pages normalize to same string)
5. No-match → gap, NOT linkres (link with no normalized match produces zero `linkres` findings)
6. `--fix` idempotency (second run: no new autofix findings, file content unchanged)
7. CI `strict` stays green (a properly-formed new page with `[prov:]` markers passes `--strict`)
8. `orphan` reconciliation (after self-alias added, orphan count reflects Obsidian-accurate resolver)

**Key fixture to cover the parens litmus test** (from RESEARCH.md §Specifics — `Hack (Agentive Stack)` normalization):
- Page with `title: "Hack (Agentive Stack)"`, `id: hack-agentive-stack`, `aliases: []`
- Link text `[[Hack (Agentive Stack)]]` should normalize to `hack agentive stack` and uniquely match → `linkres error`
- After `--fix` adds `Hack (Agentive Stack)` as alias → link resolves directly → 0 errors

---

### `tests/phase-09/test_lint_require_version.sh` (modify)

**Analog:** itself (lines 10-27)

**Why this analog:** The test only needs two line-range updates when `LINT_VERSION` bumps from `1.4.0` to `1.5.0`.

**Current assertions that must change** (lines 10-27):
```bash
# Case 1: exact match passes
bash "$LINT" --require-version 1.4.0 --dry-run >/dev/null 2>&1 \
    || { echo "FAIL: --require-version 1.4.0 should pass when LINT_VERSION=1.4.0" >&2; exit 1; }

# Case 3: newer pin fails with actionable stderr
if bash "$LINT" --require-version 1.5.0 --dry-run 2>/tmp/require-err >/dev/null; then
    echo "FAIL: --require-version 1.5.0 should fail when LINT_VERSION=1.4.0" >&2
    exit 1
fi
grep -q "1.5.0" /tmp/require-err ...
grep -q "1.4.0" /tmp/require-err ...    # "running version" assertion
```

**Required updates after bump to `1.5.0`:**
- Line 10-11: change `1.4.0` → `1.5.0` (Case 1 exact match)
- Line 18: change `1.5.0` → `1.6.0` (Case 3 must-fail pin; 1.6.0 is the next non-existent future version)
- Line 24-25: change `1.5.0` → `1.6.0` (matching stderr token in the version-fail error message)
- Line 26-27: change `1.4.0` → `1.5.0` (the "running version" stderr token that should appear)
- Line 15 (Case 2 older pin) is already generic (`1.1.0 ≤ 1.5.0`): no change needed

---

### `wiki/decisions/dr-2026-06-02-<slug>.md` (create)

**Analog:** `wiki/decisions/dr-2026-04-14-phase6-decision-type.md`

**Why this analog:** This is a `trigger_type: schema-update` DR with `affected_pages: []` (infrastructure record — no pre-existing wiki page is restructured; the schema convention is being corrected). The `dr-2026-04-14-phase6-decision-type.md` file is the only other `schema-update` + `affected_pages: []` DR in the corpus.

**Full frontmatter shape** (from `dr-2026-04-14-phase6-decision-type.md` lines 1-24):
```yaml
---
id: dr-2026-06-02-<slug>
title: "<DR Title>"
type: decision
status: active
summary: "<One-sentence summary>"
created_at: 2026-06-02
updated_at: 2026-06-02
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---
```

**Required forbidden-patterns comment** (lines 26-30 of analog):
```markdown
<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->
```

**Section ordering** (7 required sections, from `dr-2026-04-14-phase6-decision-type.md`):
1. `## TL;DR` — one-sentence summary
2. `## Decision` — what was decided (Obsidian resolves by filename+aliases; self-alias invariant; `linkres` category enforces it)
3. `## Why` — the false claim being corrected; what framing was adopted (`title` ≠ Obsidian resolver) vs replaced (`title` was the resolver)
4. `## Alternatives Considered` — at least one alternative + rejection reason
5. `## Consequences` — `linkres` category added; templates updated; 65 pages backfilled
6. `## Affected Pages` — "None. This is an infrastructure-only schema correction." (same pattern as analog)
7. `## Sources` — "None. Internal schema decision." (same pattern as analog)

**Slug recommendation** (Claude's Discretion): `dr-2026-06-02-obsidian-filename-alias-resolution` — captures both the Obsidian resolution rule correction and the self-alias convention.

**Neutrality rule:** No real vault terms in body text or examples (CLAUDE.md §3). Use abstract placeholders: `<page-title>`, `<concept-slug>`, `<entity-name>`.

---

### `CLAUDE.md` §5 + §8 (modify) + `AGENTS.md` sync

**Analog:** `CLAUDE.md` §11.3 "CI mode" section (source-of-truth section that `docs/reference/ci.md` must stay aligned with — same pattern: CLAUDE.md is the authority, secondary docs reference it)

**Why this analog:** §11.3 is the model for a "source of truth" schema section that secondary docs must link to rather than restate. §8 after the edit adopts the same relationship with `schema/templates/*.md` (the rule lives in §8; templates reference §8).

**Sync mechanism** (`bin/sync-claude.sh`):
```bash
# AGENTS.md is the source. CLAUDE.md is the byte-copy destination.
cp "$SRC" "$DST"   # SRC=AGENTS.md, DST=CLAUDE.md
```
**Critical:** every CLAUDE.md edit plan task must include `bash bin/sync-claude.sh && git add AGENTS.md` before committing. The pre-commit hook enforces byte-equality and will reject the commit otherwise.

**§5 `title` field table row to correct** (line ~288 in CLAUDE.md):
```
Current:  | `title` | string | Human-readable canonical title. Wikilinks resolve to this value. |
Corrected:| `title` | string | Human-readable canonical title. Used in page headings and the self-alias (§8). Obsidian resolves `[[X]]` by **filename stem + `aliases`**, not by this field. |
```

**§5 Frontmatter Validation Checklist — two new items** (after current item 17):
```
18. `aliases` contains the canonical `title` value (case-sensitive string match) —
    ensures `[[Title]]` resolves in Obsidian via the self-alias
19. `aliases` contains the `id` slug — ensures both `[[slug]]` and `[[Title]]`
    resolve via Obsidian's filename-stem-or-alias rule
```

**§8 new rule 4a** (after rule 4 "Use the `aliases` frontmatter field for alternate names"):
```
4a. Every page MUST include its `title` and `id` slug in the `aliases` list.
    Obsidian resolves `[[X]]` by **filename stem + `aliases`**, NEVER by the
    `title` frontmatter field. Without self-aliases, `[[Title]]` renders as
    an unresolved red link even though a page with that title exists.
```

**§8 "Bad vs. Good" example to add** (use placeholders — neutrality rule):
```
BAD:  aliases: []                   (empty — [[<page-title>]] will not resolve)
GOOD: aliases:
        - "<Page Title>"
        - <page-id-slug>            (self-aliases guarantee Obsidian resolution)
```

**`docs/reference/ci.md` update** — add `linkres` row to the severity table (line ~32):
```
| `linkres` | error | Obsidian link unresolvable: title not in aliases, or body link has unique normalized match — graph-integrity defect, blocks CI. |
```
Note: `docs/reference/ci.md` must stay aligned with CLAUDE.md §11.3 (CLAUDE.md is the source of truth; ci.md is the secondary reference per AGENTS.md §11.3 CI mode section).

---

### `schema/templates/*.md` + `schema/obsidian/*.md` (12 files, modify)

**Analog:** `schema/templates/concept.md` (line 16) + `schema/obsidian/concept.md` (line 16)

**Current state in all 12 files** (line 16 in both template sets):
```yaml
aliases: []
```

**Required change — `schema/templates/*.md`** (6 files: concept, entity, overview, comparison, source-summary, decision):
```yaml
aliases:
  # Self-alias invariant (CLAUDE.md §8): add your page title and id slug here
  # so [[Title]] resolves in Obsidian. See §8 rule 4a for the full explanation.
  # Example: if title is "<Page Title>" and id is "<page-id-slug>", add both:
  #   - "<Page Title>"
  #   - <page-id-slug>
```
Neutrality: no real vault terms in template files. Use abstract placeholders `<Page Title>`, `<page-id-slug>` in comment examples.

**Required change — `schema/obsidian/*.md`** (6 files: concept, entity, overview, comparison, source-summary, decision — each uses `{{title}}` Obsidian template placeholder):
```yaml
aliases:
  - {{title}}
```
The Obsidian `{{title}}` placeholder auto-fills the page title on template use, providing the self-alias automatically.

**Note:** The `schema/obsidian/decision.md` template also has `aliases: []`. It gets the `{{title}}` treatment like the other 5 obsidian templates.

---

### `wiki/` + `examples/` page frontmatter — self-alias backfill (65 pages)

**Analog:** `wiki/entities/anthropic.md` (lines 26-28)

**Why this analog:** `anthropic.md` is the canonical self-alias exemplar in the live wiki — has both `title` ("Anthropic") and id ("anthropic") as aliases alongside a real alternate name ("Anthropic PBC"). This is the target shape after `--fix`.

**Current shape (needs fix)** — from `wiki/overviews/domain-driven-design.md` lines 23-24:
```yaml
aliases:
  - DDD
```
Only has the acronym alias; missing `title: "Domain-Driven Design"` and `id: domain-driven-design`.

**Target shape after `--fix`** — from `wiki/entities/anthropic.md` lines 26-28:
```yaml
aliases:
  - Anthropic           # <-- title (self-alias)
  - Anthropic PBC       # <-- existing real alias, PRESERVED
```
For `domain-driven-design.md` specifically:
```yaml
aliases:
  - DDD                 # existing — preserved
  - Domain-Driven Design  # title added by --fix
  - domain-driven-design  # id added by --fix
```

**Minimal self-alias shape** (page with no existing aliases):
```yaml
aliases:
  - My Concept Title    # title
  - my-concept-id       # id slug
```

**`--fix` applies mechanically** to all 65 pages (45 wiki/ + 20 examples/). After `--fix`:
- All 26 title-exact body links (`[[Domain-Driven Design]]` etc.) resolve via the new alias
- The `[[Hack (Agentive Stack)]]` link also resolves (title IS `Hack (Agentive Stack)`)
- Only `[[Bounded Contexts]]` (plural variant) remains a Wave 2 manual edit

**Note on `example: true` pages:** The `linkres` check inherits the `all_pages` `example: true` skip (line 972 of lint.sh). So `--fix` on examples/ pages is safe (adds aliases to improve Obsidian graph connectivity) but is NOT gated by `linkres`. Run `--fix` on examples/ as a separate step or include it in the same `--fix` pass over the whole repo.

---

## Shared Patterns

### `should_run()` guard
**Source:** `bin/lint.sh` line 425
**Apply to:** Every new or modified category block in lint.sh
```python
def should_run(cat):
    return category_filter == 'all' or category_filter == cat
```
Every category block opens with `if should_run('linkres'):`. No exceptions.

### `add_finding()` signature
**Source:** `bin/lint.sh` line 404
**Apply to:** All findings emitted inside the `linkres` block
```python
def add_finding(severity, category, path, message):
    findings.append((severity, category, path, message))
```
The `--format json` output pipeline reads `findings` automatically — no extra wiring needed.

### `WIKILINK_RE` for body link extraction
**Source:** `bin/lint.sh` line 385
**Apply to:** `linkres` body-link-variant subcheck (B)
```python
WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')
```
Already in scope; do not redefine.

### `all_pages` tuple shape
**Source:** `bin/lint.sh` lines 956-974
**Apply to:** All loops inside `linkres` block
```python
all_pages = []  # (path, fm, body, error)
# ...
# example: true pages already excluded (line 972)
```
Each item: `(fpath, fm, body, err)` where `fm` is `None` if parse failed, `body` is the page body string.

### `EXCLUDE_DIRS` skip
**Source:** `bin/lint.sh` line 396
**Apply to:** `linkres` (inherited automatically via `all_pages` filtering)
```python
EXCLUDE_DIRS = {'maintenance', 'examples'}
```
`all_pages` already excludes these directories. The `linkres` check operates on `all_pages` directly and inherits all pre-filtering.

### Self-contained test harness (no `lib.sh`)
**Source:** `tests/phase-09/test_lint_duplicate.sh` lines 1-13
**Apply to:** `test_lint_linkres.sh`
`test_lint_duplicate.sh` is self-contained: creates its own `TMP`, builds a temp wiki inline, runs lint, asserts via `python3 -`. This is preferred for `linkres` tests because the category check is pure file inspection (no git needed, no `make_fixture_repo` needed).

### `--fix` idempotency pattern
**Source:** `bin/lint.sh` lines 1434-1468 (`has_contradictions` fix)
**Apply to:** `_apply_self_alias_fix()` helper inside `linkres` block
Rule: read `fm.get('aliases') or []`; compute `needed = {title, id} - existing_lower`; if empty, return without writing. One `autofix` finding per page (not per alias).

### AGENTS.md ↔ CLAUDE.md byte-equality
**Source:** `bin/sync-claude.sh` (the whole file)
**Apply to:** Every CLAUDE.md edit task in this phase
```bash
bash bin/sync-claude.sh   # copies AGENTS.md -> CLAUDE.md
git add AGENTS.md         # stage the synced copy
```
The pre-commit hook auto-rejects commits where these files differ. Run sync before every commit that touches CLAUDE.md.

---

## No Analog Found

No files in this phase lack an analog. All 7 file targets have a clear existing match.

---

## Metadata

**Analog search scope:** `bin/`, `tests/phase-09/`, `wiki/decisions/`, `wiki/entities/`, `wiki/overviews/`, `schema/templates/`, `schema/obsidian/`
**Files scanned:** ~20 files read directly; ~50 scanned via grep/bash
**Pattern extraction date:** 2026-06-02
