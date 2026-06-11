# Phase 20: PDF Ingestion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 20-pdf-ingestion
**Areas discussed:** Convention doc home, Tool specificity, Sub-case verdict, Epistemic policy, Frontmatter + lint, Tooling depth, Validation artifact

**Format note:** The user requested a full gray-area enumeration with internal tradeoff analysis up front (effectively `--analyze --batch` style), then answered in two AskUserQuestion batches plus one freeform clarification round.

---

## Convention doc home

| Option | Description | Selected |
|--------|-------------|----------|
| A: New `schema/reference/pdf-ingestion.md` | Self-contained convention + runbook, own routing row, lazy-loaded | ✓ (hybrid) |
| B: Section in `source-types.md` | No new file; every Pass-0 classification pays the runbook context cost | (lean pointer only) |
| C: Shared `acquisition-pipelines.md` | One file for PDF + video pipelines; one routing row total | |
| D: Split reference/workflows | Convention in existing refs; runbook as `schema/workflows/pdf-acquisition.md` | |

**User's choice:** Freeform: "maybe A with a row mentioning the routing (lean B)?" — A plus the `source-types.md` registry row carrying only a pointer/link to the new doc (no content duplication).
**Notes:** User first asked for deeper tradeoff analysis on this question before answering (the first batch left it unanswered). The expanded analysis surfaced the Pass-0 context-cost asymmetry and the Phase 21 sibling-pattern consideration. The hybrid is structurally what the design already provides (registry "Convention Doc" column); confirmed and locked.

## Tool specificity (template-public posture)

| Option | Description | Selected |
|--------|-------------|----------|
| Generic contract + olmOCR worked instance | Any extractor emitting `<!-- page: N -->` satisfies the contract; olmOCR 2 via Ollama (incl. model tag) named as worked instance | ✓ |
| Fully tool-specific | Schema doc as an olmOCR/Ollama runbook, period | |
| Video pattern (generic only) | olmOCR specifics only in `.planning/` notes | |

**User's choice:** Generic contract + olmOCR worked instance (recommended option).
**Notes:** olmOCR/Ollama are public tools — neutrality denylist covers private vault terms only; contrast with Phase 21's personal `stt` CLI.

## Sub-case verdict shape

| Option | Description | Selected |
|--------|-------------|----------|
| Format-orthogonal | PDF = acquisition-path sub-case applicable to any document type; content classified normally | ✓ |
| Single parent type | Lock PDF as sub-case of exactly one type (e.g., paper) | |
| Let the walk-through decide | No pre-commitment | |

**User's choice:** Format-orthogonal (recommended option).

## Epistemic policy (PDF-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Tiered: clean vs degraded | Human classifies at acquisition; born-digital → sourced; degraded → mandatory spot-verification + tentative default, upgradeable | ✓ |
| Lower default only | Degraded → tentative/mixed, no verification mandate | |
| Spot-verification only | Page spot-checks, default unchanged | |

**User's choice:** Tiered (recommended option).
**Notes:** Question text stipulated claims stay `support_type: direct` (primary source); user did not object — locked as D-09.

## Frontmatter shape + lint enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Flat fields + lint check | `extraction_tool`, `extraction_model`, `extraction_date`, `original_asset`; lint requires extraction fields when `original_asset` is `*.pdf` | ✓ |
| Flat fields, convention-only | Same fields, no lint this phase | |
| Single combined string | `extracted_by: "..."` + `original_asset` | |

**User's choice:** Flat fields + lint check (recommended option).

## Tooling depth

| Option | Description | Selected |
|--------|-------------|----------|
| Thin `pdf-extract.sh` + `ingest.sh --asset` | Extractor script (pdftoppm + local Ollama + markers) plus bundle flag on ingest.sh | ✓ |
| `pdf-extract.sh` only, manual bundle | Document the cp step instead of touching ingest.sh | |
| Doc-only runbook | Human runs the per-page loop by hand | |

**User's choice:** Thin `pdf-extract.sh` + `ingest.sh --asset` (recommended option).

## Validation artifact (PDF-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Clean born-digital PDF | Fast, low-risk happy path | ✓ |
| Degraded/scanned PDF | Exercises tier-2 spot-verification in anger | |
| Clean primary + degraded spot-exercise | Both paths with one official artifact | |

**User's choice:** Clean born-digital PDF.
**Notes:** Specific artifact not named — user supplies it at execution time (plan must include a prompt for it). Constraints noted: cloud-safe, ~5–30 pages.

---

## Claude's Discretion

- Exact section structure/wording of `pdf-ingestion.md` (neutral placeholders in template-public surfaces)
- Field-name spelling; whether `extraction_date` collapses into `ingested_at`
- Spot-verification N, page selection method, and the post-verification upgrade rule
- Registry-row verdict wording
- `pdf-extract.sh` CLI surface and poppler dependency note placement
- Exact LINT_VERSION number and lint check shape
- Spot-verification via audit tooling vs manual checklist (read-only either way)
- Whether to author a reflect-tier decision record for the schema change

## Deferred Ideas

- Wiki-side auto-marker insertion (provenance.md D-07) — stays deferred
- 999.5 External Source Drift detection — out of milestone
- Degraded-scan end-to-end ingest — convention ships now; in-anger validation is future work
- Reviewed-not-folded todo: `phase-14-lint-mask-fence-edge-cases` (third consecutive review)
