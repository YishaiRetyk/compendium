# tests/lib/normalize.sh — FROZEN shared seam (D-08; D-09 rebase 2026-07-03, see below).
# Reads stdin, writes normalized stdout.
# Redact ONLY time-bearing wall-clock timestamps + tmp/fixture paths + the executing
# checkout's own root (exec-root token — D-09 rebase).
# Contractual values (frontmatter created/updated bare dates, log dates, staleness dates, IDs, hashes)
# are DETERMINISTIC and must NOT be masked — masking them would hide a wrong Python value (false parity).
# A tool emitting a genuinely non-deterministic bare date/hash on a happy path is handled by that
# tool's characterization test (Plan 04) with a CASE-SPECIFIC normalizer extension or a frozen `now`
# — never by widening this shared normalizer.
#
# D-09 REBASE (2026-07-03, Phase 25 first live cross-run channel comparison):
#   1. `YYYY-MM-DD HH:MM:SS UTC` (space-separated run-stamp form, e.g. brownfield APPLIED.md)
#      joins the ISO `T`-form in the <TS> redaction — same time-bearing wall-clock class the
#      header has always sanctioned.
#   2. _NORM_EXEC_ROOTS (colon-separated absolute paths, exported by the seam at capture time)
#      are each redacted to ONE `<EXEC_ROOT>` token BEFORE the tmp patterns, so the oracle
#      worktree path, the staged-index materialization, and the live repo root all normalize
#      identically — a tool embedding its own location is not a behavioral difference.
normalize() {
    # REVIEW FIX (2026-07-03): mktemp honors $TMPDIR — on hosts where TMPDIR != /tmp (or is
    # nested under /tmp) fixture paths would escape the literal /tmp pattern and the two capture
    # legs could never byte-match. The current TMPDIR root is redacted too (sed-escaped).
    local _tmproot _tmproot_esc _root _root_esc
    _tmproot="${TMPDIR:-/tmp}"; _tmproot="${_tmproot%/}"
    _tmproot_esc="$(printf '%s' "$_tmproot" | sed -e 's/[][(){}.*^$+?|#\\/]/\\&/g')"
    local -a _sed_args=()
    # Exec-root unification FIRST (longest, most specific prefixes; see D-09 rebase note).
    if [ -n "${_NORM_EXEC_ROOTS:-}" ]; then
        # REVIEW FIX (2026-07-03): split on ':' WITHOUT glob expansion. An exec root
        # containing a shell metachar (a checkout path with '[' or '*') would otherwise be
        # pathname-expanded here and corrupt the <EXEC_ROOT> sed program → false parity
        # divergence. `read -a` under IFS=':' splits on colon and never globs.
        local _IFS_saved="$IFS" _root
        local -a _roots=()
        IFS=':' read -r -a _roots <<< "$_NORM_EXEC_ROOTS"
        IFS="$_IFS_saved"
        for _root in ${_roots[@]+"${_roots[@]}"}; do
            _root="${_root%/}"
            [ -n "$_root" ] && [ "$_root" != "/" ] || continue
            _root_esc="$(printf '%s' "$_root" | sed -e 's/[][(){}.*^$+?|#\\/]/\\&/g')"
            _sed_args+=(-e "s#${_root_esc}#<EXEC_ROOT>#g")
        done
    fi
    sed -E \
      ${_sed_args[@]+"${_sed_args[@]}"} \
      -e "s#${_tmproot_esc}/[A-Za-z0-9._-]+#<TMP>#g" \
      -e 's#/tmp/[A-Za-z0-9._-]+#<TMP>#g' \
      -e 's#phase[0-9]+(\.[0-9]+)?-fixture-[A-Za-z0-9]+#<FIXTURE>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?#<TS>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC#<TS>#g'
    # DELIBERATELY ABSENT: bare-date redaction, SHA1/short-hex redaction.
    # CAUTION: do NOT reorder output — lint --ci --format json within-severity order is the locked
    # json-to-annotations.py contract.
}
export -f normalize
