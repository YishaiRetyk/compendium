---
phase: 14
reviewers: [codex]
reviewed_at: 2026-06-03T11:57:47Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 1
---

# Cross-AI Plan Review — Phase 14

> Re-plan of Phase 14 (Graph Link Resolution) after the self-alias premise was falsified at
> the LINK-10 human-verify gate. Reviewed approach: uniform piped links `[[id|Title]]`.
> This is review cycle 1 (no prior REVIEWS.md existed).

## Codex Review

## Summary

The re-plan has the right architectural direction: uniform `[[id|Title]]` links are the simplest durable fix, and splitting schema, enforcement, and data migration is sensible. The main risk is in 14-02: the proposed lint logic does not fully enforce the new convention and has unsafe rewrite/scanning behavior. As written, it can silently allow bare red links, scan or rewrite code/comment/frontmatter examples, and leave the orphan check partially dependent on aliases.

## Strengths

- Correctly abandons the false self-alias premise and avoids plugin dependency.
- Good wave structure: schema/enforcement first, data rewrite second, human Obsidian verification last.
- DR supersession is explicitly handled, including old/new `supersedes` fields.
- `AGENTS.md` ↔ `CLAUDE.md` byte equality and template parity tests are called out.
- `--fix` strategy is directionally right: unique match auto-fix, ambiguous match manual, idempotency required.
- Plan 14-03 correctly treats the rewrite as mechanical and avoids adding new links.

## Concerns

- **HIGH:** 14-02 allows bare no-match links to pass. That violates the new unconditional rule. A bare `[[Future Concept]]` should still be a `linkres` error or warning requiring `[[future-concept|Future Concept]]`.

- **HIGH:** The proposed `--fix` rewrite applies to the entire file content, not just body text. It can rewrite frontmatter, fenced code, inline code, HTML comments, and FORBIDDEN PATTERNS examples.

- **HIGH:** The scanner does not mask fenced code, inline code spans, or HTML comments. This matters because the new DR/log/schema prose contains literal examples like `[[id|Title]]`, `[[X]]`, and `[[backpressure|Backpressure]]`.

- **HIGH:** The new DR frontmatter `summary` includes `[[id|Title]]`, which is a wikilink in YAML frontmatter and violates the schema rule (§3 / §8 rule 6). Escape it or describe it without Obsidian wikilink syntax. *(Verified against 14-01-PLAN.md line 431: the `summary:` string literally contains `[[id|Title]]`.)*

