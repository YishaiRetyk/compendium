# Phase 9: Collaborative PR Workflow + CI Lint Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 09-collaborative-pr-workflow-ci-lint-gate
**Areas discussed:** Lint --ci / --format json, --strict quality ratchet, Privacy-leak guard, CI workflow layout, Contributor field, CONTRIBUTING.md, --require-version pinning, PR template, Multi-provider CI docs

---

## Area 1 — Lint `--ci` / `--format json` output shape

### Q1.1 — Flag independence

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Independent | `--format json` and `--ci` orthogonal; either alone or combined | ✓ |
| 2. `--ci` implies `--format json` | Single flag for CI | |
| 3. `--ci` is a full profile (JSON + skip drift-external) | One flag = entire profile | |

**User's choice:** 1 — Independent
**Notes:** Orthogonal flags easier to reason about; enables local JSON preview and local CI-severity preview separately.

### Q1.2 — JSON destination

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Stdout only; no lint-report.md | Clean text/json separation | ✓ |
| 2. Stdout AND write lint-report.md | Both at once | |
| 3. Stdout + write lint-report.json | Two artifacts | |

**User's choice:** 1 — Stdout only
**Notes:** "text mode = human report behavior; json mode = machine output behavior" — crisp contract; no `--dry-run` special-case needed.

### Q1.3 — Exit-code semantics in `--ci`

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Exit 1 on blocker-severity only | Warnings don't block | ✓ |
| 2. Always exit 0; GitHub required-check drives gate | Decoupled | |
| 3. Exit 1 on error OR warning | Stricter; conflicts with CI-03 | |

**User's choice:** 1 — Exit 1 on blockers only
**Notes:** Conventional CI semantics; matches CI-03 severity split.

**User refinement to D-01:** Rewrite to "CI applies the CI severity policy and defaults to skipping drift-external; `--skip-category` remains available as an explicit override" — avoid implying opaque coupling.

**User simplification to D-02:** Drop the `--dry-run` interaction language. Just say: "`--format json` writes JSON to stdout only; when `--format json` is set, lint-report.md is not written." Final captured contract:
- text mode = human report behavior
- json mode = machine output behavior
- ci mode = severity-remap + drift-external skip profile
- flags remain orthogonal

---

## Area 2 — `--strict` quality ratchet

### Q2.1 — Trigger

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Every PR (hard gate) | Strongest guarantee | |
| 2. Merge-to-main only | No PR friction; late catch | |
| 3. Every PR to main; skipped on draft PRs | Ready-for-review gate | ✓ |

**User's choice:** 3 — Ready-for-review PRs (skip drafts)
**Notes:** "Drafts are the whole point of surfacing WIP before ratchet applies; avoids misuse of escape hatch just to keep drafts moving." Plus regression run post-merge on main.

### Q2.2 — Matching decision record rule

| Option | Description | Selected |
|--------|-------------|----------|
| 1. DR in PR diff with `affected_pages` containing the page ID | Uses AGENTS.md §4.6 schema | ✓ |
| 2. DR filename contains page slug | Simpler grep; fragile | |
| 3. Any relevant-type DR in diff | Less precise | |

**User's choice:** 1 — `affected_pages` linkage
**Notes:** Already in schema, mechanically checkable, more robust than filename heuristics, more precise than "some DR exists."

### Q2.3 — Escape hatch

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `<!-- lint:expect-inferred id=... reason="..." -->` inline marker | Local, auditable, visible in diff | ✓ |
| 2. No escape hatch | Highest friction; DR inflation risk | |
| 3. `[skip-strict]` commit message token | Repo-level opt-out; invisible in code | |

**User's choice:** 1 — Inline escape hatch
**Notes:** Parser must be strict: marker immediately above claim (no blank line), `id` must match containing page, `reason` required and non-empty. Skipped findings surface in JSON as `info`.

### Q2.4 — "New page lacking provenance" definition

| Option | Description | Selected |
|--------|-------------|----------|
| 1. New + synthesis type (entity/concept/overview/comparison) + zero `[prov:` | Scoped correctly; exempts source + decision | ✓ |
| 2. Any new page with zero `[prov:` | Over-fires on decision pages | |
| 3. Density threshold | Hard to define; C-4 pitfall | |

**User's choice:** 1 — Added synthesis pages only
**Notes:** Source and decision pages exempt by design (different support models).

**User refinement to D-04:** Change trigger from "every PR hard gate" to "ready-for-review PRs + post-merge regression on main; skip or advisory on draft PRs." Keep D-05, D-06, D-07 as drafted.

---

## Area 3 — Privacy-leak guard

### Q3.1 — Location

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Standalone `bin/check-privacy.sh` | Phase 7 neutrality twin pattern | ✓ |
| 2. New `privacy-leak` category in `bin/lint.sh` | Leverages lint infra; couples to `--skip-category` | |
| 3. Inline grep in workflow YAML | Zero files; hard to test locally | |

**User's choice:** 1 — Standalone script
**Notes:** Privacy leak is a release/publication gate, not ordinary wiki-health lint; keeps responsibilities clean.

