# Phase 14: Graph Link Resolution — Research

**Researched:** 2026-06-02
**Domain:** bash/python3 lint tooling + YAML frontmatter + Obsidian wikilink resolution
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — `linkres` gates only deterministic, high-confidence graph defects.**

| Case | Classification |
|---|---|
| `[[X]]` resolves by Obsidian rules (filename stem OR an alias) | **OK** |
| A page's own `title` or `id` is not reachable through filename or aliases | **linkres bug → error** |
| `[[X]]` does not resolve, normalized `X` **uniquely** matches a page | **linkres bug → error** |
| `[[X]]` does not resolve, normalized match finds **multiple** pages | **linkres ambiguous → warning** |
| `[[X]]` does not resolve, **no** normalized match | **gap (informational), NOT linkres** |

**D-02 — Normalization algorithm (deterministic, conservative):**
1. casefold
2. replace punctuation, hyphen, underscore, and parentheses **characters** with spaces (strip chars, NOT content)
3. collapse whitespace
4. small explicit plural map: `contexts→context`, `policies→policy`, `contracts→contract`
5. NO word reordering, NO synonym matching, NO substring-only matching
6. NO edit distance on the gating path

**D-03 — Reconcile `orphan` and `gap` to Obsidian-accurate resolution (LINK-06).**
- `orphan` MUST stop using `title` as a resolver.
- `gap` switches too, but stays informational.

**D-04 — `linkres` is CI-gating (`error` in `--ci` remap) for high-confidence defects only.**

**D-05 — Do NOT split title-unreachable (error) vs link-variant (warning).** Unique normalized match = real graph-integrity defect = error.

**D-06 — `--fix` repairs self-aliases ONLY; never rewrites body links.**
- ensure `aliases` exists
- add `title` if missing from aliases
- add `id` slug if missing from aliases
- preserve all existing aliases
- idempotent (re-running is a no-op)
- do NOT rewrite body links

**D-07 — Variant link reconciliation is human-reviewed Wave 2, NOT auto-fix.**

**D-08 — Default direction = edit the call site for mechanical variants; aliases only for genuine alternate names.**

### Claude's Discretion
- Exact `bin/lint.sh` code structure for the `linkres` category (function decomposition, where the shared normalization helper lives, `LINT_VERSION` bump to 1.5.0).
- Exact prose/placement of the §8 rewrite and §5 checklist item; self-alias wording in `schema/templates/*.md` and `schema/obsidian/*.md` — neutrality rules apply.
- Decision-record slug + `affected_pages` for the LINK-03 `schema-update` DR.
- Test decomposition under `tests/` (title-unreachable error, unique-match error, multi-match warning, no-match→gap exclusion, `--fix` idempotency, CI strict stays green).
- Whether the plural map is a literal dict or a tiny rule set.

### Deferred Ideas (OUT OF SCOPE)
- Auto-rewrite of body-link variants
- Synonym / edit-distance / substring matching for `linkres`
- General stemmer for pluralization
- v1.2 schema progressive-disclosure refactor (backlog 999.4)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LINK-01 | `CLAUDE.md` §8 states Obsidian resolves `[[X]]` by filename + `aliases`, not `title` | §8 "Graph View Implications" + §5 `title` field description contain the false claim; both need correction |
| LINK-02 | Self-alias invariant documented and templated — `title` and `id` ∈ `aliases`; §5 checklist + templates ship the self-alias | `schema/templates/*.md` have empty `aliases: []`; 6 obsidian templates also need update |
| LINK-03 | Decision record (`trigger_type: schema-update`) capturing the convention fix | Standard DR authoring per §4.6; `affected_pages: []` (infrastructure record) |
| LINK-04 | `bin/lint.sh` gains `linkres` category flagging pages whose `title` is not reachable | New category, slots into existing infrastructure |
| LINK-05 | `linkres` distinguishes knowledge-gap red links from should-resolve-but-mismatched links | D-01 5-bucket state machine; no-match stays in `gap` |
| LINK-06 | `--fix` backfills self-alias idempotently; `orphan` reconciled to Obsidian-accurate resolution | Extends existing `--fix` pattern; `orphan` resolver change affects orphan counts |
| LINK-07 | All `wiki/` pages carry self-aliases; `bin/lint.sh --category linkres` exits 0 | 45/49 pages need self-alias (quantified); `--fix` handles this mechanically |
| LINK-08 | Link-text variants reconciled (plural, parens, casing mismatches) | 28 unique-match defects found; all have clear remediation per D-07/D-08 |
| LINK-09 | `examples/` pages carry self-aliases respecting `example: true` / lint-skip | 20 examples pages need self-alias; lint skip logic confirmed |
| LINK-10 | Human-verified connected graph in Obsidian | Verification step only; not mechanically testable |
</phase_requirements>

---

## Summary

Phase 14 is a bash/Python3 tooling phase with zero runtime, zero AI, and zero frontend. The core work is: (1) correct two false claims in CLAUDE.md (§8 and §5) plus matching text in templates and obsidian templates; (2) add a `linkres` lint category to `bin/lint.sh` that implements a 5-bucket D-01 state machine using a new normalization helper; (3) fix `orphan`'s title-based resolver to use Obsidian-accurate stem+alias resolution; (4) implement `--fix` self-alias backfill following the existing `contradiction-sync` idempotent-regex pattern; and (5) remediate 45 wiki pages and 20 examples pages via `--fix` followed by manual variant reconciliation.

