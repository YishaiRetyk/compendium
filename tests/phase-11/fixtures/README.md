# Phase 11 Brownfield Suggest+Verify Fixtures

Byte-frozen fixtures backing BRWN-11..BRWN-22 (test harness for
`bin/brownfield.sh suggest`, the four canonical migration scripts under
`schema/brownfield/migrations/`, `bin/brownfield.sh review-typing`, and
`bin/brownfield.sh verify`).

These files are the golden input for Phase 11; any change is an
**intentional fixture regeneration**, not a drive-by edit.  Later plans
(11-02/03/04/05) produce `expected/` artifacts that must be byte-equal to
committed goldens — or the fixtures are regenerated in lockstep with the
intentional plan change, never silently.

## Fixture Layout Contract (D-20)

Each fixture directory has three pieces:

- `input/` — starting vault content (deterministic; frozen bytes).
- `expected/` — golden output artifacts produced by Plans 11-02..11-04.
  Wave-0 (Plan 11-01) commits this subdirectory empty; Plans 11-02..11-04
  populate it as GREEN tests land.
- `README.md` — one-paragraph intent + which contract or review-feedback
  item the fixture exercises.

## Fixture Roster (7 fixtures)

Five fixtures come from CONTEXT.md Decision D-20; the sixth and seventh
(`repo-root-shape-vault`, `nested-bullets-vault`) are added per REVIEWS.md
items 3 and 5 respectively.

### D-20 Core (5)

1. **`small-vault-ambiguous`** — 3–6 pages, <10 clusters. Exercises the TTY
   small-batch path of `review-typing` (below the N=20 threshold per
   RESEARCH Q3).  Mixed kebab-case and PascalCase filenames, varied H1s.
2. **`large-vault-ambiguous`** — ≥25 pages, ≥20 clusters. Exercises the
   AI-handoff large-batch path of `review-typing` (prompt written to
   `.brownfield/review-typing-prompt.md` for out-of-band AI execution).
3. **`pre-typed-vault`** — 5 of 6 pages already have valid `type:`
   frontmatter; proves `02-provenance-bootstrap`'s state-based prereq is
   satisfied (no majority-untyped WARN).
4. **`privacy-sensitive-vault`** — 3 pages containing email-like
   (`jdoe@acme.com`), phone-like (`212-555-0199`), SSN-like (`123-45-6789`)
   strings.  Exercises `04-privacy-review`'s pattern set and proves the
   advisory-only / never-flips-privacy contract.
5. **`already-tagged-vault`** — pages where every TL;DR + Key Facts bullet
   already carries `[epistemic:: sourced]` or `[epistemic:: inferred]`.
   Proves `02-provenance-bootstrap` is idempotent and reports honestly
   when no eligible bullets remain.

### Review-Feedback Additions (2)

6. **`repo-root-shape-vault`** — *NEW per REVIEWS.md item 3*. Mimics a
   real repo root with control-plane surfaces (`docs/`, `schema/`,
   `examples/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/`) plus a
   single real target page (`wiki/concepts/foo.md`).  Ships with a
   `.brownfield-ignore` file listing the canonical exclusions.  Exercises
   `test_suggest_respects_brownfield_ignore.sh` — locks Plan 11-02's
   contract that suggest MUST reuse Phase 10's `.brownfield-ignore` parser
   rather than forking the walker logic.
7. **`nested-bullets-vault`** — *NEW per REVIEWS.md item 5*. Pages whose
   TL;DR + Key Facts sections contain BOTH top-level bullets (column 0
   `-`) AND markdown-standard nested indented bullets (`  -` at col 2 and
   `    -` at col 4).  Exercises `test_02_top_level_bullets_only.sh` —
   locks Plan 11-03's regex tightening (only top-level bullets gain
   `[epistemic:: inferred]`; nested bullets remain untouched).

## Test Tagging Convention — `# EXPECTED_BY:`

