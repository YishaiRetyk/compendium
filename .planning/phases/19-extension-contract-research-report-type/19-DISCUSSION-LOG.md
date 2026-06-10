# Phase 19: Extension Contract + Research-Report Type - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 19-extension-contract-research-report-type
**Areas discussed:** Contract placement & routing, Citation registry shape, Enforcement depth, Retro-classification depth

---

## Contract placement & routing

| Option | Description | Selected |
|--------|-------------|----------|
| source-types.md owns it all | New `schema/reference/source-types.md` is the authoritative home for source typing (contract + decision rule + retro-fit table + enum semantics ownership); frontmatter.md/ingest.md point to it | ✓ |
| Contract-only file | Contract + retro-fit table only; enum and per-type conventions stay split across frontmatter.md and ingest.md | |

**User's choice:** source-types.md owns it all (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Add routing row | One row in the AGENTS.md/CLAUDE.md routing table; authoritative refs always get rows (Phase 18 precedent applies to pointers, not authoritative content) | ✓ |
| No core line | Reachable only via cross-links; protects core line count but breaks the every-authoritative-ref-has-a-row invariant | |

**User's choice:** Add routing row (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| All 6 enum types + reconcile | Retro-fit all enum values + research-report; align the ingest claim-granularity table vocabulary to enum types via the sub-case concept | ✓ |
| All 6 enum types, no reconcile | Retro-fit all enum values but leave the granularity-table vocabulary untouched | |
| Only types in use | Rows for article + transcript + research-report; unused enum values marked "declared, no instances yet" | |

**User's choice:** All 6 enum types + reconcile (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Sub-case registry in contract | source-types.md gets an "Evaluated candidates" section; Phases 20–21 append rows | ✓ |
| Sub-cases live with parent type | Contract defines only the rule; sub-cases documented in parent-type docs | |

**User's choice:** Sub-case registry in contract (recommended)

---

## Citation registry shape

| Option | Description | Selected |
|--------|-------------|----------|
| New #r\<n\> locator row | Add Reference row to the Locator Types table; explicit, grep-able; audit degrades gracefully until taught | ✓ |
| Reuse #sec: grammar | `#sec:references` — zero grammar change but unbounded (loses per-citation addressability) | |
| Dual: section anchor + ref id | `#sec:references/r3` sub-anchor — more complex, no precedent | |

**User's choice:** New #r\<n\> locator row (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Body ## References block | Structured list in summary page body keyed `r<n>::` (URL, title, access date, status); no new frontmatter | ✓ |
| Frontmatter cited_urls | Type-specific YAML list; machine-parseable but 30-entry blobs | |
| Both (body + frontmatter) | Two copies = drift risk | |

**User's choice:** Body ## References block (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Re-point the earning claim | Promotion upgrades the triggering claim derived→direct via UPDATE op; registry entry marked promoted | ✓ |
| Registry-only promotion | Claims never rewritten; readers follow report→registry→source chain | |
| You decide | Planner picks based on structured-ops support | |

**User's choice:** Re-point the earning claim (recommended)

---

## Enforcement depth

| Option | Description | Selected |
|--------|-------------|----------|
| Lint check, error severity | New provenance-category check: research-report source + `direct` = error; LINT_VERSION 1.9.0 | ✓ |
| Warning severity | Same check, non-blocking | |
| Convention only | Document the rule; rely on audit | |

**User's choice:** Yes — lint check, error severity (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Both: selector + #r resolution | 5th audit priority selector + resolve_locator slices numbered bibliography entries | ✓ |
| Selector only | Prioritized claims audit as insufficient-locator | |
| Docs only | Convention, no script change | |

**User's choice:** Both: selector + #r resolution (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Validate enum values | Lint errors on unknown source_type values; valid set defined once matching source-types.md | ✓ |
| Presence only | Keep current behavior; typos bypass the laundering check | |

**User's choice:** Yes — validate values (recommended)

---

## Retro-classification depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full sweep: direct → derived | Rewrite all 168 markers across 14 pages; locators unchanged | ✓ |
| Grandfather clause | Lint exempts pre-Phase-19 claims; keeps the laundering falsehood forever | |
| Sweep + locator upgrade | Also re-point claims to #r\<n\> — closer to a re-ingest | |

**User's choice:** Full sweep: direct → derived (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Re-grade in the sweep | Dependent pages drop to epistemic_status: mixed in the same pass | ✓ |
| Claims only | Page headers left contradicting their own claim markers | |

**User's choice:** Yes — re-grade in the sweep (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Full backfill, positional numbering | r\<n\> = nth bibliography entry top-to-bottom; complete registry mapping in summary pages | ✓ |
| Structural minimum | Registry with only load-bearing entries; rest unregistered | |

**User's choice:** Full backfill, positional numbering (recommended)

---

## Claude's Discretion

- Exact section structure/wording of source-types.md (neutral placeholders in template-public surfaces)
- Reconciled granularity-table vocabulary mapping
- Positional numbering across vs per topic-group for the frameworks report
- Epistemic default wording (`mixed` vs `tentative` and when each applies)
- Audit selector name / `--select` token
- Scripted vs hand-applied sweep
- Decision-record authoring for the schema change

## Deferred Ideas

- 999.5 External Source Drift detection (registries are its trigger; out of milestone)
- `repository` source type (backlog; pairs with 999.5)
- Web-assist inside query workflow (seed flags as likely never in scope)

## Reviewed Todos (not folded)

- `phase-14-lint-mask-fence-edge-cases` — unrelated behavioral lint change; stays in backlog (also reviewed-not-folded in Phase 17)
