#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ROUTES=$ROOT/profiles/hpc-multinode-mpi-routes.tsv
python3 - "$ROUTES" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
rows = []
for number, line in enumerate(path.read_text().splitlines(), 1):
    if not line or line.startswith("#"):
        continue
    fields = line.split("|")
    assert len(fields) == 7, (number, len(fields))
    assert all(fields), number
    assert all(" " not in field and "\t" not in field for field in fields), number
    rows.append(fields)
hosts = [row[0] for row in rows]
assert hosts == ["local", "ab", "ab2", "ri", "al", "rc", "t4"]
assert len(set(hosts)) == 7
allowed = {"candidate_needs_dry_run", "resource_change_gated", "no_base_route", "candidate_documented"}
assert all(row[1] in allowed for row in rows)
assert [row[1] for row in rows].count("no_base_route") == 2
assert next(row for row in rows if row[0] == "al")[1] == "candidate_documented"
assert all("priority" not in row[3].lower() and "nice" not in row[3].lower() for row in rows)
PY
printf '%s\n' 'multi-node MPI route tests: PASS'
