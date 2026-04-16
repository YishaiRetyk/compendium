# Phase 10: Brownfield Scan + Bootstrap - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `bin/brownfield.sh` with two subcommands — `scan` (dry-run inventory + provisional classification, writes `.brownfield/REPORT.md`, zero vault mutation) and `bootstrap` (idempotent mechanical transforms: sentinel frontmatter with the typed-merge policy, SHA hashing of existing source summary pages, `index.md`/`log.md` skeletons if absent, YAML round-trip via `ruamel.yaml`). Plus: add `bootstrap_stage` + `bootstrap_date` rows to AGENTS.md §5 field-descriptions table (narrowly scoped brownfield sentinel, NOT a provenance substitute); extend `bin/lint.sh` with the BRWN-08 downgrade (error→info on the allowlist when `bootstrap_stage: bootstrapped`) and a new `brownfield` category covering BRWN-09 30-day staleness; extend `bin/ingest.sh` with BRWN-10 strip + stderr warn; ship byte-exact fixture tests in `tests/phase-10/` covering both transformed-output and skip/report-artifact contracts.

**Out of scope for Phase 10 (→ Phase 11):** `bin/brownfield.sh suggest`, `bin/brownfield.sh verify`, all four staged migration scripts (`01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-classification.sh`), authoritative page-typing mutations, cross-link inference, privacy auto-classification, AGENTS.md §11.5 full populate.

**Out of scope for Phase 10 (→ Phase 12):** Obsidian render verification, Codex agent-parity run, write-back scenario re-run.

**Out of scope entirely:** Single-command `brownfield apply` chain-runner (deferred to v1.2 BRWNAPPLY-01 per REQUIREMENTS.md), LLM calls inside `brownfield.sh` (explicitly anti-feature per research Bucket 5), source-summary page creation during bootstrap (crosses from scaffolding into content-layer intervention).

</domain>

<decisions>
## Implementation Decisions

### Area 1 — YAML safety + backup posture

- **D-01 (Parse-failure handling):** Pre-flight `yaml.safe_load` per file. On parse failure → append structured entry to `.brownfield/SKIPPED.md` (path + parse error), do not mutate, continue with remaining files. End-of-run summary prints counts: parsed / bootstrapped / skipped / next-action-review. No mechanical YAML repair attempted. Research C-2 prevention #2.
- **D-02 (Typed merge policy for key collisions on parseable frontmatter — three field classes):**
  - **Class A — safe-additive** (`tags`, `aliases`, `sources`, simple-scalar `status`): preserve existing value, inject sentinel only where the key is absent.
  - **Class B — schema-authoritative** (`type`, `epistemic_status`, `knowledge_domain`, `privacy`, `bootstrap_stage`): preserve existing value, **never overwrite**; log to `.brownfield/REPORT.md` as a warning when the existing value is missing, malformed, or noncanonical. Semantic correction is `suggest`/`lint`'s job, not bootstrap's.
  - **Class C — structural hard failure** (unparseable YAML, non-mapping frontmatter, detectable duplicate YAML keys, intent-guessing required): skip → `.brownfield/SKIPPED.md`.
