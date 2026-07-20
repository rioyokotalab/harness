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
cp -R "$ROOT" "$repo"
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

partial_home=$TEMP_DIR/partial-home
mkdir -p "$partial_home"
cp "$home/.bashrc" "$partial_home/.bashrc"
cp "$TEMP_DIR/profile.before" "$partial_home/.bash_profile"
cp "$partial_home/.bashrc" "$TEMP_DIR/partial-bashrc.before"
cp "$partial_home/.bash_profile" "$TEMP_DIR/partial-profile.before"
run_partial() {
    HOME="$partial_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$repo/bin/harness" bash-startup-unify "$@"
}
run_partial --host local --plan >"$TEMP_DIR/partial.plan"
grep -F 'state=profile-only' "$TEMP_DIR/partial.plan" >/dev/null ||
    fail 'partial-current plan'
run_partial --host local --apply >"$TEMP_DIR/partial.apply"
partial_transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/partial.apply")
[ -n "$partial_transaction" ] || fail 'partial-current transaction'
cmp -s "$partial_home/.bashrc" "$TEMP_DIR/partial-bashrc.before" ||
    fail 'partial-current changed canonical bashrc'
cmp -s "$partial_home/.bash_profile" "$repo/shell/bash_profile.canonical" ||
    fail 'partial-current thin profile'
run_partial --rollback "$partial_transaction" >"$TEMP_DIR/partial.rollback"
cmp -s "$partial_home/.bashrc" "$TEMP_DIR/partial-bashrc.before" ||
    fail 'partial-current bashrc rollback'
cmp -s "$partial_home/.bash_profile" "$TEMP_DIR/partial-profile.before" ||
    fail 'partial-current profile rollback'
awk '!inserted && $0 == "# >>> harness managed >>>" {
        print "export PROFILE_MISMATCH=yes"; inserted=1
    }
    { print }' "$partial_home/.bash_profile" >"$TEMP_DIR/partial-profile.mismatch"
mv "$TEMP_DIR/partial-profile.mismatch" "$partial_home/.bash_profile"
cp "$partial_home/.bash_profile" "$TEMP_DIR/partial-profile.mismatch-before"
if run_partial --host local --plan >"$TEMP_DIR/partial.mismatch" 2>&1; then
    fail 'partial-current accepted mismatched profile middle'
fi
grep -F 'distinct profile local bytes require explicit merge authority' \
    "$TEMP_DIR/partial.mismatch" >/dev/null ||
    fail 'partial-current mismatch refusal'
run_partial --host local --plan --merge-distinct-profile \
    >"$TEMP_DIR/partial.merge-plan"
grep -F 'state=merge-distinct-profile' "$TEMP_DIR/partial.merge-plan" >/dev/null ||
    fail 'partial-current explicit merge plan'
run_partial --host local --apply --merge-distinct-profile \
    >"$TEMP_DIR/partial.merge-apply"
partial_merge_transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/partial.merge-apply")
[ -n "$partial_merge_transaction" ] || fail 'partial-current merge transaction'
grep -F -x 'export PROFILE_LOGIN_ONLY=kept' "$partial_home/.bashrc" >/dev/null ||
    fail 'partial-current prior login body preservation'
grep -F -x 'export PROFILE_MISMATCH=yes' "$partial_home/.bashrc" >/dev/null ||
    fail 'partial-current distinct profile preservation'
run_partial --rollback "$partial_merge_transaction" \
    >"$TEMP_DIR/partial.merge-rollback"
cmp -s "$partial_home/.bash_profile" "$TEMP_DIR/partial-profile.mismatch-before" ||
    fail 'partial-current distinct profile rollback'
cmp -s "$partial_home/.bashrc" "$TEMP_DIR/partial-bashrc.before" ||
    fail 'partial-current distinct bashrc rollback'
cp "$TEMP_DIR/partial-profile.before" "$partial_home/.bash_profile"
run_partial --host local --apply >"$TEMP_DIR/partial.reapply"
run_partial --host local --plan >"$TEMP_DIR/partial.current"
grep -F 'state=current action=none' "$TEMP_DIR/partial.current" >/dev/null ||
    fail 'partial-current reapply'

