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
from urllib.parse import urlsplit


ARCHIVE_SCHEMA = "harness-housekeeping-archive-v2"
OWNER_ALIAS_SCHEMA = "harness-housekeeping-owner-alias-v2"
OWNER_ALIAS_SCHEMA_V1 = "harness-housekeeping-owner-alias-v1"
COMPACTION_SCHEMA = "harness-housekeeping-compaction-v1"
GENERATION_SCHEMA = "harness-housekeeping-generation-v1"
PLAN_SCHEMA = "harness-housekeeping-plan-v2"
MAX_PLAN_AGE = 900
GENERATION_BYTES_TRIGGER = 512 * 1024 * 1024
GENERATION_RECEIPTS_TRIGGER = 30
GENERATION_AGE_DAYS_TRIGGER = 30
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


def generation_receipts_trigger() -> int:
    # Scale synthetic receipt fixtures only; production keeps the frozen limit.
    override = testing_override("HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER")
    if override is None:
        return GENERATION_RECEIPTS_TRIGGER
    if not re.fullmatch(r"[1-9]|[12][0-9]", override):
        die("test generation receipt trigger is invalid")
    return int(override)


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


def owner_alias_directory(*, create: bool = False) -> Path:
    state = state_directory()[1]
    directory = state / "owner-aliases"
    if create:
        directory.mkdir(mode=0o700, exist_ok=True)
    if not directory.exists() and not directory.is_symlink():
        return directory
    if directory.is_symlink() or not directory.is_dir():
        die("archive owner-alias directory identity is unsafe")
    info = directory.lstat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        die("archive owner-alias directory identity is unsafe")
    return directory


def normalized_remote_identity(value: str) -> str:
    if not value or CONTROL_RE.search(value) or any(character.isspace() for character in value):
        die("archive owner terminal remote is malformed")
    scp = (
        None
        if "://" in value
        else re.fullmatch(
            r"(?:(?P<user>[A-Za-z0-9._-]+)@)?(?P<host>[A-Za-z0-9.-]+):(?P<path>[^:]+)",
            value,
        )
    )
    if scp:
        host = scp.group("host").lower()
        path = scp.group("path")
    else:
        parsed = urlsplit(value)
        if parsed.scheme not in {"ssh", "https"} or not parsed.hostname:
            die("archive owner terminal remote must be credential-free SSH or HTTPS")
        if parsed.password is not None or (parsed.scheme == "https" and parsed.username):
            die("archive owner terminal remote contains credential material")
        if parsed.query or parsed.fragment:
            die("archive owner terminal remote is malformed")
        host = parsed.hostname.lower()
        try:
            port = parsed.port
        except ValueError as exc:
            raise HousekeepingError("archive owner terminal remote port is malformed") from exc
        if port is not None:
            host += f":{port}"
        path = parsed.path.lstrip("/")
    path = path.rstrip("/")
    if path.endswith(".git"):
        path = path[:-4]
    if (
        not host
        or not path
        or path.startswith("-")
        or "//" in path
        or any(part in {"", ".", ".."} for part in path.split("/"))
    ):
        die("archive owner terminal remote identity is malformed")
    return f"{host}/{path}"


def single_origin(repo: Path) -> str:
    result = git(repo, "remote", "get-url", "--all", "origin", check=False)
    rows = text(result).splitlines() if result.returncode == 0 else []
    if len(rows) != 1:
        die("archive owner origin is missing or ambiguous")
    return rows[0]


def terminal_remote_identity(repo: Path) -> str:
    override = testing_override("HARNESS_TEST_REMOTE_IDENTITY")
    if override:
        return normalized_remote_identity(override)
    return normalized_remote_identity(single_origin(repo))


def exact_local_origin(repo: Path) -> Path:
    value = single_origin(repo)
    lexical = Path(value)
    if not lexical.is_absolute():
        die("archive legacy owner origin is not an exact absolute local path")
    canonical = lexical.resolve(strict=False)
    if lexical != canonical or lexical.is_symlink():
        die("archive legacy owner origin traverses a symlink")
    return canonical


def alias_tip_digest(tips: Sequence[Dict[str, str]]) -> str:
    rows = sorted((row["archive"], row["tip"]) for row in tips)
    return hashlib.sha256(json.dumps(rows, separators=(",", ":")).encode()).hexdigest()


def owner_alias_name(source: Path) -> str:
    return hashlib.sha256(str(source).encode()).hexdigest() + ".json"


def owner_alias_source_key(source: Path) -> str:
    try:
        return str(source.resolve(strict=True))
    except FileNotFoundError:
        return str(source)


def parse_owner_alias(path: Path) -> Dict[str, Any]:
    validate_private_file(path)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("archive owner alias is malformed") from exc
    required = {
        "schema",
        "created_utc",
        "source_receipt",
        "source_sha256",
        "legacy_repository",
        "legacy_repository_id",
        "legacy_git_common_dir",
        "bundle",
        "bundle_sha256",
        "tips",
        "owner_repository",
        "owner_id",
        "owner_remote",
        "protected_main",
        "mapping",
        "restore_drill",
    }
    schema = value.get("schema") if isinstance(value, dict) else None
    expected = required | ({"recovery"} if schema == OWNER_ALIAS_SCHEMA else set())
    if (
        not isinstance(value, dict)
        or schema not in {OWNER_ALIAS_SCHEMA_V1, OWNER_ALIAS_SCHEMA}
        or set(value) != expected
    ):
        die("archive owner alias fields are malformed")
    absolute_fields = (
        "source_receipt",
        "legacy_repository",
        "legacy_git_common_dir",
        "bundle",
        "owner_repository",
    )
    if (
        any(
            not isinstance(value[field], str) or not Path(value[field]).is_absolute()
            for field in absolute_fields
        )
        or any(
            not re.fullmatch(r"[0-9a-f]{64}", str(value[field]))
            for field in ("source_sha256", "bundle_sha256")
        )
    ):
        die("archive owner alias identity is malformed")
    for field in ("legacy_repository_id", "owner_id"):
        identity = value[field]
        if (
            not isinstance(identity, list)
            or len(identity) != 2
            or any(not isinstance(item, int) or item < 0 for item in identity)
        ):
            die("archive owner alias filesystem identity is malformed")
    try:
        datetime.strptime(value["created_utc"], "%Y-%m-%dT%H:%M:%SZ")
    except (TypeError, ValueError) as exc:
        raise HousekeepingError("archive owner alias creation time is malformed") from exc
    tips = value["tips"]
    if (
        not isinstance(tips, list)
        or not tips
        or any(
            not isinstance(row, dict)
            or set(row) != {"archive", "tip"}
            or not isinstance(row["archive"], str)
            or run(["git", "check-ref-format", row["archive"]], check=False).returncode
            != 0
            or not OID_RE.fullmatch(str(row["tip"]))
            for row in tips
        )
        or len({row["archive"] for row in tips}) != len(tips)
        or len({row["tip"] for row in tips}) != len(tips)
        or tips != sorted(tips, key=lambda row: (row["archive"], row["tip"]))
    ):
        die("archive owner alias tips are malformed")
    remote = value["owner_remote"]
    if not isinstance(remote, str) or normalized_remote_identity("ssh://" + remote) != remote:
        die("archive owner alias remote identity is malformed")
    protected = value["protected_main"]
    if (
        not isinstance(protected, dict)
        or set(protected) != {"ref", "tip"}
        or protected["ref"] != "refs/remotes/origin/main"
        or not OID_RE.fullmatch(str(protected["tip"]))
    ):
        die("archive owner alias protected-main identity is malformed")
    mapping = value["mapping"]
    if not isinstance(mapping, dict) or set(mapping) != {
        "method",
        "legacy_origin",
        "evidence_repository",
        "evidence_repository_id",
        "evidence_repository_remote",
        "evidence_commit",
        "evidence_path",
        "evidence_sha256",
    }:
        die("archive owner alias mapping fields are malformed")
    evidence_path = mapping["evidence_path"]
    if (
        mapping["method"]
        not in {"direct-local-origin-v1", "authorized-single-relocation-v1"}
        or not isinstance(mapping["legacy_origin"], str)
        or not Path(mapping["legacy_origin"]).is_absolute()
        or not isinstance(mapping["evidence_repository"], str)
        or not Path(mapping["evidence_repository"]).is_absolute()
        or not isinstance(mapping["evidence_repository_id"], list)
        or len(mapping["evidence_repository_id"]) != 2
        or any(
            not isinstance(item, int) or item < 0
            for item in mapping["evidence_repository_id"]
        )
        or not isinstance(mapping["evidence_repository_remote"], str)
        or normalized_remote_identity("ssh://" + mapping["evidence_repository_remote"])
        != mapping["evidence_repository_remote"]
        or not OID_RE.fullmatch(str(mapping["evidence_commit"]))
        or not isinstance(evidence_path, str)
        or Path(evidence_path).is_absolute()
        or not evidence_path
        or any(part in {"", ".", ".."} for part in Path(evidence_path).parts)
        or not re.fullmatch(r"[0-9a-f]{64}", str(mapping["evidence_sha256"]))
    ):
        die("archive owner alias mapping identity is malformed")
    if mapping["method"] == "direct-local-origin-v1":
        if mapping["legacy_origin"] != value["owner_repository"]:
            die("archive owner direct mapping changed")
    elif mapping["legacy_origin"] == value["owner_repository"]:
        die("archive owner relocation did not change the canonical owner")
    drill = value["restore_drill"]
    if (
        not isinstance(drill, dict)
        or set(drill) != {"method", "verified_utc", "headset_sha256"}
        or drill["method"] != "independent-bare-fetch-exact-heads-v1"
        or not re.fullmatch(r"[0-9a-f]{64}", str(drill["headset_sha256"]))
        or drill["headset_sha256"] != alias_tip_digest(tips)
    ):
        die("archive owner alias restore proof is malformed")
    try:
        datetime.strptime(drill["verified_utc"], "%Y-%m-%dT%H:%M:%SZ")
    except (TypeError, ValueError) as exc:
        raise HousekeepingError("archive owner alias restore time is malformed") from exc
    if schema == OWNER_ALIAS_SCHEMA:
        recovery = value["recovery"]
        if not isinstance(recovery, dict) or set(recovery) != {"method", "generations"}:
            die("archive owner alias recovery fields are malformed")
        generations = recovery["generations"]
        if (
            recovery["method"]
            not in {"source-bundle-v1", "generation-recovery-v1"}
            or not isinstance(generations, list)
            or (
                recovery["method"] == "source-bundle-v1"
                and generations
            )
            or (
                recovery["method"] == "generation-recovery-v1"
                and len(generations) < 2
            )
            or any(
                not isinstance(row, dict)
                or set(row) != {"receipt", "sha256"}
                or not isinstance(row["receipt"], str)
                or not Path(row["receipt"]).is_absolute()
                or not re.fullmatch(r"[0-9a-f]{64}", str(row["sha256"]))
                for row in generations
            )
            or len({row["receipt"] for row in generations}) != len(generations)
        ):
            die("archive owner alias recovery identity is malformed")
    source = Path(value["source_receipt"])
    if path.name != owner_alias_name(source):
        die("archive owner alias filename changed")
    return value


def load_owner_aliases() -> Dict[str, Tuple[Path, Dict[str, Any]]]:
    directory = owner_alias_directory()
    if not directory.exists():
        return {}
    aliases: Dict[str, Tuple[Path, Dict[str, Any]]] = {}
    repository_bindings: Dict[Tuple[str, Tuple[int, ...]], Tuple[Any, ...]] = {}
    paths = sorted(directory.iterdir())
    if any(path.suffix != ".json" for path in paths):
        die("archive owner-alias directory contains an unknown artifact")
    for path in paths:
        value = parse_owner_alias(path)
        source = value["source_receipt"]
        source_key = owner_alias_source_key(Path(source))
        if source_key in aliases:
            die("archive source has duplicate owner aliases")
        repository_key = (
            value["legacy_repository"],
            tuple(value["legacy_repository_id"]),
        )
        mapping = value["mapping"]
        binding = (
            value["owner_repository"],
            tuple(value["owner_id"]),
            value["owner_remote"],
            mapping["method"],
            mapping["legacy_origin"],
            mapping["evidence_repository"],
            tuple(mapping["evidence_repository_id"]),
            mapping["evidence_repository_remote"],
            mapping["evidence_path"],
            mapping["evidence_sha256"],
        )
        if (
            repository_key in repository_bindings
            and repository_bindings[repository_key] != binding
        ):
            die("archive repository has mixed owner aliases")
        repository_bindings[repository_key] = binding
        aliases[source_key] = (path, value)
    return aliases


