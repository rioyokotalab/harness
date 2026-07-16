#!/usr/bin/env python3
"""Audit a public Git repository without emitting matched values."""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import tempfile
from typing import Iterator


MAX_FINDINGS = 500
MAX_FINDINGS_PER_RULE = 50
LARGE_BLOB_BYTES = 1_000_000

SUSPICIOUS_PATH = re.compile(
    r"(?i)(?:^|/)(?:\.env(?:$|\.)|id_(?:rsa|dsa|ecdsa|ed25519)(?:$|\.)|"
    r"[^/]*\.(?:pem|key|p12|pfx)|credentials?(?:$|\.)|secrets?(?:$|\.))"
)

CONTENT_RULES = (
    (
        "private-key-header",
        re.compile(rb"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----"),
    ),
    (
        "known-token-shape",
        re.compile(
            rb"(?<![A-Za-z0-9])(?:github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|"
            rb"AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{20,})"
        ),
    ),
    (
        "credential-assignment",
        re.compile(
            rb"(?i)(?:api[_-]?key|access[_-]?token|auth[_-]?token|password|secret)"
            rb"\s*[:=]\s*['\"]?[^\s'\"<>{}]{12,}"
        ),
    ),
    (
        "credential-path-reference",
        re.compile(rb"(?:~|/home/[A-Za-z0-9._-]+)?/\.ssh/|RESTIC_PASSWORD_FILE"),
    ),
    (
        "operational-absolute-path",
        re.compile(
            rb"/(?:home|groups|capstor|data1|lvs0|gs/bs|mnt/nfs-[A-Za-z0-9._-]*)/"
        ),
    ),
)

CREDENTIAL_ENTROPY = re.compile(
    rb"(?i)(?:api[_-]?key|access[_-]?token|auth[_-]?token|password|secret)"
    rb"\s*[:=]\s*['\"]?([A-Za-z0-9+/=_-]{24,})"
)


class AuditError(RuntimeError):
    pass


