# privacy-sensitive-vault

Exercises D-20 core roster: 3 pages containing email-like, phone-like, and
SSN-like strings that `04-privacy-review`'s regex set must detect.  All
three pages ship with `privacy: local_only` already set — proving 04 is
advisory-only and NEVER flips the privacy field (per D-07 + BRWN-18 hard
contract).  All PII strings are obviously fake test data.

Expected outputs live in `expected/`; input is frozen — do not edit without
regenerating `expected/` (see tests/phase-11/fixtures/README.md).
