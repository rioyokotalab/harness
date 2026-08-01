#!/usr/bin/env python3
"""Check or refresh the generated values in the context-routing audit."""

from __future__ import annotations

import argparse
import difflib
import os
from pathlib import Path
import re
import tempfile


LABELS = {
    "factual-lookup": "factual lookup",
    "documentation-edit": "documentation edit",
    "ordinary-code-fix": "ordinary code fix",
    "tmux-health-diagnosis": "tmux health diagnosis",
    "unsafe-tail-recovery": "unsafe-tail recovery",
    "fleet-hardening": "fleet hardening",
    "native-hpc-experiment": "native HPC experiment",
    "duration-ledger": "duration ledger",
}
PRIOR_BOARD_WORDS = 1153


def word_count(path: Path) -> int:
    return len(path.read_text(encoding="utf-8").split())


def percentage(before: int, after: int) -> str:
    tenths = (before - after) * 1000 // before
    return f"{tenths // 10}.{tenths % 10}%"


def scenario_values(root: Path, manifest: Path) -> tuple[dict[str, list[str]], int, int]:
    expected: dict[str, list[str]] = {}
    total_reductions: list[int] = []
    nonledger_reductions: list[int] = []
    for raw in manifest.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        scenario, baseline_total, baseline_nonledger, resources = raw.split("|")
        total_before = int(baseline_total)
        nonledger_before = int(baseline_nonledger)
        counts = {
            relative: word_count(root / relative)
            for relative in resources.split(",")
        }
        total_after = sum(counts.values())
        nonledger_after = total_after - counts["TODO.md"]
        total_reductions.append((total_before - total_after) * 1000 // total_before)
        nonledger_reductions.append(
            (nonledger_before - nonledger_after) * 1000 // nonledger_before
        )
        expected[LABELS[scenario]] = [
            f"{total_before:,}",
            f"{total_after:,}",
            percentage(total_before, total_after),
            f"{nonledger_before:,}",
            f"{nonledger_after:,}",
            percentage(nonledger_before, nonledger_after),
        ]
    total_sorted = sorted(total_reductions)
    nonledger_sorted = sorted(nonledger_reductions)
    return (
        expected,
        sum(total_sorted[3:5]) // 2,
        sum(nonledger_sorted[3:5]) // 2,
    )


def render(root: Path, document: Path, manifest: Path) -> str:
    text = document.read_text(encoding="utf-8")
    expected, total_median, nonledger_median = scenario_values(root, manifest)
    for label, values in expected.items():
        row = f"| {label} | " + " | ".join(values) + " |"
        pattern = rf"^\| {re.escape(label)} \|.*\|$"
        text, count = re.subn(pattern, row, text, count=1, flags=re.MULTILINE)
        if count != 1:
            raise SystemExit(f"context benchmark row missing or duplicated: {label}")

    text, count = re.subn(
        r"The median total reduction is [0-9.]+%",
        f"The median total reduction is {total_median // 10}.{total_median % 10}%",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("context benchmark total-median sentence is malformed")
    text, count = re.subn(
        r"Median non-ledger\nreduction is [0-9.]+%",
        "Median non-ledger\n"
        f"reduction is {nonledger_median // 10}.{nonledger_median % 10}%",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("context benchmark non-ledger sentence is malformed")

    todo = root / "TODO.md"
    todo_lines = len(todo.read_text(encoding="utf-8").splitlines())
    todo_words = word_count(todo)
    text = re.sub(
        r"active board is(\n?)[0-9]+ lines / [0-9]+ words",
        lambda match: (
            f"active board is{match.group(1)}{todo_lines} lines / "
            f"{todo_words} words"
        ),
        text,
    )
    task_words = word_count(root / "docs/tasks/T-351.md")
    text, count = re.subn(
        r"That record is [0-9]+ words",
        f"That record is {task_words} words",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("context benchmark task-record sentence is malformed")
    combined = todo_words + task_words
    text, count = re.subn(
        r"board plus representative payload is [0-9]+ words—[0-9.]+%",
        "board plus representative payload is "
        f"{combined} words—{percentage(PRIOR_BOARD_WORDS, combined)}",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("context benchmark compact-board sentence is malformed")
    text, count = re.subn(
        r"The\nalways-read policy is [0-9]+ words",
        "The\n"
        f"always-read policy is {word_count(root / 'AGENTS.md')} words",
        text,
        count=1,
    )
    if count != 1:
        raise SystemExit("context benchmark policy sentence is malformed")
    return text


def atomic_write(path: Path, content: str) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=".context-benchmark-", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def main() -> int:
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true")
    action.add_argument("--write", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    document = root / "docs/audits/t351-autonomy-efficiency/context-benchmark.md"
    manifest = root / "docs/audits/t351-autonomy-efficiency/context-scenarios.tsv"
    current = document.read_text(encoding="utf-8")
    expected = render(root, document, manifest)
    if args.write:
        if current != expected:
            atomic_write(document, expected)
        print("CONTEXT_BENCHMARK mode=write status=current")
        return 0
    if current == expected:
        print("CONTEXT_BENCHMARK mode=check status=pass")
        return 0
    for line in difflib.unified_diff(
        current.splitlines(),
        expected.splitlines(),
        fromfile=str(document),
        tofile=f"{document} (generated)",
        lineterm="",
    ):
        print(line)
    print("FAIL: context benchmark is stale; run tools/refresh-context-benchmark.py --write")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
