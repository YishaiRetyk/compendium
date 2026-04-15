---
phase: 4
reviewers: [codex, gemini]
reviewed_at: 2026-04-12
plans_reviewed: [04-01-PLAN.md, 04-02-PLAN.md, 04-03-PLAN.md, 04-04-PLAN.md, 04-05-PLAN.md]
---

# Cross-AI Plan Review — Phase 4

## Codex Review

### Plan 01: Compilation Status Tracking

**Summary**

This plan is directionally correct and probably necessary groundwork for delta compilation, but it looks too narrow to fully support `QURY-03` on its own. Adding the fields to `AGENTS.md`, the ingest workflow, templates, and three existing source pages establishes the schema, but it does not yet guarantee consistent lifecycle semantics, transition rules, or how downstream query logic will consume those fields deterministically.

**Strengths**

- Introduces the minimum metadata needed for query-scoped delta compilation.
- Anchors the change in the schema first, which is the right authority boundary for this repo.
- Includes backfill work, which reduces split-brain behavior between old and new source pages.
- Keeps scope constrained to schema and representative existing data.

**Concerns**

- `HIGH`: The plan defines fields but not their state transition rules. Without explicit semantics for `pending -> partial -> compiled -> stale`, later query behavior may drift.
- `HIGH`: Backfilling only three existing source pages may leave the wiki in a mixed state where query logic behaves inconsistently depending on source age.
- `MEDIUM`: `compiled_against_hash` likely depends on what hash is being compared against. If it is ambiguous whether this is source `content_hash`, page set hash, or query target hash, delta compilation will be unreliable.
- `MEDIUM`: `compiled_targets` needs a canonical format and allowed values, or the same target may be represented inconsistently.
- `LOW`: If templates are updated but validators are not, malformed source pages may silently enter the repo.

**Suggestions**

- Define explicit transition rules and invariants in `AGENTS.md`.
- Specify exact field types and examples for `compiled_against_hash` and `compiled_targets`.
- Add a repo-wide audit step or script to identify all source pages missing the new fields, even if full backfill is deferred.
- Decide whether unbackfilled legacy sources should default to `pending` or be treated as incompatible until updated.
- Add at least one negative test case in later validation for malformed or stale compilation metadata.

**Risk Assessment**

`MEDIUM` — Good foundation, but by itself it under-specifies behavior and could create ambiguous downstream logic if the field semantics are not nailed down now.

---

### Plan 02: CLI Search Helper

**Summary**

This is a good small plan with clear user value and appropriate implementation scope. The bash choice and dual-mode design fit the project constraints well. The main risk is not over-engineering but under-specifying output contracts, especially if query mode is intended to scaffold LLM prompts consistently across agents.

**Strengths**

- Matches the locked decisions and keeps the tool agent-agnostic.
- Bash is appropriate for portability and low operational overhead.
- Dual-mode search aligns with the repo's progressive disclosure model: index first, fulltext second.
- Testing all modes is the right minimum bar for a CLI helper.

**Concerns**

- `MEDIUM`: The plan does not specify deterministic output format. If different modes emit inconsistent text, downstream LLM workflows will be brittle.
- `MEDIUM`: Fulltext grep behavior needs edge-case handling for no matches, special characters, case sensitivity, and binary files.
- `MEDIUM`: Query mode "scaffolds LLM prompts" can drift into prompt-generation logic that becomes harder to keep stable than simple search output.
- `LOW`: Performance may degrade as the wiki grows if index lookup falls back to broad grep too often.
- `LOW`: If `wiki/index.md` is stale or malformed, index-based mode needs a fallback or explicit failure mode.

**Suggestions**

- Define exact CLI contract per mode: inputs, exit codes, and output shape.
- Make index mode fail fast and clearly when `wiki/index.md` is missing or unparsable.
- Use fixed, grep-friendly section delimiters so other agents can reliably consume output.
- Decide upfront on case sensitivity and whether search is title-only, title-plus-summary, or broader.
- Add tests for empty query, no matches, regex-like input, and missing index file.

