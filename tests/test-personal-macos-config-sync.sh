#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-config-sync-test.XXXXXX")
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
        echo "FAIL: guarded Mac config-sync cleanup" >&2
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
    case "$2" in %u) format=%u ;; %Lp) format=%a ;; %l) format=%h ;; *) exit 2 ;; esac
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
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] && [ "$last" = "$MACOS_TEST_FAIL_DEST" ] &&
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
    "$ROOT/libexec/harness-macos-config-sync" "$public/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$public/profiles/personal-macos/base.conf"
git -C "$public" init -q -b main
configure_identity "$public"
git -C "$public" add libexec profiles
git -C "$public" commit -q -m 'synthetic public config sync engine'
chmod 700 "$public/.git"
SYNC=$public/libexec/harness-macos-config-sync

setup_home() {
    name=$1
    home=$TEMP_DIR/$name-home
    source=$TEMP_DIR/$name-source
    origin=$TEMP_DIR/$name-origin.git
    writer=$TEMP_DIR/$name-writer
    private=$home/.config/harness/private
    managed=$home/.config/harness/managed
    mkdir -p "$source/hosts" "$home/.config/harness" "$home/.ssh" "$managed"
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
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/ssh_config" "$home/.ssh/config"
    cp "$ROOT/tests/fixtures/personal-macos/private-v2/bashrc" \
        "$managed/personal-macos-private.bash"
    cp "$ROOT/tests/fixtures/personal-macos/private-v2/tmux.conf" "$home/.tmux.conf"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" "$managed" \
        "$home/.ssh" "$private" "$private/.git" "$private/hosts"
    chmod 600 "$home/.ssh/config" "$managed/personal-macos-private.bash" \
        "$home/.tmux.conf" "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    printf '%s|%s|%s|%s\n' "$home" "$private" "$writer" "$origin"
}

run_sync() {
    test_home=$1
    shift
    HOME="$test_home" HARNESS_ROOT="$public" PATH="$fake_bin:/usr/bin:/bin" \
        "$SYNC" "$@"
}

IFS='|' read -r home private writer origin <<EOF
$(setup_home primary)
EOF
seed_required=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$seed_required" = \
    'MACOS_CONFIG_SYNC class=current agreement=no action=seed-required' ] ||
    fail "first-adoption seed requirement"
seed_plan=$(run_sync "$home" --host mac-test-pilot --seed --plan)
printf '%s\n' "$seed_plan" | grep -F 'action=seed apply=not-requested' >/dev/null ||
    fail "bundle seed plan"
git -C "$private" cat-file -e HEAD:ssh_config 2>/dev/null &&
    fail "seed plan changed private repository"
seed_apply=$(run_sync "$home" --host mac-test-pilot --seed --apply)
printf '%s\n' "$seed_apply" | grep -F 'action=applied' >/dev/null ||
    fail "bundle seed apply"
for payload in ssh_config bashrc tmux.conf; do
    git -C "$private" cat-file -e "HEAD:$payload" 2>/dev/null ||
        fail "seed omitted $payload"
done
grep -F -x 'minimum_engine_schema=2' "$private/companion.conf" >/dev/null ||
    fail "seed omitted engine gate"
cmp -s "$home/.ssh/config" "$private/ssh_config" || fail "SSH seed mismatch"
cmp -s "$home/.config/harness/managed/personal-macos-private.bash" \
    "$private/bashrc" || fail "Bash seed mismatch"
cmp -s "$home/.tmux.conf" "$private/tmux.conf" || fail "tmux seed mismatch"
[ -f "$home/.local/state/harness/personal-macos/config-sync.conf" ] ||
    fail "seed omitted bundle state"

equal_output=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$equal_output" = \
    'MACOS_CONFIG_SYNC class=current agreement=yes action=none activation=unchanged' ] ||
    fail "bundle equal no-op"
loader_value=$(HOME="$home" /bin/bash --noprofile --norc -ic \
    '. "$1"; printf "%s" "$HARNESS_SYNTHETIC_SHARED_BASH"' _ \
    "$ROOT/shell/personal-macos.bash" 2>/dev/null)
[ "$loader_value" = loaded ] || fail "managed Bash did not load private fragment"

bash_sentinel=PRIVATE_BASH_LOCAL_ONLY_SENTINEL
printf 'export HARNESS_SYNTHETIC_SHARED_BASH=%s\n' "$bash_sentinel" \
    >"$home/.config/harness/managed/personal-macos-private.bash"
