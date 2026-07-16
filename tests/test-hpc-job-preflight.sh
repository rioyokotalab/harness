#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PROBE=$ROOT/tools/hpc-job-preflight.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/hpc-job-preflight.XXXXXX")
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

write_fake() {
    name=$1
    body=$2
    file=$fake_bin/$name
    printf '#!/bin/sh\n%s\n' "$body" >"$file"
    chmod 700 "$file"
}

sh -n "$PROBE"
write_fake squeue 'exit 0'
output=$(HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1)
printf '%s\n' "$output" | grep -F 'result=absent jobs=0 temporary=0 status=pass' >/dev/null

write_fake squeue 'exit 7'
if env HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1 >"$TEST_ROOT/slurm-query.out" 2>&1; then
    printf '%s\n' 'FAIL: failed Slurm query was accepted as zero jobs' >&2
    exit 1
fi
grep -F 'native Slurm query failed' "$TEST_ROOT/slurm-query.out" >/dev/null

write_fake squeue 'printf "123|%-100s|%-100s\n" t238test "$(id -un)"'
if env HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1 >"$TEST_ROOT/slurm-collision.out" 2>&1; then
    printf '%s\n' 'FAIL: exact Slurm name collision was accepted' >&2
    exit 1
fi
grep -F 'jobs=1 temporary=0 status=fail' "$TEST_ROOT/slurm-collision.out" >/dev/null

write_fake qselect 'exit 0'
output=$(HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=ab \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1)
printf '%s\n' "$output" | grep -F 'jobs=0 temporary=0 status=pass' >/dev/null
write_fake qselect 'exit 9'
if env HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=ab \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1 >"$TEST_ROOT/pbs-query.out" 2>&1; then
    printf '%s\n' 'FAIL: failed PBS query was accepted as zero jobs' >&2
    exit 1
fi
grep -F 'native PBS query failed' "$TEST_ROOT/pbs-query.out" >/dev/null

write_fake qstat 'printf "%s\n" "job-ID prior name user state submit/start at queue slots" "--------------------------------------------------------------------------------"'
output=$(HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=t4 \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1)
printf '%s\n' "$output" | grep -F 'jobs=0 temporary=0 status=pass' >/dev/null
write_fake qstat 'exit 4'
if env HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=t4 \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1 >"$TEST_ROOT/age-query.out" 2>&1; then
    printf '%s\n' 'FAIL: failed AGE query was accepted as zero jobs' >&2
    exit 1
fi
grep -F 'native AGE query failed' "$TEST_ROOT/age-query.out" >/dev/null

mkdir -p "$TEST_ROOT/.local/state/harness/hpc-readiness"
chmod 700 "$TEST_ROOT/.local/state/harness/hpc-readiness"
: >"$TEST_ROOT/.local/state/harness/hpc-readiness/t238-result-v1.out"
write_fake squeue 'exit 0'
if env HOME=$TEST_ROOT PATH=$fake_bin:/usr/bin:/bin HARNESS_LOGICAL_HOST=local \
    "$PROBE" t238test t238-result-v1.out .t238-result-v1 >"$TEST_ROOT/result-collision.out" 2>&1; then
    printf '%s\n' 'FAIL: fixed result collision was accepted' >&2
    exit 1
fi
grep -F 'result=present jobs=0 temporary=0 status=fail' "$TEST_ROOT/result-collision.out" >/dev/null

printf '%s\n' 'HPC job preflight tests: PASS'
