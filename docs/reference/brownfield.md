# Brownfield Workflow

Mechanical onboarding of an existing Obsidian vault into the LLM Wiki Compiler schema. `bin/brownfield.sh` ships two complete subcommands — `scan` (dry-run inventory) and `bootstrap` (idempotent mechanical transforms) — plus two stubs (`suggest`, `verify`) that ship in Phase 11.

> **Decision boundary:** Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema.

This one-liner captures the entire policy surface: bootstrap is conservative by design. It never guesses semantics, never overwrites existing parseable values, and never blocks on ambiguity — ambiguity is logged for later review.

## Prerequisites

- **Python 3 with `ruamel.yaml`** — single new runtime dependency in v1.1, scoped to the brownfield path only. The wizard, ingest, search, and lint paths remain bash + stdlib + pyyaml. Install:
  ```bash
  pip install ruamel.yaml
  # or, on Debian/Ubuntu
  apt install python3-ruamel.yaml
  # or, on macOS via Homebrew
  brew install python@3 && pip3 install ruamel.yaml
  ```
- **Git** — required for the canonical undo recipe (no per-file `.orig` backups; git is the authoritative rollback mechanism).
- **Clean working tree** — commit or stash changes before running `bootstrap --apply` so rollback is a single `git reset --hard`.

## scan subcommand

`bin/brownfield.sh scan` is a dry-run inventory. It reads every markdown page in the vault, classifies each one via a 4-signal rule set, and writes `.brownfield/REPORT.md` with an Inventory + Excluded + "Needs human judgment" tail. It NEVER mutates vault content.

### Classification signals (rule-based, no LLM calls per BRWN-16)

1. Existing frontmatter `type:` — authoritative if valid per AGENTS.md §4.
2. Filename convention — PascalCase/proper-noun → entity; `YYYY-MM-DD-*` → journal/source; `src-*` → source summary; `vs-*` / `X-vs-Y` → comparison.
3. H1 + section-heading structure — `## Extracted Claims` + `## Source Metadata` → source summary; `## Comparison Table` → comparison; `## TL;DR` + `## Key Facts` + `## Detail` → entity/concept.
4. Outbound wikilink density — outbound-heavy + abstract framing → concept; inbound-heavy + proper-noun-like title → entity.

Confidence labels: `high` (3+ signals agree OR explicit valid frontmatter type) / `medium` (2 signals agree) / `low` (1 signal, ambiguous) / `unknown` (0 signals OR conflict).

### Flags

- `--root <path>` — vault root (default: `.`)
- `--list-excluded` — emit every excluded-file path in REPORT.md (default: counts only)
- `-h, --help` — show usage

### Output contract

`.brownfield/REPORT.md` with sections: `## Inventory` (page | label | confidence | signals table), `## Excluded` (counts per exclusion rule; full list under `--list-excluded`), `## Needs human judgment` (prose open-questions for unknown pages per D-18).

### Exclusion model

**Built-in defaults** (D-19): `.obsidian/**`, `.trash/**`, `templates/**`, `attachments/**`, `.brownfield/**`, `.git/**`, daily-note patterns (`YYYY-MM-DD.md` at root or under `daily/`, `journal/`).

**User override:** create `.brownfield-ignore` at the vault root with gitignore-like patterns (fnmatch-based subset of gitignore grammar — supports `*`, `**`, and `!` negation only; directory-only trailing-slash and other advanced gitignore features are NOT supported). Lines prefixed with `!` un-exclude built-in defaults (e.g., `!attachments/` if you use `attachments/` for wiki content rather than Obsidian attachments). Negation wins over defaults, matching gitignore semantics.

## bootstrap subcommand

`bin/brownfield.sh bootstrap` writes sentinel frontmatter into vault pages so downstream tools (lint, ingest, future suggest/verify) can distinguish imported-from-Obsidian content from LLM-generated content.

### Safety posture

**Dry-run default.** You must pass `--apply` to mutate files. No `--assume-yes` / `--force` in v1.1. Every `--apply` run halts on first write failure to avoid partial fan-out damage.

### Flags

- `--apply` — write changes (default is dry-run)
- `--dry-run` — preview only; write `.brownfield/REPORT.md` without mutating files (default behavior)
- `--verbose` — emit per-file unified diffs to stdout during dry-run
- `--root <path>` — vault root (default: `.`)
- `-h, --help` — show usage

### What bootstrap writes

**For pages WITHOUT frontmatter:** the full D-14 sentinel set (16 base fields + 2 brownfield-specific fields):

Inferred mechanically from the file: `id` (kebab-cased filename), `title` (H1 or filename), `created_at` (file mtime), `updated_at` (today).

Empty scaffolding (conservative — not interpretation): `type: ""`, `summary: ""`, `knowledge_domain: ""`, `sources: []`, `tags: []`, `domains: []`, `aliases: []`, `supersedes: null`, `superseded_by: null`.

Fixed defaults: `status: active`, `epistemic_status: tentative` (signals "not LLM-sourced"), `privacy: local_only` (fail-closed per AGENTS.md §13), `has_contradictions: false`.

