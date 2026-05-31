---
phase: 13
reviewers: [codex]
reviewed_at: 2026-05-31T19:46:53Z
plans_reviewed: [13-01-PLAN.md, 13-02-PLAN.md, 13-03-PLAN.md, 13-04-PLAN.md, 13-05-PLAN.md]
---

# Cross-AI Plan Review — Phase 13

## Codex Review

## Summary

The plan set is strong overall: it decomposes Phase 13 cleanly into harness, deterministic selection/resolution, privacy/verifier boundary, documentation, and verification closure. The best parts are the explicit fail-closed privacy test, the raw-source-only resolver requirement, and the review-only/no-autofix guardrails. The main risks are around ambiguous verifier locality, locator edge cases, and the complexity of copying code out of a monolithic `lint.sh` heredoc without creating silent drift.

## Strengths

- Clear wave ordering: harness first, deterministic core and docs in parallel, privacy/verdict after core, verification last.
- Good threat modeling around the actual high-risk boundary: `local_only` passage egress to a verifier.
- Strong D-11 protection against circular verification by requiring raw `path:` resolution, not source-summary extracted claims.
- Good use of fake and recording verifier helpers to make an LLM-shaped workflow testable.
- Review-only behavior is consistently preserved: no auto rewrite, no CI gate, no error severity.
- The page-marker convention is pragmatic and dependency-free.
- `requirements-sync` closure in Plan 05 gives good traceability discipline.

## Concerns

- **HIGH: Verifier locality is underspecified.**  
  Plan 03 says local_only claims are admitted when `--allow-local` is set “OR a local `--verifier` is configured,” but there is no explicit way to classify a verifier as local vs cloud. Treating any `--verifier` as local would break FAITH-04. Default should be: all `--verifier` commands are treated as cloud/egress unless `--allow-local` or an explicit `--verifier-local` flag is supplied.

- **HIGH: `--emit-worklist` can become an accidental egress surface.**  
  The plan says no verifier means the worklist is output for the operating agent. If `local_only` passages are included in stdout by default, that can still violate the spirit of fail-closed privacy in cloud-agent contexts. The same privacy partition should apply before worklist emission.

- **MEDIUM: `pending-verifier` is outside the declared verdict enum.**  
  Plan 02 emits `pending-verifier`, while the declared shape lists `supports|weak|contradicts|insufficient|insufficient-locator|skipped-privacy|skipped-nontext`. This is acceptable as an internal transitional state, but it can break JSON schema tests or downstream assumptions. Prefer `insufficient` with rationale “verifier not run” or add `pending-verifier` explicitly as an operational verdict.

- **MEDIUM: Locator resolution edge cases need sharper acceptance tests.**  
  `#sec:` matching needs slug/case/space behavior defined. `#para<n>` needs to say whether frontmatter counts, whether headings are paragraphs, and how blank-line parsing handles lists/code blocks. `#t` “best-effort” is vague and likely under-tested.

- **MEDIUM: Copying lint primitives verbatim is brittle.**  
  Since `lint.sh` is a monolithic heredoc, copying selected functions creates two sources of truth. That may be acceptable short term, but the plan should include a follow-up or explicit comment block listing copied symbol origins and expected drift risk.

- **MEDIUM: `--verifier <cmd>` parsing via shlex needs a precise rule.**  
  The plan says `subprocess.run([verifier_cmd_via_shlex_or_list], ...)`. If implemented incorrectly, it may either fail for commands with args or invoke a shell. Require `shlex.split(verifier_cmd)` with `shell=False`, and never pass claim/passage in argv.

- **LOW: Plan 01 “RED-ready” language is slightly inconsistent.**  
  The harness canary passes and the aggregator exits 0, so it is not actually RED. That is fine operationally, but wording should avoid implying the test suite fails before implementation.

- **LOW: Plan 04 depends on schema sections not shown in the supplied AGENTS excerpt.**  
  It references §13 privacy routing and §11 workflows. If those sections exist in-repo, fine; if not, Plan 04/03 need to add or reconcile them explicitly.

- **LOW: Plan 05 may record generated maintenance artifacts as required artifacts before they exist.**  
  `audit-report.md` and `audit-state.md` are generated on run. Verification should ensure the relevant command has been run in the final repo state before claiming they exist.

## Suggestions