**Quantified remediation surface:** 45/49 wiki pages need at least one self-alias (title or id missing). 28 unique body link texts currently resolve by `title` but NOT by filename-stem or alias (all have unique normalized matches under D-02, all are `linkres error` defects). 9 body link texts have no match at all (genuine red-links / knowledge-gap candidates — `gap` category, not `linkres`). Examples cluster: all 20 pages need self-aliases. After `--fix`, the `--category linkres` check should exit 0 over wiki/; Wave 2 reconciles the 28 body-link variants manually.

**Primary recommendation:** Wire `linkres` into the existing `resolution_map` + add a `normalize_link()` helper just above the `orphan` block; reconcile `orphan` and `gap` in the same pass by making the resolution map Obsidian-accurate (stem+alias only) and removing title from the orphan resolver; implement `--fix` as idempotent regex against the `aliases:` YAML block following the `has_contradictions` pattern.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Wikilink resolution | Schema/CLAUDE.md | bin/lint.sh | Resolution rule is a schema convention; lint enforces it |
| Self-alias backfill | bin/lint.sh `--fix` | — | Mechanical frontmatter write; same tier as `has_contradictions` fix |
| Body-link variant reconciliation | Human (Wave 2) | — | Editorial judgment; D-06 excludes from auto-fix |
| Obsidian graph connectivity | Obsidian client | wiki/ frontmatter | Obsidian reads filesystem; frontmatter aliases drive resolution |
| CI enforcement | `.github/workflows/lint.yml` | bin/lint.sh | Existing CI jobs; `linkres` slots into severity-remap table |

---

## Standard Stack

No new dependencies for this phase.

### Core (already present)
| Tool | Version | Purpose |
|------|---------|---------|
| `bin/lint.sh` | 1.4.0 → 1.5.0 (MINOR) | Health-check CLI; gains `linkres` category |
| Python 3 + PyYAML | system | Lint engine (already inside lint.sh heredoc) |
| bash | ≥4 | Script execution |

### No New Libraries
This phase adds zero new `pip install` dependencies. The normalization helper (D-02) uses only Python stdlib: `str.casefold()`, `re.sub()`, `str.split()`, `str.join()`, and a literal dict.

---

## Architecture Patterns

### System Architecture Diagram

```
CLAUDE.md §8 / §5        schema/templates/*.md
  (false claim fixed)       (self-alias added)
           |                       |
           v                       v
     AGENTS.md ← sync ← CLAUDE.md (byte-identical)
           |
           v
    bin/lint.sh  ──── normalize_link() helper
         |                  |
    resolution_map      D-02 normalization
    (stem+alias only)   (casefold + punct→space
     after fix)          + plural map)
         |
    ┌────┴─────────────────────────────────┐
    │  linkres check (new)                 │
    │  orphan check (reconciled)           │
    │  gap check (reconciled)              │
    └──────────────────────────────────────┘
         |
    findings → CI_SEVERITY_REMAP
         linkres → error
         orphan → error (unchanged)
         gap → warning (unchanged)
         |
    .github/workflows/lint.yml (strict + lint jobs)
         |
    wiki/ pages ← --fix self-alias backfill
    examples/ pages ← self-alias backfill
         |
    Human: Wave 2 variant reconciliation
    Human: Obsidian verify (LINK-10)
```

### Recommended Phase Directory Structure
```
.planning/phases/14-graph-link-resolution/
├── 14-CONTEXT.md       (locked — done)
├── 14-RESEARCH.md      (this file)
├── 14-PLAN-P01.md      (Wave 1a: schema docs + DR)
├── 14-PLAN-P02.md      (Wave 1b: bin/lint.sh + tests)
└── 14-PLAN-P03.md      (Wave 2: data remediation)
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| YAML frontmatter write | Custom YAML serializer | Same `re.sub()` + regex pattern used by `has_contradictions` auto-fix (lines 1438-1464) |
| Normalization | Import nltk/unidecode/stemmer | Plain `re.sub() + str.split()` + a 3-entry dict literal |
| Wikilink parsing | Custom parser | Existing `WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')` (line 385) |
| Resolution map | New data structure | Existing `resolution_map` pattern from `orphan` block (lines 1084-1105) |
| Test harness | New framework | Inline bash + `python3 -` inline assertion (same as `test_lint_duplicate.sh`) |

---

## Key Code Integration Points

### 1. `resolution_map` builder — orphan block, lines 1083-1105 [VERIFIED: bin/lint.sh]

The current builder adds `pid.lower()`, `fm['title'].lower()`, and `str(alias).lower()` to a dict mapping `lowercase_name → set(page_ids)`. This is the reuse anchor for both the new `linkres` check AND the reconciled `orphan`/`gap` checks.

**Required change for D-03:** The builder currently adds `title` to the map. The Obsidian-accurate builder must add ONLY `filename_stem` and `aliases`, NOT `title`. Title goes into a separate `title_map` used only by the unique-match normalization pass.

