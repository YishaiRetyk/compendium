---
quick_id: 260703-m4f
slug: lint-mask-fence-edge-cases
completed: 2026-07-03
status: complete
commit: (see git log — lint(mask) commit, 2026-07-03)
---

# Summary — 260703-m4f lint mask fence edge-case hardening

**Delivered.** `mask_markdown`'s fence handling in `bin/lint.sh` replaced: the
paired-only `_FENCE_RE` regex (which required a closed ```` ``` … ``` ```` pair and
leaked everything otherwise) is now a line-based `_mask_fences` scanner implementing
the CommonMark closing rules — closer must be the same fence char, at least
opener-length, followed only by whitespace; an info-string "closer" does not close;
an unclosed fence masks through EOF. LINT_VERSION 1.10.0 → 1.10.1 (PATCH).

**Defects closed** (Phase 14 review, deferred at three milestone closes):

- **WR-02:** unclosed fence leaked into linkres/provenance/gap scans and was
  exposed to `--fix` content mutation. Now masked to EOF; T7 proves `--fix`
  leaves such files byte-identical.
- **WR-03:** a closing line with an info string (e.g. ` ```ruby `) defeated the
  close-match and leaked the rest of the block. Now handled per CommonMark (the
  line does not close; masking continues to a true closer or EOF). Bonus from the
  scanner: opener-length rule (T5) and char-match rule (T6) now correct too.

**Evidence:**

- `tests/phase-09/test_lint_mask_fences.sh` — 7/7 PASS (was RED at baseline: T1
  failed with a bare-link error from inside an unclosed fence).
- Phase-09 suite: 25/31 with the change vs 23/31 at the stashed baseline — the
  two gained are this test and the de-staled `test_lint_version.sh`; the 6
  remaining failures are pre-existing (stale §11.x section tests etc., unchanged).
- Live tree: `bin/lint.sh --dry-run --format json` produces **byte-identical
  findings** (78 = 78, empty symmetric diff) pre/post — hardening only.

**Also fixed:** `tests/phase-09/test_lint_version.sh` had gone permanently stale
(asserted `1.7.0` against a live `1.10.0`, failing at every suite run since v1.2 and
being re-confirmed as "pre-existing failure" at every phase close). It now reads
LINT_VERSION from `bin/lint.sh` (single source of truth) with a semver-shape guard so
it can never go stale again — and it still fails if `--version` output diverges.

**Deferred (unchanged):** todo IN-01 (redundant `/`-target check), IN-02 (CRLF files
bypass frontmatter masking — splice-safe, cosmetic), IN-03 (linkres skips
unparseable-frontmatter pages, deferring to the yaml check). The audit-claims.sh
`_resolve_para` fence *toggle* (any ```-prefixed line flips state) is a different,
lenient-by-design consumer (paragraph counting, not mutation-guarding) — out of scope.
