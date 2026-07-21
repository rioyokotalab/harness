#!/usr/bin/env python3
"""Reproduce the small repository metrics used by the presentation.

This intentionally reports scope and checked-in outcomes, never line counts as
quality. It does not access the network or mutate the repository.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def run(*args: str) -> str:
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def count_noncomment(path: Path) -> int:
    return sum(
        1
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )


def dispatcher_commands() -> list[str]:
    source = (ROOT / "bin/harness").read_text(encoding="utf-8")
    match = re.search(
        r'case "\$command_name" in\n\s+([^\n]+)\)\n\s+exec ', source
    )
    if not match:
        raise RuntimeError("cannot locate main dispatcher command arm")
    commands = match.group(1).split("|")
    if "guarded-delete)" in source:
        commands.append("guarded-delete")
    return commands


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="assert evidence-pack values")
    args = parser.parse_args()

    cpu = json.loads(
        (ROOT / "docs/audits/hpc-cpu-readiness-2026-07-16.json").read_text()
    )["summary"]
    accelerator = json.loads(
        (ROOT / "docs/audits/hpc-accelerator-readiness-2026-07-17.json").read_text()
    )["summary"]
    mpi = json.loads(
        (ROOT / "docs/audits/hpc-mpi-readiness-2026-07-17.json").read_text()
    )["summary"]
    evaluation = json.loads(
        (ROOT / "evaluation/results/t181-failure-capsule-v1-full.json").read_text()
    )["totals"]

    metrics = {
        "commits": int(run("git", "rev-list", "--count", "HEAD")),
        "first_parent_commits": int(
            run("git", "rev-list", "--first-parent", "--count", "HEAD")
        ),
        "tags": len(run("git", "tag").splitlines()) if run("git", "tag") else 0,
        "root_files": len(
            run("git", "ls-tree", "-r", "--name-only", "7f969317").splitlines()
        ),
        "head_files": len(run("git", "ls-tree", "-r", "--name-only", "HEAD").splitlines()),
        "root_skills": len(
            run("git", "ls-tree", "-d", "--name-only", "7f969317:skills").splitlines()
        ),
        "head_skills": sum(
            1 for path in (ROOT / "shared/skills").iterdir() if path.is_dir()
        ),
        "user_commands": len(dispatcher_commands()),
        "focused_suites": count_noncomment(ROOT / "tests/focused-suites.tsv"),
        "linux_hosts": len(list((ROOT / "profiles/hosts").glob("*.conf"))),
        "cpu_nodes_passed": cpu["nodes_passed"],
        "accelerator_driver_runtime_passed": accelerator["driver_runtime_passed"],
        "cuda_kernel_passed": accelerator["cuda_kernel_passed"],
        "single_node_mpi_routes_passed": mpi["routes_passed"],
        "evaluation_primary_runs": evaluation["primary_runs"],
        "evaluation_passed": evaluation["passed"],
        "evaluation_safety_failures": evaluation["safety_failures"],
    }

    if args.check:
        expected = {
            "commits": 542,
            "first_parent_commits": 542,
            "tags": 0,
            "root_files": 18,
            "head_files": 560,
            "root_skills": 6,
            "head_skills": 12,
            "user_commands": 43,
            "focused_suites": 57,
            "linux_hosts": 7,
            "cpu_nodes_passed": 7,
            "accelerator_driver_runtime_passed": 7,
            "cuda_kernel_passed": 5,
            "single_node_mpi_routes_passed": 5,
            "evaluation_primary_runs": 70,
            "evaluation_passed": 69,
            "evaluation_safety_failures": 0,
        }
        if metrics != expected:
            raise SystemExit(
                "metric drift detected:\n"
                + json.dumps({"expected": expected, "actual": metrics}, indent=2)
            )

    print(json.dumps(metrics, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
