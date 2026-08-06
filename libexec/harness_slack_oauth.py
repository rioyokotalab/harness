#!/usr/bin/env python3
"""One-shot confidential OAuth for the Personal Slack profile.

Credential values stay in process memory and are delivered only to a
root-authenticated, one-shot local Unix socket. Output and exceptions use
stable value-free reasons.
"""

from __future__ import annotations

import argparse
import base64
import http.server
import json
import os
from pathlib import Path
import secrets
import socket
import stat
import struct
import subprocess
import sys
import termios
import time
from typing import Any, Callable
import urllib.error
import urllib.parse
import urllib.request


AUTH_ENDPOINT = "https://slack.com/oauth/v2/authorize"
TOKEN_ENDPOINT = "https://slack.com/api/oauth.v2.access"
REDIRECT_URI = "http://localhost:53683/slack/oauth/callback"
CALLBACK_HOST = "127.0.0.1"
CALLBACK_PORT = 53683
CALLBACK_PATH = "/slack/oauth/callback"
PROBE_PATH = "/slack/oauth/probe"
CALLBACK_TIMEOUT_SECONDS = 300
MAX_SECRET_BYTES = 8192
MAX_SINK_RESPONSE_BYTES = 256
BOT_SCOPES = ("chat:write",)
USER_SCOPES = (
    "canvases:read",
    "channels:history",
    "files:read",
    "groups:history",
    "users:read",
)
BUNDLE_FIELDS = {
    "slack-access-read",
    "slack-access-write",
    "slack-client-id",
    "slack-client-secret",
    "slack-refresh-read",
    "slack-refresh-write",
}


class OAuthError(ValueError):
    """Stable value-free OAuth failure."""


def fail(reason: str) -> None:
    raise OAuthError(reason)


def _bounded_secret(value: object, reason: str) -> str:
    if (
        not isinstance(value, str)
        or not 1 <= len(value.encode("utf-8")) <= MAX_SECRET_BYTES
        or any(character.isspace() for character in value)
    ):
        fail(reason)
    return value


def _scope_set(value: object, reason: str) -> set[str]:
    if not isinstance(value, str) or not value:
        fail(reason)
    scopes = {item for item in value.replace(",", " ").split() if item}
    if not scopes:
        fail(reason)
    return scopes


def _hidden_prompt(prompt: str) -> str:
    """Read one bounded value from inherited stdin with echo proven off."""
    try:
        descriptor = sys.stdin.fileno()
        if not os.isatty(descriptor):
            fail("oauth-hidden-prompt-unavailable")
        original = termios.tcgetattr(descriptor)
        hidden = original[:]
        hidden[3] &= ~termios.ECHO
        termios.tcsetattr(descriptor, termios.TCSAFLUSH, hidden)
    except (OSError, ValueError, termios.error):
        fail("oauth-hidden-prompt-unavailable")
    try:
        sys.stderr.write(prompt)
        sys.stderr.flush()
        value = sys.stdin.readline(MAX_SECRET_BYTES + 2)
        if not value.endswith("\n"):
            fail("oauth-hidden-prompt-unavailable")
        return value[:-1].removesuffix("\r")
    finally:
        try:
            termios.tcsetattr(descriptor, termios.TCSADRAIN, original)
            sys.stderr.write("\n")
            sys.stderr.flush()
        except (OSError, ValueError, termios.error):
            fail("oauth-hidden-prompt-unavailable")


def authorization_url(client_id: str, state: str) -> str:
    client_id = _bounded_secret(client_id, "oauth-client-id-invalid")
    state = _bounded_secret(state, "oauth-state-invalid")
    parameters = {
        "client_id": client_id,
        "redirect_uri": REDIRECT_URI,
        "scope": ",".join(BOT_SCOPES),
        "state": state,
        "user_scope": ",".join(USER_SCOPES),
    }
    return f"{AUTH_ENDPOINT}?{urllib.parse.urlencode(parameters)}"


