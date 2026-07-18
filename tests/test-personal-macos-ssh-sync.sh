#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-ssh-sync-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded Mac SSH-sync cleanup" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { echo "FAIL: $*" >&2; exit 1; }

fake_bin=$TEMP_DIR/fake-bin
mkdir "$fake_bin"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
echo Darwin
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    case "$2" in
        %u) format=%u ;;
        %Lp) format=%a ;;
        %l) format=%h ;;
        *) exit 2 ;;
    esac
    shift 2
    [ "${1:-}" != -- ] || shift
    exec /usr/bin/stat -c "$format" -- "$1"
fi
exec /usr/bin/stat "$@"
EOF
cat >"$fake_bin/mv" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] &&
   [ "$last" = "$MACOS_TEST_FAIL_DEST" ] &&
   [ ! -e "${MACOS_TEST_FAIL_MARKER:-}" ]; then
    : >"$MACOS_TEST_FAIL_MARKER"
    exit 42
fi
exec /usr/bin/mv "$@"
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/mv"

configure_identity() {
    git -C "$1" config user.name mac-test
    git -C "$1" config user.email mac-test.invalid
}

public=$TEMP_DIR/public
mkdir -p "$public/libexec" "$public/profiles/personal-macos"
cp -p "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-ssh-sync" "$public/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$public/profiles/personal-macos/base.conf"
git -C "$public" init -q -b main
configure_identity "$public"
git -C "$public" add libexec profiles
git -C "$public" commit -q -m 'synthetic public SSH sync engine'
chmod 700 "$public/.git"
SYNC=$public/libexec/harness-macos-ssh-sync

setup_home() {
    name=$1
    home=$TEMP_DIR/$name-home
    source=$TEMP_DIR/$name-source
    origin=$TEMP_DIR/$name-origin.git
    writer=$TEMP_DIR/$name-writer
    private=$home/.config/harness/private
    mkdir -p "$source/hosts" "$home/.config/harness" "$home/.ssh"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
        "$source/companion.conf"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
        "$source/hosts/mac-test-pilot.conf"
    chmod 600 "$source/companion.conf" "$source/hosts/mac-test-pilot.conf"
    git -C "$source" init -q -b main
    configure_identity "$source"
    git -C "$source" add companion.conf hosts/mac-test-pilot.conf
    git -C "$source" commit -q -m 'synthetic private pre-adoption'
    git init -q --bare -b main "$origin"
    git -C "$source" remote add origin "$origin"
    git -C "$source" push -q -u origin main
    git clone -q "$origin" "$private"
    git clone -q "$origin" "$writer"
    configure_identity "$private"
    configure_identity "$writer"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
        "$home/.ssh/config"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$home/.ssh" "$private" "$private/.git" "$private/hosts"
    chmod 600 "$home/.ssh/config" "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    printf '%s|%s|%s|%s\n' "$home" "$private" "$writer" "$origin"
}

run_sync() {
    test_home=$1
    shift
    HOME="$test_home" HARNESS_ROOT="$public" \
        PATH="$fake_bin:/usr/bin:/bin" "$SYNC" "$@"
}

IFS='|' read -r home private writer origin <<EOF
$(setup_home primary)
EOF

seed_required=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$seed_required" = \
    'MACOS_SSH_SYNC class=current agreement=no action=seed-required' ] ||
    fail "first-adoption seed requirement"
seed_plan=$(run_sync "$home" --host mac-test-pilot --seed --plan)
printf '%s\n' "$seed_plan" | grep -F \
    'class=current agreement=no action=seed apply=not-requested' >/dev/null ||
    fail "first-seed plan"
git -C "$private" cat-file -e HEAD:ssh_config 2>/dev/null &&
    fail "seed plan changed private repository"

seed_apply=$(run_sync "$home" --host mac-test-pilot --seed --apply)
printf '%s\n' "$seed_apply" | grep -F \
    'class=current agreement=yes action=applied' >/dev/null || fail "first seed apply"
[ "$(/usr/bin/stat -c %a "$home/.ssh/config")" = 600 ] ||
    fail "first seed did not normalize destination mode"
