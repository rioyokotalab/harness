#!/usr/bin/env python3
"""Validate the repository-local producer/consumer task contract."""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "docs/producer/config.json"
INDEX_PATH = ROOT / "docs/producer/index.tsv"
PRODUCER_PATH = ROOT / "PRODUCER.md"
PRODUCER_PREFIXES = ("PRODUCER.md", "docs/producer/")
ALLOWED_STATES = {"ready", "gated", "claimed", "complete", "cancelled"}
ALLOWED_CONSUMERS = {"any", "codex", "claude"}
ALLOWED_RECORD_STATUSES = {"active", "blocked", "complete"}
MAX_ACTIVE_RECORD_WORDS = 900
FORBIDDEN_FIELDS = {
    "credential", "credentials", "secret", "secrets", "token", "password",
    "private_payload", "message_body", "event_body", "attachment",
}


def fail(message: str) -> None:
    raise SystemExit(f"PRODUCER_LEDGER status=failed reason={message}")


def read_config() -> dict[str, object]:
    try:
        config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid-config:{exc}")
    required = {"schema", "repository", "prefix", "next_id", "public", "max_packet_bytes"}
    if set(config) != required or config["schema"] != 1:
        fail("config-schema")
    if not re.fullmatch(r"[a-z][a-z0-9-]*", str(config["repository"])):
        fail("config-repository")
    if not re.fullmatch(r"[A-Z][A-Za-z]*", str(config["prefix"])):
        fail("config-prefix")
    if not isinstance(config["next_id"], int) or config["next_id"] < 1:
        fail("config-next-id")
    if not isinstance(config["public"], bool):
        fail("config-public")
    if (
        not isinstance(config["max_packet_bytes"], int)
        or not 512 <= config["max_packet_bytes"] <= 8192
    ):
        fail("config-packet-budget")
    return config


def metadata(path: Path, maximum: int) -> tuple[dict[str, str], str]:
    if not path.is_file() or path.is_symlink():
        fail(f"unsafe-file:{path.relative_to(ROOT)}")
    data = path.read_bytes()
    if len(data) > maximum:
        fail(f"oversized:{path.relative_to(ROOT)}")
    text = data.decode("utf-8")
    head, marker, _body = text.partition("\n---\n")
    if not marker:
        fail(f"missing-metadata-boundary:{path.relative_to(ROOT)}")
    values: dict[str, str] = {}
    for line in head.splitlines():
        key, separator, value = line.partition(": ")
        if not separator or not re.fullmatch(r"[a-z_]+", key) or key in values:
            fail(f"invalid-metadata:{path.relative_to(ROOT)}")
        if key in FORBIDDEN_FIELDS:
            fail(f"sensitive-field:{path.relative_to(ROOT)}:{key}")
        values[key] = value
    if "../" in text or "/home/" in text or "/mnt/" in text:
        fail(f"cross-repository-path:{path.relative_to(ROOT)}")
    return values, text


def read_rows() -> list[dict[str, str]]:
    if not INDEX_PATH.is_file() or INDEX_PATH.is_symlink():
        fail("unsafe-index")
    with INDEX_PATH.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    fields = ["task", "state", "priority", "created", "packet"]
    if not rows or list(rows[0]) != fields:
        fail("index-schema")
    return rows


def producer_queue_ids(
    text: str, task_pattern: re.Pattern[str]
) -> tuple[str, ...]:
    """Read task IDs only from the exact human queue table."""
    lines = text.splitlines()
    headings = [index for index, line in enumerate(lines) if line == "## Queue"]
    if len(headings) != 1:
        fail("producer-queue-section")
    index = headings[0] + 1
    while index < len(lines) and not lines[index]:
        index += 1
    expected = (
        "| Task | State | Priority | Packet |",
        "| --- | --- | ---: | --- |",
    )
    if lines[index : index + 2] != list(expected):
        fail("producer-queue-format")
    tasks: list[str] = []
    for line in lines[index + 2 :]:
        if not line or line.startswith("## "):
            break
        if not line.startswith("| ") or not line.endswith(" |"):
            fail("producer-queue-format")
        cells = [cell.strip() for cell in line[1:-1].split("|")]
        if len(cells) != 4 or task_pattern.fullmatch(cells[0]) is None:
            fail("producer-queue-row")
        tasks.append(cells[0])
    duplicates = sorted(task for task in set(tasks) if tasks.count(task) > 1)
    if duplicates:
        fail(f"producer-queue-duplicate:{duplicates[0]}")
    return tuple(tasks)


