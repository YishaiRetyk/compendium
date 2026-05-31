# Deferred Items — Phase 13

Items discovered during execution that are OUT OF SCOPE for the current plan
(not in the plan's `files_modified`, not caused by this plan's changes).

## 13-04

- **Pre-existing neutrality leak in `wiki/maintenance/lint-report.md`** (discovered during Task 1).
  `bash bin/check-neutrality.sh` exits 2 because the generated lint report at
  `wiki/maintenance/lint-report.md` lines 82–83 contains real vault terms
  (`kahneman`, `personal-decision-journal`) inside its `### Drift` section
  ("Raw source has no wiki source summary page" findings that echo real source paths).
  This failure is PRESENT ON HEAD (verified by stashing all 13-04 edits — exit 2 persists),
  so it is NOT introduced by this plan. Plan 13-04's own edits (AGENTS.md, CLAUDE.md,
  schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md) are verified
  byte-clean of every denylist term (0 hits in a scoped scan).
  Fix is out of scope here: the lint-report is a generated control-plane artifact and is
  not in this plan's `files_modified`. Likely correct remediation (a separate change):
  either add `neutrality_exempt: true` frontmatter to the report (the scanner's documented
  per-page exemption for control-plane/meta records) or regenerate the report with
  neutralized paths. Tracked for a follow-up neutrality/lint-hygiene change.
