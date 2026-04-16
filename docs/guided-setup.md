# Guided Setup (Wizard Track)

Run `bin/init-wizard.sh` and answer 6 prompts; the wizard writes 5 files to repo root.

## Quickstart

```bash
bash bin/init-wizard.sh
```

The wizard runs pre-flight (bash >= 4, git, python3) and then prompts you in this order:

1. **Maintainer name** — recorded in `.wizard-answers.yaml` and the initial decision record
2. **Primary domain** — substituted into `{{PRIMARY_DOMAIN}}` (validated `^[a-z0-9-]+$`)
3. **LLM agent** — `claude-code | codex | other`; controls `{{AGENT_FILENAME}}` self-reference
4. **Default privacy tier** — `local_only | cloud_safe`; substituted into `{{DEFAULT_PRIVACY}}`
5. **Decay profile** — `software | science | biography | personal-goals | default`
6. **Obsidian browsing** — y/n; recorded for future tooling, does not alter AGENTS.md

## Modes

- `bash bin/init-wizard.sh` — interactive, mutates repo
- `bash bin/init-wizard.sh --dry-run` — preview-only, prints unified diff per file
- `bash bin/init-wizard.sh --answers-file path/to/answers.yaml` — non-interactive (CI / replay)

## What gets written

5 files at repo root: `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-<TODAY>-initial-setup.md`, `wiki/index.md` (appended).

## Re-run / upgrade

The wizard refuses to re-run on an initialized repo (presence of `.wizard-answers.yaml`). To start fresh: `rm .wizard-answers.yaml AGENTS.md && bash bin/init-wizard.sh`. Upgrade flow planned for v1.2.

See [manual-setup.md](manual-setup.md) for the hand-edit equivalent.

## Prerequisites

See [reference/setup-prerequisites.md](reference/setup-prerequisites.md) for bash/git/python3 install instructions across macOS / Debian / Ubuntu / Arch / WSL.
