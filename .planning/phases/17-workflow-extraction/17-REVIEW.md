---
phase: 17-workflow-extraction
reviewed: 2026-06-07T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - bin/lint.sh
  - CLAUDE.md
  - AGENTS.md
  - schema/AGENTS.template.md
  - schema/workflows/structured-operations.md
  - schema/workflows/ingest.md
  - schema/workflows/query.md
  - schema/workflows/lint.md
  - schema/workflows/reflect.md
  - schema/workflows/brownfield.md
  - schema/workflows/release.md
  - schema/workflows/audit.md
  - schema/reference/log-format.md
  - docs/reference/agent-parity.md
  - docs/reference/ci.md
  - CONTRIBUTING.md
  - wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md
  - wiki-cloud/index.md
findings:
  critical: 0
  warning: 5
  info: 3
  total: 8
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-06-07
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

This phase extracted the inline §9 (structured operations), §10 (pipeline), §11.1–11.7 (workflows), and §12 (index/log format) out of the AGENTS.md/CLAUDE.md monolith into `schema/workflows/*.md` + `schema/reference/log-format.md`, abolished cross-file §N references in favor of path-refs, and added a `routing` lint category to `bin/lint.sh` to enforce router integrity.

The mechanical core is sound. I verified empirically:
- `bash bin/lint.sh --category routing` exits 0 over the live tree (no dangling refs, no §N residue, all 9 extracted files have routing-table rows).
- AGENTS.md ≡ CLAUDE.md byte-identical (diff empty); both equal the 287-line post-extraction core. `schema/AGENTS.template.md` mirrors with the inclusion-audit header.
- The inclusion-audit baseline (`287 lines @ 2026-06-05`) matches the current AGENTS.md line count exactly, so the drift tripwire is correctly seeded.
- All cross-file §N references in the corpus (AGENTS.md + schema/) are gone; reference-stub edits converted §N pointers to path-refs faithfully.
- Content fidelity of the extracted workflow files is good — operation definitions, executor model, lint 15-step procedure, and log formats survived intact.

The defects found are **not** in the executable routing logic — they are drift between the shipped code/files and the documentation that is supposed to describe them. The most serious are: (1) the `routing` category itself is undocumented in `schema/workflows/lint.md`, which the phase declares to be the *authoritative* spec for the lint CI contract — i.e. the headline deliverable is unregistered in its own authority file; and (2) the phase's decision record misnames two of the files it created (`operations.md`/`pipeline.md` that do not exist on disk). Neither is caught by the new routing lint because the routing check scans neither `wiki-cloud/decisions/` nor the authoritative category list.

## Warnings

### WR-01: `routing` category undocumented in its own authority file (`schema/workflows/lint.md`)

**File:** `schema/workflows/lint.md:81`, `schema/workflows/lint.md:150`
**Issue:** This phase added the `routing` category to `bin/lint.sh` (`CI_SEVERITY_REMAP['routing'] = 'error'`, line 322; `--category` help line 29) and made it a CI-gating error severity. But `schema/workflows/lint.md` — which line 74 of that same file declares to be "the authoritative specification for ... the severity-remap dispatch table" and states "Drift between this section and the shipped code is a regression" — does not mention `routing` anywhere:
- Line 81 (`--ci` severity-remap table) lists `yaml/orphan/crossref/provenance/linkres -> error` but omits `routing`.
- Line 150 (`**Categories** (valid values for --category filter)`) lists `orphan, crossref, stale, contradiction, gap, provenance, yaml, drift, duplicate` — omitting `routing` (and also `contributor`, `brownfield`, `linkres`, which `bin/lint.sh` accepts).
- The 15-step lint procedure (lines 128–148) never describes what the routing check does.

By the file's own stated rule, this is a regression. A foreign agent reading the "authoritative" lint workflow would not know `routing` exists, what it gates, or that it maps to `error` in CI.
**Fix:** Add `routing -> error` to the line 81 severity-remap table; add `routing` (plus the other shipped-but-undocumented categories) to the line 150 category list; add a procedure step describing the routing check (forward dangling-ref → error, inverse orphan → warning, inclusion-audit drift → info). Mirror the addition into `docs/reference/ci.md` severity table and the `bin/lint.sh --ci` help text (lines 38–42, which also omit both `routing` and `linkres`).

### WR-02: Decision record names files that do not exist (`operations.md`, `pipeline.md`)

**File:** `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md:36-37`
**Issue:** The DR's **Decision** section — the canonical "why is the wiki shaped this way" artifact for this phase — lists extraction targets that were never created:
- Line 36: `§9 (Operations Vocabulary + Executor Model) → schema/workflows/operations.md` — actual file is `structured-operations.md`; `operations.md` does not exist on disk.
- Line 37: `§10 (Compiler Pipeline) → schema/workflows/pipeline.md` — `pipeline.md` does not exist; §10 content was folded into `schema/workflows/ingest.md`.

I confirmed both files are absent (`ls` fails) and that the §10 pipeline content (Pass 0, Classify, Append-Then-Synthesize) actually lives in `ingest.md` and `structured-operations.md`. The DR therefore misdescribes the change it records. This is not caught by the routing lint because that check does not scan `wiki-cloud/decisions/*.md`.
**Fix:** Correct line 36 to `schema/workflows/structured-operations.md` and line 37 to "folded into `schema/workflows/ingest.md` (Pass 0–4 + Append-Then-Synthesize)". Re-check the title/TL;DR "§9–§12" framing against the actual file mapping.

### WR-03: `docs/reference/agent-parity.md` still describes the pre-extraction state as in-progress

