---
phase: 10
reviewers: [gemini, codex]
reviewed_at: 2026-04-17
plans_reviewed: [10-01-PLAN.md, 10-02-PLAN.md, 10-03-PLAN.md, 10-04-PLAN.md, 10-05-PLAN.md]
---

# Cross-AI Plan Review — Phase 10

## Gemini Review

# Phase 10 Plan Review: Brownfield Scan + Bootstrap

## 1. Summary
The implementation plans for Phase 10 are exceptionally thorough, well-structured, and demonstrate a deep understanding of the project's technical constraints and safety posture. The strategy for onboarding existing Obsidian vaults ("brownfield") correctly prioritizes data integrity through a mechanical-only bootstrap process, idempotent transforms, and extensive byte-exact fixture testing. The division into four waves (Harness, Scan, Bootstrap, Wiring/Docs) is logical and manages complexity well, particularly the "atomicity constraint" in Plan 10-04.

## 2. Strengths
- **Dual Golden Contract (D-07):** The test harness in 10-01 is excellently designed to verify both the successful transformation of parseable files and the correct reporting/skipping of malformed ones (e.g., tabs in YAML, duplicate keys).
- **Isolation and Reproducibility:** The `W-2 ISOLATION RULE` in 10-03 (rooting tests at `input/` subdirs) is a sophisticated mitigation against tests accidentally walking their own expected-output directories.
- **Dependency Management:** Graceful handling of the `ruamel.yaml` dependency in Plan 10-03 with an actionable error message ensures a good user experience for the first non-bash-native tool.
- **Incremental Update Safety:** The `Append-Then-Synthesize` logic and the `D-02` Typed-Merge policy provide a robust framework for preventing the most common pitfall: silent frontmatter corruption.
- **Schema Alignment:** Plan 10-04's handling of the byte-equality chain (AGENTS.md -> CLAUDE.md -> Template -> Fixture) is precise and prevents CI regressions from upstream setup-parity checks.

## 3. Concerns
- **Performance of Orphan Detection (D-15):** Plan 10-03 Task 1 Step 4 describes walking raw sources and checking "any" wiki summary page for a match. In large vaults, an $O(N \times M)$ search may become slow.
  - **Severity: LOW** (Mitigated by the fact that bootstrap is typically a one-time operation).
- **False-Positive Warnings in Ingest (BRWN-10):** In Plan 10-04 Task 2, the bash check for `BF_VALUE` uses a global `grep` on the file. If a file contains `bootstrap_stage:` in a code block but not in the frontmatter, the script will print a "stripped" warning even if the Python script (correctly) does not modify the file.
  - **Severity: LOW** (UX noise only, no data loss).
- **Parallelism of Wave 3:** Plans 10-03 and 10-04 are both Wave 3. While they touch different files, 10-04 includes tests for lint/ingest that depend on the existence of bootstrapped pages.
  - **Severity: LOW** (10-04 correctly manages this by creating its own small bootstrapped fixtures in Task 3 Step F).

## 4. Suggestions
- **Optimization (10-03 T-10-03-01):** In the orphan raw-source detection logic, suggest loading all summary page `path` values into a Python `set` first, then checking each raw source against the set for $O(N+M)$ performance.
- **UX Refinement (10-04 T-10-04-02):** To avoid false-positive "stripped" warnings, consider gating the `echo "Note: stripped..."` message behind the Python script's exit code (e.g., exit 0 if modified, exit 2 if no match found). Alternatively, limit the initial `grep` to the frontmatter block using `sed -n '/^---$/,/^---$/p'`.
- **Fixture Stability (10-01 T-10-01-02):** For the `tabs-in-yaml` and `duplicate-yaml-keys` fixtures, consider pinning the expected error string in the test code to match the specific version of `ruamel.yaml` or `PyYAML` used in the target environment to make the tests as "strong" as possible.

## 5. Risk Assessment
**Risk: LOW**