Brownfield-specific: `bootstrap_stage: bootstrapped`, `bootstrap_date: <today as YYYY-MM-DD UTC>`.

**For pages WITH parseable frontmatter:** the typed-merge policy applies.

### Typed-merge policy (D-02)

Bootstrap NEVER blindly overwrites existing frontmatter. Each sentinel field is classified into one of three classes:

**Class A — safe-additive:** `tags`, `aliases`, `sources`, `status`. Bootstrap preserves existing values; injects sentinel defaults only where a key is absent. Collisions are logged to `.brownfield/REPORT.md` under `## Preserved collision`.

**Class B — schema-authoritative:** `type`, `epistemic_status`, `knowledge_domain`, `privacy`, `bootstrap_stage`. Bootstrap preserves existing values and **never overwrites**. If the existing value is missing, malformed, or noncanonical, it is logged to `.brownfield/REPORT.md` under `## Preserved schema-authoritative field` with a warning — semantic correction is `suggest` / `lint`'s job in Phase 11, not bootstrap's.

**Class C — structural hard failure:** Unparseable YAML, non-mapping frontmatter, detectable duplicate YAML keys. Bootstrap skips the page and records the skip in `.brownfield/SKIPPED.md` with the parse error and a one-line suggestion.

### Output contract

After `--apply`, the `.brownfield/` directory contains:

- `REPORT.md` — four sections: (a) bootstrapped-successfully, (b) bootstrapped-with-preserved-collisions, (c) bootstrapped-with-schema-warnings, (d) **"Needs human judgment"** — the scan tail, reused across both subcommands per D-04, which collects both (i) unclassifiable pages from `scan` mode AND (ii) orphan raw sources found during `bootstrap` (raw files under `sources/` with no corresponding `wiki/sources/*.md` summary page; handoff to Phase 11 `suggest/01-page-typing.sh`). The report MUST have exactly four sections — there is no separate "Needs summary" section; orphan raw sources are a form of unclassifiable-needs-user-judgment and belong in (d).
- `APPLIED.md` — append-only execution manifest: every touched file + timestamp + outcome. Each `--apply` run appends a new `## Run <timestamp>` block so you can audit bootstrap invocations over time.
- `SKIPPED.md` — parse-failure + unsafe-structure files only (scoped narrowly per D-05 so reviewers can triage unparseable files independently from merge collisions).

`.brownfield/` is gitignored per `TMPL-04`; these files are operator-local audit artifacts, not committed content.

### Idempotency

Every page bootstrap touches is tagged with `bootstrap_stage: bootstrapped`. On re-run, bootstrap skips pages carrying this sentinel silently. Running `bootstrap --apply` twice in a row produces zero-byte diff on the second run (verified by `tests/phase-10/test_brownfield_bootstrap_idempotent.sh`).

### Failure modes

- **Parse failure** (unparseable YAML) → file skipped, entry written to `.brownfield/SKIPPED.md`, end-of-run summary shows count.
- **Write failure mid-apply** (disk full, permission denied) → bootstrap halts on first failure. `.brownfield/APPLIED.md` records successful-before + failed file + untouched-remainder. Exit code non-zero. Choose: `git reset --hard` OR fix-and-rerun (idempotent per sentinel — successful-before files are no-ops on retry).
- **Missing ruamel.yaml** → actionable stderr pointing at `pip install ruamel.yaml`; exit 1 before any write.

## Rollback (canonical undo recipe)

Git is the authoritative backup. No per-file `.orig` copies are created (D-06).

```bash
# 1. Identify the commit BEFORE your bootstrap --apply ran
git log --oneline

# 2. Rewind
git reset --hard <sha-before-bootstrap>

# 3. Remove the .brownfield/ artifacts (optional; they are gitignored but local)
rm -rf .brownfield/
```

> **Important:** If you had uncommitted local changes before running `bootstrap --apply`, those changes will be lost by `git reset --hard`. Always commit or stash your work before applying bootstrap so that rollback is clean.

If bootstrap also created `wiki/index.md` or `wiki/log.md` skeletons (BRWN-04 rule: created if absent), those will be removed by `git reset` since they were new files, not modifications.

## Mechanical-vs-judgment boundary

> **Boundary:** Brownfield bootstrap preserves existing parseable frontmatter values, injects only absent required sentinel fields, and logs any collisions or noncanonical existing values for later review. It skips only files whose frontmatter cannot be parsed safely or whose structure makes mechanical injection unsafe.

Why this matters:

