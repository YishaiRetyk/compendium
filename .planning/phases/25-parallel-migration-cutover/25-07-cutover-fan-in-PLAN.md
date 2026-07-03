---
phase: 25-parallel-migration-cutover
plan: 07
type: execute
wave: 2
depends_on: [01, 02, 03, 04, 05, 06]
files_modified:
  - wiki-cloud/decisions/ (migration decision record — exact slug per reflect workflow)
  - wiki-cloud/index.md
  - wiki-cloud/log.md
  - docs/ + schema/ reference fixes (only if the census finds inaccuracies)
autonomous: true
requirements: [CUT-01]
---

<objective>
Wave-2 fan-in: certify the migration and document it. All 16 tools now run Python behind
their shims; this plan (1) authors the migration decision record via the reflect
workflow, (2) runs the full bin/*.sh reference census across schema/, docs/,
CLAUDE.md/AGENTS.md, and .claude/settings.local.json and fixes any drift, (3) holds
AGENTS.md ≡ CLAUDE.md byte-equality, and (4) runs the final full-green certification on
WIKI_IMPL=py.
</objective>

<context>
- The DR follows `schema/workflows/reflect.md` (decision-record authoring) and lands in
  `wiki-cloud/decisions/` with an index/log entry per `schema/reference/log-format.md`.
  Content: shim-and-swap rationale, common/ consolidation, two-layer test strategy,
  the MIG-06 retirements (migrate-privacy-dirs deleted — spent one-off; install-hooks
  stays bash — hot-path presence check), and the SHIMOUT/LIBSWAP deferrals.
- Reference census: every `bin/<tool>.sh` mention must be ACCURATE post-migration (the
  shims persist, so most references stay true by design — the census verifies rather
  than rewrites). Any doc naming `migrate-privacy-dirs.sh` (none found at plan time)
  or describing bash internals would be the drift to fix.
- Template-public surfaces (docs/, schema/, AGENTS.md/CLAUDE.md) use abstract
  placeholders — no real vault terms in any edit.
- This is a docs/wiki commit (`reflect(v1.5-migration): ...` for the DR per the commit
  conventions; census fixes fold in — one logical operation).
- Phase-completion ritual (verification doc, adversarial review, REQUIREMENTS flip,
  ROADMAP/STATE) follows AFTER this plan, outside it, as with Phase 24.
</context>

<tasks>
1. Census: grep all `bin/*.sh` references across schema/, docs/, AGENTS.md, CLAUDE.md,
   .github/, .claude/settings.local.json; table of hits with accurate/stale verdicts;
   fix stale ones (edit AGENTS.md → bin/sync-claude.sh to hold byte-equality).
2. Author the DR (reflect workflow; validate-op preconditions where applicable); update
   wiki-cloud/index.md + log.md per log-format.
3. Final certification: full three-leg parity run at the fan-in commit; `pytest` full
   run; `bash bin/check-common-freeze.sh` exit 0; CI-equivalent local runs of the six
   required checks' scripts where locally runnable.
4. Commit; SUMMARY with the certification transcript summary.
</tasks>

<acceptance>
- DR page exists, lint-clean, indexed + logged; AGENTS.md ≡ CLAUDE.md (cmp exits 0).
- Reference census table shows 100% accurate `bin/*.sh` references; zero mentions of the
  retired tool outside history/planning docs.
- Three-leg parity 0/0/0 with ALL 16 tools in ported.manifest; full pytest green;
  freeze guard clean. MIG-01..06 + CUT-01 demonstrably satisfiable for the verification
  doc.
</acceptance>