def run_git(repo: Path, *args: str, input_bytes: bytes | None = None) -> bytes:
    process = subprocess.run(
        ["git", "-C", str(repo), *args],
        input=input_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if process.returncode != 0:
        raise AuditError(f"git command failed without exposing stderr: {' '.join(args)}")
    return process.stdout


def strict_repo(path: Path) -> Path:
    lexical = path.expanduser().absolute()
    if lexical.is_symlink() or not lexical.is_dir():
        raise AuditError("repository must be a real directory")
    resolved = lexical.resolve(strict=True)
    top = Path(run_git(resolved, "rev-parse", "--show-toplevel").decode().strip())
    if top.resolve(strict=True) != resolved:
        raise AuditError("repository path must be its exact Git top level")
    return resolved


def object_inventory(repo: Path) -> tuple[dict[str, list[str]], dict[str, tuple[str, int]]]:
    object_paths: dict[str, list[str]] = collections.defaultdict(list)
    for raw_line in run_git(repo, "rev-list", "--objects", "--all").splitlines():
        fields = raw_line.decode("utf-8", errors="surrogateescape").split(" ", 1)
        object_id = fields[0]
        if len(fields) == 2 and fields[1]:
            object_paths[object_id].append(fields[1])
        else:
            object_paths.setdefault(object_id, [])
    request = ("\n".join(object_paths) + "\n").encode("ascii")
    checked = run_git(
        repo,
        "cat-file",
        "--batch-check=%(objectname) %(objecttype) %(objectsize)",
        input_bytes=request,
    )
    metadata: dict[str, tuple[str, int]] = {}
    for raw_line in checked.splitlines():
        object_id, kind, size = raw_line.decode("ascii").split()
        metadata[object_id] = (kind, int(size))
    return object_paths, metadata


def blob_stream(repo: Path, object_ids: list[str]) -> Iterator[tuple[str, bytes]]:
    process = subprocess.Popen(
        ["git", "-C", str(repo), "cat-file", "--batch"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert process.stdin is not None and process.stdout is not None
    try:
        for object_id in object_ids:
            process.stdin.write((object_id + "\n").encode("ascii"))
            process.stdin.flush()
            header = process.stdout.readline().decode("ascii").strip().split()
            if len(header) != 3 or header[0] != object_id or header[1] != "blob":
                raise AuditError("unexpected Git batch response")
            size = int(header[2])
            content = process.stdout.read(size)
            if len(content) != size or process.stdout.read(1) != b"\n":
                raise AuditError("truncated Git batch response")
            yield object_id, content
    finally:
        process.stdin.close()
        process.stdout.close()
        stderr = process.stderr.read() if process.stderr is not None else b""
        returncode = process.wait()
        if process.stderr is not None:
            process.stderr.close()
        if returncode != 0 or stderr:
            raise AuditError("Git batch reader failed without exposing stderr")


def object_commit_map(repo: Path) -> dict[str, str]:
    output = run_git(repo, "log", "--all", "--raw", "--no-abbrev", "--format=commit:%H")
    result: dict[str, str] = {}
    commit: str | None = None
    for raw_line in output.splitlines():
        line = raw_line.decode("utf-8", errors="surrogateescape")
        if line.startswith("commit:"):
            commit = line.removeprefix("commit:")
            continue
        if commit is None or not line.startswith(":") or "\t" not in line:
            continue
        metadata = line.split("\t", 1)[0].split()
        if len(metadata) < 4:
            continue
        for object_id in metadata[2:4]:
            if object_id != "0" * 40:
                result.setdefault(object_id, commit)
    return result


def metadata_fingerprint(rule_id: str, path: str, object_id: str, offset: int) -> str:
    source = f"{rule_id}\0{path}\0{object_id}\0{offset}".encode("utf-8", errors="surrogateescape")
    return hashlib.sha256(source).hexdigest()


def finding(
    rule_id: str,
    path: str,
    object_id: str,
    size: int,
    offset: int = 0,
) -> dict[str, object]:
    return {
        "rule_id": rule_id,
        "path": path,
        "object_id": object_id,
        "size": size,
        "metadata_fingerprint": metadata_fingerprint(rule_id, path, object_id, offset),
    }


def shannon_entropy(value: bytes) -> float:
    frequencies = collections.Counter(value)
    length = len(value)
    return -sum((count / length) * math.log2(count / length) for count in frequencies.values())


def audit(repo: Path, name: str) -> dict[str, object]:
    paths_by_object, metadata = object_inventory(repo)
    blob_ids = sorted(object_id for object_id, value in metadata.items() if value[0] == "blob")
    findings: list[dict[str, object]] = []
    seen: set[tuple[str, str, str]] = set()
    unique_counts: collections.Counter[str] = collections.Counter()
    retained_counts: collections.Counter[str] = collections.Counter()

    def add(item: dict[str, object]) -> None:
        key = (str(item["rule_id"]), str(item["path"]), str(item["object_id"]))
        if key in seen:
            return
        seen.add(key)
        rule_id = str(item["rule_id"])
        unique_counts[rule_id] += 1
        if len(findings) < MAX_FINDINGS and retained_counts[rule_id] < MAX_FINDINGS_PER_RULE:
            findings.append(item)
            retained_counts[rule_id] += 1

    for object_id, content in blob_stream(repo, blob_ids):
        size = metadata[object_id][1]
        paths = sorted(set(paths_by_object.get(object_id) or ["<unmapped-blob>"]))
        for path in paths:
            if SUSPICIOUS_PATH.search(path):
                add(finding("suspicious-path", path, object_id, size))
            if size >= LARGE_BLOB_BYTES:
                add(finding("large-blob", path, object_id, size))
        if b"\x00" in content[:8192]:
            continue
        for rule_id, pattern in CONTENT_RULES:
            match = pattern.search(content)
            if match is None:
                continue
            for path in paths:
                add(finding(rule_id, path, object_id, size, match.start()))
        entropy_match = CREDENTIAL_ENTROPY.search(content)
        if entropy_match is not None and shannon_entropy(entropy_match.group(1)) >= 4.0:
            for path in paths:
                add(finding("high-entropy-credential", path, object_id, size, entropy_match.start(1)))

    commits_by_object = object_commit_map(repo)
    for item in findings:
        object_id = str(item["object_id"])
        item["example_commit"] = commits_by_object.get(object_id)

    tracked = run_git(repo, "ls-files", "-z").split(b"\0")
    tracked_count = sum(1 for value in tracked if value)
    untracked = run_git(repo, "ls-files", "--others", "--exclude-standard", "-z").split(b"\0")
    untracked_count = sum(1 for value in untracked if value)
    ignored = run_git(repo, "ls-files", "--others", "--ignored", "--exclude-standard", "-z").split(b"\0")
    ignored_count = sum(1 for value in ignored if value)
    status = run_git(repo, "status", "--porcelain=v1", "-z").split(b"\0")
    dirty_entries = sum(1 for value in status if value)
    commit_count = int(run_git(repo, "rev-list", "--all", "--count").decode("ascii").strip())
    head = run_git(repo, "rev-parse", "HEAD").decode("ascii").strip()
    return {
        "schema": 1,
        "repository": name,
        "head": head,
        "scope": "all reachable refs plus value-free working-tree counts",
        "value_exposed": False,
        "limits": {
            "max_findings": MAX_FINDINGS,
            "max_findings_per_rule": MAX_FINDINGS_PER_RULE,
            "large_blob_bytes": LARGE_BLOB_BYTES,
        },
        "counts": {
            "commits": commit_count,
            "objects": len(metadata),
            "blobs": len(blob_ids),
            "tracked_files": tracked_count,
            "untracked_files": untracked_count,
            "ignored_files": ignored_count,
            "dirty_entries": dirty_entries,
            "findings": sum(unique_counts.values()),
            "retained_findings": len(findings),
        },
        "finding_counts": dict(sorted(unique_counts.items())),
        "findings_truncated": sum(unique_counts.values()) > len(findings),
        "findings": sorted(findings, key=lambda item: (str(item["rule_id"]), str(item["path"]), str(item["object_id"]))),
    }


def write_report(path: Path, report: dict[str, object]) -> None:
    parent = path.parent.resolve(strict=True)
    if path.exists() or path.is_symlink():
        raise AuditError("output path must be new")
    payload = (json.dumps(report, sort_keys=True, indent=2) + "\n").encode("utf-8")
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=parent)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb", closefd=True) as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o644)
        os.link(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._-]+", arguments.name):
        raise AuditError("repository name is unsafe")
    repo = strict_repo(arguments.repo)
    report = audit(repo, arguments.name)
    if arguments.output is None:
        print(json.dumps({key: report[key] for key in ("schema", "repository", "head", "value_exposed", "counts", "finding_counts", "findings_truncated")}, sort_keys=True))
    else:
        output = arguments.output.expanduser().absolute()
        write_report(output, report)
        print(output)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AuditError as error:
        print(f"public-repo-audit: {error}", file=os.sys.stderr)
        raise SystemExit(2)