cmp -s "$home/.ssh/config" "$private/ssh_config" || fail "seed content agreement"
[ -f "$home/.local/state/harness/personal-macos/ssh-sync.conf" ] ||
    fail "first seed omitted state"

equal_output=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$equal_output" = 'MACOS_SSH_SYNC class=current agreement=yes action=none' ] ||
    fail "equal no-op"

local_sentinel=PRIVATE_LOCAL_ONLY_SENTINEL
printf '%s\n' 'Host local-edit.invalid' \
    '    HostName 192.0.2.21' "    User $local_sentinel" >"$home/.ssh/config"
chmod 600 "$home/.ssh/config"
publish_plan=$(run_sync "$home" --host mac-test-pilot --plan)
printf '%s\n' "$publish_plan" | grep -F 'action=publish' >/dev/null ||
    fail "local-only publish plan"
grep -F "$local_sentinel" <<EOF >/dev/null && fail "publish plan leaked SSH content"
$publish_plan
EOF
publish_apply=$(run_sync "$home" --host mac-test-pilot --apply)
printf '%s\n' "$publish_apply" | grep -F 'action=applied' >/dev/null ||
    fail "local-only publish apply"
git -C "$writer" pull -q --ff-only
cmp -s "$home/.ssh/config" "$writer/ssh_config" || fail "published payload mismatch"

cp "$home/.ssh/config" "$TEMP_DIR/before-remote"
printf '%s\n' 'Host remote-edit.invalid' '    HostName 192.0.2.31' \
    '    User synthetic-remote' >"$writer/ssh_config"
chmod 600 "$writer/ssh_config"
git -C "$writer" add ssh_config
git -C "$writer" commit -q -m 'synthetic remote-only edit'
git -C "$writer" push -q origin main
remote_plan=$(run_sync "$home" --host mac-test-pilot --plan)
printf '%s\n' "$remote_plan" | grep -F 'action=pull' >/dev/null ||
    fail "remote-only pull plan"
remote_apply=$(run_sync "$home" --host mac-test-pilot --apply)
printf '%s\n' "$remote_apply" | grep -F 'action=applied' >/dev/null ||
    fail "remote-only pull apply"
cmp -s "$home/.ssh/config" "$writer/ssh_config" || fail "remote-only apply mismatch"
remote_transaction=$(printf '%s\n' "$remote_apply" |
    sed -n 's/.* transaction=\([^ ]*\).*/\1/p')
[ -n "$remote_transaction" ] || fail "remote transaction identifier"

rollback_output=$(run_sync "$home" --rollback "$remote_transaction")
printf '%s\n' "$rollback_output" | grep -F 'action=rolled-back' >/dev/null ||
    fail "exact Mac rollback"
cmp -s "$home/.ssh/config" "$TEMP_DIR/before-remote" ||
    fail "Mac rollback did not restore exact prior file"
run_sync "$home" --host mac-test-pilot --apply >/dev/null ||
    fail "reapply after rollback"

cp "$home/.ssh/config" "$TEMP_DIR/before-divergence"
printf '%s\n' 'Host local-conflict.invalid' '    HostName 192.0.2.41' \
    >"$home/.ssh/config"
chmod 600 "$home/.ssh/config"
git -C "$writer" pull -q --ff-only
printf '%s\n' 'Host remote-conflict.invalid' '    HostName 192.0.2.42' \
    >"$writer/ssh_config"
chmod 600 "$writer/ssh_config"
git -C "$writer" add ssh_config
git -C "$writer" commit -q -m 'synthetic conflicting edit'
git -C "$writer" push -q origin main
if run_sync "$home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/diverged.out" 2>&1; then
    fail "concurrent divergence accepted"
fi
grep -F 'class=diverged agreement=no' "$TEMP_DIR/diverged.out" >/dev/null ||
    fail "concurrent divergence classification"
grep -F 'local-conflict.invalid' "$home/.ssh/config" >/dev/null ||
    fail "divergence changed local configuration"

