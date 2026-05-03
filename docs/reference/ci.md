# CI Lint Gate

> Reference documentation for Phase 9 CI surface: lint severity policy, JSON output, privacy-leak guard, `--strict` mode, escape-hatch markers, `--require-version` pinning, and multi-provider workflow equivalents.

## TL;DR

Every PR triggers three parallel CI jobs on GitHub Actions (see [`.github/workflows/lint.yml`](../../.github/workflows/lint.yml)):

- `lint` — `bin/lint.sh --ci --format json` — structural errors block merge, judgment findings warn.
- `privacy-leak` — `bin/check-privacy.sh` — `privacy: local_only` frontmatter in public paths fails PR.
- `strict` — `bin/lint.sh --strict` — unmatched `[inferred]`/`[tentative]` claims or new pages without provenance fail PR (skipped on draft PRs).

All three jobs are required status checks in branch protection on `main`.

## Severity policy

> **Source of truth:** The authoritative severity mapping lives in [AGENTS.md §11.3 "CI mode"](../../AGENTS.md). This page reproduces the table for ergonomic reference and adds **rationale** for each category — the mapping itself must stay in sync with §11.3. If you find a discrepancy, §11.3 wins and this page is the bug.

`bin/lint.sh --ci` applies the following severity remap via a single dispatch table (keeps rule changes auditable in one place).

| Category | Severity (CI mode) | Rationale |
|----------|--------------------|-----------|
| `yaml` | error | Parse failure — page unreadable by tooling. |
| `orphan` | error | Broken wiki structure — page unreachable from index. |
| `crossref` | error | Broken wikilink — navigation failure. |
| `provenance` | error | Claim without source — schema requirement (AGENTS.md §6). |
| `stale` | warning | Decay-date exceeded — content review recommended, not required. |
| `gap` | warning | Red link with multiple references — knowledge gap signal. |
| `contradiction` | warning | Source disagreement — scholarly expectation, not system failure (Phase 5 decision). |
| `contradiction-sync` | warning | `has_contradictions` frontmatter out of sync with body markers. |
| `drift` | warning | Cross-system drift (content-hash, index coverage). |
| `contributor` | warning | `contributor:: @handle` mismatch with git commit authors (non-blocking audit). |
| `autofix` | info | Mechanical fix applied (e.g., stale marker updated). |
| `skip-count` | info | Escape-hatch marker exempted a claim. |

**Exit code:** `--ci` exits 1 iff any post-remap finding has severity `error`. Warnings and info-only runs exit 0.

**Default skips under `--ci`:** `drift-external` (DRFT-03 requires local Obsidian/Zotero state; headless CI cannot satisfy it).

**Overriding the defaults:** `bin/lint.sh --ci --skip-category <cat>` is an explicit override. `--skip-category` is also available outside `--ci` mode as the inverse of `--category`.

## JSON output schema

> **Source of truth:** [AGENTS.md §11.3 "CI mode"](../../AGENTS.md). The JSON shape is defined there; this section reproduces it with field-level documentation. Schema changes land in AGENTS.md first.

`bin/lint.sh --format json` writes a single JSON array to stdout. Shape matches the internal `add_finding()` tuple exactly — no schema divergence between local and CI findings.

```json
[
  {
    "severity": "error",
    "category": "yaml",
    "path": "wiki/concepts/broken.md",
    "line": 5,
    "message": "yaml: could not parse frontmatter"
  },
  {
    "severity": "warning",
    "category": "stale",
    "path": "wiki/entities/einstein.md",
    "message": "claim checked_at 2025-03-01 exceeds domain decay (science: 730 days)"
  }
]
```

**Fields:**

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `severity` | yes | string | One of `error`, `warning`, `info`. Post `--ci` remap if `--ci` was set. |
| `category` | yes | string | One of the categories listed above. |
| `path` | yes | string | Path relative to repo root. |
| `line` | no | integer | 1-indexed line number when the finding has a specific location. |
| `message` | yes | string | Human-readable description. May include references to fix hints. |

`--format json` mode does NOT write `wiki/maintenance/lint-report.md`. Stdout is the single output stream.

## Privacy-leak guard

`bin/check-privacy.sh` is a standalone script (pattern-twin of `bin/check-neutrality.sh`) that scans YAML frontmatter under **public paths** for `privacy: local_only`.

**Public paths (hardcoded in `bin/check-privacy.sh`):**

- `examples/`
- `docs/`
- `AGENTS.md`
- `CLAUDE.md`
- `README.md`
- `.github/`

**Explicitly EXCLUDED:** `wiki/**`. `local_only` is valid user content there — see [PRIVACY.md](../../PRIVACY.md) and [AGENTS.md §13](../../AGENTS.md).

**Scan scope:** Full tree, frontmatter-only (body-text mentions of the tier name in prose are NOT flagged).

**Exit codes:**

- `0` — clean
- `1` — script failure (missing Python 3 / PyYAML / bad args)
- `2` — privacy-leak found; stderr carries `path:line:` entries

