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
    "$ROOT/libexec/harness-doctor"
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

"$HARNESS" inventory --host local --format json >"$TEMP_DIR/local.json"
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["schema"] == "1"' \
    "$TEMP_DIR/local.json" || fail "invalid JSON inventory"

for logical_host in local ab ab2 ai4s al rc t4; do
    fixture=$ROOT/tests/fixtures/$logical_host.facts
    [ -f "$fixture" ] || fail "missing fixture: $logical_host"
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

echo "phase-1 harness tests passed"