chmod 600 "$home/.config/harness/managed/personal-macos-private.bash"
publish_plan=$(run_sync "$home" --host mac-test-pilot --plan)
printf '%s\n' "$publish_plan" | grep -F 'action=publish' >/dev/null ||
    fail "local-only publish plan"
case "$publish_plan" in *"$bash_sentinel"*) fail "plan leaked Bash content" ;; esac
run_sync "$home" --host mac-test-pilot --apply >/dev/null || fail "local publish"
git -C "$writer" pull -q --ff-only
cmp -s "$home/.config/harness/managed/personal-macos-private.bash" \
    "$writer/bashrc" || fail "published Bash mismatch"

cp "$home/.tmux.conf" "$TEMP_DIR/tmux-before-remote"
printf '%s\n' 'set -g mouse off' >"$writer/tmux.conf"
chmod 600 "$writer/tmux.conf"
git -C "$writer" add tmux.conf
git -C "$writer" commit -q -m 'synthetic remote tmux edit'
git -C "$writer" push -q origin main
remote_apply=$(run_sync "$home" --host mac-test-pilot --apply)
cmp -s "$home/.tmux.conf" "$writer/tmux.conf" || fail "remote tmux mismatch"
transaction=$(printf '%s\n' "$remote_apply" |
    sed -n 's/.* transaction=\([^ ]*\).*/\1/p')
[ -n "$transaction" ] || fail "remote transaction identifier"
cp "$home/.ssh/config" "$TEMP_DIR/rollback-current-ssh"
cp "$home/.config/harness/managed/personal-macos-private.bash" \
    "$TEMP_DIR/rollback-current-bash"
cp "$home/.tmux.conf" "$TEMP_DIR/rollback-current-tmux"
printf '%s\n' '# later owner change' \
    >>"$home/.config/harness/managed/personal-macos-private.bash"
if run_sync "$home" --rollback "$transaction" \
    >"$TEMP_DIR/rollback-changed.out" 2>&1; then
    fail "changed bundle rollback accepted"
fi
cmp -s "$home/.ssh/config" "$TEMP_DIR/rollback-current-ssh" ||
    fail "refused rollback partially changed SSH"
cmp -s "$home/.tmux.conf" "$TEMP_DIR/rollback-current-tmux" ||
    fail "refused rollback partially changed tmux"
cp "$TEMP_DIR/rollback-current-bash" \
    "$home/.config/harness/managed/personal-macos-private.bash"
chmod 600 "$home/.config/harness/managed/personal-macos-private.bash"
run_sync "$home" --rollback "$transaction" >/dev/null || fail "exact rollback"
cmp -s "$home/.tmux.conf" "$TEMP_DIR/tmux-before-remote" ||
    fail "rollback did not restore tmux"
run_sync "$home" --host mac-test-pilot --apply >/dev/null || fail "reapply"

printf '%s\n' 'set -g status-left local-conflict' >"$home/.tmux.conf"
chmod 600 "$home/.tmux.conf"
git -C "$writer" pull -q --ff-only
printf '%s\n' 'set -g status-left remote-conflict' >"$writer/tmux.conf"
chmod 600 "$writer/tmux.conf"
git -C "$writer" add tmux.conf
git -C "$writer" commit -q -m 'synthetic conflicting edit'
git -C "$writer" push -q origin main
if run_sync "$home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/diverged.out" 2>&1; then
    fail "concurrent divergence accepted"
fi
grep -F 'class=diverged agreement=no' "$TEMP_DIR/diverged.out" >/dev/null ||
    fail "divergence classification"
grep -F 'local-conflict' "$home/.tmux.conf" >/dev/null ||
    fail "divergence changed local tmux"

# shellcheck disable=SC2034
IFS='|' read -r private_fail_home private_fail_repo private_fail_writer \
    private_fail_origin <<EOF
$(setup_home private-failure)
EOF
private_fail_marker=$TEMP_DIR/private-failed-once
if HOME="$private_fail_home" HARNESS_ROOT="$public" \
    PATH="$fake_bin:/usr/bin:/bin" \
    MACOS_TEST_FAIL_DEST="$private_fail_repo/tmux.conf" \
    MACOS_TEST_FAIL_MARKER="$private_fail_marker" "$SYNC" \
    --host mac-test-pilot --seed --apply \
    >"$TEMP_DIR/private-failure.out" 2>&1; then
    fail "injected private bundle replacement failure succeeded"