# shellcheck disable=SC2034
IFS='|' read -r invalid_home invalid_private invalid_writer invalid_origin <<EOF
$(setup_home invalid)
EOF
printf '%s\n' 'Host invalid.invalid' '    ProxyCommand "unterminated' \
    >"$invalid_home/.ssh/config"
chmod 600 "$invalid_home/.ssh/config"
if run_sync "$invalid_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/invalid.out" 2>&1; then
    fail "invalid local SSH grammar accepted"
fi
grep -F 'SSH configuration grammar is invalid' "$TEMP_DIR/invalid.out" >/dev/null ||
    fail "invalid grammar refusal"

# shellcheck disable=SC2034
IFS='|' read -r unsafe_home unsafe_private unsafe_writer unsafe_origin <<EOF
$(setup_home unsafe)
EOF
chmod 666 "$unsafe_home/.ssh/config"
if run_sync "$unsafe_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/unsafe-mode.out" 2>&1; then
    fail "unsafe local SSH mode accepted"
fi
grep -F 'SSH configuration has unsafe mode' "$TEMP_DIR/unsafe-mode.out" >/dev/null ||
    fail "unsafe local mode refusal"

# shellcheck disable=SC2034
IFS='|' read -r fetch_home fetch_private fetch_writer fetch_origin <<EOF
$(setup_home fetch-failure)
EOF
git -C "$fetch_private" remote set-url origin "$TEMP_DIR/unavailable-origin.git"
if run_sync "$fetch_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/fetch-failure.out" 2>&1; then
    fail "injected fetch failure succeeded"
fi
grep -F 'class=auth-failed agreement=no' "$TEMP_DIR/fetch-failure.out" >/dev/null ||
    fail "fetch failure classification"

# shellcheck disable=SC2034
IFS='|' read -r push_home push_private push_writer push_origin <<EOF
$(setup_home push-failure)
EOF
run_sync "$push_home" --host mac-test-pilot --seed --apply >/dev/null
printf '%s\n' '#!/bin/sh' 'exit 1' >"$push_origin/hooks/pre-receive"
chmod 755 "$push_origin/hooks/pre-receive"
cp "$push_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/push-state-before"
printf '%s\n' 'Host push-failure.invalid' '    HostName 192.0.2.51' \
    >"$push_home/.ssh/config"
chmod 600 "$push_home/.ssh/config"
if run_sync "$push_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/push-failure.out" 2>&1; then
    fail "injected push failure succeeded"
fi
grep -F 'class=auth-failed agreement=no' "$TEMP_DIR/push-failure.out" >/dev/null ||
    fail "push failure classification"
cmp -s "$push_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/push-state-before" || fail "push failure changed state"
unlink "$push_origin/hooks/pre-receive"
retry_push=$(run_sync "$push_home" --host mac-test-pilot --apply)
printf '%s\n' "$retry_push" | grep -F 'action=applied' >/dev/null ||
    fail "retry after push failure"

printf '%s\n' 'Host atomic-failure.invalid' '    HostName 192.0.2.61' \
    >"$push_home/.ssh/config"
chmod 600 "$push_home/.ssh/config"
cp "$push_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/atomic-state-before"
cp "$push_home/.ssh/config" "$TEMP_DIR/atomic-source"
marker=$TEMP_DIR/atomic-failed-once
if HOME="$push_home" HARNESS_ROOT="$public" PATH="$fake_bin:/usr/bin:/bin" \
    MACOS_TEST_FAIL_DEST="$push_home/.ssh/config" \
    MACOS_TEST_FAIL_MARKER="$marker" "$SYNC" --host mac-test-pilot --apply \
    >"$TEMP_DIR/atomic-failure.out" 2>&1; then
    fail "injected atomic replacement failure succeeded"
fi
cmp -s "$push_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/atomic-state-before" || fail "atomic failure changed state"
cmp -s "$push_home/.ssh/config" "$TEMP_DIR/atomic-source" ||
    fail "atomic failure did not retain local edit"
run_sync "$push_home" --host mac-test-pilot --apply >/dev/null ||
    fail "retry after atomic replacement failure"

echo "personal macOS SSH-sync tests passed"
