---
phase: 07-neutral-template-foundation
plan: 02
subsystem: template-neutralization
tags: [neutralization, wiki-skeleton, lint, decision-record, wave-2]

requires:
  - phase: 07-neutral-template-foundation
    plan: 01
    provides: tests/phase-07/run.sh Wave 0 aggregator (extended with 5 new test_*.sh siblings)
provides:
  - examples/kahneman/ (7 pages + 2 sources + README + log)
  - wiki/ reduced to TMPL-05 skeleton (index.md + log.md + decisions/)
  - wiki/decisions/dr-2026-04-15-kahneman-to-examples.md (canonical AGENTS.md §4.6 type: decision record)
  - bin/lint.sh honoring examples/ + example: true + WIKI_ROOT env var
affects:
  - 07-03 (AGENTS.md neutralization — depends on Kahneman content living in examples/)
  - 07-05 (CI denylist / orphan-branch publish — depends on local_only content being absent from public paths)

tech-stack:
  added: []
  patterns:
    - "WIKI_ROOT env var override for lint.sh (fixture-driven testing pattern carried over from 07-01)"
    - "Per-file example: true skip complements top-level EXCLUDE_DIRS for reference pages placed outside examples/"
    - "Canonical AGENTS.md §4.6 type: decision schema — 14 required fields (12 base + trigger_type + affected_pages), 7 ordered body sections"

key-files:
  created:
    - examples/kahneman/README.md
    - examples/kahneman/log.md
    - examples/kahneman/entities/daniel-kahneman.md (relocated)
    - examples/kahneman/concepts/prospect-theory.md (relocated)
    - examples/kahneman/concepts/loss-aversion.md (relocated)
    - examples/kahneman/concepts/cognitive-biases.md (relocated)
    - examples/kahneman/comparisons/system-1-vs-system-2.md (relocated)
    - examples/kahneman/overviews/decision-making.md (relocated + orphan wikilink removed)
    - examples/kahneman/sources/src-2026-04-09-thinking-fast-and-slow-part1.md (relocated)
    - examples/kahneman/sources/src-2026-04-10-kahneman-prospect-theory.md (relocated)
    - wiki/decisions/dr-2026-04-15-kahneman-to-examples.md
    - tests/phase-07/test_kahneman_moved.sh
    - tests/phase-07/test_kahneman_readme.sh
    - tests/phase-07/test_wiki_skeleton.sh
    - tests/phase-07/test_no_stale_kahneman_paths.sh
    - tests/phase-07/test_lint_exclude.sh
    - tests/phase-07/fixtures/lint-exclude/examples/sample.md
    - tests/phase-07/fixtures/lint-exclude/wiki/marked.md
    - tests/phase-07/fixtures/lint-exclude/wiki/normal.md
  modified:
    - bin/lint.sh (EXCLUDE_DIRS += 'examples', per-file example: true skip, WIKI_ROOT env var)
    - wiki/index.md (reduced to skeleton)
    - wiki/log.md (reduced to skeleton)
    - AGENTS.md (surgical edit: worked example paths generalized; full rewrite deferred to 07-03)
  deleted:
    - wiki/overviews/personal-decision-patterns.md (privacy: local_only)
    - wiki/sources/src-2026-04-10-personal-decision-journal.md (privacy: local_only)
    - wiki/maintenance/lint-report.md (TMPL-05 skeleton-only)
    - wiki/maintenance/reflect-state.md (TMPL-05 skeleton-only)
    - wiki/{entities,concepts,comparisons,overviews,sources}/.gitkeep (dirs fully removed)

key-decisions:
  - "Decision record uses canonical AGENTS.md §4.6 schema with ALL fields (supersedes, superseded_by, aliases, has_contradictions added after first lint surfaced them as BASE_FIELDS — per bin/lint.sh check-1)"
  - "AGENTS.md worked-example paths (3 lines referencing wiki/concepts/loss-aversion.md etc.) surgically generalized now so test_no_stale_kahneman_paths.sh passes; full NEUT-02/03 rewrite of AGENTS.md illustrative content stays in plan 07-03"
  - "WIKI_ROOT env var added (rather than plan's ad-hoc override) to reuse 07-01's --root fixture pattern for another file-scanning tool"
  - "test_lint_exclude uses --dry-run on both fixture and real-repo calls to prevent lint from regenerating wiki/maintenance/ during the test and breaking test_wiki_skeleton on re-run"

requirements-completed: [NEUT-01, NEUT-04, NEUT-05, NEUT-07, TMPL-05]

duration: ~12min
completed: 2026-04-15
---

# Phase 07 Plan 02: Kahneman → examples/, wiki Skeleton, lint NEUT-04 Summary

**Relocated the 7-page Kahneman cluster + 2 source summaries to `examples/kahneman/`, deleted `privacy: local_only` creator content and `wiki/maintenance/` entirely, reduced `wiki/` to a TMPL-05 skeleton (`index.md` + `log.md` + `decisions/`), committed a canonical-schema NEUT-07 decision record, and extended `bin/lint.sh` to skip `examples/` and any page with `example: true` frontmatter.**

