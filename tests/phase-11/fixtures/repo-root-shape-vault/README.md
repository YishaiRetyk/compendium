# repo-root-shape-vault

Exercises **REVIEWS.md item 3** (suggest scan scope). Mimics a real repo
root with top-level `docs/`, `schema/`, `examples/`, `AGENTS.md`,
`CLAUDE.md`, `README.md`, and `.github/` surfaces, PLUS a single real
wiki target page (`wiki/concepts/foo.md`).  Ships with a
`.brownfield-ignore` listing the canonical control-plane exclusions.

The test `test_suggest_respects_brownfield_ignore.sh` asserts that the ONLY
file appearing in `page-typing-candidates.yaml` is `wiki/concepts/foo.md` —
NO docs/, schema/, examples/, AGENTS.md, etc.  Locks Plan 11-02's
contract that suggest MUST reuse Phase 10's `.brownfield-ignore` parsing
(no fork of the walker logic).

Expected outputs live in `expected/`; input is frozen — do not edit without
regenerating `expected/` (see tests/phase-11/fixtures/README.md).
