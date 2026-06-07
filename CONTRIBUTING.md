# Contributing to this Wiki

Thanks for contributing. This is a bash + git-based wiki compiler; contributions are git pull requests.

## How to contribute

Every contribution (new source, page update, schema amendment) follows the **branch-per-ingest** convention:

1. **Fork** the repo on GitHub (or clone directly if you have write access).
2. **Branch** from `main`: `git checkout -b ingest/<source-slug>`.
3. **Scaffold** the source bundle with `bin/ingest.sh <path-to-source-file>`. This writes the raw source under `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` and prints a ready-to-paste log-entry template.
4. **Compile** — follow the ingest workflow in [schema/workflows/ingest.md](schema/workflows/ingest.md) to update entity/concept/overview pages, append the log entry, and regenerate TL;DRs.
5. **Lint locally**: `bash bin/lint.sh` — fix structural errors before pushing.
6. **Open a PR** against `main`. The PR template auto-populates with a 6-section checklist (see `.github/pull_request_template.md`).

### CI gate

Three required checks run on every PR (branch protection rule):

- `lint` — `bin/lint.sh --ci --format json` + GitHub annotations. Structural findings (`yaml`, `orphan`, `crossref`, `provenance`) block merge; `stale`, `gap`, `contradiction` surface as warnings.
- `privacy-leak` — `bin/check-privacy.sh` scans public paths (`examples/`, `docs/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/`) for `privacy: local_only` frontmatter. Leaks block merge. `wiki-cloud/**` is exempt (valid user content).
- `strict` — `bin/lint.sh --strict` on ready-for-review PRs. Fails on new `[inferred]` / `[tentative]` claims without a matching decision record, and on new entity/concept/overview/comparison pages with zero `[prov:` markers. Draft PRs skip this check.

See [docs/reference/ci.md](docs/reference/ci.md) for the full severity policy, JSON schema, multi-provider equivalents, escape-hatch markers, and `--require-version` pinning.

### Local pre-commit gate

Run `bash bin/install-hooks.sh` once per clone to activate the AGENTS.md ↔ CLAUDE.md sync check and the local wiki write-gate (Phase 12.2). The gate blocks new staged pages under `wiki-cloud/{entities,concepts,overviews,comparisons}/` that contain zero `[prov:]` markers; bypass with `git commit --no-verify` (rare, document the reason in the commit message). See [docs/reference/ci.md](docs/reference/ci.md) and [schema/workflows/lint.md](schema/workflows/lint.md) for the full contract (exemption ordering, exit codes, --staged-requires-strict).

## Attribution

**Git commit authorship is the source of truth** (COLAB-05). The `Author:` field on your commit is the canonical record of who produced the change. Squash-merging erases authorship granularity — we recommend merge commits for ingest PRs (documented, not enforced).

The optional `contributor:: @github-handle` Dataview inline field in `wiki-cloud/log.md` is a **convenience index** for filtering log history by contributor:

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

See [PRIVACY.md](PRIVACY.md) for the `local_only` / `cloud_safe` tiers. The `privacy-leak` CI job fails any PR that puts `privacy: local_only` frontmatter in public paths. `local_only` is valid inside `wiki-cloud/**` — it is your user content and never reaches cloud LLM APIs per the tier rules in [schema/reference/privacy.md](schema/reference/privacy.md).

## Merge conflicts

The wiki has two write-heavy hotspots where concurrent PRs conflict. Here are the canonical resolution recipes.

### `wiki-cloud/log.md` (append-only activity log)

Log entries are timestamped (`## [YYYY-MM-DD] ingest | ...`). Conflicts happen when two branches both append entries.

**Resolution — keep both sides, sort by timestamp:**

```bash
git checkout main -- wiki-cloud/log.md           # start from main's version
git checkout your-branch -- wiki-cloud/log.md    # merge-check your changes back
# In your editor: paste both sides' entries; sort by the `## [YYYY-MM-DD]`
# header so chronological order is preserved.
bash bin/lint.sh wiki-cloud/                     # validate
git add wiki-cloud/log.md
git commit -m "resolve log.md conflict"
```

**Optional opt-in**: `.gitattributes` merge-union driver — automates this for you:

```gitattributes
# Add this to .gitattributes LOCALLY (not committed by default).
# Git will union-merge append-only conflicts in log.md automatically.
wiki-cloud/log.md merge=union
```

We deliberately do NOT commit this as a default `.gitattributes` line. `merge=union` changes git behavior globally for the repo; contributors who haven't read this doc would be surprised. Opt in per-clone if you find yourself resolving log.md conflicts regularly.

### `wiki-cloud/index.md` (category listings)

Index entries are organized by page type (Entities, Concepts, Sources, Comparisons, Overviews, Decisions). Conflicts happen when two branches both add entries under the same category.

**Resolution — keep both, alphabetize within category, re-run lint:**

```bash
git checkout main -- wiki-cloud/index.md
git checkout your-branch -- wiki-cloud/index.md
# In your editor: merge both sides' entries within each category header.
# Alphabetize the entries under each `## Category` header.
bash bin/lint.sh wiki-cloud/                     # confirms no broken links
git add wiki-cloud/index.md
git commit -m "resolve index.md conflict"
```

`merge=union` is NOT recommended for `wiki-cloud/index.md` — it would collide headers and produce duplicate category sections.

## Lint severity tiers

Three tiers gate PR merges:

- `error` blocks merge — structural failures (parse errors, broken refs, missing provenance)
- `warning` annotates but does not block — judgment findings (stale claims, knowledge gaps, contradictions, drift, contributor mismatches)
- `info` annotates as a notice — mechanical observations (autofix applied, escape-hatch markers)

**Source of truth for the exact category → severity mapping:** [schema/workflows/lint.md](schema/workflows/lint.md) "CI mode" — do not reproduce the table here; it drifts. [docs/reference/ci.md](docs/reference/ci.md) provides the full policy rationale and multi-provider equivalents.

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

See [schema/workflows/lint.md](schema/workflows/lint.md) and [docs/reference/ci.md](docs/reference/ci.md) for details.
