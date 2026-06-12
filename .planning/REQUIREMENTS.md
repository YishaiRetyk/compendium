# Requirements: LLM Wiki Compiler — Milestone v1.3 Source Ingestion

**Defined:** 2026-06-10
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.

## v1.3 Requirements

Requirements for milestone v1.3 Source Ingestion. Each maps to roadmap phases.

Design lineage: `.planning/seeds/research-report-ingest.md` (design LOCKED — RPT category implements it), `.planning/seeds/primary-source-type-extensions.md` (OPEN — VID category resolves its Candidate B; repos/Candidate A stay backlog), `.planning/notes/2026-05-31-milestone-grouping-proposal.md` → "Source Ingestion" cluster (SI.1 = EXT, SI.2 = RPT, SI.4 = VID; PDF is an anticipated SI.n instance), and `.planning/todos/pending/2026-06-10-v1-3-source-ingestion-milestone-accept-pdf-olmocr2-youtube-s.md` (acceptance assessment).

### Extension Contract (EXT)

- [x] **EXT-01**: A source-type extension contract exists in `schema/reference/` defining the 5-dimension recipe (acquisition / locator / extraction granularity / drift / epistemic default) and the primary-vs-secondary axis (primary → `direct`, secondary → `derived`)
- [x] **EXT-02**: The contract encodes the decision rule: a new `source_type` is justified only if it changes at least one of the 5 dimensions; otherwise the candidate is documented as a sub-case of an existing type
- [x] **EXT-03**: Existing source types are retro-fit as contract instances (a table mapping each current type across the 5 dimensions), with `research-report` as the worked secondary instance — the contract is extracted from real cases, not invented in a vacuum

### Research-Report Type (RPT)

- [x] **RPT-01**: `source_type: research-report` is added to the frontmatter enum and ingest Pass-0 classification, marking AI deep-research artifacts (Claude/ChatGPT/Perplexity) as synthesized secondary sources
- [x] **RPT-02**: The ingest convention preserves the report's bibliography intact in the immutable raw source and captures it as an addressable citation registry in the source summary
- [x] **RPT-03**: Claims extracted from a research report carry second-order provenance — `support_type: derived` (never `direct`), with locators reusing the report's own reference anchors
- [x] **RPT-04**: Research-report claims default to a lower epistemic tier (`mixed`/`tentative`) and are flagged as priority targets for `bin/audit-claims.sh` (anti-epistemic-laundering defense)
- [x] **RPT-05**: Any citation-registry entry is promotable to a first-class source when a claim earns it (Model C hybrid promotion path, documented)
- [x] **RPT-06**: The two already-ingested deep-research reports (PDF-extraction SOTA, Claude Code frameworks) are retro-classified under the new type with citation registries backfilled

### PDF Ingestion (PDF)

- [ ] **PDF-01**: A documented PDF acquisition pipeline exists: olmOCR 2 (local Ollama) → Markdown with `<!-- page: N -->` page markers, ready for standard ingest
- [ ] **PDF-02**: The PDF sub-case convention records the original-PDF reference and extraction tool/model in source frontmatter; claims use the existing `#p` page locators
- [ ] **PDF-03**: VLM-hallucination guidance is written into the convention: degraded/scanned input gets spot-verification steps and/or a lower epistemic default
- [x] **PDF-04**: End-to-end validation: one real PDF acquired → ingested → wiki pages with page-anchored provenance, exercising the bundle convention (original PDF co-located as asset)

### Video/YouTube Ingestion (VID)

- [ ] **VID-01**: A documented video acquisition pipeline exists: yt-dlp + timestamped STT producing speaker-labeled, timestamped transcripts (the creator's local `stt` CLI is the worked instance; template-public docs stay tool-generic)
- [ ] **VID-02**: The video-as-transcript sub-case convention defines frontmatter metadata (url, channel, title, publish_date, duration); claims use the existing `#t<start>-<end>` locators
- [ ] **VID-03**: The convention documents the video drift stance: immutable once published; the concern is deletion/link-rot, not content change (no drift machinery)
- [ ] **VID-04**: End-to-end validation: one real YouTube video acquired via the pipeline → ingested → wiki pages with timestamp-anchored provenance

## Future Requirements

Deferred. Tracked but not in the current roadmap.

### Drift Detection

- **DRIFT**: External source drift detection (URL-backed staleness) — ROADMAP.md Backlog 999.5; research-report citation registries are its natural trigger

### Repository Source Type

- **REPO**: `source_type: repository` with `#path:file:L` / `#commit:` locators and commit-SHA drift — `primary-source-type-extensions.md` Candidate A; pairs with 999.5

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| 999.5 External Source Drift detection | Deferred by scoping decision 2026-06-10; design alongside or after RPT registries exist |
| `repository` source type (SI.3) | Separate trigger; shares drift machinery with 999.5 — sequence them together later |
| Multimodal frame capture for slide-heavy videos (`#frame:`) | Defer until a demo-heavy video actually needs it (seed open question 8) |
| A 5th "web research" operation / auto-crawl | Breaks the human-curates-sources role division; explicit seed + roadmap non-goal |
| Auto-promoting every citation to a first-class source (Model B) | Over-engineered (30+ sources/report, link rot); promote on demand only (Model C) |
| In-repo acquisition tooling (vendoring stt / olmocr2 wrappers) | Acquisition tools live outside the repo; milestone ships conventions + docs + at most thin glue |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXT-01 | Phase 19 | Complete |
| EXT-02 | Phase 19 | Complete |
| EXT-03 | Phase 19 | Complete |
| RPT-01 | Phase 19 | Complete |
| RPT-02 | Phase 19 | Complete |
| RPT-03 | Phase 19 | Complete |
| RPT-04 | Phase 19 | Complete |
| RPT-05 | Phase 19 | Complete |
| RPT-06 | Phase 19 | Complete |
| PDF-01 | Phase 20 | Pending |
| PDF-02 | Phase 20 | Pending |
| PDF-03 | Phase 20 | Pending |
| PDF-04 | Phase 20 | Complete |
| VID-01 | Phase 21 | Pending |
| VID-02 | Phase 21 | Pending |
| VID-03 | Phase 21 | Pending |
| VID-04 | Phase 21 | Pending |

**Coverage:**
- v1.3 requirements: 17 total
- Mapped to phases: 17 (Phase 19: 9, Phase 20: 4, Phase 21: 4)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-10*
*Last updated: 2026-06-10 after roadmap creation (traceability filled)*
