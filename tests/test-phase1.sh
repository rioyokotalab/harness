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
    "$ROOT/libexec/harness-tool" \
    "$ROOT/libexec/harness-runtime" \
    "$ROOT/libexec/harness-python" \
    "$ROOT/libexec/harness-agent" \
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

for logical_host in local ab ab2 ri al rc t4; do
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

"$HARNESS" tool --host ab2 --name ripgrep --facts "$ROOT/tests/fixtures/ab2.facts" \
    --plan >"$TEMP_DIR/tool-plan.out"
grep 'INSTALL artifact=.*ripgrep/15.1.0/linux-x86_64' \
    "$TEMP_DIR/tool-plan.out" >/dev/null || fail "tool artifact plan"
grep 'sha256=1c9297be4a084eea7ecaedf93eb03d058d6faae29bbc57ecdaf5063921491599' \
    "$TEMP_DIR/tool-plan.out" >/dev/null || fail "tool checksum plan"
if "$HARNESS" tool --host ab2 --name unsupported \
    --facts "$ROOT/tests/fixtures/ab2.facts" --plan \
    >"$TEMP_DIR/unsupported-tool.out" 2>&1; then
    fail "tool plan accepted an unsupported artifact"
fi
mkdir -p "$TEMP_DIR/uv-plan-home"
HOME="$TEMP_DIR/uv-plan-home" "$HARNESS" tool --host al --name uv \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/uv-plan.out"
grep 'INSTALL artifact=.*uv/0.9.18/linux-aarch64' "$TEMP_DIR/uv-plan.out" \
    >/dev/null || fail "uv AArch64 artifact plan"
grep 'sha256=f8e23ec786b18660ade6b033b6191b7e9c283c872eeb8c4531d56a873decf160' \
    "$TEMP_DIR/uv-plan.out" >/dev/null || fail "uv AArch64 checksum plan"

mkdir -p "$TEMP_DIR/rclone-plan-home"
HOME="$TEMP_DIR/rclone-plan-home" "$HARNESS" tool --host rc --name rclone \
    --facts "$ROOT/tests/fixtures/rc.facts" --plan >"$TEMP_DIR/rclone-x86-plan.out"
grep 'sha256=dbee7ccd7a5d617e4ed4cd4555c16669b511abfe8d31164f61be35ac9e999bd2' \
    "$TEMP_DIR/rclone-x86-plan.out" >/dev/null || fail "rclone x86-64 checksum plan"
grep 'EXTRACT format=zip member=rclone-v1.74.3-linux-amd64/rclone binary=rclone' \
    "$TEMP_DIR/rclone-x86-plan.out" >/dev/null || fail "rclone x86-64 extraction plan"
HOME="$TEMP_DIR/rclone-plan-home" "$HARNESS" tool --host al --name rclone \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/rclone-arm-plan.out"
grep 'sha256=8f8d47446e061f80c3256659fe8e21f56d72d96aaefe1275d088ea5eb6b42aa7' \
    "$TEMP_DIR/rclone-arm-plan.out" >/dev/null || fail "rclone AArch64 checksum plan"
grep 'EXTRACT format=zip member=rclone-v1.74.3-linux-arm64/rclone binary=rclone' \
    "$TEMP_DIR/rclone-arm-plan.out" >/dev/null || fail "rclone AArch64 extraction plan"

broken_bin=$TEMP_DIR/broken-bin
broken_home=$TEMP_DIR/broken-home
mkdir -p "$broken_bin" "$broken_home"
printf '%s\n' '#!/bin/sh' 'exit 1' >"$broken_bin/ninja"
chmod 755 "$broken_bin/ninja"
HOME="$broken_home" PATH="$broken_bin:/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ninja --plan \
    >"$TEMP_DIR/ninja-unusable-plan.out"
grep 'SHADOW command=ninja reason=host-command-unusable strategy=user-path' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "unusable host Ninja plan"
grep 'INSTALL artifact=.*ninja/1.13.2/linux-x86_64' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "Ninja artifact plan"
grep 'sha256=5749cbc4e668273514150a80e387a957f933c6ed3f5f11e03fb30955e2bbead6' \
    "$TEMP_DIR/ninja-unusable-plan.out" >/dev/null || fail "Ninja x86-64 checksum plan"

