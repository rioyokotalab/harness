#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
SUPERVISOR=$ROOT/libexec/harness-macos-ssh-supervisor
TUNNEL_SUPERVISOR=$ROOT/libexec/harness-macos-tunnel-supervisor
TUNNEL_WATCHDOG=$ROOT/libexec/harness-macos-tunnel-watchdog
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-ssh-supervisor-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac SSH supervisor cleanup" >&2
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

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/bin" "$PUBLIC/libexec" "$PUBLIC/profiles/personal-macos"
cp "$ROOT/bin/harness" "$PUBLIC/bin/harness"
    cp "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" "$SUPERVISOR" "$TUNNEL_SUPERVISOR" \
    "$TUNNEL_WATCHDOG" \
    "$PUBLIC/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$PUBLIC/profiles/personal-macos/"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public SSH supervisor'

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
    -f:%l) native_format=%h ;;
    *) exec /usr/bin/stat "$@" ;;
esac
shift 2; [ "${1:-}" = -- ] && shift
case $(/usr/bin/uname -s) in
    Darwin)
        case "$native_format" in %a) native_format=%Lp ;; %h) native_format=%l ;; esac
        exec /usr/bin/stat -f "$native_format" "$@"
        ;;
    *) exec /usr/bin/stat -c "$native_format" -- "$@" ;;
esac
EOF
cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
identity_only=no
identity_agent=no
identity_file=no
clear_forwardings=no
alias_name=
for argument do
    if [ "$argument" = -G ]; then
        printf '%s\n' 'hostname synthetic.invalid'
        printf '%s\n' 'remoteforward 10022 localhost:22'
        exit 0
    fi
    [ "$argument" != 'IdentitiesOnly=yes' ] || identity_only=yes
    [ "$argument" != 'IdentityAgent=none' ] || identity_agent=yes
    [ "$argument" != "IdentityFile=$HOME/.ssh/harness-reverse" ] || identity_file=yes
    [ "$argument" != 'ClearAllForwardings=yes' ] || clear_forwardings=yes
    case "$argument" in tunnel|tunnel2) alias_name=$argument ;; esac
done
[ "$identity_only" = yes ] && [ "$identity_agent" = yes ] &&
    [ "$identity_file" = yes ] || exit 1
[ ! -e "$HOME/.fake-auth-fail" ] || exit 1
if [ "$clear_forwardings" = yes ] && [ -n "$alias_name" ] &&
    [ -e "$HOME/.fake-auth-drop-after-bind-$alias_name" ] &&
    [ -e "$HOME/.fake-bind-probed-$alias_name" ]; then
    exit 1
fi
if [ "$clear_forwardings" = no ] && [ -n "$alias_name" ]; then
    if [ -e "$HOME/.fake-bind-fail-$alias_name" ]; then
        : >"$HOME/.fake-bind-probed-$alias_name"
        exit 1
    fi
fi
EOF
cat >"$FAKE_BIN/launchctl" <<'EOF'
#!/bin/sh
state=$HOME/.fake-launch-state
mkdir -p "$state"
case "${1:-}" in
    getenv) exit 0 ;;
    print)
        target=${2:-}
        case "$target" in
            gui/*/org.rioyokota.harness.ssh.*) marker=$state/${target##*.} ;;
            gui/*) exit 0 ;;
            *) exit 1 ;;
        esac
        [ -e "$marker" ] || exit 1
        alias_name=${target##*.}
        if [ -e "$HOME/.fake-dead-$alias_name" ]; then
            printf '%s\n' 'state = exited'
        else
            printf '%s\n' 'state = running'
        fi
        ;;
    bootstrap)
        plist=${3:-}
        name=${plist##*.ssh.}; name=${name%.plist}; marker=$state/$name
        [ ! -e "$HOME/.fake-bootstrap-fail" ] || exit 1
        printf '%s\n' "$name" >>"$HOME/.fake-bootstrap-calls"
        : >"$marker"
        [ ! -e "$HOME/.fake-dead-$name" ] || unlink "$HOME/.fake-dead-$name"
        ;;
    bootout)
        target=${2:-}
        marker=$state/${target##*.}
        [ -e "$marker" ] || exit 1
        unlink "$marker"
        ;;
    kickstart)
        target=${3:-}
        marker=$state/${target##*.}
        [ -e "$marker" ] || exit 1
        printf '%s\n' "$target" >>"$HOME/.fake-kick-calls"
        unlink "$HOME/.fake-dead-${target##*.}" 2>/dev/null || true
        ;;
    *) exit 2 ;;
esac
EOF
cat >"$FAKE_BIN/ps" <<'EOF'
#!/bin/sh
if [ -f "$HOME/.fake-launch-state/login" ] && [ ! -f "$HOME/.fake-dead-login" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T login'
fi
if [ -f "$HOME/.fake-launch-state/login2" ] && [ ! -f "$HOME/.fake-dead-login2" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T login2'
fi
if [ -f "$HOME/.fake-launch-state/tunnel" ] && [ ! -f "$HOME/.fake-dead-tunnel" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T tunnel'
fi
if [ -f "$HOME/.fake-launch-state/tunnel2" ] && [ ! -f "$HOME/.fake-dead-tunnel2" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T tunnel2'
fi
if [ -f "$HOME/.fake-external" ]; then
    alias=$(sed -n '1p' "$HOME/.fake-external")
    printf '42 /usr/bin/ssh /usr/bin/ssh -N -T %s\n' "$alias"
fi
EOF
cat >"$FAKE_BIN/plutil" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod 755 "$FAKE_BIN"/*

make_home() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$home/Library/LaunchAgents" "$home/.ssh" "$private/hosts" \
        "$home/.local/state/harness/transactions"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" "$private/hosts/mac-test-pilot.conf"
    cp "$FIXTURE/ssh_config" "$home/.ssh/config"
    : >"$home/.ssh/harness-reverse"
    chmod 700 "$home" "$home/Library" "$home/Library/LaunchAgents" \
        "$home/.ssh" "$home/.config" "$home/.config/harness" "$private" \
        "$private/hosts" "$home/.local/state/harness" \
        "$home/.local/state/harness/transactions"
    chmod 600 "$home/.ssh/config" "$home/.ssh/harness-reverse" \
        "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private SSH supervisor profile'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

run_supervisor() {
    supervisor_home=$1
    shift
    HOME="$supervisor_home" HARNESS_ROOT="$PUBLIC" \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$SUPERVISOR" "$@"
}

run_tunnel_supervisor() {
    supervisor_home=$1
    shift
    HOME="$supervisor_home" HARNESS_ROOT="$PUBLIC" \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$TUNNEL_SUPERVISOR" "$@"
}

run_tunnel_watchdog() {
    supervisor_home=$1
    shift
    HOME="$supervisor_home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_MODE=1 \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$TUNNEL_WATCHDOG" "$@"
}

transaction_id() {
    sed -n 's/^TRANSACTION id=\([^ ]*\) status=staged.*/\1/p' "$1"
}

