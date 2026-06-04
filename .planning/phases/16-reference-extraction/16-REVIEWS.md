---
phase: 16
reviewers: [claude, codex]
reviewed_at: 2026-06-04T23:10:00
plans_reviewed: [16-00-PLAN.md, 16-01-PLAN.md, 16-02-PLAN.md, 16-03-PLAN.md, 16-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 16: Reference Extraction

## Claude Review

I now have what I need — I verified the wizard's actual behavior, the release/privacy gates, and (critically) discovered pre-existing parity tests the plans must contend with. Here is the review.

---

### 1. Summary

This is a careful, well-sequenced plan set with genuinely good seam reasoning (the §6 consumer-split, bottom-up editing, the Wave-0 neutrality pre-arming). The extraction *content* model is sound. However, the plan set has **one structural blind spot that is likely fatal as written**: it largely ignores the template-mirroring mechanics and the *existing* CI parity tests that already assert `AGENTS.md ≡ schema/AGENTS.template.md` for the very sections being extracted (§4, §5, §16). As decomposed, Waves 1–3 stub `AGENTS.md` but the template-mirror of those stubs is neither clearly owned by a plan nor sequenced to keep parity green per-commit — which means (a) three pre-existing tests go red, and (b) the wizard would render a stale, non-stubbed `AGENTS.md` for new users, defeating the phase goal at the template layer. Several focus-area concerns the requester raised are real; a couple are lower-risk than feared once you look at what the gates actually do. Net: the plan needs one more pass on template-sync ownership and test-impact before execution.

### 2. Strengths

- **Wave 0 ordering is correct.** Arming `check-neutrality.sh` over `schema/` (Plan 16-00) *before* any `schema/reference/*.md` lands is exactly right, and isolating it as an AGENTS.md-untouched single-file commit correctly avoids firing the sync pre-commit hook.
- **Bottom-up editing within a plan** (16-01, 16-03) is the right technique to keep earlier line anchors stable across a multi-section edit.
- **The §6 consumer-split is well-reasoned** (concur with the routing).
- **16-03 locating sections by header text, not line number,** is the correct discipline given upstream line drift.
- **Per-commit gate discipline** (sync → sync --check → check-neutrality at each editing commit) is the right invariant for byte-equality.
- **lint.md is seeded as an explicit *partial* with a Phase-17-ownership header** — the cross-phase handoff is at least acknowledged rather than silent.

### 3. Concerns

#### HIGH — Template mirror of the §4–§16 stubs is unowned and mis-sequenced; it breaks existing parity tests
The phase goal says "mirror all stubs into `schema/AGENTS.template.md`," but the task decomposition only has **Plan 16-04 mirror its own 3 structural changes** (router line, routing table, §3 line). No plan clearly owns mirroring the §4/§5/§6/§8/§13 stubs and the §7/§16 *deletions* into the template. This collides with reality verified in the repo:

- `tests/phase-09.1/test_template_parity.sh` asserts **§4 and §16 bodies are byte-identical** between `AGENTS.md` and `schema/AGENTS.template.md`, extracting §4 as `^## 4.` → `^## 5.` and §16 as `^## 16.` → EOF.
- `tests/phase-10/test_agents_template_parity_section_5.sh` asserts the **same for §5**.

Consequences as written:
1. After 16-01 stubs §4/§5 and deletes §7, and 16-03 deletes §16 — but the template still holds the full bodies — **all three parity tests go red.** No plan in the set runs phase-09.1 or phase-10 (16-04 only runs phase-07 + phase-08), so the breakage is silent until someone runs full CI.
2. Even if 16-04 is *intended* to mirror everything, there is a **Wave-1→Wave-2 window** where `AGENTS.md` is stubbed but the template is not — parity is red across every intermediate commit, violating "CI gates pass unchanged in behavior."
3. **Worse than a red test:** the wizard renders `AGENTS.md` *from the template* (`init-wizard.sh:647 render_agents_md`). If the template keeps full §4–§16, a freshly-initialized end-user repo gets the **old monolith inline AND the new reference files** — duplicated, contradictory, and the opposite of the phase goal.

**Fix:** Each editing plan (16-01/02/03) must mirror its own stub edits into `schema/AGENTS.template.md` **in the same commit** (template has no sync gate, so this is manual but must be per-commit, not deferred). And the set must explicitly update/retire the §4/§5/§16 assertions in phase-09.1 and phase-10 — those tests *codify* the old monolith shape and cannot survive extraction unchanged. This is the single most important gap.

#### HIGH — Plan 16-02 appears to address `AGENTS.md` §6 by absolute line number after 16-01 already shifted the file
16-02's description targets "§6 lines 399–553 / 555–578 / 580–602 / 604–618." But 16-01 stubs §5 (was 140 lines → ~2) and §4, deleting/shrinking content *above* §6. By the time 16-02 runs, §6 no longer lives at 399 — it has shifted up ~130+ lines. If 16-02's `AGENTS.md` edit uses those literal addresses (rather than header anchors as 16-03 explicitly does), it will cut the wrong region (now somewhere in §8/§11). The cited line numbers are fine as *content-identity* of the source material, but the plan must state — as 16-03 does — that the `AGENTS.md` mutation locates §6 by `^## 6\.` → `^## 7\.`/next-header. **Confirm 16-02 is header-anchored, not line-addressed.**

#### MEDIUM — Routing table ships dangling pointers for ingest/query/reflect that contradict still-inline content
16-04 inserts routing rows for `schema/workflows/{ingest,query,reflect}.md`, which do not exist until Phase 17, while the actual workflow content **remains fully inline in §11** of core (Phase 16 only seeds lint decay math). So an agent given only `AGENTS.md` reads a router row saying "go to `schema/workflows/ingest.md`," follows it, gets file-not-found — *and the content was right there in §11 the whole time*. A dangling pointer that overrides present inline content is worse than no row. Note `lint.md` is **not** in this bucket: 16-02 creates it, so its row resolves (to a partial). **Fix:** for ingest/query/reflect, either omit the rows until Phase 17 or mark them explicitly "inline in §11 until Phase 17 — do not dereference yet," visually distinct from the resolvable `lint.md`/reference rows.

#### MEDIUM — No automated guard preserves the load-bearing v1.1.1 "filename/path ONLY" sentence
The milestone treats "Obsidian resolves `[[X]]` by filename/path ONLY" as a verbatim truth that must survive into `wikilinks.md`. Nothing in the plan set *gates* this — survival depends entirely on author discipline during a hand-move, and a paraphrase would pass every existing test (`test_no_kahneman`, neutrality, sync all stay green on a reworded sentence). For a fact this load-bearing, add a one-line grep assertion to 16-03's verification (`grep -q 'filename/path ONLY' schema/reference/wikilinks.md`) and ideally a small phase-16 test. Same technique should guard the §3-resident MUST-NOT verbatim list if any of it migrates.

#### MEDIUM — §7 dissolve and §16/Appendix-C deletion need an explicit subsection→destination map to prove no silent loss
- **§7** contains more than the per-type ordering table: it has "Rules for LLM Agents" (read index first; TL;DR/Key Facts before Detail) and "Why This Matters." 16-01 merges *only the ordering table* and deletes the rest "no stub." Much of the agent-rule essence is duplicated in §3's "LLM Navigation Rule," so it probably survives — **but the plan should assert that mapping**, not assume it.
- **Appendix C** is a 10-rule quick-reference. 16-03 says "audit rules 1–10 for absorption (esp. rule 6)." "Audit for absorption" is too soft for a deletion. Each rule needs a named home (rule 6→privacy.md is the only one specified) or a conscious "already covered by §X" / "intentionally dropped."

**Fix:** add a small "disposition table" to 16-01 and 16-03 (every dissolved subsection → destination file or "dropped, rationale"). Cheap insurance against silent content loss, which is the highest-consequence failure mode of an extraction.

#### MEDIUM — Decision record `affected_pages: [index, log]` is semantically wrong; should be `[]`
`index.md` and `log.md` are navigation artifacts without `id`/frontmatter — they are not id-bearing wiki pages, and they can't carry the `decision_history` back-link that `affected_pages` is supposed to enable. The schema's own precedent for an infrastructure/inaugural record is **`affected_pages: []`** (Section 4.6 example `dr-2026-04-14-phase6-decision-type`; DRFT-04 even hard-excludes the `index`/`log` tokens from page-ID resolution). To the requester's sub-question: the DR should **not** list the extracted-from pages either — the extracted content lands in `schema/reference/*.md`, which are likewise not wiki pages. **Use `affected_pages: []`** and describe the extraction narratively in the body. *(Note: Codex disputes this — see Divergent Views; Codex argues index/log DO carry `id:` frontmatter and the value is schema-valid.)*

#### LOW–MEDIUM — The check-privacy.sh gap is real but lower-risk than flagged; the more useful observation is the asymmetry
The requester flagged "HIGH: `check-privacy.sh` doesn't cover `schema/` and ships via release." Two facts lower this:
1. `check-privacy.sh` is a **path-component guard** (`check-privacy.sh:93-96`) — it fires only if a file's *path* contains a `wiki-local/` component. The realistic leak vector for this extraction is **private terms pasted into `schema/reference/*.md` content**, which is the *neutrality* scanner's job — and Plan 16-00 closes that. The content being moved is already-public `AGENTS.md` text.
2. `bin/release.sh` doesn't even invoke `check-privacy.sh` — its pre-flight is `check-neutrality.sh` + `sync-claude --check` + a `privacy: local_only` grep (`release.sh:160,173`). So the path guard never runs at release time regardless.

So: not a HIGH content-leak. **But** there's a defensible defense-in-depth inconsistency — after 16-00, neutrality covers `schema/` while the structural path guard still doesn't, even though `schema/` is in the release ALLOWLIST (`release.sh:29`). Recommend a one-line addition of `schema` to `check-privacy.sh:76 PUBLIC_PATHS` for symmetry (and verify `tests/phase-15/test_check_privacy_rekey.sh` tolerates it). Treat as hygiene, not a blocker. *(Note: Codex rates this HIGH — see Divergent Views.)*

#### LOW — Wizard does reach end users with the reference files, but nothing verifies stub pointers resolve post-render
To the requester's wizard question: `init-wizard.sh` renders **only 5 artifacts** and does **not** copy `schema/reference/*.md`. That's fine — those files ship as static repo content (clone + `release.sh` ALLOWLIST `schema`), so end users get them via the tree, not the render. **However**, `--dry-run` only previews the 5 rendered files and checks for leftover `{{...}}` (`init-wizard.sh:935-994`); it does **not** verify that the stub pointers in the rendered `AGENTS.md` resolve to real files. 16-04's `test -f each routing target` covers only the *routing-table* targets, not the inline §4/§5/§6/§8/§13 stub pointers. So `--dry-run` is *insufficient* as a stub-integrity check. Add an explicit post-render assertion that every `schema/reference/…` and `schema/workflows/…` path referenced in rendered `AGENTS.md` exists on disk (excluding the known Phase-17 rows).

### 4. Suggestions (concrete)

1. **Make template-mirror per-commit and per-plan.** Move template stub edits into 16-01/02/03 (same commit as the `AGENTS.md` edit), not deferred to 16-04. Keep `AGENTS.md ≡ template` (modulo the 4 `{{placeholders}}`) true at every commit.
2. **Add the parity-test updates to the plan explicitly.** phase-09.1 (§4/§16) and phase-10 (§5) encode the monolith shape; the plan must rewrite their assertions to the post-extraction reality, and 16-04 (or a new final task) must **run them** alongside phase-07/08.
3. **Confirm 16-02 is header-anchored** for the `AGENTS.md` §6 mutation; strip the absolute line numbers from the *edit* step (keep them only as source-content provenance).
4. **Disposition tables** for §7 and §16/Appendix-C: every dissolved subsection → file or "dropped + why."
5. **Grep gates** for the v1.1.1 piped-link sentence and any migrated MUST-NOT verbatim text.
6. **Routing table:** render ingest/query/reflect rows as "inline in §11 until Phase 17," visually distinct from resolvable rows; or omit until Phase 17.
7. **DR:** `affected_pages: []`; narrate extraction in the body.
8. **Hygiene:** add `schema` to `check-privacy.sh` PUBLIC_PATHS; add a stub-target existence assertion to 16-04.
9. **Consider a render-equality smoke check** (`render(template, repo answers) == AGENTS.md`) as the durable guard that template and core never diverge again — this is the structural fix that makes concern #1 un-recurrable.

### 5. Risk Assessment

**Overall: HIGH (as written) → reducible to LOW–MEDIUM with the template-sync and test-impact fixes.**

Justification: the *content* extraction is low-risk and well-reasoned, and the byte-equality discipline for AGENTS↔CLAUDE is sound. The risk concentrates in two things the plan under-specifies: (1) the template mirror is unowned/mis-sequenced and silently breaks three pre-existing parity tests *and* the wizard render path — this is not cosmetic, it corrupts what new users receive; and (2) 16-02's apparent line-addressing against an already-shifted file. Both are deterministic failures, not edge cases. They are also entirely fixable in a short re-plan pass — none require rethinking the seams. The privacy/neutrality concern the requester weighted highest is, on inspection of the actual gates, the *least* of the real risks. Fix template-sync ownership, sequence it per-commit, and reconcile the parity tests, and this becomes a clean, low-risk extraction.

---

## Codex Review

### Summary

The plan set is directionally good, but not yet safe to execute as written. The extraction design is coherent, especially the consumer split for §6, but the tooling boundary does not yet match the new authority boundary. The biggest blockers are: `schema/` ships publicly but is not covered by `check-privacy.sh`; `init-wizard.sh` currently renders only five artifacts and does not copy `schema/reference/*`; Plan 16-02 uses original line numbers after Plan 16-01 has already shifted the file; and existing "AGENTS.md is the only rules file" language will become false unless updated broadly.

### Strengths

- Good sequencing to arm `check-neutrality.sh` before adding public `schema/reference/*` files.
- The §6 consumer split is mostly right: contradiction marker syntax belongs with provenance/inline grammar, while decay/staleness math belongs with lint.
- Repeated `AGENTS.md` → `CLAUDE.md` sync checks are the right guard for byte equality.
- Creating a decision record is appropriate for this structural schema change.
- Plan 16-03 correctly switches to header-based extraction after prior edits shift line numbers.

### Concerns

- **HIGH:** `schema/` is public in releases, but `check-privacy.sh` does not scan it. Confirmed `bin/release.sh` allowlists `schema` (bin/release.sh), while `check-privacy.sh` public paths omit it (bin/check-privacy.sh:76). This is a real leak risk because `schema/wiki-local/...` or copied local-only material under `schema/` could ship.

- **HIGH:** The wizard does not currently copy extracted reference files. `_render_all_five` writes only `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, one decision record, and `wiki-cloud/index.md` (bin/init-wizard.sh:853). `--dry-run` only diffs those same five artifacts. So broken or missing `schema/reference/*` targets would not be caught.

- **HIGH:** Plan 16-02 relies on original §6 line numbers after Plan 16-01 has already replaced §4/§5 and deleted §7. Those line numbers will be wrong unless 16-02 extracts from a saved pre-edit snapshot. Use header/sentinel extraction, or extract all source slices before mutating core.

- **HIGH:** The plan updates some "sole source" wording, but likely misses other now-false authority claims. Current schema rules say conventions do not live in `schema/`; Phase 16 makes that false. Grep for `sole`, `authoritative`, `No other file`, `does NOT contain rules`, and update all contradictory statements.

- **MEDIUM:** Mirroring `schema/AGENTS.template.md` only in 16-04 leaves several commits where `AGENTS.md` points to extracted refs but the wizard template still renders the old monolith. That is risky for bisectability and per-commit CI. Mirror template changes with each core stub commit, or make the extraction/template mirror one atomic commit.

- **MEDIUM:** §16 deletion and Appendix C absorption are under-specified. "Audit rules 1-10" is not enough. Require a mapping table: each appendix item goes to a destination file or has an explicit deletion rationale.

- **MEDIUM:** The routing table should not contain bare links to nonexistent Phase-17 files. If `ingest.md`, `query.md`, and `reflect.md` do not exist yet, the row should say "currently resident in §11; extraction planned for Phase 17," without presenting a missing file as authoritative.

- **MEDIUM:** Verbatim preservation is not strongly guarded. Add grep tests for the exact Obsidian truth: `Obsidian resolves [[X]] by filename/path ONLY`, plus the universal piped-link rule.

- **MEDIUM:** Seeding `schema/workflows/lint.md` before Phase 17 is acceptable only if Phase 17 is explicitly told to expand the existing file. Otherwise it creates a merge/ownership hazard.

- **LOW:** `affected_pages: [index, log]` is schema-valid because both files have `id: index` and `id: log`. Do not list AGENTS.md or extracted reference files in `affected_pages`; put those in `Sources` or `Consequences`.

### Suggestions

- Add a Plan 16-00b: include `schema` in `check-privacy.sh` `PUBLIC_PATHS`, update its help text/docs, and add a regression test.
- Add `check-privacy.sh` to `bin/release.sh` staged preflight, not only CI.
- Add a Phase 16 routing test that parses all non-Phase-17 paths in the routing table and asserts `test -f`.
- Replace `init-wizard --dry-run` verification with `init-wizard --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/...` plus checks that all stub targets exist in the rendered/package context.
- Add extraction integrity checks: compare source slices from the pre-extraction commit to new files, or at least grep for sentinel phrases from every moved section.

### Risk Assessment

**HIGH as written.** The prose architecture is sound, but the implementation plans leave public-surface privacy coverage and wizard/reference-file delivery unresolved. Fix those tooling gaps and the risk drops to medium or low.

---

## Consensus Summary

Both reviewers independently rate the plan set **HIGH risk as written**, while agreeing the *content/seam design is sound* and every concern is fixable in a short re-plan pass without rethinking the architecture. Several of the highest-rated concerns were independently verified against the live repo during this review (parity tests, wizard render path, line-shift hazard, check-privacy gap).

### Agreed Strengths

- Wave-0 ordering (arm `check-neutrality.sh` over `schema/` before any extraction commit) is correct.
- The §6 consumer-split routing (Contradiction Inline Syntax → provenance.md; decay/staleness → lint.md) is correct and well-reasoned.
- Repeated `sync-claude --check` byte-equality discipline at each commit is the right guard.
- Plan 16-03's switch to header-anchored (not line-number) extraction is the correct discipline.
- Writing a schema-update decision record is appropriate.

### Agreed Concerns (highest priority — both reviewers)

1. **[HIGH] Wizard / template-mirror delivery gap.** `init-wizard.sh` renders only 5 artifacts and does NOT copy `schema/reference/*.md`; the template mirror of the §4–§16 stubs is deferred to 16-04 (or unowned). Both flag that the template must be mirrored per-commit (not deferred) and that the wizard/template path is under-verified. **Claude additionally proved** this breaks pre-existing parity tests (`tests/phase-09.1/test_template_parity.sh` for §4/§16, `tests/phase-10/test_agents_template_parity_section_5.sh` for §5) — confirmed present in the repo; no plan runs them.
2. **[HIGH] Plan 16-02 line-addressing after 16-01 shifts the file.** §6 no longer lives at line 399 once 16-01 collapses §4/§5 (~130+ line shift). 16-02 must extract by header anchor / pre-edit snapshot, exactly as 16-03 already does. (Confirmed: §6 header is at line 399 in the current monolith; 16-01 removes ~250 lines above it.)
3. **[MEDIUM] Routing table dangling Phase-17 rows.** ingest/query/reflect rows point to files that don't exist while the content is still inline in §11. Mark them "inline in §11 until Phase 17 — do not dereference" or omit. Both reviewers agree `lint.md` is fine (16-02 creates it).
4. **[MEDIUM] No automated guard for the verbatim v1.1.1 truth.** Add `grep -q 'filename/path ONLY'` (and the piped-link rule) to 16-03 verification; a paraphrase currently passes all gates.
5. **[MEDIUM] §16/Appendix-C absorption under-specified.** "Audit rules 1–10" is too soft for a deletion; require an explicit disposition/mapping table (each rule → destination file or conscious "dropped + rationale"). Claude extends this to the §7 dissolve too.
6. **[MEDIUM] Template-mirror timing leaves per-commit CI red windows** (bisectability + "CI gates pass unchanged in behavior" violated across the Wave-1→Wave-2 window).

### Divergent Views (worth investigating)

- **check-privacy.sh `schema/` gap severity.** Codex rates this **HIGH** (schema ships via release ALLOWLIST; a `wiki-local/` path under schema/ could leak). Claude rates it **LOW–MEDIUM hygiene**, arguing (a) check-privacy is only a *path-component* guard and the real extraction leak vector is *content* terms, which 16-00 already covers via neutrality; and (b) `release.sh` doesn't even invoke check-privacy.sh at release time. **Resolution path:** both agree the one-line fix (add `schema` to `check-privacy.sh:76 PUBLIC_PATHS`) is worth doing — it is cheap and removes the asymmetry — so adopt it regardless of severity framing. Disagreement is only about whether it blocks.

- **DR `affected_pages` value.** Claude says `affected_pages: [index, log]` is **semantically wrong → use `[]`** (index/log are navigation artifacts; DRFT-04 hard-excludes the index/log tokens from page-ID resolution; §4.6 precedent for infra records is `[]`). Codex says it is **schema-valid because index.md and log.md carry `id: index`/`id: log` frontmatter** (LOW). **Resolution path:** verify whether `wiki-cloud/index.md` and `wiki-cloud/log.md` actually carry `id:` frontmatter; if they do, the value is technically valid but the DRFT-04 exclusion + §4.6 `[]` precedent still argue for `[]` as the cleaner choice. Both agree the DR should NOT list AGENTS.md or the extracted reference files in `affected_pages`.

- **Now-false authority language scope.** Codex raises an additional **HIGH** not surfaced by Claude: beyond line 3 and the §3 MUST-NOT line, grep the whole spec for `sole`, `authoritative`, `No other file`, `does NOT contain rules` and fix every now-contradictory statement (e.g., §2's "schema/ does NOT contain rules or conventions" becomes false once `schema/reference/*.md` hold authoritative rules). Claude's plan-1 framing covers the two known lines but does not call out the broader sweep. **Resolution path:** adopt Codex's grep-sweep as a required step in 16-04.
