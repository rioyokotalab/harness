#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-login-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$TEST_ROOT/repo
fake_bin=$TEST_ROOT/bin
mkdir -p "$repo/bin" "$repo/libexec" "$fake_bin"
cp "$ROOT/bin/harness" "$repo/bin/harness"
cp "$ROOT/libexec/harness-codex-login" "$repo/libexec/harness-codex-login"

cat >"$repo/libexec/harness-inventory" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$repo/bin/harness-codex" <<'EOF'
#!/bin/sh
set -eu
printf 'rayon=%s tokio=%s argc=%s arg1=%s arg2=%s\n' \
    "${RAYON_NUM_THREADS-unset}" "${TOKIO_WORKER_THREADS-unset}" \
    "$#" "${1-unset}" "${2-unset}"
EOF
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "$FAKE_UNAME"
EOF
chmod 755 "$repo/bin/harness" "$repo/bin/harness-codex" \
    "$repo/libexec/harness-inventory" "$repo/libexec/harness-codex-login" \
    "$fake_bin/uname"

FAKE_UNAME=Linux RAYON_NUM_THREADS=64 TOKIO_WORKER_THREADS=32 \
    PATH="$fake_bin:/usr/bin:/bin" \
    "$repo/bin/harness" codex-login --probe 'two words' \
    >"$TEST_ROOT/linux.out"
[ "$(cat "$TEST_ROOT/linux.out")" = \
    'rayon=8 tokio=8 argc=2 arg1=--probe arg2=two words' ] ||
    fail 'Linux limits or arguments changed'

env -u RAYON_NUM_THREADS -u TOKIO_WORKER_THREADS \
    FAKE_UNAME=Darwin PATH="$fake_bin:/usr/bin:/bin" \
    "$repo/bin/harness" codex-login --probe \
    >"$TEST_ROOT/darwin.out"
[ "$(cat "$TEST_ROOT/darwin.out")" = \
    'rayon=unset tokio=unset argc=1 arg1=--probe arg2=unset' ] ||
    fail 'macOS launcher injected Linux limits'

grep -F 'launcher=$HARNESS_ROOT/libexec/harness-codex-login' \
    "$ROOT/libexec/harness-codex-resilient" >/dev/null ||
    fail 'resilient supervisor bypasses bounded launcher'
grep -F 'codex-login      launch Codex with bounded Linux login-node worker pools' \
    "$ROOT/bin/harness" >/dev/null ||
    fail 'Harness help omits bounded launcher'

co_alias=$(bash -c '. "$1"; alias co' _ \
    "$ROOT/shell/common-aliases.sh")
[ "$co_alias" = \
    "alias co='harness codex-resilient --run --name harness --last'" ] ||
    fail 'shared co alias does not use resilient supervisor'
if bash -c '. "$1"; alias codex >/dev/null 2>&1' \
    _ "$ROOT/shell/common-aliases.sh"; then
    fail 'shared aliases still hide native codex'
fi

printf '%s\n' 'PASS: Codex login-node launcher'
