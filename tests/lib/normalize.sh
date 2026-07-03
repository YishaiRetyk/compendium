# tests/lib/normalize.sh — FROZEN shared seam (D-08). Reads stdin, writes normalized stdout.
# Redact ONLY time-bearing (T..:..:..) wall-clock timestamps + tmp/fixture paths.
# Contractual values (frontmatter created/updated bare dates, log dates, staleness dates, IDs, hashes)
# are DETERMINISTIC and must NOT be masked — masking them would hide a wrong Python value (false parity).
# A tool emitting a genuinely non-deterministic bare date/hash on a happy path is handled by that
# tool's characterization test (Plan 04) with a CASE-SPECIFIC normalizer extension or a frozen `now`
# — never by widening this shared normalizer.
normalize() {
    sed -E \
      -e 's#/tmp/[A-Za-z0-9._-]+#<TMP>#g' \
      -e 's#phase[0-9]+(\.[0-9]+)?-fixture-[A-Za-z0-9]+#<FIXTURE>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?#<TS>#g'
    # DELIBERATELY ABSENT: bare-date redaction, SHA1/short-hex redaction.
    # CAUTION: do NOT reorder output — lint --ci --format json within-severity order is the locked
    # json-to-annotations.py contract.
}
export -f normalize
