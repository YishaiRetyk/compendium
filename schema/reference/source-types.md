# Source Types

> Agent-authoritative reference for `source_type` values, the 5-dimension extension contract, and the primary-vs-secondary axis.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

Use this file when classifying a new source (Pass 0), evaluating whether a source-type candidate warrants a new enum value, or authoring claims with the appropriate support type and epistemic default.

## 1. The 5 Dimensions

Every source type is characterized along five dimensions. A new `source_type` enum value is justified only when the candidate changes at least one dimension relative to all existing types. If all five dimensions match an existing type, the candidate is a **sub-case** (a convention note on an existing type) — NOT a new enum value.

| Dimension | Description | Why It Matters |
|-----------|-------------|----------------|
| **Acquisition** | How the source is obtained (downloaded, recorded, copy-paste, AI-generated, scraped) | Drives the acquisition pipeline and tooling notes |
| **Locator** | What locator syntax addresses claims (`#p`, `#sec:`, `#t`, `#r`, none) | Must be grep-able and resolvable by `bin/audit-claims.sh` |
| **Extraction Granularity** | Atomic claims vs paragraph clusters vs bulk-copy; whether `support_type: derived` is mandatory | Drives per-source extraction depth and provenance rules |
| **Drift** | Whether the source can change post-ingest: `static` (never changes), `live` (can change), `published-immutable` (fixed after publication) | Governs staleness detection and `content_hash` policy |
| **Epistemic Default** | The default `epistemic_status` for pages whose claims are predominantly this source type | Signals downstream confidence to readers and the audit |

## 2. Primary vs Secondary Axis

Sources are classified as **primary** or **secondary** based on whether wiki claims trace directly to the original material.

- **Primary sources** use `support_type: direct` — the wiki claim traces to the source material itself (the article, transcript, paper, or data file the human placed in `sources/`).
- **Secondary sources** use `support_type: derived` (MANDATORY — never `direct`) — the wiki claim traces to a synthesis or aggregation of primary material; the original primary sources are one step removed. The secondary-ness MUST be recorded, not erased.

**Decision rule:** A new `source_type` is justified only if it changes at least one of the 5 dimensions relative to all existing types. If all 5 dimensions match an existing type, the candidate is documented as a sub-case — a convention note on an existing type — NOT a new enum value.

## 3. Retro-fit Table (All 7 Types)

All current `source_type` enum values mapped across the 5 dimensions:

| Type | Axis | Acquisition | Locator | Extraction Granularity | Drift | Epistemic Default |
|------|------|-------------|---------|----------------------|-------|-------------------|
| `article` | primary | downloaded or copy-paste | `#sec:`, `#para` | paragraph clusters or atomic | static | sourced |
| `paper` | primary | downloaded or copy-paste | `#p`, `#sec:`, `#para` | atomic claims | static | sourced |
| `transcript` | primary | recorded or downloaded | `#t<start>-<end>` | paragraph/utterance clusters | static after recording | sourced |
| `journal` | primary | written by author | `#sec:`, `#para` | paragraph clusters | static after writing | mixed |
| `data` | primary | downloaded | `#p` or none | bulk-copy or cited stats | static | sourced |
| `image` | primary | downloaded or captured | `#img<n>` | described content | static | sourced |
| `research-report` | secondary | AI-generated or third-party aggregated | `#r<n>` for bibliography; `#sec:`, `#para` for body | atomic claims, `support_type: derived` only | static after generation | mixed |

## 4. Evaluated Candidates Sub-case Registry

When a new source-type candidate is evaluated, a row is appended here with the verdict. Phases 20 and 21 finalize the pdf and video rows respectively.

| Candidate | Verdict | Dimensions That Change | Convention Doc | Notes |
|-----------|---------|----------------------|----------------|-------|
| `pdf` | sub-case (format-orthogonal; any parent type) | Acquisition (always); Epistemic Default (degraded input only) | `schema/reference/pdf-ingestion.md` | Acquisition-path sub-case applicable to any document type; content classifies normally at Pass 0 (article/paper/data/...) and the PDF convention layers on. `#p` page locators + page markers already exist; claims stay `support_type: direct`; degraded scans get `tentative` + spot-verification (D-08). |
| `video` | sub-case of `transcript` | Acquisition (always); Epistemic Default (degraded audio only) | `schema/reference/video-ingestion.md` | Timestamp locators (`#t`) + the `[H:MM:SS]` line grammar already exist; download + STT replaces recorded acquisition. Claims stay `support_type: direct`; degraded audio gets `tentative` + N=3 spot-verification (D-09). |
| `repository` | pending | — | — | Pairs with 999.5 drift machinery (commit-SHA staleness); deferred |