The overall risk is low because:
1. **Mutation is Opt-in:** `bootstrap` defaults to dry-run, and `scan` has zero mutation by design.
2. **Git-Centric Recovery:** The plans explicitly designate Git as the canonical backup and provide a clear `git reset --hard` recipe in the documentation.
3. **Comprehensive Testing:** The 7-fixture suite covers edge cases like CRLF, Dataview-inline fields, and malformed YAML that are common in real-world Obsidian vaults.
4. **Mechanical Boundary:** The strict adherence to "mechanical-only" transforms in Phase 10 prevents the LLM from making semantic errors during the most sensitive part of the onboarding process.

The plans are ready for execution.

---

## Codex Review

**10-01-PLAN**
Summary: The harness plan is structurally sound and gives later waves a clear mechanical gate, but it overcommits on some fixture semantics before the implementation decisions are fully stabilized. The fixture roster and dual-contract idea are good; the main risk is freezing behavior too early in places where the later implementation still has discretion.

Strengths
- Establishes a reusable `tests/phase-10/` harness early, which is the right dependency inversion for BRWN-21.
- Separates parseable vs unparseable fixtures cleanly with `expected/` vs `expected-skipped-entry.md`.
- Uses strong prior-art references from `tests/phase-08` and `tests/phase-09`, which reduces novelty risk.
- Includes self-check tests, which is useful for guarding the harness itself before behavior tests accumulate.
- The fixture README and explicit roster reduce ambiguity for later executors.

Concerns
- HIGH: The objective says "6 byte-frozen fixture directories" but the plan actually creates 7 fixtures, and several acceptance criteria still talk as if the harness should initially report `0/0` before the plan also creates two tests and expects `2/2`. That inconsistency is likely to confuse an executor and a reviewer.
- MEDIUM: The parseable `expected/page.md` files freeze the exact D-14 sentinel output before Plan 03 settles details like field ordering, YAML null rendering, quote style, and CRLF normalization. That is fine if intentional, but it removes implementation latitude and should be called out as a deliberate contract, not just a fixture seed.
- MEDIUM: `tabs-in-yaml/expected-skipped-entry.md` knowingly includes a `{PARSE_ERROR}` placeholder, so it is not actually byte-frozen yet. That weakens the "dual golden contract" claim unless the contract is explicitly defined as structural for skip artifacts until Plan 03 pins the error string.
- LOW: The verification step for Task 1 expects `PHASE 10 TESTS: 0/0`, but Task 2 creates tests and the plan overall expects `2/2`. That is probably just staging confusion, but it should be normalized.

Suggestions
- Make the fixture count consistent everywhere: either say "7 fixtures" throughout or explicitly say "6 canonical per D-07 plus 1 additional duplicate-key fixture."
- Split the contract wording: Parseable fixtures: byte-exact golden outputs. Unparseable fixtures: byte-exact header/path/suggestion shape, with parse error string pinned later unless implementation normalizes it.
- State explicitly that `expected/page.md` defines canonical field order and scalar rendering for bootstrap output. Right now that is implied, but it is a major implementation constraint.
- Fix the staged aggregator expectations so Task 1 expects `0/0` only before tests exist, and Task 2 expects `2/2` after the self-checks land.

Risk Assessment: MEDIUM. The plan is good scaffolding, but there is avoidable ambiguity around fixture count and what is truly byte-frozen versus placeholder-based.

---

**10-02-PLAN**
Summary: This is a strong plan for `scan`: it keeps classification rule-based, extracts the classifier for reuse, and covers the important operator-facing contracts. The main weakness is that the gitignore-style override parser is underspecified relative to the plan's promises, and some classification logic is too simplistic for the confidence semantics it claims.

Strengths
- Good extraction boundary: `bin/lib/brownfield_classify.py` is reusable by Phase 11, which aligns with D-16 and the stated reuse goal.
- Correctly keeps `scan` PyYAML-only and defers `ruamel.yaml` to bootstrap, preserving the dependency boundary.
- Tests cover the user-visible contract well: help, report generation, exclusion defaults, unknown-page framing, confidence output, and override behavior.
- The `suggest`/`verify` exit-2 stubs reduce future dispatch churn and make the CLI shape visible early.
- The no-mutation SHA snapshot in `test_brownfield_scan_report.sh` is exactly the right safety test for BRWN-01.