mkdir -p "$TEMP_DIR/claude-plan-home"
HOME="$TEMP_DIR/claude-plan-home" "$HARNESS" tool --host al --name claude \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/claude-arm-plan.out"
grep 'INSTALL artifact=.*claude/2.1.207/linux-aarch64' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude AArch64 artifact plan"
grep 'sha256=02c381be3269489119287dc0b5f4b99b870d886f058918994b51e06b701dd1be' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude AArch64 checksum plan"
grep 'EXTRACT format=tar.gz member=package/claude binary=claude' \
    "$TEMP_DIR/claude-arm-plan.out" >/dev/null || fail "Claude extraction plan"

mkdir -p "$TEMP_DIR/runtime-plan-home"
HOME="$TEMP_DIR/runtime-plan-home" "$HARNESS" runtime --host al --name node \
    --facts "$ROOT/tests/fixtures/al.facts" --plan >"$TEMP_DIR/node-arm-plan.out"
grep 'sha256=589f5b6dd4fcfee4dfda73013903c966abaa8abd93dbc9d436544e472b4f0e74' \
    "$TEMP_DIR/node-arm-plan.out" >/dev/null || fail "Node AArch64 checksum plan"
grep 'CREATE link=.*\.local/bin/npm source=.*/bin/npm' \
    "$TEMP_DIR/node-arm-plan.out" >/dev/null || fail "Node npm activation plan"

path_home=$TEMP_DIR/path-home
mkdir -p "$path_home/.local/bin"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$path_home/.local/bin/rg"
chmod 755 "$path_home/.local/bin/rg"
HOME="$path_home" PATH="/usr/bin:/bin" "$HARNESS" inventory --host local \
    >"$TEMP_DIR/user-bin-inventory.out"
grep '^tool_rg=present$' "$TEMP_DIR/user-bin-inventory.out" >/dev/null ||
    fail "inventory missed user tool outside inherited PATH"

# Exercise a real apply/rollback against an isolated clean Git checkout.
test_repo=$TEMP_DIR/repo
test_home=$TEMP_DIR/home
mkdir -p "$test_repo" "$test_home"
managed_rg_dir=$test_home/.local/opt/ripgrep/15.1.0/linux-x86_64
mkdir -p "$managed_rg_dir" "$test_home/.local/bin"
printf '%s\n' '#!/bin/sh' 'echo "ripgrep 15.1.0"' >"$managed_rg_dir/rg"
chmod 755 "$managed_rg_dir/rg"
ln -s "$managed_rg_dir/rg" "$test_home/.local/bin/rg"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ripgrep --plan \
    >"$TEMP_DIR/managed-tool-plan.out"
grep 'KEEP command=rg source=managed-artifact' "$TEMP_DIR/managed-tool-plan.out" \
    >/dev/null || fail "managed tool discovery outside PATH"
rm "$test_home/.local/bin/rg" "$managed_rg_dir/rg"
rmdir "$managed_rg_dir"
managed_ninja_dir=$test_home/.local/opt/ninja/1.13.2/linux-x86_64
mkdir -p "$managed_ninja_dir"
printf '%s\n' '#!/bin/sh' 'echo 0.0' >"$managed_ninja_dir/ninja"
chmod 755 "$managed_ninja_dir/ninja"
ln -s "$managed_ninja_dir/ninja" "$test_home/.local/bin/ninja"
if HOME="$test_home" PATH="/usr/bin:/bin" \
    "$HARNESS" tool --host local --name ninja --plan \
    >"$TEMP_DIR/invalid-managed-ninja.out" 2>&1; then
    fail "tool plan accepted an invalid managed Ninja"
fi
grep 'BLOCK command=ninja reason=managed-artifact-version-or-health-mismatch' \
    "$TEMP_DIR/invalid-managed-ninja.out" >/dev/null || fail "invalid managed Ninja evidence"
rm "$test_home/.local/bin/ninja" "$managed_ninja_dir/ninja"
rmdir "$managed_ninja_dir"
cp -R "$ROOT/bin" "$ROOT/libexec" "$ROOT/profiles" "$ROOT/shared" \
    "$ROOT/shell" "$ROOT/tools" "$ROOT/.codex" "$ROOT/.claude" "$test_repo/"
