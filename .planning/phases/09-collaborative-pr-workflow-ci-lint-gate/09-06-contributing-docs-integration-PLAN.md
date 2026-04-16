---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 06
type: execute
wave: 4
depends_on: [09-05]
files_modified:
  - CONTRIBUTING.md
  - docs/reference/ci.md
  - docs/reference/index.md
  - tests/phase-09/test_contributing_md.sh
  - tests/phase-09/test_ci_docs.sh
  - tests/phase-09/test_docs_cross_links.sh
autonomous: true
requirements:
  - COLAB-01
  - COLAB-05
  - COLAB-06
  - CI-09

must_haves:
  truths:
    - "Top-level `CONTRIBUTING.md` exists at repo root documenting: fork → branch-per-ingest → `bin/ingest.sh` → local `bin/lint.sh` → open PR; lint severity tiers summary; privacy review (local_only never in public paths); attribution rules (git authorship = source of truth per COLAB-05); merge-conflict recipes for `wiki/log.md` + `wiki/index.md` (COLAB-06); `.gitattributes` snippet `wiki/log.md merge=union` as operator opt-in (not committed default per D-24)."
    - "`docs/reference/ci.md` is fully populated (no longer a stub) with: severity policy table, JSON output schema, privacy-leak guard explainer, `--strict` mode doc, escape-hatch marker doc, `--require-version` pinning usage, multi-provider equivalents (GitHub canonical + GitLab snippet + Gitea + Codeberg notes)."
    - "`docs/reference/ci.md` provider-equivalents section: platform-neutral principles first, then GitHub Actions (canonical reference to `.github/workflows/lint.yml`), then ~15-25 line GitLab `.gitlab-ci.yml` snippet, then Gitea-schema-compatibility note, then Codeberg/Forgejo runner-image note. No Bitbucket / Jenkins / Drone."
    - "`docs/reference/index.md` links to `ci.md` (verify existing link still accurate) and adds a link to CONTRIBUTING.md at repo root."
    - "CONTRIBUTING.md does NOT contain governance language, CoC, or release cadence (D-23 scope constraint)."
  artifacts:
    - path: "CONTRIBUTING.md"
      provides: "COLAB-01 PR workflow + COLAB-05 attribution rules + COLAB-06 merge-conflict recipes"
      contains: "wiki/log.md"
    - path: "docs/reference/ci.md"
      provides: "CI-09 full Phase 9 CI surface doc (closes Phase 7 D-11 stub-fill promise / CONTEXT.md D-32)"
      contains: "severity policy"
    - path: "docs/reference/index.md"
      provides: "Cross-link verification — ci.md link accurate; CONTRIBUTING.md linked"
      contains: "ci.md"
    - path: "tests/phase-09/test_contributing_md.sh"
      provides: "CONTRIBUTING.md structure test (PR workflow + merge-conflict recipes + attribution + privacy)"
    - path: "tests/phase-09/test_ci_docs.sh"
      provides: "ci.md full-populate test (severity table + JSON schema + providers + escape-hatch + --require-version)"
    - path: "tests/phase-09/test_docs_cross_links.sh"
      provides: "Reverse-link verification (CONTRIBUTING.md → ci.md, docs/reference/index.md → ci.md, ci.md → PRIVACY.md)"
  key_links:
    - from: "CONTRIBUTING.md"
      to: "docs/reference/ci.md"
      via: "inline markdown link for severity policy + escape-hatch details"
      pattern: "docs/reference/ci\\.md"
    - from: "docs/reference/ci.md"
      to: ".github/workflows/lint.yml"
      via: "canonical-reference link to the shipped workflow"
      pattern: "lint\\.yml|workflows/lint"
    - from: "docs/reference/ci.md"
      to: "bin/lint.sh + bin/check-privacy.sh"
      via: "CLI documentation (severity policy + privacy-leak guard)"
      pattern: "bin/lint\\.sh|bin/check-privacy\\.sh"
    - from: "docs/reference/index.md"
      to: "CONTRIBUTING.md"
      via: "markdown link (reference track → repo-root doc)"
      pattern: "CONTRIBUTING"
---

<objective>
Ship the **user-facing documentation layer** that explains the CI gate shipped in Plans 02–05:

