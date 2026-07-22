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
if [ "$clear_forwardings" = no ] && [ -n "$alias_name" ]; then
    [ ! -e "$HOME/.fake-bind-fail-$alias_name" ] || exit 1
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
touch "$apply_home/.fake-auth-fail"
if run_supervisor "$apply_home" --host mac-test-pilot --kick login \
    >"$TEMP_DIR/kick-auth-fail.out" 2>&1; then
    fail "kick accepted authentication drift"
fi
grep -F 'unattended SSH authentication is not ready for restart' \
    "$TEMP_DIR/kick-auth-fail.out" >/dev/null || fail "kick authentication refusal"
[ ! -e "$apply_home/.fake-kick-calls" ] ||
    fail "authentication failure reached launchctl kickstart"
[ -e "$apply_home/.fake-launch-state/login" ] ||
    fail "authentication failure unloaded the existing service"
unlink "$apply_home/.fake-auth-fail"
run_supervisor "$apply_home" --host mac-test-pilot --kick login >"$TEMP_DIR/kick.out"
[ "$(wc -l <"$apply_home/.fake-kick-calls" | tr -d ' ')" -eq 1 ] ||
    fail "successful kick did not call launchctl exactly once"

bootstrap_before=$(wc -l <"$apply_home/.fake-bootstrap-calls" | tr -d ' ')
unlink "$apply_home/.fake-launch-state/login"
touch "$apply_home/.fake-auth-fail"
if run_supervisor "$apply_home" --host mac-test-pilot --kick login \
    >"$TEMP_DIR/unloaded-auth-fail.out" 2>&1; then
    fail "unloaded recovery accepted authentication drift"
fi
[ "$(wc -l <"$apply_home/.fake-bootstrap-calls" | tr -d ' ')" -eq \
    "$bootstrap_before" ] || fail "authentication failure reached bootstrap"
[ ! -e "$apply_home/.fake-launch-state/login" ] ||
    fail "failed unloaded recovery created a service"
unlink "$apply_home/.fake-auth-fail"
run_supervisor "$apply_home" --host mac-test-pilot --kick login \
    >"$TEMP_DIR/unloaded-recovery.out"
grep -F 'alias=login action=bootstrap status=running' \
    "$TEMP_DIR/unloaded-recovery.out" >/dev/null || fail "unloaded bootstrap result"
[ -e "$apply_home/.fake-launch-state/login" ] ||
    fail "unloaded recovery did not bootstrap the service"

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

tunnel_home=$(make_home tunnel)
run_tunnel_supervisor "$tunnel_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/tunnel-apply.out"
tunnel_tx=$(transaction_id "$TEMP_DIR/tunnel-apply.out")
[ -n "$tunnel_tx" ] || fail "tunnel apply emitted no staged transaction"
for alias in tunnel tunnel2; do
    [ -f "$tunnel_home/Library/LaunchAgents/org.rioyokota.harness.ssh.$alias.plist" ] ||
        fail "missing staged $alias plist"
done
[ -f "$tunnel_home/.local/state/harness/macos-tunnel-supervisor/current" ] ||
    fail "tunnel supervisor did not use independent state"
run_tunnel_supervisor "$tunnel_home" --activate "$tunnel_tx" --alias tunnel \
    >"$TEMP_DIR/tunnel-activate.out"
run_tunnel_supervisor "$tunnel_home" --host mac-test-pilot --kick tunnel \
    >"$TEMP_DIR/tunnel-kick.out"
touch "$tunnel_home/.fake-dead-tunnel"
run_tunnel_supervisor "$tunnel_home" --host mac-test-pilot --status \
    >"$TEMP_DIR/tunnel-dead-status.out"
grep -F 'ALIAS name=tunnel loaded=yes running=no managed=0 external=0' \
    "$TEMP_DIR/tunnel-dead-status.out" >/dev/null || fail "dead tunnel status"
run_tunnel_supervisor "$tunnel_home" --host mac-test-pilot --kick tunnel \
    >"$TEMP_DIR/tunnel-dead-kick.out"
[ ! -e "$tunnel_home/.fake-dead-tunnel" ] || fail "dead tunnel was not restarted"
run_tunnel_supervisor "$tunnel_home" --deactivate "$tunnel_tx" --alias tunnel \
    >"$TEMP_DIR/tunnel-deactivate.out"
run_tunnel_supervisor "$tunnel_home" --rollback "$tunnel_tx" \
    >"$TEMP_DIR/tunnel-rollback.out"

watchdog_home=$(make_home watchdog)
run_tunnel_supervisor "$watchdog_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/watchdog-tunnel-apply.out"
watchdog_tunnel_tx=$(transaction_id "$TEMP_DIR/watchdog-tunnel-apply.out")
run_tunnel_supervisor "$watchdog_home" --activate "$watchdog_tunnel_tx" --alias tunnel \
    >"$TEMP_DIR/watchdog-tunnel-activate.out"
run_tunnel_supervisor "$watchdog_home" --activate "$watchdog_tunnel_tx" --alias tunnel2 \
    >>"$TEMP_DIR/watchdog-tunnel-activate.out"

run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/watchdog-plan.out"
grep -F 'WATCHDOG stage=create interval=30 recovery=bounded-drain blocked=0' \
    "$TEMP_DIR/watchdog-plan.out" >/dev/null || fail "watchdog ready plan"
[ ! -e "$watchdog_home/Library/LaunchAgents/org.rioyokota.harness.ssh.tunnel-watchdog.plist" ] ||
    fail "watchdog plan created a launch agent"