zip_fixture_dir=$TEMP_DIR/zip-fixture
zip_fixture_archive=$TEMP_DIR/rclone-fixture.zip
zip_fixture_member=rclone-v1.74.3-linux-amd64/rclone
mkdir -p "$zip_fixture_dir"
printf '%s\n' '#!/bin/sh' 'echo "rclone v1.74.3"' >"$zip_fixture_dir/rclone"
chmod 755 "$zip_fixture_dir/rclone"
python3 -c 'import sys,zipfile; z=zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED); z.write(sys.argv[2], sys.argv[3]); z.close()' \
    "$zip_fixture_archive" "$zip_fixture_dir/rclone" "$zip_fixture_member"
zip_fixture_hash=$(sha256sum "$zip_fixture_archive" | awk '{print $1}')
sed -i "s/dbee7ccd7a5d617e4ed4cd4555c16669b511abfe8d31164f61be35ac9e999bd2/$zip_fixture_hash/" \
    "$test_repo/tools/artifacts.tsv"
runtime_fixture_parent=$TEMP_DIR/runtime-fixture
runtime_fixture_root=$runtime_fixture_parent/node-v24.16.0-linux-x64
runtime_fixture_archive=$TEMP_DIR/node-fixture.tar.gz
mkdir -p "$runtime_fixture_root/bin" "$runtime_fixture_root/lib"
printf '%s\n' '#!/bin/sh' 'echo v24.16.0' >"$runtime_fixture_root/bin/node"
printf '%s\n' '#!/bin/sh' 'echo 11.13.0' >"$runtime_fixture_root/lib/npm.sh"
chmod 755 "$runtime_fixture_root/bin/node" "$runtime_fixture_root/lib/npm.sh"
for command_name in npm npx corepack; do
    ln -s ../lib/npm.sh "$runtime_fixture_root/bin/$command_name"
done
tar -czf "$runtime_fixture_archive" -C "$runtime_fixture_parent" \
    node-v24.16.0-linux-x64
runtime_fixture_hash=$(sha256sum "$runtime_fixture_archive" | awk '{print $1}')
sed -i "s/2faf6a387e9b62b888e21c54f01249fb27537ffecf1842f29f4c919d0a59a0ff/$runtime_fixture_hash/" \
    "$test_repo/tools/runtimes.tsv"
agent_launcher_parent=$TEMP_DIR/agent-launcher-fixture
agent_launcher_root=$agent_launcher_parent/package
agent_launcher_archive=$TEMP_DIR/codex-launcher-fixture.tar.gz
mkdir -p "$agent_launcher_root/bin"
printf '%s\n' '#!/bin/sh' 'echo "codex-cli 0.144.4"' >"$agent_launcher_root/bin/codex.js"
chmod 755 "$agent_launcher_root/bin/codex.js"
printf '%s\n' '{"name":"@openai/codex","version":"0.144.4"}' \
    >"$agent_launcher_root/package.json"
tar -czf "$agent_launcher_archive" -C "$agent_launcher_parent" package
agent_launcher_hash=$(sha256sum "$agent_launcher_archive" | awk '{print $1}')
agent_native_parent=$TEMP_DIR/agent-native-fixture
agent_native_root=$agent_native_parent/package
agent_native_archive=$TEMP_DIR/codex-native-fixture.tar.gz
mkdir -p "$agent_native_root/vendor/x86_64-unknown-linux-musl/bin"
printf '%s\n' native-fixture >"$agent_native_root/vendor/x86_64-unknown-linux-musl/bin/codex"
printf '%s\n' '{"name":"@openai/codex","version":"0.144.4-linux-x64"}' \
    >"$agent_native_root/package.json"
tar -czf "$agent_native_archive" -C "$agent_native_parent" package
agent_native_hash=$(sha256sum "$agent_native_archive" | awk '{print $1}')
sed -i "s/613aadb30be4b6a6daa45cbd086f5d4a84636bcd8c036510c106464bd087f193/$agent_launcher_hash/g" \
    "$test_repo/tools/agents.tsv"
sed -i "s/9a4a45314e80b53c4761b80067e3a68c2302f9a9026059b5f54f22dec8f34323/$agent_native_hash/" \
    "$test_repo/tools/agents.tsv"
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

