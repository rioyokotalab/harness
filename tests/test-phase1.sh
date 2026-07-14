#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-test.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

for script in \
    "$ROOT/bin/harness" \
    "$ROOT/libexec/harness-common" \
    "$ROOT/libexec/harness-inventory" \
    "$ROOT/libexec/harness-plan" \
    "$ROOT/libexec/harness-doctor" \
    "$ROOT/libexec/harness-apply" \
    "$ROOT/libexec/harness-remediate" \
    "$ROOT/libexec/harness-shell" \
    "$ROOT/libexec/harness-rollback"
do
    sh -n "$script" || fail "shell syntax: $script"
done

"$HARNESS" inventory --host local >"$TEMP_DIR/local.facts"
awk -F= '
    NF != 2 { exit 1 }
    $1 !~ /^[A-Za-z0-9_]+$/ { exit 1 }
    $2 !~ /^[A-Za-z0-9._+-]+$/ { exit 1 }
' "$TEMP_DIR/local.facts" || fail "unsafe inventory fact format"
if grep -F "$HOME" "$TEMP_DIR/local.facts" >/dev/null 2>&1; then
    fail "inventory exposed a home path"
fi
cut -d= -f1 "$TEMP_DIR/local.facts" | LC_ALL=C sort -u \
    >"$TEMP_DIR/allowed-keys"

"$HARNESS" inventory --host local --format json >"$TEMP_DIR/local.json"
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["schema"] == "1"' \
    "$TEMP_DIR/local.json" || fail "invalid JSON inventory"

for logical_host in local ab ab2 ai4s al rc t4; do
    fixture=$ROOT/tests/fixtures/$logical_host.facts
    [ -f "$fixture" ] || fail "missing fixture: $logical_host"
    awk -F= '
        NF != 2 { exit 1 }
        $1 !~ /^[A-Za-z0-9_]+$/ { exit 1 }
        $2 !~ /^[A-Za-z0-9._+-]+$/ { exit 1 }
    ' "$fixture" || fail "unsafe fixture fact format: $logical_host"
    cut -d= -f1 "$fixture" | LC_ALL=C sort >"$TEMP_DIR/fixture-keys"
    if uniq -d "$TEMP_DIR/fixture-keys" | grep . >/dev/null 2>&1; then
        fail "duplicate fixture fact: $logical_host"
    fi
    if comm -23 "$TEMP_DIR/fixture-keys" "$TEMP_DIR/allowed-keys" |
        grep . >/dev/null 2>&1; then
        fail "unknown fixture fact: $logical_host"
    fi
    "$HARNESS" doctor --host "$logical_host" --facts "$fixture" \
        >"$TEMP_DIR/doctor-$logical_host.out" ||
        fail "doctor rejected fixture: $logical_host"
    grep "SUMMARY host=$logical_host failures=0" \
        "$TEMP_DIR/doctor-$logical_host.out" >/dev/null ||
        fail "doctor summary: $logical_host"
    "$HARNESS" plan --host "$logical_host" --facts "$fixture" \
        >"$TEMP_DIR/plan-$logical_host.out" ||
        fail "plan rejected fixture: $logical_host"
    grep "END plan host=$logical_host remote_changes=none" \
        "$TEMP_DIR/plan-$logical_host.out" >/dev/null ||
        fail "plan mutation marker: $logical_host"
done

grep 'CREATE harness_checkout' "$TEMP_DIR/plan-al.out" >/dev/null ||
    fail "remote checkout plan"
grep 'INSTALL tool=uv' "$TEMP_DIR/plan-al.out" >/dev/null ||
    fail "remote uv plan"

sed 's/^arch=x86_64$/arch=aarch64/' "$ROOT/tests/fixtures/local.facts" \
    >"$TEMP_DIR/wrong-arch.facts"
if "$HARNESS" doctor --host local --facts "$TEMP_DIR/wrong-arch.facts" \
    >"$TEMP_DIR/wrong-arch.out" 2>&1; then
    fail "doctor accepted an architecture mismatch"
