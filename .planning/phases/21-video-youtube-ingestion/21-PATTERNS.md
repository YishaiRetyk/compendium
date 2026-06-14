# Phase 21: Video/YouTube Ingestion - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 11 (1 new doc, 4 schema edits, 1 new decision record, 3 validation-ingest pages, 2 byte-sync/router edits)
**Analogs found:** 11 / 11 (zero net-new code — the leanest possible parallel of Phase 20)

This is a documentation/convention-engineering phase with **no new shell code** (D-04
diverges from Phase 20's `bin/pdf-extract.sh`). Every file has a strong in-repo analog:
either the Phase 20 PDF artifact it mirrors, or the de-facto-committed transcript exemplar
it formalizes. The planner should treat the convention doc as "copy the `pdf-ingestion.md`
shape, swap PDF→video specifics, and DROP the lint-enforcement / asset / new-script
machinery that video deliberately does not carry."

**Critical thread (every template-public file):** the personal `stt` tool name and any
private vault slug must NOT appear in `schema/`, `bin/`, `docs/`, `.claude/skills/`,
`AGENTS.md`/`CLAUDE.md`/`README.md`, or `wiki-cloud/` scaffolding. Worked-instance `stt`
details live only in `.planning/`. `bin/check-neutrality.sh` is the backstop gate, not the
primary defense — prevent leaks at write time. (Real vault pages under `sources/` and
`wiki-cloud/sources/` MAY name `stt`; neutrality binds template-public surfaces only — D-07.)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/reference/video-ingestion.md` (NEW; planner names it) | config (authoritative reference doc) | transform (convention spec) | `schema/reference/pdf-ingestion.md` | exact (role + section structure) |
| `schema/reference/source-types.md` | config (registry/contract) | transform | self §4 (provisional `video` row L50 → finalized) | in-place edit |
| `schema/reference/frontmatter.md` | config (field spec) | transform | self (Source Summary Additional Fields block L58–80, the PDF sub-case block L69–74) | in-place edit |
| `schema/reference/provenance.md` | config (locator spec) | transform | self (`#t` row L31 — DO NOT redefine; already complete) | read-only (no edit needed) |
| `AGENTS.md` | config (router) | transform | self (routing table L45–64, the `pdf-ingestion.md` row L51) | in-place edit (if doc is new) |
| `CLAUDE.md` | config (byte-mirror) | transform | self (synced via `bin/sync-claude.sh`) | derived (NEVER hand-edit — run the script) |
| `wiki-cloud/decisions/dr-2026-06-1X-video-ingestion.md` (NEW, optional) | decision record | event-driven (schema change) | `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` | exact (same `trigger_type: schema-update`, same domain) |
| `sources/2026/2026-XX/<YYYY-MM-DD-slug>.md` (NEW; validation ingest) | source (raw transcript) | file-I/O | `sources/2026/2026-05/2026-05-03-is-this-the-only-skill-left.md` | exact (de-facto format) |
| `wiki-cloud/sources/src-<YYYY-MM-DD-slug>.md` (NEW; validation summary) | source summary | transform | `wiki-cloud/sources/src-2026-05-03-is-this-the-only-skill-left.md` | exact (de-facto format) |
| topic pages updated by validation ingest (concept/entity) | concept / entity | transform | `wiki-cloud/concepts/jagged-frontier.md` (`#t`-anchored claims) | role-match |
| `bin/audit-claims.sh`, `bin/ingest.sh`, `bin/lint.sh` | utility | (reused, NOT modified) | — | **no change** (see "Reused As-Is" below) |

## Reused As-Is (NO modification — divergence from Phase 20)

These three scripts that Phase 20 *edited* are **reused unchanged** in Phase 21. Mapping them
matters precisely so the planner does NOT re-touch them:

- **`bin/audit-claims.sh`** — `#t` resolution already works against the D-01 line grammar
  (see Shared Pattern: `#t` Resolver). Zero changes (D-01). Reused read-only for optional
  spot-verification (D-10).
- **`bin/ingest.sh`** — the single-file (no-`--asset`) path is the right fit for a
  transcript-only video source (D-05). The Phase-20 `--asset` flag is NOT exercised; no
  binary is co-located.
- **`bin/lint.sh`** — NO new rule. Phase 20 added a conditional `extraction_*` check keyed
  on `original_asset=*.pdf`; video extraction fields are convention-only (D-07), so there is
  no mechanical trigger and no lint branch to add. Do not parallel the Phase-20 lint edit.

## Pattern Assignments

### `schema/reference/video-ingestion.md` (NEW — config/reference, transform)

**Analog:** `schema/reference/pdf-ingestion.md` (the #1 structural analog — mirror its
section skeleton, retitle for video, and apply the video divergences below).

**Header + authority banner** to copy verbatim-in-shape (`pdf-ingestion.md` L1–6):
```markdown
# Video Ingestion

> Agent-authoritative reference for the video-as-sub-case-of-transcript convention and the
> YouTube acquisition runbook.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and
> AGENTS.md, this file wins.

Use this file when acquiring a YouTube/video source (running the acquisition runbook),
authoring the source summary for a video-acquired transcript, or deciding the epistemic
status of claims drawn from STT-extracted spoken text.
```

**§1 Classification — the 5-dimension walk-through** mirrors `pdf-ingestion.md` §1 (L8–22)
but for `transcript` as the parent, not "any parent type". PDF table to adapt (L14–20):
```markdown
| Dimension | Effect of the video format |
|-----------|----------------------------|
| **Acquisition** | Changes (download via yt-dlp-equivalent + timestamped STT vs. a locally-recorded transcript). |
| **Locator** | **Unchanged** — `#t<start>-<end>` already exists (`schema/reference/provenance.md`); the STT emits the `[H:MM:SS]` lines it resolves against. |
| **Extraction Granularity** | **Unchanged** — inherited from `transcript` (utterance/paragraph clusters). |
| **Drift** | **Unchanged** — `static after recording`; the committed transcript is the durable archive, link-rot of `url` is the only concern (D-06). |
| **Epistemic Default** | Changes **conditionally** — only for degraded audio. Clean spoken-word keeps `transcript`'s `sourced` default. See the Tiered Epistemic Policy section. |
```
Conclusion sentence (mirror PDF's "does NOT earn a new enum value", D-14): video is a
**sub-case of `transcript`**, not a new `source_type` — only Acquisition changes (and
Epistemic Default conditionally). This is the format-orthogonal framing carried forward from
Phase 20 D-05.

**§2 Frontmatter Fields** mirrors `pdf-ingestion.md` §2 (L24–39) BUT WITHOUT the lint mandate.
Document the five VID-02 fields as a flat `snake_case` table:
```markdown
| Field | Meaning |
|-------|---------|
| `url` | The video URL — a courtesy pointer that may rot (D-06). Base field, reused. |
| `channel` | Publishing channel / author. |
| `title` | Video title. |
| `publish_date` | ISO 8601 video publication date. |
| `duration` | Runtime (e.g. `~12 min`). |
```
Plus the convention-only extraction fields (`extraction_tool` / `extraction_model` /
`extraction_date`) — recorded on STT-extracted transcripts but **NOT lint-enforced** (D-07).
**CRITICAL divergence from PDF §2 L39:** do NOT copy the sentence "Lint **requires** all four
fields when `original_asset` points at a `*.pdf`." There is no `original_asset` for video and
no lint trigger; state explicitly that these fields are convention-only (no mechanical signal
distinguishes an STT transcript from one built off official captions, so a lint rule would
guess). Note which of the five reuse existing base fields (`url` is already a base source-
summary field per `frontmatter.md` L64; planner decides `publish_date`/`duration` spelling
per Claude's Discretion).

**§3 `#t` Locator Usage** mirrors `pdf-ingestion.md` §3 (L41–45):
```markdown
Claims from video sources use the existing `#t<start>-<end>` timestamp locators, which
resolve against the `[H:MM:SS]` lines the STT emits — see `schema/reference/provenance.md`.
Do NOT redefine the grammar.

Claims keep `support_type: direct` (D-11). A video is a **primary** transcript source: STT
is *extraction*, not *derivation*. Transcription risk is carried by the page's
`epistemic_status`, NEVER by the support type. Using `derived` here is an
epistemic-laundering error.
```
This is a direct re-skin of the PDF §3 paragraph (swap `#p`→`#t`, OCR→STT) — the
support_type-stays-direct logic is identical (D-11 carries forward Phase 20 D-09).

**§4 Tiered Epistemic Policy** mirrors `pdf-ingestion.md` §4 (L47–56), adapted to audio:
```markdown
- **Clean spoken-word audio** → the `transcript` type's normal `sourced` default.
  The convention MANDATES claim-level hedging on the STT failure surface: proper
  nouns / named entities, technical terms, numbers & statistics, and anything the
  speaker themselves hedges (D-09 — formalizes what the existing two transcripts do inline).
- **Degraded audio** (music bed, heavy crosstalk, poor mic, heavy accent) →
  page-level `epistemic_status: tentative` + a mandatory spot-verification of
  **N = 3 sampled segments** (D-09, PDF-symmetric).
```
Spot-verification target diverges from PDF (D-10): PDF reads against a co-located
`original_asset`; **video re-watches the live `url` at the segment's `#t` timestamp** (no
local asset exists — D-05). Convention caveat: a rotted video cannot be verified → the
segment stays `tentative`. Read-only; reuse `bin/audit-claims.sh` for `#t` resolution where
useful (no new audit machinery). The PDF "confident hallucination" failure-mode paragraph
(L56) maps to the STT failure surface — keep the structure, re-aim it at spoken text.

