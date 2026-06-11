# Phase 20: PDF Ingestion - Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 11 (2 new, 9 modified/extended)
**Analogs found:** 10 / 11 (1 genuinely net-new: `bin/pdf-extract.sh`)

This is a documentation/convention-engineering phase with thin shell glue. Almost every
file has a strong in-repo analog because Phase 19 built the exact machinery this phase
re-applies (the source-type contract, the registry, the routing/lint/sync wiring). The
planner should treat each file as "copy the Phase-19 shape, swap in PDF specifics."

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/reference/pdf-ingestion.md` | config (authoritative reference doc) | transform (convention spec) | `schema/reference/source-types.md` §5–6 (research-report worked instance) | exact (role + structure) |
| `schema/reference/source-types.md` | config (registry/contract) | transform | self (§4 provisional `pdf` row already present) | in-place edit |
| `schema/reference/frontmatter.md` | config (field spec) | transform | self (Source Summary Additional Fields block, L58–75) | in-place edit |
| `schema/workflows/ingest.md` | config (workflow doc) | transform | self (Pass 0, L17–18; research-report sub-bullet is the precedent) | in-place edit |
| `AGENTS.md` | config (router) | transform | self (routing table, L45–63) | in-place edit |
| `CLAUDE.md` | config (byte-mirror) | transform | self (synced via `bin/sync-claude.sh`) | derived (do not hand-edit) |
| `bin/lint.sh` | utility (validator) | request-response (file→findings) | self (L1091 source-summary conditional block) | exact (same function, parallel branch) |
| `bin/ingest.sh` | utility (CLI) | file-I/O | self (arg parse L161–199; placement L283–313) | exact (extend, don't replace) |
| `bin/pdf-extract.sh` | utility (CLI / acquisition glue) | file-I/O + request-response (per-page HTTP) | `bin/audit-claims.sh` (header/structure); `bin/ingest.sh` (arg-parse skeleton) | role-match (no model-calling script exists) |
| `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` | decision record | event-driven (schema change) | `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` | exact (same trigger_type, same domain) |
| `tests/phase-20/` (run.sh, lib.sh, test_*.sh) | test | request-response | `tests/phase-18/` (run.sh + lib.sh aggregator pattern) | role-match |

## Pattern Assignments

### `schema/reference/pdf-ingestion.md` (NEW — config/reference, transform)

**Analog:** `schema/reference/source-types.md` (the whole file is the structural model; §5–6 is the worked-instance section to mirror for the convention half).

This is the one genuinely-authored doc. Copy the authoritative-reference header style and the
worked-instance section structure from source-types.md.

**Header pattern** (source-types.md L1–6):
```markdown
# PDF Ingestion

> Agent-authoritative reference for the PDF-as-sub-case convention and the
> PDF→Markdown acquisition runbook.
> The AGENTS.md routing table points here. If you find a discrepancy between this
> file and AGENTS.md, this file wins.
```

**Worked-instance section structure to mirror** (source-types.md §5 "research-report —
Worked Secondary Instance", L55–96): the research-report section walks Classification →
Provenance → Epistemic default → Ingest checklist. `pdf-ingestion.md` mirrors this with:
Classification (parent type, sub-case) → Frontmatter fields → `#p` locator usage →
Tiered epistemic policy (D-08) → Acquisition runbook → Ingest checklist.

**Neutrality (MUST):** template-public file. Use placeholders `<source-id>`,
`<YYYY-MM-DD-slug>`, `<page-title>` (CLAUDE.md L171 MUST-NOT list). Public tool names
olmOCR / Ollama / poppler ARE permitted (CONTEXT D-04). The model tag
`richardyoung/olmocr2:7b-q8` is a public tag — allowed.

**Runbook command shape** (from RESEARCH.md Code Examples — verified primitives): the
pdftoppm→base64→`/api/generate`→marker loop. Cite the wiki's own SOTA overview
(`wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md`) as the recommendation
source per D-04.

---

### `schema/reference/source-types.md` (MODIFIED — config/registry, transform)

**Analog:** self — the provisional `pdf` row already exists at §4, L49.

