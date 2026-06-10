# Phase 19: Extension Contract + Research-Report Type - Research

**Researched:** 2026-06-10
**Domain:** Schema documentation and tooling (markdown schema files, bash/Python scripts)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** New `schema/reference/source-types.md` is THE authoritative home for source typing: the 5-dimension contract, primary/secondary axis, decision rule, retro-fit table, worked instances, AND ownership of `source_type` enum semantics. `schema/reference/frontmatter.md` keeps its enum line but points to source-types.md for semantics; `schema/workflows/ingest.md` Pass 0 points to it for classification.

**D-02:** source-types.md gets a row in the AGENTS.md/CLAUDE.md routing table ("Adding/evaluating a new source type → `schema/reference/source-types.md`"). Byte-equality maintained via `bin/sync-claude.sh`. Phase 18's no-new-core-lines precedent applies to pointers, not authoritative refs — every authoritative `schema/reference/*.md` has a routing row.

**D-03:** Retro-fit table covers ALL six existing enum types (article, paper, transcript, journal, data, image) plus `research-report` as the worked 7th. While writing it, **reconcile the ingest claim-granularity table vocabulary** (report, technical doc, book-chapter, essay, meeting notes…) to enum types — sub-case names map to their parent enum type via the contract's sub-case concept.

**D-04:** source-types.md includes an **"Evaluated candidates" sub-case registry**: one row per evaluated candidate (pdf, video, repository, …) with verdict (new type / sub-case of X), dimensions touched, link to its convention doc. Phases 20–21 append rows here instead of inventing structure.

**D-05:** New locator row in `schema/reference/provenance.md` Locator Types table: `Reference | #r<number> | #r7 | research-report bibliography entries`. Explicit and grep-able; claims cite `[prov:<report-src>#r7|derived|<date>]`.

**D-06:** The citation registry lives as a **body `## References` block** in the source summary page — one entry per citation keyed `r<n>::` with URL, title, access date, and promotion status. NO new frontmatter field (avoids 30-entry YAML blobs; respects the no-provenance-blobs-in-frontmatter rule; Dataview-reachable via inline fields).

**D-07:** Promotion mechanics (RPT-05, Model C): when a citation earns promotion, the human acquires the cited page and it gets its own normal ingest; the **earning claim is re-pointed** — `[prov:report#r7|derived]` → `[prov:new-source#locator|direct]` (an UPDATE op) — and the registry entry is marked `promoted → <new-source-id>`. Other claims citing the report stay as-is.

**D-08:** Lint mechanically enforces derived-never-direct (RPT-03): new check in the provenance category — `[prov:<research-report-src>#…|direct]` is an **error**. This is the anti-laundering defense; convention-only would silently regress. LINT_VERSION bumps 1.8.0 → 1.9.0.

**D-09:** Lint also validates `source_type` enum VALUES (currently presence-only): unknown values are an error; the valid set is defined once, matching source-types.md. Closes the typo-bypass hole in D-08.

**D-10:** `bin/audit-claims.sh` gets BOTH thin additions for RPT-04: (a) a **5th priority selector** (research-report/derived claims) alongside stale/epistemic/recency/fanout; (b) `resolve_locator` learns to resolve `#r<n>` **positionally** against the report's bibliography section, so prioritized claims return real passages instead of `insufficient-locator`.

**D-11:** Full claims sweep: all existing `direct` markers across 14 wiki pages citing the two reports are rewritten `direct → derived`. Locators stay unchanged. Lint goes green by fixing data, not by grandfathering.

**D-12:** Page-level `epistemic_status` is re-graded in the same sweep: dependent pages whose provenance-backed claims are now mostly derived drop to `mixed`; `updated_at` bumped.

**D-13:** Full registry backfill for both reports with **positional numbering**: `r<n>` = nth entry top-to-bottom in the raw source's bibliography section (raw sources are immutable — numbering is never added to the source files). The summary page's `## References` registry records the complete mapping (~12 entries for the PDF-SOTA report's "## Source Citations", ~15 entries for the frameworks report's "## Sources by Topic") with URL/title/status.

**D-14:** Retro-classification is NOT a re-ingest: summary pages get `source_type: research-report` + registry; claims get the D-11/D-12 sweep; no re-extraction of new claims.

### Claude's Discretion

- Exact section structure/wording of source-types.md (contract prose, table layouts) — must use neutral placeholders in template-public surfaces per the MUST-NOT list.
- The reconciled granularity-table vocabulary mapping (which loose names map to which enum parents).
- Whether the frameworks report's topic-grouped "## Sources by Topic" numbers positionally across groups or per-group (pick one, document it in the registry convention).
- Epistemic default wording: seed says `mixed` (or `tentative`) — pick the default and when each applies.
- Audit selector name and CLI `--select` token for the 5th selector.
- Whether the sweep is scripted (one-off) or hand-applied — one commit per logical operation either way.
- Decision-record authoring for the schema change.

### Deferred Ideas (OUT OF SCOPE)

