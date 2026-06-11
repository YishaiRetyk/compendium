# Phase 20: PDF Ingestion - Research

**Researched:** 2026-06-11
**Domain:** Documentation/convention engineering — PDF→Markdown acquisition pipeline + source-type sub-case convention for an LLM wiki compiler
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** New authoritative `schema/reference/pdf-ingestion.md` holds BOTH the PDF sub-case convention (frontmatter fields, locator usage, epistemic tiers) AND the acquisition pipeline runbook. Lazy-loaded — PDF content is NOT needed at Pass-0 classification time, so it must not bloat `source-types.md` (the progressive-disclosure argument that drove v1.2).
- **D-02:** "A + lean B" pointer structure: `source-types.md`'s Evaluated Candidates registry row for `pdf` is finalized with the verdict; its "Convention Doc" column links to `schema/reference/pdf-ingestion.md`. One-row pointer cost at classification time; no runbook content duplicated into the contract file (Phase 16 bare-pointer-stub pattern).
- **D-03:** `pdf-ingestion.md` gets a routing-table row in AGENTS.md/CLAUDE.md (Phase 19 D-02 precedent: every authoritative `schema/reference/*.md` gets a row). Byte-equality via `bin/sync-claude.sh`; the `routing` lint category validates the path; neutrality gate applies.
- **D-04:** The schema doc defines a **generic contract** — any PDF→Markdown extractor that emits `<!-- page: N -->` markers satisfies the pipeline — with **olmOCR 2 via Ollama as the named worked instance**, including the exact model tag (`richardyoung/olmocr2:7b-q8`). olmOCR/Ollama are public tools, so naming them in template-public text is allowed (unlike Phase 21's personal `stt` CLI). Cite the wiki's own SOTA overview as the recommendation's source.
- **D-05:** The registry verdict is **format-orthogonal**: PDF is an *acquisition-path* sub-case applicable to any document type. Content is classified normally at Pass 0 (article/paper/data/...), and the PDF convention layers on top. The 5-dimension walk-through formalizes it: only Acquisition changes unconditionally; Epistemic Default changes conditionally (degraded input). Do NOT lock PDF to a single parent type.
- **D-06:** Flat snake_case fields on the source summary page: `extraction_tool`, `extraction_model`, `extraction_date`, `original_asset` (relative path to the co-located PDF). Flat for Dataview queryability; no nested YAML block; no provenance blobs in frontmatter.
- **D-07:** Lint-enforced, not convention-only (Phase 19 D-08 posture): when `original_asset` points at a `*.pdf`, the extraction fields are required. LINT_VERSION bumps (current 1.9.1 → 1.10.0 minimum per the additive-category rule).
- **D-08:** **Tiered epistemic policy.** Human classifies clean-vs-degraded at acquisition time (born-digital vs scan is trivially observable; no fragile heuristics). Born-digital/clean → normal `sourced` default, no verification mandate. Degraded/scanned → mandatory spot-verification of N pages + `tentative` page-level epistemic default, upgradeable after verification passes.
- **D-09:** Claims from PDF sources stay `support_type: direct` — PDF is a primary source; OCR is extraction, not derivation. Hallucination risk is expressed through *epistemic status*, never through support type (Phase 19's `derived` is reserved for secondary sources).
- **D-10:** Ship thin `bin/pdf-extract.sh`: PDF in → marked-up Markdown out, via pdftoppm (poppler) page rendering + per-page local Ollama calls + `<!-- page: N -->` marker assembly. This is the first repo script invoking a local model — `bin/ingest.sh`'s "no LLM API calls" charter is per-script, not repo-wide; document the distinction.
- **D-11:** Extend `bin/ingest.sh` with an `--asset` flag so a bundle ingest co-locates the original PDF alongside `source.md` in one invocation (currently single-file only).
- **D-12:** Validation artifact is **one clean born-digital, cloud-safe PDF**, ~5–30 pages (local 7B-q8 inference practicality). The user supplies the specific PDF at execution time — the plan MUST include a checkpoint/prompt for it. `sources/` is cloud-safe-only; verify before ingest.

### Claude's Discretion

- Exact section structure and wording of `pdf-ingestion.md` (neutral placeholders in template-public surfaces per the MUST-NOT list).
- Final field-name spelling and whether `extraction_date` is distinct from `ingested_at` (collapse if redundant).
- N for spot-verification (how many pages, selection method) and the upgrade rule wording (`tentative` → what, after verification).
- Registry-row verdict wording for the format-orthogonal sub-case.
- `pdf-extract.sh` CLI surface (flags, output path conventions, error handling), poppler dependency note placement.
- Exact LINT_VERSION number and lint check implementation shape.
- Whether spot-verification during validation uses the audit tooling or a manual checklist (read-only either way; no new audit machinery).
- Decision-record authoring: a `reflect`-tier DR in `wiki-cloud/decisions/` for the schema change is the established pattern (Phase 18/19 precedent) — author one if the schema edits warrant it.

### Deferred Ideas (OUT OF SCOPE)

- **Wiki-side auto-marker insertion** (provenance.md D-07 "helper-later") — stays deferred; acquisition now produces markers.
- **999.5 External Source Drift detection** — out of milestone.
- **Degraded-scan end-to-end ingest** — validation artifact is clean born-digital; a real degraded-scan tier-2 ingest is future work (convention ships now, tested at convention level).
- New `source_type` enum value — PDF is a sub-case, not a type.
- `phase-14-lint-mask-fence-edge-cases` todo — reviewed and NOT folded (third consecutive review-not-fold; stays in backlog).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PDF-01 | Documented PDF acquisition pipeline: olmOCR 2 (local Ollama) → Markdown with `<!-- page: N -->` markers, ready for standard ingest | Pipeline verified end-to-end: pdftoppm renders pages → PNG, Ollama `/api/generate` accepts base64 images, model `richardyoung/olmocr2:7b-q8` confirmed pulled with vision capability + built-in OCR system prompt. Runbook + `bin/pdf-extract.sh` (D-10). |
| PDF-02 | Sub-case convention records original-PDF reference + extraction tool/model in source frontmatter; claims use existing `#p` locators | `#p` locator + `<!-- page: N -->` marker grammar already fully specified in `provenance.md`; zero grammar changes. New flat fields `extraction_tool/extraction_model/extraction_date/original_asset` land in `frontmatter.md` Source Summary block (D-06). |
| PDF-03 | VLM-hallucination guidance: degraded/scanned input gets spot-verification and/or lower epistemic default | Grounded in the wiki's own `vlm-ocr-hallucination.md` concept page. Tiered policy (D-08): human classifies clean-vs-degraded at acquisition; degraded → `tentative` + N-page spot-verify, upgradeable. `support_type` stays `direct` (D-09). |
| PDF-04 | End-to-end validation: one real PDF acquired → ingested → wiki pages with page-anchored provenance; original PDF co-located as bundle asset | `bin/ingest.sh --asset` extension (D-11) + human-checkpoint for the user-supplied clean born-digital cloud-safe PDF (D-12). `audit-claims.sh` already resolves `#p` for spot-verification. |
</phase_requirements>

## Summary

This is a **documentation/convention-engineering phase with thin shell glue**, not a feature-build. Nearly every primitive the phase needs already exists and is verified present: the `#p` page locator and `<!-- page: N -->` marker convention are fully specified in `schema/reference/provenance.md` (with slice semantics and graceful degradation); `bin/audit-claims.sh` already resolves `#p` against those markers; the provisional `pdf` registry row already sits in `source-types.md` §4 awaiting finalization; `bin/ingest.sh` already does dated-dir/content_hash/bundle scaffolding; and the local environment is staged (Ollama 0.20.2, `richardyoung/olmocr2:7b-q8` pulled, poppler 24.02.0 with `pdftoppm`/`pdfinfo`, jq, base64, python3 all present and the Ollama server reachable).

The phase's real work is (1) authoring one new authoritative file `schema/reference/pdf-ingestion.md` (convention + runbook), (2) wiring it into the routing/lint/sync machinery exactly as Phase 19 wired `source-types.md`, (3) adding four flat frontmatter fields with a conditional lint check, (4) extending two shell scripts (`ingest.sh --asset`, new `pdf-extract.sh`), and (5) one real end-to-end validation ingest gated on a user-supplied PDF. The single genuinely new technical artifact is `bin/pdf-extract.sh` — and even that is "thin glue" the milestone explicitly permits: a pdftoppm→Ollama-per-page→marker-assembly loop.

The dominant risks are not technical-unknowns but **sequencing and neutrality**: the new conditional lint check must not fire red on a not-yet-ingested PDF source (Phase 19's lesson — never lint red between commits), and template-public surfaces must use abstract placeholders (public tool names olmOCR/Ollama/poppler are allowed; real vault slugs are not).

**Primary recommendation:** Treat this as "fill the provisional slots Phase 19 left open." Author `pdf-ingestion.md` mirroring the §5–6 research-report worked-instance structure; finalize the `pdf` registry row as a format-orthogonal sub-case; add the four flat fields + a conditional `original_asset→*.pdf` lint check (LINT_VERSION 1.10.0); build `pdf-extract.sh` against the Ollama `/api/generate` HTTP endpoint (NOT `ollama run`, which attaches images interactively, not script-friendly); land data-then-check so the repo never lints red; gate PDF-04 on a `autonomous: false` checkpoint.

## Architectural Responsibility Map

This is a single-tier CLI + markdown-corpus system. "Tiers" here map to the repo's layered model (schema / tooling / wiki content).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PDF→Markdown acquisition | Tooling (`bin/pdf-extract.sh`) + external local model | Runbook doc (`pdf-ingestion.md`) | Acquisition is the one dimension that changes; it lives outside the wiki, invoked by a thin script. The model runs locally via Ollama HTTP API. |
| Page-marker emission (`<!-- page: N -->`) | Tooling (`pdf-extract.sh` assembly loop) | — | Markers come free and positionally correct from the per-page loop (one page render = one marker). Provenance.md D-07 keeps auto-insertion *at lint/audit time* deferred; here markers originate at acquisition. |
| Sub-case convention (fields, locators, epistemic tiers) | Schema (`schema/reference/pdf-ingestion.md`) | `source-types.md` registry row (pointer) | Authoritative convention; lazy-loaded, not needed at Pass-0. |
| Classification verdict (sub-case, not new type) | Schema (`source-types.md` §4 registry) | `pdf-ingestion.md` | The contract file owns the registry; the verdict finalizes the provisional row. |
| Frontmatter field validation | Tooling (`bin/lint.sh` yaml category) | `frontmatter.md` (doc) | Lint is the enforcement mechanism (D-07); frontmatter.md is the human-facing spec. |
| Bundle asset co-location | Tooling (`bin/ingest.sh --asset`) | — | File-system bookkeeping; composes with existing placement logic, charter intact (no LLM calls in ingest.sh). |
| Provenance resolution / spot-verification | Tooling (`bin/audit-claims.sh`, read-only) | manual checklist | Already resolves `#p`; no new audit machinery (D-08 discretion). |
| End-to-end validation ingest | Wiki content (`sources/`, `wiki-cloud/`) | human checkpoint | Normal logged ingest; real slugs fine here (not template-public). |

## Standard Stack

### Core (all VERIFIED present on this machine — `[VERIFIED: local probe 2026-06-11]`)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Ollama | 0.20.2 | Local model server; serves olmOCR 2 via HTTP `/api/generate` | Already installed; server reachable at `localhost:11434`. The wiki's own SOTA overview names olmOCR 2 the strongest self-hosting pick. |
| `richardyoung/olmocr2:7b-q8` | (pulled 2 days ago, 9.5 GB) | VLM-OCR model. Base: Qwen2.5-VL-7B-Instruct OCR fine-tune, Q8_0, 128k ctx, **vision capability confirmed**, built-in OCR system prompt | The exact tag named in D-04. olmOCR-2-7B = `allenai/olmOCR-2-7B-1025`; 82.4 on olmOCR-Bench per the wiki overview. |
| poppler (`pdftoppm`, `pdfinfo`) | 24.02.0 | Render PDF pages to PNG (`-png -r <dpi> -f <n> -l <n>`); read page count (`pdfinfo`) | Standard PDF rasterizer; Ollama takes images not PDFs, so rasterization is mandatory (CONTEXT specifics). |
| `jq` | 1.7 | Safe JSON assembly of the base64-image request body | Avoids hand-rolled JSON escaping in shell. |
| `base64`, `python3` | (3.12.3) | base64-encode the page PNG; fallback JSON assembly | Standard. |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `bin/audit-claims.sh` | Resolves `#p` locators against `<!-- page: N -->` markers (read-only) | Spot-verification of degraded pages (D-08); no new machinery. |
| `bin/sync-claude.sh --check` | AGENTS.md→CLAUDE.md byte-equality (`cmp -s`) | After adding the routing-table row (D-03). |
| `bin/check-neutrality.sh` | Template-public denylist backstop | Pre-commit gate on the routing + doc commits. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `pdftoppm` (poppler) | `pdf2image` (Python wrapper) | Adds a Python runtime dep; poppler is already present and CLI-native — no new dep, aligns with the repo's "thin glue" / minimal-dependency posture. |
| Ollama `/api/generate` HTTP endpoint | `ollama run MODEL [PROMPT]` CLI with image | **`ollama run` attaches images interactively, NOT script-friendly** `[VERIFIED: ollama run --help — no positional image arg; image-attach is an interactive REPL affordance]`. The HTTP `/api/generate` with base64 `images: [...]` is the robust scriptable path. **Use the HTTP API.** |
| olmOCR 2 via Ollama | olmOCR's own toolkit / vLLM serving | The repo deliberately keeps acquisition tools out of the repo (REQUIREMENTS "In-repo acquisition tooling" out-of-scope). Ollama is the already-staged, lowest-friction local server. Generic contract (D-04) permits any extractor emitting markers. |

**Installation:** Nothing to install — all tools verified present. The runbook should document the dependency list (poppler, Ollama, the model tag, jq) as a prerequisites note so a fresh clone knows what's needed `[VERIFIED: local probe]`.

**Model invocation shape (VERIFIED-adjacent — endpoint reachable, full call not run to save time):**
```bash
# Per page: render → encode → POST to Ollama → capture text
pdftoppm -png -r 150 -f "$N" -l "$N" "$PDF" "$TMP/page"     # → page-NN.png
B64=$(base64 -w0 "$TMP/page-${NN}.png")
curl -s http://localhost:11434/api/generate -d "$(jq -n \
  --arg m "richardyoung/olmocr2:7b-q8" \
  --arg p "Extract all text from this document page as Markdown, preserving structure." \
  --arg img "$B64" \
  '{model:$m, prompt:$p, images:[$img], stream:false}')" | jq -r '.response'
```
*Plan note:* the model carries a built-in OCR system prompt, so the per-page `prompt` can be minimal. `num_ctx` defaults to 4096 in the Modelfile; long/dense pages may warrant `options.num_ctx: 8192`. The planner should include a "tune DPI + num_ctx on the real artifact" task — 150 DPI is the pdftoppm default and a reasonable start.

## Architecture Patterns

### System Architecture Diagram (acquisition → ingest → provenance)

```
                         ACQUISITION (outside wiki, bin/pdf-extract.sh)
  original.pdf ──► pdfinfo (page count)
       │                │
       │                ▼
       │          for N in 1..pages:
       │            pdftoppm -png -f N -l N ──► page-N.png
       │                                          │
       │                                          ▼
       │                            base64 ──► POST /api/generate (Ollama)
       │                                          │  model: olmocr2:7b-q8
       │                                          ▼
       │                                   per-page Markdown text
       │                                          │
       │                       assemble: "<!-- page: N -->\n" + text
       │                                          ▼
       └──────────────────────────────►  extracted.md  (page-marked Markdown)
                                                  │
                 ┌────────────────────────────────┘
                 ▼   INGEST (bin/ingest.sh --asset original.pdf)
   sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/
        ├── source.md      (= extracted.md, the marked Markdown)
        └── original.pdf   (co-located bundle asset)   ← --asset
                 │
                 ▼   COMPILE (LLM agent, normal ingest workflow)
   wiki-cloud/sources/<source_id>.md   ── frontmatter: source_type (parent type),
        │                                  extraction_tool/model/date, original_asset
        │                                  claims with [prov:<id>#p<N>|direct]
        ▼
   topic pages (entities/concepts/...) with #p-anchored provenance
                 │
                 ▼   VERIFY (read-only)
   bin/audit-claims.sh resolves #p<N> against <!-- page: N --> markers
   bin/lint.sh: original_asset→*.pdf ⇒ extraction_* fields required (D-07)
```

### Recommended Edit Surface (files this phase touches)

```
schema/reference/pdf-ingestion.md     # NEW — convention + runbook (authoritative, lazy-loaded)
schema/reference/source-types.md      # §4 registry row pdf → finalize verdict + Convention Doc pointer
schema/reference/frontmatter.md       # Source Summary block (~L58-75) → 4 new flat fields
schema/workflows/ingest.md            # Pass 0 (~L17) → PDF classifies to parent type; pointer to convention
AGENTS.md                             # routing-table row for pdf-ingestion.md (~L50 area)
CLAUDE.md                             # byte-equal mirror (bin/sync-claude.sh)
bin/lint.sh                           # L13 LINT_VERSION; L408 SOURCE_EXTRA_FIELDS; ~L1091 conditional check
bin/ingest.sh                         # arg parse (~L161) + placement (~L300-313) → --asset
bin/pdf-extract.sh                    # NEW — thin acquisition glue
wiki-cloud/decisions/dr-...           # OPTIONAL reflect-tier DR (Phase 18/19 precedent)
+ validation ingest: sources/... + wiki-cloud/sources/... + index.md + log.md
```

### Pattern 1: "A + lean B" authoritative-file + registry-pointer (D-01/D-02)
**What:** A self-contained authoritative `schema/reference/*.md` owns the full convention; the contract file (`source-types.md`) carries only a one-row pointer. No content duplication.
**When to use:** Any sub-case whose detail is not needed at the classification chokepoint (Pass 0).
**Example:** Mirror the existing research-report structure — `source-types.md` §5–6 is the worked secondary instance; `pdf-ingestion.md` is the worked acquisition-path sub-case. The registry §4 row:
```markdown
| `pdf` | sub-case (format-orthogonal; any parent type) | Acquisition (always); Epistemic Default (degraded input only) | `schema/reference/pdf-ingestion.md` | ... |
```

### Pattern 2: Data-then-lint-check ordering (Phase 19 lesson)
**What:** Land the lint check in a state where the existing repo stays green; only ingest the PDF source (which carries the new required fields) such that the conditional never fires on absent data.
**When to use:** Any additive conditional lint check.
**How:** The check is gated on `original_asset` pointing at `*.pdf`. Pages without `original_asset` (every existing source) are untouched. So the check can land *before* the validation ingest without going red — only a `*.pdf`-asset page that omits `extraction_*` fails. `[CITED: CONTEXT Established-Patterns — "the new conditional lint check must not fire on a not-yet-ingested PDF source"]`

### Pattern 3: Conditional source-field check (mirror the research-report enum gate)
**What:** Lint's source-summary block (`bin/lint.sh` ~L1091) already does conditional source validation (`source_type` enum, `compilation_status` enum). Add a parallel `if original_asset endswith '.pdf'` branch requiring the four `extraction_*` fields.
**Where:** Inside `if fm.get('type') == 'source':` after the `source_type` enum check. `SOURCE_EXTRA_FIELDS` (L408) stays unchanged (those are unconditional); the PDF fields are a *conditional* requirement, so they get their own branch, not a `SOURCE_EXTRA_FIELDS` append.

### Anti-Patterns to Avoid
- **Adding a `pdf` value to the `source_type` enum** — PDF is a sub-case (D-05); `VALID_SOURCE_TYPES` (L399) stays at 7 values. The content's parent type (article/paper/data...) is the `source_type`.
- **Appending the PDF fields to `SOURCE_EXTRA_FIELDS`** — that list is *unconditional* (every source page must have them); the PDF fields are conditional on `original_asset→*.pdf`. Adding them there would fail every existing source page.
- **Using `ollama run` for the extraction loop** — interactive image-attach, not scriptable. Use `/api/generate`.
- **Duplicating runbook content into `source-types.md`** — violates D-02 and the progressive-disclosure rationale.
- **`support_type: derived` on PDF claims** — PDF is primary; `derived` is reserved for secondary sources (D-09). Hallucination risk → epistemic status only.
- **Auto-inserting markers at lint/audit time** — explicitly deferred (provenance.md D-07); markers originate at acquisition.
- **Real vault slugs in template-public files** — `pdf-ingestion.md`, `frontmatter.md`, `ingest.md`, AGENTS.md/CLAUDE.md, `bin/` use abstract placeholders. Public tool names (olmOCR, Ollama, poppler) are permitted.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `#p` locator resolution / slice semantics | A new page-slice resolver | `bin/audit-claims.sh` `slice_pages()` (L422-477) | Already resolves `<!-- page: N -->` with exclusive-upper-bound semantics + `insufficient-locator` graceful degradation. |
| Page-marker grammar | A new marker syntax | `provenance.md` `<!-- page: N -->` (already specified) | Grammar + slice semantics already locked; Phase 20 only *produces* markers. |
| PDF rasterization | Custom render code | `pdftoppm -png` | Battle-tested poppler. |
| JSON request escaping | String-concatenated JSON | `jq -n` | Base64 strings + prompts need safe escaping. |
| Dated dir / content_hash / bundle naming | New scaffolding | `bin/ingest.sh` existing logic | `--asset` composes with it (D-11). |
| Routing-table integrity | Manual path-check | `bin/lint.sh` `routing` category (L2413) | Validates forward path existence + inverse reachability automatically on LINT run. |
| AGENTS↔CLAUDE parity | Manual diff | `bin/sync-claude.sh` (`cmp -s`) | Byte-equality enforced by pre-commit hook. |

**Key insight:** This phase is ~90% wiring existing, verified primitives into a documented convention. The only net-new code is `bin/pdf-extract.sh` (a render→infer→assemble loop), and the milestone explicitly scopes it as permitted thin glue.

## Common Pitfalls

### Pitfall 1: Lint goes red between commits
**What goes wrong:** Adding the conditional `extraction_*` requirement before any compliant PDF source exists, or appending PDF fields to the unconditional `SOURCE_EXTRA_FIELDS`, fires errors on existing source pages or on the in-progress validation source.
**Why it happens:** Misplacing the check as unconditional, or ordering the lint-version bump before the data.
**How to avoid:** Gate strictly on `original_asset` ending `.pdf`. Existing sources have no `original_asset` → untouched. Land the check; it stays green until a PDF source with the asset but missing fields appears (which the validation ingest authors correctly in the same logical operation). `[CITED: CONTEXT — Phase 19 ordering lesson]`
**Warning signs:** `bin/lint.sh` reports `Source page missing fields` on pre-existing `wiki-cloud/sources/*.md`.

### Pitfall 2: `ollama run` chosen for the extract loop
**What goes wrong:** Script hangs or ignores the image; `ollama run MODEL PROMPT` has no positional image argument.
**Why it happens:** Training-era assumption that `ollama run model image.png` works.
**How to avoid:** Use the HTTP `/api/generate` endpoint with `images: [<base64>]`, `stream: false`. `[VERIFIED: ollama run --help shows no image positional; server reachable at localhost:11434]`
**Warning signs:** Empty `.response`, or the CLI dropping into an interactive prompt.

### Pitfall 3: Page-marker off-by-one / blank-page drift
**What goes wrong:** The per-page loop emits markers that don't line up with the model's page numbering, breaking `#p` resolution.
**Why it happens:** Skipping blank/failed pages, or 0- vs 1-indexing between `pdftoppm -f N` and the marker `N`.
**How to avoid:** Drive both the render index and the marker from the same 1-based loop variable; always emit `<!-- page: N -->` even for an empty page (so slices stay aligned). Verify against `pdfinfo` page count.
**Warning signs:** `audit-claims.sh` returns `insufficient-locator` for `#p` on a marked source; total markers ≠ `pdfinfo` page count.

### Pitfall 4: VLM hallucination on degraded scans treated as high-confidence
**What goes wrong:** Single-pass VLM text from a bad scan is plausible-but-wrong, but ingested as `sourced`/`direct` with no flag.
**Why it happens:** olmOCR (a VLM-OCR model) inherits the confident-failure mode documented in `vlm-ocr-hallucination.md` — it emits fluent wrong text rather than flagging unreadability.
**How to avoid:** The D-08 tiered policy. Human flags degraded at acquisition → `tentative` page-level default + mandatory N-page spot-verification (read against the co-located PDF or via `audit-claims.sh`), upgradeable to `sourced` only after verification. `support_type` stays `direct` (D-09 — extraction, not derivation).
**Warning signs:** A scanned-source page with `epistemic_status: sourced` and no verification record.

### Pitfall 5: Neutrality leak in template-public surfaces
**What goes wrong:** A real vault slug/term lands in `pdf-ingestion.md` / `frontmatter.md` / `ingest.md` / AGENTS.md / `bin/`.
**Why it happens:** Reaching for a "concrete example" using real content.
**How to avoid:** Use placeholders (`<source-id>`, `<YYYY-MM-DD-slug>`, `<page-title>`). Public tool names olmOCR/Ollama/poppler are permitted. `bin/check-neutrality.sh` is the backstop, not the primary defense. The validation ingest itself (`sources/`, `wiki-cloud/`) is NOT template-public — real slugs are fine there.
**Warning signs:** `bin/check-neutrality.sh` non-zero exit on the routing/doc commit.

### Pitfall 6: CLAUDE.md drift on the routing-table commit
**What goes wrong:** AGENTS.md gets the new routing row but CLAUDE.md isn't synced; pre-commit hook blocks or CI fails.
**How to avoid:** `bash bin/sync-claude.sh && git add CLAUDE.md` before committing the routing change (Phase 09.1-02 precedent collapses the 2-attempt path to 1). `[CITED: STATE Phase 09.1-02 accumulated context]`

## Code Examples

### Conditional PDF-field lint check (shape, mirrors L1091 research-report gate)
```python
# Source: bin/lint.sh, inside `if fm.get('type') == 'source':` after source_type enum check
# D-07: when original_asset points at a *.pdf, the extraction fields are required.
oa = fm.get('original_asset', '')
if isinstance(oa, str) and oa.lower().endswith('.pdf'):
    PDF_EXTRACTION_FIELDS = ['extraction_tool', 'extraction_model',
                             'extraction_date', 'original_asset']
    missing_pdf = [f for f in PDF_EXTRACTION_FIELDS if not fm.get(f)]
    if missing_pdf:
        add_finding('error', 'yaml', rel,
                    f'PDF source (original_asset=*.pdf) missing extraction fields: {missing_pdf}')
```
*(Field-name spelling and whether `extraction_date` collapses into `ingested_at` are Claude's discretion per CONTEXT — confirm before locking.)*

### New flat frontmatter fields (frontmatter.md Source Summary block, D-06)
```yaml
# Added to the Source Summary Additional Fields block (~L58-75 of frontmatter.md)
# Present only when the source was acquired from a PDF (original_asset points at the co-located PDF).
extraction_tool: olmocr           # generic: the extractor that emitted the page markers
extraction_model: "richardyoung/olmocr2:7b-q8"
extraction_date: YYYY-MM-DD       # discretion: may collapse into ingested_at if redundant
original_asset: original.pdf      # relative path to the co-located PDF in the bundle
```

### pdf-extract.sh core loop (assembly — VERIFIED tooling, full model call not run)
```bash
# Source: design from verified primitives (pdftoppm 24.02.0, Ollama /api/generate, jq 1.7)
PAGES=$(pdfinfo "$PDF" | awk '/^Pages:/{print $2}')
: > "$OUT"
for N in $(seq 1 "$PAGES"); do
  pdftoppm -png -r "${DPI:-150}" -f "$N" -l "$N" "$PDF" "$TMP/page" >/dev/null
  PNG=$(ls "$TMP"/page-*.png | head -1)          # pdftoppm zero-pads; pick the single render
  B64=$(base64 -w0 "$PNG")
  TEXT=$(curl -s http://localhost:11434/api/generate -d "$(jq -n \
    --arg m "$MODEL" --arg p "$PROMPT" --arg img "$B64" \
    '{model:$m, prompt:$p, images:[$img], stream:false}')" | jq -r '.response')
  printf '<!-- page: %d -->\n%s\n\n' "$N" "$TEXT" >> "$OUT"
  rm -f "$PNG"
done
```
*(Exact CLI surface — flags, output path, error handling, poppler dependency note — is Claude's discretion per CONTEXT.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Traditional 3-stage OCR (Tesseract/PaddleOCR) | VLM-OCR single-forward-pass (olmOCR 2 etc.) | 2025-2026 | VLM-OCR leads OmniDocBench; olmOCR 2 is the strongest self-hosting pick per the wiki's own overview. `[CITED: wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md]` |
| Trust single-pass VLM output | Guardrail degraded/scanned pages (flag low-confidence, cross-check, or lower epistemic default) | NeurIPS 2025 hallucination finding | Directly motivates the D-08 tiered policy. `[CITED: wiki-cloud/concepts/vlm-ocr-hallucination.md]` |

**Deprecated/outdated:** None applicable to the locked decisions. The wiki overview notes the SOTA "moves monthly" and per-page prices/leaderboards are volatile — but the phase commits to a generic contract (any marker-emitting extractor) with olmOCR 2 as the *named instance*, so leaderboard drift does not invalidate the design.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A minimal per-page prompt suffices because the model carries a built-in OCR system prompt | Standard Stack / Code Examples | Low — verified the model has an OCR system prompt; worst case the runbook tunes the prompt on the real artifact (already a planned task). |
| A2 | 150 DPI (pdftoppm default) + num_ctx 4096 is an adequate starting point for a clean born-digital PDF | Standard Stack | Low — these are tunable; CONTEXT explicitly scopes the validation to a clean born-digital ~5-30pg PDF. Plan should include a "tune on real artifact" task. |
| A3 | LINT_VERSION 1.10.0 is the correct bump (MINOR, additive conditional check) | D-07 / pitfalls | Low — current is 1.9.1; the semver rule (MINOR on non-breaking additions) is documented at lint.sh L10-12. Confirm exact number at implementation. |

**Note:** The full olmOCR model inference call was NOT executed during research (to avoid a slow local GPU/CPU run); the *endpoint reachability*, *model presence*, *vision capability*, and *every other tool* were verified. The first real model call is correctly the PDF-04 validation task (gated on the user-supplied PDF).

## Open Questions

1. **Does `extraction_date` add value over `ingested_at`?**
   - What we know: CONTEXT D-06 lists `extraction_date`; the discretion section flags possible collapse into `ingested_at`.
   - What's unclear: whether acquisition and ingest happen far enough apart to warrant two dates.
   - Recommendation: Default to collapsing into `ingested_at` unless the runbook envisions a multi-day acquire→ingest gap; keeps the field set minimal. Confirm in planning/discuss.

2. **N (spot-verification page count) and the upgrade rule wording.**
   - What we know: D-08 mandates N-page spot-verify for degraded input, `tentative` → upgradeable.
   - What's unclear: exact N and selection method (random? first/last/middle?).
   - Recommendation: Small fixed N (e.g., 3) with a documented selection heuristic; since the validation artifact is clean born-digital, tier-2 is documented-but-not-exercised this phase — so wording matters more than tuning.

3. **Does the schema change warrant a reflect-tier DR?**
   - What we know: Phase 18/19 authored DRs for schema changes; D-discretion permits one.
   - Recommendation: Yes — a `schema-update` trigger_type DR in `wiki-cloud/decisions/` capturing "PDF as format-orthogonal sub-case + first local-model-invoking script" is consistent with precedent and aids future Phase 21 (video) which inherits the pattern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ollama server | PDF-01 extraction | ✓ (server up, reachable) | 0.20.2 | — |
| `richardyoung/olmocr2:7b-q8` | PDF-01 named instance | ✓ (pulled, vision-capable) | 7b-q8 / Qwen2.5-VL-7B | generic contract permits any marker-emitting extractor |
| `pdftoppm` (poppler) | page rendering | ✓ | 24.02.0 | `pdf2image` (adds Python dep) |
| `pdfinfo` (poppler) | page count | ✓ | 24.02.0 | parse `pdftoppm` output |
| `jq` | JSON assembly | ✓ | 1.7 | python3 json.dumps |
| `base64` | image encoding | ✓ | (coreutils) | python3 base64 |
| `python3` | lint check, fallback | ✓ | 3.12.3 | — |
| User-supplied clean born-digital cloud-safe PDF (~5-30pg) | PDF-04 validation | ✗ (supplied at execution) | — | **human checkpoint, autonomous: false** (D-12) |

**Missing dependencies with no fallback:** None for the convention/tooling work. PDF-04 requires the user-supplied PDF — a `autonomous: false` checkpoint, not a blocker to the rest of the phase.

**Missing dependencies with fallback:** None blocking.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in config.json — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash test scripts under `tests/phase-NN/` (per-phase `run.sh` aggregator + `lib.sh`); pattern from Phases 07-11 |
| Config file | none — convention is `tests/phase-20/run.sh` + `tests/phase-20/lib.sh` (mirror an existing phase dir) |
| Quick run command | `bash tests/phase-20/run.sh` (after Wave 0 creates it) |
| Full suite command | run each `tests/phase-*/run.sh` (lint + neutrality + sync gates are the cross-cutting checks) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PDF-01 | `bin/pdf-extract.sh` emits `<!-- page: N -->`-marked Markdown; marker count == page count | integration (small fixture PDF) | `bash tests/phase-20/test_pdf_extract_markers.sh` | ❌ Wave 0 |
| PDF-01 | runbook + routing row present; `bin/lint.sh --category routing` green; `bin/sync-claude.sh --check` clean | smoke | `bin/lint.sh --category routing && bin/sync-claude.sh --check` | ✅ (lint/sync exist) |
| PDF-02 | conditional lint: `original_asset=*.pdf` without `extraction_*` ⇒ error; with them ⇒ clean | unit (fixture frontmatter) | `bash tests/phase-20/test_pdf_extraction_fields.sh` | ❌ Wave 0 |
| PDF-02 | `frontmatter.md` documents the 4 fields; `pdf-ingestion.md` authoritative file exists | smoke | `bash tests/phase-20/test_pdf_convention_doc.sh` | ❌ Wave 0 |
| PDF-03 | `pdf-ingestion.md` contains tiered epistemic policy (degraded→tentative+spot-verify; clean→sourced) | content grep | `bash tests/phase-20/test_pdf_epistemic_tiers.sh` | ❌ Wave 0 |
| PDF-04 | `bin/ingest.sh --asset` co-locates PDF alongside `source.md` in the bundle dir | integration (fixture) | `bash tests/phase-20/test_ingest_asset_flag.sh` | ❌ Wave 0 |
| PDF-04 | real validation ingest: wiki pages with `#p` provenance; `audit-claims.sh` resolves them | manual + audit (human checkpoint) | `bin/audit-claims.sh` on the ingested source | partial (human-gated) |
| (cross) | full `bin/lint.sh` green at every commit (no red between commits) | smoke | `bin/lint.sh` | ✅ |
| (cross) | `bin/check-neutrality.sh` clean on template-public edits | smoke | `bin/check-neutrality.sh` | ✅ |

### Sampling Rate
- **Per task commit:** `bin/lint.sh` (or `--category` subset) + relevant `tests/phase-20/test_*.sh`
- **Per wave merge:** `bash tests/phase-20/run.sh` + `bin/sync-claude.sh --check` + `bin/check-neutrality.sh`
- **Phase gate:** full `bin/lint.sh` green + `tests/phase-20/run.sh` green before `/gsd-verify-work`; PDF-04 human checkpoint signed off.

### Wave 0 Gaps
- [ ] `tests/phase-20/run.sh` + `tests/phase-20/lib.sh` — aggregator + helpers (clone from an existing phase dir, e.g. `tests/phase-19/`)
- [ ] `tests/phase-20/test_pdf_extract_markers.sh` — covers PDF-01 (needs a tiny committed fixture PDF or a generated one; a 1-2 page born-digital fixture)
- [ ] `tests/phase-20/test_pdf_extraction_fields.sh` — covers PDF-02 (fixture frontmatter, `WIKI_ROOT` override pattern from prior phases)
- [ ] `tests/phase-20/test_pdf_convention_doc.sh` — covers PDF-02 (authoritative file + frontmatter doc)
- [ ] `tests/phase-20/test_pdf_epistemic_tiers.sh` — covers PDF-03 (content assertions)
- [ ] `tests/phase-20/test_ingest_asset_flag.sh` — covers PDF-04 `--asset` (fixture, no model call)
- [ ] Note: the model-dependent extraction test should use a *tiny* fixture or be marked slow/optional so CI without a GPU/model isn't blocked — gate the live-model assertion behind a "model available" probe (mirror Phase 13.1 `blocked-on-host-runtime` precedent for environment-dependent checks).

## Project Constraints (from CLAUDE.md)

- **Routing discipline:** AGENTS.md is the router; each linked file is authoritative for its own sections. The new `pdf-ingestion.md` gets a routing-table row; no conventions in files outside AGENTS.md/the routed files.
- **Frontmatter:** snake_case field names; ISO 8601 dates; no wikilinks in frontmatter; no provenance blobs/nested blocks in frontmatter (D-06 flat fields comply).
- **Wikilinks:** body links MUST be `[[id|Exact Title]]` piped form; link on first mention only; never bare `[[Title]]`.
- **Commits:** conventional prefixes — `schema:` for the convention/routing/frontmatter edits, `lint(scope):` for the lint-check bump, `ingest(slug):` for the validation ingest. One commit per logical operation (a 15-file ingest is one commit).
- **Structured operations:** the registry-row finalization is an UPDATE to `source-types.md` — run `bin/validate-op.sh` if treating it as a formal solo op; otherwise it rolls under the `schema:` commit.
- **Privacy/neutrality:** template-public surfaces use placeholders; public tool names allowed; `sources/` is cloud-safe-only (verify the PDF-04 artifact is cloud-safe before ingest, D-12); `bin/check-privacy.sh` + `bin/check-neutrality.sh` are pre-commit gates.
- **Navigation:** progressive disclosure — index → TL;DR/Key Facts → Detail. The lazy-load argument (D-01) is a direct application of this rule.

## Sources

### Primary (HIGH confidence)
- `[VERIFIED: local probe 2026-06-11]` — Ollama 0.20.2, `richardyoung/olmocr2:7b-q8` (9.5 GB, vision-capable, OCR system prompt, Qwen2.5-VL-7B/Q8_0/128k ctx), poppler 24.02.0 (`pdftoppm`/`pdfinfo`, `-png -r -f -l`), jq 1.7, base64, python3 3.12.3, Ollama server reachable at localhost:11434, `ollama run` has no scriptable image positional.
- `schema/reference/provenance.md` — `#p` locator + `<!-- page: N -->` marker grammar, slice semantics (exclusive upper bound), graceful degradation, D-07 helper-later deferral.
- `schema/reference/source-types.md` — 5-dimension contract, decision rule, provisional `pdf` registry row (§4), research-report worked instance (§5-6 structure to mirror).
- `schema/reference/frontmatter.md` — Source Summary Additional Fields block (edit target).
- `bin/lint.sh` — LINT_VERSION 1.9.1 (L13), `SOURCE_EXTRA_FIELDS` (L408), source-summary conditional validation (~L1091), `routing` category (L2413), severity map.
- `bin/ingest.sh` — arg parsing (L161), placement logic (L300-313), "no LLM calls" charter.
- `bin/audit-claims.sh` — `#p` resolution `slice_pages()` (L422-477), `PAGE_MARK_RE`, `insufficient-locator`.
- `bin/sync-claude.sh` — `cmp -s` byte-equality.
- `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md` — olmOCR 2 SOTA recommendation (the D-04 citation source).
- `wiki-cloud/concepts/vlm-ocr-hallucination.md` — the failure mode the D-08 tiered policy defends against.

### Secondary (MEDIUM confidence)
- `[CITED: ollama.com/richardyoung/olmocr2:7b-q8]` — model = `allenai/olmOCR-2-7B-1025`, Qwen2.5-VL-7B OCR fine-tune, markdown output with equations/tables.

### Tertiary (LOW confidence)
- None load-bearing. olmOCR-Bench score (82.4) and leaderboard positions cited only as wiki-overview-sourced context, not as design dependencies.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every tool verified present and reachable via direct local probe.
- Architecture: HIGH — edit surfaces read directly; all primitives (locators, lint conditional pattern, ingest scaffolding) inspected in source.
- Pitfalls: HIGH — sequencing/neutrality pitfalls drawn from Phase 19 lessons in CONTEXT + STATE; `ollama run` pitfall verified against `--help`.
- Pipeline mechanics: HIGH for tooling; MEDIUM for prompt/DPI/num_ctx tuning (deliberately deferred to the real-artifact validation task).

**Research date:** 2026-06-11
**Valid until:** 2026-07-11 (stable — convention/tooling phase; olmOCR leaderboard volatility does not affect the generic-contract design)