fi
[ -z "$(git -C "$private_fail_repo" status --porcelain --untracked-files=normal)" ] ||
    fail "private replacement failure left dirty companion"
[ ! -e "$private_fail_repo/ssh_config" ] &&
    [ ! -e "$private_fail_repo/bashrc" ] &&
    [ ! -e "$private_fail_repo/tmux.conf" ] ||
    fail "private replacement failure left partial payloads"
grep -F -x 'minimum_engine_schema=1' \
    "$private_fail_repo/companion.conf" >/dev/null ||
    fail "private replacement failure changed compatibility contract"
run_sync "$private_fail_home" --host mac-test-pilot --seed --apply >/dev/null ||
    fail "retry after private bundle replacement failure"

# shellcheck disable=SC2034
IFS='|' read -r commit_fail_home commit_fail_repo commit_fail_writer \
    commit_fail_origin <<EOF
$(setup_home commit-failure)
EOF
git -C "$commit_fail_repo" config user.name ''
git -C "$commit_fail_repo" config user.email ''
if run_sync "$commit_fail_home" --host mac-test-pilot --seed --apply \
    >"$TEMP_DIR/commit-failure.out" 2>&1; then
    fail "private bundle commit failure succeeded"
fi
[ -z "$(git -C "$commit_fail_repo" status --porcelain --untracked-files=normal)" ] ||
    fail "private commit failure left dirty companion"
[ ! -e "$commit_fail_repo/ssh_config" ] &&
    [ ! -e "$commit_fail_repo/bashrc" ] &&
    [ ! -e "$commit_fail_repo/tmux.conf" ] ||
    fail "private commit failure left partial payloads"
grep -F -x 'minimum_engine_schema=1' \
    "$commit_fail_repo/companion.conf" >/dev/null ||
    fail "private commit failure changed compatibility contract"

# shellcheck disable=SC2034
IFS='|' read -r invalid_home invalid_private invalid_writer invalid_origin <<EOF
$(setup_home invalid)
EOF
printf '%s\n' 'if then' \
    >"$invalid_home/.config/harness/managed/personal-macos-private.bash"
chmod 600 "$invalid_home/.config/harness/managed/personal-macos-private.bash"
if run_sync "$invalid_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/invalid.out" 2>&1; then
    fail "invalid Bash accepted"
fi
grep -F 'Bash configuration grammar is invalid' "$TEMP_DIR/invalid.out" >/dev/null ||
    fail "invalid Bash refusal"
printf '%s\n' 'export API_TOKEN=synthetic-value' \
    >"$invalid_home/.config/harness/managed/personal-macos-private.bash"
chmod 600 "$invalid_home/.config/harness/managed/personal-macos-private.bash"
if run_sync "$invalid_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/credential.out" 2>&1; then
    fail "credential-like Bash assignment accepted"
fi
grep -F 'Bash configuration contains prohibited credential material' \
    "$TEMP_DIR/credential.out" >/dev/null || fail "Bash credential refusal"

# shellcheck disable=SC2034
IFS='|' read -r unsafe_home unsafe_private unsafe_writer unsafe_origin <<EOF
$(setup_home unsafe)
EOF
tmux_side_effect=$TEMP_DIR/tmux-side-effect
printf '%s\n' "run-shell 'touch $tmux_side_effect'" >"$unsafe_home/.tmux.conf"
chmod 600 "$unsafe_home/.tmux.conf"
run_sync "$unsafe_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/nonexecuting-tmux.out" || fail "tmux parse-only validation"
[ ! -e "$tmux_side_effect" ] || fail "tmux validator executed config"
printf '%s\n' 'not-a-tmux-command value' >"$unsafe_home/.tmux.conf"
chmod 600 "$unsafe_home/.tmux.conf"
if run_sync "$unsafe_home" --host mac-test-pilot --seed --plan \
    >"$TEMP_DIR/invalid-tmux.out" 2>&1; then
    fail "invalid tmux command accepted"
fi
grep -F 'tmux configuration grammar is invalid' "$TEMP_DIR/invalid-tmux.out" \
    >/dev/null || fail "invalid tmux grammar refusal"

