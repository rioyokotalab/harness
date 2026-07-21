#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-ssh-sync-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
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
file_mode() {
    case $(uname -s) in Darwin) /usr/bin/stat -f %Lp "$1" ;; *) /usr/bin/stat -c %a "$1" ;; esac
}

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
    case $(/usr/bin/uname -s) in
        Darwin)
            case "$format" in %a) format=%Lp ;; %h) format=%l ;; esac
            exec /usr/bin/stat -f "$format" "$1"
            ;;
        *) exec /usr/bin/stat -c "$format" -- "$1" ;;
    esac
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
exec /bin/mv "$@"
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/mv"

configure_identity() {
    git -C "$1" config user.name mac-test
    git -C "$1" config user.email mac-test.invalid
}

public=$TEMP_DIR/public
mkdir -p "$public/libexec" "$public/profiles/personal-macos" "$public/config/ssh"
cp -p "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-ssh-sync" \
    "$ROOT/libexec/harness-ssh-config-layout" "$public/libexec/"
cp "$ROOT/config/ssh/harness.conf" "$public/config/ssh/harness.conf"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$public/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v2.conf" \
    "$public/profiles/personal-macos/formula-policy-v2.conf"
git -C "$public" init -q -b main
configure_identity "$public"
git -C "$public" add libexec profiles config
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
    HOME="$test_home" HARNESS_ROOT="$public" HARNESS_TESTING=1 \
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
[ "$(file_mode "$home/.ssh/config")" = 600 ] ||
    fail "first seed did not normalize destination mode"
cmp -s "$home/.ssh/config" "$private/ssh_config" || fail "seed content agreement"
[ -f "$home/.local/state/harness/personal-macos/ssh-sync.conf" ] ||
    fail "first seed omitted state"

equal_output=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$equal_output" = 'MACOS_SSH_SYNC class=current agreement=yes action=none' ] ||
    fail "equal no-op"

# The layout adapter changes only the live root while the private payload still
# equals the recorded base. This must remain an ordinary local-only publish,
# not a three-way divergence requiring an arbitrary winner.
# shellcheck disable=SC2034
IFS='|' read -r layout_home layout_private layout_writer _layout_origin <<EOF
$(setup_home layout-migration)
EOF
cat >>"$layout_home/.ssh/config" <<'EOF'

Host github
    HostName github.com
    User git

Host *
    ServerAliveInterval 15
EOF
run_sync "$layout_home" --host mac-test-pilot --seed --apply >/dev/null
git -C "$layout_writer" pull -q --ff-only
cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
    "$TEMP_DIR/layout-remote"
printf '%s\n' '' 'Include ~/.ssh/config.d/harness.conf' \
    >>"$TEMP_DIR/layout-remote"
mv "$TEMP_DIR/layout-remote" "$layout_writer/ssh_config"
chmod 600 "$layout_writer/ssh_config"
git -C "$layout_writer" add ssh_config
git -C "$layout_writer" commit -q -m 'synthetic historical include-only advance'
git -C "$layout_writer" push -q origin main
sed 's/synthetic-user/synthetic-layout-local/' \
    "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
    >"$layout_home/.ssh/config"
printf '%s\n' 'Match all' 'Include ~/.ssh/config.d/harness.conf' \
    >>"$layout_home/.ssh/config"
chmod 600 "$layout_home/.ssh/config"
mkdir "$layout_home/.ssh/config.d"
cp "$public/config/ssh/harness.conf" "$layout_home/.ssh/config.d/harness.conf"
chmod 700 "$layout_home/.ssh/config.d"
chmod 600 "$layout_home/.ssh/config.d/harness.conf"
layout_plan=$(run_sync "$layout_home" --host mac-test-pilot --plan)
printf '%s\n' "$layout_plan" | grep -F 'class=current agreement=no action=publish' \
    >/dev/null || fail "layout migration was not classified local-only"
layout_apply=$(run_sync "$layout_home" --host mac-test-pilot --apply)
layout_transaction=$(printf '%s\n' "$layout_apply" |
    sed -n 's/.* transaction=\([^ ]*\).*/\1/p')
[ -n "$layout_transaction" ] || fail "layout migration transaction identifier"
git -C "$layout_writer" pull -q --ff-only
cmp -s "$layout_home/.ssh/config" "$layout_writer/ssh_config" ||
    fail "layout migration payload was not published"
