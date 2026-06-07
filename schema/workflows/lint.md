# Lint Workflow

> Agent-authoritative reference for the lint workflow: the decay/staleness model, severity tiers, the `bin/lint.sh` CI-mode contract, and the 15-step lint procedure.
> This file is the authoritative specification for the CI + local-gate contracts (the severity-remap table, `--format json` schema, escape-hatch markers, `--require-version`, and the `--staged` write-gate). `docs/reference/ci.md`, `CONTRIBUTING.md`, and `.github/workflows/lint.yml` link here rather than restating the policy.
> The AGENTS.md routing table (decay/staleness + lint workflow) points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

### Domain-Based Decay Rate Table

Claims inherit temporal relevance from their source publication dates. Different knowledge domains decay at different rates. The lint workflow uses this table to flag stale claims mechanically.

| Domain | Base Decay Period | Rationale |
|--------|-------------------|-----------|
| `software` | 180 days (6 months) | Libraries, APIs, and tooling change rapidly |
| `science` | 730 days (2 years) | Replication and meta-analysis cycles |
| `biography` | 1825 days (5 years) | Biographical facts change slowly |
| `personal-goals` | 90 days (3 months) | Goals evolve with life circumstances |
| (default) | 365 days (1 year) | Fallback for unclassified domains |

**Epistemic status modifiers** (per D-08): Tentative and inferred claims decay faster than their domain default. Multiply the base decay period by the modifier:

| Epistemic Status | Modifier | Effect |
|------------------|----------|--------|
| `sourced` | 1.0 | Base rate |
| `mixed` | 0.85 | 15% faster decay |
| `inferred` | 0.75 | 33% faster decay |
| `tentative` | 0.5 | Twice as fast decay |

**Hash override** (per D-09): If a source page's `content_hash` differs from `compiled_against_hash`, ALL claims linked to that source via `[prov:]` markers are immediately stale regardless of decay window.

**Date fallback chain** for staleness calculation: When `checked_at` is missing from a provenance marker, use (in order): (1) the source page's `ingested_at` date, (2) the wiki page's `updated_at` date.

### Staleness Auto-Fix Rules

The lint workflow applies mechanical staleness fixes (per D-12):

**Claim-level auto-fix:** When a claim's provenance date exceeds its domain decay threshold (adjusted by epistemic modifier), the lint adds `[epistemic:: stale]` after the claim's provenance marker cluster. Rules for marker placement:
- One `[epistemic:: stale]` marker per claim -- do not duplicate if already present
- Place immediately after the last `[prov:...]` marker on the claim line
- If the claim already has `[epistemic:: sourced]` or `[epistemic:: inferred]`, replace it with `[epistemic:: stale]`
- A "claim" is defined as a single bullet point or paragraph containing `[prov:]` markers
- This operation is deterministic and reversible (removing the stale marker restores prior state)

**Page-level status:** The lint only auto-updates page-level `epistemic_status` to `stale` when the rollup clearly warrants it (per D-13): all material claims are stale, OR the TL;DR/Key Facts section contains materially stale claims. Default: do NOT auto-change page-level status.

**Logging:** All auto-fix staleness changes are logged in `wiki-cloud/maintenance/lint-report.md` and `wiki-cloud/log.md` (per D-14).

---

## Lint Workflow

```
Trigger:  User requests a health check, or periodically after several ingests
Inputs:   wiki-cloud/ directory (all pages)
Outputs:  Structured findings report, optionally fixed pages, updated log
Commit:   lint(<scope>): <one-line summary>
```

**Severity Tiers** (per D-17):

| Severity | Meaning | Examples |
|----------|---------|----------|
| `error` | Must fix -- broken references, invalid structure | Broken provenance refs, missing source pages, YAML parse failures, invalid frontmatter enum values |
| `warning` | Should fix -- quality degradation | Stale claims, orphan pages, contradictions, missing cross-references |
| `info` | Nice to know -- improvement opportunities | Knowledge gaps, sparse coverage, suggested questions |

**Auto-Fix Boundary** (per D-18, D-19):

Auto-fix (mechanical, deterministic, reversible): updating stale claim markers per decay table, syncing `has_contradictions` frontmatter boolean to match presence of `[contradiction:]` markers in body.

Report-only (no auto-fix): contradictions, knowledge gaps, orphan pages, missing cross-references, page restructuring, any fix requiring judgment.

#### CI mode (Phase 9)

