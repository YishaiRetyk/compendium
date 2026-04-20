# end-to-end-golden fixture

This fixture holds the golden final vault state after the full Phase 11
happy-path runs against `small-vault-ambiguous/input/`:

```
suggest -> review-typing (approve all) -> 01 --apply -> 02 --apply
        -> 03 (advisory) -> 04 (advisory) -> verify -> verify --promote
```

All four input pages under `wiki/` end up at `bootstrap_stage: verified`
with `type:` filled in and eligible TL;DR / Key Facts bullets tagged with
`[epistemic:: inferred]`.

## Env-var pins for determinism

```
BROWNFIELD_FIXTURE_TODAY=2026-04-20
BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
BROWNFIELD_TOOL_VERSION=1.1.0
```

## Regeneration recipe

```bash
TMP=$(mktemp -d -t e2e-golden-XXXXX)
cp -a tests/phase-11/fixtures/small-vault-ambiguous/input/. "$TMP"/
(cd "$TMP" && git init -q -b main \
   && git config user.email "fixture@example.com" \
   && git config user.name "Fixture" \
   && git add -A \
   && git -c commit.gpgsign=false commit -q --allow-empty -m init)

export PYTHONPATH="$HOME/.local/lib/python3/dist-packages"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0

bash bin/brownfield.sh suggest --root "$TMP"
printf 'a\na\na\na\na\na\n' | bash bin/brownfield.sh review-typing --root "$TMP"
bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply
bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply
bash "$TMP/.brownfield/migrations/03-cross-link-inference.sh"
bash "$TMP/.brownfield/migrations/04-privacy-review.sh"
bash bin/brownfield.sh verify --root "$TMP"
bash bin/brownfield.sh verify --root "$TMP" --promote

rm -rf tests/phase-11/fixtures/end-to-end-golden/expected
mkdir -p tests/phase-11/fixtures/end-to-end-golden/expected
cp -a "$TMP/wiki" tests/phase-11/fixtures/end-to-end-golden/expected/
```

See `tests/phase-11/fixtures/README.md` for the full fixture-layout contract.

`test_end_to_end_happy_path.sh` (Plan 11-01) performs `diff -rq` against
`expected/wiki/**` when this directory exists.
