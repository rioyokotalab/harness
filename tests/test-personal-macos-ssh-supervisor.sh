#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
SUPERVISOR=$ROOT/libexec/harness-macos-ssh-supervisor
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
    "$ROOT/libexec/harness-macos-profile" "$SUPERVISOR" "$PUBLIC/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$ROOT/profiles/personal-macos/formula-policy-v2.conf" \
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
        [ "$native_format" != %a ] || native_format=%Lp
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
for argument do
    if [ "$argument" = -G ]; then
        printf '%s\n' 'hostname synthetic.invalid'
        printf '%s\n' 'remoteforward 10022 localhost:22'
        exit 0
    fi
    [ "$argument" != 'IdentitiesOnly=yes' ] || identity_only=yes
    [ "$argument" != 'IdentityAgent=none' ] || identity_agent=yes
    [ "$argument" != "IdentityFile=$HOME/.ssh/harness-reverse" ] || identity_file=yes
done
[ "$identity_only" = yes ] && [ "$identity_agent" = yes ] &&
    [ "$identity_file" = yes ] || exit 1
[ ! -e "$HOME/.fake-auth-fail" ]
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
            gui/*/org.rioyokota.harness.ssh.login2) marker=$state/login2 ;;
            gui/*/org.rioyokota.harness.ssh.login) marker=$state/login ;;
            gui/*) exit 0 ;;
            *) exit 1 ;;
        esac
        [ -e "$marker" ] || exit 1
        printf '%s\n' 'state = running'
        ;;
    bootstrap)
        plist=${3:-}
        case "$plist" in *login2.plist) marker=$state/login2 ;; *) marker=$state/login ;; esac
        [ ! -e "$HOME/.fake-bootstrap-fail" ] || exit 1
        : >"$marker"
        ;;
    bootout)
        target=${2:-}
        case "$target" in *login2) marker=$state/login2 ;; *) marker=$state/login ;; esac
        [ -e "$marker" ] || exit 1
        unlink "$marker"
        ;;
    kickstart)
        target=${3:-}
        case "$target" in *login2) marker=$state/login2 ;; *) marker=$state/login ;; esac
        [ -e "$marker" ]
        ;;
    *) exit 2 ;;
esac
EOF
cat >"$FAKE_BIN/ps" <<'EOF'
#!/bin/sh
if [ -f "$HOME/.fake-launch-state/login" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T login'
fi
if [ -f "$HOME/.fake-launch-state/login2" ]; then
    printf '%s\n' '1 /usr/bin/ssh /usr/bin/ssh -N -T login2'
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
if run_supervisor "$plan_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/auth-fail.out" 2>&1; then
    fail "plan accepted unavailable unattended authentication"
fi
[ "$(grep -c 'reason=unattended-auth' "$TEMP_DIR/auth-fail.out")" -eq 2 ] ||
    fail "unattended authentication refusal count"
unlink "$plan_home/.fake-auth-fail"

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

login_plist=$apply_home/Library/LaunchAgents/org.rioyokota.harness.ssh.login.plist
cp "$login_plist" "$TEMP_DIR/login.plist.original"
printf '%s\n' '<!-- changed -->' >>"$login_plist"
if run_supervisor "$apply_home" --rollback "$tx" >"$TEMP_DIR/changed.out" 2>&1; then
    fail "rollback accepted a changed launch agent"
fi
grep -F 'Mac SSH supervisor plist changed' "$TEMP_DIR/changed.out" >/dev/null ||
    fail "changed launch agent refusal"
mv "$TEMP_DIR/login.plist.original" "$login_plist"
chmod 600 "$login_plist"

printf '%s\n' login >"$apply_home/.fake-external"
if run_supervisor "$apply_home" --activate "$tx" --alias login \
    >"$TEMP_DIR/external.out" 2>&1; then
    fail "activation accepted an external tunnel"
fi
grep -F 'external SSH tunnel process blocks activation' "$TEMP_DIR/external.out" >/dev/null ||
    fail "external tunnel refusal"
unlink "$apply_home/.fake-external"

touch "$apply_home/.fake-auth-fail"
if run_supervisor "$apply_home" --activate "$tx" --alias login \
    >"$TEMP_DIR/activation-auth.out" 2>&1; then
    fail "activation accepted authentication drift"
fi
grep -F 'unattended SSH authentication is not ready' "$TEMP_DIR/activation-auth.out" >/dev/null ||
    fail "activation authentication refusal"
unlink "$apply_home/.fake-auth-fail"

run_supervisor "$apply_home" --activate "$tx" --alias login >"$TEMP_DIR/activate-login.out"
[ -e "$apply_home/.fake-launch-state/login" ] || fail "login service not loaded"
run_supervisor "$apply_home" --host mac-test-pilot --status >"$TEMP_DIR/status.out"
grep -F 'ALIAS name=login loaded=yes running=yes' "$TEMP_DIR/status.out" >/dev/null ||
    fail "active login status"
run_supervisor "$apply_home" --host mac-test-pilot --kick login >"$TEMP_DIR/kick.out"

if run_supervisor "$apply_home" --rollback "$tx" >"$TEMP_DIR/active-rollback.out" 2>&1; then
    fail "rollback accepted an active service"
fi
grep -F 'deactivate both Mac SSH supervisor services before rollback' \
    "$TEMP_DIR/active-rollback.out" >/dev/null || fail "active rollback refusal"

run_supervisor "$apply_home" --deactivate "$tx" --alias login >"$TEMP_DIR/deactivate.out"
[ ! -e "$apply_home/.fake-launch-state/login" ] || fail "login service remained loaded"
run_supervisor "$apply_home" --activate "$tx" --alias login2 >"$TEMP_DIR/activate-login2.out"
[ -e "$apply_home/.fake-launch-state/login2" ] || fail "login2 service not loaded"
run_supervisor "$apply_home" --deactivate "$tx" --alias login2 >"$TEMP_DIR/deactivate-login2.out"

run_supervisor "$apply_home" --rollback "$tx" >"$TEMP_DIR/rollback.out"
[ "$(sed -n '1p' "$apply_home/.local/state/harness/transactions/$tx.macos-ssh-supervisor.status")" = rolled-back ] ||
    fail "rollback status"
[ ! -e "$apply_home/.local/state/harness/macos-ssh-supervisor/current" ] ||
    fail "rollback retained current state"
[ ! -e "$apply_home/.local/state/harness/macos-ssh-supervisor" ] ||
    fail "rollback retained transaction-created supervisor directory"
for alias in login login2; do
    [ ! -e "$apply_home/Library/LaunchAgents/org.rioyokota.harness.ssh.$alias.plist" ] ||
        fail "rollback retained $alias plist"
done

collision_home=$(make_home collision)
printf '%s\n' occupied >"$collision_home/Library/LaunchAgents/org.rioyokota.harness.ssh.login.plist"
chmod 600 "$collision_home/Library/LaunchAgents/org.rioyokota.harness.ssh.login.plist"
if run_supervisor "$collision_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/collision.out" 2>&1; then
    fail "apply accepted an existing launch agent"
fi
grep -F 'reason=existing-path' "$TEMP_DIR/collision.out" >/dev/null ||
    fail "existing launch agent refusal"
[ ! -e "$collision_home/.local/state/harness/macos-ssh-supervisor" ] ||
    fail "blocked apply created supervisor state"

echo "personal macOS SSH supervisor tests: PASS"