**Risk Assessment**

`LOW` — The scope is controlled and achievable. Most risk comes from missing output-contract details, not architectural problems.

---

### Plan 03: Operations Validator

**Summary**

This plan is valuable and necessary, but it appears underscoped relative to the role the validator plays in the phase goal. If `bin/validate-op.sh` is the mechanical enforcement layer for structured mutations, it needs very crisp boundaries around what it can validate deterministically versus what remains policy-level guidance. The current five checks are a good start but may not be enough to prevent invalid operations from being logged and applied.

**Strengths**

- Correctly separates mechanical enforcement from higher-level policy in `AGENTS.md`.
- Batch validation is the right design choice for operation pipelines.
- The chosen checks target high-value failure modes: structural validity, provenance, privacy, merge correctness.
- Pass/fail test cases suggest healthy skepticism about tool behavior.

**Concerns**

- `HIGH`: The validator only checks targets exist, but operation semantics also depend on operation type. `ARCHIVE`, `SUPERSEDE`, `MERGE`, and `UPDATE` likely need different required fields and constraints.
- `HIGH`: "YAML parses" is too weak if frontmatter must also satisfy required schema fields and enums.
- `HIGH`: "Privacy respected" needs exact rules. Inheritance and cross-page propagation can be subtle, especially with mixed `local_only` and `cloud_safe` inputs.
- `MEDIUM`: Provenance resolution may be expensive or noisy unless the validator defines whether it checks source ID existence only or locator syntax too.
- `MEDIUM`: Distinct MERGE sources is necessary but insufficient; merge targets may also need checks for duplicate IDs, status compatibility, and supersession integrity.
- `LOW`: If validator output is not machine-readable, executor integration will be awkward.

**Suggestions**

- Add per-operation validation rules, not just global checks.
- Validate frontmatter schema compliance, not only YAML parseability.
- Emit structured results with explicit error codes for executor use.
- Define whether privacy checks operate on source inputs, target page, or both.
- Add checks for status transitions and supersession consistency where applicable.

**Risk Assessment**

`MEDIUM-HIGH` — The plan is important, but if implemented exactly as stated it may create false confidence while still allowing semantically invalid mutations through.

---

### Plan 04: AGENTS.md Query Workflow + Executor + Log Format

**Summary**

This is the most consequential plan and the one with the highest risk. It owns most of the actual phase behavior, but it is currently compressed into too few tasks for the amount of policy it needs to encode. Rewriting query workflow, structured operations semantics, validator integration, write-back rules, delta compilation behavior, privacy inheritance, and log format in one pass risks producing a coherent document that is still incomplete at the behavioral edges.

**Strengths**

- Places the core logic in the authoritative spec, which is exactly right for this project.
- Correctly ties together query behavior, structured mutations, validator references, and logging.
- Includes the locked decisions that matter most for avoiding ambiguity.
- Keeps implementation aligned with deterministic execution rather than ad hoc agent behavior.

**Concerns**

- `HIGH`: This plan appears to define the executor behavior only through AGENTS edits. If there is no explicit executable operation schema, different agents may interpret `UPDATE`, `MERGE`, `SUPERSEDE`, and `ARCHIVE` differently.
- `HIGH`: Mandatory write-back on "novel/durable synthesis" is subjective unless AGENTS defines decision criteria with examples and exclusion cases.
- `HIGH`: Delta compilation rules depend on Plan 01 fields, but the plan only depends on Plan 01. In practice it also depends on search/discovery behavior and validator/log semantics being stable.
- `HIGH`: Privacy inheritance is easy to get wrong. If a query synthesizes from both `local_only` and `cloud_safe` pages, the plan needs an explicit downgrade rule and mutation constraint.
- `MEDIUM`: Log format may be parseable but still insufficient if it does not include operation IDs, targets, validator outcome, and rationale linkage.
- `MEDIUM`: Updating section 9 and 12 alongside section 11.2 in one task bundle increases review difficulty and raises the chance of internal inconsistencies.
- `LOW`: This may become the dumping ground for unresolved design decisions from earlier waves.

