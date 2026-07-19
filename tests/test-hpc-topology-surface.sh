#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PROBE=$ROOT/tools/hpc-topology-surface.sh
AUDIT=$ROOT/docs/audits/hpc-topology-login-surface-2026-07-17.json
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/hpc-topology-surface.XXXXXX")
fake_bin=$TEST_ROOT/bin
mkdir -p "$fake_bin"

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$ROOT/tests/guarded-test-cleanup.sh" "$ROOT/bin/harness" \
        "${TMPDIR:-/tmp}" "$TEST_ROOT" "${TMPDIR:-/tmp}" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

write_lscpu() {
    body=$1
    printf '#!/bin/sh\n%s\n' "$body" >"$fake_bin/lscpu"
    chmod 700 "$fake_bin/lscpu"
}

sh -n "$PROBE"
if [ "$(uname -s)" = Linux ]; then
write_lscpu 'printf "%s\n" "# NODE" 0 0 1 1'
output=$(PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local "$PROBE")
printf '%s\n' "$output" | grep -E '^HPC_TOPOLOGY_SURFACE host=local .* login_numa_nodes=2 status=pass$' >/dev/null

write_lscpu 'exit 7'
if PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local "$PROBE" >"$TEST_ROOT/fail.out" 2>&1; then
    printf '%s\n' 'FAIL: failed lscpu query was accepted' >&2
    exit 1
fi
grep -F 'lscpu query failed' "$TEST_ROOT/fail.out" >/dev/null

write_lscpu 'printf "%s\n" "# NODE" -'
if PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local "$PROBE" >"$TEST_ROOT/malformed.out" 2>&1; then
    printf '%s\n' 'FAIL: topology without a numeric NUMA node was accepted' >&2
    exit 1
fi
grep -F 'malformed lscpu topology output' "$TEST_ROOT/malformed.out" >/dev/null
fi

python3 - "$AUDIT" <<'PY'
import json
import sys

x = json.load(open(sys.argv[1]))
assert x["schema"] == 1
assert x["scope"] == "login_surface_only"
assert set(x["nodes"]) == {"local", "ab", "ab2", "ri", "al", "rc", "t4"}
assert all(node["taskset"] == "present" and node["lscpu"] == "present" for node in x["nodes"].values())
assert all(isinstance(node["login_numa_nodes"], int) and node["login_numa_nodes"] > 0 for node in x["nodes"].values())
for key, total in x["totals"].items():
    field = key.removesuffix("_present")
    assert total == sum(node[field] == "present" for node in x["nodes"].values())
PY

printf '%s\n' 'HPC topology surface tests: PASS'
