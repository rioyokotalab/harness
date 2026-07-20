#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
COMMAND=$ROOT/libexec/harness-macos-login-shell
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-login-shell-test.XXXXXX")
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
        echo "FAIL: guarded personal-Mac login-shell cleanup" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/profiles/personal-macos"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$PUBLIC/profiles/personal-macos/base.conf"
cp "$ROOT/profiles/personal-macos/formula-policy-v2.conf" \
    "$PUBLIC/profiles/personal-macos/formula-policy-v2.conf"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public login-shell fixture'

home=$TEMP_DIR/home
private=$home/.config/harness/private
mkdir -p "$private/hosts"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" \
    "$private/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
    "$private/hosts/mac-test-pilot.conf"
chmod 700 "$home" "$home/.config" "$home/.config/harness" "$private" \
    "$private/hosts"
chmod 600 "$private/companion.conf" "$private/hosts/mac-test-pilot.conf"
git -C "$private" init -q -b main
git -C "$private" config user.name mac-test
git -C "$private" config user.email mac-test.invalid
git -C "$private" add companion.conf hosts/mac-test-pilot.conf
git -C "$private" commit -q -m 'synthetic private login-shell fixture'
chmod 700 "$private/.git"

fake_bin=$TEMP_DIR/fake-bin
fake_prefix=$TEMP_DIR/homebrew
formula_prefix=$fake_prefix/opt/bash
cellar_prefix=$fake_prefix/Cellar/bash/5.3.0
mkdir -p "$fake_bin" "$fake_prefix/bin" "$fake_prefix/opt" \
    "$cellar_prefix/bin"
cat >"$fake_prefix/bin/brew" <<'EOF'
#!/bin/sh
case "$1:${2:-}" in
    --prefix:) printf '%s\n' "$FAKE_BREW_PREFIX" ;;
    --prefix:bash) printf '%s\n' "$FAKE_BASH_PREFIX" ;;
    list:--formula)
        [ "$3:$4" = --versions:bash ] || exit 2
        echo 'bash 5.3.0'
        ;;
    *) exit 2 ;;
esac
EOF
cat >"$cellar_prefix/bin/bash" <<'EOF'
#!/bin/sh
exit 0
EOF
ln -s "$cellar_prefix" "$formula_prefix"
ln -s "$formula_prefix/bin/bash" "$fake_prefix/bin/bash"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in -s) echo Darwin ;; -m) echo arm64 ;; *) exit 2 ;; esac
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
if [ "$1" = -f ]; then
    format=$2
    shift 2
    [ "${1:-}" = -- ] && shift
    if [ "$1" = "$TEST_SHELLS_FILE" ]; then
        case "$format" in %u) echo 0 ;; %Lp) echo 644 ;; %l) echo 1 ;; %g) echo 0 ;; *) exit 2 ;; esac
        exit 0
    fi
    case "$format" in %u) native=%u ;; %Lp) native=%a ;; %l) native=%h ;; %g) native=%g ;; *) exit 2 ;; esac
    case "$REAL_PLATFORM" in
        Darwin)
            case "$native" in %a) native=%Lp ;; %h) native=%l ;; esac
            exec "$REAL_STAT" -f "$native" "$1"
            ;;
        *) exec "$REAL_STAT" -c "$native" -- "$1" ;;
    esac
fi
exec "$REAL_STAT" "$@"
EOF
cat >"$fake_bin/dscl" <<'EOF'
#!/bin/sh
[ "$1:$2:$4" = .:-read:UserShell ] || exit 2
printf 'UserShell: %s\n' "$(sed -n '1p' "$TEST_ACCOUNT_STATE")"
EOF
cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
[ "$1" = -n ] || exit 2
shift
case "$1" in
    /usr/bin/true) exit 0 ;;
    /usr/bin/install)
        [ "$2:$3:$4:$5:$6:$7" = -o:0:-g:0:-m:644 ] || exit 2
        [ "$9" = "$TEST_SHELLS_FILE" ] || exit 2
        cp "$8" "$9"
        chmod 644 "$9"
        ;;
    /usr/bin/chsh)
        [ "$2" = -s ] || exit 2
        printf '%s\n' "$3" >"$TEST_ACCOUNT_STATE"
        ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_prefix/bin/brew" "$cellar_prefix/bin/bash" \
    "$fake_bin/uname" "$fake_bin/stat" "$fake_bin/dscl" "$fake_bin/sudo"

shells_file=$TEMP_DIR/shells
account_state=$TEMP_DIR/account-shell
printf '%s\n' /bin/bash /bin/zsh >"$shells_file"
chmod 644 "$shells_file"
printf '%s\n' /bin/bash >"$account_state"
chmod 600 "$account_state"
cp "$shells_file" "$TEMP_DIR/shells.before"
real_stat=$(command -v stat)
real_platform=$(uname -s)

run_command() {
    HOME="$home" HARNESS_ROOT="$PUBLIC" HARNESS_TEST_ALLOW_NONMAIN=1 \
        HARNESS_TEST_SHELLS_FILE="$shells_file" TEST_SHELLS_FILE="$shells_file" \
        TEST_ACCOUNT_STATE="$account_state" FAKE_BREW_PREFIX="$fake_prefix" \
        FAKE_BASH_PREFIX="$formula_prefix" REAL_STAT="$real_stat" \
        REAL_PLATFORM="$real_platform" PATH="$fake_prefix/bin:$fake_bin:/usr/bin:/bin" \
        "$COMMAND" "$@"
}

run_command --host mac-test-pilot --plan >"$TEMP_DIR/plan.out"
grep -F -x \
    'MACOS_LOGIN_SHELL mode=plan registry=add account=change target=managed-homebrew-bash' \
    "$TEMP_DIR/plan.out" >/dev/null || fail "login-shell plan"
grep -F -x 'END macos_login_shell apply=not-requested activation=none' \
    "$TEMP_DIR/plan.out" >/dev/null || fail "login-shell plan end"

run_command --host mac-test-pilot --apply >"$TEMP_DIR/apply.out"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "login-shell transaction identifier"
[ "$(sed -n '1p' "$account_state")" = "$fake_prefix/bin/bash" ] ||
    fail "account shell apply"
[ "$(grep -F -x -c "$fake_prefix/bin/bash" "$shells_file")" -eq 1 ] ||
    fail "shell registry apply"
run_command --host mac-test-pilot --apply >"$TEMP_DIR/noop.out"
grep -F -x 'END macos_login_shell action=none activation=unchanged' \
    "$TEMP_DIR/noop.out" >/dev/null || fail "login-shell no-op"

run_command --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$shells_file" "$TEMP_DIR/shells.before" || fail "shell registry rollback"
[ "$(sed -n '1p' "$account_state")" = /bin/bash ] || fail "account shell rollback"

run_command --host mac-test-pilot --apply >"$TEMP_DIR/reapply.out"
reapply_transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/reapply.out")
[ -n "$reapply_transaction" ] || fail "login-shell reapply transaction"
printf '%s\n' '# owner drift' >>"$shells_file"
cp "$shells_file" "$TEMP_DIR/shells.drifted"
if run_command --rollback "$reapply_transaction" >"$TEMP_DIR/drift.out" 2>&1; then
    fail "login-shell rollback accepted changed registry"
fi
grep -F 'rollback blocked by changed state' "$TEMP_DIR/drift.out" >/dev/null ||
    fail "login-shell changed-state refusal"
cmp -s "$shells_file" "$TEMP_DIR/shells.drifted" ||
    fail "login-shell refusal changed registry"

echo 'personal macOS login-shell tests: PASS'