**§5 Acquisition Runbook (tool-generic contract)** mirrors `pdf-ingestion.md` §5 (L58–74) but
this is the **highest-neutrality-risk section** (D-04). PDF named `olmOCR`/`bin/pdf-extract.sh`
because those are public; the personal STT tool is NOT nameable here. Write the contract as:
```markdown
**Generic contract (D-04):** any pipeline of a video downloader (`yt-dlp` or equivalent) +
a timestamped speech-to-text engine that emits the `[H:MM:SS] SPEAKER: text` line grammar
(D-01) satisfies this convention. No repo script is shipped; the convention is tool-generic.
```
DO NOT name a worked instance in this file (contrast PDF L62, which named `bin/pdf-extract.sh`).
The worked instance lives in `.planning/` phase notes only. There is **no §6-equivalent
Ingest-Checklist `--asset` step** (PDF §6 step 2, L79) — video is single-file (D-05).

**§6 Ingest Checklist** mirrors `pdf-ingestion.md` §6 (L76–82), dropping the `--asset` line:
```markdown
1. Run the (tool-generic) URL → timestamped-transcript pipeline.
2. Commit the transcript as a single `.md` file (no bundle dir — D-05), rich frontmatter +
   `[H:MM:SS]` lines. Optional `## Description` section between frontmatter and transcript
   when the video description carries substance (D-08).