**Changing public paths:** The `PUBLIC_PATHS` array in `bin/check-privacy.sh` is hardcoded. Expanding or contracting the scope requires a PR — this is the intentional review loop.

## `--strict` mode (quality ratchet)

`bin/lint.sh --strict` is a merge-time quality ratchet, separate from `--ci`. The `strict` CI job runs it on every ready-for-review PR (`draft == false`).

**What it fails on:**

1. **Unmatched inferred/tentative claims:** A wiki page contains `[epistemic:: inferred]` or `[epistemic:: tentative]` but no `type: decision` page in the wiki has the containing page's `id` in its `affected_pages` frontmatter list (AGENTS.md §4.6).
2. **New pages without provenance:** A git-diff status `A` (Added) page under `wiki/{entities,concepts,overviews,comparisons}/` has zero `[prov:...]` markers in body. Source pages (`type: source`) and decision records (`type: decision`) are exempt by design (different support models per AGENTS.md §4.3/§4.6).

**What it does not fail on:** Everything the `--ci` mode warns about (stale, gap, contradiction). Those stay warnings.

**Draft PRs:** The `strict` job is skipped on draft PRs (GitHub job conditional `if: github.event.pull_request.draft == false || github.event_name == 'push'`). Mark a PR ready-for-review to trigger the ratchet.

**`fetch-depth: 0`:** The `strict` job's checkout step uses full history so `git diff --name-status origin/main...HEAD` resolves correctly. Other jobs use shallow clones.

## Local pre-commit write gate (Phase 12.2)

> **Source of truth:** The authoritative specification lives in [AGENTS.md §11.3 "CI mode"](../../AGENTS.md). This page reproduces the install + bypass commands for ergonomic reference — the rules themselves (exemption ordering, exit codes, scope) must stay in sync with §11.3. If you find a discrepancy, §11.3 wins and this page is the bug.

`bin/lint.sh --staged` is a local-only scope swap that gates new synthesized wiki pages over the **staged index** (not `origin/main...HEAD`), so structurally invalid writes are caught BEFORE they land in local history. The CI `--strict` job remains the merge-time ratchet; this is the pre-commit-time complement.

**What it fails on:**

- A page staged as git-diff status `A` under `wiki/{entities,concepts,overviews,comparisons}/` with zero `[prov:...]` markers in the body. This is D-10 (new-page provenance) ONLY — D-08 (DR-match for added inferred/tentative claims) is enforced by the CI `strict` job, not the local gate.

**What it does not fail on:** see the AGENTS.md §11.3 "Staged-mode rules" subsection for the full exemption ordering. Summary: pages outside the four required-types directories, anything under `examples/`, `type: source` or `type: decision` pages, `example: true`, and `bootstrap_stage: bootstrapped` are exempt; `bootstrap_stage: verified` is NOT exempt.

**How to install:**

```sh
bash bin/install-hooks.sh
```

Activates `core.hooksPath=.githooks`, which composes the existing AGENTS.md ↔ CLAUDE.md sync check with the new write-gate.

**How to bypass (rarely):**

```sh
git commit --no-verify
```

Per AGENTS.md §3, `--no-verify` is the only operator escape; document the reason in the commit message when used. There is no `WGATE_SKIP=1` env var and no per-page `wgate_exempt: true` frontmatter — those would create permanent bypass surfaces and are explicitly rejected.

**How to fix a blocked commit:**

1. Add `[prov:source_id#locator]` markers to the page body. This is the primary fix.
2. If the page is a source summary or decision record (not a synthesized page), set `type: source` or `type: decision` in frontmatter — it should not have been gated; review the page type.
3. As a last resort, `git commit --no-verify` to bypass and follow up with provenance markers in the next commit.

## Escape-hatch markers

Intentional `[inferred]` or `[tentative]` claims that do not yet have a matching decision record can carry an HTML-comment marker:

```markdown
<!-- lint:expect-inferred id=<page-id> reason="<one-line justification>" -->
- Claim text [prov:src-X#sec:Y] [epistemic:: inferred]
```

Or for tentative claims:

```markdown
<!-- lint:expect-tentative id=<page-id> reason="<reason>" -->
```

**Strict placement rules:**

1. Marker must be the **line IMMEDIATELY above** the claim. A blank line between marker and claim INVALIDATES the exemption.
2. `id` must match the containing page's frontmatter `id`.
3. `reason` is required and non-empty.

Exempted claims emit a `severity: info`, `category: skip-count` finding (reviewer-visible `::notice` annotation in PR UI).

Aggregate across the wiki with `bin/lint.sh --count-skips` — emits one info/skip-count finding per marker for human review.

## `--require-version` pinning

`bin/lint.sh` carries a bash constant `LINT_VERSION="1.1.0"` at the top of the file. Three related flags:

- `bin/lint.sh --version` — prints `LINT_VERSION` and exits 0.
- `bin/lint.sh --require-version X.Y.Z` — minimum-version check. Fails with exit 1 if `LINT_VERSION < X.Y.Z` (semver tuple comparison, not string).
- No exact-version pinning in v1.1 (`--require-exact-version` deferred).

**Workflow YAML example:**

