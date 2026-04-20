# nested-bullets-vault

Exercises **REVIEWS.md item 5** (02 top-level-bullets-only enforcement).
TL;DR + Key Facts sections contain BOTH top-level bullets (column 0 `-`)
AND markdown-standard nested indented bullets (`  -` at col 2 and `    -`
at col 4).  Also includes a top-level bullet inside `## Detail` which must
NOT be tagged (D-05 section_scan restricts 02 to TL;DR + Key Facts only).

Expected behavior: after `02-provenance-bootstrap --apply`, ONLY the 4
top-level bullets in TL;DR + Key Facts (A, B, fact 1, fact 2) gain
` [epistemic:: inferred]`.  Nested bullets and Detail-section bullets
must be untouched.  The test `test_02_top_level_bullets_only.sh` asserts
this.  Locks Plan 11-03's regex tightening in `is_eligible_claim_bullet`
and `section_scan` — `BULLET_START_RE` must distinguish `^- ` (col 0) from
`^  - ` (indented).

Expected outputs live in `expected/`; input is frozen — do not edit without
regenerating `expected/` (see tests/phase-11/fixtures/README.md).
