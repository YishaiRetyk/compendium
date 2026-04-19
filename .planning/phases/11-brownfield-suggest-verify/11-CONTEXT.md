# Phase 11: Brownfield Suggest + Verify - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `bin/brownfield.sh` subcommands `suggest` + `review-typing` + `verify` (with `--promote`), the four staged migration scripts (`01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-review.sh` — renamed from `04-privacy-classification.sh`), the hybrid generation model (canonical scripts in `schema/brownfield/migrations/`; vault-specific candidate/decision YAMLs under `.brownfield/`), single `.brownfield/applied.log` with markdown-block schema, full populate of `AGENTS.md §11.5 Brownfield Workflow`, complete `docs/reference/brownfield.md` suggest/review/verify sections, `tests/phase-11/` with RED-to-GREEN contract suite + one end-to-end happy-path test, and the Tier-1 decision record documenting the apply-vs-advisory architecture + review-manifest pattern.

**Out of scope for Phase 11 (→ v1.2):** Single-command `brownfield apply` chain-runner (BRWNAPPLY-01). Runtime-specific skills (`.claude/skills/brownfield-*.md`). Deeper AGENTS.md workflow-extraction work (backlog 999.4). Promoting 03-cross-link-inference or 04-privacy-review to manifest-backed apply (both stay advisory in v1.1). LLM integration inside `bin/brownfield.sh` (hard lock per BRWN-16; AI assistance operates on artifacts from outside the CLI).

**Out of scope for Phase 11 (→ Phase 12):** Obsidian render verification, Codex agent-parity run, write-back scenario re-run (DEBT-01/02/04).

**Out of scope entirely:** Auto-promotion of `privacy:` values by scanner heuristics (fail-closed preserved per AGENTS.md §13). New claim-level schema fields beyond existing epistemic vocabulary (BRWN-15 hard lock — no magic-string provenance values, no new inline-field subtypes). LLM calls inside migration scripts (BRWN-16). Rigid prerequisite gates between migration scripts (BRWN-13 per-class posture preserved; soft readiness checks only).

</domain>

<decisions>
## Implementation Decisions

### Area 1 — Per-script judgment semantics (apply-class vs advisory-class split)

- **D-01 (Architecture split):** Four migration scripts split into two classes by their relationship to vault mutation.
  - **Apply class (touches pages):** `01-page-typing.sh`, `02-provenance-bootstrap.sh`. Ship a real `--apply` path that mutates frontmatter / body text.
  - **Advisory class (reports only):** `03-cross-link-inference.sh`, `04-privacy-review.sh`. Generate `.brownfield/REPORT.md` sections + structured candidate files; never mutate pages; `--apply` is either a no-op or omitted entirely.
  - **Design principle (quote verbatim in AGENTS.md §11.5 + docs):** *"Review may be interactive and AI-guided; apply must always be deterministic."*

- **D-02 (01-page-typing — two-stage discovery→review→apply):**
  - **Stage 1 (discovery, no user input):** Script walks the vault, classifies each page via the reusable `bin/lib/brownfield_classify.py` (from Phase 10 D-16). Extends the classifier with inbound-link density (already reserved as `inbound_count` parameter per Phase 10 verification). Writes `.brownfield/page-typing-candidates.yaml` (clustered by confidence + signal-pattern, e.g., `cluster_1: 12 pages, confidence=medium, signals={frontmatter=none, filename=pascalcase, h1=entity-like, links=inbound-heavy}`). Writes `.brownfield/page-typing-decisions.yaml` with every cluster initialized to `decision: pending`.
  - **Stage 2 (review, interactive or AI-guided — see D-04):** User updates `page-typing-decisions.yaml` via `bin/brownfield.sh review-typing`.
  - **Stage 3 (apply, deterministic):** `bash .brownfield/migrations/01-page-typing.sh --apply` reads the decisions manifest only; it does NOT re-classify at apply time. Mutates `type:` per manifest; idempotent; respects ruamel.yaml round-trip.

- **D-03 (01-page-typing — confidence policy):**
  - `high` confidence (3+ signals agree OR explicit valid frontmatter `type:`) → auto-apply (default behavior; decisions manifest pre-populated with `decision: approve`).
  - `medium` confidence → planner's call at research time: either auto-apply behind an explicit threshold flag (e.g., `--auto-medium`) OR route to review queue (default: review). Planner verifies empirically against fixtures.
  - `low` confidence → review queue (never auto-applied).
  - `unknown` → always review queue.
  - Mantra: **"Check readiness, not history."** Policy keys off current vault signals, not `applied.log`.

- **D-04 (review-typing UX — small-batch TTY + large-batch AI handoff):** `bin/brownfield.sh review-typing` is an orchestrator that branches on pending-set size:
  - **Small batch (pending clusters < N, likely N=20):** TTY questionnaire prompts cluster-by-cluster. Per cluster: `approve all` / `reject all` / `inspect individual pages` / `override selected pages`. Writes back to `page-typing-decisions.yaml`.
  - **Large batch (pending clusters ≥ N):** Emits `.brownfield/review-typing-prompt.md` — a structured prompt template pointing at `page-typing-candidates.yaml` + `page-typing-decisions.yaml` with instructions telling the AI to explain tradeoffs, help merge/split clusters, and **edit the decisions manifest, not pages**. User runs this in their AI session (Claude Code, Codex, etc.) outside the CLI. AGENTS.md §11.5 documents this so any future agent recognizes the artifact.
  - Both modes write back to the **same** decisions manifest. Apply is always `bash .brownfield/migrations/01-page-typing.sh --apply` reading that manifest.
  - TTY stays simple — no fancy TUI. Keep cluster-by-cluster primitives: approve / reject / inspect / override.
  - No LLM calls inside `bin/brownfield.sh` (preserves BRWN-16 mechanical-tool boundary).

