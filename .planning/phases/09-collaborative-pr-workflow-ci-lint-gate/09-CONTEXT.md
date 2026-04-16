# Phase 9: Collaborative PR Workflow + CI Lint Gate - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the git-based PR workflow and automated CI gates that let contributors fork the template, ingest on a branch, and open a PR with mechanical quality/privacy/attribution enforcement. Concretely: extend `bin/lint.sh` with `--format json`, `--ci`, `--strict`, `--skip-category`, `--require-version` flags; add `bin/check-privacy.sh` (Phase 7 neutrality-twin); add `--contributor` to `bin/ingest.sh` + `bin/search.sh`; ship `CONTRIBUTING.md`, `.github/pull_request_template.md`, `.github/workflows/lint.yml` (3 jobs: lint / privacy-leak / strict), `.git-author-map.txt` seed, populate `docs/reference/ci.md`. Amend AGENTS.md §11.1 (ingest `--contributor`), §11.3 (CI mode + escape-hatch markers), §12 (`contributor::` inline field).

**Out of scope for Phase 9:** brownfield commands (Phases 10–11), Obsidian/Codex render verification (Phase 12), `bin/normalize-frontmatter.sh` / `bin/resolve-conflict.sh` (deferred — build when usage data justifies), post-merge link-audit auto-PR (M-7 prevention — defer), three-field source_author/ingest_contributor/last_modified_by schema (M-8 full form — v1.1 uses the single `contributor::` inline field), rename helper `bin/rename-page.sh` (defer), severity-escalation policy tracked in `.lint-state.json` (C-4 prevention #3 — defer; escape-hatch marker is the v1.1 lever).

</domain>

<decisions>
## Implementation Decisions

### Area 1 — Lint `--ci` / `--format json` output contract

- **D-01:** `--format json` and `--ci` are **independent, orthogonal flags**. Either can be used alone or combined. `--format` defaults to `text`. `--skip-category` remains an explicit standalone override.
- **D-02:** `--ci` applies the CI-03 severity policy (blockers: `yaml`, `orphan`, `crossref`, `provenance`; warnings: `stale`, `gap`, `contradiction`; `info`: `gap` red-links, knowledge-domain sparse-coverage) **and defaults to skipping `drift-external`** (satisfies CI-04). Internally, `--ci` sets a default skip that `--skip-category` or the absence of `--skip-category` can override explicitly.
- **D-03:** `--format json` writes the JSON array to **stdout only**; `lint-report.md` is **not written** in JSON mode. `--dry-run` has no special interaction (JSON mode already implies machine-output / no-markdown behavior).
- **D-04:** JSON shape: array of `{severity, category, path, line?, message}` objects matching the existing `add_finding()` tuple exactly (no schema divergence between local and CI findings).
- **D-05:** Exit-code semantics:
  - Without `--ci`: exit 0 unless the script itself fails (preserves current behavior).
  - With `--ci`: exit **1 iff any post-remap finding has severity `error`**; exit 0 on warnings/info/clean. Script-runtime failures (python3 missing, wiki dir missing) still exit 1 via the existing preserved exit path — CI ops distinguish via stderr vs stdout JSON.
- **D-06:** Contract summary (documented in AGENTS.md §11.3 "CI mode" subsection and `docs/reference/ci.md`):
  - `bin/lint.sh` → text output, normal local behavior.
  - `bin/lint.sh --format json` → JSON array to stdout, no markdown report.
  - `bin/lint.sh --ci` → text output, CI severity profile, default skip of `drift-external`.
  - `bin/lint.sh --ci --format json` → CI severity profile + JSON to stdout, exit non-zero only on error-severity findings.

### Area 2 — `--strict` quality ratchet

- **D-07:** `--strict` trigger: fires as a **hard gate on ready-for-review PRs targeting `main`**, and as a **regression run post-merge on `main`**. **Skipped (or advisory-only) on draft PRs** — draft status signals active iteration where WIP claims may precede their DR. GitHub job config uses `if: github.event.pull_request.draft == false || github.event_name == 'push'`.
- **D-08:** "Matching decision record" rule: a file in the PR diff with `type: decision` whose **`affected_pages` frontmatter list contains the page ID** holding the new `[inferred]` or `[tentative]` claim. Uses AGENTS.md §4.6 schema — no new convention, no filename heuristic.
- **D-09:** Escape-hatch marker: `<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->` and `<!-- lint:expect-tentative id=<page-id> reason="..." -->` on the **line immediately above** the claim. Parser is strict:
  - Marker must appear immediately above the claim line (no blank line between).
  - `id` must match the containing page's frontmatter `id` field.
  - `reason` is required and non-empty.
  Skipped findings are emitted in the JSON output as severity `info` (visible to reviewers, non-blocking). `bin/lint.sh --count-skips` surfaces accumulation for human review; no automated skip cap in v1.1.
- **D-10:** "New page lacking provenance" definition: a **git-diff status `A` (Added, not Modified)** page whose `type` is one of `{entity, concept, overview, comparison}` **and** whose body contains **zero `[prov:` occurrences**. Source pages (`type: source`) and decision records (`type: decision`) are **exempt by design** (different support models per AGENTS.md §4.3, §4.6).
- **D-11:** `--strict` runs as a separate CI job from the primary `lint` job (Area 4, D-15) so a failing ratchet doesn't mask structural errors and vice versa.

### Area 3 — Privacy-leak guard

- **D-12:** New **standalone script `bin/check-privacy.sh`** — pattern-twin of Phase 7's `bin/check-neutrality.sh`. Privacy-leak is a release/publication gate, not ordinary wiki-health lint; keeping it out of `bin/lint.sh` avoids interaction with `--skip-category` semantics and `--version` pinning (CI-08). Safe to run pre-commit locally.
- **D-13:** **Full-tree scan** on each CI run (no diff-only mode). Matches Phase 7 `bin/check-neutrality.sh` scope posture; catches pre-existing leaks, not just newly-introduced ones. Simpler, robust.
- **D-14:** Scan targets **YAML frontmatter only** — `privacy: local_only` matched by regex bracketed within the `^---` frontmatter block. Prose mentions of the tier name in body text are **not** false-positive flagged. Exit 0 clean; exit 1 with `path: offending-frontmatter-line` list on hits.
- **D-15:** Public-paths glob: **hardcoded `PUBLIC_PATHS` bash array at the top of `bin/check-privacy.sh`** with an inline comment citing CI-07. Default set: `examples/**`, `docs/**`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/**`. `wiki/**` is **explicitly excluded** (user content; `local_only` valid there per AGENTS.md §13). Changing the set requires a PR — the correct review loop for scope changes. Consistency with Phase 7 pattern.

### Area 4 — CI workflow layout

- **D-16:** **One `.github/workflows/lint.yml` file with three independent jobs**: `lint`, `privacy-leak`, `strict`. Each job runs in parallel, shares the checkout + setup-python + PyYAML install pattern (same as Phase 7/8 workflows). Siblings to existing `.github/workflows/neutrality.yml` + `setup-parity.yml` — no consolidation (different concerns).
- **D-17:** Required-check names (operator sets these in branch protection on the public repo): **`lint`**, **`privacy-leak`**, **`strict`**, plus existing `neutrality` and `setup-parity`. Short, descriptive, match job names. Documented in `docs/reference/ci.md` with the same operator-action guidance comment block used in Phase 7's `neutrality.yml`.
- **D-18:** Enforcement model mirrors Phase 7/8: `pull_request` = hard gate (branch protection required check); `push` to `main` = advisory (post-merge regression visibility).

### Area 5 — Contributor field + single-author detection

- **D-19:** Handle format: **`@github-handle`** (e.g., `contributor:: @octocat`). With leading `@`. Documented in AGENTS.md §12 amendment. GitHub-native; matches PR mentions; future auto-linking is trivial.
- **D-20:** Single-author detection heuristic (runs at ingest time): `git log --all --format='%ae' 2>/dev/null | sort -u | wc -l`. If `== 1`, **omit the `contributor::` field entirely**. If `> 1`, attempt resolution (D-21). Explicit `--contributor` flag overrides detection in either direction (forces emit on single-author, forces the flag-provided value on multi-author).
- **D-21:** Handle resolution flow for auto-detect (`bin/ingest.sh` without `--contributor`):
  1. Read `git config user.email`.
  2. Look up in `.git-author-map.txt` at repo root (committed, human-curated, format `email → @handle`, one per line, `#` comments allowed).
  3. **If hit → emit mapped `contributor:: @handle`.**
  4. **If miss → warn clearly to stderr, omit the `contributor::` field, and suggest either (a) re-run with `--contributor @handle` or (b) add the email-to-handle mapping to `.git-author-map.txt`.** Do **not** write bare email into the field (preserves field shape, privacy hygiene, parser consistency).
  No GitHub API calls — no auth/rate-limit/offline concerns. Map file starts empty; wizard + manual-setup do not create it (populated as contributors onboard).
- **D-22:** Lint check (CI-08) — new **low-severity `contributor` category** inside `bin/lint.sh`. For each `contributor:: @handle` in `wiki/log.md`, verify the associated email (via `.git-author-map.txt` reverse lookup) appears in `git log --all --format='%ae'`. Mismatch → **warning** (non-blocking). Does not block CI. Skipped in `--ci` mode when single-author detection suppressed the field anyway.

### Area 6 — CONTRIBUTING.md + merge-conflict recipes

- **D-23:** `CONTRIBUTING.md` scope (COLAB-01): PR workflow (fork → branch-per-ingest → `bin/ingest.sh` → `bin/lint.sh` locally → open PR), lint gate expectations (severity tiers summary, escape-hatch marker reference from D-09), privacy review (`local_only` never in public paths), attribution rules (git authorship authoritative per COLAB-05; `contributor::` as convenience + `.git-author-map.txt` handle map). **No governance / CoC / release cadence** — focused doc matching COLAB-01 wording exactly.
- **D-24:** Merge-conflict recipes (COLAB-06): **narrative walkthrough + copy-pasteable commands** for (a) `wiki/log.md` append conflicts (resolution: keep both sides, sort by timestamp), (b) `wiki/index.md` category-listing conflicts (resolution: keep both, alphabetize within category, **then re-run `bin/lint.sh` to validate**). Include a `.gitattributes` snippet recommending `wiki/log.md merge=union` as an **operator opt-in** (documented, not committed by default). Recipes live in `CONTRIBUTING.md` and are cross-linked from `docs/reference/ci.md`.
- **D-25:** `bin/normalize-frontmatter.sh` and `bin/resolve-conflict.sh` are **explicitly deferred** (see Deferred Ideas). Ship the docs now; build the tools when real contributor-usage data supports them.

### Area 7 — Lint `--require-version` pinning

- **D-26:** Version format: **semver `MAJOR.MINOR.PATCH`**. Initial Phase 9 value: **`1.1.0`** (aligns with milestone). Breaking change (removed category, changed severity semantics) = MAJOR bump. Non-breaking additions = MINOR. Bug fixes = PATCH.
- **D-27:** Storage: **`LINT_VERSION="1.1.0"` bash constant near the top of `bin/lint.sh`**. `bin/lint.sh --version` prints it and exits 0. Version-constant changes ride in the same PR as rule changes (review convention, no CI enforcement in v1.1).
- **D-28:** Pinning semantics: **`--require-version X.Y.Z` means the running version must be `>= X.Y.Z` (minimum version)**. Fails with exit 1 + clear stderr message if running version doesn't satisfy the pin. Workflow YAML sets this explicitly: `bin/lint.sh --require-version 1.1.0 --ci --format json`. Pin is optional — absent pin accepts current version. If exact pinning is needed later, add `--require-exact-version` then (not v1.1).

### Area 8 — PR template

- **D-29:** `.github/pull_request_template.md` structure (markdown, ~30 lines, terse/mechanical tone):
  - `## Summary` — 1–2 sentence description (free text).
  - `## Ingest type` — checkbox list: `[ ] new source`, `[ ] update existing page(s)`, `[ ] merge pages`, `[ ] supersede page`, `[ ] docs-only`, `[ ] other (describe)`.
  - `## Source attribution` — free-text field for URL/citation. Note: **"May be left blank for docs-only PRs."**
  - `## Privacy review` — single checkbox: `[ ] I confirm no `privacy: local_only` frontmatter appears in public paths (examples/, docs/, AGENTS.md, CLAUDE.md, README.md, .github/). See PRIVACY.md.`
  - `## Lint` — checkbox `[ ] bin/lint.sh passes locally` + collapsible `<details><summary>lint output</summary>…</details>` block.
  - `## Expected findings (optional)` — free-text for intentional `[inferred]`/`[tentative]`/contradiction claims + pointer to D-09 `<!-- lint:expect-* -->` markers.
- **D-30:** Tone: terse/mechanical, consistent with Phase 7/8 docs voice (technical, plainspoken, bullets over prose).

### Area 9 — Multi-provider CI docs

- **D-31:** `docs/reference/ci.md` provider-equivalents section structure:
  - **Platform-neutral principles** — JSON contract, exit-code semantics, severity policy (the portable part).
  - **GitHub Actions** → canonical `.github/workflows/lint.yml` shipped in this phase.
  - **GitLab CI** → ~15–25 line `.gitlab-ci.yml` snippet doing lint + privacy + strict.
  - **Gitea Actions** → note: GitHub Actions schema-compatible; the `.github/workflows/lint.yml` works as-is in `.gitea/workflows/` with a one-line tweak on the runner image.
  - **Codeberg (Forgejo Actions)** → same as Gitea + Codeberg-specific runner image note.
  - **No Bitbucket, no Jenkins, no Drone** — explicitly deferred.
- **D-32:** `docs/reference/ci.md` is **fully populated** in Phase 9 (closes the "stub filled in Phase 9" promise from Phase 7 D-11). Contents: severity policy table, JSON output schema, privacy-leak guard explainer, `--strict` mode, escape-hatch marker docs, `--require-version` pinning usage, multi-provider equivalents. Single place that explains the Phase 9 CI surface.

### Claude's Discretion

- Exact stdout formatting, exit codes beyond 0/1, and flag parsing details for `bin/check-privacy.sh` — mirror existing `bin/check-neutrality.sh` / `bin/lint.sh` conventions.
- Internal refactor shape of `bin/lint.sh` severity-remap dispatcher (single map table vs. case statement) — planner's call, must be unit-testable.
- `.git-author-map.txt` format edge cases (trailing whitespace, duplicate email entries, case-sensitivity of email) — planner drafts, consistent with `.neutrality-denylist.txt` conventions.
- Exact bash parsing of the escape-hatch marker regex (`lint:expect-inferred|lint:expect-tentative`) — planner's call; must produce a deterministic match result and inform the `--count-skips` aggregator.
- Whether `bin/search.sh --contributor` parses `@handle` or accepts bare — planner's call; recommend accepting both for user ergonomics (strip leading `@` for matching).
- CI job ordering and `needs:` edges inside `lint.yml` — planner's call; default to full parallelism (`lint`, `privacy-leak`, `strict` all independent, each a separate required check).
- Whether the escape-hatch marker parser is inlined in `bin/lint.sh` python3 block or extracted to a small helper — planner's call; inline is consistent with current structure.
- Exact failure-message wording across new flags and scripts — must be actionable and point at the relevant doc section.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements (authoritative scope)
- `.planning/ROADMAP.md` §Phase 9 — goal, dependencies, success criteria (1–5), full REQ-ID list (COLAB-01..08, CI-01..09).
- `.planning/REQUIREMENTS.md` §COLAB (lines 63–70), §CI (lines 73–82), traceability table (lines 200–216).
- `.planning/MILESTONES.md` — v1.1 Shareability framing.
- `.planning/PROJECT.md` — agent-agnostic constraint, zero-new-deps posture, attribution policy ("git authorship is source of truth"), out-of-scope list (real-time editing, hosted multi-tenant, auto-merge on lint pass, CLA bot).

### Phase 7 & 8 Artifacts (locked upstream decisions)
- `.planning/phases/07-neutral-template-foundation/07-CONTEXT.md` — D-03 (CLAUDE.md byte-sync pattern), D-04 (`--dry-run`/`--apply` safety posture), Phase 7 CI-workflow enforcement-model comments (mirrored in D-18).
- `.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md` — D-18 (Python `difflib` unified-diff pattern; reusable for CI annotation formatting), D-19 (completion-summary format), D-20 (TTY/NO_COLOR convention).
- `.github/workflows/neutrality.yml` (Phase 7) — enforcement-model comment block, `actions/checkout@v6` + `actions/setup-python@v6` + `pip install pyyaml` baseline, pattern-twin for `lint.yml`.
- `.github/workflows/setup-parity.yml` (Phase 8) — same baseline; env-var-driven determinism pattern.

### Research (informs architecture; not re-litigated)
- `.planning/research/FEATURES.md` §Bucket 4 (Git-Based PR Workflow, lines 132–177) — must-haves, differentiators, anti-features, complexity.
- `.planning/research/ARCHITECTURE.md` §Decision 3 (contributor field — lines 70–95), §Decision 6 (PR lint gate JSON flag — lines 157–185).
- `.planning/research/PITFALLS.md` §C-4 (lint gate too strict / too loose, lines 94–119), §M-5 (YAML merge conflicts, lines 209–229), §M-6 (duplicate pages on concurrent ingest, lines 231–250), §M-7 (cross-ref breakage post-merge, lines 252–265), §M-8 (attribution confusion, lines 267–287), §m-7 (`local_only` accidental push, line 410+).
- `.planning/research/STACK.md` — bash + python3 + PyYAML baseline, GitHub Actions `ubuntu-latest`, zero new runtime deps.
- `.planning/research/SUMMARY.md` — milestone-wide synthesis.

### Existing Code Surface (read before editing)
- `bin/lint.sh` (1131 lines) — add `--format`, `--ci`, `--strict`, `--skip-category`, `--require-version`, `--version`, `--count-skips` flags; extend severity-remap policy; add `contributor` category check; add escape-hatch marker parser; add `--strict` provenance + DR-matching logic. Existing `add_finding()` tuple shape is the canonical JSON record.
- `bin/ingest.sh` (252 lines) — add `--contributor <handle>` flag; auto-detect from `git config user.email` → `.git-author-map.txt` lookup; emit `contributor:: @handle` in log.md append.
- `bin/search.sh` (286 lines) — add `--contributor <handle>` filter parsing `wiki/log.md`.
- `bin/check-neutrality.sh` (393 lines) — pattern-twin reference for the new `bin/check-privacy.sh`.
- `bin/sync-claude.sh` (Phase 7) — AGENTS.md → CLAUDE.md sync must still pass after §11.1, §11.3, §12 amendments.
- `bin/release.sh` (Phase 7) — orphan-branch release runbook; privacy-leak guard output contract must align with release pre-flight.
- `AGENTS.md` §11.1 (ingest workflow — add `--contributor` auto-detect step), §11.3 (lint workflow — add "CI mode" subsection documenting severity remap + escape-hatch markers), §12 (log format — document `contributor::` inline field), §4.6 (decision records — referenced by D-08 matching rule, no change needed), §13 (privacy tiers — referenced by D-15, no change needed).
- `docs/reference/ci.md` — Phase 9 stub, fully populated this phase (D-32).
- `docs/reference/index.md` — links to `ci.md` already present; verify CONTRIBUTING.md is cross-linked as needed.
- `wiki/log.md` — destination for `contributor::` inline field; confirm current log format compatibility.

### External Specs (for planner's reference only)
- GitHub Actions workflow commands — `::error file=...,line=...::` / `::warning` annotation syntax (used by the JSON → annotation shim).
- no-color.org — `NO_COLOR` env-var convention (inherited from Phase 8 D-20; applies to `bin/check-privacy.sh` and any new stderr output).
- Gitea Actions schema-compatibility note (no local spec).
- Forgejo runner image docs (no local spec).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`bin/lint.sh` `add_finding()` tuple** — canonical JSON record shape for `--format json`; no schema divergence needed (D-04).
- **`bin/lint.sh` severity tiers (`error`, `warning`, `info`)** — already defined in the codebase; `--ci` adds a remap dispatcher on top.
- **`bin/lint.sh` category filter (`--category`)** — `--skip-category` is the inverse; shares the existing category enum.
- **`bin/check-neutrality.sh`** — structural twin for `bin/check-privacy.sh` (exit codes, stdout shape, `PUBLIC_PATHS` array pattern, frontmatter-regex scan).
- **`bin/ingest.sh` log.md append point** — single edit site for `contributor::` emission.
- **`bin/search.sh` index + query modes** — established flag-parsing pattern; `--contributor` filter slots in cleanly.
- **`.github/workflows/neutrality.yml` + `setup-parity.yml`** — CI scaffolding pattern: checkout@v6, setup-python@v6, pip install pyyaml, `pull_request` hard gate + `push` advisory.

### Established Patterns
- **Zero new runtime deps** (STACK.md) — Phase 9 adds none. All new logic is bash + python3 + PyYAML (already in scope).
- **Pattern-twin scripts** (`bin/check-neutrality.sh` → `bin/check-privacy.sh`) — deliberate consistency for operator muscle-memory; Phase 7 pattern.
- **Full-tree CI scans** (neutrality, setup-parity) — simpler than diff-only; catches drift; Phase 9 `privacy-leak` follows suit (D-13).
- **Mechanical-first, human-review-second** — applied here to escape-hatch markers (D-09): the marker is mechanical bypass; reviewer acceptance via PR review is the human gate.
- **Safe-by-default flags** — `--dry-run` / `--apply` split elsewhere; Phase 9 inherits by not adding destructive operations (lint + checks are read-only except for `--fix` which is unchanged).
- **Structured operations / decision records** — D-08 uses `affected_pages` frontmatter (AGENTS.md §4.6) as the matching linkage; no new schema.
- **Enforcement model comment block** (Phase 7 `neutrality.yml`) — reused verbatim in `lint.yml` header to teach operators the branch-protection required-check lever.

### Integration Points
- **New script:** `bin/check-privacy.sh`.
- **New fixtures / data files:** `.git-author-map.txt` at repo root (committed, human-curated, may ship empty in Phase 9 with a header comment).
- **New CI workflow:** `.github/workflows/lint.yml` (three jobs: `lint`, `privacy-leak`, `strict`).
- **New top-level file:** `CONTRIBUTING.md`.
- **New template:** `.github/pull_request_template.md`.
- **Modified:** `bin/lint.sh` (+ `--format`, `--ci`, `--strict`, `--skip-category`, `--require-version`, `--version`, `--count-skips` flags; severity-remap policy; `contributor` category; escape-hatch marker parser; `--strict` provenance + DR-match logic; `LINT_VERSION="1.1.0"` constant).
- **Modified:** `bin/ingest.sh` (+ `--contributor <handle>`; auto-detect via `.git-author-map.txt`; `contributor::` log.md emission).
- **Modified:** `bin/search.sh` (+ `--contributor <handle>` filter).
- **Modified:** `AGENTS.md` (§11.1 ingest `--contributor` doc; §11.3 CI mode + escape-hatch doc; §12 `contributor::` inline field doc).
- **Modified:** `docs/reference/ci.md` (stub → full page per D-32).
- **Modified:** `docs/reference/index.md` (verify cross-links).
- **Amended:** `.planning/REQUIREMENTS.md` — flip COLAB-01..08 + CI-01..09 status checkboxes on phase verification (DEBT-03 / requirements-sync responsibility, not a Phase 9 mutation).
- **New CI required-check names** (operator sets in branch protection on the public repo): `lint`, `privacy-leak`, `strict` (alongside existing `neutrality`, `setup-parity`).

</code_context>

<specifics>
## Specific Ideas

- **Escape-hatch marker parser** (D-09): immediate-above-line placement is load-bearing — a blank line between marker and claim must fail the match. This prevents stale markers drifting down as pages are edited. Document in AGENTS.md §11.3.
- **`.git-author-map.txt` format** (D-21): `email → @handle` one per line, `#` comments allowed, tab or `->` separator (planner's call; `#` comment convention matches `.neutrality-denylist.txt`). Ships empty or with a single header comment in Phase 9.
- **`wiki/log.md merge=union` `.gitattributes` snippet** (D-24): ships as documented recipe in CONTRIBUTING.md, **not committed as a default `.gitattributes` line** — operator opt-in keeps git behavior predictable for users who haven't read the doc.
- **`bin/search.sh --contributor` leading-@ handling**: accept both `@octocat` and `octocat` (strip leading `@` internally); matches the user ergonomic intuition of either.
- **CI-08 lint check skip condition**: when single-author detection (D-20) suppresses the `contributor::` field, the lint `contributor` category reports zero findings and contributes nothing to warning counts — avoids "no contributors found" noise on personal forks.
- **`bin/lint.sh --count-skips` aggregator** (D-09): counts escape-hatch markers across the wiki, prints per-page totals and a grand total. Designed for human review, not automated enforcement. Planner may route output through the standard finding path (severity `info`, category `skip-count`) for JSON consistency.
- **GitHub annotation shim**: inline `jq` or `python3` one-liner inside `.github/workflows/lint.yml` converting JSON → `::error file=..,line=..::` / `::warning` per severity. Pattern identical to Phase 7 `neutrality.yml` and Phase 8 `setup-parity.yml` inline post-processing steps. No separate shim script.
- **`--require-version` is a minimum-version check** (D-28): running version `1.2.0` passes `--require-version 1.1.0`. Exact pinning is deliberately not in v1.1 (Occam's razor — add when needed).

</specifics>

<deferred>
## Deferred Ideas

- **`bin/normalize-frontmatter.sh`** (research M-5 prevention #1) — YAML sequence canonicalization helper; defer until real contributor-usage data shows frontmatter merge conflicts are frequent.
- **`bin/resolve-conflict.sh`** (research M-5 prevention #4) — parse-both-sides union helper; same deferral rationale.
- **Three-field attribution schema** (`source_author`, `ingest_contributor`, `last_modified_by` — M-8 prevention #1) — full form deferred; v1.1 uses a single `contributor::` inline field. Revisit if attribution ambiguity becomes a reported problem.
- **`bin/update-contributor-index.sh`** (M-8 prevention #2) — mechanical git-log → log.md sync; deferred. The lint check (D-22) is the v1.1 enforcement lever; mechanical sync can land when drift is observed.
- **`bin/rename-page.sh`** (M-7 prevention #3) — inbound-reference updater + redirect stub + DR scaffolder; deferred.
- **Post-merge lint hook / auto-fix PR** (M-7 prevention #1, `post_merge_link_audit`) — scheduled CI job on `main` that opens auto-fix PRs; deferred. Phase 9 ships the `push` trigger for advisory visibility, not auto-fix generation.
- **Merge-base lint comparison** (C-4 prevention #2) — running lint against the merged-state ref rather than the PR branch head; deferred.
- **Severity-escalation policy tracked in `.lint-state.json`** (C-4 prevention #3) — warning-persists-across-3-PRs → auto-promoted to error; deferred. The escape-hatch marker is v1.1's explicit judgment lever.
- **Gap-detection `--exempt-pr-new` flag** (C-4 prevention #5) — PR-new topics exempt from sparse-coverage warnings; deferred. Current `--ci` remap downgrades `gap` to warning, which is already non-blocking.
- **`--require-exact-version` flag** — exact-pinning semantics; deferred. `--require-version` as minimum-version is sufficient for v1.1.
- **CI posting lint report as PR comment** (Bucket 4 differentiator; Danger-JS / reviewdog pattern) — adds a bot-identity + token surface; GitHub annotations cover 80% of the value; deferred.
- **GitLab/Gitea/Codeberg runner-image cookbook** beyond one-liner equivalents — ship the snippet; do not take ownership of cross-provider test coverage.
- **Bitbucket Pipelines + Jenkins + Drone equivalents** — not in CI-09 roadmap; deferred.
- **`.pending-topics.md` branch-coordination file** (M-6 prevention #2) — remote-aware topic reservation; deferred.
- **`bin/ingest.sh` remote-branch slug-collision check** (M-6 prevention #1) — `git fetch --all` + cross-branch grep; deferred.
- **Auto-promote default merge strategy to "merge commits, not squash"** (M-8 prevention #3) — operator setting on the public repo; documented in `docs/reference/ci.md` but not enforced by any CI check.

</deferred>

---

*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Context gathered: 2026-04-16*
