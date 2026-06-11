# Phase 20: PDF Ingestion - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

PDFs become ingestible sources via a documented acquisition pipeline (PDF → Markdown with `<!-- page: N -->` page markers; olmOCR 2 on local Ollama as the worked instance), formalized as a **format-orthogonal sub-case** under the Phase 19 extension contract — finalizing the provisional registry row in `schema/reference/source-types.md` — with page-anchored `#p` provenance, extraction tool/model recorded in source frontmatter, tiered VLM-hallucination epistemic guidance for degraded scans, and one real PDF ingested end-to-end exercising the bundle convention (original PDF co-located as asset).

Covers PDF-01..04. **Out of scope:** video ingestion (Phase 21); external source drift detection (999.5); any new `source_type` enum value (PDF is a sub-case, not a type); wiki-side auto-marker insertion at lint/audit time (provenance.md D-07 stays deferred — markers originate in acquisition).

</domain>

<decisions>
## Implementation Decisions

### Convention doc home & routing
- **D-01:** New authoritative `schema/reference/pdf-ingestion.md` holds BOTH the PDF sub-case convention (frontmatter fields, locator usage, epistemic tiers) and the acquisition pipeline runbook. Lazy-loaded — PDF content is NOT needed at Pass-0 classification time, so it must not bloat `source-types.md` (the progressive-disclosure argument that drove v1.2).
- **D-02:** "A + lean B" pointer structure: `source-types.md`'s Evaluated Candidates registry row for `pdf` is finalized with the verdict and its "Convention Doc" column links to `schema/reference/pdf-ingestion.md`. One-row pointer cost at classification time; no runbook content duplicated into the contract file (Phase 16 bare-pointer-stub pattern).
- **D-03:** `pdf-ingestion.md` gets a routing-table row in AGENTS.md/CLAUDE.md (Phase 19 D-02 precedent: every authoritative `schema/reference/*.md` gets a row). Byte-equality via `bin/sync-claude.sh`; the `routing` lint category validates the path; neutrality gate applies.