run_sync "$layout_home" --rollback "$layout_transaction" >/dev/null ||
    fail "layout migration rollback"
layout_rollback_plan=$(run_sync "$layout_home" --host mac-test-pilot --plan)
printf '%s\n' "$layout_rollback_plan" | grep -F 'agreement=no action=pull' \
    >/dev/null || fail "layout migration rollback refresh plan"
run_sync "$layout_home" --host mac-test-pilot --apply >/dev/null ||
    fail "layout migration rollback reapply"
cmp -s "$layout_home/.ssh/config" "$layout_writer/ssh_config" ||
    fail "layout migration rollback reapply mismatch"

sed 's/synthetic-layout-local/synthetic-layout-live-conflict/' \
    "$layout_home/.ssh/config" >"$TEMP_DIR/layout-live-conflict"
mv "$TEMP_DIR/layout-live-conflict" "$layout_home/.ssh/config"
chmod 600 "$layout_home/.ssh/config"
sed 's/synthetic-layout-local/synthetic-layout-remote-conflict/' \
    "$layout_writer/ssh_config" >"$TEMP_DIR/layout-remote-conflict"
mv "$TEMP_DIR/layout-remote-conflict" "$layout_writer/ssh_config"
chmod 600 "$layout_writer/ssh_config"
git -C "$layout_writer" add ssh_config
git -C "$layout_writer" commit -q -m 'synthetic non-shared layout conflict'
git -C "$layout_writer" push -q origin main
if run_sync "$layout_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/layout-conflict.out" 2>&1; then
    fail "non-shared layout conflict accepted"
fi
grep -F 'class=diverged agreement=no' "$TEMP_DIR/layout-conflict.out" >/dev/null ||
    fail "non-shared layout conflict classification"

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

# A new Mac may explicitly adopt an existing shared private payload without
# publishing or requiring its unequal local file to match first.
IFS='|' read -r adopt_home _adopt_private adopt_writer _adopt_origin <<EOF
$(setup_home adopt-remote)
EOF
cp "$adopt_home/.ssh/config" "$TEMP_DIR/adopt-prior"
printf '%s\n' 'Host shared-remote.invalid' '    HostName 192.0.2.51' \
    >"$adopt_writer/ssh_config"
chmod 600 "$adopt_writer/ssh_config"
git -C "$adopt_writer" add ssh_config
git -C "$adopt_writer" commit -q -m 'synthetic shared payload'
git -C "$adopt_writer" push -q origin main
if run_sync "$adopt_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/adopt-default.out" 2>&1; then
    fail "unequal first agreement was accepted without direction"
fi
grep -F 'class=diverged agreement=no' "$TEMP_DIR/adopt-default.out" >/dev/null ||
    fail "unequal first agreement classification"
adopt_plan=$(run_sync "$adopt_home" --host mac-test-pilot --adopt-remote --plan)
printf '%s\n' "$adopt_plan" | grep -F \
    'class=current agreement=no action=adopt apply=not-requested' >/dev/null ||
    fail "remote-adoption plan"
cmp -s "$adopt_home/.ssh/config" "$TEMP_DIR/adopt-prior" ||
    fail "remote-adoption plan changed live config"
adopt_apply=$(run_sync "$adopt_home" --host mac-test-pilot --adopt-remote --apply)
printf '%s\n' "$adopt_apply" | grep -F 'action=applied' >/dev/null ||
    fail "remote-adoption apply"
cmp -s "$adopt_home/.ssh/config" "$adopt_writer/ssh_config" ||
    fail "remote-adoption payload mismatch"
adopt_transaction=$(printf '%s\n' "$adopt_apply" |
    sed -n 's/.* transaction=\([^ ]*\).*/\1/p')
[ -n "$adopt_transaction" ] || fail "remote-adoption transaction identifier"
run_sync "$adopt_home" --rollback "$adopt_transaction" >/dev/null ||
    fail "remote-adoption rollback"
cmp -s "$adopt_home/.ssh/config" "$TEMP_DIR/adopt-prior" ||
    fail "remote-adoption rollback did not restore prior config"
run_sync "$adopt_home" --host mac-test-pilot --adopt-remote --apply >/dev/null ||
    fail "remote-adoption reapply"
