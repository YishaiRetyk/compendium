---
phase: 17
reviewers: [codex]
reviewed_at: 2026-06-05
plans_reviewed: [17-01-PLAN.md, 17-02-PLAN.md, 17-03-PLAN.md, 17-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 17

> Reviewer set: Codex (independent). Claude self-review skipped for independence
> (this review was orchestrated from inside Claude Code). Gemini not requested.
> Several Codex HIGH concerns were independently re-verified against the live
> repo by the orchestrator; verification notes are inlined under each concern.

## Codex Review

### Overall

The four-wave sequencing is sound and the plans cover WF-01..WF-09 in the right
order, but they should not be executed unchanged. The main blockers are an
inconsistent `§N` policy, verification commands that contradict the planned
headers/footers, a duplicate lint "source of truth" acceptance check, and several
Plan 17-04 routing/lint implementation risks. All are fixable, but should be fixed
before execution because they will otherwise produce false-red checks or a routing
guard that is either too loose or impossible to satisfy.

**Cross-plan verdict: MEDIUM-HIGH.** The single most important fix is to define one
consistent cross-file reference policy and encode it identically in every grep,
acceptance criterion, and the routing guard.

### Plan 17-01

**Summary:** Strong WF-01/WF-02 extraction, but an immediate self-contradiction:
it requires no `§N` refs in new files while adding `AGENTS.md §9` / `§11.1` refs
in the standard headers and See Also footers.

**Strengths**
- Correctly extracts §9 and folds only the two substantive §10 blocks into `ingest.md`.
- Closes Open Q9 with explicit `update:`/`merge:`/`supersede:`/`archive:` prefixes.
- Keeps CLAUDE.md/AGENTS.md byte-equality in scope; avoids YAML frontmatter in schema files.

**Concerns**
- **HIGH — self-contradicting §N grep:** acceptance `grep -qE '§[0-9]|Section [0-9]' <newfile>` returns non-zero (asserting NO §N) will FAIL because the plan's own header template adds `AGENTS.md §9 points here` and the See Also footer adds `§9 stub`. *(Orchestrator verified: the interface header template at plan L122 literally writes `AGENTS.md §9 points here`, and the footer at L146 writes `§9 stub`. The negative assertion is logically inverted relative to the templates the same task emits.)*
- **HIGH — two authoritative log shapes:** the compact "2-line" solo-op log shape in core conflicts with the original §12 multi-line structured-op format that Plan 17-03 relocates to `log-format.md`. Two canonical shapes unless explicitly reconciled.
- **MEDIUM:** `structured-operations.md` links to `schema/reference/log-format.md` before that file exists (created in Wave 3). Tolerable sequentially, bad if Wave 1 is used standalone.
- **MEDIUM:** `ingest.md` is titled "Ingest Workflow" and declared authoritative before its procedure exists (Wave 2 adds it); bridging note mitigates but leaves temporary incomplete authority.

**Suggestions**
- Replace back-links like `AGENTS.md §9 points here` with `AGENTS.md routing table points here` (path/dispatch wording, no section number) — OR explicitly exempt only that backlink form in EVERY grep and in the routing guard.
- Pick one canonical solo-op log shape; if core keeps the compact form, `log-format.md` must mark it canonical or label the compact core a dispatch summary only.
- Make the no-`§N` verification scoped: forbid refs to EXTRACTED sections, not every `§` token.

**Risk: MEDIUM-HIGH** — extraction logic good; verification rules internally inconsistent and likely fail immediately.

### Plan 17-02

**Summary:** Correctly completes ingest/query extraction and preserves the
write-back-mandatory residue, but inherits the same `§N` verification flaw and has
a neutrality risk around carrying `examples/kahneman` references into
template-public schema files.

**Strengths**
- Extends seeded `ingest.md` rather than recreating it; keeps bare per-workflow log format inline (WF-07 intent).
- Correctly promotes Ingest+Query into the routing table while leaving Lint/Reflect inline until Wave 3.
- Preserves the write-back-mandatory line in resident core.

**Concerns**
- **HIGH — inherited §N grep flaw:** the no-`§N` grep fails against planned headers/footers like `AGENTS.md §11.2 points here`.
- **MEDIUM:** relocating the worked-example path `examples/kahneman/...` into `schema/workflows/query.md` may trip the template-public neutrality rule unless that path has a documented exemption. *(The plan's own T-17-04 threat row asserts a path-only exemption "per established neutrality precedent" — confirm `bin/check-neutrality.sh` actually treats `examples/kahneman/` path refs as exempt before relying on it.)*
- **MEDIUM:** "core keeps ONLY the write-back line" also keeps routing stubs; probably intended, but phrase the acceptance as "only substantive resident query rule."
- **LOW:** partial routing-table promotion is safe only because Wave 3 is guaranteed sequential.

**Suggestions**
- Use placeholder example paths unless neutrality explicitly exempts the committed example cluster.
- Make the §11.2 resident-rule acceptance precise (one substantive write-back sentence + pointer).
- Add a post-edit check that `ingest.md` has the procedure BEFORE the folded §10 blocks (ordering matters for agent usability).

**Risk: MEDIUM** — achieves WF-03/WF-04 conceptually; §-ref policy and neutrality handling need cleanup.

### Plan 17-03

**Summary:** The most important extraction wave; mostly well-scoped but highest
documentation-consistency risk. Biggest concrete issue: the lint "source of truth"
string is added to the banner AND preserved in the relocated body, while
acceptance requires exactly one occurrence.

**Strengths**
- Extends existing `schema/workflows/lint.md` (no second lint file); explicitly protects the CI-contract framing (key WF-05 requirement).
- Includes the brownfield miss, release, audit, reflect, and §12 log-format extraction; handles external referrers before the routing guard is enabled.

**Concerns**
- **HIGH — duplicate source-of-truth count:** `grep -c 'Source of truth for Phase 9 / Phase 12.2 CI' == 1` conflicts with adding the phrase to the new banner (Part A) AND preserving the original body verbatim (CLAUDE.md L571). Will count 2. *(Orchestrator verified: the phrase appears once in CLAUDE.md today at L571; Plan 03 Part A writes it again in the new banner while also relocating L571 verbatim → two occurrences → acceptance fails.)*
- **HIGH — §N policy inconsistency across files:** `log-format.md` permits resident `AGENTS.md §3`; workflow headers add extracted `§11.x`; Plan 04 later allows only `{1,2,3}`. These rules do not line up.
- **HIGH — Phase-16 files already carry §N back-links, never repointed:** existing `schema/reference/*.md` (and the seeded `schema/workflows/lint.md`) already contain `AGENTS.md §4/§5/§6/§8/§13` back-links, a `see §6 PROV-01..05`, and a literal `§11.5 Brownfield Workflow` ref. Plan 17-03 repoints only `docs/` external referrers, NOT these schema files → Plan 17-04's schema-wide `routing` guard will FAIL. *(Orchestrator verified: `grep -rnE '§[0-9]' schema/reference/ schema/workflows/` returns 13+ hits across page-types.md, privacy.md, provenance.md, frontmatter.md, wikilinks.md, lint.md. Under Plan 04's "{1,2,3} only" rule every one of these is an `error`, so `bin/lint.sh --category routing` cannot exit 0 — a phase-close blocker.)*
- **MEDIUM:** `wc -l brownfield.md` "roughly 180–195" may be too tight after header/footer + conversions.
- **MEDIUM:** "exactly one routing-table row" is not actually verified — `grep -q` also matches pointer stubs/duplicates.

**Suggestions**
- Preserve the CI source-of-truth phrase exactly once (keep it in the body, paraphrase the banner — or vice versa).
- Before Plan 17-04, run a schema-wide `rg '§[0-9]|Section [0-9]' schema/` and convert the existing Phase-16 back-links too, OR define a narrow allowed-backlink syntax used consistently everywhere.
- Use bounded-table assertions for routing rows, not global grep.
- Widen the brownfield line-count tolerance or check for required subcommand headings instead.

**Risk: HIGH** until the §N policy and duplicate source-of-truth check are fixed. Otherwise well designed.

### Plan 17-04

**Summary:** Directionally right close-gating plan, but needs tighter
implementation design. The routing category is the riskiest part: it mixes
category-level severity remapping with message-prefix exceptions, scans
`docs/reference` paths without adding them to the known set, and depends on checks
that may not fail on findings.

**Strengths**
- Builds the routing guard only after all extraction waves; clean forward(error)/inverse(warning) split.
- Inclusion-audit baseline is the actual post-extraction count, not a target. WF-09 evidence is pragmatic (mechanical guard + desk-check floor + non-gating empirical run). Full CI suite included.

**Concerns**
- **HIGH — destructive negative test:** the Task 1 negative test does `git checkout schema/workflows/release.md`, which can revert unrelated/uncommitted work. *(Orchestrator verified: `release.md` is created in Plan 03 and is untracked/uncommitted when Plan 04 runs; `git checkout` on it would error or restore a stale blob, not cleanly remove the appended dangling line. Use a temp copy rooted by `LINT_REPO_ROOT` instead.)*
- **HIGH — docs/reference refs vs known set:** the forward check scans `docs/reference/<x>.md` references but the known set is described as only `schema/` + `AGENTS.md`. Valid refs like `docs/reference/scaling.md`/`tooling.md` may false-error. Build target existence by checking repo-root-relative paths on disk.
- **HIGH — unrepointed Phase-16 §N back-links (same root cause as 17-03 HIGH):** the guard rejects existing `schema/reference/*.md` extracted-section back-links unless Plan 04 also repoints them or permits a defined backlink exception. As written, the gate cannot go green.
- **HIGH — exit-0 doesn't prove no findings:** assertions should inspect JSON, not just exit code. *(Orchestrator nuance: for ERROR-severity forward findings, `bin/lint.sh` non-CI mode DOES `sys.exit(1 if has_error else 0)` (L2456/L2582), so a forward dangling ref would exit 1. But ORPHAN(warning)/AUDIT(info) findings do NOT affect exit code, so the negative/inverse tests must inspect `--format json`. Codex's concern is correct for the warning/info paths.)*
- **MEDIUM:** prefix-based severity exceptions (`ORPHAN:`/`AUDIT:`) are brittle — a `remap_ci_severity(sev,cat,msg)` helper or separate logical subcategories is safer and testable.
- **MEDIUM:** baseline `N` can be off by two lines if counted BEFORE inserting the two inclusion-audit comments; acceptance requires `N == wc -l` AFTER insertion. Recompute after writing the comments.
- **MEDIUM:** WF-08 says every resident section carries a justification, but the plan makes inline core justifications optional / summary-only.
- **MEDIUM:** creating+indexing the DR mutates `wiki-cloud/` but the plan adds no `wiki-cloud/log.md` entry or operation-validation path.
- **LOW:** wizard dry-run is in the action text but missing from the automated verification/acceptance criteria.

