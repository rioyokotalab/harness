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
assert {item.get("job") for item in items if item["status"] == "captured_pending"} == {"91220", "91240"}
assert next(item for item in items if item["id"] == "Q9")["requires"] == ["Q5"]
assert next(item for item in items if item["id"] == "Q10")["requires"] == ["Q3"]
assert sum(item["status"] == "executing" for item in items) == 1
assert next(item for item in items if item["id"] == "Q4")["status"] == "blocked_by_scheduler_interface"
PY
printf '%s\n' 'LLM/HPC next-action queue tests: PASS'