profile_home=$TEMP_DIR/profile-home
mkdir -p "$profile_home"
printf '%s\n' '# existing interactive setup' >"$profile_home/.bashrc"
printf '%s\n' '# existing login setup' >"$profile_home/.profile"
HOME="$profile_home" "$test_repo/bin/harness" shell --host ri --plan \
    >"$TEMP_DIR/profile-shell-plan.out"
grep 'APPEND file=.profile' "$TEMP_DIR/profile-shell-plan.out" >/dev/null ||
    fail "existing profile login selection"
if grep 'file=.bash_profile' "$TEMP_DIR/profile-shell-plan.out" >/dev/null; then
    fail "shell plan bypassed existing profile"
fi
cp "$profile_home/.bashrc" "$TEMP_DIR/original-profile-bashrc"
cp "$profile_home/.profile" "$TEMP_DIR/original-profile-login"
HOME="$profile_home" "$test_repo/bin/harness" shell --host local --apply \
    >"$TEMP_DIR/profile-shell-apply.out"
profile_shell_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/profile-shell-apply.out")
[ -n "$profile_shell_transaction" ] || fail "missing profile shell transaction"
[ ! -e "$profile_home/.bash_profile" ] || fail "shell apply created bash profile"
grep -F '# >>> harness managed >>>' "$profile_home/.profile" >/dev/null ||
    fail "shell apply missed existing profile"
HOME="$profile_home" "$test_repo/bin/harness" rollback "$profile_shell_transaction" \
    >"$TEMP_DIR/profile-shell-rollback.out"
cmp -s "$profile_home/.bashrc" "$TEMP_DIR/original-profile-bashrc" ||
    fail "profile-selection bashrc rollback"
cmp -s "$profile_home/.profile" "$TEMP_DIR/original-profile-login" ||
    fail "profile-selection login rollback"
[ ! -e "$profile_home/.bash_profile" ] || fail "rollback created bash profile"

# Exercise exact-member ZIP apply and rollback without network access.
fake_bin=$TEMP_DIR/fake-bin
mkdir -p "$fake_bin"
printf '%s\n' \
    '#!/bin/sh' \
    'out=' \
    'while [ "$#" -gt 0 ]; do' \
    '    case "$1" in' \
    '        -o) out=$2; shift 2 ;;' \
    '        *) shift ;;' \
    '    esac' \
    'done' \
    '[ -n "$out" ]' \
    'cp "$FIXTURE_ARCHIVE" "$out"' >"$fake_bin/curl"
chmod 755 "$fake_bin/curl"
HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" FIXTURE_ARCHIVE="$zip_fixture_archive" \
    "$test_repo/bin/harness" tool --host local --name rclone --apply \
    >"$TEMP_DIR/zip-tool-apply.out"
zip_tool_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/zip-tool-apply.out")
[ -n "$zip_tool_transaction" ] || fail "missing ZIP tool transaction"
grep "NATIVE unzip -p STAGING $zip_fixture_member > STAGING/rclone" \
    "$TEMP_DIR/zip-tool-apply.out" >/dev/null || fail "ZIP native extraction report"
grep "CALLER native='hash -r' reason=refresh-command-path-cache" \
    "$TEMP_DIR/zip-tool-apply.out" >/dev/null || fail "tool caller cache refresh"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$test_home/.local/bin/rclone" --version >"$TEMP_DIR/zip-tool-version.out"
grep '^rclone v1.74.3$' "$TEMP_DIR/zip-tool-version.out" >/dev/null ||
    fail "ZIP installed version"
HOME="$test_home" PATH="/usr/bin:/bin" \
    "$test_repo/bin/harness" tool --host local --name rclone --plan \
    >"$TEMP_DIR/zip-tool-repeat.out"
grep 'KEEP command=rclone source=managed-artifact' "$TEMP_DIR/zip-tool-repeat.out" \
    >/dev/null || fail "ZIP managed artifact plan"
HOME="$test_home" "$test_repo/bin/harness" rollback "$zip_tool_transaction" \
    >"$TEMP_DIR/zip-tool-rollback.out"
[ ! -e "$test_home/.local/bin/rclone" ] && [ ! -L "$test_home/.local/bin/rclone" ] ||
    fail "ZIP rollback left stable link"
[ ! -e "$test_home/.local/opt/rclone/1.74.3/linux-x86_64" ] ||
    fail "ZIP rollback left artifact directory"