**Suggestions**

- Split this into two plans or at least two reviewable substeps: query workflow semantics, then structured operations/logging semantics.
- Define an explicit operation payload schema with required fields per verb.
- Add concrete examples for mandatory write-back and explicit examples for when not to write back.
- Define privacy inheritance as a simple deterministic rule, ideally "most restrictive input wins."
- Specify executor preconditions and postconditions, including whether validation occurs before logging, after logging, or both.
- Require at least one end-to-end worked example in `AGENTS.md` showing query -> delta compile -> operation batch -> log entry.

**Risk Assessment**

`HIGH` — This plan carries most of the phase goal and is currently too compressed for the amount of behavior it must standardize. It can succeed, but only with sharper decomposition and more explicit schemas.

---

### Plan 05: End-to-End Validation

**Summary**

This is the right final step, but the current plan is too weak to validate the whole phase with confidence. A single real query workflow plus a human checkpoint is useful as a smoke test, not as sufficient validation for `QURY-01` and the structured operations stack.

**Strengths**

- Correctly waits until all prior pieces are available.
- Uses a real workflow rather than isolated unit checks.
- Includes a human review checkpoint.

**Concerns**

- `HIGH`: One "real query workflow" is not enough coverage for this phase.
- `HIGH`: There is no explicit requirement to test mandatory write-back behavior.
- `MEDIUM`: Human checkpoint without a checklist can devolve into subjective review.
- `MEDIUM`: If the chosen query is too simple, it may not exercise all pieces together.
- `LOW`: No rollback or cleanup plan if the validation run creates bad wiki state.

**Suggestions**

- Expand validation to a small matrix: standard query, delta compilation trigger, write-back trigger, validator rejection, privacy-sensitive case.
- Define a human review checklist tied to phase success criteria.
- Use disposable artifacts to avoid polluting the wiki if the run fails.
- Verify log entries and page mutations as part of the acceptance test.

**Risk Assessment**

`MEDIUM` — Necessary integration step, but currently more smoke test than convincing phase validation.

---

### Cross-Plan Assessment

**Overall Risk: MEDIUM-HIGH**

The phase is achievable with the current structure, but success depends on tightening semantic contracts in Plans 01, 03, and especially 04. Without that, the project may ship something that looks complete in docs but still behaves inconsistently across agents.

---

## Gemini Review

### Summary

The Phase 4 plans are well-structured, prioritizing the foundational metadata and CLI tooling (Wave 1) before codifying the complex agent workflows (Wave 2). The strategy of using "Delta Compilation" via status fields and hashes is a sophisticated approach to solving the "RAG-recomputation" problem, shifting the system toward a true incremental compiler model. The split between mechanical validation (`bin/validate-op.sh`) and policy enforcement (`AGENTS.md`) is a strong architectural choice that balances automation with agent flexibility.

### Strengths

- **Incremental Synthesis Architecture**: Using `compiled_against_hash` and `compilation_status` (Plan 01) transforms the wiki from a static collection of notes into a state machine. This is critical for scalability.
- **Agent-Agnostic Tooling**: Implementing search and validation in Bash (Plans 02 & 03) ensures that any LLM agent (Claude, Gemini, GPT) can interact with the system using standard CLI primitives.
- **Mechanical Enforcement**: The 5 mechanical checks in `bin/validate-op.sh` provide a "linter" for wiki mutations, preventing the most common LLM errors.
- **Write-back Logic**: The decision to use "Page Ownership" (D-01) rather than "Query Origin" prevents the wiki from becoming cluttered with redundant "Answer to Question X" pages.

### Concerns

