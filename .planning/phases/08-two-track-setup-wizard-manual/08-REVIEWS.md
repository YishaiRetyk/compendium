---
phase: 8
reviewers: [gemini, codex]
reviewed_at: 2026-04-16
plans_reviewed:
  - 08-01-test-harness-and-fixtures-PLAN.md
  - 08-02-init-wizard-core-PLAN.md
  - 08-03-wizard-side-effects-PLAN.md
  - 08-04-manual-track-and-docs-PLAN.md
  - 08-05-ci-byte-equality-PLAN.md
---

# Cross-AI Plan Review — Phase 8

## Gemini Review

This is a comprehensive review of the Phase 8 implementation plans for the LLM Wiki Compiler.

### Summary
Phase 8 establishes the "Two-Track Setup" (Wizard + Manual) to ensure a consistent, reproducible onboarding experience. The plans are exceptionally well-sequenced, starting with the establishment of a "byte-frozen" target state (Wave 0), followed by the core logic (Wave 1), destructive side effects (Wave 2), and finally the CI enforcement gate (Wave 3). The use of Bash entrypoints with Python3 inline blocks for complex rendering and validation is consistent with established project idioms. The core "byte-equality" requirement is effectively mitigated against cross-platform drift through the use of `.gitattributes` and deterministic environment variables for testing.

