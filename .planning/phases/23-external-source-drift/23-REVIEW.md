---
phase: 23-external-source-drift
reviewed: 2026-07-03
depth: standard (single-reviewer line-by-line; the xhigh 10-angle fan-out ran hours earlier on Phase 22 and its lessons were applied here at authoring time)
findings: { critical: 0, warning: 0, info: 3 }
status: resolved
---

# Phase 23: Code Review Report (standard depth)

Line-by-line self-review of the 23-01/23-02 diff with the Phase-22 review lessons applied preemptively: no `grep -q` pipelines under pipefail in the tests (write-once-grep-file pattern), JSON handed to Python via files, runner missing-test=FAIL, fence semantics N/A (no new markdown parsing), curl/git invocations timeout-bounded and prompt-free, `continue` after the repository branch prevents double-reporting via the generic URL check, video-exclusion predicate matches the documented sub-case marker exactly.

## Info-tier observations (accepted, no change)

- **IN-01 — doi.org always reports `moved`:** permanent redirectors emit a standing info. Accepted at info severity; skip-list refinement noted in the DR if noise grows.
- **IN-02 — `_http_code` treats 403/5xx as reachable:** deliberate — a WAF-blocked or erroring host is not link-rot; only 404/410/dead-host assert death. Documented severity table in lint.md matches the code.
- **IN-03 — registry sampling is first-10, not random:** deterministic by design (stable across runs, honest "sampled" label in the finding message); randomization would churn findings run-to-run.