### Q3.2 — Scan scope

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Full tree on each run | Matches Phase 7 pattern; catches pre-existing drift | ✓ |
| 2. Diff-only against merge-base | Faster; pre-existing leaks can persist | |
| 3. Full tree + diff annotation | Hybrid | |

**User's choice:** 1 — Full tree
**Notes:** Simpler, robust, catches existing leaks.

### Q3.3 — Public-paths glob configuration

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Hardcoded `PUBLIC_PATHS` bash array | Matches Phase 7; change via PR | ✓ |
| 2. Workflow env var | Runtime flexibility; forks may loosen | |
| 3. External `.privacy-public-paths.txt` file | Still PR-scoped | |

**User's choice:** 1 — Hardcoded array
**Notes:** Correct review loop is "change via PR"; runtime override via workflow env would enable casual loosening. Scan is frontmatter-block only — not whole-file prose.

---

## Area 4 — CI workflow layout

### Q4.1 — File organization

| Option | Description | Selected |
|--------|-------------|----------|
| 1. One `lint.yml` with three jobs | Parallel; single file; independent required checks | ✓ |
| 2. Three separate files | Literal one-concern-per-file | |
| 3. One file, one job, sequential steps | Short-circuits hide later failures | |

**User's choice:** 1 — One file, three jobs
**Notes:** Preserves parallelism, independent failure visibility, and separate required checks without workflow-file sprawl. Sibling to existing `neutrality.yml` + `setup-parity.yml` — older concerns stay separate.

### Q4.2 — Required-check names

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Short: `lint`, `privacy-leak`, `strict` | Match job names | ✓ |
| 2. Composite: `lint / lint`, `lint / privacy-leak`, ... | Unambiguous origin | |
| 3. Matrix producing per-category checks | Over-engineered | |

**User's choice:** 1 — Short names
**Notes:** Cleaner for branch protection, PR status display, docs.

---

## Area 5 — Contributor field + single-author detection

### Q5.1 — Handle format

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `@github-handle` | GitHub-native; matches PR mentions | ✓ |
| 2. Bare handle | Ambiguous (name vs handle) | |
| 3. Email | Verbose; privacy surface | |

**User's choice:** 1 — `@github-handle`

### Q5.2 — Single-author detection

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `git log --all --format='%ae' | sort -u | wc -l == 1` | Deterministic; no config | ✓ |
| 2. Repo config opt-in | Explicit; setup step | |
| 3. Explicit opt-out flag every time | Friction-heavy | |

**User's choice:** 1 — Git-history check at ingest time
**Notes:** Mirror-safe; reproducible on fresh clone.

### Q5.3 — Handle resolution flow

| Option | Description | Selected |
|--------|-------------|----------|
| 1a. Git config email → `.git-author-map.txt` lookup; fall back to bare email | Stable; explicit map | |
| 1b. Git config email → map; if miss, warn + OMIT field (no email fallback) | Preserves field shape, privacy hygiene | ✓ |
| 2. Strip `@domain` from email | Works for noreply; breaks for corp emails | |
| 3. Require `--contributor` always on multi-author | High friction | |

**User's choice:** 1b — Warn + omit on map miss (modified D-15)
**Notes:** User rejected bare-email fallback — "breaks the field's declared shape; leaks identifying info; inconsistent Dataview/search semantics." Rule: warn + omit + suggest re-run with `--contributor` or add mapping.

### Q5.4 — Lint check (CI-08)

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Low-severity warning via handle↔git-author map | Matches CI-08 wording | ✓ |
| 2. Error-level: block merge | Over-strict | |
| 3. No lint check | Ignores CI-08 | |

**User's choice:** 1 — Low-severity warning
**Notes:** Does NOT block CI. Skipped in `--ci` mode when single-author detection already suppressed the field.

**User refinement to D-15:** No bare-email fallback. If map miss: warn clearly + omit field + suggest add mapping or use `--contributor @handle`.

---

## Area 6 — CONTRIBUTING.md + merge-conflict recipes

### Q6.1 — Scope

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Focused: PR workflow + merge-conflict recipes + attribution + privacy | Matches COLAB-01 wording | ✓ |
| 2. Full governance (CoC, review policy, release cadence) | Scope explosion | |
| 3. Minimal one-paragraph | Fails COLAB-06 | |

**User's choice:** 1 — Focused
**Notes:** Avoids turning collaboration how-to into full governance doc; honest about maturity.

### Q6.2 — Merge-conflict recipe format

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Narrative + copy-pasteable commands; optional `.gitattributes` hint | Concrete; no premature helper-script API | ✓ |
| 2. `bin/resolve-conflict.sh` helper | Scope creep; needs tests | |
| 3. `.gitattributes merge=union` only | Opaque to users | |

**User's choice:** 1 — Narrative + commands
**Notes:** `.gitattributes wiki/log.md merge=union` documented as operator opt-in (not committed default). **User added refinement:** index.md recipe must explicitly say "re-run lint after manual resolution" — validation step after re-alphabetizing.