cmp -s "$adopt_home/.ssh/config" "$adopt_writer/ssh_config" ||
    fail "remote-adoption reapply mismatch"

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

# Schema 3 preserves each Mac's distinct live root in an independent payload.
# Per-host migration is explicit, leaves the legacy root during transition,
# ignores unrelated-host payload advances, and finalizes only at exact
# host/payload bijection.
IFS='|' read -r per_host_home per_host_private per_host_writer per_host_origin <<EOF
$(setup_home per-host)
EOF
run_sync "$per_host_home" --host mac-test-pilot --seed --apply >/dev/null
git -C "$per_host_writer" pull -q --ff-only
sed 's/logical_id=mac-test-pilot/logical_id=mac-test-other/' \
    "$per_host_writer/hosts/mac-test-pilot.conf" \
    >"$per_host_writer/hosts/mac-test-other.conf"
chmod 600 "$per_host_writer/hosts/mac-test-other.conf"
git -C "$per_host_writer" add hosts/mac-test-other.conf
git -C "$per_host_writer" commit -q -m 'synthetic second Mac declaration'
git -C "$per_host_writer" push -q origin main
printf '%s\n' 'Host per-host.invalid' '    HostName 192.0.2.71' \
    '    User PRIVATE_PER_HOST_SENTINEL' >"$per_host_home/.ssh/config"
chmod 600 "$per_host_home/.ssh/config"
cp "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before"
per_host_plan=$(run_sync "$per_host_home" --host mac-test-pilot \
    --migrate-per-host --plan)
printf '%s\n' "$per_host_plan" | grep -F \
    'action=migrate-per-host apply=not-requested' >/dev/null ||
    fail "per-host migration plan"
if printf '%s\n' "$per_host_plan" | grep -F PRIVATE_PER_HOST_SENTINEL >/dev/null; then
    fail "per-host migration plan exposed private content"
fi
[ ! -e "$per_host_private/ssh/mac-test-pilot.conf" ] ||
    fail "per-host migration plan changed private repository"
cp "$per_host_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/per-host-state-before"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$per_host_origin/hooks/pre-receive"
chmod 755 "$per_host_origin/hooks/pre-receive"
if run_sync "$per_host_home" --host mac-test-pilot \
    --migrate-per-host --apply >"$TEMP_DIR/per-host-push-failure.out" 2>&1; then
    fail "injected per-host migration push failure succeeded"
fi
grep -F 'class=auth-failed agreement=no' \
    "$TEMP_DIR/per-host-push-failure.out" >/dev/null ||
    fail "per-host migration push failure classification"
cmp -s "$per_host_home/.local/state/harness/personal-macos/ssh-sync.conf" \
    "$TEMP_DIR/per-host-state-before" ||
    fail "per-host migration push failure changed state"
cmp -s "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before" ||
    fail "per-host migration push failure changed live SSH bytes"
unlink "$per_host_origin/hooks/pre-receive"
per_host_apply=$(run_sync "$per_host_home" --host mac-test-pilot \
    --migrate-per-host --apply)
printf '%s\n' "$per_host_apply" | grep -F 'action=applied' >/dev/null ||
    fail "per-host migration apply"
[ -f "$per_host_private/ssh_config" ] ||
    fail "per-host migration removed legacy payload early"
cmp -s "$per_host_home/.ssh/config" \
    "$per_host_private/ssh/mac-test-pilot.conf" ||
    fail "per-host migration payload mismatch"
cmp -s "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before" ||
    fail "per-host migration changed live SSH bytes"

git -C "$per_host_writer" pull -q --ff-only
mkdir -p "$per_host_writer/ssh"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" \
    "$per_host_writer/ssh/mac-test-other.conf"
chmod 600 "$per_host_writer/ssh/mac-test-other.conf"
git -C "$per_host_writer" add ssh/mac-test-other.conf
git -C "$per_host_writer" commit -q -m 'synthetic unrelated Mac payload'
git -C "$per_host_writer" push -q origin main
unrelated_plan=$(run_sync "$per_host_home" --host mac-test-pilot --plan)
printf '%s\n' "$unrelated_plan" | grep -F 'action=pull' >/dev/null ||
    fail "unrelated per-host advance was not a state refresh"
run_sync "$per_host_home" --host mac-test-pilot --apply >/dev/null
cmp -s "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before" ||
    fail "unrelated per-host advance changed selected live SSH bytes"