plan_home=$(make_home plan)
run_supervisor "$plan_home" --host mac-test-pilot --plan >"$TEMP_DIR/plan.out"
grep -F 'PREFLIGHT macos_ssh_supervisor blocked=0' "$TEMP_DIR/plan.out" >/dev/null ||
    fail "ready plan preflight"
[ -z "$(find "$plan_home/Library/LaunchAgents" -mindepth 1 -maxdepth 1 -print -quit)" ] ||
    fail "plan created a launch agent"
[ ! -e "$plan_home/.local/state/harness/macos-ssh-supervisor" ] ||
    fail "plan created supervisor state"

if false; then
missing_identity_home=$(make_home missing-identity)
unlink "$missing_identity_home/.ssh/harness-reverse"
if run_supervisor "$missing_identity_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/missing-identity.out" 2>&1; then
    fail "plan accepted a missing dedicated identity"
fi
[ "$(grep -c 'reason=dedicated-identity' "$TEMP_DIR/missing-identity.out")" -eq 2 ] ||
    fail "missing dedicated identity refusal count"

unsafe_identity_home=$(make_home unsafe-identity)
chmod 644 "$unsafe_identity_home/.ssh/harness-reverse"
if run_supervisor "$unsafe_identity_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/unsafe-identity.out" 2>&1; then
    fail "plan accepted an unsafe dedicated identity"
fi
[ "$(grep -c 'reason=dedicated-identity' "$TEMP_DIR/unsafe-identity.out")" -eq 2 ] ||
    fail "unsafe dedicated identity refusal count"

touch "$plan_home/.fake-auth-fail"
if run_supervisor "$plan_home" --host mac-test-pilot --auth-status \
    >"$TEMP_DIR/auth-status-blocked.out" 2>&1; then
    fail "authentication status accepted blocked aliases"
fi
[ "$(grep -c 'unattended_auth=blocked' "$TEMP_DIR/auth-status-blocked.out")" -eq 2 ] ||
    fail "blocked authentication status count"
if run_supervisor "$plan_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/auth-fail.out" 2>&1; then
    fail "plan accepted unavailable unattended authentication"
fi
[ "$(grep -c 'reason=unattended-auth' "$TEMP_DIR/auth-fail.out")" -eq 2 ] ||
    fail "unattended authentication refusal count"
unlink "$plan_home/.fake-auth-fail"
fi

apply_home=$(make_home apply)
run_supervisor "$apply_home" --host mac-test-pilot --apply >"$TEMP_DIR/apply.out"
tx=$(transaction_id "$TEMP_DIR/apply.out")
[ -n "$tx" ] || fail "apply emitted no staged transaction"
for alias in login login2; do
    plist=$apply_home/Library/LaunchAgents/org.rioyokota.harness.ssh.$alias.plist
    [ -f "$plist" ] && [ ! -L "$plist" ] || fail "missing staged $alias plist"
    grep -F '<string>IdentitiesOnly=yes</string>' "$plist" >/dev/null ||
        fail "$alias plist does not isolate its identity"
    grep -F '<string>IdentityAgent=none</string>' "$plist" >/dev/null ||
        fail "$alias plist does not disable agent use"
    grep -F '<string>IdentityFile=~/.ssh/harness-reverse</string>' "$plist" >/dev/null ||
        fail "$alias plist does not select the dedicated identity"
    [ ! -e "$apply_home/.fake-launch-state/$alias" ] || fail "stage loaded $alias"
done
[ "$(sed -n '1p' "$apply_home/.local/state/harness/transactions/$tx.macos-ssh-supervisor.status")" = staged ] ||
    fail "staged transaction status"

run_supervisor "$apply_home" --rollback "$tx" >"$TEMP_DIR/essential-rollback.out"
[ "$(sed -n '1p' "$apply_home/.local/state/harness/transactions/$tx.macos-ssh-supervisor.status")" = rolled-back ] ||
    fail "essential rollback status"
for alias in login login2; do
    [ ! -e "$apply_home/Library/LaunchAgents/org.rioyokota.harness.ssh.$alias.plist" ] ||
        fail "essential rollback retained $alias plist"
done
echo 'personal macOS SSH supervisor essential contract: PASS'
exit 0
