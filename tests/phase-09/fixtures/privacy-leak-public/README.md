# Fixture: privacy-leak-public

**Purpose:** `privacy: local_only` frontmatter in a PUBLIC path (`docs/`) MUST cause `bin/check-privacy.sh` to exit 2 (CI-07 leak).

## Triggers

- CI-07 privacy-leak negative case: per D-14 (frontmatter-only scan) and D-15 (PUBLIC_PATHS includes `docs/`), any file under `docs/` with `privacy: local_only` in its YAML frontmatter is a leak that the privacy scanner must flag.

## Contents

- `docs/sample.md` — a sample doc page with `privacy: local_only` in frontmatter.

## Encoding discipline

LF line endings, UTF-8 encoding.