Per REVIEWS.md item 6 (per-plan gate split), every `test_*.sh` file's
SECOND LINE is:

```bash
# EXPECTED_BY: 11-NN
```

where `11-NN` is one of `11-01`, `11-02`, `11-03`, `11-04`, `11-05` — the
plan whose completion flips the test GREEN.

Run all tests for a specific plan with:

```bash
bash tests/phase-11/run.sh --expected-by 11-02
```

Tests without an `EXPECTED_BY` comment are ALWAYS counted (backward-compat
safety).  Invalid `--expected-by` values are rejected at flag-parse time.

### Tag Assignment (Plan 11-01 populates; reference only)

| Plan   | Tests |
|--------|-------|
| 11-01  | `test_migration_script_names.sh`, `test_no_llm_calls.sh`, `test_hashlib_not_sha256sum.sh` |
| 11-02  | `test_suggest_*`, `test_canonical_byte_equality.sh`, `test_op_hash_*`, `test_01_highconf_multisignal_autoapprove.sh` |
| 11-03  | `test_01_*` (except highconf_multisignal), `test_02_*`, `test_03_*`, `test_04_*`, `test_applied_log_*` |
| 11-04  | `test_review_typing_*`, `test_verify_*`, `test_end_to_end_happy_path.sh` |
| 11-05  | `test_agents_*`, `test_canonical_agents_*`, `test_docs_*` |

## EOL Policy

All fixture `.md` files use LF + UTF-8 without BOM (matching the prior-phase
fixture-seeding invariant: "All seeded .md fixtures use LF + UTF-8").  Pin
via `.gitattributes`:

```
tests/phase-11/fixtures/**/*.md text eol=lf
```

## Determinism Pins (env-var overrides)

Phase 11 fixtures reuse Phase 10's date pins and introduce one new pin for
candidate-file metadata headers:

| Env var | Value | Purpose |
|---------|-------|---------|
| `BROWNFIELD_FIXTURE_TODAY` | `2026-04-20` | Freezes wall-clock-derived `generated_at` timestamps in `.brownfield/*.yaml` metadata headers. |
| `BROWNFIELD_FIXTURE_CREATED_AT` | `2026-04-20` | Freezes `created_at` / `bootstrap_date` values in produced frontmatter. |
| `BROWNFIELD_TOOL_VERSION` | `1.1.0` | Pins the `tool_version:` field in candidate-file metadata headers (D-09). |

These are exported by each test file before invoking any Phase-11-produced
command, so fixture goldens are reproducible across runs.

## Regeneration Recipe

After Plans 11-02/03/04 ship intentional changes to `.brownfield/` output
shape, applied.log schema, or report section templates:

```bash
# 1. Suggest against every fixture input that produces goldens.
for f in small-vault-ambiguous large-vault-ambiguous pre-typed-vault \
         privacy-sensitive-vault already-tagged-vault \
         repo-root-shape-vault nested-bullets-vault; do
    BROWNFIELD_FIXTURE_TODAY=2026-04-20 \
    BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20 \
    BROWNFIELD_TOOL_VERSION=1.1.0 \
    bash bin/brownfield.sh suggest --root tests/phase-11/fixtures/$f/input/
    # ... (per-plan follow-up: 01/02/03/04 apply/advisory; review-typing; verify) ...
    # Copy produced .brownfield/ artifacts into expected/.
done

# 2. Verify the regeneration.
bash tests/phase-11/run.sh

# 3. Commit as a deliberate fixture regeneration.
git add tests/phase-11/fixtures/
git commit -m 'fixtures(phase-11): regenerate after <reason>'
```

## Pattern Lineage

This harness clones `tests/phase-10/` byte-for-byte with `10 -> 11` rename
and one addition: `assert_canonical_scripts_byte_identical` (see
`tests/phase-11/lib.sh`) — used by Plan 11-02's byte-copy invariant tests.
