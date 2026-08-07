#!/usr/bin/env python3
"""Rotate one profile-local Slack credential role exactly once."""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
from typing import Any, Callable
import urllib.error
import urllib.parse
import urllib.request

import harness_slack_mcp_remote as remote


TOKEN_ENDPOINT = "https://slack.com/api/oauth.v2.access"
SCOPE_ENDPOINT = "https://slack.com/api/auth.test"
MIN_ROTATING_TTL_SECONDS = 60 * 60
MAX_ROTATING_TTL_SECONDS = 12 * 60 * 60 + 5 * 60
ROLE = {
    "read": {
        "access": "slack-access-read",
        "kind": "user",
        "refresh": "slack-refresh-read",
        "scopes": {
            "canvases:read",
            "channels:history",
            "files:read",
            "groups:history",
            "users:read",
        },
        # Slack documents `identify` as inherent to user tokens and explicit
        # for classic or migrated app lineage. It adds no capability beyond
        # the identity already inherent in the user token.
        "effective_scopes": {
            "canvases:read",
            "channels:history",
            "files:read",
            "groups:history",
            "identify",
            "users:read",
        },
    },
    "write": {
        "access": "slack-access-write",
        "kind": "bot",
        "refresh": "slack-refresh-write",
        "scopes": {"chat:write"},
        "effective_scopes": {"chat:write"},
    },
}
SWALLOW_READ = {
    "access": "slack-access-read",
    "kind": "bot",
    "refresh": "slack-refresh-read",
    "scopes": {
        "canvases:read",
        "channels:history",
        "files:read",
        "groups:history",
    },
    "effective_scopes": {
        "canvases:read",
        "channels:history",
        "files:read",
        "groups:history",
    },
}
MAX_RESPONSE_BYTES = 64 * 1024


class RotationError(ValueError):
    """Stable value-free rotation failure."""


def fail(reason: str) -> None:
    raise RotationError(reason)


def progress(phase: str) -> None:
    print(f"SLACK_ROTATION status=progress phase={phase}", file=sys.stderr)


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(
        self,
        req: object,
        fp: object,
        code: int,
        msg: str,
        headers: object,
        newurl: str,
    ) -> None:
        return None


SCOPE_OPENER = urllib.request.build_opener(_NoRedirect())


def _scopes(value: object) -> set[str]:
    if not isinstance(value, str):
        fail("rotation-response-invalid")
    result = {item for item in value.replace(",", " ").split() if item}
    if not result or any(
        re.fullmatch(r"[a-z][a-z0-9._:-]{0,63}", item) is None for item in result
    ):
        fail("rotation-response-invalid")
    return result


def role_policy(profile: str, role: str) -> dict[str, object]:
    if profile == "personal":
        policy = ROLE.get(role)
    elif profile == "swallow" and role == "read":
        policy = SWALLOW_READ
    else:
        policy = None
    if policy is None:
        fail("rotation-role-invalid")
    return policy


def parse_response(
    role: str, value: object, profile: str = "personal"
) -> tuple[str, str, set[str]]:
    policy = role_policy(profile, role)
    if not isinstance(value, dict) or value.get("ok") is not True:
        fail("rotation-refresh-rejected")
    ttl = value.get("expires_in")
    if value.get("token_type") != policy["kind"]:
        fail("rotation-token-type-invalid")
    if (
        type(ttl) is not int
        or not MIN_ROTATING_TTL_SECONDS <= ttl <= MAX_ROTATING_TTL_SECONDS
    ):
        fail("rotation-expiry-invalid")
    scopes = _scopes(value.get("scope"))
    access = value.get("access_token")
    refresh = value.get("refresh_token")
    for token, reason in (
        (access, "rotation-access-token-invalid"),
        (refresh, "rotation-refresh-token-invalid"),
    ):
        if (
            not isinstance(token, str)
            or not 16 <= len(token) <= remote.MAX_CREDENTIAL_BYTES
            or any(character.isspace() for character in token)
        ):
            fail(reason)
    return access, refresh, scopes


def enforce_scopes(expected: set[str], actual: set[str]) -> None:
    missing = expected - actual
    additional = actual - expected
    if missing and additional:
        fail("rotation-scope-drift")
    if missing:
        fail("rotation-scope-missing")
    if additional:
        fail("rotation-scope-additional")


