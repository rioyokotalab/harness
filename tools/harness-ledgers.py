#!/usr/bin/env python3
"""Validate Harness's direct Har and nightly Nit ledgers."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TASK_CONFIG = ROOT / "docs/tasks/config.json"
TASK_INDEX = ROOT / "docs/tasks/index.tsv"
TASK_BOARD = ROOT / "TODO.md"
NIGHTLY_CONFIG = ROOT / "docs/nightly/config.json"
NIGHTLY_INDEX = ROOT / "docs/nightly/index.tsv"
NIGHTLY_BOARD = ROOT / "NIGHTLY.md"

ORDINARY_ID = re.compile(r"Har-(\d{3})")
NIGHTLY_ID = re.compile(r"Nit-(\d{3})")
ORDINARY_STATES = {"active", "blocked", "complete", "time-gated"}
ORDINARY_NONTERMINAL = {"active", "blocked", "time-gated"}
NIGHTLY_STATES = {"ready", "active", "gated", "blocked", "complete", "canceled"}
NIGHTLY_NONTERMINAL = {"ready", "active", "gated", "blocked"}
RETIRED_PATHS = (
    "PRODUCER.md",
    "docs/producer",
    "docs/consumer",
    "tools/producer-ledger.py",
    "tools/consumer_protocol.py",
    "tools/consumer_validation.py",
    "libexec/harness-producer-ledger",
    "docs/agent-policy/producer-consumer.md",
)


class LedgerError(ValueError):
    """Stable, value-free ledger failure."""


def fail(reason: str) -> None:
    print(f"HARNESS_LEDGERS status=failed reason={reason}", file=sys.stderr)
    raise SystemExit(1)


def read_config(path: Path, prefix: str) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise LedgerError("config-invalid") from error
    if (
        not isinstance(value, dict)
        or set(value) != {
            "schema", "repository", "prefix", "next_id", "max_active_record_words"
        }
        or value["schema"] != 1
        or value["repository"] != "harness"
        or value["prefix"] != prefix
        or not isinstance(value["next_id"], int)
        or value["next_id"] < 1
        or not isinstance(value["max_active_record_words"], int)
        or not 1 <= value["max_active_record_words"] <= 900
    ):
        raise LedgerError("config-schema")
    return value


def read_tsv(path: Path, fields: list[str]) -> list[dict[str, str]]:
    try:
        with path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter="\t")
            if reader.fieldnames != fields:
                raise LedgerError("index-header")
            rows = list(reader)
    except OSError as error:
        raise LedgerError("index-unavailable") from error
    if any(set(row) != set(fields) or any(value is None for value in row.values()) for row in rows):
        raise LedgerError("index-row")
    return rows


def source_exists(value: str) -> bool:
    path = Path(value)
    resolved = ROOT / path
    return (
        not path.is_absolute()
        and ".." not in path.parts
        and resolved.exists()
        and not resolved.is_symlink()
    )


def validate_ordinary() -> tuple[dict[str, object], list[dict[str, str]]]:
    config = read_config(TASK_CONFIG, "Har")
    rows = read_tsv(TASK_INDEX, ["task", "state", "summary", "source"])
    seen: set[str] = set()
    numbers: list[int] = []
    nonterminal: set[str] = set()
    for row in rows:
        match = ORDINARY_ID.fullmatch(row["task"])
        if match:
            numbers.append(int(match.group(1)))
            if not (ROOT / f"docs/tasks/{row['task']}.md").is_file():
                raise LedgerError("ordinary-record")
            if row["state"] not in ORDINARY_STATES:
                raise LedgerError("ordinary-state")
            if row["state"] in ORDINARY_NONTERMINAL:
                nonterminal.add(row["task"])
                if len((ROOT / f"docs/tasks/{row['task']}.md").read_text(
                    encoding="utf-8"
                ).split()) > int(config["max_active_record_words"]):
                    raise LedgerError("ordinary-record-size")
        elif not re.fullmatch(r"T-\d+", row["task"]):
            raise LedgerError("ordinary-id")
        if row["task"] in seen:
            raise LedgerError("ordinary-duplicate")
        seen.add(row["task"])
        if not row["summary"] or not row["source"]:
            raise LedgerError("ordinary-empty")
        if not all(source_exists(source) for source in row["source"].split(";")):
            raise LedgerError("ordinary-source")
    next_id = int(config["next_id"])
    if numbers and next_id <= max(numbers):
        raise LedgerError("ordinary-next-id")
    if numbers != sorted(numbers, reverse=True):
        raise LedgerError("ordinary-order")
    board = TASK_BOARD.read_text(encoding="utf-8")
    if len(board.splitlines()) > 80 or len(board.split()) > 600:
        raise LedgerError("ordinary-board-size")
    if f"Next free ID: Har-{next_id:03d}." not in board:
        raise LedgerError("ordinary-board-next-id")
    board_tasks = set(re.findall(r"^### (Har-\d{3}) —", board, re.MULTILINE))
    if board_tasks != nonterminal:
        raise LedgerError("ordinary-board-parity")
    indexed_sources = {
        source
        for row in rows
        for source in row["source"].split(";")
    }
    for row in rows:
        task = row["task"]
        sources = row["source"].split(";")
        if task in nonterminal:
            if (
                "TODO.md" not in sources
                or f"`docs/tasks/{task}.md`" not in board
            ):
                raise LedgerError("ordinary-board-pointer")
        elif task.startswith("Har-") and "TODO.md" in sources:
            raise LedgerError("ordinary-complete-board-source")
    for archive in (ROOT / "docs/history").glob("TODO-full-archive-*.md"):
        if archive.relative_to(ROOT).as_posix() not in indexed_sources:
            raise LedgerError("ordinary-archive-source")
    return config, rows


def read_nightly_record(path: Path, word_limit: int) -> dict[str, str]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise LedgerError("nightly-record") from error
    if len(lines) < 4 or lines[3] != "---":
        raise LedgerError("nightly-record-schema")
    values: dict[str, str] = {}
    for line, key in zip(lines[:3], ("task", "status", "updated")):
        if not line.startswith(f"{key}: "):
            raise LedgerError("nightly-record-schema")
        values[key] = line.split(": ", 1)[1]
    if len(path.read_text(encoding="utf-8").split()) > word_limit:
        raise LedgerError("nightly-record-size")
    return values


def nightly_board_rows(text: str) -> dict[str, tuple[str, int, str]]:
    rows: dict[str, tuple[str, int, str]] = {}
    pattern = re.compile(
        r"^\| (Nit-\d{3}) \| (ready|active|gated|blocked) \| (\d+) \| "
        r"`(docs/nightly/tasks/Nit-\d{3}\.md)` \|$",
        re.MULTILINE,
    )
    for task, state, priority, record in pattern.findall(text):
        if task in rows or record != f"docs/nightly/tasks/{task}.md":
            raise LedgerError("nightly-board-row")
        rows[task] = (state, int(priority), record)
    return rows


def validate_nightly() -> tuple[dict[str, object], list[dict[str, str]]]:
    config = read_config(NIGHTLY_CONFIG, "Nit")
    rows = read_tsv(
        NIGHTLY_INDEX,
        ["task", "state", "priority", "created", "record", "summary"],
    )
    seen: set[str] = set()
    numbers: list[int] = []
    expected_board: dict[str, tuple[str, int, str]] = {}
    for row in rows:
        match = NIGHTLY_ID.fullmatch(row["task"])
        if not match or row["task"] in seen:
            raise LedgerError("nightly-id")
        seen.add(row["task"])
        numbers.append(int(match.group(1)))
        if row["state"] not in NIGHTLY_STATES:
            raise LedgerError("nightly-state")
        try:
            priority = int(row["priority"])
        except ValueError as error:
            raise LedgerError("nightly-priority") from error
        if not 0 <= priority <= 999 or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", row["created"]):
            raise LedgerError("nightly-fields")
        expected = f"docs/nightly/tasks/{row['task']}.md"
        if row["record"] != expected or not row["summary"]:
            raise LedgerError("nightly-routing")
        record = read_nightly_record(
            ROOT / expected, int(config["max_active_record_words"])
        )
        if record["task"] != row["task"] or record["status"] != row["state"]:
            raise LedgerError("nightly-record-parity")
        if row["state"] in NIGHTLY_NONTERMINAL:
            expected_board[row["task"]] = (row["state"], priority, expected)
    observed_files = {
        path.stem for path in (ROOT / "docs/nightly/tasks").glob("Nit-*.md")
    }
    if observed_files != seen:
        raise LedgerError("nightly-record-set")
    next_id = int(config["next_id"])
    if numbers and next_id <= max(numbers):
        raise LedgerError("nightly-next-id")
    board = NIGHTLY_BOARD.read_text(encoding="utf-8")
    if f"Next free ID: Nit-{next_id:03d}." not in board:
        raise LedgerError("nightly-board-next-id")
    if nightly_board_rows(board) != expected_board:
        raise LedgerError("nightly-board-parity")
    return config, rows


def validate_retirement() -> None:
    for relative in RETIRED_PATHS:
        if (ROOT / relative).exists() or (ROOT / relative).is_symlink():
            raise LedgerError("self-consumer-infrastructure")


def validate() -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    _ordinary_config, ordinary_rows = validate_ordinary()
    _nightly_config, nightly_rows = validate_nightly()
    if any(row["task"].startswith("Nit-") for row in ordinary_rows):
        raise LedgerError("namespace-crossing")
    validate_retirement()
    print(
        "HARNESS_LEDGERS status=pass "
        f"ordinary={len(ordinary_rows)} nightly={len(nightly_rows)}"
    )
    return ordinary_rows, nightly_rows


def next_task() -> None:
    ordinary_rows, _nightly_rows = validate()
    by_task = {row["task"]: row for row in ordinary_rows}
    board = TASK_BOARD.read_text(encoding="utf-8")
    for task in re.findall(r"^### (Har-\d{3}) —", board, re.MULTILINE):
        if by_task[task]["state"] == "active":
            print(f"HARNESS_TASK_SELECTION status=selected task={task}")
            return
    print("HARNESS_TASK_SELECTION status=idle")


def next_nightly() -> None:
    _ordinary_rows, nightly_rows = validate()
    eligible = [row for row in nightly_rows if row["state"] in {"active", "ready"}]
    eligible.sort(
        key=lambda row: (
            0 if row["state"] == "active" else 1,
            int(row["priority"]), row["created"], int(row["task"].split("-")[1]),
        )
    )
    if not eligible:
        print("HARNESS_NIGHTLY_SELECTION status=idle")
        return
    print(f"HARNESS_NIGHTLY_SELECTION status=selected task={eligible[0]['task']}")


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate")
    subparsers.add_parser("next-task")
    subparsers.add_parser("next-nightly")
    next_id = subparsers.add_parser("next-id")
    next_id.add_argument("ledger", choices=("task", "nightly"))
    arguments = parser.parse_args()
    try:
        if arguments.command == "validate":
            validate()
        elif arguments.command == "next-task":
            next_task()
        elif arguments.command == "next-nightly":
            next_nightly()
        else:
            validate()
            config = read_config(
                TASK_CONFIG if arguments.ledger == "task" else NIGHTLY_CONFIG,
                "Har" if arguments.ledger == "task" else "Nit",
            )
            print(
                "HARNESS_NEXT_ID status=pass "
                f"ledger={arguments.ledger} id={config['prefix']}-{int(config['next_id']):03d}"
            )
    except LedgerError as error:
        fail(str(error))


if __name__ == "__main__":
    main()
