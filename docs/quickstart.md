# Quickstart

**Goal:** From fresh clone to first ingested page in five minutes.

## 0. Prerequisites

You need `bash >= 4`, `git`, and `python3`. See [reference/setup-prerequisites.md](reference/setup-prerequisites.md) for platform-specific install instructions (macOS, Debian/Ubuntu, Arch, Fedora, WSL, Windows).

## 1. Fork the template

Click "Use this template" on the <org>/<repo> GitHub page.

## 2. Run the setup wizard

```bash
bash bin/init-wizard.sh
```

The wizard prompts you for 6 inputs (maintainer name, primary domain, LLM agent, privacy tier, decay profile, Obsidian y/n) and writes 5 files to your repo root: `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-<TODAY>-initial-setup.md`, and an append to `wiki/index.md`. See [guided-setup.md](guided-setup.md) for the full prompt walkthrough.

If you prefer to hand-edit, see [manual-setup.md](manual-setup.md) — it reaches a byte-identical end state without invoking the wizard.

## 3. Ingest your first source

```bash
bash bin/ingest.sh <path-to-source>
```

`bin/ingest.sh` (Phase 3) drops the source file into `sources/YYYY/YYYY-MM/` and prepares the bookkeeping that the LLM agent then drives through the ingest workflow (AGENTS.md §11.1). Output is a source summary page under `wiki/sources/` plus updated entity/concept/overview pages with claim-level provenance.

## 4. Open in Obsidian

Open the repo as an Obsidian vault. Your compiled wiki lives under `wiki/`. The `examples/kahneman/` cluster (hidden from Obsidian by default via `.obsidianignore`) is a reference example you can browse for shape.

## Reference material

- [AGENTS.md](../AGENTS.md) — canonical agent spec
- [docs/reference/setup-prerequisites.md](reference/setup-prerequisites.md) — platform install matrix
- [docs/reference/schema-tour.md](reference/schema-tour.md) — schema walkthrough (Phase 12)
- [docs/reference/privacy-model.md](reference/privacy-model.md) — privacy tiers (Phase 12)