- **D-05 (02-provenance-bootstrap — direct apply, narrow surface):**
  - Targets **only** top-level bullets under `## TL;DR` and `## Key Facts` sections. Detail is never touched.
  - Appends ` [epistemic:: inferred]` at end of line when all of: no existing `[epistemic::...]` marker; not a link-only or source-list bullet; not a question/task/placeholder (heuristic: not ending in `?`, not starting with `TODO:`/`FIXME:`/checkbox).
  - No review manifest. Discovery writes `.brownfield/provenance-bootstrap-report.yaml` as a compact preview (per-page eligible-bullet counts + 2-3 example bullets per page). User inspects, runs `--apply` if happy.
  - If a page has `## Key Facts` but zero eligible claim bullets → report honestly (`no eligible claim bullets found`), do not invent granularity.
  - Page-level `bootstrap_stage: bootstrapped` carries lineage; no claim-level `[prov:bootstrap]` magic strings (BRWN-15 hard lock).
  - Rollback: `git reset --hard` (per Phase 10 D-06).
  - Future escape hatch (not v1.1): `.brownfield/02-exclude.txt` page-level opt-out if real-world usage shows noise.

- **D-06 (03-cross-link-inference — report-only):**
  - Scans vault for exact-title and alias mentions of other page titles across all pages.
  - Writes `.brownfield/cross-link-candidates.yaml` and a dedicated `## Cross-link candidates` section in `.brownfield/REPORT.md`, grouped by source page.
  - Per candidate: `source_page`, `line_number`, `matched_text`, `proposed_target`, `match_type` (`exact-title` | `alias`), `short_rationale`, `target_already_linked_from_source` (bool — respects AGENTS.md §8 first-mention-only).
  - No `--apply` path (or `--apply` exits non-zero with message pointing at REPORT.md). User applies by hand.
  - Future (not v1.1): manifest-backed apply pattern mirroring 01 (`cross-link-decisions.yaml`).

- **D-07 (04-privacy-review — RENAMED; report-only; fail-closed preserved):**
  - **Rename:** `04-privacy-classification.sh` → `04-privacy-review.sh` throughout phase artifacts. BRWN-12 in REQUIREMENTS.md gets a requirement-wording amendment (planner action item — matches Phase 10 precedent on BRWN-04 amendment).
  - Scans page bodies for privacy-sensitive patterns (email-like `\S+@\S+\.\S+`, phone-like digit groupings, SSN-like `\d{3}-\d{2}-\d{4}`, user-authored `.brownfield-privacy-terms.txt` if present).
  - Writes `.brownfield/privacy-findings.yaml` + a `## Privacy review` section in `.brownfield/REPORT.md`.
  - **NEVER flips `privacy:` frontmatter.** Fail-closed per AGENTS.md §13 stays intact; every bootstrapped page keeps `privacy: local_only` until a human explicitly promotes it.
  - Contract phrase (script `--help` + docs): *"04-privacy-review classifies findings for review priority, not for frontmatter mutation."*
  - Future (not v1.1): user-authored `.brownfield-privacy-cloudsafe.txt` allowlist as an explicit override layer; scanner still never auto-promotes.

### Area 2 — Suggest generation + op_hash + applied.log

- **D-08 (Hybrid generation model):** Canonical migration scripts live under `schema/brownfield/migrations/*.sh` (versioned in git, reviewable, testable for byte-equality). `bin/brownfield.sh suggest` does TWO things:
  1. **Byte-copy** canonical scripts into `.brownfield/migrations/*.sh`. Byte-equality is CI-enforced (suggest must not mutate script content).
  2. **Generate vault-specific data files** under `.brownfield/` (not inside `migrations/`): `page-typing-candidates.yaml`, `page-typing-decisions.yaml` (empty/pending), `provenance-bootstrap-report.yaml`, `cross-link-candidates.yaml`, `privacy-findings.yaml`.
  - Separation: logic is versioned in `schema/`; state is ephemeral in `.brownfield/`.
  - Scripts read data files at run time; they do NOT bake vault-specific logic into rendered shell code.

- **D-09 (Candidate-file metadata header):** Every generated candidate/data file under `.brownfield/` opens with a YAML metadata block:
  ```yaml
  # ---
  # schema_version: 1
  # tool_version: <from a version constant in suggest>
  # generated_at: <UTC ISO timestamp>
  # vault_root: <absolute path>
  # source_script_hash: <sha256 of the canonical script the data backs>
  # ---
  ```
  Future `verify` / `review-typing` use this to detect stale review artifacts.

- **D-10 (op_hash scope — script semantics only):** The `# op_hash: sha256:<hex>` header in each migration script covers the canonical script body + an embedded schema/version constant + the expected data-file schema version(s). It does **NOT** include candidate-YAML hashes, decision-manifest hashes, vault page hashes, or timestamps. Rationale: op_hash answers *"what operation definition is this script implementing?"* — not *"what exact vault state did this run consume?"* Run-state answers go to `applied.log` (D-11).
  - Paired comment in header: `# op_hash_scope: canonical-script-body + data-schema-version`
  - Future (not v1.1): optional `run_hash` derived from `op_hash` + input hashes, if external auditing needs a full-run fingerprint.

- **D-11 (applied.log — single file, markdown-block schema):** `.brownfield/applied.log` is append-only; one block per meaningful execution; UTC timestamps only.
  - **Apply-class (01, 02):** append a block on real `--apply` only (NOT on dry-run candidate regeneration).
  - **Advisory-class (03, 04):** append a block on advisory execution that produced findings or completed a review pass.
  - **Plain dry-runs that only regenerate candidates do NOT append.**
  - **Apply-block schema:**
    ```markdown
    ## <script-name> @ <UTC ISO timestamp>
    mode: apply
    op_hash: sha256:...
    exit_code: 0
    prereq_check: pass | warn
    inputs:
    - <.brownfield/...> @ sha256:...
    - <.brownfield/...> @ sha256:...
    files_touched: <n>
    files_created: <n>
    files_updated: <n>
    files_skipped: <n>
    changes:
    - <path> | <updated|created> | <before> -> <after>
    summary:
    - approved_clusters: <n>
    - overridden_pages: <n>
    - pending_pages_remaining: <n>
    ```
  - **Advisory-block schema:**
    ```markdown
    ## <script-name> @ <UTC ISO timestamp>
    mode: advisory
    op_hash: sha256:...
    exit_code: 0
    prereq_check: pass | warn
    mutations: none
    report_section: REPORT.md#<anchor>
    summary:
    - pages_scanned: <n>
    - findings: <n>
    - high_risk_findings: <n>
    ```
  - Apply blocks include hashes of decision/candidate inputs (load-bearing for traceability: "what exact review state produced these mutations?").
  - No JSONL (future `--format json` flag possible if needed); no per-script logs; no appending to REPORT.md.

