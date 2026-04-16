# Phase 9: Collaborative PR Workflow + CI Lint Gate — Research

**Researched:** 2026-04-16
**Domain:** GitHub-Actions CI gating for a bash + python3 wiki compiler; PR-time quality/privacy/attribution enforcement
**Confidence:** HIGH (all load-bearing claims verified against in-repo code or GitHub Docs 2026)

## Summary

Phase 9 is deliberately a **light-touch extension** of infrastructure shipped in Phases 7–8. The CI scaffolding pattern (`actions/checkout@v6` + `actions/setup-python@v6` + `pip install pyyaml` on `ubuntu-latest`) is already battle-tested in two workflows (`neutrality.yml`, `setup-parity.yml`); `lint.yml` follows the same shape with three parallel jobs. The heavy lifting is inside `bin/lint.sh`: a severity-remap dispatcher on top of an existing, working `add_finding()` tuple; a new `--format json` branch that emits the tuple verbatim; a `--strict` pass that matches new `[inferred]/[tentative]` claims against `type: decision` pages with matching `affected_pages`; and an escape-hatch marker parser for judgment-flagged exceptions. A new standalone script `bin/check-privacy.sh` is a pattern-twin of `bin/check-neutrality.sh` (also already shipped) — same stdout shape, same exit codes, same frontmatter-block regex approach.

The project-specific risks are NOT "can we make GitHub Actions annotate a PR" (well-documented, 10 error + 10 warning + 50 total annotation cap per job). They are (1) **severity-policy coherence** — making the CI mode block structural breakage but not judgment work without becoming performative (C-4); (2) **attribution honesty** — git authorship stays the source of truth while `contributor:: @handle` is a convenience index with `.git-author-map.txt` resolution (M-8); (3) **operator discoverability** — GitHub branch-protection required checks must be named `lint`, `privacy-leak`, `strict` in a human-readable way, documented alongside the existing `neutrality` / `setup-parity` checks.

**Primary recommendation:** Mirror Phase 7/8's enforcement-model comment block and pattern-twin structure. Layer the severity-remap dispatcher on top of the existing `add_finding()` tuple without schema divergence. Ship `docs/reference/ci.md` as the single place documenting the Phase 9 CI surface (closes the "populated in Phase 9" stub promise from Phase 7).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Area 1 — Lint `--ci` / `--format json` output contract

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

#### Area 2 — `--strict` quality ratchet

- **D-07:** `--strict` trigger: fires as a **hard gate on ready-for-review PRs targeting `main`**, and as a **regression run post-merge on `main`**. **Skipped (or advisory-only) on draft PRs** — draft status signals active iteration where WIP claims may precede their DR. GitHub job config uses `if: github.event.pull_request.draft == false || github.event_name == 'push'`.
- **D-08:** "Matching decision record" rule: a file in the PR diff with `type: decision` whose **`affected_pages` frontmatter list contains the page ID** holding the new `[inferred]` or `[tentative]` claim. Uses AGENTS.md §4.6 schema — no new convention, no filename heuristic.
- **D-09:** Escape-hatch marker: `<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->` and `<!-- lint:expect-tentative id=<page-id> reason="..." -->` on the **line immediately above** the claim. Parser is strict:
  - Marker must appear immediately above the claim line (no blank line between).
  - `id` must match the containing page's frontmatter `id` field.
  - `reason` is required and non-empty.
  Skipped findings are emitted in the JSON output as severity `info` (visible to reviewers, non-blocking). `bin/lint.sh --count-skips` surfaces accumulation for human review; no automated skip cap in v1.1.
- **D-10:** "New page lacking provenance" definition: a **git-diff status `A` (Added, not Modified)** page whose `type` is one of `{entity, concept, overview, comparison}` **and** whose body contains **zero `[prov:` occurrences**. Source pages (`type: source`) and decision records (`type: decision`) are **exempt by design**.
- **D-11:** `--strict` runs as a separate CI job from the primary `lint` job so a failing ratchet doesn't mask structural errors and vice versa.

#### Area 3 — Privacy-leak guard

