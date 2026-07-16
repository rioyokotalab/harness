#!/bin/bash
set -euo pipefail

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'venv-readiness: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

root=$HOME/harness
scratch=${TMPDIR:-/tmp}
build=$(mktemp -d "$scratch/t214-venv-$host.XXXXXX")
cleanup=$root/tests/guarded-test-cleanup.sh

finish() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$build" ]; then
        "$cleanup" "$HOME/.local/bin/harness" "$scratch" "$build" "$scratch" \
            >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

umask 077
actual_arch=$(uname -m)
case $host in ri|al) expected_arch=aarch64 ;; *) expected_arch=x86_64 ;; esac
[ "$actual_arch" = "$expected_arch" ] || {
    printf 'FAIL host=%s gate=venv-readiness-v1 reason=architecture\n' "$host"
    exit 2
}
uv=$(command -v uv || true)
if [ -z "$uv" ] && [ -x "$HOME/.local/bin/uv" ]; then
    uv=$HOME/.local/bin/uv
fi
if [ -z "$uv" ]; then
    printf 'FAIL host=%s gate=venv-readiness-v1 reason=uv-absent\n' "$host"
    exit 2
fi
if [ -x "$HOME/.local/bin/python3.12" ]; then
    python=$HOME/.local/bin/python3.12
else
    python=$(command -v python3 || true)
fi
[ -n "$python" ] || {
    printf 'FAIL host=%s gate=venv-readiness-v1 reason=python-absent\n' "$host"
    exit 2
}
printf 'UV %s\n' "$("$uv" --version)"
printf 'BASE_PYTHON %s\n' "$("$python" --version)"
UV_CACHE_DIR=$build/uv-cache
UV_OFFLINE=1
UV_PYTHON_DOWNLOADS=never
export UV_CACHE_DIR UV_OFFLINE UV_PYTHON_DOWNLOADS
if ! "$uv" --offline --no-python-downloads venv --no-project --python "$python" \
    "$build/venv" >"$build/uv.out" 2>&1; then
    printf 'FAIL host=%s gate=venv-readiness-v1 reason=offline-create\n' "$host"
    exit 2
fi
[ -x "$build/venv/bin/python" ] || {
    printf 'FAIL host=%s gate=venv-readiness-v1 reason=python-entrypoint\n' "$host"
    exit 2
}
"$build/venv/bin/python" -I -c \
    'import site,sys; assert sys.prefix != sys.base_prefix; assert site.ENABLE_USER_SITE is False'
"$build/venv/bin/python" -I "$root/tests/smoke/python.py" >/dev/null
printf 'VENV_PYTHON %s\n' "$("$build/venv/bin/python" --version)"
printf 'PASS host=%s gate=venv-readiness-v1 arch=%s offline=1 downloads=disabled cleanup=guarded\n' \
    "$host" "$actual_arch"