## Performance

- **Duration:** ~12 min
- **Tasks:** 2
- **Tests:** 6/6 green (test_requirements_sync + test_kahneman_moved + test_kahneman_readme + test_wiki_skeleton + test_no_stale_kahneman_paths + test_lint_exclude)
- **Commits:** 2

## Task Commits

1. **Task 1: Relocate Kahneman cluster + skeleton wiki + canonical decision record + stale-path scan** — `ddceccd` (refactor)
2. **Task 2: Extend bin/lint.sh EXCLUDE_DIRS + example: true + WIKI_ROOT (NEUT-04)** — `cdf81dd` (feat)

## File Moves (git mv preserved history)

| From | To |
| --- | --- |
| wiki/entities/daniel-kahneman.md | examples/kahneman/entities/daniel-kahneman.md |
| wiki/concepts/prospect-theory.md | examples/kahneman/concepts/prospect-theory.md |
| wiki/concepts/loss-aversion.md | examples/kahneman/concepts/loss-aversion.md |
| wiki/concepts/cognitive-biases.md | examples/kahneman/concepts/cognitive-biases.md |
| wiki/comparisons/system-1-vs-system-2.md | examples/kahneman/comparisons/system-1-vs-system-2.md |
| wiki/overviews/decision-making.md | examples/kahneman/overviews/decision-making.md |
| wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md | examples/kahneman/sources/src-2026-04-09-thinking-fast-and-slow-part1.md |
| wiki/sources/src-2026-04-10-kahneman-prospect-theory.md | examples/kahneman/sources/src-2026-04-10-kahneman-prospect-theory.md |

## Deletions

| Path | Reason |
| --- | --- |
| wiki/overviews/personal-decision-patterns.md | privacy: local_only — must not ship |
| wiki/sources/src-2026-04-10-personal-decision-journal.md | privacy: local_only — must not ship |
| wiki/maintenance/lint-report.md | TMPL-05 skeleton-only — regenerate locally on demand |
| wiki/maintenance/reflect-state.md | TMPL-05 skeleton-only — regenerate locally on demand |
| wiki/{entities,concepts,comparisons,overviews,sources}/.gitkeep | Directories fully removed (TMPL-05 skeleton = no content dirs) |

## bin/lint.sh Diff Summary

- `EXCLUDE_DIRS = {'maintenance'}` → `{'maintenance', 'examples'}` (top-level directory skip).
- After `parse_frontmatter(fpath)`, added a `if isinstance(fm, dict) and fm.get('example') is True: continue` guard before appending to `all_pages`. This applies the NEUT-04 D-09 fallback anywhere in the tree.
- `WIKI_DIR="wiki/"` → `WIKI_DIR="${WIKI_ROOT:-wiki/}"`; positional `[wiki-directory]` arg still wins.

## NEUT-07 Decision Record — Canonical Schema

Path: `wiki/decisions/dr-2026-04-15-kahneman-to-examples.md`

**Frontmatter fields (canonical per AGENTS.md §4.6):** `id`, `title`, `type: decision`, `status: active`, `summary`, `created_at: 2026-04-15`, `updated_at: 2026-04-15`, `sources: []`, `epistemic_status: sourced`, `tags: [meta, schema, neutralization]`, `domains: [wiki-infrastructure]`, `privacy: cloud_safe`, `knowledge_domain: software`, `supersedes:`, `superseded_by:`, `aliases: []`, `has_contradictions: false`, `trigger_type: schema-update`, `affected_pages: [12 entries]`.

**Forbidden non-canonical fields absent:** no `date:` key; no `class: SUPERSEDE` key. Grep-verified.

**Required body sections (all 7, in order):** `## TL;DR` → `## Decision` → `## Why` → `## Alternatives Considered` → `## Consequences` → `## Affected Pages` → `## Sources`.

## Repo-wide Stale-path Scan Result

`tests/phase-07/test_no_stale_kahneman_paths.sh` — PASS after surgical edit.

Initial run found 3 matches in AGENTS.md worked-example lines 1286/1290/1292 referencing `wiki/concepts/loss-aversion.md`, `wiki/concepts/cognitive-biases.md`, `wiki/concepts/prospect-theory.md`. Replaced the concrete paths with generic placeholders (`the relevant concept page`, `wiki/concepts/<page>.md`) plus a pointer to `examples/kahneman/concepts/`. Full rewrite of AGENTS.md illustrative content is plan 07-03's job (NEUT-02/03); this edit is the minimum surgical change needed to make 07-02's scan test green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Orphan `[[personal-decision-patterns]]` wikilink in `examples/kahneman/overviews/decision-making.md`**

- **Found during:** Task 1 in-cluster wikilink check (step 5 python block).
- **Issue:** The page carried a Related Pages bullet pointing at `[[personal-decision-patterns]]`, a `privacy: local_only` target that we were deleting in the same commit. Left in, it would ship as a broken link in the public release.
- **Fix:** Removed the bullet.
- **Commit:** `ddceccd` (Task 1), then again surfaced in `cdf81dd` (Task 2) because of staging order — the Task 1 commit recorded the file as a rename without the modification; Task 2 commit carries the actual content change.