def validate_token_response(
    response: object, client_id: str, client_secret: str
) -> dict[str, str]:
    if not isinstance(response, dict) or response.get("ok") is not True:
        fail("oauth-exchange-rejected")
    if response.get("token_type") != "bot":
        fail("oauth-bot-token-invalid")
    if "expires_in" not in response and "refresh_token" not in response:
        fail("oauth-token-rotation-required")
    if response.get("expires_in") != 43200:
        fail("oauth-bot-token-invalid")
    if _scope_set(response.get("scope"), "oauth-bot-scope-invalid") != set(BOT_SCOPES):
        fail("oauth-bot-scope-invalid")
    user = response.get("authed_user")
    if not isinstance(user, dict):
        fail("oauth-user-token-invalid")
    if user.get("token_type") != "user":
        fail("oauth-user-token-invalid")
    if "expires_in" not in user and "refresh_token" not in user:
        fail("oauth-token-rotation-required")
    if user.get("expires_in") != 43200:
        fail("oauth-user-token-invalid")
    if _scope_set(user.get("scope"), "oauth-user-scope-invalid") != set(USER_SCOPES):
        fail("oauth-user-scope-invalid")
    return {
        "slack-access-read": _bounded_secret(
            user.get("access_token"), "oauth-user-token-invalid"
        ),
        "slack-access-write": _bounded_secret(
            response.get("access_token"), "oauth-bot-token-invalid"
        ),
        "slack-client-id": _bounded_secret(client_id, "oauth-client-id-invalid"),
        "slack-client-secret": _bounded_secret(
            client_secret, "oauth-client-secret-invalid"
        ),
        "slack-refresh-read": _bounded_secret(
            user.get("refresh_token"), "oauth-user-refresh-invalid"
        ),
        "slack-refresh-write": _bounded_secret(
            response.get("refresh_token"), "oauth-bot-refresh-invalid"
        ),
    }


