---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 06
subsystem: docs-integration
tags: [contributing, ci-docs, documentation, multi-provider, diátaxis-reference]

requires:
  - phase: 09-02
    provides: --require-version, --ci, --format json, --skip-category flags documented in ci.md
  - phase: 09-03
    provides: --strict + escape-hatch marker contract + --count-skips documented in ci.md + CONTRIBUTING.md
  - phase: 09-04
    provides: bin/check-privacy.sh + .git-author-map.txt + bin/search.sh --contributor referenced in CONTRIBUTING.md
  - phase: 09-05
    provides: AGENTS.md §11.3 source-of-truth designation that CONTRIBUTING.md + ci.md link rather than restate; .github/workflows/lint.yml canonical reference; PR template escape-hatch pointer
provides:
  - "CONTRIBUTING.md at repo root: PR workflow (fork → branch → bin/ingest.sh → bin/lint.sh → PR), attribution rules (git authorship authoritative, contributor:: convenience index), merge-conflict recipes (wiki/log.md sort-by-timestamp, wiki/index.md alphabetize, .gitattributes merge=union operator opt-in), privacy review pointer to PRIVACY.md, escape-hatch marker docs"
  - "docs/reference/ci.md fully populated: closes Phase 7 D-11 stub-fill promise and CONTEXT.md D-32; 267 lines covering severity policy, JSON schema, privacy-leak guard, --strict, escape-hatch markers, --require-version, 4-provider CI equivalents"
  - "docs/reference/index.md cross-link updates: adds Contributing section linking to CONTRIBUTING.md at repo root"
  - "3 test files (test_contributing_md.sh, test_ci_docs.sh, test_docs_cross_links.sh) + 1 obsoleted test-relaxation (tests/phase-07/test_reference_stubs.sh drops ci.md from the stub list + adds inverse 'ci.md is NOT a stub' assertion)"
affects: []

tech-stack:
  added: []  # Zero new runtime deps
  patterns:
    - "Source-of-truth linking pattern: docs under docs/reference/ link to AGENTS.md §§N.N for authoritative specs rather than restating them — prevents drift (Codex MEDIUM fix)"
    - "Diátaxis reference-track docs extending pattern: Phase 7 shipped the track skeleton + the first populated file (release.md); Phase 9 ships the second populated file (ci.md); Phases 10-12 follow the same template pattern"
    - "Obsoleted-by-future-phase test relaxation: phase-07/test_reference_stubs.sh drops ci.md from the stub list when Phase 9 populates it (precedent: Phase 08-04 relaxed phase-07 test_docs_skeleton.sh)"
    - "Merge-conflict recipe convention: two-command checkout-both + editor-merge + lint-validate + commit; .gitattributes merge=union as operator opt-in (D-24) documented but NOT committed as default"

key-files:
  created:
    - "CONTRIBUTING.md (128 lines) — repo-root PR workflow + attribution + merge conflicts + privacy + escape hatches"
    - "docs/reference/ci.md (267 lines, populated from 9-line stub) — full CI surface doc"
    - "tests/phase-09/test_contributing_md.sh (70 lines) — structure + scope + no-CoC guard"
    - "tests/phase-09/test_ci_docs.sh (57 lines) — severity table + JSON keys + sections + multi-provider + excluded-providers guard"
    - "tests/phase-09/test_docs_cross_links.sh (24 lines) — outbound links + reverse index link"
  modified:
    - "docs/reference/index.md (+4 lines: Contributing section + link to CONTRIBUTING.md)"
    - "tests/phase-07/test_reference_stubs.sh (drop ci.md from the stub-marker list + inverse 'ci.md is NOT a stub' assertion; [Rule 3 - Blocking Issue])"

