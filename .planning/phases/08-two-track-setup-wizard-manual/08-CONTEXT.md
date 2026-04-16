# Phase 8: Two-Track Setup (Wizard + Manual) - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver `bin/init-wizard.sh` (bash, interactive + `--answers-file` + `--dry-run` modes) and `docs/manual-setup.md` (prompt-ordered hand-edit walkthrough) such that both paths produce a byte-identical personalized `AGENTS.md` (and its `CLAUDE.md` sync twin), `.wizard-answers.yaml`, and an initial decision record. Byte-equality enforced by a fixture-driven CI test.

**Out of scope for Phase 8:** `--upgrade` / `--force` / `bin/upgrade.sh` (v1.2); second-domain presets; GUI wizard; network-dependent behavior; Obsidian plugin. `docs/quickstart.md` is populated *using* the wizard flow landed here, but remaining `docs/reference/*.md` stubs stay Phase 12's job.

</domain>

<decisions>
## Implementation Decisions

### Placeholder Set (Area 2)
- **D-01:** Template stays at **exactly 4 placeholders** (Phase 7 D-08 upheld): `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. `{{EXAMPLE_CLUSTER_REF}}` stays rejected; `{{USER_NAME}}` stays out of AGENTS.md and lives only in `.wizard-answers.yaml` + the initial decision record.
- **D-02:** **Amend WZRD-07** in `.planning/REQUIREMENTS.md` to state "exactly 4 placeholders" and drop `{{USER_NAME}}` + `{{EXAMPLE_CLUSTER_REF}}` from its list. Amendment is part of Phase 8; note the change in the phase's decision record.

### Idempotency & Re-run (Area 3)
- **D-03:** **Initialization signal** is the presence of `.wizard-answers.yaml` at repo root (primary, wizard-owned, unambiguous). Existence of `AGENTS.md` at repo root is a secondary sanity check.
- **D-04:** **Re-run behavior (interactive / answers-file, no `--dry-run`):** refuse with a clear non-zero exit. Message names the answers file and its setup date, explains no `--force` exists in v1.1, and points at "delete `.wizard-answers.yaml` and `AGENTS.md` to re-run from scratch; upgrade flow coming in v1.2."
- **D-05:** **Manual-looking repo without answers file** (AGENTS.md placeholder-free but no `.wizard-answers.yaml`): warn and require deliberate handling. No destructive overwrite. Recommended recovery = follow the manual-setup checklist exit step that writes an `.wizard-answers.yaml` matching the hand-edited state.
- **D-06:** **`--dry-run` is always allowed to render/preview regardless of initialization state.** Pure preview, never mutates. Useful for manual-track debugging.

### Manual Track & Byte-Equality (Area 4)
- **D-07:** **`docs/manual-setup.md` structure:** prompt-ordered — 6 numbered sections (one per wizard prompt), each with (i) the wizard's question, (ii) the file/line to edit, (iii) an inline minimal diff snippet, (iv) an example value. Ends with the one-to-one wizard-prompt checklist (MANUAL-03), the equivalence statement (MANUAL-04), and the file-touch list (MANUAL-05).
- **D-08:** **Canonical-answers fixture location:** `schema/fixtures/canonical-answers.yaml`. Colocated with `schema/AGENTS.template.md`. One obvious home; no new top-level tree.
- **D-09:** **Byte-equality test mechanics (MANUAL-06):** commit the expected rendered artifact at `schema/fixtures/canonical-AGENTS.md`. CI runs `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --dry-run` (or writes to a tempdir) and diffs the rendered output against `canonical-AGENTS.md`. The manual-setup.md minimal-diff example (D-10 below) must land on the same file when followed. Deterministic, fixture-driven; no doc-parsing in CI.
- **D-10:** **Minimal-diff example (MANUAL-02) domain:** a neutral `personal-knowledge` setup (aligns with `PROJECT.md` first-domain language; distinct from `examples/kahneman/` which is a preserved reference cluster). Do **not** reuse Kahneman — Phase 7 neutralized AGENTS.md away from it; reintroducing here would regress NEUT-02/03.

### Prompt Set & Allowed Values (Area 1)
- **D-11:** **Six prompts in this order:** (1) Maintainer name → captured in `.wizard-answers.yaml` + decision record, default pulled from `git config user.name` when present. (2) Primary domain → `{{PRIMARY_DOMAIN}}`, free-form validated `^[a-z0-9-]+$`, default `personal-knowledge`. (3) LLM agent → `{claude-code, codex, other}`, default `claude-code`; resolved to `{{AGENT_FILENAME}}` = `CLAUDE.md` for `claude-code`, `AGENTS.md` for `codex` / `other` (both files always written per Phase 7 D-03). (4) Privacy tier → `{local_only, cloud_safe}`, default `local_only`; substituted directly into `{{DEFAULT_PRIVACY}}`. (5) Decay profile → `{software, science, biography, personal-goals, default}`, default `default` (maps to the AGENTS.md §6 decay table). (6) Obsidian browsing → y/n, default y; recorded in `.wizard-answers.yaml` for future tooling but does **not** alter the generated AGENTS.md (wikilinks/Dataview are structural, not optional).
- **D-12:** **No three-named-profile privacy abstraction in v1.1.** Research-suggested `strict / mixed / open` profiles deferred — underlying schema only has two tiers and no bundled behavior. If v1.2 adds profile semantics (tier + `.gitignore` defaults + sharing posture), add them on top of this cleaner base. `.gitignore` remains Phase 7 D-14's concern.
- **D-13:** **Semantic groups (WZRD-02) cover prompts 2–6 in four groups:** Domain (prompt 2) → LLM agent (prompt 3) → Privacy defaults (prompts 4 + 5) → Obsidian conventions (prompt 6). Maintainer name (prompt 1) prints first with its own one-line explainer ("recorded in the initial decision record for attribution"). Each group prints a one-sentence explainer before its questions.

### Validation & Pre-flight UX (Area 5)
- **D-14:** **Validation posture is mode-dependent.** Interactive mode = **fail-fast per prompt**, re-prompt with an inline error on invalid input. `--answers-file` mode = **collect all errors**, print a summary, exit non-zero. Shared validator returns `{valid: bool, errors: [{field, rule, example}]}`; same function called per-answer interactively vs. once-per-batch from file.
- **D-15:** **Pre-flight (WZRD-09) runs before any prompting or file I/O** — the "before touching anything" language from the spec is load-bearing. Missing tools short-circuit with exit non-zero.
- **D-16:** **Pre-flight error format:** terse one-line-per-missing-tool message plus a pointer to `docs/reference/setup-prerequisites.md` for platform-specific install commands. Keeps the wizard small; centralizes platform matrix maintenance in a doc.
- **D-17:** **Invalid-input error (WZRD-04) shape:** `Invalid <field> "<value>". Must match <rule>. Try: <concrete example>.` Rule for precision, example for fast recovery.

### Output & Diff Engine (Area 6)
- **D-18:** **`--dry-run` output = unified diff per file** generated via Python `difflib.unified_diff`. Deterministic cross-platform output; avoids BSD/GNU `diff` quirks and missing-tool risk. python3 is already in STACK.md scope, so the zero-new-runtime-deps promise holds.
- **D-19:** **Completion summary (WZRD-08) format (real run):** concise list of files written — `<path>  (<size>, <short status>)` — followed by a single `Next: bin/ingest.sh <path/to/first/source>` hint. No inline diff on real runs; use `--dry-run` beforehand for that.
- **D-20:** **Color/TTY handling:** colorize when stdout is a TTY, plain otherwise (auto-detect). Respect the `NO_COLOR` env var per the no-color.org convention. No `--no-color` flag needed in v1.1.

### Initial Decision Record (Area 7)
- **D-21:** **Path:** `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md` (date = wizard invocation date). Matches AGENTS.md §4.6 naming convention.
- **D-22:** **`trigger_type: schema-update`** (closest semantic fit from the existing enum — template placeholder substitution is a schema-shaped event). **Do not widen the enum** in v1.1; revisit if a pattern of bootstrap-class events emerges.
- **D-23:** **`affected_pages: []`** — AGENTS.md §4.6 explicitly permits this for inaugural/infrastructure records. AGENTS.md and CLAUDE.md are not wiki pages (no `id` frontmatter field per the page schema).
- **D-24:** **Body is wizard-generated from a deterministic template** — all seven required sections (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources) filled with real content via substitution. Alternatives Considered lists the rejected options for each prompt. No LLM-in-wizard.
- **D-25:** **Captured metadata in the body:** the six answers, wizard version string, ISO timestamp, and the template git SHA (resolved via `git log -1 --format=%H schema/AGENTS.template.md` when the repo is a git checkout; omitted with a `<unresolved>` marker otherwise). Gives full reproducibility + future upgrade-diff precision.
- **D-26:** **`.wizard-answers.yaml` is the machine-authoritative source of the answer set.** The decision record narrates the answers in prose and links to `.wizard-answers.yaml` in its Sources section — no verbatim duplication of the full YAML.

### Claude's Discretion
- Exact wording of the semantic-group one-sentence explainers (D-13) — planner drafts, user reviews at verification.
- Concrete prompt prompt-text strings, spacing, and in-wizard status formatting.
- Exit code numbers beyond 0/non-zero (e.g., distinct codes for pre-flight fail vs. validation fail) — mirror existing bin/ scripts' conventions.
- `.wizard-answers.yaml` YAML key names and ordering (must cover the 6 answers + wizard version + timestamp + template SHA at minimum; exact key naming planner's call, consistent with snake_case per AGENTS.md §3).
- Whether `--answers-file` reads YAML via a python3 inline block or a small bash parser — planner's call; python3 inline is likely cleaner.
- Exact layout of `docs/reference/setup-prerequisites.md` (D-16 points at it; content scoped to bash ≥ 4 + git + python3 install commands across macOS / Debian / Ubuntu / Arch / WSL). Planner may draft as a short page; content can be refined in Phase 12 docs pass.
- Whether the pre-flight check lives inline in `bin/init-wizard.sh` or as a shared helper (e.g., `bin/_preflight.sh`) for reuse by future wizards.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements (authoritative scope)
- `.planning/ROADMAP.md` §Phase 8 — goal, dependencies, success criteria (1–5), full REQ-ID list (WZRD-01..11, MANUAL-01..06).
- `.planning/REQUIREMENTS.md` §WZRD (lines 38–50), §MANUAL (lines 52–58), traceability table (lines 183–199). **Note:** WZRD-07 requires amendment per D-02 as part of this phase.
- `.planning/MILESTONES.md` — v1.1 Shareability framing.
- `.planning/PROJECT.md` — agent-agnostic constraint, zero-new-deps posture, out-of-scope list (GUI wizards, multi-tenant hosting).

### Phase 7 Artifacts (locked upstream decisions)
- `.planning/phases/07-neutral-template-foundation/07-CONTEXT.md` — D-03 (CLAUDE.md sync), D-04 (`--dry-run`/`--apply` safety posture), D-08 (4 placeholders), D-11 (`docs/quickstart.md` Phase-8-aware stubs), D-14 (`.gitignore` scope — stays Phase 7's).
- `.planning/phases/07-neutral-template-foundation/07-VERIFICATION.md` — verification pattern to mirror.
- `schema/AGENTS.template.md` — the template the wizard renders; contains the 4 placeholders at lines 32, 588, 589, 848.

### Research (informs architecture; not re-litigated)
- `.planning/research/FEATURES.md` §Bucket 2 (Guided Setup Wizard, lines 53–93) and §Bucket 3 (Manual Setup, lines 99–127) — must-haves, nice-to-haves, anti-features, complexity estimates.
- `.planning/research/ARCHITECTURE.md` §Decision 1 (lines 13–29) — placeholder posture, `bin/init-wizard.sh` role, `.wizard-answers.yaml` purpose.
- `.planning/research/PITFALLS.md` §M-1 (lines 123–138), §M-3 — wizard drift prevention, schema-version pinning, `test_wizard_output_matches_manual`.
- `.planning/research/STACK.md` — bash, python3, GitHub Actions `ubuntu-latest` baseline; zero new runtime deps.
- `.planning/research/SUMMARY.md` — milestone synthesis; pitfalls reference.

### Existing Code Surface (read before editing)
- `bin/lint.sh` — flag-parsing, exit-code, stdout-format conventions to mirror.
- `bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh` — bash idiom reference (heredoc args, python3 inline blocks, env-var passing).
- `bin/sync-claude.sh` (Phase 7) — AGENTS.md → CLAUDE.md sync mechanics; wizard writes AGENTS.md then invokes (or inlines) this sync.
- `bin/release.sh` (Phase 7) — `--dry-run` default + `--apply` interactive confirmation — model for wizard's destructive-op posture (though wizard's default IS to mutate; `--dry-run` is the preview flag).
- `docs/manual-setup.md`, `docs/guided-setup.md` — current stubs labeling themselves "populated in v1.1 Phase 8."
- `docs/quickstart.md` — Phase 7 D-11 stub; wizard/ingest sections to populate.
- `wiki/decisions/` — existing decision records as format exemplars for D-21..D-26.
- `AGENTS.md` §4.6 (Decision page type), §6 (decay table keyed on `knowledge_domain`), §13 (privacy tiers).

### CI Infrastructure (wired in Phase 7; extended here)
- `.github/workflows/*.yml` — existing neutrality + CLAUDE.md-sync jobs; MANUAL-06 byte-equality check added as a new step or workflow.
- `.neutrality-denylist.txt` and/or equivalents — byte-equality fixture content must pass neutrality checks (no Kahneman, no personal-content tokens in `canonical-AGENTS.md`).

### External (reference only)
- no-color.org — `NO_COLOR` env-var convention (D-20).
- copier update semantics (research context for deferred `--upgrade`) — no local doc.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`bin/sync-claude.sh`** — wizard invokes (or inlines) to keep `CLAUDE.md` = `AGENTS.md` byte-identical post-render; closes Phase 7 D-03 loop inside the wizard flow.
- **`bin/lint.sh`** — flag-parsing, exit-code, stdout-format conventions mirrored by `bin/init-wizard.sh`.
- **`schema/AGENTS.template.md`** — already contains the 4 locked placeholders at known line numbers.
- **`bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh`** — python3 inline block pattern; wizard's `--answers-file` YAML reader and Python-difflib diff generator use the same pattern (D-18).
- **`bin/release.sh`** — `--dry-run` default posture; wizard inverts (default mutates, `--dry-run` previews) but the convention language is identical.

### Established Patterns
- **Zero new runtime deps** (STACK.md) — wizard is bash + python3 only. No PyYAML; parse `.wizard-answers.yaml` via python3 inline (`yaml` stdlib absent, so use a minimal parser or `python3 -c 'import sys, re; ...'` with the controlled key set).
- **`--dry-run` / `--apply` split** (Phase 7 D-04) — wizard inverts default (normal run mutates; `--dry-run` previews) but follows the same flag-naming convention.
- **Mechanical-first, human-review-second** — applied here to the decision record: deterministic template substitution, no LLM-in-wizard (research anti-feature).
- **Safe-by-default on initialized state** (D-04) — refuse, don't silently overwrite; matches Phase 7's destructive-op posture.
- **Byte-equality CI checks** (Phase 7's CLAUDE.md-sync check) — MANUAL-06 test follows the same shape: commit the expected artifact, render at CI time, `diff -q`.

### Integration Points
- **New script:** `bin/init-wizard.sh` (bash; interactive + `--answers-file <path>` + `--dry-run` modes).
- **New fixtures:** `schema/fixtures/canonical-answers.yaml`, `schema/fixtures/canonical-AGENTS.md` (D-08, D-09).
- **New (possibly):** `bin/_preflight.sh` or an inline pre-flight block (Claude's discretion).
- **Modified:** `.planning/REQUIREMENTS.md` (amend WZRD-07 per D-02); `docs/manual-setup.md` (stub → full walkthrough); `docs/guided-setup.md` (stub → wizard walkthrough); `docs/quickstart.md` (Phase-8-pending sections → populated); potentially `docs/reference/setup-prerequisites.md` (new short page per D-16).
- **New CI workflow step:** MANUAL-06 byte-equality check (render via `--answers-file` + `--dry-run`, diff against `canonical-AGENTS.md`).
- **Written at wizard runtime (target repo):** `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md`.

</code_context>

<specifics>
## Specific Ideas

- **Shared validator contract:** a single function returning `{valid, errors: [{field, rule, example}]}` — called per-prompt interactively (fail-fast) and once-per-batch for `--answers-file` (collect-all). Same code path, different invocation shape. Cheap to do right, expensive to retrofit. (D-14)
- **Template git SHA resolution (D-25):** `git log -1 --format=%H schema/AGENTS.template.md` — when in a git checkout, captures the exact template version rendered; emit `<unresolved>` if git is unavailable. Enables precise upgrade diffs in v1.2.
- **Canonical-answers fixture contents (D-08):** `{name: "Template Maintainer", domain: "personal-knowledge", agent: "claude-code", privacy: "local_only", decay: "default", obsidian: true}`. Must pass all neutrality checks (no personal tokens).
- **Manual track exit step (D-05):** `docs/manual-setup.md` final checklist ends with a concrete snippet that writes an `.wizard-answers.yaml` matching the hand-edited answer set. Gives manual-track users a clean initialization signal parity with the wizard track.
- **Semantic-group order (D-13):** Name → Domain → Agent → Privacy (tier + decay) → Obsidian. Four declared groups; prompt 1 (name) prints its own explainer before the groups begin.
- **YAML reading without PyYAML:** `.wizard-answers.yaml` uses a flat, controlled key set (six answers + metadata). A ~15-line python3 inline parser handling `key: value` + booleans + quoted strings is sufficient — no need for the PyYAML dep.

</specifics>

<deferred>
## Deferred Ideas

- **`bin/init-wizard.sh --upgrade`** (copier-update-style 3-way merge on schema version bumps) — deferred to v1.2; `.wizard-answers.yaml` + template git SHA captured in the initial decision record are the enabling data.
- **`--force` flag** (delete-and-re-render with interactive confirmation) — deferred; beginning of an upgrade/reset flow, best designed alongside `--upgrade`.
- **Named privacy profiles** (`strict` / `mixed` / `open` bundling tier + `.gitignore` + sharing defaults) — deferred to v1.2 when the bundled behavior exists. v1.1 stays direct-tier.
- **`bootstrap` trigger_type** added to AGENTS.md §4.6 enum — deferred until a pattern of bootstrap-class events warrants the widening.
- **Multi-domain starter presets** (personal / research / engineering variants) — explicitly deferred per FEATURES.md Bucket 6.
- **GUI wizard / Electron / web form** — scope explosion; Obsidian plugin route (already deferred to v1.2+) is the right vector.
- **LLM-in-wizard** (auto-generated domain-specific example pages) — rejected per FEATURES.md anti-features; would violate "quiet and reliable" constraint.
- **Network-dependent wizard behavior** (fetch latest template from GitHub) — rejected per FEATURES.md; breaks air-gapped use, makes the wizard non-deterministic.
- **Doc-parsing byte-equality test** (extract snippets from `manual-setup.md` programmatically) — deferred; Q4.3 chose fixture-driven comparison for v1.1 to keep CI simple.
- **Platform-specific prerequisite install automation** — out of scope; `docs/reference/setup-prerequisites.md` is informational only, not an installer.

</deferred>

---

*Phase: 08-two-track-setup-wizard-manual*
*Context gathered: 2026-04-16*
