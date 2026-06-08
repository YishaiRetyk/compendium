# Canonical Migration Scripts

Canonical migration scripts for `bin/brownfield.sh suggest`.

`bin/brownfield.sh suggest` byte-copies each of these scripts into a per-run
`.brownfield/migrations/` directory inside the target vault, prepending an
`op_hash` metadata header so the copied script is self-describing.  Users
run the copied scripts (never these canonical files) to apply the
migration.

## The Four Scripts

| Script                          | Class          | Purpose |
|---------------------------------|----------------|---------|
| `01-page-typing.sh`             | apply          | Reads paired immutable inputs (`page-typing-decisions.yaml` + `page-typing-candidates.yaml`); mutates wiki page `type:` frontmatter deterministically. |
| `02-provenance-bootstrap.sh`    | apply (direct) | Walks the vault; marks eligible top-level bullets under `## TL;DR` and `## Key Facts` with `[epistemic:: inferred]`. |
| `03-cross-link-inference.sh`    | advisory-only  | Scans vault for exact-title + alias mentions; writes `cross-link-candidates.yaml` + REPORT.md section.  No `--apply` path. |
| `04-privacy-review.sh`          | advisory-only  | Scans vault for PII-like regex matches; classifies findings for review priority.  Never flips `privacy:`. |

## op_hash Header Convention

Canonical scripts ship **without** `# op_hash:` / `# op_hash_scope:`
headers.  `bin/brownfield.sh suggest` prepends the computed header to each
copied script at byte-copy time:

```
#!/usr/bin/env bash              <- line 1 (shebang preserved from canonical)
# op_hash: sha256:<64-hex>       <- line 2 (prepended by suggest)
# op_hash_scope: canonical-script-body + data-schema-version   <- line 3
# ...                             <- original lines 2..N continue below
```

This is enforced by the byte-equality CI contract:
`schema/brownfield/migrations/*.sh` body (post-op_hash-header-strip) MUST
match `.brownfield/migrations/*.sh` body (post-strip).  The test
`tests/phase-11/test_canonical_byte_equality.sh` and
`tests/phase-11/test_op_hash_header_shape.sh` assert the shape.

Rationale (RESEARCH Q2): if canonical scripts carried a baked-in `op_hash`,
the hash would be self-referential (computing the hash requires stripping
the hash itself).  Prepend-at-copy-time breaks the circularity and keeps
the canonical source deterministic.

## applied.log block shapes (per-script variance — documented, not drift)

Per REVIEWS.md item 10 contract decision (**DOCUMENTED PER-SCRIPT
VARIANCE**), each script's applied.log block has a locked shape.  All
blocks share the invariant header + fields:

```
## <script-name> @ <UTC ISO>
mode: apply | advisory
op_hash: sha256:<64-hex>
exit_code: <int>
prereq_check: pass | warn
summary:
- ...
```

Beyond those shared fields, each script's body is intentionally different.
Tests `test_applied_log_apply_schema.sh` and
`test_applied_log_advisory_schema.sh` assert the per-script contract, not a
unified schema.

### 01-page-typing.sh (apply-class, paired immutable inputs)

```
## 01-page-typing.sh @ 2026-04-19T14:22:31Z
mode: apply
op_hash: sha256:abc123...
exit_code: 0
prereq_check: pass
inputs:
- .brownfield/page-typing-candidates.yaml @ sha256:def456...
- .brownfield/page-typing-decisions.yaml @ sha256:789abc...
files_touched: 12
files_created: 0
files_updated: 12
files_skipped: 4
changes:
- wiki/concepts/foo.md | updated | type: "" -> concept
summary:
- approved_clusters: 3
- overridden_pages: 2
- pending_pages_remaining: 5
```

`inputs:` has EXACTLY 2 lines (candidates + decisions).  `summary:` has
`approved_clusters`, `overridden_pages`, `pending_pages_remaining`.

### 02-provenance-bootstrap.sh (apply-class, direct-apply — no candidate inputs)

```
## 02-provenance-bootstrap.sh @ <UTC ISO>
mode: apply
op_hash: sha256:...
exit_code: 0
prereq_check: pass | warn
inputs:
- (vault walk — no candidate inputs; 02 is direct-apply)
files_touched: <n>
files_created: 0
files_updated: <n>
files_skipped: <n>
changes:
- <path> | updated | tagged <n> bullets with [epistemic:: inferred]
summary:
- pages_with_eligible_bullets: <n>
- pages_with_no_eligible_bullets: <n>
```

`inputs:` has EXACTLY 1 literal line.  `prereq_check:` may be `warn`
(soft state-based WARN per D-12).

### 03-cross-link-inference.sh (advisory-only)

```
## 03-cross-link-inference.sh @ <UTC ISO>
mode: advisory
op_hash: sha256:...
exit_code: 0
prereq_check: pass
mutations: none
report_section: REPORT.md#cross-link-candidates
summary:
- candidates: <n>
- already_linked: <n>
```

No `files_touched` / `changes:` fields (not applicable).

### 04-privacy-review.sh (advisory-only)

```
## 04-privacy-review.sh @ 2026-04-19T14:31:02Z
mode: advisory
op_hash: sha256:...
exit_code: 0
prereq_check: pass
mutations: none
report_section: REPORT.md#privacy-review
summary:
- pages_scanned: 184
- findings: 17
- high_risk_findings: 3
```

No `files_touched` / `changes:` fields.

## See Also

- AGENTS.md §11.5 for the authoritative workflow contract (which ALSO
  documents these per-script shapes; populated by Plan 11-05).
- `docs/reference/brownfield.md` for the operator runbook.
- `tests/phase-11/fixtures/README.md` for fixture layout + regeneration.