finalize_plan=$(run_sync "$per_host_home" --host mac-test-pilot \
    --finalize-per-host --plan)
printf '%s\n' "$finalize_plan" | grep -F \
    'action=finalize-per-host apply=not-requested' >/dev/null ||
    fail "per-host finalization plan"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$per_host_origin/hooks/pre-receive"
chmod 755 "$per_host_origin/hooks/pre-receive"
if run_sync "$per_host_home" --host mac-test-pilot \
    --finalize-per-host --apply >"$TEMP_DIR/finalize-push-failure.out" 2>&1; then
    fail "injected per-host finalization push failure succeeded"
fi
grep -F 'class=auth-failed agreement=no' \
    "$TEMP_DIR/finalize-push-failure.out" >/dev/null ||
    fail "per-host finalization push failure classification"
cmp -s "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before" ||
    fail "per-host finalization push failure changed live SSH bytes"
unlink "$per_host_origin/hooks/pre-receive"
run_sync "$per_host_home" --host mac-test-pilot \
    --finalize-per-host --apply >/dev/null || fail "per-host finalization retry"
[ ! -e "$per_host_private/ssh_config" ] ||
    fail "per-host finalization retained legacy payload"
grep -F -x 'minimum_engine_schema=3' \
    "$per_host_private/companion.conf" >/dev/null ||
    fail "per-host finalization did not raise engine contract"
HOME="$per_host_home" HARNESS_ROOT="$public" \
    "$public/libexec/harness-macos-profile" --host mac-test-pilot >/dev/null ||
    fail "final per-host profile validation"
run_sync "$per_host_home" --host mac-test-pilot --apply >/dev/null ||
    fail "selected state refresh after finalization"
[ "$(run_sync "$per_host_home" --host mac-test-pilot --plan)" = \
    'MACOS_SSH_SYNC class=current agreement=yes action=none' ] ||
    fail "final per-host no-op"
cmp -s "$per_host_home/.ssh/config" "$TEMP_DIR/per-host-live-before" ||
    fail "per-host finalization changed live SSH bytes"

printf '%s\n' 'Host per-host-local.invalid' '    HostName 192.0.2.81' \
    >"$per_host_home/.ssh/config"
chmod 600 "$per_host_home/.ssh/config"
per_host_publish=$(run_sync "$per_host_home" --host mac-test-pilot --apply)
printf '%s\n' "$per_host_publish" | grep -F 'action=applied' >/dev/null ||
    fail "final per-host local publication"
git -C "$per_host_writer" pull -q --ff-only
cmp -s "$per_host_home/.ssh/config" \
    "$per_host_writer/ssh/mac-test-pilot.conf" ||
    fail "final per-host selected publication mismatch"
[ ! -e "$per_host_writer/ssh_config" ] ||
    fail "final per-host publication recreated legacy payload"
printf '%s\n' 'Host per-host-remote.invalid' '    HostName 192.0.2.82' \
    >"$per_host_writer/ssh/mac-test-pilot.conf"
chmod 600 "$per_host_writer/ssh/mac-test-pilot.conf"
git -C "$per_host_writer" add ssh/mac-test-pilot.conf
git -C "$per_host_writer" commit -q -m 'synthetic selected per-host advance'
git -C "$per_host_writer" push -q origin main
run_sync "$per_host_home" --host mac-test-pilot --apply >/dev/null ||
    fail "final per-host remote application"
cmp -s "$per_host_home/.ssh/config" \
    "$per_host_writer/ssh/mac-test-pilot.conf" ||
    fail "final per-host selected remote mismatch"

# shellcheck disable=SC2034
IFS='|' read -r incomplete_final_home _incomplete_private _incomplete_writer _incomplete_origin <<EOF
$(setup_home incomplete-final)
EOF
run_sync "$incomplete_final_home" --host mac-test-pilot --seed --apply >/dev/null
if run_sync "$incomplete_final_home" --host mac-test-pilot \
    --finalize-per-host --plan >"$TEMP_DIR/incomplete-final.out" 2>&1; then
    fail "incomplete per-host finalization accepted"
fi
grep -F 'class=invalid agreement=no' "$TEMP_DIR/incomplete-final.out" >/dev/null ||
    fail "incomplete per-host finalization classification"

echo "personal macOS SSH-sync tests passed"
