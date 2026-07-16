#!/bin/sh
set -eu

[ "$#" -eq 3 ] || {
    printf '%s\n' 'shared-executable-visibility: boundary, executable, and digest required' >&2
    exit 2
}
boundary=$1
executable=$2
expected=$3
case $boundary:$executable in
    /*:/*) ;;
    *) printf '%s\n' 'shared-executable-visibility: absolute paths required' >&2; exit 2 ;;
esac
case $expected in
    ''|*[!0-9a-f]*) printf '%s\n' 'shared-executable-visibility: invalid digest' >&2; exit 2 ;;
esac
[ "${#expected}" -eq 64 ] || {
    printf '%s\n' 'shared-executable-visibility: invalid digest' >&2
    exit 2
}
[ -d "$boundary" ] && [ ! -L "$boundary" ] || {
    printf '%s\n' 'shared-executable-visibility: invalid boundary' >&2
    exit 2
}
[ -f "$executable" ] && [ ! -L "$executable" ] && [ -x "$executable" ] || {
    printf '%s\n' 'shared-executable-visibility: invalid executable' >&2
    exit 2
}
canonical_boundary=$(realpath -e -- "$boundary")
canonical_executable=$(realpath -e -- "$executable")
case $canonical_executable in
    "$canonical_boundary"/*) ;;
    *) printf '%s\n' 'shared-executable-visibility: executable outside boundary' >&2; exit 2 ;;
esac
actual=$(sha256sum "$executable" | awk '{ print $1 }')
[ "$actual" = "$expected" ] || {
    printf '%s\n' 'shared-executable-visibility: digest mismatch' >&2
    exit 2
}
printf 'SHARED_EXECUTABLE sha256=%s status=pass\n' "$actual"
