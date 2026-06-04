---
phase: 16
slug: reference-extraction
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a documentation-extraction phase: the validation mechanism is the
> existing CI/gate suite + content-preservation checks, not a unit-test framework.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash scripts + existing CI gates (no unit-test framework for this phase) |
| **Config file** | `.github/workflows/lint.yml` (existing) + `tests/phase-07/`, `tests/phase-08/` |
| **Quick run command** | `bash bin/sync-claude.sh --check && bash bin/check-neutrality.sh` |
| **Full suite command** | `bash bin/lint.sh --ci && bash bin/check-privacy.sh && bash bin/check-neutrality.sh && bash bin/init-wizard.sh --dry-run` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every section-extraction commit:** Run `bash bin/sync-claude.sh --check && bash bin/check-neutrality.sh`
- **After every plan wave:** Run the full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green + every routing-stub target resolves to an existing file
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| W0 setup | — | 0 | REF-01..10 | T-16-01 | `schema` neutrality-scanned | automated | `grep -n 'schema' bin/check-neutrality.sh` (PUBLIC_PATHS) | ✅ | ⬜ pending |
| §4 extract | — | 1 | REF-01 | — | content preserved | automated | `test -f schema/reference/page-types.md && grep -ci "section order" schema/reference/page-types.md` | ❌ W0 | ⬜ pending |
| §5 extract | — | 1 | REF-02 | — | content preserved | automated | `test -f schema/reference/frontmatter.md` | ❌ W0 | ⬜ pending |
| §6 split | — | 1 | REF-03 | — | consumer-split correct | automated | `test -f schema/reference/provenance.md && grep -c "Decay Period" schema/workflows/lint.md` | ❌ W0 | ⬜ pending |
| §7 dissolve | — | 1 | REF-04 | — | §7 header gone from core | automated | `! grep -q "^## 7\. Progressive Disclosure" CLAUDE.md` | ❌ W0 | ⬜ pending |
| §8 extract | — | 1 | REF-05 | — | uniform-piped-link truth verbatim | automated | `grep -q "filename/path ONLY" schema/reference/wikilinks.md` | ❌ W0 | ⬜ pending |
| §13 extract | — | 1 | REF-06 | T-16-02 | privacy form preserved | automated | `test -f schema/reference/privacy.md` | ❌ W0 | ⬜ pending |
| §14/§15 extract | — | 1 | REF-07 | — | docs siblings created | automated | `test -f docs/reference/scaling.md && test -f docs/reference/tooling.md` | ❌ W0 | ⬜ pending |
| §16 delete | — | 1 | REF-07 | — | appendices removed | automated | `! grep -q "^## 16\. Appendices" CLAUDE.md` | ❌ W0 | ⬜ pending |
| routing table | — | 2 | REF-08 | — | IMPORTANT: table + all targets resolve | automated | routing-stub-target resolution script (every path `test -f`) | ❌ W0 | ⬜ pending |
| byte-equality | — | 2 | REF-09 | — | AGENTS≡CLAUDE + template mirror | automated | `bash bin/sync-claude.sh --check` | ✅ | ⬜ pending |
| REF-10 DR | — | 2 | REF-10 | — | decision record written | automated | `ls wiki-cloud/decisions/dr-*-reference-extraction*.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add `schema` to `PUBLIC_PATHS` in `bin/check-neutrality.sh` (~line 94) **before** the first extraction commit — otherwise `schema/reference/*.md` files escape the neutrality scan (critical gap surfaced by research).
- [ ] No new test files needed — this phase uses existing CI infrastructure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Extracted leaf content == original §-content minus stub (no silent drop) | REF-01..06 | Semantic equivalence not fully grep-checkable | For each section, grep the first + last distinctive sentence of the original §-range in the corresponding leaf file; confirm both present. Diff line counts pre/post. |
| Template stub mirrors core stub at the same logical position | REF-09 | `schema/AGENTS.template.md` has `{{placeholder}}` lines → not byte-identical to CLAUDE.md | Visually diff each stub block between CLAUDE.md and AGENTS.template.md |
| Routing table rows are genuinely most-navigable (operation × topic) | REF-08 | Dispatch quality is a judgment call | Spot-check: given only AGENTS.md, can the table route to each reference file in one hop? |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify command or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the `check-neutrality.sh` PUBLIC_PATHS gap
- [ ] Full suite green + routing-stub-target resolution passes
- [ ] Content-preservation manual checks complete for every extracted section
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