**Concrete reconciliation approach:**
```python
# Obsidian-accurate resolution map (for orphan, gap, linkres)
obsidian_map = {}  # lowercase (stem OR alias) -> set of page ids

# Title map for normalized-match lookup (linkres unique-match)
title_map = {}     # lowercase title -> page id

for fpath, fm, body, err in all_pages:
    pid = fm.get('id', '')
    stem = os.path.splitext(os.path.basename(fpath))[0].lower()
    obsidian_map.setdefault(stem, set()).add(pid)
    for alias in (fm.get('aliases') or []):
        obsidian_map.setdefault(str(alias).lower(), set()).add(pid)
    # Title for normalized-match (not Obsidian resolution)
    if fm.get('title'):
        title_map[fm['title'].lower()] = pid
```

The existing `resolution_map` variable name is used elsewhere in the file (lines 1119, 1133, 1481-1498). The safest approach is to **rename the new Obsidian-accurate map to `obsidian_map`** and keep `resolution_map` as the old name pointing at `obsidian_map` for backward compatibility — OR (cleaner) just rename `resolution_map` to `obsidian_map` throughout the orphan block and update the `gap` reuse guard at line 1482.

The `gap` block has a guarded reuse at lines 1481-1498:
```python
if 'resolution_map' not in dir():
    resolution_map = {}
    # ... rebuild ...
```
This guard must be updated to match the new variable name.

### 2. Severity-remap dispatch table — line 316 [VERIFIED: bin/lint.sh]

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
    'contributor':        'warning',
    'brownfield':         'warning',
    'autofix':            'info',
    'skip-count':         'info',
}
```

**Add:** `'linkres': 'error'` alongside `'orphan': 'error'`. One line change.

### 3. `--category` / `--skip-category` arg parsing — lines 120-160 [VERIFIED: bin/lint.sh]

No code change needed here. The `should_run(cat)` function at line 425 checks `category_filter == 'all' or category_filter == cat`. Adding `linkres` as a valid category just requires: (a) using `should_run('linkres')` in the new block, and (b) adding `linkres` to the usage string (lines 27-31).

**Usage string update needed:** line 27-31 currently lists: `orphan, crossref, stale, contradiction, gap, provenance, yaml, drift, duplicate, contributor, brownfield`. Add `linkres` to this list.

### 4. `duplicate` category as structural template — lines 1620-1768 [VERIFIED: bin/lint.sh]

The `duplicate` check (added in quick task 260602-d6a) is the most recent category addition and the best structural template for `linkres`. Key structural patterns to mirror:
- Self-contained page inventory (does not depend on `orphan` running first, but CAN reuse the resolution map if available)
- `should_run('linkres')` guard
- Findings added via `add_finding()` with `(severity, 'linkres', rel_path, message)`
- `--format json` works automatically (all findings go through the same pipeline)

Unlike `duplicate` (which is report-only), `linkres` also has a `--fix` path.

### 5. `--fix` frontmatter write pattern — lines 1434-1468 [VERIFIED: bin/lint.sh]

The `has_contradictions` auto-fix is the canonical pattern for idempotent frontmatter writes:
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

The self-alias fix is slightly more complex because it must parse the current `aliases:` list, add missing entries, and write back without destroying existing aliases. **Concrete approach:**

```python
def _add_self_aliases(content, title, page_id):
    """Idempotent: add title and id to aliases list, preserving existing entries.
    Returns (new_content, changed: bool).
    Uses simple regex — not YAML round-trip — to match existing lint.sh conventions."""
    # Find aliases block: match 'aliases:\n  - ...' OR 'aliases: []' OR 'aliases:\n'
    # Strategy: replace the existing aliases list with the augmented one.
    # Extract current aliases from the frontmatter block.
    import re
    fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        return content, False
    fm_text = fm_match.group(1)
    
    # Parse existing aliases lines from frontmatter
    existing_aliases = re.findall(r'^\s+- (.+)$', 
        re.search(r'^aliases:(.*?)(?=^\w)', fm_text, re.MULTILINE | re.DOTALL).group(1) if
        re.search(r'^aliases:', fm_text, re.MULTILINE) else '', re.MULTILINE)
    
    # Use PyYAML to get the current aliases list (already loaded as fm in lint context)
    # ... (see implementation note below)
```

**Implementation note:** Since `parse_frontmatter()` already returns the parsed `fm` dict (line 407), the `--fix` code has `fm` available. The cleanest approach is:
1. Read `fm.get('aliases') or []` to get the current list
2. Compute `needed = {title, page_id} - set(existing_aliases)` (case-sensitive add)
3. If `needed` is empty: skip (idempotent)
4. Otherwise: use `re.sub()` to locate and replace the `aliases:` block in the raw content string

The `re.sub()` approach on the raw text is consistent with how ALL other auto-fixes in lint.sh work (no ruamel.yaml dependency). The regex to match the aliases block:
```python
# Case 1: aliases: []  (empty list)
# Case 2: aliases:\n  - item\n  - item\n  (non-empty list)
ALIASES_BLOCK_RE = re.compile(
    r'^(aliases:)\s*(\[\]|\n(?:  - .+\n)*)',
    re.MULTILINE
)
```

### 6. `normalize_link()` helper — placement [VERIFIED: bin/lint.sh]

The helper should be defined as a module-level function, just above the `orphan` block (~line 1076), so it is available to:
- The `linkres` check (primary use)
- The reconciled `gap` check if it uses normalized matching for reporting
- Any future check needing the same normalization

```python
# ---------------------------------------------------------------------------
# Shared normalization helper (D-02: for linkres + reconciled orphan/gap)
# ---------------------------------------------------------------------------