- **Hash Definition (Plan 01) [LOW]**: The plans mention `compiled_against_hash` but do not specify the hashing algorithm or scope. If the hash includes metadata that changes frequently, it will trigger unnecessary re-compilations.
- **Search "Scaffolding" Complexity (Plan 02) [MEDIUM]**: Plan 02 mentions that `bin/search.sh` will "scaffold LLM prompts." This risks over-engineering the bash script. Scripts should provide data; the instruction to use that data belongs in `AGENTS.md`.
- **Privacy Validation (Plan 03) [MEDIUM]**: Validating "Privacy Respected" via a Bash script is non-trivial. A clear tagging standard must be established for this to be reliable.
- **Workflow Fatigue (Plan 04) [MEDIUM]**: The 9-step query workflow is robust but complex. There is a risk that agents with smaller context windows or lower instruction-following capabilities will "shortcut" the process.

### Suggestions

- **Standardize the Hash**: Explicitly use `git hash-object <file>` for `compiled_against_hash`. Since the project is already a git repo, this provides a deterministic, built-in way to track content changes.
- **Simplify Search Scaffolding**: Shift the "scaffolding" responsibility. `bin/search.sh` should output structured data that the agent can then ingest.
- **Atomic Operations**: Ensure `bin/validate-op.sh` can be run in a `--dry-run` mode for self-correction.
- **Delta Trigger Definition**: Clearly define that `compilation_status: stale` should be automatically applied by `ingest.sh` when a source is updated.

### Risk Assessment

**Overall Risk: LOW**

The dependency graph is logical, and the use of "Wave 1" to build the safety rails before enabling high-power mutations significantly mitigates the risk of wiki corruption. The primary remaining risk is "Agent Drift" — where different agents interpret the vocabulary with varying rigor. However, the combination of `bin/validate-op.sh` and the deterministic log format provides sufficient auditability.

---

## Consensus Summary

### Agreed Strengths
- **Schema-first approach is correct**: Both reviewers agree that anchoring changes in AGENTS.md as the authoritative spec is the right design for this repo
- **Agent-agnostic CLI tooling**: Bash scripts for search and validation are the right choice for portability and zero-dependency operation
- **Wave sequencing is sound**: Building metadata + tools (Wave 1) before workflow spec (Wave 2) before validation (Wave 3) is logical and low-conflict
- **Write-back by page ownership**: D-01's "type by semantic role, not origin" prevents wiki clutter — both reviewers noted this as strong design

### Agreed Concerns
- **Privacy inheritance under-specified** (both HIGH/MEDIUM): Both reviewers flag that privacy validation and inheritance rules (especially when synthesizing from mixed `local_only` + `cloud_safe` sources) need explicit deterministic rules, not implicit agent judgment
- **Plan 04 carries too much semantic load** (Codex HIGH, Gemini MEDIUM): Both note the query workflow rewrite is the most consequential plan and risks being under-decomposed — Codex suggests splitting into substeps, Gemini flags "workflow fatigue" for agents
- **Validator needs sharper scope** (both MEDIUM+): Both agree the 5 mechanical checks are a good start but need tighter definition — Codex wants per-operation rules and schema compliance beyond YAML parsing, Gemini wants `--dry-run` mode and clearer privacy checking
- **Search output contract needs definition** (both MEDIUM): Both flag that `bin/search.sh` output format should be explicitly specified for downstream consumption

### Divergent Views
- **Overall risk assessment**: Codex rates MEDIUM-HIGH, Gemini rates LOW. Codex focuses on semantic completeness and edge-case coverage; Gemini takes a more pragmatic view that the safety rails are sufficient
- **Hash specification**: Gemini suggests `git hash-object` specifically; Codex flags it as ambiguous but doesn't propose a specific solution. Note: CONTEXT.md D-06 already specifies SHA-256 of source content, and the existing `content_hash` field uses this — `compiled_against_hash` copies from `content_hash`
- **Plan 05 validation depth**: Codex rates this HIGH concern (too narrow), wants a validation matrix; Gemini doesn't raise validation coverage as a concern
- **Plan decomposition**: Codex strongly suggests splitting Plan 04; Gemini is satisfied with the current structure but flags complexity risk
