#!/usr/bin/env python3
"""Root-only Swallow Slack encrypted-credential and service installer."""

from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import sys
from typing import Callable

import harness_slack_install as common


SOURCE_ROOT = Path(__file__).resolve().parents[1]
PROFILE_SOURCE = Path("/etc/harness-slack-broker/profiles/swallow.json")
CREDENTIAL_ROOT = Path("/etc/harness-slack-broker/credentials/swallow")
CREDENTIAL_STORE = CREDENTIAL_ROOT / "current"
QUARANTINE_STORES = tuple(
    CREDENTIAL_ROOT
    / (
        "quarantine-before-reenroll"
        if index == 1
        else f"quarantine-before-reenroll-{index}"
    )
    for index in range(1, 5)
)
EXPECTED_FIELDS = {
    "slack-access-read",
    "slack-client-id",
    "slack-client-secret",
    "slack-refresh-read",
}
UNIT_ROOT = Path("/etc/systemd/system")
ENROLLMENT_SOCKET = Path("/run/harness-slack-swallow-enroll.sock")
MAX_INPUT_BYTES = 64 * 1024


class SwallowInstallError(ValueError):
    """Stable value-free Swallow installation failure."""


def fail(reason: str) -> None:
    raise SwallowInstallError(reason)


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


def preflight(expected_revision: str | None = None) -> str:
    revision = common.protected_revision()
    if expected_revision is not None and revision != expected_revision:
        fail("source-revision-changed")
    if os.path.lexists(CREDENTIAL_STORE):
        fail("credential-store-not-empty")
    try:
        profile = PROFILE_SOURCE.lstat()
        service = (UNIT_ROOT / "harness-slack-swallow.service").lstat()
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
    probe = Path(f"/run/harness-slack-swallow-preflight-{os.getpid()}")
    try:
        common._encrypt("harness-slack-swallow-preflight", "synthetic-preflight-value", probe)
    finally:
        if probe.is_file() and not probe.is_symlink():
            probe.unlink()
    return revision


def install_credentials(
    bundle: dict[str, str],
    encrypt: Callable[[str, str, Path], None] = common._encrypt,
) -> None:
    CREDENTIAL_ROOT.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = CREDENTIAL_ROOT.lstat()
    if info.st_uid != 0 or stat.S_IMODE(info.st_mode) != 0o700:
        fail("credential-store-invalid")
    if os.path.lexists(CREDENTIAL_STORE):
        fail("credential-store-not-empty")
    stage = CREDENTIAL_ROOT / f".enroll-{os.getpid()}"
    stage.mkdir(mode=0o700)
    paths = {name: stage / name for name in EXPECTED_FIELDS}
    try:
        for name in sorted(EXPECTED_FIELDS):
            encrypt(name, bundle[name], paths[name])
        for path in paths.values():
            info = path.lstat()
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
            access = paths["slack-access-read"]
            client_id = paths["slack-client-id"]
            client_secret = paths["slack-client-secret"]
            refresh = paths["slack-refresh-read"]
            if access.is_file() and not access.is_symlink():
                access.unlink()
            if client_id.is_file() and not client_id.is_symlink():
                client_id.unlink()
            if client_secret.is_file() and not client_secret.is_symlink():
                client_secret.unlink()
            if refresh.is_file() and not refresh.is_symlink():
                refresh.unlink()
            stage.rmdir()


def replacements(release: Path) -> dict[str, str]:
    return {
        "CLIENT_USER": "rioyokota",
        "CREDENTIAL_STORE": str(CREDENTIAL_STORE),
        "PROFILE": "swallow",
        "PROFILE_SOURCE": str(PROFILE_SOURCE),
        "READ_CREDENTIAL_SOURCE": str(CREDENTIAL_STORE / "slack-access-read"),
        "RELEASE": str(release),
        "SERVICE_IDENTITY": "harness_slack_swallow",
    }


def install_units(release: Path) -> bytes:
    service_path = UNIT_ROOT / "harness-slack-swallow.service"
    try:
        prior_service = service_path.read_bytes()
    except OSError:
        fail("fail-closed-service-missing")
    templates = SOURCE_ROOT / "config/slack/systemd"
    values = replacements(release)
    common._atomic_unit(
        service_path.name,
        common.render(templates / "harness-slack-swallow-read.service.in", values),
    )
    for kind in ("service", "timer"):
        name = f"harness-slack-swallow-rotate-read.{kind}"
        common._atomic_unit(name, common.render(templates / f"{name}.in", values))
    return prior_service


