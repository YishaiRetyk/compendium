# 25-04 SUMMARY — wiki-ops port + retirements (MIG-05, MIG-06)

**Status:** Complete (2026-07-03)

## What shipped

- Six modules: `ingest.py`, `validate_op.py`, `search.py`, `requirements_sync.py`,
  `pdf_extract.py`, `repo_snapshot.py` (RB-1's tool #16) + six shim flips + six
  manifest appends.
- **External commands stay external** (the load-bearing parity rule): `date -u`
  subprocessed at the ingest TODAY/YEAR/MONTH sites and repo-snapshot RETRIEVED site
  (PATH date-shim goldens keep working on the py leg); git / pdfinfo / pdftoppm /
  curl / jq / sha256sum all subprocess with identical argv.
- **search.py ports the Phase-14 piped-index bug FAITHFULLY** (keyword/query modes;
  goldens pin the broken output; fix stays todo
  `2026-07-03-search-keyword-broken-on-piped-index`).
- MIG-06 retirements: `bin/migrate-privacy-dirs.sh` DELETED (spent Phase-15 one-off;
  zero references in tests/docs/schema/CI — census at plan time; history preserves
  it); `bin/install-hooks.sh` STAYS BASH (6-line git config, hot path). Both recorded
  here + in the CUT-01 DR.
- TEST-06: `tests/test_wiki_ops_unit.py` (31 tests — requirements/VERIFICATION
  parsing + drift math, validate-op precondition cores, search index parsing incl.
  the pinned `id|Title` bug, snapshot license/language heuristics).
- Port-agent self-verification: 150+ four-channel cases; ALL applicable committed
  goldens byte-matched (validate-op ×10, search ×9 incl. the pinned exit-1-empty
  piped-index freezes, requirements-sync ×3 under C collation, ingest mutating
  scaffold with the date-shim farm); phase-20 HTTP-stub parity (STUB-OCR-TEXT
  round-trip, env knobs, error keys); phase-22's five repo-snapshot invocations
  replicated byte-for-byte.

## Notes / findings

- **Empirical bash discovery (agent):** `inherit_errexit` is off — `set -e` does NOT
  propagate into `$(...)`, so ingest in a non-git dir exits 0 with contributor
  omitted; the phase-20 comment claiming it aborts is folklore. Replicated exactly.
- Pipeline tails done natively only where byte-equivalent (head -1, glob counts —
  incl. the bug-compat silent exit-2 when pdf-extract's PNG glob is empty).
- Python tracebacks on undecodable inputs differ from bash's `<stdin>` framing —
  filtered by `^FAIL` greps in every observable channel; no suite coverage.
- Non-ASCII query-word length uses byte length — matches bash under the seam's
  LC_ALL=C pin.
