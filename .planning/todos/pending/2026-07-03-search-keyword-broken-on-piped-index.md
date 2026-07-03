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
