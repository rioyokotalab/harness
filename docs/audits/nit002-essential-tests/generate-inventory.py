#!/usr/bin/env python3
"""Build the reproducible Nit-002 focused-suite ownership inventory artifact."""

from __future__ import annotations

import argparse
from collections import Counter
import csv
import hashlib
from pathlib import Path
import re
import subprocess


SLEEP = re.compile(r"(?m)\bsleep(?:\s|$)")
POLL = re.compile(r"(?i)poll|deadline|until .*\[|while .*\[")
RETRY = re.compile(r"(?i)retry|attempts?|backoff")
WAIT = re.compile(r"(?m)^\s*(?:if\s+)?wait(?:\s|$)")
ASSERTION = re.compile(r"(?m)\b(?:assert|fail)\b|\|\|\s*exit\s+1")
ROOT_REFERENCE = re.compile(r'(?:\$ROOT|\$root)/([A-Za-z0-9_./*{}-]+)')
RETIRE_FROM_DEFAULT = {
    "tests/test-client-comparison.sh",
    "tests/test-development-evaluation.sh",
    "tests/test-llm-hpc-next-actions.sh",
    "tests/test-t343-fable-retest.sh",
    "tests/test-task-ledger-routing.sh",
}
EXTRACT_THEN_RETIRE = {"tests/test-phase1-integration.sh"}
MAKE_INCREMENTAL = {
    "tests/test-repository-independence.sh",
    "tests/test-shellcheck.sh",
}


def rows(root: Path) -> list[dict[str, object]]:
    groups: list[tuple[str, re.Pattern[str]]] = []
    for raw in (root / "tests/validation-groups.tsv").read_text().splitlines():
        if raw and not raw.startswith("#"):
            name, _label, pattern = raw.split("|", 2)
            groups.append((name, re.compile(pattern)))

    impact_owners: Counter[str] = Counter()
    for raw in (root / "tests/validation-impact.tsv").read_text().splitlines():
        if raw and not raw.startswith("#"):
            _pattern, _tier, suite, _reason = raw.rsplit("|", 3)
            if suite != "-":
                impact_owners[suite] += 1

    inventory = []
    for raw in (root / "tests/focused-suites.tsv").read_text().splitlines():
        if not raw or raw.startswith("#"):
            continue
        fields = raw.split("|")
        suite, label, estimate = fields[:3]
        source = (root / suite).read_text(encoding="utf-8")
        matched_groups = [name for name, pattern in groups if pattern.search(suite)]
        if len(matched_groups) != 1:
            raise ValueError(f"suite does not have exactly one group: {suite}")
        direct = impact_owners[suite]
        inventory.append(
            {
                "suite": suite,
                "group": matched_groups[0],
                "label": label,
                "estimate_s": int(estimate),
                "source_lines": len(source.splitlines()),
                "source_sha256": hashlib.sha256(source.encode()).hexdigest(),
                "assertion_tokens": len(ASSERTION.findall(source)),
                "root_references": ",".join(sorted(set(ROOT_REFERENCE.findall(source)))),
                "impact_rules": direct,
                "reachability": "direct-owner" if direct else "broad-only",
                "sleep_token": int(bool(SLEEP.search(source))),
                "poll_token": int(bool(POLL.search(source))),
                "wait_token": int(bool(WAIT.search(source))),
                "retry_token": int(bool(RETRY.search(source))),
                "initial_disposition": disposition(suite, int(estimate), direct),
            }
        )
    return inventory


def owner_gaps(root: Path) -> list[dict[str, str]]:
    rules = []
    for raw in (root / "tests/validation-impact.tsv").read_text().splitlines():
        if raw and not raw.startswith("#"):
            pattern, tier, suite, reason = raw.rsplit("|", 3)
            rules.append((re.compile(pattern), tier, suite, reason))
    focused = {
        raw.split("|", 1)[0]
        for raw in (root / "tests/focused-suites.tsv").read_text().splitlines()
        if raw and not raw.startswith("#")
    }
    tracked = subprocess.run(
        ["git", "ls-files"],
        cwd=root,
        check=True,
        stdin=subprocess.DEVNULL,
        text=True,
        stdout=subprocess.PIPE,
    ).stdout.splitlines()
    relevant = re.compile(
        r"^(?:\.github/|bin/|config/|install\.sh$|libexec/|presentation/scripts/|"
        r"profiles/|shell/|tests/(?:fixtures|smoke)/|tools/)"
    )
    gaps = []
    for path in tracked:
        if not relevant.search(path) or path in focused:
            continue
        matches = [rule for rule in rules if rule[0].search(path)]
        owners = sorted({rule[2] for rule in matches if rule[2] != "-"})
        if owners:
            continue
        gaps.append(
            {
                "path": path,
                "tier": max((rule[1] for rule in matches), default="R3"),
                "classification": (
                    "mapped-without-owner" if matches else "unmapped"
                ),
            }
        )
    return gaps


def time_coupling(root: Path, inventory: list[dict[str, object]]) -> list[dict[str, object]]:
    findings = []
    for item in inventory:
        suite = str(item["suite"])
        for number, raw in enumerate((root / suite).read_text().splitlines(), 1):
            stripped = raw.strip()
            if (SLEEP.search(raw) and ".sleep =" not in raw) or "time.sleep(" in raw:
                kind = "elapsed-sleep"
                action = "remove-or-replace-with-event"
            elif WAIT.search(raw):
                kind = "child-join"
                action = "retain-only-after-exact-event-or-signal"
            elif re.search(r"\bwhile\b.*(?:attempt|\.active| -[eSf] )", raw):
                kind = "poll-loop"
                action = "replace-with-event"
            else:
                continue
            findings.append(
                {
                    "suite": suite,
                    "line": number,
                    "kind": kind,
                    "action": action,
                    "source": stripped[:180],
                }
            )
    return findings


def disposition(suite: str, estimate: int, direct_rules: int) -> str:
    if suite in RETIRE_FROM_DEFAULT:
        return "retire-historical-default"
    if suite in EXTRACT_THEN_RETIRE:
        return "extract-unique-core-then-retire-broad-replay"
    if suite in MAKE_INCREMENTAL:
        return "changed-path-incremental"
    if not direct_rules:
        return "assign-exact-owner-or-retire"
    if estimate > 10:
        return "split-selectable-contracts"
    return "retain-focused-owner"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).parents[3])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--owner-gaps", type=Path)
    parser.add_argument("--time-coupling", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    inventory = rows(root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=list(inventory[0]),
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(inventory)
    gaps = owner_gaps(root)
    if args.owner_gaps:
        args.owner_gaps.parent.mkdir(parents=True, exist_ok=True)
        with args.owner_gaps.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=list(gaps[0]),
                delimiter="\t",
                lineterminator="\n",
            )
            writer.writeheader()
            writer.writerows(gaps)
    timing = time_coupling(root, inventory)
    if args.time_coupling:
        args.time_coupling.parent.mkdir(parents=True, exist_ok=True)
        with args.time_coupling.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=list(timing[0]),
                delimiter="\t",
                lineterminator="\n",
            )
            writer.writeheader()
            writer.writerows(timing)
    print(f"ESSENTIAL_TEST_INVENTORY suites={len(inventory)} output={args.output}")
    print(f"ESSENTIAL_TEST_OWNER_GAPS paths={len(gaps)} output={args.owner_gaps or '-'}")
    print(
        f"ESSENTIAL_TEST_TIME_COUPLING rows={len(timing)} "
        f"output={args.time_coupling or '-'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