1. **`CONTRIBUTING.md`** (COLAB-01, COLAB-05, COLAB-06) — PR workflow (fork → branch-per-ingest → local lint → PR), attribution rules (git authorship authoritative), merge-conflict recipes (`wiki/log.md` append conflicts, `wiki/index.md` category conflicts), privacy review, reference to CI gates.
2. **`docs/reference/ci.md`** (CI-09, closes Phase 7 D-11 stub-fill) — full Phase 9 CI surface: severity policy table, JSON output schema, `--strict` mode, escape-hatch markers, `--require-version`, multi-provider equivalents (GitHub canonical, GitLab snippet, Gitea compat note, Codeberg/Forgejo note).
3. **`docs/reference/index.md`** — verify cross-links; add pointer to `CONTRIBUTING.md`.

Purpose: Plans 02–05 built the mechanisms; Plan 05 documented the schema in AGENTS.md. Plan 06 closes the loop with **human-facing docs** — the files a new contributor actually opens when approaching the repo. This is where the D-23 scope constraint ("no governance, no CoC, no release cadence — focused on PR workflow + attribution + merge-conflict recipes") bites.

Output: 2 new top-level / reference docs + 1 existing-file cross-link update + 3 tests. Phase 9 complete.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md
@.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-05-SUMMARY.md
@docs/reference/ci.md
@docs/reference/index.md
@.github/workflows/lint.yml
@AGENTS.md

<interfaces>
From CONTEXT.md D-23 (CONTRIBUTING.md scope — EXACT):
  - PR workflow (fork → branch-per-ingest → bin/ingest.sh → bin/lint.sh locally → open PR)
  - Lint gate expectations (severity tiers summary — reference ci.md for detail)
  - Privacy review (local_only never in public paths — reference PRIVACY.md)
  - Attribution rules (git authorship authoritative per COLAB-05)
  - NO governance, NO CoC, NO release cadence

From CONTEXT.md D-24 (merge-conflict recipes — EXACT behavior):
  - wiki/log.md append conflicts → keep both sides, sort by `## [YYYY-MM-DD]` timestamp
  - wiki/index.md category-listing conflicts → keep both, alphabetize within category, re-run bin/lint.sh
  - .gitattributes snippet: wiki/log.md merge=union — documented as operator opt-in, NOT committed by default

From CONTEXT.md D-31 + D-32 (docs/reference/ci.md structure — EXACT):
  - Platform-neutral principles (JSON contract, exit codes, severity policy)
  - GitHub Actions → canonical (.github/workflows/lint.yml)
  - GitLab CI → ~15-25 line .gitlab-ci.yml snippet (lint + privacy + strict)
  - Gitea Actions → note: GitHub Actions schema-compatible; .github/workflows/lint.yml works in .gitea/workflows/ with one-line runner-image tweak
  - Codeberg (Forgejo Actions) → same as Gitea + Codeberg-specific runner image note
  - NO Bitbucket, NO Jenkins, NO Drone

From D-30 (tone): terse/mechanical, bullets over prose, Phase 7/8 voice.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Write CONTRIBUTING.md (PR workflow + attribution + merge-conflict recipes) + test</name>
  <files>CONTRIBUTING.md, tests/phase-09/test_contributing_md.sh</files>
  <read_first>
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-23 (scope), D-24 (merge-conflict recipes), D-30 (tone)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Pitfall 2" (YAML merge conflicts)
    - README.md — current tone/voice reference at repo root (if exists)
    - PRIVACY.md — reference for privacy-review subsection
    - AGENTS.md §12 — log.md format (for merge-conflict recipe context)
  </read_first>
  <behavior>
    - Test A (test_contributing_md.sh, structure): `CONTRIBUTING.md` exists at repo root. Contains sections (exact `##` matches): PR workflow or `How to contribute` (one of these), `Attribution`, `Merge conflicts`, `Privacy` (and/or `Privacy review`), `Lint` (or `Lint gate` — severity-tier summary).
    - Test B (test_contributing_md.sh, PR workflow): Contains all 5 workflow steps (as bullets or numbered list): `fork`, `branch`, `bin/ingest.sh`, `bin/lint.sh`, `pull request` (or `PR` / `open PR`).
    - Test C (test_contributing_md.sh, attribution): Contains the exact phrase "source of truth" (or similar — git authorship authoritative per COLAB-05). References `.git-author-map.txt`.
    - Test D (test_contributing_md.sh, merge-conflict recipes): Contains: (a) `wiki/log.md` conflict resolution (sort by timestamp / keep both); (b) `wiki/index.md` conflict resolution (alphabetize, re-run lint); (c) `.gitattributes` snippet with `merge=union` AND explicit note that it is NOT committed by default.
    - Test E (test_contributing_md.sh, scope constraint): Does NOT contain "Code of Conduct" (D-23 excludes governance). Does NOT contain "release cadence" or "release schedule".
    - Test F (test_contributing_md.sh, CI references): Links to `docs/reference/ci.md` for severity-policy detail.
  </behavior>
  <action>
