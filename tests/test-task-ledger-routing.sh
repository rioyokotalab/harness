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
task_files = {}
for path in sorted((root / "docs/tasks").glob("T-*.md")):
    match = re.fullmatch(r"(T-\d+)\.md", path.name)
    assert match and path.is_file() and not path.is_symlink(), path
    task_files[match.group(1)] = path

text = board.read_text(encoding="utf-8")
lines = text.splitlines()
words = text.split()
assert len(lines) <= 80, len(lines)
assert len(words) <= 600, len(words)
assert hashlib.sha256(archive.read_bytes()).hexdigest() == (
    "d55459a2944fdb86986677d7fce6bdcbccd0b86a6b6eee799f60fe183a9ff95a"
)
board_tasks = re.findall(r"^### (T-\d+) —", text, re.MULTILINE)
assert board_tasks and len(board_tasks) == len(set(board_tasks)), board_tasks
assert set(board_tasks) == set(task_files), (board_tasks, sorted(task_files))
for task in board_tasks:
    assert f"`docs/tasks/{task}.md`" in text, task

task_text = "\n".join(
    task_files[task].read_text(encoding="utf-8") for task in board_tasks
)
for required in (
    "docs/plans/t351-autonomy-efficiency.md",
    "docs/audits/t351-autonomy-efficiency/time-slices.md",
    "Run one final exact-tree suite",
    "hosting settings, rulesets",
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
    assert required in task_text, required

for routed_only in (
    "2064918.pbs1",
    "2026-08-29",
    "nas-03.yokota",
):
    assert routed_only not in text, routed_only

with index.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
assert rows
assert list(rows[0]) == ["task", "state", "summary", "source"]
by_task = {row["task"]: row for row in rows}
assert len(by_task) == len(rows)
task_numbers = []
allowed_states = {"active", "time-gated", "blocked", "complete"}
for row in rows:
    assert re.fullmatch(r"T-\d+", row["task"]), row
    assert row["state"] in allowed_states, row
    assert row["summary"] and row["source"], row
    task_numbers.append(int(row["task"][2:]))
    for source in row["source"].split(";"):
        candidate = Path(source)
        assert not candidate.is_absolute() and ".." not in candidate.parts, (
            row["task"],
            source,
        )
        resolved = root / candidate
        assert resolved.exists() and not resolved.is_symlink(), (row["task"], source)
assert task_numbers == sorted(task_numbers, reverse=True), task_numbers
assert f"Next free ID: T-{max(task_numbers) + 1}." in text
for task in board_tasks:
    assert by_task[task]["state"] != "complete", task
    sources = by_task[task]["source"].split(";")
    assert "TODO.md" in sources, task
    assert f"docs/tasks/{task}.md" in sources, task
for task, state in {
    "T-351": "active",
    "T-196": "time-gated",
    "T-328": "time-gated",
    "T-303": "blocked",
    "T-350": "complete",
}.items():
    assert by_task[task]["state"] == state

print(
    f"TASK_LEDGER status=pass lines={len(lines)} words={len(words)} "
    f"index_rows={len(rows)}"
)
PY