Concerns
- HIGH: The classifier API and confidence rules do not really implement D-16 signal 4 as specified. The plan says inbound/outbound link density helps distinguish entity vs concept, but the sample implementation only uses outbound count and never computes inbound links at all. That means "inbound-heavy + proper-noun-like title -> entity" is not actually satisfied.
- HIGH: `.brownfield-ignore` semantics are promised as "gitignore-grammar" with negation, but the implementation note says "use `fnmatch` with a small wrapper that treats `**` as recursive." That is materially weaker than gitignore semantics and likely to mis-handle rooted patterns, directory-only patterns, and negation precedence.
- MEDIUM: The scan fixture and tests assume `.obsidian/workspace.json` exclusion, but since the walk only considers `.md` files, that path is not a meaningful proof of directory exclusion. The better exclusion proof is an excluded markdown file under `.obsidian/`.
- MEDIUM: `unknown_reason()` returns a generic "What kind of page should this become?" which is weaker than D-18's desired open-question framing that reflects observed ambiguity. The plan text asks for concise observed-signals prose; the stub implementation does not actually do that.
- LOW: The help contract includes the D-02 decision boundary epigraph, but that decision boundary is really bootstrap-specific. It is not wrong, but it could confuse users if shown for `scan`.

Suggestions
- Either narrow the requirement from "gitignore-grammar" to "gitignore-like subset" in docs/tests, or strengthen implementation expectations to cover actual gitignore semantics the plan claims.
- Adjust the fixture to include an excluded markdown file under `.obsidian/` and maybe one under `attachments/` to prove directory filtering on markdown paths, not just non-markdown paths.
- If inbound links are not practical in Phase 10 `scan`, say that explicitly and revise the classifier rules to "outbound density only in scan; inbound reused in Phase 11 when full-vault graph context is available." Right now the plan claims more than it implements.
- Strengthen `unknown_reason()` to embed observed signals, e.g. "no valid type frontmatter; filename matches no convention; no signature headings; low link density."
- Add a performance note: classification should be O(total files + total markdown size), and scan should avoid repeated full-tree passes.

Risk Assessment: MEDIUM. The CLI/test shape is solid, but the classifier and ignore parser currently overpromise relative to the implementation sketch.

---

**10-03-PLAN**
Summary: This is the critical plan, and it is thoughtfully designed around safety, idempotency, and observability. It covers most roadmap success criteria directly. The biggest risks are implementation complexity inside one plan, a few places where the plan conflates spec with fixture assumptions, and one important dependency edge with Plan 04 around `bootstrap_stage`/`bootstrap_date` semantics.

Strengths
- Strong safety posture: dry-run default, `--apply` opt-in, explicit failure semantics, append-only manifests, and no auto-rollback.
- D-02 typed-merge policy is encoded clearly and tested explicitly via the typed-merge test.
- Good separation into helper module `bin/lib/brownfield_yaml.py`, which should keep the shell wrapper manageable.
- Excellent coverage of BRWN-03/04/05/06/07/21 with direct tests rather than inferred confidence.
- Correctly preserves the dependency boundary: `ruamel.yaml` is bootstrap-only.
- The W-2 isolation rule for tests is a strong improvement; it prevents accidental traversal of committed `expected/` fixtures.

Concerns
- HIGH: `read_fm_body()` proposes a regex-based frontmatter splitter `^---\n(.*?)^---\n?`, which is brittle for YAML containing literal block scalars or content that itself includes `---` on a line. Given this is the highest-risk path, frontmatter splitting should be more defensive than a simple regex.
- HIGH: The plan says "preserve comments and key order via ruamel round-trip," but `merge_sentinels(existing_fm, sentinel_set, ...)` returns a plain dict in the interface sketch. If the implementation actually round-trips through plain dicts rather than ruamel's `CommentedMap`, comment placement and key ordering may drift.
- HIGH: D-15 source-summary hashing is underspecified operationally. The plan says to update `content_hash` on existing `wiki/sources/*.md` summaries by reading `path:` frontmatter, but bootstrap is also supposed to be mechanical-only and scoped to imported vault pages. This can cause bootstrap to mutate source-summary pages unrelated to the scanned vault root unless root scoping is defined very carefully.
- MEDIUM: The CRLF fixture expectation bakes in LF normalization, but the roadmap/success criteria talk about "byte-exact reproducible," not specifically "normalize line endings." That is probably acceptable, but it is a policy decision that should be surfaced earlier because it affects user-visible diffs.
- MEDIUM: The skip-artifact tests are only structural for parse-error content, not byte-exact, which slightly weakens the BRWN-21 proof for unparseable fixtures.
- MEDIUM: Plan 03 and Plan 04 are marked as same-wave parallel plans, but they are not fully disjoint semantically. Plan 04's lint and ingest changes depend on the exact sentinel fields written here, and its tests assume those fields exist with specific names and meanings. The file write sets are disjoint, but behavioral coupling is real.
- LOW: The `bootstrap --help` behavior is not fully described. Since `bin/brownfield.sh --help` already exists, subcommand-specific help should be explicit to avoid parser ambiguity.