_PLURAL_MAP = {
    'contexts': 'context',
    'policies': 'policy',
    'contracts': 'contract',
}
_PUNCT_RE = re.compile(r'[^\w\s]')  # strips parens, hyphens, punctuation
_WS_RE = re.compile(r'\s+')

def normalize_link(text):
    """D-02: casefold, strip punctuation chars (including parens — NOT their content),
    collapse whitespace, apply small explicit plural map.
    'Hack (Agentive Stack)' -> 'hack agentive stack' (NOT 'hack').
    'Bounded Contexts' -> 'bounded context'."""
    s = text.casefold()
    s = _PUNCT_RE.sub(' ', s)   # strip ALL punctuation chars (parens, hyphen, etc.)
    s = s.replace('_', ' ')     # underscore -> space (re module \w includes underscore)
    s = _WS_RE.sub(' ', s).strip()
    words = [_PLURAL_MAP.get(w, w) for w in s.split()]
    return ' '.join(words)
```

**Litmus test (D-02 validation):**
- `normalize_link('Hack (Agentive Stack)')` → `'hack agentive stack'` ✓ (NOT `'hack'`)
- `normalize_link('Bounded Contexts')` → `'bounded context'` ✓
- `normalize_link('domain-driven-design')` → `'domain driven design'` ✓

### 7. `linkres` check implementation outline

```python
# ---------------------------------------------------------------------------
# Check N: Obsidian-accurate link resolution (linkres) — LINK-04, LINK-05
# ---------------------------------------------------------------------------

if should_run('linkres'):
    print("  Checking Obsidian-accurate link resolution (linkres)...", file=sys.stderr)

    # --- Subcheck A: title-unreachable pages (LINK-04) ---
    # Every page's title and id must be reachable via filename stem or an alias.
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        title = fm.get('title', '')
        stem = os.path.splitext(os.path.basename(fpath))[0]
        aliases = [str(a) for a in (fm.get('aliases') or []) if a]
        reachable = {stem.lower()} | {a.lower() for a in aliases}

        if title and title.lower() not in reachable:
            rel = os.path.relpath(fpath)
            add_finding('error', 'linkres', rel,
                        f"title '{title}' not reachable via filename or aliases "
                        f"(Obsidian will not resolve [[{title}]]); "
                        f"run --fix to add self-alias")
            if do_fix and not dry_run:
                _apply_self_alias_fix(fpath, fm, title, pid)

        if pid and pid.lower() not in reachable:
            rel = os.path.relpath(fpath)
            add_finding('error', 'linkres', rel,
                        f"id '{pid}' not reachable via filename or aliases; "
                        f"run --fix to add self-alias")
            if do_fix and not dry_run:
                _apply_self_alias_fix(fpath, fm, title, pid)

    # --- Subcheck B: body link variants (LINK-05) ---
    # Build normalized map: normalize(stem OR alias) -> set of page ids
    norm_map = {}
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        stem = os.path.splitext(os.path.basename(fpath))[0]
        aliases = [str(a) for a in (fm.get('aliases') or []) if a]
        for name in ([stem] + aliases):
            key = normalize_link(name)
            norm_map.setdefault(key, set()).add(pid)
        # Also add title to norm_map (so links using exact title can be normalized-matched)
        if fm.get('title'):
            key = normalize_link(fm['title'])
            norm_map.setdefault(key, set()).add(pid)

    # Check all body links
    for fpath, fm, body, err in all_pages:
        if fm is None or body is None:
            continue
        linker_id = fm.get('id', '')
        rel = os.path.relpath(fpath)
        for target in WIKILINK_RE.findall(body):
            t = target.strip()
            t_lower = t.lower()
            # Skip if resolves correctly via Obsidian rules
            if t_lower in obsidian_map:
                continue
            # No-match: stays in gap, not linkres
            normed = normalize_link(t)
            matches = norm_map.get(normed, set())
            if len(matches) == 0:
                continue  # Genuine red link -- gap category handles this
            elif len(matches) == 1:
                target_id = list(matches)[0]
                add_finding('error', 'linkres', rel,
                            f"[[{t}]] does not resolve under Obsidian rules "
                            f"(no filename-stem or alias match), but uniquely "
                            f"normalized-matches '{target_id}'; "
                            f"fix: add alias OR correct link text")
            else:
                add_finding('warning', 'linkres', rel,
                            f"[[{t}]] does not resolve under Obsidian rules "
                            f"and normalized-matches multiple pages: {sorted(matches)}; "
                            f"manual triage required")
```

### 8. `_apply_self_alias_fix()` helper — idempotent frontmatter write

```python
def _apply_self_alias_fix(fpath, fm, title, page_id):
    """Idempotent: ensure aliases ⊇ {title, page_id}. Never removes existing aliases."""
    try:
        content = open(fpath, encoding='utf-8').read()
        existing = [str(a) for a in (fm.get('aliases') or []) if a]
        existing_lower = {a.lower() for a in existing}
        to_add = []
        if title and title.lower() not in existing_lower:
            to_add.append(title)
        if page_id and page_id.lower() not in existing_lower:
            to_add.append(page_id)
        if not to_add:
            return  # Already idempotent
        # Build new aliases block
        new_aliases = existing + to_add
        aliases_lines = '\n'.join(f'  - {a}' for a in new_aliases)
        new_block = f'aliases:\n{aliases_lines}'
        # Replace existing aliases block (handles both empty and non-empty)
        ALIASES_RE = re.compile(r'^aliases:.*?(?=^\w|\Z)', re.MULTILINE | re.DOTALL)
        new_content = ALIASES_RE.sub(new_block + '\n', content, count=1)
        if new_content == content:
            return  # Regex did not match; skip to avoid corruption
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        rel = os.path.relpath(fpath)
        add_finding('info', 'autofix', rel,
                    f'Added self-aliases: {to_add}')
    except Exception:
        pass