- **D-12:** New **standalone script `bin/check-privacy.sh`** — pattern-twin of Phase 7's `bin/check-neutrality.sh`. Privacy-leak is a release/publication gate, not ordinary wiki-health lint; keeping it out of `bin/lint.sh` avoids interaction with `--skip-category` semantics and `--version` pinning.
- **D-13:** **Full-tree scan** on each CI run (no diff-only mode). Matches Phase 7 `bin/check-neutrality.sh` scope posture; catches pre-existing leaks, not just newly-introduced ones.
- **D-14:** Scan targets **YAML frontmatter only** — `privacy: local_only` matched by regex bracketed within the `^---` frontmatter block. Prose mentions of the tier name in body text are **not** false-positive flagged.
- **D-15:** Public-paths glob: **hardcoded `PUBLIC_PATHS` bash array at the top of `bin/check-privacy.sh`** with an inline comment citing CI-07. Default set: `examples/**`, `docs/**`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/**`. `wiki/**` is **explicitly excluded** (user content; `local_only` valid there per AGENTS.md §13).

#### Area 4 — CI workflow layout

- **D-16:** **One `.github/workflows/lint.yml` file with three independent jobs**: `lint`, `privacy-leak`, `strict`. Each runs in parallel, shares the checkout + setup-python + PyYAML install pattern. Siblings to existing `neutrality.yml` + `setup-parity.yml` — no consolidation.
- **D-17:** Required-check names (operator sets these in branch protection): **`lint`**, **`privacy-leak`**, **`strict`**, plus existing `neutrality` and `setup-parity`. Documented in `docs/reference/ci.md` with the same operator-action guidance block used in Phase 7's `neutrality.yml`.
- **D-18:** Enforcement model mirrors Phase 7/8: `pull_request` = hard gate (branch protection required check); `push` to `main` = advisory.

#### Area 5 — Contributor field + single-author detection

- **D-19:** Handle format: **`@github-handle`** (e.g., `contributor:: @octocat`).
- **D-20:** Single-author detection heuristic: `git log --all --format='%ae' 2>/dev/null | sort -u | wc -l`. If `== 1`, **omit the `contributor::` field entirely**. If `> 1`, attempt resolution. Explicit `--contributor` flag overrides detection in either direction.
- **D-21:** Handle resolution flow (auto-detect without `--contributor`):
  1. Read `git config user.email`.
  2. Look up in `.git-author-map.txt` at repo root.
  3. If hit → emit mapped `contributor:: @handle`.
  4. If miss → warn to stderr, omit the field, suggest `--contributor @handle` or add mapping. **Do NOT write bare email into the field.**
- **D-22:** Lint check (CI-08) — new **low-severity `contributor` category** inside `bin/lint.sh`. For each `contributor:: @handle` in `wiki/log.md`, verify the associated email (via `.git-author-map.txt` reverse lookup) appears in `git log --all --format='%ae'`. Mismatch → **warning** (non-blocking). Skipped in `--ci` mode when single-author detection suppressed the field.

#### Area 6 — CONTRIBUTING.md + merge-conflict recipes

- **D-23:** `CONTRIBUTING.md` scope (COLAB-01): PR workflow (fork → branch-per-ingest → `bin/ingest.sh` → `bin/lint.sh` locally → open PR), lint gate expectations, privacy review, attribution rules. **No governance / CoC / release cadence.**
- **D-24:** Merge-conflict recipes (COLAB-06): **narrative walkthrough + copy-pasteable commands** for (a) `wiki/log.md` append conflicts (keep both sides, sort by timestamp), (b) `wiki/index.md` category-listing conflicts (keep both, alphabetize within category, re-run `bin/lint.sh`). Include a `.gitattributes` snippet recommending `wiki/log.md merge=union` as an **operator opt-in**.
- **D-25:** `bin/normalize-frontmatter.sh` and `bin/resolve-conflict.sh` are **explicitly deferred**.

#### Area 7 — Lint `--require-version` pinning

- **D-26:** Version format: **semver `MAJOR.MINOR.PATCH`**. Initial Phase 9 value: **`1.1.0`**. Breaking change = MAJOR, non-breaking additions = MINOR, bug fixes = PATCH.
- **D-27:** Storage: **`LINT_VERSION="1.1.0"` bash constant near the top of `bin/lint.sh`**. `bin/lint.sh --version` prints it and exits 0.
- **D-28:** Pinning semantics: **`--require-version X.Y.Z` means running version must be `>= X.Y.Z` (minimum version)**. Fails with exit 1 + clear stderr message if running version doesn't satisfy the pin. Pin is optional — absent pin accepts current version.

#### Area 8 — PR template

- **D-29:** `.github/pull_request_template.md` structure (~30 lines, terse/mechanical tone): `## Summary`, `## Ingest type` (checkboxes), `## Source attribution`, `## Privacy review` (single checkbox), `## Lint` (checkbox + collapsible output block), `## Expected findings (optional)` with D-09 escape-hatch marker pointer.
- **D-30:** Tone: terse/mechanical, consistent with Phase 7/8 docs voice.

#### Area 9 — Multi-provider CI docs

- **D-31:** `docs/reference/ci.md` provider-equivalents section: platform-neutral principles → GitHub Actions (canonical) → GitLab CI (~15–25 line snippet) → Gitea Actions (note: schema-compatible; one-line tweak on runner image) → Codeberg/Forgejo Actions. **No Bitbucket, no Jenkins, no Drone.**
- **D-32:** `docs/reference/ci.md` **fully populated** in Phase 9 (closes Phase 7 D-11 stub-fill promise). Contents: severity policy table, JSON output schema, privacy-leak guard explainer, `--strict` mode, escape-hatch marker docs, `--require-version` pinning usage, multi-provider equivalents.

### Claude's Discretion

- Exact stdout formatting, exit codes beyond 0/1, and flag parsing details for `bin/check-privacy.sh` — mirror existing `bin/check-neutrality.sh` / `bin/lint.sh` conventions.
- Internal refactor shape of `bin/lint.sh` severity-remap dispatcher (single map table vs. case statement) — must be unit-testable.
- `.git-author-map.txt` format edge cases (trailing whitespace, duplicate email entries, case-sensitivity of email) — consistent with `.neutrality-denylist.txt` conventions.
- Exact bash parsing of the escape-hatch marker regex — must produce a deterministic match result and inform the `--count-skips` aggregator.
- Whether `bin/search.sh --contributor` parses `@handle` or accepts bare — recommend accepting both (strip leading `@` for matching).
- CI job ordering and `needs:` edges inside `lint.yml` — default to full parallelism.
- Whether the escape-hatch marker parser is inlined in `bin/lint.sh` python3 block or extracted to a small helper — inline is consistent with current structure.
- Exact failure-message wording across new flags and scripts — must be actionable and point at the relevant doc section.

### Deferred Ideas (OUT OF SCOPE)

- `bin/normalize-frontmatter.sh` (YAML sequence canonicalization)
- `bin/resolve-conflict.sh` (parse-both-sides union helper)
- Three-field attribution schema (`source_author`, `ingest_contributor`, `last_modified_by`)
- `bin/update-contributor-index.sh` (mechanical git-log → log.md sync)
- `bin/rename-page.sh` (inbound-reference updater + redirect stub + DR scaffolder)
- Post-merge lint hook / auto-fix PR (scheduled CI job on `main`)
- Merge-base lint comparison (running lint against merged-state ref)
- Severity-escalation policy tracked in `.lint-state.json`
- Gap-detection `--exempt-pr-new` flag
- `--require-exact-version` flag
- CI posting lint report as PR comment (Danger-JS / reviewdog pattern)
- GitLab/Gitea/Codeberg runner-image cookbook beyond one-liner equivalents
- Bitbucket Pipelines + Jenkins + Drone equivalents
- `.pending-topics.md` branch-coordination file
- `bin/ingest.sh` remote-branch slug-collision check
- Auto-promote default merge strategy to "merge commits, not squash"
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COLAB-01 | Top-level `CONTRIBUTING.md` describing branch-per-ingest convention, PR workflow, attribution rules | D-23 scope constraint; fork workflow, D-09 escape-hatch marker reference, D-24 merge-conflict recipes all live here |
| COLAB-02 | `.github/pull_request_template.md` prompts for source attribution, ingest type, privacy review, lint output | D-29 6-section structure, D-30 tone; mechanical checklist pattern proven by Phase 7/8 docs |
| COLAB-03 | `log.md` entry schema amended (AGENTS.md §12) with optional `contributor:: <handle>` Dataview inline field | Dataview `[prov::]` / `[epistemic::]` precedent in §6; amendment slots into §12 without header format change |
| COLAB-04 | `bin/ingest.sh --contributor <handle>` flag; auto-detect from `git config user.email`; omit on single-author repos | D-19..D-21 handle resolution flow; `.git-author-map.txt` at repo root; `bin/ingest.sh` has a single log.md append site (existing code insight) |
| COLAB-05 | Git commit authorship is the attribution source of truth; documented as such in `CONTRIBUTING.md` | D-23 explicit mention; PROJECT.md policy; `contributor::` is convenience index, not ground truth (M-8 prevention) |
| COLAB-06 | `CONTRIBUTING.md` includes merge-conflict recipes for `index.md` and `log.md` | D-24 narrative + commands; M-5 prevention; `.gitattributes merge=union` as documented opt-in |
| COLAB-07 | `bin/search.sh --contributor <handle>` filter (parses `log.md` contributor field) | Existing `bin/search.sh` flag-parsing pattern; Claude's Discretion: accept both `@handle` and bare |
| COLAB-08 | `bin/lint.sh` optional check: `contributor::` handles appear as git commit authors (low-severity warning) | D-22 new `contributor` category; reverse-lookup via `.git-author-map.txt`; skipped in `--ci` mode for single-author repos |
| CI-01 | `.github/workflows/lint.yml` runs on every PR with `actions/checkout@v6` + `actions/setup-python@v6` on `ubuntu-latest` | Phase 7 `neutrality.yml` + Phase 8 `setup-parity.yml` establish the identical scaffold; D-16 three-job layout |
| CI-02 | `bin/lint.sh --format json` mode emits structured findings `{severity, category, path, line?, message}` | D-04 JSON shape matches existing `add_finding()` tuple; D-03 stdout only, no lint-report.md written in JSON mode |
| CI-03 | `bin/lint.sh --ci` mode severity policy: `stale`/`gap`/`contradiction` warnings; `yaml`/`orphan`/`crossref`/`provenance` blockers | D-02 remap dispatcher; D-05 exit-1 iff any post-remap error-severity finding |
| CI-04 | `bin/lint.sh --skip-category drift-external` skips cross-tool drift checks in CI | D-02 `--ci` defaults to this skip; `--skip-category` is inverse of existing `--category` flag |
| CI-05 | Annotation shim converts JSON findings to GitHub `::error file=...,line=...::` inline annotations | Verified 2026 syntax (HIGH); Phase 7/8 precedent uses inline `python3`/`jq` post-processing steps |
| CI-06 | `bin/lint.sh --strict` mode: non-zero exit on `[inferred]`/`[tentative]` without matching DR, or new pages lacking provenance | D-08 DR-match via `affected_pages` frontmatter; D-10 new-page definition (git-diff status A); D-09 escape-hatch marker |
| CI-07 | Privacy-leak guard: CI fails PR when `privacy: local_only` appears under public paths; configurable via workflow YAML | D-12 standalone `bin/check-privacy.sh`; D-15 hardcoded `PUBLIC_PATHS` array (changing = PR review); D-14 frontmatter-only scan |
| CI-08 | `bin/lint.sh --version` supports version pinning | D-26 semver `1.1.0`; D-27 `LINT_VERSION` bash constant; D-28 `--require-version X.Y.Z` = minimum version |
| CI-09 | `/docs/reference/ci.md` documents GitLab/Gitea/Codeberg equivalents | D-31 platform-neutral principles + 4 providers; D-32 fully populated (closes Phase 7 stub); JSON contract is the portable piece |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

CLAUDE.md is byte-identical to AGENTS.md (enforced by pre-commit hook in Phase 7). Directives relevant to Phase 9:

1. **Schema authority:** AGENTS.md is the sole authoritative specification. Any new convention (e.g., escape-hatch marker syntax, `contributor::` inline field, `--ci` / `--strict` flags, version-pinning semantics) MUST be documented in AGENTS.md before or alongside code. Phase 9 explicitly amends §11.1 (ingest `--contributor`), §11.3 (CI mode + escape-hatch markers), §12 (`contributor::` log field).
2. **Date format:** ISO 8601 (`YYYY-MM-DD`). The `--version` semver output is not a date but any workflow YAML timestamps, `.git-author-map.txt` header dates, log entries, decision records must use ISO 8601.
3. **Frontmatter field names:** `snake_case` only. If any new frontmatter field appears (none planned in Phase 9 — contributor is a Dataview inline body field, not frontmatter), it must follow this convention.
4. **Commit conventions:** Conventional commits with wiki operation types. `schema:` applies to AGENTS.md amendments; feature changes use scoped conventional commits. One logical operation per commit.
5. **Privacy fail-closed semantics:** `local_only` is fail-closed default. Privacy-leak guard MUST NOT emit false negatives (silent pass through). `wiki/**` `local_only` is valid per §13; the guard targets public-facing surfaces only.
6. **DO NOT:** create topic-based directories; put conventions outside AGENTS.md; put wikilinks in YAML frontmatter; use display aliases in wikilinks. These rules do not directly bind Phase 9 script code but do bind any `CONTRIBUTING.md` or `docs/reference/ci.md` prose that uses examples.
7. **LLM navigation rule:** progressive disclosure (index.md first → TL;DR → Detail). `CONTRIBUTING.md` and `docs/reference/ci.md` must be scannable — lead with TL;DR/summary, push detail to later sections.
8. **Pre-commit hook precedent:** `.githooks/pre-commit` already exists (AGENTS.md → CLAUDE.md byte-equality enforcement). Any new pre-commit behavior (e.g., privacy-leak local check recommendation) MUST NOT be committed as a default hook — it is an operator opt-in. CONTRIBUTING.md documents the opt-in recipe.

## Standard Stack

### Core (all already in repo, zero new dependencies)

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| bash | `>= 4` (observed: 5.2.21) | Script shell for `bin/lint.sh`, `bin/ingest.sh`, `bin/search.sh`, new `bin/check-privacy.sh` | Matches Phase 7/8 baseline; universal on `ubuntu-latest` |
| python3 | `>= 3.10` (observed: 3.12.3, CI uses 3.12) | Inline heredoc blocks for YAML parsing, JSON emission, severity remap | Already invoked by `bin/lint.sh`, `bin/check-neutrality.sh` |
| PyYAML | `>= 6.0` (observed: 6.0.1) | YAML frontmatter parse in lint + privacy-leak scripts | Installed via `pip install pyyaml` in CI (Phase 7/8 precedent) |
| git | `>= 2.40` (observed: 2.43.0) | Diff-status `A` detection for `--strict`, commit authorship enumeration for D-22 contributor check | Already required by v1.0 baseline |
| GitHub Actions: `actions/checkout@v6` | v6 (current major, 2026) | Repo checkout in CI | Already used in `neutrality.yml`, `setup-parity.yml` |
| GitHub Actions: `actions/setup-python@v6` | v6 (current major, 2026) | Python 3.12 install | Already used in `neutrality.yml`, `setup-parity.yml` |
| `ubuntu-latest` runner | Ubuntu 24.04 LTS (rolled out by Oct 2025) | CI execution environment | Already used in `neutrality.yml`, `setup-parity.yml` |

### Supporting (used inline in CI workflow and scripts)

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `jq` or python3 one-liner | `jq 1.7` (observed) | JSON → `::error file=...::` annotation shim inside `lint.yml` | Phase 7 `neutrality.yml` precedent uses Python one-liners; Phase 9 may use `jq` or Python — planner's call. Prefer `python3` for consistency with existing workflows (no new `apt install`). |
| `gh` CLI | `2.45.0` (observed) | Optional — PR metadata inspection from scripts if ever needed | Not used in v1.1 CI; available on runner. |
| `cmp`, `grep`, `sed`, `diff` | bash-native | Byte-equality check, regex scan | `bin/sync-claude.sh --check` uses `cmp`; pattern consistent |

### Alternatives Considered and Rejected

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `actions/setup-python@v6` + `pip install pyyaml` | Pre-built container image with PyYAML | Container-image pinning is heavier than pip-install (which takes ~2s and is what Phase 7/8 already do). Locked by Phase 7 precedent; no reason to diverge. |
| One consolidated `lint.yml` job with all checks | Three parallel jobs (`lint`, `privacy-leak`, `strict`) | **D-16 locks three jobs.** Parallelism + failure isolation beats single-job concision. One failing ratchet must not mask structural errors. |
| `jq` annotation shim | `python3` annotation shim | Both work. `python3` is already installed (no `apt install jq` step). Planner's call; CONTEXT.md Claude's Discretion. |
| `bin/lint.sh --privacy-leak` sub-category | Standalone `bin/check-privacy.sh` | **D-12 locks standalone script.** Keeps privacy-leak out of `--skip-category` and `--version` pinning semantics; aligns with Phase 7 pattern-twin. |
| Danger-JS / reviewdog PR-comment bot | GitHub inline annotations only | **Deferred** (context: C-4 prevention). Adds bot identity + token surface; annotations cover 80% of the value. |
| Diff-only privacy-leak scan | Full-tree scan | **D-13 locks full-tree.** Catches pre-existing leaks; simpler; matches `bin/check-neutrality.sh`. |
| New frontmatter fields for attribution (`source_author`, `ingest_contributor`) | Single `contributor::` Dataview inline field | **Three-field schema deferred.** v1.1 ships single-field; revisit if ambiguity becomes a reported problem (M-8). |
| Merge-base lint run against merged-state ref | PR-branch-head lint only | **Deferred** (C-4 prevention #2). Current PR-branch-head lint already catches most cases; merge-base adds complexity for marginal coverage. |

**Installation:**
```bash
# Already covered by existing CI workflow scaffolding:
- uses: actions/checkout@v6
- uses: actions/setup-python@v6
  with:
    python-version: '3.12'
- run: pip install pyyaml
```

No new dependencies. **Zero install footprint beyond the existing v1.0/v1.1 baseline.** This is intentional per STACK.md §"Summary of New Dependencies" and PROJECT.md's zero-new-deps bias.

**Version verification:** All versions verified against current `/home/yishai/Documents/life/.github/workflows/neutrality.yml` (Phase 7) and `setup-parity.yml` (Phase 8). GitHub confirms `actions/checkout@v6` and `actions/setup-python@v6` are current majors as of 2026 (HIGH confidence — WebSearch 2026).

## Architecture Patterns

### Recommended Project Structure

```
bin/
├── lint.sh                            # MODIFIED: +--format, --ci, --strict, --skip-category,
│                                       #           --require-version, --version, --count-skips
├── ingest.sh                          # MODIFIED: +--contributor <handle>, auto-detect via
│                                       #           .git-author-map.txt, emit contributor:: in log.md
├── search.sh                          # MODIFIED: +--contributor <handle> filter
├── check-privacy.sh                   # NEW: pattern-twin of check-neutrality.sh
├── check-neutrality.sh                # UNCHANGED (Phase 7)
├── release.sh                         # UNCHANGED (Phase 7; privacy-leak integrates via pre-flight)
├── sync-claude.sh                     # UNCHANGED (Phase 7; must still pass after AGENTS.md §§11.1/11.3/12 amendments)
└── ...

.github/
├── workflows/
│   ├── lint.yml                       # NEW: three parallel jobs — lint, privacy-leak, strict
│   ├── neutrality.yml                 # UNCHANGED (Phase 7)
│   └── setup-parity.yml               # UNCHANGED (Phase 8)
└── pull_request_template.md           # NEW: per D-29 structure

CONTRIBUTING.md                        # NEW: per D-23 scope
.git-author-map.txt                    # NEW: committed, human-curated, email → @handle mapping
                                       #      (may ship empty with header comment)

docs/reference/
├── ci.md                              # MODIFIED: stub → full page per D-32
├── index.md                           # UNCHANGED structure; verify ci.md cross-link still accurate
└── ...

AGENTS.md                              # MODIFIED: §11.1 (ingest --contributor auto-detect step),
                                       #           §11.3 (CI mode + escape-hatch markers),
                                       #           §12 (contributor:: inline field)
CLAUDE.md                              # byte-identical copy, re-synced via bin/sync-claude.sh

tests/
└── phase-09/                          # NEW: test aggregator (run.sh) + per-requirement test_*.sh
    ├── run.sh
    ├── test_lint_format_json.sh       # CI-02
    ├── test_lint_ci_mode.sh           # CI-03
    ├── test_lint_skip_category.sh     # CI-04
    ├── test_lint_strict_dr_match.sh   # CI-06
    ├── test_lint_strict_new_page.sh   # CI-06
    ├── test_lint_strict_escape_hatch.sh # D-09
    ├── test_lint_version_pinning.sh   # CI-08
    ├── test_lint_contributor_check.sh # COLAB-08
    ├── test_check_privacy_clean.sh    # CI-07
    ├── test_check_privacy_leak.sh     # CI-07
    ├── test_check_privacy_wiki_ok.sh  # CI-07 (wiki/** local_only valid)
    ├── test_ingest_contributor.sh     # COLAB-04
    ├── test_ingest_single_author.sh   # COLAB-04 single-author omit
    ├── test_ingest_auto_detect.sh     # COLAB-04 auto-detect + map miss
    ├── test_search_contributor.sh     # COLAB-07
    ├── test_contributing_md.sh        # COLAB-01/05/06
    ├── test_pr_template.sh            # COLAB-02
    ├── test_lint_workflow.sh          # CI-01
    └── test_ci_docs.sh                # CI-09
```

### Pattern 1: Severity Remap Dispatcher (CI Mode)

**What:** A single table-driven remap applied after findings accumulate, before output. Keeps the remap readable (one place, one map) and testable (unit-test the map table in isolation).

**When to use:** Any time output format depends on context (CI vs. local). Phase 9 uses it for the CI severity policy.

**Example sketch (inline python3 in `bin/lint.sh`):**
```python
# CI severity remap (per CI-03, D-02)
# Applied ONLY when --ci is set; no-op otherwise.
CI_SEVERITY_REMAP = {
    # category        : ci_severity
    'yaml':             'error',
    'orphan':           'error',
    'crossref':         'error',
    'provenance':       'error',
    'stale':            'warning',
    'gap':              'warning',        # red-link / sparse
    'contradiction':    'warning',
    'contradiction-sync': 'warning',
    'drift':            'warning',        # non-external drift still surfaces
    'contributor':      'warning',        # COLAB-08 / D-22
    'autofix':          'info',
    'skip-count':       'info',           # D-09 aggregator output
}

def apply_ci_remap(findings, ci_mode):
    if not ci_mode:
        return findings
    out = []
    for sev, cat, path, msg in findings:
        new_sev = CI_SEVERITY_REMAP.get(cat, sev)
        out.append((new_sev, cat, path, msg))
    return out
```

The table is the spec — every category Phase 5/6 added has a row here; Phase 9 adds `contributor` and `skip-count`. New categories in future phases extend one line.

### Pattern 2: Pattern-Twin Script (privacy-leak ↔ neutrality)

**What:** `bin/check-privacy.sh` is structurally identical to `bin/check-neutrality.sh` — same flag conventions (`--root`, `--format text|json`, `--help`), same `PUBLIC_PATHS` bash array, same inline-python3 scanner, same exit-code convention (0 clean, 1 script failure, 2 guard-match).

**When to use:** When adding a CI guard that matches an existing one in shape. Operator muscle-memory compounds.

**Example sketch (top of `bin/check-privacy.sh`):**
```bash
#!/usr/bin/env bash
# bin/check-privacy.sh -- CI-07 privacy-leak guard.
# Scans YAML frontmatter under PUBLIC_PATHS for `privacy: local_only`.
# Pattern-twin of bin/check-neutrality.sh.
#
# Exits: 0 clean; 1 script failure; 2 privacy-leak found.
set -euo pipefail

# Public control-plane paths scanned (per CI-07 / D-15).
# wiki/** is EXCLUDED — local_only is valid user content there (AGENTS.md §13).
PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md .github)

ROOT="${PWD}"
FORMAT="text"
# ... arg parsing identical to check-neutrality.sh ...
```

Scan logic: walk `PUBLIC_PATHS` recursively, open each `.md` file, extract frontmatter block between first two `^---` markers, regex-match `^privacy:\s*local_only\s*$`. Emit hits on stderr (`path:line: privacy=local_only`) or JSON to stdout when `--format json`. Exit 2 on any hit.

### Pattern 3: Escape-Hatch Marker Parser (Strict Mode)

**What:** A precise, whitespace-sensitive regex that matches `<!-- lint:expect-inferred id=<slug> reason="..." -->` or `<!-- lint:expect-tentative ... -->` ONLY when it appears on the line **immediately before** a claim line. Prevents stale markers drifting down as pages are edited.

**When to use:** Strict-mode claim-severity filtering. Applied AFTER new `[inferred]`/`[tentative]` claims are enumerated but BEFORE they are treated as strict-mode violations.

**Example sketch:**
```python
# D-09 escape-hatch marker parser.
# Regex is strict: id + reason both required.
EXPECT_MARKER_RE = re.compile(
    r'^<!--\s*lint:expect-(inferred|tentative)\s+'
    r'id=(?P<id>[a-z0-9-]+)\s+'
    r'reason="(?P<reason>[^"]+)"\s*-->\s*$'
)

def is_claim_excepted(lines, claim_line_index, page_id):
    """True iff line above is a matching lint:expect-* marker for this page_id.
    Blank line between marker and claim INVALIDATES the exception."""
    if claim_line_index == 0:
        return False
    prev = lines[claim_line_index - 1]
    m = EXPECT_MARKER_RE.match(prev)
    if not m:
        return False
    return m.group('id') == page_id
```

Skipped claims are emitted as severity `info` (category `skip-count`) so reviewers see them inline in the PR annotations but aren't blocked. `bin/lint.sh --count-skips` aggregates these per-page for human review.

### Pattern 4: Three-Job CI Workflow (Parallel Independent Gates)

**What:** `lint.yml` declares three jobs (`lint`, `privacy-leak`, `strict`), each with its own `runs-on`, `steps`, and enforcement role. No `needs:` edges — they run in parallel. Each becomes its own required check in branch protection.

**Example sketch:**
```yaml
name: Lint + Privacy + Strict
on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Lint (CI mode + JSON)
        id: lint
        run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > lint.json || true
      - name: Convert JSON to GitHub annotations
        run: python3 .github/scripts/json-to-annotations.py lint.json
      - name: Fail if any error-severity findings
        run: bash bin/lint.sh --require-version 1.1.0 --ci   # re-run, use exit code

  privacy-leak:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Privacy-leak guard (CI-07)
        run: bash bin/check-privacy.sh

  strict:
    # D-07: skip on draft PRs; run on ready-for-review + push to main.
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 0 }   # needs full history for git diff base comparison
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      - name: Strict quality ratchet (CI-06)
        run: bash bin/lint.sh --require-version 1.1.0 --strict
```

Enforcement-model comment block at the top mirrors `neutrality.yml`'s verbatim (Section "Integration Points" below lists the canonical comment text).

### Anti-Patterns to Avoid

- **DO NOT couple `lint` and `strict` jobs.** They must fail independently. A failing ratchet masks structural errors and vice versa (D-11).
- **DO NOT put the privacy-leak guard inside `bin/lint.sh`.** It is a release/publication gate, not a wiki-health check. Bundling pollutes `--skip-category` and `--version` semantics (D-12).
- **DO NOT write `lint-report.md` in JSON mode.** Two outputs = two places to drift from each other. JSON mode is stdout-only (D-03).
- **DO NOT add new frontmatter fields for attribution.** v1.1 explicitly defers the three-field schema. `contributor::` stays a Dataview inline body field (COLAB-03).
- **DO NOT write bare email into `contributor::` field.** Preserves field shape, privacy hygiene, parser consistency (D-21). Warn to stderr and omit on auto-detect miss.
- **DO NOT call the `gh` CLI or any remote service from `bin/*.sh` in Phase 9.** All logic is local-only and CI-idempotent. No auth, no rate limits, no offline failure modes.
- **DO NOT use display-alias wikilinks (`[[A|B]]`) in CONTRIBUTING.md or ci.md examples.** Violates AGENTS.md §8. Use `[[Exact Title]]`.
- **DO NOT commit `.gitattributes` with `wiki/log.md merge=union` by default.** It is an operator opt-in documented in CONTRIBUTING.md (D-24). Default `.gitattributes` behavior must stay predictable.
- **DO NOT bump `--require-version` without bumping `LINT_VERSION`.** The constant lives near the top of `bin/lint.sh`; both change in the same PR. v1.1 convention, no CI enforcement yet (D-27).
- **DO NOT re-derive the JSON shape differently for CI vs. local.** `--format json` emits the exact tuple from `add_finding()` — no remapping of field names, no shape mutation (D-04).
- **DO NOT scan prose body text for `privacy: local_only`.** Frontmatter-only scan per D-14 — body mentions of the tier name are legitimate documentation.
- **DO NOT block PR merge on `push` trigger runs.** `push` is advisory-only. Branch protection required checks fire on `pull_request` only. (D-18, inherited from Phase 7/8.)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Convert JSON findings to PR annotations | Custom bot posting PR comments via `gh api` | GitHub inline workflow commands: `::error file=X,line=Y,col=Z::message` | Native, zero auth, no rate limit for first 10/10/50 per job; **verified current 2026 syntax**. PR-comment bots are explicitly deferred (C-4). |
| Parse `affected_pages` YAML list in decision records | Line-based regex over frontmatter | `yaml.safe_load` on the frontmatter block | Already in every inline python3 block in `bin/lint.sh`; PyYAML is in CI baseline. Hand-rolled YAML parsing is how silent-breakage starts (C-2). |
| Detect "new" pages in PR | Diff-scan the whole PR branch against `main` | `git diff --name-status origin/main...HEAD` (status `A` only, per D-10) | Git already distinguishes Added from Modified. `fetch-depth: 0` on checkout step to get base ref. |
| Look up email → GitHub handle | `gh api /users/email/:email` or WHOIS | Committed `.git-author-map.txt` at repo root | No GitHub API calls — no auth, no rate limit, no offline failure (D-21). Map is human-curated, PR-reviewed. |
| Version comparison semantics | Bash string compare or sort `-V` | Python-native `tuple(map(int, v.split('.')))` comparison inside inline python3 | One-line Python inside existing `bin/lint.sh` heredoc. Bash string compare gets edge cases wrong for semver (1.10.0 vs 1.2.0). |
| Unified-diff in annotation output | Custom hunk-extraction logic | GitHub annotations are line-level, not diff-level; just emit `file=`, `line=` | Annotations don't need diff context — they create inline commentary in the PR "Files changed" tab. |
| Counting escape-hatch markers across wiki | Custom aggregation script | Inline findings with category `skip-count`, severity `info` | D-09 aggregator is a lint-finding category; routes through the standard pipeline; no separate helper script. |
| Detecting multi-author repo | `gh api /repos/.../contributors` | `git log --all --format='%ae' | sort -u | wc -l` | Local, no network, no auth. D-20 canonical heuristic. |
| `merge=union` as a default for `wiki/log.md` | Commit `.gitattributes` with `wiki/log.md merge=union` line | Document it as operator opt-in in `CONTRIBUTING.md` | Committing the default changes git behavior for users who haven't read the doc — unpredictable (D-24). |
| Per-platform CI workflows (GitLab + Gitea + Codeberg all shipped) | Parallel YAML files for 3 providers | Ship `.github/workflows/lint.yml` canonical; document others as ~15–25 line snippets in `docs/reference/ci.md` | v1.1 does not take ownership of cross-provider test coverage (D-31). Doc-only equivalents; the portable piece is the JSON contract. |
| Rich TUI for `--count-skips` output | Colored/boxed table with rich/curses | Plain-text per-page totals + grand total via existing lint output pipeline | Zero new deps; consistent with existing lint summary format. |
| Remote-branch slug-collision check in `bin/ingest.sh` | `git fetch --all` + cross-branch `git grep` | **Deferred** in v1.1 | M-6 prevention #1 is explicit deferred work; not blocking Phase 9. |
| Post-merge link-audit auto-PR | Scheduled CI job on `main` with auto-fix PR open | **Deferred** in v1.1 | M-7 prevention #1 is explicit deferred work. `push` trigger exists for advisory visibility only (D-18). |

**Key insight:** Phase 9 is an **integration phase**, not an invention phase. Every "don't hand-roll" item above has a five-line solution using existing tooling (git, Python stdlib, PyYAML, GitHub Actions workflow commands). The complexity lives in the **policy decisions** (already resolved in CONTEXT.md), not in the implementation primitives.

## Runtime State Inventory

> Phase 9 is greenfield code/config work with no rename, refactor, or migration component. No runtime state needs auditing.

**Skipped:** Phase 9 is not a rename/refactor/migration phase. All work is additive:
- **New files:** `bin/check-privacy.sh`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, `.github/workflows/lint.yml`, `.git-author-map.txt`, `tests/phase-09/**`
- **Modified files:** `bin/lint.sh`, `bin/ingest.sh`, `bin/search.sh`, `AGENTS.md` (§11.1, §11.3, §12), `CLAUDE.md` (re-sync), `docs/reference/ci.md` (stub → full), `docs/reference/index.md` (verify cross-links accurate)
- **No existing data is renamed, removed, or migrated.** No runtime services (n8n, databases, schedulers, etc.) are in scope for this project at all.

*Per the template instruction: "Nothing found in category — verified by repo grep for rename/refactor/migration-related changes in the phase scope; all Phase 9 work is additive or amends existing text."*

## Common Pitfalls

### Pitfall 1: Severity policy becomes performative (C-4 — primary concern)

**What goes wrong:** Lint rejects legitimate PRs (e.g., a new concept page that will be fleshed out in follow-up) or accepts PRs that introduce real drift (contradictions buried inside a new concept page). Contributors learn to `--no-verify` or route around the gate; it becomes rubber stamp.

**Why it happens:** A PR lints a partial branch state with whole-vault lint rules. v1.0 lint was tuned for single-user whole-vault scans. The CI severity policy (CI-03) must distinguish **structural errors** (block) from **judgment findings** (warn).

**How to avoid:**
1. Severity remap is deterministic: `yaml`/`orphan`/`crossref`/`provenance` always block; `stale`/`gap`/`contradiction` always warn (D-02). No per-PR escalation in v1.1.
2. Escape-hatch marker (D-09) exists for intentional `[inferred]`/`[tentative]` additions. Reviewer acceptance is the human gate.
3. `--strict` runs as a separate job so a failing ratchet doesn't mask structural errors (D-11).
4. Severity-escalation policy (warning-persists-3-PRs → auto-promoted to error) is explicitly **deferred** — the escape hatch marker is v1.1's lever.

**Warning signs:**
- Contributors open meta-PRs solely to "fix lint" without addressing underlying issues.
- Escape-hatch markers accumulate faster than DRs resolve them (check with `--count-skips`).
- Branch protection required check list diverges from `lint.yml` job names.

### Pitfall 2: YAML merge conflicts in concurrent PRs (M-5)

**What goes wrong:** Two branches both append to `wiki/log.md` or both update `wiki/index.md`; 3-way merge fails with YAML-conflict markers injected into frontmatter or body.

**Why it happens:** `wiki/log.md` is append-heavy (every ingest/query/lint/reflect adds entries). `wiki/index.md` is write-heavy on ingests. Git's line-based merge is fragile against these append-only patterns.

**How to avoid:**
1. `CONTRIBUTING.md` merge-conflict recipes (D-24) explicitly walk through both files:
   - `wiki/log.md`: keep-both-sides + sort by `## [YYYY-MM-DD]` timestamp.
   - `wiki/index.md`: keep-both-sides + alphabetize within category, then re-run `bin/lint.sh` to validate.
2. Operator opt-in `.gitattributes` snippet: `wiki/log.md merge=union`. Documented as recipe, NOT committed by default.
3. `bin/normalize-frontmatter.sh` and `bin/resolve-conflict.sh` are **deferred** — document first, build tooling when real contributor usage justifies it (D-25).

**Warning signs:**
- Contributors open issues asking how to resolve `log.md` conflicts.
- Git history shows fix commits titled "resolve log.md merge" with no other substantive change.

### Pitfall 3: Attribution confusion (M-8)

**What goes wrong:** A contributor ingests a paper by researcher B. The log.md entry names contributor A (git author). A reviewer squash-merges; git `Author` becomes A but `Committer` becomes the maintainer. Downstream readers confuse "who curated" with "who authored the source."

**Why it happens:** Three roles exist (`source_author`, `ingest_contributor`, `last_modified_by`) but v1.1 uses a single inline field. Squash-merge erases authorship granularity.

**How to avoid:**
1. `CONTRIBUTING.md` COLAB-05: "Git commit authorship is the attribution source of truth; `contributor::` is a convenience index." Explicit.
2. Source summary pages (AGENTS.md §4.3) document source authors in body text — distinct from ingest contributors.
3. `CONTRIBUTING.md` recommends merge commits (not squash) for ingest PRs; squash OK for docs-only (documented note, not enforced).
4. D-22 lint check catches bogus `contributor:: @handle` values that don't appear in git commit authors — low-severity warning, non-blocking.

**Warning signs:**
- `@handle` values in `log.md` that never appear in `git log --all --format='%ae'`.
- Lint `contributor` category warnings pile up.

### Pitfall 4: Privacy-leak guard emits false negatives

**What goes wrong:** A `privacy: local_only` frontmatter line survives into `docs/**` or `examples/**` because the scanner missed it (wrong regex, wrong file scope, too-narrow scan).

**Why it happens:** Privacy semantics are fail-closed by design (AGENTS.md §13). A silent pass-through is a privacy breach.

**How to avoid:**
1. Full-tree scan (D-13) — never diff-only. Catches pre-existing leaks.
2. Frontmatter-block extraction via `^---` delimiter matching (same pattern as `bin/check-neutrality.sh` `parse_frontmatter_block`).
3. Unit tests for `bin/check-privacy.sh`:
   - Clean repo → exit 0.
   - `examples/foo.md` with `privacy: local_only` → exit 2 with path + line in output.
   - `wiki/foo.md` with `privacy: local_only` → exit 0 (valid user content).
   - Prose body `"The local_only tier is..."` in `docs/` → exit 0 (frontmatter-only scan).
4. CI job `privacy-leak` is a required status check.

**Warning signs:**
- Test fixture `examples/` file with `privacy: local_only` → scan reports clean (false negative).
- Changing the `PUBLIC_PATHS` array without review.

### Pitfall 5: `contributor::` auto-detect writes bare email on miss

**What goes wrong:** `bin/ingest.sh --contributor` auto-detect can't find the user's email in `.git-author-map.txt`; to avoid "no field" the implementer writes `contributor:: user@example.com` as a fallback.

**Why it matters:** (a) Privacy hygiene — emails are PII; (b) field-shape consistency — downstream parsers (`bin/search.sh --contributor`, D-22 lint check) expect `@handle`; (c) reverse lookup to git `%ae` breaks.

**How to avoid:**
1. D-21 explicit: "Do NOT write bare email into the field (preserves field shape, privacy hygiene, parser consistency)."
2. On miss: warn to stderr (clearly, with suggested fix), omit the field entirely.
3. Unit test: `test_ingest_auto_detect_map_miss` verifies no `contributor::` emission + stderr warning.

**Warning signs:**
- `grep -r "contributor:: [^@]" wiki/log.md` returns hits.
- D-22 lint check reports widespread reverse-lookup failures.

### Pitfall 6: Version pinning breaks PRs silently on minor bumps

**What goes wrong:** A rule change in `bin/lint.sh` ships with `LINT_VERSION="1.2.0"`. Old PRs with workflow `--require-version 1.1.0` pass (≥ check succeeds) but encounter NEW findings not present on the PR's original branch → flaky CI.

**Why it happens:** "Minimum version" semantics (D-28) mean newer versions always satisfy older pins — good for adoption, bad for reproducibility across long-lived PRs.

**How to avoid:**
1. `--require-version` semantics are explicitly "≥ X.Y.Z" (D-28). `--require-exact-version` is deferred v1.1.
2. Document in `docs/reference/ci.md`: "Pinning guarantees the minimum rule set, not exact reproduction. Rebase stale PRs onto `main` to pick up current rules."
3. Breaking changes MUST bump MAJOR (D-26). Non-breaking additions MUST bump MINOR. Contributors can tell from the version bump what to expect.

**Warning signs:**
- A rule change merged without bumping `LINT_VERSION`.
- PRs that passed last week fail today with no branch changes.

## Code Examples

### 1. Severity remap table (inside `bin/lint.sh` python3 block)

```python
# Source: derived from AGENTS.md §11.3 severity tiers + CONTEXT.md D-02
# Pattern: dispatch table; single site of truth for CI severity policy.

CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'stale':              'warning',
    'gap':                'warning',
    'contradiction':      'warning',
    'contradiction-sync': 'warning',
    'drift':              'warning',
    'contributor':        'warning',   # D-22
    'autofix':            'info',
    'skip-count':         'info',      # D-09 aggregator
}

def emit_findings(findings, ci_mode, fmt):
    if ci_mode:
        findings = [(CI_SEVERITY_REMAP.get(cat, sev), cat, path, msg)
                    for sev, cat, path, msg in findings]
    if fmt == 'json':
        import json
        payload = [
            {'severity': sev, 'category': cat, 'path': path, 'message': msg}
            for sev, cat, path, msg in findings
        ]
        print(json.dumps(payload, indent=2))  # stdout
        return
    # text mode: existing behavior
    ...
```

### 2. JSON → GitHub annotations shim (inline inside `lint.yml`)

```yaml
# Source: verified 2026 syntax per GitHub Docs; pattern-twin of Phase 7 neutrality.yml
- name: Convert JSON findings to GitHub annotations
  run: |
    python3 - << 'PYEOF'
    import json, sys
    with open('lint.json') as f:
        findings = json.load(f)
    for item in findings:
        sev = item['severity']
        # GitHub workflow commands: error, warning, notice
        cmd = {'error': 'error', 'warning': 'warning', 'info': 'notice'}.get(sev, 'notice')
        parts = [f"file={item['path']}"]
        if 'line' in item and item['line']:
            parts.append(f"line={item['line']}")
        attrs = ','.join(parts)
        # Escape newlines per GitHub Actions conventions
        msg = item['message'].replace('\r', '%0D').replace('\n', '%0A')
        print(f"::{cmd} {attrs}::{msg}")
    PYEOF
```

### 3. `bin/check-privacy.sh` core scanner (pattern-twin of `bin/check-neutrality.sh`)

```python
# Source: pattern-twin of bin/check-neutrality.sh L171-L239 (parse_frontmatter_block + scan)
import os, re, sys, json

PUBLIC_PATHS = os.environ['CP_PUBLIC_PATHS'].split(':')
ROOT = os.path.abspath(os.environ['CP_ROOT'])
FORMAT = os.environ.get('CP_FORMAT', 'text')

PRIVACY_LOCAL_ONLY_RE = re.compile(r'^privacy:\s*local_only\s*$', re.M)

def parse_frontmatter_block(text):
    if not text.startswith('---'):
        return None
    end = text.find('\n---', 3)
    if end == -1:
        return None
    return text[3:end]

def scan():
    hits = []
    for rel in PUBLIC_PATHS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            continue
        targets = [full] if os.path.isfile(full) else []
        if os.path.isdir(full):
            for dirpath, _, files in os.walk(full):
                for fn in files:
                    if fn.endswith('.md'):
                        targets.append(os.path.join(dirpath, fn))
        for t in targets:
            try:
                content = open(t, encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            fm = parse_frontmatter_block(content)
            if fm is None:
                continue
            m = PRIVACY_LOCAL_ONLY_RE.search(fm)
            if m:
                # Compute absolute line number in file
                line_no = content[:content.find('\n---', 3)].count('\n') + 1  # rough
                # Precise: count newlines from start of file to match.start() + 3
                line_no = content[:m.start() + 3].count('\n') + 1
                hits.append({
                    'path': os.path.relpath(t, ROOT),
                    'line': line_no,
                    'message': 'privacy: local_only in public path',
                })
    hits.sort(key=lambda h: (h['path'], h['line']))
    if FORMAT == 'json':
        print(json.dumps(hits, indent=2))
    else:
        for h in hits:
            print(f"{h['path']}:{h['line']}: privacy: local_only leaked", file=sys.stderr)
    sys.exit(2 if hits else 0)

scan()
```

### 4. Git-diff-based "new page" detection (`--strict` mode)

```python
# Source: D-10 definition; git diff --name-status A filter.
import subprocess

def new_pages_in_pr(base_ref='origin/main'):
    """Return list of Added (status A) .md paths under wiki/ entities|concepts|overviews|comparisons."""
    result = subprocess.run(
        ['git', 'diff', '--name-status', f'{base_ref}...HEAD'],
        check=True, capture_output=True, text=True,
    )
    new_paths = []
    for line in result.stdout.splitlines():
        parts = line.split('\t', 1)
        if len(parts) != 2:
            continue
        status, path = parts
        if status != 'A':
            continue
        if not path.endswith('.md'):
            continue
        # Must be under one of the provenance-required type dirs
        if not any(path.startswith(f'wiki/{t}/') for t in
                   ('entities', 'concepts', 'overviews', 'comparisons')):
            continue
        new_paths.append(path)
    return new_paths
```

### 5. Decision-record → affected-page matching (`--strict` mode)

```python
# Source: D-08. Load all type: decision pages in diff, union affected_pages lists.
import yaml

def collect_dr_affected_pages(diff_pages):
    """For every type: decision page in the PR diff, return set of page IDs it covers."""
    covered = set()
    for path in diff_pages:
        if not path.endswith('.md'):
            continue
        try:
            content = open(path, encoding='utf-8').read()
        except OSError:
            continue
        if not content.startswith('---'):
            continue
        try:
            end = content.index('---', 3)
            fm = yaml.safe_load(content[3:end]) or {}
        except (ValueError, yaml.YAMLError):
            continue
        if fm.get('type') != 'decision':
            continue
        for pid in (fm.get('affected_pages') or []):
            covered.add(pid)
    return covered
```

### 6. `.git-author-map.txt` format

```
# .git-author-map.txt -- email → GitHub handle map for bin/ingest.sh auto-detect.
# Format: "<email>  ->  @<github-handle>"  (two-space-arrow-two-space, or tab)
# Comments start with #. Case-insensitive match on email.
#
# Add your email → @handle here. If you maintain this as a single-author repo,
# this file can stay empty — bin/ingest.sh detects single-author and omits the
# contributor:: field entirely.

# octocat@github.com -> @octocat
```

### 7. `.github/workflows/lint.yml` skeleton (three parallel jobs)

```yaml
# Source: pattern-twin of Phase 7 neutrality.yml + Phase 8 setup-parity.yml.
#
# ENFORCEMENT MODEL (mirrors .github/workflows/neutrality.yml):
#   - `pull_request` is the HARD GATE. Branch protection rules on the public
#     repo MUST require passing runs of this workflow on PR before merging.
#     Required check names: `lint`, `privacy-leak`, `strict`.
#   - `push` to `main` is ADVISORY ONLY (post-merge visibility).
#
# Operator action required on the public remote:
#   Settings -> Branches -> Branch protection rule for `main`:
#     [x] Require status checks to pass before merging
#         Required checks: lint, privacy-leak, strict (alongside neutrality, setup-parity)
#
# See: docs/reference/ci.md for full severity policy, JSON schema, multi-provider
# equivalents, privacy-leak guard documentation, and `--require-version` pinning.

name: Lint + Privacy + Strict

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Lint (CI mode + JSON, pinned version)
        id: lint_run
        run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json
        continue-on-error: true
      - name: Convert JSON findings to GitHub annotations
        run: python3 .github/scripts/json-to-annotations.py /tmp/lint.json
      - name: Fail on error-severity findings
        if: steps.lint_run.outcome == 'failure'
        run: exit 1

  privacy-leak:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Privacy-leak guard (CI-07)
        run: bash bin/check-privacy.sh

  strict:
    # D-07: skip on draft PRs; run on ready-for-review PRs + push to main.
    if: github.event.pull_request.draft == false || github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0  # D-10 needs full history for `git diff origin/main...HEAD`
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - name: Install PyYAML
        run: pip install pyyaml
      - name: Strict quality ratchet (CI-06)
        run: bash bin/lint.sh --require-version 1.1.0 --strict
```

### 8. `.github/pull_request_template.md` (per D-29)

```markdown
## Summary

<!-- 1-2 sentences. What does this PR do? -->

## Ingest type

- [ ] new source
- [ ] update existing page(s)
- [ ] merge pages
- [ ] supersede page
- [ ] docs-only
- [ ] other (describe in Summary)

## Source attribution

<!-- URL or citation of the source being ingested. May be left blank for docs-only PRs. -->

## Privacy review

- [ ] I confirm no `privacy: local_only` frontmatter appears in public paths (examples/, docs/, AGENTS.md, CLAUDE.md, README.md, .github/). See [PRIVACY.md](PRIVACY.md).

## Lint

- [ ] `bin/lint.sh` passes locally.

<details>
<summary>lint output</summary>

```text
<!-- paste bin/lint.sh output here -->
```

</details>

## Expected findings (optional)

<!--
Intentional [inferred] or [tentative] claims or contradictions introduced
by this PR? Add escape-hatch markers on the line ABOVE the claim:

  <!-- lint:expect-inferred id=<page-id> reason="why this is inferred" -->
  - Claim text here [prov:...] [epistemic:: inferred]

See docs/reference/ci.md#escape-hatch-markers.
-->
```

## State of the Art

| Old Approach (pre-v1.1 or pre-Phase-9) | Current Approach (Phase 9) | When Changed | Impact |
|----------------------------------------|----------------------------|--------------|--------|
| `bin/lint.sh` runs once, writes only text report | Two output modes: text (existing) + `--format json` (new) — shape matches `add_finding()` tuple | Phase 9 (CI-02) | CI annotations become possible without a separate CI-only code path; single source of truth |
| All lint findings at same severity tier regardless of context | `--ci` mode applies severity remap via dispatch table | Phase 9 (CI-03, D-02) | Structural errors block merge; judgment findings warn; CI becomes actionable |
| `drift-external` (DRFT-03: .obsidian/ awareness) ran in CI, produced noise | `--ci` defaults to skipping `drift-external` via `--skip-category` | Phase 9 (CI-04, D-02) | CI doesn't fail on absent `.obsidian/` in headless runner |
| Contradictions treated as blockers | Contradictions are warnings in CI (they reflect source disagreement, not system failure) | Phase 5 decision (D-03 in Phase 5) / reinforced in Phase 9 D-02 | Contradiction-detection remains useful without being gate-closing |
| Privacy enforcement relied on reviewer vigilance | Mechanical `bin/check-privacy.sh` CI gate | Phase 9 (CI-07) | Automatic enforcement of AGENTS.md §13 privacy tiers across public paths |
| Attribution = git authorship only | Git authorship (source of truth) + `contributor:: @handle` Dataview inline index | Phase 9 (COLAB-03, COLAB-05) | Maintainers can audit one contributor's ingests via `bin/search.sh --contributor`; git stays ground truth |
| No lint-rule versioning | `bin/lint.sh --version` + `--require-version X.Y.Z` semver pinning | Phase 9 (CI-08) | Workflow YAML pins minimum rule version; breakage requires MAJOR bump (intentional signal) |
| No formal escape hatch for intentional `[inferred]`/`[tentative]` claims | `<!-- lint:expect-inferred id=... reason="..." -->` marker on line above claim | Phase 9 (D-09) | Judgment-flagged exceptions stay visible in PR review but don't block `--strict` |
| `docs/reference/ci.md` was Phase 7 stub | Fully populated: severity policy, JSON schema, privacy-leak, `--strict`, escape-hatch, `--require-version`, multi-provider | Phase 9 (CI-09, D-32) | Single place to understand CI surface; closes Phase 7 D-11 commitment |
| `bin/lint.sh` had `--category <cat>` (inclusive) only | Adds `--skip-category <cat>` (exclusive) | Phase 9 (CI-04) | Both directions of category filtering supported |

**Deprecated/outdated in Phase 9 context:**
- "Write a custom bot to post lint reports as PR comments" — GitHub inline annotations cover 80% of value; deferred.
- "Add `source_author` / `ingest_contributor` / `last_modified_by` frontmatter fields" — single `contributor::` inline field in v1.1; three-field schema deferred.
- "Maintain parallel CI configs for GitHub / GitLab / Gitea / Codeberg" — canonical GitHub workflow + doc-only snippets for others.
- "Diff-only privacy scan" — full-tree scan catches pre-existing leaks; simpler; matches Phase 7 pattern.

## Open Questions

1. **How is `fetch-depth: 0` on the `strict` job's checkout step performance-wise?**
   - What we know: Phase 8 `setup-parity.yml` uses default shallow clone + explicit `WIZARD_TEMPLATE_SHA` env var to avoid depth issues. Strict mode needs `git diff origin/main...HEAD` which requires full history.
   - What's unclear: whether a partial clone (e.g., `fetch-depth: 50`) would suffice for typical PR branch depth, or if full history is safest.
   - Recommendation: Start with `fetch-depth: 0` on the `strict` job only (lint + privacy-leak stay shallow). Revisit if CI runtime becomes a concern after real PR traffic.

2. **Annotation cap: 10 error + 10 warning + 50 total per job.**
   - What we know: verified 2026 GitHub Docs. Findings beyond the cap are silently dropped from the PR UI (logs still have them).
   - What's unclear: typical lint-finding count per PR on this repo (varies wildly with PR size).
   - Recommendation: Document the cap in `docs/reference/ci.md`. If hit, sort annotations by severity so errors appear first. Add a trailing notice: "... and N more findings — see full lint output in workflow logs."

3. **Does `--require-version` need a corresponding `schema_version` bump in AGENTS.md on breaking changes?**
   - What we know: AGENTS.md currently does not carry an explicit schema version field (last checked; §5 base fields don't include one).
   - What's unclear: whether introducing AGENTS.md `schema_version` is in scope for Phase 9 or is a separate concern.
   - Recommendation: Scope to `LINT_VERSION` only in Phase 9 (CONTEXT.md locks this). AGENTS.md schema versioning is a v1.2+ concern if ever; don't invent now.

4. **`.git-author-map.txt` case-sensitivity on email.**
   - What we know: D-21 specifies lookup against `git config user.email`. Case-sensitivity is Claude's Discretion.
   - What's unclear: whether `User@Example.com` and `user@example.com` should resolve to the same handle.
   - Recommendation: Case-insensitive email match (RFC 5321 local part is technically case-sensitive but in practice almost never used so). Document in the file's header comment.

5. **How does `bin/search.sh --contributor @octocat` interact with the existing --query mode?**
   - What we know: `--query` generates an LLM-ready prompt; `--contributor` filters `wiki/log.md` entries.
   - What's unclear: semantics when both flags are passed.
   - Recommendation: Treat `--contributor` as orthogonal — it filters results before `--query` generates the prompt. Or reject the combination in v1.1. Planner's call during design.

6. **Handling deleted-then-re-added pages in `--strict` new-page detection.**
   - What we know: D-10 says "git-diff status `A` (Added, not Modified)." But a page can be Renamed (`R`) or Deleted-and-re-Added, which presents as different statuses depending on similarity threshold.
   - What's unclear: whether Rename and Copy statuses should also be exempt.
   - Recommendation: Phase 9 treats only pure `A` as "new page." Renames/Copies inherit provenance from the source; the original page already had `[prov:]` markers. Document this in `docs/reference/ci.md` §`--strict` mode.

## Environment Availability

| Dependency | Required By | Available (local) | Version | Fallback |
|------------|-------------|-------------------|---------|----------|
| bash | All `bin/*.sh` + `.githooks/pre-commit` | ✓ | 5.2.21 | — |
| python3 | `bin/lint.sh`, `bin/check-privacy.sh` inline heredocs | ✓ | 3.12.3 | — |
| PyYAML | `bin/lint.sh`, `bin/check-privacy.sh` frontmatter parsing | ✓ | 6.0.1 | — |
| git | `bin/ingest.sh` author detect, `bin/lint.sh` `--strict` diff scan | ✓ | 2.43.0 | — |
| jq | Optional (python3 shim preferred in workflow YAML) | ✓ | 1.7 | python3 one-liner (planner may choose either) |
| gh CLI | Not required at runtime; only for manual operator tasks | ✓ | 2.45.0 | — |
| `actions/checkout@v6` | `.github/workflows/lint.yml` | ✓ (CI-side) | v6 | None — canonical version |
| `actions/setup-python@v6` | `.github/workflows/lint.yml` | ✓ (CI-side) | v6 | None — canonical version |
| `ubuntu-latest` runner | `.github/workflows/lint.yml` | ✓ (CI-side) | Ubuntu 24.04 LTS | None — canonical |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

**Confidence:** HIGH — every tool in the chain is already used in Phase 7/8 workflows and scripts. Phase 9 introduces zero new runtime dependencies (STACK.md).

## Validation Architecture

> workflow.nyquist_validation is true (default in `.planning/config.json`). Validation architecture section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Plain bash test suite via `tests/phase-NN/test_*.sh` + aggregator `tests/phase-NN/run.sh` |
| Config file | None — bash harness convention (established Phase 7/8) |
| Quick run command | `bash tests/phase-09/run.sh` |
| Full suite command | `bash tests/phase-09/run.sh && bash tests/phase-08/run.sh && bash tests/phase-07/run.sh` (regression chain) |

The phase-09 aggregator is a verbatim copy of `tests/phase-08/run.sh` (lines 1–49) renamed — same nullglob globbing, same pass/fail accounting, same `PHASE 09 TESTS: N/M` summary line. Consistency across phases is operator muscle-memory.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | `.github/workflows/lint.yml` exists with three jobs, uses v6 actions + ubuntu-latest | unit | `bash tests/phase-09/test_lint_workflow.sh` | ❌ Wave 0 |
| CI-02 | `bin/lint.sh --format json` emits array of `{severity, category, path, line?, message}` to stdout, no lint-report.md | unit | `bash tests/phase-09/test_lint_format_json.sh` | ❌ Wave 0 |
| CI-03 | `bin/lint.sh --ci` applies severity remap (blockers vs warnings) | unit | `bash tests/phase-09/test_lint_ci_mode.sh` | ❌ Wave 0 |
| CI-04 | `--ci` skips `drift-external` by default; `--skip-category` overrides | unit | `bash tests/phase-09/test_lint_skip_category.sh` | ❌ Wave 0 |
| CI-05 | Workflow YAML contains annotation shim producing `::error file=...::` lines | unit | `bash tests/phase-09/test_annotation_shim.sh` | ❌ Wave 0 |
| CI-06 (DR-match) | `--strict` passes when new `[inferred]` claim has matching DR; fails when it doesn't | unit | `bash tests/phase-09/test_lint_strict_dr_match.sh` | ❌ Wave 0 |
| CI-06 (new page) | `--strict` fails on new entity/concept/overview/comparison page with zero `[prov:` | unit | `bash tests/phase-09/test_lint_strict_new_page.sh` | ❌ Wave 0 |
| CI-06 (escape hatch) | `<!-- lint:expect-inferred id=... reason="..." -->` on line above exempts claim | unit | `bash tests/phase-09/test_lint_strict_escape_hatch.sh` | ❌ Wave 0 |
| CI-07 (clean) | `bin/check-privacy.sh` exits 0 on clean repo | unit | `bash tests/phase-09/test_check_privacy_clean.sh` | ❌ Wave 0 |
| CI-07 (leak) | `bin/check-privacy.sh` exits 2 on `privacy: local_only` in `examples/`, `docs/`, etc. | unit | `bash tests/phase-09/test_check_privacy_leak.sh` | ❌ Wave 0 |
| CI-07 (wiki valid) | `bin/check-privacy.sh` exits 0 on `privacy: local_only` inside `wiki/` | unit | `bash tests/phase-09/test_check_privacy_wiki_ok.sh` | ❌ Wave 0 |
| CI-08 (--version) | `bin/lint.sh --version` prints `1.1.0` and exits 0 | unit | `bash tests/phase-09/test_lint_version.sh` | ❌ Wave 0 |
| CI-08 (pinning) | `--require-version 1.2.0` fails when LINT_VERSION is 1.1.0 | unit | `bash tests/phase-09/test_lint_require_version.sh` | ❌ Wave 0 |
| CI-09 | `docs/reference/ci.md` exists with severity table, JSON schema, GitLab + Gitea + Codeberg sections | unit | `bash tests/phase-09/test_ci_docs.sh` | ❌ Wave 0 |
| COLAB-01 | `CONTRIBUTING.md` exists with required sections | unit | `bash tests/phase-09/test_contributing_md.sh` | ❌ Wave 0 |
| COLAB-02 | `.github/pull_request_template.md` has 6 sections per D-29 | unit | `bash tests/phase-09/test_pr_template.sh` | ❌ Wave 0 |
| COLAB-03 | AGENTS.md §12 documents `contributor:: @handle` inline field | unit | `bash tests/phase-09/test_agents_section_12.sh` | ❌ Wave 0 |
| COLAB-04 (single) | `bin/ingest.sh` on single-author repo omits `contributor::` | integration | `bash tests/phase-09/test_ingest_single_author.sh` | ❌ Wave 0 |
| COLAB-04 (auto) | `bin/ingest.sh` auto-detect via `.git-author-map.txt` hit | integration | `bash tests/phase-09/test_ingest_auto_detect.sh` | ❌ Wave 0 |
| COLAB-04 (miss) | `bin/ingest.sh` auto-detect miss → warn + omit (no bare email) | integration | `bash tests/phase-09/test_ingest_auto_detect_miss.sh` | ❌ Wave 0 |
| COLAB-04 (explicit) | `bin/ingest.sh --contributor @handle` overrides detection | integration | `bash tests/phase-09/test_ingest_contributor_explicit.sh` | ❌ Wave 0 |
| COLAB-05 | `CONTRIBUTING.md` states git authorship as source of truth | unit | (covered by `test_contributing_md.sh`) | ❌ Wave 0 |
| COLAB-06 | `CONTRIBUTING.md` includes merge-conflict recipes for log.md + index.md | unit | (covered by `test_contributing_md.sh`) | ❌ Wave 0 |
| COLAB-07 | `bin/search.sh --contributor @handle` filters log entries | unit | `bash tests/phase-09/test_search_contributor.sh` | ❌ Wave 0 |
| COLAB-08 | `bin/lint.sh` `contributor` category warns on handle mismatch with git authors | integration | `bash tests/phase-09/test_lint_contributor_check.sh` | ❌ Wave 0 |
| — | `bin/sync-claude.sh --check` passes after AGENTS.md §§11.1/11.3/12 amendments | unit | (covered by existing `tests/phase-07/test_sync_claude.sh` regression) | ✓ |
| — | `bin/lint.sh` regression (existing v1.0 checks still pass on example wiki) | integration | (existing wiki fixtures; no new test needed) | ✓ |
| — | Phase 7 regression (neutrality, denylist, release) | integration | `bash tests/phase-07/run.sh` | ✓ |
| — | Phase 8 regression (wizard + manual + byte-equality) | integration | `bash tests/phase-08/run.sh` | ✓ |

### Sampling Rate

- **Per task commit:** `bash tests/phase-09/run.sh` — runs Phase 9 tests only (~15-20 tests, fast).
- **Per wave merge:** `bash tests/phase-09/run.sh && bash tests/phase-08/run.sh && bash tests/phase-07/run.sh` — phase + regression chain.
- **Phase gate:** Full suite green (all three phases) before `/gsd:verify-work`. Plus all three CI jobs (`lint`, `privacy-leak`, `strict`) green on the phase branch's PR into `main`.

### Wave 0 Gaps

- [ ] `tests/phase-09/run.sh` — aggregator (copy + rename from `tests/phase-08/run.sh`)
- [ ] `tests/phase-09/lib.sh` — optional shared helpers (follow Phase 8 pattern); temp-repo fixtures, setup_git_author helper
- [ ] `tests/phase-09/fixtures/` — fixture repos for `--strict` DR-matching + escape-hatch + privacy-leak scenarios
- [ ] All `test_*.sh` files listed in the map above (roughly 20 new tests)
- [ ] No framework install needed — bash + existing python3 + PyYAML already present

*(If existing test infrastructure already covers a row, the row in the table has ✓ under File Exists.)*

## Sources

### Primary (HIGH confidence)

- **`/home/yishai/Documents/life/AGENTS.md`** §11.1 (ingest workflow, lines 1175–1206), §11.3 (lint workflow, lines 1319–1368), §12 (index + log, lines 1446–1516), §13 (privacy routing, lines 1517+), §4.6 (decision records, earlier in file). Read in full for the base contract Phase 9 amends.
- **`/home/yishai/Documents/life/bin/lint.sh`** (1131 lines) — `add_finding()` tuple signature (line 188–189), `should_run()` category filter (line 209), all 10 checks with their severity assignments, report generation (line 1017+). This IS the canonical JSON shape.
- **`/home/yishai/Documents/life/bin/check-neutrality.sh`** (393 lines) — structural twin pattern, `PUBLIC_PATHS` array (line 94), `parse_frontmatter_block` (line 171), scan loop (line 187), exit codes (0/1/2).
- **`/home/yishai/Documents/life/bin/ingest.sh`** (252 lines) — log.md append site, arg-parsing skeleton, slug sanitization, UTC date policy.
- **`/home/yishai/Documents/life/bin/search.sh`** (286 lines) — flag-parsing convention for `--contributor` addition; current modes (default, `--paths-only`, `--fulltext`, `--query`).
- **`/home/yishai/Documents/life/.github/workflows/neutrality.yml`** (43 lines) — enforcement-model comment block verbatim reference.
- **`/home/yishai/Documents/life/.github/workflows/setup-parity.yml`** (56 lines) — three-step pattern (checkout, setup-python, pip install pyyaml), env-var determinism pattern.
- **`/home/yishai/Documents/life/.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md`** — all 32 locked decisions.
- **`/home/yishai/Documents/life/.planning/REQUIREMENTS.md`** §COLAB (lines 63–70), §CI (lines 73–82), traceability table (lines 200–216).
- **`/home/yishai/Documents/life/.planning/ROADMAP.md`** §Phase 9 (lines 70–80) — goal + 5 success criteria + 17 REQ-IDs.
- **`/home/yishai/Documents/life/docs/reference/ci.md`** — current stub (9 lines), confirms "populated in Phase 9" commitment.
- **`/home/yishai/Documents/life/docs/reference/index.md`** — cross-link map (ci.md → Phase 9 ownership).
- **GitHub Docs 2026:** Workflow commands — `::error file=...,line=...,col=...::message` and `::warning` syntax verified. [Workflow commands for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)
- **GitHub Docs 2026:** Annotation limits — 10 error + 10 warning + 50 total per job. [Workflow commands for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)

### Secondary (MEDIUM confidence)

- **`.planning/research/ARCHITECTURE.md`** §Decision 3 (contributor field, lines 70–95), §Decision 6 (PR lint gate JSON flag, lines 157–185). Informs architecture choices; not re-litigated.
- **`.planning/research/PITFALLS.md`** §C-4 (lint gate too strict/too loose, lines 94–119), §M-5 (YAML merge conflicts, lines 209–229), §M-8 (attribution confusion, lines 267–287), §m-7 (local_only accidentally pushed, line 410+).
- **`.planning/research/FEATURES.md`** §Bucket 4 (Git-Based PR Workflow for Collaborative Curation, lines 132–177). Confirms table stakes, differentiators, anti-features.
- **`.planning/research/STACK.md`** §"CI (PR Lint Gate)" (lines 70+). Confirms `actions/checkout@v6` + `actions/setup-python@v6` + `ubuntu-latest` are canonical as of 2026.
- **Gitea Docs — Actions Comparison to GitHub Actions:** schema-compatible with caveats (runs-on single-value, Go actions supported, absolute-URL `uses` supported). [Compared to GitHub Actions | Gitea Documentation](https://docs.gitea.com/usage/actions/comparison)
- **`actions/setup-python` releases:** v6 is current major as of 2026. [Releases · actions/setup-python](https://github.com/actions/setup-python/releases)

### Tertiary (LOW confidence, no asserted facts ride on these)

- WebSearch hits on "Gitea Actions 2026 schema" — content confirms compatibility but does not provide a canonical 2026 migration guide. Planner may need to verify runner-image one-liner equivalents (Codeberg/Forgejo) against current docs at implementation time.
- Annotation-limit edge cases (how the UI behaves when exactly 50 annotations are hit) — documented behavior is "silently dropped"; no author tested.

## Metadata

**Confidence breakdown:**

- Standard stack: **HIGH** — all versions pinned by in-repo workflow files; zero new dependencies.
- Architecture patterns: **HIGH** — severity remap, pattern-twin, three-job layout all precedented in Phase 7/8 code (`bin/check-neutrality.sh`, `.github/workflows/neutrality.yml`, `setup-parity.yml`).
- Pitfalls: **HIGH** — all six pitfalls sourced from PITFALLS.md (C-4, M-5, M-8, m-7) plus novel ones derived from D-14 (false-negative privacy), D-21 (bare-email leak), D-28 (version pin semantics).
- Code examples: **HIGH** — all sketches reference real line numbers in current `bin/lint.sh`, `bin/check-neutrality.sh`, or verified GitHub Actions workflow-command syntax.
- Annotation syntax: **HIGH** — verified 2026 via GitHub Docs; matches current syntax used in the wild.
- Multi-provider equivalents: **MEDIUM** — GitHub Actions and Gitea schema compat verified; GitLab / Codeberg specifics left to planner to confirm against current provider docs at implementation time.

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (30 days — stable surface; GitHub Actions action versions and annotation syntax are slow-moving)
