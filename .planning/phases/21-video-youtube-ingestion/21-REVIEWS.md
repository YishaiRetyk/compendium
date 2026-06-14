---
phase: 21
reviewers: [claude, codex]
reviewed_at: 2026-06-14T11:33:57Z
plans_reviewed: [21-01-PLAN.md, 21-02-PLAN.md]
review_cycle: 2
prior_cycle_high_concerns: 2
current_cycle_high_concerns: 0
---

# Cross-AI Plan Review — Phase 21 — Cycle 2 (current)

> Cycle 2 re-review after 21-02 was revised to close the two cycle-1 HIGH concerns
> (diarization/speaker-label fallback; metadata acquisition path). Both reviewers
> (Claude, Codex) ran on the revised 21-01 + 21-02 PLAN.md. The cycle-1 reviews are
> preserved below for traceability.

## Cycle 2 — Claude Review

I've verified the load-bearing mechanics against the actual tooling. Here is my review.

---

# Cross-AI Plan Review — Phase 21 (Video/YouTube Ingestion), Cycle 2

## 1. Summary

Both revised plans are in strong shape. The two prior HIGH concerns are now closed with concrete, mostly-correct mechanical gates: 21-02 adds an explicit diarization gate (a `>=2 distinct labels` grep + a 3-branch fallback) and a fully-specified `yt-dlp` field→frontmatter mapping with ISO normalization and a manual watch-page cross-check. I verified the most consequential machinery against the repo — the audit JSON contract, `TS_RE`, lint exit-code policy, and the convention divergence anchors all check out, and the source-scoped `jq` audit assertions are genuinely non-vacuous. I found **no new HIGH concerns**. I did find one **MEDIUM** correctness bug introduced this cycle (the crossref-delta `grep` is vacuous — empirically confirmed) and one **MEDIUM** robustness gap in the diarization gate's grep (it only counts all-caps single-token labels, so a correctly *mended* transcript with Title-Case names would spuriously fail). Neither undermines the prior-HIGH closures; both are fail-safe and easily tightened.

## 2. Prior-HIGH Closure Verdict

### PRIOR-HIGH-1 (Diarization / speaker-label fallback) — **FULLY RESOLVED**

The revised 21-02 adds a dedicated gate (Task 3, step 1a) with exactly the three escape branches the prior cycle asked for, plus a grep-checkable acceptance criterion. Quoting the closing text:

> "If `DISTINCT < 2`, OR the labels are obviously wrong … apply ONE of these three fallback branches BEFORE proceeding to PREPARE — do NOT silently ingest a single-label or mislabeled transcript: (a) RERUN `stt` with an adjusted `--speakers` … (b) MEND AT INGEST … (c) REJECT THE VIDEO … RETURN to the Task 2 `checkpoint:human-action`."

And the verifiable gate:

> "the committed transcript carries >=2 DISTINCT speaker labels — `grep -oE '\] +[A-Z][A-Z0-9_]*:' <source-file> | sed -E 's/^\] +//; s/:$//' | sort -u | wc -l` returns a count `>= 2`."

This is a real, blocking precondition with an explicit fallback — the substance of the prior concern is addressed and verifiable. The mitigation also appears in the threat register (T-21-07). **One robustness caveat** on the grep itself (see Concerns C-2) keeps this from being airtight, but the failure is fail-safe (over-strict, never permissive), so closure stands.

### PRIOR-HIGH-2 (Metadata acquisition underspecified) — **FULLY RESOLVED**

The revised plan replaces the underspecified metadata step with an explicit, sourced mapping (Task 3, step 2):

> "`title` ← yt-dlp `title` … `channel` ← yt-dlp `channel` (or `uploader`) … `publish_date` ← yt-dlp `upload_date` (format `YYYYMMDD`) — NORMALIZE to ISO `YYYY-MM-DD` … (e.g. `20260514` → `2026-05-14`) … `duration` ← yt-dlp `duration` … OR use yt-dlp `duration_string`."

…with a mandated human cross-check ("open <VIDEO_URL> in the browser … confirm the four captured values … MATCH the page before authoring frontmatter") and acceptance criteria that enforce it:

> "`title`, `channel`, `publish_date`, `duration` are all NON-EMPTY … AND `publish_date` is ISO `YYYY-MM-DD` (`grep -qE 'publish_date: *[0-9]{4}-[0-9]{2}-[0-9]{2}'` succeeds …)."

The source of each field is now unambiguous, the format conversion is specified with a worked example, and accuracy is double-gated (canonical metadata + human cross-check). This is well-closed. (Minor nit in Suggestions on `duration` format consistency.)

## 3. Strengths