```

**Key regex:** `r'^aliases:.*?(?=^\w|\Z)'` with `re.MULTILINE | re.DOTALL` matches the entire aliases block from `aliases:` up to the next top-level YAML key (or end of frontmatter). The `count=1` prevents misfire on body text. This handles: `aliases: []`, `aliases:\n  - item`, `aliases:\n  - item\n  - item`.

---

## CLAUDE.md Edits Required

### §5 `title` field description — line 288 [VERIFIED: grep output]

**Current:** `| 'title' | string | Human-readable canonical title. Wikilinks resolve to this value. |`

**Corrected:** `| 'title' | string | Human-readable canonical title. Used in page headings and the self-alias (§8). Obsidian resolves `[[X]]` by **filename stem + `aliases`**, not by this field. |`

### §5 Frontmatter Validation Checklist — item 18 (new)

After current item 17 (`If 'decision_history' is present...`), add:
```
18. `aliases` contains the canonical `title` value (case-sensitive string match) — ensures `[[Title]]` resolves in Obsidian via the self-alias
19. `aliases` contains the `id` slug — ensures `[[slug]]` and `[[Title]]` both resolve
```

### §8 "Bad vs. Good Wikilink Examples" — add resolution explanation

The current §8 rules say "Use `[[Exact Page Title]]`" but do not explain that this only works if the `title` is in `aliases`. The fix adds a rule:

After rule 4 (`Use the 'aliases' frontmatter field for alternate names...`), insert:
```
4a. Every page MUST include its `title` and `id` slug in the `aliases` list.
    Obsidian resolves `[[X]]` by **filename stem + `aliases`**, NEVER by the `title` frontmatter field.
    Without self-aliases, `[[Title]]` renders as an unresolved red link even though a page with that title exists.
```

### §8 "Graph View Implications" — false claim in comment

The text "Obsidian resolves aliases to the canonical page automatically" (line 657) is partially correct (it describes alias resolution) but the preceding rule 1 says "Use `[[Exact Page Title]]`" without explaining that title ≠ filename. The correction clarifies the full mechanism.

### §8 "Bad vs. Good Wikilink Examples" — add self-alias example

```
BAD:  aliases: []                (empty — [[Title]] will not resolve in Obsidian)
GOOD: aliases:
        - "Exact Page Title"
        - page-id-slug           (self-aliases guarantee Obsidian resolution)