fi
grep 'FAIL arch expected=x86_64 observed=aarch64' \
    "$TEMP_DIR/wrong-arch.out" >/dev/null ||
    fail "architecture mismatch evidence"

if "$HARNESS" doctor --host excluded-host >"$TEMP_DIR/excluded.out" 2>&1; then
    fail "doctor accepted an unknown host"
fi

# Exercise a real apply/rollback against an isolated clean Git checkout.
test_repo=$TEMP_DIR/repo
test_home=$TEMP_DIR/home
mkdir -p "$test_repo" "$test_home"
cp -R "$ROOT/bin" "$ROOT/libexec" "$ROOT/profiles" "$ROOT/shared" \
    "$ROOT/shell" "$ROOT/.codex" "$ROOT/.claude" "$test_repo/"
git -C "$test_repo" init -q
git -C "$test_repo" config user.name harness-test
git -C "$test_repo" config user.email harness-test.invalid
git -C "$test_repo" add .
git -C "$test_repo" commit -qm baseline
HOME="$test_home" "$test_repo/bin/harness" apply --host local --plan \
    >"$TEMP_DIR/control-plan.out"
grep 'changes=not-applied' "$TEMP_DIR/control-plan.out" >/dev/null ||
    fail "control-plane dry run"
HOME="$test_home" "$test_repo/bin/harness" apply --host local --apply \
    >"$TEMP_DIR/control-apply.out"
transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/control-apply.out")
[ -n "$transaction" ] || fail "missing apply transaction"
[ -L "$test_home/.local/bin/harness" ] || fail "missing applied command link"
[ -L "$test_home/.codex/AGENTS.md" ] || fail "missing applied guidance link"
rm "$test_home/.local/bin/harness"
ln -s "$TEMP_DIR/foreign" "$test_home/.local/bin/harness"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$transaction" \
    >"$TEMP_DIR/refused-rollback.out" 2>&1; then
    fail "rollback removed a changed link"
fi
[ "$(readlink "$test_home/.local/bin/harness")" = "$TEMP_DIR/foreign" ] ||
    fail "rollback did not preserve a changed link"
rm "$test_home/.local/bin/harness"
ln -s "$test_repo/bin/harness" "$test_home/.local/bin/harness"
HOME="$test_home" "$test_repo/bin/harness" rollback "$transaction" \
    >"$TEMP_DIR/control-rollback.out"
[ ! -L "$test_home/.local/bin/harness" ] || fail "rollback left command link"
[ ! -L "$test_home/.codex/AGENTS.md" ] || fail "rollback left guidance link"
grep 'status=rolled-back' "$TEMP_DIR/control-rollback.out" >/dev/null ||
    fail "rollback transaction status"

printf '%s\n' 'export TEST_TOKEN=fake-secret-value' >"$test_home/.bashrc"
printf '%s\n' '# existing login setup' >"$test_home/.bash_profile"
cp "$test_home/.bashrc" "$TEMP_DIR/original-bashrc"
cp "$test_home/.bash_profile" "$TEMP_DIR/original-bash-profile"
HOME="$test_home" "$test_repo/bin/harness" shell --host local --plan \
    >"$TEMP_DIR/shell-plan.out"
grep 'APPEND file=.bashrc' "$TEMP_DIR/shell-plan.out" >/dev/null || fail "shell plan"
HOME="$test_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/shell-apply.out"
shell_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' "$TEMP_DIR/shell-apply.out")
[ -n "$shell_transaction" ] || fail "missing shell transaction"
if grep -R 'fake-secret-value' "$test_home/.local/state/harness" >/dev/null 2>&1; then
    fail "shell transaction copied pre-existing content"
fi
applied_size=$(wc -c <"$test_home/.bashrc" | tr -d ' ')
printf '%s\n' '# later user change' >>"$test_home/.bashrc"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$shell_transaction" \
    >"$TEMP_DIR/refused-shell-rollback.out" 2>&1; then
    fail "shell rollback accepted later changes"
fi
grep 'later user change' "$test_home/.bashrc" >/dev/null ||
    fail "shell rollback damaged later changes"