**File:** `docs/reference/agent-parity.md:103`, `docs/reference/agent-parity.md:115`
**Issue:** This doc was edited this phase but two passages still describe Phase 17 as not-yet-done, which is now factually wrong after the extraction landed:
- Line 103: "The ingest workflow row is marked 'Future home: `schema/workflows/ingest.md`' with a '(Phase 17)' annotation". The actual AGENTS.md routing table no longer contains "Future home" / "(Phase 17)" text — it points to `schema/workflows/ingest.md` unconditionally (verified: zero "Future home"/"STILL INLINE"/"Phase 17" matches in AGENTS.md).
- Line 115: "the inline workflow content in AGENTS.md is still the 'live' text in Phase 17 cycle 4 (the routing table's `schema/workflows/ingest.md` row is Phase-17-gated) ... once Phase 17 completes the move, the routing table row becomes unconditional." The move IS complete; the inline content is gone. This describes a state that no longer exists.

A reader following this desk-check would be told the migration is pending when it has shipped.
**Fix:** Update lines 103 and 115 to past tense — the ingest row is now an unconditional routing-table pointer to `schema/workflows/ingest.md`; the inline workflow content has been removed from AGENTS.md.

### WR-04: Routing forward/§N check does not scan CLAUDE.md

**File:** `bin/lint.sh:2385-2396`
**Issue:** The routing corpus is built from `AGENTS.md` + `schema/reference/*.md` + `schema/workflows/*.md` (lines 2386–2396). `CLAUDE.md` is excluded. The forward dangling-ref check and the §N pattern-prohibition therefore never run against CLAUDE.md. In practice the pre-commit byte-equality hook keeps CLAUDE.md ≡ AGENTS.md, so a dangling ref in CLAUDE.md can only exist if it also exists in AGENTS.md (where it would be caught). But the safety net depends entirely on the sync hook being installed (`bin/install-hooks.sh` is opt-in per clone) and on CI's separate sync job. If CLAUDE.md drifts out-of-band (e.g. a direct edit on a clone without hooks), the routing check is blind to a CLAUDE.md-only dangling ref or §N reference. The reliance is implicit and undocumented in the check.
**Fix:** Either add `CLAUDE.md` to `corpus_files` (cheap, makes the check self-contained), or add an inline comment at line 2386 noting that CLAUDE.md routing integrity is delegated to the AGENTS.md↔CLAUDE.md byte-equality gate and is intentionally out of routing scope.

### WR-05: §N pattern-prohibition check has no code-block masking (latent false-positive)

**File:** `bin/lint.sh:2426`, `bin/lint.sh:2444-2450`
**Issue:** `SECTION_REF_RE = re.compile(r'§[0-9]|\bSection [0-9]')` is applied to raw corpus content with no markdown masking (unlike the provenance and linkres checks, which call `mask_markdown()`). The comment at lines 2422–2424 asserts "Section headings carry no § glyph and do not match \bSection [0-9] — exempt by construction." That holds for the current corpus (verified: zero matches), but the check will false-positive (severity `error`, CI-gating) on any *future* legitimate use of "Section 5" inside a fenced code block, an inline-code example, or an HTML comment in a workflow file — e.g. a doc example quoting another tool's "Section 3" output. Because routing maps to `error` under `--ci`, such a false positive would block merge with no escape hatch.
**Fix:** Run `SECTION_REF_RE` (and ideally `PATH_REF_RE`) over `mask_markdown(corpus_content)` instead of raw content, consistent with the provenance/linkres masking pattern already in the file. The character-offset-preserving mask keeps the "near: …snippet…" context accurate.

## Info

### IN-01: Inclusion-audit baseline `287 lines` is off-by-one for the template

**File:** `schema/AGENTS.template.md:7`
**Issue:** The header reads `<!-- inclusion-audit: 287 lines @ 2026-06-05 -->` but the template is 288 lines (the `{{...}}` wizard placeholders add a line vs. AGENTS.md's 287). The drift check only runs against AGENTS.md (287, exact), so this is never flagged, but the baseline-N claim is literally inaccurate for the file it sits in.
**Fix:** Either accept the documented divergence (the header is conceptually a copy of AGENTS.md's baseline) or note in a comment that the count tracks AGENTS.md, not the template.

### IN-02: DR filename date (`dr-2026-06-05`) differs from its `created_at` (`2026-06-07`)

**File:** `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md:7`
**Issue:** The decision record's `id`/filename encodes `2026-06-05` but `created_at`/`updated_at` are `2026-06-07`, and the index entry lists it as `(sourced, 2026-06-07)`. Harmless for resolution (the wikilink targets the `id`, which matches), but the date stamps disagree with the slug.
**Fix:** Optional — align the slug date with `created_at`, or accept that the slug date encodes the design-decision date rather than the authoring date.

### IN-03: `structured-operations.md` ops-vocab table intentionally omitted (verify intent)

**File:** `schema/workflows/structured-operations.md:6`
**Issue:** The extracted file opens directly at "### Operation Definitions"; the "Operations Vocabulary" verb table (UPDATE/MERGE/SUPERSEDE/ARCHIVE → Verb → What It Does) was left as ambient residue in AGENTS.md (line 202) per the inclusion annotation. This is consistent with the router-plus-leaf model and appears deliberate, but it means the authoritative structured-operations leaf does not contain the one-glance verb table — a reader who JIT-loads only the leaf misses it. Flagging for confirmation that this split is intended rather than an extraction omission.
**Fix:** If intended, no action. If the leaf should be self-sufficient, copy the 5-row vocab table into `structured-operations.md` above "### Operation Definitions".

---

_Reviewed: 2026-06-07_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