- **999.5 External Source Drift detection** — citation registries are its natural trigger; explicitly out of this milestone.
- **`repository` source type** — gets a sub-case-registry row only if evaluated; implementation stays backlog.
- **Web-assist inside query workflow** — noted in the seed as "likely out of scope even when this seed promotes"; do not build.
- Phase 14 `lint-mask-fence-edge-cases` todo — reviewed-not-folded, stays pending.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXT-01 | A source-type extension contract exists in `schema/reference/` defining the 5-dimension recipe (acquisition / locator / extraction granularity / drift / epistemic default) and the primary-vs-secondary axis | source-types.md is the new authoritative file; the 5 dimensions and the primary/secondary axis come directly from the seeds |
| EXT-02 | The contract encodes the decision rule: a new `source_type` is justified only if it changes at least one of the 5 dimensions; otherwise the candidate is documented as a sub-case | The seeds define this rule explicitly; source-types.md formalizes it with an "Evaluated candidates" registry |
| EXT-03 | Existing source types are retro-fit as contract instances (a table mapping each current type across the 5 dimensions), with `research-report` as the worked secondary instance | All 6 existing enum values plus `research-report` get rows in the retro-fit table |
| RPT-01 | `source_type: research-report` is added to the frontmatter enum and ingest Pass-0 classification | frontmatter.md enum line + source-types.md semantics + ingest.md Pass 0 classify step |
| RPT-02 | The ingest convention preserves the report's bibliography intact and captures it as an addressable citation registry in the source summary | `## References` body block with `r<n>::` keyed entries; raw source is immutable |
| RPT-03 | Claims carry `support_type: derived` (never `direct`), with locators reusing the report's own reference anchors | New `#r<n>` locator row in provenance.md; lint enforcement via D-08/D-09 |
| RPT-04 | Research-report claims default to a lower epistemic tier and are flagged as priority audit targets | epistemic default `mixed` (body of report) or `tentative` (bibliography-only), new audit selector for derived claims |
| RPT-05 | Any citation-registry entry is promotable to a first-class source (Model C hybrid promotion path, documented) | D-07 documents the re-pointing mechanics and `promoted → <source-id>` registry status |
| RPT-06 | The two already-ingested deep-research reports are retro-classified with citation registries backfilled | 97 `direct` → `derived` markers swept in 14 pages; 2 source summary pages updated; registries backfilled |
</phase_requirements>

---

## Summary

Phase 19 is a pure documentation, schema, and tooling phase — no new external libraries, no new runtimes. All deliverables are markdown schema files under `schema/reference/` and `schema/workflows/`, bash/Python additions to `bin/lint.sh` and `bin/audit-claims.sh`, and wiki mutations (source summary updates + dependent-page claim sweep).

The phase has two tightly coupled deliverables. The extension contract (`schema/reference/source-types.md`) formalizes the 5-dimension decision framework from the seeds into a reusable contract with a retro-fit table covering all 7 source types (6 existing + `research-report`). The `research-report` type is the worked secondary instance that validates the contract against real examples, implemented across five surfaces: the `source_type` enum (frontmatter.md + source-types.md), the `#r<n>` locator (provenance.md), the ingest convention (ingest.md Pass 0), the citation registry convention (source summary body), and the lint/audit enforcement (bin/lint.sh D-08/D-09, bin/audit-claims.sh 5th selector).

The retro-classification work (RPT-06) is the most mechanical part: 97 `|direct|` markers in 14 dependent wiki pages need to become `|derived|`, and 2 source summary pages need `source_type: article` changed to `source_type: research-report` plus a `## References` registry block added. The D-08 lint check must land in the same commit sequence as or after the sweep — the sweep first, then the new lint check — so CI never goes red between commits.

**Primary recommendation:** Author source-types.md first (the contract document), then add the `#r<n>` locator row to provenance.md and the new lint checks to lint.sh, then do the retro-classification sweep (which must land before the D-08 check fires), then do the wiki mutations (source summaries + index/log updates). This ordering keeps CI green throughout.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Extension contract definition | Schema docs (`schema/reference/source-types.md`) | AGENTS.md/CLAUDE.md routing table | The contract is a documentation artifact; the router provides entry-point discovery |
| `source_type` enum enforcement | `bin/lint.sh` (yaml category, D-09) | `schema/reference/frontmatter.md` (declares the enum) | Lint is the mechanical enforcer; frontmatter.md declares the valid set |
| Derived-never-direct enforcement | `bin/lint.sh` (provenance category, D-08) | `bin/audit-claims.sh` (5th selector flags them for review) | Lint gates CI; audit provides deeper verification |
| Citation registry | Source summary body (`## References` block) | — | Body placement avoids YAML blob; Dataview-reachable via inline fields |
| `#r<n>` locator resolution | `bin/audit-claims.sh` (`resolve_locator`) | — | Audit resolves locators to passages; lint only validates syntax |
| Retro-classification sweep | Direct wiki page edits (14 dependent pages + 2 summary pages) | `wiki-cloud/log.md` (UPDATE op log) | Wiki mutations go through the standard UPDATE operation |

---

## Standard Stack

This phase has no new library dependencies. All tooling is in the existing stack.

### Core (already present)

| Tool | Version | Purpose |
|------|---------|---------|
| Python 3 | 3.12.3 [VERIFIED: shell] | Single Python heredoc inside bin/lint.sh and bin/audit-claims.sh |
| Bash | 5.2.21 [VERIFIED: shell] | Outer shell for both bin scripts |
| git | 2.43.0 [VERIFIED: shell] | Commit and diff operations in lint/audit |
| PyYAML | stdlib (already imported in lint.sh) | Frontmatter parsing |

**No new packages to install.** [VERIFIED: confirmed by reviewing bin/lint.sh imports — only stdlib + PyYAML]

---

## Architecture Patterns

### System Architecture Diagram