def validate_owner_alias(
    source: Path,
    parsed: Dict[str, Any],
    alias: Dict[str, Any],
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> Path:
    values = parsed["values"]
    expected_tips = sorted(
        ({"archive": row["archive"], "tip": row["tip"]} for row in parsed["items"]),
        key=lambda row: (row["archive"], row["tip"]),
    )
    try:
        legacy_identity = [
            int(item) for item in values.get("repository_id", "").split(":")
        ]
    except ValueError as exc:
        raise HousekeepingError("archive owner alias legacy identity is malformed") from exc
    required_bindings = (
        owner_alias_source_key(Path(alias["source_receipt"]))
        == owner_alias_source_key(source)
        and alias["source_sha256"] == digest(source)
        and alias["legacy_repository"] == values.get("repository_canonical")
        and alias["legacy_repository_id"]
        == legacy_identity
        and alias["legacy_git_common_dir"] == values["git_common_dir"]
        and alias["bundle"] == values["bundle"]
        and alias["bundle_sha256"] == values["bundle_sha256"]
        and alias["tips"] == expected_tips
    )
    if not required_bindings:
        die("archive owner alias no longer matches its source receipt")
    mapping = alias["mapping"]
    evidence_value = mapping["evidence_repository"]
    evidence_cached = owner_cache.get(evidence_value) if owner_cache is not None else None
    if evidence_cached is None:
        evidence_repo = canonical_repo(Path(evidence_value))
        evidence_remote = terminal_remote_identity(evidence_repo)
        evidence_main = origin_main(evidence_repo)
        if evidence_main is None:
            die("archive owner mapping evidence protected main is unknown")
        evidence_cached = (evidence_repo, evidence_remote, evidence_main)
        if owner_cache is not None:
            owner_cache[evidence_value] = evidence_cached
    evidence_repo, evidence_remote, evidence_main = evidence_cached
    if (
        list(path_id(evidence_repo)) != mapping["evidence_repository_id"]
        or evidence_remote != mapping["evidence_repository_remote"]
        or is_ancestor(evidence_repo, mapping["evidence_commit"], evidence_main)
        is not True
    ):
        die("archive owner mapping evidence identity changed")
    evidence = git(
        evidence_repo,
        "show",
        f"{mapping['evidence_commit']}:{mapping['evidence_path']}",
        check=False,
    )
    if (
        evidence.returncode != 0
        or hashlib.sha256(evidence.stdout).hexdigest() != mapping["evidence_sha256"]
    ):
        die("archive owner mapping evidence changed")
    selected = None
    try:
        evidence_lines = evidence.stdout.decode("utf-8").splitlines()
    except UnicodeDecodeError as exc:
        raise HousekeepingError("archive owner mapping evidence is malformed") from exc
    if (
        not evidence_lines
        or evidence_lines[0]
        != "legacy_repository\tlegacy_origin\towner_repository\tmethod"
    ):
        die("archive owner mapping evidence schema changed")
    for line in evidence_lines[1:]:
        fields = line.split("\t")
        if len(fields) == 4 and fields[0] == alias["legacy_repository"]:
            if selected is not None:
                die("archive owner mapping evidence is duplicated")
            selected = fields
    if selected != [
        alias["legacy_repository"],
        mapping["legacy_origin"],
        alias["owner_repository"],
        mapping["method"],
    ]:
        die("archive owner mapping evidence no longer matches the alias")
    bundle = Path(alias["bundle"])
    if bundle.exists() or bundle.is_symlink():
        validate_private_file(bundle)
        if digest(bundle) != alias["bundle_sha256"]:
            die("archive owner alias source bundle changed")
    owner_value = alias["owner_repository"]
    cached = owner_cache.get(owner_value) if owner_cache is not None else None
    if cached is None:
        owner = canonical_repo(Path(owner_value))
        if list(path_id(owner)) != alias["owner_id"]:
            die("archive owner alias durable owner identity changed")
        remote = terminal_remote_identity(owner)
        current_main = origin_main(owner)
        if current_main is None:
            die("archive owner alias protected main is unknown")
        cached = (owner, remote, current_main)
        if owner_cache is not None:
            owner_cache[owner_value] = cached
    owner, remote, current_main = cached
    if list(path_id(owner)) != alias["owner_id"]:
        die("archive owner alias durable owner identity changed")
    if remote != alias["owner_remote"]:
        die("archive owner alias terminal remote changed")
    recorded_main = alias["protected_main"]["tip"]
    if (
        git(owner, "cat-file", "-e", f"{recorded_main}^{{commit}}", check=False).returncode
        != 0
        or is_ancestor(owner, recorded_main, current_main) is not True
    ):
        die("archive owner alias protected main rewound or diverged")
    return owner


def resolve_archive_owner(
    source: Path,
    parsed: Optional[Dict[str, Any]] = None,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> Path:
    parsed = parsed or parse_archive_receipt(source)
    repository = Path(parsed["values"].get("repository_canonical", ""))
    if not repository.is_absolute():
        die("archive receipt repository identity is missing")
    if repository.exists() or repository.is_symlink():
        return canonical_repo(repository)
    alias_rows = aliases if aliases is not None else load_owner_aliases()
    row = alias_rows.get(owner_alias_source_key(source))
    if row is None:
        die("archive legacy repository is absent without an owner alias")
    return validate_owner_alias(source, parsed, row[1], owner_cache)


def committed_mapping_evidence(
    coordinator_repo: Path,
    commit: str,
    relative_path: str,
    legacy_repository: str,
    legacy_origin: str,
    owner_repository: str,
) -> Tuple[str, str, str]:
    if not OID_RE.fullmatch(commit):
        die("archive owner mapping evidence commit is malformed")
    path = Path(relative_path)
    if (
        path.is_absolute()
        or not relative_path
        or any(part in {"", ".", ".."} for part in path.parts)
    ):
        die("archive owner mapping evidence path is malformed")
    if git(coordinator_repo, "cat-file", "-e", f"{commit}^{{commit}}", check=False).returncode:
        die("archive owner mapping evidence commit is unavailable")
    protected = origin_main(coordinator_repo)
    if protected is None or is_ancestor(coordinator_repo, commit, protected) is not True:
        die("archive owner mapping evidence is outside protected main")
    result = git(coordinator_repo, "show", f"{commit}:{relative_path}", check=False)
    if result.returncode != 0:
        die("archive owner mapping evidence file is unavailable")
    payload = result.stdout
    try:
        lines = payload.decode("utf-8").splitlines()
    except UnicodeDecodeError as exc:
        raise HousekeepingError("archive owner mapping evidence is malformed") from exc
    expected_header = "legacy_repository\tlegacy_origin\towner_repository\tmethod"
    if not lines or lines[0] != expected_header:
        die("archive owner mapping evidence schema is unsupported")
    mappings: Dict[str, Tuple[str, str, str]] = {}
    for line in lines[1:]:
        fields = line.split("\t")
        if (
            len(fields) != 4
            or fields[0] in mappings
            or any(CONTROL_RE.search(field) for field in fields)
            or any(not Path(field).is_absolute() for field in fields[:3])
            or fields[3]
            not in {"direct-local-origin-v1", "authorized-single-relocation-v1"}
        ):
            die("archive owner mapping evidence row is malformed")
        mappings[fields[0]] = (fields[1], fields[2], fields[3])
    selected = mappings.get(legacy_repository)
    if selected is None or selected[:2] != (legacy_origin, owner_repository):
        die("archive owner mapping evidence does not match the requested owner")
    method = selected[2]
    if (method == "direct-local-origin-v1") != (legacy_origin == owner_repository):
        die("archive owner mapping evidence method changed")
    return method, hashlib.sha256(payload).hexdigest(), terminal_remote_identity(
        coordinator_repo
    )


def independent_alias_restore(
    coordinator_repo: Path,
    bundle: Path,
    tips: Sequence[Dict[str, str]],
) -> str:
    restore = Path(
        tempfile.mkdtemp(
            prefix="harness-owner-alias-", dir=str(scratch_boundaries()[0])
        )
    )
    try:
        git(restore, "init", "--bare")
        git(
            restore,
            "fetch",
            "--quiet",
            str(bundle),
            *[f"{row['archive']}:{row['archive']}" for row in tips],
        )
        for row in tips:
            restored = text(git(restore, "rev-parse", "--verify", row["archive"])).strip()
            if restored != row["tip"]:
                die("archive owner alias independent restore changed a tip")
        git(restore, "fsck", "--full", "--no-dangling")
    finally:
        remove_restore_tree(coordinator_repo, restore)
    return alias_tip_digest(tips)


def independent_alias_restore_sources(
    coordinator_repo: Path,
    tips: Sequence[Dict[str, str]],
    recovery_sources: Dict[str, Tuple[Path, str]],
) -> str:
    restore = Path(
        tempfile.mkdtemp(
            prefix="harness-owner-alias-", dir=str(scratch_boundaries()[0])
        )
    )
    try:
        git(restore, "init", "--bare")
        for row in tips:
            source = recovery_sources.get(row["tip"])
            if source is None:
                die("archive owner alias recovery source is incomplete")
            bundle, source_ref = source
            git(
                restore,
                "fetch",
                "--quiet",
                str(bundle),
                f"{source_ref}:{row['archive']}",
            )
            restored = text(
                git(restore, "rev-parse", "--verify", row["archive"])
            ).strip()
            if restored != row["tip"]:
                die("archive owner alias independent restore changed a tip")
        git(restore, "fsck", "--full", "--no-dangling")
    finally:
        remove_restore_tree(coordinator_repo, restore)
    return alias_tip_digest(tips)


def create_owner_alias(
    coordinator_repo: Path,
    source: Path,
    owner_value: str,
    legacy_origin_value: str,
    evidence_commit: str,
    evidence_path: str,
) -> Dict[str, Any]:
    state = state_directory()[1]
    validate_private_file(source)
    if source.resolve(strict=True).parent != state or source.suffix != ".receipt":
        die("archive owner alias source receipt is outside durable state")
    source_sha256 = digest(source)
    parsed = parse_archive_receipt(source)
    values = parsed["values"]
    legacy_value = values.get("repository_canonical")
    legacy_id = values.get("repository_id")
    if not legacy_value or not Path(legacy_value).is_absolute() or not legacy_id:
        die("archive owner alias requires archive-v2 repository identity")
    try:
        legacy_identity = [int(item) for item in legacy_id.split(":")]
    except ValueError as exc:
        raise HousekeepingError("archive owner alias legacy identity is malformed") from exc
    if len(legacy_identity) != 2 or any(item < 0 for item in legacy_identity):
        die("archive owner alias legacy identity is malformed")
    owner = canonical_repo(Path(owner_value))
    if str(owner) != owner_value:
        die("archive owner alias durable owner path is not exact")
    legacy_origin = Path(legacy_origin_value)
    if not legacy_origin.is_absolute():
        die("archive owner alias legacy origin is not absolute")
    method, evidence_sha256, evidence_remote = committed_mapping_evidence(
        coordinator_repo,
        evidence_commit,
        evidence_path,
        legacy_value,
        legacy_origin_value,
        owner_value,
    )
    legacy = Path(legacy_value)
    if legacy.exists() or legacy.is_symlink():
        canonical_legacy = canonical_repo(legacy)
        common = Path(
            text(git(canonical_legacy, "rev-parse", "--absolute-git-dir")).strip()
        ).resolve(strict=True)
        if common != Path(values["git_common_dir"]).resolve(strict=True):
            die("archive owner alias legacy Git common directory changed")
        if exact_local_origin(canonical_legacy) != legacy_origin:
            die("archive owner alias local-origin mapping changed")
    elif method != "authorized-single-relocation-v1":
        die("archive owner alias cannot infer an absent direct owner")
    if method == "direct-local-origin-v1":
        if legacy_origin != owner:
            die("archive owner alias direct owner changed")
    else:
        if legacy_origin == owner or legacy_origin.exists() or legacy_origin.is_symlink():
            die("archive owner alias relocation predecessor is not retired")
    owner_remote = terminal_remote_identity(owner)
    protected_main = origin_main(owner)
    if protected_main is None:
        die("archive owner alias protected main is unknown")
    bundle = Path(values["bundle"])
    tips = sorted(
        ({"archive": row["archive"], "tip": row["tip"]} for row in parsed["items"]),
        key=lambda row: (row["archive"], row["tip"]),
    )
    created_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    restored_digest = alias_tip_digest(tips)
    value: Dict[str, Any] = {
        "schema": OWNER_ALIAS_SCHEMA,
        "created_utc": created_utc,
        "source_receipt": str(source),
        "source_sha256": source_sha256,
        "legacy_repository": legacy_value,
        "legacy_repository_id": legacy_identity,
        "legacy_git_common_dir": values["git_common_dir"],
        "bundle": str(bundle),
        "bundle_sha256": values["bundle_sha256"],
        "tips": tips,
        "owner_repository": str(owner),
        "owner_id": list(path_id(owner)),
        "owner_remote": owner_remote,
        "protected_main": {
            "ref": "refs/remotes/origin/main",
            "tip": protected_main,
        },
        "mapping": {
            "method": method,
            "legacy_origin": str(legacy_origin),
            "evidence_repository": str(coordinator_repo),
            "evidence_repository_id": list(path_id(coordinator_repo)),
            "evidence_repository_remote": evidence_remote,
            "evidence_commit": evidence_commit,
            "evidence_path": evidence_path,
            "evidence_sha256": evidence_sha256,
        },
        "restore_drill": {
            "method": "independent-bare-fetch-exact-heads-v1",
            "verified_utc": created_utc,
            "headset_sha256": restored_digest,
        },
        "recovery": {
            "method": "source-bundle-v1",
            "generations": [],
        },
    }
    directory = owner_alias_directory(create=True)
    destination = directory / owner_alias_name(source)
    if destination.exists() or destination.is_symlink():
        die("archive source already has an owner alias")

    bundle_present = bundle.exists() or bundle.is_symlink()
    candidate_aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None
    candidate_cache: Dict[str, Tuple[Path, str, str]] = {}
    if bundle_present:
        validate_private_file(bundle)
        if digest(bundle) != values["bundle_sha256"]:
            die("archive owner alias source bundle changed")
        git(owner, "bundle", "verify", str(bundle))
        independent_alias_restore(coordinator_repo, bundle, tips)
    else:
        candidate_aliases = load_owner_aliases()
        candidate_aliases[owner_alias_source_key(source)] = (destination, value)
        generation_directory = state / "generations"
        generations = []
        recovery_sources: Dict[str, Tuple[Path, str]] = {}
        generation_cache: Dict[Path, Dict[str, Any]] = {}
        for path in sorted(generation_directory.glob("*.json")):
            generation_value = parse_generation_receipt(
                path, state, candidate_aliases, candidate_cache
            )
            if not generation_covers_source(
                state,
                path,
                source.name,
                source_sha256,
                str(owner),
                [row["tip"] for row in tips],
                generation_value,
                candidate_aliases,
                candidate_cache,
            ):
                continue
            rows = [
                row
                for row in generation_value["repositories"]
                if generation_repository_matches(
                    state,
                    generation_value,
                    row,
                    source,
                    owner,
                    candidate_aliases,
                    candidate_cache,
                )
            ]
            if len(rows) != 1:
                die("archive owner alias generation repository changed")
            for head in rows[0]["heads"]:
                if head["tip"] in {item["tip"] for item in tips}:
                    recovery_sources.setdefault(
                        head["tip"], (Path(rows[0]["bundle"]), head["ref"])
                    )
            generations.append({"receipt": str(path), "sha256": digest(path)})
            generation_cache[path] = generation_value
        if len(generations) < 2 or set(recovery_sources) != {
            row["tip"] for row in tips
        }:
            die("archive owner alias lacks verified compacted recovery")
        value["recovery"] = {
            "method": "generation-recovery-v1",
            "generations": generations,
        }
        independent_alias_restore_sources(
            coordinator_repo, tips, recovery_sources
        )

    # Re-read every mutable identity immediately before immutable publication.
    validate_private_file(source)
    if digest(source) != source_sha256:
        die("archive owner alias source receipt changed")
    if bundle_present:
        if not bundle.exists() or digest(bundle) != values["bundle_sha256"]:
            die("archive owner alias source bundle changed")
    else:
        if bundle.exists() or bundle.is_symlink():
            die("archive owner alias compacted bundle identity changed")
        compacted = archive_audit(
            owner,
            source,
            aliases=candidate_aliases,
            owner_cache=candidate_cache,
        )
        if not compacted["retired"] or compacted["generations"] < 2:
            die("archive owner alias compacted recovery changed")
    if terminal_remote_identity(owner) != owner_remote:
        die("archive owner alias terminal remote changed before publication")
    if testing_override("HARNESS_TEST_OWNER_ALIAS_MAIN_DRIFT") == "1":
        die("archive owner alias protected main changed before publication")
    if origin_main(owner) != protected_main:
        die("archive owner alias protected main changed before publication")
    if method == "direct-local-origin-v1" and legacy.exists():
        if exact_local_origin(canonical_repo(legacy)) != owner:
            die("archive owner alias local origin changed before publication")

    payload = json_bytes(value)
    published: Optional[Path] = None
    try:
        if testing_override("HARNESS_TEST_OWNER_ALIAS_INTERRUPT") == "before":
            die("archive owner alias publication interrupted before publication")
        published = publish_bytes(directory, destination.name, payload)
        if testing_override("HARNESS_TEST_OWNER_ALIAS_INTERRUPT") == "after":
            die("archive owner alias publication interrupted after publication")
        parsed_alias = parse_owner_alias(published)
        validate_owner_alias(source, parsed, parsed_alias)
    except BaseException:
        if (
            published is not None
            and published.exists()
            and digest(published) == hashlib.sha256(payload).hexdigest()
        ):
            validate_private_file(published)
            published.unlink()
            fsync_directory(directory)
        raise
    return {
        "alias": str(published),
        "source": source.name,
        "owner": owner.name,
        "method": method,
        "tips": len(tips),
    }


def alias_generation_recovery(
    repo: Path,
    receipt_path: Path,
    parsed: Dict[str, Any],
    alias: Dict[str, Any],
    generation_cache: Dict[Path, Dict[str, Any]],
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]],
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]],
) -> Optional[Dict[str, Any]]:
    recovery = alias.get("recovery")
    if not isinstance(recovery, dict) or recovery.get("method") != "generation-recovery-v1":
        return None
    state = state_directory()[1]
    generation_directory = state / "generations"
    tips = [row["tip"] for row in parsed["items"]]
    recovery_sources: Dict[str, Tuple[Path, str]] = {}
    verified_generations = []
    for generation in recovery["generations"]:
        path = Path(generation["receipt"])
        if path.resolve(strict=True).parent != generation_directory.resolve(strict=True):
            die("archive owner alias generation is outside durable state")
        validate_private_file(path)
        if digest(path) != generation["sha256"]:
            die("archive owner alias generation receipt changed")
        value = generation_cache.get(path)
        if value is None:
            value = parse_generation_receipt(path, state, aliases, owner_cache)
            generation_cache[path] = value
        if not generation_covers_source(
            state,
            path,
            receipt_path.name,
            digest(receipt_path),
            str(repo),
            tips,
            value,
            aliases,
            owner_cache,
        ):
            die("archive owner alias generation coverage changed")
        rows = [
            row
            for row in value["repositories"]
            if generation_repository_matches(
                state, value, row, receipt_path, repo, aliases, owner_cache
            )
        ]
        if len(rows) != 1:
            die("archive owner alias generation repository changed")
        for head in rows[0]["heads"]:
            if head["tip"] in tips:
                recovery_sources.setdefault(
                    head["tip"], (Path(rows[0]["bundle"]), head["ref"])
                )
        verified_generations.append(generation)
    if set(recovery_sources) != set(tips):
        die("archive owner alias generation recovery is incomplete")
    return {
        "value": {
            "generations": verified_generations,
            "tips": tips,
            "bundle_bytes": 0,
        },
        "recovery_sources": recovery_sources,
    }


