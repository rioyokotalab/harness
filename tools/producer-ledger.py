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


def validate() -> None:
    config = read_config()
    assignment_path = ROOT / "docs/producer/assignment.tsv"
    with assignment_path.open(encoding="utf-8", newline="") as handle:
        assignments = list(csv.DictReader(handle, delimiter="\t"))
    if (
        len(assignments) != 1
        or list(assignments[0]) != ["client", "slot", "state"]
    ):
        fail("assignment-schema")
    assignment = assignments[0]
    if assignment["client"] not in ALLOWED_CONSUMERS:
        fail("assignment-client")
    if not re.fullmatch(r"[a-z][a-z0-9-]*", assignment["slot"]):
        fail("assignment-slot")
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
    prior_order: tuple[int, str, str] | None = None
    producer_text = PRODUCER_PATH.read_text(encoding="utf-8")
    if len(producer_text.encode()) > 4096:
        fail("oversized-producer-entrypoint")
    if f"Next free ID: {prefix}-{int(config['next_id']):03d}." not in producer_text:
        fail("next-id-entrypoint")
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
        for key in ("task", "state", "priority", "created"):
            if values[key] != row[key]:
                fail(f"packet-index-mismatch:{row['task']}:{key}")
        if values["repository"] != repository or values["consumer"] not in ALLOWED_CONSUMERS:
            fail(f"packet-routing:{row['task']}")
        record = Path(values["record"])
        if record.is_absolute() or ".." in record.parts or not (ROOT / record).is_file():
            fail(f"packet-record:{row['task']}")
        if "tmux" in packet_text.lower() or "harness:" in packet_text.lower():
            fail(f"assignment-coupling:{row['task']}")
        if bool(config["public"]) and re.search(
            r"PRIVATE_(?:PERSONAL|STUDENTS)_CANARY", packet_text
        ):
            fail(f"public-privacy-canary:{row['task']}")
    if max(numbers) >= int(config["next_id"]):
        fail("next-id-not-free")
    board_text = (ROOT / "TODO.md").read_text(encoding="utf-8")
    board_ids = set(re.findall(rf"\b{re.escape(prefix)}-\d{{3}}\b", board_text))
    if not board_ids <= seen:
        fail(f"unproduced-board-task:{','.join(sorted(board_ids - seen))}")
    receipt_dir = ROOT / "docs/consumer/receipts"
    for path in sorted(receipt_dir.glob(f"{prefix}-*.md")) if receipt_dir.is_dir() else []:
        values, text = metadata(path, 4096)
        if set(values) != {"task", "status", "updated", "validation"}:
            fail(f"receipt-schema:{path.name}")
        if values["task"] not in seen or values["status"] not in {"complete", "blocked"}:
            fail(f"receipt-routing:{path.name}")
        if re.search(r"(?im)^authority(?: granted)?:", text):
            fail(f"receipt-authority:{path.name}")
    print(
        f"PRODUCER_LEDGER status=pass repository={repository} "
        f"tasks={len(rows)} board_tasks={len(board_ids)}"
    )


def changed_paths(base: str) -> list[str]:
    git = shutil.which("git")
    if git is None:
        fail("git-unavailable")
    result = subprocess.run(  # noqa: S603
        [
            git, "-C", str(ROOT), "diff", "--name-only",
            "--diff-filter=ACMRTUXB", base,
        ],
        check=True, text=True, stdout=subprocess.PIPE,
    )
    return [line for line in result.stdout.splitlines() if line]


def check_diff(base: str, role: str) -> None:
    config = read_config()
    prefix = str(config["prefix"])
    tasks = {row["task"] for row in read_rows()}
    paths = changed_paths(base)
    if role == "producer":
        bad = [
            path for path in paths
            if path != "PRODUCER.md" and not path.startswith("docs/producer/")
        ]
    else:
        bad = [path for path in paths if path == "PRODUCER.md" or path.startswith("docs/producer/")]
        for path in paths:
            match = re.fullmatch(rf"docs/tasks/({re.escape(prefix)}-\d{{3}})\.md", path)
            if match and match.group(1) not in tasks:
                bad.append(path)
    if bad:
        fail(f"{role}-writer-boundary:{','.join(sorted(set(bad)))}")
    print(f"PRODUCER_LEDGER_DIFF status=pass role={role} paths={len(paths)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")
    for role in ("producer", "consumer"):
        command = sub.add_parser(f"check-{role}-diff")
        command.add_argument("--base", required=True)
    args = parser.parse_args()
    if args.command == "validate":
        validate()
    else:
        check_diff(args.base, args.command.removeprefix("check-").removesuffix("-diff"))


if __name__ == "__main__":
    main()
