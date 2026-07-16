#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATOR=$ROOT/tools/hpc-project-intake-validate.py
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/hpc-project-intake-validator.XXXXXX")
manifest=$TEST_ROOT/intake.json

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$ROOT/tests/guarded-test-cleanup.sh" "$ROOT/bin/harness" \
        "${TMPDIR:-/tmp}" "$TEST_ROOT" "${TMPDIR:-/tmp}" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

write_valid() {
    phase=$1
    cat >"$manifest" <<EOF
{
  "schema": 1,
  "status": "$phase",
  "project": {"project_id": "fixture", "workload": "both", "target_hosts": ["local", "al"]},
  "software": {
    "framework": {"name": "project-framework", "version": "locked", "lock_evidence": "project-lock"},
    "language_standards": ["C++20"],
    "mpi_required": true,
    "scientific_libraries": [{"name": "HDF5", "features": ["parallel"], "abi_constraints": ["project-MPI"]}]
  },
  "environment": {
    "mechanism": "container",
    "artifacts": [{"architecture": "x86_64", "reference": "project-image", "digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000"}]
  },
  "scheduler": {
    "route_source": "project_script",
    "account_confirmed": true,
    "resources": {"nodes": 1, "tasks_per_node": 1, "cpus_per_task": 1, "accelerators_per_node": 0, "duration": "00:05:00", "priority": "default"}
  },
  "data": {"input_boundary_ref": "project-input", "output_boundary_ref": "project-output", "checkpoint_boundary_ref": "project-checkpoint", "retention_policy_ref": "project-retention"},
  "validation": {"correctness_gate": "project-smoke", "numerical_contract": "project-tolerance", "checkpoint_contract": "project-restart", "performance_deferred": true},
  "authority": {"licenses_reviewed": true, "external_downloads_authorized": false, "credential_refs": ["runtime-registry"]}
}
EOF
}

expect_failure() {
    label=$1
    shift
    if "$@" >"$TEST_ROOT/$label.out" 2>&1; then
        printf 'FAIL: %s unexpectedly passed\n' "$label" >&2
        exit 1
    fi
}

PYTHONPYCACHEPREFIX=$TEST_ROOT/pycache python3 -m py_compile "$VALIDATOR"
write_valid ready
"$VALIDATOR" --require-ready "$manifest" | grep -F 'status=pass phase=ready targets=2 artifacts=1 libraries=1' >/dev/null
write_valid draft
"$VALIDATOR" "$manifest" | grep -F 'status=pass phase=draft' >/dev/null
expect_failure draft-not-ready "$VALIDATOR" --require-ready "$manifest"

write_valid ready
sed -i 's/"schema": 1,/"schema": 1, "unexpected": true,/' "$manifest"
expect_failure unknown-field "$VALIDATOR" "$manifest"
grep -F 'undeclared field is present' "$TEST_ROOT/unknown-field.out" >/dev/null

write_valid ready
sed -i 's/sha256:0000000000000000000000000000000000000000000000000000000000000000/sha256:bad/' "$manifest"
expect_failure digest "$VALIDATOR" "$manifest"

write_valid ready
sed -i 's/runtime-registry/runtime\/registry/' "$manifest"
expect_failure credential-ref "$VALIDATOR" "$manifest"

ln -s "$manifest" "$TEST_ROOT/link.json"
expect_failure symlink "$VALIDATOR" "$TEST_ROOT/link.json"
printf '%s\n' 'HPC project intake validator tests: PASS'