**Current provisional row** (L49) to finalize:
```markdown
| `pdf` | sub-case of `article` or `paper` (provisional) | Acquisition (provisional) | (Phase 20) | Page locators (`#p`) already exist; ... |
```

**Finalize to** (format-orthogonal verdict, D-05 — do NOT lock to a single parent type;
Convention Doc column points at the new file per D-02):
```markdown
| `pdf` | sub-case (format-orthogonal; any parent type) | Acquisition (always); Epistemic Default (degraded input only) | `schema/reference/pdf-ingestion.md` | ... |
```

The Retro-fit Table at §3 (L33–41) is the dimension-vocabulary the verdict's "Dimensions
That Change" column must speak. The §4 registry header note (L45) already names "Phases 20
and 21 finalize the pdf and video rows" — no structural change, fill the row only.

**Structured op:** this is an UPDATE to source-types.md. Per CLAUDE.md §9, optionally run
`bin/validate-op.sh UPDATE schema/reference/source-types.md`; otherwise it rolls under the
`schema:` commit.

---

### `schema/reference/frontmatter.md` (MODIFIED — config/field-spec, transform)

**Analog:** self — the Source Summary Additional Fields block at L58–73.

**Insertion point** (L62–73, the `type: source` YAML block):
```yaml
path: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md
url: "https://..."
content_hash: "sha256:abc123..."
ingested_at: YYYY-MM-DD
source_type: article|paper|transcript|journal|data|image|research-report
```

**Add the 4 flat PDF fields** (D-06; conditional/present-only-for-PDF-sources) directly
after, mirroring the existing flat snake_case style:
```yaml
# Present only when the source was acquired from a PDF.
extraction_tool: olmocr
extraction_model: "richardyoung/olmocr2:7b-q8"
extraction_date: YYYY-MM-DD       # discretion: may collapse into ingested_at if redundant
original_asset: original.pdf      # relative path to the co-located PDF in the bundle
```

**Discretion flag:** RESEARCH Open Question 1 recommends collapsing `extraction_date` into
`ingested_at` unless a multi-day acquire→ingest gap is envisioned. Confirm at plan time;
if collapsed, drop the field from BOTH frontmatter.md and the lint check.

**Field-descriptions table** (L37–56) is the other place each field is documented row-wise —
match that pattern if adding prose descriptions.

---

### `schema/workflows/ingest.md` (MODIFIED — config/workflow, transform)

**Analog:** self — Pass 0 classification step (L17) and the research-report sub-bullet
(L18) are the exact precedent for adding a sub-case pointer.

**Pattern to copy** (L18, the research-report Pass-0 sub-bullet):
```markdown
   - **research-report:** AI-synthesized or third-party aggregated reports ... See `schema/reference/source-types.md`.