Create `CONTRIBUTING.md` at repo root. Target ~120 lines, terse/mechanical tone. Structure:

```markdown
# Contributing to this Wiki

Thanks for contributing. This is a bash + git-based wiki compiler; contributions are git pull requests.

## How to contribute

Every contribution (new source, page update, schema amendment) follows the **branch-per-ingest** convention:

1. **Fork** the repo on GitHub (or clone directly if you have write access).
2. **Branch** from `main`: `git checkout -b ingest/<source-slug>`.
3. **Scaffold** the source bundle with `bin/ingest.sh <path-to-source-file>`. This writes the raw source under `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` and prints a ready-to-paste log-entry template.
4. **Compile** — follow the ingest workflow in [AGENTS.md §11.1](AGENTS.md) to update entity/concept/overview pages, append the log entry, and regenerate TL;DRs.
5. **Lint locally**: `bash bin/lint.sh` — fix structural errors before pushing.
6. **Open a PR** against `main`. The PR template auto-populates with a 6-section checklist (see `.github/pull_request_template.md`).

### CI gate

Three required checks run on every PR (branch protection rule):

- `lint` — `bin/lint.sh --ci --format json` + GitHub annotations. Structural findings (`yaml`, `orphan`, `crossref`, `provenance`) block merge; `stale`, `gap`, `contradiction` surface as warnings.
- `privacy-leak` — `bin/check-privacy.sh` scans public paths (`examples/`, `docs/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/`) for `privacy: local_only` frontmatter. Leaks block merge. `wiki/**` is exempt (valid user content).
- `strict` — `bin/lint.sh --strict` on ready-for-review PRs. Fails on new `[inferred]` / `[tentative]` claims without a matching decision record, and on new entity/concept/overview/comparison pages with zero `[prov:` markers. Draft PRs skip this check.

See [docs/reference/ci.md](docs/reference/ci.md) for the full severity policy, JSON schema, multi-provider equivalents, escape-hatch markers, and `--require-version` pinning.

## Attribution

**Git commit authorship is the source of truth** (COLAB-05). The `Author:` field on your commit is the canonical record of who produced the change. Squash-merging erases authorship granularity — we recommend merge commits for ingest PRs (documented, not enforced).

The optional `contributor:: @github-handle` Dataview inline field in `wiki/log.md` is a **convenience index** for filtering log history by contributor:

```
bin/search.sh --contributor @octocat
```

### How `contributor::` is resolved

`bin/ingest.sh` emits `contributor:: @handle` into the log-entry template:

1. If you pass `--contributor @handle`, the flag wins.
2. If the repo has a single author (`git log --all --format='%ae' | sort -u | wc -l == 1`), the field is omitted entirely. Personal forks stay clean.
3. Otherwise, `git config user.email` is looked up in `.git-author-map.txt` at repo root (format `email  ->  @handle`, `#` comments, case-insensitive). On hit, emit mapped handle; on miss, warn and omit (never bare email).

Add yourself to `.git-author-map.txt` on your first multi-author PR:

```
your.email@example.com  ->  @your-github-handle
```

## Privacy

See [PRIVACY.md](PRIVACY.md) for the `local_only` / `cloud_safe` tiers. The `privacy-leak` CI job fails any PR that puts `privacy: local_only` frontmatter in public paths. `local_only` is valid inside `wiki/**` — it is your user content and never reaches cloud LLM APIs per AGENTS.md §13.

## Merge conflicts

The wiki has two write-heavy hotspots where concurrent PRs conflict. Here are the canonical resolution recipes.

### `wiki/log.md` (append-only activity log)

Log entries are timestamped (`## [YYYY-MM-DD] ingest | ...`). Conflicts happen when two branches both append entries.

**Resolution — keep both sides, sort by timestamp:**

```bash
git checkout main -- wiki/log.md           # start from main's version
git checkout your-branch -- wiki/log.md    # merge-check your changes back
# In your editor: paste both sides' entries; sort by the `## [YYYY-MM-DD]`
# header so chronological order is preserved.
bash bin/lint.sh wiki/                     # validate
git add wiki/log.md
git commit -m "resolve log.md conflict"
```

**Optional opt-in**: `.gitattributes` merge-union driver — automates this for you:

```gitattributes
# Add this to .gitattributes LOCALLY (not committed by default).
# Git will union-merge append-only conflicts in log.md automatically.
wiki/log.md merge=union
```

We deliberately do NOT commit this as a default `.gitattributes` line. `merge=union` changes git behavior globally for the repo; contributors who haven't read this doc would be surprised. Opt in per-clone if you find yourself resolving log.md conflicts regularly.

### `wiki/index.md` (category listings)

Index entries are organized by page type (Entities, Concepts, Sources, Comparisons, Overviews, Decisions). Conflicts happen when two branches both add entries under the same category.

**Resolution — keep both, alphabetize within category, re-run lint:**

```bash
git checkout main -- wiki/index.md
git checkout your-branch -- wiki/index.md
# In your editor: merge both sides' entries within each category header.
# Alphabetize the entries under each `## Category` header.
bash bin/lint.sh wiki/                     # confirms no broken links
git add wiki/index.md
git commit -m "resolve index.md conflict"
```

`merge=union` is NOT recommended for `wiki/index.md` — it would collide headers and produce duplicate category sections.

## Lint severity tiers

Three tiers gate PR merges:

- `error` blocks merge — structural failures (parse errors, broken refs, missing provenance)
- `warning` annotates but does not block — judgment findings (stale claims, knowledge gaps, contradictions, drift, contributor mismatches)
- `info` annotates as a notice — mechanical observations (autofix applied, escape-hatch markers)

**Source of truth for the exact category → severity mapping:** [AGENTS.md §11.3 "CI mode"](AGENTS.md) — do not reproduce the table here; it drifts. [docs/reference/ci.md](docs/reference/ci.md) provides the full policy rationale and multi-provider equivalents.

## Escape-hatch markers (intentional inferred/tentative claims)

If your PR adds `[epistemic:: inferred]` or `[epistemic:: tentative]` claims without (yet) committing a matching decision record, add an escape-hatch marker on the line IMMEDIATELY above the claim:

```markdown
<!-- lint:expect-inferred id=<page-id> reason="reviewer-visible justification" -->
- Claim text [prov:src-X#sec:Y] [epistemic:: inferred]
```

Rules:

- Marker must be the IMMEDIATELY preceding line (no blank line between).
- `id` must match the containing page's frontmatter `id`.
- `reason` is required and non-empty.
- Exempted claims surface in CI annotations as `::notice` (visible to reviewers, non-blocking).

See [AGENTS.md §11.3 CI mode](AGENTS.md) and [docs/reference/ci.md](docs/reference/ci.md) for details.
```

Write `tests/phase-09/test_contributing_md.sh`:

```bash
#!/usr/bin/env bash
# COLAB-01/05/06: CONTRIBUTING.md exists with D-23 scope — PR workflow,
# attribution, merge-conflict recipes, privacy review. NO CoC / governance.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

C="$REPO_ROOT/CONTRIBUTING.md"
test -f "$C" || { echo "FAIL: CONTRIBUTING.md missing at repo root" >&2; exit 1; }

# PR workflow steps
for step in "fork" "branch" "bin/ingest.sh" "bin/lint.sh" "PR"; do
    grep -qi "$step" "$C" || { echo "FAIL: CONTRIBUTING.md missing PR-workflow step '$step'" >&2; exit 1; }
done

# Attribution section with source-of-truth claim
grep -qi "source of truth\|authoritative" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing 'source of truth' / 'authoritative' attribution" >&2; exit 1; }
grep -q "\.git-author-map\.txt" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing .git-author-map.txt reference" >&2; exit 1; }
grep -q "contributor::" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing contributor:: documentation" >&2; exit 1; }

# Merge-conflict recipes
grep -q "wiki/log\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing wiki/log.md conflict recipe" >&2; exit 1; }
grep -q "wiki/index\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing wiki/index.md conflict recipe" >&2; exit 1; }
grep -qi "sort.*timestamp\|by timestamp\|chronological" "$C" \
    || { echo "FAIL: log.md recipe missing sort-by-timestamp rule" >&2; exit 1; }
grep -qi "alphabetize" "$C" \
    || { echo "FAIL: index.md recipe missing 'alphabetize' rule" >&2; exit 1; }

# .gitattributes merge=union as opt-in (D-24)
grep -q "merge=union" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing merge=union snippet" >&2; exit 1; }
grep -qiE "not committed|do NOT commit|opt[ -]in" "$C" \
    || { echo "FAIL: .gitattributes snippet missing 'not committed default' / 'opt-in' qualifier" >&2; exit 1; }

# Privacy
grep -q "PRIVACY.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing PRIVACY.md link" >&2; exit 1; }

# CI reference
grep -q "docs/reference/ci\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing docs/reference/ci.md link" >&2; exit 1; }

# Source-of-truth link: AGENTS.md §11.3 is authoritative for the category→severity mapping (Codex MEDIUM review)
grep -qi "AGENTS\.md.*11\.3\|source of truth.*AGENTS" "$C" \
    || { echo "FAIL: CONTRIBUTING.md severity-tier section must link to AGENTS.md §11.3 as source of truth (not duplicate the table)" >&2; exit 1; }
if grep -qE "^\| \`yaml\` \|" "$C"; then
    echo "FAIL: CONTRIBUTING.md should NOT reproduce the full category→severity table — link to AGENTS.md §11.3 instead (spec-duplication guard, Codex MEDIUM review)" >&2
    exit 1
fi

# Escape-hatch marker doc (CI-06 linkage)
grep -q "lint:expect-inferred\|lint:expect-tentative" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing escape-hatch marker documentation" >&2; exit 1; }

# D-23 scope constraint: no governance / CoC / release cadence
if grep -qi "Code of Conduct\|CoC\b" "$C"; then
    echo "FAIL: CONTRIBUTING.md contains 'Code of Conduct' — D-23 excludes governance" >&2
    exit 1
fi
if grep -qi "release cadence\|release schedule" "$C"; then
    echo "FAIL: CONTRIBUTING.md contains release cadence — D-23 excludes it" >&2
    exit 1
fi

echo "PASS: CONTRIBUTING.md structure + scope"
```

Mark executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_contributing_md.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f CONTRIBUTING.md` at repo root
    - Contains all 5 PR-workflow bullets: fork, branch, `bin/ingest.sh`, `bin/lint.sh`, PR
    - Contains `## Attribution` section with "source of truth" (or "authoritative") phrasing
    - Contains `.git-author-map.txt` reference and `contributor::` field explanation
    - Contains `wiki/log.md` conflict recipe with sort-by-timestamp rule
    - Contains `wiki/index.md` conflict recipe with alphabetize rule
    - Contains `merge=union` snippet labeled as opt-in (NOT committed default)
    - Links to `PRIVACY.md` and `docs/reference/ci.md`
    - Contains escape-hatch marker reference (`lint:expect-inferred` or `lint:expect-tentative`)
    - Does NOT contain "Code of Conduct" or "release cadence" / "release schedule" (D-23)
    - Test exits 0
    - Tone check (manual): bullets over prose, terse mechanical voice, consistent with Phase 7/8 docs
  </acceptance_criteria>
  <done>
    A new contributor lands on the public repo, reads CONTRIBUTING.md, and in 3 minutes understands: how to open a PR, which CI gates will fire, how attribution works (git authorship authoritative), and how to resolve the two common merge-conflict types.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Fully populate docs/reference/ci.md (CI-09 D-32) + update docs/reference/index.md cross-links + 2 tests</name>
  <files>docs/reference/ci.md, docs/reference/index.md, tests/phase-09/test_ci_docs.sh, tests/phase-09/test_docs_cross_links.sh</files>
  <read_first>
    - docs/reference/ci.md — current stub (9 lines) — closes "populated in Phase 9" promise from Phase 7
    - docs/reference/index.md — Diátaxis reference track index; verify ci.md link present and accurate
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md — D-31 (4-provider structure), D-32 (full-populate)
    - .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-RESEARCH.md — §"Open Questions" #1 and #2 (fetch-depth reasoning, annotation cap)
    - .github/workflows/lint.yml (shipped in Plan 05) — canonical reference
    - AGENTS.md §11.3 CI mode subsection (amended in Plan 05) — internal reference anchor target
  </read_first>
  <behavior>
    - Test G (test_ci_docs.sh, stub replaced): `docs/reference/ci.md` no longer contains the literal string "stub" or "populated in v1.1 Phase 9" (the stub disclaimer text).
    - Test H (test_ci_docs.sh, severity policy): Contains severity-policy table with at least these categories: `yaml`, `orphan`, `crossref`, `provenance`, `stale`, `gap`, `contradiction`. Each appears alongside its CI severity (error or warning).
    - Test I (test_ci_docs.sh, JSON schema): Contains a code block documenting the JSON output shape with at least the keys `severity`, `category`, `path`, `message`.
    - Test J (test_ci_docs.sh, sections): Contains sections (as `##` headers) documenting: severity policy, JSON output, privacy-leak guard, `--strict` mode, escape-hatch markers, `--require-version` pinning, provider equivalents.
    - Test K (test_ci_docs.sh, multi-provider): Contains sections / subsections mentioning: GitHub Actions (canonical), GitLab CI, Gitea, Codeberg. Contains a GitLab `.gitlab-ci.yml`-formatted snippet. Does NOT mention Bitbucket or Jenkins or Drone.
    - Test L (test_docs_cross_links.sh): `docs/reference/index.md` links to `ci.md` (existing) and to `CONTRIBUTING.md` (new — repo-root file, relative path `../../CONTRIBUTING.md`). `docs/reference/ci.md` links back to `PRIVACY.md` and `.github/workflows/lint.yml` and `AGENTS.md`.
  </behavior>
  <action>
**Step 1: Fully populate `docs/reference/ci.md`.**

Replace the entire stub. Target ~200 lines. Structure follows D-32 exactly:

```markdown
# CI Lint Gate

> Reference documentation for Phase 9 CI surface: lint severity policy, JSON output, privacy-leak guard, --strict mode, escape-hatch markers, --require-version pinning, and multi-provider workflow equivalents.

## TL;DR

Every PR triggers three parallel CI jobs on GitHub Actions (see `.github/workflows/lint.yml`):

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

The canonical workflow is `.github/workflows/lint.yml`. Three parallel jobs, each a required status check in branch protection:

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
```

**Step 2: Update `docs/reference/index.md` cross-links.**

Read the existing file, verify:
- `ci.md` is linked (should be — from Phase 7 TMPL-08)
- Add a link to `CONTRIBUTING.md` at repo root (new — use relative path `../../CONTRIBUTING.md`)

If `docs/reference/index.md` does not currently list CONTRIBUTING.md, add a line in an appropriate section (e.g., "See also" or a "Getting started" subsection).

**Step 3: Write two tests.**

`tests/phase-09/test_ci_docs.sh`:

```bash
#!/usr/bin/env bash
# CI-09 / D-32: docs/reference/ci.md fully populated.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

F="$REPO_ROOT/docs/reference/ci.md"
test -f "$F" || { echo "FAIL: $F missing" >&2; exit 1; }

# No longer a stub
if grep -qi "populated in v1\.1 Phase 9\|Status: stub" "$F"; then
    echo "FAIL: ci.md still contains stub disclaimer" >&2; exit 1
fi

# Severity policy table covers the canonical categories
for cat in yaml orphan crossref provenance stale gap contradiction; do
    grep -q "$cat" "$F" || { echo "FAIL: ci.md severity table missing category '$cat'" >&2; exit 1; }
done
# Error + warning mentioned
grep -qi "error" "$F" || { echo "FAIL: severity-policy missing 'error'" >&2; exit 1; }
grep -qi "warning" "$F" || { echo "FAIL: severity-policy missing 'warning'" >&2; exit 1; }

# JSON schema section: keys
for key in severity category path message; do
    grep -q "$key" "$F" || { echo "FAIL: JSON schema missing key '$key'" >&2; exit 1; }
done

# Required sections
for heading in "Severity policy" "JSON output" "Privacy-leak" "strict" "Escape-hatch" "require-version" "GitHub Actions" "GitLab"; do
    grep -qi "$heading" "$F" || { echo "FAIL: ci.md missing section mentioning '$heading'" >&2; exit 1; }
done

# Multi-provider coverage
grep -qi "Gitea" "$F" || { echo "FAIL: ci.md missing Gitea section" >&2; exit 1; }
grep -qi "Codeberg\|Forgejo" "$F" || { echo "FAIL: ci.md missing Codeberg/Forgejo" >&2; exit 1; }
# GitLab has a .gitlab-ci.yml snippet
grep -q "\.gitlab-ci\.yml\|stages:" "$F" || { echo "FAIL: ci.md missing GitLab snippet" >&2; exit 1; }

# Excluded providers
for excluded in Bitbucket Jenkins Drone; do
    if grep -qi "$excluded section\|## $excluded" "$F"; then
        # allow passing mention in "out of scope" list, but not a full section
        if grep -qE "^#+ .*$excluded" "$F"; then
            echo "FAIL: ci.md has a section for '$excluded' (D-31 excludes)" >&2; exit 1
        fi
    fi
done

# Escape-hatch marker example
grep -q "lint:expect-inferred" "$F" || { echo "FAIL: ci.md missing lint:expect-inferred example" >&2; exit 1; }

# --require-version example in YAML
grep -q "require-version" "$F" || { echo "FAIL: ci.md missing --require-version" >&2; exit 1; }

# Source-of-truth pointer to AGENTS.md §11.3 (Codex MEDIUM review — prevents spec duplication drift)
grep -qi "AGENTS\.md.*11\.3\|source of truth.*AGENTS" "$F" \
    || { echo "FAIL: ci.md severity-policy / JSON-schema sections must link to AGENTS.md §11.3 as source of truth" >&2; exit 1; }

echo "PASS: docs/reference/ci.md fully populated"
```

`tests/phase-09/test_docs_cross_links.sh`:

```bash
#!/usr/bin/env bash
# Cross-link integrity: ci.md → PRIVACY.md/AGENTS.md/lint.yml; index.md → ci.md + CONTRIBUTING.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CI="$REPO_ROOT/docs/reference/ci.md"
IDX="$REPO_ROOT/docs/reference/index.md"

# ci.md outbound links
grep -q "PRIVACY\.md" "$CI" || { echo "FAIL: ci.md missing link to PRIVACY.md" >&2; exit 1; }
grep -q "AGENTS\.md" "$CI" || { echo "FAIL: ci.md missing link to AGENTS.md" >&2; exit 1; }
grep -q "lint\.yml\|workflows/lint" "$CI" || { echo "FAIL: ci.md missing link to .github/workflows/lint.yml" >&2; exit 1; }
grep -q "CONTRIBUTING\.md" "$CI" || { echo "FAIL: ci.md missing link to CONTRIBUTING.md" >&2; exit 1; }

# index.md cross-links
test -f "$IDX" || { echo "FAIL: $IDX missing" >&2; exit 1; }
grep -q "ci\.md" "$IDX" || { echo "FAIL: docs/reference/index.md missing ci.md link" >&2; exit 1; }
grep -q "CONTRIBUTING\.md" "$IDX" \
    || { echo "FAIL: docs/reference/index.md should link to CONTRIBUTING.md" >&2; exit 1; }

echo "PASS: docs cross-links integrity"
```

Both tests executable.
  </action>
  <verify>
    <automated>bash tests/phase-09/test_ci_docs.sh && bash tests/phase-09/test_docs_cross_links.sh</automated>
  </verify>
  <acceptance_criteria>
    - `docs/reference/ci.md` no longer contains "stub" or "populated in v1.1 Phase 9" stub disclaimer
    - `docs/reference/ci.md` has ≥200 lines of content
    - Contains severity-policy table with at least 7 categories mapped to CI severity
    - Contains JSON output schema code block with keys `severity`, `category`, `path`, `message`
    - Contains sections: Severity policy, JSON output, Privacy-leak, `--strict`, Escape-hatch, `--require-version`, GitHub Actions, GitLab, Gitea, Codeberg
    - Contains a GitLab `.gitlab-ci.yml`-formatted snippet with `stages:` keyword
    - Does NOT have top-level sections for Bitbucket / Jenkins / Drone (may appear in "Out of scope" list only)
    - Links from ci.md to PRIVACY.md, AGENTS.md, CONTRIBUTING.md, `.github/workflows/lint.yml`
    - `docs/reference/index.md` links to `ci.md` and `CONTRIBUTING.md`
    - Both tests exit 0
  </acceptance_criteria>
  <done>
    `docs/reference/ci.md` is the single canonical location documenting Phase 9's CI surface. Contributors reading CONTRIBUTING.md for the TL;DR can drill into ci.md for full detail. Multi-provider equivalents (GitLab, Gitea, Codeberg) are documented with copy-pasteable snippets — the portable piece (JSON contract + exit-code semantics) is explicit.
  </done>
</task>

</tasks>

<verification>
- `CONTRIBUTING.md` exists at repo root with PR workflow + attribution + merge-conflict recipes; passes scope constraints (no CoC, no release cadence).
- `docs/reference/ci.md` fully populated with severity policy, JSON schema, --strict, escape-hatch, --require-version, 4-provider equivalents.
- `docs/reference/index.md` cross-links verified (CONTRIBUTING.md added, ci.md link confirmed).
- `bash tests/phase-09/test_contributing_md.sh && bash tests/phase-09/test_ci_docs.sh && bash tests/phase-09/test_docs_cross_links.sh` all exit 0.
- `bash tests/phase-09/run.sh` full suite passes (tail: `PHASE 09 TESTS: N/M` with N == M).
- Regression: `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh` exit 0 (docs-test regressions unaffected).
- `bash bin/check-neutrality.sh` exits 0 (no Kahneman leak in new docs).
- `bash bin/check-privacy.sh` exits 0 (no `privacy: local_only` leak into new docs files).
</verification>

<success_criteria>
Phase 9 is complete. A contributor landing on the public repo:
1. Reads `CONTRIBUTING.md` → understands PR workflow + CI gate + attribution + merge conflicts in 3 minutes.
2. Drills into `docs/reference/ci.md` → learns the full severity policy, JSON schema, multi-provider setup.
3. Opens a PR → template auto-populates with 6-section checklist; 3 CI jobs run; annotations surface inline.
4. Git authorship + `contributor:: @handle` tracks who did what; `.git-author-map.txt` resolves handles.
5. Privacy-leak attempts fail the PR; strict ratchet catches judgment-drift without blocking draft iteration.
</success_criteria>

<output>
After completion, create `.planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-06-SUMMARY.md` documenting: CONTRIBUTING.md final section list + D-23 scope adherence, docs/reference/ci.md final section structure, multi-provider coverage decisions, the 3 test files. Declare Phase 9 complete pending operator branch-protection action on the public repo (setting `lint`, `privacy-leak`, `strict` as required checks).
</output>

## Review Response

This plan was revised on 2026-04-16 in response to cross-AI review feedback (see `09-REVIEWS.md`).

### Accepted

| Reviewer | Severity | Concern | How Addressed |
|----------|----------|---------|---------------|
| Codex | MEDIUM | Spec duplication risk: severity policy, JSON schema, and provider equivalents could drift across AGENTS.md §11.3, `docs/reference/ci.md`, workflow file, and `CONTRIBUTING.md`. | AGENTS.md §11.3 designated as source of truth in Plan 05. This plan amended: (a) CONTRIBUTING.md "Lint severity tiers" section now links to AGENTS.md §11.3 rather than duplicating the category→severity table; (b) `docs/reference/ci.md` Severity policy and JSON schema sections open with a blockquote pointing to §11.3 as the authoritative spec; (c) both docs tests now assert the source-of-truth pointer is present AND (for CONTRIBUTING.md) that the full category→severity table is NOT reproduced (spec-duplication guard). |

### Rejected

None for this plan.

### Deferred

| Reviewer | Severity | Concern | Deferral Reason |
|----------|----------|---------|-----------------|
| Codex | MEDIUM | `docs/reference/ci.md` becomes a second detailed specification layer alongside AGENTS.md and scripts. Drift risk. | Partially addressed via the source-of-truth pointers. The rationale text in ci.md's severity table is intentionally kept — it provides user-facing context AGENTS.md §11.3 does not duplicate. |
| Codex | MEDIUM | GitLab `apt-get install -y git bash` may not suffice in slim images. | Snippet framed as illustrative per D-32. No change — users adapt to their runner images. |
| Codex | LOW | Merge-commit recommendation is advisory, not enforced. | Already phrased as "recommended" in CONTRIBUTING.md. No change. |
| Codex | LOW | Docs tests only exclude top-level provider sections, allowing out-of-scope mentions. | Deliberate — "out of scope" lists need to NAME the excluded providers to be informative. No change. |
| Codex | LOW | Merge-conflict resolution commands are narrative. | Current level is correct for README-style docs. No change. |

