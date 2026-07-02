---
phase: 22-repository-source-type
reviewed: 2026-07-03
depth: xhigh (10 finder angles + adversarial verification, subagent fan-out)
files_reviewed: 25 (commits 40c5299..c08718c)
findings:
  critical: 0
  warning: 15
  info: ~8 (deferred/no-change)
status: resolved
resolved_at: 2026-07-03
fixes_applied: 15
---

# Phase 22: Code Review Report

10 independent finder angles (5 correctness, reuse/simplification/efficiency, altitude, conventions) ran as parallel subagents over the full phase diff; most findings were empirically REPRODUCED by the finders before reporting. The headline: **the phase's own "10/10 locators resolve" verification was partially hollow** — resolution was checked as non-None, not as usable-passage — re-proving the v1.3 retrospective lesson (*verify the verification machinery*) on the very phase that cited it.

## Findings → Resolutions (all 15 fixed)

1. **`_resolve_sec`/`_resolve_ref` fence-blind (wrong-passage resolution)** — quoted `##` headings inside fenced excerpts matched as real sections/bibliographies; a claim could be verified against text the source merely QUOTES. → Shared `_fence_mask_lines` helper (CommonMark rules matching lint's `_mask_fences`: same-char closer ≥ opener length, info-string closers don't close, unclosed → EOF) now used by all four boundary-scanning resolvers. Fixture T12 guards the #sec: case.
2. **`_resolve_path` naive fence toggle** — 4-backtick nesting desynced on inner ``` lines; `~~~` untracked; odd parity before `## Excerpts` hid the whole registry. → Rewritten on `_fence_mask_lines`; fixture T4 covers nested + tilde variants.
3. **Hollow `#sec:readme` on live pages** — the generator embedded the README verbatim, whose own H1 terminated the `## README` slice at 9 chars; two live claims audited "resolved" with an unusable passage. → Generator now demotes embedded README H1s to comments (test T6); the live snapshot amended same-phase (logged UPDATE, hash recomputed): `#sec:readme` resolves to a 619-char passage containing the cited text.
4. **`_resolve_commit` accepted ANY 40-hex in the metadata** (never consulted the Commit-line contract) + fence-blind slice. → Prefix-match restricted to the `- Commit:` line; fence-aware; fixture T8 (foreign/parent sha → insufficient-locator).
5. **Counts claim unverifiable by construction** — "34 agents / 69 commands" anchored `#commit:` but the metadata passage carried no counts. → Tree-stats line added to `## Snapshot Metadata` (same logged amendment); convention doc now states: facts anchored `#commit:` must be written into the metadata section.
6. **Whole-file excerpt matched range requests** (containment bypass). → Whole-file entries satisfy path-only requests ONLY (T11); doc clarified.
7. **Single-line excerpt heading `### file:L<n>` unaddressable** (grammar asymmetry). → Entry grammar accepts `:L<n>` ≡ `:L<n>-L<n>` (T5); doc shows the form.
8. **Inverted range `L20-L10` resolved.** → Rejected (T10).
9. **LGPL/MPL misclassified as GPL** (order-dependent heuristic; reproduced against /usr/share/common-licenses). → MPL/LGPL/AGPL checked before the GPL phrase; ordering comment added.
10. **`--dest` clobbered curated `source.md` on re-run.** → Collision guard + `--force` (test T7).
11. **`PRIMARY_LANGUAGE` pipeline could abort the script** under `set -euo pipefail` (find error / SIGPIPE). → `|| true` guards inside the substitution; `[ -n ]` fallback now reachable.
12. **Test harness bugs in the resolver test** — `printf | grep -q` under pipefail (SIGPIPE false-FAIL) and findings-JSON spliced into a Python triple-quoted literal (backslash re-interpretation). → Write-once-grep-file pattern; JSON handed via file + `json.load` (the sibling test's pattern).
13. **`run.sh` SKIP-on-missing exits green** — a renamed test silently drops out. → Missing test file = FAIL.
14. **gsd.md unannotated 35+/50+ vs 34/69 conflict + "mechanics remain accurate" overclaim.** → Old bullet annotated counts-superseded; the Detail sentence scoped to core mechanics with the counts named as superseded point-in-time facts.
15. **Duplicate 2026-07-03 lint log entry** (tool-appended beside the hand-written one — a phantom second operation). → Duplicate removed; amendment logged.

Also fixed while in the area: `usage()` sed self-extraction replaced with the house heredoc pattern; lowercase-40-hex commit_sha stated explicitly in the convention (lint strict-lowercase ↔ resolver-case-insensitive disagreement resolved normatively); registry anchors at the LAST non-fenced `## Excerpts` (README-content hijack defense).

## Deferred / no-change (with reasons)

- **Per-claim registry re-scan memoization** (efficiency): immaterial at realistic scale (finder's own measurement: <10 ms for real snapshots).
- **Cross-phase run.sh aggregator dedup + tests lib reuse**: real drift risk but repo-wide refactor territory — a natural TEST-0x item for the staged v1.5 Python Migration (pytest replaces the aggregators wholesale).
- **Table-driven license map / find-extension list dedup**: cosmetic; heuristic is curator-reviewed output.
- **`resolve_locator` declarative longest-prefix dispatch**: the D-11 comment + T1 regression test carry the invariant for now; revisit at the v1.5 port (natural Python refactor).
- **Registry row's forward reference to external drift checks in lint.md**: becomes true when Phase 23 lands (same session); wording verified then.
- **Process note (conventions finder):** the reflect commit bundled a lint run + report refresh — logged here as a convention nit; lint runs get their own commit going forward.

## Verification of the fix pass

- tests/phase-22: 3/3 suites, now 12+7+4 cases (T3b superseded by the stronger T4/T12 family).
- tests/phase-13 (audit resolvers): 31/33 — identical to baseline (the 2 failures pre-exist).
- Live worklist over the amended source: every sampled repo passage substantive (`#sec:readme` 619 chars incl. the cited text; `#commit:` passage contains the tree stats).
- lint --dry-run 0 errors; sync-claude, neutrality, gen-skills all green.