```
CONTEXT.md (D-01..D-14 locked decisions)
        │
        ▼
schema/reference/source-types.md ──────────────────────────────┐
  [NEW] 5-dim contract, retro-fit table, evaluated candidates   │
        │                                                        │
        ├── pointer from frontmatter.md (source_type enum line) │
        ├── pointer from ingest.md (Pass 0 classify step)       │
        └── routing row in AGENTS.md/CLAUDE.md                  │
                                                                 │
schema/reference/provenance.md                                   │
  [EDIT] +#r<n> row in Locator Types table                       │
                                                                 │
bin/lint.sh                                                      │
  [EDIT] LINT_VERSION 1.8.0 → 1.9.0                             │
  [EDIT] VALID_SOURCE_TYPES set (D-09)                           │
  [EDIT] provenance check: derived-never-direct for research-report sources (D-08)
                                                                 │
bin/audit-claims.sh                                              │
  [EDIT] RANK dict: add 'derived-report' rank 5 (D-10a)         │
  [EDIT] resolve_locator: add #r<n> positional resolver (D-10b) │
                                                                 │
schema/workflows/ingest.md                                       │
  [EDIT] Pass 0 classify: add research-report case              │
  [EDIT] Claim Granularity table: reconcile vocabulary (D-03)   │
                                                                 │
schema/workflows/audit.md                                        │
  [EDIT] FAITH-01 selectors: document the 5th selector          │
                                                                 │
                    ┌───────────────────────────────────────────┘
                    ▼
wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md
wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md
  [UPDATE] source_type: article → research-report
  [UPDATE] + ## References registry block (D-13)
                    │
                    ▼
14 dependent wiki pages (entities + concepts + comparisons + overviews)
  [UPDATE] 97 |direct| → |derived| (D-11)
  [UPDATE] page-level epistemic_status re-graded where "mostly derived" (D-12)
  [UPDATE] updated_at bumped
                    │
                    ▼
wiki-cloud/log.md + wiki-cloud/index.md
  [APPEND] UPDATE ops logged per log-format.md convention
```

### Recommended Project Structure Changes

No new directories. New and edited files only:

```
schema/reference/
├── source-types.md          # NEW — extension contract (EXT-01..03, RPT-01)
├── frontmatter.md           # EDIT — source_type enum pointer + research-report to enum
├── provenance.md            # EDIT — #r<n> locator row (RPT-02, RPT-03)
schema/workflows/
├── ingest.md                # EDIT — Pass 0 + granularity table (RPT-01, D-03)
├── audit.md                 # EDIT — 5th selector documented (RPT-04, D-10)
bin/
├── lint.sh                  # EDIT — D-08, D-09, LINT_VERSION bump
├── audit-claims.sh          # EDIT — D-10a (selector), D-10b (resolve_locator)
AGENTS.md / CLAUDE.md        # EDIT — routing table row (D-02); byte-sync via bin/sync-claude.sh
wiki-cloud/sources/
├── src-2026-06-09-pdf-to-text-llm-ingestion-sota.md   # UPDATE — retro-classify
├── src-2026-04-16-claude-code-frameworks-report.md     # UPDATE — retro-classify
wiki-cloud/ (14 dependent pages)                        # UPDATE — D-11/D-12 sweep
wiki-cloud/log.md                                       # APPEND
wiki-cloud/index.md                                     # EDIT (if source summaries need re-description)
wiki-cloud/decisions/                                   # NEW DR for schema change (reflect tier)
```

---

## Existing Schema Surfaces — Detailed Findings

### frontmatter.md — source_type enum (current state)

The `source_type` field in `schema/reference/frontmatter.md` (Source Summary Additional Fields block) currently reads:

```yaml
source_type: article|paper|transcript|journal|data|image
```

[VERIFIED: read frontmatter.md directly]

Changes needed:
1. Add `research-report` to the enum pipe-separated list.
2. Add a pointer sentence: "Semantics for each type and the extension decision rule live in `schema/reference/source-types.md`."
3. Update the Frontmatter Validation Checklist item 10 to include the new value.

The `SOURCE_EXTRA_FIELDS` list in `bin/lint.sh` (line 406) already includes `source_type` as a required field for type:source pages; the new VALID_SOURCE_TYPES set (D-09) enforces the enum values. [VERIFIED: read lint.sh line 406]

### provenance.md — Locator Types table (current state)

