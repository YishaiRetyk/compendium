# large-vault-ambiguous

Exercises D-20 core roster: large vault (≥25 pages, ≥20 distinct classifier-
signal tuples) for the AI-handoff large-batch path of `review-typing`
(cluster count at or above the N=20 threshold per RESEARCH Q3, triggering
emission of `.brownfield/review-typing-prompt.md` for out-of-band AI
execution).

Pages are terse by design (one TL;DR bullet each): the fixture's purpose is
**signal diversity** (varied filename conventions, H1 shapes, inbound-link
densities, section presences) not content depth.  This keeps the fixture
small on disk while ensuring the classifier produces many distinct clusters.

Expected outputs live in `expected/`; input is frozen — do not edit without
regenerating `expected/` (see tests/phase-11/fixtures/README.md).