def archive_audit(
    repo: Path,
    receipt_path: Path,
    generation_cache: Optional[Dict[Path, Dict[str, Any]]] = None,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
    bundle_cache: Optional[
        Dict[
            Tuple[str, Tuple[int, int], Path],
            Tuple[Tuple[int, int, int, int, int], str, Dict[str, str]],
        ]
    ] = None,
) -> Dict[str, Any]:
    parsed = parse_archive_receipt(receipt_path)
    values = parsed["values"]
    resolved_owner = resolve_archive_owner(
        receipt_path, parsed, aliases=aliases, owner_cache=owner_cache
    )
    if str(repo) != str(resolved_owner) or path_id(repo) != path_id(resolved_owner):
        die("archive receipt belongs to a different Git repository")
    legacy = Path(values.get("repository_canonical", ""))
    if legacy.exists() or legacy.is_symlink():
        common = Path(text(git(repo, "rev-parse", "--git-common-dir")).strip())
        if not common.is_absolute():
            common = repo / common
        if common.resolve(strict=True) != Path(values["git_common_dir"]).resolve(strict=True):
            die("archive receipt belongs to a different Git repository")
    bundle = Path(values["bundle"])
    heads: Dict[str, str] = {}
    recovery_sources: Dict[str, Tuple[Path, str]] = {}
    compaction = None
    if bundle.exists() or bundle.is_symlink():
        bundle_info = validate_private_file(bundle)
        bundle_identity = (
            bundle_info.st_dev,
            bundle_info.st_ino,
            bundle_info.st_size,
            bundle_info.st_mtime_ns,
            bundle_info.st_ctime_ns,
        )
        bundle_key = (str(repo), path_id(repo), bundle.resolve(strict=True))
        cached_bundle = bundle_cache.get(bundle_key) if bundle_cache is not None else None
        # Reuse verification only inside this inventory process and only while
        # the private file's kernel identity and recorded digest are unchanged.
        # A replaced or modified bundle is hashed and verified again.
        if (
            cached_bundle is not None
            and cached_bundle[0] == bundle_identity
            and cached_bundle[1] == values["bundle_sha256"]
        ):
            heads = dict(cached_bundle[2])
        else:
            if digest(bundle) != values["bundle_sha256"]:
                die("archive bundle digest changed")
            git(repo, "bundle", "verify", str(bundle))
            for line in text(
                git(repo, "bundle", "list-heads", str(bundle))
            ).splitlines():
                fields = line.split(" ", 1)
                if len(fields) == 2:
                    heads[fields[1]] = fields[0]
            if bundle_cache is not None:
                bundle_cache[bundle_key] = (
                    bundle_identity,
                    values["bundle_sha256"],
                    dict(heads),
                )
        if len(heads) != len(parsed["items"]):
            die("archive bundle head set changed")
        recovery_sources = {
            row["tip"]: (bundle, row["archive"]) for row in parsed["items"]
        }
    else:
        cache = generation_cache if generation_cache is not None else {}
        compaction = applied_compaction(
            repo,
            receipt_path,
            cache,
            aliases=aliases,
            owner_cache=owner_cache,
        )
        if compaction is None:
            alias_rows = aliases if aliases is not None else load_owner_aliases()
            alias_row = alias_rows.get(owner_alias_source_key(receipt_path))
            if alias_row is not None:
                compaction = alias_generation_recovery(
                    repo,
                    receipt_path,
                    parsed,
                    alias_row[1],
                    cache,
                    alias_rows,
                    owner_cache,
                )
        if compaction is None:
            die("archive bundle is absent without verified recovery")
        state = state_directory()[1]
        recovery_sources.update(compaction.get("recovery_sources", {}))
        for generation in compaction["value"]["generations"]:
            generation_path = Path(generation["receipt"])
            generation_value = cache.get(generation_path)
            if generation_value is None:
                generation_value = parse_generation_receipt(
                    generation_path, state, aliases, owner_cache
                )
                cache[generation_path] = generation_value
            rows = [
                row
                for row in generation_value["repositories"]
                if generation_repository_matches(
                    state, generation_value, row, receipt_path, repo, aliases, owner_cache
                )
            ]
            if len(rows) != 1:
                die("archive compaction recovery repository changed")
            for head in rows[0]["heads"]:
                if head["tip"] in compaction["value"]["tips"]:
                    recovery_sources.setdefault(
                        head["tip"], (Path(rows[0]["bundle"]), head["ref"])
                    )
        if set(recovery_sources) != set(compaction["value"]["tips"]):
            die("archive compaction recovery coverage changed")
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
        elif compaction is not None and row["tip"] in recovery_sources:
            continue
        else:
            die("archive tip is unavailable from both ref and bundle")
    return {
        "items": len(parsed["items"]),
        "live": live,
        "bundled": bundled,
        "retired": compaction is not None,
        "bundle_bytes": (
            compaction["value"]["bundle_bytes"]
            if compaction is not None
            else validate_private_file(bundle).st_size
        ),
        "recovery_sources": recovery_sources,
        "generations": (
            len(compaction["value"]["generations"])
            if compaction is not None
            else 0
        ),
    }


