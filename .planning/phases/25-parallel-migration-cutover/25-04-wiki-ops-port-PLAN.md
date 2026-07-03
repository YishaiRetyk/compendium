---
phase: 25-parallel-migration-cutover
plan: 04
type: execute
wave: 1
depends_on: [01]
files_modified:
  - src/compendium/ingest.py
  - src/compendium/validate_op.py
  - src/compendium/search.py
  - src/compendium/requirements_sync.py
  - src/compendium/pdf_extract.py
  - src/compendium/repo_snapshot.py
  - bin/ingest.sh
  - bin/validate-op.sh
  - bin/search.sh
  - bin/requirements-sync.sh
  - bin/pdf-extract.sh
  - bin/repo-snapshot.sh
  - bin/migrate-privacy-dirs.sh (DELETED — MIG-06 retirement)
  - tests/ported.manifest
  - tests/test_wiki_ops_unit.py
autonomous: true
requirements: [MIG-05, MIG-06]
---

<objective>
Port the six wiki-operations tools — ingest (493), validate-op (392), search (338),
requirements-sync (272), pdf-extract (243), repo-snapshot (164; RB-1's tool #16) — and
execute the MIG-06 retirements: delete `bin/migrate-privacy-dirs.sh` (spent Phase-15
one-off, zero references in tests/docs/schema/CI — verified at plan time) and record
that `install-hooks.sh` deliberately stays bash (6-line git config, hot path). External
boundaries stay subprocess/HTTP: git (repo-snapshot, validate-op), poppler (pdf-extract),
Ollama HTTP endpoint (pdf-extract).
</objective>

<context>
- **search.sh carries the KNOWN BUG** (keyword/query modes broken on piped-index links
  since Phase 14; goldens pin the broken output). Port the bug FAITHFULLY — the fix is
  todo `2026-07-03-search-keyword-broken-on-piped-index`, post-migration.
- **validate-op** is invoked by `.claude/settings.local.json` permission entries and is
  the precondition gate for all structured ops (CLAUDE.md §9) — argv/exit/diagnostic
  parity is user-facing. 10 golden cases exist (validate_op ×10).
- **requirements-sync** parses REQUIREMENTS.md tables + VERIFICATION.md bare-`Complete`
  status lines (Phase-24 lesson: the parser's line-shape is strict); goldens ×5 exist
  (re-frozen under C collation — REQUIREMENTS.md uppercase sorts first; preserve ordering
  semantics exactly).
- **pdf-extract**: phase-20 test uses a local HTTP stub (OLLAMA_URL + PDF_EXTRACT_MODEL
  env knobs) asserting the POST to `/api/generate` — the Python port must honor both env
  knobs and the request/consume behavior. Ollama-absent → SKIP semantics preserved.
- **ingest**: strips frontmatter fields per schema §5 (`stripped by bin/ingest.sh` is
  doc-load-bearing text — phase-10 doc test); mutating golden exists (ingest case).
- **repo-snapshot**: pure bash + git; 5 behavioral invocations in tests/phase-22 incl.
  error paths + `--force` clobber guard.
- Retirement mechanics: `git rm bin/migrate-privacy-dirs.sh` (history preserves it; the
  frozen oracle worktree at 9905bf0 still contains it, so the bash leg is unaffected).
  No manifest entry for it (never in scope). Decision text lands in the CUT-01 DR;
  this plan's SUMMARY records the census proving zero references.
</context>

<tasks>
1. Baseline both legs (phase-09/13/15/20/22/23 touchpoints + goldens). Read all six
   scripts; per-tool contract table (modes, exits, output shapes).
2. Port in ascending size: repo_snapshot → pdf_extract → requirements_sync → search →
   validate_op → ingest. Verbatim usage/error text; heredoc Python lifted; bash
   pipelines translated with identical output ordering.
3. TEST-06: `tests/test_wiki_ops_unit.py` — requirements-table parsing, validate-op
   precondition checks, search index parsing (pinning the faithful bug at unit level
   with a comment pointing at the todo), snapshot manifest construction.
4. Flip 6 shims + 6 manifest appends; `git rm bin/migrate-privacy-dirs.sh`.
5. Three-leg parity; commit `feat(25): port wiki-ops cluster to python, retire
   migrate-privacy-dirs (MIG-05, MIG-06)`; SUMMARY.
</tasks>

<acceptance>
- All 6 tools byte-parity on their golden cases (validate-op ×10, search ×9, ingest,
  requirements-sync ×5) + suite invocations; three-leg parity 0/0/0; manifest match.
- pdf-extract stub test green on py leg (POSTs `/api/generate`, honors env knobs).
- search py leg reproduces the pinned broken keyword/query behavior byte-for-byte.
- `bin/migrate-privacy-dirs.sh` gone; full run-all green (proving zero test coupling);
  freeze guard clean.
</acceptance>