run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/watchdog-apply.out"
watchdog_tx=$(sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete.*/\1/p' \
    "$TEMP_DIR/watchdog-apply.out")
[ -n "$watchdog_tx" ] || fail "watchdog apply emitted no transaction"
run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --status \
    >"$TEMP_DIR/watchdog-status.out"
grep -F 'installed=yes loaded=yes' "$TEMP_DIR/watchdog-status.out" >/dev/null ||
    fail "watchdog installed status"

run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --run-once \
    >"$TEMP_DIR/watchdog-healthy.out"
grep -F 'action=none reason=route-running' "$TEMP_DIR/watchdog-healthy.out" >/dev/null ||
    fail "watchdog healthy no-op"

touch "$watchdog_home/.fake-dead-tunnel" "$watchdog_home/.fake-dead-tunnel2"
run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --run-once \
    >"$TEMP_DIR/watchdog-dual.out"
grep -F 'action=drain status=started' "$TEMP_DIR/watchdog-dual.out" >/dev/null ||
    fail "watchdog dual drain"
grep -F 'action=restore status=complete' "$TEMP_DIR/watchdog-dual.out" >/dev/null ||
    fail "watchdog dual restore"
for alias in tunnel tunnel2; do
    [ -e "$watchdog_home/.fake-launch-state/$alias" ] ||
        fail "watchdog did not reload $alias"
    [ ! -e "$watchdog_home/.fake-dead-$alias" ] ||
        fail "watchdog did not restart $alias"
done

recovery_lock=$watchdog_home/.local/state/harness/macos-tunnel-supervisor/recovery.lock
printf 'pid=%s\nstart=%s\n' "$$" \
    "$(/bin/ps -p "$$" -o lstart= | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" \
    >"$recovery_lock"
chmod 600 "$recovery_lock"
run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --run-once \
    >"$TEMP_DIR/watchdog-busy.out"
grep -F 'action=defer reason=busy' "$TEMP_DIR/watchdog-busy.out" >/dev/null ||
    fail "watchdog lock contention"
unlink "$recovery_lock"

printf '%s\n' 'pid=999999999' 'start=stale-process' >"$recovery_lock"
chmod 600 "$recovery_lock"
run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --run-once \
    >"$TEMP_DIR/watchdog-stale-lock.out"
grep -F 'action=none reason=route-running' "$TEMP_DIR/watchdog-stale-lock.out" >/dev/null ||
    fail "watchdog stale lock recovery"
[ ! -e "$recovery_lock" ] || fail "watchdog retained stale recovery lock"

touch "$watchdog_home/.fake-dead-tunnel" "$watchdog_home/.fake-dead-tunnel2" \
    "$watchdog_home/.fake-auth-fail"
if run_tunnel_watchdog "$watchdog_home" --host mac-test-pilot --run-once \
    >"$TEMP_DIR/watchdog-auth-fail.out" 2>&1; then
    fail "watchdog accepted authentication failure"
fi
grep -F 'authentication is not ready for pair recovery' \
    "$TEMP_DIR/watchdog-auth-fail.out" >/dev/null || fail "watchdog authentication refusal"
[ -e "$watchdog_home/.fake-launch-state/tunnel" ] &&
    [ -e "$watchdog_home/.fake-launch-state/tunnel2" ] ||
    fail "authentication failure changed service baseline"
[ ! -e "$recovery_lock" ] || fail "authentication failure retained recovery lock"
unlink "$watchdog_home/.fake-auth-fail"

touch "$watchdog_home/.fake-bind-fail-tunnel" "$watchdog_home/.fake-bind-fail-tunnel2"
if HARNESS_TEST_RECOVERY_ATTEMPTS=1 run_tunnel_watchdog "$watchdog_home" \
    --host mac-test-pilot --run-once >"$TEMP_DIR/watchdog-timeout.out" 2>&1; then
    fail "watchdog accepted stale-listener timeout"
fi
grep -F 'stale-listener drain timed out' "$TEMP_DIR/watchdog-timeout.out" >/dev/null ||
    fail "watchdog timeout classification"
[ -e "$watchdog_home/.fake-launch-state/tunnel" ] &&
    [ -e "$watchdog_home/.fake-launch-state/tunnel2" ] ||
    fail "watchdog timeout did not restore loaded baseline"
[ ! -e "$recovery_lock" ] || fail "watchdog timeout retained recovery lock"
unlink "$watchdog_home/.fake-bind-fail-tunnel"
unlink "$watchdog_home/.fake-bind-fail-tunnel2"

run_tunnel_watchdog "$watchdog_home" --rollback "$watchdog_tx" \
    >"$TEMP_DIR/watchdog-rollback.out"
[ ! -e "$watchdog_home/Library/LaunchAgents/org.rioyokota.harness.ssh.tunnel-watchdog.plist" ] ||
    fail "watchdog rollback retained plist"
run_tunnel_supervisor "$watchdog_home" --deactivate "$watchdog_tunnel_tx" --alias tunnel \
    >"$TEMP_DIR/watchdog-tunnel-deactivate.out"
run_tunnel_supervisor "$watchdog_home" --deactivate "$watchdog_tunnel_tx" --alias tunnel2 \
    >>"$TEMP_DIR/watchdog-tunnel-deactivate.out"
run_tunnel_supervisor "$watchdog_home" --rollback "$watchdog_tunnel_tx" \
    >"$TEMP_DIR/watchdog-tunnel-rollback.out"

echo "personal macOS SSH supervisor tests: PASS"
