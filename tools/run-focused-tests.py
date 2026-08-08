#!/usr/bin/env python3
"""Run isolated focused suites with bounded, cleanup-aware concurrency."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import platform
import signal
import subprocess
import sys
import time
from typing import Any, NamedTuple


class Suite(NamedTuple):
    index: int
    relative: str
    path: Path
    label: str
    estimate: int
    resource: str
    platforms: frozenset[str]


class Running(NamedTuple):
    suite: Suite
    process: Any
    stream: Any
    log: Path
    started: float


class Result(NamedTuple):
    suite: Suite
    status: int
    elapsed: float
    log: Path
    state: str


class RunnerSignal(Exception):
    def __init__(self, signum: int):
        super().__init__(signum)
        self.signum = signum


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--log-dir", required=True)
    parser.add_argument("--jobs", required=True)
    parser.add_argument("--reserve-cpus", type=int, default=0)
    parser.add_argument("--heavy-jobs", default="auto")
    parser.add_argument("--platform", default=platform.system())
    parser.add_argument("--timings-file")
    parser.add_argument("--suite", action="append", default=[])
    parser.add_argument("--keep-going", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    return parser.parse_args()


def visible_cpu_count() -> int:
    if hasattr(os, "sched_getaffinity"):
        return len(os.sched_getaffinity(0))
    return os.cpu_count() or 1


def default_jobs(visible_cpus: int) -> int:
    return 8 if visible_cpus >= 8 else 4


def auto_jobs(visible_cpus: int, reserve_cpus: int) -> int:
    available = max(1, visible_cpus - reserve_cpus)
    return min(default_jobs(visible_cpus), available)


def resolve_jobs(raw: str, reserve_cpus: int = 0) -> tuple[int, int | None]:
    if raw == "auto":
        visible_cpus = visible_cpu_count()
        return auto_jobs(visible_cpus, reserve_cpus), visible_cpus
    if reserve_cpus:
        return 0, None
    try:
        return int(raw), None
    except ValueError:
        return 0, None


def resolve_heavy_jobs(raw: str, jobs: int, system: str) -> int:
    if system != "Darwin":
        return jobs
    if raw == "auto":
        # Preserve a light-work lane on smaller Macs, but let machines with
        # enough workers admit up to four process-heavy suites. Matched Riken
        # measurements show that two-way admission leaves the full gate
        # needlessly serialized and that four-way admission already increases
        # individual heavy-suite runtimes, so retain that bounded ceiling.
        return max(1, min(4, jobs // 2))
    try:
        return int(raw)
    except ValueError:
        return 0


def load_manifest(root: Path, manifest: Path) -> list[Suite]:
    suites: list[Suite] = []
    for number, raw in enumerate(manifest.read_text(encoding="utf-8").splitlines(), 1):
        if not raw or raw.startswith("#"):
            continue
        fields = raw.split("|")
        if len(fields) not in (2, 3, 4, 5) or not fields[0] or not fields[1]:
            raise ValueError(f"invalid manifest line {number}")
        estimate = 0
        if len(fields) >= 3 and fields[2]:
            try:
                estimate = int(fields[2])
            except ValueError as error:
                raise ValueError(f"invalid manifest line {number}") from error
            if estimate < 1 or estimate > 3600:
                raise ValueError(f"invalid manifest line {number}")
        resource = fields[3] if len(fields) >= 4 else "light"
        platform_text = fields[4] if len(fields) == 5 else "all"
        platforms = (
            frozenset({"Darwin", "Linux"})
            if platform_text == "all"
            else frozenset({platform_text})
        )
        if (
            resource not in {"light", "heavy"}
            or platform_text not in {"all", "Darwin", "Linux"}
        ):
            raise ValueError(f"invalid manifest line {number}")
        path = root / fields[0]
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"unsafe or absent suite: {fields[0]}")
        suites.append(
            Suite(
                len(suites) + 1,
                fields[0],
                path,
                fields[1],
                estimate,
                resource,
                platforms,
            )
        )
    if not suites:
        raise ValueError("empty focused-suite manifest")
    return suites


def select_suites(
    suites: list[Suite], requested: list[str], system: str
) -> tuple[list[Suite], list[Suite]]:
    if len(requested) != len(set(requested)):
        raise ValueError("duplicate --suite selection")
    available = {suite.relative for suite in suites}
    missing = sorted(set(requested) - available)
    if missing:
        raise ValueError(f"suite is outside the manifest: {missing[0]}")
    selected = set(requested) if requested else {suite.relative for suite in suites}
    candidates = [suite for suite in suites if suite.relative in selected]
    return (
        [suite for suite in candidates if system in suite.platforms],
        [suite for suite in candidates if system not in suite.platforms],
    )


def prepare_timings_file(raw: str | None) -> Path | None:
    if raw is None:
        return None
    target = Path(raw).absolute()
    if target.exists() or target.is_symlink():
        raise ValueError(f"--timings-file already exists: {target}")
    try:
        parent = target.parent.resolve(strict=True)
    except FileNotFoundError as error:
        raise ValueError(f"--timings-file parent is absent: {target.parent}") from error
    if not parent.is_dir() or parent.is_symlink():
        raise ValueError(f"--timings-file parent is unsafe: {target.parent}")
    return parent / target.name


def test_environment() -> dict[str, str]:
    environment = os.environ.copy()
    try:
        count = int(environment.get("GIT_CONFIG_COUNT", "0"))
    except ValueError as error:
        raise ValueError("invalid inherited GIT_CONFIG_COUNT") from error
    environment["GIT_CONFIG_COUNT"] = str(count + 1)
    environment[f"GIT_CONFIG_KEY_{count}"] = "maintenance.auto"
    environment[f"GIT_CONFIG_VALUE_{count}"] = "false"
    return environment


def start_one(suite: Suite, root: Path, log_dir: Path) -> Running:
    log = log_dir / f"{suite.index:03d}-{suite.path.stem}.log"
    stream = log.open("xb")
    try:
        process = subprocess.Popen(
            [str(suite.path)],
            cwd=root,
            stdin=subprocess.DEVNULL,
            stdout=stream,
            stderr=subprocess.STDOUT,
            env=test_environment(),
            start_new_session=True,
        )
    except BaseException:
        stream.close()
        raise
    return Running(suite, process, stream, log, time.monotonic())


def finish_one(running: Running, cancelled: bool) -> Result:
    status = running.process.returncode
    if status is None:
        raise RuntimeError("completion event arrived before child status")
    running.stream.flush()
    os.fsync(running.stream.fileno())
    running.stream.close()
    state = "cancelled" if cancelled else ("pass" if status == 0 else "fail")
    return Result(
        running.suite,
        status,
        time.monotonic() - running.started,
        running.log,
        state,
    )


def signal_groups(running: dict[int, Running], signum: int) -> None:
    for item in running.values():
        if item.process.poll() is not None:
            continue
        try:
            os.killpg(item.process.pid, signum)
        except ProcessLookupError:
            pass


def stop_running(running: dict[int, Running]) -> None:
    signal_groups(running, signal.SIGTERM)
    for item in running.values():
        item.process.wait()


def wait_for_completion(running: dict[int, Running]) -> int:
    pid, status = os.waitpid(-1, 0)
    for index, item in running.items():
        if item.process.pid == pid:
            item.process.returncode = os.waitstatus_to_exitcode(status)
            return index
    raise RuntimeError("reaped an unknown focused-suite child")


def eligible_position(
    pending: list[Suite], running: dict[int, Running], heavy_jobs: int
) -> int | None:
    heavy_running = sum(item.suite.resource == "heavy" for item in running.values())
    for position, suite in enumerate(pending):
        if suite.resource != "heavy" or heavy_running < heavy_jobs:
            return position
    return None


def write_timings(
    target: Path,
    *,
    system: str,
    jobs: int,
    heavy_jobs: int,
    keep_going: bool,
    status: str,
    elapsed: float,
    suites: list[Suite],
    results: list[Result],
    not_applicable: list[Suite],
) -> None:
    completed = {result.suite.index for result in results}
    payload = {
        "schema": "harness-focused-timings-v1",
        "platform": system,
        "jobs": jobs,
        "heavy_jobs": heavy_jobs,
        "mode": "keep-going" if keep_going else "fail-fast",
        "status": status,
        "seconds": round(elapsed, 3),
        "suites_total": len(suites),
        "results": [
            {
                "suite": result.suite.relative,
                "resource": result.suite.resource,
                "estimate_seconds": result.suite.estimate or None,
                "state": result.state,
                "exit_code": result.status,
                "seconds": round(result.elapsed, 3),
            }
            for result in sorted(results, key=lambda result: result.suite.index)
        ],
        "not_run": [suite.relative for suite in suites if suite.index not in completed],
        "not_applicable": [suite.relative for suite in not_applicable],
    }
    descriptor = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
        json.dump(payload, stream, sort_keys=True, separators=(",", ":"))
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())


def main() -> int:
    run_started = time.monotonic()
    args = parse_args()
    jobs, visible_cpus = resolve_jobs(args.jobs, args.reserve_cpus)
    if (
        args.reserve_cpus < 0
        or args.reserve_cpus > 15
        or jobs < 1
        or jobs > 16
        or args.platform not in {"Darwin", "Linux"}
    ):
        print(
            "focused-tests: --jobs must be auto or an integer between 1 and 16; "
            "--reserve-cpus 0..15 is valid only with auto; platform must be "
            "Darwin or Linux",
            file=sys.stderr,
        )
        return 2
    heavy_jobs = resolve_heavy_jobs(args.heavy_jobs, jobs, args.platform)
    if heavy_jobs < 1 or heavy_jobs > jobs:
        print(
            "focused-tests: --heavy-jobs must be auto or an integer between 1 and --jobs",
            file=sys.stderr,
        )
        return 2
    root = Path(args.root).resolve(strict=True)
    manifest = Path(args.manifest).resolve(strict=True)
    log_dir = Path(args.log_dir)
    try:
        timings_file = prepare_timings_file(args.timings_file)
    except ValueError as error:
        print(f"focused-tests: {error}", file=sys.stderr)
        return 2
    try:
        log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)
    except FileExistsError:
        print(f"focused-tests: --log-dir already exists: {log_dir}", file=sys.stderr)
        return 2
    try:
        suites, not_applicable = select_suites(
            load_manifest(root, manifest), args.suite, args.platform
        )
    except ValueError as error:
        print(f"focused-tests: {error}", file=sys.stderr)
        return 2

    if visible_cpus is not None:
        print(
            f"focused-tests: jobs={jobs} visible_cpus={visible_cpus} mode=auto "
            f"reserve_cpus={args.reserve_cpus}"
        )
    print(
        f"focused-tests: platform={args.platform} heavy_jobs={heavy_jobs} "
        f"mode={'keep-going' if args.keep_going else 'fail-fast'}"
    )

    admission_order = sorted(suites, key=lambda suite: (-suite.estimate, suite.index))
    pending = list(admission_order)
    running: dict[int, Running] = {}
    results: list[Result] = []
    cancelled: set[int] = set()
    failure_seen = False
    prior_handlers: dict[int, Any] = {}

    def interrupt(signum: int, _frame: Any) -> None:
        raise RunnerSignal(signum)

    for signum in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
        prior_handlers[signum] = signal.getsignal(signum)
        signal.signal(signum, interrupt)
    interrupted = 0
    try:
        while pending or running:
            while pending and len(running) < jobs and (args.keep_going or not failure_seen):
                position = eligible_position(pending, running, heavy_jobs)
                if position is None:
                    break
                suite = pending.pop(position)
                running[suite.index] = start_one(suite, root, log_dir)
            if not running:
                break
            completed = [wait_for_completion(running)]
            for index in completed:
                result = finish_one(running.pop(index), index in cancelled)
                results.append(result)
                if result.state == "fail" and not failure_seen:
                    failure_seen = True
            if failure_seen and not args.keep_going and running and not cancelled:
                cancelled.update(running)
                stop_running(running)
                for index in sorted(list(running)):
                    results.append(
                        finish_one(running.pop(index), index in cancelled)
                    )
    except RunnerSignal as error:
        interrupted = error.signum
        cancelled.update(running)
        stop_running(running)
    except BaseException:
        cancelled.update(running)
        stop_running(running)
        for index in sorted(list(running)):
            results.append(finish_one(running.pop(index), index in cancelled))
        raise
    finally:
        for signum, handler in prior_handlers.items():
            signal.signal(signum, handler)
    for index in sorted(list(running)):
        results.append(finish_one(running.pop(index), index in cancelled))

    failed = False
    for result in sorted(results, key=lambda item: item.suite.index):
        if args.verbose or result.state == "fail":
            print(
                f"{result.state.upper()} suite={result.suite.path.name} "
                f"seconds={result.elapsed:.3f}"
            )
        if result.state == "fail":
            failed = True
            print(f"FAIL: {result.suite.label}; log={result.log}", file=sys.stderr)
            sys.stderr.buffer.write(result.log.read_bytes())
    elapsed = time.monotonic() - run_started
    if timings_file is not None:
        receipt_status = "interrupted" if interrupted else ("fail" if failed else "pass")
        write_timings(
            timings_file,
            system=args.platform,
            jobs=jobs,
            heavy_jobs=heavy_jobs,
            keep_going=args.keep_going,
            status=receipt_status,
            elapsed=elapsed,
            suites=suites,
            results=results,
            not_applicable=not_applicable,
        )
        print(f"focused-tests: timings={timings_file} platform={args.platform}")
    not_run = len(suites) - len(results)
    state = "interrupted" if interrupted else ("fail" if failed else "pass")
    if failed or interrupted:
        print(
            f"focused-tests: status={state} suites={len(results)}/{len(suites)} "
            f"cancelled={sum(result.state == 'cancelled' for result in results)} "
            f"not_run={not_run} seconds={elapsed:.3f}"
        )
    else:
        print(
            f"focused-tests: status=pass suites={len(results)} seconds={elapsed:.3f}"
        )
    if interrupted:
        return 128 + interrupted
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