retire_home=$TEMP_DIR/retire-home
mkdir -p "$retire_home"
cp "$partial_home/.bashrc" "$retire_home/.bashrc"
cp "$partial_home/.bash_profile" "$retire_home/.bash_profile"
awk '$0 == "# >>> harness managed >>>" && !inserted {
        print "# Source .bash_common"
        print "if [ -r \"$HOME/.bash_common\" ]; then"
        print "    source \"$HOME/.bash_common\""
        print "fi"
        inserted=1
    }
    { print }' "$retire_home/.bashrc" >"$TEMP_DIR/retire-bashrc"
mv "$TEMP_DIR/retire-bashrc" "$retire_home/.bashrc"
printf '%s\n' 'export THIN_TAIL_LOGIN_ONLY=kept' >>"$retire_home/.bash_profile"
cp "$retire_home/.bashrc" "$TEMP_DIR/retire-bashrc.before"
cp "$retire_home/.bash_profile" "$TEMP_DIR/retire-profile.before"
run_retire() {
    HOME="$retire_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$repo/bin/harness" bash-startup-unify "$@"
}
run_retire --host local --plan --merge-thin-profile-tail \
    --remove-bash-common-reference >"$TEMP_DIR/retire.plan"
grep -F 'state=merge-thin-profile-tail' "$TEMP_DIR/retire.plan" >/dev/null ||
    fail 'thin profile tail plan'
grep -E 'bash_common_reference_bytes=[1-9][0-9]*' "$TEMP_DIR/retire.plan" >/dev/null ||
    fail 'bash-common reference removal plan'
run_retire --host local --apply --merge-thin-profile-tail \
    --remove-bash-common-reference >"$TEMP_DIR/retire.apply"
retire_transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/retire.apply")
[ -n "$retire_transaction" ] || fail 'thin tail retirement transaction'
cmp -s "$retire_home/.bash_profile" "$repo/shell/bash_profile.canonical" ||
    fail 'thin tail profile convergence'
grep -F -x 'export THIN_TAIL_LOGIN_ONLY=kept' "$retire_home/.bashrc" >/dev/null ||
    fail 'thin tail preservation'
if grep -F '.bash_common' "$retire_home/.bashrc" >/dev/null; then
    fail 'bash-common reference retained'
fi
run_retire --rollback "$retire_transaction" >"$TEMP_DIR/retire.rollback"
cmp -s "$retire_home/.bashrc" "$TEMP_DIR/retire-bashrc.before" ||
    fail 'bash-common reference rollback'
cmp -s "$retire_home/.bash_profile" "$TEMP_DIR/retire-profile.before" ||
    fail 'thin profile tail rollback'
run_retire --host local --apply --merge-thin-profile-tail \
    --remove-bash-common-reference >"$TEMP_DIR/retire.reapply"
run_retire --host local --plan >"$TEMP_DIR/retire.current"
grep -F 'state=current action=none' "$TEMP_DIR/retire.current" >/dev/null ||
    fail 'thin tail retirement reapply'

run --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'bashrc rollback'
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail 'profile rollback'
[ "$(file_mode "$home/.bashrc")" = 640 ] || fail 'bashrc rollback mode'
[ "$(file_mode "$home/.bash_profile")" = 600 ] || fail 'profile rollback mode'
if find "$home" -maxdepth 1 -name '.*.harness-*-rollback-*' -print | grep . >/dev/null; then
    fail 'adjacent rollback temporary retained'
fi

if HOME="$home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 HARNESS_TEST_FAIL_AFTER=1 \
    "$repo/bin/harness" bash-startup-unify --host local --apply >"$TEMP_DIR/injected.out" 2>&1; then
    fail 'injected replacement failure accepted'
