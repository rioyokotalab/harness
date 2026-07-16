#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SCHEMA=$ROOT/docs/schemas/hpc-project-intake.schema.json
DOC=$ROOT/docs/hpc-project-intake.md

python3 - "$SCHEMA" <<'PY'
import json, sys
x = json.load(open(sys.argv[1]))
assert x["$schema"] == "https://json-schema.org/draft/2020-12/schema"
assert x["type"] == "object" and x["additionalProperties"] is False
assert set(x["required"]) == {"schema", "status", "project", "software", "environment", "scheduler", "data", "validation", "authority"}
assert x["properties"]["project"]["properties"]["target_hosts"]["items"]["enum"] == ["local", "ab", "ab2", "ri", "al", "rc", "t4"]
assert x["properties"]["validation"]["properties"]["performance_deferred"] == {"const": True}
assert x["properties"]["authority"]["properties"]["credential_refs"]["items"]["pattern"] == "^[A-Za-z0-9._-]{1,64}$"
encoded = json.dumps(x).lower()
for forbidden in ("password_value", "token_value", "private_key_value", "credential_value"):
    assert forbidden not in encoded
PY
[ "$(grep -Ec '^[0-9]+\. ' "$DOC")" -eq 11 ]
grep -F 'ask one question at a' "$DOC" >/dev/null
grep -F 'identifiers only—never values, contents, hashes, or copied files' "$DOC" >/dev/null
grep -F 'performance deferred' "$DOC" >/dev/null
printf '%s\n' 'HPC project intake tests: PASS'
