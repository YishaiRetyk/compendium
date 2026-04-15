# Quickstart

**Goal:** From fresh clone to first ingested page in five minutes.

## 1. Fork the template

Click "Use this template" on the <org>/<repo> GitHub page.

## 2. Run the setup wizard

> Phase 8 — this section lands in v1.1 Phase 8. The wizard (`bin/init-wizard.sh`) will personalize `AGENTS.md` from your answers to ~6 prompts. See [guided-setup.md](guided-setup.md) once populated.

If you prefer to hand-edit, see [manual-setup.md](manual-setup.md) (also Phase 8).

## 3. Ingest your first source

> Phase 8 — this section lands in v1.1 Phase 8. `bin/ingest.sh` drives the LLM agent through a deterministic ingest workflow. Output is a source summary page + updated entity/concept/overview pages with claim-level provenance.

## 4. Open in Obsidian

Open the repo as an Obsidian vault. Your compiled wiki lives under `wiki/`. The `examples/kahneman/` cluster (hidden from Obsidian by default via `.obsidianignore`) is a reference example you can browse for shape.

## Reference material

- [AGENTS.md](../AGENTS.md) — canonical agent spec
- [docs/reference/schema-tour.md](reference/schema-tour.md) — schema walkthrough (Phase 12)
- [docs/reference/privacy-model.md](reference/privacy-model.md) — privacy tiers (Phase 12)
