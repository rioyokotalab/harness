#!/usr/bin/env python3
"""Evidence-first repository housekeeping primitives."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import secrets
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple


ARCHIVE_SCHEMA = "harness-housekeeping-archive-v2"
PLAN_SCHEMA = "harness-housekeeping-plan-v2"
MAX_PLAN_AGE = 900
OID_RE = re.compile(r"^[0-9a-f]{40}$")
TXN_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,79}$")
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")


class HousekeepingError(RuntimeError):
    pass


def die(message: str) -> None:
    raise HousekeepingError(message)


def run(
    arguments: Sequence[str],
    *,
    cwd: Optional[Path] = None,
    input_bytes: Optional[bytes] = None,
    check: bool = True,
    timeout: int = 30,
) -> subprocess.CompletedProcess[bytes]:
    try:
        result = subprocess.run(
            list(arguments),
            cwd=str(cwd) if cwd else None,
            input=input_bytes,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as exc:
        raise HousekeepingError("native command timed out") from exc
    if check and result.returncode != 0:
        die("native command failed: " + " ".join(arguments[:3]))
    return result


def text(result: subprocess.CompletedProcess[bytes]) -> str:
    try:
        return result.stdout.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise HousekeepingError("native command returned malformed text") from exc


def git(repo: Path, *arguments: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    return run(["git", "-C", str(repo), *arguments], check=check)


def canonical_repo(value: Path) -> Path:
    root = Path(text(git(value, "rev-parse", "--show-toplevel")).strip()).resolve()
    if value.resolve() != root:
        die("housekeeping repository must be its primary root")
    info = root.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid():
        die("repository root identity is unsafe")
    return root


def testing_override(name: str) -> Optional[str]:
    value = os.environ.get(name)
    if value and os.environ.get("HARNESS_TESTING") != "1":
        die("test override is unsafe")
    return value


def state_directory() -> Tuple[Path, Path]:
    override = testing_override("HARNESS_TEST_RECEIPT_DIR")
    if override:
        lexical = Path(override)
    else:
        base = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
        lexical = base / "harness" / "housekeeping"
    lexical.mkdir(mode=0o700, parents=True, exist_ok=True)
    if lexical.is_symlink():
        die("housekeeping state directory must not be a symlink")
    canonical = lexical.resolve(strict=True)
    info = canonical.lstat()
    if (
        not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or stat.S_IMODE(info.st_mode) != 0o700
    ):
        die("housekeeping state directory must be current-user mode 0700")
    return lexical.absolute(), canonical


def fsync_directory(directory: Path) -> None:
    descriptor = os.open(str(directory), os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def publish_bytes(directory: Path, name: str, payload: bytes) -> Path:
    destination = directory / name
    if destination.exists() or destination.is_symlink():
        die("refusing to replace a durable housekeeping artifact")
    descriptor, temporary_name = tempfile.mkstemp(prefix=".housekeeping-", dir=str(directory))
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.link(str(temporary), str(destination))
        temporary.unlink()
        fsync_directory(directory)
    finally:
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()
    validate_private_file(destination)
    return destination


def validate_private_file(path: Path) -> os.stat_result:
    if not path.is_absolute() or path.is_symlink() or not path.is_file():
        die("housekeeping artifact is not a real absolute file")
    info = path.lstat()
    if (
        info.st_uid != os.getuid()
        or stat.S_IMODE(info.st_mode) != 0o600
        or info.st_nlink != 1
    ):
        die("housekeeping artifact identity is unsafe")
    return info


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def transaction_id(prefix: str) -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dt%H%M%Sz")
    return f"{prefix}-{stamp}-{os.getpid()}-{secrets.token_hex(3)}"


def validate_item(name: str, tip: str) -> None:
    if not name or CONTROL_RE.search(name) or name.startswith("-"):
        die("archive branch name is malformed")
    if not OID_RE.fullmatch(tip):
        die("archive tip is malformed")


def parse_items(path: Path) -> List[Tuple[str, str]]:
    validate_private_file(path)
    items: List[Tuple[str, str]] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw:
            continue
        fields = raw.split("\t")
        if len(fields) != 2:
            die("archive item row is malformed")
        validate_item(fields[0], fields[1])
        items.append((fields[0], fields[1]))
    if (
        not items
        or len(set(items)) != len(items)
        or len({name for name, _tip in items}) != len(items)
    ):
        die("archive items are empty or duplicated")
    if len({tip for _name, tip in items}) != len(items):
        die("archive tips must be unique")
    return items


def write_items(directory: Path, items: Sequence[Tuple[str, str]], name: str) -> Path:
    payload = "".join(f"{branch}\t{tip}\n" for branch, tip in items).encode()
    return publish_bytes(directory, name, payload)


def archive_create(
    repo: Path,
    items: Sequence[Tuple[str, str]],
    transaction: str,
    source: str,
    details: Optional[Dict[str, Dict[str, str]]] = None,
) -> Dict[str, Any]:
    if not TXN_RE.fullmatch(transaction):
        die("archive transaction is malformed")
    if (
        not items
        or len(set(items)) != len(items)
        or len({name for name, _tip in items}) != len(items)
        or len({_tip for _name, _tip in items}) != len(items)
    ):
        die("archive items are empty or duplicated")
    lexical_state, state = state_directory()
    prefix = f"refs/harness-housekeeping/archive/{transaction}"
    existing = text(git(repo, "for-each-ref", "--format=%(refname)", prefix)).strip()
    if existing:
        die("archive transaction already exists")
    ref_rows: List[Tuple[str, str, str]] = []
    commands = ["start"]
    for branch, tip in items:
        validate_item(branch, tip)
        git(repo, "cat-file", "-e", f"{tip}^{{commit}}")
        ref = f"{prefix}/{branch}"
        run(["git", "check-ref-format", ref])
        ref_rows.append((branch, tip, ref))
        commands.append(f"create {ref} {tip}")
    commands.extend(("prepare", "commit"))
    update = run(
        ["git", "-C", str(repo), "update-ref", "--stdin"],
        input_bytes=("\n".join(commands) + "\n").encode(),
    )
    del update

    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{transaction}-", dir=str(state))
    os.close(descriptor)
    temporary = Path(temporary_name)
    temporary.unlink()
    bundle = state / f"{transaction}.bundle"
    receipt = state / f"{transaction}.receipt"
    if bundle.exists() or receipt.exists():
        die("archive artifact already exists")
    try:
        git(repo, "bundle", "create", str(temporary), *[row[2] for row in ref_rows])
        os.chmod(str(temporary), 0o600)
        with temporary.open("rb") as handle:
            os.fsync(handle.fileno())
        git(repo, "bundle", "verify", str(temporary))
        bundle_digest = digest(temporary)
        os.link(str(temporary), str(bundle))
        temporary.unlink()
        fsync_directory(state)
        validate_private_file(bundle)
        receipt_lines = [
            f"schema={ARCHIVE_SCHEMA}",
            f"transaction={transaction}",
            f"repository_lexical={repo}",
            f"repository_canonical={repo.resolve()}",
            f"repository_id={path_id(repo)[0]}:{path_id(repo)[1]}",
            f"git_common_dir={Path(text(git(repo, 'rev-parse', '--absolute-git-dir')).strip()).resolve()}",
            f"state_lexical={lexical_state}",
            f"state_canonical={state}",
            f"head={text(git(repo, 'rev-parse', 'HEAD')).strip()}",
            f"created_utc={datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
            f"source={source}",
            f"bundle={bundle}",
            f"bundle_sha256={bundle_digest}",
            f"archive_prefix={prefix}",
            f"items={len(ref_rows)}",
        ]
        for branch, tip, ref in ref_rows:
            detail = (details or {}).get(branch, {})
            classification = detail.get("classification", "manual")
            pr = detail.get("pr", "none")
            if CONTROL_RE.search(classification) or CONTROL_RE.search(pr) or " " in classification or " " in pr:
                die("archive classification metadata is malformed")
            receipt_lines.append(
                f"item branch={branch} tip={tip} archive={ref} "
                f"restore=git_branch_exact classification={classification} pr={pr}"
            )
        published = publish_bytes(
            state, receipt.name, ("\n".join(receipt_lines) + "\n").encode()
        )
        return {
            "transaction": transaction,
            "prefix": prefix,
            "bundle": str(bundle),
            "receipt": str(published),
            "items": len(ref_rows),
        }
    finally:
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()


def parse_archive_receipt(path: Path) -> Dict[str, Any]:
    validate_private_file(path)
    values: Dict[str, str] = {}
    items: List[Dict[str, str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("item "):
            row: Dict[str, str] = {}
            for field in line.split()[1:]:
                if "=" not in field:
                    die("archive receipt item is malformed")
                key, value = field.split("=", 1)
                row[key] = value
            required_item = {"branch", "tip", "archive", "restore"}
            if not required_item.issubset(row) or not set(row).issubset(
                required_item | {"classification", "pr"}
            ):
                die("archive receipt item fields are malformed")
            validate_item(row["branch"], row["tip"])
            items.append(row)
        else:
            if "=" not in line:
                die("archive receipt field is malformed")
            key, value = line.split("=", 1)
            if key in values:
                die("archive receipt field is duplicated")
            values[key] = value
    required = {
        "schema",
        "transaction",
        "git_common_dir",
        "bundle",
        "bundle_sha256",
        "archive_prefix",
        "items",
    }
    if not required.issubset(values):
        die("archive receipt is incomplete")
    if values["schema"] not in {ARCHIVE_SCHEMA, "harness-housekeeping-archive-v1"}:
        die("archive receipt schema is unsupported")
    try:
        expected_items = int(values["items"])
    except ValueError as exc:
        raise HousekeepingError("archive item count is malformed") from exc
    if expected_items != len(items) or not items:
        die("archive item count changed")
    return {"values": values, "items": items}


def archive_audit(repo: Path, receipt_path: Path) -> Dict[str, Any]:
    parsed = parse_archive_receipt(receipt_path)
    values = parsed["values"]
    common = Path(text(git(repo, "rev-parse", "--git-common-dir")).strip())
    if not common.is_absolute():
        common = repo / common
    if common.resolve(strict=True) != Path(values["git_common_dir"]).resolve(strict=True):
        die("archive receipt belongs to a different Git repository")
    bundle = Path(values["bundle"])
    validate_private_file(bundle)
    if digest(bundle) != values["bundle_sha256"]:
        die("archive bundle digest changed")
    git(repo, "bundle", "verify", str(bundle))
    heads: Dict[str, str] = {}
    for line in text(git(repo, "bundle", "list-heads", str(bundle))).splitlines():
        fields = line.split(" ", 1)
        if len(fields) == 2:
            heads[fields[1]] = fields[0]
    if len(heads) != len(parsed["items"]):
        die("archive bundle head set changed")
    live = 0
    bundled = 0
    for row in parsed["items"]:
        expected_ref = values["archive_prefix"] + "/" + row["branch"]
        if row["archive"] != expected_ref:
            die("archive receipt branch mapping changed")
        run(["git", "check-ref-format", row["archive"]])
        result = git(repo, "rev-parse", "--verify", row["archive"], check=False)
        if result.returncode == 0 and text(result).strip() == row["tip"]:
            live += 1
        elif heads.get(row["archive"]) == row["tip"]:
            bundled += 1
        else:
            die("archive tip is unavailable from both ref and bundle")
    return {"items": len(parsed["items"]), "live": live, "bundled": bundled}


def json_bytes(value: Dict[str, Any]) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def publish_plan(kind: str, repo: Path, payload: Dict[str, Any]) -> Tuple[Path, str]:
    _lexical, state = state_directory()
    plans = state / "plans"
    plans.mkdir(mode=0o700, exist_ok=True)
    if plans.is_symlink():
        die("housekeeping plan directory must not be a symlink")
    info = plans.lstat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        die("housekeeping plan directory is unsafe")
    value: Dict[str, Any] = {
        "schema": PLAN_SCHEMA,
        "kind": kind,
        "created_epoch": int(time.time()),
        "repository": str(repo),
        "repository_id": list(path_id(repo)),
        "head": text(git(repo, "rev-parse", "HEAD")).strip(),
    }
    value.update(payload)
    name = transaction_id(kind) + ".json"
    path = publish_bytes(plans, name, json_bytes(value))
    return path, digest(path)


def path_id(path: Path) -> Tuple[int, int]:
    info = path.stat()
    return info.st_dev, info.st_ino


def load_plan(path: Path, token: str, kind: str, repo: Path) -> Dict[str, Any]:
    validate_private_file(path)
    if not re.fullmatch(r"[0-9a-f]{64}", token) or digest(path) != token:
        die("housekeeping plan token changed")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("housekeeping plan is malformed") from exc
    if value.get("schema") != PLAN_SCHEMA or value.get("kind") != kind:
        die("housekeeping plan schema or kind changed")
    age = int(time.time()) - value.get("created_epoch", -1)
    if age < 0 or age > MAX_PLAN_AGE:
        die("housekeeping plan is stale; re-plan")
    if value.get("repository") != str(repo) or value.get("repository_id") != list(path_id(repo)):
        die("housekeeping repository identity changed")
    if value.get("head") != text(git(repo, "rev-parse", "HEAD")).strip():
        die("housekeeping repository head changed")
    return value


def gh_program() -> Optional[str]:
    override = testing_override("HARNESS_TEST_GH")
    if override:
        return override
    return shutil.which("gh")


def pull_requests(repo: Path) -> Optional[List[Dict[str, Any]]]:
    program = gh_program()
    if not program:
        return None
    result = run(
        [
            program,
            "pr",
            "list",
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,state,headRefName,headRefOid,baseRefName,mergedAt",
        ],
        cwd=repo,
        check=False,
    )
    if result.returncode != 0:
        return None
    try:
        value = json.loads(text(result))
    except json.JSONDecodeError:
        return None
    if not isinstance(value, list):
        return None
    records: List[Dict[str, Any]] = []
    for row in value:
        if not isinstance(row, dict):
            return None
        required = {"number", "state", "headRefName", "headRefOid", "baseRefName", "mergedAt"}
        if not required.issubset(row):
            return None
        if (
            not isinstance(row["number"], int)
            or not isinstance(row["state"], str)
            or not isinstance(row["headRefName"], str)
            or not isinstance(row["baseRefName"], str)
            or (row["headRefOid"] is not None and not isinstance(row["headRefOid"], str))
            or (row["mergedAt"] is not None and not isinstance(row["mergedAt"], str))
        ):
            return None
        records.append(row)
    return records


def origin_main(repo: Path) -> Optional[str]:
    result = git(repo, "rev-parse", "--verify", "refs/remotes/origin/main", check=False)
    if result.returncode != 0:
        return None
    oid = text(result).strip()
    if not OID_RE.fullmatch(oid):
        return None
    test_remote = testing_override("HARNESS_TEST_REMOTE_MAIN")
    if test_remote:
        return oid if test_remote == oid else None
    if os.environ.get("HARNESS_TESTING") == "1":
        return oid
    remote = git(repo, "ls-remote", "--exit-code", "origin", "refs/heads/main", check=False)
    if remote.returncode != 0:
        return None
    rows = [line.split() for line in text(remote).splitlines() if line.strip()]
    if len(rows) != 1 or len(rows[0]) != 2 or rows[0][1] != "refs/heads/main":
        return None
    return oid if rows[0][0] == oid else None


def is_ancestor(repo: Path, tip: str, base: Optional[str]) -> Optional[bool]:
    if not base:
        return None
    result = git(repo, "merge-base", "--is-ancestor", tip, base, check=False)
    if result.returncode == 0:
        return True
    if result.returncode == 1:
        return False
    return None


def classify_tip(
    repo: Path,
    name: str,
    tip: str,
    prs: Optional[List[Dict[str, Any]]],
    main_oid: Optional[str],
) -> Dict[str, Any]:
    record: Dict[str, Any] = {
        "name": name,
        "tip": tip,
        "candidate": False,
        "reason": "unknown",
        "pr": None,
    }
    if prs is None or main_oid is None:
        record["reason"] = "api-or-origin-main-unknown"
        return record
    matches = [row for row in prs if row["headRefName"] == name]
    exact = [
        row
        for row in matches
        if row["state"].upper() == "MERGED"
        and row["mergedAt"]
        and row["headRefOid"] == tip
    ]
    if len(exact) == 1:
        record.update(candidate=True, reason="merged-pr-exact-head", pr=exact[0])
        return record
    if len(exact) > 1:
        record["reason"] = "ambiguous-exact-merged-pr"
        return record
    ancestor = is_ancestor(repo, tip, main_oid)
    if ancestor is True:
        record.update(candidate=True, reason="ancestor-origin-main")
        return record
    if ancestor is None:
        record["reason"] = "ancestry-unknown"
    elif any(row["state"].upper() == "OPEN" for row in matches):
        record["reason"] = "open-pr"
    elif any(row["state"].upper() == "MERGED" for row in matches):
        record["reason"] = "merged-pr-head-mismatch"
    elif matches:
        record["reason"] = "closed-or-ambiguous-pr"
    else:
        record["reason"] = "no-pr-and-not-merged"
    return record


def worktree_rows(repo: Path) -> List[Dict[str, str]]:
    result = git(repo, "worktree", "list", "--porcelain", "-z")
    rows: List[Dict[str, str]] = []
    current: Dict[str, str] = {}
    for raw in result.stdout.split(b"\0"):
        if not raw:
            if current:
                rows.append(current)
                current = {}
            continue
        try:
            line = raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise HousekeepingError("worktree metadata is malformed") from exc
        key, separator, value = line.partition(" ")
        current[key] = value if separator else "1"
    if current:
        rows.append(current)
    if rows:
        rows[0]["harness_primary"] = "1"
    return rows


def checked_out_branches(repo: Path) -> List[str]:
    return [
        row["branch"][len("refs/heads/") :]
        for row in worktree_rows(repo)
        if row.get("branch", "").startswith("refs/heads/")
    ]


def local_branch_records(repo: Path) -> Tuple[List[Dict[str, Any]], Optional[str], bool]:
    prs = pull_requests(repo)
    main_oid = origin_main(repo)
    current_result = git(repo, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    current = text(current_result).strip() if current_result.returncode == 0 else ""
    held = set(checked_out_branches(repo))
    records: List[Dict[str, Any]] = []
    for line in text(
        git(repo, "for-each-ref", "--format=%(refname:short)\t%(objectname)", "refs/heads")
    ).splitlines():
        fields = line.split("\t")
        if len(fields) != 2:
            die("local branch metadata is malformed")
        name, tip = fields
        if name == current:
            records.append({"name": name, "tip": tip, "candidate": False, "reason": "current", "pr": None})
        elif name in held:
            records.append({"name": name, "tip": tip, "candidate": False, "reason": "worktree-held", "pr": None})
        else:
            records.append(classify_tip(repo, name, tip, prs, main_oid))
    return records, main_oid, prs is not None


def plan_branches(repo: Path) -> Dict[str, Any]:
    records, main_oid, api_ok = local_branch_records(repo)
    payload = {"origin_main": main_oid, "api_ok": api_ok, "records": records}
    receipt, token = publish_plan("branches", repo, payload)
    candidates = [row for row in records if row["candidate"]]
    print(f"HOUSEKEEPING routine=branches mode=plan candidates={len(candidates)} reports={len(records)-len(candidates)} api={'ok' if api_ok else 'unknown'}")
    for row in records:
        label = "CANDIDATE" if row["candidate"] else "REPORT"
        pr = row["pr"]["number"] if row.get("pr") else "none"
        print(f"  {label} branch={row['name']} tip={row['tip']} reason={row['reason']} pr={pr}")
    print(f"  RECEIPT path={receipt} token={token}")
    return payload


def same_candidate_records(left: List[Dict[str, Any]], right: List[Dict[str, Any]]) -> bool:
    return left == right


def apply_branches(repo: Path, receipt_path: Path, token: str) -> None:
    plan = load_plan(receipt_path, token, "branches", repo)
    current, main_oid, api_ok = local_branch_records(repo)
    if not api_ok or main_oid != plan.get("origin_main"):
        die("branch mutable state changed or is unknown")
    if not same_candidate_records(current, plan.get("records", [])):
        die("branch candidate set changed; re-plan")
    candidates = [row for row in current if row["candidate"]]
    if not candidates:
        print("HOUSEKEEPING routine=branches mode=apply removed=0 reason=no-candidates")
        return
    transaction = transaction_id("branches")
    archived = archive_create(
        repo,
        [(row["name"], row["tip"]) for row in candidates],
        transaction,
        str(receipt_path),
        {
            row["name"]: {
                "classification": row["reason"],
                "pr": str(row["pr"]["number"]) if row.get("pr") else "none",
            }
            for row in candidates
        },
    )
    commands = ["start"]
    for row in candidates:
        commands.append(f"delete refs/heads/{row['name']} {row['tip']}")
    commands.extend(("prepare", "commit"))
    run(
        ["git", "-C", str(repo), "update-ref", "--stdin"],
        input_bytes=("\n".join(commands) + "\n").encode(),
    )
    print(
        "HOUSEKEEPING routine=branches mode=apply "
        f"removed={len(candidates)} archive_receipt={archived['receipt']}"
    )


def remote_records(repo: Path) -> Tuple[List[Dict[str, Any]], Optional[str], bool]:
    prs = pull_requests(repo)
    main_oid = origin_main(repo)
    rows: List[Dict[str, Any]] = []
    output = text(
        git(
            repo,
            "for-each-ref",
            "--format=%(refname:short)\t%(objectname)",
            "refs/remotes/origin",
        )
    )
    for line in output.splitlines():
        short, tip = line.split("\t", 1)
        if short in {"origin", "origin/HEAD", "origin/main"}:
            continue
        name = short[len("origin/") :] if short.startswith("origin/") else short
        classified = classify_tip(repo, name, tip, prs, main_oid)
        classified["candidate"] = False
        rows.append(classified)
    return rows, main_oid, prs is not None


def plan_remotes(repo: Path) -> None:
    records, main_oid, api_ok = remote_records(repo)
    receipt, token = publish_plan(
        "remotes", repo, {"origin_main": main_oid, "api_ok": api_ok, "records": records}
    )
    print(f"HOUSEKEEPING routine=remotes mode=report branches={len(records)} api={'ok' if api_ok else 'unknown'} apply=unavailable")
    for row in records:
        pr = row["pr"]["number"] if row.get("pr") else "none"
        print(f"  REPORT remote_branch={row['name']} tip={row['tip']} reason={row['reason']} pr={pr}")
    print(f"  RECEIPT path={receipt} token={token}")


def strict_descendant(path: Path, boundary: Path) -> bool:
    try:
        path.relative_to(boundary)
    except ValueError:
        return False
    return path != boundary


def scratch_boundaries() -> List[Path]:
    override = testing_override("HARNESS_TEST_WORKTREE_BOUNDARIES")
    raw = override.split(os.pathsep) if override else [os.environ.get("TMPDIR", "/tmp")]
    boundaries: List[Path] = []
    for value in raw:
        lexical = Path(value)
        if lexical.is_symlink() or not lexical.is_dir():
            die("worktree scratch boundary is unsafe")
        path = lexical.resolve(strict=True)
        boundaries.append(path)
    return boundaries


def status_counts(path: Path) -> Dict[str, int]:
    result = git(
        path,
        "status",
        "--porcelain=v2",
        "--untracked-files=all",
        "--ignored=matching",
        "-z",
    )
    counts = {"tracked": 0, "untracked": 0, "ignored": 0}
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        marker = record[:1]
        if marker in {b"1", b"2", b"u"}:
            counts["tracked"] += 1
        elif marker == b"?":
            counts["untracked"] += 1
        elif marker == b"!":
            counts["ignored"] += 1
        else:
            die("worktree status record is malformed")
    return counts


def nested_repository_count(root: Path) -> int:
    count = 0
    for directory, names, files in os.walk(str(root), followlinks=False):
        current = Path(directory)
        if current != root and (".git" in names or ".git" in files):
            count += 1
        names[:] = [name for name in names if name != ".git"]
    return count


def submodule_count(root: Path) -> int:
    if (root / ".gitmodules").exists():
        return 1
    result = git(root, "submodule", "status", "--recursive", check=False)
    if result.returncode != 0:
        return 1
    return sum(1 for line in text(result).splitlines() if line.strip())


def path_below(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def linux_process_use(root: Path) -> Tuple[int, bool]:
    users = run(["ps", "-eo", "uid=,pid="], check=False)
    if users.returncode != 0:
        return 0, False
    pids: List[str] = []
    for line in text(users).splitlines():
        fields = line.split()
        if len(fields) == 2 and fields[0] == str(os.getuid()) and fields[1].isdigit():
            pids.append(fields[1])
    used = set()
    complete = True
    for pid in pids:
        process = Path("/proc") / pid
        links: List[Path] = [process / "cwd"]
        fd = process / "fd"
        try:
            links.extend(fd / name for name in os.listdir(str(fd)))
        except FileNotFoundError:
            continue
        except PermissionError:
            complete = False
            continue
        for link in links:
            try:
                value = Path(os.readlink(str(link)))
            except FileNotFoundError:
                continue
            except PermissionError:
                complete = False
                continue
            if value.is_absolute() and path_below(value, root):
                used.add(pid)
    return len(used), complete


def lsof_process_use(root: Path) -> Tuple[int, bool]:
    program = shutil.which("lsof")
    if not program:
        return 0, False
    result = run([program, "-Fn", "+D", str(root)], check=False)
    if result.returncode not in {0, 1}:
        return 0, False
    processes = {
        line[1:]
        for line in text(result).splitlines()
        if line.startswith("p") and line[1:].isdigit()
    }
    return len(processes), True


def process_use(root: Path) -> Tuple[int, bool]:
    if shutil.which("lsof"):
        return lsof_process_use(root)
    if sys.platform.startswith("linux"):
        return linux_process_use(root)
    return 0, False


def tree_facts(root: Path) -> Tuple[int, int]:
    device = root.stat().st_dev
    entries = 0
    total = 0
    stack = [root]
    while stack:
        current = stack.pop()
        info = current.lstat()
        if info.st_dev != device:
            continue
        entries += 1
        total += info.st_size
        if stat.S_ISDIR(info.st_mode) and not stat.S_ISLNK(info.st_mode):
            with os.scandir(str(current)) as iterator:
                stack.extend(Path(entry.path) for entry in iterator)
    return entries, total


def worktree_snapshot(
    repo: Path,
    row: Dict[str, str],
    prs: Optional[List[Dict[str, Any]]],
    main_oid: Optional[str],
) -> Dict[str, Any]:
    raw_path = Path(row.get("worktree", ""))
    result: Dict[str, Any] = {
        "path": str(raw_path),
        "tip": row.get("HEAD", ""),
        "branch": row.get("branch", "").replace("refs/heads/", "", 1),
        "candidate": False,
        "reasons": [],
    }
    reasons: List[str] = result["reasons"]
    if not raw_path.is_absolute() or not raw_path.exists() or raw_path.is_symlink():
        reasons.append("path-missing-or-unsafe")
        return result
    path = raw_path.resolve(strict=True)
    result["path"] = str(path)
    if row.get("harness_primary") == "1":
        reasons.append("primary-worktree")
        return result
    if path == repo:
        reasons.append("current-worktree")
        return result
    boundaries = scratch_boundaries()
    boundary = next((item for item in boundaries if strict_descendant(path, item)), None)
    if not boundary:
        reasons.append("outside-scratch-boundary")
    else:
        result["boundary"] = str(boundary)
    if path.lstat().st_uid != os.getuid():
        reasons.append("owner-mismatch")
    if "locked" in row:
        reasons.append("locked")
    branch = result["branch"]
    tip = result["tip"]
    if not branch or not OID_RE.fullmatch(tip):
        reasons.append("detached-or-tip-unknown")
    else:
        classification = classify_tip(repo, branch, tip, prs, main_oid)
        result["branch_reason"] = classification["reason"]
        result["pr"] = classification.get("pr")
        if not classification["candidate"]:
            reasons.append("branch-" + classification["reason"])
    try:
        counts = status_counts(path)
    except HousekeepingError:
        reasons.append("status-unknown")
        counts = {"tracked": -1, "untracked": -1, "ignored": -1}
    result.update(counts)
    for key in ("tracked", "untracked", "ignored"):
        if counts[key] != 0:
            reasons.append(key + "-residue")
    nested = nested_repository_count(path)
    submodules = submodule_count(path)
    result.update(nested=nested, submodules=submodules)
    if nested:
        reasons.append("nested-repository")
    if submodules:
        reasons.append("submodule")
    processes, process_complete = process_use(path)
    result.update(processes=processes, process_scan_complete=process_complete)
    if processes:
        reasons.append("live-process-or-open-file")
    if not process_complete:
        reasons.append("process-scan-unknown")
    marker = path / ".git"
    if marker.is_symlink() or not marker.is_file():
        reasons.append("git-marker-identity-mismatch")
    else:
        marker_info = marker.lstat()
        if marker_info.st_uid != os.getuid() or marker_info.st_nlink != 1:
            reasons.append("git-marker-identity-mismatch")
    common = Path(text(git(repo, "rev-parse", "--git-common-dir")).strip())
    if not common.is_absolute():
        common = repo / common
    common = common.resolve(strict=True)
    admin_parent = common / "worktrees"
    try:
        admin_raw = Path(text(git(path, "rev-parse", "--absolute-git-dir")).strip())
        if admin_raw.is_symlink() or not admin_raw.is_dir():
            raise FileNotFoundError
        admin = admin_raw.resolve(strict=True)
    except (HousekeepingError, FileNotFoundError):
        reasons.append("admin-unknown")
    else:
        result.update(admin=str(admin), admin_boundary=str(admin_parent))
        if admin.parent != admin_parent or admin.lstat().st_uid != os.getuid():
            reasons.append("admin-identity-mismatch")
        try:
            marker_value = marker.read_text(encoding="utf-8").strip()
            backlink = (admin / "gitdir").read_text(encoding="utf-8").strip()
        except (OSError, UnicodeDecodeError):
            reasons.append("admin-backlink-unknown")
        else:
            expected_marker = "gitdir: " + str(admin_raw)
            if marker_value != expected_marker or Path(backlink).resolve() != marker.resolve():
                reasons.append("admin-backlink-mismatch")
    entries, bytes_count = tree_facts(path)
    result.update(entries=entries, bytes=bytes_count)
    result["candidate"] = not reasons
    return result


def guarded_program() -> Path:
    root = Path(os.environ.get("HARNESS_ROOT", Path(__file__).resolve().parent.parent))
    program = root / "shared/skills/guarded-bulk-delete/scripts/guarded-delete"
    if not program.is_file() or not os.access(str(program), os.X_OK):
        die("guarded-delete is unavailable")
    return program


def guarded_plan(repo: Path, boundary: Path, target: Path, manifest: Path) -> str:
    result = run(
        [
            str(guarded_program()),
            "plan",
            "--within",
            str(boundary),
            "--manifest",
            str(manifest),
            "--",
            str(target),
        ],
        cwd=repo,
    )
    for line in text(result).splitlines():
        if line.startswith("TOKEN sha256="):
            return line.split("=", 1)[1]
    die("guarded-delete plan omitted its token")


def select_worktree_records(
    records: List[Dict[str, Any]], selected_path: Optional[str]
) -> Optional[str]:
    if selected_path is None:
        return None
    requested = Path(selected_path)
    if not requested.is_absolute() or not requested.exists() or requested.is_symlink():
        die("selected worktree path is missing or unsafe")
    canonical = str(requested.resolve(strict=True))
    matches = [record for record in records if record.get("path") == canonical]
    if len(matches) != 1:
        die("selected worktree is not an exact repository worktree")
    for record in records:
        if record is matches[0] or not record.get("candidate"):
            continue
        record["candidate"] = False
        record["reasons"].append("not-selected")
    return canonical


def plan_worktrees(repo: Path, selected_path: Optional[str] = None) -> None:
    prs = pull_requests(repo)
    main_oid = origin_main(repo)
    rows = worktree_rows(repo)
    records = [worktree_snapshot(repo, row, prs, main_oid) for row in rows]
    selected = select_worktree_records(records, selected_path)
    candidates = [record for record in records if record["candidate"]]
    _lexical, state = state_directory()
    manifests = state / "worktree-manifests"
    manifests.mkdir(mode=0o700, exist_ok=True)
    if manifests.is_symlink() or manifests.lstat().st_uid != os.getuid() or stat.S_IMODE(manifests.lstat().st_mode) != 0o700:
        die("worktree manifest directory is unsafe")
    for index, record in enumerate(candidates):
        marker = transaction_id(f"worktree-{index}")
        directory_manifest = manifests / f"{marker}-directory.manifest"
        admin_manifest = manifests / f"{marker}-admin.manifest"
        record["directory_manifest"] = str(directory_manifest)
        record["directory_token"] = guarded_plan(
            repo, Path(record["boundary"]), Path(record["path"]), directory_manifest
        )
        record["admin_manifest"] = str(admin_manifest)
        record["admin_token"] = guarded_plan(
            repo,
            Path(record["admin_boundary"]),
            Path(record["admin"]),
            admin_manifest,
        )
    receipt, token = publish_plan(
        "worktrees",
        repo,
        {
            "origin_main": main_oid,
            "api_ok": prs is not None,
            "selected_path": selected,
            "records": records,
        },
    )
    print(f"HOUSEKEEPING routine=worktrees mode=plan candidates={len(candidates)} reports={len(records)-len(candidates)} api={'ok' if prs is not None else 'unknown'} selected={selected or 'all'}")
    for record in records:
        label = "CANDIDATE" if record["candidate"] else "REPORT"
        reason = "eligible" if record["candidate"] else ",".join(record["reasons"])
        print(f"  {label} worktree={record['path']} branch={record['branch'] or 'detached'} tip={record['tip'] or 'unknown'} reason={reason} entries={record.get('entries', 0)} bytes={record.get('bytes', 0)}")
    print(f"  RECEIPT path={receipt} token={token}")


def execution_state(path: Path, value: Dict[str, Any]) -> None:
    payload = json_bytes(value)
    descriptor, temporary_name = tempfile.mkstemp(prefix=".worktree-state-", dir=str(path.parent))
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(str(temporary), str(path))
        os.chmod(str(path), 0o600)
        fsync_directory(path.parent)
    finally:
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()


def load_recovery_state(repo: Path, path: Path) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    validate_private_file(path)
    _lexical, state = state_directory()
    if path.resolve(strict=True).parent != state or not path.name.startswith(
        "worktree-apply-"
    ):
        die("worktree recovery receipt is outside durable state")
    try:
        progress = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("worktree recovery receipt is malformed") from exc
    if (
        not isinstance(progress, dict)
        or progress.get("schema") != "harness-housekeeping-worktree-apply-v1"
        or not isinstance(progress.get("plan"), str)
        or not isinstance(progress.get("plan_sha256"), str)
        or not re.fullmatch(r"[0-9a-f]{64}", progress["plan_sha256"])
        or not isinstance(progress.get("completed"), list)
        or any(not isinstance(item, str) for item in progress["completed"])
    ):
        die("worktree recovery receipt schema changed")
    plan_path = Path(progress["plan"])
    validate_private_file(plan_path)
    plans = state / "plans"
    if plan_path.resolve(strict=True).parent != plans.resolve(strict=True):
        die("worktree recovery plan is outside durable state")
    if digest(plan_path) != progress["plan_sha256"]:
        die("worktree recovery plan digest changed")
    try:
        plan = json.loads(plan_path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("worktree recovery plan is malformed") from exc
    if (
        not isinstance(plan, dict)
        or plan.get("schema") != PLAN_SCHEMA
        or plan.get("kind") != "worktrees"
        or plan.get("repository") != str(repo)
        or plan.get("repository_id") != list(path_id(repo))
        or not isinstance(plan.get("records"), list)
    ):
        die("worktree recovery repository or plan changed")
    return progress, plan


def recovery_admin_identity(
    repo: Path, record: Dict[str, Any], path: Path, admin: Path
) -> None:
    if admin.is_symlink() or not admin.is_dir() or admin.lstat().st_uid != os.getuid():
        die("worktree recovery administration identity changed")
    if (admin / "locked").exists() or (admin / "locked").is_symlink():
        die("worktree recovery administration became locked")
    rows = [
        row
        for row in worktree_rows(repo)
        if row.get("worktree") == str(path)
    ]
    if (
        len(rows) != 1
        or rows[0].get("HEAD") != record["tip"]
        or rows[0].get("branch") != f"refs/heads/{record['branch']}"
    ):
        die("worktree recovery administration metadata changed")
    try:
        backlink = (admin / "gitdir").read_text(encoding="utf-8").strip()
        head = (admin / "HEAD").read_text(encoding="utf-8").strip()
    except (OSError, UnicodeDecodeError) as exc:
        raise HousekeepingError(
            "worktree recovery administration metadata is unreadable"
        ) from exc
    if Path(backlink).resolve() != (path / ".git").resolve() or head != (
        f"ref: refs/heads/{record['branch']}"
    ):
        die("worktree recovery administration backlink changed")


def recover_worktree(repo: Path, receipt_path: Path) -> None:
    progress, plan = load_recovery_state(repo, receipt_path)
    phase = progress.get("phase")
    if phase in {"complete", "recovered"}:
        remaining = progress.get("remaining", [])
        if not isinstance(remaining, list):
            die("worktree recovery remaining set changed")
        print(
            "HOUSEKEEPING routine=worktrees mode=recover "
            f"phase={phase} status=no-op remaining_replan={len(remaining)}"
        )
        return
    if phase not in {"directory-deleted", "admin-deleted", "branch-deleted"}:
        die("worktree recovery phase requires ordinary re-plan")
    current = progress.get("current")
    if not isinstance(current, str):
        die("worktree recovery current path is missing")
    candidates = [
        row
        for row in plan["records"]
        if isinstance(row, dict)
        and row.get("candidate") is True
        and row.get("path") == current
    ]
    if len(candidates) != 1:
        die("worktree recovery candidate changed")
    record = candidates[0]
    branch = record.get("branch")
    tip = record.get("tip")
    archive_receipt = progress.get("archive_receipt")
    if (
        not isinstance(branch, str)
        or not isinstance(tip, str)
        or not OID_RE.fullmatch(tip)
        or not isinstance(archive_receipt, str)
    ):
        die("worktree recovery candidate metadata changed")
    validate_item(branch, tip)
    branch_ref = f"refs/heads/{branch}"
    existing = git(repo, "rev-parse", "--verify", branch_ref, check=False)
    if existing.returncode == 0 and text(existing).strip() != tip:
        die("worktree recovery branch tip changed")
    if existing.returncode != 0 and phase == "directory-deleted":
        die("worktree recovery branch disappeared before administration cleanup")
    prs = pull_requests(repo)
    main_oid = origin_main(repo)
    classification = classify_tip(repo, branch, tip, prs, main_oid)
    if (
        not classification["candidate"]
        or classification["reason"] != record.get("branch_reason")
    ):
        die("worktree recovery merge classification changed or is unknown")
    path = Path(current)
    if not path.is_absolute() or path.exists() or path.is_symlink():
        die("worktree recovery directory is present or unsafe")
    archive_path = Path(archive_receipt)
    parsed_archive = parse_archive_receipt(archive_path)
    if (
        len(parsed_archive["items"]) != 1
        or parsed_archive["items"][0]["branch"] != branch
        or parsed_archive["items"][0]["tip"] != tip
    ):
        die("worktree recovery archive candidate changed")
    archive_audit(repo, archive_path)

    common = Path(text(git(repo, "rev-parse", "--git-common-dir")).strip())
    if not common.is_absolute():
        common = repo / common
    common = common.resolve(strict=True)
    admin_boundary = common / "worktrees"
    admin = Path(str(record.get("admin", "")))
    if (
        not admin.is_absolute()
        or admin.parent != admin_boundary
        or record.get("admin_boundary") != str(admin_boundary)
    ):
        die("worktree recovery administration path changed")
    if admin.exists() or admin.is_symlink():
        if phase != "directory-deleted":
            die("worktree recovery administration unexpectedly remains")
        recovery_admin_identity(repo, record, path, admin)
        _lexical, state = state_directory()
        manifests = state / "worktree-manifests"
        manifests.mkdir(mode=0o700, exist_ok=True)
        info = manifests.lstat()
        if (
            manifests.is_symlink()
            or info.st_uid != os.getuid()
            or stat.S_IMODE(info.st_mode) != 0o700
        ):
            die("worktree recovery manifest directory is unsafe")
        manifest = manifests / (transaction_id("worktree-recovery") + ".manifest")
        token = guarded_plan(repo, admin_boundary, admin, manifest)
        guarded_apply(repo, str(manifest), token)
    if admin.exists() or admin.is_symlink():
        die("worktree recovery administration survived deletion")
    progress["phase"] = "admin-deleted"
    execution_state(receipt_path, progress)

    held = [
        row
        for row in worktree_rows(repo)
        if row.get("branch") == f"refs/heads/{branch}"
    ]
    if held:
        die("worktree recovery branch remains worktree-held")
    existing = git(repo, "rev-parse", "--verify", branch_ref, check=False)
    if existing.returncode == 0 and text(existing).strip() != tip:
        die("worktree recovery branch tip changed")
    git(repo, "update-ref", "-d", branch_ref, tip)
    if git(repo, "show-ref", "--verify", "--quiet", branch_ref, check=False).returncode == 0:
        die("worktree recovery branch survived expected-old deletion")
    if current not in progress["completed"]:
        progress["completed"].append(current)
    progress["phase"] = "branch-deleted"
    execution_state(receipt_path, progress)
    planned_paths = [
        row.get("path")
        for row in plan["records"]
        if isinstance(row, dict) and row.get("candidate") is True
    ]
    remaining = [item for item in planned_paths if item not in progress["completed"]]
    progress["phase"] = "recovered" if remaining else "complete"
    progress.pop("current", None)
    if remaining:
        progress["remaining"] = remaining
    else:
        progress.pop("remaining", None)
    execution_state(receipt_path, progress)
    print(
        "HOUSEKEEPING routine=worktrees mode=recover "
        f"phase={progress['phase']} worktree={current} status=recovered "
        f"remaining_replan={len(remaining)}"
    )


def comparable_worktree(record: Dict[str, Any]) -> Dict[str, Any]:
    excluded = {"directory_manifest", "directory_token", "admin_manifest", "admin_token"}
    return {key: value for key, value in record.items() if key not in excluded}


def guarded_apply(repo: Path, manifest: str, token: str) -> None:
    run(
        [
            str(guarded_program()),
            "apply",
            "--manifest",
            manifest,
            "--token",
            token,
        ],
        cwd=repo,
    )


def apply_worktrees(repo: Path, receipt_path: Path, token: str) -> None:
    plan = load_plan(receipt_path, token, "worktrees", repo)
    prs = pull_requests(repo)
    main_oid = origin_main(repo)
    if prs is None or main_oid != plan.get("origin_main"):
        die("worktree mutable state changed or is unknown")
    current_rows = worktree_rows(repo)
    current = [worktree_snapshot(repo, row, prs, main_oid) for row in current_rows]
    select_worktree_records(current, plan.get("selected_path"))
    planned = plan.get("records", [])
    if [comparable_worktree(row) for row in current] != [comparable_worktree(row) for row in planned]:
        die("worktree candidate set changed; re-plan")
    candidates = [record for record in planned if record.get("candidate")]
    if not candidates:
        print("HOUSEKEEPING routine=worktrees mode=apply removed=0 reason=no-candidates")
        return
    _lexical, state = state_directory()
    state_path = state / (transaction_id("worktree-apply") + ".json")
    progress: Dict[str, Any] = {
        "schema": "harness-housekeeping-worktree-apply-v1",
        "plan": str(receipt_path),
        "plan_sha256": digest(receipt_path),
        "phase": "validated",
        "completed": [],
    }
    execution_state(state_path, progress)
    for record in candidates:
        transaction = transaction_id("worktree-archive")
        archived = archive_create(
            repo,
            [(record["branch"], record["tip"])],
            transaction,
            str(receipt_path),
            {
                record["branch"]: {
                    "classification": record.get("branch_reason", "worktree-eligible"),
                    "pr": str(record["pr"]["number"]) if record.get("pr") else "none",
                }
            },
        )
        progress.update(
            phase="archived",
            current=record["path"],
            archive_receipt=archived["receipt"],
        )
        execution_state(state_path, progress)
        guarded_apply(repo, record["directory_manifest"], record["directory_token"])
        progress["phase"] = "directory-deleted"
        execution_state(state_path, progress)
        if os.environ.get("HARNESS_TEST_INTERRUPT_AFTER_WORKTREE") == "1":
            if os.environ.get("HARNESS_TESTING") != "1":
                die("test interruption override is unsafe")
            die("synthetic interruption after worktree-directory deletion")
        if not repo.is_dir():
            die("primary repository changed after worktree deletion")
        archive_audit(repo, Path(archived["receipt"]))
        guarded_apply(repo, record["admin_manifest"], record["admin_token"])
        progress["phase"] = "admin-deleted"
        execution_state(state_path, progress)
        if os.environ.get("HARNESS_TEST_INTERRUPT_AFTER_ADMIN") == "1":
            if os.environ.get("HARNESS_TESTING") != "1":
                die("test interruption override is unsafe")
            die("synthetic interruption after worktree-admin deletion")
        branch_ref = f"refs/heads/{record['branch']}"
        git(repo, "update-ref", "-d", branch_ref, record["tip"])
        if git(repo, "show-ref", "--verify", "--quiet", branch_ref, check=False).returncode == 0:
            die("task branch survived expected-old deletion")
        progress["completed"].append(record["path"])
        progress["phase"] = "branch-deleted"
        execution_state(state_path, progress)
    progress["phase"] = "complete"
    progress.pop("current", None)
    execution_state(state_path, progress)
    print(
        "HOUSEKEEPING routine=worktrees mode=apply "
        f"removed={len(candidates)} receipt={state_path}"
    )


def owner_home() -> Path:
    override = testing_override("HARNESS_TEST_OWNER_HOME")
    return Path(override) if override else Path.home()


def launcher_candidates() -> List[Path]:
    home = owner_home()
    candidates: List[Path] = []
    for path in home.glob("*.sh"):
        if path.name == "run_this.sh" or path.is_symlink() or not path.is_file():
            continue
        info = path.lstat()
        if info.st_uid == os.getuid() and info.st_nlink == 1:
            candidates.append(path)
    return sorted(candidates)


def plan_launchers() -> None:
    candidates = launcher_candidates()
    print(f"HOUSEKEEPING routine=launchers mode=plan candidates={len(candidates)}")
    for path in candidates:
        print(f"  CANDIDATE launcher={path}")


def apply_launcher(value: Optional[str]) -> None:
    if not value:
        die("launcher apply requires --launcher with one exact candidate")
    candidates = launcher_candidates()
    target = Path(value).absolute()
    if target not in candidates:
        die("launcher is not a current exact candidate")
    target.unlink()
    print(f"HOUSEKEEPING routine=launchers mode=apply removed=1 launcher={target}")


def plan_scratch(repo: Path) -> None:
    candidates = [
        path
        for pattern in (".t*-sandbox", "*-scratch")
        for path in repo.glob(pattern)
        if path.is_dir()
    ]
    for path in candidates:
        print(f"  CANDIDATE scratch={path} route=guarded-bulk-delete")
    print(f"HOUSEKEEPING routine=scratch mode=plan candidates={len(candidates)} route=guarded-bulk-delete")


def plan_board(repo: Path) -> None:
    board = repo / "TODO.md"
    body = board.read_text(encoding="utf-8") if board.is_file() else ""
    lines = len(body.splitlines())
    words = len(body.split())
    active = sum(1 for line in body.splitlines() if line.startswith("### "))
    print(f"HOUSEKEEPING routine=board mode=report lines={lines} words={words} active={active} note=verify-context-gate-after-compaction")


def plan_evidence(repo: Path) -> None:
    count = sum(1 for path in (repo / "docs/audits").glob("*/cowork") if path.is_dir())
    print(f"HOUSEKEEPING routine=evidence mode=report cowork_sessions={count} note=retained-by-default")


def open_worktree(
    repo: Path,
    branch: Optional[str],
    destination_value: Optional[str],
    expected_main: Optional[str],
) -> None:
    if not branch or not destination_value or not expected_main:
        die("open-worktree requires --branch, --path, and --expected-main")
    if not OID_RE.fullmatch(expected_main):
        die("expected main tip is malformed")
    checked = git(repo, "check-ref-format", "--branch", branch, check=False)
    if checked.returncode != 0 or branch == "main":
        die("task branch name is unsafe")

    rows = worktree_rows(repo)
    if not rows or Path(rows[0].get("worktree", "")).resolve() != repo:
        die("worktree creation requires the primary repository root")
    current = text(
        git(repo, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    ).strip()
    if current != "main":
        die("reference checkout must be on main")
    counts = status_counts(repo)
    if counts["tracked"] or counts["untracked"]:
        die("reference checkout must be clean")
    local_main = text(git(repo, "rev-parse", "refs/heads/main")).strip()
    remote_main = origin_main(repo)
    head = text(git(repo, "rev-parse", "HEAD")).strip()
    if not remote_main or len({head, local_main, remote_main, expected_main}) != 1:
        die("reference checkout and expected protected main are not identical")
    if git(repo, "show-ref", "--verify", "--quiet", f"refs/heads/{branch}", check=False).returncode == 0:
        die("task branch already exists")

    destination = Path(destination_value)
    absolute = Path(os.path.abspath(os.fspath(destination)))
    if destination != absolute or destination.exists() or destination.is_symlink():
        die("task worktree path must be an absent absolute path")
    boundaries = scratch_boundaries()
    boundary = next(
        (item for item in boundaries if strict_descendant(absolute, item)), None
    )
    if not boundary:
        die("task worktree path is outside a declared scratch boundary")
    try:
        parent = absolute.parent.resolve(strict=True)
    except FileNotFoundError as exc:
        raise HousekeepingError("task worktree parent is unavailable") from exc
    if absolute.parent != parent:
        die("task worktree parent changed through a symlink")
    if not strict_descendant(parent, boundary) and parent != boundary:
        die("task worktree parent is outside the declared boundary")
    if parent != boundary and parent.lstat().st_uid != os.getuid():
        die("task worktree parent owner is unsafe")

    git(repo, "worktree", "add", "-b", branch, str(absolute), expected_main)
    matches = [
        row
        for row in worktree_rows(repo)
        if Path(row.get("worktree", "")).resolve() == absolute
    ]
    if (
        len(matches) != 1
        or matches[0].get("HEAD") != expected_main
        or matches[0].get("branch") != f"refs/heads/{branch}"
    ):
        die("created task worktree failed exact readback")
    print(
        "HOUSEKEEPING routine=worktree-open mode=apply "
        f"branch={branch} tip={expected_main} path={absolute} "
        f"ignored_reference_entries={counts['ignored']} status=created"
    )


def repository_from_environment(explicit: Optional[str] = None) -> Path:
    override = testing_override("HARNESS_TEST_HOUSEKEEPING_REPO")
    if override:
        root = Path(override)
    elif explicit:
        root = Path(explicit)
    else:
        root = Path(os.environ["HARNESS_ROOT"])
    return canonical_repo(root)


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(prog="harness housekeeping")
    action = value.add_mutually_exclusive_group(required=True)
    action.add_argument("--plan", action="store_true")
    action.add_argument("--apply", action="store_true")
    action.add_argument("--archive", action="store_true")
    action.add_argument("--audit", action="store_true")
    action.add_argument("--open-worktree", action="store_true")
    action.add_argument("--recover-worktree", action="store_true")
    value.add_argument(
        "--routine",
        choices=("all", "scratch", "branches", "remotes", "worktrees", "launchers", "board", "evidence"),
        default="all",
    )
    value.add_argument("--receipt")
    value.add_argument("--token")
    value.add_argument("--items")
    value.add_argument("--transaction")
    value.add_argument("--source", default="manual")
    value.add_argument("--launcher")
    value.add_argument("--repo")
    value.add_argument("--branch")
    value.add_argument("--path", dest="worktree_path")
    value.add_argument("--expected-main")
    return value


def require_receipt(arguments: argparse.Namespace) -> Tuple[Path, str]:
    if not arguments.receipt or not arguments.token:
        die("apply requires --receipt and --token")
    return Path(arguments.receipt).absolute(), arguments.token


def main(argv: Optional[Sequence[str]] = None) -> int:
    arguments = parser().parse_args(argv)
    repo = repository_from_environment(arguments.repo)
    if arguments.worktree_path and not (
        arguments.open_worktree
        or (arguments.plan and arguments.routine == "worktrees")
    ):
        die("--path is valid only for worktree open or an exact worktrees plan")
    if arguments.open_worktree:
        open_worktree(
            repo,
            arguments.branch,
            arguments.worktree_path,
            arguments.expected_main,
        )
        return 0
    if arguments.recover_worktree:
        if not arguments.receipt:
            die("worktree recovery requires --receipt")
        recover_worktree(repo, Path(arguments.receipt).absolute())
        return 0
    if arguments.archive:
        if not arguments.items or not arguments.transaction:
            die("archive requires --items and --transaction")
        result = archive_create(
            repo,
            parse_items(Path(arguments.items).absolute()),
            arguments.transaction,
            arguments.source,
        )
        print(f"HOUSEKEEPING routine=archive mode=apply refs={result['items']} bundle={result['bundle']} receipt={result['receipt']} status=verified")
        return 0
    if arguments.audit:
        if not arguments.receipt:
            die("audit requires --receipt")
        result = archive_audit(repo, Path(arguments.receipt).absolute())
        print(f"HOUSEKEEPING routine=archive mode=audit items={result['items']} live={result['live']} bundled={result['bundled']} status=pass")
        return 0
    if arguments.plan:
        selected = (
            ("scratch", plan_scratch),
            ("branches", plan_branches),
            ("remotes", plan_remotes),
            (
                "worktrees",
                lambda selected_repo: plan_worktrees(
                    selected_repo, arguments.worktree_path
                ),
            ),
            ("launchers", lambda _repo: plan_launchers()),
            ("board", plan_board),
            ("evidence", plan_evidence),
        )
        for name, operation in selected:
            if arguments.routine in {"all", name}:
                operation(repo)
        return 0
    if arguments.routine == "branches":
        receipt, token = require_receipt(arguments)
        apply_branches(repo, receipt, token)
        return 0
    if arguments.routine == "worktrees":
        receipt, token = require_receipt(arguments)
        apply_worktrees(repo, receipt, token)
        return 0
    if arguments.routine == "launchers":
        apply_launcher(arguments.launcher)
        return 0
    die("selected routine is report-only or apply requires an exact routine")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except HousekeepingError as exc:
        print(f"harness: {exc}", file=sys.stderr)
        raise SystemExit(2)
