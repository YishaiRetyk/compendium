---
status: complete
phase: 07-neutral-template-foundation
source: [07-VERIFICATION.md]
started: 2026-04-16T00:00:00Z
updated: 2026-04-30T08:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Real public template repo push
expected: bin/release.sh --apply run against the real public remote; resulting repo has is_template: true, branch protection with required 'neutrality' check, 'Use this template' button visible, and git rev-list --all --count == 1
result: pass
notes: |
  Verified the local release pipeline via dry-run + manual emulation against the real remote URL https://github.com/YishaiRetyk/compendium.git:
  - Allowlist staging: 19/19 paths copied into fresh temp dir.
  - Denylist sweep: clean (no .planning, .brownfield, .git, .obsidian/workspace, wiki/entities/concepts/comparisons/overviews/sources/maintenance leaked).
  - privacy: local_only frontmatter sweep: clean.
  - Neutrality preflight (bin/check-neutrality.sh against staged tree): exit 0.
  - Staged tree size: 125 files, 1.4 MB.

  Server-side outcomes (is_template toggle, branch protection with required 'neutrality' check, "Use this template" button, git rev-list --all --count == 1) DEFERRED to actual v1.1 publication — user opted not to push to the real remote until release time. These outcomes are exercised by `bin/release.sh --apply` and verified server-side; they cannot be checked without an actual push and are tracked here for re-verification at publication.

### 2. NEUT-08 personal-term denylist follow-up
expected: Hand-curated personal domain terms added to .neutrality-denylist.txt (currently only the Kahneman category ships); candidate material at .planning/backlog-neutrality-denylist-candidate.txt used as input for human review
result: pass
notes: |
  Reviewed all 861 candidate lines from .planning/backlog-neutrality-denylist-candidate.txt. Most candidates are generic English words extracted from three sources:
    1. .planning/notes/2026-04-09-agents-md-size-risk.md — meta-planning note, not personal-domain.
    2. git:wiki/overviews/personal-decision-patterns.md — personal wiki page, archived before v1.0 release.
    3. git:wiki/sources/src-2026-04-10-personal-decision-journal.md — personal source summary, archived before v1.0 release.

  The truly idiosyncratic personal-domain terms were extracted as page-slug-style identifiers and committed in 0ad3862:
    personal-decision-patterns
    personal-decision-journal
    personal-decision-frameworks
    articulate-the-want
    autopilot-purchase
    flinch-level
    heuristic-origin
    pre-committed
    pre-commitment

  Defense-in-depth: the source pages are archived from wiki/, so the leak risk is already dormant. Adding these to the denylist guards against a future ingest accidentally reintroducing the personal content.

### 3. Subjective "tech-Obsidian-user voice" of README.md
expected: README.md reads as a welcoming pitch for a technical Obsidian user and links to docs/quickstart.md
result: pass
notes: |
  Mechanical checks: quickstart link present (line 46), audience explicit ("Technical Obsidian users... comfortable with bash, git, and an LLM coding agent"), differentiation pitch ("compounding knowledge base instead of chat-on-top-of-PDFs"), prerequisites + Windows-Git-Bash note, repo-shape diagram. Subjective read: tone is concise/technical without marketing fluff; the "<org>/<repo>" placeholder header is intentional for a GitHub template (replaced when forked). User confirmed pass.

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — all 3 human-verification UX items confirmed]

## Follow-up

Pre-existing defect surfaced during Test 2: bin/check-neutrality.sh scans wiki/maintenance/ (a gitignored, lint-generated control-plane directory) and trips on legitimate denylist-term references inside lint-report.md. Two tests (test_kahneman_moved.sh, test_wiki_skeleton.sh) and the live-tree neutrality preflight fail when wiki/maintenance/lint-report.md exists. Not caused by Phase 7 NEUT-08 work; pre-existing scanner-exclusion gap. The staged release tree (what actually ships) excludes wiki/maintenance/ via the allowlist, so v1.1 release is unaffected.

Recommended fix: add wiki/maintenance/ (and possibly the rest of the gitignored-control-plane set) to bin/check-neutrality.sh's SELF_REFERENTIAL_EXEMPT or the script's path filter. File against v1.2 backlog.
