---
phase: 20
reviewers: [claude, codex]
reviewed_at: 2026-06-11T16:38:55+03:00
plans_reviewed: [20-01-PLAN.md, 20-02-PLAN.md, 20-03-PLAN.md, 20-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 20

> Note: this review was requested with `--claude --codex` from within a Claude Code session.
> The Claude review ran as a fresh, independent `claude -p` session (no shared context with
> the planning session), but is the same model family as the planner — weight its agreement
> with the plans accordingly; its *disagreements* are the higher-signal findings.

## Claude Review

# Cross-AI Plan Review — Phase 20: PDF Ingestion (Plans 20-01 … 20-04)

**Review method note:** I verified the plans' load-bearing claims against the live repo rather than taking them on faith. Confirmed accurate: `LINT_VERSION="1.9.1"` at `bin/lint.sh:13`; `SOURCE_EXTRA_FIELDS` and the 7-value `VALID_SOURCE_TYPES`; the `type == 'source'` conditional block at lint.sh:1090–1110 matching the plan's interface excerpt verbatim; the `WIKI_ROOT` env override (lint.sh:94, with prior-art usage in `tests/phase-07` and `tests/phase-15`); `--category` flag; the provisional `pdf` registry row in `source-types.md` §4; decision-page `trigger_type`/`affected_pages` lint checks; `slice_pages`/`insufficient-locator` in `audit-claims.sh`; `tests/phase-18/` as the harness analog; and — importantly — that `bin/ingest.sh` **always** creates a dated bundle dir with `source.md` via cwd-relative paths, so the `--asset` extension composes exactly as planned and the temp-cwd test isolation in Plan 03 works without the hedged fallbacks. One verified discrepancy is material and drives my only HIGH concern (below).

---

## 1. Summary

This is a well-grounded, decision-faithful plan set. All twelve locked decisions (D-01…D-12) trace cleanly to specific tasks; the wave structure is correct (no file overlap between parallel Plans 01/02, real dependencies for 03/04); the anti-patterns the research identified (unconditional `SOURCE_EXTRA_FIELDS` append, `pdf` enum value, `ollama run`, `derived` support type) are explicitly encoded as negative acceptance criteria, which is unusually disciplined. The plans' single systemic weakness is verification fidelity: many "lint stays green" gates invoke `bash bin/lint.sh` in default mode, which I verified **always exits 0 regardless of findings** ("Non-CI, non-strict mode always exits 0" — lint.sh:2802). The phase's own top-ranked risk (never lint red between commits) is therefore guarded by a command that cannot detect red. The second notable gap is error handling in `pdf-extract.sh`'s model loop, where a failed Ollama call silently writes `null` into the output. Both are cheap to fix at execution time.

## 2. Strengths

- **Decision traceability is exemplary.** Every D-xx appears in a `must_haves.truths` entry or task action, and the `key_links` blocks encode the actual integration edges (registry row → convention doc → routing row → byte-synced mirror).
- **Sequencing is correct and verified.** Plan 02 authors `pdf-ingestion.md` (Task 1) *before* the registry row references it (Task 2) and before the routing row (Task 3) — satisfying the forward routing check, which errors on dangling paths. The interim "file exists, no routing row" state only triggers the inverse check, which I confirmed is warning-severity (non-blocking).
- **The conditional lint gate genuinely lands green.** Gating on `original_asset` ending `.pdf` means zero existing source pages are touched (none carry the field) — the data-then-check ordering from Phase 19's lesson is structurally sound, not just asserted.
- **Test isolation strategy is grounded.** `WIKI_ROOT` override exists and has prior-art usage; `ingest.sh`'s cwd-relative `sources/` path makes the temp-cwd isolation in Plan 03 Task 3 work as the primary path, not the fallback.
- **The aggregator-lists-all-five-tests-up-front move** (Plan 01 Task 0) eliminates a cross-plan edit conflict on `run.sh` and is honestly documented as an intentional RED state.
- **Model-gated test design** (skip-not-fail on Ollama unreachable / fixture absent) correctly protects GPU-less CI, mirroring the Phase 13.1 blocked-on-host-runtime precedent.
- **Human checkpoints are placed exactly where autonomy ends** (D-12 PDF supply; final faithfulness spot-check), with concrete resume signals and a "skip" escape hatch.
- **Threat models are proportionate** — localhost-only model calls, `basename`-based traversal mitigation, mktemp isolation — without invented severity.
- **Plans corrected a research error:** RESEARCH points at `tests/phase-19/` as the harness clone source, which does not exist; the plans correctly use `tests/phase-18/`.

## 3. Concerns

- **HIGH — "lint green" gates are vacuous as written.** Verified: default `bin/lint.sh` exits 0 even with error-severity findings; only `--ci` or `--strict` produce exit-1-on-error. Affected: Plan 02 Task 2 verify (`bash bin/lint.sh >/dev/null 2>&1`), Plan 03 Task 1 verify and acceptance ("`bash bin/lint.sh` exits 0 against the current repo"), Plan 04 Task 2/3 verifies, and every acceptance criterion of the form "`bash bin/lint.sh` exits 0 (no red between commits)". These all pass *unconditionally*. The pre-commit hook and CI presumably run in CI mode so the real gates still exist, but the plans' inline self-verification — the mechanism the executor actually consults — gives false assurance on the phase's own #1 stated risk. Same issue may afflict Plan 03's `test_pdf_extraction_fields.sh` if the test author leans on exit codes (the plan does instruct output-grepping for Variant A, but Variant B "assert NO PDF-extraction finding" needs explicit output/JSON inspection too).
- **MEDIUM — `pdf-extract.sh` silently ingests model-call failures.** `curl -s` (no `-f`) against `/api/generate` returns an `{"error": ...}` body on a missing/unloaded model; `jq -r '.response'` then yields the string `null`, which the loop writes under a valid page marker. The preflight only probes `/api/tags` reachability, not presence of `$MODEL`. With `set -euo pipefail` nothing aborts. Result: a structurally valid, marker-aligned output file full of `null` — the worst failure mode for a provenance system because it passes the marker-count sanity check. The post-loop marker≠pages warning won't catch it.
- **MEDIUM — `tests/phase-20/run.sh` is deliberately red for the whole Wave-1→Wave-2 window.** Defensible as RED→GREEN honesty, but it contradicts RESEARCH's own sampling contract ("Per wave merge: `bash tests/phase-20/run.sh`" — which cannot pass at the Wave-1 merge), and any cross-phase full-suite run during the window reports failures that look like regressions. The mitigation is only a NOTE inside Task 0's action text; it should be surfaced in the Wave-1 gate definition.
- **MEDIUM — committing a binary PDF to git history is effectively irreversible.** The cloud-safety judgment is a one-shot human confirmation at Task 1; if it's later revised, the PDF persists in history (rewrite required). The repo's posture mitigates this (local `main` is never pushed; origin receives only the neutralized orphan-branch release), but the plan doesn't state that the release workflow excludes `sources/` — worth one explicit line in Plan 04's privacy step. Also unstated: ~5–30 page PDFs are fine, but no size guard exists (`--asset` will happily co-locate a 200 MB file).
- **LOW — Plan 03 Task 3's "git status clean" acceptance can be dirtied by lint itself.** Default-mode lint runs in earlier verify steps regenerate `wiki-cloud/maintenance/lint-report.md` (text mode writes the report unless `--dry-run`). If report content shifts (counts, dates), `git status --porcelain wiki-cloud/` is non-empty for reasons unrelated to test isolation.
- **LOW — Plan 01 Task 1's verify can't fail on a broken `--help`.** `bin/pdf-extract.sh --help >/dev/null 2>&1; echo "syntax+help exit ok"` — the trailing `echo` makes the compound succeed regardless.
- **LOW — Plan 04 acceptance uses `sources/**/source.md`**, which requires `shopt -s globstar` (off by default in bash); as written the check may silently not match. Use `find` instead.
- **LOW — `extraction_date` discretion resolved implicitly.** RESEARCH recommended collapsing into `ingested_at`; the plans keep all four fields consistently (lint check, frontmatter doc, tests, DR), which is fine — but no artifact records *why* the keep-both option won. One sentence in the DR or `pdf-ingestion.md` closes it.
- **LOW — model-probe granularity.** The skip-gate probes server reachability only; a machine with Ollama but without `richardyoung/olmocr2:7b-q8` (plus a future fixture PDF) would run the live assertion and fail rather than skip.

## 4. Suggestions

1. **Make every lint gate exit-code-meaningful.** Replace `bash bin/lint.sh` in verify/acceptance commands with `bash bin/lint.sh --ci` (or `--strict`), or assert on `--format json` output via `jq '[.[] | select(.severity=="error")] | length == 0'`. For Plan 03's fixture test, explicitly mandate output/JSON assertions in both variants and forbid bare-exit-code reliance.
2. **Harden the `pdf-extract.sh` model call** (still thin glue): preflight `curl -sf "$OLLAMA_URL/api/tags" | jq -e --arg m "$MODEL" '.models[].name | select(. == $m)'` to fail loud on a missing model; per-page, capture the full response, check `jq -e '.error'` and `.response != null`, and on failure abort with the page number rather than appending. Optionally count non-empty pages in the final summary.
3. **Strengthen the model-gated test probe** to also check the model tag in `/api/tags` before exercising the live path (skip with a distinct message if the model is absent).
4. **State the Wave-1 gate explicitly:** "Wave-1 exit = `bin/lint.sh --ci` green + `test_pdf_extract_markers.sh` green individually; `run.sh` 5/5 is a Wave-2 exit criterion." This reconciles the intentional RED window with the sampling contract.
5. **In Plan 04 Task 1, add one verification line** confirming the release/publish path excludes `sources/` (or that the artifact is acceptable in the orphan-branch release), and consider an informal size sanity check (`du -h`) alongside `pdfinfo`.
6. Swap the globstar acceptance check for `find sources -name source.md -exec grep -l '^<!-- page:' {} +`, and drop the trailing `echo` from Plan 01 Task 1's verify so `--help` failures actually fail.
7. Have the DR (Plan 04 Task 3) record the `extraction_date`-kept-distinct rationale in one sentence — it's the only Claude's-discretion item the plans resolve without leaving a trace.

## 5. Risk Assessment

**Overall: LOW-to-MEDIUM (MEDIUM as written; LOW after fixing the lint-gate commands).**

The design risk is genuinely low: this is convention engineering over verified primitives, the dependency ordering is correct, every locked decision is faithfully encoded, and I could not find a sequencing path that lints red in CI mode. The residual risk concentrates in two execution-time blind spots — self-verification commands that cannot fail (HIGH concern, trivially fixed by adding `--ci`), and silent `null`-page output from an unhandled model-call failure (MEDIUM, ~10 lines of shell). Plan 04's human checkpoints appropriately fence the only irreversible action (committing a real PDF). Nothing here suggests the plans would fail to achieve the four phase requirements; the fixes are surgical and should be applied before or during execution rather than via re-planning.

---

## Codex Review

## Summary

The plans are well-structured and mostly achieve Phase 20’s goals: they preserve PDF as a format-orthogonal acquisition sub-case, reuse the existing `#p` locator system, add thin acquisition glue, enforce frontmatter mechanically, and reserve the real end-to-end ingest for a human-gated validation artifact. The main risks are execution details: shell/Ollama failure handling, test sequencing that may leave the repo red between waves, template-public neutrality around real wiki paths, and Plan 04 mixing human-blocked validation with schema decision-record work.

## Strengths

- Clear wave ordering: acquisition/doc work first, enforcement/tooling second, real ingest last.
- Correct architectural choice: PDF remains a sub-case, not a new `source_type`.
- Good reuse of existing primitives: `<!-- page: N -->`, `#p<N>`, `audit-claims.sh`, `ingest.sh`, routing lint, sync gates.
- Conditional lint check is scoped correctly to `original_asset: *.pdf`, avoiding existing-source breakage.
- Human checkpoint for PDF-04 is appropriate because `sources/` is cloud-safe-only.
- Threat models are practical and tied to the actual trust boundaries.

## Concerns

- **HIGH — Template-public neutrality risk in Plan 20-02.** `pdf-ingestion.md` is template-public, but the plan asks it to cite real `wiki-cloud/...` paths such as `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md`. That appears to conflict with the AGENTS.md rule forbidding real private wiki slugs/terms in template-public files. This needs an explicit exception or placeholder strategy.

- **HIGH — `pdf-extract.sh` can silently emit bad output.** Plan 20-01 uses `curl -s ... | jq -r '.response'` without `curl -f`, `.error` handling, model-existence validation, or null/empty response checks. Ollama failures could produce `null` text under valid page markers, which would look structurally correct but semantically broken.

- **HIGH — Plan 20-04 fallback to `wiki-local/` does not satisfy PDF-04.** If the supplied PDF is not cloud-safe, the plan says to route to `wiki-local/`. That is privacy-safe, but it fails the phase requirement requiring one cloud-safe PDF in `sources/`. Better to stop and request a replacement PDF.

- **MEDIUM — Plan 20-01 intentionally creates a failing aggregator.** `tests/phase-20/run.sh` references four missing tests until Plan 20-03. If any CI, local script, or GSD verifier runs phase tests between waves, the repo is knowingly red. That conflicts with the “no red between commits” posture elsewhere.

- **MEDIUM — AGENTS.md inclusion-audit baseline is not mentioned.** Adding a routing row changes the resident core. The AGENTS.md header says to justify added lines and update the inclusion-audit baseline; Plan 20-02 only syncs CLAUDE.md.

- **MEDIUM — `ingest.sh --asset` overwrite semantics are under-specified.** Plain `cp` overwrites by default on GNU systems, so the proposed `--force` distinction may not actually protect existing assets. Also reject asset basenames like `source.md` to avoid clobbering the ingested source.

- **MEDIUM — Test isolation assumptions are brittle.** Plan 20-03’s acceptance requires `git status --porcelain sources/ wiki-cloud/` to be empty after tests, which can fail in a dirty worktree unrelated to the test. Also, running `ingest.sh` from a temp cwd only works if the script does not force repo-root paths.

- **MEDIUM — Plan 20-04 audit verification is too vague.** `bash bin/audit-claims.sh 2>/dev/null | tail -5` hides errors and does not prove the new source’s `#p` locators resolved. It should target the new source and assert no `insufficient-locator`.

- **LOW — Some acceptance greps are fragile.** For example, forbidding `support_type: derived` may fail if the doc includes an anti-pattern sentence. Source-type enum greps may miss multiline definitions.

## Suggestions

- Make `pdf-extract.sh` fail loud: use `curl -fsS`, check `/api/tags` for the configured model, detect `.error`, reject `null` responses, validate `PAGES` is a positive integer, and write to a temp output before replacing the final file.

- Avoid a red Plan 20-01 test harness by either creating placeholder skip tests, making missing tests skip until authored, or letting Plan 20-03 add the final aggregator entries.

- Resolve the neutrality issue before implementation: either avoid real wiki-cloud slugs in `schema/reference/pdf-ingestion.md`, use placeholders, or document a deliberate exception and ensure the neutrality gate agrees.

- Add the AGENTS.md/CLAUDE.md inclusion-audit baseline update to Plan 20-02.

- Strengthen `--asset`: reject missing/non-file assets, reject basename `source.md`, prevent overwrite unless `--force`, and define `original_asset` as bundle-relative.

- For tests, prefer explicit temp roots or add a `SOURCES_ROOT` override to `ingest.sh`. Compare git status before/after instead of requiring a globally clean tree.

- Move the schema-update decision record out of human-blocked Plan 20-04, or split it into an autonomous reflect plan after Plans 20-01 through 20-03. If it remains in Plan 20-04, also update `wiki-cloud/index.md` and `wiki-cloud/log.md` for the decision page.

- In Plan 20-04, if the PDF is not cloud-safe, abort PDF-04 and ask for another artifact rather than routing to `wiki-local/`.

## Risk Assessment

**Overall risk: MEDIUM.** The architecture is sound and the phase goals are achievable, but the execution plans need tightening around failure detection, neutrality, test sequencing, and end-to-end verification. With the suggested fixes, risk drops to low-to-medium because most primitives already exist and the remaining work is scoped shell glue plus schema wiring.

---

## Consensus Summary

Both reviewers judge the architecture sound and the phase goals achievable — the risk concentrates in execution-time failure detection, not design. Neither reviewer recommends re-architecting; both recommend surgical tightening before/during execution.

### Agreed Strengths

- **Format-orthogonal sub-case verdict is correct** — PDF stays an acquisition-path sub-case, never a new `source_type` enum value; anti-patterns encoded as negative acceptance criteria.
- **Wave ordering and dependency structure are correct** — convention/doc work before enforcement, real ingest last; no file overlap between parallel Wave-1 plans.
- **Conditional lint gate is scoped correctly** — fires only on `original_asset: *.pdf`, so zero existing sources are touched (data-then-check ordering lands green).
- **Strong reuse of verified primitives** — `<!-- page: N -->` grammar, `#p<N>` locators, `audit-claims.sh`, `ingest.sh`, routing lint, sync/neutrality gates.
- **Human checkpoints placed exactly where autonomy ends** (user-supplied cloud-safe PDF; final faithfulness spot-check).
- **Threat models are proportionate and tied to real trust boundaries** (localhost-only model calls, basename traversal guard, mktemp isolation).

### Agreed Concerns

1. **`bin/pdf-extract.sh` can silently emit broken output** (Claude MEDIUM / Codex HIGH — highest-priority shared finding). `curl -s` without `-f` + `jq -r '.response'` writes the literal string `null` under structurally valid page markers when the model is missing or a call fails; the marker-count sanity check cannot catch it. Fix: preflight the model tag in `/api/tags`, use `curl -fsS`, check `.error` and reject null/empty responses, abort loud with the failing page number.
2. **Verification commands that cannot fail** (Claude HIGH: default `bin/lint.sh` always exits 0 — verified against lint.sh:2802; Codex MEDIUM: `audit-claims.sh 2>/dev/null | tail -5` proves nothing about the new source). All "lint green"/audit gates must use `--ci`/`--strict` or assert on JSON/output content, and the Plan 04 audit step should target the new source and assert no `insufficient-locator`.
3. **Intentionally red `tests/phase-20/run.sh` during the Wave-1→Wave-2 window** (both MEDIUM). Defensible RED→GREEN honesty, but it contradicts the per-wave sampling contract and looks like a regression to any cross-phase suite run. Fix: define the Wave-1 exit gate as individual-test green (not 5/5 aggregate), or make missing tests skip until authored.
4. **Test-isolation acceptance criteria are brittle** (Claude LOW / Codex MEDIUM). `git status --porcelain` cleanliness can be dirtied by lint's own report regeneration or a pre-dirty worktree; compare before/after status instead of requiring a globally clean tree.

### Divergent Views

- **Neutrality of real `wiki-cloud/` slugs in `pdf-ingestion.md`** — Codex HIGH (citing `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md` in a template-public schema file appears to violate the AGENTS.md placeholder rule); Claude did not flag. Worth resolving explicitly: placeholder, or documented exception that the neutrality gate accepts.
- **`wiki-local/` fallback in Plan 04** — Codex HIGH: routing a non-cloud-safe PDF to `wiki-local/` is privacy-safe but *fails PDF-04* (which requires the artifact in cloud-safe `sources/`); better to stop and request a replacement PDF. Claude did not flag.
- **Vacuous self-verification severity** — Claude rates the exit-0 lint gates its only HIGH (verified in repo source); Codex did not examine lint exit semantics.
- **Smaller single-reviewer items** — Claude: globstar in Plan 04 acceptance (`sources/**/source.md` silently no-ops), trailing `echo` masks `--help` failures, record the `extraction_date`-kept rationale in the DR. Codex: AGENTS.md inclusion-audit baseline not updated by Plan 02, `--asset` overwrite semantics under-specified (reject `source.md` basename, no-overwrite without `--force`), move the DR out of the human-blocked Plan 04 or also update index/log.

### Net Assessment

Overall risk **MEDIUM as written → LOW after fixes**. Recommended action: `/gsd-plan-phase 20 --reviews` to fold in the agreed concerns (1–4) plus the two Codex-only HIGH items (neutrality strategy, wiki-local fallback).