def generation_headset_digest(heads: Sequence[Dict[str, str]]) -> str:
    rows = sorted((row["ref"], row["tip"]) for row in heads)
    payload = json.dumps(rows, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def parse_generation_receipt(
    path: Path,
    state: Path,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> Dict[str, Any]:
    validate_private_file(path)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("archive generation receipt is malformed") from exc
    if not isinstance(value, dict) or value.get("schema") != GENERATION_SCHEMA:
        die("archive generation receipt schema is unsupported")
    if not isinstance(value.get("generation"), str) or not TXN_RE.fullmatch(
        value["generation"]
    ):
        die("archive generation identity is malformed")
    try:
        datetime.strptime(value["created_utc"], "%Y-%m-%dT%H:%M:%SZ")
    except (KeyError, TypeError, ValueError) as exc:
        raise HousekeepingError("archive generation creation time is malformed") from exc
    sources = value.get("source_receipts")
    repositories = value.get("repositories")
    if (
        not isinstance(sources, list)
        or not sources
        or not isinstance(repositories, list)
        or not repositories
    ):
        die("archive generation receipt is incomplete")
    source_names: set[str] = set()
    for source in sources:
        if (
            not isinstance(source, dict)
            or set(source) != {"name", "sha256"}
            or not isinstance(source["name"], str)
            or Path(source["name"]).name != source["name"]
            or not re.fullmatch(r"[0-9a-f]{64}", str(source["sha256"]))
            or source["name"] in source_names
        ):
            die("archive generation source receipt is malformed")
        source_names.add(source["name"])
        existing = state / source["name"]
        if existing.exists() or existing.is_symlink():
            validate_private_file(existing)
            if digest(existing) != source["sha256"]:
                die("archive generation source receipt changed")
    repository_paths: set[str] = set()
    for repository in repositories:
        if not isinstance(repository, dict) or set(repository) != {
            "repository_canonical",
            "repository_id",
            "protected_main",
            "bundle",
            "bundle_sha256",
            "heads",
            "restore_drill",
        }:
            die("archive generation repository row is malformed")
        canonical = repository["repository_canonical"]
        identity = repository["repository_id"]
        protected = repository["protected_main"]
        bundle_value = repository["bundle"]
        heads = repository["heads"]
        drill = repository["restore_drill"]
        if (
            not isinstance(canonical, str)
            or not Path(canonical).is_absolute()
            or canonical in repository_paths
            or not isinstance(identity, list)
            or len(identity) != 2
            or any(not isinstance(item, int) or item < 0 for item in identity)
            or not isinstance(protected, dict)
            or set(protected) != {"ref", "tip"}
            or protected["ref"] != "refs/remotes/origin/main"
            or not OID_RE.fullmatch(str(protected["tip"]))
            or not isinstance(bundle_value, str)
            or not Path(bundle_value).is_absolute()
            or not re.fullmatch(r"[0-9a-f]{64}", str(repository["bundle_sha256"]))
            or not isinstance(heads, list)
            or not heads
            or not isinstance(drill, dict)
            or set(drill) != {"method", "verified_utc", "headset_sha256"}
            or drill["method"] != "independent-bare-fetch-exact-heads-v1"
            or not re.fullmatch(r"[0-9a-f]{64}", str(drill["headset_sha256"]))
        ):
            die("archive generation repository identity is malformed")
        repository_paths.add(canonical)
        try:
            datetime.strptime(drill["verified_utc"], "%Y-%m-%dT%H:%M:%SZ")
        except (TypeError, ValueError) as exc:
            raise HousekeepingError("archive generation restore time is malformed") from exc
        refs: set[str] = set()
        tips: set[str] = set()
        for head in heads:
            if (
                not isinstance(head, dict)
                or set(head) != {"ref", "tip"}
                or not isinstance(head["ref"], str)
                or not head["ref"].startswith("refs/harness-housekeeping/generation/")
                or run(
                    ["git", "check-ref-format", head["ref"]], check=False
                ).returncode
                != 0
                or not OID_RE.fullmatch(str(head["tip"]))
                or head["ref"] in refs
                or head["tip"] in tips
            ):
                die("archive generation head row is malformed")
            refs.add(head["ref"])
            tips.add(head["tip"])
        if protected["tip"] not in tips:
            die("archive generation omitted protected main")
        if generation_headset_digest(heads) != drill["headset_sha256"]:
            die("archive generation restore proof changed")
        bundle = Path(bundle_value)
        validate_private_file(bundle)
        if bundle.resolve(strict=True).parent != path.parent.resolve(strict=True):
            die("archive generation bundle is outside its generation directory")
        if digest(bundle) != repository["bundle_sha256"]:
            die("archive generation bundle digest changed")
        owner = resolve_recorded_repository(
            state,
            canonical,
            identity,
            aliases=aliases,
            owner_cache=owner_cache,
            generation_source_names=source_names,
        )
        git(owner, "bundle", "verify", str(bundle))
        bundled_heads: Dict[str, str] = {}
        for line in text(git(owner, "bundle", "list-heads", str(bundle))).splitlines():
            fields = line.split(" ", 1)
            if len(fields) == 2:
                bundled_heads[fields[1]] = fields[0]
        if bundled_heads != {head["ref"]: head["tip"] for head in heads}:
            die("archive generation bundle head set changed")
    return value


def resolve_recorded_repository(
    state: Path,
    canonical: str,
    identity: Sequence[int],
    *,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
    generation_source_names: Optional[set[str]] = None,
) -> Path:
    repository = Path(canonical)
    if repository.exists() or repository.is_symlink():
        owner = canonical_repo(repository)
        if list(path_id(owner)) != list(identity):
            die("archive recorded repository identity changed")
        return owner
    alias_rows = aliases if aliases is not None else load_owner_aliases()
    candidates = [
        (Path(source_value), row[1])
        for source_value, row in alias_rows.items()
        if row[1]["legacy_repository"] == canonical
        and row[1]["legacy_repository_id"] == list(identity)
    ]
    if not candidates and generation_source_names is not None:
        candidates = [
            (Path(source_value), row[1])
            for source_value, row in alias_rows.items()
            if row[1]["legacy_repository"] == canonical
            and Path(row[1]["source_receipt"]).name in generation_source_names
        ]
    if not candidates:
        die("archive recorded repository is absent without an owner alias")
    owners: Dict[Tuple[str, Tuple[int, int]], Path] = {}
    for source, alias in candidates:
        if not source.exists() or source.is_symlink():
            die("archive recorded repository alias source is unavailable")
        parsed = parse_archive_receipt(source)
        owner = validate_owner_alias(source, parsed, alias, owner_cache)
        owners[(str(owner), path_id(owner))] = owner
    if len(owners) != 1:
        die("archive recorded repository has mixed owner aliases")
    return next(iter(owners.values()))


def generation_repository_matches(
    state: Path,
    generation: Dict[str, Any],
    row: Dict[str, Any],
    source: Path,
    owner: Path,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> bool:
    parsed = parse_archive_receipt(source)
    source_owner = resolve_archive_owner(
        source, parsed, aliases=aliases, owner_cache=owner_cache
    )
    if str(source_owner) != str(owner) or path_id(source_owner) != path_id(owner):
        return False
    row_owner = resolve_recorded_repository(
        state,
        row["repository_canonical"],
        row["repository_id"],
        aliases=aliases,
        owner_cache=owner_cache,
        generation_source_names={
            source["name"] for source in generation["source_receipts"]
        },
    )
    return str(row_owner) == str(owner) and path_id(row_owner) == path_id(owner)


def parse_compaction_receipt(path: Path) -> Dict[str, Any]:
    validate_private_file(path)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HousekeepingError("archive compaction receipt is malformed") from exc
    required = {
        "schema",
        "transaction",
        "created_epoch",
        "source_receipt",
        "source_sha256",
        "repository_canonical",
        "repository_id",
        "bundle",
        "bundle_sha256",
        "bundle_bytes",
        "bundle_id",
        "tips",
        "generations",
    }
    if not isinstance(value, dict) or set(value) != required:
        die("archive compaction receipt fields are malformed")
    if (
        value["schema"] != COMPACTION_SCHEMA
        or not isinstance(value["transaction"], str)
        or not TXN_RE.fullmatch(value["transaction"])
        or not isinstance(value["created_epoch"], int)
        or value["created_epoch"] < 0
        or not isinstance(value["repository_canonical"], str)
        or not Path(value["repository_canonical"]).is_absolute()
        or not isinstance(value["repository_id"], list)
        or len(value["repository_id"]) != 2
        or any(not isinstance(item, int) or item < 0 for item in value["repository_id"])
        or not isinstance(value["bundle_bytes"], int)
        or value["bundle_bytes"] < 0
        or not isinstance(value["bundle_id"], list)
        or len(value["bundle_id"]) != 2
        or any(not isinstance(item, int) or item < 0 for item in value["bundle_id"])
    ):
        die("archive compaction receipt identity is malformed")
    for field in ("source_receipt", "bundle"):
        if not isinstance(value[field], str) or not Path(value[field]).is_absolute():
            die("archive compaction path is malformed")
    for field in ("source_sha256", "bundle_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", str(value[field])):
            die("archive compaction digest is malformed")
    tips = value["tips"]
    if (
        not isinstance(tips, list)
        or not tips
        or len(set(tips)) != len(tips)
        or any(not isinstance(tip, str) or not OID_RE.fullmatch(tip) for tip in tips)
    ):
        die("archive compaction tips are malformed")
    generations = value["generations"]
    if not isinstance(generations, list) or len(generations) < 2:
        die("archive compaction has insufficient generations")
    generation_paths: set[str] = set()
    for generation in generations:
        if (
            not isinstance(generation, dict)
            or set(generation) != {"receipt", "sha256"}
            or not isinstance(generation["receipt"], str)
            or not Path(generation["receipt"]).is_absolute()
            or not re.fullmatch(r"[0-9a-f]{64}", str(generation["sha256"]))
            or generation["receipt"] in generation_paths
        ):
            die("archive compaction generation row is malformed")
        generation_paths.add(generation["receipt"])
    return value


def generation_covers_source(
    state: Path,
    generation_path: Path,
    source_name: str,
    source_sha256: str,
    repository: str,
    tips: Sequence[str],
    generation_value: Optional[Dict[str, Any]] = None,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> bool:
    generation = (
        generation_value
        if generation_value is not None
        else parse_generation_receipt(generation_path, state, aliases, owner_cache)
    )
    if {"name": source_name, "sha256": source_sha256} not in generation[
        "source_receipts"
    ]:
        return False
    owner = canonical_repo(Path(repository))
    source = state / source_name
    rows = [
        row
        for row in generation["repositories"]
        if generation_repository_matches(
            state, generation, row, source, owner, aliases, owner_cache
        )
    ]
    if len(rows) != 1:
        return False
    covered = {head["tip"] for head in rows[0]["heads"]}
    return set(tips).issubset(covered)


def generation_covers_declared_sources(
    state: Path,
    generation: Dict[str, Any],
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> bool:
    for source in generation["source_receipts"]:
        receipt = state / source["name"]
        if not receipt.exists() or receipt.is_symlink():
            return False
        parsed = parse_archive_receipt(receipt)
        repository = parsed["values"].get("repository_canonical")
        owner = resolve_archive_owner(
            receipt, parsed, aliases=aliases, owner_cache=owner_cache
        )
        rows = [
            row
            for row in generation["repositories"]
            if generation_repository_matches(
                state, generation, row, receipt, owner, aliases, owner_cache
            )
        ]
        covered = {head["tip"] for row in rows for head in row["heads"]}
        if (
            not repository
            or {"name": receipt.name, "sha256": source["sha256"]}
            not in generation["source_receipts"]
            or len(rows) != 1
            or not {item["tip"] for item in parsed["items"]}.issubset(covered)
        ):
            return False
    return True


def audit_compaction(
    repo: Path,
    compaction_path: Path,
    expected_source: Optional[Path] = None,
    generation_cache: Optional[Dict[Path, Dict[str, Any]]] = None,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> Dict[str, Any]:
    alias_rows = aliases if aliases is not None else load_owner_aliases()
    owner_rows = owner_cache if owner_cache is not None else {}
    value = parse_compaction_receipt(compaction_path)
    source = Path(value["source_receipt"])
    if expected_source is not None and source.resolve(strict=True) != expected_source.resolve(
        strict=True
    ):
        die("archive compaction source receipt changed")
    validate_private_file(source)
    if digest(source) != value["source_sha256"]:
        die("archive compaction source receipt digest changed")
    recorded_owner = resolve_recorded_repository(
        state_directory()[1],
        value["repository_canonical"],
        value["repository_id"],
        aliases=alias_rows,
        owner_cache=owner_rows,
    )
    if str(repo) != str(recorded_owner) or path_id(repo) != path_id(recorded_owner):
        die("archive compaction repository identity changed")
    parsed_source = parse_archive_receipt(source)
    source_values = parsed_source["values"]
    _lexical, state = state_directory()
    if source.resolve(strict=True).parent != state or Path(value["bundle"]).parent != state:
        die("archive compaction source is outside durable state")
    if (
        source_values["bundle"] != value["bundle"]
        or source_values["bundle_sha256"] != value["bundle_sha256"]
        or sorted(item["tip"] for item in parsed_source["items"])
        != sorted(value["tips"])
    ):
        die("archive compaction source metadata changed")
    generation_directory = state / "generations"
    for generation in value["generations"]:
        path = Path(generation["receipt"])
        if path.resolve(strict=True).parent != generation_directory.resolve(strict=True):
            die("archive compaction generation is outside durable state")
        validate_private_file(path)
        if digest(path) != generation["sha256"]:
            die("archive compaction generation receipt changed")
        generation_value = (
            generation_cache.get(path) if generation_cache is not None else None
        )
        if generation_value is None:
            generation_value = parse_generation_receipt(
                path, state, alias_rows, owner_rows
            )
            if generation_cache is not None:
                generation_cache[path] = generation_value
        if not generation_covers_source(
            state,
            path,
            source.name,
            value["source_sha256"],
            str(repo),
            value["tips"],
            generation_value,
            alias_rows,
            owner_rows,
        ):
            die("archive compaction generation coverage changed")
    bundle = Path(value["bundle"])
    if bundle.exists() or bundle.is_symlink():
        info = validate_private_file(bundle)
        if (
            list(path_id(bundle)) != value["bundle_id"]
            or
            info.st_size != value["bundle_bytes"]
            or digest(bundle) != value["bundle_sha256"]
        ):
            die("archive compaction bundle changed")
        status = "planned"
    else:
        status = "applied"
    return {"status": status, "value": value}


def applied_compaction(
    repo: Path,
    source: Path,
    generation_cache: Optional[Dict[Path, Dict[str, Any]]] = None,
    aliases: Optional[Dict[str, Tuple[Path, Dict[str, Any]]]] = None,
    owner_cache: Optional[Dict[str, Tuple[Path, str, str]]] = None,
) -> Optional[Dict[str, Any]]:
    _lexical, state = state_directory()
    directory = state / "compactions"
    if not directory.exists() and not directory.is_symlink():
        return None
    if directory.is_symlink() or not directory.is_dir():
        die("archive compaction directory identity is unsafe")
    info = directory.lstat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        die("archive compaction directory identity is unsafe")
    matches = []
    for path in sorted(directory.glob("*.json")):
        value = parse_compaction_receipt(path)
        if value["source_receipt"] == str(source):
            result = audit_compaction(
                repo,
                path,
                source,
                generation_cache,
                aliases,
                owner_cache,
            )
            if result["status"] == "applied":
                matches.append(result)
    if len(matches) > 1:
        die("archive source has ambiguous compaction receipts")
    return matches[0] if matches else None


def compaction_directory() -> Path:
    state = state_directory()[1]
    directory = state / "compactions"
    directory.mkdir(mode=0o700, exist_ok=True)
    if directory.is_symlink() or not directory.is_dir():
        die("archive compaction directory identity is unsafe")
    info = directory.lstat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        die("archive compaction directory identity is unsafe")
    return directory


def plan_archive_compaction(repo: Path, source: Path) -> Dict[str, Any]:
    state = state_directory()[1]
    validate_private_file(source)
    if source.resolve(strict=True).parent != state or source.suffix != ".receipt":
        die("archive compaction source receipt is outside durable state")
    parsed = parse_archive_receipt(source)
    values = parsed["values"]
    aliases = load_owner_aliases()
    owner_cache: Dict[str, Tuple[Path, str, str]] = {}
    source_owner = resolve_archive_owner(
        source, parsed, aliases=aliases, owner_cache=owner_cache
    )
    if str(source_owner) != str(repo) or path_id(source_owner) != path_id(repo):
        die("archive compaction source belongs to a different repository")
    audit = archive_audit(repo, source, aliases=aliases, owner_cache=owner_cache)
    if audit["retired"]:
        die("archive source bundle is already compacted")
    bundle = Path(values["bundle"])
    bundle_info = validate_private_file(bundle)
    if bundle.parent != state:
        die("archive compaction bundle is outside durable state")

    directory = compaction_directory()
    for path in sorted(directory.glob("*.json")):
        existing = parse_compaction_receipt(path)
        if existing["source_receipt"] == str(source):
            die("archive compaction plan already exists for source receipt")

    generations = []
    generation_directory = state / "generations"
    if generation_directory.exists() or generation_directory.is_symlink():
        if generation_directory.is_symlink() or not generation_directory.is_dir():
            die("archive generation directory identity is unsafe")
        generation_info = generation_directory.lstat()
        if (
            generation_info.st_uid != os.getuid()
            or stat.S_IMODE(generation_info.st_mode) != 0o700
        ):
            die("archive generation directory identity is unsafe")
        for path in sorted(generation_directory.glob("*.json")):
            if generation_covers_source(
                state,
                path,
                source.name,
                digest(source),
                str(repo),
                [item["tip"] for item in parsed["items"]],
                aliases=aliases,
                owner_cache=owner_cache,
            ):
                generation_digest = digest(path)
                generations.append(
                    {"receipt": str(path), "sha256": generation_digest}
                )
    if len(generations) < 2:
        die("archive compaction requires two verified covering generations")

    transaction = transaction_id("compaction")
    value: Dict[str, Any] = {
        "schema": COMPACTION_SCHEMA,
        "transaction": transaction,
        "created_epoch": int(time.time()),
        "source_receipt": str(source),
        "source_sha256": digest(source),
        "repository_canonical": str(repo),
        "repository_id": list(path_id(repo)),
        "bundle": str(bundle),
        "bundle_sha256": values["bundle_sha256"],
        "bundle_bytes": bundle_info.st_size,
        "bundle_id": list(path_id(bundle)),
        "tips": sorted(item["tip"] for item in parsed["items"]),
        "generations": generations,
    }
    receipt = publish_bytes(directory, transaction + ".json", json_bytes(value))
    result = audit_compaction(repo, receipt, source)
    if result["status"] != "planned":
        die("archive compaction plan changed before publication")
    token = digest(receipt)
    print(
        "HOUSEKEEPING routine=archive-compaction mode=plan "
        f"source={source.name} bytes={bundle_info.st_size} "
        f"generations={len(generations)} candidate=yes"
    )
    print(f"  RECEIPT path={receipt} token={token}")
    return {"receipt": str(receipt), "token": token, "bytes": bundle_info.st_size}


def apply_archive_compaction(repo: Path, receipt: Path, token: str) -> None:
    directory = compaction_directory()
    validate_private_file(receipt)
    if receipt.resolve(strict=True).parent != directory.resolve(strict=True):
        die("archive compaction receipt is outside durable state")
    if not re.fullmatch(r"[0-9a-f]{64}", token) or digest(receipt) != token:
        die("archive compaction token changed")
    result = audit_compaction(repo, receipt)
    value = result["value"]
    if result["status"] == "applied":
        print(
            "HOUSEKEEPING routine=archive-compaction mode=apply "
            f"source={Path(value['source_receipt']).name} removed=0 status=already-applied"
        )
        return
    bundle = Path(value["bundle"])
    state = state_directory()[1]
    if bundle.parent != state:
        die("archive compaction bundle escaped durable state")
    descriptor = os.open(str(state), os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    try:
        info = os.stat(bundle.name, dir_fd=descriptor, follow_symlinks=False)
        if (
            not stat.S_ISREG(info.st_mode)
            or [info.st_dev, info.st_ino] != value["bundle_id"]
            or info.st_uid != os.getuid()
            or stat.S_IMODE(info.st_mode) != 0o600
            or info.st_nlink != 1
            or info.st_size != value["bundle_bytes"]
        ):
            die("archive compaction bundle identity changed before unlink")
        os.unlink(bundle.name, dir_fd=descriptor)
        os.fsync(descriptor)
    finally:
        os.close(descriptor)
    if bundle.exists() or bundle.is_symlink():
        die("archive compaction bundle survived exact unlink")
    final = audit_compaction(repo, receipt)
    if final["status"] != "applied":
        die("archive compaction did not reach applied state")
    print(
        "HOUSEKEEPING routine=archive-compaction mode=apply "
        f"source={Path(value['source_receipt']).name} removed=1 "
        f"bytes={value['bundle_bytes']} generations={len(value['generations'])} "
        "status=verified"
    )


def state_tree_bytes(state: Path) -> int:
    return sum(
        path.lstat().st_size
        for path in state.rglob("*")
        if path.is_file() and not path.is_symlink()
    )


def generation_trigger_facts(
    state: Path,
    receipts: Sequence[Path],
    latest: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    covered = (
        {
            (source["name"], source["sha256"])
            for source in latest["source_receipts"]
        }
        if latest is not None
        else set()
    )
    uncovered = []
    for receipt in receipts:
        validate_private_file(receipt)
        if (receipt.name, digest(receipt)) not in covered:
            uncovered.append(receipt)
    oldest_days = max(
        (artifact_age_days(validate_private_file(receipt)) for receipt in uncovered),
        default=0,
    )
    if not receipts:
        trigger_bytes = 0
        basis = "delta" if latest is not None else "bootstrap"
    elif latest is None:
        trigger_bytes = state_tree_bytes(state)
        basis = "bootstrap"
    else:
        bundles: set[Path] = set()
        for receipt in uncovered:
            bundle = Path(parse_archive_receipt(receipt)["values"]["bundle"])
            if bundle.exists() or bundle.is_symlink():
                validate_private_file(bundle)
                bundles.add(bundle.resolve(strict=True))
        trigger_bytes = sum(validate_private_file(bundle).st_size for bundle in bundles)
        basis = "delta"
    reasons = []
    if trigger_bytes > GENERATION_BYTES_TRIGGER:
        reasons.append("bytes")
    if len(uncovered) > generation_receipts_trigger():
        reasons.append("receipts")
    if oldest_days >= GENERATION_AGE_DAYS_TRIGGER:
        reasons.append("age")
    return {
        "basis": basis,
        "uncovered": len(uncovered),
        "bytes": trigger_bytes,
        "oldest_days": oldest_days,
        "reasons": reasons,
    }


def remove_restore_tree(repo: Path, target: Path) -> None:
    boundaries = scratch_boundaries()
    boundary = next(
        (item for item in boundaries if strict_descendant(target, item)), None
    )
    if boundary is None:
        die("archive generation restore path is outside scratch boundaries")
    manifest = target.parent / f".{target.name}.manifest"
    if manifest.exists() or manifest.is_symlink():
        die("archive generation restore manifest already exists")
    token = guarded_plan(repo, boundary, target, manifest)
    try:
        guarded_apply(repo, str(manifest), token)
    finally:
        if manifest.exists() or manifest.is_symlink():
            validate_private_file(manifest)
            manifest.unlink()
    if target.exists() or target.is_symlink():
        die("archive generation restore tree survived guarded cleanup")


def create_generation(coordinator_repo: Path) -> Dict[str, Any]:
    _lexical, state = state_directory()
    receipts = sorted(state.glob("*.receipt"))
    if not receipts:
        die("archive generation requires source receipts")
    directory = state / "generations"
    aliases = load_owner_aliases()
    owner_cache: Dict[str, Tuple[Path, str, str]] = {}
    existing_generations = []
    if directory.exists() or directory.is_symlink():
        info = directory.lstat()
        if (
            directory.is_symlink()
            or not directory.is_dir()
            or info.st_uid != os.getuid()
            or stat.S_IMODE(info.st_mode) != 0o700
        ):
            die("archive generation directory identity is unsafe")
        for receipt in sorted(directory.glob("*.json")):
            value = parse_generation_receipt(
                receipt, state, aliases, owner_cache
            )
            created = datetime.strptime(
                value["created_utc"], "%Y-%m-%dT%H:%M:%SZ"
            ).replace(tzinfo=timezone.utc)
            existing_generations.append((created, value))
    trigger_generations = [
        row
        for row in existing_generations
        if generation_covers_declared_sources(
            state, row[1], aliases, owner_cache
        )
    ]
    latest = (
        max(trigger_generations, key=lambda row: row[0])[1]
        if trigger_generations
        else None
    )
    trigger = generation_trigger_facts(state, receipts, latest)
    if not trigger["reasons"]:
        die("archive generation trigger is not met")
    generation = transaction_id("generation")
    directory.mkdir(mode=0o700, exist_ok=True)
    info = directory.lstat()
    if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
        die("archive generation directory identity is unsafe")

    sources = []
    grouped: Dict[str, Dict[str, Any]] = {}
    generation_cache: Dict[Path, Dict[str, Any]] = {}
    for receipt in receipts:
        parsed = parse_archive_receipt(receipt)
        values = parsed["values"]
        repository_value = values.get("repository_canonical")
        if not repository_value or not Path(repository_value).is_absolute():
            die("archive generation source repository is missing")
        owner = resolve_archive_owner(
            receipt, parsed, aliases=aliases, owner_cache=owner_cache
        )
        audit = archive_audit(
            owner,
            receipt,
            generation_cache,
            aliases=aliases,
            owner_cache=owner_cache,
        )
        sources.append({"name": receipt.name, "sha256": digest(receipt)})
        row = grouped.setdefault(
            str(owner),
            {"repository": owner, "tips": {}},
        )
        for item in parsed["items"]:
            row["tips"].setdefault(item["tip"], audit["recovery_sources"][item["tip"]])

    if existing_generations:
        created, latest = max(existing_generations, key=lambda row: row[0])
        current_main = {
            repository_value: origin_main(grouped[repository_value]["repository"])
            for repository_value in grouped
        }
        recorded_main_sets: Dict[str, set[str]] = {}
        for repository in latest["repositories"]:
            recorded_owner = resolve_recorded_repository(
                state,
                repository["repository_canonical"],
                repository["repository_id"],
                aliases=aliases,
                owner_cache=owner_cache,
                generation_source_names={
                    source["name"] for source in latest["source_receipts"]
                },
            )
            recorded_main_sets.setdefault(str(recorded_owner), set()).add(
                repository["protected_main"]["tip"]
            )
        recorded_main = {
            owner: next(iter(tips))
            for owner, tips in recorded_main_sets.items()
            if len(tips) == 1
        }
        age_days = max(0, (datetime.now(timezone.utc) - created).days)
        if (
            latest["source_receipts"] == sources
            and len(recorded_main) == len(recorded_main_sets)
            and recorded_main == current_main
            and age_days < GENERATION_AGE_DAYS_TRIGGER
        ):
            die("latest archive generation already covers current sources")

    prepared: List[Dict[str, Any]] = []
    created_refs: List[Tuple[Path, str, str]] = []
    linked_bundles: List[Path] = []
    temporary_bundles: List[Path] = []
    published_receipt: Optional[Path] = None
    try:
        for index, repository_value in enumerate(sorted(grouped)):
            owner = grouped[repository_value]["repository"]
            main_tip = origin_main(owner)
            if main_tip is None:
                die("archive generation protected main is unknown")
            tip_sources = grouped[repository_value]["tips"]
            tips = set(tip_sources)
            tips.add(main_tip)
            prefix = f"refs/harness-housekeeping/generation/{generation}/r{index}"
            if text(
                git(owner, "for-each-ref", "--format=%(refname)", prefix)
            ).strip():
                die("archive generation ref namespace already exists")
            heads = []
            prefetched_refs: set[str] = set()
            for tip in sorted(tips):
                label = "main" if tip == main_tip else f"tip-{tip}"
                ref = f"{prefix}/{label}"
                run(["git", "check-ref-format", ref])
                if (
                    git(
                        owner,
                        "cat-file",
                        "-e",
                        f"{tip}^{{commit}}",
                        check=False,
                    ).returncode
                    != 0
                ):
                    source = tip_sources.get(tip)
                    if source is None:
                        die("archive generation protected main object is unavailable")
                    source_bundle, source_ref = source
                    git(
                        owner,
                        "fetch",
                        "--quiet",
                        str(source_bundle),
                        f"{source_ref}:{ref}",
                    )
                    restored = text(git(owner, "rev-parse", "--verify", ref)).strip()
                    if restored != tip:
                        die("archive generation source bundle changed a tip")
                    prefetched_refs.add(ref)
                    created_refs.append((owner, ref, tip))
                heads.append({"ref": ref, "tip": tip})
            commands = ["start"]
            commands.extend(
                f"create {head['ref']} {head['tip']}"
                for head in heads
                if head["ref"] not in prefetched_refs
            )
            commands.extend(("prepare", "commit"))
            run(
                ["git", "-C", str(owner), "update-ref", "--stdin"],
                input_bytes=("\n".join(commands) + "\n").encode(),
            )
            created_refs.extend(
                (owner, head["ref"], head["tip"])
                for head in heads
                if head["ref"] not in prefetched_refs
            )

            descriptor, temporary_name = tempfile.mkstemp(
                prefix=f".{generation}-r{index}-", dir=str(directory)
            )
            os.close(descriptor)
            temporary = Path(temporary_name)
            temporary.unlink()
            temporary_bundles.append(temporary)
            final_bundle = directory / f"{generation}-r{index}.bundle"
            if final_bundle.exists() or final_bundle.is_symlink():
                die("archive generation bundle already exists")
            git(
                owner,
                "bundle",
                "create",
                str(temporary),
                *[head["ref"] for head in heads],
            )
            os.chmod(temporary, 0o600)
            with temporary.open("rb") as handle:
                os.fsync(handle.fileno())
            git(owner, "bundle", "verify", str(temporary))

            restore = Path(
                tempfile.mkdtemp(
                    prefix=f"harness-{generation}-r{index}-",
                    dir=str(scratch_boundaries()[0]),
                )
            )
            try:
                git(restore, "init", "--bare")
                git(
                    restore,
                    "fetch",
                    "--quiet",
                    str(temporary),
                    *[f"{head['ref']}:{head['ref']}" for head in heads],
                )
                for head in heads:
                    restored = text(
                        git(restore, "rev-parse", "--verify", head["ref"])
                    ).strip()
                    if restored != head["tip"]:
                        die("archive generation independent restore changed a head")
                git(restore, "fsck", "--full", "--no-dangling")
            finally:
                remove_restore_tree(coordinator_repo, restore)

            prepared.append(
                {
                    "repository_canonical": repository_value,
                    "repository_id": list(path_id(owner)),
                    "protected_main": {
                        "ref": "refs/remotes/origin/main",
                        "tip": main_tip,
                    },
                    "bundle": str(final_bundle),
                    "bundle_sha256": digest(temporary),
                    "heads": heads,
                    "restore_drill": {
                        "method": "independent-bare-fetch-exact-heads-v1",
                        "verified_utc": datetime.now(timezone.utc).strftime(
                            "%Y-%m-%dT%H:%M:%SZ"
                        ),
                        "headset_sha256": generation_headset_digest(heads),
                    },
                    "temporary": temporary,
                }
            )

        current_receipts = sorted(state.glob("*.receipt"))
        current_sources = []
        for receipt in current_receipts:
            validate_private_file(receipt)
            current_sources.append(
                {"name": receipt.name, "sha256": digest(receipt)}
            )
        if current_sources != sources:
            die("archive generation source receipt set changed")
        for repository in prepared:
            owner = canonical_repo(Path(repository["repository_canonical"]))
            if origin_main(owner) != repository["protected_main"]["tip"]:
                die("archive generation protected main changed")

        for repository in prepared:
            temporary = repository.pop("temporary")
            final_bundle = Path(repository["bundle"])
            os.link(temporary, final_bundle)
            temporary.unlink()
            temporary_bundles.remove(temporary)
            fsync_directory(directory)
            validate_private_file(final_bundle)
            linked_bundles.append(final_bundle)
        receipt_path = directory / f"{generation}.json"
        payload = {
            "schema": GENERATION_SCHEMA,
            "generation": generation,
            "created_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "source_receipts": sources,
            "repositories": prepared,
        }
        published_receipt = publish_bytes(
            directory, receipt_path.name, json_bytes(payload)
        )
        parse_generation_receipt(
            published_receipt, state, aliases, owner_cache
        )
        return {
            "generation": generation,
            "receipt": str(published_receipt),
            "repositories": len(prepared),
            "heads": sum(len(repository["heads"]) for repository in prepared),
            "bytes": sum(path.lstat().st_size for path in linked_bundles),
            "trigger": ",".join(trigger["reasons"]),
            "trigger_basis": trigger["basis"],
            "uncovered": trigger["uncovered"],
        }
    except BaseException:
        if published_receipt is not None and published_receipt.exists():
            published_receipt.unlink()
        for path in linked_bundles:
            if path.exists() and not path.is_symlink():
                validate_private_file(path)
                path.unlink()
        for path in temporary_bundles:
            if path.exists() and not path.is_symlink():
                path.unlink()
        for repository in prepared:
            temporary = repository.get("temporary")
            if isinstance(temporary, Path) and temporary.exists():
                temporary.unlink()
        for owner, ref, tip in reversed(created_refs):
            git(owner, "update-ref", "-d", ref, tip, check=False)
        raise


def pr_tree_status(
    repo: Path,
    row: Dict[str, str],
    pull_rows: Optional[List[Dict[str, Any]]],
) -> str:
    number = row.get("pr", "none")
    if number == "none":
        return "none"
    if not number.isdigit() or pull_rows is None:
        return "unknown"
    matches = [item for item in pull_rows if item["number"] == int(number)]
    if len(matches) != 1:
        return "unknown"
    pull = matches[0]
    merge = pull.get("mergeCommit")
    if (
        pull["state"].upper() != "MERGED"
        or pull["headRefOid"] != row["tip"]
        or not isinstance(merge, dict)
        or not OID_RE.fullmatch(str(merge.get("oid", "")))
    ):
        return "unknown"
    head_tree = git(repo, "rev-parse", "--verify", f"{row['tip']}^{{tree}}", check=False)
    merge_tree = git(
        repo,
        "rev-parse",
        "--verify",
        f"{merge['oid']}^{{tree}}",
        check=False,
    )
    if head_tree.returncode != 0 or merge_tree.returncode != 0:
        return "unknown"
    return "equal" if text(head_tree).strip() == text(merge_tree).strip() else "different"


def ledger_reference_map(
    repositories: Sequence[Path], needles: Sequence[str]
) -> Dict[str, str]:
    unique = sorted(set(needles))
    if not unique or any(not needle or CONTROL_RE.search(needle) for needle in unique):
        die("archive ledger lookup is malformed")
    statuses = {needle: "no" for needle in unique}
    pattern_arguments = [argument for needle in unique for argument in ("-e", needle)]
    unknown = False
    for repository in repositories:
        result = git(
            repository,
            "grep",
            "--no-color",
            "-h",
            "-o",
            "-F",
            *pattern_arguments,
            "refs/remotes/origin/main",
            "--",
            "TODO.md",
            "docs/tasks",
            "docs/audits",
            check=False,
        )
        if result.returncode == 0:
            for match in text(result).splitlines():
                if match in statuses:
                    statuses[match] = "yes"
        elif result.returncode != 1:
            unknown = True
    if unknown:
        for needle, status in statuses.items():
            if status == "no":
                statuses[needle] = "unknown"
    return statuses


def combined_ledger_status(statuses: Dict[str, str], needles: Sequence[str]) -> str:
    values = [statuses[needle] for needle in needles]
    if "yes" in values:
        return "yes"
    return "unknown" if "unknown" in values else "no"


def artifact_age_days(info: os.stat_result) -> int:
    return max(0, int((time.time() - info.st_mtime) // 86400))


def plan_archives(coordinator_repo: Path) -> None:
    _lexical, state = state_directory()
    receipts = sorted(state.glob("*.receipt"))
    aliases = load_owner_aliases()
    owner_cache: Dict[str, Tuple[Path, str, str]] = {}
    generation_directory = state / "generations"
    if generation_directory.exists() or generation_directory.is_symlink():
        generation_info = generation_directory.lstat()
        if (
            generation_directory.is_symlink()
            or not generation_directory.is_dir()
            or generation_info.st_uid != os.getuid()
            or stat.S_IMODE(generation_info.st_mode) != 0o700
        ):
            die("archive generation directory identity is unsafe")
    generation_receipts = (
        sorted(generation_directory.glob("*.json"))
        if generation_directory.is_dir()
        else []
    )
    generation_values = [
        (path, parse_generation_receipt(path, state, aliases, owner_cache))
        for path in generation_receipts
    ]
    generation_cache = {path: value for path, value in generation_values}
    trigger_generations = [
        row
        for row in generation_values
        if generation_covers_declared_sources(
            state, row[1], aliases, owner_cache
        )
    ]
    latest_generation = (
        max(
            trigger_generations,
            key=lambda row: datetime.strptime(
                row[1]["created_utc"], "%Y-%m-%dT%H:%M:%SZ"
            ),
        )[1]
        if trigger_generations
        else None
    )
    trigger_facts = generation_trigger_facts(state, receipts, latest_generation)
    state_bytes = state_tree_bytes(state)
    if not receipts:
        print(
            "HOUSEKEEPING routine=archives mode=report receipts=0 items=0 "
            "unique_tips=0 bytes=0 archive_only=0 pr_equal=0 "
            "pr_unknown=0 ledger_yes=0 ledger_unknown=0 "
            f"state_bytes={state_bytes} generations={len(generation_receipts)} "
            f"generation_trigger={','.join(trigger_facts['reasons']) or 'no'} "
            f"generation_trigger_basis={trigger_facts['basis']} "
            f"generation_uncovered={trigger_facts['uncovered']} "
            f"generation_trigger_bytes={trigger_facts['bytes']} "
            f"aliases={len(aliases)} unbound_aliases={len(aliases)} "
            "candidates=0 apply=unavailable"
        )
        for path, value in generation_values:
            print(
                "  AUX "
                f"type=generation name={path.name} bytes={path.lstat().st_size} "
                f"age_days={artifact_age_days(path.lstat())} "
                f"repositories={len(value['repositories'])} "
                f"sources={len(value['source_receipts'])} "
                "restore_drill=pass status=valid candidate=no"
            )
        return
    total_items = 0
    total_bytes = 0
    retired_bundles = 0
    retired_bytes = 0
    archive_only = 0
    pr_equal = 0
    pr_unknown = 0
    ledger_yes = 0
    ledger_unknown = 0
    unique_tips: set[str] = set()
    bound_bundles: set[Path] = set()
    repo_cache: Dict[
        str,
        Tuple[Path, Optional[str], Optional[List[Dict[str, Any]]], Dict[str, str]],
    ] = {}
    bundle_cache: Dict[
        Tuple[str, Tuple[int, int], Path],
        Tuple[Tuple[int, int, int, int, int], str, Dict[str, str]],
    ] = {}
    item_facts_cache: Dict[
        Tuple[str, str, str, str, str],
        Tuple[bool, bool, List[str], Optional[bool], str],
    ] = {}
    output_rows: List[str] = []
    for receipt in receipts:
        parsed = parse_archive_receipt(receipt)
        values = parsed["values"]
        repository_value = values.get("repository_canonical")
        if not repository_value or not Path(repository_value).is_absolute():
            die("archive receipt repository identity is missing")
        owner_repo = resolve_archive_owner(
            receipt, parsed, aliases=aliases, owner_cache=owner_cache
        )
        owner_value = str(owner_repo)
        if owner_value not in repo_cache:
            refs = {}
            for line in text(
                git(owner_repo, "for-each-ref", "--format=%(refname) %(objectname)")
            ).splitlines():
                fields = line.split(" ", 1)
                if len(fields) != 2 or not OID_RE.fullmatch(fields[1]):
                    die("archive repository ref inventory is malformed")
                refs[fields[0]] = fields[1]
            repo_cache[owner_value] = (
                owner_repo,
                origin_main(owner_repo),
                pull_requests(owner_repo),
                refs,
            )
        owner_repo, main_oid, pull_rows, refs = repo_cache[owner_value]
        audit = archive_audit(
            owner_repo,
            receipt,
            generation_cache,
            aliases=aliases,
            owner_cache=owner_cache,
            bundle_cache=bundle_cache,
        )
        bundle = Path(values["bundle"])
        bundle_bytes = audit["bundle_bytes"]
        if audit["retired"]:
            retired_bundles += 1
            retired_bytes += bundle_bytes
        else:
            bound_bundles.add(bundle.resolve(strict=True))
            total_bytes += bundle_bytes
        transaction = values.get("transaction", receipt.stem)
        try:
            created = datetime.strptime(
                values["created_utc"], "%Y-%m-%dT%H:%M:%SZ"
            ).replace(tzinfo=timezone.utc)
        except (KeyError, ValueError) as exc:
            raise HousekeepingError("archive receipt creation time is malformed") from exc
        age_days = max(0, (datetime.now(timezone.utc) - created).days)
        receipt_archive_only = 0
        receipt_equal = 0
        receipt_unknown = 0
        ledgers = [owner_repo]
        if coordinator_repo != owner_repo:
            ledgers.append(coordinator_repo)
        receipt_needles = [transaction, receipt.name]
        receipt_needles.extend(row["tip"] for row in parsed["items"])
        receipt_ledger = ledger_reference_map(ledgers, receipt_needles)
        for row in parsed["items"]:
            tip = row["tip"]
            unique_tips.add(tip)
            total_items += 1
            item_key = (
                owner_value,
                tip,
                row["archive"],
                row.get("pr", "none"),
                main_oid or "",
            )
            item_facts = item_facts_cache.get(item_key)
            if item_facts is None:
                archive_ref_live = refs.get(row["archive"]) == tip
                object_present = archive_ref_live or (
                    git(
                        owner_repo,
                        "cat-file",
                        "-e",
                        f"{tip}^{{commit}}",
                        check=False,
                    ).returncode
                    == 0
                )
                containing = (
                    text(
                        git(
                            owner_repo,
                            "for-each-ref",
                            "--contains",
                            tip,
                            "--format=%(refname)",
                        )
                    ).splitlines()
                    if object_present
                    else []
                )
                normal_refs = [
                    ref
                    for ref in containing
                    if not ref.startswith("refs/harness-housekeeping/archive/")
                    and not ref.startswith("refs/harness-housekeeping/generation/")
                ]
                ancestry = (
                    None
                    if main_oid is None or not object_present
                    else is_ancestor(owner_repo, tip, main_oid)
                )
                tree_status = pr_tree_status(owner_repo, row, pull_rows)
                item_facts = (
                    archive_ref_live,
                    object_present,
                    normal_refs,
                    ancestry,
                    tree_status,
                )
                item_facts_cache[item_key] = item_facts
            archive_ref_live, object_present, normal_refs, ancestry, tree_status = (
                item_facts
            )
            only = not normal_refs
            archive_only += int(only)
            receipt_archive_only += int(only)
            main_status = (
                "unknown" if ancestry is None else ("yes" if ancestry else "no")
            )
            pr_equal += int(tree_status == "equal")
            pr_unknown += int(tree_status == "unknown")
            receipt_equal += int(tree_status == "equal")
            receipt_unknown += int(tree_status == "unknown")
            ledger_status = combined_ledger_status(
                receipt_ledger, (tip, transaction, receipt.name)
            )
            ledger_yes += int(ledger_status == "yes")
            ledger_unknown += int(ledger_status == "unknown")
            if audit["retired"]:
                copy_status = "ref+generation" if archive_ref_live else "generation"
            else:
                copy_status = "ref+bundle" if archive_ref_live else "bundle"
            output_rows.append(
                "  ITEM "
                f"repository={owner_repo.name} transaction={transaction} "
                f"branch={row['branch']} tip={tip} main={main_status} "
                f"normal_refs={len(normal_refs)} archive={copy_status} "
                f"pr_tree={tree_status} ledger={ledger_status} candidate=no"
            )
        output_rows.insert(
            len(output_rows) - len(parsed["items"]),
            "  REPORT "
            f"repository={owner_repo.name} transaction={transaction} "
            f"items={audit['items']} bytes={bundle_bytes} age_days={age_days} "
            f"retired={int(audit['retired'])} generations={audit['generations']} "
            f"archive_only={receipt_archive_only} pr_equal={receipt_equal} "
            f"pr_unknown={receipt_unknown} audit=pass candidate=no",
        )
    plan_paths = sorted((state / "plans").glob("*.json")) if (state / "plans").is_dir() else []
    manifest_paths = sorted(
        path
        for directory in (state / "plans", state / "worktree-manifests")
        if directory.is_dir()
        for path in directory.glob("*.manifest")
    )
    apply_paths = sorted(state.glob("worktree-apply-*.json"))
    all_bundles = sorted(state.rglob("*.bundle"))
    evidence_payloads = sorted(state.rglob("*.tar.gz"))
    compaction_paths = sorted((state / "compactions").glob("*.json")) if (state / "compactions").is_dir() else []
    auxiliary_names = [
        path.name
        for paths in (plan_paths, manifest_paths, apply_paths, all_bundles, evidence_payloads, compaction_paths)
        for path in paths
    ]
    auxiliary_ledger = ledger_reference_map([coordinator_repo], auxiliary_names)
    for path in plan_paths:
        info = validate_private_file(path)
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise HousekeepingError("archive inventory found a malformed plan") from exc
        if value.get("schema") != PLAN_SCHEMA or not isinstance(value.get("kind"), str):
            die("archive inventory found an unsupported plan")
        output_rows.append(
            "  AUX "
            f"type=plan name={path.name} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} kind={value['kind']} "
            f"ledger={auxiliary_ledger[path.name]} "
            "status=valid candidate=no"
        )
    for path in manifest_paths:
        info = validate_private_file(path)
        output_rows.append(
            "  AUX "
            f"type=manifest name={path.name} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} "
            f"ledger={auxiliary_ledger[path.name]} "
            "status=identity-valid candidate=no"
        )
    incomplete_applies = 0
    for path in apply_paths:
        info = validate_private_file(path)
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise HousekeepingError("archive inventory found malformed apply state") from exc
        if value.get("schema") != "harness-housekeeping-worktree-apply-v1":
            die("archive inventory found unsupported apply state")
        phase = value.get("phase")
        if not isinstance(phase, str):
            die("archive inventory found apply state without a phase")
        incomplete_applies += int(phase != "complete")
        output_rows.append(
            "  AUX "
            f"type=worktree-apply name={path.name} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} phase={phase} "
            f"ledger={auxiliary_ledger[path.name]} "
            "status=valid candidate=no"
        )
    generation_bundles = {
        Path(repository["bundle"]).resolve(strict=True)
        for _path, value in generation_values
        for repository in value["repositories"]
    }
    unbound_bundles = [
        path
        for path in all_bundles
        if path.resolve(strict=True) not in bound_bundles
        and path.resolve(strict=True) not in generation_bundles
    ]
    for path in unbound_bundles:
        info = validate_private_file(path)
        output_rows.append(
            "  AUX "
            f"type=unbound-bundle name={path.relative_to(state)} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} "
            f"ledger={auxiliary_ledger[path.name]} "
            "status=preserved-unknown candidate=no"
        )
    for path in evidence_payloads:
        info = validate_private_file(path)
        output_rows.append(
            "  AUX "
            f"type=evidence-payload name={path.relative_to(state)} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} "
            f"ledger={auxiliary_ledger[path.name]} "
            "status=preserved candidate=no"
        )
    for path, value in generation_values:
        info = validate_private_file(path)
        output_rows.append(
            "  AUX "
            f"type=generation name={path.name} bytes={info.st_size} "
            f"age_days={artifact_age_days(info)} "
            f"repositories={len(value['repositories'])} "
            f"sources={len(value['source_receipts'])} "
            "restore_drill=pass status=valid candidate=no"
        )
    unbound_aliases = 0
    for source_value, (path, alias) in aliases.items():
        source = Path(source_value)
        if not source.exists() or source.is_symlink():
            unbound_aliases += 1
            status = "unbound"
        else:
            validate_owner_alias(
                source,
                parse_archive_receipt(source),
                alias,
                owner_cache,
            )
            status = "valid"
        output_rows.append(
            "  AUX "
            f"type=owner-alias name={path.name} source={source.name} "
            f"owner={Path(alias['owner_repository']).name} status={status} candidate=no"
        )
    for path in compaction_paths:
        value = parse_compaction_receipt(path)
        owner = resolve_recorded_repository(
            state,
            value["repository_canonical"],
            value["repository_id"],
            aliases=aliases,
            owner_cache=owner_cache,
        )
        audited = audit_compaction(owner, path, generation_cache=generation_cache)
        output_rows.append(
            "  AUX "
            f"type=compaction name={path.name} bytes={value['bundle_bytes']} "
            f"source={Path(value['source_receipt']).name} "
            f"generations={len(value['generations'])} status={audited['status']} "
            "candidate=no"
        )
    oldest_days = max(
        artifact_age_days(validate_private_file(receipt)) for receipt in receipts
    )
    trigger = ",".join(trigger_facts["reasons"]) or "no"
    print(
        "HOUSEKEEPING routine=archives mode=report "
        f"receipts={len(receipts)} items={total_items} "
        f"unique_tips={len(unique_tips)} bytes={total_bytes} "
        f"retired_bundles={retired_bundles} retired_bytes={retired_bytes} "
        f"archive_only={archive_only} pr_equal={pr_equal} "
        f"pr_unknown={pr_unknown} ledger_yes={ledger_yes} "
        f"ledger_unknown={ledger_unknown} plans={len(plan_paths)} "
        f"manifests={len(manifest_paths)} applies={len(apply_paths)} "
        f"incomplete_applies={incomplete_applies} "
        f"unbound_bundles={len(unbound_bundles)} "
        f"evidence_payloads={len(evidence_payloads)} "
        f"state_bytes={state_bytes} oldest_days={oldest_days} "
        f"generations={len(generation_receipts)} generation_trigger={trigger} "
        f"generation_trigger_basis={trigger_facts['basis']} "
        f"generation_uncovered={trigger_facts['uncovered']} "
        f"generation_trigger_bytes={trigger_facts['bytes']} "
        f"compactions={len(compaction_paths)} "
        f"aliases={len(aliases)} unbound_aliases={unbound_aliases} "
        "candidates=0 apply=unavailable"
    )
    for row in output_rows:
        print(row)


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
            "number,state,headRefName,headRefOid,baseRefName,mergedAt,mergeCommit",
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
            or (
                "mergeCommit" in row
                and row["mergeCommit"] is not None
                and (
                    not isinstance(row["mergeCommit"], dict)
                    or not isinstance(row["mergeCommit"].get("oid"), str)
                )
            )
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


def local_branch_records(
    repo: Path, retire_all_nonmain: bool = False
) -> Tuple[List[Dict[str, Any]], Optional[str], bool]:
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
            record = classify_tip(repo, name, tip, prs, main_oid)
            if retire_all_nonmain and main_oid is not None and prs is not None:
                record.update(candidate=True, reason="owner-retire-all")
            records.append(record)
    return records, main_oid, prs is not None


def plan_branches(repo: Path, retire_all_nonmain: bool = False) -> Dict[str, Any]:
    records, main_oid, api_ok = local_branch_records(repo, retire_all_nonmain)
    payload = {
        "origin_main": main_oid,
        "api_ok": api_ok,
        "retire_all_nonmain": retire_all_nonmain,
        "records": records,
    }
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


def apply_branches(
    repo: Path,
    receipt_path: Path,
    token: str,
    retire_all_nonmain: bool = False,
) -> None:
    plan = load_plan(receipt_path, token, "branches", repo)
    if plan.get("retire_all_nonmain") is not retire_all_nonmain:
        die("branch retirement authority changed")
    current, main_oid, api_ok = local_branch_records(repo, retire_all_nonmain)
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


def validate_branch_name(repo: Path, name: str) -> None:
    validate_item(name, "0" * 40)
    if name == "main":
        die("protected main cannot be a retirement candidate")
    run(["git", "check-ref-format", f"refs/heads/{name}"])


def remote_tracking_tips(repo: Path) -> Dict[str, str]:
    rows: Dict[str, str] = {}
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
        validate_branch_name(repo, name)
        if not OID_RE.fullmatch(tip) or name in rows:
            die("remote-tracking branch metadata is malformed")
        rows[name] = tip
    return rows


def hosted_head_tips(repo: Path) -> Dict[str, str]:
    if os.environ.get("HARNESS_TESTING") == "1" and not testing_override(
        "HARNESS_TEST_REMOTE_LIVE"
    ):
        rows = remote_tracking_tips(repo)
        main = origin_main(repo)
        if main is None:
            die("hosted main is unknown")
        return {"main": main, **rows}
    result = git(repo, "ls-remote", "--heads", "origin", check=False)
    if result.returncode != 0:
        die("hosted branch inventory is unavailable")
    rows: Dict[str, str] = {}
    for line in text(result).splitlines():
        fields = line.split("\t")
        if len(fields) != 2 or not fields[1].startswith("refs/heads/"):
            die("hosted branch metadata is malformed")
        tip = fields[0]
        name = fields[1][len("refs/heads/") :]
        if not OID_RE.fullmatch(tip) or name in rows:
            die("hosted branch metadata is malformed")
        if name != "main":
            validate_branch_name(repo, name)
        rows[name] = tip
    if "main" not in rows:
        die("hosted main is missing")
    return rows


def remote_records(repo: Path, retire_all_nonmain: bool = False) -> Tuple[List[Dict[str, Any]], str]:
    hosted = hosted_head_tips(repo)
    tracking = remote_tracking_tips(repo)
    records: List[Dict[str, Any]] = []
    for name in sorted(key for key in hosted if key != "main"):
        records.append(
            {
                "name": name,
                "tip": hosted[name],
                "tracking_tip": tracking.get(name),
                "source": "hosted",
                "candidate": retire_all_nonmain,
                "reason": "owner-retire-all" if retire_all_nonmain else "report-only",
            }
        )
    for name in sorted(set(tracking) - set(hosted)):
        records.append(
            {
                "name": name,
                "tip": tracking[name],
                "tracking_tip": tracking[name],
                "source": "tracking-only",
                "candidate": retire_all_nonmain,
                "reason": "owner-retire-all" if retire_all_nonmain else "stale-tracking-ref",
            }
        )
    return records, hosted["main"]


def reconcile_remote_retirement(
    planned: List[Dict[str, Any]], current: List[Dict[str, Any]]
) -> Dict[str, Dict[str, Any]]:
    planned_by_name = {row["name"]: row for row in planned}
    current_by_name = {row["name"]: row for row in current}
    if len(planned_by_name) != len(planned) or len(current_by_name) != len(current):
        die("remote branch metadata is duplicated")
    for name, row in current_by_name.items():
        expected = planned_by_name.get(name)
        if expected is None:
            die("remote branch mutable state changed; re-plan")
        if row["source"] == "hosted":
            if expected["source"] != "hosted" or row["tip"] != expected["tip"]:
                die("remote branch mutable state changed; re-plan")
            tracking_tip = row.get("tracking_tip")
            if tracking_tip is not None and tracking_tip != expected.get("tracking_tip"):
                die("remote branch mutable state changed; re-plan")
        elif expected["source"] == "hosted":
            if (
                expected.get("tracking_tip") is None
                or row["tip"] != expected["tracking_tip"]
            ):
                die("remote branch mutable state changed; re-plan")
        elif row["tip"] != expected["tip"]:
            die("remote branch mutable state changed; re-plan")
    return current_by_name


def plan_remotes(repo: Path, retire_all_nonmain: bool = False) -> None:
    records, main_oid = remote_records(repo, retire_all_nonmain)
    receipt, token = publish_plan(
        "remotes",
        repo,
        {
            "origin": terminal_remote_identity(repo) if retire_all_nonmain else "report-only",
            "origin_main": main_oid,
            "retire_all_nonmain": retire_all_nonmain,
            "records": records,
        },
    )
    candidates = [row for row in records if row["candidate"]]
    print(
        "HOUSEKEEPING routine=remotes "
        f"mode={'plan' if retire_all_nonmain else 'report'} "
        f"branches={len(records)} candidates={len(candidates)} "
        f"apply={'guarded' if retire_all_nonmain else 'unavailable'}"
    )
    for row in records:
        label = "CANDIDATE" if row["candidate"] else "REPORT"
        print(
            f"  {label} remote_branch={row['name']} tip={row['tip']} "
            f"source={row['source']} reason={row['reason']}"
        )
    print(f"  RECEIPT path={receipt} token={token}")


def apply_remotes(
    repo: Path, receipt_path: Path, token: str, retire_all_nonmain: bool
) -> None:
    plan = load_plan(receipt_path, token, "remotes", repo)
    if not retire_all_nonmain or plan.get("retire_all_nonmain") is not True:
        die("remote retirement requires explicit owner-retire-all authority")
    current, main_oid = remote_records(repo, True)
    if (
        plan.get("origin") != terminal_remote_identity(repo)
        or plan.get("origin_main") != main_oid
    ):
        die("remote branch mutable state changed; re-plan")
    planned = plan.get("records")
    if not isinstance(planned, list):
        die("remote retirement plan records are malformed")
    current_by_name = reconcile_remote_retirement(planned, current)
    candidates = [row for row in planned if row["candidate"]]
    if not candidates:
        print("HOUSEKEEPING routine=remotes mode=apply removed=0 reason=no-candidates")
        return

    transaction = transaction_id("remotes")
    hosted = [
        row
        for row in candidates
        if row["source"] == "hosted"
        and row["name"] in current_by_name
        and current_by_name[row["name"]]["source"] == "hosted"
    ]
    staging: List[Tuple[str, str]] = []
    if hosted:
        refspecs = []
        for row in hosted:
            staging_ref = f"refs/harness-housekeeping/staging/{transaction}/{row['name']}"
            run(["git", "check-ref-format", staging_ref])
            refspecs.append(f"+refs/heads/{row['name']}:{staging_ref}")
            staging.append((staging_ref, row["tip"]))
        git(repo, "fetch", "--no-tags", "origin", *refspecs)
        for ref, tip in staging:
            if text(git(repo, "rev-parse", "--verify", ref)).strip() != tip:
                die("hosted branch fetch changed before archive")

    items: List[Tuple[str, str]] = []
    details: Dict[str, Dict[str, str]] = {}
    for row in candidates:
        archive_name = f"{row['source']}/{row['name']}"
        items.append((archive_name, row["tip"]))
        details[archive_name] = {"classification": "owner-retire-all", "pr": "none"}
        tracking_tip = row.get("tracking_tip")
        if row["source"] == "hosted" and tracking_tip and tracking_tip != row["tip"]:
            tracking_name = f"tracking/{row['name']}"
            items.append((tracking_name, tracking_tip))
            details[tracking_name] = {"classification": "tracking-diverged", "pr": "none"}
    archived = archive_create(repo, items, transaction, str(receipt_path), details)
    archive_audit(repo, Path(archived["receipt"]))

    if hosted:
        push = ["git", "-C", str(repo), "push", "--porcelain", "--atomic", "origin"]
        push.extend(
            f"--force-with-lease=refs/heads/{row['name']}:{row['tip']}"
            for row in hosted
        )
        push.extend(f":refs/heads/{row['name']}" for row in hosted)
        run(push, timeout=120)
    remaining = hosted_head_tips(repo)
    if remaining != {"main": main_oid}:
        die("hosted branch retirement did not converge to protected main")

    deletes = ["start"]
    for row in candidates:
        tracking_tip = row.get("tracking_tip")
        if tracking_tip:
            ref = f"refs/remotes/origin/{row['name']}"
            existing = git(repo, "rev-parse", "--verify", ref, check=False)
            if existing.returncode == 0:
                if text(existing).strip() != tracking_tip:
                    die("remote-tracking ref changed after hosted retirement")
                deletes.append(f"delete {ref} {tracking_tip}")
    for ref, tip in staging:
        existing = git(repo, "rev-parse", "--verify", ref, check=False)
        if existing.returncode == 0:
            if text(existing).strip() != tip:
                die("staging ref changed after hosted retirement")
            deletes.append(f"delete {ref} {tip}")
    deletes.extend(("prepare", "commit"))
    run(
        ["git", "-C", str(repo), "update-ref", "--stdin"],
        input_bytes=("\n".join(deletes) + "\n").encode(),
    )
    print(
        "HOUSEKEEPING routine=remotes mode=apply "
        f"removed_hosted={len(hosted)} removed_tracking={sum(bool(row.get('tracking_tip')) for row in candidates)} "
        f"archive_receipt={archived['receipt']} status=verified"
    )


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


def require_durable_worktree_archive_owner(repo: Path) -> None:
    """Keep archive receipts anchored outside disposable scratch roots."""
    enforce_in_test = testing_override(
        "HARNESS_TEST_ENFORCE_DURABLE_ARCHIVE_OWNER"
    )
    if os.environ.get("HARNESS_TESTING") == "1" and enforce_in_test != "1":
        return
    boundaries = set(scratch_boundaries())
    for standard in (Path("/tmp"), Path("/var/tmp")):
        if standard.is_dir() and not standard.is_symlink():
            boundaries.add(standard.resolve(strict=True))
    for boundary in sorted(boundaries):
        if repo == boundary or strict_descendant(repo, boundary):
            die(
                "worktree housekeeping repository is inside a scratch "
                "boundary; use the durable canonical repository so archive "
                "receipts remain auditable"
            )


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
    if not isinstance(selected_path, str):
        die("selected worktree path is malformed")
    requested = Path(selected_path)
    if (
        not requested.is_absolute()
        or not requested.exists()
        or requested.is_symlink()
    ):
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
    require_durable_worktree_archive_owner(repo)
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
    print(
        "HOUSEKEEPING routine=worktrees mode=plan "
        f"candidates={len(candidates)} reports={len(records)-len(candidates)} "
        f"api={'ok' if prs is not None else 'unknown'} selected={selected or 'all'}"
    )
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
    require_durable_worktree_archive_owner(repo)
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
        worktree_path = Path(record["path"])
        if worktree_path.exists() or worktree_path.is_symlink():
            die("worktree directory survived guarded deletion")
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
        admin_path = Path(record["admin"])
        if admin_path.exists() or admin_path.is_symlink():
            die("worktree administration survived guarded deletion")
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
    action.add_argument("--create-owner-alias", action="store_true")
    action.add_argument("--create-generation", action="store_true")
    action.add_argument("--plan-archive-compaction", action="store_true")
    action.add_argument("--apply-archive-compaction", action="store_true")
    action.add_argument("--audit", action="store_true")
    action.add_argument("--open-worktree", action="store_true")
    action.add_argument("--recover-worktree", action="store_true")
    value.add_argument(
        "--routine",
        choices=("all", "scratch", "branches", "remotes", "worktrees", "archives", "launchers", "board", "evidence"),
        default="all",
    )
    value.add_argument("--receipt")
    value.add_argument("--token")
    value.add_argument("--items")
    value.add_argument("--transaction")
    value.add_argument("--source", default="manual")
    value.add_argument("--source-receipt")
    value.add_argument("--owner-repo")
    value.add_argument("--legacy-origin")
    value.add_argument("--mapping-evidence-commit")
    value.add_argument("--mapping-evidence-path")
    value.add_argument("--launcher")
    value.add_argument("--repo")
    value.add_argument("--branch")
    value.add_argument("--path", dest="worktree_path")
    value.add_argument("--expected-main")
    value.add_argument("--retire-all-nonmain", action="store_true")
    return value


def require_receipt(arguments: argparse.Namespace) -> Tuple[Path, str]:
    if not arguments.receipt or not arguments.token:
        die("apply requires --receipt and --token")
    return Path(arguments.receipt).absolute(), arguments.token


def main(argv: Optional[Sequence[str]] = None) -> int:
    arguments = parser().parse_args(argv)
    repo = repository_from_environment(arguments.repo)
    if arguments.retire_all_nonmain and (
        arguments.routine not in {"branches", "remotes"}
        or not (arguments.plan or arguments.apply)
    ):
        die("--retire-all-nonmain requires a branches or remotes plan/apply")
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
    if arguments.create_owner_alias:
        required = (
            arguments.source_receipt,
            arguments.owner_repo,
            arguments.legacy_origin,
            arguments.mapping_evidence_commit,
            arguments.mapping_evidence_path,
        )
        if any(value is None for value in required):
            die(
                "owner alias creation requires --source-receipt, --owner-repo, "
                "--legacy-origin, --mapping-evidence-commit, and --mapping-evidence-path"
            )
        result = create_owner_alias(
            repo,
            Path(arguments.source_receipt).absolute(),
            arguments.owner_repo,
            arguments.legacy_origin,
            arguments.mapping_evidence_commit,
            arguments.mapping_evidence_path,
        )
        print(
            "HOUSEKEEPING routine=owner-alias mode=create "
            f"source={result['source']} owner={result['owner']} "
            f"method={result['method']} tips={result['tips']} "
            f"alias={result['alias']} restore=pass status=verified"
        )
        return 0
    if arguments.create_generation:
        result = create_generation(repo)
        print(
            "HOUSEKEEPING routine=archives mode=create-generation "
            f"generation={result['generation']} "
            f"repositories={result['repositories']} heads={result['heads']} "
            f"bytes={result['bytes']} trigger={result['trigger']} "
            f"trigger_basis={result['trigger_basis']} "
            f"uncovered={result['uncovered']} "
            f"receipt={result['receipt']} restore=pass status=verified"
        )
        return 0
    if arguments.plan_archive_compaction:
        if not arguments.source_receipt:
            die("archive compaction plan requires --source-receipt")
        plan_archive_compaction(repo, Path(arguments.source_receipt).absolute())
        return 0
    if arguments.apply_archive_compaction:
        if not arguments.receipt or not arguments.token:
            die("archive compaction apply requires --receipt and --token")
        apply_archive_compaction(
            repo, Path(arguments.receipt).absolute(), arguments.token
        )
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
        print(
            "HOUSEKEEPING routine=archive mode=audit "
            f"items={result['items']} live={result['live']} "
            f"bundled={result['bundled']} status=pass "
            f"retired={int(result['retired'])} generations={result['generations']}"
        )
        return 0
    if arguments.plan:
        selected = (
            ("scratch", plan_scratch),
            (
                "branches",
                lambda selected_repo: plan_branches(
                    selected_repo, arguments.retire_all_nonmain
                ),
            ),
            (
                "remotes",
                lambda selected_repo: plan_remotes(
                    selected_repo, arguments.retire_all_nonmain
                ),
            ),
            (
                "worktrees",
                lambda selected_repo: plan_worktrees(
                    selected_repo, arguments.worktree_path
                ),
            ),
            ("archives", plan_archives),
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
        apply_branches(
            repo, receipt, token, arguments.retire_all_nonmain
        )
        return 0
    if arguments.routine == "remotes":
        receipt, token = require_receipt(arguments)
        apply_remotes(
            repo, receipt, token, arguments.retire_all_nonmain
        )
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
