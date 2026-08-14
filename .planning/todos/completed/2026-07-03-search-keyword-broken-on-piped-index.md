# search.sh keyword/--paths-only/--query silently broken on piped-wikilink indexes

**Surfaced:** 2026-07-03, Phase 24 Plan 04 characterization backfill (TEST-03) — the previously
untested search modes got goldens and the capture exposed a latent bug.

**Symptom:** `bin/search.sh <keyword>` (and `--paths-only`, `--query`) exits 1 with EMPTY
stdout/stderr on the real wiki. Verified live: `bash bin/search.sh gsd` → exit 1, no output.

**Mechanism:** the index-entry title extraction (`sed -E 's/.*\[\[([^]]+)\]\].*/\1/'`) keeps the
full `id|Title` inner text of a PIPED link; `resolve_page_path` slugifies that to
`<id>-<title-slug>` which never matches a page file; the fallback
`grep -rl "^title:.*$title" ... | head -1` finds nothing → grep exits 1 → under
`set -euo pipefail` the command substitution aborts the whole script. Since Phase 14 made ALL
index links piped (`[[id|Title]]`), every keyword/query search on a conforming index dies this way.
`--fulltext` is unaffected (greps page bodies directly).

**Frozen behavior:** `tests/goldens/search/{keyword,paths-only,query-mode}/` freeze the broken
exit-1/empty behavior on a piped index (characterization = freeze what IS);
`tests/goldens/search/*-bare-index/` cover the working result-formatting path via bare links.

**Fix (POST-v1.5 — behavior change, excluded by the parity bar):** strip the `|Title` display
segment before slugifying (take the target side of the pipe), and make the fallback grep
pipefail-safe (`|| true`). When fixed, re-freeze the three piped-index goldens (both impls —
the Python port must change in lockstep or after cutover).

## Resolution (2026-08-14, wayfinder ticket 24)

Fixed in `src/compendium/search.py` + `bin/search.sh`. The bash implementation was
already retired (Phase 26 / 26-02), so the "both impls in lockstep" caveat no longer
applies — there is one implementation.

Three defects were in the way of a working consult, not one:

1. **Alias parsing (this todo).** `_split_wikilink()` now takes the target side of the
   pipe as the resolution key; the frontmatter-title fallback uses the display side,
   which is the only side that can match `^title:`. `resolve_page_path()` no longer
   returns a grep exit status for the caller to `sys.exit()` on — an unresolved entry
   returns `""` and is reported.
2. **`decisions/` was missing from the resolver's directory list** — five indexed
   decision records were unreachable even with alias parsing fixed. The list is now
   `PAGE_TYPE_DIRS`, the six canonical subdirectories from `schema/AGENTS.template.md`.
3. **`bin/search.sh` pinned cwd to the repo root unconditionally** (commit `afc30f8`),
   which fixed C-8 callers invoking from an arbitrary directory but made every other
   vault unsearchable — it silently redirected the search and answered "No results
   found" with exit 0. Now: `COMPENDIUM_WIKI_ROOT`, else a wiki in the caller's cwd,
   else the repo root. This also restored two tests that were failing on `afc30f8`
   despite being pinned PASS in `tests/SUITE_MANIFEST.txt`
   (`phase-09/test_search_contributor`, `phase-24/test_search_modes_characterization`).

Also added per the ticket-06 addition: non-silent exits everywhere, and a
digest-visible consult-health record (`ok`/`fail`) written outside every sovereign
store. The three piped-index goldens were re-frozen to real results, and
`tests/phase-24/test_search_real_index_readonly.sh` now runs C-8 against the REAL
index read-only — the gap that let this bug live behind a green suite.
