---
phase: 20
reviewers: [claude, codex]
reviewed_at: 2026-06-11T18:45:50+03:00
review_round: 4
plans_reviewed: [20-01-PLAN.md, 20-02-PLAN.md, 20-03-PLAN.md, 20-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 20 (Round 4)

## Claude Review

# Cross-AI Plan Review — Phase 20: PDF Ingestion (Round 4)

**Review method:** Since rounds 1–3 already reshaped the design, this round focused on independently verifying the factual claims the plans now rest on, directly against the repo. Results of that probe:

| Claim | Verified |
|---|---|
| `LINT_VERSION="1.9.1"` at `bin/lint.sh:13`; `--ci`/`--dry-run`/`--category` flags; CI exit-1-on-error vs default exit-0 | ✅ exact |
| Unscoped `--ci` red today: "18 pre-existing crossref errors" | ✅ ran it — exactly 18 errors, all crossref, none phase-related |
| `WIKI_ROOT` env override (`WIKI_DIR="${WIKI_ROOT:-wiki-cloud/}"` at lint.sh:94); findings print to **stderr** | ✅ |
| `SOURCE_EXTRA_FIELDS` / 7-value `VALID_SOURCE_TYPES` / `type==source` conditional block shape / decision-page `trigger_type: schema-update` validation | ✅ |
| `ingest.sh`: `FORCE=0` + `--force` + `[ "${FORCE:-0}" != "1" ]` convention, `--contributor` short-circuit, cwd-relative `DEST_DIR="sources/..."`, asset-check insertion point between L279 and the L281 `mkdir` | ✅ |
| `audit-claims.sh`: `--since`/`--sample`/`--format json` exist; findings carry `source_id` **and** `verdict`; worklist is verdict-less; recency selector diffs `base...HEAD` (committed changes only → post-commit ordering is mandatory) | ✅ |
| `check-sources-cloud-safe.sh` scope = exactly the two checks Plan 04 states (frontmatter `local_only` + `sources/local-only/` dir) | ✅ |
| `schema/AGENTS.template.md` routing table genuinely missing the `source-types.md` row (Phase 19 drift) | ✅ confirmed |
| Fixture Regeneration Rule command in `schema/fixtures/README.md` matches Plan 02 verbatim; `tests/phase-08/test_canonical_byte_equality.sh` exists | ✅ |
| `inclusion-audit: 288 lines` == actual `wc -l` of AGENTS.md (288) → Plan 02's equality acceptance check is semantically correct | ✅ |
| Provisional `pdf` row at `source-types.md:49`; retro-fit grep count = exactly 7 and stays 7 after the edit; provenance marker grammar at the cited lines; `ps2pdf` present | ✅ |

This is an unusually well-grounded plan set. The remaining findings below are execution-clarity issues, not design flaws.

---

## 20-01-PLAN.md (pdf-extract.sh + test harness)

**Summary:** Solid. The argv-limit fix (`--rawfile` + `-d @file`), per-page timeout, null-response guards, namespaced env vars, and the committed `ps2pdf` fixture are all correctly specified and consistent with the verified environment.

**Concerns:**
- **LOW — Cold-model-load vs the 300s default timeout.** The first `/api/generate` call loads a 9.5 GB model; on a CPU-bound or memory-pressured host that load + first inference can exceed `PDF_EXTRACT_TIMEOUT=300`, aborting page 1 with a misleading "timed out" error. The override exists; the usage text should mention that the *first* page includes model load and may need a higher value (or the runbook in Plan 02 should).
- **LOW — Commit shape unspecified.** Plan 02 mandates "ONE `schema:` commit" and Plan 04 names its `ingest()`/`reflect()` commits, but Plans 01 and 03 never state their commit prefixes/grouping. Given "one commit per logical operation" is a hard repo rule and commit-shape ambiguity generated fixes in earlier rounds, say it explicitly (e.g., Plan 01 = one commit; is `tests:`/`schema:`/something else the right prefix for new tooling?).
- **INFO — Aggregator swallows SKIP context.** `run_test` redirects test output to `/dev/null`, so a model-unreachable SKIP inside the marker test surfaces as a bare `PASS:` line. Accepted by design in round 3 (SKIP-exit-0 counts as PASS), but it means "5/5 passed" on a model-less machine is indistinguishable from a live-exercised run. A one-line comment in `run.sh` noting this would prevent a future false confidence read.

**Strengths:** marker-emission contract (always emit, even for blank pages, abort only on null/error) is exactly right for a provenance system; temp-output-then-`mv` prevents structurally-valid partial files; two-stage preflight (server + model tag) is the correct spoofing mitigation.

## 20-02-PLAN.md (convention doc + registry + routing)

**Summary:** Complete and correct. The setup-parity chain (template edit → fixture regen → byte-equality test, all one commit) closes the last CI trap, and I verified every link in that chain exists.

**Concerns:**
- **LOW — "plain `| ... |` blockquote format" is self-contradictory and factually off.** The template's routing rows carry the same `> |` blockquote prefix as AGENTS.md (verified). The word "plain" could nudge an executor into dropping the `> ` prefix, silently corrupting the table — and nothing gates it (the fixture regenerates from whatever the template says, and acceptance only greps for the filename). The `read_first` step mitigates this, but fix the wording: "matching the surrounding `> | ... |` blockquote rows."
- **LOW — Top-5 lint print window (shared with Plan 03).** Verified: lint prints only the **top 5** findings to stderr; in dry-run nothing else carries finding content. Plan 02's own gates use exit codes (fine), but be aware any content-grep on lint output anywhere in this phase sees at most 5 lines.

**Strengths:** the neutrality treatment (abstract `<concept-slug>`/`<overview-slug>` placeholders for the wiki's own pages, "the derived support type" prose so the negative grep stays meaningful) is precise; the `^\| .pdf.`-anchored "no longer provisional" grep correctly excludes the still-provisional `video` row; the 7-row retro-fit count assertion is robust (confirmed `research-report` appears only in §3, so the count can't drift to 8).

## 20-03-PLAN.md (lint check + --asset + four tests)

**Summary:** The conditional-check shape, bare-filename guard, and `--asset` precondition ordering are all correct against the verified source. The test design correctly avoids the exit-code trap (default-mode lint always exits 0 — verified) and the stderr-capture trap.

**Concerns:**
- **LOW — Content assertions ride on the top-5 findings window.** For a single-page fixture tree this is sound (any finding for the only page must appear in the top 5), but it's an implicit invariant: if a fixture-authoring slip produces 6+ findings, the *target* finding ('extraction' / 'bare co-located') can be pushed out of the printed window and Variant A/C fail for an opaque reason. Add a comment in the test (or assert total finding count first) so a future maintainer debugging a red variant knows only 5 lines print.
- **LOW — `$FIXTURE_PAGE_NAME` referenced in the Variant B assertion is never defined in the plan.** Trivial for the executor to infer, but worth one sentence.
- **LOW — Commit shape unspecified** (same as Plan 01): lint.sh bump (`lint(scope):` per conventions?) vs ingest.sh `--asset` vs four tests — one logical operation or two/three? State it.

**Strengths:** Variant C exercising the path-component guard makes the new lint branch non-vacuous in three directions (missing-field fires, compliant is silent, path violation fires); the before/after `git status --porcelain` comparison is the right isolation proof; the `--contributor` bypass for non-git temp cwd matches the verified `resolve_contributor` behavior exactly.

## 20-04-PLAN.md (E2E validation + DR)

**Summary:** The round-3 post-commit audit redesign is verified correct (the recency selector really does diff committed changes only, and findings really do carry `source_id`+`verdict`). Two residual defects remain, both fixable with a sentence each.

**Concerns:**
- **MEDIUM — The optional completeness check counts claims the audit structurally never samples.** Verified at the source: `audit-claims.sh` **skips `type: source` pages entirely** when building the claim universe ("source summaries are registry entries, not audited claims"). Task 2 step 4 authors `#p`-anchored claims **on the source summary page**, and step 10's completeness check counts `[prov:<source-id>#p` markers "across the new wiki pages." If that count includes the summary page's own claims, findings will *always* be fewer than markers, and the plan's instruction — "if the findings count is LOWER, raise `--sample` and re-run rather than weakening the assertion" — becomes an unsatisfiable loop. Scope the marker count to **non-source topic pages only**, and add a sentence noting the summary-page exclusion.
- **MEDIUM — Crossref-delta baseline is captured too late.** Step 7 says "capture the crossref error count before and after the ingest," but step 7 executes after steps 4–5 have already authored the new pages into the working tree — a sequential executor has no clean way to get the "before" count at that point (today's baseline is 18, but the plan rightly avoids hardcoding it). Move the baseline capture to the top of Task 2 (or immediately after the Task 1 checkpoint), alongside the step-6 `PRE_REF` capture.
- **LOW — Verify-block placeholders.** The `<automated>` block uses `$PRE_REF` and `<source-id>` literally; run verbatim it fails. The comment acknowledges substitution, but the executor contract for `<automated>` blocks is usually "runnable as-is" — consider marking those two lines as requiring substitution more explicitly.

**Strengths:** the post-commit audit ordering with parent-of-ingest-commit `PRE_REF` re-derivation is exactly right per the verified `git diff base...HEAD` selector; the "STOP and request a replacement, never wiki-local fallback" privacy posture correctly preserves PDF-04; treating the `wiki-local/maintenance/` audit writes as expected uncommitted control-plane state matches observed repo behavior (those files are dirty in the working tree right now from a prior audit run); the irreversibility framing on the binary-in-git-history decision is the right emphasis for the human checkpoint.

---

## Cross-Cutting Suggestions

1. **Plan 04, step 10:** restrict the completeness count to topic pages (`grep -rl '\[prov:<source-id>#p' wiki-cloud/{entities,concepts,overviews,comparisons}/` shape), and state that summary-page claims are by-design outside the audit universe.
2. **Plan 04, Task 2:** add "capture crossref baseline" as an explicit step 0/1 action next to nothing-yet-authored state.
3. **Plans 01 + 03:** one sentence each on commit prefix + grouping.
4. **Plan 02, Task 3 step 4:** reword "plain" → "the same `> |` blockquote row format as the surrounding table."
5. **Plan 01 or 02 runbook:** one line documenting that the first page pays the model cold-load inside `PDF_EXTRACT_TIMEOUT`.

## Risk Assessment

**Overall: LOW.**

The plans achieve all four phase requirements with full coverage (PDF-01: Plans 01+02; PDF-02: Plans 02+03; PDF-03: Plan 02; PDF-04: Plans 03+04), honor every locked decision D-01..D-12, and — unusually for round 4 — every load-bearing factual claim I probed checked out exactly (including the "18 crossref errors" count, the template drift, the audit selector's commit-only diff, and the inclusion-audit baseline semantics). The two MEDIUM findings are confined to Plan 04's verification *procedure* (an unsatisfiable optional check and a too-late baseline capture); neither threatens the deliverables themselves, and both are one-sentence fixes. No dependency-ordering, scope-creep, or security issues remain. I'd consider these plans ready for execution after the two Plan 04 amendments.

---

## Codex Review

## Summary

The plans are strong and unusually well-reviewed. They line up with the Phase 20 goals, preserve the “PDF as sub-case” boundary, avoid adding a `pdf` source type, and include good sequencing around lint, routing, neutrality, and human-gated PDF validation. Remaining risks are mostly around test signal quality, shell-script edge cases, and Plan 04’s operational complexity.

## Strengths

- Clear dependency split: tooling/docs in wave 1, enforcement/tests in wave 2, real ingest in wave 3.
- Good preservation of v1.2 progressive-disclosure discipline: `pdf-ingestion.md` is authoritative, `source-types.md` remains a lean pointer.
- Strong avoidance of known pitfalls: no `ollama run`, no unconditional frontmatter fields, no `pdf` enum value.
- Solid local-model hardening in `pdf-extract.sh`: file-based base64 payloads, `curl -fsS`, timeout, model preflight, null/error response guards.
- Good privacy posture for PDF-04: human confirmation remains primary; mechanical cloud-safe guard is not overstated.
- Good lint sequencing: conditional check should not fire on existing sources.

## Concerns

- **MEDIUM: Aggregator hides in-test skips.** `tests/phase-20/run.sh` counts any test exit 0 as PASS, so model-gated skips inside `test_pdf_extract_markers.sh` appear as passed. That weakens the “5/5 passed, 0 skipped” claim.
- **MEDIUM: Plan 01 fixture test may be flaky or slow.** A real 7B VLM call in a default test can be slow, hardware-sensitive, and OCR-output-sensitive. The bypass helps, but it also reduces signal unless CI/local gates explicitly distinguish live vs skipped.
- **MEDIUM: `pdf-extract.sh` image cleanup is fragile.** Reusing `$TMP/page` and selecting `ls "$TMP"/page-*.png | head -1` can pick stale files if `pdftoppm` ever leaves more than one output or a failed iteration leaves residue before abort. Safer to render each page into a per-page prefix or clear matching files before render.
- **LOW: `base64 -w0` is GNU-specific.** This repo appears Linux-oriented, but the runbook should name that expectation or use a portable fallback if macOS support matters.
- **MEDIUM: Plan 03 lint test may depend on incomplete fixture frontmatter.** It says “full required base fields” but does not prescribe exact minimal valid YAML. If authored loosely, unrelated yaml findings can make the test noisy.
- **LOW: `original_asset` path guard may reject valid-looking but unusual filenames inconsistently.** It rejects `/` and startswith `..`, but not names like `..scan.pdf`. That is probably acceptable as a filename, but the convention should be clear that only path traversal/components are banned.
- **MEDIUM: Plan 04 is operationally dense.** It combines acquisition, classification, source-summary authoring, topic-page merge, lint delta checks, commit, audit, index/log updates, DR, and human verification. Correct, but high cognitive load and easy to partially complete.
- **LOW: Plan 04 crossref delta check is underspecified.** “Before and after” needs a precise capture point before new pages are authored, otherwise the comparison can be accidentally taken too late.

## Suggestions

- Make in-test skips machine-readable: have tests emit `SKIP:` and let `run.sh` detect that status, or add a separate required live gate command for Plan 01/04.
- In `pdf-extract.sh`, render with a unique prefix per page, e.g. `$TMP/page-$N`, and select exactly one matching PNG; fail if zero or more than one.
- Add one explicit fixture YAML block to Plan 03 so the lint test cannot accidentally fail for unrelated required-field omissions.
- Add a lightweight static test for `pdf-extract.sh` request construction that does not invoke Ollama, so CI still validates the argv-limit fix.
- In Plan 04, split the pre-ingest baseline instructions into an explicit step before authoring pages: capture yaml/crossref counts and `PRE_REF` before any content mutation.
- Treat the DR as a separate reflect commit, as the plan suggests; it keeps the ingest commit focused and easier to audit.

## Risk Assessment

**Overall risk: MEDIUM.** The architecture and sequencing are sound, and the plans should achieve PDF-01 through PDF-04. The remaining risk is not conceptual; it is execution risk from shell edge cases, test skip semantics, and the complexity of the real ingest/audit workflow in Plan 04. The phase is safe to proceed with after tightening the test signal and `pdf-extract.sh` page-render handling.

---

## Consensus Summary

Both reviewers judge the plan set sound and execution-ready after small amendments — no design flaws, no dependency-ordering, scope, or security issues. Claude rates overall risk **LOW** (every load-bearing factual claim probed against the repo checked out exactly); Codex rates it **MEDIUM**, driven by execution risk in shell edge cases and Plan 04's operational density, not by architecture.

### Agreed Strengths

- **Dependency split and sequencing** — tooling/docs → enforcement/tests → real ingest waves are correct, and the lint conditional-check sequencing won't fire on existing sources (both).
- **`pdf-extract.sh` hardening** — file-based base64 payloads / `--rawfile` argv-limit fix, per-page timeout, model preflight, null/error response guards all called out as correct by both reviewers.
- **PDF-04 privacy posture** — human confirmation primary, mechanical cloud-safe guard not overstated; "STOP and request replacement, never wiki-local fallback" (both).
- **Sub-case boundary discipline** — no `pdf` enum value, `pdf-ingestion.md` authoritative with `source-types.md` a lean pointer, progressive-disclosure preserved (both).

### Agreed Concerns

1. **Plan 04: crossref-delta baseline captured too late** (Claude MEDIUM / Codex LOW). Step 7's "before" count has no clean capture point once steps 4–5 have authored pages. Both prescribe the same fix: an explicit baseline-capture step at the top of Task 2 (alongside `PRE_REF`), before any content mutation.
2. **Test aggregator hides in-test SKIPs** (Codex MEDIUM / Claude INFO). `run.sh` counts SKIP-exit-0 as PASS, so "5/5 passed" on a model-less machine is indistinguishable from a live run. Accepted by design in round 3, but both want the signal made visible — machine-readable `SKIP:` detection (Codex) or at minimum a comment in `run.sh` (Claude).

### Divergent Views

- **Plan 04 completeness check counts unsampled claims** (Claude MEDIUM, source-verified; Codex silent). `audit-claims.sh` skips `type: source` pages, but step 10 counts `#p` markers across all new pages including the source summary — making the "raise `--sample` and re-run" instruction an unsatisfiable loop. Claude's fix: scope the marker count to non-source topic pages only. This is the highest-priority unique finding.
- **`pdf-extract.sh` page-image cleanup fragility** (Codex MEDIUM; Claude silent). `ls "$TMP"/page-*.png | head -1` can pick stale files if `pdftoppm` leaves residue. Codex's fix: per-page render prefix, fail if zero or >1 matches.
- **Commit-shape gaps in Plans 01 and 03** (Claude LOW ×2; Codex silent). Neither plan states its commit prefix/grouping despite the one-commit-per-operation hard rule.
- **Fixture/wording precision** — Claude flags Plan 02's "plain `| ... |`" wording (should say blockquote `> |` rows) and the undefined `$FIXTURE_PAGE_NAME`; Codex flags Plan 03's unprescribed fixture YAML and the GNU-specific `base64 -w0`. Different items, same theme: pin down executor-facing literals.
- **Overall risk**: LOW (Claude) vs MEDIUM (Codex) — the gap is entirely about execution/operational risk in Plan 04 and shell scripting, not design.