key-decisions:
  - "CONTRIBUTING.md links to AGENTS.md §11.3 for severity policy rather than duplicating the category→severity table (Codex MEDIUM fix) — confirmed via test assertion that the full table markdown is NOT present in CONTRIBUTING.md"
  - "docs/reference/ci.md opens its Severity policy + JSON schema sections with source-of-truth blockquotes pointing to AGENTS.md §11.3 (Codex MEDIUM fix) — prevents the 4-way spec duplication risk across AGENTS.md / workflow file / ci.md / CONTRIBUTING.md"
  - ".gitattributes merge=union is documented as operator opt-in (NOT committed as default) per D-24 — prevents surprise for contributors who haven't read CONTRIBUTING.md"
  - "Multi-provider scope per D-31: GitHub Actions canonical + GitLab snippet + Gitea schema-compat note + Codeberg/Forgejo note. No Bitbucket / Jenkins / Drone — test asserts no top-level sections for those (they may appear in 'Out of scope' list)"
  - "docs/reference/index.md uses a Contributing subsection (not a flat bullet) so the semantic break between reference-track docs and the repo-root contributor doc is visible in the TOC"
  - "[Rule 3 - Blocking Issue] tests/phase-07/test_reference_stubs.sh relaxed to drop ci.md from the stub list. Precedent: Phase 08-04 relaxing phase-07/test_docs_skeleton.sh when Phase 8 populated its stubs. Applied as an inverse-assertion pattern: ci.md is NOT a stub; the remaining 4 files still carry the marker."

patterns-established:
  - "Pattern: Two-tier source-of-truth documentation — authoritative spec in AGENTS.md §§N.N; ergonomic reference in docs/reference/* that adds rationale/examples but always opens with a source-of-truth blockquote pointing up. Prevents spec duplication drift."
  - "Pattern: Multi-provider CI docs — start with platform-neutral principles (JSON contract + exit-code semantics + severity policy) so contributors on any provider understand the portable pieces; then enumerate provider-specific snippets."
  - "Pattern: Merge-conflict recipe docs — three canonical fields per recipe (conflict shape, resolution commands, .gitattributes opt-in with rationale). Applied to wiki/log.md (sort by timestamp) and wiki/index.md (alphabetize within category)."

requirements-completed: [COLAB-01, COLAB-05, COLAB-06, CI-09]

duration: 8min
completed: 2026-04-16
---

# Phase 09 Plan 06: Contributing + CI Docs Integration Summary

**Ships the human-facing documentation layer closing out Phase 9 and v1.1 Phase 9 complete: CONTRIBUTING.md at repo root (PR workflow + attribution + merge-conflict recipes + privacy + escape hatches) plus docs/reference/ci.md fully populated (severity policy + JSON schema + 4-provider CI equivalents + escape-hatch markers + --require-version pinning), with both docs linking to AGENTS.md §11.3 as the source of truth rather than restating policy (Codex MEDIUM fix).**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-16 (following Plan 09-05 completion)
- **Completed:** 2026-04-16
- **Tasks:** 2 (both `type="auto" tdd="true"`, both green first attempt after one Rule-3 obsoleted-test relaxation)
- **Files created:** 5 (CONTRIBUTING.md, ci.md populate, 3 tests)
- **Files modified:** 2 (docs/reference/index.md, tests/phase-07/test_reference_stubs.sh)
- **Net doc lines added:** ~395 across 2 user-facing docs (128 CONTRIBUTING + 267 ci.md populated from 9-line stub)

## Accomplishments

### CONTRIBUTING.md (repo root, 128 lines)

- **`## How to contribute`** — 6-step workflow: fork → branch-per-ingest (`ingest/<source-slug>`) → `bin/ingest.sh` scaffold → AGENTS.md §11.1 compile → `bin/lint.sh` locally → open PR. Points to `.github/pull_request_template.md` for auto-populated checklist.
- **`### CI gate` subsection** — 3 bullets summarizing `lint` / `privacy-leak` / `strict` jobs with exact behavior: structural findings block, judgment findings warn, privacy leaks block, strict job fails on unmatched inferred/tentative claims and new-pages-without-prov, draft PRs skip strict. Links to `docs/reference/ci.md` for depth.
- **`## Attribution`** — "Git commit authorship is the source of truth" (COLAB-05) plus the optional `contributor:: @github-handle` Dataview inline body field. Documents the 4-path resolution order (explicit --contributor > single-author-omit > .git-author-map.txt hit > map-miss-warn-and-omit). Example `.git-author-map.txt` entry included.
- **`## Privacy`** — Points to PRIVACY.md for tier model; states that `privacy-leak` CI job fails PRs with `privacy: local_only` in public paths while `wiki/**` remains exempt (per AGENTS.md §13).
- **`## Merge conflicts`** — Two recipes with full bash examples:
  - `### wiki/log.md` — "keep both sides, sort by timestamp" via `## [YYYY-MM-DD]` header sort; plus operator opt-in `.gitattributes` snippet `wiki/log.md merge=union` explicitly labeled NOT committed by default (D-24 rationale: surprise-prevention).
  - `### wiki/index.md` — "keep both, alphabetize within category, re-run lint"; explicit note that `merge=union` is NOT recommended for index.md (header collisions).
