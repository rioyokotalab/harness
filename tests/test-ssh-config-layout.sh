#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
COMMAND=$ROOT/libexec/harness-ssh-config-layout
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-ssh-layout-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }
file_mode() {
    case $(uname -s) in
        Darwin) stat -f %Lp "$1" ;;
        *) stat -c %a "$1" ;;
    esac
}
run_layout() {
    test_home=$1
    shift
    HARNESS_ROOT="$test_repo" HARNESS_TESTING=1 HARNESS_TEST_ALLOW_NONMAIN=1 \
        HOME="$test_home" "$COMMAND" --host test "$@"
}
make_home() {
    home=$1
    mkdir -p "$home/.ssh/config.d"
    chmod 700 "$home/.ssh" "$home/.ssh/config.d"
}
write_legacy_root() {
    path=$1
    {
        printf '%s\n' '# private sentinel stays byte-for-byte'
        printf '%s\n' 'Host node-only' '    HostName node.invalid'
        printf '%s\n' '    IdentityFile ~/.ssh/T291_PRIVATE_SENTINEL' ''
        printf '%s\n' 'Host github' '    HostName github.com' '    User git'
        printf '%s\n' '' 'Host *' '    ServerAliveInterval 30'
    } >"$path"
    chmod 640 "$path"
}

command -v ssh >/dev/null 2>&1 || fail "ssh unavailable"
test_repo=$TEMP_DIR/repo
mkdir -p "$test_repo/config/ssh"
cp "$ROOT/config/ssh/harness.conf" "$test_repo/config/ssh/harness.conf"
git -C "$test_repo" init -q
git -C "$test_repo" config user.name test
git -C "$test_repo" config user.email test.invalid
git -C "$test_repo" add config/ssh/harness.conf
git -C "$test_repo" commit -qm canonical
git -C "$test_repo" branch -M main

home=$TEMP_DIR/home
make_home "$home"
write_legacy_root "$home/.ssh/config"
cp "$home/.ssh/config" "$TEMP_DIR/root.before"
ln -s "$test_repo/config/ssh/harness.conf" "$home/.ssh/config.d/harness.conf"

run_layout "$home" --plan >"$TEMP_DIR/plan.out"
grep -F 'state=migrate github_blocks=1 default_blocks=1 managed_includes=0 fragment=symlink action=normalize' \
    "$TEMP_DIR/plan.out" >/dev/null || fail "legacy plan"
grep -F T291_PRIVATE_SENTINEL "$TEMP_DIR/plan.out" >/dev/null && fail "private value in plan"
run_layout "$home" --apply >"$TEMP_DIR/apply.out"
transaction=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "transaction identifier"
[ -f "$home/.ssh/config.d/harness.conf" ] && [ ! -L "$home/.ssh/config.d/harness.conf" ] ||
    fail "fragment is not regular"
cmp -s "$home/.ssh/config.d/harness.conf" "$test_repo/config/ssh/harness.conf" ||
    fail "fragment canonical bytes"
[ "$(file_mode "$home/.ssh/config.d/harness.conf")" = 600 ] || fail "fragment mode"
[ "$(file_mode "$home/.ssh/config")" = 640 ] || fail "root mode preservation"
[ "$(grep -c '^Include ~/.ssh/config.d/harness.conf$' "$home/.ssh/config")" -eq 1 ] ||
    fail "one managed include"
[ "$(tail -n 1 "$home/.ssh/config")" = 'Include ~/.ssh/config.d/harness.conf' ] ||
    fail "managed include is not terminal"
[ "$(tail -n 2 "$home/.ssh/config" | head -n 1)" = 'Match all' ] ||
    fail "managed global context reset is absent"
sed "s|^Include ~/.ssh/config.d/harness.conf$|Include $home/.ssh/config.d/harness.conf|" \
    "$home/.ssh/config" >"$TEMP_DIR/effective-config"
ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
    github 2>/dev/null |
    awk '$1 == "hostname" { h=$2 } $1 == "user" { u=$2 }
        $1 == "serveraliveinterval" { s=$2 }
        END { exit h == "github.com" && u == "git" && s == 15 ? 0 : 1 }' ||
    fail "terminal include did not resolve GitHub and defaults globally"