- **The audit verification is genuinely non-vacuous and I confirmed it against the script.** `bin/audit-claims.sh --format json` emits a flat array of finding dicts (`bin/audit-claims.sh:1111`), each carrying `source_id` and `verdict` keys (`:753`,`:755`). A resolving `#t` claim gets verdict `insufficient` (deterministic stub, no verifier); a non-resolving one gets `insufficient-locator` (`:282`). So the plan's two `jq` assertions — `select(.source_id==$sid)|length>0` (selected) and `select(.source_id==$sid and .verdict=="insufficient-locator")|length==0` (all resolved) — read exactly as intended. The plan also explicitly forbids the vacuous global `! grep -q insufficient-locator` form (the Phase 19 `#sec:` residue would defeat it). Excellent.
- **POST-COMMIT ordering for the audit is correctly understood and called out** (the recency selector diffs committed changes), with `PRE_REF` captured at step 0 and the verify block honestly flagged as "NOT runnable verbatim."
- **The four PDF divergences are precisely targeted.** I confirmed the anchors in `pdf-ingestion.md`: the "Lint **requires** all four fields when `original_asset` points at a `*.pdf`" mandate (L39), the `bin/pdf-extract.sh`/olmOCR naming (L62), and the `--asset` step (L79). 21-01's negative greps (`! grep -qi 'lint requires'`, `! grep -q -- '--asset'`, `! grep -q 'bin/pdf-extract'`) and neutrality posture cleanly invert exactly those.
- **`TS_RE` confirmed** (`bin/audit-claims.sh:392`: `^\s*\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?`): the `SPEAKER:` prefix is opaque to the resolver, so D-01/D-03 grammar resolves with zero changes — the "no resolver edit" claim is correct.
- **Lint scoping is sound.** I verified text-mode `--ci` exits 1 iff an error-severity finding exists, so `bin/lint.sh --ci --dry-run --category yaml && …` is a valid gate, and scoping to `yaml` correctly sidesteps the 18 pre-existing crossref errors (real, not hypothetical — I ran it).
- **Privacy is double-gated** (human confirmation primary, `bin/check-sources-cloud-safe.sh` mechanical backstop — confirmed present) with the right disposition note that mechanical ≠ content-level.
- Commit hygiene is correct: ingest as one `ingest(<slug>):` commit, DR as a separate `reflect(...)` commit, audit control-plane left uncommitted.

## 4. Concerns