def validate_active_records(prefix: str, tasks: set[str]) -> None:
    record_dir = ROOT / "docs/tasks"
    for path in sorted(record_dir.glob(f"{prefix}-*.md")):
        if not path.is_file() or path.is_symlink():
            fail(f"unsafe-task-record:{path.name}")
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            fail(f"unreadable-task-record:{path.name}:{exc}")
        # Records predating the metadata-managed lifecycle remain historical.
        if not text.startswith("task: "):
            continue
        head, marker, _body = text.partition("\n---\n")
        if not marker:
            fail(f"task-record-metadata:{path.name}")
        values: dict[str, str] = {}
        for line in head.splitlines():
            key, separator, value = line.partition(": ")
            if not separator or not re.fullmatch(r"[a-z_]+", key) or key in values:
                fail(f"task-record-metadata:{path.name}")
            values[key] = value
        task = values.get("task", "")
        status = values.get("status", "")
        if task != path.stem or task not in tasks:
            fail(f"task-record-identity:{path.name}")
        if status not in ALLOWED_RECORD_STATUSES:
            fail(f"task-record-status:{path.name}")
        words = len(text.split())
        if status == "active" and words > MAX_ACTIVE_RECORD_WORDS:
            fail(f"active-record-words:{task}:{words}>{MAX_ACTIVE_RECORD_WORDS}")