- **D-12 (Prerequisites — script-specific soft state-based checks):** Preserve BRWN-13 "per-class user invocation" posture. Do NOT use `applied.log` as a dependency source — it tells you history, not readiness.
  - `01-page-typing.sh` — no prereq check.
  - `02-provenance-bootstrap.sh` — soft **state-based** check: count pages with empty `type:` frontmatter; if majority of vault is untyped, emit stderr WARN: `"WARN: <N> bootstrapped pages still have empty type:. 02-provenance-bootstrap works best after page typing review or on pages with existing valid type. Proceeding anyway."` Exit 0 and continue.
  - `03-cross-link-inference.sh` — no prereq check.
  - `04-privacy-review.sh` — no prereq check.
  - Rule: **"Check readiness, not history."** Inspect current vault state, never `applied.log`.

### Area 3 — Verify + bootstrap_stage transitions

- **D-13 (verify scope — read-only by default, explicit --promote):**
  - `bin/brownfield.sh verify` (no flags) runs `bin/lint.sh --ci --category yaml,provenance,orphan,crossref,brownfield` (**privacy NOT included** — privacy is handled by the separate `bin/check-privacy.sh` on public paths only, per Phase 9 D-15; `verify` does not claim to gate on privacy advisory completion). Prints summary of what blocks promotion. **Mutates nothing.**
  - `bin/brownfield.sh verify --promote` re-runs the checks AND flips `bootstrap_stage: bootstrapped` → `verified` on pages that pass an explicit objective pass-list.

- **D-14 (--promote objective pass-list, per-page gate):** A page is promoted to `bootstrap_stage: verified` iff ALL of:
  1. Currently `bootstrap_stage: bootstrapped` (not already `verified` or `archived`).
  2. `type:` is set to a valid enum per AGENTS.md §4.
  3. Page has zero blocking findings (severity `error`) in the verify-checked lint categories.
  4. Required type-specific fields present where applicable (e.g., source summaries have `path`, `content_hash`, `ingested_at`, `source_type` per AGENTS.md §5).
  5. No pending review decision remains for the page in `page-typing-decisions.yaml` (all relevant clusters resolved).
  - Pages failing any gate remain at `bootstrap_stage: bootstrapped`.
  - `--promote` is the **human sign-off** for advisory steps that aren't mechanically provable (privacy review especially): the user's act of running `--promote` asserts they've examined advisory outputs.

- **D-15 (`bootstrap_stage` lifecycle diagram):** Documented in AGENTS.md §11.5 and `docs/reference/brownfield.md`:
  ```
  (absent) ──[bin/brownfield.sh bootstrap --apply]──> bootstrapped
  bootstrapped ──[bin/brownfield.sh verify --promote, passes gate]──> verified
  bootstrapped ──[normal ingest via bin/ingest.sh]──> (stripped per BRWN-10)
  verified     ──[no automatic downgrade]──> (manual edit only)
  raw          ──[reserved for future import workflows]──> (no writer in v1.1)
  ```

### Area 4 — AGENTS.md §11.5 content shape

- **D-16 (§11.5 = thin authoritative contract):** Full canonical workflow block per brownfield subcommand (scan, bootstrap, suggest, review-typing, verify) — matches §11.1–11.4 shape exactly: `Trigger / Inputs / Outputs / Commit format` preamble block, numbered `Steps`, `Abort conditions`. Compact and lean — no tutorial, no operator ergonomics. AGENTS.md stays the "sole authoritative specification."
  - Rule: **"Put decisions, boundaries, and lifecycle in AGENTS; put examples, UX, and operational detail in docs."**
  - Load-bearing principles explicitly in §11.5 body prose:
    1. Mechanical-vs-judgment boundary (first principle).
    2. "Review may be interactive and AI-guided; apply must always be deterministic." (the D-01 design principle — quote verbatim).
    3. Apply-class vs advisory-class split (name each of the four scripts with their class).
    4. `bootstrap_stage` lifecycle diagram (D-15).
  - Pointers at end of §11.5: `See: docs/reference/brownfield.md` for operator runbook.
  - CLAUDE.md auto-syncs via `.githooks/pre-commit` per Phase 7 D-03 — no separate §11.5 maintenance.
  - `schema/AGENTS.template.md` mirrors the §11.5 additions (Phase 9.1 extraction-invariant pattern for template-parity test).
  - Canonical fixture `schema/fixtures/canonical-AGENTS.md` regenerated via the Phase 8-01 python3 render routine to preserve the Phase-8 byte-equality test.

- **D-17 (`docs/reference/brownfield.md` content for Phase 11):**
  - Populate the currently-stubbed `## suggest subcommand`, `## verify subcommand`, and a new `## review-typing subcommand` section.
  - Include: TTY mode cluster UX description, large-batch AI-handoff template reference, candidate-file shapes with examples, the full lifecycle walkthrough (bootstrap → suggest → review-typing → 01 apply → 02 apply → 03/04 advisory → verify → verify --promote), end-to-end rollback recipe (still `git reset --hard`), troubleshooting table for common failure modes.
  - Does NOT restate the §11.5 normative contract — links to it.

### Area 5 — Plan structure + test strategy

- **D-18 (5 plans default, with 11-03 split escape hatch):**
  - **11-01:** Wave-0 test harness + fixtures + `schema/brownfield/migrations/*.sh` skeleton files + RED tests covering the full contract suite (D-19). **11-01 locks the contract, not just the harness.**
  - **11-02:** `suggest` subcommand + hybrid script copy + candidate-file generation (consumes existing `bin/lib/brownfield_classify.py` from Phase 10).
  - **11-03:** Four migration scripts (01 discovery→clustering→apply-from-manifest, 02 direct-apply + report, 03 advisory report, 04 advisory report).
    - **Escape hatch:** if researcher/planner finds 01-page-typing materially larger than 02+03+04 combined, split 11-03 into `11-03a` (01-page-typing alone) + `11-03b` (02+03+04). Don't pre-plan this split; trust the planner after research.
  - **11-04:** `review-typing` subcommand + `verify` subcommand + `--promote` gate + applied.log writer integration.
  - **11-05:** AGENTS.md §11.5 full populate + `docs/reference/brownfield.md` suggest/review-typing/verify sections + `schema/AGENTS.template.md` §11.5 mirror + `schema/fixtures/canonical-AGENTS.md` regenerate + REQUIREMENTS.md BRWN-12 rename amendment (`04-privacy-classification` → `04-privacy-review`) + REQUIREMENTS.md new REQ-ID for `review-typing` subcommand (planner to propose wording) + Tier-1 decision record (D-20).

