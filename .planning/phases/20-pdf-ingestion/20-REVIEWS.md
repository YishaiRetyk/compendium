---
phase: 20
reviewers: [claude, codex]
reviewed_at: 2026-06-11T18:18:23+03:00
review_round: 3
plans_reviewed: [20-01-PLAN.md, 20-02-PLAN.md, 20-03-PLAN.md, 20-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 20 (Round 3)

## Claude Review

All verification is done. The plans' factual claims almost all check out against the repo — with one significant exception in Plan 04's audit assertions, which I confirmed at source level. Here is the review:

---

# Cross-AI Plan Review — Phase 20: PDF Ingestion (Round 3)

**Reviewer note on method:** I verified the plans' load-bearing factual claims directly against the repo rather than reviewing prose alone. Confirmed true: `bin/lint.sh` `--ci`/`--dry-run`/`--category` compose with meaningful exit codes; unscoped `--ci --dry-run` **is** red today (exit 1, crossref) while `--category yaml` is green — the round-2 scoped-gate posture is accurate; `WIKI_ROOT` override exists (`lint.sh:94`) and Plan 03's fixture layout matches it; `bin/ingest.sh --contributor` exists and short-circuits git resolution; `bin/check-sources-cloud-safe.sh` exists; the AGENTS.md inclusion-audit baseline (288) equals today's line count; `schema/AGENTS.template.md` really does lack the source-types row (the Phase 19 drift claim is true); the provisional `pdf` row sits at `source-types.md:49` exactly as quoted; the 7-row retro-fit grep count is exactly 7 today and won't collide with §4 registry rows; `--emit-worklist` does write `audit-report.md` + `audit-state.md`; and `ingest.sh` writes only the bundle, so the temp-cwd test isolation is sound. **One critical claim does not hold** — see Plan 04.

---

## Plan 20-01 — pdf-extract.sh + test harness

### Summary
A well-grounded tooling plan. The Ollama invocation design (HTTP `/api/generate`, file-based payload I/O via `--rawfile` + `-d @file`, two-stage preflight, null-response guards, atomic temp-output-then-move, same-loop-variable marker emission) addresses every realistic failure mode of the extraction loop, and the prior review rounds' fixes (argv limit, `grep -c || true`, model-tag probe) are all technically correct. The committed-fixture decision closes the "loop untested until Wave 3" gap properly.

### Strengths
- The `--rawfile`/`-d @file` payload path is the correct fix for the MAX_ARG_STRLEN problem; the acceptance criteria (`! grep -q -- '--arg img'`) mechanically prevent regression to the broken form.
- Fail-loud-per-page with mandatory marker emission for *empty* (but not *null*) pages is exactly the right distinction for a provenance system — a blank page keeps slices aligned; a failed call aborts rather than writing `null` under a valid marker.
- The aggregator's SKIP-for-unauthored-tests design keeps the suite green across the Wave-1→Wave-2 window with an honest skip count as the signal — clean solution to the "aggregator references future tests" problem.
- Marker-count-vs-`pdfinfo` sanity check catches off-by-one/blank-page drift (Pitfall 3) deterministically, independent of model output quality.

### Concerns
- **MEDIUM — No timeout on the per-page model call.** `curl -fsS` has no `--max-time`. A wedged Ollama server (or a cold model load on a slow machine) hangs the script — and therefore the live test, and therefore `run.sh` — indefinitely. The preflight `/api/tags` probe doesn't protect against a hang mid-generation.
- **MEDIUM — Live-test cost on every suite run.** On this machine (model + fixture present), every `tests/phase-20/run.sh` invocation runs 2 real 7B-VLM inferences. The phase's own sampling contract runs the aggregator per wave merge and per phase gate, and Plan 03 reruns it; that's potentially minutes of inference per verification cycle. The assertion itself is loop-deterministic (marker count, not content), so repeated live runs add latency without adding signal after the first pass.
- **LOW — Generic environment-variable names.** `MODEL`, `DPI`, `PROMPT`, `OUT` as env-overridable defaults are collision-prone (`MODEL` especially is commonly set in CI/agent environments) and would silently change behavior. 
- **LOW — Raw-PDF-bytes fixture generation is fiddly.** Hand-computing xref byte offsets in inline python is the most error-prone way to make a 2-page PDF. `ps2pdf` is present on this machine (verified); two lines of PostScript piped through it is far simpler, and since the fixture is committed once, generation tooling portability doesn't matter.
- **LOW — TDD ordering inconsistency.** Task 2 is marked `tdd="true"` with a RED→GREEN note ("run the test before Task 1's script exists"), but it's sequenced *after* Task 1. Cosmetic, but an executor following task order can't actually observe RED.

### Suggestions
- Add `--max-time` (e.g., 300s/page, env-overridable) to the generation curl, and a corresponding note in `usage()`.
- Namespace the env overrides (`PDF_EXTRACT_MODEL`, `PDF_EXTRACT_DPI`, …) or make flags the only override surface.
- Add a cheap live-test bypass (`PDF_EXTRACT_SKIP_LIVE=1` → SKIP path) so routine suite runs don't pay 2 inferences; keep the live path as the default for wave gates.
- Generate the fixture with `ps2pdf` instead of hand-rolled PDF objects; keep the `pdfinfo` Pages:2 verification either way.

### Risk: **LOW**

---

## Plan 20-02 — pdf-ingestion.md + schema wiring

### Summary
The strongest plan of the four. It encodes every locked decision (D-01..D-09) into concrete, greppable artifacts, mirrors the Phase 19 worked-instance structure deliberately, and its trickiest constraints — neutrality of template-public surfaces while *referencing* real wiki pages, the inclusion-audit baseline update, and the AGENTS.template.md drift repair — are all handled with verified-correct mechanics. The "write 'the derived support type' in prose so the negative grep stays meaningful" instruction is the kind of detail that makes acceptance criteria actually trustworthy.

### Strengths
- The abstract-placeholder treatment of the wiki's own overview/concept slugs (read for content, never embed the slug) resolves the genuine tension between D-04 ("cite the wiki's own SOTA overview") and the neutrality MUST-NOT — with a negative grep to enforce it.
- The provisional-row negative grep is correctly anchored to the table row (`! grep -E '^\| .pdf.' … | grep -q provisional`) so the still-provisional `video` row can't break it — and I verified the current row shapes make this anchor valid.
- The inclusion-audit acceptance criterion (`grep -oP 'inclusion-audit: \K[0-9]+'` == `wc -l`) is satisfiable: the baseline is exactly in sync today (288/288), so the only delta is the row being added.
- The template drift repair (adding both the missing Phase 19 `source-types.md` row and the new row to `AGENTS.template.md`) fixes a real, verified gap rather than an assumed one.
- `extraction_date`-vs-`ingested_at` is resolved *and the rationale is recorded in the shipped doc*, not just in planning artifacts — closing the research open question durably.

### Concerns
- **LOW — Commit granularity is underspecified.** Task 1 (file), Task 2 (three edits), Task 3 (routing + sync + template) read as separately verifiable units, but the project rule is one commit per logical operation. If Tasks 1–3 commit separately, the window between Task 1's and Task 3's commits has `pdf-ingestion.md` existing without a routing row — the routing category's inverse orphan-file check is warning-severity (Phase 17 design), so this shouldn't go red, but the plan never states whether this is one `schema:` commit or three.
- **LOW — Line-number anchors will drift.** Several edit anchors are cited to specific lines (frontmatter.md L67/L69, ingest.md L18). The content anchors given alongside them are sufficient; executors should trust those over the numbers.

### Suggestions
- State explicitly that Tasks 1–3 land as a single `schema:` commit (the natural reading of "one logical operation," and it makes the routing-points-at-existing-file guarantee trivial).

### Risk: **LOW**

---

## Plan 20-03 — conditional lint check + ingest --asset + four tests

### Summary
Solid enforcement plan with correct anti-pattern guards (no `SOURCE_EXTRA_FIELDS` append, no enum addition), correct data-then-check ordering, and a genuinely defensive `--asset` design (all preconditions validated before any tree mutation). I verified the things this plan stakes its tests on: the `WIKI_ROOT` override exists and the fixture layout (`$TMP/sources/`) matches lint's scan-root semantics; `--contributor` short-circuits the git pipeline that would otherwise kill the temp-cwd test; and ingest.sh writes nothing outside the bundle, so the isolation and before/after-porcelain assertions are sound.

### Strengths
- The bare-co-located-filename guard on `original_asset` (with its own test variant C) closes a real convention hole that suffix-only matching would have left.
- Output-content-based lint assertions (with the explicit "default-mode lint always exits 0" warning, verified accurate) instead of exit-code assertions — and variant B's zero-yaml-findings-overall check prevents a fixture-authoring bug from masking the real assertion.
- The `--asset` precondition block runs before `mkdir -p` — no partial bundles — and the explicit existence-vs-`--force` check (rather than `cp` flag semantics) is correct for GNU cp's overwrite-by-default behavior.
- The before/after `git status --porcelain` comparison (rather than absolute cleanliness) is robust to the already-dirty worktree, which is in fact dirty right now.

### Concerns
- **LOW — Redundant guard clause.** `if '/' in oa or oa.startswith('..')` — the second condition is unreachable for any path that the first doesn't already catch (`../x.pdf` contains `/`); only a pathological bare `..something.pdf` hits it. Harmless, but the comment shouldn't imply it carries weight.
- **LOW — `FORCE` variable convention assumed.** The snippet uses `[ "${FORCE:-0}" != "1" ]`; the plan hedges correctly, but the executor must confirm how `bin/ingest.sh` actually represents `--force` (the interfaces block lists `FORCE` as a state var without its value convention) and match it rather than introduce a parallel convention.
- **LOW — Variant B page-name grep is slightly brittle.** `! echo "$OUTPUT" | grep -q "$FIXTURE_PAGE_NAME"` depends on lint's output never echoing scanned-file names outside findings. Scoped to `--category yaml` this holds today, but a future verbose line would false-fail the test. Anchoring on the finding prefix (e.g., `\[error\].*$FIXTURE_PAGE_NAME`) would be more precise.

### Suggestions
- In variant B's assertion, match the finding-line shape rather than the bare page name.
- Have the lint test invoke with `--dry-run` as well — it writes `$TMP/maintenance/lint-report.md` otherwise (harmless in a temp dir, but `--dry-run` makes the test's read-only intent explicit).

### Risk: **LOW**

---

## Plan 20-04 — end-to-end validation ingest

### Summary
The checkpoint design, privacy handling (irreversible-binary-in-git framing, no-wiki-local-fallback rule), cloud-safe mechanical backstop, and DR task are all well-constructed. However, the plan's machine verification of the phase's core promise — that `#p` locators on the new source actually resolve — is broken in two confirmed ways: the worklist-based "no insufficient-locator" assertion is structurally vacuous, and the audit-before-commit sequencing means the selection assertion will likely fail spuriously. This is the same class of defect (vacuous gate) that Phase 19's verification cycle caught in D-08, and it's in the step the plan explicitly labels as its round-2 anti-vacuity fix.

### Strengths
- Task 1's checkpoint is unusually well-specified: page-count range check, size sanity with the "binary in git history is effectively permanent" framing, and an explicit skip path.
- The "STOP and request a replacement — never a wiki-local fallback" rule correctly distinguishes privacy-safe from requirement-satisfying (a wiki-local ingest would pass privacy and fail PDF-04).
- `check-sources-cloud-safe.sh` as a post-ingest mechanical backstop (verified to exist) doubles as the first compatibility test of that guard against a binary-asset bundle — good dual use.
- The crossref *delta* check (after ≤ before) rather than an absolute gate is the right call given the verified-red pre-existing crossref backlog.
- The DR task records the `extraction_date` rationale and is wired into index/log — closing the research open questions visibly.

### Concerns
- **HIGH — The worklist `verdict` assertion is vacuous (confirmed at source).** `--emit-worklist` entries contain `path, line, source_id, locator, claim, passage, support_type, privacy` — **no `verdict` key** (`audit-claims.sh` header: "emit-worklist (JSON, no verdict)"). Claims whose locator fails to resolve hit `add_finding('insufficient-locator', …); continue` *before* `worklist.append` — they never appear in the worklist at all. Therefore `jq '[.[] | select(.source_id == $sid and .verdict == "insufficient-locator")] | length == 0'` **can never fail**, for any input, ever. The failure it's meant to catch manifests as *absence* from the worklist, which the companion `length > 0` check doesn't detect either: one resolvable claim out of twenty passes both assertions while nineteen locators are broken.
- **HIGH — Audit-before-commit sequencing defeats the selection assertion.** The recency selector resolves changed pages via `git diff --name-only {base_ref}...HEAD` (`audit-claims.sh:582`) — **committed changes only**. The plan runs VERIFY at step 6 with `PRE_REF = HEAD` taken pre-commit, and COMMIT at step 9. At step 6, `PRE_REF...HEAD` is empty; the new pages get no recency hit, and clean `sourced`/`direct` claims hit none of the other selectors (not stale, not low-epistemic, not derived-report). The worklist will most likely contain zero entries for the new source and the `length > 0` assertion fails — a false negative that invites the executor to "fix" the assertion, compounding the vacuity above.
- **MEDIUM — The crossref delta check may require out-of-scope-looking edits.** New pages sharing domains/tags with existing pages can create *new* "missing cross-reference" errors that are only resolvable by adding backlinks to *existing* pages. That's a normal part of the merge pass, but the plan should say so, or an executor may read the delta failure as a regression rather than as "finish the merge."
- **LOW — `$PRE_REF` and `<source-id>` placeholders in the `<automated>` verify block** require executor substitution and a shell where `PRE_REF` survives; a fresh verification session re-deriving `PRE_REF` post-commit needs `git log` archaeology. State how to re-derive it (e.g., the commit before the `ingest(<slug>)` commit).

### Suggestions
- **Rework step 6 into a findings-based, post-commit check.** Concretely: commit the ingest (step 9) first, *then* run `bash bin/audit-claims.sh --since "$PRE_REF" --sample 100 --format json` and assert over **findings** (which carry both `source_id` and `verdict` per record — verified): (a) `[.[] | select(.source_id == $sid)] | length > 0` (selection happened — recency now fires because the commit exists), and (b) `[.[] | select(.source_id == $sid and .verdict == "insufficient-locator")] | length == 0`. In no-verifier mode, resolvable claims yield the `insufficient`/"verifier not run" placeholder, so (a)+(b) together are exactly "selected and all locators resolved," non-vacuously. If a pre-push audit is wanted, run it after the commit but before push — the ordering constraint is commit-then-audit, not push-then-audit.
- Optionally add a stronger completeness check that doesn't depend on selectors at all: count `[prov:<sid>#p` markers across the new wiki pages and compare against the source-scoped findings count — proves no claim escaped the sample.
- Add one sentence to step 7 noting that resolving new crossref errors by backlinking existing pages is part of the merge pass, not scope creep.

### Risk: **MEDIUM-HIGH** as written (the phase's only end-to-end requirement is machine-verified by an assertion pair that cannot fail for the right reason and will fail for the wrong one). Drops to **LOW** with the contained step-6 rework — nothing else in the plan depends on it.

---

## Overall Risk Assessment: **MEDIUM**

Plans 01–03 are execution-ready: their claims are verified against the repo down to flag semantics and line anchors, dependency ordering is sound (Wave 1 plans touch disjoint files; Plan 03's tests consume both Wave 1 outputs; Wave 3 is correctly human-gated), scope matches the milestone's "thin glue" constraint with no creep, and the security/threat treatment (argv-safe JSON assembly, basename-derived destinations, fail-closed privacy) is proportionate. The phase achieves PDF-01..03 as planned.

The single material defect is Plan 04's verification step for PDF-04: a structurally vacuous worklist assertion plus an audit/commit ordering error — ironically in the exact spot the plan marks as its round-2 anti-vacuity fix. The fix is small and fully specified above (findings-based `--format json` assertions, run post-commit). I recommend one more revision pass on Plan 04 only; Plans 01–03 need no further review rounds — the four LOW/MEDIUM suggestions there (curl timeout, namespaced env vars, live-test bypass, ps2pdf fixture) can be applied at execution time without re-review.

---

## Codex Review

**Summary**

The plans are strong overall: they respect the Phase 19 contract, keep PDF as a format-orthogonal sub-case, avoid the `source_type: pdf` trap, and include unusually good safeguards around argv limits, missing Ollama models, lint scoping, and neutrality. I would not execute them unchanged, though. Two issues need correction first: Plan 02 changes `schema/AGENTS.template.md` but does not regenerate `schema/fixtures/canonical-AGENTS.md`, which will break setup-parity CI; Plan 04’s audit step runs before the ingest commit even though `audit-claims.sh --since` selects changed pages via `git diff <ref>...HEAD`, so uncommitted new pages will not be selected.

**Strengths**

- Good architecture fit: PDF is correctly modeled as an acquisition-path sub-case, not a new enum.
- The `pdf-extract.sh` design handles the real argv-size failure mode by using `--rawfile` and `-d @file`.
- Lint enforcement is conditional and avoids making existing source pages red.
- `ingest.sh --asset` is scoped to pure file I/O, preserving the script charter.
- Plans correctly avoid unscoped full-lint gates where known crossref backlog exists.
- Plan 04 correctly treats human cloud-safety confirmation as a blocking checkpoint.
- Audit plan correctly avoids the invalid `--select <source-id>` idea and uses worklist filtering.

**Concerns**

- **HIGH — Plan 02:** `schema/AGENTS.template.md` is edited, but `schema/fixtures/canonical-AGENTS.md` is not listed or regenerated. Existing setup-parity tests explicitly require fixture regeneration after template changes.
- **HIGH — Plan 04:** The source-scoped audit assertion is ordered before commit. `audit-claims.sh --since` uses committed `HEAD` diffs, so new uncommitted wiki pages may not enter the recency selector at all.
- **MEDIUM — Plan 04:** Wiki authoring should explicitly read `schema/reference/page-types.md`, `schema/reference/log-format.md`, and `schema/reference/privacy.md`; the current read list is too light for creating source/topic pages and log/index entries.
- **MEDIUM — Plan 01:** The marker-count test can pass even if OCR returns empty text under every marker. That proves alignment, not useful Markdown extraction.
- **MEDIUM — Plan 01/04:** Live Ollama calls have no timeout or max-duration guard. A bad page/model/server state can hang local execution or CI-like environments with Ollama present.
- **LOW — Plan 03:** The lint fixture test is output-grep based. JSON output with `--ci --format json` would be less brittle and avoid default-mode exit-code confusion.
- **LOW — Plan 04:** `check-sources-cloud-safe.sh` only mechanically checks raw source Markdown frontmatter and `sources/local-only/`; it does not inspect binary PDF content. The plan mostly knows this, but its wording slightly overstates the guard.

**Suggestions**

- Add `schema/fixtures/canonical-AGENTS.md` to Plan 02 `files_modified`, regenerate it with `bin/init-wizard.sh`, and run `tests/phase-08/test_canonical_byte_equality.sh`.
- In Plan 04, either run the audit after the ingest commit using `PRE_REF` as the previous commit, or add a temporary/staged selection mechanism. As written, the “new source was selected” assertion is not reliable.
- Add a fixture OCR content assertion in Plan 01: for the 2-page sample PDF, require non-marker body text and ideally a fuzzy match for “Phase 20 fixture page”.
- Add `curl --max-time` or a script-level timeout option to `pdf-extract.sh`; use it in tests.
- Prefer JSON lint assertions in Plan 03, and add negative `--asset` tests for missing asset, `source.md` basename, existing asset without `--force`, and no partial bundle.
- In Plan 04, explicitly keep `wiki-local/maintenance/*` audit mutations uncommitted unless the repo’s established local practice says otherwise.
- Keep the validation ingest small: source summary plus the minimum topic-page updates needed to prove `#p|direct` provenance.

**Risk Assessment**

Overall risk is **MEDIUM**. The design is sound and the plans are unusually complete, but Plan 02 has a likely CI failure and Plan 04 has a concrete audit-ordering bug. After fixing those, Plan 20-01 is medium risk because of local-model runtime behavior, Plan 20-02 becomes low risk, Plan 20-03 is low-to-medium risk, and Plan 20-04 remains medium because it depends on a human-supplied PDF and real OCR quality.

---

## Consensus Summary

Both reviewers rate the phase **MEDIUM** overall and agree Plans 01–03 are close to execution-ready while Plan 04's verification step needs one more revision pass. Two HIGH concerns survive round 3 — one shared, one Codex-only but verified against the repo by the orchestrator.

### Agreed Strengths

- **PDF as a format-orthogonal sub-case, not a new enum** — both reviewers confirm the plans respect the Phase 19 extension contract and avoid the `source_type: pdf` trap.
- **The `--rawfile` + `-d @file` payload path in `pdf-extract.sh`** correctly solves the argv-size (MAX_ARG_STRLEN) failure mode, with acceptance criteria that prevent regression.
- **Scoped lint gates** — plans correctly avoid unscoped full-lint gates given the verified-red pre-existing crossref backlog.
- **Plan 04's human checkpoint and privacy handling** — the blocking cloud-safety confirmation, the irreversible-binary-in-git framing, and the no-wiki-local-fallback rule are well-constructed.
- **`ingest.sh --asset` defensive design** — preconditions validated before any tree mutation, scoped to pure file I/O.

### Agreed Concerns

1. **HIGH (both) — Plan 04 audit-before-commit ordering bug.** `audit-claims.sh --since` selects changed pages via `git diff <ref>...HEAD` (committed changes only). Plan 04 runs the source-scoped audit at step 6, before the ingest commit at step 9, so the new pages never enter the recency selector and the "new source was selected" assertion fails spuriously. Fix: commit first, then audit with `PRE_REF` = the commit before the ingest commit.
2. **MEDIUM (both) — No timeout on live Ollama calls.** `curl -fsS` in `pdf-extract.sh` has no `--max-time`; a wedged server or cold model load hangs the script, the live test, and the whole suite indefinitely. Add an env-overridable `--max-time` (e.g., 300s/page).
3. **MEDIUM (both, different angles) — Live-test signal/cost.** Claude: every suite run pays 2 real 7B-VLM inferences for a loop-deterministic assertion (add a `PDF_EXTRACT_SKIP_LIVE=1` bypass). Codex: the marker-count assertion passes even if OCR returns empty text under every marker (add a non-marker body-text / fuzzy content assertion for the fixture).

### Divergent Views

- **Plan 04 worklist assertion vacuity (Claude HIGH, source-verified; Codex called the same mechanism a strength).** Claude confirmed at source that `--emit-worklist` entries carry no `verdict` key and that `insufficient-locator` claims are excluded from the worklist before append — so the `select(.verdict == "insufficient-locator") | length == 0` assertion can never fail, for any input. Codex praised the worklist-filtering approach without checking the emitted shape. **Claude's source-level finding should win**: rework step 6 to findings-based `--format json` assertions run post-commit (selection `length > 0` + `insufficient-locator == 0`).
- **Plan 02 canonical fixture regeneration (Codex HIGH; Claude rated Plan 02 LOW/strongest).** Codex flagged that Plan 02 edits `schema/AGENTS.template.md` without regenerating `schema/fixtures/canonical-AGENTS.md`. **Verified real by the orchestrator**: `tests/phase-08/test_canonical_byte_equality.sh` asserts byte-equality of the wizard render against that fixture, so the template edit breaks setup-parity CI unless the fixture is regenerated and listed in `files_modified`. This should be treated as an agreed HIGH despite single-reviewer origin.
- **Plan 03 lint-test assertion shape** — Codex prefers `--ci --format json` assertions outright; Claude finds output-grep acceptable but suggests anchoring variant B on the finding-line prefix. Compatible; either tightening works.
- **Plan 04 read list** — Codex (MEDIUM) wants `page-types.md`, `log-format.md`, `privacy.md` added to the authoring read list; Claude did not raise it.

### Recommended Action

Re-plan **Plan 04** (step 6 rework: commit-then-audit, findings-based assertions) and patch **Plan 02** (add `schema/fixtures/canonical-AGENTS.md` regeneration + byte-equality test to the task and `files_modified`). Plans 01/03 suggestions (curl timeout, live-test bypass, fixture content assertion, namespaced env vars) can be applied during the same pass or at execution time.