- **[MEDIUM] The crossref-delta check is vacuous — empirically confirmed.** Step 0 captures `CROSSREF_BEFORE=$(bash bin/lint.sh --ci --dry-run --category crossref 2>&1 | grep -c ERROR || true)` and step 7 requires `CROSSREF_AFTER <= CROSSREF_BEFORE`. But lint prints findings as `[error] …` (lowercase) and a summary line `Errors:   18` — it **never emits uppercase `ERROR`** for findings. I ran the exact command: with **18 real crossref errors present**, `grep -c ERROR` returns **`0`**. So `BEFORE == AFTER == 0` unconditionally and the delta `0 <= 0` always passes. The "assert the ingest introduced no NEW crossref errors" guard cannot detect new crossref errors. This is ironic given the plan correctly warns against the symmetric "grep that can never fail" mistake in the audit step. Impact is bounded (it's a secondary hygiene check; the primary yaml gate works and VID-04 doesn't depend on it; the merge-pass instructions tell the agent to resolve new crossref errors anyway), so MEDIUM, not HIGH — but as written the gate is dead.
- **[MEDIUM] Diarization-gate grep only counts ALL-CAPS single-token labels — fragile against the plan's own mending path.** `grep -oE '\] +[A-Z][A-Z0-9_]*:'` matches raw `SPEAKER_00` and all-caps `ALICE`/`BOB` (the PATTERNS.md example), but **fails to count Title-Case or multi-word labels** (`Alice`, `Dr. Smith`, `JOHN SMITH:`). D-03 and fallback branch (b) explicitly permit "map raw `SPEAKER_NN` labels to meaningful names at ingest." A diligent executor who maps to human names (`Alice`/`Bob`) would produce a correct multi-speaker transcript that **fails the acceptance grep with `DISTINCT == 0`**. The failure is fail-safe (over-strict, never lets a single-label transcript through), so PRIOR-HIGH-1 closure holds — but it can trigger spurious gate failures and executor confusion on a legitimately-correct artifact. The grep also hard-depends on the bracketed timestamp form; a bracketless emitter would zero it out.
- **[LOW] Diarization capability is not confirmed before the human checkpoint.** The whole phase hinges on the `SPEAKER:` path (the one piece of zero-coverage new surface), which requires working pyannote diarization (often gated behind a HuggingFace token / model-license acceptance). Task 1's diarization smoke test is **optional** ("OPTIONAL smoke … if a fast confirmation is wanted"). If diarization is misconfigured, that is only discovered after the human supplies a URL *and* after full STT inference on a 5–20 min video, then handled by the expensive reject-branch (c). Front-loading is cheap insurance.
- **[LOW] `$PRE_REF` / shell-state fragility across tool calls.** Step 0 captures `PRE_REF` and `CROSSREF_BEFORE` as shell vars, but each Bash invocation is a fresh shell (state doesn't persist), and the audit runs many steps later post-commit. The plan acknowledges re-derivation ("or re-derive as the parent of the ingest commit"), so this is manageable, but it's a manual reconstruction point where a wrong ref would silently change what the audit selects.
- **[LOW] Privacy backstop scope.** `bin/check-sources-cloud-safe.sh` only checks for `privacy: local_only` frontmatter and a `sources/local-only/` dir; a genuinely-private unlisted video without those markers would pass mechanically. Human confirmation is correctly the primary control and the plan is honest about this — noting only so it isn't mistaken for a content-level guarantee.

**No new HIGH concerns.** Neither MEDIUM undermines a prior-HIGH closure: both are fail-safe (the crossref delta only fails to catch hygiene regressions; the diarization grep only over-rejects).

## 5. Suggestions

- **Fix the crossref delta to a real count.** Replace the uppercase-`ERROR` grep with a JSON count (the script supports `--format json`, mirroring the audit step the plan already trusts):
  `CROSSREF_BEFORE=$(bash bin/lint.sh --ci --dry-run --format json --category crossref 2>/dev/null | jq '[.[]|select(.severity=="error" and .category=="crossref")]|length')`
  (Avoid `grep -c '[error]'` — the console only prints the top-5 findings, so it caps at 5.)
- **Broaden the diarization grep and/or constrain mapped labels.** Either widen the character class to tolerate Title-Case/mixed labels — e.g. `grep -oE '\]\s+[A-Za-z][A-Za-z0-9_ ]*:'` (then trim) — or have 21-01's convention + 21-02's mending step mandate that mapped labels stay single-token (underscores, not spaces). Pick one and make the acceptance grep match it, so a correctly-mended transcript can't spuriously fail.
- **Promote the Task 1 diarization smoke test from optional to mandatory.** Require a short multi-speaker public clip to produce `>=2` `SPEAKER:` labels before the Task 2 checkpoint. This catches a pyannote/token misconfiguration cheaply and strengthens PRIOR-HIGH-1's closure by moving the most likely failure ahead of the expensive full-video run and the human ask.
- **Reconcile the `duration` format.** 21-01's convention example uses `~12 min` while 21-02 authors `H:MM:SS`/`duration_string`. Harmless (free-text, unvalidated), but pick one form in the convention so the worked instance matches the doc.
- **(Nit, 21-01)** A couple of acceptance-criteria greps embed literal backticks inside the pattern (e.g. ``grep -q 'sub-case of `transcript`'``); these are illustrative but won't run verbatim in `sh`. Worth a note that they're guidance, not copy-paste commands.

## 6. Risk Assessment — **LOW**

This is a documentation/convention phase plus a single human-gated validation ingest; it adds no executable code, no network/auth surface, and reuses an already-proven `#t` resolver. The two prior HIGH concerns are genuinely closed with verifiable gates, and the highest-stakes verification (the source-scoped audit) is provably non-vacuous against the real script. The two MEDIUM findings are both fail-safe (a dead hygiene check and an over-strict gate) and trivially fixable, and the LOW items are well-understood operational fragilities the plan already flags. Recommend proceeding after tightening the crossref delta and the diarization grep; neither requires another full review cycle.

---

## Cycle 2 — Codex Review

**Summary**

The revised Phase 21 plans are substantially stronger. Plan 21-01 is a well-scoped convention/schema plan with good neutrality controls and clear divergence from the PDF precedent. Plan 21-02 now has concrete gates for the two prior HIGH issues: diarization is no longer assumed, and metadata acquisition now has an explicit source mapping plus a watch-page cross-check. I do not see a new HIGH concern. The remaining risks are mostly execution brittleness around real-world STT/YouTube tooling and a few checks that should be hardened to avoid false negatives.

**Prior-HIGH Closure Verdict**

**PRIOR-HIGH-1: Diarization / speaker-label fallback missing — FULLY RESOLVED**

The revised plan now has both a hard gate and fallback branches before ingest:

> “the committed transcript carries >=2 DISTINCT speaker labels — if diarization yields a wrong count, duplicated/inconsistent labels, or a single label, the executor applies a fallback (rerun stt with adjusted --speakers, mend labels at ingest, or reject the video back to the Task 2 checkpoint) BEFORE ingesting”

Task 3 step 1a is also explicit:

> “The gate (`DISTINCT >= 2` on the file that will actually be committed) is a hard precondition for PREPARE”

And the acceptance criterion closes the loop:

> “DIARIZATION GATE (D-03/D-12): the committed transcript carries >=2 DISTINCT speaker labels…”

The grep is acceptable for the planned raw `SPEAKER_00:` / uppercase-label format, but it is brittle if labels are manually mapped to normal names like `Alice:`. That is a hardening issue, not a reopened HIGH, because the gate fails closed rather than silently accepting a bad transcript.

**PRIOR-HIGH-2: Metadata acquisition underspecified — FULLY RESOLVED**

The revised plan gives a concrete field-source mapping:

> `title ← yt-dlp title`  
> `channel ← yt-dlp channel or uploader`  
> `publish_date ← yt-dlp upload_date … NORMALIZE to ISO YYYY-MM-DD`  
> `duration ← yt-dlp duration … OR duration_string`

It also adds an accuracy gate:

> “MANUAL CROSS-CHECK: open <VIDEO_URL> in the browser … confirm the four captured values … MATCH the page before authoring frontmatter”

And acceptance requires:

> “title, channel, publish_date, duration are all NON-EMPTY … publish_date is ISO YYYY-MM-DD … duration is non-empty”

This closes the original ambiguity. I would still recommend recording the metadata source/cross-check result in `21-02-SUMMARY.md`, because the check is procedural rather than fully machine-verifiable after the fact.

**Strengths**

- Clear dependency separation: 21-01 defines the convention; 21-02 validates it on a real source.
- Correctly preserves `video` as a `transcript` sub-case rather than introducing a new source type.
- Strong neutrality posture: template-public docs stay generic, while real source pages may record real extraction details.
- The diarization fallback is now operationally useful: rerun, mend, or reject.
- The audit check is non-vacuous and source-scoped, avoiding the prior global `insufficient-locator` trap.
- The plan correctly handles cloud-safety with both human confirmation and `check-sources-cloud-safe.sh`.

**Concerns**

- **MEDIUM:** Task 1 says it confirms `stt` “end-to-end on a YouTube URL,” but the automated acceptance only checks `command -v stt` and `stt --help`. That does not prove YouTube download, network access, cookies, model availability, diarization, or transcript emission. Make the smoke test mandatory or rename the task to “CLI availability preflight.”
- **MEDIUM:** The distinct-speaker grep is too narrow for manually mended labels. It matches `SPEAKER_00:` / uppercase snake labels, but not `Alice:`, `Speaker 1:`, or labels with spaces. Either require mended labels to use uppercase snake case, or broaden the parser.
- **MEDIUM:** Metadata cross-check is specified, but not auditably recorded. If accuracy is later questioned, the repo may only show final fields, not how they were obtained. Record the `.info.json` path or `yt-dlp --print` values plus “watch page cross-check passed” in `21-02-SUMMARY.md`.
- **LOW:** The crossref delta check uses `grep -c ERROR || true`, which could hide a lint command failure that emits no `ERROR` lines. Prefer a structured lint output if available, or explicitly preserve and inspect the lint exit status.
- **LOW:** The acceptance criterion requiring at least one `[epistemic:: tentative]` marker may force an artificial hedge if the extracted durable claims do not include proper nouns, numbers, or technical terms. Better phrase it as “present when the extracted claims include STT failure-surface content.”

**Suggestions**

- Make Task 1’s smoke test mandatory on a short public URL, or explicitly downgrade it to a non-end-to-end preflight.
- Replace the speaker-count extraction with something like a timestamp-anchored label parser that captures any colon-delimited label after the timestamp, or require all committed labels to use normalized uppercase labels.
- Add a required metadata note in `21-02-SUMMARY.md`: source used (`.info.json` or `yt-dlp --print`), normalized `publish_date`, final duration, and watch-page cross-check result.
- Add an acceptance check that the source summary’s `path` points to the single committed transcript and that at least one audited claim resolves to that path via the source id.
- Keep Task 4’s decision-record commit careful about staged files, since the post-commit audit intentionally leaves `wiki-local/maintenance` dirty.

**Risk Assessment**

Overall risk: **MEDIUM**. The plan quality is high and the two prior HIGH concerns are closed. The residual risk comes from real-world acquisition variability: YouTube download behavior, STT/diarization output formats, and manual metadata verification. None of these are design-breaking, but the execution gates should be hardened so failure modes are explicit rather than discovered late.

---

## Cycle 2 — Consensus Summary

Both reviewers independently judge the two prior-cycle HIGH concerns **FULLY RESOLVED**
and find **no new HIGH concerns**. The revised 21-02 closes both gaps with concrete,
mostly grep-checkable mechanical gates; residual risk is operational hardening, not design.

**Current unresolved HIGH concerns: 0.**

### Prior-HIGH Closure (both reviewers agree)

- **PRIOR-HIGH-1 (Diarization / speaker-label fallback) — FULLY RESOLVED (both).** Task 3
  step 1a adds a hard `DISTINCT >= 2` precondition before PREPARE plus the exact 3-branch
  fallback the prior cycle asked for (rerun with adjusted/omitted `--speakers` / mend raw
  labels at ingest / reject-and-return-to-Task-2), mirrored in acceptance criteria and the
  T-21-07 threat-register row. Both note the gate fails closed (over-strict, never permissive).
- **PRIOR-HIGH-2 (Metadata acquisition underspecified) — FULLY RESOLVED (both).** Task 3
  step 2 gives an explicit yt-dlp field->source mapping (`title`<-`title`,
  `channel`<-`channel`/`uploader`, `publish_date`<-`upload_date` normalized to ISO YYYY-MM-DD
  with a worked example, `duration`<-`duration`/`duration_string`) + a mandatory watch-page
  cross-check + acceptance criteria requiring all four non-empty and `publish_date` ISO-formatted.

### Agreed Concerns (cycle 2 — all MEDIUM or below, none HIGH)

- **[MEDIUM, both] Diarization-gate grep is too narrow for mended labels.** `grep -oE '\] +[A-Z][A-Z0-9_]*:'`
  counts raw `SPEAKER_00` / all-caps labels but NOT the Title-Case / multi-word names that fallback
  branch (b) "mend at ingest" explicitly permits (`Alice`, `Dr. Smith`). A correctly-mended transcript
  could spuriously fail the gate (`DISTINCT == 0`). Fail-safe (over-rejects, never under-rejects), so it
  does NOT reopen PRIOR-HIGH-1 — but should be broadened, or mapped labels constrained to a matching form.
- **[MEDIUM, Claude — empirically confirmed] Crossref-delta check is vacuous.** Step 0/7 count `grep -c ERROR`,
  but lint prints `[error]` (lowercase) for findings, never uppercase `ERROR`; Claude ran it with 18 real
  crossref errors present and `grep -c ERROR` returned 0, so `BEFORE == AFTER == 0` and the delta always
  passes. Bounded impact (secondary hygiene check; the primary yaml gate works and VID-04 does not depend
  on it), so MEDIUM. Fix: count via `--format json` + jq, as the audit step already does.
- **[MEDIUM, Codex] Task 1 "end-to-end" claim vs. availability-only acceptance.** Task 1 says it confirms
  `stt` end-to-end on a URL, but the automated acceptance only checks `command -v stt` + `stt --help`; the
  URL->transcript smoke test is OPTIONAL. Make the smoke test mandatory or rename the task to a CLI preflight.
  (Claude raises the diarization-specific variant of this as LOW.)
- **[LOW, both] Operational fragilities the plan already flags:** `$PRE_REF` / `CROSSREF_BEFORE` shell-state
  loss across tool calls (re-derive as `HEAD^`); privacy backstop is marker-only (human confirmation is
  correctly primary); `[epistemic:: tentative]` acceptance could force an artificial hedge; `duration` format
  inconsistency between 21-01 (`~12 min`) and 21-02 (`H:MM:SS`).

### Divergent Views

- **Overall risk ceiling.** Claude rates the phase **LOW** (convention phase + one human-gated ingest, no
  new code, proven `#t` resolver, prior HIGHs closed with verifiable gates). Codex rates it **MEDIUM**,
  weighting residual real-world STT/YouTube acquisition variability more heavily. Both agree no further review
  cycle is required and recommend proceeding after tightening the diarization grep (and, per Claude, the dead
  crossref-delta check) — neither blocks execution.

---

# Cross-AI Plan Review — Phase 21 — Cycle 1 (prior, preserved for traceability)


## Claude Review

# Cross-AI Plan Review: Phase 21 (Video/YouTube Ingestion)

## 1. Summary

These are two unusually well-engineered plans for a documentation/convention phase. **21-01** authors the `video-ingestion.md` convention as a deliberately lighter re-skin of the Phase 20 PDF doc, faithfully encoding 14 locked decisions with four explicit, individually-justified divergences (no lint mandate, no `--asset`, no `bin/` script, live-URL spot-verify). **21-02** validates end-to-end by ingesting one real multi-speaker video to exercise the single piece of genuinely-new surface (the `SPEAKER:` labeling path). The plans are tightly scoped, show clear learning from prior-phase review findings (the non-vacuous audit assertions explicitly route around the Phase 19 `#sec:` residue), and handle the two real trust boundaries — template-public neutrality and the privacy tier — with both write-time discipline and mechanical backstops. The concerns below are refinements, not structural problems; nearly all residual risks fail *loudly* (acceptance criteria block bad commits) rather than silently.

## 2. Strengths

- **Divergences are proven, not just stated.** Acceptance criteria include negative greps (`! grep -q -- '--asset'`, `! grep -q 'bin/pdf-extract'`, `! grep -qi 'lint requires'`, `! grep -q 'support_type: derived'`) that mechanically confirm each Phase-20 divergence was actually applied. This is rare rigor.
- **Non-vacuous audit verification.** 21-02 step 10 asserts *both* that the new source's `#t` claims were selected (`length > 0`) *and* that none return `insufficient-locator`, scoped by `source_id` via `jq`. It explicitly rejects the global `! grep -q insufficient-locator` that "can never pass while the Phase 19 #sec: residue exists." This shows the planner read `19-REVIEW.md`.
- **Delta-based crossref check, not absolute.** Capturing `CROSSREF_BEFORE` and requiring `AFTER <= BEFORE` correctly tolerates the pre-existing backlog out of this phase's scope, rather than demanding a clean absolute count it can't achieve.
- **Correct atomicity.** Routing row + target file land in one commit (routing lint stays green); template edit + regenerated fixture land together (setup-parity gate stays green); exactly one non-dry-run lint invocation is reserved for the ingest commit.
- **Privacy fail-closed and honest.** Human confirmation (primary) + `check-sources-cloud-safe.sh` (mechanical backstop) + an explicit "STOP — do not ingest *anywhere*, a wiki-local ingest fails VID-04" instruction that resists the tempting privacy-safe-but-wrong escape.
- **Pre-flight probe before the human checkpoint.** Task 1 confirms `stt` resolves before Task 2 interrupts the user — good UX sequencing.
- **Honest verify blocks.** 21-02 flags its automated block as "NOT runnable verbatim — substitution required" instead of pretending the runtime-determined slug is known at plan time.

## 3. Concerns

- **[MEDIUM] The inclusion-audit acceptance criterion assumes an unverified invariant.** 21-01 Task 3 asserts `[ "$(grep -oP 'inclusion-audit: \K[0-9]+' AGENTS.md)" -eq "$(wc -l < AGENTS.md)" ]`, i.e. that the audit count *equals the whole-file line count*. Nothing in the plan or PATTERNS establishes this holds today. If the baseline tracks resident-core lines or non-comment lines (plausible given the "~287-line core" framing), the count and `wc -l` may differ by a constant, and a correct edit will still fail the assertion. The failure is loud (blocks commit), but it will stall the autonomous wave.
- **[MEDIUM] The only true end-to-end `stt` confirmation (URL→transcript) is optional.** D-13 explicitly wants the planner to "confirm `stt` runs end-to-end on a URL *before* the validation checkpoint." Task 1 hard-verifies only `command -v stt` and `stt --help`; the smoke test that actually proves URL→transcript (step 3) is marked OPTIONAL. If it's skipped, a pipeline failure first surfaces in Task 3 *after* the human has already supplied a URL and is waiting — exactly the interruption D-13 sought to avoid.
- **[MEDIUM] `bin/ingest.sh --slug <slug> <file>` CLI contract is asserted, not confirmed.** 21-02 step 4 hard-codes this invocation. Phase 20 used `bin/ingest.sh --asset`; the exact `--slug` flag and positional-file form aren't verified in the provided context. A wrong invocation fails while the human waits.
- **[MEDIUM-LOW] Baseline state is fragile across context resets.** `PRE_REF` and especially `CROSSREF_BEFORE` are captured as shell variables in step 0. The plan gives a re-derivation for `PRE_REF` (parent of the ingest commit) but `CROSSREF_BEFORE` cannot be re-derived once the tree has mutated — it depends on the pre-ingest working state. A sequential executor that loses shell state mid-task can't recover the delta baseline.
- **[LOW] `--speakers N` has no fallback when the user doesn't know the exact count.** Task 2 asks the user to confirm "2+ speakers," but the user may not know N exactly. Task 3 feeds "the actual speaker count" to `stt --speakers <N>` with no documented auto-detect fallback (omit the flag).
- **[LOW] DR date is hard-coded `2026-06-14`.** 21-02 Task 4 fixes the filename and `created_at` to today. Because Task 4 runs after a human checkpoint of unknown latency, execution could slip to a later date, producing a misdated decision record.
- **[LOW] Validation implicitly assumes clean English audio** (`--lang en` "if needed", `sourced` tier expected) but Task 2's checkpoint criteria don't state a language preference. A non-English or borderline-degraded pick would push into the `tentative`/spot-verify path that the validation isn't set up to exercise.

## 4. Suggestions

- In 21-01 Task 3, add a pre-edit step: read the current `inclusion-audit: N` and `wc -l`, confirm the relationship, and update N to preserve *that* relationship (+1) — rather than assuming `N == wc -l`. Adjust the acceptance criterion to match whatever invariant actually holds.
- Promote the 21-02 Task 1 smoke test from OPTIONAL to "required unless already confirmed this session," using any short public multi-speaker clip, so the human is never asked for a URL the pipeline can't process. Keep it throwaway/non-ingested as written.
- Add an explicit `bin/ingest.sh --help` confirmation to 21-02 Task 1 (or read_first), and pin the verified single-file invocation, so the real run isn't the first time the flag syntax is exercised.
- Persist `PRE_REF` and `CROSSREF_BEFORE` to a scratch file (e.g. `.planning/phases/21-.../.baseline`) instead of shell variables, so the delta check survives a context reset.
- Document a `--speakers` auto-detect fallback in Task 3 for when the user can't give an exact count.
- Make the DR date dynamic (derive from execution date) rather than hard-coding `2026-06-14`.
- Optionally add "clear spoken English (or a language the local model handles well)" to the Task 2 checkpoint criteria to keep the validation on the `sourced` path it's designed for.

## 5. Risk Assessment

**Overall: LOW–MEDIUM** (21-01 is LOW; 21-02 is MEDIUM).

Justification: This is a convention phase with no net-new executable code, a strong in-repo analog (Phase 20) for every artifact, and exceptionally thorough acceptance criteria that catch their own failure modes. The dependency ordering is correct, scope is lean to the point of being a model of restraint, and the two genuine trust boundaries (neutrality, privacy) are mitigated at both write-time and gate-time. The residual risk concentrates in 21-02's reliance on an external local tool (`stt`), runtime-determined values, and a human-in-the-loop — but those failures are recoverable (return to checkpoint) and loud, not silent or goal-corrupting. The single most likely stall is the inclusion-audit invariant assumption in 21-01; the most likely *annoyance* is an unconfirmed `stt`/`ingest.sh` contract surfacing only after the human checkpoint. Addressing the four MEDIUM items would move the phase to solidly LOW risk.

---

## Codex Review

## 21-01 Plan Review

**Summary**
Plan 21-01 is strong and well-scoped. It correctly treats video as a `transcript` sub-case, mirrors the Phase 20 PDF pattern where useful, and explicitly avoids the main risks: leaking the personal STT tool, adding unnecessary scripts, creating a new `video` enum, or inventing new lint behavior.

**Strengths**
- Clear dependency-free Wave 1 scope: schema convention, registry wiring, routing, template, fixture.
- Good reuse of `pdf-ingestion.md` structure while calling out the intentional divergences.
- Strong neutrality controls for template-public files.
- Correctly preserves existing `#t` locator semantics instead of redefining provenance.
- Good routing discipline: AGENTS row, CLAUDE sync, template row, regenerated fixture.
- Acceptance criteria are mostly concrete and executable.

**Concerns**
- **MEDIUM:** The plan says `frontmatter.md` documents five fields, but the concrete YAML block intentionally omits `url` and `title` because they are base fields. That is reasonable, but the acceptance criteria only check `publish_date`, `channel`, and `duration`; they do not verify the doc explains how `url` and `title` satisfy VID-02.
- **MEDIUM:** The frontmatter block adds `extraction_tool`, `extraction_model`, and `extraction_date` even though they are convention-only. This is fine, but it may imply those fields are generally expected on all video-acquired transcripts. The prose should be explicit that official-caption transcripts may omit or adapt them.
- **LOW:** The `support_type: derived` negative grep is brittle. A future explanatory sentence could mention it safely, but the plan forbids the literal string to keep acceptance meaningful. That is acceptable but slightly test-driven rather than spec-driven.
- **LOW:** Inclusion-audit line count update is fragile if an executor runs formatting or adds/removes blank lines. The acceptance check catches it, but this step is easy to miss.
- **LOW:** The plan includes a commit instruction even though some GSD execution modes may separate planning artifacts from implementation commits. Not harmful, but should not block execution if the local workflow handles commits elsewhere.

**Suggestions**
- Add an explicit acceptance check that `video-ingestion.md` documents all five VID-02 fields, including reused base fields `url` and `title`.
- In `frontmatter.md`, add prose near the YAML block saying `title` and `url` remain base source fields and are not duplicated in the video block.
- Consider verifying `schema/reference/provenance.md` was not changed.
- Make the ingest pointer explicitly lazy-load only; avoid adding procedural detail to `schema/workflows/ingest.md`.

**Risk Assessment: LOW**
This is documentation/schema wiring with no code changes and strong precedent from Phase 20. Main risk is public-surface leakage or small schema ambiguity around reused frontmatter fields; both are mitigated by neutrality checks and clearer prose.

---

## 21-02 Plan Review

**Summary**
Plan 21-02 is thorough and directly validates VID-04, but it is materially riskier because it depends on live external media, local STT behavior, diarization quality, source privacy judgment, and full wiki ingest discipline. The plan mostly handles those risks, though it would benefit from tighter fallback paths around STT output shape, metadata acquisition, and degraded/missing diarization.

**Strengths**
- Correctly blocks on Plan 21-01 and follows the new convention rather than re-deciding it.
- Human checkpoint is appropriate: the URL must be user-supplied and cloud-safe.
- Multi-speaker requirement is well-justified because it exercises the new `SPEAKER:` path.
- Good distinction between template-public surfaces and real vault pages.
- Strong provenance verification: post-commit, source-scoped audit, non-vacuous selection assertion.
- Good privacy backstop with `check-sources-cloud-safe.sh`.
- Correctly avoids `--asset`, bundle dirs, and `source_type: video`.

**Concerns**
- **HIGH:** The plan assumes `stt` output includes usable speaker labels for the selected video. Diarization may fail, produce inconsistent labels, or omit speakers even when `--speakers N` is supplied. The plan needs an explicit fallback: reject video, rerun with adjusted `N`, or manually preserve/mend labels.
- **HIGH:** Metadata collection is underspecified. `title`, `channel`, `publish_date`, and `duration` must be accurate, but the plan does not say whether they come from `yt-dlp` metadata, YouTube page inspection, STT output, or manual entry.
- **MEDIUM:** "Ask user to confirm reachable YouTube video" may require network access and YouTube availability. The plan should say what happens if the URL is blocked, age-restricted, requires login, has disabled captions but audio works, or `yt-dlp` fails.
- **MEDIUM:** The post-commit audit mutates `wiki-local/maintenance/*` and leaves it uncommitted. That is intentional, but it can confuse dirty-worktree checks. The plan should explicitly require confirming only expected local files remain dirty.
- **MEDIUM:** The plan says `wiki-cloud/decisions/` is template-public. In this repo's rules, `wiki-cloud/` scaffolding is public-sensitive, but real `wiki-cloud/decisions` pages are also checked by neutrality. The concern is handled, but the wording could make executors overgeneralize and avoid real terms in ordinary wiki pages.
- **MEDIUM:** Optional Task 4 is described as optional but then strongly expected and has its own commit. This creates ambiguity: is VID-04 complete without it? It should be either required or clearly non-blocking.
- **LOW:** The crossref delta check counts `ERROR` in shell output, which can be brittle if lint formatting changes.
- **LOW:** `FINDINGS=$(...)` after post-commit depends on `$PRE_REF` surviving the session. The plan notes substitution, but a resumed executor should be told to rederive it as `HEAD^` if needed.

**Suggestions**
- Add a metadata acquisition step: capture `title`, `channel`, `publish_date`, `duration`, and canonical URL from downloader metadata when available, with manual fallback.
- Add diarization fallback criteria: if fewer than two speaker labels appear, rerun with known `--speakers`, choose another video, or explicitly fail the validation.
- Add failure handling for `stt`/YouTube errors: unreachable URL, download failure, auth-required video, non-English language, very long runtime, no speech.
- Make Task 4 either required for Phase 21, or mark it explicitly "nice-to-have, not VID-04 blocking."
- After audit, add a worktree check confirming only expected `wiki-local/maintenance` files are dirty.
- Consider running a source-scoped grep before audit to verify at least one `#t...|direct` claim exists in the new summary/topic pages.

**Risk Assessment: MEDIUM**
The design is sound, but execution depends on external video availability, local GPU/STT behavior, diarization quality, and careful ingest authoring. These are manageable with the proposed fallback rules.

---

## Overall Assessment

The two-plan phase is well-structured: Plan 21-01 establishes the convention, and Plan 21-02 validates it with a real artifact. The plans do achieve VID-01 through VID-04 if executed carefully. The main improvements are not architectural; they are operational hardening around live YouTube/STT failure modes and making the VID-02 metadata path unambiguous.

---

## Consensus Summary

Both reviewers independently judge the phase well-structured, tightly scoped, and likely to achieve VID-01..VID-04 if executed carefully. The split is consistent: **21-01 (convention authoring) is LOW risk; 21-02 (live end-to-end validation) is the risk concentration**, entirely in operational hardening around the external `stt`/YouTube pipeline rather than architecture.

### Agreed Strengths

- Correct treatment of video as a `transcript` sub-case; reuse of the Phase 20 PDF pattern with explicit, justified divergences (both reviewers).
- Strong neutrality controls for template-public surfaces; correct avoidance of `--asset`, bundle dirs, and a new `source_type: video` enum (both reviewers).
- Preserves existing `#t<start>-<end>` locator semantics rather than redefining provenance (both reviewers).
- Sound provenance/audit verification and a fail-closed privacy backstop (`check-sources-cloud-safe.sh` plus human confirmation) (both reviewers).
- Correct dependency ordering: 21-02 blocks on 21-01 and follows the new convention rather than re-deciding it (both reviewers).

### Agreed Concerns

- **Diarization / speaker-label fragility (raised by both; HIGH in Codex, LOW in Claude).** `stt` may fail to produce usable speaker labels even with `--speakers N`. Both want an explicit fallback (rerun with adjusted N, omit-flag auto-detect, choose another video, or mend labels). Codex rates this HIGH; Claude frames the narrower "user doesn't know N" sub-case as LOW.
- **`stt`/`ingest.sh` contract not confirmed before the human checkpoint (both, MEDIUM).** The URL→transcript smoke test is OPTIONAL and the `bin/ingest.sh --slug <slug> <file>` invocation is asserted, not verified — so a pipeline/flag failure first surfaces after the human has already supplied a URL and is waiting.
- **Baseline state fragile across context resets (both, MEDIUM/LOW).** `PRE_REF` / `CROSSREF_BEFORE` live in shell variables; `CROSSREF_BEFORE` cannot be re-derived after the tree mutates. Both suggest persisting baselines or documenting `HEAD^` re-derivation.

### Divergent Views

- **Metadata acquisition path (Codex HIGH; Claude does not flag).** Codex treats the unspecified source of `title`/`channel`/`publish_date`/`duration` (yt-dlp metadata vs. page inspection vs. manual) as a HIGH gap. Claude does not raise it, implicitly trusting the executor to source standard YouTube metadata.
- **Inclusion-audit invariant (Claude MEDIUM; Codex LOW).** Claude singles out the `inclusion-audit: N == wc -l AGENTS.md` assertion as the single most likely autonomous-wave stall (an unverified invariant). Codex notes the same line-count fragility but rates it LOW.
- **Overall severity ceiling.** Codex assigns two HIGH concerns to 21-02; Claude assigns none (its ceiling is MEDIUM). Both nonetheless converge on an overall LOW–MEDIUM phase, with all residual risk recoverable (return-to-checkpoint) and loud rather than silent/goal-corrupting.
