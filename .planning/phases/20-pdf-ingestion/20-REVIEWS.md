---
phase: 20
reviewers: [claude, codex]
reviewed_at: 2026-06-11T17:30:00+03:00
plans_reviewed: [20-01-PLAN.md, 20-02-PLAN.md, 20-03-PLAN.md, 20-04-PLAN.md]
review_round: 2
---

# Cross-AI Plan Review — Phase 20 (Round 2)

> Round 2 review, run after the round-1 fixes were applied (commit 68d85ba).
> Note: this review was requested with `--claude --codex` from within a Claude Code session.
> The Claude review ran as a fresh, independent `claude -p` session (no shared context with
> the planning session), but is the same model family as the planner — weight its agreement
> with the plans accordingly; its *disagreements* are the higher-signal findings.

## Claude Review

# Cross-AI Plan Review: Phase 20 — PDF Ingestion

## 1. Summary

These are unusually well-grounded plans — nearly every line reference, flag name, and precedent I spot-checked against the live repo is accurate (LINT_VERSION 1.9.1 at `bin/lint.sh:13`, the conditional source block at L1091, `WIKI_ROOT` override at L94, the `--slug`/`--force` patterns in `bin/ingest.sh`, the provisional `pdf` registry row, the 288-line inclusion-audit baseline, the `tests/phase-18` harness). The wave structure is sound, requirements coverage is complete, and the prior review round's fixes (skip-not-fail aggregator, null-response guards, `source.md` clobber guard, neutrality placeholders) are well integrated. However, I verified **two execution-blocking defects** the plans would hit mid-flight: (1) the repeated acceptance criterion "`bash bin/lint.sh --ci` exits 0" is **unsatisfiable on the current tree** — full `--ci` exits 1 today with 18 pre-existing crossref errors unrelated to this phase (the prior review's vacuous-exit-code fix overcorrected into a falsely-failing gate); and (2) the `pdf-extract.sh` core loop passes multi-hundred-KB base64 strings through argv (`jq --arg`, `curl -d "$..."`), which fails on Linux's 128 KB per-argument limit — I reproduced "Argument list too long" with a 533 KB string. Both have cheap, local fixes.

## 2. Strengths

- **Verified edit surfaces.** All insertion points exist as described: `frontmatter.md` Source Summary block (L62–75), `ingest.md` Pass-0 research-report sub-bullet (step 3), `source-types.md` §4 provisional row and §5–6 worked-instance structure to mirror, AGENTS.md routing row format (`> | ... | ... |` at L50 area).
- **The lint check design is correct.** The conditional `original_asset → *.pdf` branch parallels the existing `type == 'source'` gates exactly; the anti-patterns (don't touch `SOURCE_EXTRA_FIELDS`, don't add `pdf` to the 7-value enum) are real and correctly fenced. I confirmed `--ci --category yaml` is green today, so the data-then-check ordering holds.
- **Test isolation is viable as designed.** `WIKI_ROOT` is a real env override (`WIKI_DIR="${WIKI_ROOT:-wiki-cloud/}"`), and lint's report/log writes derive from `WIKI_DIR`, so fixture runs stay inside the mktemp dir. `ingest.sh`'s `DEST_DIR` is cwd-relative, so the temp-cwd strategy for `test_ingest_asset_flag.sh` works.
- **The `--asset` extension composes cleanly.** `FORCE=0/1` and `--force` already exist in `ingest.sh` with exactly the semantics the plan's overwrite guard assumes; the `basename`-derived destination and `source.md` clobber guard are right.
- **Inclusion-audit discipline.** Plan 02 correctly knows about the `<!-- inclusion-audit: 288 lines @ ... -->` baseline (current count matches `wc -l` exactly, so the acceptance grep is meaningful).
- **Honest checkpointing.** PDF-04's human-action gate (cloud-safe + born-digital + size sanity, with the "binary in git history is permanent" warning) and the explicit no-wiki-local-fallback rule are exactly right for this repo's privacy model.
- **Scope discipline.** No new source_type, no marker-grammar changes, no audit machinery, degraded-scan e2e explicitly deferred — the plans resist every adjacent temptation.