truncate -s "$applied_size" "$test_home/.bashrc"
HOME="$test_home" "$test_repo/bin/harness" rollback "$shell_transaction" \
    >"$TEMP_DIR/shell-rollback.out"
cmp -s "$test_home/.bashrc" "$TEMP_DIR/original-bashrc" || fail "bashrc rollback"
cmp -s "$test_home/.bash_profile" "$TEMP_DIR/original-bash-profile" || fail "bash profile rollback"

printf '%s\n' 'uenv start prgenv-gnu/25.11:v1 --view=default' >>"$test_home/.bashrc"
cp "$test_home/.bashrc" "$TEMP_DIR/original-remediation-bashrc"
HOME="$test_home" "$test_repo/bin/harness" remediate --host al --plan \
    >"$TEMP_DIR/remediation-plan.out"
grep 'PATCH file=.bashrc match=reviewed-uenv-start' \
    "$TEMP_DIR/remediation-plan.out" >/dev/null || fail "remediation plan"
HOME="$test_home" "$test_repo/bin/harness" remediate --host al --apply \
    >"$TEMP_DIR/remediation-apply.out"
remediation_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/remediation-apply.out")
[ -n "$remediation_transaction" ] || fail "missing remediation transaction"
grep -F -x '# harness: use prgenv for an interactive uenv' \
    "$test_home/.bashrc" >/dev/null || fail "remediation exact patch"
if grep -R 'fake-secret-value' "$test_home/.local/state/harness" >/dev/null 2>&1; then
    fail "remediation transaction copied pre-existing content"
fi
sed -i 's/^# harness: use prgenv/# xarness: use prgenv/' "$test_home/.bashrc"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$remediation_transaction" \
    >"$TEMP_DIR/refused-remediation-rollback.out" 2>&1; then
    fail "remediation rollback accepted a changed patch"
fi
grep -F -x '# xarness: use prgenv for an interactive uenv' \
    "$test_home/.bashrc" >/dev/null || fail "remediation rollback damaged changed patch"
sed -i 's/^# xarness: use prgenv/# harness: use prgenv/' "$test_home/.bashrc"
HOME="$test_home" "$test_repo/bin/harness" rollback "$remediation_transaction" \
    >"$TEMP_DIR/remediation-rollback.out"
cmp -s "$test_home/.bashrc" "$TEMP_DIR/original-remediation-bashrc" ||
    fail "remediation rollback"
HOME="$test_home" "$test_repo/bin/harness" shell --host al --plan \
    >"$TEMP_DIR/al-shell-plan.out"
al_payload_bytes=$((1 + $(wc -c <"$test_repo/shell/bashrc.al.block" | tr -d ' ')))
grep "APPEND file=.bashrc bytes=$al_payload_bytes" "$TEMP_DIR/al-shell-plan.out" \
    >/dev/null || fail "al host-specific shell payload"
al_profile_payload_bytes=$((1 + $(wc -c <"$test_repo/shell/bash_profile.al.block" | tr -d ' ')))
grep "APPEND file=.bash_profile bytes=$al_profile_payload_bytes" \
    "$TEMP_DIR/al-shell-plan.out" >/dev/null || fail "al host-specific login payload"
if HOME="$test_home" "$test_repo/bin/harness" remediate --host rc --plan \
    >"$TEMP_DIR/unknown-remediation.out" 2>&1; then
    fail "remediation accepted an unreviewed host"
fi
ln -s "$test_repo" "$test_home/harness"
if HOME="$test_home" bash --noprofile --norc -c \
    '. "$HOME/harness/shell/bashrc.al.block"; type prgenv >/dev/null 2>&1'; then
    fail "al convenience loaded in a non-interactive shell"
fi
HOME="$test_home" bash --noprofile --norc -ic \
    '. "$HOME/harness/shell/bashrc.al.block"; type prgenv' \
    >"$TEMP_DIR/al-interactive.out" 2>&1 || fail "al interactive convenience"
grep 'prgenv is a function' "$TEMP_DIR/al-interactive.out" >/dev/null ||
    fail "al interactive function missing"

echo "phase-1 harness tests passed"