Suggestions
- Replace the frontmatter regex split with a line-oriented parser: detect opening `---` only at file start, scan line by line until the next standalone `---`, treat everything after that as body verbatim.
- Require `brownfield_yaml.py` to use ruamel-native structures throughout merge/write, not plain dicts. Make preservation of `CommentedMap` part of the interface contract.
- Clarify root scoping for D-15: either bootstrap only mutates source summaries under `<root>/wiki/sources`, or explicitly state bootstrap is repo-root oriented and must not be pointed at arbitrary subtrees if hashing is desired.
- Decide and document EOL policy in the plan frontmatter, not only in the summary handoff. This is a contract, not an implementation footnote.
- Add one test for write-failure behavior if feasible, or at least a narrow unit-level test around APPLIED manifest append semantics after partial progress.
- Mark Plan 03 and Plan 04 as "parallel in files, sequential in semantic contract." That helps reviewers and executors avoid assuming independence.

Risk Assessment: HIGH. This plan is achievable, but it carries most of the phase's correctness risk and still has a few specification holes around frontmatter parsing, comment-preserving round-trip behavior, and root scoping.

---

**10-04-PLAN**
Summary: This plan is justified despite its breadth. It is not gratuitous scope creep; it is a necessary atomic bundle because the schema edit fans out into CLAUDE sync, template parity, canonical fixture regeneration, and then operational consumers in ingest and lint. The main risk is not size but coupling: a mistake in one sub-area could burn time across multiple test suites.

Strengths
- Correctly recognizes the atomicity constraint around `AGENTS.md` -> `CLAUDE.md` -> `schema/AGENTS.template.md` -> `canonical-AGENTS.md`.
- Good use of existing enforcement surfaces from prior phases; this lowers review risk.
- The BRWN-10 ingest-strip test is unusually strong because it locks the D-21 stderr string as a single line, not just substring presence.
- The lint plan properly scopes the downgrade inside `--ci`, which is the right interpretation of the Phase 9 severity-remap pattern.
- Tests are targeted and non-overlapping: schema parity, ingest strip behavior, lint category/help, stale age behavior, and CI downgrade semantics.

Concerns
- HIGH: The `bootstrap_stage` AGENTS row text says values are `raw | bootstrapped | verified`, but Plan 03 only ever writes `bootstrapped`, and nothing in Phase 10 defines how `raw` is represented on disk. That is acceptable as a forward-looking enum, but the docs/tests should not imply current write-path support for `raw`.
- MEDIUM: The BRWN-08 downgrade allowlist is implemented as category-based (`yaml`, `provenance`, `orphan`), but the roadmap success criterion describes finding classes like "unknown type," "empty knowledge_domain," "missing sources," and "epistemic_status: tentative." Those are not perfectly isomorphic to the category names. There is some risk that the chosen allowlist is either too broad or too narrow.
- MEDIUM: The plan says text-mode lint is unchanged, which is sensible, but that means roadmap success criterion 4 should be interpreted as CI-gate behavior, not general lint behavior. That mismatch should be flagged more prominently as a requirements wording issue, not just a doc note.
- MEDIUM: The ingest strip implementation uses a frontmatter heuristic bounded by the first detected frontmatter block. That is reasonable, but the acceptance criterion "line number between 310 and 320" is brittle and should not be used as a lasting quality gate.
- LOW: Task 3 adds an info summary finding with empty path for brownfield counts. That is fine, but if JSON consumers assume every finding has a real path, it could cause minor downstream handling drift.

