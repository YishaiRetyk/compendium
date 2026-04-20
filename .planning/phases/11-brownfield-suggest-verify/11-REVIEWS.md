---
phase: 11
reviewers: [gemini, codex]
reviewed_at: 2026-04-20T13:16:24Z
plans_reviewed:
  - 11-01-PLAN.md
  - 11-02-PLAN.md
  - 11-03-PLAN.md
  - 11-04-PLAN.md
  - 11-05-PLAN.md
---

# Cross-AI Plan Review — Phase 11: Brownfield Suggest + Verify

## Gemini Review

This review covers implementation plans **11-01 through 11-05** for the Brownfield Suggest + Verify phase.

### 1. Summary
The plan set is exceptionally robust, demonstrating high architectural maturity and rigorous adherence to the "mechanical tool" thesis of the LLM Wiki Compiler. By separating immutable script logic from ephemeral vault data through the **hybrid generation model** and isolating judgment work into a **review manifest**, the phase achieves a rare balance of AI-assisted productivity and deterministic safety. The testing strategy is exhaustive, leveraging pattern-twins from previous phases to ensure non-regression while locking the new "D-19 contract" via a Wave-0 RED suite. The resolution of the §11.5 numbering conflict (Option C) is a thoughtful fix for accumulated technical debt.

### 2. Strengths
* **Architectural Decoupling:** The "Logic in `schema/`, State in `.brownfield/`" split (D-08) is a superior design that ensures migration scripts remain versioned, auditable, and testable across different vaults without rendering brittle, vault-specific shell code.
* **Review-Manifest Pattern:** Using a YAML manifest (`decisions.yaml`) as a control signal for `01-page-typing` is the "secret sauce" of this phase. it allows for high-trust automation of the highest-friction judgment call (page typing) while keeping the actual mutation script deterministic.
* **Conservative Direct-Apply Heuristics:** The `02-provenance-bootstrap` logic is appropriately surgical, targeting only specific sections (TL;DR/Key Facts) and implementing 8 distinct skip classes to minimize noise pollution.
* **Idempotency Engineering:** The use of `op_hash` (D-10) and the `bootstrap_stage: verified` gate (D-14) provides a strong integrity ratchet. The decision to "check readiness, not history" (D-12) avoids the common pitfall of relying on mutable logs for execution policy.
* **Context Window Stewardship:** The plan explicitly uses small-batch/large-batch branching in `review-typing` to ensure that AI assistance is only invoked when the decision density exceeds human comfort, preventing unnecessary token consumption.

### 3. Concerns
* **Python Path Complexity in Scripts (Severity: LOW):** The migration scripts (01-04) use a fallback logic to find `bin/lib/` by walking upward. While portable, this may be brittle if a user moves the `.brownfield/` directory.
    * *Mitigation:* The plans already prioritize the `BROWNFIELD_LIB_DIR` env var; the fallback is a reasonable "last resort."
* **Gate 5 (Pending Clusters) Resolution Performance (Severity: LOW):** In `verify --promote`, the script reads both `candidates.yaml` and `decisions.yaml` to build the `pending_pages` set.
    * *Mitigation:* The plan correctly notes this happens ONCE at startup, keeping the per-page gate evaluation at O(1).
* **Regex False Positives in Privacy Review (Severity: MEDIUM):** Even with code-fence skipping, `04-privacy-review` may flag common patterns (e.g., product IDs matching phone groupings).
    * *Mitigation:* D-07 hard-locks this script to report-only/advisory status; the risk of silent frontmatter corruption is zero. The troubleshooting table in 11-05 correctly frames this as an expected behavior needing human review.