**Suggestions**
- Implement routing severity remap as a function with explicit tests for forward-error / orphan-warning / audit-info.
- Check routing target existence against repo-root-relative disk paths, not only a schema known set.
- Run routing assertions via JSON (no `severity=="error"` for forward; optionally no `ORPHAN:` at close).
- Replace the destructive `git checkout` negative test with a temp copied repo.
- Make resident-section inclusion justifications mandatory (HTML comments near headers or a compact resident audit table).
- Add `wiki-cloud/log.md` to the DR task (or justify the exemption); recompute the inclusion baseline after inserting the comments.

**Risk: HIGH** — concept solid; routing guard and baseline mechanics need correction before implementation.

---

## Consensus Summary

Only one external reviewer (Codex) was invoked, so "consensus" here is Codex's
verdict cross-checked against the orchestrator's direct repo verification. Every
HIGH below was empirically reproduced against the live tree.

### Agreed Strengths
- Wave sequencing (1→4) is correct: routing guard built last, after all `§N` are abolished and every workflow file is reachable.
- WF-01 Open-Q9 closure (`update:`/`merge:`/`supersede:`/`archive:` solo-op prefixes) is clean.
- WF-05 single-lint-file merge (extend the Phase-16 seed, no second lint file) is right.
- Inclusion-audit baseline = actual post-extraction count (delta-from-baseline, not a ceiling) is a sound anti-Goodhart design.
- WF-09 three-tier evidence (mechanical guard / desk-check floor / non-gating empirical) is pragmatic and matches the v1.1 precedent.

