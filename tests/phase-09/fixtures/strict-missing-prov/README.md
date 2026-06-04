# Fixture: strict-missing-prov

**Purpose:** New-page detection — a git-diff status `A` page with `type` in {entity, concept, overview, comparison} and ZERO `[prov:` occurrences MUST cause `bin/lint.sh --strict` to exit non-zero.

## Triggers

- CI-06 new-page-without-provenance: per D-10, a newly-added page in the four provenance-requiring types with no `[prov:` markers anywhere in the body is a hard failure.

## Contents

- `wiki-cloud/concepts/new-concept.md` — concept page whose body contains NO `[prov:` markers.

## Test harness pattern

Tests call `seed_origin_main_ref` after `make_fixture_repo` and optionally add a second commit to make the page appear as status-A in `git diff --name-status origin/main...HEAD`.

The fixture has no `[epistemic:: inferred]` markers so it does NOT trigger the DR-match rule (isolates the provenance check).

## Encoding discipline

LF line endings, UTF-8 encoding.