def validate(
    *, require_converged: bool = False, emit: bool = True
) -> tuple[dict[str, object], list[dict[str, str]], dict[str, dict[str, str]]]:
    config = read_config()
    assignment_path = ROOT / "docs/producer/assignment.tsv"
    with assignment_path.open(encoding="utf-8", newline="") as handle:
        assignments = list(csv.DictReader(handle, delimiter="\t"))
    if not assignments or list(assignments[0]) != ["client", "slot", "state"]:
        fail("assignment-schema")
    slots: set[str] = set()
    for assignment in assignments:
        if assignment["client"] not in ALLOWED_CONSUMERS:
            fail("assignment-client")
        if not re.fullmatch(r"[a-z][a-z0-9-]*", assignment["slot"]):
            fail("assignment-slot")
        if assignment["slot"] in slots:
            fail("assignment-duplicate-slot")
        slots.add(assignment["slot"])
        if assignment["state"] not in {"active", "idle", "producer"}:
            fail("assignment-state")
    nightly = ROOT / "docs/producer/NIGHTLY.md"
    if (
        not nightly.is_file()
        or nightly.is_symlink()
        or nightly.stat().st_size > 4096
    ):
        fail("nightly-contract")
    repository = str(config["repository"])
    prefix = str(config["prefix"])
    task_pattern = re.compile(rf"{re.escape(prefix)}-(\d{{3}})")
    rows = read_rows()
    seen: set[str] = set()
    numbers: list[int] = []
    packets: dict[str, dict[str, str]] = {}
    prior_order: tuple[int, str, str] | None = None
    producer_text = PRODUCER_PATH.read_text(encoding="utf-8")
    if len(producer_text.encode()) > 4096:
        fail("oversized-producer-entrypoint")
    if f"Next free ID: {prefix}-{int(config['next_id']):03d}." not in producer_text:
        fail("next-id-entrypoint")
    queue_tasks = producer_queue_ids(producer_text, task_pattern)
    for row in rows:
        match = task_pattern.fullmatch(row["task"])
        if not match or row["task"] in seen:
            fail(f"invalid-or-duplicate-task:{row['task']}")
        seen.add(row["task"])
        numbers.append(int(match.group(1)))
        if row["state"] not in ALLOWED_STATES:
            fail(f"invalid-state:{row['task']}")
        try:
            priority = int(row["priority"])
        except ValueError:
            fail(f"invalid-priority:{row['task']}")
        if not 0 <= priority <= 999 or not re.fullmatch(r"20\d\d-\d\d-\d\d", row["created"]):
            fail(f"invalid-ordering:{row['task']}")
        order = (priority, row["created"], row["task"])
        if prior_order is not None and order < prior_order:
            fail("index-order")
        prior_order = order
        expected_packet = f"docs/producer/tasks/{row['task']}.md"
        if row["packet"] != expected_packet:
            fail(f"packet-path:{row['task']}")
        packet_path = ROOT / row["packet"]
        values, packet_text = metadata(packet_path, int(config["max_packet_bytes"]))
        required = {
            "task", "repository", "state", "priority", "created",
            "consumer", "record", "authority",
        }
        if set(values) != required:
            fail(f"packet-schema:{row['task']}")
        for key in ("task", "created"):
            if values[key] != row[key]:
                fail(f"packet-index-mismatch:{row['task']}:{key}")
        if values["state"] not in ALLOWED_STATES:
            fail(f"packet-state:{row['task']}")
        try:
            packet_priority = int(values["priority"])
        except ValueError:
            fail(f"packet-priority:{row['task']}")
        if not 0 <= packet_priority <= 999:
            fail(f"packet-priority:{row['task']}")
        if values["repository"] != repository or values["consumer"] not in ALLOWED_CONSUMERS:
            fail(f"packet-routing:{row['task']}")
        if values["record"] != "pending":
            record = Path(values["record"])
            if (
                record.is_absolute()
                or ".." in record.parts
                or not (ROOT / record).is_file()
            ):
                fail(f"packet-record:{row['task']}")
        if "tmux" in packet_text.lower() or "harness:" in packet_text.lower():
            fail(f"assignment-coupling:{row['task']}")
        if bool(config["public"]) and re.search(
            r"PRIVATE_(?:PERSONAL|STUDENTS)_CANARY", packet_text
        ):
            fail(f"public-privacy-canary:{row['task']}")
        packets[row["task"]] = values
    queue_set = set(queue_tasks)
    unknown_queue = sorted(queue_set - seen)
    if unknown_queue:
        fail(f"producer-queue-unknown:{unknown_queue[0]}")
    terminal = {
        row["task"] for row in rows if row["state"] in {"complete", "cancelled"}
    }
    stale_queue = sorted(queue_set & terminal)
    if stale_queue:
        fail(f"producer-queue-stale-terminal:{stale_queue[0]}")
    nonterminal = seen - terminal
    omitted_queue = sorted(nonterminal - queue_set)
    if omitted_queue:
        fail(f"producer-queue-omitted:{omitted_queue[0]}")
    if max(numbers) >= int(config["next_id"]):
        fail("next-id-not-free")
    validate_active_records(prefix, seen)
    board_text = (ROOT / "TODO.md").read_text(encoding="utf-8")
    board_ids = set(re.findall(rf"\b{re.escape(prefix)}-\d{{3}}\b", board_text))
    if not board_ids <= seen:
        fail(f"unproduced-board-task:{','.join(sorted(board_ids - seen))}")
    receipt_dir = ROOT / "docs/consumer/receipts"
    receipts: dict[str, dict[str, str]] = {}
    for path in sorted(receipt_dir.glob(f"{prefix}-*.md")) if receipt_dir.is_dir() else []:
        values, text = metadata(path, 4096)
        if set(values) != {"task", "status", "updated", "validation"}:
            fail(f"receipt-schema:{path.name}")
        if values["task"] not in seen or values["status"] not in {"complete", "blocked"}:
            fail(f"receipt-routing:{path.name}")
        if path.stem != values["task"] or values["task"] in receipts:
            fail(f"receipt-identity:{path.name}")
        if re.search(r"(?im)^authority(?: granted)?:", text):
            fail(f"receipt-authority:{path.name}")
        receipts[values["task"]] = values

    reconciliation_pending: list[str] = []
    executable: list[dict[str, str]] = []
    for row in rows:
        task = row["task"]
        state = row["state"]
        receipt = receipts.get(task)
        record_path = ROOT / f"docs/tasks/{task}.md"
        if state in {"claimed", "complete"} and not record_path.is_file():
            fail(f"task-record:{task}")
        if state == "complete":
            if not receipt or receipt["status"] != "complete":
                fail(f"terminal-receipt:{task}")
        elif state == "gated" and receipt and receipt["status"] == "blocked":
            pass
        elif receipt:
            reconciliation_pending.append(task)
        if state in {"ready", "claimed"} and receipt is None:
            executable.append(row)
        if state in {"complete", "cancelled"} and task in board_ids:
            fail(f"terminal-board-task:{task}")
        if receipt and task in board_ids:
            fail(f"receipt-board-task:{task}")

    for assignment in assignments:
        if assignment["state"] != "active":
            continue
        client = assignment["client"]
        compatible_executable = any(
            client == "any"
            or packets[row["task"]]["consumer"] in {"any", client}
            for row in executable
        )
        compatible_handoff = any(
            row["task"] in reconciliation_pending
            and (
                client == "any"
                or packets[row["task"]]["consumer"] in {"any", client}
            )
            for row in rows
        )
        if not compatible_executable and not compatible_handoff:
            fail(f"assignment-without-executable-task:{assignment['slot']}")

    if require_converged and reconciliation_pending:
        fail(f"receipt-disposition:{reconciliation_pending[0]}")
    if emit:
        print(
            f"PRODUCER_LEDGER status=pass repository={repository} "
            f"tasks={len(rows)} board_tasks={len(board_ids)} "
            f"reconciliation_pending={len(reconciliation_pending)}"
        )
    return config, rows, receipts


