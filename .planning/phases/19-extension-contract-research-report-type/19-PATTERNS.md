# Phase 19: Extension Contract + Research-Report Type - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 11 new/modified files (1 new schema/reference doc, 2 schema/reference edits, 2 schema/workflow edits, 2 bin script edits, 2 source summary updates, 1 decision record, plus AGENTS.md/CLAUDE.md routing row)
**Analogs found:** 10 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/reference/source-types.md` | reference-doc | transform (decision framework → contract tables) | `schema/reference/provenance.md` | role-match |
| `schema/reference/frontmatter.md` | reference-doc (edit) | config | `schema/reference/frontmatter.md` itself | self-edit |
| `schema/reference/provenance.md` | reference-doc (edit) | config | `schema/reference/provenance.md` itself | self-edit |
| `schema/workflows/ingest.md` | workflow-doc (edit) | batch | `schema/workflows/ingest.md` itself | self-edit |
| `schema/workflows/audit.md` | workflow-doc (edit) | event-driven | `schema/workflows/audit.md` itself | self-edit |
| `bin/lint.sh` | utility (edit) | batch, transform | `bin/lint.sh` itself — VALID_TYPES/VALID_STATUS pattern | self-edit, exact pattern |
| `bin/audit-claims.sh` | utility (edit) | batch, event-driven | `bin/audit-claims.sh` itself — RANK/selector_active pattern | self-edit, exact pattern |
| `AGENTS.md` / `CLAUDE.md` | config (edit) | config | AGENTS.md routing table rows (lines 47–62) | exact |
| `wiki-cloud/sources/src-2026-06-09-*.md` | source-summary (update) | CRUD | `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` itself | self-edit |
| `wiki-cloud/sources/src-2026-04-16-*.md` | source-summary (update) | CRUD | `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` | exact |
| `wiki-cloud/decisions/dr-2026-…-source-type-contract.md` | decision-record (new) | CRUD | `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` | exact |

---

## Pattern Assignments

### `schema/reference/source-types.md` (new reference-doc)

**Analog:** `schema/reference/provenance.md`

**File header pattern** (`schema/reference/provenance.md` lines 1–5):
```markdown
# Provenance, Epistemics, and Contradiction

> Agent-authoritative reference for inline provenance markers `[prov:...]`, epistemic status markers `[epistemic::]`, and contradiction markers `[contradiction:...]`.
> The AGENTS.md routing table points here (syntax/epistemics portion).
```
Apply: Open with `# Source Types` + a `> Agent-authoritative reference for…` blockquote that says "The AGENTS.md routing table points here." This is the pattern all `schema/reference/*.md` files use.

**Table-with-rows pattern** (`schema/reference/provenance.md` lines 26–32):
```markdown
| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | `#p12-14`, `#p8` | PDFs, papers |
| Section | `#sec:<name>` | `#sec:introduction` | Markdown sections |
```
Apply: Use the same 4-column table format for the 5-dimension retro-fit table (rows = source types, columns = the 5 dimensions). Use a 4-column table for the Evaluated Candidates registry (candidate, verdict, dimensions-changed, link).

**Graceful-degradation note pattern** (`schema/reference/provenance.md` lines 52–55):
```markdown
**Optional, with a documented fallback:** markers are never required. When present, `#p` resolves to a bounded passage; when absent, a `#p` locator degrades to the audit's first-class `insufficient-locator` verdict (NOT an error).
```
Apply: The `#r<n>` convention needs the same "graceful degradation" paragraph: when a source has no bibliography section, `#r<n>` degrades to `insufficient-locator` (NOT an error), matching the `<!-- page: N -->` precedent.