- Bootstrap is safe to re-run on the same vault; it will never overwrite your existing `type`, `privacy`, `knowledge_domain`, `epistemic_status`, or `bootstrap_stage` values.
- Bootstrap will NEVER:
  - Choose a page type for you (semantic judgment — see Phase 11's `01-page-typing.sh`)
  - Infer cross-links between pages (Phase 11's `03-cross-link-inference.sh`)
  - Classify privacy (Phase 11's `04-privacy-classification.sh`)
  - Bootstrap provenance markers onto existing claims (Phase 11's `02-provenance-bootstrap.sh`)
- Bootstrap ONLY does mechanical work: YAML round-trip, sentinel injection, SHA hashing, skeleton creation.

## Interaction with lint and ingest

### `bin/lint.sh --ci` (BRWN-08 downgrade)

After bootstrap, the vault will contain pages with `bootstrap_stage: bootstrapped` + empty `type`, missing `sources`, `epistemic_status: tentative`. These would normally be lint errors. `bin/lint.sh --ci` downgrades findings in the allowlist (`yaml`, `provenance`, `orphan`) from `error` to `info` when the page carries `bootstrap_stage: bootstrapped`. This lets CI gates pass on a fresh brownfield vault while the user works through Phase 11 migrations.

**Scope note (I-1):** The BRWN-08 error→info downgrade fires in `--ci` mode ONLY (per the Phase 9 `CI_SEVERITY_REMAP` convention). Text-mode lint behavior (plain `bin/lint.sh` without `--ci`) is unchanged: the original severities are preserved. If you run `bin/lint.sh` locally after `bin/brownfield.sh bootstrap`, you will still see full-severity `yaml`/`provenance`/`orphan` findings on bootstrapped pages — this is expected. The downgrade is a CI-gate pragmatic, not a universal severity change. Use `--ci` locally if you want to mirror the CI severity view.

### `bin/lint.sh --category brownfield` (BRWN-09)

A dedicated lint category reports the count of `bootstrapped` pages and warns on any page `bootstrapped` more than 30 days ago — prodding the user to complete Phase 11 migrations before too much time passes. The summary emits `info/brownfield` with `bootstrapped pages: X; stale (>30d): Y` whenever at least one bootstrapped page exists.

### `bin/ingest.sh` (BRWN-10 strip)

If a user ingests a source whose frontmatter carries `bootstrap_stage` or `bootstrap_date`, `bin/ingest.sh` strips those fields during the copy into `sources/YYYY/YYYY-MM/` and prints a one-line stderr `Note: stripped ...` warning per field. This prevents the brownfield sentinel from polluting normally-ingested content. The strip is frontmatter-scoped: body text containing the token (e.g., inside a code block) is preserved verbatim.

## `bootstrap_stage` field reference

| Value | Meaning |
|-------|---------|
| `raw` | Reserved for future import workflows that scan but don't yet bootstrap. |
| `bootstrapped` | Written by `bin/brownfield.sh bootstrap`. Page has mechanical sentinel frontmatter; user should complete Phase 11 migrations to reach `verified`. |
| `verified` | Page has been reviewed against Phase 11's suggest/verify workflow. Persists on imported pages as a page-level marker for "content predates the LLM ingest pipeline." |

See AGENTS.md §5 for the authoritative field definition and the explicit contrast with claim-level provenance (PROV-01..05 are the authoritative provenance mechanism; `bootstrap_stage` tracks page-level migration state only).

## suggest subcommand

[Populated in Phase 11]

The `suggest` subcommand generates four staged, idempotent migration scripts for judgment-heavy transforms (BRWN-11..14): `01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-classification.sh`. Each is user-invoked, dry-run by default, with `--apply` to execute. See REQUIREMENTS.md §BRWN-11..14 for the Phase 11 contract.

## verify subcommand

[Populated in Phase 11]

The `verify` subcommand wraps `bin/lint.sh` with brownfield-appropriate severity thresholds to confirm the vault passes after user-applied migrations (BRWN-17). See REQUIREMENTS.md §BRWN-17.

## Known limitations

- **Scan classification is heuristic:** The 4-signal rule set (D-16) uses filename conventions, frontmatter, heading structure, and outbound link density. It cannot distinguish every page type correctly — `unknown` is the honest output when signals conflict or are absent. Phase 11's `01-page-typing.sh` adds inbound-link context for higher accuracy.
- **Bootstrap does not infer provenance, privacy, or page type:** These are judgment calls that belong in Phase 11's suggest/verify workflow. Bootstrap only writes mechanical sentinel frontmatter.
- **Lint downgrade is CI-only:** The BRWN-08 error->info downgrade for bootstrapped pages fires in `bin/lint.sh --ci` mode only (I-1 scope). Local `bin/lint.sh` runs show full-severity findings on bootstrapped pages. Use `--ci` locally to mirror CI behavior.

## See also

- [AGENTS.md §5](../../AGENTS.md) — `bootstrap_stage` + `bootstrap_date` field definitions
- [AGENTS.md §11.5](../../AGENTS.md) — Brownfield Workflow (populated in Phase 11)
- [AGENTS.md §13](../../AGENTS.md) — Privacy fail-closed default (`privacy: local_only`)
- [docs/quickstart.md](../quickstart.md) — Five-minute onboarding with ruamel.yaml prerequisite note
- [REQUIREMENTS.md §BRWN](../../.planning/REQUIREMENTS.md) — Phase 10 + Phase 11 requirements
