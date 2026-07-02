---
id: dr-2026-07-03-external-source-drift
title: "External Source Drift: Surface, Don't Mark (Opt-in --network Lint Checks)"
type: decision
status: active
summary: "Records that external source drift detection ships as opt-in, review-only
  lint --network checks in the pre-plumbed drift-external subcategory — repository
  HEAD-vs-commit_sha, URL reachability with videos excluded, citation-registry
  link-rot ratios — and that the original backlog sketch's automatic stale-marking
  was consciously narrowed to surfacing only: claims cite the immutable snapshot;
  currency is a human re-snapshot/annotate decision."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-07-03-external-source-drift
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# External Source Drift: Surface, Don't Mark (Opt-in --network Lint Checks)

## TL;DR

Phase 23 ships external source drift detection as **opt-in `bin/lint.sh --network` checks** inside the `drift-external` logical subcategory that Phase 9 pre-plumbed (`EXTERNAL: ` prefix, `--ci` default-skip). Three families: repository upstream HEAD vs `commit_sha` (`git ls-remote`, no clone), source-URL reachability (videos excluded — their convention already settled link-rot), and research-report citation-registry link-rot ratios. The stance is **surface, don't mark**: the original backlog sketch said drift should mark affected source summaries `stale`, and that was deliberately narrowed — nothing mutates, severity never exceeds warning, and the follow-up (re-snapshot as a NEW ingest vs annotate via UPDATE op) is a human decision.

## Decision

1. **Landing slot: lint `--network`, not a new script (D-01).** The `drift` category already owned external-state checks via the `EXTERNAL: ` prefix, and the CI contract already default-skipped `drift-external` — the slot was designed two milestones ago. Without the flag, lint performs zero network I/O: the no-mandatory-network-dependency non-goal holds by construction, not by policy.
2. **Three check families (D-02)** with fixed severities: drifted/unreachable repository → warning; dead URL → warning; moved-behind-redirects → info; registry rot ≥50% of a deterministic first-10 sample → warning, any dead → info; everything healthy → silence.
3. **Surface, don't mark (D-03) — the narrowing this DR exists to record.** Claims cite the **immutable ingested snapshot** and remain faithful to it no matter what happens upstream; external drift changes *currency*, not *faithfulness*. Auto-flipping `status`/`epistemic_status` would conflate the two and mutate pages from a diagnostic — exactly what the review-only audit precedent forbids. Follow-up guidance lives in `schema/workflows/lint.md`.
4. **Videos excluded (D-04)** per the video convention's link-rot stance: the committed transcript is the durable archive; a dead courtesy URL is not drift. Exclusion is by the sub-case marker (`source_type: transcript` + `channel`), documented, not accidental.
5. **Graceful degradation (D-05):** missing curl/git → one info; timeouts bounded; `GIT_TERMINAL_PROMPT=0`.

## Why

v1.3 shipped citation registries (the named trigger for backlog 999.5) and Phase 22 shipped `repo_url`/`commit_sha`/`default_branch` (the cleanest drift anchor in the system). The trigger case then arrived on its own: the Phase-22 validation ingest discovered the wiki's documented repository home was an archived redirect — live external drift, found manually, one phase before this detector. The first `--network` run over the live wiki (2026-07-03) confirmed the design's signal profile: the repository source verified **current** (upstream `next` HEAD equals the snapshot commit — a true negative), two URLs reported benign `moved` infos (a GitHub repo rename redirect; doi.org, which redirects by design), zero dead links, zero registry rot.

## Alternatives Considered

- **Auto-mark `stale` on drift (the 999.5 sketch):** rejected — conflates upstream currency with claim faithfulness; mutating pages from a network diagnostic breaks the review-only diagnostic contract the audit established.
- **A standalone `bin/drift-check.sh` (audit-style):** rejected — would duplicate lint's page inventory, findings/severity/report machinery, and CI contract when the `drift-external` slot already existed for exactly this.
- **Content-hash/ETag change detection for HTML URLs:** deferred (tracked as CCD) — dynamic pages make it noisy; reachability plus SHA comparison is the honest v1 signal.
- **Running the checks in default lint with a network timeout:** rejected — "no mandatory network dependency for core workflows" is a standing non-goal; opt-in flag keeps the default path pure.

## Consequences

- The `drift` category now has a documented external tier; `LINT_VERSION` 1.12.0.
- Repository sources get continuous (opt-in) currency monitoring against the fields Phase 22 defined; re-snapshot is the documented refresh path.
- Known benign-noise pattern: permanent redirectors (doi.org) always emit a `moved` info — acceptable at info severity; a skip-list is a candidate refinement if the noise grows.

## Affected Pages

- None mutated by design — the checks are review-only. (Consumes `wiki-cloud/sources/` frontmatter; writes findings only.)

## Sources

- `schema/workflows/lint.md` — External Source Drift section (authoritative operational spec).
- `.planning/phases/23-external-source-drift/23-CONTEXT.md` — D-01..D-07 design decisions.