3. Author the source summary with `source_type: transcript` + the video frontmatter fields.
4. Claims use `#t<start>-<end>` with `support_type: direct`; mandate claim-level hedging on
   the STT failure surface.
5. If audio is degraded → page-level `tentative` + spot-verify N = 3 segments against the
   live `url`; otherwise → `sourced`.
```

**See Also block** mirrors `pdf-ingestion.md` L84–89: link `source-types.md`, `frontmatter.md`,
`provenance.md`, `schema/workflows/ingest.md`.

---

### `schema/reference/source-types.md` (MODIFIED — config/registry, in-place edit)

**Analog:** self — the **provisional `video` row already exists** at L50 and just gets
finalized (D-14). This is the lowest-risk edit in the phase.

**Current provisional row** (L50, the `## 4. Evaluated Candidates Sub-case Registry` table):
```markdown
| `video` | sub-case of `transcript` (provisional) | Acquisition (provisional) | (Phase 21) | Timestamp locators (`#t`) already exist; Phase 21 walk-through finalizes verdict and dimension assessment |
```

**Finalized row to write** (mirror the *finalized* `pdf` row format directly above it at L49):
```markdown
| `video` | sub-case of `transcript` | Acquisition (always); Epistemic Default (degraded audio only) | `schema/reference/video-ingestion.md` | Timestamp locators (`#t`) + the `[H:MM:SS]` line grammar already exist; download + STT replaces recorded acquisition. Claims stay `support_type: direct`; degraded audio gets `tentative` + N=3 spot-verification (D-09). |
```
Drop "(provisional)" from both the Verdict and Dimensions cells; fill the Convention-Doc cell
with the new doc path; rewrite Notes to match the finalized verdict. The `transcript` enum row
in §3 (L37: `recorded or downloaded | #t<start>-<end> | paragraph/utterance clusters | static
after recording | sourced`) needs **no edit** — video is absorbed by it.

---

### `schema/reference/frontmatter.md` (MODIFIED — config/field-spec, in-place edit)

**Analog:** self — the PDF sub-case block in "Source Summary Additional Fields" (L69–74) is
the exact shape to parallel.

**PDF block to mirror** (L69–74):
```yaml
# PDF sub-case fields — present ONLY when the source was acquired from a PDF.
# OMIT all four entirely on non-PDF sources (do NOT leave them empty). See schema/reference/pdf-ingestion.md.
extraction_tool: olmocr
extraction_model: "richardyoung/olmocr2:7b-q8"
extraction_date: YYYY-MM-DD
original_asset: original.pdf
```

**Video block to add** (parallel placement, neutral example values — do NOT name the personal
STT tool; use a generic placeholder since this is a template-public surface):
```yaml
# Video sub-case fields (transcript parent) — present on video-acquired transcript sources.
# extraction_* are convention-only (NOT lint-enforced — see schema/reference/video-ingestion.md).
url: "https://..."          # courtesy pointer; may rot
channel: "<channel-name>"
publish_date: YYYY-MM-DD
duration: "~12 min"
extraction_tool: "<stt-tool>"
extraction_model: "<asr-model>"
extraction_date: YYYY-MM-DD
```
Note `url` is already listed at L64 — reuse it, don't duplicate. Decide per Claude's Discretion
whether `publish_date`/`duration` reuse existing base fields. **Neutrality:** unlike the PDF
block which names a public model tag (`richardyoung/olmocr2:7b-q8`), the video block must use
placeholders (`<stt-tool>`, `<asr-model>`) — this file is template-public.

---

### `schema/reference/provenance.md` (READ-ONLY — no edit)

**Analog:** self. The `#t` locator is **already fully defined** (L31, Locator Types table)
with a worked example, and the "Examples in Context" block already shows a transcript `#t`
claim (L78). VID-02's locator need is satisfied today. Do NOT edit this file. Mapped here so
the planner does not mistakenly schedule a provenance edit.
```markdown
| Timestamp | `#t<start>-<end>` | `#t00:12:10-00:12:48` | Audio/video transcripts |
```

---

### `AGENTS.md` + `CLAUDE.md` (MODIFIED — config/router + byte-mirror)

**Analog:** self — the routing table (AGENTS.md L45–64) and the existing `pdf-ingestion.md`
row at L51.

**Existing row to parallel** (AGENTS.md L51):
```markdown
> | Ingesting a PDF source (acquisition runbook + sub-case convention) | `schema/reference/pdf-ingestion.md` |
```

**New row to add** (only if the planner ships a new doc — Claude's Discretion whether new file
vs. extending an existing transcript doc):
```markdown
> | Ingesting a video/YouTube source (acquisition runbook + sub-case convention) | `schema/reference/video-ingestion.md` |
```
Add it adjacent to the PDF row (both are acquisition sub-case docs). **Workflow (Phase 16/19/20
pattern, D-03):**
1. Edit `AGENTS.md` ONLY (it is the source of truth).
2. Run `bash bin/sync-claude.sh` to byte-copy AGENTS.md → CLAUDE.md. NEVER hand-edit CLAUDE.md.
3. `git add CLAUDE.md`. CI runs `bin/sync-claude.sh --check` (exit 2 on drift) + the `routing`
   lint category (an `error`-severity gate — `bin/lint.sh` L322 — so a dangling/un-synced
   routing row fails CI).

`bin/sync-claude.sh` is a pure `cp` + `cmp` (L32–33): no transformation, exact byte equality.

---

### `wiki-cloud/decisions/dr-2026-06-1X-video-ingestion.md` (NEW, optional — decision record)

**Analog:** `wiki-cloud/decisions/dr-2026-06-11-pdf-ingestion.md` (the direct Phase-20
parallel — same `trigger_type: schema-update`, same `domains: [wiki-infrastructure]`,
`affected_pages: []`).

**Frontmatter to mirror** (dr-2026-06-11 L1–24): `type: decision`, `status: active`,
`trigger_type: schema-update`, `affected_pages: []`, `knowledge_domain: software`,
`tags: [meta, schema]`, `domains: [wiki-infrastructure]`. Title in the
"X as Y + Z" shape, e.g. *"Video as Sub-Case of Transcript + Tool-Generic Acquisition (No
Repo Script)"*.

**Body section order to mirror** (dr-2026-06-11 L26–92): `## TL;DR` → `## Decision`
(numbered coupled deliverables) → `## Why` → `## Alternatives Considered` → `## Consequences`
→ `## Affected Pages` (`None.` — infrastructure DR) → `## Sources`. The PDF DR's
**Alternatives Considered** maps cleanly to Phase 21's declined options (preserved in
CONTEXT.md `<deferred>` L111): `.info.json`/thumbnail bundle, `archive_url`/Wayback field,
`url_dead:` rot convention, lint-enforced extraction fields. The PDF DR L81 even forward-
references this phase ("This DR aids Phase 21 ... inherits the same format-orthogonal sub-case
pattern") — cite it. Author this DR only if the schema edits warrant it (Phase 18/19/20
precedent; Claude's Discretion D per CONTEXT.md L50).

**Neutrality:** `wiki-cloud/decisions/` is template-public scaffolding-adjacent — keep the
STT tool name out; describe it generically ("a timestamped STT engine").

---

### Validation ingest: raw transcript `sources/2026/2026-XX/<YYYY-MM-DD-slug>.md` (NEW — source)

**Analog:** `sources/2026/2026-05/2026-05-03-is-this-the-only-skill-left.md` — the de-facto
committed format the validation ingest (D-12) mirrors.

**Frontmatter shape to copy** (exemplar L1–9):
```yaml
---
title: "<Video Title>"
author: "<Channel>"
publication: "YouTube"
url: "https://www.youtube.com/watch?v=..."
date: YYYY-MM-DD
source_type: transcript
privacy: cloud_safe
---
```
**Body line grammar** (exemplar L13+) — single-speaker example uses NO labels:
```markdown
[0:00:00] It's a skill that all senior devs build by accident over years.
[0:00:05] And it looks like it's the whole job now.
```
**Phase-21 divergence (D-03, the one piece of NEW surface):** the validation video is
**multi-speaker** (D-12), so its lines carry a `SPEAKER:` prefix the exemplar lacks:
```markdown
[0:00:00] ALICE: It's a skill that all senior devs build by accident over years.
[0:00:05] BOB: And it looks like it's the whole job now.
```
The `[H:MM:SS]` timestamp stays FIRST so the audit `TS_RE` (`^\s*\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?`)
still matches at line start (D-01). Hour-digit normalization (`0:00:00` vs `00:00:00`) is
tolerated by `TS_RE` either way — pick one in the convention (Claude's Discretion).
**Privacy:** `sources/` is cloud-safe-only — verify the video is cloud-safe before ingest (D-12).

---

### Validation ingest: source summary `wiki-cloud/sources/src-<YYYY-MM-DD-slug>.md` (NEW)

**Analog:** `wiki-cloud/sources/src-2026-05-03-is-this-the-only-skill-left.md`.

**Full frontmatter shape to copy** (exemplar L1–44): `type: source`, base fields, then the
source-summary additional fields `path` / `url` / `content_hash` / `ingested_at` /
`source_type: transcript` / `compilation_status` / `compiled_against_hash` / `compiled_targets`
(L30–43). Add the video sub-case fields (`channel` or `author`, `publish_date`, `duration`,
convention-only `extraction_*`).

**De-facto claim-level hedging that D-09 formalizes** — the exemplar already does this inline;
mirror the pattern (exemplar L83–85, proper-noun/number hedging on the STT failure surface):
```markdown
- A study attributed to "Hosini and Liftinger" reportedly used resume data from 62 million
  workers across 285,000 U.S. firms; speaker explicitly hedges the names
  [prov:src-...#t00:10:25-00:10:48|direct|...] [epistemic:: tentative]
```
`#t`-anchored `support_type: direct` claims throughout (exemplar L54–94). Page-level
`epistemic_status: sourced` for clean audio (exemplar L12); `tentative` only if degraded.

---

### Topic pages updated by validation ingest (concept / entity — MODIFIED)

**Analog:** `wiki-cloud/concepts/jagged-frontier.md` — live `#t`-anchored claims authored from
a YouTube transcript (`...#t00:04:56-00:05:21|direct|...`, cited in CONTEXT.md L71). New/updated
concept/entity pages receive `#t` `direct` claims from the validation video following the same
shape. Standard ingest-workflow merge; no new pattern.

## Shared Patterns

### `#t` Resolver (the constraint the D-01 line grammar must satisfy)
**Source:** `bin/audit-claims.sh` L392–419 (`TS_RE`, `_ts_to_secs`, `_resolve_t`) + L498–506
(dispatch). **Apply to:** the convention doc §3/§4, every validation-ingest `#t` claim, the
multi-speaker line grammar.
```python
TS_RE = re.compile(r'^\s*\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?')   # timestamp at line start

def _ts_to_secs(ts):
    parts = [int(p) for p in ts.split(':')]
    if len(parts) == 3: h, m, s = parts
    else:               h, m, s = 0, parts[0], parts[1]
    return h * 3600 + m * 60 + s

def _resolve_t(raw_text, start, end):           # slices lines whose ts ∈ [start,end]
    for line in raw_text.splitlines():
        m = TS_RE.match(line)
        if m and s0 <= _ts_to_secs(m.group(1)) <= e0: out.append(line)
```
**Load-bearing facts:** (1) `TS_RE` anchors at line start with optional `[...]` brackets and
allows a 1–2 digit hour — so `[H:MM:SS]`, `[HH:MM:SS]`, AND `[MM:SS]` all resolve. (2) It
matches ONLY the leading timestamp; everything after (including a `SPEAKER:` prefix) is opaque
line text — **so the D-03 multi-speaker `SPEAKER:` label needs ZERO resolver change** (D-01).
(3) `#t` dispatch at L498–506 splits on `-`; single-value `#t<ts>` also works. **Conclusion the
planner can rely on:** no `bin/audit-claims.sh` edit is needed or wanted.

### Tool-Generic Posture + Neutrality Gate (D-04 / D-07)
**Source:** `bin/check-neutrality.sh` L97 (`PUBLIC_PATHS`), L150–166 (denylist + exemptions).
**Apply to:** EVERY template-public file in this phase — the convention doc, `source-types.md`,
`frontmatter.md`, `AGENTS.md`/`CLAUDE.md`, the decision record.
```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema .claude/skills)
```
The gate greps these paths against `.neutrality-denylist.txt` and exits 2 on any match. The
personal STT tool name (and the personal asr/diarize module names) belong on this denylist and
must NOT appear in any `PUBLIC_PATHS` surface. **Posture (D-04):** the convention doc names a
*generic* contract (`yt-dlp` or equivalent + a timestamped STT) and ships **no worked-instance
name and no `bin/` script** — diverging from `pdf-ingestion.md` §5 L60–62 which named
`olmOCR`/`bin/pdf-extract.sh` (legal because those tools are public). Prevent the leak at write
time; the gate is the backstop, not the design.

### AGENTS.md ↔ CLAUDE.md Byte-Sync (D-03, routing)
**Source:** `bin/sync-claude.sh` L32–33 (cp + cmp), `bin/lint.sh` L322 (`'routing': 'error'`).
**Apply to:** the routing-table edit (if a new doc ships).
```bash
cp "$SRC" "$DST"                       # AGENTS.md -> CLAUDE.md, byte-for-byte
cmp -s "$SRC" "$DST" || exit 1
```
Edit AGENTS.md only → run `bin/sync-claude.sh` → `git add CLAUDE.md`. CI gates on
`sync-claude.sh --check` (exit 2 on drift) AND the `routing` lint category at `error` severity.

### Format-Orthogonal Sub-Case Verdict (D-14, carried from Phase 20 D-05)
**Source:** `schema/reference/source-types.md` §1–2 (5-dimension contract L8–27, decision rule
L27) + the finalized `pdf` precedent §4 L49. **Apply to:** the convention doc §1 and the
`source-types.md` row finalization. A candidate earns a new enum value ONLY if it changes ≥1
dimension a sub-case cannot absorb; `video` changes only Acquisition (always) + Epistemic
Default (conditionally) → sub-case of `transcript`, not a new type.

## No Analog Found

None. Every Phase-21 file has either a Phase-20 PDF artifact it mirrors or a de-facto-committed
transcript exemplar it formalizes. The single piece of genuinely-new convention surface — the
`SPEAKER:` multi-speaker labeling path (D-03) — has no existing in-repo instance (the two
committed transcripts are both single-speaker), which is exactly why D-12 mandates a
multi-speaker validation video to exercise it. There is no net-new *code* (D-04 ships no script),
so unlike Phase 20 there is no script-with-no-analog row.

## Metadata

**Analog search scope:** `schema/reference/`, `bin/`, `sources/2026/2026-05/`,
`wiki-cloud/sources/`, `wiki-cloud/decisions/`, `wiki-cloud/concepts/`, `AGENTS.md`/`CLAUDE.md`,
`.planning/phases/20-pdf-ingestion/`.
**Files scanned:** 13 (10 read in full or targeted; 3 grepped for structure).
**Pattern extraction date:** 2026-06-14
