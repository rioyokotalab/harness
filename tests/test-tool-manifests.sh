#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
names = ("agents", "python", "runtimes", "source-dependencies", "sources")
tables = {}
for name in names:
    path = root / f"tools/{name}.tsv"
    lines = path.read_text(encoding="utf-8").splitlines()
    assert lines and lines[0].startswith("# "), path
    header = lines[0][2:].split("|")
    rows = [line.split("|") for line in lines[1:] if line]
    assert rows and all(len(row) == len(header) for row in rows), path
    assert all(all(field for field in row) for row in rows), path
    assert len({tuple(row) for row in rows}) == len(rows), path
    for row in rows:
        values = dict(zip(header, row))
        for field, value in values.items():
            if field.endswith("url"):
                assert value.startswith("https://"), (path, field)
            if field.endswith("sha256"):
                assert re.fullmatch(r"[0-9a-f]{64}", value), (path, field)
            if field == "publisher-sha3-256":
                assert value == "none" or re.fullmatch(r"[0-9a-f]{64}", value)
    tables[name] = (header, rows)

source_names = {row[0] for row in tables["sources"][1]}
for row in tables["source-dependencies"][1]:
    assert row[0] in source_names, row[0]

print(f"TOOL_MANIFESTS status=pass tables={len(tables)}")
PY