### Q6.3 — Frontmatter-normalization helper

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Defer to backlog / v1.2 | Build when usage data supports | ✓ |
| 2. Ship `bin/normalize-frontmatter.sh` in Phase 9 | Proactive; wrong-abstraction risk | |

**User's choice:** 1 — Defer
**Notes:** Helpers built after real usage reveals pain, not before.

---

## Area 7 — Lint `--require-version` pinning

### Q7.1 — Version string format

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Semver `MAJOR.MINOR.PATCH` | Standard | ✓ |
| 2. Date-based | No breaking-intent signal | |
| 3. Commit-hash | Opaque | |

**User's choice:** 1 — Semver, initial `1.1.0`.

### Q7.2 — Version storage

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `LINT_VERSION` constant at top of `bin/lint.sh` | Colocated with rules | ✓ |
| 2. Separate `bin/LINT_VERSION` file | Drift risk | |
| 3. Derived from git tag | Brittle in shallow clones | |

**User's choice:** 1 — Inline bash constant
**Notes:** Changes ride in same PR as rule changes (review convention, no CI enforcement in v1.1).

### Q7.3 — Pinning mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `--require-version X.Y.Z` flag | Explicit; visible in CI logs | ✓ |
| 2. Implicit `.lint-version` file | Invisible dependency | |
| 3. `LINT_MIN_VERSION` env var | Same shape, different surface | |

**User's choice:** 1 — `--require-version` flag
**User refinement:** Explicitly document as **minimum version (>= X.Y.Z)**. If exact-pin needed later, add a separate `--require-exact-version` flag.

---

## Area 8 — PR template

### Q8.1 — Checkbox set

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Minimal + targeted (ingest type + source attribution + privacy + lint + expected-findings) | Covers COLAB-02 + D-06 integration | ✓ |
| 2. Full contributor-friendly (change summary, tests, reviewers, docs) | Longer; abandonment risk | |
| 3. Minimal without privacy checkbox | Misses Bucket 4 differentiator | |

**User's choice:** 1 — Minimal + targeted

### Q8.2 — Tone

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Terse/mechanical (bullets + one-line prompts) | Matches Phase 7/8 voice | ✓ |
| 2. Prose/welcoming | Warmer; longer | |

**User's choice:** 1 — Terse/mechanical
**User refinement:** Source attribution note — "may be left blank for docs-only PRs" so contributors don't feel they're violating the template.

---

## Area 9 — Multi-provider CI docs depth

### Q9.1 — Depth

| Option | Description | Selected |
|--------|-------------|----------|
| 1. One-liner + copyable snippet per provider | Concrete + maintainable | ✓ |
| 2. Full working workflow files per provider | Maintenance cost; no verification infra | |
| 3. Prose only, no YAML | Misses differentiator | |

**User's choice:** 1 — One-liner + snippets

### Q9.2 — Provider set

| Option | Description | Selected |
|--------|-------------|----------|
| 1. GitLab CI + Gitea Actions + Codeberg (Forgejo) | Matches CI-09 | ✓ |
| 2. Add Bitbucket Pipelines | Not in CI-09 | |
| 3. Add Jenkins/Drone | Expands surface | |

**User's choice:** 1 — GitLab + Gitea + Codeberg
**Notes:** `docs/reference/ci.md` closes Phase 7's "stub filled in Phase 9" promise — single place documenting severity policy, JSON schema, privacy guard, strict mode, escape-hatch markers, version pinning, and provider equivalents.

---

## Claude's Discretion

- Exact stdout formatting + exit codes + flag-parsing details for `bin/check-privacy.sh` (mirror `bin/check-neutrality.sh`).
- Internal shape of `bin/lint.sh` severity-remap dispatcher.
- `.git-author-map.txt` format edge cases (trailing whitespace, duplicate email, case-sensitivity).
- Bash regex for escape-hatch marker parser and the `--count-skips` aggregator.
- `bin/search.sh --contributor` handle normalization (recommend accept both `@octocat` and `octocat`).
- CI job `needs:` edges inside `lint.yml` (recommend full parallelism).
- Escape-hatch marker parser location (inline vs helper).
- Failure-message wording across new flags and scripts.

## Deferred Ideas

- `bin/normalize-frontmatter.sh`, `bin/resolve-conflict.sh`, `bin/rename-page.sh`, `bin/update-contributor-index.sh`
- Three-field attribution schema (`source_author` / `ingest_contributor` / `last_modified_by`)
- Post-merge lint auto-fix PR, merge-base lint comparison, severity-escalation policy (`.lint-state.json`)
- Gap-detection `--exempt-pr-new` flag
- `--require-exact-version` flag
- Lint-report PR-comment bot (Danger-JS / reviewdog)
- Bitbucket / Jenkins / Drone provider equivalents
- `.pending-topics.md` branch-coordination file, `bin/ingest.sh` remote-branch slug-collision check
- Committing `.gitattributes wiki/log.md merge=union` as a default (stays operator opt-in)
