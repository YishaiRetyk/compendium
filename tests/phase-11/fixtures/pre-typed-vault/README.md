# pre-typed-vault

Exercises D-20 core roster: 6 pages where 5 already have valid `type:`
frontmatter (a mix of `entity`/`concept`/`overview`) and 1 retains
`type: ""`.  Proves that `02-provenance-bootstrap`'s state-based prereq
check (majority-untyped threshold) does NOT fire when the vault is mostly
typed, so 02 continues without the soft WARN.

Expected outputs live in `expected/`; input is frozen — do not edit without
regenerating `expected/` (see tests/phase-11/fixtures/README.md).
