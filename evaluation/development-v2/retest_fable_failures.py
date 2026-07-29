#!/usr/bin/env python3
"""Retest only the accepted T-336 Claude failure rows with Fable/high."""

from __future__ import annotations

import argparse
import copy
import hashlib
import importlib.util
import json
import os
import sys
from pathlib import Path
from typing import Any


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent.parent
FROZEN_RUNNER = ROOT / "evaluation" / "development_v2.py"
CORPUS = ROOT / "evaluation" / "development-v2" / "corpus.json"
PILOT = ROOT / "evaluation" / "results" / "t336-harness-development-v2-20260729-r7-pilot.json"
CONFIRMATION = (
    ROOT / "evaluation" / "results" / "t336-harness-development-v2-20260729-r7-confirmation.json"
)
RETEST_ID = "t343-t336-fable-high-20260729-r1"
MODEL = "claude-fable-5"
EFFORT = "high"
SELECTED = (
    ("code-coherence", 1),
    ("code-coherence", 2),
    ("code-coherence", 3),
    ("ci-gate-preserve", 2),
)
EXPECTED_HASHES = {
    FROZEN_RUNNER: "7a90d16a2428d8fedb17dd43e25a542610d2c2c8ba7a17856c9bc66671f1d71e",
    CORPUS: "2d05bb3ba7b13c7958e67c28423cd10f53d9d6d44a6c4e2a832ab79c459b2ee3",
    PILOT: "2694b7485f75efbb4b3280ac1e79b2e1b4d5c490c9b787e15a65b7bca6f54e8d",
    CONFIRMATION: "483e1f773e7989966ecef669d43b1bb8c12bf2018b5c49cc8c2dda404c6c06dc",
}


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def load_runner() -> Any:
    spec = importlib.util.spec_from_file_location("t343_frozen_development_v2", FROZEN_RUNNER)
    if spec is None or spec.loader is None:
        fail("frozen T-336 runner cannot be loaded")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def frozen_inputs() -> None:
    for path, expected in EXPECTED_HASHES.items():
        if not path.is_file() or path.is_symlink() or digest(path) != expected:
            fail(f"frozen input differs: {path.relative_to(ROOT)}")


def retest_corpus(runner: Any, *, check_client: bool) -> dict[str, Any]:
    frozen_inputs()
    original = runner.validate_corpus(check_clients=False)
    corpus = copy.deepcopy(original)
    corpus["experiment_id"] = RETEST_ID
    corpus["clients"]["claude"]["model"] = MODEL
    corpus["clients"]["claude"]["effort"] = EFFORT
    if check_client:
        declaration = corpus["clients"]["claude"]
        if runner.command_version(declaration["command"]) != declaration["version"]:
            fail("Claude version differs from the frozen declaration")
    runner.EXPERIMENT_ID = RETEST_ID
    return corpus


def selection(runner: Any, corpus: dict[str, Any]) -> list[tuple[dict[str, Any], int]]:
    tasks = runner.tasks_by_id(corpus)
    rows: list[tuple[dict[str, Any], int]] = []
    for task_id, observation in SELECTED:
        if task_id not in tasks or observation not in (1, 2, 3):
            fail("selected row is absent from the frozen corpus")
        rows.append((tasks[task_id], observation))
    return rows


def selection_label() -> str:
    return ",".join(f"{task_id}/o{observation}" for task_id, observation in SELECTED)


def validate(*, skip_client_check: bool) -> None:
    if skip_client_check and os.environ.get("HARNESS_PORTABLE_CI") != "1":
        fail("--skip-client-check is restricted to HARNESS_PORTABLE_CI=1")
    runner = load_runner()
    corpus = retest_corpus(runner, check_client=not skip_client_check)
    selection(runner, corpus)
    suffix = " client_check=skipped-portable-ci" if skip_client_check else ""
    print(
        f"VALID retest={RETEST_ID} cases={len(SELECTED)} "
        f"model={MODEL} effort={EFFORT}{suffix}"
    )


def selftest() -> None:
    runner = load_runner()
    corpus = retest_corpus(runner, check_client=False)
    rows = selection(runner, corpus)
    if len(rows) != len(set(SELECTED)):
        fail("selected rows are not unique")
    if corpus["clients"]["codex"]["model"] != "gpt-5.6-sol":
        fail("non-target client declaration drifted")
    print(f"SELFTEST retest={RETEST_ID} selected={selection_label()}")


def require_clean_source(runner: Any) -> str:
    if runner.core.git(["status", "--porcelain"]).strip():
        fail("Harness source must be clean before a scored Fable retest")
    return runner.core.git(["rev-parse", "HEAD"]).strip()


