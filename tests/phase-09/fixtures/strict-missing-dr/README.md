# Fixture: strict-missing-dr

**Purpose:** Strict mode — `[epistemic:: inferred]` claim with NO matching decision record.

`bin/lint.sh --strict` MUST exit non-zero on this fixture: the `[inferred]` claim on `wiki-cloud/concepts/attention.md` has no corresponding `type: decision` page in `wiki-cloud/decisions/` listing `attention` in `affected_pages`.

## Triggers

- CI-06 strict-mode DR-match negative case: every `[inferred]` claim on a changed wiki page must be accompanied by a decision record whose `affected_pages` includes the page ID.

## Contents

- `wiki-cloud/concepts/attention.md` — concept page with one `[epistemic:: inferred]` claim and no matching decision record.

## Encoding discipline

All seeded `.md` files use LF line endings and UTF-8 encoding (no BOM, no CRLF). Line-number-sensitive assertions in Plan 09-03 rely on this.

## Harness

`make_fixture_repo strict-missing-dr` copies this tree (minus README.md) into a mktemp dir and seeds a single commit.
