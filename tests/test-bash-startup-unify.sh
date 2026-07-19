#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-bash-unify-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
        >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
cp -R "$ROOT" "$repo"
mkdir -p "$home"
git -C "$repo" init -q
git -C "$repo" config user.name harness-test
git -C "$repo" config user.email harness-test.invalid
git -C "$repo" add .
git -C "$repo" commit -q --allow-empty -m baseline

prefix=$TEMP_DIR/prefix
cat >"$prefix" <<'EOF'
# >>> harness early managed >>>
HARNESS_LOGICAL_HOST=local
export HARNESS_LOGICAL_HOST
if [ -r "$HOME/harness/shell/early-cache.sh" ]; then
    . "$HOME/harness/shell/early-cache.sh"
fi
# <<< harness early managed <<<
EOF
cat "$prefix" >"$home/.bashrc"
printf '%s\n' 'export BASHRC_LOCAL=kept' 'export PRIVATE_SENTINEL_BASHRC=opaque' >>"$home/.bashrc"
cat "$repo/shell/bashrc.local.block" >>"$home/.bashrc"
cat "$prefix" >"$home/.bash_profile"
printf '%s\n' 'export PROFILE_LOGIN_ONLY=kept' 'export PRIVATE_SENTINEL_PROFILE=opaque' >>"$home/.bash_profile"
cat "$repo/shell/bash_profile.local.block" >>"$home/.bash_profile"
chmod 640 "$home/.bashrc"
chmod 600 "$home/.bash_profile"
cp "$home/.bashrc" "$TEMP_DIR/bashrc.before"
cp "$home/.bash_profile" "$TEMP_DIR/profile.before"

run() {
    HOME="$home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$repo/bin/harness" bash-startup-unify "$@"
}

run --host local --plan >"$TEMP_DIR/plan.out"
grep -F 'state=merge' "$TEMP_DIR/plan.out" >/dev/null || fail 'merge plan'
if grep -F 'PRIVATE_SENTINEL' "$TEMP_DIR/plan.out" >/dev/null; then fail 'plan leaked owner bytes'; fi
run --host local --apply >"$TEMP_DIR/apply.out"
transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail 'transaction id'
[ "$(stat -f %Lp "$home/.bashrc" 2>/dev/null || stat -c %a "$home/.bashrc")" = 640 ] || fail 'bashrc mode preservation'
[ "$(stat -f %Lp "$home/.bash_profile" 2>/dev/null || stat -c %a "$home/.bash_profile")" = 600 ] || fail 'profile mode preservation'
grep -F -x '# >>> harness canonical bash profile >>>' "$home/.bash_profile" >/dev/null || fail 'thin profile marker'
cmp -s "$home/.bash_profile" "$repo/shell/bash_profile.canonical" || fail 'exact thin profile'
grep -F -x '# >>> harness login-only local >>>' "$home/.bashrc" >/dev/null || fail 'login-only marker'
grep -F -x 'export PROFILE_LOGIN_ONLY=kept' "$home/.bashrc" >/dev/null || fail 'profile middle preservation'
grep -F -x 'export BASHRC_LOCAL=kept' "$home/.bashrc" >/dev/null || fail 'bashrc middle preservation'
nonlogin=$(HOME="$home" /bin/bash --noprofile --norc -c '. "$HOME/.bashrc"; printf "%s|%s\n" "${BASHRC_LOCAL-unset}" "${PROFILE_LOGIN_ONLY-unset}"')
[ "$nonlogin" = 'kept|unset' ] || fail 'non-login scope'
login=$(HOME="$home" /bin/bash --noprofile --norc -l -c '. "$HOME/.bashrc"; printf "%s|%s\n" "${BASHRC_LOCAL-unset}" "${PROFILE_LOGIN_ONLY-unset}"')
[ "$login" = 'kept|kept' ] || fail 'login scope'
run --host local --plan >"$TEMP_DIR/current.out"
grep -F 'state=current action=none' "$TEMP_DIR/current.out" >/dev/null || fail 'idempotent plan'

run --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'bashrc rollback'
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail 'profile rollback'

if HOME="$home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 HARNESS_TEST_FAIL_AFTER=1 \
    "$repo/bin/harness" bash-startup-unify --host local --apply >"$TEMP_DIR/injected.out" 2>&1; then
    fail 'injected replacement failure accepted'
fi
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'injected bashrc recovery'
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail 'injected profile recovery'

run --host local --apply >"$TEMP_DIR/reapply.out"
changed=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/reapply.out")
printf '%s\n' '# later owner edit' >>"$home/.bashrc"
if run --rollback "$changed" >"$TEMP_DIR/changed.out" 2>&1; then fail 'rollback accepted changed canonical bashrc'; fi
grep -F -x '# later owner edit' "$home/.bashrc" >/dev/null || fail 'changed rollback damaged owner edit'

printf '%s\n' 'Bash startup unification tests: PASS'