fi
cmp -s "$home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'injected bashrc recovery'
cmp -s "$home/.bash_profile" "$TEMP_DIR/profile.before" || fail 'injected profile recovery'
[ "$(file_mode "$home/.bashrc")" = 640 ] || fail 'injected bashrc recovery mode'
[ "$(file_mode "$home/.bash_profile")" = 600 ] || fail 'injected profile recovery mode'
if find "$home" -maxdepth 1 -name '.*.harness-*-recovery-*' -print | grep . >/dev/null; then
    fail 'adjacent recovery temporary retained'
fi

run --host local --apply >"$TEMP_DIR/reapply.out"
changed=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/reapply.out")
printf '%s\n' '# later owner edit' >>"$home/.bashrc"
if run --rollback "$changed" >"$TEMP_DIR/changed.out" 2>&1; then fail 'rollback accepted changed canonical bashrc'; fi
grep -F -x '# later owner edit' "$home/.bashrc" >/dev/null || fail 'changed rollback damaged owner edit'

absent_home=$TEMP_DIR/absent-home
mkdir -p "$absent_home"
cp "$TEMP_DIR/bashrc.before" "$absent_home/.bashrc"
run_absent() {
    HOME="$absent_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        "$repo/bin/harness" bash-startup-unify "$@"
}
run_absent --host local --plan >"$TEMP_DIR/absent-plan.out"
grep -F 'profile_prestate=absent' "$TEMP_DIR/absent-plan.out" >/dev/null || fail 'absent profile classification'
run_absent --host local --apply >"$TEMP_DIR/absent-apply.out"
absent_transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/absent-apply.out")
cmp -s "$absent_home/.bash_profile" "$repo/shell/bash_profile.canonical" || fail 'absent profile creation'
run_absent --rollback "$absent_transaction" >"$TEMP_DIR/absent-rollback.out"
[ ! -e "$absent_home/.bash_profile" ] || fail 'absent profile rollback removal'
cmp -s "$absent_home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'absent profile bashrc rollback'

if HOME="$absent_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 HARNESS_TEST_FAIL_AFTER=2 \
    "$repo/bin/harness" bash-startup-unify --host local --apply >"$TEMP_DIR/absent-injected.out" 2>&1; then
    fail 'absent profile injected failure accepted'
fi
[ ! -e "$absent_home/.bash_profile" ] || fail 'absent profile injected recovery'
cmp -s "$absent_home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'absent profile injected bashrc recovery'

symlink_home=$TEMP_DIR/symlink-home
persistent=$TEMP_DIR/persistent
layout=$TEMP_DIR/home-layout.tsv
mkdir -p "$symlink_home" "$persistent/.local"
ln -s "$persistent/.local" "$symlink_home/.local"
cp "$TEMP_DIR/bashrc.before" "$symlink_home/.bashrc"
printf '%s\n' "local|$persistent|$TEMP_DIR/cache|.local|none|none|none" >"$layout"
run_symlink() {
    HOME="$symlink_home" HARNESS_ROOT="$repo" HARNESS_TEST_ALLOW_NONMAIN=1 \
        HARNESS_HOME_LAYOUT_FILE="$layout" \
        "$repo/bin/harness" bash-startup-unify "$@"
}
run_symlink --host local --apply >"$TEMP_DIR/symlink-apply.out"
symlink_transaction=$(sed -n 's/^BASH_STARTUP_UNIFY action=applied transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/symlink-apply.out")
run_symlink --host local --rollback "$symlink_transaction" >"$TEMP_DIR/symlink-rollback.out"
[ ! -e "$symlink_home/.bash_profile" ] || fail 'declared symlink rollback profile removal'
cmp -s "$symlink_home/.bashrc" "$TEMP_DIR/bashrc.before" || fail 'declared symlink rollback bashrc'

printf '%s\n' "local|$TEMP_DIR/other|$TEMP_DIR/cache|.local|none|none|none" >"$layout"
mkdir -p "$TEMP_DIR/other"
if run_symlink --host local --apply >"$TEMP_DIR/symlink-refusal.out" 2>&1; then
    fail 'undeclared local symlink target accepted'
fi

printf '%s\n' 'Bash startup unification tests: PASS'
