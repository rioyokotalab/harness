#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
board = root / "TODO.md"
archive = root / "docs/history/TODO-full-archive-2026-07-30.md"
index = root / "docs/tasks/index.tsv"
config = json.loads((root / "docs/tasks/config.json").read_text())
text = board.read_text(encoding="utf-8")

assert len(text.splitlines()) <= 80
assert len(text.split()) <= 600
assert hashlib.sha256(archive.read_bytes()).hexdigest() == (
    "d55459a2944fdb86986677d7fce6bdcbccd0b86a6b6eee799f60fe183a9ff95a"
)
assert set(config) == {
    "schema", "repository", "prefix", "next_id", "max_active_record_words"
}
assert config["schema"] == 1
assert config["repository"] == "harness"
assert config["prefix"] == "Har"
assert isinstance(config["next_id"], int) and config["next_id"] > 0
assert config["max_active_record_words"] == 900
assert f"Next free ID: Har-{config['next_id']:03d}." in text

board_tasks = re.findall(r"^### (Har-\d{3}) —", text, re.MULTILINE)
assert board_tasks and len(board_tasks) == len(set(board_tasks))
with index.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
assert list(rows[0]) == ["task", "state", "summary", "source"]
by_task = {row["task"]: row for row in rows}
assert len(by_task) == len(rows)
nonterminal = {
    row["task"] for row in rows
    if row["task"].startswith("Har-") and row["state"] in {"active", "blocked", "time-gated"}
}
assert set(board_tasks) == nonterminal

numbers = []
indexed_sources = set()
for row in rows:
    assert re.fullmatch(r"(?:Har|T)-\d+", row["task"]), row
    assert row["state"] in {"active", "time-gated", "blocked", "complete"}, row
    assert row["summary"] and row["source"]
    if row["task"].startswith("Har-"):
        numbers.append(int(row["task"].split("-")[1]))
        assert (root / f"docs/tasks/{row['task']}.md").is_file()
    for source in row["source"].split(";"):
        indexed_sources.add(source)
        candidate = Path(source)
        assert not candidate.is_absolute() and ".." not in candidate.parts
        assert (root / candidate).exists(), (row["task"], source)
assert numbers == sorted(numbers, reverse=True)
assert config["next_id"] > max(numbers)

for task in board_tasks:
    assert f"`docs/tasks/{task}.md`" in text
    assert "TODO.md" in by_task[task]["source"].split(";")
for task, row in by_task.items():
    if task.startswith("Har-") and task not in board_tasks:
        assert row["state"] == "complete", (task, row["state"])
        assert "TODO.md" not in row["source"].split(";")

for task, state in {
    "T-351": "complete",
    "Har-196": "time-gated",
    "Har-328": "time-gated",
    "Har-303": "blocked",
    "Har-371": "complete",
    "Har-376": "complete",
    "T-350": "complete",
}.items():
    assert by_task[task]["state"] == state

for required in (
    "docs/plans/t351-autonomy-efficiency.md",
    "Complete upon protected merge of PR #484",
    "2026-08-08",
):
    assert required in "\n".join(
        path.read_text(encoding="utf-8") for path in sorted((root / "docs/tasks").glob("*.md"))
    )
for archive_path in sorted((root / "docs/history").glob("TODO-full-archive-*.md")):
    assert archive_path.relative_to(root).as_posix() in indexed_sources

assert not (root / "PRODUCER.md").exists()
assert not (root / "docs/producer").exists()
assert not (root / "docs/consumer").exists()
assert (root / "docs/history/harness-producer-consumer-ledger-2026-08-05/README.md").is_file()

print(f"TASK_LEDGER status=pass rows={len(rows)} active={len(board_tasks)}")
PY