- **D-19 (RED test suite targets — locked in 11-01):**
  - `suggest` copies canonical scripts byte-identically from `schema/brownfield/migrations/` into `.brownfield/migrations/`.
  - `suggest` writes vault-specific data artifacts under `.brownfield/` (NOT vault-specific rendered scripts).
  - Candidate/data files carry the D-09 metadata header.
  - `01-page-typing` discovery writes candidate clusters + empty decisions manifest.
  - `01-page-typing --apply` reads decisions manifest only, is idempotent (zero-byte diff on re-run), and never re-classifies at apply time.
  - `review-typing` small-batch mode updates `page-typing-decisions.yaml` via scripted stdin.
  - `review-typing` large-batch mode writes `.brownfield/review-typing-prompt.md` and does NOT mutate pages.
  - `02-provenance-bootstrap --apply` only touches eligible top-level bullets in TL;DR + Key Facts; honest "no eligible bullets" output when none.
  - `03-cross-link-inference` is advisory-only; `--apply` either no-ops or exits non-zero pointing at REPORT.md.
  - `04-privacy-review` is advisory-only; NEVER flips `privacy:` frontmatter.
  - `.brownfield/applied.log` block shape (D-11) stable and append-only; apply-class appends on `--apply` only; advisory-class appends on findings.
  - `op_hash` stable across vaults for the same canonical script version.
  - `verify` is read-only by default.
  - `verify --promote` only flips eligible `bootstrapped` → `verified` pages; blockers remain `bootstrapped`.
  - Prereqs: state-based; `02` WARN message phrasing correct; no script uses `applied.log` as a dependency source.
  - One end-to-end happy-path test: `suggest → review-typing → 01 --apply → 02 --apply → 03 advisory → 04 advisory → verify → verify --promote`. Asserts final vault state matches a golden fixture.

- **D-20 (Fixture design):**
  - Small vault with 3–6 ambiguous pages (cluster count < 10) to exercise small-batch TTY review.
  - Larger vault fixture that triggers the AI-guided handoff path (cluster count ≥ 20).
  - Fixture with pre-existing valid `type:` frontmatter to prove 02's prereq check is state-based, not history-based.
  - Fixture with sensitive-looking strings (email-like, phone-like, SSN-like) to exercise 04-privacy-review.
  - Fixture with already-tagged `[epistemic::]` bullets in TL;DR/Key Facts to prove 02 skips them.
  - Fixtures pin dates via Phase-10-precedent env vars (`BROWNFIELD_FIXTURE_TODAY`, `BROWNFIELD_FIXTURE_CREATED_AT`) for byte-equality determinism.

### Tier-1 Decision Record (scope)

