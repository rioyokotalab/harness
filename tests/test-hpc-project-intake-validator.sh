#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATOR=$ROOT/tools/hpc-project-intake-validate.py
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/hpc-project-intake-validator.XXXXXX")
manifest=$TEST_ROOT/intake.json

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$ROOT/tests/guarded-test-cleanup.sh" "$ROOT/bin/harness" \
        "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

sed_in_place() {
    case $(uname -s) in Darwin) sed -i '' "$1" "$2" ;; *) sed -i "$1" "$2" ;; esac
}

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

python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$VALIDATOR"
if grep -E 'from __future__ import annotations|list\[|dict\[|tuple\[|Path \|' "$VALIDATOR" >/dev/null; then
    printf '%s\n' 'FAIL: validator requires newer-than-Python-3.6 syntax' >&2
    exit 1
fi
PYTHONDONTWRITEBYTECODE=1 python3 - "$VALIDATOR" <<'PY'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("intake_validator", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
try:
    module.validate_schema_definition({"type": "string", "maxLength": 3})
except module.ValidationError:
    pass
else:
    raise SystemExit("unsupported schema keyword was accepted")
PY
write_valid ready
"$VALIDATOR" --require-ready "$manifest" | grep -F 'status=pass phase=ready targets=2 artifacts=1 libraries=1' >/dev/null
write_valid draft
"$VALIDATOR" "$manifest" | grep -F 'status=pass phase=draft' >/dev/null
expect_failure draft-not-ready "$VALIDATOR" --require-ready "$manifest"

write_valid ready
sed_in_place 's/"schema": 1,/"schema": 1, "unexpected": true,/' "$manifest"
expect_failure unknown-field "$VALIDATOR" "$manifest"
grep -F 'undeclared field is present' "$TEST_ROOT/unknown-field.out" >/dev/null

write_valid ready
sed_in_place 's/sha256:0000000000000000000000000000000000000000000000000000000000000000/sha256:bad/' "$manifest"
expect_failure digest "$VALIDATOR" "$manifest"

write_valid ready
sed_in_place 's/runtime-registry/runtime\/registry/' "$manifest"
expect_failure credential-ref "$VALIDATOR" "$manifest"

ln -s "$manifest" "$TEST_ROOT/link.json"
expect_failure symlink "$VALIDATOR" "$TEST_ROOT/link.json"
printf '%s\n' 'HPC project intake validator tests: PASS'
