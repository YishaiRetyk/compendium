# Phase 10 Brownfield Fixtures

Byte-frozen fixtures backing BRWN-21 (test harness for `bin/brownfield.sh bootstrap`).

These files are the golden input for BRWN-21; any change to them is an
**intentional fixture regeneration**, not a drive-by edit.  Plan 03's
`bin/brownfield.sh bootstrap --apply` must produce output that is byte-equal
to every `expected/page.md` here — or the fixtures are regenerated in lockstep
with the intentional Plan 03 change, never silently.

## Dual Golden Contract (D-07)

Phase 10 CONTEXT.md Decision D-07 mandates two shapes of fixture:

| Fixture type | Layout                                    | Asserts                                                                                              |
|--------------|-------------------------------------------|------------------------------------------------------------------------------------------------------|
| Parseable    | `input/page.md` + `expected/page.md`      | `bin/brownfield.sh bootstrap --apply` produces `expected/page.md` byte-exact (`cmp -s`).             |
| Unparseable  | `input/page.md` + `expected-skipped-entry.md` | `input/page.md` is left untouched AND `.brownfield/SKIPPED.md` contains the expected entry block. |

## Fixture Roster (7 fixtures)

Six fixtures come from D-07's canonical roster; the seventh
(`duplicate-yaml-keys`) is added per CONTEXT.md §Specifics bullet 8 to
guarantee the skip-artifact contract is testable even if ruamel.yaml parses
tabs permissively.

### Parseable (5)

1. **`clean-frontmatter`** — well-formed frontmatter page; tests Class A/B
   preserve + absent-field injection.
2. **`no-frontmatter`** — bare markdown with no frontmatter block; tests the
   full D-14 sentinel set injection path.
3. **`crlf`** — CRLF line endings throughout input; tests ruamel.yaml's
   documented LF-normalize-on-write behaviour (D-03).  The input file is
   intentionally authored with literal `\r\n` bytes on disk; see
   `.gitattributes` entry `tests/phase-10/fixtures/crlf/input/page.md -text`
   which tells git not to normalize this file on checkout.
4. **`dataview-inline`** — frontmatter plus a body containing Dataview inline
   fields (`foo:: bar`); bootstrap must NOT touch the body (AGENTS.md §6
   mixed inline grammar — `[prov:]` + `[epistemic::]` + `foo::` coexist).
5. **`frontmatter-with-comments`** — YAML comments between fields; tests the
   ruamel.yaml round-trip preserves comments (BRWN-06).

### Unparseable (2)

6. **`tabs-in-yaml`** — literal tab character indentation inside the
   frontmatter (YAML spec rejects tabs for indentation); skip-artifact fixture.
7. **`duplicate-yaml-keys`** — same YAML key twice in the frontmatter block;
   skip-artifact fixture (YAML spec forbids duplicate keys).

## EOL Policy

All parseable `expected/page.md` files use LF + UTF-8 without BOM (matches
Phase 09-01 D invariant: "All seeded .md fixtures use LF + UTF-8").  This is
pinned via `.gitattributes`:

```
tests/phase-10/fixtures/**/*.md text eol=lf
```

with a single exception for the `crlf` fixture's input:

```
tests/phase-10/fixtures/crlf/input/page.md -text
```

The `-text` attribute disables all EOL conversion so git preserves the
literal `\r\n` bytes across platforms.

ruamel.yaml normalizes CRLF to LF on write, so the `crlf` fixture's
`expected/page.md` uses LF — this is the expected behavior, not a bug.

## Fixture Date Freeze

Every parseable `expected/page.md` freezes both `created_at` and
`updated_at` to `2026-04-17`, and sets `bootstrap_date: 2026-04-17`.  This
keeps `expected/` byte-stable across runs (see CONTEXT.md D-14 "For fixtures,
freeze to 2026-04-17").

Plan 03's bootstrap implementation will need a test-mode date injection
(either via `BROWNFIELD_TODAY=2026-04-17` env var, a `--today` flag, or a
fixture-specific clock shim) to produce the pinned dates.  Without this, the
fixtures will drift daily.

## Regeneration Recipe

After Plan 03 ships an intentional change to field order, YAML rendering, or
default values:

```bash
# 1. Run bootstrap against every parseable fixture input.
for f in clean-frontmatter no-frontmatter crlf dataview-inline frontmatter-with-comments; do
    BROWNFIELD_TODAY=2026-04-17 bash bin/brownfield.sh bootstrap --apply \
        tests/phase-10/fixtures/$f/input/
    cp tests/phase-10/fixtures/$f/input/page.md tests/phase-10/fixtures/$f/expected/page.md
done

# 2. For unparseable fixtures, regenerate the SKIPPED.md entry block.
# (Plan 03 documents the exact shape and any ruamel.yaml parse-error substitution.)

# 3. Verify the regeneration.
bash tests/phase-10/run.sh

# 4. Commit as a deliberate fixture regeneration.
git add tests/phase-10/fixtures/
git commit -m 'fixtures(phase-10): regenerate after <reason>'
```

## Canonical Field Order (Deliberate Implementation Constraint)

The `expected/page.md` files define the **canonical field order and scalar
rendering** for bootstrap output.  This is deliberate — Plan 03's
`bin/brownfield.sh bootstrap --apply` must produce output matching this exact
field ordering, YAML null rendering (`null` not `~`), quote style, and scalar
format.  Changes to field order or rendering in Plan 03 require regenerating
these fixtures, not silently drifting.

See the D-07 Decision in `.planning/phases/10-brownfield-scan-bootstrap/10-CONTEXT.md`
for the source-of-truth specification.
