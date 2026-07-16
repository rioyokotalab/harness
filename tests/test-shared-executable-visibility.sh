#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CHECK=$ROOT/tests/smoke/jobs/shared-executable-visibility.sh
BOUNDARY=$ROOT/tests/smoke/jobs
EXPECTED=$(sha256sum "$CHECK" | awk '{ print $1 }')
LINK=$(mktemp "${TMPDIR:-/tmp}/shared-executable-link.XXXXXX")
unlink -- "$LINK"
trap '[ ! -L "$LINK" ] || unlink -- "$LINK"' EXIT HUP INT TERM

sh -n "$CHECK"
[ "$("$CHECK" "$BOUNDARY" "$CHECK" "$EXPECTED")" = \
    "SHARED_EXECUTABLE sha256=$EXPECTED status=pass" ]
if "$CHECK" "$BOUNDARY" "$CHECK" 0000000000000000000000000000000000000000000000000000000000000000 \
    >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: incorrect executable digest accepted' >&2
    exit 1
fi
ln -s -- "$CHECK" "$LINK"
if "$CHECK" "${TMPDIR:-/tmp}" "$LINK" "$EXPECTED" >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: executable symlink accepted' >&2
    exit 1
fi
unlink -- "$LINK"
if "$CHECK" "$BOUNDARY" /bin/sh "$EXPECTED" >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: executable outside boundary accepted' >&2
    exit 1
fi
printf '%s\n' 'shared executable visibility tests: PASS'
