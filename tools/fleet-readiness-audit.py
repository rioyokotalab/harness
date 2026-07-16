#!/usr/bin/env python3
"""Collect one bounded, credential-free readiness probe per managed node."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Any


HOSTS = ("local", "ab", "ab2", "ri", "al", "rc", "t4")
MAX_OUTPUT = 1_048_576
SAFE_VALUE = re.compile(r"^[A-Za-z0-9._,+-]+$")
HEX_OBJECT = re.compile(r"^[0-9a-f]{40}(?:[0-9a-f]{24})?$")
SCHEDULE = re.compile(
    r"^RESTIC_SCHEDULE_(CHAIN|SMOKE) host=([a-z0-9]+) status=([a-z-]+) "
    r"job=([A-Za-z0-9._-]+) name=([A-Za-z0-9._-]+) eligible=([0-9]+) "
    r"present=([01]) state=([A-Za-z0-9._-]+)$"
)

REMOTE_SCRIPT = r'''set -u
host=__HOST__
root=$HOME/harness
harness=$root/bin/harness
export HARNESS_LOGICAL_HOST=$host GIT_OPTIONAL_LOCKS=0
printf 'SCHEMA\t1\nHOST\t%s\n' "$host"
if head=$(git -C "$root" rev-parse HEAD 2>/dev/null); then
    printf 'HEAD\t%s\n' "$head"
else
    printf 'HEAD_ERROR\t1\n'
fi
if dirty=$(git -C "$root" status --porcelain=v1 2>/dev/null | wc -l | tr -d ' '); then
    printf 'DIRTY\t%s\n' "$dirty"
else
    printf 'DIRTY_ERROR\t1\n'
fi
"$harness" inventory --host "$host" --format json 2>/dev/null |
    python3 -c 'import json,sys; print("INVENTORY\t"+json.dumps(json.load(sys.stdin),sort_keys=True,separators=(",",":")))' ||
    printf 'INVENTORY_ERROR\t1\n'
doctor=$("$harness" doctor --host "$host" 2>/dev/null || true)
summary=$(printf '%s\n' "$doctor" | sed -n 's/^SUMMARY /SUMMARY /p' | sed -n '1p')
if [ -n "$summary" ]; then printf 'DOCTOR\t%s\n' "$summary"; else printf 'DOCTOR_ERROR\t1\n'; fi
status=$("$harness" restic-schedule status --host "$host" 2>/dev/null || true)
if [ -n "$status" ]; then
    printf '%s\n' "$status" | while IFS= read -r line; do printf 'SCHEDULE\t%s\n' "$line"; done
else
    printf 'SCHEDULE_ERROR\t1\n'
fi
for rel in .codex/AGENTS.md .codex/rules/default.rules .claude/CLAUDE.md .vimrc; do
    path=$HOME/$rel
    if [ -L "$path" ]; then
        printf 'CONTROL\t%s\tsymlink\t%s\n' "$rel" "$(readlink -- "$path")"
    elif [ -f "$path" ]; then
        printf 'CONTROL\t%s\tregular\t-\n' "$rel"
    else
        printf 'CONTROL\t%s\tabsent\t-\n' "$rel"
    fi
done
for rel in .local .cache .allinea .apptainer .cupy .lhotse .mozilla .nsightsystems .nv .starpu .triton; do
    path=$HOME/$rel
    if [ -L "$path" ]; then
        printf 'STORAGE\t%s\tsymlink\t%s\n' "$rel" "$(readlink -- "$path")"
    elif [ -d "$path" ]; then
        printf 'STORAGE\t%s\tdirectory\t-\n' "$rel"
    elif [ -e "$path" ]; then
        printf 'STORAGE\t%s\tother\t-\n' "$rel"
    else
        printf 'STORAGE\t%s\tabsent\t-\n' "$rel"
    fi
done
for rel in CMakeLists.txt cpp20.cpp cpu.c cpu.cpp cpu.f90 cuda.cu llm_torch.py mpi.c python.py sanitizer.c; do
    path=$root/tests/smoke/$rel
    if [ -f "$path" ] && oid=$(git -C "$root" hash-object -- "$path" 2>/dev/null); then
        printf 'SMOKE\t%s\t%s\n' "$rel" "$oid"
    else
        printf 'SMOKE\t%s\tabsent\n' "$rel"
    fi
done
probe_version() {
    label=$1
    shift
    command_name=$1
    if command -v "$command_name" >/dev/null 2>&1 && output=$("$@" 2>/dev/null); then
        first=$(printf '%s\n' "$output" | sed -n '1p' | tr '\t\r\n' '   ' | cut -c1-180)
        printf 'VERSION\t%s\tpresent\t%s\n' "$label" "$first"
    else
        printf 'VERSION\t%s\tabsent\t-\n' "$label"
    fi
}
probe_version git git --version
probe_version python python3 --version
probe_version node node --version
probe_version cmake cmake --version
probe_version ninja ninja --version
probe_version cc cc --version
probe_version cxx c++ --version
probe_version fortran gfortran --version
probe_version cuda nvcc --version
probe_version mpi mpicc --version
probe_version codex codex --version
probe_version claude claude --version
probe_version restic "$harness" restic version
'''


class AuditError(RuntimeError):
    pass


def validate_ssh(value: str) -> str:
    if "/" not in value:
        return value
    path = Path(value).expanduser().resolve(strict=True)
    if not path.is_file() or not os.access(path, os.X_OK):
        raise AuditError("--ssh must name an executable regular file")
    return str(path)


def probe(host: str, ssh: str, timeout: int) -> dict[str, Any]:
    script = REMOTE_SCRIPT.replace("__HOST__", host)
    if host == "local":
        command = ["bash", "-l", "-s"]
    else:
        command = [
            ssh,
            "-o", "BatchMode=yes",
            "-o", f"ConnectTimeout={min(timeout, 30)}",
            host,
            "env", f"HARNESS_LOGICAL_HOST={host}", "bash", "-l", "-s",
        ]
    try:
        result = subprocess.run(
            command,
            input=script,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise AuditError(f"probe timed out: {host}") from exc
    stdout = result.stdout.encode("utf-8", errors="surrogateescape")
    stderr = result.stderr.encode("utf-8", errors="surrogateescape")
    if len(stdout) > MAX_OUTPUT or len(stderr) > MAX_OUTPUT:
        raise AuditError(f"probe output exceeded bound: {host}")
    if result.returncode != 0:
        raise AuditError(f"probe failed without exposing output: {host}")
    parsed = parse_probe(host, result.stdout)
    parsed["stderr_present"] = bool(result.stderr)
    return parsed


def parse_probe(host: str, output: str) -> dict[str, Any]:
    data: dict[str, Any] = {
        "host": host,
        "controls": {},
        "storage": {},
        "smoke_sources": {},
        "versions": {},
        "schedule": {},
        "discarded_stdout_lines": 0,
    }
    schema = False
    marker = False
    for line in output.splitlines():
        fields = line.split("\t")
        tag = fields[0]
        if tag == "SCHEMA" and fields == ["SCHEMA", "1"]:
            schema = True
        elif tag == "HOST" and fields == ["HOST", host]:
            marker = True
        elif tag == "HEAD" and len(fields) == 2 and HEX_OBJECT.fullmatch(fields[1]):
            data["head"] = fields[1]
        elif tag == "DIRTY" and len(fields) == 2 and fields[1].isdigit():
            data["dirty_entries"] = int(fields[1])
        elif tag == "INVENTORY" and len(fields) == 2:
            inventory = json.loads(fields[1])
            if not isinstance(inventory, dict) or inventory.get("logical_host") != host:
                raise AuditError(f"invalid inventory identity: {host}")
            if any(not isinstance(key, str) or not isinstance(value, str) or not SAFE_VALUE.fullmatch(value)
                   for key, value in inventory.items()):
                raise AuditError(f"unsafe inventory value: {host}")
            data["inventory"] = inventory
        elif tag == "DOCTOR" and len(fields) == 2:
            match = re.fullmatch(rf"SUMMARY host={re.escape(host)} failures=([0-9]+) warnings=([0-9]+)", fields[1])
            if not match:
                raise AuditError(f"invalid doctor summary: {host}")
            data["doctor"] = {"failures": int(match.group(1)), "warnings": int(match.group(2))}
        elif tag == "SCHEDULE" and len(fields) == 2:
            match = SCHEDULE.fullmatch(fields[1])
            if not match or match.group(2) != host:
                raise AuditError(f"invalid schedule summary: {host}")
            data["schedule"][match.group(1).lower()] = {
                "status": match.group(3), "job": match.group(4), "name": match.group(5),
                "eligible_epoch": int(match.group(6)), "present": match.group(7) == "1",
                "state": match.group(8),
            }
        elif tag in {"CONTROL", "STORAGE"} and len(fields) == 4:
            name, kind, target = fields[1:]
            if not re.fullmatch(r"\.[A-Za-z0-9._/-]+", name) or kind not in {"symlink", "regular", "directory", "other", "absent"}:
                raise AuditError(f"invalid link metadata: {host}")
            if target != "-" and (len(target) > 512 or any(ord(char) < 32 for char in target)):
                raise AuditError(f"unsafe link target: {host}")
            data["controls" if tag == "CONTROL" else "storage"][name] = {"kind": kind, "target": target}
        elif tag == "SMOKE" and len(fields) == 3:
            if not re.fullmatch(r"[A-Za-z0-9_.-]+", fields[1]) or (fields[2] != "absent" and not HEX_OBJECT.fullmatch(fields[2])):
                raise AuditError(f"invalid smoke metadata: {host}")
            data["smoke_sources"][fields[1]] = fields[2]
        elif tag == "VERSION" and len(fields) == 4:
            label, state, value = fields[1:]
            if not re.fullmatch(r"[a-z]+", label) or state not in {"present", "absent"} or len(value) > 180 or any(ord(char) < 32 for char in value):
                raise AuditError(f"invalid version metadata: {host}")
            data["versions"][label] = {"state": state, "value": value}
        elif tag.endswith("_ERROR") and fields == [tag, "1"]:
            data.setdefault("errors", []).append(tag.removesuffix("_ERROR").lower())
        else:
            data["discarded_stdout_lines"] += 1
    if not schema or not marker or "head" not in data or "dirty_entries" not in data:
        raise AuditError(f"incomplete probe identity: {host}")
    return data


def write_new(path: Path, report: dict[str, Any]) -> None:
    path = path.expanduser().absolute()
    parent = path.parent.resolve(strict=True)
    if path.exists() or path.is_symlink():
        raise AuditError("output path must be new")
    payload = (json.dumps(report, sort_keys=True, indent=2) + "\n").encode()
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=parent)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb", closefd=True) as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.link(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", action="append", choices=HOSTS)
    parser.add_argument("--ssh", default="ssh")
    parser.add_argument("--timeout", type=int, default=90)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    hosts = tuple(arguments.host or HOSTS)
    if len(set(hosts)) != len(hosts) or not 10 <= arguments.timeout <= 300:
        raise AuditError("host list or timeout is invalid")
    ssh = validate_ssh(arguments.ssh)
    results: dict[str, Any] = {}
    failures: dict[str, str] = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(hosts)) as executor:
        futures = {executor.submit(probe, host, ssh, arguments.timeout): host for host in hosts}
        for future in concurrent.futures.as_completed(futures):
            host = futures[future]
            try:
                results[host] = future.result()
            except AuditError as error:
                failures[host] = str(error)
    report = {"schema": 1, "scope": "bounded read-only login readiness", "nodes": results, "failures": failures}
    write_new(arguments.output, report)
    print(json.dumps({"output": str(arguments.output), "nodes": sorted(results), "failures": failures}, sort_keys=True))
    return 1 if failures else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AuditError, json.JSONDecodeError) as error:
        print(f"fleet-readiness-audit: {error}", file=os.sys.stderr)
        raise SystemExit(2)