def validate_response(
    role: str, value: object, profile: str = "personal"
) -> tuple[str, str]:
    policy = role_policy(profile, role)
    access, refresh, scopes = parse_response(role, value, profile)
    enforce_scopes(policy["effective_scopes"], scopes)
    return access, refresh


def verify_access_scopes_once(access_token: str) -> set[str]:
    """Read only Slack's effective-scope response header for a fresh token."""
    request = urllib.request.Request(
        SCOPE_ENDPOINT,
        data=b"",
        headers={
            "Accept": "application/json",
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    try:
        with SCOPE_OPENER.open(request, timeout=30) as result:
            if int(result.status) != 200:
                fail("rotation-scope-readback-rejected")
            value = result.headers.get("X-OAuth-Scopes")
    except urllib.error.HTTPError:
        fail("rotation-scope-readback-rejected")
    except (OSError, TimeoutError, urllib.error.URLError):
        fail("rotation-scope-readback-unavailable")
    return _scopes(value)


def exchange_once(
    client_id: str, client_secret: str, refresh_token: str
) -> dict[str, Any]:
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode("utf-8")).decode(
        "ascii"
    )
    request = urllib.request.Request(
        TOKEN_ENDPOINT,
        data=urllib.parse.urlencode(
            {"grant_type": "refresh_token", "refresh_token": refresh_token}
        ).encode("ascii"),
        headers={
            "Accept": "application/json",
            "Authorization": f"Basic {basic}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as result:
            payload = result.read(MAX_RESPONSE_BYTES + 1)
    except urllib.error.HTTPError:
        fail("rotation-refresh-rejected")
    except (OSError, TimeoutError, urllib.error.URLError):
        # The request may have reached Slack and consumed the single-use
        # refresh token. Never retry an ambiguous exchange.
        fail("rotation-refresh-ambiguous")
    if len(payload) > MAX_RESPONSE_BYTES:
        fail("rotation-response-invalid")
    try:
        value = json.loads(payload)
    except (UnicodeError, json.JSONDecodeError):
        fail("rotation-response-invalid")
    if not isinstance(value, dict):
        fail("rotation-response-invalid")
    return value


def _encrypt(name: str, value: str, output: Path) -> None:
    try:
        result = subprocess.run(
            [
                "systemd-creds",
                "encrypt",
                "--name",
                name,
                "-",
                str(output),
            ],
            input=value.encode("utf-8"),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("rotation-store-failed")
    if result.returncode != 0:
        fail("rotation-store-failed")
    os.chmod(output, 0o600)


def store_pair(
    store: Path,
    role: str,
    access: str,
    refresh: str,
    encrypt: Callable[[str, str, Path], None] = _encrypt,
    owner_uid: int = 0,
) -> None:
    policy = ROLE[role]
    try:
        info = store.lstat()
    except OSError:
        fail("rotation-store-invalid")
    if (
        not stat.S_ISDIR(info.st_mode)
        or stat.S_IMODE(info.st_mode) != 0o700
        or info.st_uid != owner_uid
    ):
        fail("rotation-store-invalid")
    stage = store / f".rotate-{role}-{os.getpid()}"
    previous = store / f".previous-{role}"
    stage.mkdir(mode=0o700)
    try:
        staged_access = stage / str(policy["access"])
        staged_refresh = stage / str(policy["refresh"])
        encrypt(str(policy["access"]), access, staged_access)
        encrypt(str(policy["refresh"]), refresh, staged_refresh)
        for name in (str(policy["access"]), str(policy["refresh"])):
            info = (stage / name).lstat()
            if (
                not stat.S_ISREG(info.st_mode)
                or info.st_uid != owner_uid
                or stat.S_IMODE(info.st_mode) != 0o600
                or info.st_nlink != 1
                or info.st_size == 0
            ):
                fail("rotation-store-failed")
        previous.mkdir(mode=0o700, exist_ok=True)
        # Save only the still-valid access generation. A consumed refresh token
        # is never retained as a candidate for replay.
        current_access = store / str(policy["access"])
        if current_access.exists():
            old = previous / str(policy["access"])
            if old.exists():
                old.unlink()
            os.replace(current_access, old)
        # Commit the new single-use refresh before its paired access token so a
        # crash cannot lose the only usable refresh generation.
        os.replace(staged_refresh, store / str(policy["refresh"]))
        os.replace(staged_access, store / str(policy["access"]))
    finally:
        for child in tuple(stage.iterdir()) if stage.exists() else ():
            child.unlink()
        if stage.exists():
            stage.rmdir()


def rotate_role(
    role: str,
    credentials: Path,
    store: Path,
    *,
    profile: str = "personal",
    exchange: Callable[[str, str, str], dict[str, Any]] = exchange_once,
    store_action: Callable[[Path, str, str, str], None] = store_pair,
    verify_scopes: Callable[[str], set[str]] = verify_access_scopes_once,
    read_credential: Callable[[str], str] = remote.read_credential,
) -> None:
    policy = role_policy(profile, role)
    client_id = read_credential(str(credentials / "slack-client-id"))
    client_secret = read_credential(str(credentials / "slack-client-secret"))
    refresh = read_credential(str(credentials / str(policy["refresh"])))
    progress("exchange-starting")
    response = exchange(client_id, client_secret, refresh)
    progress("exchange-received")
    access, next_refresh, response_scopes = parse_response(role, response, profile)
    progress("response-shape-valid")
    expected_scopes = policy["effective_scopes"]
    if response_scopes != expected_scopes:
        progress("scope-readback-starting")
        effective_scopes = verify_scopes(access)
        enforce_scopes(expected_scopes, effective_scopes)
        progress("scope-readback-valid")
    else:
        progress("response-scope-valid")
    progress("credential-store-starting")
    store_action(store, role, access, next_refresh)
    progress("credential-store-complete")


def validate_restart(
    role: str, service: str | None, profile: str = "personal"
) -> None:
    expected = (
        f"harness-slack-{profile}.service"
        if role == "read" and profile in {"personal", "swallow"}
        else None
    )
    if service != expected:
        fail("rotation-restart-invalid")


def diagnose_scopes(
    role: str,
    credentials: Path,
    *,
    profile: str = "personal",
    verify_scopes: Callable[[str], set[str]] = verify_access_scopes_once,
    read_credential: Callable[[str], str] = remote.read_credential,
) -> str:
    policy = role_policy(profile, role)
    access = read_credential(str(credentials / str(policy["access"])))
    actual = verify_scopes(access)
    missing = sorted(policy["effective_scopes"] - actual)
    additional = sorted(actual - policy["effective_scopes"])
    status = "pass" if not missing and not additional else "drift"
    return (
        f"SLACK_SCOPE status={status} role={role} "
        f"missing={','.join(missing) if missing else 'none'} "
        f"additional={','.join(additional) if additional else 'none'}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--credentials", required=True)
    parser.add_argument("--profile", choices=("personal", "swallow"), default="personal")
    parser.add_argument("--role", choices=tuple(ROLE), required=True)
    parser.add_argument("--store")
    parser.add_argument("--restart-service")
    parser.add_argument("--diagnose-scopes", action="store_true")
    args = parser.parse_args()
    try:
        if os.geteuid() != 0:
            fail("rotation-root-required")
        if args.diagnose_scopes:
            if args.store is not None or args.restart_service is not None:
                fail("rotation-diagnosis-arguments-invalid")
            print(diagnose_scopes(args.role, Path(args.credentials), profile=args.profile))
            return 0
        if args.store is None:
            fail("rotation-store-required")
        validate_restart(args.role, args.restart_service, args.profile)
        rotate_role(
            args.role, Path(args.credentials), Path(args.store), profile=args.profile
        )
        if args.restart_service:
            result = subprocess.run(
                ["systemctl", "restart", args.restart_service],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=30,
                check=False,
            )
            if result.returncode != 0:
                fail("rotation-restart-failed")
    except RotationError as exc:
        reason = str(exc)
        status = (
            "renewal-required"
            if reason == "rotation-refresh-rejected"
            else "repair-required"
            if reason == "rotation-refresh-ambiguous"
            else "failed"
        )
        print(f"SLACK_ROTATION status={status} reason={reason}", file=sys.stderr)
        return 2
    except Exception:
        print("SLACK_ROTATION status=failed reason=internal-error", file=sys.stderr)
        return 2
    print(f"SLACK_ROTATION status=complete profile={args.profile} role={args.role}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
