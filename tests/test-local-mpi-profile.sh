#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/local-mpi-profile-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        printf '%s\n' 'FAIL: guarded local MPI profile cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

home=$TEMP_DIR/home
mkdir -p "$home/harness" "$home/fake-mpi"
cp -R "$ROOT/shell" "$home/harness/"
cat >"$home/fake-mpi/mpicc" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 755 "$home/fake-mpi/mpicc"

module_log=$TEMP_DIR/module.log
profile_output=$(env -u HARNESS_INTERACTIVE_LOADED \
    -u HARNESS_REMOTE_SESSION_LOADED HOME="$home" PATH=/usr/bin:/bin \
    MPI_MODULE_LOG="$module_log" HARNESS_LOGICAL_HOST=local \
    bash --noprofile --norc -ic '
        module() {
            printf "%s\n" "$*" >>"$MPI_MODULE_LOG"
            if [ "$1" = load ]; then
                PATH=$HOME/fake-mpi:$PATH
                export PATH
            fi
        }
        . "$HOME/harness/shell/profile.sh"
        command -v mpicc
    ' 2>/dev/null)
[ "$profile_output" = "$home/fake-mpi/mpicc" ] ||
    fail 'interactive local profile did not expose mpicc'
[ "$(sed -n '1p' "$module_log")" = \
    'unload openmpi/5.0-cuda-12.8' ] || fail 'unexpected module unload route'
[ "$(sed -n '2p' "$module_log")" = \
    'load openmpi/5.0-cuda-12.8' ] || fail 'unexpected module load route'
[ "$(wc -l <"$module_log")" -eq 2 ] || fail 'unexpected module command count'

: >"$module_log"
HOME="$home" PATH="$home/fake-mpi:/usr/bin:/bin" \
    MPI_MODULE_LOG="$module_log" bash --noprofile --norc -c '
        module() { printf "%s\n" "$*" >>"$MPI_MODULE_LOG"; }
        . "$HOME/harness/shell/hosts/local.sh"
    '
[ ! -s "$module_log" ] || fail 'existing MPI selection was replaced'

: >"$module_log"
HOME="$home" PATH=/usr/bin:/bin MPI_MODULE_LOG="$module_log" \
    HARNESS_LOGICAL_HOST=local bash --noprofile --norc -c '
        module() { printf "%s\n" "$*" >>"$MPI_MODULE_LOG"; }
        . "$HOME/harness/shell/profile.sh"
    '
[ ! -s "$module_log" ] || fail 'non-interactive profile loaded an MPI module'

warning=$(HOME="$home" PATH=/usr/bin:/bin bash --noprofile --norc -c '
    module() { return 1; }
    . "$HOME/harness/shell/hosts/local.sh"
' 2>&1)
[ "$warning" = \
    'harness: local MPI module unavailable; mpicc remains off PATH' ] ||
    fail 'module failure was not reported clearly'

printf '%s\n' 'local MPI profile tests: PASS'