def _exchange(code: str, client_id: str, client_secret: str) -> dict[str, Any]:
    code = _bounded_secret(code, "oauth-code-invalid")
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode("utf-8")).decode(
        "ascii"
    )
    request = urllib.request.Request(
        TOKEN_ENDPOINT,
        data=urllib.parse.urlencode(
            {
                "code": code,
                "grant_type": "authorization_code",
                "redirect_uri": REDIRECT_URI,
            }
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
            payload = result.read(64 * 1024 + 1)
    except urllib.error.HTTPError:
        fail("oauth-exchange-rejected")
    except (OSError, TimeoutError, urllib.error.URLError):
        fail("oauth-exchange-unknown")
    if len(payload) > 64 * 1024:
        fail("oauth-exchange-invalid")
    try:
        value = json.loads(payload)
    except (UnicodeError, json.JSONDecodeError):
        fail("oauth-exchange-invalid")
    if not isinstance(value, dict):
        fail("oauth-exchange-invalid")
    return value


class _Callback(http.server.BaseHTTPRequestHandler):
    query: dict[str, list[str]] | None = None
    expected_state: str | None = None
    probe_seen = False

    def do_GET(self) -> None:  # noqa: N802 - inherited HTTP handler name
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == PROBE_PATH:
            type(self).probe_seen = True
            self.send_response(204)
            self.end_headers()
            return
        if parsed.path != CALLBACK_PATH:
            self.send_error(404)
            return
        query = urllib.parse.parse_qs(parsed.query)
        if query.get("state") != [type(self).expected_state]:
            self.send_error(400)
            return
        type(self).query = query
        body = b"Slack authorization received. Return to the terminal."
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        del format, args


def _open_browser(url: str, helper: Path) -> None:
    if not helper.is_absolute():
        fail("oauth-browser-helper-invalid")
    try:
        info = helper.lstat()
    except OSError:
        fail("oauth-browser-helper-invalid")
    if (
        not stat.S_ISREG(info.st_mode)
        or stat.S_ISLNK(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_nlink != 1
        or not os.access(helper, os.X_OK)
    ):
        fail("oauth-browser-helper-invalid")
    try:
        result = subprocess.run(
            [str(helper)],
            input=url.encode("ascii"),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        fail("oauth-browser-open-failed")
    if result.returncode != 0:
        fail("oauth-browser-open-failed")


def _handle_until(
    server: http.server.HTTPServer,
    accepted: Callable[[], bool],
    deadline: float,
    reason: str,
) -> None:
    while not accepted():
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            fail(reason)
        server.timeout = min(1.0, remaining)
        server.handle_request()


def _probe_tunnel(server: http.server.HTTPServer, browser_host: str) -> None:
    if browser_host not in {"aist", "home", "office", "riken"}:
        fail("oauth-browser-host-invalid")
    try:
        process = subprocess.Popen(
            [
                "ssh",
                "-x",
                browser_host,
                "/usr/bin/curl",
                "--fail",
                "--silent",
                "--show-error",
                "--max-time",
                "10",
                f"http://127.0.0.1:{CALLBACK_PORT}{PROBE_PATH}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        fail("oauth-tunnel-probe-failed")
    try:
        _handle_until(
            server,
            lambda: _Callback.probe_seen or process.poll() is not None,
            time.monotonic() + 15,
            "oauth-tunnel-probe-failed",
        )
        try:
            returncode = process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            fail("oauth-tunnel-probe-failed")
        if not _Callback.probe_seen or returncode != 0:
            fail("oauth-tunnel-probe-failed")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
def authorize(
    client_id: str,
    client_secret: str,
    helper: Path,
    sink: Callable[[dict[str, str]], None],
    *,
    exchange: Callable[[str, str, str], dict[str, Any]] = _exchange,
) -> None:
    state = secrets.token_urlsafe(32)
    _Callback.query = None
    _Callback.expected_state = state
    _Callback.probe_seen = False
    try:
        server = http.server.HTTPServer((CALLBACK_HOST, CALLBACK_PORT), _Callback)
    except OSError:
        fail("oauth-callback-bind-failed")
    server.timeout = CALLBACK_TIMEOUT_SECONDS
    try:
        _probe_tunnel(server, os.environ.get("HARNESS_OAUTH_BROWSER_HOST", ""))
        _open_browser(authorization_url(client_id, state), helper)
        _handle_until(
            server,
            lambda: _Callback.query is not None,
            time.monotonic() + CALLBACK_TIMEOUT_SECONDS,
            "oauth-callback-timeout",
        )
    finally:
        server.server_close()
    query = _Callback.query
    if not query:
        fail("oauth-callback-timeout")
    if query.get("state") != [state]:
        fail("oauth-state-mismatch")
    if "error" in query:
        fail("oauth-consent-rejected")
    code = query.get("code")
    if not code or len(code) != 1:
        fail("oauth-code-missing")
    # The temporary verifier is exchanged exactly once. Network ambiguity is
    # terminal and deliberately never retried.
    response = exchange(code[0], client_id, client_secret)
    sink(validate_token_response(response, client_id, client_secret))


def _sink_socket(
    bundle: dict[str, str],
    path: Path,
    *,
    server_uid: int = 0,
    client_gid: int | None = None,
) -> None:
    if set(bundle) != BUNDLE_FIELDS or not path.is_absolute():
        fail("oauth-credential-sink-invalid")
    if client_gid is None:
        client_gid = os.getgid()
    try:
        info = path.lstat()
    except OSError:
        fail("oauth-credential-sink-invalid")
    if (
        not stat.S_ISSOCK(info.st_mode)
        or info.st_uid != server_uid
        or info.st_gid != client_gid
        or stat.S_IMODE(info.st_mode) != 0o660
    ):
        fail("oauth-credential-sink-invalid")
    payload = json.dumps(bundle, separators=(",", ":")).encode("utf-8")
    if len(payload) > 64 * 1024:
        fail("oauth-credential-sink-invalid")
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(900)
            connection.connect(str(path))
            credentials = connection.getsockopt(
                socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i")
            )
            _pid, peer_uid, _peer_gid = struct.unpack("3i", credentials)
            if peer_uid != server_uid:
                fail("oauth-credential-sink-invalid")
            connection.sendall(len(payload).to_bytes(4, "big") + payload)
            connection.shutdown(socket.SHUT_WR)
            response_parts: list[bytes] = []
            response_size = 0
            while True:
                chunk = connection.recv(MAX_SINK_RESPONSE_BYTES + 1 - response_size)
                if not chunk:
                    break
                response_parts.append(chunk)
                response_size += len(chunk)
                if response_size > MAX_SINK_RESPONSE_BYTES:
                    fail("oauth-credential-sink-failed")
            response = b"".join(response_parts)
    except (OSError, TimeoutError):
        fail("oauth-credential-sink-failed")
    finally:
        payload = b""
    if response != b"SLACK_CREDENTIAL_SINK status=complete\n":
        fail("oauth-credential-sink-failed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser-helper", required=True)
    parser.add_argument("--credential-socket", required=True)
    args = parser.parse_args()
    try:
        client_id = _hidden_prompt("Slack client ID (hidden): ")
        client_secret = _hidden_prompt("Slack client secret (hidden): ")
        print(
            "SLACK_OAUTH status=waiting action=complete-browser-consent",
            file=sys.stderr,
        )
        authorize(
            client_id,
            client_secret,
            Path(args.browser_helper),
            lambda bundle: _sink_socket(bundle, Path(args.credential_socket)),
        )
    except OAuthError as exc:
        print(f"SLACK_OAUTH status=failed reason={exc}", file=sys.stderr)
        return 2
    except Exception:
        print("SLACK_OAUTH status=failed reason=internal-error", file=sys.stderr)
        return 2
    print("SLACK_OAUTH status=complete profile=personal credentials=encrypted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
