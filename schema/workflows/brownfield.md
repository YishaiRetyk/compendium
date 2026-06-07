# Brownfield Workflow

> Agent-authoritative reference for the brownfield vault onboarding workflow: scan, bootstrap, suggest, review-typing, verify, and the bootstrap_stage lifecycle gate.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

The brownfield workflow onboards existing Obsidian vaults into the wiki compiler
schema. It is the mechanical counterpart to ingest (`schema/workflows/ingest.md`) — where ingest creates
wiki pages from sources, brownfield transforms pre-existing vault pages into
schema-compliant form. The workflow operates through five subcommands plus the
`bootstrap_stage` lifecycle gate.

**Core principle:** *Review may be interactive and AI-guided; apply must always be deterministic.*

**Architectural boundary — apply class vs advisory class:**

| Subcommand / script | Class | What it does |
|---------------------|-------|--------------|
| `bin/brownfield.sh scan` | inventory | Dry-run classification; writes `.brownfield/REPORT.md`; zero vault mutation (Phase 10) |
| `bin/brownfield.sh bootstrap` | apply | Mechanical frontmatter injection with `bootstrap_stage: bootstrapped` (Phase 10) |
| `bin/brownfield.sh suggest` | generator | Byte-copies canonical migration scripts + generates candidate data files |
| `bin/brownfield.sh review-typing` | orchestrator | TTY small-batch cluster prompts OR large-batch AI-handoff via prompt.md |
| `bin/brownfield.sh verify [--promote]` | gate | Read-only lint wrapper + stale-artifact WARN; `--promote` flips `bootstrap_stage` on passing pages |
| `.brownfield/migrations/01-page-typing.sh` | apply | Page typing from paired manifests (candidates + decisions) |
| `.brownfield/migrations/02-provenance-bootstrap.sh` | apply | TL;DR + Key Facts top-level-bullet `[epistemic:: inferred]` tagging |
| `.brownfield/migrations/03-cross-link-inference.sh` | advisory | Cross-link candidates report |
| `.brownfield/migrations/04-privacy-review.sh` | advisory | Privacy-sensitive findings report |

**Root resolution (all four migration scripts):** each script derives its vault
root from its own filesystem location — specifically, the parent of the
`.brownfield/` directory containing the script. Migration scripts do NOT default
to `$(pwd)`; `BROWNFIELD_ROOT` is an explicit env-var override for advanced use.
This prevents cross-tree mutation when a script is invoked via absolute path
from an unrelated cwd.

## bootstrap_stage Lifecycle

```
(absent) ──[bin/brownfield.sh bootstrap --apply]──> bootstrapped
bootstrapped ──[bin/brownfield.sh verify --promote, passes gate]──> verified
bootstrapped ──[normal ingest via bin/ingest.sh]──> (stripped per BRWN-10)
verified     ──[no automatic downgrade]──> (manual edit only)
raw          ──[reserved for future import workflows]──> (no writer in v1.1)
```

## 11.5.1 suggest

```
Trigger:  User completes bootstrap and wants to migrate typing / provenance /
          cross-links / privacy.
Inputs:   Vault (current state) + bin/lib/brownfield_classify.py rule set.
Outputs:  .brownfield/migrations/*.sh (byte-copies with op_hash headers on lines
          2 and 3, shebang preserved on line 1),
          .brownfield/*.yaml candidate data files (each opening with a D-09
          metadata header including source_script_hash for stale-artifact
          detection by `verify`),
          REPORT.md advisory sections.
Commit:   N/A (.brownfield/ is gitignored per TMPL-04).
```

**Steps:**

1. Byte-copy canonical scripts from `schema/brownfield/migrations/*.sh` into
   `.brownfield/migrations/*.sh`. Prepend `# op_hash: sha256:<hex>` (line 2) +
   `# op_hash_scope: canonical-script-body + data-schema-version` (line 3),
   preserving the shebang on line 1.
2. Walk vault using `bin/lib/brownfield_walk.py walk_vault_respecting_ignore()` —
   the SAME helper used by `scan`. Honors `.brownfield-ignore` patterns.
3. Cluster classifications via `cluster_by_signals()`. Write
   `.brownfield/page-typing-candidates.yaml` with metadata header per D-09.
4. Write `.brownfield/page-typing-decisions.yaml` with every cluster
   `decision: pending`. High-confidence clusters auto-approve when EITHER the
   frontmatter signal is an explicit valid type enum OR 3+ non-frontmatter
   signals agree with the proposed label (D-03 verbatim).
5. Generate `.brownfield/provenance-bootstrap-report.yaml`,
   `cross-link-candidates.yaml`, `privacy-findings.yaml`.
6. Append `## Cross-link candidates` + `## Privacy review` sections to
   `.brownfield/REPORT.md`.

**Paired immutable inputs contract:** `page-typing-candidates.yaml` (cluster
membership — which pages belong to which cluster) and `page-typing-decisions.yaml`
(policy — which clusters are approved, rejected, or pending, with optional
per-page overrides) are consumed TOGETHER by `01-page-typing.sh --apply`.
`--apply` never re-classifies at apply time; candidates.yaml is read strictly
for the cluster-id → page-list lookup. Both files are required — deleting
either before apply causes a hard error.

**Abort conditions:**

- `schema/brownfield/migrations/` missing from repo.
- Vault root does not exist.

## 11.5.2 review-typing

