---
phase: 14
reviewers: [codex]
reviewed_at: 2026-06-03T12:14:51Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 2
---

# Cross-AI Plan Review — Phase 14 (Convergence Cycle 2)

> Convergence cycle 2. The Phase 14 plans (uniform piped links `[[id|Title]]`) were revised to
> address the 7 HIGH-severity concerns Codex raised in cycle 1. This review assesses the CURRENT
> plan text and reports only the HIGHs that REMAIN UNRESOLVED.
>
> **Cycle-1 → cycle-2 disposition:** 5 of 7 cycle-1 HIGHs FULLY RESOLVED (#1, #3, #4, #5, #6);
> 1 PARTIALLY RESOLVED (#2); 1 UNRESOLVED (#7); plus 1 NEW HIGH raised this cycle.
> **Unresolved HIGH count this cycle: 3.**

## Codex Review

**Summary**

The revised plans close most of the cycle-1 HIGHs in intent and test coverage, but not all. HIGH
#1, #3, #4, #5, and #6 are resolved by the current plan text. HIGH #2 is only partially resolved
because the proposed positional `--fix` still risks destructive writes by operating on parsed
`body` but writing it back as the whole file. HIGH #7 remains unresolved because the revised T4
fixture is still semantically wrong against the current `normalize_link()` behavior. There is also
one new HIGH: planned live wiki/log/DR prose introduces unmasked literal `[[...]]` examples that the
new linkres rules will treat as real links.

**Cycle-1 HIGH Disposition**

| Prior HIGH | Status | Justification |
|---|---:|---|
| #1 bare no-match links passed silently | RESOLVED | 14-02 explicitly says every bare `[[X]]` is a finding, including no-match red links, and adds a no-match error path (T7). |
| #2 `--fix` rewrote unsafe regions | PARTIALLY RESOLVED | Masking + positional replacement are specified, but 14-02 builds the rewrite worklist from `body` and writes `new_content` to `abs_path`, which would overwrite the full file with body-only content (dropping frontmatter). |
| #3 scanner did not mask code/comments | RESOLVED | `mask_markdown()` masks frontmatter, fenced code, inline code, and HTML comments; T12 covers those spans. |
| #4 DR frontmatter wikilink | RESOLVED | The new DR `summary:` is prose-only with an explicit `awk` check for zero `[[...]]` in YAML frontmatter. |
| #5 orphan resolution still indexed aliases | RESOLVED | 14-02 removes alias indexing from orphan resolution; T11 asserts alias-only inbound does not save a page from orphan. |
| #6 aggregator ran before tests re-pointed | RESOLVED | 14-02 explicitly defers `tests/phase-09/run.sh` until after `test_lint_linkres.sh` is re-pointed (Task 2). |
| #7 inconsistent T4 fixture | UNRESOLVED | New T4 uses `[[Alpha Concept|Alpha]]` while `alpha` has id/title `alpha`/`Alpha`. `normalize_link("Alpha Concept")` → `"alpha concept"` (two words) ≠ `"alpha"`, so `_classify_piped` returns `gap`, not `error` — the asserted ERROR will not be produced. Same defect class as cycle 1. |

**Strengths**

- The revised plans correctly invert the schema convention from aliases to filename/path resolution.
- Dependency ordering is much better: 14-03 depends on both docs (14-01) and lint behavior (14-02).
- The masking contract is explicit and test-backed (T12).
- Orphan behavior is now aligned with real Obsidian resolution (alias-free).
- The `examples/` vacuous-lint issue is addressed with a dedicated masked scanner (not `bin/lint.sh`).

**Concerns**

- **HIGH (PARTIALLY RESOLVED cycle-1 #2): 14-02 `--fix` can still corrupt wiki pages.**
  In Task 1 Step C, `linkres_scan` appends `(rel, fpath, body)` for `all_pages`, then the rewrite
  loop iterates `raw[last:start]` over that `body` and writes `new_content` to `abs_path`. Since
  `body` is post-frontmatter content, writing it back to the full file path drops YAML frontmatter
  and any pre-body content. The fix must operate on full file text (with frontmatter masked
  in-place by `mask_markdown`, whose `_FM_RE` already handles a leading `---...---`), or preserve
  and reapply the frontmatter + body offset. *(Verified against bin/lint.sh: `mask_markdown` masks
  frontmatter, so reading the FULL file is the intended design; the plan's `body`-only worklist
  contradicts it.)*

- **HIGH (UNRESOLVED cycle-1 #7): T4 remains internally inconsistent.**
  `[[Alpha Concept|Alpha]]` does not normalize to `alpha` under the current `normalize_link()`
  (verified: it yields `"alpha concept"`, two words). The verdict will be `gap`, not the asserted
  `error`. Use a target that normalizes to an existing page but is not the id — e.g.
  `[[Alpha!|Alpha]]` (punctuation stripped → `"alpha"`) or the parenthetical case
  `[[Beta Parenthetical|Beta (Parenthetical)]]` for a page with title `Beta (Parenthetical)`,
  id `beta` (`normalize_link` strips parens as characters → `"beta parenthetical"` — confirm the
  chosen fixture actually yields a single normalized match to a real page).

- **HIGH (NEW this cycle): planned live wiki/DR/log prose contains unmasked literal wikilinks.**
  14-01 Step B adds an old-DR redirect note containing a bare `[[X]]` in blockquote prose (`(Obsidian
  resolves [[X]] by filename stem + aliases)`) — outside any masked span (blockquotes are not masked).
  14-03 Step C appends a log entry containing `[[id|Title]]` (piped, non-existent target) in plain
  prose. After Wave 2, the bare `[[X]]` becomes an unfixable no-match linkres ERROR, and the piped
  `[[id|Title]]` becomes a spurious `gap`/red-link — both can make the final `linkres wiki/` gate
  (14-03 Task 1 Step E / verification) fail. Backtick or rephrase these literal link examples in the
  DR redirect note and the log entries so they live in masked (inline-code) spans.

**Suggestions**

- Change 14-02's `linkres_scan` tuple to carry the FULL file content (not parsed `body`) before the
  positional rewrite; rely on `mask_markdown`'s `_FM_RE` to protect frontmatter.
- Add an explicit regression test asserting `--fix` preserves frontmatter byte-for-byte except for
  intended body edits.
- Replace T4 with `[[Alpha!|Alpha]]` or `[[Beta Parenthetical|Beta (Parenthetical)]]` and confirm
  the normalized match count is exactly 1 so the verdict is `error`.
- Backtick all literal link syntax in wiki/log/DR prose: `` `[[X]]` ``, `` `[[id|Title]]` ``,
  `` `[[Title]]` ``.
- Add a final `linkres wiki/` check AFTER appending the 14-03 log entry, not only before.

**Risk Assessment**

Overall risk is **HIGH as written** because 14-02's proposed implementation can destroy frontmatter
during `--fix`, the T4 test will not assert what it claims, and the planned wiki/log/DR content can
make the final linkres gate fail. The conceptual direction is sound; fixing those plan details would
bring phase risk down substantially.

---

## Consensus Summary

Only one reviewer (Codex) was invoked (`--codex`), so "consensus" reflects a single perspective —
consistent with cycle 1's reviewer set.

### Agreed Strengths

- Correct schema inversion (filename/path resolution; uniform piped links).
- Improved wave dependency ordering (14-03 depends on 14-01 + 14-02).
- Explicit, test-backed masking contract (T12) and alias-free orphan resolution (T11).
- Dedicated masked scanner for `examples/` (resolves cycle-1's vacuous-lint MEDIUM).

### Agreed Concerns (cycle-2 unresolved HIGHs — 3)

1. **14-02 `--fix` frontmatter corruption (cycle-1 #2, PARTIALLY RESOLVED)** — the rewrite worklist
   is built from post-frontmatter `body` but written back to the full file path, dropping frontmatter.
2. **T4 fixture still inconsistent (cycle-1 #7, UNRESOLVED)** — `[[Alpha Concept|Alpha]]` normalizes
   to `"alpha concept"` ≠ `"alpha"`, so it yields `gap`, not the asserted `error`.
3. **Unmasked literal wikilinks in live wiki/DR/log prose (NEW)** — the 14-01 redirect note's bare
   `[[X]]` and the 14-03 log entry's `[[id|Title]]` sit in unmasked prose and will trip the final
   linkres gate.

### Divergent Views

None — single reviewer.

### Recommended next action

Re-plan to fold in the 3 remaining HIGHs before executing Wave 1:
- 14-02: read the FULL file (not `body`) into the linkres scan/rewrite worklist; add a frontmatter-
  preservation regression test; fix the T4 fixture to a target that normalizes to a real page id.
- 14-01 / 14-03: backtick (mask) the literal `[[...]]` examples in the DR redirect note and the log
  entries, and add a post-log final `linkres wiki/` check.

Run `/gsd-plan-phase 14 --reviews` to incorporate.