Suggestions
- In AGENTS.md row wording, explicitly say `raw` is reserved for future import flows and may be absent in Phase 10-generated pages. That would align docs with implementation.
- Add one test that plain `bin/lint.sh` on a bootstrapped page still emits the original severity. The plan mentions this behavior, but I only see CI and absence cases explicitly called out.
- Convert the brittle line-number acceptance criterion in ingest to a pattern-based ordering check, e.g. "strip block appears after the copy block and before hash compute" via awk or grep context, without fixed numbers.
- Flag the BRWN-08 wording mismatch as a real pre-merge note in the summary, not just a handoff. It affects whether the roadmap's success criterion is actually satisfied as written.
- Consider whether the `brownfield` summary info finding should use a synthetic path like `wiki/` or empty path; document that choice for JSON consumers.

Risk Assessment: MEDIUM. The scope is justified, but semantic coupling is high and the downgrade behavior may still need a wording amendment upstream.

---

**10-05-PLAN**
Summary: This is a good closure plan. It turns the shipped behavior into an operator-facing runbook and provides traceable verification evidence. The docs are thorough and reflect most of the important phase decisions. The main risk is maintainability: the docs are very explicit and therefore easy to drift from behavior unless kept tightly aligned.

Strengths
- Strong doc structure: prerequisites, scan, bootstrap, rollback, boundary, lint/ingest interaction, and deferred stubs.
- Correctly carries forward the key decisions verbatim: D-02 decision boundary, typed-merge class taxonomy, D-06 git-based rollback, W-4 four-section report structure, I-1 `--ci`-only downgrade scope.
- `10-VERIFICATION.md` gives DEBT-03-compatible traceability rather than a hand-wavy closeout.
- The docs tests are appropriately documentation-focused rather than duplicating prior behavioral tests.
- Good call on the X/X regex for the phase test aggregator; that is more robust than pinning an exact count.

Concerns
- MEDIUM: The target of ">=150 lines" is a coarse proxy for completeness. It is fine as a smoke test, but it can hide drift if sections are present but behavior details are stale.
- MEDIUM: The rollback section uses `git reset --hard` and `rm -rf .brownfield/`. That is correct in a committed-clean working tree, but the docs should probably reiterate that users should commit or stash before `bootstrap --apply`, otherwise unrelated local changes are lost.
- LOW: `10-VERIFICATION.md` cites wildcard patterns like `test_brownfield_bootstrap_apply_*.sh` as evidence. That is readable, but if `requirements-sync.sh` or later tooling expects exact file references, explicit filenames are safer.
- LOW: The docs say `.brownfield/` is gitignored per `TMPL-04`; if that is ever changed or partial, the statement could drift. Not a plan flaw so much as a maintenance point.

Suggestions
- Add one sentence in rollback: "If you had uncommitted local changes before bootstrap, use `git stash` first or commit before applying; `git reset --hard` discards unrelated work."
- In `10-VERIFICATION.md`, prefer exact test filenames where practical, especially for BRWN-21. It improves auditability.
- Add a short "known limitations" subsection to brownfield docs: scan classification is heuristic, bootstrap does not infer provenance/privacy/page type, lint downgrade is CI-only.
- Consider one doc test that compares `bin/brownfield.sh --help` output against the documented flag set more mechanically; currently the plan only mentions this as a spot-check.

Risk Assessment: LOW to MEDIUM. The plan is a strong documentation/verification closeout. Most remaining risk is drift over time, not immediate execution failure.

---