```

**Add a parallel PDF sub-bullet** under step 3: PDF classifies to its content's parent type
(article/paper/...), then layers the PDF convention; pointer to
`schema/reference/pdf-ingestion.md`. Do NOT introduce a `pdf` source_type (anti-pattern,
D-05). Keep it a one-line pointer (lazy-load discipline, D-01).

---

### `AGENTS.md` + `CLAUDE.md` (MODIFIED — config/router + byte-mirror)

**Analog:** self — the routing table (AGENTS.md / CLAUDE.md L45–63).

**Pattern to copy** (existing routing rows, CLAUDE.md L50):
```markdown
> | Adding/evaluating a new source type | `schema/reference/source-types.md` |
```

**Add a new row** for `pdf-ingestion.md` (D-03; Phase 19 D-02 precedent — every
authoritative `schema/reference/*.md` gets a row):
```markdown
> | Ingesting a PDF source (acquisition runbook + sub-case convention) | `schema/reference/pdf-ingestion.md` |
```

**CRITICAL sequencing** (RESEARCH Pitfall 6): edit AGENTS.md, then
`bash bin/sync-claude.sh && git add CLAUDE.md` BEFORE committing — never hand-edit
CLAUDE.md. The `routing` lint category (lint.sh ~L2413) validates the new row points at an
existing file, so `pdf-ingestion.md` must exist in the SAME commit. Pre-commit gates on
this commit: `sync-claude --check`, `check-neutrality.sh`, `gen-skills.sh --check`.

---

### `bin/lint.sh` (MODIFIED — utility/validator, request-response)

**Analog:** self — the source-summary conditional block at L1091–1109 is the exact gate
shape to parallel.

**LINT_VERSION bump** (L13): `1.9.1` → `1.10.0` (MINOR, additive conditional check;
semver rule documented L10–12). Confirm exact number at implementation (RESEARCH A3).

**Core pattern — existing conditional source-field check** (L1091–1109):
```python
        # Source-specific fields
        if fm.get('type') == 'source':
            missing_src = [f for f in SOURCE_EXTRA_FIELDS if f not in fm]
            if missing_src:
                add_finding('error', 'yaml', rel, f'Source page missing fields: {missing_src}')
            cs = fm.get('compilation_status')
            if cs and cs not in VALID_COMPILATION:
                add_finding('error', 'yaml', rel, f"Invalid compilation_status: '{cs}'")
            st = fm.get('source_type', '')
            ...
```

**Add a PARALLEL conditional branch** inside this same `if fm.get('type') == 'source':`
block (RESEARCH Pattern 3), gated on `original_asset` ending `.pdf`:
```python
            # D-07: PDF sources (original_asset=*.pdf) require the extraction fields.
            oa = fm.get('original_asset', '')
            if isinstance(oa, str) and oa.lower().endswith('.pdf'):
                PDF_EXTRACTION_FIELDS = ['extraction_tool', 'extraction_model',
                                         'extraction_date', 'original_asset']
                missing_pdf = [f for f in PDF_EXTRACTION_FIELDS if not fm.get(f)]
                if missing_pdf:
                    add_finding('error', 'yaml', rel,
                                f'PDF source (original_asset=*.pdf) missing '
                                f'extraction fields: {missing_pdf}')
```

**ANTI-PATTERN (RESEARCH Pitfall 1):** do NOT append the PDF fields to
`SOURCE_EXTRA_FIELDS` (L408) — that list is UNCONDITIONAL and would fire on every existing
source page. The PDF requirement is conditional, so it gets its own branch.

**ANTI-PATTERN:** do NOT add `pdf` to `VALID_SOURCE_TYPES` (L399–400) — PDF is a sub-case,
not an enum value (D-05). The set stays at 7 values.

**Data-then-check ordering (RESEARCH Pattern 2 / Phase 19 lesson):** the gate is on
`original_asset → *.pdf`. Every existing source lacks `original_asset` → untouched → repo
stays green. The check can land before the validation ingest without going red.

---

### `bin/ingest.sh` (MODIFIED — utility/CLI, file-I/O)

**Analog:** self — arg-parse loop (L161–199) and file-placement (L283–313).

**Arg-parse pattern to copy** (L167–175, the `--slug` case — value-taking flag with arity
check):
```bash
        --slug)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --slug requires a value" >&2
                exit 1
            fi
            SLUG_OVERRIDE="$2"
            SLUG_PROVIDED=1
            shift 2
            ;;
```

**Add an `--asset <path>` case** in the same `while`/`case` loop (D-11), mirroring `--slug`:
capture `ASSET_FILE="$2"; shift 2`. Declare `ASSET_FILE=""` next to the other state vars
(L155–159).

**Placement pattern to extend** (L281–313): after `mkdir -p "${DEST_DIR}"` and the
existing `source${EXT}` copy, co-locate the asset into the SAME bundle dir:
`cp "$ASSET_FILE" "${DEST_DIR}/$(basename "$ASSET_FILE")"`. The existing dated-dir +
content_hash + bundle naming (L270–281) composes with this — reuse, don't reimplement
(RESEARCH "Don't Hand-Roll").

**Charter note (D-10):** ingest.sh's "no LLM API calls, file-system bookkeeping only"
charter stays intact — the asset copy is pure file I/O. Model calls live ONLY in the
separate `bin/pdf-extract.sh`.

---

### `bin/pdf-extract.sh` (NEW — utility/CLI, file-I/O + per-page HTTP)

**Analog:** no model-calling script exists (this is the first). Closest structural analogs:
- `bin/audit-claims.sh` header (L1–38) — the authoritative `#!/usr/bin/env bash` +
  `set -euo pipefail` + version-var + `usage()` + scope-comment house style.
- `bin/ingest.sh` (L150–199) — the `while`/`case` arg-parse skeleton.

**Header pattern to copy** (audit-claims.sh L1–11, 36–38):
```bash
#!/usr/bin/env bash
# bin/pdf-extract.sh -- PDF→Markdown acquisition glue (Phase 20).
#
# Renders each PDF page to PNG (pdftoppm), OCRs it via a local Ollama VLM, and
# assembles <!-- page: N --> page markers. The FIRST repo script that invokes a
# local model: ingest.sh's "no LLM calls" charter is per-script, not repo-wide.
set -euo pipefail

EXTRACT_VERSION="0.1.0"
```

**Core loop pattern** (RESEARCH Code Examples — VERIFIED primitives: pdftoppm 24.02.0,
Ollama `/api/generate`, jq 1.7):
```bash
PAGES=$(pdfinfo "$PDF" | awk '/^Pages:/{print $2}')
: > "$OUT"
for N in $(seq 1 "$PAGES"); do
  pdftoppm -png -r "${DPI:-150}" -f "$N" -l "$N" "$PDF" "$TMP/page" >/dev/null
  PNG=$(ls "$TMP"/page-*.png | head -1)
  B64=$(base64 -w0 "$PNG")
  TEXT=$(curl -s http://localhost:11434/api/generate -d "$(jq -n \
    --arg m "$MODEL" --arg p "$PROMPT" --arg img "$B64" \
    '{model:$m, prompt:$p, images:[$img], stream:false}')" | jq -r '.response')
  printf '<!-- page: %d -->\n%s\n\n' "$N" "$TEXT" >> "$OUT"
  rm -f "$PNG"
done
```

**ANTI-PATTERN (RESEARCH Pitfall 2):** do NOT use `ollama run MODEL PROMPT` — it has no
scriptable image positional (interactive REPL only). Use the HTTP `/api/generate` endpoint
with `images: [<base64>]`, `stream: false`.

**ANTI-PATTERN (RESEARCH Pitfall 3):** drive the render index AND the marker from the SAME
1-based loop var; always emit `<!-- page: N -->` even for empty pages so `#p` slices stay
aligned. Verify total markers == `pdfinfo` page count.

**Marker grammar (do NOT reinvent):** `<!-- page: N -->` is fully specified in
`provenance.md` L37–58 (slice semantics, exclusive upper bound, graceful degradation). This
script only PRODUCES markers — zero grammar change.

**Neutrality:** template-public (`bin/`). Placeholders for any example paths; olmOCR /
Ollama / poppler tool names permitted. Document the poppler/Ollama/jq dependency list as a
prerequisites note (discretion on placement, CONTEXT).

---

### `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` (NEW/OPTIONAL — decision record)

**Analog:** `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` (Phase 19's
schema-change DR — same `trigger_type`, same domain).

**Frontmatter pattern to copy** (dr-2026-06-10 L1–24):
```yaml
---
id: dr-2026-06-11-pdf-ingestion
title: "PDF as Format-Orthogonal Source Sub-Case + First Local-Model Acquisition Script"
type: decision
status: active
summary: "..."
created_at: 2026-06-11
updated_at: 2026-06-11
sources: []
epistemic_status: sourced
tags: [meta, schema]
domains: [wiki-infrastructure]
supersedes: null
superseded_by: null
aliases: [dr-2026-06-11-pdf-ingestion]
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---
```

**Body structure to mirror** (dr-2026-06-10 has `## TL;DR` → `## Decision` with numbered
coupled deliverables). RESEARCH Open Question 3 recommends authoring this DR — it aids
Phase 21 (video), which inherits the format-orthogonal pattern. Decision-record authoring
is Claude's discretion (CONTEXT); author if the schema edits warrant it (Phase 18/19
precedent says yes).

**Decision-page lint:** `trigger_type` must be in the valid set (lint.sh L1113:
`schema-update` qualifies); `affected_pages` must be a YAML list (L1119–1123).

---

### `tests/phase-20/` (NEW — tests)

**Analog:** `tests/phase-18/` (run.sh aggregator + lib.sh helpers — the established
per-phase test convention, clonable directly).

**Aggregator pattern to copy** (phase-18/run.sh L1–30):
```bash
#!/usr/bin/env bash
# tests/phase-20/run.sh -- Phase 20 PDF Ingestion test aggregator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
PASS=0; FAIL=0
run_test() {
    local name="$1"
    if bash "$SCRIPT_DIR/$name" > /dev/null 2>&1; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name"; FAIL=$((FAIL+1))
    fi
}
run_test test_pdf_extraction_fields.sh
...
```

**lib.sh helper pattern to copy** (phase-18/lib.sh — REPO_ROOT resolver + `assert_exit_code`):
```bash
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
assert_exit_code() { ... }
export -f assert_exit_code
```

**Test files needed** (RESEARCH Wave 0 Gaps, §Test Map): `test_pdf_extraction_fields.sh`
(fixture-frontmatter lint unit, `WIKI_ROOT` override pattern), `test_pdf_convention_doc.sh`,
`test_pdf_epistemic_tiers.sh` (content greps), `test_ingest_asset_flag.sh` (fixture, no
model call), `test_pdf_extract_markers.sh` (tiny fixture PDF; gate the live-model assertion
behind a "model available" probe — mirror Phase 13.1 `blocked-on-host-runtime` precedent so
GPU-less CI isn't blocked).

---

## Shared Patterns

### Authoritative-reference-file + registry-pointer ("A + lean B", D-01/D-02)
**Source:** `schema/reference/source-types.md` (full file is the model; §4 registry row +
§5 worked instance are the two halves).
**Apply to:** `pdf-ingestion.md` (the "A" — self-contained authoritative doc) and the
`source-types.md` §4 row (the "lean B" — one-row pointer, no content duplication). Phase 21
(video) inherits this exact shape.

### Routing-table wiring (every `schema/reference/*.md` gets a row)
**Source:** AGENTS.md / CLAUDE.md routing table (L45–63); `bin/sync-claude.sh` (`cmp -s`
byte-equality).
**Apply to:** the `pdf-ingestion.md` row. ALWAYS `bin/sync-claude.sh && git add CLAUDE.md`
before commit; never hand-edit CLAUDE.md (RESEARCH Pitfall 6).

### Conditional source-field lint gate
**Source:** `bin/lint.sh` L1091–1109 (the `if fm.get('type') == 'source':` block — the
`source_type` enum and `compilation_status` checks are the parallel-branch precedent).
**Apply to:** the new `original_asset → *.pdf` conditional. Same function, new branch.
Never make it unconditional (Pitfall 1).

### Data-then-check ordering (never lint red between commits)
**Source:** Phase 19 lesson (CONTEXT Established-Patterns; RESEARCH Pattern 2).
**Apply to:** the lint-version bump + check. The `*.pdf`-gated branch lands green because no
existing source carries `original_asset`; the validation ingest authors the compliant
fields in the same logical operation.

### Template-public neutrality
**Source:** CLAUDE.md L171 MUST-NOT list; `bin/check-neutrality.sh` (backstop).
**Apply to:** `pdf-ingestion.md`, `frontmatter.md`, `ingest.md`, AGENTS.md/CLAUDE.md,
`bin/pdf-extract.sh`. Placeholders (`<source-id>`, `<YYYY-MM-DD-slug>`, `<page-title>`);
public tool names olmOCR/Ollama/poppler permitted. The validation ingest itself
(`sources/`, `wiki-cloud/`) is NOT template-public — real slugs fine there.

### Decision-record authoring for schema changes
**Source:** `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` (Phase 19
precedent; `trigger_type: schema-update`).
**Apply to:** the optional `dr-2026-06-11-pdf-ingestion.md`.

### Don't-hand-roll (reuse verified primitives)
**Source:** RESEARCH "Don't Hand-Roll" table.
**Apply to:** `#p` slice resolution (`bin/audit-claims.sh` `slice_pages()` L422–477 — read-
only spot-verification, no new machinery); `<!-- page: N -->` grammar (`provenance.md`
L37–58); PDF rasterization (`pdftoppm`); JSON escaping (`jq -n`); dated-dir/content_hash/
bundle naming (`bin/ingest.sh`); routing integrity (`bin/lint.sh` `routing` category).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `bin/pdf-extract.sh` (model-calling portion) | utility | per-page HTTP to local model | First repo script to invoke a local model via `/api/generate`. The bash skeleton (header, arg-parse, `set -euo pipefail`) copies `bin/audit-claims.sh` + `bin/ingest.sh`, but the render→infer→assemble loop is net-new "thin glue" the milestone explicitly permits. Pattern source is RESEARCH Code Examples (verified primitives), not an existing analog. |

## Metadata

**Analog search scope:** `schema/reference/`, `schema/workflows/`, `bin/`,
`wiki-cloud/decisions/`, `tests/phase-*/`, AGENTS.md/CLAUDE.md routing table.
**Files scanned (read):** source-types.md, frontmatter.md, provenance.md, ingest.md,
lint.sh (L1–20, 395–418, 1075–1132), ingest.sh (L150–199, 270–319), audit-claims.sh
(L1–40), dr-2026-06-10-source-type-contract.md, tests/phase-18/{run.sh,lib.sh}, CLAUDE.md.
**Pattern extraction date:** 2026-06-11