- **`## Lint severity tiers`** — 3-bullet tier summary (error blocks / warning annotates / info notice) then **points to AGENTS.md §11.3 as source of truth** and explicitly does NOT reproduce the category→severity table (Codex MEDIUM spec-duplication fix; test asserts the `| \`yaml\` |` table row is NOT present).
- **`## Escape-hatch markers`** — `lint:expect-inferred` / `lint:expect-tentative` syntax with 4 strictness rules (immediately-above adjacency + id match + non-empty reason + skip-count info emission).
- **D-23 scope honored:** No Code of Conduct. No release cadence. No release schedule. No governance. Test asserts all three exclusions.

### docs/reference/ci.md (267 lines, populated from 9-line stub)

- **`## TL;DR`** — 3-job CI overview with links to `.github/workflows/lint.yml`.
- **`## Severity policy`** — Opens with source-of-truth blockquote pointing to AGENTS.md §11.3 (Codex MEDIUM fix). Includes rationale table for 12 categories mapped to CI severities (yaml/orphan/crossref/provenance = error; stale/gap/contradiction/contradiction-sync/drift/contributor = warning; autofix/skip-count = info). Documents exit-code policy, default `drift-external` skip, and `--skip-category` override.
- **`## JSON output schema`** — Opens with source-of-truth blockquote. Full JSON example + field table (severity/category/path/line/message with required-ness and type). Notes `--format json` does NOT write lint-report.md.
- **`## Privacy-leak guard`** — PUBLIC_PATHS list (examples/, docs/, AGENTS.md, CLAUDE.md, README.md, .github/) + wiki/** exemption + frontmatter-only scan (D-14) + exit codes (0/1/2) + review-loop note for changing public paths.
- **`## --strict mode`** — D-08 PR-diff scope + D-10 new-page provenance + D-07 draft-skip + `fetch-depth: 0` rationale.
- **`## Escape-hatch markers`** — Syntax for both `inferred` and `tentative` variants + 3 strict placement rules + `skip-count` info-severity emission + `--count-skips` aggregator.
- **`## --require-version pinning`** — LINT_VERSION=1.1.0 + semver tuple comparison + workflow YAML example + MAJOR/MINOR/PATCH bump semantics + caveat on long-lived PRs + deferred `--require-exact-version`.
- **`## GitHub Actions (canonical)`** — Points to `.github/workflows/lint.yml` + operator branch-protection action + annotation shim reference (`.github/scripts/json-to-annotations.py`) + 10/10/50 cap strategy.
- **`## GitLab CI`** — 25-line `.gitlab-ci.yml` snippet covering all 3 jobs with `image: python:3.12-slim` + `GIT_DEPTH: "0"` on strict stage + GitLab-equivalent draft-skip via `$CI_MERGE_REQUEST_LABELS` (D-31 structure).
- **`## Gitea Actions`** — Schema-compatibility note (`.github/workflows/lint.yml` → `.gitea/workflows/lint.yml`) + runs-on adjustment guidance.
- **`## Codeberg (Forgejo Actions)`** — Fork-of-Gitea note + Codeberg-specific runner-image guidance.
- **`## Platform-neutral principles`** — 3-bullet summary of the portable pieces (JSON contract + exit-code semantics + severity policy table).
- **`## Out of scope (v1.1)`** — Bitbucket / Jenkins / Drone / Danger-JS / reviewdog / severity-escalation policy / exact-version pinning / merge-base lint / post-merge link-audit. Test asserts no top-level sections for Bitbucket/Jenkins/Drone but allows mention in this list.
- **`## See also`** — Back-links to AGENTS.md + CONTRIBUTING.md + PRIVACY.md + lint.yml.

### docs/reference/index.md

- Adds **`## Contributing`** subsection with a single bullet link to `../../CONTRIBUTING.md` (repo-root path via relative link). Existing Phase 7 bullet for `ci.md` is verified unchanged.

### Tests

- **`tests/phase-09/test_contributing_md.sh` (70 lines)** — structural + scope + no-CoC + no-release-cadence + spec-duplication-guard (fails if the full `| \`yaml\` |` category→severity table is present; pass requires linking to AGENTS.md §11.3 as source of truth).
- **`tests/phase-09/test_ci_docs.sh` (57 lines)** — stub replaced + 7-category severity coverage + 4 JSON schema keys + 8 required sections + Gitea/Codeberg multi-provider coverage + GitLab snippet presence + excluded-providers guard (no top-level Bitbucket/Jenkins/Drone sections) + escape-hatch marker example + `--require-version` docs + AGENTS.md §11.3 source-of-truth pointer.
- **`tests/phase-09/test_docs_cross_links.sh` (24 lines)** — ci.md outbound to PRIVACY.md/AGENTS.md/lint.yml/CONTRIBUTING.md + index.md reverse links to ci.md + CONTRIBUTING.md.

## Task Commits

Each task followed TDD (RED → GREEN):

1. **Task 1 RED: failing CONTRIBUTING.md structure test** — `d1f5347` (test)
2. **Task 1 GREEN: CONTRIBUTING.md** — `7a0717c` (feat)
3. **Task 2 RED: failing ci.md + cross-links tests** — `dfc19ca` (test)
4. **Task 2 GREEN: ci.md populated + index.md cross-links + phase-07 test relaxation** — `54c7f06` (feat)

All commits use the canonical Phase-9 format: `{type}(09-06): {description}` with extended body.

## Files Created/Modified

### Created

- `CONTRIBUTING.md` — 128 lines. Structure: How to contribute → CI gate → Attribution → Privacy → Merge conflicts → Lint severity tiers → Escape-hatch markers.
- `docs/reference/ci.md` — 267 lines (up from 9-line stub). Structure: TL;DR → Severity policy → JSON output schema → Privacy-leak guard → --strict mode → Escape-hatch markers → --require-version pinning → GitHub Actions (canonical) → GitLab CI → Gitea Actions → Codeberg (Forgejo Actions) → Platform-neutral principles → Out of scope (v1.1) → See also.
- `tests/phase-09/test_contributing_md.sh` — 70 lines, executable. PR-workflow-steps + attribution + merge-conflict recipes + privacy + CI link + source-of-truth AGENTS.md §11.3 + spec-duplication guard + escape-hatch marker + no-CoC + no-release-cadence.
- `tests/phase-09/test_ci_docs.sh` — 57 lines, executable. Stub-replaced + severity categories + JSON keys + 8 required section headings + multi-provider coverage + excluded-provider guard + escape-hatch + --require-version + §11.3 source-of-truth.
- `tests/phase-09/test_docs_cross_links.sh` — 24 lines, executable. Outbound + reverse links.

### Modified

- `docs/reference/index.md` — +4 lines: Contributing subsection + `../../CONTRIBUTING.md` relative link.
- `tests/phase-07/test_reference_stubs.sh` — drop ci.md from the stub-file list (now 4 files, not 5) + add inverse assertion `ci.md is NOT a stub` (Rule 3 obsoleted-by-future-phase relaxation; Phase 08-04 precedent).

## Decisions Made

All decisions followed the revised plan verbatim (post-Codex MEDIUM revision of 2026-04-16). Specific decisions worth preserving:

- **Source-of-truth designation enforced structurally.** CONTRIBUTING.md's "Lint severity tiers" section intentionally avoids reproducing the category→severity table and instead points readers to AGENTS.md §11.3. The test `test_contributing_md.sh` asserts this enforcement two ways: (a) `grep -qi "AGENTS\.md.*11\.3"` requires the AGENTS.md §11.3 pointer; (b) `grep -qE "^\| \`yaml\` \|"` must NOT match (spec-duplication guard). This prevents the drift risk Codex MEDIUM called out.
- **ci.md uses inline blockquotes for source-of-truth pointers.** Each of the two content-rich sections (Severity policy, JSON output schema) opens with `> **Source of truth:** ...` so a reader scanning headers immediately sees the canonical spec location. The rationale column in the severity table is intentionally kept — it adds user-facing context AGENTS.md §11.3 does not duplicate. This was an accepted Codex MEDIUM concession: partial spec duplication is fine when the duplicated content has distinct purpose.
- **`.gitattributes merge=union` documented as opt-in, not committed.** D-24 rationale preserved verbatim in CONTRIBUTING.md: "changes git behavior globally for the repo; contributors who haven't read this doc would be surprised. Opt in per-clone if you find yourself resolving log.md conflicts regularly." Test asserts the opt-in qualifier is present (`grep -qiE "not committed|do NOT commit|opt[ -]in"`).
- **Multi-provider scope deliberately narrow (D-31).** GitHub Actions canonical + GitLab snippet + Gitea compat note + Codeberg/Forgejo note. Explicitly excludes Bitbucket Pipelines / Jenkins / Drone — no ownership of cross-provider test coverage beyond the three providers. Test allows provider names in the "Out of scope" list but fails if any provider has a top-level section header.
- **Phase-07 test relaxation is Rule 3.** Phase 9 Plan 06's mandate is to fully populate ci.md. Phase 7 shipped a test that enforces ci.md carries a stub marker. This is the exact obsoleted-by-future-phase pattern Phase 8 hit with `test_docs_skeleton.sh`. Solution: drop ci.md from the stub-file list, add inverse assertion that ci.md is NOT a stub. The phase-07 test intent (release.md is fully populated; other stubs still marked) is preserved; only the specific file that moved to "populated" is updated.

## Deviations from Plan

**1. [Rule 3 - Blocking Issue] Relaxed tests/phase-07/test_reference_stubs.sh to drop ci.md from the stub-marker list.**

The phase-07 test asserts all 5 reference-track stubs (schema-tour.md, brownfield.md, privacy-model.md, ci.md, examples.md) carry the exact `Status: stub — populated in v1.1 Phase` marker. Phase 9 Plan 06's mandate is to fully populate ci.md (closing the D-11 stub-fill promise from Phase 7). These are incompatible — completing Plan 06 necessarily breaks the phase-07 assertion.

**Fix:** (a) remove ci.md from the `STUB_FILES` array (now 4 files: schema-tour.md, brownfield.md, privacy-model.md, examples.md), (b) add inverse assertion `grep -q 'Status: stub' docs/reference/ci.md` must NOT match (ci.md must not be a stub — the structural guarantee moved from "is a stub" to "is no longer a stub"). Comment documents the Phase 9 Plan 06 population rationale.

**Precedent:** Phase 08-04 applied exactly this pattern to phase-07 `test_docs_skeleton.sh` — relaxed "Phase 8" stub-marker assertions + raised quickstart line cap when Phase 8 populated those files. Both relaxations are structurally identical: a phase-completion assertion moves forward with the obsoleting phase's work.

**Files touched:** `tests/phase-07/test_reference_stubs.sh` (+5 / -3 lines). Commit: `54c7f06`.

**Scope-bounded:** The relaxation only changes the set of files required to carry the stub marker + adds the inverse assertion for ci.md. It does NOT change any other assertion in the test (release.md stub-absence, required-content greps, brownfield.md ruamel.yaml check all unchanged).

## Issues Encountered

**1. Phase-07 stub-marker regression.** Caught on first run of the phase-07 aggregator after committing ci.md. Diagnosed in <1 minute (test_reference_stubs.sh was explicitly asserting ci.md still has the stub marker). Fixed inline via Rule 3 relaxation. No further issues.

**Nothing else.** Both plan tests passed first run after GREEN implementation. CONTRIBUTING.md structure test and ci.md populate test matched the plan's `<behavior>` specifications exactly. Cross-links test confirmed both outbound and reverse-link integrity.

## Verification Results

All 3 new tests pass:

```
PASS: CONTRIBUTING.md structure + scope
PASS: docs/reference/ci.md fully populated
PASS: docs cross-links integrity
```

Full Phase 9 suite:

```
PHASE 09 TESTS: 28/28
```

Phase regressions (all green after Rule 3 relaxation):

```
PHASE 07 TESTS: 22/22
PHASE 08 TESTS: 21/21
```

CI guard invariants:

```
$ bash bin/check-privacy.sh
(exit 0 — clean)

$ bash bin/check-neutrality.sh
(exit 0 — clean)
```

Both new docs are free of privacy leaks and neutrality violations.

## Known Stubs

None — all deliverables fully populated. CONTRIBUTING.md has complete content for all 6 D-23 scope sections; ci.md covers all 13 required subsections per D-32; both tests exercise the full contract.

The remaining Diátaxis reference-track stubs (schema-tour.md, brownfield.md, privacy-model.md, examples.md) are intentional and tracked by the amended `test_reference_stubs.sh` — they will be populated in Phases 10-12 per the ROADMAP.

## Self-Check: PASSED

All created files exist:
- `CONTRIBUTING.md` — FOUND (128 lines, contains fork/branch/bin/ingest.sh/bin/lint.sh/PR + Attribution + Merge conflicts + .gitattributes opt-in + escape-hatch marker + AGENTS.md §11.3 source-of-truth pointer)
- `docs/reference/ci.md` — FOUND (267 lines, fully populated, 13 sections, no stub marker)
- `tests/phase-09/test_contributing_md.sh` — FOUND (executable)
- `tests/phase-09/test_ci_docs.sh` — FOUND (executable)
- `tests/phase-09/test_docs_cross_links.sh` — FOUND (executable)

Files modified verified:
- `docs/reference/index.md` — FOUND (Contributing subsection with `../../CONTRIBUTING.md` link)
- `tests/phase-07/test_reference_stubs.sh` — FOUND (STUB_FILES array contains 4 files; ci.md inverse assertion present)

Commits verified in git log:
- `d1f5347` — FOUND (Task 1 RED: failing CONTRIBUTING.md structure test)
- `7a0717c` — FOUND (Task 1 GREEN: CONTRIBUTING.md)
- `dfc19ca` — FOUND (Task 2 RED: failing ci.md + cross-links tests)
- `54c7f06` — FOUND (Task 2 GREEN: ci.md populated + index.md + phase-07 test relaxation)

## Next Phase Readiness

### Phase 9 is complete.

**Operator action required on the public repo (one-time):**

> Settings → Branches → Branch protection rule for `main`:
> - [x] Require status checks to pass before merging
> - Required checks: `lint`, `privacy-leak`, `strict` (alongside existing `neutrality`, `setup-parity`)

Once the operator sets these 3 required checks, the full Phase 9 contributor-PR-workflow + CI-gate + privacy-leak + strict ratchet is live. No code changes are pending from Phase 9 — all 6 plans complete.

### Ready for Phase 10 (Brownfield Scan + Bootstrap)

- CONTRIBUTING.md provides the contributor onboarding flow Phase 10's brownfield docs will extend (Phase 10 adds brownfield-specific subcommand docs to `docs/reference/brownfield.md`).
- `docs/reference/index.md` Contributing subsection is extensible — Phase 11 can add a brownfield-specific subsection if needed.
- The source-of-truth linking pattern established here (docs/reference/* → AGENTS.md §§N.N) is the template Phase 10 + Phase 11 follow when populating their stub files.

### When a contributor lands on the repo

1. Reads `README.md` → understands what the project does.
2. Reads `CONTRIBUTING.md` → understands PR workflow (fork → branch-per-ingest → ingest.sh → lint → PR), CI gate (3 jobs), attribution (git auth + contributor::), merge conflicts (log/index recipes), privacy (local_only never public), escape hatches in ~3 minutes.
3. Opens a PR → template auto-populates with 6-section D-29 checklist.
4. CI runs 3 parallel jobs → annotations surface inline in PR UI.
5. If questions remain, drills into `docs/reference/ci.md` for severity policy detail, JSON schema, multi-provider equivalents.
6. If adding an intentional `[inferred]` claim, adds `<!-- lint:expect-inferred id=... reason="..." -->` marker on line immediately above.

### No blockers or concerns.

---
*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Plan: 06 (contributing-docs-integration)*
*Completed: 2026-04-16*
*Phase 9: COMPLETE*
