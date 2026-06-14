---
phase: 21
reviewers: [claude, codex]
reviewed_at: 2026-06-14T11:12:14Z
plans_reviewed: [21-01-PLAN.md, 21-02-PLAN.md]
---

# Cross-AI Plan Review — Phase 21

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
