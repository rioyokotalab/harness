#!/usr/bin/env python3
"""Run isolated focused suites with bounded concurrency and attributable logs."""

from __future__ import annotations

import argparse
import concurrent.futures
import os
from pathlib import Path
import subprocess
import sys
import time


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--log-dir", required=True)
    parser.add_argument("--jobs", required=True, type=int)
    return parser.parse_args()


def load_manifest(root: Path, manifest: Path) -> list[tuple[Path, str]]:
    suites: list[tuple[Path, str]] = []
    for number, raw in enumerate(manifest.read_text(encoding="utf-8").splitlines(), 1):
        if not raw or raw.startswith("#"):
            continue
        fields = raw.split("|", 1)
        if len(fields) != 2 or not fields[0] or not fields[1]:
            raise ValueError(f"invalid manifest line {number}")
        path = root / fields[0]
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"unsafe or absent suite: {fields[0]}")
        suites.append((path, fields[1]))
    if not suites:
        raise ValueError("empty focused-suite manifest")
    return suites


def run_one(index: int, path: Path, label: str, root: Path, log_dir: Path) -> tuple:
    log = log_dir / f"{index:03d}-{path.stem}.log"
    started = time.monotonic()
    with log.open("wb") as stream:
        result = subprocess.run(
            [str(path)], cwd=root, stdin=subprocess.DEVNULL,
            stdout=stream, stderr=subprocess.STDOUT, check=False,
            env=os.environ.copy(),
        )
    return index, path, label, result.returncode, time.monotonic() - started, log


def main() -> int:
    args = parse_args()
    if args.jobs < 1 or args.jobs > 16:
        print("focused-tests: --jobs must be between 1 and 16", file=sys.stderr)
        return 2
    root = Path(args.root).resolve(strict=True)
    manifest = Path(args.manifest).resolve(strict=True)
    log_dir = Path(args.log_dir)
    try:
        log_dir.mkdir(mode=0o700, parents=False, exist_ok=False)
    except FileExistsError:
        print(f"focused-tests: --log-dir already exists: {log_dir}", file=sys.stderr)
        return 2
    try:
        suites = load_manifest(root, manifest)
    except ValueError as error:
        print(f"focused-tests: {error}", file=sys.stderr)
        return 2

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = [
            executor.submit(run_one, i, path, label, root, log_dir)
            for i, (path, label) in enumerate(suites, 1)
        ]
        for future in concurrent.futures.as_completed(futures):
            results.append(future.result())

    failed = False
    for _, path, label, status, elapsed, log in sorted(results):
        state = "PASS" if status == 0 else "FAIL"
        print(f"{state} suite={path.name} seconds={elapsed:.3f}")
        if status != 0:
            failed = True
            print(f"FAIL: {label}; log={log}", file=sys.stderr)
            sys.stderr.buffer.write(log.read_bytes())
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
