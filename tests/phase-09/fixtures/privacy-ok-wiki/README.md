# Fixture: privacy-ok-wiki

**Purpose:** `privacy: local_only` inside `wiki/` is valid user content per AGENTS.md §13. `bin/check-privacy.sh` MUST exit 0 on this fixture.

## Triggers

- CI-07 privacy positive case: `wiki/` is NOT in PUBLIC_PATHS (D-15). Local-only content lives here by design; the privacy scanner must leave it alone.

## Contents

- `wiki/local.md` — a wiki page with `privacy: local_only` in frontmatter (legitimate user content).

## Encoding discipline

LF line endings, UTF-8 encoding.
