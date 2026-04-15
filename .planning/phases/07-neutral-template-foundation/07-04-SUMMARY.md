---
phase: 07-neutral-template-foundation
plan: 04
subsystem: public-surface-scaffolding
tags: [readme, license, privacy, docs, diataxis, release-runbook, wave-4]

requires:
  - phase: 07-neutral-template-foundation
    plan: 02
    provides: examples/kahneman/ relocation, wiki skeleton (ensures 'Repo shape' in README is accurate)
provides:
  - README.md (TMPL-02) — 7-section stranger-facing pitch with <org>/<repo> placeholder + link to docs/quickstart.md
  - LICENSE (TMPL-03) — MIT boilerplate
  - PRIVACY.md (TMPL-09) — two-tier local_only/cloud_safe explainer pointing to AGENTS.md as source of truth
  - .gitignore (TMPL-04) — 4-category coverage (Obsidian / .brownfield / .planning / OS+editor)
  - .gitattributes — LF eol for .md/.sh
  - .obsidianignore — starter default hiding examples/ with safe-to-delete comment header
  - docs/ four-track skeleton (TMPL-06/07) — Diátaxis mapping + quickstart/guided-setup/manual-setup/reference
  - docs/reference/ (TMPL-08) — 5 stubs + 1 full release runbook
  - tests/phase-07/test_readme.sh, test_license.sh, test_privacy.sh, test_gitignore.sh
  - tests/phase-07/test_docs_skeleton.sh, test_reference_stubs.sh, test_no_kahneman_in_public_docs.sh
affects:
  - 07-05 (release.sh + check-neutrality.sh can now reference docs/reference/release.md and the stranger-facing file set)
  - Phase 08 (wizard): docs/guided-setup.md + docs/manual-setup.md are stubs waiting to be populated alongside bin/init-wizard.sh
  - Phase 09 (CI): docs/reference/ci.md stub waiting to be populated alongside .github/workflows/lint.yml
  - Phases 10-11 (brownfield): docs/reference/brownfield.md stub waiting to be populated alongside bin/brownfield.sh
  - Phase 12 (reference polish): schema-tour, privacy-model, examples stubs waiting to be populated

tech-stack:
  added: []
  patterns:
    - "Kahneman-zero-tolerance test exempts sanctioned examples/kahneman/ path references via post-grep filter (mirrors 07-03 test_agents_neutralized.sh precedent)"
    - "ROOT env var override for phase-07 tests (matches WIKI_ROOT pattern from 07-02 and --root from 07-01)"
    - "Reference-stub template shape: frontmatter-free + 'Status: stub — populated in v1.1 Phase N' marker + 'See also' footer linking to AGENTS.md and docs/README.md"

key-files:
  created:
    - README.md
    - LICENSE
    - PRIVACY.md
    - .gitignore
    - .gitattributes
    - .obsidianignore
    - docs/README.md
    - docs/quickstart.md
    - docs/guided-setup.md
    - docs/manual-setup.md
    - docs/reference/index.md
    - docs/reference/schema-tour.md
    - docs/reference/brownfield.md
    - docs/reference/privacy-model.md
    - docs/reference/ci.md
    - docs/reference/examples.md
    - docs/reference/release.md
    - tests/phase-07/test_readme.sh
    - tests/phase-07/test_license.sh
    - tests/phase-07/test_privacy.sh
    - tests/phase-07/test_gitignore.sh
    - tests/phase-07/test_docs_skeleton.sh
    - tests/phase-07/test_reference_stubs.sh
    - tests/phase-07/test_no_kahneman_in_public_docs.sh
  modified: []

key-decisions:
  - "README 'Repo shape' tree neutralized: 'examples/kahneman/ — Daniel Kahneman, behavioral economics' replaced with 'examples/ — Reference example clusters (bundled sample domain)'. Plan's Interfaces spec listed the creator-named entry explicitly, but the plan's own Kahneman-zero-tolerance test forbids it. Neutralization won — the README is the stranger-facing pitch; a fresh template user should not encounter 'Daniel Kahneman' in their repo shape on clone."
  - "test_no_kahneman_in_public_docs.sh exempts lines that only reference the sanctioned `examples/kahneman/` directory path (required by quickstart's 'reference example you can browse for shape' and by release.md's published file list). Filter substracts `examples/kahneman[a-z0-9._/-]*` from each hit line before re-scanning for Kahneman tokens. Direct precedent: 07-03 test_agents_neutralized.sh `See: examples/kahneman/` pointer exemption."
  - "release.md smoke-check grep pattern uses `<creator-slug>|<creator-term-1>|<creator-term-2>` placeholders instead of the literal Kahneman tokens from the plan's source. Literal tokens would self-trip the Kahneman-zero-tolerance test for docs/ — the runbook is a template, not a creator-specific document."