def run(root: Path) -> None:
    runner = load_runner()
    corpus = retest_corpus(runner, check_client=True)
    source_revision = require_clean_source(runner)
    run_root = runner.ensure_root(root, corpus)
    containment_failed = False
    for task, observation in selection(runner, corpus):
        pair = runner.prepare_row(run_root, task, observation)
        result = runner.run_client("claude", pair / "claude" / "private", corpus)
        print(
            f"RESULT task={task['id']} observation={observation} "
            f"outcome={result['outcome']} failures={','.join(result['failure_codes']) or 'none'}",
            flush=True,
        )
        if result["outcome"] == "containment_failure":
            containment_failed = True
            break
    if containment_failed:
        print("STOP containment-or-integrity-failure")
        raise SystemExit(3)
    print(f"COMPLETE retest={RETEST_ID} source_revision={source_revision}")


def collect_results(runner: Any, root: Path) -> list[dict[str, Any]]:
    values = []
    for task_id, observation in SELECTED:
        path = root / "runs" / f"o{observation:02d}" / task_id / "claude" / "private" / "result.json"
        if not path.is_file() or path.is_symlink():
            fail(f"retest result is incomplete: {task_id}/o{observation}")
        value = runner.core.read_private_json(path)
        if (
            value.get("experiment_id") != RETEST_ID
            or value.get("task_id") != task_id
            or value.get("observation") != observation
            or value.get("client") != "claude"
        ):
            fail(f"retest result identity differs: {task_id}/o{observation}")
        values.append(value)
    return values


def build_report(runner: Any, corpus: dict[str, Any], root: Path) -> dict[str, Any]:
    state = runner.core.read_private_json(root / "experiment.json")
    if state.get("experiment_id") != RETEST_ID or state.get("clients") != corpus["clients"]:
        fail("retest root declaration differs")
    results = collect_results(runner, root)
    containment_failures = sum(value["outcome"] == "containment_failure" for value in results)
    return {
        "schema": 1,
        "experiment_id": RETEST_ID,
        "source_revision": runner.core.git(["rev-parse", "HEAD"]).strip(),
        "created_at": state["created_at"],
        "model": MODEL,
        "effort": EFFORT,
        "selection": [
            {"task_id": task_id, "observation": observation}
            for task_id, observation in SELECTED
        ],
        "frozen_inputs": {
            str(path.relative_to(ROOT)): expected
            for path, expected in EXPECTED_HASHES.items()
        },
        "runs": results,
        "summary": {
            "cases": len(results),
            "passed": sum(value["outcome"] == "passed" for value in results),
            "task_failed": sum(value["outcome"] == "task_failed" for value in results),
            "unsafe": sum(value["outcome"] == "unsafe" for value in results),
            "invalid": sum(
                value["outcome"]
                not in ("passed", "task_failed", "unsafe")
                for value in results
            ),
            "duration_ms": sum(value["duration_ms"] for value in results),
            "tool_calls": sum(value["tool_calls"] for value in results),
        },
        "containment": {
            "passed": containment_failures == 0,
            "failures": containment_failures,
        },
        "scope_note": (
            "Failure-only descriptive retest against the frozen T-336 corpus, "
            "fixtures, containment, normalization, and hidden graders; it is "
            "not a full paired client comparison."
        ),
    }


def report(root: Path, output: Path) -> None:
    runner = load_runner()
    corpus = retest_corpus(runner, check_client=True)
    run_root = runner.ensure_root(root, corpus)
    expected = ROOT / "evaluation" / "results" / f"{RETEST_ID}.json"
    if output.resolve() != expected.resolve() or output.exists() or output.is_symlink():
        fail("retest report output must be the new canonical absent result path")
    first = build_report(runner, corpus, run_root)
    second = build_report(runner, corpus, run_root)
    if runner.core.canonical_json(first) != runner.core.canonical_json(second):
        fail("retest report regeneration differs")
    encoded = json.dumps(first, sort_keys=True, indent=2) + "\n"
    if any(value in encoded for value in ("/tmp/", "/home/")):
        fail("retest report contains a private path")
    output.write_text(encoded, encoding="utf-8")
    print(f"PUBLISHED retest={RETEST_ID} output={output.relative_to(ROOT)}")


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    commands = value.add_subparsers(dest="command", required=True)
    validate_parser = commands.add_parser("validate")
    validate_parser.add_argument("--skip-client-check", action="store_true")
    commands.add_parser("selftest")
    run_parser = commands.add_parser("run")
    run_parser.add_argument("--root", required=True, type=Path)
    report_parser = commands.add_parser("report")
    report_parser.add_argument("--root", required=True, type=Path)
    report_parser.add_argument("--output", required=True, type=Path)
    return value


def main() -> None:
    args = parser().parse_args()
    if args.command == "validate":
        validate(skip_client_check=args.skip_client_check)
    elif args.command == "selftest":
        selftest()
    elif args.command == "run":
        run(args.root)
    elif args.command == "report":
        report(args.root, args.output)
    else:
        fail("unknown retest command")


if __name__ == "__main__":
    main()