# Exercise whole-tree runtime apply, changed-tree refusal, and exact rollback.
runtime_bin=$TEMP_DIR/runtime-bin
runtime_home=$TEMP_DIR/runtime-home-link
ln -s "$test_home" "$runtime_home"
mkdir -p "$runtime_bin"
ln -s "$fake_bin/curl" "$runtime_bin/curl"
for command_name in awk bash chmod cmp cp date dd dirname find git gzip ln mkdir mktemp mv \
    readlink rm sed sh sha256sum tail tar tr uname wc; do
    ln -s "$(command -v "$command_name")" "$runtime_bin/$command_name"
done
HOME="$runtime_home" PATH="$runtime_bin" FIXTURE_ARCHIVE="$runtime_fixture_archive" \
    "$test_repo/bin/harness" runtime --host local --name node --apply \
    >"$TEMP_DIR/runtime-apply.out"
runtime_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/runtime-apply.out")
[ -n "$runtime_transaction" ] || fail "missing runtime transaction"
HOME="$runtime_home" PATH="$runtime_bin" \
    "$test_repo/bin/harness" runtime --host local --name node --plan \
    >"$TEMP_DIR/runtime-repeat.out"
grep 'KEEP runtime=node source=managed-runtime' "$TEMP_DIR/runtime-repeat.out" \
    >/dev/null || fail "managed runtime plan"
runtime_tree=$runtime_home/.local/opt/node/24.16.0/linux-x86_64
cp -p "$runtime_tree/lib/npm.sh" "$TEMP_DIR/original-runtime-npm"
printf '%s\n' '# changed after apply' >>"$runtime_tree/lib/npm.sh"
if HOME="$runtime_home" "$test_repo/bin/harness" rollback "$runtime_transaction" \
    >"$TEMP_DIR/refused-runtime-rollback.out" 2>&1; then
    fail "runtime rollback accepted changed tree"
fi
[ -L "$runtime_home/.local/bin/node" ] && [ -d "$runtime_tree" ] ||
    fail "runtime rollback partially mutated paths"
cp -p "$TEMP_DIR/original-runtime-npm" "$runtime_tree/lib/npm.sh"
HOME="$runtime_home" "$test_repo/bin/harness" rollback "$runtime_transaction" \
    >"$TEMP_DIR/runtime-rollback.out"
for command_name in node npm npx corepack; do
    [ ! -e "$runtime_home/.local/bin/$command_name" ] &&
        [ ! -L "$runtime_home/.local/bin/$command_name" ] ||
        fail "runtime rollback left link: $command_name"
done
[ ! -e "$runtime_tree" ] || fail "runtime rollback left tree"

# Exercise the two-archive agent tree, changed-tree refusal, and exact rollback.
agent_bin=$TEMP_DIR/agent-bin
agent_home=$TEMP_DIR/agent-home-link
ln -s "$test_home" "$agent_home"
mkdir -p "$agent_bin"
for command_name in awk bash chmod cmp cp date dirname find git gzip ln mkdir mktemp mv \
    readlink rm sed sh sha256sum tar tr uname wc; do
    ln -s "$(command -v "$command_name")" "$agent_bin/$command_name"
done
printf '%s\n' '#!/bin/sh' 'echo v24.16.0' >"$agent_bin/node"
chmod 755 "$agent_bin/node"
printf '%s\n' \
    '#!/bin/sh' \
    'url=' \
    'out=' \
    'while [ "$#" -gt 0 ]; do' \
    '  case "$1" in' \
    '    https://*) url=$1; shift ;;' \
    '    -o) out=$2; shift 2 ;;' \
    '    *) shift ;;' \
    '  esac' \
    'done' \
    'case "$url" in' \
    '  *linux-x64*) cp "$FIXTURE_AGENT_NATIVE" "$out" ;;' \
    '  *) cp "$FIXTURE_AGENT_LAUNCHER" "$out" ;;' \
    'esac' >"$agent_bin/curl"
chmod 755 "$agent_bin/curl"
HOME="$agent_home" PATH="$agent_bin" \
    FIXTURE_AGENT_LAUNCHER="$agent_launcher_archive" \
    FIXTURE_AGENT_NATIVE="$agent_native_archive" \
    "$test_repo/bin/harness" agent --host local --name codex --apply \
    >"$TEMP_DIR/agent-apply.out"