```yaml
- run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json
```

**Semantics:**

- MAJOR bump = breaking change (removed category, changed severity). Old pins fail.
- MINOR bump = non-breaking addition. Old pins pass.
- PATCH bump = bug fix. Old pins pass.

Pinning is optional — workflow YAML without `--require-version` accepts any current version.

**Caveat:** Minimum-version semantics mean long-lived PRs may see new rule findings after `main` bumps the version. Rebase stale branches onto `main` to pick up current rules. Exact-version pinning is deliberately deferred; add `--require-exact-version` if reproducibility becomes critical.

## GitHub Actions (canonical)

The canonical workflow is [`.github/workflows/lint.yml`](../../.github/workflows/lint.yml). Three parallel jobs, each a required status check in branch protection:

- `lint` — severity-remapped JSON + inline annotations.
- `privacy-leak` — frontmatter scan for `local_only` in public paths.
- `strict` — ready-for-review quality ratchet.

Operator action (one-time on the public repo):

> Settings → Branches → Branch protection rule for `main`:
> - [x] Require status checks to pass before merging
> - Required checks: `lint`, `privacy-leak`, `strict` (alongside existing `neutrality`, `setup-parity`)

The JSON → GitHub annotations shim lives at `.github/scripts/json-to-annotations.py`. It maps `severity` to GitHub workflow commands (`error` → `::error`, `warning` → `::warning`, `info` → `::notice`), sorts errors first, and honors GitHub's 10/10/50 annotation cap with a trailing `::notice` when capped.

## GitLab CI

Schema-incompatible with GitHub Actions but the bash scripts and JSON contract are portable. Add `.gitlab-ci.yml` at repo root:

```yaml
# .gitlab-ci.yml — Phase 9 CI gate for GitLab
image: python:3.12-slim

before_script:
  - pip install pyyaml
  - apt-get update && apt-get install -y git bash

stages:
  - lint
  - privacy
  - strict

lint:
  stage: lint
  script:
    - bash bin/lint.sh --require-version 1.1.0 --ci --format json > lint.json
    - cat lint.json
  artifacts:
    when: always
    paths: [lint.json]

privacy-leak:
  stage: privacy
  script:
    - bash bin/check-privacy.sh

strict:
  stage: strict
  # GitLab equivalent of GitHub's draft-skip:
  rules:
    - if: $CI_MERGE_REQUEST_IID && $CI_MERGE_REQUEST_LABELS !~ /draft/
    - if: $CI_COMMIT_REF_NAME == "main"
  variables:
    GIT_DEPTH: "0"
  script:
    - bash bin/lint.sh --require-version 1.1.0 --strict
```

GitLab's inline MR annotations support differs from GitHub Actions; the JSON output is the portable piece. Consumers can post findings as MR comments via the GitLab API if desired (out of scope for v1.1).

## Gitea Actions

Gitea Actions is [GitHub Actions schema-compatible](https://docs.gitea.com/usage/actions/comparison). Copy `.github/workflows/lint.yml` to `.gitea/workflows/lint.yml` and adjust the runner image if needed:

```yaml
# Only the runs-on line typically needs adjustment:
runs-on: ubuntu-latest   # works if your Gitea runner ships ubuntu-latest-compatible images
```

Most `actions/checkout@v6` and `actions/setup-python@v6` references work as-is because Gitea supports absolute-URL references and the GitHub Marketplace ecosystem.

## Codeberg (Forgejo Actions)

Codeberg uses [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/) — a Gitea Actions fork with similar schema compatibility. Same approach as Gitea: copy `.github/workflows/lint.yml` to the Forgejo workflows directory and adjust the runner image to a Codeberg-supported label (check the Codeberg Actions runner docs for current labels).

## Platform-neutral principles

The portable pieces of this CI gate are:

1. **The JSON contract** (`bin/lint.sh --format json` output schema, documented above).
2. **Exit-code semantics** (`--ci` exit 1 on error-severity; `--strict` exit 1 on ratchet violation; `bin/check-privacy.sh` exit 2 on leak).
3. **The severity policy table** (which categories block vs. warn).

Any CI system that can run bash + Python 3 + PyYAML can enforce this gate. GitHub-specific features (inline PR annotations) are a UX bonus — the JSON artifact is the ground truth.

## Out of scope (v1.1)

- Bitbucket Pipelines, Jenkins, Drone — no ownership of cross-provider test coverage beyond the three providers above.
- Danger-JS / reviewdog PR-comment bots — GitHub annotations cover 80% of the value; adds token/auth surface.
- Severity-escalation policy (warning-persists-across-N-PRs → auto-promoted to error).
- `--require-exact-version` flag (only minimum-version pinning in v1.1).
- Merge-base lint comparison.
- Post-merge link-audit auto-PR.

## See also

- [../../AGENTS.md](../../AGENTS.md) §11.3 CI mode, §12 contributor:: inline field, §13 privacy routing
- [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
- [../../PRIVACY.md](../../PRIVACY.md)
- [../../.github/workflows/lint.yml](../../.github/workflows/lint.yml)