- **D-21 (Single Tier-1 DR covering apply-vs-advisory + review-manifest + lifecycle):** Plan 11-05 commits `wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md` with `trigger_type: schema-update`. Captures:
  - The apply-class vs advisory-class split (D-01) and why.
  - The review-manifest pattern introduced for 01-page-typing (D-02, D-04) and why 02/03/04 do NOT adopt it (narrow surface / advisory-only).
  - The design principle "Review may be interactive and AI-guided; apply must always be deterministic."
  - The `bootstrap_stage` lifecycle gate via `verify --promote` (D-13, D-14, D-15).
  - Alternatives considered (auto-apply all, per-page prompts, scanner-driven privacy promotion) and why rejected.
  - `affected_pages`: references the new AGENTS.md §11.5 content + `docs/reference/brownfield.md` + the four migration script operations.
  - This is structural enough to warrant Tier-1 (inline with the phase's structural commits), not a Tier-3 reflect catch-up.

### Claude's Discretion

- Exact threshold for small-batch vs large-batch review-typing mode (D-04). Planner picks a concrete N (recommendation ~20 clusters) after reviewing fixture sizes; documented in script header.
- Exact form of the large-batch AI-handoff prompt template (D-04). Planner drafts; must instruct AI to edit decisions-manifest only (not pages); must point at candidate+decisions files.
- `medium`-confidence default policy for 01-page-typing (D-03): auto-apply behind `--auto-medium` flag OR route to review queue. Planner verifies against fixtures.
- Internal file layout of `bin/lib/` additions (new module for clustering vs extending existing `brownfield_classify.py`). Planner's call; must be unit-testable and reusable.
- Whether to split 11-03 into 11-03a + 11-03b after research (D-18 escape hatch). Planner decides.
- Exact wording of REQUIREMENTS.md BRWN-12 rename amendment + the new REQ-ID for `review-typing`. Planner drafts; user reviews.
- Colorized diff output / TTY-color convention for review-typing (inherit Phase 8 D-20 `NO_COLOR` pattern).
- Canonical shape of `.brownfield/review-typing-prompt.md` (D-04). Lean + directive; short enough that a freshly-invoked AI session doesn't context-bloat.
- Exact `applied.log` UTC timestamp format (ISO-8601 with `Z` suffix recommended, matching Phase 3 D-11 precedent).
- Whether `bin/brownfield.sh suggest` should ever support `--force` to regenerate candidate files when the metadata header's `source_script_hash` has drifted. Probably not for v1.1; defer.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements (authoritative scope)

- `.planning/ROADMAP.md` §Phase 11 — goal, dependencies (Phase 10 scan/bootstrap infrastructure + `bootstrap_stage` field; Phase 9 `bin/lint.sh --strict` + JSON mode consumed by verify), success criteria 1–5, REQ-ID list (BRWN-11..20).
- `.planning/REQUIREMENTS.md` §BRWN lines 96–105 (BRWN-11 through BRWN-20) — Phase 11 requirements; traceability table lines 228–237. BRWN-12 wording requires amendment per D-07 (04-privacy-classification → 04-privacy-review).
- `.planning/PROJECT.md` §Current Milestone — brownfield listed as "single highest-risk surface area in v1.1." §Constraints — agent-agnostic, file-based, Obsidian-first, local-only.
- `.planning/STATE.md` §Accumulated Context — prior phase decisions; last session stopped at Phase 10 completion (32/32).

### Prior Phase Contexts (locked upstream decisions)

- `.planning/phases/10-brownfield-scan-bootstrap/10-CONTEXT.md` — ALL 22 decisions (D-01..D-22) carry forward as locked upstream: dry-run + `--apply` default (D-08), classifier rule set D-16 reusable by `01-page-typing.sh`, `.brownfield/REPORT.md` as single-file output D-04, `bootstrap_stage`/`bootstrap_date` schema D-12/D-13/D-14, `.brownfield-ignore` exclusion model D-19, `git reset` canonical undo D-06, typed-merge policy D-02, test harness dual-golden pattern D-07.
- `.planning/phases/10-brownfield-scan-bootstrap/10-VERIFICATION.md` — confirms Phase 10's 11 truths passed 2026-04-18; identifies 3 Warning-severity pre-existing issues (WR-01 orphan-raw-sources false-positive flip, WR-02 idempotency fires only on `bootstrapped`, WR-03 Obsidian table-cell rendering + §11.5 forward-ref typo) — Phase 11 planner may opportunistically close these if the §11.5 work touches the same surface; otherwise leave per verifier disposition.
- `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md` — lint `--ci` severity-remap dispatcher (D-02), `--strict` as separate job (D-11), auto-detect + stderr-warn pattern (D-20/D-21) reused by D-12's 02 soft prereq warn; `bin/check-privacy.sh` is public-paths-only (D-15), so verify does NOT call it on vault content.
- `.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md` — Python `difflib` unified-diff (D-18) reusable for review-typing diff output; TTY/`NO_COLOR` convention (D-20) inherited; byte-frozen fixture pattern (`schema/fixtures/` + LF-pinned `.gitattributes`) precedent for 11-01's fixture pack.
- `.planning/phases/07-neutral-template-foundation/07-CONTEXT.md` — CLAUDE.md byte-sync via pre-commit hook (D-03); `schema/AGENTS.template.md` parity convention.
- `.planning/phases/09.1-progressive-disclosure-extraction/09.1-CONTEXT.md` — extraction-invariant test pattern reusable for §11.5 AGENTS.md edit verification; `bin/sync-claude.sh` auto-sync pattern.

### Research (informs architecture; not re-litigated)

- `.planning/research/FEATURES.md` §Bucket 5 (lines 178–232) — table stakes, differentiators, **anti-features (line 209–215 critical: no `brownfield --apply` chain-runner, no LLM calls inside `brownfield.sh`, no TUI, no migration-history tracker, no one-shot undo, no schema-inferred fields)**, plan breakdown, integration with v1.0 primitives.
- `.planning/research/PITFALLS.md` §C-2 (lines 40–64) — silent frontmatter corruption; underpins D-05's typed-merge, D-06 git-as-backup, D-07 byte-exact fixtures.
- `.planning/research/PITFALLS.md` §C-3 (lines 68–90) — idempotency violations; underpins D-11's sentinel + content-hash conventions carried into D-10 (op_hash stable across vaults).
- `.planning/research/PITFALLS.md` §M-9+ — page classification heuristic pitfalls; Phase 10 D-16 already addresses; Phase 11's 01-page-typing extends with inbound-link density.

### Existing Code Surface (read before editing)

- `bin/brownfield.sh` (current HEAD lines 51–62) — subcommand dispatcher; `suggest|verify` branches currently exit with code 2 and "not yet implemented" message. Phase 11 replaces these branches with real implementations + adds `review-typing` branch.
- `bin/lib/brownfield_classify.py` (current HEAD) — exports `classify_page(rel_path, frontmatter, body, inbound_count=None)` and `unknown_reason()`. Phase 11's 01-page-typing extends via `inbound_count` parameter + adds clustering function.
- `bin/lib/brownfield_yaml.py` (current HEAD) — exports `read_fm_body`, `merge_sentinels`, `write_roundtrip`, `FIELD_CLASS_A`, `FIELD_CLASS_B`, `VALID_ENUMS`, `build_d14_sentinel_set`, `split_frontmatter`, `infer_id_from_filename`, `extract_h1`, `file_mtime_iso`; ruamel.yaml `YAML(typ='rt')`. Phase 11 reuses the round-trip for 01-page-typing `--apply` + 02-provenance-bootstrap frontmatter skip-detection.
- `bin/lint.sh` (current HEAD) — `--ci` severity-remap dispatcher (Phase 9) + brownfield category (Phase 10) + `--category`/`--skip-category` flags; `verify` wraps this with specific category flags per D-13.
- `bin/ingest.sh` (current HEAD lines 316–374) — BRWN-10 strip block between `cp` and `compute_hash`; no Phase 11 changes expected.
- `bin/sync-claude.sh` + `.githooks/pre-commit` — AGENTS.md → CLAUDE.md byte-sync; re-stages automatically after §11.5 edit.
- `bin/release.sh` (Phase 7) — dry-run / `--apply` split + APPLIED.md manifest precedent; `review-typing --promote` mirrors the `--apply` posture.
- `tests/phase-10/run.sh` + `lib.sh` + fixtures — pattern-clone for `tests/phase-11/`; inherit `make_fixture_repo` + fixture-date env-var pattern.

### Schema / Docs Touch Points

- `AGENTS.md §11.5` — currently reserved/stubbed; Phase 11 Plan 11-05 writes the full compact-canonical contract per D-16. CLAUDE.md auto-syncs.
- `AGENTS.md §5` — `bootstrap_stage` enum documentation (`raw | bootstrapped | verified`) is ALREADY in place from Phase 10 D-20. Phase 11 Plan 11-05 may tighten the description to reference §11.5 lifecycle (currently has a forward-ref typo pointing at §11 Release Workflow per 10-REVIEW.md WR-03 — opportunistic fix).
- `AGENTS.md §4` — no change; `type:` enum unchanged; 01-page-typing writes values that already belong to this enum.
- `AGENTS.md §6` — no change; 02-provenance-bootstrap uses existing `[epistemic:: inferred]` vocabulary per BRWN-15 + EPST-01.
- `AGENTS.md §8` — 03-cross-link-inference respects first-mention-only rule; candidate file notes whether a link already exists from source.
- `AGENTS.md §13` — 04-privacy-review respects `privacy: local_only` fail-closed default; never auto-promotes.
- `schema/AGENTS.template.md` — §11.5 mirror per Phase 9.1 template-parity test; must survive `bin/init-wizard.sh` render.
- `schema/fixtures/canonical-AGENTS.md` — regenerate via Phase 8-01 python3 render routine after §11.5 edit; Phase 8-01 byte-equality test (`tests/phase-08/test_canonical_byte_equality.sh`) must keep passing at 21/21.
- `schema/brownfield/migrations/` — NEW directory: canonical migration scripts (`01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-review.sh`). Tracked in git; byte-copied on `suggest`.
- `docs/reference/brownfield.md` — currently has scan/bootstrap complete + suggest/verify stubs (Phase 10 D-22). Phase 11 Plan 11-05 completes suggest, adds `## review-typing subcommand`, completes verify.
- `docs/reference/brownfield.md` `## Fixture testing environment variables` section (Phase 10-06) — extend if Phase 11 adds new env vars; otherwise unchanged.
- `.gitignore` — verify `.brownfield/` already excluded per TMPL-04 (Phase 7); no change. `.brownfield-privacy-terms.txt` left tracked-optional (user-authored config).
- `.planning/REQUIREMENTS.md` — Plan 11-05 flips BRWN-11..20 checkboxes post-VERIFICATION; Plan 11-05 also amends BRWN-12 wording (rename) and adds a new REQ-ID for `review-typing` (planner drafts wording).

### External Specs (planner reference)

- ruamel.yaml round-trip API — <https://yaml.readthedocs.io/en/latest/> — `YAML(typ='rt')` for 01-page-typing `--apply` frontmatter mutation + 02-provenance-bootstrap frontmatter skip-detection.
- Standard Unix `tty` detection for TTY-vs-not-TTY mode selection in review-typing small-batch vs large-batch branching.
- no-color.org — `NO_COLOR` env-var convention (inherited from Phase 8 D-20).
- AGENTS.md §11.1–11.4 self-reference — study these verbatim before writing §11.5 to match the Trigger/Inputs/Outputs/Commit/Steps/Abort template exactly.

### Requirements Amendment Hooks (from discussion)

1. **BRWN-12 rename** — `04-privacy-classification.sh` → `04-privacy-review.sh`. REQUIREMENTS.md §BRWN line 97 needs a wording amendment. Planner action item for Plan 11-05.
2. **New REQ-ID for `review-typing` subcommand** — currently not listed in BRWN-11..20. Planner drafts a REQ-ID (tentatively `BRWN-22`, keeping BRWN-21 reserved for Phase 10's byte-exact fixture test) covering: small-batch TTY cluster-by-cluster prompts, large-batch AI-handoff via `.brownfield/review-typing-prompt.md`, manifest-write-back contract, no-LLM-calls-inside-CLI constraint.
3. **Scope clarification for BRWN-17 verify** — current wording says "thin wrapper over `bin/lint.sh` with brownfield-appropriate severity thresholds." Phase 11 D-13 extends this with the `--promote` lifecycle gate. Planner may propose a wording amendment or leave BRWN-17 as the minimal contract and document `--promote` as an enhancement in the decision record.
4. **Phase 10 WR-01/WR-02/WR-03 warnings** (from 10-REVIEW.md) — opportunistic fixes during Phase 11 if the same surface is touched (e.g., if Plan 11-05 touches AGENTS.md §5, fix WR-03 forward-ref typo as part of that edit). Not required; planner's call.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`bin/lib/brownfield_classify.py`** (Phase 10) — `classify_page()` + `unknown_reason()`; `inbound_count` parameter reserved specifically for Phase 11's 01-page-typing discovery (per Phase 10 VERIFICATION.md). Extend via clustering function, not by rewriting.
- **`bin/lib/brownfield_yaml.py`** (Phase 10) — ruamel.yaml round-trip + typed-merge primitives. 01-page-typing `--apply` uses `read_fm_body` + `write_roundtrip` to mutate `type:` without touching body. 02-provenance-bootstrap uses `read_fm_body` to check for existing `[epistemic::]` markers in TL;DR/Key Facts.
- **`bin/lint.sh` severity-remap dispatcher** (Phase 9) + brownfield category (Phase 10) + `--category` flag — verify wraps this with `--category yaml,provenance,orphan,crossref,brownfield`.
- **`bin/lint.sh add_finding()` 4-tuple** (Phase 9 D-04) — applied.log block schema mirrors this structure loosely (markdown blocks with rigid key-value lines).
- **`bin/release.sh --dry-run` / `--apply` pattern** (Phase 7) — structural precedent for 01-page-typing `--apply` + verify `--promote`.
- **`bin/ingest.sh` BRWN-10 strip** (Phase 10) — single integration point; no Phase 11 changes.
- **`bin/check-privacy.sh`** (Phase 9) — public-paths-only; NOT called by verify on vault content. Shows that privacy checking is a separate concern; D-13 respects this boundary.
- **`tests/phase-10/` harness** (`run.sh`, `lib.sh`, fixtures, `BROWNFIELD_FIXTURE_TODAY`/`BROWNFIELD_FIXTURE_CREATED_AT` env vars) — pattern-clone for `tests/phase-11/` with 10→11 rename only.
- **Phase 08-01 / 08-05 byte-equality fixture pattern** (`schema/fixtures/` + LF-pinned `.gitattributes`) — precedent for `schema/brownfield/migrations/*.sh` byte-identical-copy test.
- **Python `difflib.unified_diff`** (Phase 8 D-18) — reusable for review-typing `inspect` per-page diff display.
- **`bin/sync-claude.sh` + pre-commit hook** — AGENTS.md §11.5 edit auto-syncs to CLAUDE.md; stage cleanly per Phase 9.1 R-3 precedent (`bash bin/sync-claude.sh && git add CLAUDE.md` before commit).

### Established Patterns

- **Mechanical-first, human-review-second** — Phase 11 is the apex application: scripts do deterministic work; judgment lives in manifests edited by humans (with optional AI assistance outside the CLI).
- **Safe-by-default dry-run + explicit `--apply`** — Phase 7 `bin/release.sh` + Phase 10 `bootstrap` precedent; 01-page-typing + 02-provenance-bootstrap follow; verify adds `--promote` variant.
- **Narrowly-scoped sentinel fields** — Phase 7 `example: true`, Phase 10 `bootstrap_stage`/`bootstrap_date`. Phase 11 introduces NO new sentinels (BRWN-15 hard lock).
- **Pattern-twin stderr-warn** — Phase 9 `.git-author-map.txt` miss-warn + Phase 10 BRWN-10 ingest-strip warn; extended to D-12's 02 soft prereq readiness warn.
- **Hardcoded array + user-override config file** — Phase 7 `PUBLIC_PATHS` + Phase 9 `.git-author-map.txt` + Phase 10 `.brownfield-ignore` pattern; extended by Phase 11's optional `.brownfield-privacy-terms.txt` (04 user-authored terms) and FUTURE `.brownfield-privacy-cloudsafe.txt` (not in v1.1).
- **Byte-exact fixture gold files** — Phase 8-01 + Phase 10-03 dual golden-artifact contract extended to Phase 11's migration-script byte-identity copy test.
- **Zero new runtime deps** — Phase 11 introduces NO new deps beyond Phase 10's ruamel.yaml. Bash + python3 + ruamel.yaml + PyYAML + stdlib only.
- **Review manifest pattern (NEW to Phase 11)** — apply-class script emits candidates.yaml + decisions.yaml (pending); separate review surface (TTY + AI handoff) edits decisions; script `--apply` reads decisions deterministically. Not adopted by 02/03/04.

### Integration Points

- **New subcommand branches in `bin/brownfield.sh`:** `suggest`, `review-typing`, `verify`. Current exit-2 gates at lines 53–56 replaced with real implementations.
- **New directory (tracked in git):** `schema/brownfield/migrations/` — canonical migration scripts; four files.
- **New test harness:** `tests/phase-11/run.sh` + `lib.sh` + `fixtures/` (5 fixtures per D-20).
- **Extended `.brownfield/` artifacts (all gitignored per TMPL-04):** `migrations/*.sh` (byte-copies), `page-typing-candidates.yaml`, `page-typing-decisions.yaml`, `provenance-bootstrap-report.yaml`, `cross-link-candidates.yaml`, `privacy-findings.yaml`, `review-typing-prompt.md`, `applied.log`. `REPORT.md` and `APPLIED.md` unchanged from Phase 10 (REPORT.md gains new `## Cross-link candidates` + `## Privacy review` sections).
- **Modified:** `bin/brownfield.sh` (suggest + review-typing + verify branches; `applied.log` writer helpers).
- **Modified:** `bin/lib/brownfield_classify.py` (clustering function; inbound-link density usage in 01-page-typing flow).
- **Possibly new:** `bin/lib/brownfield_typing.py` or similar if 01-page-typing discovery/clustering/apply-from-manifest logic needs its own module (planner's call per D-18 discretion).
- **Possibly new:** `bin/lib/brownfield_provenance.py` for 02-provenance-bootstrap bullet-eligibility heuristics (planner's call).
- **Modified:** `AGENTS.md §11.5` (full populate per D-16).
- **Modified (auto-sync):** `CLAUDE.md` (pre-commit hook).
- **Modified:** `schema/AGENTS.template.md` (mirror §11.5 per template-parity test).
- **Modified:** `schema/fixtures/canonical-AGENTS.md` (regenerate).
- **Modified:** `docs/reference/brownfield.md` (suggest + review-typing + verify sections).
- **Modified:** `.planning/REQUIREMENTS.md` (BRWN-12 rename amendment; new REQ-ID for review-typing; post-VERIFICATION checkbox flips).
- **New:** `wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md` (Tier-1 DR per D-21).
- **No changes:** `bin/ingest.sh` (BRWN-10 already integrated in Phase 10), `bin/lint.sh` (verify is a wrapper, not an extension; unless planner chooses to add a new `brownfield-review` sub-category for pending-review-decision counting), `bin/release.sh`, `bin/check-neutrality.sh`, `bin/check-privacy.sh`, `bin/init-wizard.sh`, `bin/sync-claude.sh`, `bin/requirements-sync.sh`, `bin/validate-op.sh`, `bin/search.sh`.

</code_context>

<specifics>
## Specific Ideas

- **Design principle (quote verbatim in AGENTS.md §11.5 + docs + decision record):** *"Review may be interactive and AI-guided; apply must always be deterministic."*
- **Review-architecture principle:** *"Check readiness, not history."* Use current vault state for prereq checks, never `applied.log`.
- **02-provenance-bootstrap contract (quote verbatim in script `--help` + docs):** *"Marks top-level bullets under `## TL;DR` and `## Key Facts` with `[epistemic:: inferred]` when the bullet looks claim-like, is not already tagged, and is not a link-only, source-list, question, task, or placeholder bullet. Never touches Detail. Reports honestly when no eligible bullets are found."*
- **04-privacy-review contract (quote verbatim in script `--help` + docs):** *"04-privacy-review classifies findings for review priority, not for frontmatter mutation. Fail-closed `privacy: local_only` is preserved; only a human (via frontmatter edit) may downgrade."*
- **applied.log apply-block example (normative schema — planner matches this exactly):**
  ```markdown
  ## 01-page-typing.sh @ 2026-04-19T14:22:31Z
  mode: apply
  op_hash: sha256:abc123...
  exit_code: 0
  prereq_check: pass
  inputs:
  - .brownfield/page-typing-candidates.yaml @ sha256:def456...
  - .brownfield/page-typing-decisions.yaml @ sha256:789abc...
  files_touched: 12
  files_created: 0
  files_updated: 12
  files_skipped: 4
  changes:
  - wiki/concepts/foo.md | updated | type: "" -> concept
  - wiki/entities/bar.md | updated | type: "" -> entity
  summary:
  - approved_clusters: 3
  - overridden_pages: 2
  - pending_pages_remaining: 5
  ```
- **applied.log advisory-block example (normative schema):**
  ```markdown
  ## 04-privacy-review.sh @ 2026-04-19T14:31:02Z
  mode: advisory
  op_hash: sha256:...
  exit_code: 0
  prereq_check: pass
  mutations: none
  report_section: REPORT.md#privacy-review
  summary:
  - pages_scanned: 184
  - findings: 17
  - high_risk_findings: 3
  ```
- **02-provenance-bootstrap WARN phrasing (for D-12 state-based prereq):** *"WARN: 37 bootstrapped pages still have empty type:. 02-provenance-bootstrap works best after page typing review or on pages with existing valid type. Proceeding anyway."*
- **Candidate-file metadata header shape (normative):**
  ```yaml
  # ---
  # schema_version: 1
  # tool_version: <suggest version constant>
  # generated_at: <UTC ISO timestamp>
  # vault_root: <absolute path>
  # source_script_hash: <sha256 of the canonical script the data backs>
  # ---
  ```
- **op_hash header shape (normative):**
  ```bash
  # op_hash: sha256:abc123...
  # op_hash_scope: canonical-script-body + data-schema-version
  ```
- **review-typing cluster prompt primitives:** `approve all` / `reject all` / `inspect individual pages` / `override selected pages`. No fancy TUI; line-oriented; survives non-interactive CI via scripted stdin.
- **review-typing AI-handoff prompt shape (directive, lean):** "Open `.brownfield/page-typing-candidates.yaml` and `.brownfield/page-typing-decisions.yaml`. Explain tradeoffs between entity/concept/overview for each pending cluster. Help the user decide cluster policy + page-level overrides. Edit ONLY the decisions manifest. Do not modify vault pages. When done, the user runs `bash .brownfield/migrations/01-page-typing.sh --apply`."
- **bootstrap_stage lifecycle diagram (normative for §11.5 + docs):**
  ```
  (absent) --[bin/brownfield.sh bootstrap --apply]--> bootstrapped
  bootstrapped --[bin/brownfield.sh verify --promote, per-page gate passes]--> verified
  bootstrapped --[bin/ingest.sh on normal ingest]--> (stripped per BRWN-10)
  verified --[no automatic downgrade; manual edit only]--> (absent | bootstrapped)
  raw --[reserved for future import workflows; no writer in v1.1]--> (no transition)
  ```
- **Pre-plan flag for planner:** REQUIREMENTS.md BRWN-12 wording amendment + new REQ-ID for `review-typing`. Planner drafts wording before Plan 11-05 lands.

</specifics>

<deferred>
## Deferred Ideas

- **Single-command `brownfield apply` chain-runner** — v1.2 BRWNAPPLY-01 (already roadmap-backlogged). Per-class user invocation is the v1.1 posture.
- **Runtime-specific skills** (`.claude/skills/brownfield-review-typing.md`, Codex equivalents) — defer until after the 999.4 v1.2 markdown-authoritative-refactor lands. Phase 11 ships the markdown artifact (`review-typing-prompt.md`); skill wrappers are a later thin layer.
- **Manifest-backed apply for 03-cross-link-inference** — v1.1 ships report-only; if real-world usage shows candidate quality is good enough, future phase can add `cross-link-decisions.yaml` + apply. Same pattern as 01-page-typing.
- **Manifest-backed apply for 04-privacy-review** — v1.1 ships advisory-only. Future: user-authored `.brownfield-privacy-cloudsafe.txt` allowlist as explicit human policy; scanner still never auto-promotes. Adds a second new config file (matches `.brownfield-ignore` pattern).
- **Page-level opt-out file for 02-provenance-bootstrap** (`.brownfield/02-exclude.txt`) — only add if real-world usage shows heuristic noise on specific pages.
- **`--force` on `suggest` to regenerate stale candidate files** — metadata-header `source_script_hash` drift detection is enough for v1.1; force regeneration is noise until a user hits the case.
- **`--format json` flag on `applied.log`** — markdown is enough for v1.1; future JSON mode if a CI/audit consumer emerges.
- **Separate `brownfield-review.sh` helper** (pulled out of `bin/brownfield.sh`) — the orchestrator fits cleanly as a `brownfield` subcommand; only factor out if review surfaces for 03/04 get promoted to manifest-backed apply later.
- **`bin/brownfield.sh status` / `bin/brownfield.sh list` introspection** — `.brownfield/applied.log` + `REPORT.md` cover v1.1 audit needs.
- **Interactive TUI with arrow keys + previews** — research Bucket 5 explicit anti-feature; CLI + manifest hit the same need with less code.
- **Obsidian plugin wrapper for `bin/brownfield.sh suggest`** — v2 PLUGIN-01.
- **Multi-vault brownfield (scan+bootstrap+suggest across multiple vaults at once)** — v1.1 assumes single-vault-per-repo.
- **`run_hash` (op_hash + input hashes)** — not needed in v1.1; applied.log input-hash fields cover auditability. Add later if a consumer wants a single fingerprint.
- **Auto-downgrade `verified` → `bootstrapped`** when a page's structural invariants break (e.g., `type:` removed) — fail-closed manual-edit-only posture per D-15 is the v1.1 contract.
- **Pre-flight `ruamel.yaml` version check inside `bin/brownfield.sh`** — already in place from Phase 10; Phase 11 inherits without changes.
- **Extending `bin/lint.sh` with a `brownfield-review` sub-category** for counting pending review decisions — planner may add this inside `bin/lint.sh` brownfield category (established in Phase 10) if it helps verify cleanly report "what blocks promotion." Discretionary.
- **LLM integration inside `bin/brownfield.sh`** — explicit anti-feature per BRWN-16 + research Bucket 5. AI assistance operates on artifacts from outside the CLI.
- **Runtime-detected shell completion (`bash complete`, `zsh compdef`) for `brownfield` subcommands** — nice-to-have; not v1.1.
- **Phase 10 WR-01/WR-02/WR-03 warnings** — opportunistic fixes during Plan 11-05 if the same surface is touched (e.g., §5 forward-ref typo from WR-03); otherwise deferred per verifier disposition.

</deferred>

---

*Phase: 11-brownfield-suggest-verify*
*Context gathered: 2026-04-19*