- Add an explicit verifier trust mode:
  - Default: `--verifier` is treated as cloud/egress.
  - `--allow-local` is the only way local_only passages enter verifier stdin.
  - Optional clearer flag: `--local-verifier <cmd>` as a synonym for `--verifier <cmd> --allow-local`.

- Apply the privacy partition before all outputs containing passages, including `--emit-worklist`, not only subprocess dispatch.

- Replace Plan 02’s `pending-verifier` with a declared operational verdict, or explicitly extend the verdict enum and tests to include it.

- Define section matching precisely:
  - exact heading text after trimming leading `#` and whitespace;
  - case-sensitive or case-insensitive;
  - whether punctuation/slugs normalize.

- Add locator tests for:
  - multiple `[prov:]` markers on one line;
  - malformed locators;
  - source ID missing from registry;
  - `path:` absolute path and `../` traversal;
  - page range missing upper marker;
  - `#sec:` no matching heading;
  - paragraphs with code blocks/lists.

- In Plan 03, require `subprocess.run(shlex.split(verifier_cmd), shell=False, input=payload, ...)` and test a verifier command with an argument.

- Add a small “copied from lint” manifest comment in `audit-claims.sh` listing copied functions/constants and source lint version. That makes future drift visible.

- Consider one end-to-end test that runs:
  `select -> resolve -> privacy partition -> fake verifier -> JSON/report/state`
  with mixed cloud_safe/local_only claims in a single fixture.

## Risk Assessment

**Overall risk: MEDIUM.**

The architecture is sound and the plans mostly satisfy FAITH-01 through FAITH-04 and SC-1 through SC-6. The highest-risk item is not implementation complexity but privacy semantics: without an explicit verifier locality model, a future implementer could accidentally treat arbitrary `--verifier` commands as safe for `local_only` passages. The second major risk is locator ambiguity, especially for `#sec`, `#para`, and transcript timestamps. Both are fixable with tighter contract language and a few additional tests.

---

## Consensus Summary

Single reviewer (Codex) this cycle. Overall risk assessed **MEDIUM**: the architecture is sound and the five-plan set cleanly decomposes Phase 13 (harness → deterministic core + docs in parallel → privacy/verdict boundary → verification closure) and broadly satisfies FAITH-01..04 / SC-1..6. The two HIGH concerns both center on the privacy boundary (verifier locality classification and worklist-emission egress); both are addressable with tighter contract language plus a few tests, not architectural rework.

### Agreed Strengths
- Clean wave ordering with the harness landing first so every downstream plan has tests to verify against.
- Fail-closed privacy partition is the right load-bearing decision, proven by a recording-verifier negative test (enforcement, not a documented promise).
- D-11 circular-verification protection (resolve against the raw `path:` file, never the source-summary `## Extracted Claims`).
- Review-only guardrails held consistently: no auto-rewrite, no CI gate, no `error` severity.
- `requirements-sync` closure in Plan 05 gives mechanical traceability.

### Agreed Concerns (highest priority)
- **HIGH — Verifier locality underspecified (Plan 03):** "a local `--verifier` is configured" has no mechanism to classify a verifier as local vs cloud. Treating any `--verifier` as local would break FAITH-04. Recommended: default ALL `--verifier` commands to cloud/egress; admit `local_only` passages only via explicit `--allow-local` (or a `--local-verifier` synonym).
- **HIGH — `--emit-worklist` is an accidental egress surface (Plan 02/03):** if `local_only` passages appear in worklist stdout by default, that violates fail-closed privacy in cloud-agent contexts. The privacy partition must apply BEFORE worklist emission, not only before subprocess dispatch.
- **MEDIUM:** `pending-verifier` stub verdict is outside the declared verdict enum (Plan 02) — may break JSON schema tests; declare it as an operational verdict or use `insufficient` with rationale.
- **MEDIUM:** Locator resolution edge cases need sharper acceptance tests (`#sec:` slug/case/space behavior; `#para` frontmatter/heading/list/code-block handling; `#t` "best-effort" is vague).
- **MEDIUM:** Verbatim copy of lint primitives creates two sources of truth — add a "copied from lint" manifest comment listing copied symbols + lint version to make drift visible.
- **MEDIUM:** `--verifier` parsing must be pinned to `shlex.split(cmd)` with `shell=False`, payload via stdin only.

### Divergent Views
None — single reviewer this cycle.
