#!/usr/bin/env python3
"""
Phase 12.1 calibration script — draws 20 lines proportionally stratified
across the 3 source clusters in .planning/backlog-neutrality-denylist-candidate.txt
with deterministic seed=42; prompts user keep/skip per line; writes decisions
to calibration-decisions.txt.

Per CONTEXT.md D-02: seed=42 is load-bearing for reproducibility.
Per CONTEXT.md D-03: prompt is binary keep/skip only; no free-text rationale.
"""
import random
import sys
from pathlib import Path

CANDIDATE = Path(".planning/backlog-neutrality-denylist-candidate.txt")
DECISIONS = Path(
    ".planning/phases/12.1-neut-08-personal-term-denylist-curation/"
    "calibration-decisions.txt"
)
SAMPLE_TOTAL = 20
SEED = 42


def parse_clusters(path: Path) -> "dict[str, list[str]]":
    clusters: dict[str, list[str]] = {}
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("# source:"):
            current = line[len("# source:"):].strip()
            clusters[current] = []
        elif current and line.strip() and not line.startswith("#"):
            clusters[current].append(line.strip())
    return clusters


def stratified_sample(
    clusters: "dict[str, list[str]]", total: int
) -> "list[tuple[str, str]]":
    """Proportional stratification: cluster_quota = round(total * cluster_size / grand_total)."""
    grand = sum(len(v) for v in clusters.values())
    out: list[tuple[str, str]] = []
    rng = random.Random(SEED)
    for source, terms in clusters.items():
        quota = max(1, round(total * len(terms) / grand)) if terms else 0
        quota = min(quota, len(terms))
        picks = rng.sample(terms, quota)
        out.extend((source, term) for term in picks)
    return out[:total]


def main() -> int:
    if not CANDIDATE.exists():
        print(f"ERROR: candidate file missing: {CANDIDATE}", file=sys.stderr)
        return 1
    clusters = parse_clusters(CANDIDATE)
    sample = stratified_sample(clusters, SAMPLE_TOTAL)
    DECISIONS.parent.mkdir(parents=True, exist_ok=True)
    with DECISIONS.open("w", encoding="utf-8") as fh:
        fh.write(f"# Phase 12.1 calibration decisions (seed={SEED}, n={len(sample)})\n")
        fh.write("# Format: <decision>\\t<term>\\t<source-cluster>\n")
        for source, term in sample:
            while True:
                resp = input(
                    f"[{source.split('/')[-1]}] {term!r}  keep/skip: "
                ).strip().lower()
                if resp in ("keep", "k", "y"):
                    fh.write(f"keep\t{term}\t{source}\n")
                    break
                if resp in ("skip", "s", "n"):
                    fh.write(f"skip\t{term}\t{source}\n")
                    break
    print(f"Wrote {len(sample)} decisions to {DECISIONS}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
