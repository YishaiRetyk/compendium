#!/usr/bin/env bash
# bin/install-hooks.sh -- wire .githooks/ as the repo hooks dir.
set -euo pipefail
git config core.hooksPath .githooks
echo "Hooks installed: core.hooksPath=.githooks"
echo "Verify: git config core.hooksPath"