### Tool specificity (template-public posture)
- **D-04:** The schema doc defines a **generic contract** — any PDF→Markdown extractor that emits `<!-- page: N -->` markers satisfies the pipeline — with **olmOCR 2 via Ollama as the named worked instance**, including the exact model tag (`richardyoung/olmocr2:7b-q8`). olmOCR/Ollama are public tools, so naming them in template-public text is allowed (unlike Phase 21's personal `stt` CLI, which stays tool-generic per VID-01). Cite the wiki's own SOTA overview as the recommendation's source.

### Sub-case verdict
- **D-05:** The registry verdict is **format-orthogonal**: PDF is an *acquisition-path* sub-case applicable to any document type. Content is classified normally at Pass 0 (article/paper/data/...), and the PDF convention (extraction frontmatter, `#p` locators, epistemic tiers) layers on top. The 5-dimension walk-through in this phase formalizes it: only Acquisition changes unconditionally; Epistemic Default changes conditionally (degraded input). Do NOT lock PDF to a single parent type.

### Frontmatter & lint enforcement
- **D-06:** Flat snake_case fields on the source summary page: `extraction_tool`, `extraction_model`, `extraction_date`, `original_asset` (relative path to the co-located PDF in the bundle). Flat for Dataview queryability; no nested YAML block; no provenance blobs in frontmatter.
- **D-07:** Lint-enforced, not convention-only (Phase 19 D-08 posture: "convention-only would silently regress"): when `original_asset` points at a `*.pdf`, the extraction fields are required. LINT_VERSION bumps (1.9.0 → 1.10.0 or per current version at implementation time).

### Epistemic policy for VLM-extracted text (PDF-03)
- **D-08:** **Tiered policy.** The **human classifies clean-vs-degraded at acquisition time** (born-digital vs scan is trivially observable; no fragile heuristics). Born-digital/clean → normal `sourced` default, no verification mandate. Degraded/scanned → mandatory spot-verification of N pages + `tentative` page-level epistemic default, upgradeable after verification passes.
- **D-09:** Claims from PDF sources stay `support_type: direct` — PDF is a primary source; OCR is extraction, not derivation. The hallucination risk is expressed through *epistemic status*, never through support type (Phase 19's `derived` is reserved for secondary sources).

### Tooling depth (thin glue)
- **D-10:** Ship thin `bin/pdf-extract.sh`: PDF in → marked-up Markdown out, via pdftoppm (poppler) page rendering + per-page local Ollama calls + `<!-- page: N -->` marker assembly. Markers come free and positionally correct from the acquisition loop. This is the "at most thin glue" the milestone constraint explicitly permits. Note: this is the first repo script invoking a local model — `bin/ingest.sh`'s "no LLM API calls" charter is per-script, not repo-wide; document the distinction.
- **D-11:** Extend `bin/ingest.sh` with an `--asset` flag so a bundle ingest co-locates the original PDF alongside `source.md` in one invocation (currently single-file only).

### End-to-end validation (PDF-04)
- **D-12:** Validation artifact is **one clean born-digital, cloud-safe PDF**, ~5–30 pages (local 7B-q8 inference practicality). The user supplies the specific PDF at execution time — the plan must include a checkpoint/prompt for it. `sources/` is cloud-safe-only; verify before ingest.

### Claude's Discretion
- Exact section structure and wording of `pdf-ingestion.md` (must use neutral placeholders in template-public surfaces per the MUST-NOT list).
- Final field-name spelling and whether `extraction_date` is distinct from `ingested_at` (collapse if redundant).
- N for spot-verification (how many pages, selection method) and the upgrade rule wording (`tentative` → what, after verification).
- Registry-row verdict wording for the format-orthogonal sub-case.
- `pdf-extract.sh` CLI surface (flags, output path conventions, error handling), poppler dependency note placement.
- Exact LINT_VERSION number and lint check implementation shape.
- Whether the spot-verification exercise during validation uses the audit tooling or a manual checklist (read-only either way; no new audit machinery).
- Decision-record authoring: a `reflect`-tier DR in `wiki-cloud/decisions/` for the schema change is the established pattern (Phase 18/19 precedent) — author one if the schema edits warrant it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Extension contract (the rule this phase applies)
- `schema/reference/source-types.md` — the 5-dimension contract, decision rule, and the provisional `pdf` registry row (§4, ~line 49) this phase finalizes; the research-report worked instance (§5–6) as the structural precedent.
- `.planning/seeds/primary-source-type-extensions.md` — the 5-dimension decision framework's design lineage.
- `.planning/notes/2026-05-31-milestone-grouping-proposal.md` — "Source Ingestion" cluster rationale (SI.n open-ended set; design-once logic).

### Schema surfaces this phase edits
- `schema/reference/provenance.md` — `#p` locator (Locator Types, ~line 28) and the `<!-- page: N -->` page-marker convention (~lines 35–58) incl. slice semantics, optional-with-graceful-degradation posture, and D-07 "document-now / helper-later" (auto-insertion stays deferred; markers now originate in acquisition).
- `schema/reference/frontmatter.md` — Source Summary Additional Fields block (~lines 58–75) where the new extraction fields land.
- `schema/workflows/ingest.md` — Pass 0 classification (PDF classifies to its content's parent type; pointer to the convention doc).
- `AGENTS.md` + `CLAUDE.md` — routing-table row for `pdf-ingestion.md`; byte-equality via `bin/sync-claude.sh --check`.

### Tooling this phase edits
- `bin/lint.sh` — `SOURCE_EXTRA_FIELDS` (~line 406) and frontmatter validation machinery for the new conditional check; LINT_VERSION at line 13.
- `bin/ingest.sh` — single-file placement logic (~lines 270–313) to extend with `--asset`; note its "file-system bookkeeping only, no LLM API calls" charter stays intact (pdf-extract.sh is a separate script).

### The wiki's own domain knowledge (grounds tool choice + hallucination guidance)
- `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md` — SOTA landscape; olmOCR 2 as strongest self-hosting pick.
- `wiki-cloud/concepts/vlm-ocr-hallucination.md` — the failure mode the tiered epistemic policy defends against (plausible-but-wrong text on degraded input).
- `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md` — source summary backing both pages (research-report; claims are `derived`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `#p` locator + `<!-- page: N -->` marker convention already fully specified in `provenance.md` (slice semantics, exclusive upper bound, graceful degradation to `insufficient-locator`) — Phase 20 produces the markers; zero locator-grammar changes needed.
- `bin/audit-claims.sh` already resolves `#p` locators against page markers — spot-verification can lean on existing resolution.
- Phase 19's registry row structure (D-04) — Phase 20 fills the existing provisional row; no new registry structure.
- `bin/ingest.sh` scaffolding (dated dirs, content_hash, bundle dir naming) — the `--asset` extension composes with existing placement logic.
- Local environment already staged: Ollama installed, `richardyoung/olmocr2:7b-q8` pulled (verified 2026-06-11).

### Established Patterns
- v1.2 extraction conventions: one authoritative file per concern under `schema/reference/`; routing rows in the resident core; bare-pointer stubs elsewhere (no reproduced content).
- Lint `routing` category validates routing-table path integrity — the new row must point at an existing file in the same commit.
- Template-public neutrality: `pdf-ingestion.md`, `frontmatter.md`, `ingest.md` edits use abstract placeholders (`<source-id>`, `<YYYY-MM-DD-slug>`); public tool names (olmOCR, Ollama, poppler) are permitted. The validation ingest itself touches `sources/` + `wiki-cloud/` where real slugs are fine.
- One commit per logical operation; `schema:` / `lint(scope):` / `ingest(slug):` prefixes per the conventions table.
- Phase 19 ordering lesson: land data and lint check so the repo never lints red between commits (the new conditional lint check must not fire on a not-yet-ingested PDF source).

### Integration Points
- `wiki-cloud/index.md` + `wiki-cloud/log.md` — the validation ingest is a normal logged ingest.
- `.github/workflows/` CI lint gate — picks up the new lint check automatically on LINT_VERSION bump.
- Pre-commit gates: `sync-claude --check`, `check-neutrality.sh`, `gen-skills.sh --check` all must pass on the routing-table commit.

</code_context>

<specifics>
## Specific Ideas

- "A with a row mentioning the routing (lean B)" — the user's own framing for D-01/D-02: self-contained convention file, with `source-types.md` carrying only the registry-row pointer. Honor this shape exactly; it is also the pattern Phase 21 (video) should inherit.
- The generic-contract framing should read: any extractor that emits `<!-- page: N -->` markers satisfies the pipeline — tool-agnostic contract, concrete worked instance.
- Pipeline reality the runbook must reflect: Ollama takes images, not PDFs — the loop is pdftoppm page rendering → per-page model call → marker assembly.

</specifics>

<deferred>
## Deferred Ideas

- **Wiki-side auto-marker insertion** (provenance.md D-07 "helper-later") — stays deferred; acquisition now produces markers, weakening the case for a lint/audit-side helper further.
- **999.5 External Source Drift detection** — out of milestone (carried from Phase 19).
- **Degraded-scan end-to-end ingest** — the validation artifact is clean born-digital; a real degraded-scan ingest exercising tier-2 spot-verification in anger is future work (the convention ships now, tested at convention level).

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` — "Harden bin/lint.sh mask_markdown for fence edge cases" (Phase 14 review residue). Reviewed and NOT folded: unrelated behavioral lint change; keyword-only match (score 0.6). Third consecutive review-not-fold (Phases 17, 19, 20) — stays in backlog.

</deferred>

---

*Phase: 20-pdf-ingestion*
*Context gathered: 2026-06-11*