agent_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/agent-apply.out")
[ -n "$agent_transaction" ] || fail "missing agent transaction"
grep "CALLER native='hash -r' reason=refresh-command-path-cache" \
    "$TEMP_DIR/agent-apply.out" >/dev/null || fail "agent caller cache refresh"
HOME="$agent_home" PATH="$agent_bin" \
    "$test_repo/bin/harness" agent --host local --name codex --plan \
    >"$TEMP_DIR/agent-repeat.out"
grep 'KEEP agent=codex source=managed-agent' "$TEMP_DIR/agent-repeat.out" >/dev/null ||
    fail "managed agent plan"
agent_tree=$agent_home/.local/opt/agents/codex/0.144.4/linux-x86_64
agent_launcher=$agent_tree/node_modules/@openai/codex/bin/codex.js
cp -p "$agent_launcher" "$TEMP_DIR/original-agent-launcher"
printf '%s\n' '# changed after apply' >>"$agent_launcher"
if HOME="$agent_home" "$test_repo/bin/harness" rollback "$agent_transaction" \
    >"$TEMP_DIR/refused-agent-rollback.out" 2>&1; then
    fail "agent rollback accepted changed tree"
fi
[ -L "$agent_home/.local/bin/codex" ] && [ -d "$agent_tree" ] ||
    fail "agent rollback partially mutated paths"
cp -p "$TEMP_DIR/original-agent-launcher" "$agent_launcher"
HOME="$agent_home" "$test_repo/bin/harness" rollback "$agent_transaction" \
    >"$TEMP_DIR/agent-rollback.out"
[ ! -e "$agent_home/.local/bin/codex" ] && [ ! -L "$agent_home/.local/bin/codex" ] ||
    fail "agent rollback left command link"
[ ! -e "$agent_tree" ] || fail "agent rollback left tree"

# Exercise uv-managed Python apply, changed-tree refusal, and exact rollback.
python_bin=$TEMP_DIR/python-bin
python_home=$TEMP_DIR/python-home-link
ln -s "$test_home" "$python_home"
mkdir -p "$python_bin"
for command_name in awk bash chmod cmp cp date dd dirname find git ln mkdir mktemp mv \
    readlink rm sed sh sha256sum tail tar tr uname wc; do
    ln -s "$(command -v "$command_name")" "$python_bin/$command_name"
done
fake_python=$TEMP_DIR/python3.12
printf '%s\n' \
    '#!/bin/sh' \
    'case "${2:-}" in' \
    '  *platform.python_version*) echo 3.12.12 ;;' \
    '  *platform.machine*) echo x86_64 ;;' \
    '  *) exit 0 ;;' \
    'esac' \
    'printf "%s\n" "$0" >"${0%/*}/../relocation-state"' >"$fake_python"
chmod 755 "$fake_python"
printf '%s\n' \
    '#!/bin/sh' \
    'if [ "${1:-}" = --version ]; then echo "uv 0.9.18"; exit 0; fi' \
    'install_dir=' \
    'while [ "$#" -gt 0 ]; do' \
    '  case "$1" in --install-dir) install_dir=$2; shift 2 ;; *) shift ;; esac' \
    'done' \
    '[ -n "$install_dir" ]' \
    'target=$install_dir/cpython-3.12.12-linux-x86_64-gnu/bin' \
    'mkdir -p "$target"' \
    'cp "$FIXTURE_PYTHON" "$target/python3.12"' >"$python_bin/uv"
chmod 755 "$python_bin/uv"
HOME="$python_home" PATH="$python_bin" FIXTURE_PYTHON="$fake_python" \
    "$test_repo/bin/harness" python --host local --minor 3.12 --apply \
    >"$TEMP_DIR/python-apply.out"
python_transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' \
    "$TEMP_DIR/python-apply.out")
[ -n "$python_transaction" ] || fail "missing Python transaction"
HOME="$python_home" PATH="$python_bin" \
    "$test_repo/bin/harness" python --host local --minor 3.12 --plan \
    >"$TEMP_DIR/python-repeat.out"
grep 'KEEP python=3.12 source=managed-python' "$TEMP_DIR/python-repeat.out" \
    >/dev/null || fail "managed Python plan"