def activate(prior_service: bytes) -> None:
    service = "harness-slack-swallow.service"
    timer = "harness-slack-swallow-rotate-read.timer"
    try:
        common._systemctl("daemon-reload")
        common._systemctl("enable", "--now", timer)
        common._systemctl("restart", service)
        common._systemctl("is-active", "--quiet", service)
        common._systemctl("is-active", "--quiet", timer)
    except common.InstallError as error:
        common._atomic_unit(service, prior_service)
        subprocess.run(
            ["systemctl", "disable", "--now", timer],
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
            ["systemctl", "restart", service],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
            check=False,
        )
        raise SwallowInstallError(str(error)) from None


def install(bundle: dict[str, str], expected_revision: str | None = None) -> None:
    revision = common.protected_revision()
    if expected_revision is not None and revision != expected_revision:
        fail("source-revision-changed")
    release = common.install_release(revision)
    install_credentials(bundle)
    activate(install_units(release))


def refresh_read_service() -> None:
    revision = common.protected_revision()
    release = common.install_release(revision)
    service_path = UNIT_ROOT / "harness-slack-swallow.service"
    try:
        info = service_path.lstat()
        prior = service_path.read_bytes()
    except OSError:
        fail("fail-closed-service-missing")
    if (
        not stat.S_ISREG(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != 0
        or info.st_mode & (stat.S_IWGRP | stat.S_IWOTH)
    ):
        fail("fail-closed-service-invalid")
    replacement = common.render(
        SOURCE_ROOT / "config/slack/systemd/harness-slack-swallow-read.service.in",
        replacements(release),
    )
    common._atomic_unit(service_path.name, replacement)
    try:
        common._systemctl("daemon-reload")
        common._systemctl("restart", service_path.name)
        common._systemctl("is-active", "--quiet", service_path.name)
    except common.InstallError as error:
        common._atomic_unit(service_path.name, prior)
        try:
            common._systemctl("daemon-reload")
            common._systemctl("restart", service_path.name)
        except common.InstallError:
            pass
        raise SwallowInstallError(str(error)) from None


def diagnose_read_scopes(
    run: Callable[..., subprocess.CompletedProcess[bytes]] = subprocess.run,
) -> None:
    revision = common.protected_revision()
    release = common.install_release(revision)
    unit = "harness-slack-swallow-scope-doctor"
    credential_directory = Path("/run/credentials") / f"{unit}.service"
    try:
        result = run(
            [
                "systemd-run",
                "--wait",
                "--pipe",
                "--collect",
                "--quiet",
                f"--unit={unit}",
                "--property=User=root",
                "--property=Group=root",
                "--property=PrivateTmp=yes",
                "--property=NoNewPrivileges=yes",
                "--property=ProtectSystem=strict",
                "--property=RestrictAddressFamilies=AF_INET AF_INET6",
                "--property=LoadCredentialEncrypted=slack-access-read:"
                f"{CREDENTIAL_STORE / 'slack-access-read'}",
                str(release / "libexec/harness-slack-rotate"),
                "--credentials",
                str(credential_directory),
                "--profile",
                "swallow",
                "--role",
                "read",
                "--diagnose-scopes",
            ],
            stdout=sys.stdout,
            stderr=sys.stderr,
            timeout=60,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("scope-doctor-failed")
    if result.returncode != 0:
        fail("scope-doctor-failed")


def quarantine(
    *,
    owner_uid: int = 0,
    systemctl_action: Callable[..., None] = common._systemctl,
) -> None:
    common.protected_revision()
    try:
        info = CREDENTIAL_STORE.lstat()
    except OSError:
        fail("credential-store-invalid")
    if (
        not stat.S_ISDIR(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != owner_uid
        or stat.S_IMODE(info.st_mode) != 0o700
    ):
        fail("credential-store-invalid")
    entries = {path.name for path in CREDENTIAL_STORE.iterdir()}
    allowed = EXPECTED_FIELDS | {".previous-read"}
    if not EXPECTED_FIELDS <= entries or not entries <= allowed:
        fail("credential-store-entries-invalid")
    for name in EXPECTED_FIELDS:
        credential = CREDENTIAL_STORE / name
        credential_info = credential.lstat()
        if (
            not stat.S_ISREG(credential_info.st_mode)
            or stat.S_ISLNK(credential_info.st_mode)
            or credential_info.st_uid != owner_uid
            or stat.S_IMODE(credential_info.st_mode) != 0o600
            or credential_info.st_nlink != 1
            or credential_info.st_size == 0
        ):
            fail("credential-store-entries-invalid")
    previous = CREDENTIAL_STORE / ".previous-read"
    if os.path.lexists(previous):
        previous_info = previous.lstat()
        prior_access = previous / "slack-access-read"
        if (
            not stat.S_ISDIR(previous_info.st_mode)
            or stat.S_ISLNK(previous_info.st_mode)
            or previous_info.st_uid != owner_uid
            or stat.S_IMODE(previous_info.st_mode) != 0o700
            or {path.name for path in previous.iterdir()} != {"slack-access-read"}
            or not prior_access.is_file()
            or prior_access.is_symlink()
            or prior_access.stat().st_uid != owner_uid
            or stat.S_IMODE(prior_access.stat().st_mode) != 0o600
            or prior_access.stat().st_nlink != 1
            or prior_access.stat().st_size == 0
        ):
            fail("credential-store-previous-invalid")
    target = next((path for path in QUARANTINE_STORES if not os.path.lexists(path)), None)
    if target is None:
        fail("credential-quarantine-full")
    systemctl_action("disable", "--now", "harness-slack-swallow-rotate-read.timer")
    systemctl_action("stop", "harness-slack-swallow.service")
    os.rename(CREDENTIAL_STORE, target)


def main() -> int:
    arguments = sys.argv[1:]
    valid_serve = (
        len(arguments) == 4
        and arguments[0] == "serve-swallow"
        and arguments[1].isdigit()
        and arguments[2].isdigit()
        and len(arguments[3]) == 40
        and all(character in "0123456789abcdef" for character in arguments[3])
    )
    commands = (
        ["preflight"],
        ["install-swallow"],
        ["quarantine-swallow"],
        ["diagnose-swallow-read-scopes"],
        ["refresh-swallow-read-service"],
    )
    if arguments not in commands and not valid_serve:
        print("SLACK_LIVE_INSTALL status=failed reason=argument-invalid", file=sys.stderr)
        return 2
    try:
        if os.geteuid() != 0:
            fail("root-required")
        if arguments == ["preflight"]:
            preflight()
            print("SLACK_LIVE_INSTALL status=pass action=preflight profile=swallow")
            return 0
        if arguments == ["quarantine-swallow"]:
            quarantine()
            print("SLACK_LIVE_INSTALL status=complete profile=swallow action=quarantined")
            return 0
        if arguments == ["diagnose-swallow-read-scopes"]:
            diagnose_read_scopes()
            return 0
        if arguments == ["refresh-swallow-read-service"]:
            refresh_read_service()
            print(
                "SLACK_LIVE_INSTALL status=complete profile=swallow "
                "action=read-service-refreshed"
            )
            return 0
        if valid_serve:
            client_uid = int(arguments[1])
            client_gid = int(arguments[2])
            revision = arguments[3]
            preflight(revision)
            common.receive_once(
                ENROLLMENT_SOCKET,
                client_uid,
                client_gid,
                lambda bundle: install(validate_bundle(bundle), revision),
                validator=validate_bundle,
            )
            print("SLACK_LIVE_INSTALL status=complete profile=swallow credentials=4")
            return 0
        payload = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
        if len(payload) > MAX_INPUT_BYTES:
            fail("credential-bundle-invalid")
        try:
            bundle = validate_bundle(json.loads(payload))
        except (UnicodeError, json.JSONDecodeError):
            fail("credential-bundle-invalid")
        install(bundle)
    except (SwallowInstallError, common.InstallError) as exc:
        print(f"SLACK_LIVE_INSTALL status=failed reason={exc}", file=sys.stderr)
        return 2
    except Exception:
        print("SLACK_LIVE_INSTALL status=failed reason=internal-error", file=sys.stderr)
        return 2
    print("SLACK_LIVE_INSTALL status=complete profile=swallow credentials=4")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