**2. [Rule 1 — Bug] NEUT-07 decision record missing `supersedes`, `superseded_by`, `aliases`, `has_contradictions`**

- **Found during:** Post-Task-1 lint run against the real wiki.
- **Issue:** Lint raised a BASE_FIELDS error on the new decision record. These four fields are in `BASE_FIELDS` per `bin/lint.sh` but were not enumerated in the plan's "canonical schema" block (which focused on decision-specific fields only).
- **Fix:** Added the four fields with neutral defaults: `supersedes:` (empty), `superseded_by:` (empty), `aliases: []`, `has_contradictions: false`.
- **Commit:** `cdf81dd` (Task 2).

**3. [Rule 3 — Blocker] AGENTS.md worked-example path references would break `test_no_stale_kahneman_paths.sh`**

- **Found during:** Task 1 verification.
- **Issue:** Plan 07-03 is scheduled to rewrite AGENTS.md illustrative content, but plan 07-02's own acceptance test `test_no_stale_kahneman_paths.sh` must exit 0 now.
- **Fix:** Surgical edit to 3 lines of AGENTS.md (lines 1286, 1290, 1292) generalizing concrete `wiki/concepts/<kahneman-page>.md` paths. Full rewrite deferred to 07-03.
- **Commit:** `ddceccd` (Task 1).

**4. [Rule 3 — Blocker] test_lint_exclude was regenerating `wiki/maintenance/` and failing test_wiki_skeleton on harness re-run**

- **Found during:** Full harness run after Task 2.
- **Issue:** Real-repo lint (t4) wrote `wiki/maintenance/lint-report.md` as a side effect, tripping `test_wiki_skeleton`'s `find wiki -mindepth 1 -maxdepth 1` check on subsequent runs.
- **Fix:** Changed both `bash bin/lint.sh` calls in test_lint_exclude to use `--dry-run`.
- **Commit:** `cdf81dd` (Task 2).

## Deferred Issues

None within this plan's scope. Pre-existing lint findings unrelated to this plan:

- Raw source pages under `sources/2026/2026-04/*/source.md` have no wiki source summary pages (all 3 are either Kahneman ones whose summaries are now under `examples/kahneman/sources/`, or the deleted `personal-decision-journal`). These warnings are expected and correct for a post-neutralization wiki.
- `wiki/decisions/dr-2026-04-14-phase6-decision-type.md` not listed in `wiki/index.md` — index is now a skeleton; full re-indexing will happen as `wiki/` accumulates real content after v1.1 ship.

## Known Stubs

None introduced by this plan. `wiki/index.md` and `wiki/log.md` are intentional TMPL-05 skeletons per plan spec (both carry minimal-meta frontmatter + skeleton body); these are the deliberate goal of the plan, not unwanted placeholders.

## Verification

- `bash tests/phase-07/run.sh` → 6/6 passing:
  - test_requirements_sync (from 07-01, still green)
  - test_kahneman_moved (13 sub-pass)
  - test_kahneman_readme (25 sub-pass)
  - test_wiki_skeleton (2 sub-pass)
  - test_no_stale_kahneman_paths (1 pass)
  - test_lint_exclude (3 pass)

- `bash bin/lint.sh --dry-run` on real repo → 0 errors, 7 warnings, 1 info. Down from 1 error / 7 warnings / 1 info after adding the 4 missing BASE_FIELDS to the decision record. All remaining findings are pre-existing or expected post-neutralization.

## Next Phase Readiness

- 07-03 can now proceed: AGENTS.md still contains Kahneman illustrative content (§11 worked examples, §13 privacy-routing examples) but all `wiki/<dir>/<kahneman-page>.md` concrete paths are cleared from the public surface. 07-03 will replace the remaining illustrative prose with generic placeholders + `See: examples/kahneman/...` pointers.
- 07-05 denylist gate can assume `wiki/` is Kahneman-free and local_only-free.

---
*Phase: 07-neutral-template-foundation*
*Completed: 2026-04-15*

## Self-Check: PASSED

Verified:

- FOUND: examples/kahneman/README.md
- FOUND: examples/kahneman/log.md
- FOUND: examples/kahneman/entities/daniel-kahneman.md
- FOUND: examples/kahneman/concepts/prospect-theory.md
- FOUND: wiki/decisions/dr-2026-04-15-kahneman-to-examples.md
- FOUND: bin/lint.sh (modified with EXCLUDE_DIRS + example:true + WIKI_ROOT)
- FOUND: tests/phase-07/test_kahneman_moved.sh
- FOUND: tests/phase-07/test_kahneman_readme.sh
- FOUND: tests/phase-07/test_wiki_skeleton.sh
- FOUND: tests/phase-07/test_no_stale_kahneman_paths.sh
- FOUND: tests/phase-07/test_lint_exclude.sh
- FOUND commit ddceccd (Task 1)
- FOUND commit cdf81dd (Task 2)
- `bash tests/phase-07/run.sh` exits 0 with 6/6 passing
