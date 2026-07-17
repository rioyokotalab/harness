#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
python3 - "$ROOT/docs/audits/llm-hpc-next-actions-2026-07-17.json" <<'PY'
import json
import sys

x = json.load(open(sys.argv[1]))
assert x["schema"] == 1
items = x["items"]
assert [item["id"] for item in items] == [f"Q{i}" for i in range(1, 11)]
assert len({item["id"] for item in items}) == len(items)
allowed = set(x["status_vocabulary"])
assert all(item["status"] in allowed for item in items)
complete = {item["id"] for item in items if item["status"] == "complete"}
assert complete == {"Q1", "Q2", "Q3", "Q4", "Q5", "Q7", "Q9"}
assert {item["job"] for item in items if item.get("job")} == {"91472", "91474", "91483", "91590"}
assert {item["replaces"] for item in items if item.get("replaces")} == {"91220", "91240", "91581"}
assert next(item for item in items if item["id"] == "Q7")["jobs"] == [
    "2046527.pbs1", "2046531.pbs1", "8185316"
]
assert next(item for item in items if item["id"] == "Q9")["requires"] == ["Q5"]
assert next(item for item in items if item["id"] == "Q10")["requires"] == ["Q3"]
assert sum(item["status"] == "executing" for item in items) == 0
assert next(item for item in items if item["id"] == "Q4")["status"] == "complete"
assert next(item for item in items if item["id"] == "Q10")["status"] == "safe_to_plan"
PY
printf '%s\n' 'LLM/HPC next-action queue tests: PASS'
