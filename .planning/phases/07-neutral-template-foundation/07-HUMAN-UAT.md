---
status: partial
phase: 07-neutral-template-foundation
source: [07-VERIFICATION.md]
started: 2026-04-16T00:00:00Z
updated: 2026-04-16T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Real public template repo push
expected: bin/release.sh --apply run against the real public remote; resulting repo has is_template: true, branch protection with required 'neutrality' check, 'Use this template' button visible, and git rev-list --all --count == 1
result: [pending]

### 2. NEUT-08 personal-term denylist follow-up
expected: Hand-curated personal domain terms added to .neutrality-denylist.txt (currently only the Kahneman category ships); candidate material at .planning/backlog-neutrality-denylist-candidate.txt used as input for human review
result: [pending]

### 3. Subjective "tech-Obsidian-user voice" of README.md
expected: README.md reads as a welcoming pitch for a technical Obsidian user and links to docs/quickstart.md
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
