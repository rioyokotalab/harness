#!/usr/bin/env python3
"""Root-only Personal Slack encrypted-credential and service installer."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import socket
import stat
import struct
import subprocess
import sys
from typing import Callable


SOURCE_ROOT = Path(__file__).resolve().parents[1]
RELEASE_ROOT = Path("/opt/harness-slack-broker/releases")
PROFILE_SOURCE = Path("/etc/harness-slack-broker/profiles/personal.json")
CREDENTIAL_ROOT = Path("/etc/harness-slack-broker/credentials/personal")
CREDENTIAL_STORE = CREDENTIAL_ROOT / "current"
UNIT_ROOT = Path("/etc/systemd/system")
EXPECTED_FIELDS = {
    "slack-access-read",
    "slack-access-write",
    "slack-client-id",
    "slack-client-secret",
    "slack-refresh-read",
    "slack-refresh-write",
}
RELEASE_FILES = (
    "harness-slack-mcp-service",
    "harness-slack-rotate",
    "harness_slack_broker.py",
    "harness_slack_audit.py",
    "harness_slack_mcp.py",
    "harness_slack_mcp_remote.py",
    "harness_slack_rotate.py",
)
MAX_INPUT_BYTES = 64 * 1024
ENROLLMENT_SOCKET = Path("/run/harness-slack-personal-enroll.sock")
SOCKET_TIMEOUT_SECONDS = 900


class InstallError(ValueError):
    """Stable value-free installation failure."""


def fail(reason: str) -> None:
    raise InstallError(reason)


def validate_bundle(value: object) -> dict[str, str]:
    if not isinstance(value, dict) or set(value) != EXPECTED_FIELDS:
        fail("credential-bundle-invalid")
    result: dict[str, str] = {}
    for name in sorted(EXPECTED_FIELDS):
        secret = value[name]
        if (
            not isinstance(secret, str)
            or not 1 <= len(secret.encode("utf-8")) <= 8192
            or any(character.isspace() for character in secret)
        ):
            fail("credential-bundle-invalid")
        result[name] = secret
    return result


def _receive_exact(connection: socket.socket, size: int) -> bytes:
    value = bytearray()
    while len(value) < size:
        chunk = connection.recv(size - len(value))
        if not chunk:
            fail("credential-bundle-invalid")
        value.extend(chunk)
    return bytes(value)


def receive_once(
    path: Path,
    client_uid: int,
    client_gid: int,
    install: Callable[[dict[str, str]], None],
    *,
    socket_uid: int = 0,
) -> None:
    if (
        not path.is_absolute()
        or client_uid < 1
        or client_gid < 1
        or os.path.lexists(path)
    ):
        fail("credential-sink-invalid")
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        listener.bind(str(path))
        listener.listen(1)
        os.chown(path, socket_uid, client_gid)
        os.chmod(path, 0o660)
        listener.settimeout(SOCKET_TIMEOUT_SECONDS)
        connection, _address = listener.accept()
        # Remove the rendezvous immediately after the sole connection so no
        # second client can race the consumed one-shot sink.
        path.unlink()
        with connection:
            connection.settimeout(900)
            credentials = connection.getsockopt(
                socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i")
            )
            _pid, peer_uid, peer_gid = struct.unpack("3i", credentials)
            if peer_uid != client_uid or peer_gid != client_gid:
                fail("credential-client-invalid")
            size = int.from_bytes(_receive_exact(connection, 4), "big")
            if not 1 <= size <= MAX_INPUT_BYTES:
                fail("credential-bundle-invalid")
            payload = _receive_exact(connection, size)
            if connection.recv(1):
                fail("credential-bundle-invalid")
            try:
                bundle = validate_bundle(json.loads(payload))
            except (UnicodeError, json.JSONDecodeError):
                fail("credential-bundle-invalid")
            finally:
                payload = b""
            install(bundle)
            connection.sendall(b"SLACK_CREDENTIAL_SINK status=complete\n")
    except socket.timeout:
        fail("credential-sink-timeout")
    finally:
        listener.close()
        if os.path.lexists(path):
            path.unlink()


def _git(*arguments: str) -> str:
    try:
        result = subprocess.run(
            [
                "git",
                "-c",
                f"safe.directory={SOURCE_ROOT}",
                "-C",
                str(SOURCE_ROOT),
                *arguments,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=30,
            check=False,
            text=True,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("source-repository-invalid")
    if result.returncode != 0:
        fail("source-repository-invalid")
    return result.stdout.strip()


def protected_revision() -> str:
    if _git("status", "--porcelain"):
        fail("source-repository-dirty")
    revision = _git("rev-parse", "HEAD")
    if revision != _git("rev-parse", "origin/main") or len(revision) != 40:
        fail("source-revision-unprotected")
    return revision


def preflight(expected_revision: str | None = None) -> str:
    revision = protected_revision()
    if expected_revision is not None and revision != expected_revision:
        fail("source-revision-changed")
    if os.path.lexists(CREDENTIAL_STORE):
        fail("credential-store-not-empty")
    try:
        profile = PROFILE_SOURCE.lstat()
        service = (UNIT_ROOT / "harness-slack-personal.service").lstat()
    except OSError:
        fail("fail-closed-service-missing")
    if (
        not stat.S_ISREG(profile.st_mode)
        or stat.S_ISLNK(profile.st_mode)
        or profile.st_uid != 0
        or profile.st_mode & (stat.S_IWGRP | stat.S_IWOTH)
        or not stat.S_ISREG(service.st_mode)
        or stat.S_ISLNK(service.st_mode)
        or service.st_uid != 0
    ):
        fail("fail-closed-service-invalid")
    for name in RELEASE_FILES:
        info = (SOURCE_ROOT / "libexec" / name).lstat()
        if not stat.S_ISREG(info.st_mode) or stat.S_ISLNK(info.st_mode):
            fail("release-source-invalid")
    probe = Path(f"/run/harness-slack-credential-preflight-{os.getpid()}")
    try:
        _encrypt("harness-slack-preflight", "synthetic-preflight-value", probe)
    finally:
        if probe.exists():
            probe.unlink()
    return revision


def install_release(revision: str) -> Path:
    RELEASE_ROOT.mkdir(mode=0o755, parents=True, exist_ok=True)
    release = RELEASE_ROOT / revision
    stage = RELEASE_ROOT / f".{revision}.{os.getpid()}.tmp"
    if os.path.lexists(release):
        info = release.lstat()
        if (
            not stat.S_ISDIR(info.st_mode)
            or stat.S_ISLNK(info.st_mode)
            or info.st_uid != 0
        ):
            fail("release-readback-mismatch")
        for name in RELEASE_FILES:
            if (release / "libexec" / name).read_bytes() != (
                SOURCE_ROOT / "libexec" / name
            ).read_bytes():
                fail("release-readback-mismatch")
        return release
    (stage / "libexec").mkdir(mode=0o755, parents=True)
    try:
        for name in RELEASE_FILES:
            source = SOURCE_ROOT / "libexec" / name
            source_info = source.lstat()
            if (
                not stat.S_ISREG(source_info.st_mode)
                or stat.S_ISLNK(source_info.st_mode)
                or source_info.st_nlink != 1
            ):
                fail("release-source-invalid")
            target = stage / "libexec" / name
            shutil.copyfile(source, target, follow_symlinks=False)
            os.chmod(target, 0o755 if "_" not in name else 0o644)
        os.rename(stage, release)
    except Exception:
        if stage.exists():
            for child in (stage / "libexec").iterdir():
                child.unlink()
            (stage / "libexec").rmdir()
            stage.rmdir()
        raise
    return release


def _encrypt(name: str, value: str, output: Path) -> None:
    try:
        result = subprocess.run(
            ["systemd-creds", "encrypt", "--name", name, "-", str(output)],
            input=value.encode("utf-8"),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("credential-encryption-failed")
    if result.returncode != 0:
        fail("credential-encryption-failed")
    os.chmod(output, 0o600)


def install_credentials(
    bundle: dict[str, str],
    encrypt: Callable[[str, str, Path], None] = _encrypt,
) -> None:
    CREDENTIAL_ROOT.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = CREDENTIAL_ROOT.lstat()
    if info.st_uid != 0 or stat.S_IMODE(info.st_mode) != 0o700:
        fail("credential-store-invalid")
    if os.path.lexists(CREDENTIAL_STORE):
        fail("credential-store-not-empty")
    stage = CREDENTIAL_ROOT / f".enroll-{os.getpid()}"
    stage.mkdir(mode=0o700)
    try:
        for name in sorted(EXPECTED_FIELDS):
            encrypt(name, bundle[name], stage / name)
        for name in sorted(EXPECTED_FIELDS):
            info = (stage / name).lstat()
            if (
                not stat.S_ISREG(info.st_mode)
                or info.st_uid != 0
                or stat.S_IMODE(info.st_mode) != 0o600
                or info.st_nlink != 1
                or info.st_size == 0
            ):
                fail("credential-encryption-failed")
        os.rename(stage, CREDENTIAL_STORE)
    finally:
        if stage.exists():
            for child in tuple(stage.iterdir()):
                child.unlink()
            stage.rmdir()


def render(template: Path, replacements: dict[str, str]) -> bytes:
    text = template.read_text(encoding="utf-8")
    for marker, value in replacements.items():
        text = text.replace(f"@@{marker}@@", value)
    if "@@" in text or "\x00" in text:
        fail("unit-render-invalid")
    return text.encode("utf-8")


def _atomic_unit(name: str, content: bytes) -> None:
    path = UNIT_ROOT / name
    temporary = UNIT_ROOT / f".{name}.{os.getpid()}.tmp"
    with temporary.open("xb") as stream:
        os.fchmod(stream.fileno(), 0o644)
        stream.write(content)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def install_units(release: Path) -> bytes:
    service_path = UNIT_ROOT / "harness-slack-personal.service"
    try:
        prior_service = service_path.read_bytes()
    except OSError:
        fail("fail-closed-service-missing")
    common = {
        "CLIENT_USER": "rioyokota",
        "CREDENTIAL_STORE": str(CREDENTIAL_STORE),
        "PROFILE": "personal",
        "PROFILE_SOURCE": str(PROFILE_SOURCE),
        "READ_CREDENTIAL_SOURCE": str(CREDENTIAL_STORE / "slack-access-read"),
        "RELEASE": str(release),
        "SERVICE_IDENTITY": "harness_slack_personal",
    }
    templates = SOURCE_ROOT / "config" / "slack" / "systemd"
    _atomic_unit(
        "harness-slack-personal.service",
        render(templates / "harness-slack-personal-read.service.in", common),
    )
    for role in ("read", "write"):
        for kind in ("service", "timer"):
            name = f"harness-slack-personal-rotate-{role}.{kind}"
            _atomic_unit(name, render(templates / f"{name}.in", common))
    return prior_service


def _systemctl(*arguments: str) -> None:
    try:
        result = subprocess.run(
            ["systemctl", *arguments],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("service-manager-failed")
    if result.returncode != 0:
        fail("service-manager-failed")


def activate(prior_service: bytes) -> None:
    try:
        _systemctl("daemon-reload")
        for role in ("read", "write"):
            _systemctl("enable", "--now", f"harness-slack-personal-rotate-{role}.timer")
        _systemctl("restart", "harness-slack-personal.service")
        _systemctl("is-active", "--quiet", "harness-slack-personal.service")
        for role in ("read", "write"):
            _systemctl("is-active", "--quiet", f"harness-slack-personal-rotate-{role}.timer")
    except InstallError:
        _atomic_unit("harness-slack-personal.service", prior_service)
        for role in ("read", "write"):
            subprocess.run(
                ["systemctl", "disable", "--now", f"harness-slack-personal-rotate-{role}.timer"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=60,
                check=False,
            )
        subprocess.run(
            ["systemctl", "daemon-reload"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
            check=False,
        )
        subprocess.run(
            ["systemctl", "restart", "harness-slack-personal.service"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
            check=False,
        )
        raise


def install_personal(bundle: dict[str, str], expected_revision: str | None = None) -> None:
    revision = protected_revision()
    if expected_revision is not None and revision != expected_revision:
        fail("source-revision-changed")
    release = install_release(revision)
    install_credentials(bundle)
    prior = install_units(release)
    activate(prior)


def main() -> int:
    arguments = sys.argv[1:]
    if (
        arguments not in (["preflight"], ["install-personal"])
        and not (
            len(arguments) == 4
            and arguments[0] == "serve-personal"
            and arguments[1].isdigit()
            and arguments[2].isdigit()
            and len(arguments[3]) == 40
            and all(character in "0123456789abcdef" for character in arguments[3])
        )
    ):
        print("SLACK_LIVE_INSTALL status=failed reason=argument-invalid", file=sys.stderr)
        return 2
    try:
        if os.geteuid() != 0:
            fail("root-required")
        if arguments == ["preflight"]:
            preflight()
            print("SLACK_LIVE_INSTALL status=pass action=preflight profile=personal")
            return 0
        if arguments[0] == "serve-personal":
            client_uid = int(arguments[1])
            client_gid = int(arguments[2])
            revision = arguments[3]
            preflight(revision)
            receive_once(
                ENROLLMENT_SOCKET,
                client_uid,
                client_gid,
                lambda bundle: install_personal(bundle, revision),
            )
            print("SLACK_LIVE_INSTALL status=complete profile=personal credentials=6")
            return 0
        payload = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
        if len(payload) > MAX_INPUT_BYTES:
            fail("credential-bundle-invalid")
        try:
            bundle = validate_bundle(json.loads(payload))
        except (UnicodeError, json.JSONDecodeError):
            fail("credential-bundle-invalid")
        install_personal(bundle)
    except InstallError as exc:
        print(f"SLACK_LIVE_INSTALL status=failed reason={exc}", file=sys.stderr)
        return 2
    except Exception:
        print("SLACK_LIVE_INSTALL status=failed reason=internal-error", file=sys.stderr)
        return 2
    print("SLACK_LIVE_INSTALL status=complete profile=personal credentials=6")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