## 3. Concerns

- **HIGH — Unscoped `bin/lint.sh --ci` gates fail today for pre-existing reasons (Plans 02, 03, 04).** Verified: `bash bin/lint.sh --ci --dry-run` exits 1 with **18 pre-existing crossref errors** (missing mutual wikilinks among recently-ingested concept pages — e.g. `bounded-context`, `comprehension-debt`). Plan 02 Task 2's automated `<verify>` chain, Plan 03 Task 1's acceptance, and Plan 04 Tasks 2/3 all require unscoped `--ci` exit 0. The executor will be blocked (or forced into an undocumented deviation — fixing 18 cross-reference errors is its own logical operation and out of phase scope). Scoped runs are green: `--ci --category yaml` → 0, `--ci --category routing` → 0.
- **HIGH — `pdf-extract.sh` core loop hits Linux's per-argument limit (Plan 01).** `jq -n --arg img "$B64"` and `curl ... -d "$(jq ...)"` pass the base64 page image as a single argv element. MAX_ARG_STRLEN is 128 KB; a 150-DPI page PNG base64 routinely exceeds that. Empirically reproduced in this environment: a 533 KB string as `jq --arg` → `jq: Argument list too long` (exit 126). As written, the script fails on essentially every real page — and because research deliberately deferred the first live model call to PDF-04 (Wave 3), this would surface at the worst point: during the human-gated validation ingest. The fixture-PDF test also skips today (no fixture committed), so no automated check catches it earlier.
- **MEDIUM — Plan 04's audit verification rests on a flag that doesn't exist and a globally-false assertion.** `bin/audit-claims.sh --select` takes *selector-category* names (`stale,epistemic,recency,fanout,derived-report`) — there is no per-source scoping flag, so "`--select <source-id>`" cannot be adapted as hoped. The fallback in the `<verify>` block is an unscoped run with `! grep -q 'insufficient-locator'` — which fails today: the Phase 19 review (tracked in `19-REVIEW.md`, noted in PROJECT.md) documents ~71% `insufficient-locator` findings on `derived-report` claims from `#sec:` slug mismatches. Additionally, the default `--sample 20` priority-ranked selection gives no guarantee the new source's claims are sampled at all, so "audit resolves the new locators" can pass vacuously or fail spuriously.
- **MEDIUM — The existing mechanical cloud-safety guard is never invoked (Plan 04).** `bin/check-sources-cloud-safe.sh` (PRIV-03, fail-closed, wired into CI's privacy-leak job) already asserts the `sources/`-is-cloud-safe invariant. Plan 04's D-12 handling is purely conversational. The guard checks structure/frontmatter rather than content (so human confirmation stays primary), but this ingest is also the first-ever bundle containing a binary asset under `sources/` — running the guard in the Task 2 verify chain both enforces D-12 mechanically and confirms the guard tolerates the new bundle shape.
- **LOW — Repeated verification lint runs mutate the wiki.** Non-dry-run `bin/lint.sh` rewrites `wiki-cloud/maintenance/lint-report.md` *and appends a log entry to `wiki-cloud/log.md` on every invocation* (lint.sh ~L2769). The plans invoke `--ci` lint in many verify blocks; an executor looping on a failing gate will accumulate log entries that then pollute the "one commit per logical operation" discipline. `--dry-run` preserves the exit-code policy (verified) and should be the default for verification-only runs.
- **LOW — `! grep -q 'pdf.*provisional'` (Plan 02 Task 2) is a fragile negative.** It currently passes, but any future prose line mentioning "pdf" before "provisional" (e.g. an expanded registry footnote) breaks it. Anchoring to the row (`^\| \`pdf\`.*provisional`) makes the assertion precise.
- **LOW — `extraction_date` open question is resolved implicitly.** Research recommended collapsing into `ingested_at`; the plans keep it distinct and (good) record the rationale in the DR — but the rationale sentence lives only in Plan 04 Task 3, *after* the field has shipped in Plans 02/03. Acceptable, just worth noting the decision is effectively locked by Wave 1.

## 4. Suggestions

- **Replace every unscoped `bin/lint.sh --ci` exit-code gate** with the categories this phase actually touches: `bash bin/lint.sh --ci --dry-run --category yaml` and `--category routing` (both verified green today). For Plan 04, where the new conditional check must be proven to fire-and-pass on the real source, `--ci --category yaml` is sufficient and immune to the crossref backlog. Alternatively, assert a delta ("no new errors vs. pre-phase baseline"), but scoped categories are simpler. Optionally file the 18 crossref errors as a separate lint-fix todo — do not fold them into this phase.
- **Switch the model-call plumbing to file-based I/O in Plan 01 Task 1:** `base64 -w0 "$PNG" > "$TMP/page.b64"`, then `jq -n --arg m "$MODEL" --arg p "$PROMPT" --rawfile img "$TMP/page.b64" '{model:$m, prompt:$p, images:[$img], stream:false}' > "$TMP/req.json"`, then `curl -fsS "$OLLAMA_URL/api/generate" -d @"$TMP/req.json"`. Add a static acceptance grep for `--rawfile` (or `-d @`) and drop none of the existing guards. Also consider committing a tiny 1–2-page generated fixture PDF in Wave 1 so the marker-count test actually exercises the loop before Wave 3 (the Ollama server and model are verified present on this machine — the live path *can* run pre-PDF-04).
- **Make Plan 04's audit assertion source-scoped and deterministic:** either run `bin/audit-claims.sh --emit-worklist` (or `--format json`) and jq-filter entries whose source id matches the new source, asserting all its `#p` locators resolve; or grep `AUDIT_OUT` for lines containing the new `src-...` id and assert none of *those* carry `insufficient-locator`. Pair with `--since <pre-ingest-ref>` and a generous `--sample` so the new claims are actually selected. Delete the global `! grep insufficient-locator` — it can never pass while the Phase 19 `#sec:` residue exists.
- **Add `bash bin/check-sources-cloud-safe.sh` to Plan 04 Task 2's verify chain** (post-ingest, pre-commit), keeping the human confirmation as the content-level check.
- **Prefer `--dry-run` on all verification-only lint invocations**, reserving a single non-dry-run lint for the run whose report/log changes are intentionally part of the ingest commit.
- Minor: anchor the Plan 02 provisional-row negative grep to the table row; in Plan 03's Variant B, also assert the fixture page produces zero `yaml` findings overall (not just no extraction finding) to catch fixture-authoring mistakes masking the real assertion.

## 5. Risk Assessment

**MEDIUM.** The plans are accurate where it counts most — edit surfaces, lint architecture, ingest scaffolding, privacy/neutrality posture, and sequencing are all verified correct, and the phase goal (PDF-01..04) is fully covered by the four plans with sensible wave gating. The risk is concentrated in two verified-failing verification gates: the unscoped `--ci` baseline (red today, 18 pre-existing crossref errors) and the argv-limit defect in the extraction loop (reproduced empirically; would surface during the human-gated PDF-04 run). Neither threatens the design — both are mechanical fixes of a few lines each — but as written they would stall execution mid-phase and force ad-hoc deviations. With the lint gates scoped to `yaml`/`routing`, the model call switched to `--rawfile`/`-d @file`, and the audit assertion made source-scoped, this drops to LOW.

---

## Codex Review

## Overall Summary

The plans are high quality: they preserve the Phase 19 contract, keep PDF as a sub-case rather than a new `source_type`, and include good sequencing/neutrality safeguards. The main risks are not architectural; they are execution details around test isolation, audit scoping/side effects, and one missing template surface.

## 20-01 — `pdf-extract.sh` + Test Harness

**Strengths**
- Correctly uses Ollama `/api/generate`, not `ollama run`.
- Good fail-loud handling for missing model, null responses, and partial output.
- Page markers are emitted from the same 1-based loop index used for rendering.

**Concerns**
- **MEDIUM:** The live marker-count test can skip indefinitely because no fixture PDF is committed or generated. That means PDF-01's core behavior is mostly untested until Plan 04.
- **LOW:** No `num_ctx` option is exposed, even though the research notes dense pages may need tuning.
- **LOW:** `grep -c` marker-count sanity check can abort before the custom error if zero markers ever occur.

**Suggestions**
- Add either a tiny generated PDF fixture plus mock Ollama server, or explicitly mark the live extraction test as deferred to Plan 04.
- Add `--num-ctx` or an `OLLAMA_OPTIONS_JSON` env hook.

**Risk Assessment:** **LOW-MEDIUM**. The script design is sound, but the automated test gives limited confidence without a real or mocked extraction path.

## 20-02 — Schema/Convention Docs

**Strengths**
- Clean "authoritative file + lean registry pointer" design.
- Correctly preserves PDF as format-orthogonal and avoids `source_type: pdf`.
- Good neutrality guardrails around real wiki slugs.

**Concerns**
- **MEDIUM:** The plan updates `AGENTS.md`/`CLAUDE.md` but not `schema/AGENTS.template.md`, whose routing table is the wizard source (`schema/AGENTS.template.md:44`). New generated routers may miss `pdf-ingestion.md`.
- **LOW:** Adding optional PDF fields inside the source-summary YAML example may make them look required for all sources unless the conditional note is very prominent.

**Suggestions**
- Add `schema/AGENTS.template.md` to `files_modified` and mirror the routing row there, unless intentionally deferred.
- In `frontmatter.md`, add a short field-description table entry for the four conditional PDF fields.

**Risk Assessment:** **LOW-MEDIUM**. The convention is coherent; the template propagation gap is the main issue.

## 20-03 — Lint Check + `ingest.sh --asset`

**Strengths**
- Conditional lint branch is correctly scoped under `type: source`; does not mutate `SOURCE_EXTRA_FIELDS` or `VALID_SOURCE_TYPES`.
- `--asset` design reuses existing bundle scaffolding.
- Good overwrite and `source.md` clobber guards.

**Concerns**
- **MEDIUM:** `original_asset` is only suffix-checked. A value like `/tmp/file.pdf` or `../file.pdf` could pass while violating the "relative co-located asset" convention.
- **MEDIUM:** The proposed `test_ingest_asset_flag.sh` runs `ingest.sh` from a non-git temp cwd, but `ingest.sh` contributor resolution assumes git context and may exit under `set -euo pipefail` (`bin/ingest.sh:108`).
- **LOW:** Asset validation happens after the source copy in the plan, so an asset-specific failure can leave a partial bundle.

**Suggestions**
- Enforce `original_asset` is relative, has no `..`, and resolves next to the source bundle when possible.
- Run the `--asset` test in a temp git fixture, following Phase 09 helpers, rather than a bare temp dir.
- Move asset basename/collision validation before copying `SOURCE_FILE`.

**Risk Assessment:** **MEDIUM**. The implementation path is right, but tests and path validation need tightening.

## 20-04 — End-to-End Real PDF Validation

**Strengths**
- Correctly blocks on user-supplied cloud-safe PDF.
- Strong privacy language: no local fallback that would fail PDF-04.
- Requires real `#p|direct` provenance and exercises the lint check non-vacuously.

**Concerns**
- **HIGH:** The audit step assumes source-scoped selection, but `bin/audit-claims.sh --select` only accepts selector categories, not source IDs (`bin/audit-claims.sh:48`).
- **MEDIUM:** Audit always writes `wiki-local/maintenance/audit-report.md` and `audit-state.md`, even in JSON/worklist mode (`bin/audit-claims.sh:1106`). The plan calls it read-only and omits those files.
- **LOW:** `files_modified` omits likely topic pages under `wiki-cloud/entities/`, `concepts/`, `overviews/`, or `comparisons/`.

**Suggestions**
- Replace the audit instruction with a concrete method: run audit with a high sample and JSON/worklist output, then parse for the new `source_id`, or add a small `--source-id` audit filter before relying on it.
- Either include `wiki-local/maintenance/` as expected audit control-plane output, or run audit in a temporary repo copy.
- Expand `files_modified` metadata to include possible topic-page directories.

**Risk Assessment:** **MEDIUM-HIGH** until the audit-scoping issue is fixed. The rest of the end-to-end flow is solid.

## Final Risk Assessment

**Overall risk: MEDIUM.** The phase goals are achievable and the plans mostly align with the schema architecture. Before execution, I would fix three things: add template routing propagation, harden `original_asset` validation/test isolation, and make the audit verification step concrete against the actual `audit-claims.sh` interface.

---

## Consensus Summary

Both reviewers rate the phase **MEDIUM** risk overall, agree the architecture is correct (PDF as a format sub-case, no new `source_type`, sound wave sequencing), and locate all remaining risk in execution-time verification details rather than design.

### Agreed Strengths

- **PDF stays a sub-case, not a new type** — both reviewers confirm the plans preserve the Phase 19 contract: no `source_type: pdf`, no mutation of `SOURCE_EXTRA_FIELDS` or the type enum, and the conditional lint branch is correctly scoped under `type: source`.
- **`pdf-extract.sh` fail-loud design** — both praise the missing-model, null-response, and partial-output guards, and the page markers derived from the same loop index used for rendering.
- **`--asset` extension composes cleanly** — both confirm it reuses existing bundle scaffolding with correct overwrite and `source.md` clobber guards.
- **Privacy posture of PDF-04** — both call out the human-gated cloud-safe checkpoint and the explicit refusal to fall back to `wiki-local/` as exactly right.
- **Neutrality and scope discipline** — placeholder usage in template-public files and resistance to scope creep (no audit machinery, degraded-scan e2e deferred) noted by both.

### Agreed Concerns

1. **Plan 04's audit verification is built on a nonexistent interface** (Claude MEDIUM, Codex HIGH — highest-priority shared finding). `bin/audit-claims.sh --select` accepts selector *categories* only, not source IDs, so the planned source-scoped audit cannot run as written. Both independently propose the same fix: run the audit with worklist/JSON output and a generous sample, then filter results by the new source's ID. Claude adds that the fallback global `! grep insufficient-locator` assertion is unsatisfiable today (Phase 19 `#sec:` residue, ~71% insufficient-locator on derived-report claims).
2. **The fixture-PDF gap leaves PDF-01's core loop untested until Wave 3** (Codex MEDIUM; Claude raises the same gap inside its HIGH argv-limit concern). Both recommend committing a tiny generated fixture PDF in Wave 1 so the extraction loop is exercised before the human-gated PDF-04 run.
3. **Verification commands have unaccounted side effects on tracked files** (Codex MEDIUM on audit always writing `wiki-local/maintenance/` control-plane files; Claude LOW on non-dry-run lint rewriting `lint-report.md` and appending to `log.md` on every verify invocation). Same underlying theme: the plans treat audit/lint runs as read-only when they are not.

### Divergent Views

- **The argv-limit defect in `pdf-extract.sh` (Claude HIGH, empirically reproduced) was not caught by Codex** — Codex rated Plan 01 LOW-MEDIUM. Claude reproduced the failure in this environment (533 KB base64 string as `jq --arg` → `Argument list too long`), so treat it as confirmed; the `--rawfile`/`-d @file` fix is cheap.
- **The unscoped `lint.sh --ci` exit-0 gates failing today (Claude HIGH, verified — 18 pre-existing crossref errors) was not raised by Codex.** Claude verified it against the live tree; treat as blocking and scope the gates to `--category yaml`/`routing` (both green today).
- **`schema/AGENTS.template.md` routing propagation (Codex MEDIUM) was not raised by Claude** — if the wizard template's routing table should mirror AGENTS.md, Plan 02 needs one more file in `files_modified`.
- **`original_asset` path validation and test git-context isolation (Codex MEDIUM ×2) were not raised by Claude** — both are cheap hardening items for Plan 03.