Rows marked *provisional* are seeded pre-evaluations; the owning phase finalizes verdict and dimension assessment by walking the candidate through the contract.

## 5. research-report — Worked Secondary Instance

`research-report` is the contract's worked secondary instance. It demonstrates the full 5-dimension evaluation and implementation convention.

**Classification.** Pass 0 assigns `source_type: research-report` when the source is:
- An AI-synthesized report (Claude / ChatGPT / Perplexity / similar tool), OR
- A third-party aggregated research artifact with its own bibliography (a report that synthesizes primary sources).

The key distinguishing feature: the source has its own bibliography / reference list, and its claims are the synthesis of that bibliography, not direct observation.

**Provenance.** ALL claims extracted from a research-report source MUST use `support_type: derived`. Any other support type (`direct`, `inferred`, `tentative`, or omitted) on a research-report citation is an epistemic-laundering error (lint enforces this as an error). Locator conventions:
- `#r<n>` for bibliography-specific claims (the nth bullet in the bibliography section, positionally numbered top-to-bottom).
- `#sec:` or `#para` for body claims.

**Exception — source summary self-citation.** The report's OWN source summary page (`type: source` with the same page `id` as the cited source) self-cites with `support_type: direct`: there `direct` describes the claim-to-cited-source relation — the claim IS directly stated in the report. The derived mandate and the lint gate apply to every OTHER page citing the report, including other source summary pages (two reports citing each other is the false-consensus channel, not self-citation).

**Citation registry.** The source summary page's `## References` block captures the bibliography as an addressable registry. Each entry uses the `r<n>::` Dataview inline field key:

```markdown
## References

<!-- r<n> = positional index into the bibliography section of the raw source -->
<!-- raw source: sources/<YYYY>/<YYYY-MM>/<YYYY-MM-DD-slug>/source.md -->

- r1:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
- r2:: [<Title>](<URL>) — accessed <YYYY-MM-DD> — status: registry
```

When a citation is promoted to a first-class source: append `| promoted → <new-source-id>` to the status value.

**Graceful degradation for `#r<n>`.** When a research-report source has no bibliography section, `#r<n>` resolves to `insufficient-locator` (NOT an error), matching the `#p` page-marker precedent. Authors on reports without bibliographies should prefer `#sec:`/`#para` locators instead.

**Epistemic default.** `mixed` for body conclusions. `tentative` for claims derived solely from bibliography entries without further verification by the human.

**Promotion path (Model C).** When a citation-registry entry earns a claim that the human wants to verify, the human acquires the primary source and ingests it normally. The earning claim is then re-pointed:
- Before: `[prov:<report-id>#r<n>|derived]`
- After: `[prov:<new-source-id>#<locator>|direct]` (an UPDATE op)
- Registry entry: `status: registry` → `status: promoted → <new-source-id>`

**Audit priority.** Research-report claims are tier-5 audit targets (`--select derived-report`). They carry a lower epistemic default and the faithfulness audit samples them first within this tier.

**Anti-laundering note.** Two reports citing each other can manufacture false consensus. The `derived` support type, lower epistemic default, and audit priority are the mechanical defenses. Never flatten a research-report's synthesis into `direct` claims — that erases the secondary-source signal and is detectable by lint as an error.

## 6. Ingest Checklist for research-report

1. Save the raw report with bibliography intact to `sources/YYYY/YYYY-MM/YYYY-MM-DD-<slug>/source.md` (raw source is immutable — never strip the bibliography).
2. Assign `source_type: research-report` in the source summary page's frontmatter.
3. Add `## References` block to the source summary with `r<n>::` keyed entries for each bibliography entry.
4. Extract claims with `support_type: derived` and `#r<n>` or `#sec:`/`#para` locators (exception: the source summary page's own claims self-cite the report with `direct` — see the self-citation exception under Provenance above).
5. Set `epistemic_status: mixed` on the source summary and dependent pages by default.

## See Also

- `AGENTS.md` — routing-table stub (entry point for "Adding/evaluating a new source type").
- `schema/reference/frontmatter.md` — `source_type` enum (the valid values this file defines).
- `schema/reference/provenance.md` — `#r<n>` locator syntax, support_type values.
- `schema/workflows/ingest.md` — Pass 0 classification step, claim granularity table.
- `schema/workflows/audit.md` — `--select derived-report` audit tier.