```
Trigger:  User resolves pending clusters in page-typing-decisions.yaml.
Inputs:   .brownfield/page-typing-candidates.yaml (read)
          .brownfield/page-typing-decisions.yaml (read+write)
Outputs:  Updated decisions.yaml with resolved decisions; OR
          .brownfield/review-typing-prompt.md (large-batch AI handoff).
Commit:   N/A (.brownfield/ is gitignored).
```

**Steps:**

1. Count pending clusters in decisions.yaml.
2. **If pending count < N (default 20) AND stdout is a TTY:** TTY prompts
   cluster-by-cluster with primitives `approve all / reject all / inspect /
   override / skip`. Override labels are validated against the `type:` enum
   in `schema/reference/page-types.md` before being persisted to the decisions manifest.
3. **If pending count ≥ N OR non-TTY:** emit `.brownfield/review-typing-prompt.md`
   — directive template pointing at candidates + decisions YAMLs. Tell user to
   open in AI session (Claude Code, Codex, etc.) and edit the decisions manifest.
4. On stdin EOF (e.g., piped `</dev/null`): write back any decisions made so
   far and exit cleanly. Never loop indefinitely.
5. Write decisions.yaml with ruamel.yaml round-trip (preserves user comments).

The CLI never calls an LLM. The AI-handoff template operates on the file
artifact from outside the CLI; the user runs a deterministic apply script afterward.

**Abort conditions:**

- `.brownfield/page-typing-decisions.yaml` not found → run the suggest subcommand first.
- All clusters already resolved → report cleanly and exit 0.

## 11.5.3 verify [--promote]

```
Trigger:  User checks vault passes lint after migration scripts have run.
Inputs:   Vault + `.brownfield/page-typing-decisions.yaml` (for Gate 5) +
          .brownfield/*.yaml metadata headers (for stale-artifact detection).
Outputs:  stdout summary of blockers + optional WARN on stale candidate
          artifacts; (with --promote) `bootstrap_stage` flips on eligible pages.
Commit:   N/A (frontmatter mutations via ruamel round-trip; user commits separately).
```

**Steps (read-only mode):**

1. For each `.brownfield/*.yaml` candidate file, compare its D-09
   `source_script_hash:` header against the current body-post-op_hash-strip
   sha256 of the corresponding `.brownfield/migrations/*.sh`. Emit a stderr
   WARN for each mismatch (`stale candidate artifact detected: <cand>; re-run
   `bin/brownfield.sh suggest` to refresh`).
2. Run `bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield`.
3. Print summary grouped by severity; list paths blocking promotion.
4. Exit 0 regardless of findings (stale WARN and lint findings are diagnostic,
   not gating).

**Steps (`--promote`):**

1. Run steps 1–3 above (stale-artifact WARN + lint).
2. Read `.brownfield/page-typing-decisions.yaml`; build pending-pages set.
3. Walk vault; for each `bootstrap_stage: bootstrapped` page, apply the 5-gate
   pass-list: (a) currently bootstrapped; (b) `type:` is a valid enum per `schema/reference/page-types.md`;
   (c) zero error-severity lint findings for the page; (d) type-specific
   required fields present (e.g., `path`, `content_hash`, `ingested_at`,
   `source_type` for `type: source`); (e) not in pending-pages set.
4. If all 5 gates pass: flip `bootstrap_stage: verified` via `write_roundtrip`.
5. Print summary: `N pages promoted; M pages blocked`.

Privacy is not checked here — `bin/check-privacy.sh` handles the public-paths
leak guard (see `schema/reference/privacy.md` and Phase 9).

**Abort conditions:**

- `bin/lint.sh` not found or exits with runtime error.
- No `bootstrap_stage: bootstrapped` pages found → nothing to verify.

## 11.5.4 applied.log per-script shapes

`.brownfield/applied.log` is append-only; one block per meaningful execution.
Apply-class (01, 02) append on `--apply` only (dry-run never appends); advisory-
class (03, 04) append on findings. The block shape is **per-script** — each
script's exact schema is documented verbatim in `schema/brownfield/migrations/README.md`
and summarized here as `applied.log block shapes`:

- **01-page-typing.sh (apply):** `inputs:` is a two-item list — hashed candidates.yaml + hashed decisions.yaml. `summary:` has `approved_clusters`, `overridden_pages`, `pending_pages_remaining`.
- **02-provenance-bootstrap.sh (apply):** `inputs:` is a one-item literal string `- (vault walk — no candidate inputs; 02 is direct-apply)` — 02 is direct-apply, no candidate manifest. `summary:` has `pages_with_eligible_bullets`, `pages_with_no_eligible_bullets`.
- **03-cross-link-inference.sh (advisory):** no `inputs:` field. `mutations: none` + `report_section: REPORT.md#cross-link-candidates`.
- **04-privacy-review.sh (advisory):** no `inputs:` field. `mutations: none` + `report_section: REPORT.md#privacy-review`.

All four share the invariant fields: `## <script> @ <UTC ISO>` header, `mode:`, `op_hash:`, `exit_code:`, `prereq_check:`, `summary:`. Field variance beyond these is intentional and documented (NOT drift).

See: `docs/reference/brownfield.md` for operator runbook, troubleshooting, and the
full lifecycle walkthrough.

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (brownfield workflow pointer to this file).
- `schema/brownfield/migrations/README.md` — canonical applied.log block shapes per script.
- `docs/reference/brownfield.md` — operator runbook and troubleshooting guide.