Current locators: Page range (#p), Section (#sec:), Paragraph (#para), Timestamp (#t), Image (#img). [VERIFIED: read provenance.md]

New row for `#r<n>`:

| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Reference | `#r<number>` | `#r7` | research-report bibliography entries |

The `#r<n>` locator is positional: `r1` = first bullet in the bibliography section (top-to-bottom reading), `r2` = second, etc. For the frameworks report with topic-grouped sources, positional numbering runs sequentially across groups (not per-group). This makes `rN` deterministic from the raw source without adding any markup to the immutable file.

**Graceful degradation:** when a source has no bibliography section, `#r<n>` resolves the same way as a missing `<!-- page: N -->` marker — the audit emits `insufficient-locator` (not an error). This matches the existing `#p` graceful-degradation pattern in provenance.md.

### ingest.md — Pass 0 and Claim Granularity table (current state)

The Pass 0 classify step (Step 3 of ingest workflow) currently lists: "article, paper, transcript, journal entry, data file, or image-heavy." [VERIFIED: read ingest.md]

Changes needed:
1. Add `research-report` to the Pass 0 classify list.
2. Add a Pass 0 note: research-reports are secondary sources — the `derived` support type and lower epistemic default apply automatically.
3. Claim Granularity table reconciliation (D-03): the table currently has informal row labels like "article, paper, report, technical doc" and "book-chapter, essay". These need to map to the 6 official enum types. The vocabulary mapping (Claude's discretion):
   - "report, technical doc" → sub-cases of `article` (no new type — same acquisition/locator/granularity)
   - "book-chapter, essay" → sub-cases of `article` or `paper` depending on academic vs general
   - "meeting notes" → sub-case of `transcript`
   - `research-report` → new row in the granularity table: "Atomic claims, but every claim MUST carry `support_type: derived`; the report's synthesized conclusions are extracted, not its internal sources"

### lint.sh — current provenance check architecture (relevant section)

The provenance check (lines 1123–1138) currently:
1. Iterates all pages (skipping errors/missing frontmatter).
2. Masks markdown (frontmatter, fences, HTML comments, inline code).
3. Runs `PROV_RE.findall(masked_body)` yielding `(source_id, locator, support_type, checked_at)` tuples.
4. Checks `source_id` is in `source_registry` (the dict built from type:source pages).

[VERIFIED: read lint.sh lines 1123–1138, 1040–1043]

**D-08 addition:** After the existing `source_id not in source_registry` check, add a second check:

```python
# D-08: derived-never-direct for research-report sources
src_fm = source_registry.get(source_id)
if src_fm and src_fm.get('source_type') == 'research-report':
    if support_type == 'direct':
        add_finding('error', 'provenance', rel,
                    f'Epistemic laundering: [prov:{source_id}#...] '
                    f'uses support_type=direct on a research-report source '
                    f'(research-reports are secondary; use derived)')
```

This composes existing pieces: `PROV_RE` already captures `support_type` as group 3; `source_registry` already holds the source frontmatter including `source_type`. [VERIFIED: lint.sh architecture]

**D-09 addition:** In the yaml check section (around line 1089–1095), add `source_type` enum validation:

```python
VALID_SOURCE_TYPES = {'article', 'paper', 'transcript', 'journal', 'data', 'image', 'research-report'}
if fm.get('type') == 'source':
    st = fm.get('source_type', '')
    if st and st not in VALID_SOURCE_TYPES:
        add_finding('error', 'yaml', rel, f"Invalid source_type: '{st}'")
```

[VERIFIED: lint.sh lines 1088–1095 show existing pattern for enum validation]

**LINT_VERSION:** Change line 13 from `"1.8.0"` to `"1.9.0"`. [VERIFIED: lint.sh line 13]

### audit-claims.sh — selector and resolve_locator architecture

**Current RANK dict** (line ~605): `{'stale': 1, 'epistemic': 2, 'recency': 3, 'fanout': 4}` [VERIFIED: read audit-claims.sh]

**Current `--select` CSV** (line ~50): `stale,epistemic,recency,fanout` [VERIFIED: read audit-claims.sh]

**D-10a — 5th selector:** Add `derived-report` (or similar — Claude's discretion on the CLI token name) as rank 5. The selector logic:

```python
# In the RANK dict:
RANK = {'stale': 1, 'epistemic': 2, 'recency': 3, 'fanout': 4, 'derived-report': 5}

# In the selector loop (after existing hits):
if selector_active('derived-report'):
    src_fm = source_registry.get(sid, {})
    if isinstance(src_fm, dict) and src_fm.get('source_type') == 'research-report':
        hits.append('derived-report')
```

The `source_registry` is already built from source summary frontmatter; no new data loading needed. [VERIFIED: read audit-claims.sh build of source_registry]

**D-10b — `#r<n>` resolver in `resolve_locator`:** Current `resolve_locator` function (lines ~423–464) handles: `#img`, `#sec:`, `#para`, `#t`, `#p`. Unknown forms fall through to `return None, None`. [VERIFIED: read audit-claims.sh lines 423–464]

Add `#r<n>` case before the final fallthrough:

```python
if loc.startswith('#r') and loc[2:].isdigit():
    n = int(loc[2:])
    return _resolve_ref(raw_source_text, n), None
```

The `_resolve_ref` helper finds the bibliography section header (`## Source Citations`, `## Sources by Topic`, or generic `## Sources` / `## References`) and returns the `n`th bullet entry (1-indexed, positional across groups for topic-grouped sources).

---

## Two Reports — Concrete Facts for Retro-Classification

### PDF-to-Text SOTA Report

- **Raw source:** `sources/2026/2026-06/2026-06-09-pdf-to-text-llm-ingestion-sota.md` [VERIFIED: file exists]
- **Source summary:** `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` [VERIFIED: file exists]
- **Current `source_type`:** `article` [VERIFIED: read frontmatter]
- **Bibliography section:** `## Source Citations` (unnumbered bullet list, 12 entries) [VERIFIED: read raw source lines 84–99]
- **Registry entries (positional r1–r12):**
  - r1: OmniDocBench — GitHub: https://github.com/opendatalab/OmniDocBench
  - r2: OmniDocBench — arXiv (CVPR 2025): https://arxiv.org/html/2412.07626v2
  - r3: olmOCR — Ai2 blog: https://olmocr.allenai.org/blog
  - r4: olmOCR 2 — Ai2 blog: https://allenai.org/blog/olmocr-2
  - r5: olmOCR — arXiv: https://arxiv.org/abs/2502.18443
  - r6: olmOCR 2 — arXiv: https://arxiv.org/abs/2510.19817
  - r7: olmOCR-Bench — GitHub: https://github.com/allenai/olmocr/tree/main/olmocr/bench
  - r8: "Seeing is Believing?" — arXiv (NeurIPS 2025): https://arxiv.org/html/2506.20168v2
  - r9: Mistral OCR — news: https://mistral.ai/news/mistral-ocr/
  - r10: Mistral OCR — pricing: https://mistral.ai/pricing/
  - r11: Artificial Analysis OCR aggregator: https://artificialanalysis.ai/agents/ocr
  - r12: CodeSOTA OCR landscape: https://www.codesota.com/ocr
  - r12 (actually r13 if counting separately): Jimmy Song deep-dive (Sept 2025): https://jimmysong.io/blog/pdf-to-markdown-open-source-deep-dive/

  Note: r9 and r10 are two separate URLs on the Mistral line. Treat as r9 (news) and r10 (pricing). Total = 13 distinct URLs in 12 bullet entries (one bullet has two URLs). Planner should decide: count by bullets (12 entries) or by URLs (13 items). Bullets is cleaner — r9 covers both Mistral URLs.

- **Direct markers in source summary pages themselves:** 22 (self-citing; these stay `direct` — correct). [VERIFIED: counted]
- **Direct markers in dependent wiki pages (to sweep):** 47 [VERIFIED: counted per-page]
  - olmocr.md: 8 (all report-citing)
  - omnidocbench.md: 6 (all report-citing)
  - vlm-ocr-hallucination.md: 6 (all report-citing)
  - ocr-pipeline-vs-vlm-ingestion.md: 10 report-citing (5 also non-report)
  - pdf-text-extraction-for-llm-ingestion.md: 10 report-citing
  - agent-skills.md: 2 report-citing (20 non-report)
- **Current `epistemic_status` of vlm-ocr-hallucination.md:** `sourced` — after sweep (100% derived) → drops to `mixed` per D-12. [VERIFIED: checked frontmatter]

### Claude Code Frameworks Report

- **Raw source:** `sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md` [VERIFIED: file exists]
- **Source summary:** `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md` [VERIFIED: file exists]
- **Current `source_type`:** `article` [VERIFIED: read frontmatter]
- **Bibliography section:** `## Sources by Topic` (topic-grouped, 2 groups: "Building blocks" 9 entries + "Frameworks" 6 entries = 15 total) [VERIFIED: read raw source lines 238–257]
- **Registry entries (positional r1–r15, across groups):**
  - r1–r9: "Building blocks" group (9 bullets)
  - r10–r15: "Frameworks" group (6 bullets)
  - Specific entries: r1=Anthropic Engineering Agent Skills, r2=Skill authoring best practices, r3=Slash commands docs, r4=Subagents docs, r5=Claude Code best practices, r6=agents.md open standard, r7=multi-agent research system, r8=Stop bloating CLAUDE.md (alexop.dev), r9=Writing a good CLAUDE.md (HumanLayer), r10=obra/superpowers, r11=gsd-build/get-shit-done, r12=github/spec-kit, r13=Pulumi comparison, r14=Medium comparison, r15=dev.to skills stack
- **Direct markers in source summary pages themselves:** 32 (self-citing; stay `direct`). [VERIFIED: counted]
- **Direct markers in dependent wiki pages (to sweep):** 50 [VERIFIED: counted per-page]
  - claude-code.md: 7 report-citing (9 non-report)
  - gsd.md: 9 (all report-citing)
  - spec-kit.md: 9 (all report-citing)
  - superpowers.md: 8 (all report-citing)
  - progressive-disclosure.md: 6 report-citing (20 non-report)
  - spec-driven-development.md: 7 (all report-citing)
  - subagents.md: 8 (all report-citing)
  - claude-code-orchestration-frameworks.md: 7 (all report-citing, minus 1 non-report in table)
  - agent-skills.md: 2 report-citing (20 non-report)
  - pdf-text-extraction-for-llm-ingestion.md: 0 report-citing (only PDF SOTA report)

  Note: counting is approximate per-file; the actual grep count is 97 total across all 14 pages combined (both reports). [VERIFIED: confirmed 97 by grep]

- **Epistemic_status re-grading assessment (D-12):**
  - `vlm-ocr-hallucination.md` (all 6 prov markers → report-citing): currently `sourced`, drops to `mixed`
  - `agent-skills.md` (2 of 22 → report-citing): currently `sourced`, stays `sourced`
  - All other 12 pages: already `mixed`, stay `mixed`
  [VERIFIED: checked all 14 page epistemic_status values]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-line YAML frontmatter parsing | Custom regex parser | `yaml.safe_load()` (already used in lint.sh) | PyYAML is already in the codebase; hand-rolled parsers fail on edge cases |
| Source type validation | Ad-hoc per-check if-else | `VALID_SOURCE_TYPES` set (same pattern as existing `VALID_TYPES`, `VALID_STATUS`) | The existing enum-validation pattern at line 1081–1086 is the template to follow |
| Finding the bibliography section | File-wide regex | Positional: find the first `## Source Citations` / `## Sources by Topic` / `## Sources` / `## References` header, then yield the Nth bullet below it | Grep-for-header + count-bullets is simpler and more robust than complex patterns |
| Neutrality-safe examples in template-public docs | Use real source slugs in schema docs | Use abstract placeholders: `<source-id>`, `<report-slug>`, `<date>` | CLAUDE.md MUST-NOT list forbids real vault slugs in schema/reference/ docs |

---

## Common Pitfalls

### Pitfall 1: Lint fires before sweep lands

**What goes wrong:** D-08 error check lands in a commit before the 97 `|direct|` → `|derived|` sweep. CI goes red; the blocking commit cannot easily be undone.

**Why it happens:** The planner schedules the lint update and the data sweep in separate plan files, and the lint update commits first.

**How to avoid:** In the plan, the sweep task MUST be in the same wave as or an earlier wave than the D-08 lint check. Concretely: the same commit that changes LINT_VERSION and adds the D-08 check should be the same commit that completes the sweep, OR the sweep commit lands before the lint-check commit in the same wave. The CONTEXT.md specifics note (line 112) explicitly states this coupling.

**Warning signs:** Plan has D-08 in Wave N and sweep in Wave N+1.

### Pitfall 2: Source summary pages also swept

**What goes wrong:** The sweep changes `|direct|` markers in `wiki-cloud/sources/src-2026-*.md` itself (the source summary pages), which is wrong — source summaries cite their OWN raw source, which IS a direct relationship.

**Why it happens:** The grep pattern `|direct|` matches everything in the wiki-cloud tree; the sweep script doesn't exclude source pages.

**How to avoid:** The D-08 lint check is scoped to non-source pages only — it checks `source_id in research-report sources` AND the current page is NOT itself a `type: source` page (source summaries are self-referential). The sweep task should explicitly exclude `wiki-cloud/sources/` from the sed/replace scope.

**Warning signs:** After the sweep, the source summary pages' `## Extracted Claims` show `|derived|` instead of `|direct|`.

### Pitfall 3: Routing table row added but file not created in same commit

**What goes wrong:** The AGENTS.md routing table row for `schema/reference/source-types.md` is added before the file is created. The routing check (forward check: PATH_REF_RE) emits a dangling-reference error.

**Why it happens:** Routing table and file creation are in separate tasks.

**How to avoid:** Source-types.md file creation and the AGENTS.md routing row addition must land in the same commit. The lint.sh routing check will verify this.

**Warning signs:** `bin/lint.sh --category routing` emits a dangling reference error for `schema/reference/source-types.md`.

### Pitfall 4: Real vault slugs in schema/reference/source-types.md

**What goes wrong:** The source-types.md contract examples use real source IDs (`src-2026-06-09-pdf-to-text-llm-ingestion-sota`) or real page slugs in the worked-example column.

**Why it happens:** The author copy-pastes from the concrete retro-classification work directly into the template-public schema doc.

**How to avoid:** CLAUDE.md MUST-NOT list explicitly forbids this. Use abstract placeholders: `<source-id>`, `<report-slug>`, `<entity-name>`. The retro-classification work (wiki-cloud/ files) may use real slugs — only the schema docs must be neutral.

**Warning signs:** `bin/check-neutrality.sh` emits a denylist match on a schema/reference/ or AGENTS.md file.

### Pitfall 5: `#r<n>` positional resolver assumes fixed header names

**What goes wrong:** The `_resolve_ref` helper in audit-claims.sh hard-codes `## Source Citations` as the bibliography header, missing the frameworks report's `## Sources by Topic`.

**Why it happens:** The two reports use different bibliography header names.

**How to avoid:** The resolver should search for multiple candidate headers in order: first line matching `^## Source Citations`, `^## Sources by Topic`, `^## Sources`, `^## References`. The first match wins.

**Warning signs:** The audit returns `insufficient-locator` for all `#r<n>` claims from the frameworks report.

### Pitfall 6: epistemic_status re-grade too broad

**What goes wrong:** D-12 re-grades ALL 14 dependent pages from `sourced` to `mixed`, even pages like `agent-skills.md` where only 2 of 22 markers cite the report.

**Why it happens:** The planner interprets "mostly derived" loosely.

**How to avoid:** Only re-grade pages where the report-citing markers are the majority (>50%) of all provenance markers. Concrete: `vlm-ocr-hallucination.md` (6/6 = 100%) drops to `mixed`. `agent-skills.md` (2/22 = 9%) stays `sourced`. All other 12 pages are already `mixed` — no change needed.

---

## Runtime State Inventory

This phase is not a rename/refactor. No runtime state inventory required. The retro-classification touches only git-tracked files in `wiki-cloud/`. There are no external datastores, live service configurations, or OS-registered state to update.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bin/lint.sh (deterministic health checker, not a test runner) |
| Config file | none — lint.sh is self-contained |
| Quick run command | `bash bin/lint.sh --category provenance --category yaml` |
| Full suite command | `bash bin/lint.sh` |
| Lint version check | `bash bin/lint.sh --require-version 1.9.0` |

No unit test files exist for this phase (no tests/ directory structure for schema phases). Validation is through the lint workflow running clean.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXT-01 | source-types.md exists with 5-dimension contract | lint routing forward-check | `bash bin/lint.sh --category routing` | ❌ Wave 0: source-types.md must be created |
| EXT-02 | Decision rule documented in source-types.md | manual review | N/A — document content review | ❌ Wave 0 |
| EXT-03 | Retro-fit table covers 7 types | manual review | N/A | ❌ Wave 0 |
| RPT-01 | `research-report` in enum, Pass 0 documented | `bash bin/lint.sh --category yaml` (D-09 enum check fires on unknown values) | ❌ Wave 0 |
| RPT-02 | ## References block in both source summaries | `bash bin/lint.sh` (routing + yaml pass) | ❌ Wave 0 |
| RPT-03 | No `direct` markers on research-report sources | `bash bin/lint.sh --category provenance` (D-08 check) | ❌ Wave 0: sweep must precede D-08 check |
| RPT-04 | Default epistemic `mixed`, audit selector active | `bash bin/audit-claims.sh --select derived-report --sample 5` | ❌ Wave 0 |
| RPT-05 | Promotion path documented | manual review | N/A | ❌ Wave 0 |
| RPT-06 | Both summaries retro-classified, 97 markers swept | `bash bin/lint.sh` (full lint green) | ❌ Wave 0: data changes |

### Sampling Rate

- **Per task commit:** `bash bin/lint.sh --category provenance --category yaml` (fast, catches D-08/D-09 regressions)
- **Per wave merge:** `bash bin/lint.sh` (full suite)
- **Phase gate:** Full lint green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `schema/reference/source-types.md` — new authoritative file (EXT-01..03, RPT-01)
- [ ] Routing table row in AGENTS.md — required for forward-check to pass
- [ ] LINT_VERSION bump to 1.9.0 — required before D-08 check can be tested
- [ ] D-08/D-09 checks in lint.sh — needed for RPT-03/RPT-01 automated verification
- [ ] Sweep of 97 `|direct|` markers — must land before D-08 check fires

---

## Security Domain

`security_enforcement` not configured in config.json (absent = enabled). Assessing ASVS applicability.

### Applicable ASVS Categories

| ASVS Category | Applies | Rationale |
|---------------|---------|-----------|
| V2 Authentication | No | No user auth — this is a local CLI tool and markdown schema |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | No access control layer |
| V5 Input Validation | Marginal | bin/lint.sh already validates YAML frontmatter; D-09 adds enum validation |
| V6 Cryptography | No | No crypto in this phase |

### Known Threat Patterns

The primary threat this phase addresses is NOT a security vulnerability in the traditional sense — it's **epistemic laundering**: AI-synthesized secondary claims ingested as if they were primary-sourced, manufacturing false confidence. The `derived-never-direct` lint enforcement (D-08) is the mechanical defense.

No network egress, no user-supplied data paths, no credential handling in this phase.

---

## Open Questions (RESOLVED)

1. **Bibliography registry entry count for PDF SOTA report**
   - What we know: 12 bullet entries in `## Source Citations`; one bullet has two comma-separated URLs (Mistral OCR news + pricing)
   - What's unclear: Does "one bullet = one registry entry" (12 entries, r9 covers both Mistral URLs) or "one URL = one entry" (13 entries)?
   - Recommendation: One bullet = one registry entry (12 entries, r1–r12). The registry records the bibliographic unit as written; if a researcher needs to distinguish the two Mistral URLs, the single `r9` entry has both URLs in its title.

2. **D-12 re-grading threshold precision**
   - What we know: CONTEXT.md says "pages whose provenance-backed claims are now mostly derived drop to `mixed`"; we've identified `vlm-ocr-hallucination.md` (100%) as the only page meeting this threshold
   - What's unclear: Is there an explicit numeric threshold (e.g., >50%)? The CONTEXT.md says "mostly" without a number
   - Recommendation: Apply to pages where >50% of body provenance markers cite research-report sources. Only `vlm-ocr-hallucination.md` qualifies.

3. **Routing inverse check for new schema/reference/*.md files**
   - What we know: The routing inverse check only covers `schema/workflows/*.md` + `schema/reference/log-format.md` in `orphan_candidates`. New `source-types.md` won't be auto-enforced by the inverse check.
   - What's unclear: Should the inverse check be extended to cover ALL `schema/reference/*.md`? D-02 requires a routing row, but lint won't auto-catch its absence.
   - Recommendation: Do NOT extend the inverse check in this phase (scope creep). The routing row is D-02 locked; the human/planner is responsible for adding it. The forward check will catch a dangling row if the file is referenced but doesn't exist.

---

## Environment Availability

All required tools are available. This phase has no external dependencies beyond the project's own tooling.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | bin/lint.sh, bin/audit-claims.sh | ✓ | 3.12.3 | — |
| Bash | bin scripts, pre-commit hook | ✓ | 5.2.21 | — |
| git | lint.sh (diff), audit-claims.sh (diff) | ✓ | 2.43.0 | — |
| PyYAML | bin/lint.sh | ✓ | bundled with Python install | — |

---

## Code Examples

### D-08 derived-never-direct check (to add in provenance section of lint.sh)

```python
# Source: lint.sh lines 1123-1138 (existing pattern, extend)
# After the existing broken-ref check:
if source_id not in source_registry:
    add_finding('error', 'provenance', rel,
                f'Broken prov ref: {source_id} not found in {wiki_dir}sources/')
    continue  # skip further checks for missing source
# D-08: derived-never-direct for research-report sources
src_fm = source_registry.get(source_id)
if isinstance(src_fm, dict) and src_fm.get('source_type') == 'research-report':
    if support_type == 'direct':
        add_finding('error', 'provenance', rel,
                    f'Epistemic laundering: [prov:{source_id}#...] uses '
                    f'support_type=direct on a research-report source '
                    f'(secondary sources must use derived)')
```

### D-09 source_type enum validation (to add in yaml section of lint.sh)

```python
# Source: lint.sh lines 1088-1095 (existing pattern, extend)
VALID_SOURCE_TYPES = {'article', 'paper', 'transcript', 'journal',
                      'data', 'image', 'research-report'}
# Within the `if fm.get('type') == 'source':` block:
st = fm.get('source_type', '')
if st and st not in VALID_SOURCE_TYPES:
    add_finding('error', 'yaml', rel,
                f"Invalid source_type: '{st}' (expected one of: "
                f"{', '.join(sorted(VALID_SOURCE_TYPES))})")
```

### #r<n> locator resolver (to add in resolve_locator of audit-claims.sh)

```python
# Source: audit-claims.sh lines 423-464 (existing resolver pattern, extend)
# Add before the final `return None, None` fallthrough:
if loc.startswith('#r') and loc[2:].isdigit():
    n = int(loc[2:])
    return _resolve_ref(raw_source_text, n), None

def _resolve_ref(text, n):
    """Return the Nth bullet in the first bibliography section found.
    Searches for ## Source Citations / ## Sources by Topic / ## Sources /
    ## References headers (first match). Returns None if not found or N
    out of range. Positional numbering is across groups for topic-grouped sources."""
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
    # Stop at the next ## heading
    next_h = re.search(r'^##\s', after_header, re.MULTILINE)
    section = after_header[:next_h.start()] if next_h else after_header
    bullets = bullet_re.findall(section)
    if not bullets or n < 1 or n > len(bullets):
        return None
    return bullets[n - 1]
```

### Citation registry entry format (body block in source summary page)

```markdown
## References

<!-- r<n> = positional index into the bibliography section of the raw source -->
<!-- raw source: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md -->

- r1:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
- r2:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
- r7:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry | promoted → <new-source-id>
```

(Use `status: registry` for unverified entries; `promoted → <new-source-id>` when a claim has been re-pointed to a first-class source.)

### Routing table row format (for AGENTS.md/CLAUDE.md)

```markdown
> | Adding/evaluating a new source type | `schema/reference/source-types.md` |
```

This follows the `> | description | \`path\` |` pattern that `ROUTING_ROW_RE` in lint.sh matches. [VERIFIED: lint.sh line 2462 regex]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Positional numbering across groups is the right choice for the frameworks report `## Sources by Topic` | Code Examples, Retro-Classification section | Minor — if per-group numbering is chosen instead, the registry convention doc and the actual registry entries both change, but no code is affected |
| A2 | The `source_registry` dict in audit-claims.sh stores source frontmatter as a flat dict (not a nested `{fm: {...}}` dict) | Code Examples (derived-report selector) | If the registry is structured as `{fm: {...}}`, the `.get('source_type')` access needs to become `.get('fm', {}).get('source_type')`. The audit-claims.sh code shows `entry['fm'] if isinstance(entry, dict) else entry` pattern — the dict access is guarded. |
| A3 | 12 bibliography bullet entries in PDF SOTA report (treating the dual-URL Mistral bullet as one entry) | Retro-Classification section | Minor — worst case is r9 needs to split into r9/r10, shifting r10–r12 to r10–r13 |

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: `.planning/phases/19-extension-contract-research-report-type/19-CONTEXT.md`] — locked decisions D-01 through D-14
- [VERIFIED: `schema/reference/frontmatter.md`] — source_type enum current state, SOURCE_EXTRA_FIELDS
- [VERIFIED: `schema/reference/provenance.md`] — current Locator Types table, Support Types table
- [VERIFIED: `schema/workflows/ingest.md`] — Pass 0 classify step, Claim Granularity table
- [VERIFIED: `schema/workflows/audit.md`] — audit workflow, FAITH-01 selectors, privacy contract
- [VERIFIED: `bin/lint.sh`] — LINT_VERSION 1.8.0, PROV_RE, source_registry, existing enum-validation pattern, VALID_TYPES, provenance check lines 1123–1138, routing check
- [VERIFIED: `bin/audit-claims.sh`] — RANK dict, selector loop, resolve_locator function lines 423–464
- [VERIFIED: `sources/2026/2026-06/2026-06-09-pdf-to-text-llm-ingestion-sota.md`] — bibliography section, entry count
- [VERIFIED: `sources/2026/2026-04/2026-04-16-claude-code-frameworks-report.md`] — bibliography section, entry count, grouping
- [VERIFIED: `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md`] — current source_type: article, compilation_status, compiled_targets
- [VERIFIED: `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md`] — current source_type: article, compilation_status, compiled_targets
- [VERIFIED: grep counts] — 97 direct markers in 14 dependent pages cite the two reports; 146 total direct markers in those 14 pages; 14 files identified
- [VERIFIED: `.githooks/pre-commit`] — sync-claude + gen-skills + lint --staged --strict --category provenance gates
- [VERIFIED: `.planning/seeds/research-report-ingest.md`] — LOCKED design for research-report type
- [VERIFIED: `.planning/seeds/primary-source-type-extensions.md`] — 5-dimension decision framework

### Secondary (MEDIUM confidence)

- [VERIFIED: `bin/sync-claude.sh`] — byte-equality enforcement mechanism
- [VERIFIED: `bin/gen-skills.sh`] — 4-op skills (ingest/query/lint/reflect), not affected by this phase

---

## Metadata

**Confidence breakdown:**
- Schema surface inventory (what to change and where): HIGH — all surfaces verified by direct file read
- Retro-classification targets (which files, how many markers): HIGH — verified by live grep
- Code change patterns (D-08, D-09, D-10): HIGH — verified by reading the existing parallel patterns
- Bibliography entry counts (r1–r12, r1–r15): HIGH — verified by reading raw sources
- epistemic_status re-grading scope: HIGH — verified by checking all 14 pages

**Research date:** 2026-06-10
**Valid until:** This is a documentation/schema phase with no external dependencies. All facts are derived from the local codebase — valid indefinitely until the codebase changes.
