# Fixture: ci-lint-json

**Purpose:** Exercises all severity categories for `--format json` and `--ci` severity-remap validation (CI-02/CI-03).

Seeded with a minimal wiki skeleton; downstream tests seed additional triggering files inline via heredoc as needed (so the fixture stays minimal and does not drift when `bin/lint.sh` rules evolve).

## Intended triggers (added by tests as needed)

- `yaml` error — malformed frontmatter on a seeded page.
- `orphan` warning — page with no inbound wikilinks.
- `stale` warning — page with an old `checked_at`.
- `gap` info — red link referenced from index/body.

## Contents

- `wiki/index.md` — minimal index listing one concept (skeleton only).

## Encoding discipline

LF line endings, UTF-8 encoding.