requirements-completed: [TMPL-02, TMPL-03, TMPL-04, TMPL-06, TMPL-07, TMPL-08, TMPL-09]

duration: ~4min
completed: 2026-04-15
---

# Phase 07 Plan 04: Public-Surface Scaffolding Summary

**Shipped the 6 top-level stranger-facing files (README, LICENSE, PRIVACY, .gitignore, .gitattributes, .obsidianignore) + the four-track docs/ skeleton with Diátaxis mapping + 5 reference stubs + the full orphan-branch release runbook (docs/reference/release.md) that plan 07-05 depends on, with 7 new test scripts all green and `<org>/<repo>` as the sole org/repo placeholder throughout.**

## Performance

- **Duration:** ~4 min
- **Tasks:** 2
- **Tests:** 18/18 green (11 pre-existing + 7 new)
- **Commits:** 2

## Task Commits

1. **Task 1: Top-level files (README, LICENSE, PRIVACY, .gitignore, .gitattributes, .obsidianignore) + 4 tests** — `be8af2e` (feat)
2. **Task 2: docs/ four-track skeleton + 6 reference files + release runbook + Kahneman-zero-tolerance test** — `6b0df41` (docs)

## Files Shipped (one-line descriptions per plan output spec)

### Top-level public surface

- **README.md** — 7-section stranger-facing pitch (Title + tagline / What this is / Who this is for / Repo shape / Prerequisites / First step / License); `<org>/<repo>` placeholder in title and body; link to `docs/quickstart.md`; no RAG framing.
- **LICENSE** — MIT boilerplate, `Copyright (c) 2026 <org>/<repo> contributors`, standard permission + warranty clauses.
- **PRIVACY.md** — Two-tier model (`local_only` / `cloud_safe`) explained in user-facing prose; operational-meaning bullets (local ingest / remote filter / CI gate scope / stricter-wins); "must never commit" list (local_only pages, creator-specific terms, .planning/, .brownfield/); pointer to `AGENTS.md §5` as source of truth; **no** CI grep logic copied in (D-12).
- **.gitignore** — 4 categories (Obsidian noise / .brownfield / .planning / OS+editor) with literal patterns required by test_gitignore.sh (`.obsidian/workspace*`, `.obsidian/cache`, `.trash/`, `.brownfield/`, `.planning/`, `.DS_Store`, `Thumbs.db`, `*.swp`, `.idea/`, `.vscode/`).
- **.gitattributes** — `*.md text eol=lf` + `*.sh text eol=lf` (STACK.md recommendation for line-ending normalization across contributors).
- **.obsidianignore** — Single content line `examples/`; explicit starter-default comment header with safe-to-delete instructions (REVIEWS.md medium #3 on 07-04).

### docs/ four-track skeleton (Diátaxis)

- **docs/README.md** — 4-row Diátaxis mapping table (tutorial / how-to guided / how-to manual / reference); 1-paragraph orientation.
- **docs/quickstart.md** — 27-line Phase-8-aware stub (≤60 per D-11); four numbered steps; canonical flow names `bin/init-wizard.sh` + `bin/ingest.sh` + `Obsidian`; two Phase-8 callouts for the sections Phase 8 will populate; pointer block to `../AGENTS.md`, `reference/schema-tour.md`, `reference/privacy-model.md`.
- **docs/guided-setup.md** — Phase 8 stub; 4 lines.
- **docs/manual-setup.md** — Phase 8 stub; 4 lines.

### docs/reference/

- **docs/reference/index.md** — Bulleted list linking to the 6 reference files with owning-phase annotation.
- **docs/reference/schema-tour.md** — Phase 12 stub; stub template; scope: "the frontmatter schema in AGENTS.md §5 and how claims cite their sources".
- **docs/reference/brownfield.md** — Phase 10/11 stub; stub template; scope: "scan / bootstrap / suggest / verify for an existing Obsidian vault"; flags `ruamel.yaml` prerequisite per ROADMAP Phase 10.
- **docs/reference/privacy-model.md** — Phase 12 stub; scope: "the `local_only` / `cloud_safe` tiers, conflict resolution, and CI enforcement".
- **docs/reference/ci.md** — Phase 9 stub; scope: ".github/workflows/lint.yml, severity policy, privacy-leak guard, GitLab/Gitea/Codeberg equivalents".
- **docs/reference/examples.md** — Phase 12 stub; scope: "how `examples/` works, Obsidian graph filtering via `.obsidianignore`, and safely copying example pages into `wiki/`".
- **docs/reference/release.md** — **FULL RUNBOOK (not a stub; 07-05 depends on this).** Sections: Prerequisites (clean tree, remote configured, neutrality green, CLAUDE.md byte-equal, phase-07 tests green) / What the script publishes (explicit public file set — AGENTS.md, CLAUDE.md, README.md, LICENSE, PRIVACY.md, .gitignore+.gitattributes+.obsidianignore, bin/, schema/, examples/kahneman/**, wiki/index.md + wiki/log.md + wiki/decisions/**, docs/**, .github/workflows/neutrality.yml, .githooks/pre-commit, .neutrality-denylist.txt) / Dry-run first (`--dry-run` semantics + printed audit) / Apply (`--apply` + pre-flight check-neutrality.sh + interactive `y` confirmation; no `--yes` flag in v1.1) / Post-publish smoke check / Rollback / Template upgrades deferred-to-v1.2 note.

### Tests (under tests/phase-07/)

- **test_readme.sh** — 5 assertions (exists, links to quickstart, ≥5/6 sections, placeholder, no RAG framing).
- **test_license.sh** — 3 assertions (MIT header, permission clause, warranty disclaimer).
- **test_privacy.sh** — 4 assertions (local_only, cloud_safe, AGENTS.md pointer, no CI grep copy).
- **test_gitignore.sh** — 10 assertions (one per required pattern).
- **test_docs_skeleton.sh** — 12 assertions (4 files exist, Diátaxis named, 4 track links, 4 quickstart content markers, ≤60 line constraint).
- **test_reference_stubs.sh** — 16 assertions (7 files exist, 5 stubs carry marker + aggregate check, release.md not-a-stub, 5 release.md content tokens, ruamel.yaml mention).
- **test_no_kahneman_in_public_docs.sh** — 1 aggregate assertion with sanctioned-path-exemption filter.

## `<org>/<repo>` Placeholder Audit (D-02)

| File | Occurrences |
|------|-------------|
| README.md | 2 (title H1 + "Use this template" sentence in Prerequisites section) |
| LICENSE | 1 (`<org>/<repo> contributors`) |
| docs/quickstart.md | 1 (step 1 "Use this template") |
| docs/reference/release.md | 3 (clone URL × 2, smoke check clone) |
| **Total** | **7** |

No `your-org/your-repo` or `USER/REPO` forms used anywhere. `<org>/<repo>` angle-bracket form is the single template-wide convention (D-02).

## Test Assertion Counts Passed

- test_readme: 5/5
- test_license: 3/3
- test_privacy: 4/4
- test_gitignore: 10/10
- test_docs_skeleton: 14/14 (file-existence bundle expanded)
- test_reference_stubs: 16/16 (per-file stub bundle + aggregate)
- test_no_kahneman_in_public_docs: 1/1

**Plan-04-new assertions total: 53/53.**

`bash tests/phase-07/run.sh` — 18/18 test scripts PASS (11 pre-existing from 07-01..03 + 7 new from 07-04).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan's README spec and plan's own Kahneman-zero-tolerance test are mutually contradictory**

- **Found during:** Task 2 test_no_kahneman_in_public_docs.sh first run.
- **Issue:** Plan Interfaces block specified the README "Repo shape" tree must contain `examples/kahneman/        Reference example cluster (Daniel Kahneman, behavioral economics)`. Plan Task 2 step 9 also specified a test that forbids `daniel.kahneman` (and 6 other Kahneman tokens) in README.md / PRIVACY.md / docs/. The literal words "Daniel Kahneman" in README line 24 tripped the test.
- **Fix:** Neutralized README line 24 to `examples/                 Reference example clusters (bundled sample domain)`. The stranger-facing README should not carry the creator's personal domain choice; the `examples/kahneman/` subdirectory name is a quirk of this starter's bundled reference cluster (fine per path-exemption, see fix #2) but the name of the person whose work it represents is not something a fresh-clone user should need to encounter before reading `examples/kahneman/README.md`.
- **Precedent:** Mirrors 07-03's same-shape deviation where the neutralization regex was made smart about sanctioned pointer lines.
- **Commit:** `6b0df41` (Task 2).

**2. [Rule 1 — Bug] Kahneman-zero-tolerance test as literally spec'd self-contradicts plan's own quickstart content spec**

- **Found during:** Task 2 same first-run failure.
- **Issue:** quickstart.md explicitly needs to reference `examples/kahneman/` (plan step 2 quickstart content: "The `examples/kahneman/` cluster (hidden from Obsidian by default via `.obsidianignore`)"). release.md file-set list includes `examples/kahneman/**`. Both are required by the plan; both trip the literal grep.
- **Fix:** `test_no_kahneman_in_public_docs.sh` strips `examples/kahneman[a-z0-9._/-]*` substrings from each grep hit line before re-scanning for Kahneman tokens. Lines that only reference the sanctioned directory path pass; lines that mention Kahneman terms in any other context still fail. Test comment documents the exemption and its 07-03 precedent.
- **Commit:** `6b0df41` (Task 2).

**3. [Rule 1 — Bug] release.md smoke-check grep pattern would self-trip the Kahneman-zero-tolerance test**

- **Found during:** Task 2 test_no_kahneman_in_public_docs.sh first run (third hit on docs/reference/release.md:21 — the literal `grep -rIn -iE 'kahneman|prospect.theory|loss.aversion'` copied verbatim from the plan body into release.md).
- **Issue:** The plan's release.md body includes a smoke-check grep that uses literal Kahneman tokens. But release.md is a template in the public surface; those tokens inside the grep pattern still count as Kahneman mentions and trip the test.
- **Fix:** Replaced the literal Kahneman tokens in release.md's smoke-check grep with `<creator-slug>|<creator-term-1>|<creator-term-2>` placeholders matching the template-wide `<angle-bracket>` illustrative-token convention from 07-03 D-08. The runbook instruction ("grep for creator-specific terms that shouldn't appear") remains clear; the concrete tokens that got neutralized in Phases 07-02/07-03 are what the user's own check-neutrality.sh denylist (07-05) will carry.
- **Commit:** `6b0df41` (Task 2).

## Authentication Gates

None.

## Deferred Issues

None — plan scope was self-contained.

## Known Stubs

Five intentional stubs shipped per plan output spec:

- `docs/guided-setup.md` — marked Phase 8
- `docs/manual-setup.md` — marked Phase 8
- `docs/reference/schema-tour.md` — marked Phase 12
- `docs/reference/brownfield.md` — marked Phase 10/11
- `docs/reference/privacy-model.md` — marked Phase 12
- `docs/reference/ci.md` — marked Phase 9
- `docs/reference/examples.md` — marked Phase 12

Each stub carries the literal `Status: stub — populated in v1.1 Phase N` marker so future phases have a mechanically-detectable target for "find the stubs I own and fill them in". `docs/reference/release.md` is deliberately NOT a stub (Phase 7 owns it; 07-05 depends on it).

Two Phase-8 callouts inside `docs/quickstart.md` (steps 2 and 3) are the only in-body placeholders; they use a distinct `> Phase 8 — this section lands in v1.1 Phase 8. ...` blockquote so a regex scan for quickstart stubs will find them without colliding with the "Status: stub" convention used for fully-stubbed files.

## Verification

- `bash tests/phase-07/run.sh` → **18/18 test scripts passing**.
- `bash tests/phase-07/test_readme.sh` → 5/5.
- `bash tests/phase-07/test_license.sh` → 3/3.
- `bash tests/phase-07/test_privacy.sh` → 4/4.
- `bash tests/phase-07/test_gitignore.sh` → 10/10.
- `bash tests/phase-07/test_docs_skeleton.sh` → 14/14.
- `bash tests/phase-07/test_reference_stubs.sh` → 16/16.
- `bash tests/phase-07/test_no_kahneman_in_public_docs.sh` → PASS.
- Manual voice check (D-10 / D-12): README.md and PRIVACY.md read plainspoken, honest, no fluff, no marketing copy. **Held at phase-gate** (post-07-05) for human review.

## Next Phase Readiness (07-05)

- `docs/reference/release.md` exists as a full runbook with `--dry-run` / `--apply` / `check-neutrality.sh` / Prerequisites / Rollback sections — 07-05 `bin/release.sh` and `bin/check-neutrality.sh` can be written directly against this contract.
- The public file set is enumerated in release.md "What the script publishes" — 07-05 release.sh stages precisely this list.
- `<org>/<repo>` is the template-wide placeholder; 07-05's `--remote` flag parses user-supplied `git@github.com:<org>/<repo>.git` syntax for the publish target.
- Kahneman-zero-tolerance test establishes the narrow (plan-04-owned surfaces) floor; 07-05's `check-neutrality.sh` extends to the full public surface + denylist-driven scanning.

---
*Phase: 07-neutral-template-foundation*
*Completed: 2026-04-15*

## Self-Check: PASSED

Verified:

- FOUND: README.md, LICENSE, PRIVACY.md, .gitignore, .gitattributes, .obsidianignore
- FOUND: docs/README.md, docs/quickstart.md, docs/guided-setup.md, docs/manual-setup.md
- FOUND: docs/reference/{index,schema-tour,brownfield,privacy-model,ci,examples,release}.md (7 files)
- FOUND: tests/phase-07/test_readme.sh, test_license.sh, test_privacy.sh, test_gitignore.sh, test_docs_skeleton.sh, test_reference_stubs.sh, test_no_kahneman_in_public_docs.sh
- FOUND commit: be8af2e (Task 1 — top-level files)
- FOUND commit: 6b0df41 (Task 2 — docs/ skeleton + reference stubs + release runbook)
- `bash tests/phase-07/run.sh` exits 0 with 18/18 test scripts passing
- 53/53 new plan-04 test assertions pass
