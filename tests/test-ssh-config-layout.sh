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

python3 - "$test_repo/config/ssh/harness.conf" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
stanza = None
options = []

def check(label, values):
    keys = [line.strip().split(None, 1)[0].lower() for line in values]
    if keys != sorted(keys):
        raise SystemExit("managed SSH directives are not alphabetic: " + label)

for raw in path.read_text(encoding="utf-8").splitlines():
    if raw.startswith("Host "):
        if stanza is not None:
            check(stanza, options)
        stanza = raw
        options = []
    elif stanza is not None and raw[:1].isspace() and raw.strip():
        options.append(raw)
if stanza is not None:
    check(stanza, options)
PY

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
        $1 == "forwardagent" { a=$2 } $1 == "forwardx11" { x=$2 }
        $1 == "serveraliveinterval" { s=$2 }
        END { exit h == "github.com" && u == "git" && a == "no" &&
            x == "no" && s == 15 ? 0 : 1 }' ||
    fail "terminal include did not resolve GitHub and defaults globally"
ssh -o CanonicalizeHostname=no -G -F "$TEMP_DIR/effective-config" \
    github.com 2>/dev/null |
    awk '$1 == "hostname" { h=$2 } $1 == "forwardagent" { a=$2 }
        $1 == "forwardx11" { x=$2 }
        END { exit h == "github.com" && a == "no" && x == "no" ? 0 : 1 }' ||
    fail "direct GitHub hostname inherited agent or X11 forwarding"
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
    awk '$1 == "addkeystoagent" { a=$2 }
        $1 == "connecttimeout" { c=$2 }
        $1 == "controlmaster" { m=$2 } $1 == "controlpath" { p=$2 }
        $1 == "controlpersist" { x=$2 }
        $1 == "exitonforwardfailure" { e=$2 }
        $1 == "forwardagent" { f=$2 }
        $1 == "hashknownhosts" { h=$2 }
        $1 == "serveralivecountmax" { n=$2 }
        $1 == "serveraliveinterval" { i=$2 }
        $1 == "updatehostkeys" { u=$2 }
        END {
            suffix=p
            sub(/^.*\/cm-/, "", suffix)
            exit a == "true" && c == 30 && m == "auto" &&
                p ~ /\/cm-[0-9a-f]+$/ && length(suffix) == 40 &&
                x == "yes" && e == "no" && f == "yes" &&
                h == "yes" && n == 3 && i == 15 && u == "true" ? 0 : 1
        }' ||
    fail "ordinary target lost managed default policy"
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

echo 'SSH configuration layout essential contract: PASS'
exit 0