**See Also footer pattern** (`schema/reference/provenance.md` lines 186–191):
```markdown
## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (pointer to this file and to `schema/workflows/lint.md` for decay math).
- `schema/workflows/lint.md` — decay rate table, epistemic modifiers, staleness auto-fix rules.
- `schema/reference/frontmatter.md` — frontmatter fields including `epistemic_status`.
```
Apply: End `source-types.md` with a `## See Also` section linking back to AGENTS.md, `schema/reference/frontmatter.md` (source_type enum), `schema/workflows/ingest.md` (Pass 0), and `schema/reference/provenance.md` (#r<n> locator).

**Neutrality rule (MUST-NOT list):** `schema/reference/source-types.md` is a template-public file. ALL examples in tables must use abstract placeholders (`<source-id>`, `<report-slug>`, `<entity-name>`, `<date>`). Do NOT copy real source IDs from the retro-classification work into this file.

---

### `schema/reference/frontmatter.md` — `source_type` enum edit

**Analog:** `schema/reference/frontmatter.md` itself (lines 67, 135)

**Current enum line** (line 67):
```yaml
source_type: article|paper|transcript|journal|data|image
```
Change to: `source_type: article|paper|transcript|journal|data|image|research-report`

**Current validation checklist item 10** (line 135):
```markdown
10. For `type: source` pages: `path`, `content_hash`, `ingested_at`, and `source_type` are present
```
Add pointer sentence after the enum line (in the Source Summary Additional Fields block):
```markdown
Semantics for each type and the extension decision rule → `schema/reference/source-types.md`.
```

**Pattern for pointer stubs** — Phase 16 D-01 precedent, visible throughout the file: "no reproduced content, only the pointer." The frontmatter.md edit stays minimal.

---

### `schema/reference/provenance.md` — `#r<n>` locator row edit

**Analog:** `schema/reference/provenance.md` itself, Locator Types table (lines 26–32)

**Existing table to extend:**
```markdown
| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | `#p12-14`, `#p8` | PDFs, papers |
| Section | `#sec:<name>` | `#sec:introduction` | Markdown sections |
| Paragraph | `#para<number>` | `#para3` | Specific paragraphs |
| Timestamp | `#t<start>-<end>` | `#t00:12:10-00:12:48` | Audio/video transcripts |
| Image | `#img<number>` | `#img2` | Figures, diagrams |
```
Add row:
```markdown
| Reference | `#r<number>` | `#r7` | research-report bibliography entries |
```

**Graceful-degradation note to add** (modeled on the `#p` page-marker convention, lines 52–55):
```markdown
**Graceful degradation for `#r<n>`:** when a source has no bibliography section, `#r<n>` resolves to `insufficient-locator` (NOT an error), matching the `#p` page-marker precedent (D-06). Authors on sources without bibliographies should prefer `#sec:`/`#para` locators instead.
```

**Extended form usage example** — add to the "Examples in Context" block (line 72–78):
```markdown
- Research synthesis claim [prov:<report-slug>#r7|derived|<date>]
```
(Use abstract placeholder `<report-slug>` — NOT a real source ID; neutrality rule applies.)

---

### `schema/workflows/ingest.md` — Pass 0 and Claim Granularity edits

**Analog:** `schema/workflows/ingest.md` itself (lines 3, 17, 45–51)

**File header pattern** (lines 1–11):
```markdown
# Ingest Workflow

> Agent-authoritative reference for the ingest workflow: classifying a source, extracting claims with provenance, and merging into the wiki.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.
```
All workflow doc edits must preserve this `> …this file wins.` authority clause.

**Pass 0 classify step** (line 17):
```markdown
3. **Classify** (Pipeline Pass 0): Determine source type -- article, paper, transcript, journal entry, data file, or image-heavy.
```
Add `research-report` to the list. Add a Pass 0 note:
```markdown
   Research-reports are secondary sources (AI-synthesized or third-party aggregated). The `derived` support type and a lower epistemic default (`mixed`) apply automatically — see `schema/reference/source-types.md`.
```

**Claim Granularity table** (lines 45–51) — add `research-report` row:
```markdown
| research-report | Atomic claims, but every claim MUST carry `support_type: derived`; the report's synthesized conclusions are extracted, not its internal sources. | Never use `direct` — the report is a secondary source. Locators: `#r<n>` for bibliography-specific claims; `#sec:` or `#para` for body claims. |
```
Also reconcile the existing informal row labels ("report, technical doc", "book-chapter, essay") by adding a parenthetical mapping to their parent enum type (e.g., "report, technical doc — sub-cases of `article`").

---

### `schema/workflows/audit.md` — 5th selector documentation edit

**Analog:** `schema/workflows/audit.md` itself (lines 1–38)

The audit.md file currently has no explicit FAITH-01 selector list in the document body (the selectors live in `bin/audit-claims.sh`). Add a paragraph to the "What it is" block documenting the 5th selector:

```markdown
**Priority selectors (FAITH-01).** The audit samples from four risk tiers — `stale` (source drifted), `epistemic` (inline tentative/inferred), `recency` (recent changes), `fanout` (high-inbound pages) — plus a 5th tier for research-report claims: `derived-report` (claims citing `source_type: research-report` sources). Use `bin/audit-claims.sh --select derived-report` to sample this tier in isolation; it surfaces derived claims for faithfulness review since research-reports carry a lower epistemic default.
```

---

### `bin/lint.sh` — D-08 (derived-never-direct) + D-09 (enum validation) + LINT_VERSION

**Analog:** `bin/lint.sh` itself — exact code patterns to follow:

**LINT_VERSION** (line 13):
```python
LINT_VERSION="1.8.0"
```
Change to: `LINT_VERSION="1.9.0"`

**VALID_TYPES pattern** (lines 395–398) — exact template for D-09:
```python
VALID_TYPES = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}
VALID_STATUS = {'active', 'stale', 'superseded', 'archived'}
VALID_EPISTEMIC = {'sourced', 'mixed', 'tentative', 'stale'}
VALID_COMPILATION = {'pending', 'partial', 'compiled', 'stale'}
```
Add alongside these constants (before `BASE_FIELDS`):
```python
VALID_SOURCE_TYPES = {'article', 'paper', 'transcript', 'journal',
                      'data', 'image', 'research-report'}
```

**Enum validation pattern** (lines 1081–1095) — exact template for D-09 `source_type` check:
```python
# Source-specific fields
if fm.get('type') == 'source':
    missing_src = [f for f in SOURCE_EXTRA_FIELDS if f not in fm]
    if missing_src:
        add_finding('error', 'yaml', rel, f'Source page missing fields: {missing_src}')
    cs = fm.get('compilation_status')
    if cs and cs not in VALID_COMPILATION:
        add_finding('error', 'yaml', rel, f"Invalid compilation_status: '{cs}'")
```
Add inside this `if fm.get('type') == 'source':` block, after the compilation_status check:
```python
    st = fm.get('source_type', '')
    if st and st not in VALID_SOURCE_TYPES:
        add_finding('error', 'yaml', rel,
                    f"Invalid source_type: '{st}' (expected one of: "
                    f"{', '.join(sorted(VALID_SOURCE_TYPES))})")
```

**PROV_RE capture + source_registry pattern** (lines 1134–1138) — exact insertion point for D-08:
```python
prov_matches = PROV_RE.findall(mask_markdown(body))
for source_id, locator, support_type, checked_at in prov_matches:
    if source_id not in source_registry:
        add_finding('error', 'provenance', rel,
                    f'Broken prov ref: {source_id} not found in {wiki_dir}sources/')
```
After the `if source_id not in source_registry:` block (so only when the source IS in the registry), add D-08:
```python
    # D-08: derived-never-direct for research-report sources
    else:
        src_fm = source_registry.get(source_id)
        if isinstance(src_fm, dict) and src_fm.get('source_type') == 'research-report':
            if support_type == 'direct':
                add_finding('error', 'provenance', rel,
                            f'Epistemic laundering: [prov:{source_id}#...] '
                            f'uses support_type=direct on a research-report source '
                            f'(secondary sources must use derived)')
```
**Scoping note:** The D-08 check must NOT fire on pages where `fm.get('type') == 'source'` (source summary pages self-cite with `direct`, which is correct). Add a guard: `if fm.get('type') == 'source': continue` before entering the PROV_RE loop for that page, OR scope the D-08 check with `if fm.get('type') != 'source':`.

**add_finding signature** (line 465):
```python
def add_finding(severity, category, path, message):
    findings.append((severity, category, path, message))
```
All new checks use this exact signature — `('error', 'provenance', rel, message)` for D-08 and `('error', 'yaml', rel, message)` for D-09.

---

### `bin/audit-claims.sh` — D-10a (5th selector) + D-10b (`#r<n>` resolver)

**Analog:** `bin/audit-claims.sh` itself — exact code patterns to follow:

**source_registry structure** (lines 250–258) — critical: audit-claims.sh wraps source frontmatter:
```python
# source_registry: source_id -> {'fm': sfm, 'summary_rel_path': rel}
source_registry = {}
source_summary_path = {}
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        rel = os.path.relpath(sp, REPO_ROOT)
        source_registry[sfm['id']] = {'fm': sfm, 'summary_rel_path': rel}
```
Note: audit-claims.sh stores `{'fm': sfm, …}` (nested), while lint.sh stores `sfm` flat. When accessing `source_type` in audit-claims.sh, use `entry['fm'].get('source_type')` — see the `read_raw_source` guard pattern at line 473: `sfm = entry['fm'] if isinstance(entry, dict) else entry`.

**RANK dict and selector_active pattern** (lines 605–632):
```python
RANK = {'stale': 1, 'epistemic': 2, 'recency': 3, 'fanout': 4}
selected = {}  # key (rel,line,sid,loc) -> (rank, tuple, selectors)

def selector_active(name):
    return name in SELECT

for rel, line, sid, loc, line_text, fm in all_claims:
    key = (rel, line, sid, loc)
    hits = []
    if selector_active('stale') and sid in drifted_sources:
        hits.append('stale')
    if selector_active('epistemic') and EPISTEMIC_INLINE_RE.search(line_text):
        ekind = EPISTEMIC_INLINE_RE.search(line_text).group(1)
        if ekind in ('inferred', 'tentative'):
            hits.append('epistemic')
    if selector_active('recency'):
        if first_run_wide or rel in recency_pages:
            hits.append('recency')
    if selector_active('fanout') and rel in high_fanout_paths:
        hits.append('fanout')
    if not hits:
        continue
    best_rank = min(RANK[h] for h in hits)
```
D-10a additions:
1. Add `'derived-report': 5` to RANK dict.
2. Add a 5th `selector_active` branch inside the for-loop, after the `fanout` branch:
```python
    if selector_active('derived-report'):
        entry = source_registry.get(sid, {})
        src_fm = entry.get('fm', {}) if isinstance(entry, dict) else {}
        if src_fm.get('source_type') == 'research-report':
            hits.append('derived-report')
```
3. Add `derived-report` to the `--select` CSV default (line ~50).

**resolve_locator function structure** (lines 423–464) — D-10b insertion point:
```python
def resolve_locator(raw_source_text, locator):
    loc = locator.strip()
    if not loc.startswith('#'):
        loc = '#' + loc
    try:
        if loc.startswith('#img'):
            return None, 'skipped-nontext'
        if loc.startswith('#sec:'):
            …
        if loc.startswith('#para'):
            …
        if loc.startswith('#t'):
            …
        if loc.startswith('#p'):
            …
    except Exception:
        return None, None
    # unknown / malformed locator
    return None, None
```
Add `#r<n>` case before the final `return None, None` (inside the `try:` block, after `#p`):
```python
        if loc.startswith('#r') and loc[2:].isdigit():
            n = int(loc[2:])
            return _resolve_ref(raw_source_text, n), None
```
Add `_resolve_ref` helper alongside the other `_resolve_*` helpers (before `resolve_locator`):
```python
def _resolve_ref(text, n):
    """Return the Nth bullet in the first bibliography section found.
    Searches candidate headers in order: ## Source Citations, ## Sources by Topic,
    ## Sources, ## References (first match wins). Positional numbering is
    sequential across topic groups. Returns None if not found or N out of range."""
    import re
    header_re = re.compile(
        r'^##\s+(Source Citations|Sources by Topic|Sources|References)\s*$',
        re.MULTILINE | re.IGNORECASE
    )
    bullet_re = re.compile(r'^- (.+)', re.MULTILINE)
    m = header_re.search(text)
    if not m:
        return None
    after_header = text[m.end():]
    next_h = re.search(r'^##\s', after_header, re.MULTILINE)
    section = after_header[:next_h.start()] if next_h else after_header
    bullets = bullet_re.findall(section)
    if not bullets or n < 1 or n > len(bullets):
        return None
    return bullets[n - 1]
```

---

### `AGENTS.md` / `CLAUDE.md` — routing table row (D-02)

**Analog:** Existing routing table rows in AGENTS.md/CLAUDE.md (lines 47–62 of CLAUDE.md)

**Exact existing row format:**
```markdown
> | Authoring a wiki page (type rules, section order) | `schema/reference/page-types.md` |
> | Checking required frontmatter fields | `schema/reference/frontmatter.md` |
> | Adding `[prov:]` or `[epistemic::]` markers | `schema/reference/provenance.md` |
```

**New row to add** (must match `ROUTING_ROW_RE = re.compile(r'^> \|[^\n|]*\|[^\n|]*`([^`\n]+)`[^\n|]*\|', re.MULTILINE)`):
```markdown
> | Adding/evaluating a new source type | `schema/reference/source-types.md` |
```

**Sync requirement:** AGENTS.md and CLAUDE.md must be byte-equal after the edit. Run `bin/sync-claude.sh --check` to verify. The routing row and the new file creation (`schema/reference/source-types.md`) MUST land in the same commit — the lint routing forward-check will emit a dangling-reference error if the row exists without the file.

---

### `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` and `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md` — retro-classification updates

**Analog:** `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` (full file — current state)

**Frontmatter changes (both files):**
```yaml
# Change:
source_type: article
# To:
source_type: research-report
```
Also bump `updated_at` to `2026-06-10`.

**Citation registry block to add** (D-06, D-13) — follows the body's existing `## Extracted Claims` section. Pattern from RESEARCH.md Code Examples:
```markdown
## References

<!-- r<n> = positional index into the bibliography section of the raw source -->
<!-- raw source: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug.md -->

- r1:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
- r2:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
```
The `r<n>:: ` prefix makes each entry a Dataview inline field (key `r<n>`, value the rest of the line). The `status: registry` token marks unverified/unpromoted entries. When promoted: append ` | promoted → <new-source-id>` to the status value.

**Self-citation `direct` markers stay unchanged:** The source summary's own `## Extracted Claims` cite `[prov:<own-id>#…|direct|…]`. These are correct and must NOT be swept. The D-11 sweep targets only DEPENDENT pages (entities/concepts/comparisons/overviews), not source summaries.

---

### `wiki-cloud/decisions/dr-2026-…-source-type-contract.md` (new decision record)

**Analog:** `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` (full file)

**Frontmatter pattern** (lines 1–24 of skills-overlay):
```yaml
---
id: dr-2026-06-08-skills-overlay
title: "Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate"
type: decision
status: active
summary: "…one-sentence description…"
created_at: 2026-06-08
updated_at: 2026-06-08
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-08-skills-overlay
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---
```
Apply: New DR uses `trigger_type: schema-update`, `affected_pages: []` (infrastructure-only decision, no content pages gain `decision_history`), `domains: [wiki-infrastructure]`.

**Section structure** (skills-overlay body):
```markdown
# <Title>

## TL;DR
## Decision
## Why
## Alternatives Considered
## Consequences
## Affected Pages
## Sources
```
Apply: Same section order. "Decision" describes what was added (the contract doc, the research-report type, the lint checks). "Why" covers the epistemic-laundering threat model from the seed. "Alternatives Considered" can cover the design choices from CONTEXT.md Claude's Discretion items.

---

## Shared Patterns

### Enum validation (lint.sh yaml category)

**Source:** `bin/lint.sh` lines 1081–1095
**Apply to:** D-09 `source_type` check
```python
VALID_TYPES = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}
VALID_STATUS = {'active', 'stale', 'superseded', 'archived'}
# (add alongside)
VALID_SOURCE_TYPES = {'article', 'paper', 'transcript', 'journal',
                      'data', 'image', 'research-report'}

# Pattern in the yaml check loop:
if 'type' in fm and fm['type'] not in VALID_TYPES:
    add_finding('error', 'yaml', rel, f"Invalid type: '{fm['type']}'")
# (mirrors the new source_type check)
```

### Provenance loop with source_registry lookup (lint.sh provenance category)

**Source:** `bin/lint.sh` lines 1123–1138
**Apply to:** D-08 derived-never-direct check

The PROV_RE captures four groups: `(source_id, locator, support_type, checked_at)`. The `source_registry` dict maps `source_id → sfm` (flat dict in lint.sh). The D-08 check slots after the broken-ref check, inside the for-loop, using `source_registry.get(source_id)` to load `source_type`.

### Selector + RANK pattern (audit-claims.sh)

**Source:** `bin/audit-claims.sh` lines 605–632
**Apply to:** D-10a 5th selector

The `selector_active(name)` function checks `name in SELECT`. The SELECT set is built from the `--select` CSV CLI flag (line ~50 default: `stale,epistemic,recency,fanout`). The RANK dict assigns priority 1–4; the 5th selector gets rank 5. The for-loop accumulates `hits` and calls `min(RANK[h] for h in hits)` to find the best (lowest) rank.

### resolve_locator per-scheme dispatcher (audit-claims.sh)

**Source:** `bin/audit-claims.sh` lines 423–464
**Apply to:** D-10b `#r<n>` resolver

Each locator scheme is an `if loc.startswith('#<prefix>'):` branch inside a `try/except Exception: return None, None` block. Unknown locators fall through to `return None, None` (which the caller maps to `insufficient-locator`). New `_resolve_ref` helper follows the `_resolve_sec` / `_resolve_para` / `_resolve_t` / `_resolve_page` naming pattern.

### Routing table row format (AGENTS.md/CLAUDE.md)

**Source:** `CLAUDE.md` lines 47–62, checked by `ROUTING_ROW_RE` in lint.sh line 2462
**Apply to:** D-02 routing row for `schema/reference/source-types.md`

```
^> \|[^\n|]*\|[^\n|]*`([^`\n]+)`[^\n|]*\|
```
Row must be inside the `> | … | \`path\` |` blockquote-table form. The description column is free text; the path column must be the exact repo-relative path enclosed in backticks.

### Decision record structure

**Source:** `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md`
**Apply to:** New DR for Phase 19 schema change

Commit prefix for a standalone DR: `reflect(<scope>): …` (CLAUDE.md conventions table). `trigger_type: schema-update`.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `schema/reference/source-types.md` (content) | reference-doc | transform | No existing "extension contract / decision framework" reference doc in the codebase; the 5-dimension table and evaluated-candidates registry are new structural forms. The closest analog for file structure is `schema/reference/provenance.md`; the content pattern (decision framework with verdict registry) has no direct precedent — use RESEARCH.md Code Examples + seeds for content. |

---

## Coupling Constraint (not a pattern — a sequencing rule)

The D-08 lint check (derived-never-direct error) and the D-11 retro-classification sweep (97 `|direct|` → `|derived|` markers in 14 dependent pages) are coupled. The planner must schedule the sweep in the same commit as or earlier than the D-08 lint check. If the lint check lands first, CI goes red because the existing `|direct|` markers on research-report sources will immediately trigger errors.

The sweep must exclude `wiki-cloud/sources/` (source summary pages self-cite with `direct`, which is correct). Scope the sed/replace to `wiki-cloud/entities/`, `wiki-cloud/concepts/`, `wiki-cloud/comparisons/`, and `wiki-cloud/overviews/` only.

---

## Metadata

**Analog search scope:** `schema/reference/`, `schema/workflows/`, `bin/`, `wiki-cloud/sources/`, `wiki-cloud/decisions/`
**Files scanned:** 9 (provenance.md, frontmatter.md, ingest.md, audit.md, lint.sh, audit-claims.sh, src-2026-06-09-pdf-to-text-llm-ingestion-sota.md, dr-2026-06-08-skills-overlay.md, CLAUDE.md)
**Pattern extraction date:** 2026-06-10