### 4. Suggestions
* **Strict Header Ordering:** In `bin/brownfield.sh suggest` (Plan 11-02), ensure the `# op_hash:` lines are injected *immediately* after the shebang. Some shell tools (like `head` and `tail` used in the plan) can accidentally swallow the shebang if the line indices are off-by-one. (The plan's `tail -n +2` correctly handles this, but careful implementation is required).
* **Colorized Handoff:** In the `review-typing` TTY mode, utilize the `CLR_DIM` and `CLR_BOLD` variables inherited from Phase 8 to distinguish between "Signals" and "Sample Pages" for better human readability.
* **Log Entry Granularity:** In the `applied.log` apply-block, consider adding the `bootstrap_date` of the pages being touched to the `summary` block to help users cross-reference with the 30-day lint warning.

### 5. Risk Assessment
**LOW.**
The phase is primarily additive and utilizes well-understood bash/python patterns already validated in Phases 7–10. The hard-lock on "No LLM calls in CLI" (BRWN-16) and the fail-closed privacy default (D-07) eliminate the two largest potential failure modes of an agentic system. The reliance on `git reset --hard` as the canonical undo path ensures that even mechanical script failures are easily recoverable. The project is well-positioned to reach the v1.1 "Shareability" milestone.

---

## Codex Review

## Summary

The Phase 11 plan set is strong on architecture and traceability: it preserves the brownfield mechanical-vs-judgment boundary, keeps claim-level schema frozen, sequences the work in a sensible implementation order, and uses an unusually disciplined RED-to-GREEN contract. The main problem is not missing ambition but a handful of internal inconsistencies between the stated contract and the proposed implementation, especially around root resolution, the 01-page-typing input model, and scan scope. If those are corrected before execution starts, the phase is likely to land cleanly; if not, the test suite can give false confidence while the scripts still target the wrong files or enforce the wrong invariants.

## Strengths

- The apply-class vs advisory-class split is well-designed and matches the project's stated safety posture. `01`/`02` mutate deterministically; `03`/`04` stay report-only.
- The five-plan ordering is mostly correct: Wave 0 contract lock, then `suggest`, then migration scripts, then `review-typing`/`verify`, then schema/docs/DR cleanup.
- The plans consistently respect BRWN-15 and BRWN-16. There is no schema creep into new provenance markers, and the anti-LLM-in-CLI boundary is explicit in both code and docs.
- Test coverage is unusually thorough. The D-19 contract has real teeth, and the fixture mix is well-chosen for small-batch vs large-batch review flow, privacy findings, and pre-tagged bullets.
- The hybrid generation model is a good choice. Keeping canonical scripts in `schema/brownfield/migrations/` and vault state in `.brownfield/` is the right separation for auditability and byte-equality enforcement.
- The plans do not forget the non-code surfaces. AGENTS/template parity, canonical fixture regeneration, REQUIREMENTS amendments, and the Tier-1 decision record are all included, which is exactly where brownfield phases usually drift.
- The proposed `verify --promote` gate is conceptually sound and keeps promotion mechanical instead of fuzzy.

## Concerns

- **[HIGH] Root resolution is wrong in the migration-script plans.** In 11-03, `01`/`02`/`03`/`04` default `BROWNFIELD_ROOT` to `pwd`, but the plans themselves invoke scripts as `bash "$TMP/.brownfield/migrations/..."` from outside the vault root. That means the scripts can read `.brownfield/` from one tree and mutate or inspect `wiki/` in another tree.
- **[HIGH] The 01-page-typing contract is internally inconsistent.** The plan text says `01-page-typing.sh --apply` reads `page-typing-decisions.yaml` only, but the proposed implementation also depends on `page-typing-candidates.yaml` for cluster membership. The tests are written against the "decisions only" claim, while the implementation requires both files.
- **[HIGH] `suggest` scan scope is too loose in the proposed implementation.** The 11-02 pseudocode only excludes a few hardcoded dirs and does not actually reuse the full Phase 10 `.brownfield-ignore` behavior. In repo-root usage, that can classify `docs/`, `schema/`, `AGENTS.md`, `examples/`, and other control-plane files instead of just brownfield target content.
- **[HIGH] `review-typing` can hang forever on EOF in small-batch mode.** The prompt helper returns `''` on EOF, and the command loop treats that as invalid input and re-prompts indefinitely. That is a real CI/noninteractive failure mode.
- **[MEDIUM] 02-provenance-bootstrap does not enforce "top-level bullets only."** The helper regex matches nested bullets, while the requirement says top-level bullets under `## TL;DR` and `## Key Facts`. That will over-tag nested structure and likely create noise.
- **[MEDIUM] 11-04 contains contradictory success criteria.** It says the Phase 11 aggregator should be fully green after review-typing/verify lands, but also says the AGENTS/docs tests are still expected to remain red until 11-05. Those cannot both be true.
- **[MEDIUM] High-confidence auto-approval in 11-02 is narrower than the locked decision.** D-03 says high confidence means "3+ signals agree OR explicit valid frontmatter type," but the implementation only auto-approves when the frontmatter signal is explicit. That changes review load and subtly changes semantics.
- **[MEDIUM] `sha256sum` is a portability regression.** The plans introduce shell-level `sha256sum` use inside migration scripts even though Python `hashlib` is already available and more portable. This is likely to bite on macOS.
- **[MEDIUM] The D-09 metadata header is mostly written but not actually used.** `source_script_hash`/`tool_version` are generated, but the plans do not really enforce stale-artifact detection in `review-typing` or `verify`. That weakens the intended audit story.
- **[MEDIUM] applied.log schema is drifting between scripts.** `02` invents a placeholder input line instead of hashed inputs, and the advisory summaries vary from the normative examples. If log shape stability matters, this will create test or parser churn.
- **[LOW] review-typing accepts arbitrary override labels without validation.** That pushes bad input downstream into `01 --apply` instead of rejecting it where the user entered it.
- **[LOW] privacy findings still persist raw email/phone values into `.brownfield/privacy-findings.yaml`.** That is probably acceptable because `.brownfield/` is gitignored, but the plans should state that this is intentional and bounded.

## Suggestions

- Make vault-root resolution deterministic in all four migration scripts. Default to the parent of the copied script's `.brownfield/` directory, not `pwd`, and update all planned commands/tests to rely on that.
- Fix the 01-page-typing contract before implementation. Either:
  - move cluster membership into `page-typing-decisions.yaml` so apply truly reads one manifest, or
  - explicitly define `candidates.yaml` and `decisions.yaml` as paired immutable inputs and change the tests and docs to match.
- Reuse the exact Phase 10 exclusion model in 11-02 instead of the simplified walker. If Phase 10 has `.brownfield-ignore` parsing and brownfield-scope pruning, do not fork that logic.
- Add explicit EOF behavior to `review-typing`: on empty stdin, either `skip` the cluster or abort the session cleanly with a message. Do not loop forever.
- Tighten `brownfield_provenance.py` so "top-level bullets only" is real, not descriptive. Enforce a specific indentation rule and test nested bullets explicitly.
- Split the Phase 11 tests into "expected green by 11-04" and "expected green by 11-05," or add a whitelist mechanism in the aggregator. Right now the acceptance criteria are internally contradictory.
- Validate override labels inside `review-typing` against the type enum before writing them to the manifest.
- Replace shell `sha256sum` usage with Python `hashlib` everywhere inside the scripted logic. It is already in the stack and avoids platform skew.
- Decide whether D-09 metadata is operational or merely decorative in v1.1. If operational, add stale-artifact checks in `review-typing`/`verify`; if not, say explicitly that enforcement is deferred.
- Normalize applied.log now, not later. Either define per-script variance as part of the schema or make all blocks conform to one rigid field set.
- Add one explicit fixture for "repo root contains control-plane files" or "vault root includes docs/examples" so scan-scope regressions are caught early.

## Risk Assessment

**Overall risk: MEDIUM**

The architecture is good and the plans cover the requirements comprehensively, so this is not a weak phase design. The risk comes from a few high-severity execution mismatches that could invalidate the safety guarantees the plans are trying to create: wrong root targeting, unclear apply inputs, and overly broad scan scope. If those are fixed before implementation begins, the rest of the plan set is strong enough that I would expect a successful phase.

---

## Consensus Summary

Both reviewers agree the phase is well-architected and the test strategy is disciplined. They diverge sharply on risk posture: Gemini rates the phase **LOW risk** based on architectural maturity and safety defaults; Codex rates it **MEDIUM risk** based on concrete implementation mismatches between stated contracts and proposed code. Codex's review is materially more load-bearing for planning — it surfaces execution defects Gemini missed.

### Agreed Strengths

- **Hybrid generation model / architectural decoupling** — "logic in `schema/`, state in `.brownfield/`" is the right split (both reviewers).
- **Mechanical-vs-judgment boundary holds** — apply-class (`01`/`02`) vs advisory-class (`03`/`04`) separation respects BRWN-15/BRWN-16 (both).
- **Conservative provenance-bootstrap heuristics** — TL;DR/Key Facts scoping + skip classes minimize noise (both, though Codex flags the nested-bullet implementation gap).
- **Review-manifest pattern** — `decisions.yaml` as control signal for page-typing is the "secret sauce" (Gemini) / "paired immutable inputs" (Codex).
- **Idempotency engineering** — `op_hash`, `bootstrap_stage: verified` gate, and D-12 "readiness not history" are sound (both reviewers call these out).
- **Wave-0 RED test harness + D-19 contract has real teeth** (both).

### Agreed Concerns

(Note: only two reviewers, so "agreed" here means both flagged the same territory; most concerns are unique to Codex.)

- **Privacy-review false positives (`04-privacy-review`)** — Both reviewers note regex can over-match. Both accept D-07 report-only hard-lock as sufficient mitigation. **Severity: MEDIUM (Gemini) / LOW (Codex implicit).**

### Highest-Priority Concerns (Codex HIGH — unique, action-blocking)

These are the four items that must be addressed before execution begins:

1. **Root resolution defect** — Migration scripts default `BROWNFIELD_ROOT=$(pwd)` but plans invoke them from outside the vault root via `bash "$TMP/.brownfield/migrations/..."`. Can cause cross-tree mutation. **Fix:** derive root from the copied script's `.brownfield/` parent, not `pwd`.
2. **`01-page-typing` apply contract inconsistency** — Plan text claims decisions-only, implementation requires both `candidates.yaml` and `decisions.yaml`. Tests lock the wrong contract. **Fix:** either merge cluster membership into `decisions.yaml`, or declare both files as paired immutable inputs and update tests/docs.
3. **`suggest` scan scope too loose** — Hardcoded dir excludes don't reuse Phase 10's `.brownfield-ignore` behavior; can sweep `docs/`, `schema/`, `AGENTS.md`, `examples/` into classification. **Fix:** reuse Phase 10 exclusion model verbatim.
4. **`review-typing` EOF hang** — Prompt helper returns `''` on EOF, loop re-prompts indefinitely. Breaks non-interactive / CI. **Fix:** on empty stdin, either skip cluster or abort session.

### Divergent Views

- **Overall risk:** Gemini LOW, Codex MEDIUM. Codex's HIGH-severity findings tip the aggregate risk toward MEDIUM — Gemini appears not to have inspected the scripts' `$(pwd)` defaults vs invocation sites, the `01-page-typing` input model, or `review-typing`'s EOF path at the same depth.
- **D-09 metadata header (`source_script_hash` / `tool_version`):** Gemini does not flag; Codex rates it MEDIUM — "mostly written but not actually used," weakening the audit story. Decision needed: operational or decorative?
- **`sha256sum` shell use:** Only Codex flags as MEDIUM portability regression (macOS risk). Suggestion: move all hashing to Python `hashlib`.
- **`applied.log` schema drift across scripts:** Only Codex flags as MEDIUM — `02` uses placeholder input line, advisory summaries diverge from normative examples.
- **Phase 11 aggregator success criteria in 11-04:** Only Codex identifies a contradiction — "fully green after 11-04" vs "AGENTS/docs tests red until 11-05." Needs per-plan gate split or whitelist.

### Recommended Next Action

Run `/gsd-plan-phase 11 --reviews` to incorporate feedback. Prioritize Codex's four HIGH-severity findings — they are pre-execution blockers, not execution-time issues. The MEDIUM findings around `sha256sum`, `applied.log` schema, D-09 enforcement, and the 11-04 aggregator contradiction are cheaper to fix in the plans than during implementation.