**Cross-Plan Findings**
1. HIGH: 10-03 and 10-04 are not truly independent even if their write sets are disjoint. 10-04's lint/ingest semantics assume the exact sentinel fields and meanings produced by 10-03. They can be implemented in parallel by different people, but they should not be verified or merged independently without rebasing against the final 10-03 behavior.
2. HIGH: The biggest technical gap across the set is frontmatter parsing robustness in 10-03. The current splitter/merge sketch is weaker than the safety bar implied by BRWN-04/05/06 and roadmap success criteria 2-3.
3. MEDIUM: The `.brownfield-ignore` parser in 10-02 promises more than the implementation sketch likely delivers. Either the grammar promise should be reduced or the parser strengthened.
4. MEDIUM: The roadmap success criterion 4 and BRWN-08 wording need an explicit amendment or interpretation note. The plans implement a `--ci`-only downgrade, not a universal lint severity change.
5. MEDIUM: The fixture strategy in 10-01 is good, but skip-artifact expectations are not fully byte-frozen because parse error strings are still placeholder-sensitive.

**Overall Assessment**
The plan set is well thought through and, taken together, does achieve the five Phase 10 roadmap success criteria in substance. The plans are stronger on safety and testability than on parser simplicity. That is the right tradeoff for this phase. I would approve the set with revisions focused on 10-03 parser/round-trip guarantees, 10-02 ignore-parser scope, and a clearer statement that 10-03/10-04 are parallel in files but sequential in semantic contract.

**Overall Risk Assessment: MEDIUM-HIGH**
Justification: The architecture and traceability are strong, but brownfield bootstrap is the project's highest-risk mutation surface, and the current 10-03 implementation sketch still has real failure modes around frontmatter splitting, comment-preserving round-trip behavior, and source-summary scoping. The plans are close, but they would benefit from tightening those areas before execution.

---

## Consensus Summary

### Agreed Strengths
- **Wave structure and dependency ordering** — Both reviewers approve the 4-wave progression (Harness -> Scan -> Bootstrap+Wiring -> Docs) as logical and well-sequenced.
- **Safety posture** — Both highlight dry-run default, opt-in mutation, git-based recovery, and the mechanical-only boundary as strong design choices.
- **Byte-exact fixture testing (D-07)** — Both approve the dual golden contract and the test harness design in 10-01, though both note the skip-artifact parse-error placeholder weakens true byte-equality for unparseable fixtures.
- **D-02 Typed-merge policy** — Both recognize the three-class field taxonomy (A/B/C) as a robust corruption-prevention mechanism.
- **Schema alignment atomicity (10-04)** — Both approve the AGENTS.md -> CLAUDE.md -> template -> canonical fixture commit chain as necessary despite the file count.

### Agreed Concerns
- **Skip-artifact fixture stability** — Both flag that `{PARSE_ERROR}` placeholders in unparseable fixture expected outputs weaken the byte-exact claim (Gemini LOW, Codex MEDIUM).
- **Wave 3 coupling between 10-03 and 10-04** — Both flag that file-set disjointness does not equal semantic independence; 10-04's lint/ingest tests assume 10-03's sentinel shape (Gemini LOW, Codex HIGH cross-plan #1).
- **Orphan detection performance** — Gemini flags O(N*M) concern; Codex flags root-scoping concern for D-15 source-summary hashing. Related: bootstrap should not mutate pages outside the scanned vault root.

### Divergent Views
- **Overall risk assessment** — Gemini rates LOW ("plans are ready for execution"); Codex rates MEDIUM-HIGH ("specification holes remain around frontmatter parsing"). The divergence centers on 10-03's frontmatter splitter robustness and ruamel CommentedMap preservation — concerns Codex rates HIGH that Gemini does not raise.
- **Frontmatter regex splitter (10-03)** — Codex rates HIGH (brittle for literal block scalars containing `---`); Gemini does not flag this. This is the single highest-impact divergence: if the splitter breaks on real-world YAML, bootstrap silently corrupts pages.
- **Classifier inbound-link gap (10-02)** — Codex rates HIGH (D-16 signal 4 not actually implemented — no inbound link computation); Gemini does not mention it. A practical gap since inbound link density was specified as a classification signal.
- **`.brownfield-ignore` parser scope (10-02)** — Codex rates HIGH (fnmatch is weaker than promised gitignore semantics); Gemini does not flag this. Codex suggests either narrowing the promise or strengthening the implementation.
- **BRWN-08 wording amendment (10-04)** — Codex rates MEDIUM (roadmap success criterion 4 implies universal lint, plans implement CI-only); Gemini notes CI-only scope approvingly without flagging the wording gap.
