---
phase: 14
reviewers: [codex]
reviewed_at: 2026-06-03T15:40:00Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 3
---

# Cross-AI Plan Review — Phase 14 (Convergence Cycle 3)

> Convergence cycle 3. The Phase 14 plans (uniform piped links `[[id|Title]]`) were revised to
> address the 3 HIGH-severity concerns Codex raised in cycle 2. This review assesses the CURRENT
> plan text and reports only the HIGHs that REMAIN UNRESOLVED.
>
> **Cycle-2 → cycle-3 disposition:** 2 of 3 cycle-2 HIGHs FULLY RESOLVED (#1 `--fix` frontmatter,
> #2 T4 fixture); 1 PARTIALLY RESOLVED (#3 unmasked literals — now only `wiki/index.md`); plus 1
> NEW HIGH raised this cycle (T5 multi-match fixture). **Unresolved HIGH count this cycle: 2.**

## Codex Review

**Summary**

The cycle-3 plans close the two core implementation defects well: frontmatter preservation is now
explicitly designed around full-file positional rewrites, and T4's malformed-target fixture now
correctly normalizes to a known id. One cycle-2 literal-link issue is only partially closed because
14-01 still authors an unbackticked literal `[[id|Title]]` in `wiki/index.md`. There is also one
new HIGH: the T5 multi-match fixture is internally inconsistent with the actual normalizer.

**Cycle-2 HIGH Disposition**

| Cycle-2 HIGH | Disposition | Verification |
|---|---:|---|
| #1 14-02 `--fix` frontmatter corruption | FULLY RESOLVED | 14-02 now reads the full file into `linkres_scan` (`open(fpath).read()`, NOT parsed `body`), masks frontmatter length-preservingly via `_FM_RE`, rewrites by positional `raw[last:start]` splicing, and adds T13 byte-for-byte frontmatter-preservation regression. |
| #2 T4 fixture inconsistency | FULLY RESOLVED | `[[Alpha!|Alpha]]` is valid: `Alpha!` is not literal id `alpha`, but `normalize_link("Alpha!")` strips `!` via `_PUNCT_RE` → `"alpha"`, producing exactly one normalized match → verdict `error`, not `gap`. Verified against `bin/lint.sh` normalize_link. |
| #3 Unmasked literal wikilinks in live wiki/DR/log prose | PARTIALLY RESOLVED | Old-DR `[[X]]` and the 14-03 log-entry literals are now backticked, but 14-01 Task 3 Step C still adds an unbackticked literal `[[id|Title]]` to the `wiki/index.md` DR summary entry. |

**Strengths**

- The masking/offset-preservation design is sound: full-file input plus length-preserving masking
  avoids the prior frontmatter-drop failure mode.
- T13 is the right regression guard — it proves the exact corruption scenario cannot recur silently.
- Dependency ordering is now clear: 14-03 depends on 14-01 and 14-02, and the final post-log
  `linkres wiki/` gate is correctly placed AFTER the log append (14-03 Task 2 Step D).
- The examples/ dedicated masked scanner avoids the vacuous `bin/lint.sh examples/` pass caused by
  `EXCLUDE_DIRS` exclusions.
- The old-DR redirect note correctly distinguishes the real successor link (live, piped) from the
  literal `` `[[X]]` `` example (backticked).

**Concerns**

- **HIGH (PARTIALLY RESOLVED cycle-2 #3): `wiki/index.md` still gets an unmasked literal placeholder
  link.** 14-01 Task 3 Step C instructs adding the index entry:
  `` - [[dr-2026-06-03-uniform-piped-links|...]] -- Corrects §8 to mandate uniform [[id|Title]] piped links; ... ``
  The second `[[id|Title]]` is a literal documentation example, is NOT a real link to a known page
  id, and is NOT backticked. Under 14-02's `_classify_piped()`, `"id"` is not a known id, normalizes
  to `"id"` (no page match), has no `/` → returns `gap` → `continue` (no finding). So it does NOT
  break the `linkres wiki/` exit-0 gate, but it (a) survives as a spurious unresolved red-link node
  in the Obsidian graph and (b) violates 14-01's own must-have ("the ONLY unbackticked `[[...]]`
  links are real piped links to known page ids"). 14-01's automated verify only checks the new-DR
  and old-DR files for backticking — NOT `index.md` — so this literal slips past every automated
  check in the plan. *Fix: backtick it — ``mandate uniform `[[id|Title]]` piped links``.*

- **HIGH (NEW this cycle): T5's multi-match fixture does not actually create a multi-match.**
  14-02 Task 2 specifies fixtures `gamma-one` title="Gamma Topics" and `gamma-two` title="Gamma Topic",
  asserting "both normalize to gamma-topic" so bare `[[gamma topics]]` yields a multi-match WARNING.
  But `_PLURAL_MAP` in `bin/lint.sh` (lines 1081-1084) only maps `contexts`/`policies`/`contracts` —
  NOT `topics`. So `normalize_link("Gamma Topics")` → `"gamma topics"` and
  `normalize_link("Gamma Topic")` → `"gamma topic"` are DIFFERENT keys: `[[gamma topics]]` matches
  only gamma-one (unique) → the unique-match error+fixable path, NOT the asserted multi-match WARNING.
  T5 as written will fail (verified against `bin/lint.sh:1081`). *Fix: use a pair the `_PLURAL_MAP`
  actually collapses (e.g. titles "Gamma Contract" / "Gamma Contracts" with bare `[[gamma contracts]]`),
  or two pages whose titles normalize identically by some other documented rule.*

**Suggestions**

- Backtick the literal in the 14-01 index entry: ``mandate uniform `[[id|Title]]` piped links``.
- Add a verification grep/scanner for unmasked placeholder targets (`[[id|...]]`, `[[X]]`,
  `[[Title]]`, `[[<...>|...]]`) across `wiki/index.md`, `wiki/log.md`, and `wiki/decisions/*.md` —
  not just the two DR files.
- Fix T5 with a plural pair covered by `_PLURAL_MAP` (e.g. "Gamma Contract" / "Gamma Contracts"),
  or two pages with an identical normalized title.
- Update 14-03's stale threat-model wording ("--fix regex scoped to post-frontmatter body" in
  T-14-03-01) to match the corrected full-file-plus-mask design from 14-02.

**Risk Assessment**

Overall risk is **HIGH as written** until the two remaining HIGHs are patched. The production
rewrite design is much stronger than cycle 2, but the live `wiki/index.md` placeholder can survive
lint as a silent `gap` (spurious graph node + violates the plan's own must-have), and the T5 fixture
as written will misvalidate / break the re-pointed test suite.

Unresolved HIGH count this cycle: 2.

---

## Consensus Summary

Only one reviewer (Codex) was invoked (`--codex`), consistent with cycles 1 and 2.

### Agreed Strengths

- Sound masking/offset-preservation design (full-file input + length-preserving mask) — closes the
  cycle-2 frontmatter-corruption HIGH.
- T13 frontmatter-preservation regression test is the correct guard.
- T4 fixture corrected to `[[Alpha!|Alpha]]` — now genuinely yields `error`, not `gap`.
- Correct Wave 2 dependency ordering + final post-log `linkres wiki/` gate.
- Dedicated masked `examples/` scanner (non-vacuous).

### Agreed Concerns (cycle-3 unresolved HIGHs — 2)

1. **Unbackticked literal `[[id|Title]]` in the `wiki/index.md` DR entry (cycle-2 #3, PARTIALLY
   RESOLVED)** — survives the linkres gate as a silent `gap`, produces a spurious unresolved graph
   node, and violates 14-01's own must-have; 14-01's backtick verify never checks `index.md`.
2. **T5 multi-match fixture broken (NEW)** — "Topics"/"Topic" are not in `_PLURAL_MAP`
   (only contexts/policies/contracts), so they normalize to distinct keys: `[[gamma topics]]` is a
   unique match, not the asserted multi-match WARNING. The re-pointed test will fail.

### Divergent Views

None — single reviewer.

### Recommended next action

Re-plan to fold in the 2 remaining HIGHs before executing Wave 1:
- 14-01 Task 3 Step C: backtick the literal `[[id|Title]]` in the `wiki/index.md` entry, and extend
  the backtick/unmasked-literal verify to cover `index.md` (+ `log.md`, `decisions/*.md`).
- 14-02 Task 2: fix the T5 fixture to a plural pair actually collapsed by `_PLURAL_MAP` (e.g.
  "Gamma Contract" / "Gamma Contracts") so `[[gamma contracts]]` truly yields a multi-match WARNING.
- (MEDIUM/cleanup) 14-03 T-14-03-01: correct the stale "regex scoped to post-frontmatter body"
  threat-model wording.

Run `/gsd-plan-phase 14 --reviews` to incorporate.