### Agreed Concerns (highest priority — all verified)
1. **[HIGH] Self-contradicting `§N` grep + unrepointed Phase-16 back-links (the dominant blocker).** The plans' own file-header templates emit `AGENTS.md §N points here` and `§N stub` footers, yet acceptance criteria assert no `§N` survives; AND the existing Phase-16 `schema/reference/*.md` + seeded `lint.md` already carry 13+ `§N` back-links that no plan repoints. Plan 04's `routing` guard (allow only §{1,2,3}) therefore cannot exit 0. **Resolution needed before execution:** adopt ONE policy — either (a) abolish ALL `AGENTS.md §N` in schema files (use "AGENTS.md routing table points here" / path wording) AND repoint the existing Phase-16 back-links in this phase, or (b) define a single narrow backlink-exemption regex and encode it identically in every grep, every acceptance criterion, the routing-guard pattern, and applied retroactively to the Phase-16 files. Codex (and the orchestrator) recommend (a).
2. **[HIGH] Duplicate "source of truth" string (Plan 03).** Banner add + verbatim body relocation = 2 occurrences vs the `== 1` acceptance. Keep the phrase exactly once.
3. **[HIGH] Two authoritative solo-op log shapes (Plan 01 vs 03/§12).** Compact 2-line core vs multi-line `log-format.md`. Declare one canonical.
4. **[HIGH] Plan 04 routing implementation risks:** destructive `git checkout` negative test on an uncommitted file; `docs/reference/*` refs not in the known set (false errors); ORPHAN/AUDIT warning/info findings not reflected in exit code (assert via JSON, not exit-0).

### Divergent Views
- None (single reviewer). One orchestrator refinement to Codex's "exit 0 doesn't prove no findings": it is *partially* overstated — error-severity findings DO drive `sys.exit(1)` even outside `--ci` (bin/lint.sh L2456/L2582), so forward dangling refs would exit non-zero. The concern stands specifically for the ORPHAN(warning)/AUDIT(info) paths, which must be checked via `--format json`.

### Recommended next step
Feed this review back into planning:

```
/gsd-plan-phase 17 --reviews
```

Prioritize the unified `§N` reference policy (Concern 1) — it is the load-bearing
fix that unblocks Concerns 2's sibling consistency issues and the entire Plan 04
routing gate. Concerns 2–4 are localized and mechanical once the policy is fixed.
