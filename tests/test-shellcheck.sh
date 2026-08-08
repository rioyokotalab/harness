#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if ! command -v shellcheck >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: ShellCheck is required for admitted shell validation' >&2
    exit 1
fi

set --
if [ "${HARNESS_VALIDATION_FULL:-1}" = 1 ] ||
    [ -z "${HARNESS_CHANGED_PATHS:-}" ]; then
    while IFS= read -r file; do
        set -- "$@" "$ROOT/$file"
    done <<EOF
$(git -C "$ROOT" grep -Il '^#!.*\(sh\|bash\)' -- . \
    ':(exclude)tests/fixtures/**')
EOF
else
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$ROOT/$file" ] && [ ! -L "$ROOT/$file" ] || continue
        IFS= read -r first <"$ROOT/$file" || first=
        case "$first" in '#!'*sh*) set -- "$@" "$ROOT/$file" ;; esac
    done <<EOF
${HARNESS_CHANGED_PATHS}
EOF
fi

[ "$#" -eq 0 ] || shellcheck --severity=warning "$@"

for file in "$@"; do
    case "${file#"$ROOT/"}" in
        tests/*) continue ;;
    esac
    if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
        "$file" >/dev/null; then
        printf 'FAIL: prohibited recursive deletion in %s\n' "${file#"$ROOT/"}" >&2
        exit 1
    fi
done

printf 'SHELL_POLICY status=pass files=%s\n' "$#"