for failover_alias in tunnel tunnel2; do
    ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
        "$failover_alias" 2>/dev/null |
        awk '$1 == "controlmaster" { m=$2 } $1 == "controlpath" { p=$2 }
            $1 == "controlpersist" { x=$2 }
            $1 == "exitonforwardfailure" { e=$2 }
            END { exit m == "false" && p == "" && x == "no" && e == "yes" ? 0 : 1 }' ||
        fail "failover alias retained multiplexing or non-failing forwards"
done
for no_x11_alias in tunnel tunnel2 aist aist2 home home2 office office2 riken riken2 web github; do
    ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
        "$no_x11_alias" 2>/dev/null |
        awk '$1 == "forwardx11" { x=$2 }
            END { exit x == "no" ? 0 : 1 }' ||
        fail "managed X11 opt-out missing"
done
for x11_alias in login node-only; do
    ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
        "$x11_alias" 2>/dev/null |
        awk '$1 == "forwardx11" { x=$2 } $1 == "forwardx11trusted" { t=$2 }
            END { exit x == "yes" && t == "yes" ? 0 : 1 }' ||
        fail "ordinary target lost X11 policy"
done
ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
    node-only 2>/dev/null |
    awk '$1 == "controlmaster" { m=$2 } $1 == "controlpath" { p=$2 }
        $1 == "controlpersist" { x=$2 }
        $1 == "exitonforwardfailure" { e=$2 }
        END { exit m == "auto" && p != "none" && x == "yes" && e == "no" ? 0 : 1 }' ||
    fail "ordinary target lost multiplexing or inherited fail-fast forwarding"
grep -E '^[[:space:]]*Host[[:space:]]+(github|\*)[[:space:]]*$' \
    "$home/.ssh/config" >/dev/null && fail "shared stanza remained in root"
grep -F T291_PRIVATE_SENTINEL "$home/.ssh/config" >/dev/null || fail "private root bytes lost"
run_layout "$home" --plan >"$TEMP_DIR/current.out"
grep -F 'state=current' "$TEMP_DIR/current.out" >/dev/null || fail "idempotent plan"

run_layout "$home" --rollback "$transaction" >"$TEMP_DIR/rollback.out"
cmp -s "$home/.ssh/config" "$TEMP_DIR/root.before" || fail "root rollback bytes"
[ "$(file_mode "$home/.ssh/config")" = 640 ] || fail "root rollback mode"
[ -L "$home/.ssh/config.d/harness.conf" ] &&
    [ "$(readlink "$home/.ssh/config.d/harness.conf")" = "$test_repo/config/ssh/harness.conf" ] ||
    fail "fragment symlink rollback"

failure_home=$TEMP_DIR/failure-home
make_home "$failure_home"
write_legacy_root "$failure_home/.ssh/config"
printf '%s\n' '# prior regular fragment' >"$failure_home/.ssh/config.d/harness.conf"
chmod 644 "$failure_home/.ssh/config.d/harness.conf"
cp "$failure_home/.ssh/config" "$TEMP_DIR/failure-root.before"
cp "$failure_home/.ssh/config.d/harness.conf" "$TEMP_DIR/failure-fragment.before"
if HARNESS_TEST_SSH_LAYOUT_FAIL_AFTER_FRAGMENT=1 run_layout "$failure_home" --apply \
    >"$TEMP_DIR/injected.out" 2>&1; then
    fail "injected replacement failure accepted"
fi
grep -F 'prior files were restored' "$TEMP_DIR/injected.out" >/dev/null ||
    fail "injected failure report"
cmp -s "$failure_home/.ssh/config" "$TEMP_DIR/failure-root.before" ||
    fail "injected failure root recovery"
cmp -s "$failure_home/.ssh/config.d/harness.conf" "$TEMP_DIR/failure-fragment.before" ||
    fail "injected failure fragment recovery"
[ "$(file_mode "$failure_home/.ssh/config.d/harness.conf")" = 644 ] ||
    fail "injected failure fragment mode"

