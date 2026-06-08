#!/usr/bin/env bash
# Tests for bin/release.sh dry-run default + email override + abort path.
# TMPL-11 plan 07-05 Task 3.
set -u

cd "$(dirname "$0")/../.."
ROOT="$(pwd)"
PASS=0
FAIL=0

ok() { echo "PASS $1"; PASS=$((PASS+1)); }
ng() { echo "FAIL $1: $2"; FAIL=$((FAIL+1)); }

# R1: dry-run default exit 0, markers present
OUT=$(bash bin/release.sh --remote dummy://test 2>&1)
RC=$?
if [ "$RC" -eq 0 ] \
   && echo "$OUT" | grep -q '(dry-run)' \
   && echo "$OUT" | grep -q 'INCLUDES:' \
   && echo "$OUT" | grep -q 'EXCLUDES:' \
   && echo "$OUT" | grep -q 'v1.1'; then
    ok R1_dryrun_default
else
    ng R1_dryrun_default "rc=$RC missing marker"
fi

# R2: missing --remote exits 1
bash bin/release.sh >/tmp/rel_r2.out 2>&1
RC=$?
if [ "$RC" -eq 1 ] && grep -qi 'remote' /tmp/rel_r2.out; then
    ok R2_missing_remote
else
    ng R2_missing_remote "rc=$RC"
fi

# R3: --dry-run explicit behaves like default
OUT=$(bash bin/release.sh --dry-run --remote dummy://test 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q '(dry-run)'; then
    ok R3_dryrun_explicit
else
    ng R3_dryrun_explicit "rc=$RC"
fi

# R4: --apply with n answer aborts
OUT=$(echo n | bash bin/release.sh --apply --remote dummy://test 2>&1)
RC=$?
if [ "$RC" -eq 0 ] && echo "$OUT" | grep -q 'Aborted'; then
    ok R4_apply_abort
else
    ng R4_apply_abort "rc=$RC"
fi

# R5: email override + default
OUT=$(RELEASE_EMAIL=custom@example.invalid bash bin/release.sh --remote dummy://test 2>&1)
if echo "$OUT" | grep -q 'custom@example.invalid'; then
    ok R5a_email_override
else
    ng R5a_email_override "override not printed"
fi

OUT=$(bash bin/release.sh --remote dummy://test 2>&1)
if echo "$OUT" | grep -q 'release@example.invalid'; then
    ok R5b_email_default
else
    ng R5b_email_default "default not printed"
fi

echo ""
echo "release_dryrun: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
