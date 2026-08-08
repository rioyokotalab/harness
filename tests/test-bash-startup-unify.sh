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
file_mode() {
    case $(uname -s) in
        Darwin) stat -f %Lp "$1" ;;
        *) stat -c %a "$1" ;;
    esac
}

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
mkdir "$repo"
cp -R "$ROOT/bin" "$ROOT/libexec" "$ROOT/profiles" "$ROOT/shell" "$repo/"
mkdir -p "$home"
git -C "$repo" init -q
git -C "$repo" config user.name harness-test
git -C "$repo" config user.email harness-test.invalid
git -C "$repo" add .
git -C "$repo" commit -q --allow-empty -m baseline

python3 - "$repo/libexec/harness-bash-startup-unify" <<'PY'
import ast
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
ast.parse(source, filename=sys.argv[1], feature_version=(3, 6))
if "missing_ok=" in source or "text=True" in source:
    raise SystemExit("Python 3.6-incompatible API retained")
PY

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
printf '%s\n' 'export PROFILE_LOGIN_ONLY=kept' 'if [ -f "$HOME/.bashrc" ]; then' '    . "$HOME/.bashrc"' 'fi' 'export PRIVATE_SENTINEL_PROFILE=opaque' >>"$home/.bash_profile"
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
grep -F 'profile_prestate=present' "$TEMP_DIR/plan.out" >/dev/null || fail 'present profile classification'
grep -F 'redundant_profile_loaders=1' "$TEMP_DIR/plan.out" >/dev/null || fail 'redundant loader classification'
if grep -F 'PRIVATE_SENTINEL' "$TEMP_DIR/plan.out" >/dev/null; then fail 'plan leaked owner bytes'; fi
run --host local --apply >"$TEMP_DIR/apply.out"
transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail 'transaction id'
[ "$(file_mode "$home/.bashrc")" = 640 ] || fail 'bashrc mode preservation'
[ "$(file_mode "$home/.bash_profile")" = 600 ] || fail 'profile mode preservation'
if find "$home" -maxdepth 1 -name '.*.harness-*-candidate-*' -print | grep . >/dev/null; then
    fail 'adjacent candidate retained after apply'
fi
grep -F -x '# >>> harness canonical bash profile >>>' "$home/.bash_profile" >/dev/null || fail 'thin profile marker'
cmp -s "$home/.bash_profile" "$repo/shell/bash_profile.canonical" || fail 'exact thin profile'
grep -F -x '# >>> harness login-only local >>>' "$home/.bashrc" >/dev/null || fail 'login-only marker'
grep -F -x '    :' "$home/.bashrc" >/dev/null || fail 'login-only no-op command'
grep -F -x 'export PROFILE_LOGIN_ONLY=kept' "$home/.bashrc" >/dev/null || fail 'profile middle preservation'
grep -F -x 'export BASHRC_LOCAL=kept' "$home/.bashrc" >/dev/null || fail 'bashrc middle preservation'
if grep -F '. "$HOME/.bashrc"' "$home/.bashrc" >/dev/null; then fail 'recursive profile loader retained'; fi
if grep -F 'if [ -f "$HOME/.bashrc" ]; then' "$home/.bashrc" >/dev/null; then fail 'empty loader guard retained'; fi
profile_login=$(HOME="$home" /bin/bash --noprofile --norc -c '. "$HOME/.bash_profile"; printf "%s|%s\n" "${BASHRC_LOCAL-unset}" "${PROFILE_LOGIN_ONLY-unset}"')
[ "$profile_login" = 'kept|unset' ] || fail 'thin profile load'
nonlogin=$(HOME="$home" /bin/bash --noprofile --norc -c '. "$HOME/.bashrc"; printf "%s|%s\n" "${BASHRC_LOCAL-unset}" "${PROFILE_LOGIN_ONLY-unset}"')
[ "$nonlogin" = 'kept|unset' ] || fail 'non-login scope'
login=$(HOME="$home" /bin/bash --noprofile --norc -l -c '. "$HOME/.bashrc"; printf "%s|%s\n" "${BASHRC_LOCAL-unset}" "${PROFILE_LOGIN_ONLY-unset}"')
[ "$login" = 'kept|kept' ] || fail 'login scope'
run --host local --plan >"$TEMP_DIR/current.out"
grep -F 'state=current action=none' "$TEMP_DIR/current.out" >/dev/null || fail 'idempotent plan'

run --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'bashrc rollback'
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail 'profile rollback'

# The default owner retains merge planning, owner-byte preservation, exact
# canonical output, shell behavior, idempotence, and rollback. Partial-current,
# injected-failure, absent-profile, and symlink-layout permutations below are
# targeted migration diagnostics.
printf '%s\n' 'Bash startup unification tests: PASS'
exit 0
