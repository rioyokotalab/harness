#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
from __future__ import annotations

import csv
import hashlib
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
board = root / "TODO.md"
archive = root / "docs/history/TODO-full-archive-2026-07-30.md"
index = root / "docs/tasks/index.tsv"

text = board.read_text(encoding="utf-8")
lines = text.splitlines()
words = text.split()
assert len(lines) <= 250, len(lines)
assert len(words) <= 2500, len(words)
assert hashlib.sha256(archive.read_bytes()).hexdigest() == (
    "d55459a2944fdb86986677d7fce6bdcbccd0b86a6b6eee799f60fe183a9ff95a"
)
assert "Next free ID: T-352." in text
assert re.findall(r"^### (T-\d+) —", text, re.MULTILINE) == [
    "T-351",
    "T-196",
    "T-328",
    "T-303",
]
for required in (
    "docs/plans/t351-autonomy-efficiency.md",
    "docs/audits/t351-autonomy-efficiency/time-slices.md",
    "integrate and review the two isolated Harness implementation",
    "Do not write hosting settings",
    "94950",
    "2064918.pbs1",
    "2064919.pbs1",
    "10386",
    "260847",
    "8270230",
    "176525.qjcm",
    "4275926",
    "2026-08-08",
    "SHA256:nxj4PfZ55OqTcVm5HReHI6IVy9MMcBQ+BbfrJfZRHes",
):
    assert required in text, required

with index.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
assert rows
assert list(rows[0]) == ["task", "state", "summary", "source"]
by_task = {row["task"]: row for row in rows}
assert len(by_task) == len(rows)
for task, state in {
    "T-351": "active",
    "T-196": "time-gated",
    "T-328": "time-gated",
    "T-303": "blocked",
    "T-350": "complete",
}.items():
    assert by_task[task]["state"] == state
    for source in by_task[task]["source"].split(";"):
        assert (root / source).is_file(), (task, source)

print(
    f"TASK_LEDGER status=pass lines={len(lines)} words={len(words)} "
    f"index_rows={len(rows)}"
)
PY
