#!/bin/sh
set -eu
umask 077

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-config-sync-test.XXXXXX")
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
MACOS_TEST_REAL_TMUX=$(command -v tmux) ||
    fail "tmux is unavailable for config-sync tests"
export MACOS_TEST_REAL_TMUX
case $(/usr/bin/uname -s) in
    Darwin) MACOS_TEST_HOST_STAT_STYLE=darwin ;;
    *) MACOS_TEST_HOST_STAT_STYLE=gnu ;;
esac
export MACOS_TEST_HOST_STAT_STYLE

fake_bin=$TEMP_DIR/fake-bin
mkdir "$fake_bin"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
[ -z "${MACOS_TEST_UNAME_LOG:-}" ] || printf 'probe\n' >>"$MACOS_TEST_UNAME_LOG"
echo Darwin
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    case "$2" in %u) format=%u ;; %Lp) format=%a ;; %l) format=%h ;; *) exit 2 ;; esac
    shift 2
    [ "${1:-}" != -- ] || shift
    case "$MACOS_TEST_HOST_STAT_STYLE" in
        darwin)
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
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] && [ "$last" = "$MACOS_TEST_FAIL_DEST" ] &&
   [ ! -e "${MACOS_TEST_FAIL_MARKER:-}" ]; then
    : >"$MACOS_TEST_FAIL_MARKER"
    exit 42
fi
exec /bin/mv "$@"
EOF
cat >"$fake_bin/vim" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
printf '%s\n' 'export HARNESS_SYNTHETIC_SHARED_BASH=pilot' >"$last"
EOF
cat >"$fake_bin/tmux" <<'EOF'
#!/bin/sh
last=
source_file=0
for argument do
    [ "$argument" = source-file ] && source_file=1
    last=$argument
done
if [ "$source_file" -eq 1 ] && [ ! -s "$last" ]; then
    echo 'synthetic tmux rejects an empty source-file' >&2
    exit 1
fi
exec "$MACOS_TEST_REAL_TMUX" "$@"
EOF
chmod 755 "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/mv" \
    "$fake_bin/vim" "$fake_bin/tmux"

stat_probe_log=$TEMP_DIR/stat-kernel-probes
: >"$stat_probe_log"
MACOS_TEST_UNAME_LOG="$stat_probe_log" PATH="$fake_bin:/usr/bin:/bin" \
    sh -c '. "$1"; macos_stat_owner "$2" >/dev/null; macos_stat_mode "$2" >/dev/null; macos_stat_links "$2" >/dev/null' \
    _ "$ROOT/libexec/harness-macos-common" "$ROOT/AGENTS.md"
[ "$(wc -l <"$stat_probe_log" | tr -d ' ')" = 1 ] ||
    fail "Mac stat helpers repeated the immutable kernel probe"

configure_identity() {
    git -C "$1" config user.name mac-test
    git -C "$1" config user.email mac-test.invalid
}

public=$TEMP_DIR/public
public_origin=$TEMP_DIR/public-origin.git
mkdir -p "$public/libexec" "$public/profiles/personal-macos" "$public/shell"
cp -p "$ROOT/libexec/harness-common" "$ROOT/libexec/harness-macos-common" \
    "$ROOT/libexec/harness-macos-profile" \
    "$ROOT/libexec/harness-macos-config-sync" "$public/libexec/"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$public/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v4.conf" \
    "$public/profiles/personal-macos/formula-policy-v4.conf"
cp "$ROOT/shell/personal-macos-startup.block" "$public/shell/"
git -C "$public" init -q -b main
configure_identity "$public"
git -C "$public" add libexec profiles shell
git -C "$public" commit -q -m 'synthetic public config sync engine'
git init -q --bare -b main "$public_origin"
git -C "$public" remote add origin "$public_origin"
git -C "$public" push -q -u origin main
chmod 700 "$public/.git"
SYNC=$public/libexec/harness-macos-config-sync

setup_home() {
    name=$1
    home=$TEMP_DIR/$name-home
    origin=$TEMP_DIR/$name-origin.git
    writer=$TEMP_DIR/$name-writer
    private=$home/.config/harness/private
    managed=$home/.config/harness/managed
    mkdir -p "$private/hosts" "$home/.ssh" "$managed"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
        "$private/companion.conf"
    cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    chmod 600 "$private/companion.conf" "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    configure_identity "$private"
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private pre-adoption'
    git init -q --bare -b main "$origin"
    git -C "$private" remote add origin "$origin"
    git -C "$private" push -q -u origin main
    configure_identity "$private"
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
case ${HARNESS_TEST_CASE:-plan} in
    plan) ;;
    apply) ;;
    *) fail "unknown essential config-sync case" ;;
esac

if [ "${HARNESS_TEST_CASE:-plan}" = plan ]; then
seed_required=$(run_sync "$home" --host mac-test-pilot --plan)
[ "$seed_required" = \
    'MACOS_CONFIG_SYNC class=current agreement=no action=seed-required' ] ||
    fail "first-adoption seed requirement"
seed_plan=$(run_sync "$home" --host mac-test-pilot --seed --plan)
printf '%s\n' "$seed_plan" | grep -F 'action=seed apply=not-requested' >/dev/null ||
    fail "bundle seed plan"
git -C "$private" cat-file -e HEAD:ssh_config 2>/dev/null &&
    fail "seed plan changed private repository"
echo 'personal macOS config sync plan contract: PASS'
exit 0
fi
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

echo 'personal macOS config sync apply contract: PASS'
exit 0
