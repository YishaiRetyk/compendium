# Fixture: contributor-multi

**Purpose:** Multi-author git repo fixture.

Test setup calls `setup_git_author` TWICE to add commits by `alice@example.com` and `bob@example.com`. The seeded `.git-author-map.txt` maps `alice@example.com -> @alice` but NOT `bob@example.com`.

## Expected auto-detect behavior

- When `git config user.email` is `alice@example.com`: emit `contributor:: @alice`.
- When `git config user.email` is `bob@example.com`: warn (unmapped email) and omit the `contributor::` field.
- When no git config is set and multi-author heuristic triggers but current commit author is unresolvable: warn + omit.

## Triggers

- COLAB-04 multi-author case with partial map coverage: exercises both the mapped (alice) and unmapped (bob) branches.

## Contents

- `.git-author-map.txt` — email-to-handle mapping (2-space arrow 2-space separator).

## Encoding discipline

LF line endings, UTF-8 encoding. The map-file parser is strict about whitespace and delimiter shape.
