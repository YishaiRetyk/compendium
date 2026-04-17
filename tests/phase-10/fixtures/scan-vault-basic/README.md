# scan-vault-basic fixture

Purpose: exercise the six Plan 10-02 test contracts — `--help`, REPORT.md
shape, default exclusions, confidence labels, `unknown` framing, and the
`.brownfield-ignore` negation contract.

This fixture is copied into a temp dir by `make_fixture_repo scan-vault-basic`
(helper from `tests/phase-10/lib.sh`); tests then run
`bash bin/brownfield.sh scan --root <tmp>` against the copy.  The fixture
itself is never mutated.

## Page roster and expected classification

| Path | Expected label | Confidence | Reason |
|------|---------------|-----------|--------|
| `wiki/entities/SomeEntity.md`       | `entity`  | `high`    | frontmatter `type: entity` wins |
| `wiki/concepts/some-concept.md`     | `concept` | `high`    | frontmatter `type: concept` wins |
| `wiki/sources/src-2026-04-01-paper.md` | `source` | `high` | frontmatter `type: source` wins |
| `vault/musings.md`                  | `unknown` | `unknown` | no frontmatter, no section signals, no filename convention |
| `.obsidian/workspace.json`          | (excluded) | —        | built-in `.obsidian/**` denylist |
| `attachments/diagram.md`            | `unknown` | `unknown` | lowercase filename, no frontmatter, no section signals; un-excluded by `.brownfield-ignore` negation |

The `.brownfield-ignore` file at the fixture root carries a single
`!attachments` negation line (gitignore-like subset).  Tests exercising the
default-exclusion contract remove or bypass this file; tests exercising
negation keep it in place.

## Byte-exactness

This fixture is NOT a byte-equality golden.  Scan writes to
`.brownfield/REPORT.md` inside the temp copy; tests grep the report contents
rather than comparing byte-by-byte.  (Plan 10-03 bootstrap fixtures are the
byte-equality set under `tests/phase-10/fixtures/{clean-frontmatter,…}`.)
