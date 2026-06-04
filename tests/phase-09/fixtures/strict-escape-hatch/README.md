# Fixture: strict-escape-hatch

**Purpose:** Escape-hatch marker on line IMMEDIATELY above an `[epistemic:: inferred]` claim MUST exempt the claim from `--strict` failure (D-09).

Blank line between marker and claim MUST invalidate the exemption (negative case: tests modify the fixture in-place at test time, fixture itself stays positive).

## Triggers

- CI-06 D-09 escape-hatch positive case: `<!-- lint:expect-inferred id=<page-id> reason="<why>" -->` on the line immediately above the `[epistemic:: inferred]` claim exempts that claim from the strict DR-match check.

## Contents

- `wiki-cloud/concepts/attention.md` — same shape as `strict-missing-dr/` but with the escape-hatch marker on the line directly above the `[inferred]` claim (no blank line between).

## Line-order discipline

The escape-hatch comment and the `[inferred]` claim MUST be on consecutive lines with NO blank line in between. Plan 09-03's strict tests rely on exact line-adjacency detection.

## Encoding discipline

LF line endings, UTF-8 encoding. Critical for the line-adjacency check.