python_tree=$python_home/.local/opt/python/3.12/linux-x86_64
python_executable=$(find "$python_tree" -type f -name python3.12 -print -quit)
python_tree_archive=$TEMP_DIR/python-tree.tar
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    --exclude='*/__pycache__' --exclude='*.pyc' --exclude='*.pyo' \
    -cf "$python_tree_archive" -C "$python_tree" .
python_tree_hash=$(sha256sum "$python_tree_archive" | awk '{print $1}')
python_expected_hash=$(awk -F'|' '$1 == "python" { print $3 }' \
    "$python_home/.local/state/harness/transactions/$python_transaction.manifest")
[ "$python_tree_hash" = "$python_expected_hash" ] || fail "Python tree changed during activation"
cp -p "$python_executable" "$TEMP_DIR/original-python"
printf '%s\n' '# changed after apply' >>"$python_executable"
if HOME="$python_home" "$test_repo/bin/harness" rollback "$python_transaction" \
    >"$TEMP_DIR/refused-python-rollback.out" 2>&1; then
    fail "Python rollback accepted changed tree"
fi
[ -L "$python_home/.local/bin/python3.12" ] && [ -d "$python_tree" ] ||
    fail "Python rollback partially mutated paths"
cp -p "$TEMP_DIR/original-python" "$python_executable"
python_impl=$(find "$python_tree" -mindepth 1 -maxdepth 1 -type d -name 'cpython-*' -print -quit)
mkdir -p "$python_impl/bin/__pycache__"
printf '%s\n' generated-cache >"$python_impl/bin/__pycache__/module.pyc"
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    --exclude='*/__pycache__' --exclude='*.pyc' --exclude='*.pyo' \
    -cf "$python_tree_archive" -C "$python_tree" .
python_restored_hash=$(sha256sum "$python_tree_archive" | awk '{print $1}')
[ "$python_restored_hash" = "$python_expected_hash" ] || fail "Python tree restoration mismatch"
HOME="$python_home" "$test_repo/bin/harness" rollback "$python_transaction" \
    >"$TEMP_DIR/python-rollback.out"
[ ! -e "$python_home/.local/bin/python3.12" ] &&
    [ ! -L "$python_home/.local/bin/python3.12" ] || fail "Python rollback left link"
[ ! -e "$python_tree" ] || fail "Python rollback left tree"

# Exercise artifact rollback and its all-path modification refusal without network.
artifact_dir=$test_home/.local/opt/fixture/1/linux-x86_64
artifact_link=$test_home/.local/bin/fixture
mkdir -p "$artifact_dir" "${artifact_link%/*}"
printf '%s\n' fixture-binary >"$artifact_dir/fixture"
chmod 755 "$artifact_dir/fixture"
artifact_hash=$(sha256sum "$artifact_dir/fixture" | awk '{print $1}')
ln -s "$artifact_dir/fixture" "$artifact_link"
artifact_transaction=fixture-artifact
artifact_manifest=$test_home/.local/state/harness/transactions/$artifact_transaction.manifest
printf 'schema=1\nhost=local\nrevision=test\nartifact|%s|fixture|%s\nlink|%s|%s\n' \
    "$artifact_dir" "$artifact_hash" "$artifact_link" "$artifact_dir/fixture" \
    >"$artifact_manifest"
chmod 600 "$artifact_manifest"
printf '%s\n' changed >"$artifact_dir/fixture"
if HOME="$test_home" "$test_repo/bin/harness" rollback "$artifact_transaction" \
    >"$TEMP_DIR/refused-artifact-rollback.out" 2>&1; then
    fail "artifact rollback accepted a changed binary"
fi
[ -L "$artifact_link" ] || fail "artifact rollback partially removed link"
printf '%s\n' fixture-binary >"$artifact_dir/fixture"
chmod 755 "$artifact_dir/fixture"
HOME="$test_home" "$test_repo/bin/harness" rollback "$artifact_transaction" \
    >"$TEMP_DIR/artifact-rollback.out"
[ ! -e "$artifact_link" ] && [ ! -L "$artifact_link" ] ||
    fail "artifact rollback left link"
[ ! -e "$artifact_dir" ] || fail "artifact rollback left directory"

echo "phase-1 harness tests passed"
