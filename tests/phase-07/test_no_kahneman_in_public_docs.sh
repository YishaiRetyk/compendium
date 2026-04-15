#!/usr/bin/env bash
# Asserts no Kahneman terms appear in README.md, PRIVACY.md, or docs/.
# Scope is intentionally narrow (the human-authored stranger-facing surfaces
# owned by plan 07-04). Broader public-surface scanning is plan 07-05's
# check-neutrality.sh job.
#
# Exemption (applied by Rule 1 auto-fix, mirroring 07-03's test_agents_neutralized.sh):
# lines that reference the sanctioned `examples/kahneman/` directory path
# (required by README §"Repo shape" and by quickstart's pointer to the
# reference cluster) are excluded. Any other Kahneman-term appearance
# — in prose, YAML values, provenance markers, or raw name mentions
# outside the examples/ path context — still fails the test.
set -euo pipefail
PATTERN='kahneman|prospect.theory|loss.aversion|cognitive.biases|thinking.fast|system.?1.vs.system.?2|daniel.kahneman'
ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

# Raw hits from the 3 human-authored stranger-facing surfaces
RAW=$(grep -rIin -E "$PATTERN" README.md PRIVACY.md docs/ 2>/dev/null || true)

# Filter out lines that only reference the sanctioned `examples/kahneman/` path.
# A line is exempt iff every Kahneman-token occurrence on that line is part of
# the directory path `examples/kahneman` (case-insensitive). We approximate this
# by removing `examples/kahneman` substrings and re-scanning.
FILTERED=$(printf '%s\n' "$RAW" | awk -F: '
  NF >= 3 {
    # Reconstruct the content portion (columns 3..NF joined by ":")
    line = $3
    for (i=4; i<=NF; i++) line = line ":" $i
    # Strip sanctioned path references (case-insensitive replace)
    lower = tolower(line)
    gsub(/examples\/kahneman[a-z0-9._\/-]*/, "", lower)
    # If anything Kahneman-ish remains, it is a real leak
    if (match(lower, /kahneman|prospect[. ]theory|loss[. ]aversion|cognitive[. ]biases|thinking[. ]fast|system[. ]?1[. ]vs[. ]system[. ]?2|daniel[. ]kahneman/)) {
      print $0
    }
  }
')

if [ -n "$FILTERED" ]; then
  echo "FAIL: Kahneman terms found in stranger-facing docs (outside sanctioned examples/kahneman/ path references):"
  echo "$FILTERED"
  exit 1
fi
echo "PASS: README, PRIVACY, docs/ are Kahneman-free (outside sanctioned examples/kahneman/ path references)."
