#!/bin/sh
set -eu

usage() {
    echo "Usage: guarded-test-cleanup HARNESS WITHIN TARGET STATE_DIR" >&2
    exit 2
}

[ "$#" -eq 4 ] || usage
HARNESS=$1
WITHIN=$2
TARGET=$3
STATE_DIR=$4
platform=$(uname -s)

canonical_path() {
    case "$platform" in
        Darwin) realpath "$1" ;;
        *) realpath -e -- "$1" ;;
    esac
}

path_owner() {
    case "$platform" in
        Darwin) stat -f '%u' "$1" ;;
        *) stat -c '%u' -- "$1" ;;
    esac
}

case "$HARNESS:$WITHIN:$TARGET:$STATE_DIR" in
    /*:/*:/*:/*) ;;
    *) usage ;;
esac
[ -x "$HARNESS" ] || { echo "cleanup harness is not executable: $HARNESS" >&2; exit 2; }
[ -d "$WITHIN" ] && [ ! -L "$WITHIN" ] || {
    echo "cleanup boundary is not a real directory: $WITHIN" >&2
    exit 2
}
[ -d "$TARGET" ] && [ ! -L "$TARGET" ] || {
    echo "cleanup target is not a real directory: $TARGET" >&2
    exit 2
}
[ -d "$STATE_DIR" ] && [ ! -L "$STATE_DIR" ] || {
    echo "cleanup state boundary is not a real directory: $STATE_DIR" >&2
    exit 2
}

WITHIN=$(canonical_path "$WITHIN")
TARGET=$(canonical_path "$TARGET")
STATE_DIR=$(canonical_path "$STATE_DIR")
prefix=$STATE_DIR/.guarded-test-cleanup.$$
manifest=$prefix.manifest
plan_output=$prefix.plan
umask 077

remove_exact_file() {
    path=$1
    [ -e "$path" ] || [ -L "$path" ] || return 0
    [ -f "$path" ] && [ ! -L "$path" ] || {
        echo "refusing non-regular cleanup state: $path" >&2
        return 1
    }
    [ "$(canonical_path "$path")" = "$path" ] || {
        echo "refusing non-canonical cleanup state: $path" >&2
        return 1
    }
    [ "$(path_owner "$path")" = "$(id -u)" ] || {
        echo "refusing cleanup state owned by another uid: $path" >&2
        return 1
    }
    unlink "$path"
}

cleanup_state() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    remove_exact_file "$plan_output" || cleanup_failed=1
    remove_exact_file "$manifest" || cleanup_failed=1
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        status=1
    fi
    exit "$status"
}

trap cleanup_state EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

[ ! -e "$manifest" ] && [ ! -L "$manifest" ] || {
    echo "cleanup manifest path already exists: $manifest" >&2
    exit 2
}
[ ! -e "$plan_output" ] && [ ! -L "$plan_output" ] || {
    echo "cleanup plan path already exists: $plan_output" >&2
    exit 2
}

"$HARNESS" guarded-delete plan --within "$WITHIN" \
    --manifest "$manifest" -- "$TARGET" >"$plan_output"
token=$(sed -n 's/^TOKEN sha256=//p' "$plan_output")
[ -n "$token" ] || { echo "cleanup plan emitted no token" >&2; exit 2; }
"$HARNESS" guarded-delete apply --manifest "$manifest" --token "$token"
[ ! -e "$TARGET" ] && [ ! -L "$TARGET" ] || {
    echo "cleanup target remains: $TARGET" >&2
    exit 2
}
echo "guarded test cleanup: VERIFIED target=$TARGET"