- **HIGH:** Orphan resolution may still use aliases if `obsidian_map` continues indexing aliases. Because the prior run left 53 self-aliases, this can falsely mark pages as connected. *(Verified against bin/lint.sh lines 1164-1166: the orphan block still indexes `aliases` into `obsidian_map`; 14-02 Step D's "reconcile orphan to id-only" is not reflected in concrete code edits.)*

- **HIGH:** 14-02 Task 1 runs `tests/phase-09/run.sh` before Task 2 rewrites the old self-alias tests. That will likely fail. Update tests before expecting the aggregator to pass.

- **HIGH:** Test T4 is internally inconsistent. `[[bad-target|My Concept]]` does not normalize to `my-concept`, so the proposed logic will treat it as a gap, not an error.

- **MEDIUM:** Gap-vs-error semantics are underspecified. "Unknown target is error" conflicts with "unknown target may be red-link gap." The actual rule should be explicit: unknown piped slug with no known normalized match is a gap; malformed target matching an existing page is linkres error.

- **MEDIUM:** The plan says display text must be exact canonical `title`, but also accepts plural/casing variants as cosmetic display text. Pick one. Current lint only validates target, not display.

- **MEDIUM:** `[[concepts/foo|Foo]]` path-style links would resolve in Obsidian but fail the id-only convention; the proposed logic may silently pass them as gaps if no normalized match exists.

- **MEDIUM:** Examples are excluded from lint, so "linkres exits 0 over examples/" is vacuous. Verification must use a separate scanner/parser or temporarily include examples in a read-only mode.

- **MEDIUM:** Grep checks for bare links only catch capitalized links. Lowercase bare links like `[[bounded-context]]` or `[[new-page]]` can remain undetected.

- **MEDIUM:** Test fixtures use real vault slugs like `bounded-context` and `hack-agentive-stack`. If tests are public/template-adjacent fixtures, this conflicts with the neutrality rule.

- **LOW:** `CLAUDE.md` minimum line count is brittle and not tied to correctness.

- **LOW:** Full CI claims should be careful because the plan already identifies pre-existing canonical fixture debt.

## Suggestions

- Make bare links always a `linkres` finding. Only `--fix` should distinguish unique, ambiguous, and no-match cases.
- Add a markdown masking helper before scanning/fixing: remove or protect YAML frontmatter, fenced code blocks, inline code spans, and HTML comments.
- Implement replacements positionally against the masked body, not with global `rewrite_re.sub(..., content)`.
- Remove aliases from orphan-resolution maps entirely. Use only filename stem/id targets for graph connectivity.
- Add explicit tests for: bare no-match fails, inline-code example ignored, fenced code ignored, HTML comment ignored, YAML frontmatter not rewritten, path target rejected, alias does not count as inbound.
- Change T4 to something like `[[My Concept|My Concept]]` or `[[my concept|My Concept]]` if the intended error is "target normalizes to known id but is not the actual id."
- Replace test fixture slugs with neutral placeholders.
- Make examples verification a dedicated parser command, not `bin/lint.sh examples/` if examples remain excluded.
- Escape literal wikilink syntax in wiki/log/DR prose, or rely on the new masking logic and verify it.

## Risk Assessment

**Overall risk: HIGH.** The strategic plan is sound, but the enforcement implementation has enough edge-case failures that it could report success while leaving unresolved or malformed links, or corrupt documentation examples during `--fix`. Tightening 14-02 before Wave 2 is the key prerequisite.

---

## Consensus Summary

Only one reviewer (Codex) was invoked (`--codex`), so "consensus" reflects a single perspective. The review is strongly positive on the *strategy* (uniform piped links, wave ordering, DR supersession) and strongly negative on the *enforcement implementation* in 14-02.

### Agreed Strengths

- Correct architectural pivot away from the falsified self-alias premise to dependency-free uniform piped links.
- Sound wave decomposition: convention + enforcement (Wave 1, parallel) → data remediation + human-verify (Wave 2).
- DR supersession chain and AGENTS.md ↔ CLAUDE.md byte-equality / template-parity constraints explicitly handled.

### Agreed Concerns (highest priority — all from cycle 1, all unresolved)

The HIGH-severity findings cluster around **14-02 (linkres re-point) correctness and safety**, plus one in **14-01**:

1. **Whole-file `--fix` rewrite + unmasked scanner** — the proposed `rewrite_re.sub(..., content)` operates on the entire file, and neither the scanner nor the rewriter masks fenced code, inline code, HTML comments, or frontmatter. The schema prose, DR bodies, and FORBIDDEN-PATTERNS comments contain literal `[[...]]` examples that would be corrupted or falsely flagged. (Two related HIGHs.)
2. **Orphan check still resolves via aliases** — `obsidian_map` indexes `aliases` (verified in bin/lint.sh); with 53 vestigial self-aliases on `main`, the orphan check can falsely report pages as connected, defeating the verification of the actual fix.
3. **Bare no-match links pass silently** — under the locked "unconditional piped" rule (D-02), a bare `[[Future Concept]]` with no match should still be a `linkres` finding; the plan lets it through as a gap.
4. **DR `summary` frontmatter contains a `[[id|Title]]` wikilink** — violates the no-wikilinks-in-frontmatter rule (verified, 14-01 line 431).
5. **Test-ordering and a broken test case** — 14-02 Task 1 runs the full `run.sh` aggregator before Task 2 re-points the old self-alias tests (will fail); test T4's fixture is internally inconsistent and won't produce the asserted error.

### Divergent Views

None — single reviewer.

### Recommended next action

Re-plan 14-02 (and the one 14-01 frontmatter fix) before executing Wave 1. Run `/gsd-plan-phase 14 --reviews` to fold these findings in. Key fixes: body-masking helper shared by scan + `--fix`; positional (not global-sub) rewrite; remove aliases from orphan resolution; decide bare-no-match policy (finding vs. gap) and align tests; fix the T4 fixture and re-point tests before invoking `run.sh`; de-wikilink the DR `summary`; neutralize test-fixture slugs.
