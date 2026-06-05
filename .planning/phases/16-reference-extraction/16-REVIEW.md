---
phase: 16-reference-extraction
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - bin/check-neutrality.sh
  - bin/check-privacy.sh
  - bin/lint.sh
  - AGENTS.md
  - CLAUDE.md
  - schema/AGENTS.template.md
  - schema/fixtures/canonical-AGENTS.md
  - schema/reference/page-types.md
  - schema/reference/frontmatter.md
  - schema/reference/provenance.md
  - schema/reference/wikilinks.md
  - schema/reference/privacy.md
  - schema/workflows/lint.md
  - docs/reference/scaling.md
  - docs/reference/tooling.md
  - tests/phase-07/test_agents_neutralized.sh
  - tests/phase-07/test_agents_template.sh
  - tests/phase-07/test_agents_template_placeholders.sh
  - tests/phase-09.1/test_agents_section_16.sh
  - tests/phase-09.1/test_agents_section_4_residue.sh
  - tests/phase-09.1/test_template_parity.sh
  - tests/phase-10/test_agents_section_5_bootstrap_stage.sh
  - tests/phase-10/test_agents_template_parity_section_5.sh
  - wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-06-05
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

This is a documentation-refactoring phase: nine AGENTS.md sections (§4/§5/§6/§7/§8/§13/§14/§15/§16) were extracted into standalone leaf files, AGENTS.md became a routing stub, CLAUDE.md was kept byte-identical, and the three gate scripts gained `schema/` coverage plus a durable lint-report exemption.

The mechanical infrastructure is in good shape. I verified: AGENTS.md ≡ CLAUDE.md byte-identical; all 8 routing-stub targets exist on disk; the §6 split into `provenance.md` + `lint.md` preserves all 15 subsections (provenance content is byte-identical to the original when sorted); the decay table and staleness rules survived intact; both gate scanners run clean (rc=0); the new `schema/`-coverage basename-scan correctly catches a denylisted filename under `schema/reference/`; and the `neutrality_exempt: true` lint-report exemption demonstrably exempts denylisted terms in the report body. All 8 in-scope test scripts pass.

However, one BLOCKER was found: the phase deleted the `{{DEFAULT_PRIVACY}}` and `{{DECAY_PROFILE}}` wizard-placeholder-bearing content from the template **without relocating it anywhere**, silently breaking `bin/init-wizard.sh`'s personalization substitution and dropping two spec lines. The reconciled tests' own comments assert this content "moved to leaf files," but it did not — it is gone from the entire tree. Additionally, the §7 dissolution left a dangling "Section 7" cross-reference, and two of the reconciled test assertions were weakened to the point of being trivially-passing.

## Critical Issues

### CR-01: Wizard placeholders deleted, not relocated — breaks `init-wizard.sh` personalization and drops spec content

**File:** `schema/AGENTS.template.md` (deletions); `tests/phase-07/test_agents_template_placeholders.sh:31-45`; `tests/phase-07/test_agents_template.sh`

**Issue:** The original `schema/AGENTS.template.md` carried four wizard placeholders: `{{AGENT_FILENAME}}`, `{{PRIMARY_DOMAIN}}` (×2), `{{DEFAULT_PRIVACY}}`, `{{DECAY_PROFILE}}`. This phase removed `{{DEFAULT_PRIVACY}}` and `{{DECAY_PROFILE}}` along with their carrier lines:

- `privacy_default: {{DEFAULT_PRIVACY}}` (former §5 yaml block)
- ``The default staleness decay profile is `{{DECAY_PROFILE}}` ...`` (former §6 prose)

The reconciled test comments repeatedly claim this content "moved to leaf files" / "the leaf file is the new home" (e.g. `test_agents_template_placeholders.sh` header and the WARN branch at lines 38-44). **This is false.** Grepping the entire `schema/reference/`, `schema/workflows/`, `docs/reference/`, AGENTS.md, and the template finds neither placeholder nor either carrier line anywhere — the content was deleted outright, not extracted.

Two concrete consequences:

1. **Dead wizard substitution.** `bin/init-wizard.sh` (unchanged this phase) still executes `.replace("{{DEFAULT_PRIVACY}}", DEFAULT_PRIVACY)` and `.replace("{{DECAY_PROFILE}}", DECAY_PROFILE)` against the template body (lines 657-658). With the placeholders gone, both replacements are now silent no-ops: the user's chosen privacy tier and decay profile no longer appear anywhere in their rendered AGENTS.md. The wizard still *prompts* for these values and records them in its decision record, but the spec they produce no longer reflects them.
2. **Lost spec content.** The `privacy_default` recorded-preference line and the decay-profile sentence are simply gone from the rendered specification.

This was masked because the phase-07 placeholder tests were rewritten (see WR-01) to stop enforcing the exact placeholder set, so the regression passes CI.

**Fix:** Re-home the two placeholders and their carrier lines into the leaf files that now own that content, so the wizard can still substitute them:

```
# schema/reference/frontmatter.md (or privacy.md) — restore the carrier line
privacy_default: {{DEFAULT_PRIVACY}}     # Wizard-recorded default tier preference ...

# schema/workflows/lint.md — restore the decay-profile sentence
The default staleness decay profile is `{{DECAY_PROFILE}}` (set by the wizard ...).
```

Then update `bin/init-wizard.sh` to run its `.replace(...)` substitutions across the leaf files it renders (not only the template), OR — if the leaf files are intentionally NOT wizard-rendered — remove the dead `{{DEFAULT_PRIVACY}}`/`{{DECAY_PROFILE}}` substitution lines from `init-wizard.sh` and the corresponding wizard prompts, and accept the content loss as an explicit decision recorded in the DR. Either way, the test comments asserting the content "moved to leaf files" must be corrected, since they currently document behavior that did not happen.

## Warnings

### WR-01: `test_agents_template_placeholders.sh` gutted — exact-set assertion replaced by non-failing WARN; rogue placeholders no longer caught

**File:** `tests/phase-07/test_agents_template_placeholders.sh:31-45`

**Issue:** The original test enforced an EXACT match — `if [ "$FOUND" != "$APPROVED" ]; then ... exit 1`. Its stated invariant was: "the ONLY `{{...}}` tokens in the template are the approved wizard placeholders (D-08)." That is the load-bearing guarantee that no typo'd or rogue `{{FOO}}` placeholder slips into the wizard source (which would render literally into a user's spec).

The reconciled version replaces this with (a) a presence check for `{{AGENT_FILENAME}}` and `{{PRIMARY_DOMAIN}}`, and (b) a check that the two removed placeholders are absent — but (b) was deliberately downgraded to a non-failing `WARN` ("Not a hard failure"). The exact-set assertion is gone entirely. Result: a stray `{{PRIMRY_DOMAIN}}` typo, or any unapproved `{{...}}` token, now passes silently. This is exactly the failure mode the original test existed to catch.

**Fix:** Restore an exact-set assertion against the new approved set:
```bash
APPROVED=$(printf '%s\n' '{{AGENT_FILENAME}}' '{{PRIMARY_DOMAIN}}' | sort -u)
FOUND=$(grep -oE '\{\{[A-Z_]+\}\}' "$TEMPLATE" | sort -u || true)
[ "$FOUND" = "$APPROVED" ] || { echo "FAIL: placeholder set mismatch"; diff <(echo "$APPROVED") <(echo "$FOUND"); exit 1; }
```
(Resolve in tandem with CR-01 — if the two placeholders are re-homed to leaf files, the approved set stays at four and the original exact-set check can be retained against `$TEMPLATE` plus the leaf files.)

### WR-02: Dangling "Section 7" cross-reference after §7 dissolution

**File:** `AGENTS.md:947` (and identical line in `CLAUDE.md`)

**Issue:** Line 947 reads: "The LLM reads this FIRST when searching for information (per Section 3 and Section 7)." The reference-extraction DR (line 34/46) intentionally dissolved §7 ("§7 dissolves (no file)") — there is no §7 section, no §7 stub, and no §7 routing-table row anywhere in AGENTS.md. This is the only broken internal section pointer: every other "Section N" reference still resolves to a live stub that forwards the reader. An agent following "Section 7" finds nothing.