### Strengths
- **Deterministic Testing:** The use of `WIZARD_GENERATED_AT` and `WIZARD_TEMPLATE_SHA` environment variables to freeze time and versioning during CI runs is a robust solution for testing otherwise non-deterministic artifacts like `.wizard-answers.yaml` and decision records.
- **Fail-Fast Pre-flight:** The wizard's pre-flight check (D-15) correctly identifies environment gaps (Bash < 4, missing Git/Python) before any file I/O or user interaction occurs.
- **Validation Symmetry:** Using a shared Python-based validator for both interactive (fail-fast) and file-based (collect-all) modes ensures identical logic across all invocation paths.
- **Safety Posture:** The implementation of atomic writes (tempfile + move) and the idempotency guard (refusing to overwrite an existing `.wizard-answers.yaml`) aligns with senior engineering standards for CLI tools.
- **Technical Rigor:** The resolution of Open Question 2 (using `cloud_safe` for the fixture to avoid the release-script's privacy-leak regex) shows deep awareness of cross-cutting system dependencies.

### Concerns
- **`wiki/index.md` Complexity (MEDIUM):** The logic for programmatically editing `wiki/index.md` to insert a `## Decisions` section is the most fragile part of the text manipulation. While the plan accounts for this (Plan 03, Task 1g), the Python block must be extremely robust to handle variations in the existing index file's EOF state or existing headers.
- **Git Config Dependency (LOW):** Plan 02 assumes `git config user.name` is the default. In CI environments where this may not be set, the code needs to handle a `null` or empty return from the `git` command gracefully to prevent the script from crashing or prompting for a name with a literal empty string as a default.
- **`sync-claude.sh` Pathing (LOW):** Plan 03 Task 1d mentions inlining logic if `target_root != "."`. Ensure the wizard has sufficient permissions and clear path resolution for the sibling `sync-claude.sh` script regardless of where the wizard is invoked from (using `dirname "$0"`).

### Suggestions
- **Index Guardrail:** In the Python logic for `wiki/index.md`, consider adding a specific assertion that the `## Decisions` entry was added exactly once to prevent duplicate headers if the script is run in an unusual environment.
- **Prerequisite Links:** In the pre-flight error message, ensure the link to `docs/reference/setup-prerequisites.md` is formatted as a clear path relative to the repo root to help users find the file immediately.
- **Manual Track Exit Step:** Explicitly remind users in `docs/manual-setup.md` that if they choose to hand-edit, they *must* run `bin/sync-claude.sh` manually to maintain the `CLAUDE.md` mirror, as this is a common point of drift.

### Risk Assessment: LOW
The overall risk is low due to the "Test-First" approach (committing the canonical fixture before the code) and the high degree of determinism built into the validation suite. The plans strictly adhere to the "zero new runtime deps" constraint and leverage existing, proven project patterns. The enforcement of byte-equality via CI is a top-tier mitigation against the manual-track and wizard-track drift issues identified in research.

**Approval:** All five plans (08-01 through 08-05) are approved for execution. Proceed with Wave 0.

---

## Codex Review

### 08-01 — Test Harness & Fixtures

**Summary.** Strong Wave 0: establishes byte-equality contract early, reuses Phase 7 harness, pins LF via `.gitattributes`.

**Concerns:**
- **MEDIUM:** Fixture uses `cloud_safe` but wizard default is `local_only` — defensible but easy to mishandle across docs/tests/reviewers.
- **MEDIUM:** `canonical-AGENTS.md` is pre-rendered before the wizard exists. The fixture-generation method must match the wizard's later render routine exactly.
- **LOW:** Acceptance criteria that pin an exact `diff` line-pair count is brittle.

**Suggestions:** Add rule: whenever `schema/AGENTS.template.md` changes, regenerate the fixture via the same render routine. Document the `cloud_safe` choice next to the fixture. Relax structural diff check to semantic parity.

**Risk:** LOW-MEDIUM.

### 08-02 — Init Wizard Core

**Summary.** Ambitious, mostly well-structured; clean separation of deterministic render from side effects. Scope creep via `--render-to` and a temporary "stubbed real run" behavior is the main risk.

**Concerns:**
- **HIGH:** `--render-to <dir>` is not in phase success criteria — useful but scope expansion.
- **HIGH:** Temporary "real-run repo-root writes wired in Plan 03" stub means the wizard exists in a partially truthful state; users/CI could invoke it in apparently-successful ways that don't produce required outputs.
- **MEDIUM:** `--dry-run` specifies diffs against files (`.wizard-answers.yaml`, decision record, `wiki/index.md`) whose real generation logic lives in Plan 03 — risks duplicated render logic that later diverges.
- **MEDIUM:** PyYAML stdlib fallback is acceptable, but nested-YAML fallback parser is easy to get subtly wrong.
- **LOW:** WZRD-08 completion-summary coverage claimed before real write path exists.

**Suggestions:** Mark `--render-to` explicitly as CI/testing-only and non-user-facing. Avoid the partial stub — either return a clear non-zero "not yet wired" during development or move full write path into this plan. Keep one render function shared by all modes. Narrow the stdlib YAML fallback to the exact known schema.

**Risk:** MEDIUM-HIGH.

### 08-03 — Wizard Side Effects

**Summary.** Closes the end-to-end path. Strengths: determinism env vars, reuse of `sync-claude.sh`, atomic per-file writes. Main risks: transactional integrity across multiple writes; expanding `wiki/index.md` mutation into "initialization."

**Concerns:**
- **MEDIUM:** Per-file atomic writes ≠ atomic initialization. A failure after `AGENTS.md`/`.wizard-answers.yaml` but before decision record / `wiki/index.md` leaves a partially initialized repo.
- **MEDIUM:** Updating `wiki/index.md` during setup couples the wizard to wiki layout rules that may evolve.
- **MEDIUM:** `fetch-depth: 2` for template SHA lookup is partially redundant with env-var determinism — pick one authoritative source.
- **LOW:** `--render-to` copying `wiki/index.md` from repo-root when missing is hidden behavior tests may unknowingly depend on.

**Suggestions:** Add recovery semantics for partial initialization (staging dir → promote). Isolate the `wiki/index.md` update behind a narrow helper with idempotency checks. Prefer env-var → git-lookup → `<unresolved>` fallback chain; keep tests off the git-history path. Add a test that simulates failure after one write and verifies cleanup or clear recovery instructions.

**Risk:** MEDIUM.

### 08-04 — Manual Track & Docs

**Summary.** The weakest of the five. Very detailed (good for doc completeness) but some detail drifts into awkward/incorrect operational guidance, and the manual path as written does not cleanly produce the same end state without leaning on wizard-generated artifacts — weakening the core parity claim.

**Concerns:**
- **HIGH:** Doc tells users to hand-edit `schema/AGENTS.template.md` — that is the source template, not the personalized output. Risks users mutating the starter template instead of producing repo-root `AGENTS.md`.
- **HIGH:** Section 8 effectively says manual users generate the decision record by running the wizard or copying from research — undermines the claim that the manual track independently reaches the same end state.
- **MEDIUM:** Parity claim is stronger than the actual instructions support — decision record & index update lack the precision of the main substitutions.
- **MEDIUM:** Docs reference Phase 5 CI artifacts (`setup-parity.yml`, `test_canonical_byte_equality.sh`) before they exist (sequencing fragility).
- **LOW:** Privacy-tier explanation is overloaded with fixture-policy rationale most users don't need.

**Suggestions:** Rewrite so users copy/render from `schema/AGENTS.template.md` into a new `AGENTS.md`, not edit the template in place. Give the manual track a deterministic decision-record template inline in the doc if parity is required. Separate "canonical fixture example" guidance from "typical user setup." Narrow the parity claim unless instructions really reproduce all five artifacts exactly.

**Risk:** HIGH.

### 08-05 — CI Byte-Equality Gate

**Summary.** Right final gate; enforces the main anti-drift invariant and mirrors existing CI patterns. Main issues: internal test-count inconsistency and unnecessary duplication.

**Concerns:**
- **HIGH:** Test-count math inconsistent — if `test_canonical_byte_equality.sh` lands under `tests/phase-08/test_*.sh`, the aggregator should move from `17/17` to `18/18`, not stay at `17/17`.
- **MEDIUM:** Workflow runs the dedicated byte-equality test then runs the full Phase 08 aggregator, which likely re-runs the same test — noisy, confuses failure attribution.
- **MEDIUM:** `fetch-depth: 2` is not a reliable general fix for `git log -1 <path>` when the path's last commit is deeper. If env vars are authoritative, this mitigation is weakly justified.
- **LOW:** Required-check naming assumption (`setup-parity`) should be validated against GitHub's branch-protection surface.

**Suggestions:** Resolve the count mismatch explicitly. Decide whether the dedicated test belongs inside the aggregator (if yes, don't run it separately in the workflow). If env vars are always set in CI, drop the shallow-history rationale (or use `fetch-depth: 0` for correctness). Add a short failure message telling contributors exactly how to regenerate `canonical-AGENTS.md`.

**Risk:** MEDIUM.

### Overall Assessment

Good decomposition overall. Plans 01, 03, 05 structurally sound; Plan 02 separation sensible. Main weak spot: Plan 04 — manual-track docs do not yet convincingly achieve parity. Largest cross-plan concrete issues: manual-path ambiguity, Plan 02 temporary stub, Plan 05 test-count inconsistency.

**Cross-Plan Risks:**
- **HIGH:** Manual track does not yet clearly produce the same five-artifact end state without depending on wizard-generated output.
- **MEDIUM:** Plan 02 temporarily normalizes a partially implemented wizard interface — can hide end-to-end gaps.
- **MEDIUM:** Canonical fixture policy (`cloud_safe`) diverges from wizard default (`local_only`) — manageable but easy to mishandle.
- **MEDIUM:** Phase 05 test accounting inconsistent; correct before implementation begins.

**Recommendation:** Proceed, but revise 08-04 substantially and tighten 08-02/08-05 before execution. Phase is achievable, but those issues are material enough not to call the plan set "ready as-is."

---

## Consensus Summary

### Agreed Strengths
- **Deterministic testing harness** (`WIZARD_GENERATED_AT`, `WIZARD_TEMPLATE_SHA`) — both reviewers call this out as a top-tier mitigation.
- **Test-first sequencing** — committing the canonical fixture in Wave 0 before the code exists.
- **Atomic writes + reuse of `sync-claude.sh`** — correct safety posture for CLI tools.
- **Pre-flight & validator symmetry** — shared Python validator across interactive and file-based paths.
- **Adherence to project idioms** — zero new runtime deps, bash + python3 inline blocks per existing `bin/` precedent.

### Agreed Concerns (highest priority — raised by both reviewers)

1. **`cloud_safe` fixture vs `local_only` wizard default (MEDIUM — both).** Defensible (Open Q2) but easy to mishandle across docs/tests. Needs clear, prominent rationale adjacent to the fixture and consistent treatment across Plans 01 and 04.
2. **`wiki/index.md` programmatic edit is the fragile seam (MEDIUM — both).** Gemini flags EOF/header variations; Codex flags coupling to wiki layout rules. Both recommend isolating to a narrow helper with idempotency/duplicate-header guardrails.

### Divergent Views

- **Overall risk rating:** Gemini → **LOW**, Codex → **MEDIUM** (proceed-with-revisions). The gap is driven almost entirely by Codex's Plan 04 assessment — Gemini treats manual-track docs as operational polish, Codex treats them as the primary phase-goal risk.
- **Plan 04 severity:** Gemini only mentions manual-track as a reminder to run `sync-claude.sh`. Codex rates it **HIGH**: the manual instructions tell users to hand-edit `schema/AGENTS.template.md` (the source template, not the output), and Section 8 leans on wizard-generated artifacts for the decision record — undermining the parity claim that is the phase's core promise.
- **Plan 02 scope (`--render-to`, temporary stub):** Only Codex flags as HIGH. Worth investigating — scope creep + partial-implementation normalization is a real concern even if Gemini overlooked it.
- **Plan 05 test-count math (17/17 vs 18/18):** Only Codex flags. Deterministic mechanical check — worth a targeted fix regardless of other revisions.
- **Git-config / sync-claude path handling in CI (LOW):** Only Gemini flags. Easy to address in Plan 02.

### Suggested Follow-Up

Before executing, a focused `--reviews` replan should:
1. **Plan 04 (HIGH priority):** Rewrite the manual flow so users copy/render from `schema/AGENTS.template.md` into a *new* `AGENTS.md` (not edit-in-place), and inline a deterministic decision-record template rather than referring users to the wizard.
2. **Plan 02:** Clarify `--render-to` as CI/testing-only (non-user-facing). Eliminate the "stubbed real run" by either returning a clear non-zero during development or moving the full write path into Plan 02.
3. **Plan 05:** Resolve `17/17` → `18/18` aggregator math; drop duplicate invocation or exclude the dedicated test from the aggregator; drop `fetch-depth: 2` if env vars are authoritative.
4. **Plan 03:** Isolate `wiki/index.md` edit behind a narrow helper with idempotency & duplicate-header assertion; add a partial-failure recovery story (staging dir + promote, or a test that exercises mid-init failure).
5. **Plan 01:** Add the "regenerate fixture via wizard render routine whenever template changes" rule; relax any exact-line-count diff acceptance criteria to semantic parity.
