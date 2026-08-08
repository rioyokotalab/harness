#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CONTROL=$ROOT/libexec/harness-macos-control
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-control-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac control cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

file_mode() {
    case $(uname -s) in
        Darwin) /usr/bin/stat -f '%Lp' "$1" ;;
        *) /usr/bin/stat -c '%a' -- "$1" ;;
    esac
}

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/bin" "$PUBLIC/.codex/rules" "$PUBLIC/.claude" \
    "$PUBLIC/config/agent-clients" \
    "$PUBLIC/shared/skills/mac-test-skill" \
    "$PUBLIC/profiles/personal-macos"
cp "$ROOT/bin/harness" "$ROOT/bin/harness-bash" "$PUBLIC/bin/"
cp "$ROOT/.codex/AGENTS.md" "$PUBLIC/.codex/AGENTS.md"
cp "$ROOT/.codex/rules/default.rules" "$PUBLIC/.codex/rules/default.rules"
cp "$ROOT/config/agent-clients/claude-sentinel.md" \
    "$PUBLIC/config/agent-clients/claude-sentinel.md"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$PUBLIC/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$PUBLIC/profiles/personal-macos/formula-policy-v4.conf"
printf '%s\n' 'synthetic control skill' > \
    "$PUBLIC/shared/skills/mac-test-skill/SKILL.md"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public control plane'

FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$FAKE_BIN"
cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
[ "${1:-}" = -s ] && { echo Darwin; exit 0; }
exec /usr/bin/uname "$@"
EOF
cat >"$FAKE_BIN/stat" <<'EOF'
#!/bin/sh
case "${1:-}:${2:-}" in
    -f:%u) native_format=%u ;;
    -f:%Lp) native_format=%a ;;
    *) exec /usr/bin/stat "$@" ;;
esac
shift 2; [ "${1:-}" = -- ] && shift
case $(/usr/bin/uname -s) in
    Darwin)
        [ "$native_format" != %a ] || native_format=%Lp
        exec /usr/bin/stat -f "$native_format" "$@"
        ;;
    *) exec /usr/bin/stat -c "$native_format" -- "$@" ;;
esac
EOF
cat >"$FAKE_BIN/ln" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] && [ "$last" = "$MACOS_TEST_FAIL_DEST" ]; then
    echo "injected link failure" >&2
    exit 73
fi
exec /bin/ln "$@"
EOF
chmod 755 "$FAKE_BIN/uname" "$FAKE_BIN/stat" "$FAKE_BIN/ln"

make_home() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$private/hosts"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$private" "$private/hosts"
    chmod 600 "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private control profile'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

run_control() {
    control_home=$1
    shift
    HOME="$control_home" HARNESS_ROOT="$PUBLIC" \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$CONTROL" "$@"
}

transaction_id() {
    sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete.*/\1/p' "$1"
}

link_count=4
basic_home=$(make_home basic)
run_control "$basic_home" --host mac-test-pilot --plan >"$TEMP_DIR/basic.plan"
[ "$(grep -c '^CREATE link=' "$TEMP_DIR/basic.plan")" -eq "$link_count" ] ||
    fail "plan did not report the exact managed link set"
grep -F 'END macos_control blocked=0 changes=4 applied=no' \
    "$TEMP_DIR/basic.plan" >/dev/null || fail "plan completion summary"
[ ! -e "$basic_home/.local" ] && [ ! -L "$basic_home/.local" ] ||
    fail "plan mutated local state"

run_control "$basic_home" --host mac-test-pilot --apply >"$TEMP_DIR/basic.apply"
basic_tx=$(transaction_id "$TEMP_DIR/basic.apply")
[ -n "$basic_tx" ] || fail "apply emitted no transaction identifier"
basic_manifest=$basic_home/.local/state/harness/transactions/$basic_tx.macos-control.manifest
basic_status=$basic_home/.local/state/harness/transactions/$basic_tx.macos-control.status
[ "$(file_mode "$basic_manifest")" = 600 ] ||
    fail "transaction manifest mode"
[ "$(file_mode "$basic_status")" = 600 ] ||
    fail "transaction status mode"
[ "$(file_mode "$basic_home/.local/state/harness")" = 700 ] ||
    fail "transaction state mode"
[ -L "$basic_home/.local/bin/harness" ] &&
    [ "$(readlink "$basic_home/.local/bin/harness")" = "$PUBLIC/bin/harness" ] ||
    fail "harness discovery link"
[ -L "$basic_home/.local/bin/harness-bash" ] &&
    [ "$(readlink "$basic_home/.local/bin/harness-bash")" = \
        "$PUBLIC/bin/harness-bash" ] || fail "managed Bash launcher link"
[ ! -e "$basic_home/.codex/skills/mac-test-skill" ] ||
    fail "global Codex skill link was created"

before_count=$(find "$basic_home/.local/state/harness/transactions" \
    -type f -name '*.macos-control.manifest' | wc -l | tr -d ' ')
run_control "$basic_home" --host mac-test-pilot --apply >"$TEMP_DIR/basic.second"
after_count=$(find "$basic_home/.local/state/harness/transactions" \
    -type f -name '*.macos-control.manifest' | wc -l | tr -d ' ')
[ "$before_count" = "$after_count" ] || fail "idempotent apply created a transaction"
grep -F 'END macos_control changes=none' "$TEMP_DIR/basic.second" >/dev/null ||
    fail "idempotent apply summary"

unlink "$basic_home/.local/bin/harness"
ln -s "$PUBLIC/.codex/AGENTS.md" "$basic_home/.local/bin/harness"
if run_control "$basic_home" --rollback "$basic_tx" \
    >"$TEMP_DIR/basic.changed" 2>&1; then
    fail "rollback accepted a changed link"
fi
grep -F 'rollback blocked by changed link' "$TEMP_DIR/basic.changed" >/dev/null ||
    fail "changed-link rollback refusal"
[ -L "$basic_home/.codex/AGENTS.md" ] ||
    fail "changed-link refusal mutated another link"
unlink "$basic_home/.local/bin/harness"
ln -s "$PUBLIC/bin/harness" "$basic_home/.local/bin/harness"
run_control "$basic_home" --rollback "$basic_tx" >"$TEMP_DIR/basic.rollback"
[ "$(sed -n '1p' "$basic_status")" = rolled-back ] || fail "rollback status"
[ ! -e "$basic_home/.local/bin/harness" ] &&
    [ ! -L "$basic_home/.local/bin/harness" ] || fail "rollback retained harness link"
[ ! -e "$basic_home/.codex" ] && [ ! -L "$basic_home/.codex" ] ||
    fail "rollback retained a created discovery directory"

echo 'personal macOS control essential contract: PASS'
exit 0