**Fix:** Drop the stale reference, retargeting to the surviving home of the progressive-disclosure rule:
```
... (per Section 3 LLM Navigation Rule). A `wiki-local/index.md` is created lazily ...
```

### WR-03: §4 type-name assertions are trivially-passing (common-word grep)

**File:** `tests/phase-09.1/test_agents_section_4_residue.sh:16-19`; `tests/phase-09.1/test_template_parity.sh:38-43`

**Issue:** The §4 dispatch-vocabulary check loops `for t in entity concept source comparison overview decision` and asserts `grep -qi "$t" "$A"`. The tokens `source`, `overview`, `concept`, `entity`, and `comparison` are extremely common words that appear all over AGENTS.md regardless of whether §4's roster is correct (e.g. "source summary", "overview page", "comparison table" appear in §9/§10/§11). These assertions cannot fail for any plausible mutation of §4 and therefore verify nothing about the §4 stub. `test_template_parity.sh` ASSERTION 4 has the same flaw (the compound regex always falls through to the bare `grep -qi "${t}"`).

**Fix:** Anchor the check to the §4 stub region and to the dispatch-vocabulary line specifically, e.g. extract §4 (awk from `## 4.` to `## 5.`) and assert all six bolded type names appear within that slice:
```bash
S4=$(awk '/^## 5\./{exit} /^## 4\./{f=1} f' "$A")
for t in entity concept source comparison overview decision; do
  echo "$S4" | grep -qiE "\*\*${t}\*\*|\`${t}\`" || { echo "FAIL: §4 stub missing type '$t'"; exit 1; }
done
```

### WR-04: `frontmatter.md` and other leaf files retain stale "Section 6"/"Section 5" internal references

**File:** `schema/reference/frontmatter.md:29,54`; `docs/reference/tooling.md:10,17`

**Issue:** Extracted leaf files carry forward inline references like "maps to the Section 6 decay table" (frontmatter.md:29,54) and "All frontmatter fields defined in Section 5 are queryable" (tooling.md:10). These "Section N" labels are AGENTS.md-relative and now point at bare stub sections rather than the content. The decay table is in fact in `schema/workflows/lint.md` and the frontmatter fields in `schema/reference/frontmatter.md` — a reader in the leaf file has no way to resolve "Section 6" to `lint.md`. Not incorrect behavior, but degraded navigability that undercuts the routing model the phase is establishing.

**Fix:** Replace AGENTS.md-relative "Section N" labels in leaf files with direct file pointers, e.g. "maps to the decay table in `schema/workflows/lint.md`" and "All frontmatter fields defined in `schema/reference/frontmatter.md`". (Lower urgency than WR-02 because these resolve to live stubs that forward; WR-02 resolves to nothing.)

## Info

### IN-01: `neutrality_exempt` page-level exemption does not cover the filename basename-scan

**File:** `bin/check-neutrality.sh:233-248`

**Issue:** The new basename/path-name scan (lines 233-240) runs BEFORE the `has_neutrality_exempt` content exemption (line 247). A page with `neutrality_exempt: true` would still be flagged if a denylisted term appeared in its *filename*. For the lint-report.md target this is harmless (clean filename), and arguably this is correct-by-design (a denylisted filename is a structural leak regardless of frontmatter). Flagging only so the asymmetry is intentional and documented: `neutrality_exempt` exempts content, not the path. The PATH_NAME_EXEMPT set is the only filename escape hatch. No change required unless a future exempt page needs a denylisted-token filename.

### IN-02: Pre-existing typo carried verbatim into `scaling.md`

**File:** `docs/reference/scaling.md:24`

**Issue:** `wiki/index-concepts.md` and `wiki/index-sources.md` should read `wiki-cloud/index-...`. This typo is copied verbatim from the original AGENTS.md §14 (not introduced this phase — extraction faithfully preserved it). Out of strict phase scope, but worth a one-line fix while the content is fresh.

**Fix:** `wiki-cloud/index-concepts.md`, `wiki-cloud/index-sources.md`.

---

_Reviewed: 2026-06-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
