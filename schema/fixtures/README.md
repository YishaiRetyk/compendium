# schema/fixtures/ — Canonical Byte-Equality Fixtures

These files are the byte-frozen contract between the **wizard track** (`bin/init-wizard.sh`) and the **manual track** (`docs/manual-setup.md`). CI (`.github/workflows/setup-parity.yml`) enforces byte-equality between the wizard's render and `canonical-AGENTS.md`.

## Files

- **`canonical-answers.yaml`** — the 6-answer input set
- **`canonical-AGENTS.md`** — the byte-frozen expected render of `schema/AGENTS.template.md` with `canonical-answers.yaml` applied

## Why `default_privacy: cloud_safe` (not `local_only`)

The wizard's **default** for the privacy tier prompt is `local_only` (per D-11, matching the schema's conservative privacy posture). This fixture intentionally uses `cloud_safe` instead.

**Reason:** `bin/release.sh` contains a neutrality/privacy-leak regex that rejects any file shipped in the public release containing `^privacy:[[:space:]]*local_only`. Since `canonical-AGENTS.md` ships publicly (it is the template-repo fixture), rendering it with `local_only` would make the release script reject the repo's own fixture.

Keeping the fixture at `cloud_safe` lets the public template release without contortion while preserving the wizard's `local_only` default for end users' own private repos.

**This is a deliberate deviation from the wizard default.** Hand-editors following `docs/manual-setup.md` who want byte-parity with this fixture MUST use `cloud_safe`. Hand-editors personalizing for a private repo should substitute `local_only` and accept that their output will differ from this fixture (which is fine — their repo's CI is their own).

See also: `bin/release.sh` (the `^privacy:[[:space:]]*local_only` regex near the neutrality-check block).

## Regeneration Rule

Whenever `schema/AGENTS.template.md` changes, `canonical-AGENTS.md` MUST be regenerated so the fixture stays in sync with the template.

**Regeneration command (same render routine as the wizard):**

```bash
bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
git add schema/fixtures/canonical-AGENTS.md
git commit -m "fixtures: regenerate canonical-AGENTS.md after template change"
```

**Mechanical enforcement (CI):** If `schema/AGENTS.template.md` is modified in a commit without a matching regeneration of `schema/fixtures/canonical-AGENTS.md`, the `.github/workflows/setup-parity.yml` byte-equality job fails. This is the drift-prevention gate.

## EOL Pinning

`.gitattributes` pins both files to `eol=lf` to prevent CRLF drift on Windows checkouts. See RESEARCH.md Pitfall 2 (M-2 mitigation).