# shellcheck disable=SC2034
IFS='|' read -r atomic_home atomic_private atomic_writer atomic_origin <<EOF
$(setup_home atomic)
EOF
run_sync "$atomic_home" --host mac-test-pilot --seed --apply >/dev/null
git -C "$atomic_writer" pull -q --ff-only
printf '%s\n' 'Host atomic.invalid' '    HostName 192.0.2.88' \
    >"$atomic_writer/ssh_config"
printf '%s\n' 'export HARNESS_ATOMIC_REMOTE=1' >"$atomic_writer/bashrc"
printf '%s\n' 'set -g status-right atomic' >"$atomic_writer/tmux.conf"
chmod 600 "$atomic_writer/ssh_config" "$atomic_writer/bashrc" \
    "$atomic_writer/tmux.conf"
git -C "$atomic_writer" add ssh_config bashrc tmux.conf
git -C "$atomic_writer" commit -q -m 'synthetic atomic bundle'
git -C "$atomic_writer" push -q origin main
cp "$atomic_home/.ssh/config" "$TEMP_DIR/atomic-ssh-before"
cp "$atomic_home/.config/harness/managed/personal-macos-private.bash" \
    "$TEMP_DIR/atomic-bash-before"
cp "$atomic_home/.tmux.conf" "$TEMP_DIR/atomic-tmux-before"
cp "$atomic_home/.local/state/harness/personal-macos/config-sync.conf" \
    "$TEMP_DIR/atomic-state-before"
marker=$TEMP_DIR/atomic-failed-once
if HOME="$atomic_home" HARNESS_ROOT="$public" PATH="$fake_bin:/usr/bin:/bin" \
    MACOS_TEST_FAIL_DEST="$atomic_home/.tmux.conf" MACOS_TEST_FAIL_MARKER="$marker" \
    "$SYNC" --host mac-test-pilot --apply >"$TEMP_DIR/atomic.out" 2>&1; then
    fail "injected atomic failure succeeded"
fi
cmp -s "$atomic_home/.ssh/config" "$TEMP_DIR/atomic-ssh-before" ||
    fail "atomic failure changed SSH"
cmp -s "$atomic_home/.config/harness/managed/personal-macos-private.bash" \
    "$TEMP_DIR/atomic-bash-before" || fail "atomic failure changed Bash"
cmp -s "$atomic_home/.tmux.conf" "$TEMP_DIR/atomic-tmux-before" ||
    fail "atomic failure changed tmux"
cmp -s "$atomic_home/.local/state/harness/personal-macos/config-sync.conf" \
    "$TEMP_DIR/atomic-state-before" || fail "atomic failure changed state"
run_sync "$atomic_home" --host mac-test-pilot --apply >/dev/null ||
    fail "retry after atomic failure"

adopt_home=$TEMP_DIR/adopt-home
adopt_private=$adopt_home/.config/harness/private
mkdir -p "$adopt_home/.config/harness/managed" "$adopt_home/.ssh"
git clone -q "$atomic_origin" "$adopt_private"
configure_identity "$adopt_private"
chmod 700 "$adopt_home" "$adopt_home/.config" "$adopt_home/.config/harness" \
    "$adopt_home/.config/harness/managed" "$adopt_home/.ssh" \
    "$adopt_private" "$adopt_private/.git" "$adopt_private/hosts"
chmod 600 "$adopt_private/companion.conf" "$adopt_private/ssh_config" \
    "$adopt_private/bashrc" "$adopt_private/tmux.conf" \
    "$adopt_private/hosts/mac-test-pilot.conf"
adopt_required=$(run_sync "$adopt_home" --host mac-test-pilot --plan)
[ "$adopt_required" = \
    'MACOS_CONFIG_SYNC class=current agreement=no action=adopt-required' ] ||
    fail "remote adoption gate"
run_sync "$adopt_home" --host mac-test-pilot --adopt --apply >/dev/null ||
    fail "explicit remote adoption"
cmp -s "$adopt_home/.ssh/config" "$adopt_private/ssh_config" ||
    fail "adopted SSH mismatch"
cmp -s "$adopt_home/.config/harness/managed/personal-macos-private.bash" \
    "$adopt_private/bashrc" || fail "adopted Bash mismatch"
cmp -s "$adopt_home/.tmux.conf" "$adopt_private/tmux.conf" ||
    fail "adopted tmux mismatch"

echo "personal macOS config-sync tests passed"
