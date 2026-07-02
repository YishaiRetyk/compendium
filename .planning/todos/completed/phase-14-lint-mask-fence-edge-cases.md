---
created: 2026-06-03T00:00:00
title: Harden bin/lint.sh mask_markdown for fence edge cases (Phase 14 review residue)
area: tooling
files:
  - bin/lint.sh:406
  - bin/lint.sh:1114
---

## Problem

The Phase 14 code review (`.planning/phases/14-graph-link-resolution/14-REVIEW.md`)
surfaced four masking findings. WR-01 (gap red-link scan unmasked) and WR-04
(missing test for the provenance-scan masking) were fixed during phase execution
(commits `a259dcb`, `7a4055b`). The following are **deferred** — latent edge cases
not currently triggered on the live wiki (`--ci --category linkres wiki/` exits 0,
gap scan clean), so they are tracked rather than fixed in Phase 14:

**WR-02 (`bin/lint.sh:406`) — unclosed fenced block leaks into scans.**
`mask_markdown`'s `_FENCE_RE` only matches *closed* ` ``` … ``` ` pairs. A valid
CommonMark unclosed fence (extends to EOF) is NOT masked, so a `[[Example]]` inside
it is flagged as a bare-link linkres error AND `--fix` could rewrite it *inside* the
code block (content-mutation risk). Fix: extend `_FENCE_RE` to also match an opening
fence with no closing fence through end-of-file.

**WR-03 (`bin/lint.sh:406`) — closing fence with trailing info string not matched.**
A closing line like ` ```ruby ` (info string on the closing fence) defeats the
close-match, leaking content. Fix: tolerate trailing whitespace/info-string on the
fence line per CommonMark.

**INFO items (low priority):**
- IN-01: redundant `/`-target check between `_classify_piped` and its caller.
- IN-02: CRLF files bypass frontmatter masking (stays splice-safe; cosmetic).
- IN-03: linkres silently skips unparseable-frontmatter pages, deferring to the
  `yaml` error check (acceptable, documented here for awareness).

## Why deferred

Phase 14's goal (graph connects via uniform piped links) is achieved and
human-verified; these are robustness hardening of the masking helper, not
correctness gaps in the shipped data. Bundle with any future `bin/lint.sh`
masking work. Add fixtures: unclosed-fence page, info-string-closing-fence page.