regular_home=$TEMP_DIR/regular-home
make_home "$regular_home"
write_legacy_root "$regular_home/.ssh/config"
printf '%s\n' '# prior regular fragment' >"$regular_home/.ssh/config.d/harness.conf"
chmod 644 "$regular_home/.ssh/config.d/harness.conf"
cp "$regular_home/.ssh/config.d/harness.conf" "$TEMP_DIR/regular-fragment.before"
run_layout "$regular_home" --apply >"$TEMP_DIR/regular-apply.out"
regular_tx=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/regular-apply.out")
printf '%s\n' '# owner changed postimage' >>"$regular_home/.ssh/config"
if run_layout "$regular_home" --rollback "$regular_tx" >"$TEMP_DIR/changed.out" 2>&1; then
    fail "changed postimage rollback accepted"
fi
grep -F 'blocked by a changed postimage' "$TEMP_DIR/changed.out" >/dev/null ||
    fail "changed postimage refusal"

assert_refused() {
    label=$1
    content=$2
    refuse_home=$TEMP_DIR/refuse-$label
    make_home "$refuse_home"
    printf '%s\n' "$content" >"$refuse_home/.ssh/config"
    cp "$refuse_home/.ssh/config" "$TEMP_DIR/$label.before"
    if run_layout "$refuse_home" --plan >"$TEMP_DIR/$label.out" 2>&1; then
        fail "$label accepted"
    fi
    cmp -s "$refuse_home/.ssh/config" "$TEMP_DIR/$label.before" || fail "$label mutated"
}
assert_refused duplicate 'Host github
    HostName github.com
Host github
    HostName github.com'
assert_refused multipattern 'Host github other
    HostName github.com'
assert_refused match 'Match host *.invalid
    ForwardAgent no'
assert_refused include 'Include ~/.ssh/owner.conf'
assert_refused hiddeninclude 'Host github
    HostName github.com
    Include ~/.ssh/owner.conf
Host *
    ForwardAgent no'
assert_refused duplicateinclude 'Include ~/.ssh/config.d/harness.conf
Include ~/.ssh/config.d/harness.conf'

include_only_home=$TEMP_DIR/include-only-home
make_home "$include_only_home"
printf '%s\n' 'Host node-only' '    HostName node.invalid' \
    'Include ~/.ssh/config.d/harness.conf' >"$include_only_home/.ssh/config"
cp "$ROOT/config/ssh/harness.conf" \
    "$include_only_home/.ssh/config.d/harness.conf"
chmod 600 "$include_only_home/.ssh/config" \
    "$include_only_home/.ssh/config.d/harness.conf"
run_layout "$include_only_home" --plan >"$TEMP_DIR/include-only-plan.out"
grep -F 'state=migrate github_blocks=0 default_blocks=0 managed_includes=1' \
    "$TEMP_DIR/include-only-plan.out" >/dev/null || fail "include-only upgrade plan"
run_layout "$include_only_home" --apply >/dev/null
[ "$(tail -n 2 "$include_only_home/.ssh/config" | head -n 1)" = 'Match all' ] ||
    fail "include-only upgrade context reset"

wrong_link_home=$TEMP_DIR/wrong-link-home
make_home "$wrong_link_home"
printf '%s\n' 'Host node-only' '    HostName node.invalid' >"$wrong_link_home/.ssh/config"
ln -s "$wrong_link_home/owner-fragment" "$wrong_link_home/.ssh/config.d/harness.conf"
if run_layout "$wrong_link_home" --plan >"$TEMP_DIR/wrong-link.out" 2>&1; then
    fail "unexpected fragment symlink accepted"
fi

absent_home=$TEMP_DIR/absent-home
mkdir "$absent_home"
run_layout "$absent_home" --apply >"$TEMP_DIR/absent-apply.out"
absent_tx=$(sed -n 's/.*transaction=\([^ ]*\).*/\1/p' "$TEMP_DIR/absent-apply.out")
[ "$(cat "$absent_home/.ssh/config")" = 'Match all
Include ~/.ssh/config.d/harness.conf' ] ||
    fail "absent root creation"
[ "$(file_mode "$absent_home/.ssh/config")" = 600 ] || fail "absent root mode"
run_layout "$absent_home" --rollback "$absent_tx" >/dev/null
[ ! -e "$absent_home/.ssh/config" ] || fail "absent root rollback"
[ ! -e "$absent_home/.ssh/config.d/harness.conf" ] || fail "absent fragment rollback"

echo 'SSH configuration layout tests: PASS'