def next_ready() -> None:
    _config, rows, receipts = validate(emit=False)
    for row in rows:
        if row["state"] == "ready" and row["task"] not in receipts:
            print(
                "PRODUCER_LEDGER_SELECTION status=ready "
                f"task={row['task']} packet={row['packet']} "
                "disposition=ready "
                "disposition_source=docs/producer/index.tsv "
                "packet_state=publication-only"
            )
            return
    print("PRODUCER_LEDGER_SELECTION status=idle")


def changed_paths(base: str) -> list[str]:
    git = shutil.which("git")
    if git is None:
        fail("git-unavailable")
    tracked = subprocess.run(  # noqa: S603
        [
            git, "-C", str(ROOT), "diff", "--name-only",
            "--diff-filter=ACMRTUXB", base,
        ],
        check=True, text=True, stdout=subprocess.PIPE,
    )
    untracked = subprocess.run(  # noqa: S603
        [git, "-C", str(ROOT), "ls-files", "--others", "--exclude-standard"],
        check=True, text=True, stdout=subprocess.PIPE,
    )
    return sorted(
        set(tracked.stdout.splitlines()) | set(untracked.stdout.splitlines())
    )


def changed_published_packets(base: str) -> list[str]:
    git = shutil.which("git")
    if git is None:
        fail("git-unavailable")
    result = subprocess.run(  # noqa: S603
        [
            git, "-C", str(ROOT), "diff", "--name-only",
            "--diff-filter=MDTRUXB", base, "--", "docs/producer/tasks",
        ],
        check=True, text=True, stdout=subprocess.PIPE,
    )
    return [line for line in result.stdout.splitlines() if line]


def check_diff(base: str, role: str) -> None:
    config = read_config()
    prefix = str(config["prefix"])
    tasks = {row["task"] for row in read_rows()}
    paths = changed_paths(base)
    immutable = changed_published_packets(base)
    if immutable:
        fail(f"immutable-packet:{','.join(sorted(immutable))}")
    if role == "producer":
        advisory = [
            path for path in paths
            if path != "PRODUCER.md" and not path.startswith("docs/producer/")
        ]
    else:
        advisory = [
            path for path in paths
            if path == "PRODUCER.md" or path.startswith("docs/producer/")
        ]
        for path in paths:
            match = re.fullmatch(rf"docs/tasks/({re.escape(prefix)}-\d{{3}})\.md", path)
            if match and match.group(1) not in tasks:
                advisory.append(path)
    advisory_count = len(set(advisory))
    advisory_state = "role-overlap" if advisory_count else "none"
    print(
        f"PRODUCER_LEDGER_DIFF status=pass role={role} paths={len(paths)} "
        f"advisory={advisory_state} advisory_paths={advisory_count}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    validate_parser = sub.add_parser("validate")
    validate_parser.add_argument("--require-converged", action="store_true")
    sub.add_parser("next-ready")
    for role in ("producer", "consumer"):
        command = sub.add_parser(f"check-{role}-diff")
        command.add_argument("--base", required=True)
    args = parser.parse_args()
    if args.command == "validate":
        validate(require_converged=args.require_converged)
    elif args.command == "next-ready":
        next_ready()
    else:
        check_diff(args.base, args.command.removeprefix("check-").removesuffix("-diff"))


if __name__ == "__main__":
    main()