> **Source of truth for Phase 9 / Phase 12.2 CI + local-gate contracts.** This section is the authoritative specification for: (a) the severity-remap dispatch table, (b) the `--format json` output schema, (c) the escape-hatch marker contract, (d) the `--require-version` semantics, and (e) the `--staged` local-write-gate contract (Phase 12.2). Other docs (`docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` comments) MUST link here rather than restating the policy. Drift between this section and the shipped code is a regression.

`bin/lint.sh` supports a CI operating profile via several independent, orthogonal flags:

| Flag | Effect |
|------|--------|
| `--format json` | Emit JSON array `[{severity, category, path, line?, message}]` to stdout; do NOT write `lint-report.md`. |
| `--ci` | Apply severity-remap dispatch table: `yaml`/`orphan`/`crossref`/`provenance`/`linkres` -> `error`; `stale`/`gap`/`contradiction`/`contradiction-sync`/`drift`/`contributor` -> `warning`; `autofix`/`skip-count` -> `info`. Default-skip `drift-external` category. Exit 1 iff any post-remap finding has severity `error`. |
| `--skip-category <cat>` | Exclude one category. Repeatable. Inverse of `--category`. |
| `--strict` | Quality ratchet: fail on (a) new `[epistemic:: inferred]` / `[epistemic:: tentative]` claims without a matching decision record whose `affected_pages` frontmatter contains the page ID; (b) new (git-diff status `A`) pages of type `entity`/`concept`/`overview`/`comparison` with zero `[prov:` markers. Source pages and decision records are exempt by design. |
| `--staged` | Phase 12.2 local-write-gate scope swap. With `--strict`, replaces the diff source from `git diff origin/main...HEAD` to `git diff --cached --name-only --diff-filter=A` and applies D-10 (new-page provenance) ONLY — D-08 (DR-match) stays CI-only. Files are read from the working tree, not from staged blobs. No-op without `--strict`. Used by `.githooks/pre-commit`. See "Staged-mode rules" below. |
| `--require-version X.Y.Z` | Minimum-version pin. Fails if `LINT_VERSION < X.Y.Z`. Semver tuple comparison, not string. |
| `--version` | Print `LINT_VERSION` and exit 0. |
| `--count-skips` | Enumerate every `<!-- lint:expect-* -->` escape-hatch marker. Emits one `info`/`skip-count` finding per marker (human-review aid). |

**Escape-hatch marker syntax (`--strict` exemption):**

```
<!-- lint:expect-inferred id=<page-id> reason="<one line>" -->
<!-- lint:expect-tentative id=<page-id> reason="<one line>" -->
```

Placement rules (strict):

1. Marker MUST appear on the line IMMEDIATELY above the claim line -- no blank line between.
2. `id` MUST match the containing page's frontmatter `id` field.
3. `reason` is required and non-empty.
4. Exempted claims are emitted as severity `info`, category `skip-count` (visible in PR annotations as `::notice`, non-blocking).

**CI workflow reference:** `.github/workflows/lint.yml` invokes three jobs in parallel -- `lint`, `privacy-leak`, `strict` -- each a required check in branch protection. See `docs/reference/ci.md`.

**Staged-mode rules (`--staged`, Phase 12.2):**

`bin/lint.sh --staged` is the local-write-gate scope swap. The `.githooks/pre-commit` hook invokes `bash bin/lint.sh --strict --staged --category provenance` after the AGENTS.md ↔ CLAUDE.md sync check. Rules:

1. **Requires `--strict`.** `--staged` is a no-op without `--strict` (no provenance enforcement; standard categories run as usual). The pre-commit hook always passes both flags together.
2. **Diff source:** `git diff --cached --name-only --diff-filter=A` (status-A entries in the staged index). Files are read from the WORKING TREE, not from staged blobs — pre-commit hooks fire after `git add`, so working-tree content matches the index for the typical add-then-commit flow. If you `git add foo.md && echo extra >> foo.md && git commit`, the gate sees the dirty version (which already contains the staged content); known caveat, not a bug.
3. **Scope:** D-10 (new-page provenance) ONLY. Pages staged as status-A under `wiki-cloud/{entities,concepts,overviews,comparisons}/` must contain at least one `[prov:` marker. D-08 (DR-match for added inferred/tentative claims) stays CI-only — not enforced at commit time.
4. **Exemption ordering** (first match wins):
   1. Path NOT under `wiki-cloud/{entities,concepts,overviews,comparisons}/` — not gated.
   2. Path under `examples/` anywhere in the tree — not gated (path-prefix exemption, mirrors `EXCLUDE_DIRS` for full-lint).
   3. Frontmatter `type: source` — not gated (source pages are themselves the provenance anchors).
   4. Frontmatter `type: decision` — not gated (decision records are the gating mechanism, can't gate on themselves).
   5. Frontmatter `example: true` — not gated (reference content, anywhere in the tree).
   6. Frontmatter `bootstrap_stage: bootstrapped` — not gated (brownfield in-flight; provenance-bootstrap migration `02-provenance-bootstrap.sh` adds markers later).
5. **`bootstrap_stage: verified` is NOT exempt.** Pages promoted through the brownfield 5-gate `verify --promote` flow are first-class wiki content from the gate's perspective — they must carry `[prov:]` markers like any other entity / concept / overview / comparison page.
6. **Exit policy:** reuses `--strict`'s contract — exit 1 iff any post-remap error-severity finding exists. `provenance` already maps to `error` in the severity remap.
7. **Bypass:** `git commit --no-verify` only. No `WGATE_SKIP=1` env var. No per-page `wgate_exempt: true` frontmatter (would create a permanent bypass surface defeating the gate's purpose). Per the `--no-verify` escape-hatch note in AGENTS.md Global Rules, `--no-verify` is the operator's escape hatch — use rarely, document the reason in the commit message when used.
8. **Hook activation:** `bash bin/install-hooks.sh` once per clone. The hook composes the existing AGENTS.md ↔ CLAUDE.md sync check (runs first; can re-stage CLAUDE.md) with the new write-gate (runs second; read-only over the staged index).

**Failure UX:** when the gate blocks, `bin/lint.sh` prints per-page `error/provenance/<path>: new <type> page has zero [prov:...] markers (D-10; ...)` lines, and the hook appends a single trailing footer line listing the three actionable paths (add `[prov:source_id#locator]` markers, set `type: source` / `type: decision` in frontmatter if it's not a synthesized page, or `git commit --no-verify` to bypass).

**Steps:**

1. Read `wiki-cloud/index.md` for full page inventory. Build resolution map: for each wiki page, collect filename, id, title, and aliases (case-insensitive matching).
2. **YAML frontmatter validation:** Parse all page frontmatter, check required fields, validate enum values against the schema in `schema/reference/frontmatter.md`. Severity: error for parse failures or missing required fields.
3. **Provenance validation:** Verify all `[prov:]` references resolve to known source IDs in `wiki-cloud/sources/` or `wiki-local/sources/`. Verify locator syntax (see `schema/reference/provenance.md`). Severity: error for broken refs.
4. **Orphan detection:** Find pages with no inbound wikilinks from other wiki pages (using resolution map for alias-aware, case-insensitive matching). Exclude index.md, log.md, lint-report.md. Severity: warning. Report-only.
5. **Missing cross-references:** Identify pages sharing 2+ domains AND 2+ tags that lack mutual wikilinks. Only flag for active pages (not archived/superseded). Severity: warning. Report-only.
6. **Stale claims:** Compute staleness using the decay table above (this file), epistemic modifier, and hash override. Date fallback chain: `checked_at` -> `ingested_at` -> `updated_at`. Severity: warning. Auto-fix: add/update `[epistemic:: stale]` markers per Staleness Auto-Fix Rules.
7. **Potential contradiction candidates:** Flag wiki page sections where claims carry `[prov:]` markers from 2+ different source_ids AND the section is NOT on a page of type `comparison` or `overview` (these are inherently multi-source by design). Mark as "potential contradiction candidates for agent review." The lint does NOT assert these ARE contradictions -- the LLM agent running the lint workflow reviews flagged sections and promotes confirmed disagreements to `[contradiction:]` inline markers (see `schema/reference/provenance.md`). Severity: warning. Report-only.
8. **`has_contradictions` sync:** Verify that `has_contradictions` frontmatter matches actual presence of `[contradiction:]` markers in the body. Auto-fix: set `true` if markers present, `false` if no markers present.
9. **Knowledge gaps (red links):** Collect unresolved wikilinks. Flag when: appears on 2+ distinct pages, OR appears in TL;DR/Key Facts section of any page (per D-20). Severity: info. Report-only. Suggest investigative question per D-23.
10. **Source coverage gaps:** Compare domain source counts. Flag domains with materially fewer sources than median. Only run when wiki has 5+ distinct knowledge_domain values with at least 3 having 2+ source pages (maturity guardrail per D-22). Use `knowledge_domain` consistently for both page classification and source counting. Severity: info. Report-only. Suggest investigative question per D-23.
11. **Near-duplicate pages (category: `duplicate`):** Flag same-`type` page pairs that are lexical near-duplicates -- candidate iff one page's title/alias contains the other's title/alias as a case-insensitive substring (contained length > 5), OR Levenshtein distance < 3 on titles longer than 5 chars. Survivor = the page with more inbound wikilinks (tie -> lexicographically-first id). One finding per pair. Severity: warning. Report-only -- feeds the human-confirmed MERGE operation (see `schema/workflows/structured-operations.md`); never auto-merges. Excludes `EXCLUDE_DIRS`/`examples/`, `example: true`, and archived/superseded pages. Pure-stdlib (no embeddings) -- semantic dedup is a deferred Tier-4 extension.
12. **Drift detection (category: `drift`):** Run cross-system drift checks. These detect misalignment between the wiki layer and its dependencies.
    - **Unrepresented sources (DRFT-01):** Walk `sources/` directory for `.md` files, check each has a corresponding wiki source summary page (matching the `path` field in source page frontmatter). Severity: warning.
    - **Missing source files (DRFT-02):** For each source summary page, verify the raw source file at the `path` frontmatter field exists on disk. Severity: error.
    - **Content-hash drift:** Recompute SHA-256 of the raw source file, compare against `content_hash` in source summary frontmatter. If mismatch: report finding (severity: warning). When `--fix` is passed, auto-fix `compilation_status` to `stale` on the affected source page. See compilation status transitions in `schema/reference/frontmatter.md`.
    - **Index coverage:** Verify every wiki page (excluding index.md, log.md, and maintenance/ pages) has a wikilink entry in its tier index (`wiki-cloud/index.md` or `wiki-local/index.md`). Severity: warning.
    - **Obsidian vault awareness (DRFT-03):** Verify `.obsidian/` directory exists (info if missing). Check for non-markdown files in `wiki-cloud/` subdirectories (severity: info).
    - **Orphaned operation artifacts (DRFT-04):** Detect operations that finished their file edits but skipped their commit, leaving `wiki-cloud/log.md` asserting `pages_affected` the wiki does not contain as committed files (the failure mode where a later operation's commit flushes the shared append-only `log.md` while the orphaned page/index edits dangle untracked). Read the COMMITTED `log.md` (`git show HEAD:wiki-cloud/log.md`) and, for each `pages_affected:` page ID (excluding the non-page tokens `index`, `log`, `lint-report`, `reflect-state`, `none`), verify a git-tracked wiki page with that `id` exists (resolved against pages' actual `id` frontmatter, not filename stems, so a page whose id ≠ filename — itself a yaml-check error — does not also produce a spurious orphan finding). Reading the committed log — not the working tree — means an in-flight operation whose fresh log entry is itself still uncommitted alongside its page is NOT flagged; only entries already in HEAD are audited. Scope: the machine-parseable `pages_affected:` field (`schema/workflows/query.md` Query Log Entry Format). Severity: warning. Report-only. Requires git; silently skips outside a git repo.
13. Compile findings into `wiki-cloud/maintenance/lint-report.md` organized by severity then category. Findings are grouped with category subsections (e.g., `### Drift` under `## Warnings`). Include total counts and per-category breakdowns.
14. Append entry to `wiki-cloud/log.md`: `## [YYYY-MM-DD] lint | <scope>` with summary of findings counts and auto-fixes applied.
15. Commit: `lint(<scope>): <one-line summary of findings and fixes>`

**Categories** (valid values for `--category` filter): `orphan`, `crossref`, `stale`, `contradiction`, `gap`, `provenance`, `yaml`, `drift`, `duplicate`.

**Abort conditions:**

- Wiki is empty (no pages beyond `index.md` and `log.md`). Report that the wiki is empty and skip the lint. Log this in `wiki-cloud/log.md`.

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (decay/staleness + lint workflow pointer to this file).
- `schema/reference/provenance.md` — provenance syntax, epistemic markers, contradiction markers.
- `schema/reference/frontmatter.md` — frontmatter fields including `knowledge_domain` for decay-rate bucket assignment.