```

**Neutrality rule (CLAUDE.md §3):** All examples must use placeholders (`<page-title>`, `<entity-name>`, `<concept-slug>`) — no real vault terms.

### `schema/templates/*.md` and `schema/obsidian/*.md` — 12 files

Both sets of 6 templates (concept, entity, overview, comparison, source-summary, decision) currently have `aliases: []`. All 12 need the self-alias as a comment/instruction:

```yaml
aliases:
  # Self-alias invariant: add your page title and id slug here so [[Title]] resolves in Obsidian.
  # Example: if title is "My Concept" and id is "my-concept", add both.
  # See CLAUDE.md §8 for the Obsidian resolution rule.
```

The `schema/obsidian/*.md` templates use `{{title}}` placeholders. The correct form:
```yaml
aliases:
  - {{title}}
```

---

## Common Pitfalls

### Pitfall 1: `title` in `aliases` causes false-positive idempotency
**What goes wrong:** If `--fix` naively checks `title.lower() in existing_lower` but the page has `title: "Bounded Context"` and `aliases: ["Bounded Contexts"]`, it will add `Bounded Context` (correct). On re-run, since `bounded context` IS in `existing_lower`, it skips — correct idempotency.
**Prevention:** Always compare case-insensitively for the "already present?" check, then add the EXACT canonical title string (not lowercased) to the aliases list.

### Pitfall 2: Aliases regex captures body text
**What goes wrong:** `r'^aliases:.*?(?=^\w|\Z)'` with MULTILINE + DOTALL could match beyond the frontmatter if the body contains a line starting with `aliases:`.
**Prevention:** The ALIASES_RE regex must be applied only to the frontmatter section (content up to the second `---`). Extract the frontmatter section first, apply regex, then recompose. Alternatively: check that the match starts within the frontmatter (character position < second `---` index).

### Pitfall 3: `resolution_map` rename breaks `gap` block reuse guard
**What goes wrong:** The `gap` block at line 1481 has `if 'resolution_map' not in dir(): ...`. If `orphan` renames to `obsidian_map`, the guard breaks and `gap` always rebuilds.
**Prevention:** Update the guard check to match the new variable name in both the `orphan` and `gap` blocks.

### Pitfall 4: `title` normalization adds it to `obsidian_map` inadvertently
**What goes wrong:** If the `norm_map` in the `linkres` check is built from the FULL title set (not just stem+alias), and a link text normalizes to a title, it gets flagged as a unique-match error — but after `--fix` adds the self-alias, the same link would resolve via the alias. This is correct behavior: the unique-match error is precisely the "should resolve after --fix" case.
**Prevention:** Confirm in tests that after `--fix` runs, `--category linkres` produces 0 errors (idempotency pass).

### Pitfall 5: `duplicate` category's `dup_resolution` doesn't get the normalization fix
**What goes wrong:** `duplicate` builds its own `dup_resolution` dict (lines 1691-1695) and its own `dup_inbound` counter. It uses the same incorrect title-based resolution for counting inbound links (because it mirrors the orphan check). After reconciling `orphan`'s resolver, `duplicate`'s count may drift slightly.
**Prevention:** Check whether `duplicate`'s inbound count accuracy is affected by the resolution change. Since `duplicate` uses its own self-contained resolution (including title by default via `p['names'] = {title.lower()} | {alias.lower() ...}`), and since its purpose is finding near-duplicate PAGES (not checking link resolution), this is acceptable. Document the intentional separation.

### Pitfall 6: LINT_VERSION bump breaks `test_lint_require_version.sh`
**What goes wrong:** The test at line 10-11 asserts `--require-version 1.4.0` passes against LINT_VERSION 1.4.0. After bump to 1.5.0, `--require-version 1.4.0` still passes (1.4.0 ≤ 1.5.0), and `--require-version 1.5.0` also passes. But the test at lines 18-27 asserts `--require-version 1.5.0` FAILS — after the bump, this assertion flips.
**Prevention:** Update `test_lint_require_version.sh` when bumping:
- Line 10-11: update to `--require-version 1.5.0`
- Line 18-27: change `1.5.0` to `1.6.0` (the next version that should fail)
- Line 26-27: update "running version" assertion to `1.5.0`

### Pitfall 7: Neutrality rule on CLAUDE.md / schema edits
**What goes wrong:** CLAUDE.md §3 prohibits using real vault terms in template-public files. Any illustrative example in the §8 correction or schema templates that references real pages (e.g., `domain-driven-design`, `hack-agentive-stack`) violates this rule.
**Prevention:** Use abstract placeholders only: `<page-title>`, `<concept-slug>`, `<entity-name>`, `<YYYY-MM-DD-slug>`. Run `bash bin/check-neutrality.sh` after every CLAUDE.md edit.

### Pitfall 8: AGENTS.md sync
**What goes wrong:** The pre-commit hook enforces AGENTS.md ↔ CLAUDE.md byte-equality. If CLAUDE.md is edited without syncing AGENTS.md, the commit is rejected.
**Prevention:** Every CLAUDE.md edit plan task must include: `bash bin/sync-claude.sh && git add AGENTS.md` before committing. The pre-commit hook auto-stages CLAUDE.md if it detects drift, but the planner must explicitly sequence this.

### Pitfall 9: `--fix` run order matters for variant reconciliation
**What goes wrong:** Running `--fix` adds self-aliases. But it does NOT rewrite body links. So after `--fix`, the title-unreachable errors (subcheck A) disappear, but the body-link variant errors (subcheck B) remain — because links like `[[Bounded Contexts]]` still don't match via stem or alias (the canonical alias is `Bounded Context`, not `Bounded Contexts`).
**Prevention:** Wave 2 plans must run `--fix` FIRST (for self-aliases), then manually reconcile the 28 body-link variants. After both steps, `--category linkres` exits 0.

---

## Quantified Remediation Surface

### wiki/ pages [VERIFIED: live enumeration]
- **Total pages (excl. examples, maintenance, index, log):** 49
- **Pages needing self-alias fix:** 45 (45/49 have title or id missing from aliases)
- **Pages already compliant:** 4 (have both title and id in aliases — these were the 4 not in the list above: `anthropic.md`, `claude-code.md`, `backpressure.md`, `ralph-loop-creator-skill.md` — NOTE: these were the pages NOT in the needs-fix list; the count is 45 needs fix, 4 already have title but may still need id; the `--fix` handles all cases idempotently)

### Body link variants [VERIFIED: live enumeration]
- **Body links not resolving via Obsidian (stem+alias):** 37 unique link texts
- **With UNIQUE normalized match (D-01 → error):** 28 (all have exactly one match under D-02)
- **With no match (gap/red-links, NOT linkres):** 9 (intentional: kahneman cluster, AGENTS.md, Page Title template examples)
- **With ambiguous match:** 0 found in current corpus

The 28 unique-match defects break down by type:
- Title-exact links (page linked by `[[Title]]` but title not in aliases): ~26 of the 28 (e.g., `[[Domain-Driven Design]]`, `[[Bounded Context]]`, `[[Comprehension Debt]]`, `[[Eric Evans]]`)
- Plural variant: 1 (`[[Bounded Contexts]]` → normalized → `bounded context` → unique match `bounded-context`)
- Parens variant: 1 (`[[Hack (Agentive Stack)]]` → normalized → `hack agentive stack` → unique match `hack-agentive-stack`)
- Other case variants: 1 (`[[Is this the only skill left?]]` → normalized → `is this the only skill left` → unique match `src-2026-05-03-is-this-the-only-skill-left`)

After `--fix` adds self-aliases, ALL 26 title-exact links resolve (title IS added to aliases). The 2 remaining variants (`[[Bounded Contexts]]`, `[[Hack (Agentive Stack)]]`) require Wave 2 manual reconciliation (edit the call site per D-07/D-08).

Actually — re-examining: `[[Hack (Agentive Stack)]]` is the CANONICAL title for `hack-agentive-stack.md` (title field is "Hack (Agentive Stack)"). So after `--fix` adds `Hack (Agentive Stack)` as a self-alias, `[[Hack (Agentive Stack)]]` WILL resolve via alias. Only `[[Bounded Contexts]]` (plural) remains a pure call-site variant.

### examples/ pages [VERIFIED: live enumeration]
- **Total examples pages:** 20
- **All need self-aliases:** 20 (all have `aliases: []` with no title or id)
- **Lint-skip via `example: true`:** 11 pages have `example: true` (dataview-fixtures + kahneman/README + kahneman/log); 9 kahneman cluster pages have `example: false` but `example:` present

**Note on lint-skip:** The lint skips pages with `example: true` (line 972: `if isinstance(fm, dict) and fm.get('example') is True: continue`). The `linkres` check inherits this skip automatically (it operates on `all_pages`, which already excludes `example: true` pages). So `--category linkres` will only flag the 9 `example: false` pages in the kahneman cluster that need self-aliases. The 11 `example: true` pages are not gated but still benefit from having self-aliases for Obsidian graph connectivity.

---

## Validation Architecture

### Test Framework [VERIFIED: tests/]
| Property | Value |
|----------|-------|
| Framework | bash + inline `python3 -` assertions |
| Test dir | `tests/phase-09/` (linked category tests live here) |
| Aggregator | `tests/phase-09/run.sh` (iterates `test_*.sh`, tallies PASS/FAIL) |
| Quick run | `bash tests/phase-09/test_lint_linkres.sh` (new file) |
| Full suite | `bash tests/phase-09/run.sh` |
| Pattern | Self-contained temp wiki + inline assertions via `python3 -` JSON parse |

### Phase Requirements → Test Map

| REQ-ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LINK-01 | `CLAUDE.md` §8 contains "filename + aliases" (not title) | grep assertion | `grep -q "filename.*aliases" CLAUDE.md` | ❌ Wave 1 |
| LINK-02 | §5 checklist has `title ∈ aliases` item; templates have self-alias comment | grep assertion | `grep -q "title.*aliases" CLAUDE.md` | ❌ Wave 1 |
| LINK-03 | DR file exists, `trigger_type: schema-update`, in `wiki/index.md` | yaml+existence | inline check | ❌ Wave 1 |
| LINK-04 | `linkres` category flags title-unreachable pages (error severity) | `test_lint_linkres.sh` | `bash tests/phase-09/test_lint_linkres.sh` | ❌ Wave 1 |
| LINK-05 | unique-match → error; multi-match → warning; no-match → NOT linkres | `test_lint_linkres.sh` | same | ❌ Wave 1 |
| LINK-06 | `--fix` adds self-aliases idempotently; `orphan` no longer masks unresolved | `test_lint_linkres.sh` | same | ❌ Wave 1 |
| LINK-07 | `--category linkres` exits 0 over `wiki/` | end-to-end assertion | `bash bin/lint.sh --category linkres wiki/` | ❌ Wave 2 |
| LINK-08 | No `linkres error` findings for body-link variants | same as LINK-07 | same | ❌ Wave 2 |
| LINK-09 | `examples/` carries self-aliases | end-to-end or grep | check alias presence | ❌ Wave 2 |
| LINK-10 | Connected graph in Obsidian | human-verify | manual (LINK-10 is explicit human checkpoint) | N/A |

### `test_lint_linkres.sh` — Required Test Cases

1. **Title-unreachable error:** Page with `title: "My Concept"`, `id: my-concept`, `aliases: []`, filename `my-concept.md` → linkres error (title not reachable).
2. **After `--fix` title-unreachable becomes OK:** Run `--fix` → alias added → re-run `--category linkres` → 0 errors.
3. **Unique-normalized-match error:** Page A exists with title "Hack (Agentive Stack)" and alias "Hack". Page B links `[[Hack Agentive Stack]]` (no parens). Normalized match = unique. → linkres error.
4. **Multi-match warning:** Two pages each with titles that normalize to the same string. → linkres warning (not error).
5. **No-match → gap, NOT linkres:** Page links `[[Completely Unknown Page]]`. → no linkres finding; stays in gap.
6. **`--fix` idempotency:** Run `--fix` twice; second run makes no changes (no new autofix findings; file contents identical).
7. **CI `strict` stays green:** A new page added to a fixture repo that has `[prov:]` markers and proper type → strict exits 0 with `linkres` active.
8. **`orphan` reconciliation:** After adding self-alias to a previously title-only-reachable page, `orphan` count decreases (or page no longer orphaned). This tests D-03: orphan was masking the issue, now it surfaces correctly.

### Sampling Rate
- **Per task commit:** `bash bin/lint.sh --category linkres --dry-run wiki/` (fast, no write)
- **Per wave merge:** `bash tests/phase-09/run.sh`
- **Phase gate:** Full suite green + `--category linkres` exits 0 over wiki/ + `bin/sync-claude.sh --check` clean before `/gsd-verify-work`

### Wave 0 Gaps (test infrastructure before implementing)
- [ ] `tests/phase-09/test_lint_linkres.sh` — covers LINK-04, LINK-05, LINK-06 (8 cases above)
- [ ] `test_lint_require_version.sh` updates — version assertions to 1.5.0/1.6.0 after LINT_VERSION bump

No new framework, no conftest. The existing `tests/phase-09/lib.sh` pattern (self-contained temp wiki + inline assertions) works directly.

---

## Security Domain

No security-relevant surface in this phase. This is a tooling/schema correction with no authentication, user input, cryptography, or external API calls. Security domain section omitted.

---

## Environment Availability

This phase is code/config changes only. No external runtime dependencies beyond what the project already requires.

| Dependency | Required By | Available | Version | Notes |
|------------|------------|-----------|---------|-------|
| python3 | bin/lint.sh | ✓ | system | Already required |
| PyYAML | bin/lint.sh | ✓ | system | Already required |
| bash ≥4 | scripts | ✓ | system | Already required |
| Obsidian | LINK-10 human-verify | user machine | varies | Not a CI dependency |

---

## Runtime State Inventory

This phase does not rename, refactor, or migrate existing identifiers. It ADDS aliases to pages (additive, never destructive). No runtime state inventory needed.

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `resolution_map` built with title | `obsidian_map` built with stem+alias only | The title-based map was never correct for Obsidian; it masked orphan/gap defects |
| `aliases: []` in all templates | `aliases` with self-alias comment | Self-alias invariant enforced going forward |
| `LINT_VERSION="1.4.0"` | `LINT_VERSION="1.5.0"` | MINOR bump (non-breaking category addition) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `_PUNCT_RE = re.compile(r'[^\w\s]')` pattern strips parenthesis characters but Python's `\w` does not include them, so parens become spaces | Normalization helper | If Python `\w` changes behavior, `Hack (Agentive Stack)` test case breaks |
| A2 | Python's `re` module `\w` includes underscore, so `_` needs separate replacement | Normalization helper | If not, underscore-containing slugs mis-normalize |
| A3 | The `ALIASES_RE` lookahead `(?=^\w|\Z)` correctly identifies the end of the aliases YAML block in all frontmatter layouts | `--fix` implementation | Complex nested frontmatter might mismatch; tested with live pages |

All other claims in this research are VERIFIED against the live codebase.

---

## Open Questions

1. **Should `LINT_VERSION` be bumped in the same commit as the category addition, or as a final step?**
   - What we know: `test_lint_require_version.sh` pins the current version in assertions.
   - What's unclear: Whether to bump in Wave 1b (same as category addition) or Wave 2 (after tests pass).
   - Recommendation: Bump in the same commit as the `linkres` category addition (Wave 1b). Tests must be updated atomically with the bump in that commit.

2. **Should `--fix` emit one `autofix` finding per page or per alias added?**
   - What we know: `has_contradictions` emits one finding per page. `stale` emits one per claim.
   - Recommendation: One finding per page (listing what was added), matching `has_contradictions` precedent. Message: `"Added self-aliases: ['Bounded Context', 'bounded-context']"`.

3. **Does `duplicate` category need any change from the resolution map reconciliation?**
   - What we know: `duplicate` builds its own `dup_resolution` from title+aliases (line 1691-1695). It includes title in resolution (unlike the corrected `orphan`/`gap`). Its purpose is finding near-duplicate PAGES, not checking link resolution.
   - Recommendation: Leave `duplicate` unchanged. Its title-in-resolution is correct for its purpose (detecting "Geoff Hinton" vs "Geoffrey Hinton" as near-dup pages, not as link-resolution issues). Document the intentional separation in a comment.

---

## Sources

### Primary (HIGH confidence — verified against live codebase)
- `/home/yishai/Documents/compendium/bin/lint.sh` lines 1-2209 — full code study; resolution_map builder lines 1083-1105; severity-remap lines 316-330; orphan check lines 1080-1151; gap check lines 1478-1555; duplicate check lines 1620-1768; --fix pattern lines 1434-1468; all_pages loader lines 956-976
- `/home/yishai/Documents/compendium/wiki/` — live enumeration of 49 pages; alias inventory; body link analysis
- `/home/yishai/Documents/compendium/tests/phase-09/` — test structure, lib.sh helpers, test_lint_duplicate.sh pattern
- `/home/yishai/Documents/compendium/.github/workflows/lint.yml` — CI job structure; --require-version 1.1.0 pins
- `/home/yishai/Documents/compendium/docs/reference/ci.md` — severity table; `duplicate` as warning confirmed
- `/home/yishai/Documents/compendium/schema/templates/*.md` — 6 templates; all have `aliases: []`
- `/home/yishai/Documents/compendium/schema/obsidian/*.md` — 6 Obsidian templates with `{{title}}` placeholder
- Live Python enumeration: 45/49 wiki pages need self-alias; 28 unique body-link variants found

### Secondary (MEDIUM confidence)
- 14-CONTEXT.md D-01..D-08 (locked decisions, treated as authoritative input)
- CLAUDE.md §8, §5 — verified false claim at line 288; resolution description at lines 650-710

### Tertiary (LOW confidence)
- None. All findings verified against live code.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — code verified
- Architecture: HIGH — integration points verified against live code
- Pitfalls: HIGH — based on actual code patterns and live enumeration
- Remediation surface: HIGH — enumerated live

**Research date:** 2026-06-02
**Valid until:** 2026-07-02 (30 days; this is a static codebase, highly stable)