- **D-03 (Per-file flow):** ruamel.yaml read → preserve all existing keys + formatting (comments, key order, quoting) → inject only absent required keys → record preserved collisions and schema-authoritative warnings to REPORT.md → write only if the operation is structurally safe.
- **D-04 (REPORT.md section structure):** Four sections for parseable files: (a) bootstrapped-successfully, (b) bootstrapped-with-preserved-collisions, (c) bootstrapped-with-schema-warnings. Plus a (d) "Needs human judgment" tail for `unknown` classifications from `scan` mode (same file is used for both subcommands' reports; subcommand-specific sections are clearly headered).
- **D-05 (SKIPPED.md scope):** Scoped narrowly to parse-failure + unsafe-structure files only. Separate from REPORT.md so reviewers can triage unparseable files independently.
- **D-06 (Backup / undo):** Git is the canonical backup. Bootstrap writes `.brownfield/APPLIED.md` as an execution manifest (every touched file + timestamp + outcome). `docs/reference/brownfield.md` documents `git reset --hard <sha>` as the canonical undo procedure. No per-file `.orig` copies. Rationale: repo already assumes git; duplicated recovery semantics create drift.
- **D-07 (Byte-exact fixture suite for BRWN-21):** 6 fixtures — clean-frontmatter, no-frontmatter, tabs-in-yaml, CRLF, Dataview-inline, frontmatter-with-comments. **Golden fixture contract covers BOTH shapes:** byte-exact transformed-output for parseable fixtures AND byte-exact skip/report-artifact (SKIPPED.md entry + unmutated file) for unparseable fixtures. `tabs-in-yaml` in particular (if ruamel.yaml treats it as unparseable) validates the skip-artifact path, not a transformed-file path. CI greens only on byte-exact match across all 6.

**Decision boundary (quote verbatim in runbook docs):** *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."*

### Area 2 — Dry-run vs apply default

- **D-08 (Default posture):** `bin/brownfield.sh bootstrap` defaults to dry-run. `--apply` flag required to write. No `--assume-yes` / `--force` for v1.1. Matches `bin/release.sh` Phase 7 precedent. `scan` is always dry-run by definition (BRWN-01).
- **D-09 (Dry-run output shape):** Default stdout = counts (parsed / would-bootstrap / collisions / schema-warnings / skipped) + list of files that would change + path to `.brownfield/REPORT.md`. `--verbose` flag adds per-file unified diffs (`diff -u <original> <would-be-result>`). Report file is written on dry-run AND apply so users can review between runs.
- **D-10 (Re-run idempotency semantics):** Per-file state-check via `bootstrap_stage` sentinel; files with `bootstrap_stage: bootstrapped` are skipped silently on re-run. APPLIED.md is appended to with a new timestamped run-block (not overwritten). Zero-byte diff on clean re-run (validated by BRWN-21 fixture test). Matches BRWN-03 "running twice is a no-op."
- **D-11 (Write-failure mid-apply semantics):** Halt on first hard write failure (disk full, permission denied, unexpected ruamel.yaml raise). APPLIED.md records the successful-before + failure + untouched-remainder. Exit non-zero. User chooses between `git reset --hard` rollback or fix-and-rerun (per-file idempotency D-10 ensures fix-and-rerun skips the successful-before files). No auto-rollback by bootstrap itself (git working tree may have unrelated user changes).

### Area 3 — Sentinel shape

- **D-12 (Minimal sentinel):** `bootstrap_stage: bootstrapped` alone. No content-hash sentinel field. Presence = bootstrapped; absence = not. Per-file idempotency check is frontmatter-only. Consistent with zero-claim-level-schema-expansion ethos (BRWN-07, BRWN-15).
- **D-13 (Age tracking for BRWN-09):** New `bootstrap_date: YYYY-MM-DD` field injected alongside `bootstrap_stage`. `bin/lint.sh` brownfield-category 30-day-stale calculation reads this field deterministically (survives shallow clones and unrelated edits). Single-purpose, narrowly-scoped like `bootstrap_stage`.
- **D-14 (Empty-value sentinel set for no-frontmatter pages):** Full AGENTS.md §5 required base-fields set with empty/default values, **minus anything mechanically inferrable**:
  - **Inferred (mechanical):** `id: <filename-without-ext-kebab-cased>`, `title: <H1 if present else filename>`, `created_at: <file mtime>`, `updated_at: <today>`.
  - **Empty defaults (conservative — scaffolding, not interpretation):** `type: ""`, `summary: ""`, `knowledge_domain: ""`, `sources: []`, `tags: []`, `domains: []`, `aliases: []`, `supersedes: null`, `superseded_by: null`.
  - **Fixed defaults:** `status: active`, `epistemic_status: tentative` (signals "not LLM-sourced"), `privacy: local_only` (fail-closed per AGENTS.md §13), `has_contradictions: false`.
  - **Brownfield-specific:** `bootstrap_stage: bootstrapped`, `bootstrap_date: <today>`.
  - **Rule:** **scaffolding, not interpretation**. Never invent semantic categories like `knowledge_domain: imported` — that would pollute the §6 decay model.
- **D-15 (Source-file hashing scope per BRWN-04):** Bootstrap updates `content_hash` only on **existing** `wiki/sources/*.md` summary pages (the field already belongs there per AGENTS.md §5 source-summary schema). **Orphan raw sources** (files under `sources/` with no matching summary page in `wiki/sources/`) are logged to REPORT.md as `"needs summary — handoff to Phase 11 suggest/01-page-typing.sh"`. Bootstrap never creates new wiki pages; summary-page creation is judgment-adjacent and Phase 11's responsibility. No arbitrary-markdown hashing (non-source pages have no `content_hash` field; injecting one would be schema-invalid).

### Area 4 — Scan classification + confidence

- **D-16 (Classification rule set — 4 signals, rule-based, no LLM):**
  1. **Existing frontmatter `type:`** — authoritative if present and valid per AGENTS.md §4.
  2. **Filename convention** — PascalCase or proper-noun → entity; date-prefixed (`YYYY-MM-DD-*`) → journal/source; `src-*` prefix → source summary; `vs-*` / `X-vs-Y` → comparison.
  3. **H1 + section-heading structure** — presence of `## Extracted Claims` + `## Source Metadata` → source summary; `## Comparison Table` → comparison; `## TL;DR` + `## Key Facts` + `## Detail` → entity/concept (disambiguate via signal 4).
  4. **Inbound/outbound wikilink density** — outbound-heavy + abstract framing → concept; inbound-heavy + proper-noun-like title → entity.
  Reusable by Phase 11's `01-page-typing.sh` — the rule set is authored once and consumed by both `scan` (inform) and `01-page-typing.sh` (apply).
- **D-17 (Confidence signal shape in REPORT.md):** Per-page output = categorical label (`high` / `medium` / `low` / `unknown`) **plus** short signal trace. Example: `confidence: medium | signals: frontmatter=none, filename=pascalcase, h1=entity-like, links=outbound-heavy`. Mapping rule: `high` = 3+ signals agree OR explicit frontmatter `type:` is valid; `medium` = 2 signals agree; `low` = 1 signal, ambiguous; `unknown` = 0 signals match or signals conflict across candidate types. Headline label for scanning + trace for reviewability.
- **D-18 (`unknown` page framing in REPORT.md):** One-line concise prose per page, phrased as an open question directed at the user. Example: ``vault/musings.md`` — `no type frontmatter; filename matches no convention; 0 inbound wikilinks; body has no section-heading signals. Is this a journal entry, an overview, or something else?`. Grouped at the bottom of REPORT.md under a "Needs human judgment" section. Not machine-structured JSON — prose invites user judgment without anchoring via pre-filled type suggestions.
- **D-19 (Obsidian-quirk exclusions):** Built-in denylist by default + user override via `.brownfield-ignore` gitignore-style file at repo root:
  - **Built-in defaults:** `.obsidian/**`, `.trash/**`, `templates/**`, `attachments/**`, daily-note filename patterns (`YYYY-MM-DD.md` at root or under `daily/`, `journal/`; optionally a few common Obsidian daily-note plugin patterns).
  - **User override:** `.brownfield-ignore` (same grammar as `.gitignore`); lines prefixed with `!` un-exclude from the built-in denylist.
  - **REPORT.md behavior:** scan reports excluded counts per exclusion rule (e.g., "excluded 47 files under `.obsidian/**`") — not per-file spam. Users who want the full list can pass `--list-excluded`.

### Area 5 — AGENTS.md §5 `bootstrap_stage` documentation scope

- **D-20 (Inline row in field-descriptions table):** Add one row to the AGENTS.md §5 "Field Descriptions" table for `bootstrap_stage` (and a second for `bootstrap_date`). Description wording should:
  - Name the narrow scope: "Brownfield onboarding sentinel."
  - State the enum: `raw | bootstrapped | verified`.
  - Call out the explicit contrast: "NOT a substitute for claim-level provenance (see §6 PROV-01..05)."
  - Note BRWN-10 strip: "Stripped by `bin/ingest.sh` on normal ingest."
  - Optional: forward-ref to §11.5 (populated in Phase 11).
  Matches the Phase 7 `example: true` pattern — single row, dense description, pointer to deeper docs. No dedicated §5 subsection (§5 is already long). CLAUDE.md auto-syncs via pre-commit hook per Phase 7 D-03.

### Area 6 — `bin/ingest.sh` strip behavior (BRWN-10)

- **D-21 (Strip + stderr warn):** When `bin/ingest.sh` reads a page with `bootstrap_stage` present, it strips the field during frontmatter merge and emits a one-line stderr warning: `"Note: stripped bootstrap_stage=<value> from <path> during ingest (brownfield-scoped field; see AGENTS.md §5)."` Silent-but-observable. Matches Phase 9 `.git-author-map.txt` miss-warn precedent (D-21 of Phase 9). Does NOT refuse ingest — brownfield-bootstrapped pages remain ingestable via normal flow; the strip prevents pollution per BRWN-10.

### Area 7 — docs/reference/brownfield.md content scope for Phase 10

- **D-22 (Scan + bootstrap complete; suggest + verify stubbed):** Phase 10 writes `docs/reference/brownfield.md` with:
  - **Complete sections:** Overview / prerequisites (ruamel.yaml install + git precondition) / scan subcommand (flags, output contract, exclusion model) / bootstrap subcommand (flags, dry-run posture, typed-merge policy, failure modes, git-reset undo recipe) / mechanical-vs-judgment boundary explainer.
  - **Stubbed sections (Phase 11 populates):** suggest subcommand / four staged migration scripts / verify subcommand / end-to-end runbook. Each stub is one paragraph with `[Populated in Phase 11]` marker and forward-ref to the relevant BRWN-* REQ-IDs.
  Matches Phase 7→9 `docs/reference/ci.md` pattern (stubbed in 7, fully populated in 9).

### Claude's Discretion

- Exact bash flag parsing patterns for `bin/brownfield.sh` subcommands — match existing `bin/lint.sh` / `bin/release.sh` conventions.
- Internal Python module structure for the ruamel.yaml round-trip + classifier (inline Python3 heredoc in bash vs extracted helper module under `bin/lib/`) — planner's call; must be unit-testable and importable by Phase 11's `01-page-typing.sh`.
- Exact shape of the `.brownfield-ignore` parser (gitignore-grammar subset scope — full glob support vs literal path prefixes; negation support) — planner's call; recommend full gitignore parity via `pathspec` Python module or equivalent.
- Stdout color/styling conventions (TTY detection, `NO_COLOR` env-var) — inherit Phase 8 D-20 pattern.
- Exact lint downgrade mechanism (how `bin/lint.sh` discovers `bootstrap_stage: bootstrapped` and applies the BRWN-08 allowlist error→info demotion) — planner's call; recommend per-page frontmatter auto-detect (same severity-remap dispatcher as Phase 9 `--ci`; adds a "downgrade-if-bootstrapped" modifier to the existing map). New `brownfield` lint category for BRWN-09 counts + 30-day warnings uses the same dispatcher.
- Plan count + wave structure — research suggests ~3 plans for Bucket 5 as a whole; Phase 10 covers scan + bootstrap only. Likely 3 plans: (a) Wave-0 test harness + 6 fixtures + `tests/phase-10/run.sh`; (b) `bin/brownfield.sh scan` + classification rules + `.brownfield-ignore` parser + REPORT.md writer; (c) `bin/brownfield.sh bootstrap` + typed-merge policy + APPLIED.md/SKIPPED.md writers + idempotency logic + AGENTS.md §5 edit + `bin/ingest.sh` strip + `bin/lint.sh` brownfield-category + BRWN-08 downgrade + `docs/reference/brownfield.md` write. Planner decides the actual split; may want to pull AGENTS.md §5 + `bin/lint.sh` + `bin/ingest.sh` edits into their own plan for reviewability.
- Where the classification rules live (inline in `bin/brownfield.sh` python3 block vs extracted to `bin/lib/brownfield_classify.py`) — extraction preferred if it survives to Phase 11's `01-page-typing.sh`; planner's call.
- Exact error-message wording across new flags and failure modes — must be actionable, point at the relevant doc section, and stay under 80 columns.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements (authoritative scope)

- `.planning/ROADMAP.md` §Phase 10 — goal, prerequisite dependency (ruamel.yaml), dependencies (Phase 7 `EXCLUDE_DIRS` + §5 schema; Phase 9 `bin/lint.sh --ci` severity policy), success criteria 1–5, full REQ-ID list (BRWN-01..10, BRWN-21).
- `.planning/REQUIREMENTS.md` §BRWN (lines 85–106, 112) — BRWN-01 through BRWN-10 plus BRWN-21; traceability table lines 217–227.
- `.planning/PROJECT.md` §Constraints — agent-agnostic, file-based, Obsidian-first, local-only. §Current Milestone — brownfield as the "single highest-risk surface area in v1.1."
- `.planning/MILESTONES.md` — v1.1 Shareability framing.
- `.planning/STATE.md` §Blockers/Concerns — ruamel.yaml vs PyYAML spike resolved in prior discussion; accepted as single new runtime dep.

### Prior Phase Contexts (locked upstream decisions)

- `.planning/phases/07-neutral-template-foundation/07-CONTEXT.md` — D-03 (CLAUDE.md byte-sync via pre-commit hook), D-04 (`--dry-run`/`--apply` safety posture for `bin/release.sh`), `PUBLIC_PATHS` hardcoded-array convention, allowlist staging pattern.
- `.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md` — D-18 (Python `difflib` unified-diff pattern reusable for `--verbose` diffs), D-20 (TTY/NO_COLOR convention for stderr), canonical-fixture pattern (`schema/fixtures/` + byte-equality CI).
- `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md` — D-02 (lint `--ci` severity-remap dispatcher — extended here by the BRWN-08 downgrade), D-11 (`--strict` as separate CI job), D-20/D-21 (auto-detect + stderr-warn pattern reused by BRWN-10 strip), test harness pattern (`tests/phase-09/lib.sh` `make_fixture_repo` / `setup_git_author`).
- `.planning/phases/09.1-progressive-disclosure-extraction/09.1-CONTEXT.md` — extraction-invariant test pattern reusable for §5 AGENTS.md edit verification.

### Research (informs architecture; not re-litigated)

- `.planning/research/FEATURES.md` §Bucket 5 (lines 178–232) — table stakes, differentiators, anti-features, plan breakdown, integration with v1.0 primitives.
- `.planning/research/PITFALLS.md` §C-2 (lines 40–64) — silent frontmatter corruption + 6 prevention items (underpins D-01, D-02, D-03, D-06, D-07).
- `.planning/research/PITFALLS.md` §C-3 (lines 68–90) — idempotency violations + 4 prevention items (underpins D-10, D-12, D-13).
- `.planning/research/PITFALLS.md` §M-9 (line 288+) — H1 title detection pitfalls (underpins D-16, D-19).
- `.planning/research/STACK.md` — bash + python3 + PyYAML baseline; ruamel.yaml accepted as the single new v1.1 dep for brownfield only.
- `.planning/research/SUMMARY.md` — milestone-wide synthesis.

### Existing Code Surface (read before editing)

- `bin/lint.sh` (current HEAD) — add BRWN-08 downgrade logic (per-page frontmatter auto-detect; error→info on allowlist when `bootstrap_stage: bootstrapped`); add new `brownfield` category (BRWN-09 counts + 30-day staleness warning from `bootstrap_date`); extend the Phase 9 severity-remap dispatcher.
- `bin/ingest.sh` (current HEAD) — add BRWN-10 strip: on frontmatter merge, remove `bootstrap_stage` + `bootstrap_date` if present; emit one-line stderr warning per strip.
- `bin/release.sh` (Phase 7) — `--dry-run` / `--apply` split + APPLIED.md manifest precedent; `bin/brownfield.sh bootstrap` mirrors this posture.
- `bin/check-neutrality.sh` / `bin/check-privacy.sh` (Phase 7/9) — pattern-twin for single-purpose mechanical scripts; `bin/brownfield.sh` is larger (subcommand dispatch) but internal subcommands should feel sibling-y.
- `bin/sync-claude.sh` + `.githooks/pre-commit` — AGENTS.md → CLAUDE.md byte-sync; must re-stage cleanly after §5 `bootstrap_stage` row edit.
- `bin/init-wizard.sh` (Phase 8) — git precondition already enforced; bootstrap inherits this assumption.
- `tests/phase-09/run.sh` + `lib.sh` — test harness pattern (`make_fixture_repo`, `setup_git_author`, `seed_origin_main_ref`) for `tests/phase-10/`.

### Schema / Docs Touch Points

- `AGENTS.md §5` — add rows for `bootstrap_stage` + `bootstrap_date` in the field-descriptions table per D-20. CLAUDE.md auto-syncs.
- `AGENTS.md §6` — referenced by D-20 wording (contrast with claim-level provenance PROV-01..05). No change.
- `AGENTS.md §11` — §11.5 stubbed/reserved but full populate is Phase 11. Phase 10 must not add workflow prose that Phase 11 will rewrite.
- `AGENTS.md §13` — referenced by D-14 `privacy: local_only` fail-closed default. No change.
- `docs/reference/brownfield.md` — Phase 7 stub; Phase 10 populates scan + bootstrap sections per D-22; Phase 11 populates suggest + verify.
- `docs/quickstart.md` — add prerequisite line: "Brownfield onboarding requires Python 3 with `ruamel.yaml` installed (`pip install ruamel.yaml` or distro package). Not needed for greenfield users."
- `docs/reference/index.md` — verify `brownfield.md` is linked.
- `.gitignore` — verify `.brownfield/` is already excluded per TMPL-04 (Phase 7); add `.brownfield-ignore` as a tracked-but-optional user config file (not in .gitignore).
- `wiki/index.md` — no edit needed for Phase 10.
- `.planning/REQUIREMENTS.md` — traceability checkboxes flipped post-VERIFICATION per DEBT-03 (not a Phase 10 mutation).

### External Specs (planner reference)

- ruamel.yaml round-trip API — <https://yaml.readthedocs.io/en/latest/> — specifically `YAML(typ='rt')` mode for comment/key-order preservation.
- gitignore glob grammar — <https://git-scm.com/docs/gitignore> — reference for `.brownfield-ignore` parser scope.
- `pathspec` Python library (optional) — <https://pypi.org/project/pathspec/> — pre-written gitignore-grammar parser if planner chooses to add a helper (note: this would be a 2nd new dep; weigh vs inline implementation).
- no-color.org — `NO_COLOR` env-var convention (inherited from Phase 8 D-20).

### Requirements Amendment Hook (from discussion)

The typed-merge policy (D-02) materially changes the "mechanical transforms only" framing in BRWN-04. Planner should flag this at research/plan time as a candidate REQUIREMENTS.md BRWN-04 / BRWN-08 / Phase 10 success-criterion 2 wording amendment. User explicitly offered to help draft the exact revised wording when ready.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`bin/lint.sh` severity-remap dispatcher** (Phase 9 D-02) — extend with BRWN-08 downgrade modifier; no new mechanism.
- **`bin/lint.sh` category enum + `--category` / `--skip-category`** (Phase 9) — add `brownfield` category for BRWN-09 counts + 30-day staleness.
- **`bin/lint.sh add_finding()` 4-tuple** (Phase 9 D-04) — JSON contract already established; brownfield findings slot in with `category: "brownfield"`.
- **`bin/release.sh --dry-run` / `--apply` pattern** (Phase 7) — structural precedent for `bin/brownfield.sh bootstrap`.
- **`.brownfield/APPLIED.md` manifest pattern** — analogue to `bin/release.sh`'s staging-area manifest; simpler because bootstrap writes in-place and doesn't need atomic staging.
- **`bin/ingest.sh` frontmatter merge point** (Phase 9 COLAB integration point) — single site for BRWN-10 strip + stderr warn.
- **`bin/check-neutrality.sh` hardcoded-array convention** — structural twin for `.brownfield-ignore` built-in denylist defaults (but with user-override extension).
- **`tests/phase-09/` harness** (`run.sh`, `lib.sh`, `make_fixture_repo`, `setup_git_author`) — clone to `tests/phase-10/` with 09→10 rename only.
- **Phase 08-01 / 08-05 byte-equality fixture pattern** (`schema/fixtures/` + LF-pinned `.gitattributes`) — precedent for the 6 brownfield fixtures in `tests/phase-10/fixtures/`.
- **Python `difflib.unified_diff`** (Phase 8 D-18) — reusable for `--verbose` per-file diffs.
- **`bin/sync-claude.sh` + pre-commit hook** — Phase 7 D-03; AGENTS.md §5 edit auto-syncs to CLAUDE.md.

### Established Patterns

- **Mechanical-first, human-review-second** — brownfield is the single biggest application of this principle in v1.1; bootstrap does only mechanical transforms, `suggest` handles judgment (Phase 11).
- **Safe-by-default dry-run + explicit `--apply`** — Phase 7 `bin/release.sh` precedent; extended to `bin/brownfield.sh bootstrap` per D-08.
- **Hardcoded array + user-override config file** — Phase 7 `PUBLIC_PATHS` (neutrality) + Phase 9 `.git-author-map.txt` (contributor) pattern; extended by `.brownfield-ignore` built-in denylist + user override per D-19.
- **Narrowly-scoped sentinel fields** — Phase 7 `example: true`, Phase 10 `bootstrap_stage` + `bootstrap_date`. Each gets one AGENTS.md §5 table row; no semantic sprawl.
- **Pattern-twin stderr-warn** — Phase 9 `.git-author-map.txt` miss-warn; extended to BRWN-10 ingest strip per D-21.
- **Typed merge over blanket skip** — novel to Phase 10 (no prior precedent). Three-class field taxonomy (Class A safe-additive, Class B schema-authoritative, Class C structural hard failure) formalized in D-02.
- **Zero new runtime deps except ruamel.yaml** — brownfield is the only v1.1 path that breaks the bash + python3 + PyYAML baseline; all other phases remain bash-native.
- **Byte-exact fixture gold files** — Phase 8-01 canonical-answers → canonical-AGENTS.md pattern extended to Phase 10's 6 brownfield fixtures with dual golden-artifact contract (transformed-output + skip-report) per D-07.

### Integration Points

- **New script:** `bin/brownfield.sh` with two subcommands (`scan`, `bootstrap`). `suggest` + `verify` subcommand stubs may be included as `not yet implemented — see Phase 11` exit-2 gates (Phase 8-02 precedent) — planner decides.
- **New support files (v1.1-tracked, user-visible):** `.brownfield-ignore` (optional user config; committed if present; not auto-created).
- **New test harness:** `tests/phase-10/run.sh` + `lib.sh` + `fixtures/` (6 fixtures with dual golden contract).
- **New ephemeral directory:** `.brownfield/` (gitignored per TMPL-04) — holds `REPORT.md`, `SKIPPED.md`, `APPLIED.md` across runs.
- **New docs:** `docs/reference/brownfield.md` (scan + bootstrap complete; suggest + verify stubs).
- **Modified:** `bin/lint.sh` (BRWN-08 downgrade modifier; new `brownfield` category for BRWN-09).
- **Modified:** `bin/ingest.sh` (BRWN-10 strip + stderr warn).
- **Modified:** `AGENTS.md §5` (two new field rows — `bootstrap_stage`, `bootstrap_date`).
- **Modified (auto-sync):** `CLAUDE.md` (pre-commit hook).
- **Modified:** `schema/AGENTS.template.md` (mirror §5 edits; inherits pre-commit sync).
- **Modified:** `docs/quickstart.md` (ruamel.yaml prerequisite note).
- **No changes:** `bin/search.sh`, `bin/release.sh`, `bin/check-*.sh`, `bin/init-wizard.sh`, `bin/sync-claude.sh`, `bin/requirements-sync.sh`, `bin/validate-op.sh`.

</code_context>

<specifics>
## Specific Ideas

- **Typed-merge policy phrasing for runbook docs** — the user-authored summary sentence is the canonical spec: *"Brownfield bootstrap preserves existing parseable frontmatter values, injects only absent required sentinel fields, and logs any collisions or noncanonical existing values for later review. It skips only files whose frontmatter cannot be parsed safely or whose structure makes mechanical injection unsafe."* Use verbatim in `docs/reference/brownfield.md` "mechanical-vs-judgment boundary" section.
- **Decision boundary one-liner** — *"Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema."* — suitable as a CLI `--help` epigraph and as a section-header summary.
- **REPORT.md example entry shapes** — per user's Area 1 response:
  - `## Preserved collision` block: `path` + `field` + `action` + `note` ("existing value retained during bootstrap; review optional").
  - `## Preserved schema-authoritative field` block: `path` + `field` + `value` + `action` + `note` ("noncanonical value may fail lint; review in suggest/verify").
  - `## Skipped due to parse failure` block (for SKIPPED.md): `path` + `parse_error` + one-line suggestion.
- **Signal-trace format for classification confidence** — per user: `signals: frontmatter=none, filename=pascalcase, h1=entity-like, links=outbound-heavy`. Comma-separated `key=value` slugs. Planner may canonicalize the slug vocabulary in a rule-reference doc.
- **`unknown` page prose tone** — concise, question-framed, never overconfident. Example template: `<path> — <observed-signals-listed-neutrally>. <Open question directed at user>?` Avoids pre-filled type suggestions that would anchor user judgment.
- **`.brownfield-ignore` negation support** — gitignore-grammar `!pattern` lines un-exclude from the built-in denylist. Useful when a user's vault legitimately uses `templates/` for wiki content rather than Obsidian templates.
- **`--list-excluded` flag on scan** — users who want to audit the denylist's behavior can see the full excluded-file list; default REPORT.md shows counts only.
- **Fixture 3 (tabs-in-yaml) is the canonical skip-artifact fixture** — if ruamel.yaml parses it (some versions are permissive), add a second unparseable fixture (e.g., duplicate-yaml-keys or non-mapping-root) to ensure the skip-artifact contract is tested. Planner decides the exact second fixture at implementation time.
- **`bootstrap_date` vs `bootstrap_date_utc`** — use bare `bootstrap_date: YYYY-MM-DD` consistent with AGENTS.md §5 date format (ISO 8601, no timezone suffix). UTC implied per Phase 3 D-11 precedent.

</specifics>

<deferred>
## Deferred Ideas

- **`bin/brownfield.sh suggest`** (Phases 11) — four staged migration scripts; judgment-heavy transforms.
- **`bin/brownfield.sh verify`** (Phases 11) — thin wrapper over `bin/lint.sh` with brownfield-appropriate severity thresholds.
- **AGENTS.md §11.5 Brownfield Workflow full populate** (Phase 11) — Phase 10 may reserve the slot with a header stub; full workflow prose is Phase 11.
- **`bin/brownfield.sh apply` single-command chain-runner** (v1.2 BRWNAPPLY-01) — per-class user-invoked migration is the v1.1 posture.
- **Interactive review UI for per-migration approval** (v1.2 BRWNAPPLY-02) — CLI + staged scripts hit the same need.
- **Obsidian plugin wrapper for `bin/brownfield.sh scan`** (v2 PLUGIN-01) — in-app dry-run UI.
- **Content-hash sentinel (`bootstrap_sentinel: gsd-v1:<sha8>`)** — research C-3 prevention #3 suggests this; deferred per D-12 (minimalism; current idempotency logic suffices without it).
- **`.brownfield/backups/<path>.orig` per-file copies** — research C-2 prevention #5 suggests this; deferred per D-06 (git is the canonical backup; APPLIED.md manifest is the audit trail).
- **`knowledge_domain: imported` as a distinct decay bucket** — explicitly rejected per D-14; brownfield lineage is captured at page level via `bootstrap_stage`, not by polluting the §6 decay model.
- **Source-summary page scaffolding during bootstrap** — explicitly deferred per D-15; orphan raw sources logged for Phase 11's `01-page-typing.sh`.
- **`--assume-yes` / `--force` flags on `bootstrap --apply`** — not in v1.1; add if automation / CI-driven brownfield emerges as a use case.
- **Configuration-file alternative to `.brownfield-ignore` (e.g., `.brownfield/config.yaml`)** — gitignore grammar is sufficient for v1.1; config-file surface area deferred.
- **LLM-driven classification in `brownfield.sh`** — explicit anti-feature per research Bucket 5; LLM agent can be pointed at the `scan` report in a separate session.
- **`brownfield status` / `brownfield list` introspection subcommands** — defer until user demand emerges; `.brownfield/APPLIED.md` + `REPORT.md` cover the audit needs.
- **Multi-vault brownfield (scan multiple Obsidian vaults at once)** — defer; v1.1 assumes single-vault-per-repo.
- **REQUIREMENTS.md BRWN-04 / BRWN-08 / Phase 10 success-criterion 2 wording amendment** — typed-merge policy (D-02) materially changes the "mechanical transforms only" framing; user offered to help draft the revised wording. Flag this as a pre-plan action item.
- **Plan 999.1 (Brownfield Vault Initialization — backlog)** — already SUPERSEDED per roadmap; Phases 10–11 absorb the scope.

</deferred>

---

*Phase: 10-brownfield-scan-bootstrap*
*Context gathered: 2026-04-17*
