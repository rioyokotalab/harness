#!/usr/bin/env python3
"""Bounded credential-safe client for Slack's official remote MCP server."""

from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path
import stat
import time
from typing import Any, Callable, Mapping, Protocol
import urllib.error
import urllib.request

import harness_slack_broker as broker


ENDPOINT = "https://mcp.slack.com/mcp"
PROTOCOL = "2025-06-18"
MAX_CREDENTIAL_BYTES = 16 * 1024
REMOTE_TOOL = {
    "slack_read_channel": ("slack_read_channel", {"resource": "channel_id"}),
    "slack_read_thread": (
        "slack_read_thread",
        {"resource": "channel_id", "thread": "message_ts"},
    ),
    "slack_read_linked_canvas": ("slack_read_canvas", {"resource": "canvas_id"}),
    "slack_read_linked_file": ("slack_read_file", {"resource": "file_id"}),
    "slack_read_profile": ("slack_read_user_profile", {"resource": "user_id"}),
}
LINK_PROOF_REQUIRED = {"slack_read_linked_canvas", "slack_read_linked_file"}


class RemoteMCPError(ValueError):
    """Stable value-free upstream failure."""


class HTTPFailure(RemoteMCPError):
    def __init__(self, status: int, retry_after: int | None = None) -> None:
        super().__init__("provider-http-failed")
        self.status = status
        self.retry_after = retry_after


@dataclass(frozen=True)
class HTTPResponse:
    status: int
    headers: Mapping[str, str]
    body: bytes


class Transport(Protocol):
    def post(
        self,
        body: bytes,
        token: str,
        session_id: str | None,
        timeout: int,
        max_bytes: int,
    ) -> HTTPResponse: ...

    def web_api(
        self,
        method: str,
        arguments: dict[str, Any],
        token: str,
        timeout: int,
        max_bytes: int,
    ) -> HTTPResponse: ...


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


class URLTransport:
    """Fixed-origin HTTPS transport which never serializes credentials in errors."""

    def __init__(self) -> None:
        self.opener = urllib.request.build_opener(_NoRedirect())

    def post(
        self,
        body: bytes,
        token: str,
        session_id: str | None,
        timeout: int,
        max_bytes: int,
    ) -> HTTPResponse:
        headers = {
            "Accept": "application/json, text/event-stream",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "MCP-Protocol-Version": PROTOCOL,
        }
        if session_id is not None:
            headers["Mcp-Session-Id"] = session_id
        return self._request(ENDPOINT, body, headers, timeout, max_bytes)

    def web_api(
        self,
        method: str,
        arguments: dict[str, Any],
        token: str,
        timeout: int,
        max_bytes: int,
    ) -> HTTPResponse:
        if method != "conversations.history":
            raise RemoteMCPError("provider-web-method-denied")
        body = broker.canonical_json(arguments).encode("utf-8")
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json; charset=utf-8",
        }
        return self._request(
            f"https://slack.com/api/{method}", body, headers, timeout, max_bytes
        )

    def _request(
        self,
        endpoint: str,
        body: bytes,
        headers: dict[str, str],
        timeout: int,
        max_bytes: int,
    ) -> HTTPResponse:
        request = urllib.request.Request(endpoint, data=body, headers=headers, method="POST")
        try:
            with self.opener.open(request, timeout=timeout) as response:
                payload = response.read(max_bytes + 1)
                if len(payload) > max_bytes:
                    raise RemoteMCPError("provider-response-too-large")
                return HTTPResponse(
                    status=int(response.status),
                    headers={key.lower(): value for key, value in response.headers.items()},
                    body=payload,
                )
        except urllib.error.HTTPError as exc:
            retry_after = _retry_after(exc.headers.get("Retry-After"))
            raise HTTPFailure(int(exc.code), retry_after) from None
        except (OSError, urllib.error.URLError, TimeoutError):
            raise RemoteMCPError("provider-network-failed") from None


def _retry_after(value: object) -> int | None:
    if not isinstance(value, str) or not value.isascii() or not value.isdecimal():
        return None
    parsed = int(value)
    return parsed if 1 <= parsed <= 300 else None


def read_credential(path_text: str) -> str:
    path = Path(path_text)
    if not path.is_absolute():
        raise RemoteMCPError("credential-path-invalid")
    flags = os.O_RDONLY | os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        descriptor = os.open(path, flags)
    except OSError:
        raise RemoteMCPError("credential-unavailable") from None
    try:
        info = os.fstat(descriptor)
        if (
            not stat.S_ISREG(info.st_mode)
            or info.st_nlink != 1
            or info.st_uid not in {0, os.geteuid()}
            or info.st_mode & (stat.S_IRWXG | stat.S_IRWXO)
            or not 0 < info.st_size <= MAX_CREDENTIAL_BYTES
        ):
            raise RemoteMCPError("credential-metadata-unsafe")
        chunks: list[bytes] = []
        remaining = MAX_CREDENTIAL_BYTES + 1
        while remaining:
            chunk = os.read(descriptor, remaining)
            if not chunk:
                break
            chunks.append(chunk)
            remaining -= len(chunk)
        value = b"".join(chunks)
    finally:
        os.close(descriptor)
    if len(value) > MAX_CREDENTIAL_BYTES:
        raise RemoteMCPError("credential-size-invalid")
    try:
        token = value.decode("utf-8").rstrip("\n")
    except UnicodeError:
        raise RemoteMCPError("credential-format-invalid") from None
    if not 16 <= len(token) <= 8192 or any(character.isspace() for character in token):
        raise RemoteMCPError("credential-format-invalid")
    return token


def _parse_json_response(response: HTTPResponse, request_id: int) -> dict[str, Any]:
    content_type = response.headers.get("content-type", "").split(";", 1)[0].strip().lower()
    candidates: list[object] = []
    try:
        text = response.body.decode("utf-8")
    except UnicodeError:
        raise RemoteMCPError("provider-response-invalid") from None
    if content_type == "application/json":
        try:
            candidates.append(json.loads(text))
        except json.JSONDecodeError:
            raise RemoteMCPError("provider-response-invalid") from None
    elif content_type == "text/event-stream":
        data_lines: list[str] = []
        for line in text.splitlines():
            if not line:
                if data_lines:
                    try:
                        candidates.append(json.loads("\n".join(data_lines)))
                    except json.JSONDecodeError:
                        raise RemoteMCPError("provider-response-invalid") from None
                    data_lines = []
                continue
            if line.startswith("data:"):
                data_lines.append(line[5:].lstrip())
        if data_lines:
            try:
                candidates.append(json.loads("\n".join(data_lines)))
            except json.JSONDecodeError:
                raise RemoteMCPError("provider-response-invalid") from None
    else:
        raise RemoteMCPError("provider-content-type-invalid")
    for candidate in candidates:
        if isinstance(candidate, dict) and candidate.get("id") == request_id:
            unexpected = set(candidate) - {"error", "id", "jsonrpc", "result"}
            if candidate.get("jsonrpc") != "2.0" or unexpected:
                break
            if "error" in candidate or "result" not in candidate:
                raise RemoteMCPError("provider-request-failed")
            if not isinstance(candidate["result"], dict):
                raise RemoteMCPError("provider-result-invalid")
            return candidate
    raise RemoteMCPError("provider-response-missing")


class SlackRemoteMCP:
    """Lazy, profile-bounded adapter from local tools to Slack MCP tools."""

    def __init__(
        self,
        profile: dict[str, Any],
        token: str,
        transport: Transport | None = None,
        sleeper: Callable[[float], None] = time.sleep,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.profile = broker.validate_profile(profile)
        if not 16 <= len(token) <= 8192 or any(character.isspace() for character in token):
            raise RemoteMCPError("credential-format-invalid")
        self._token = token
        self._transport = transport or URLTransport()
        self._sleeper = sleeper
        self._clock = clock
        self._next_id = 1
        self._session_id: str | None = None
        self._initialized = False
        self._remote_tools: set[str] = set()

    def _with_retry(self, action: Callable[[int], HTTPResponse]) -> HTTPResponse:
        attempt = 1
        started = self._clock()
        while True:
            remaining = self.profile["limits"]["max_seconds"] - (self._clock() - started)
            if remaining < 1:
                raise RemoteMCPError("provider-time-budget-exceeded")
            try:
                return action(max(1, int(remaining)))
            except HTTPFailure as exc:
                plan = broker.retry_plan(
                    self.profile, "read", exc.status, attempt, exc.retry_after
                )
                if not plan["retry"]:
                    raise RemoteMCPError(plan["reason"]) from None
                if plan["wait_seconds"] >= remaining:
                    raise RemoteMCPError("provider-time-budget-exceeded") from None
                self._sleeper(plan["wait_seconds"])
                attempt += 1

    def _post(self, message: dict[str, Any], request_id: int | None) -> dict[str, Any] | None:
        body = broker.canonical_json(message).encode("utf-8")
        if len(body) > broker.MAX_JSON_BYTES:
            raise RemoteMCPError("provider-request-too-large")
        response = self._with_retry(
            lambda timeout: self._transport.post(
                    body,
                    self._token,
                    self._session_id,
                    timeout,
                    self.profile["limits"]["max_bytes"],
                )
        )
        session_id = response.headers.get("mcp-session-id")
        if session_id is not None:
            invalid_character = any(
                not 0x21 <= ord(character) <= 0x7E for character in session_id
            )
            if not session_id or invalid_character:
                raise RemoteMCPError("provider-session-invalid")
            if self._session_id not in {None, session_id}:
                raise RemoteMCPError("provider-session-changed")
            self._session_id = session_id
        if request_id is None:
            if response.status != 202 or response.body:
                raise RemoteMCPError("provider-notification-invalid")
            return None
        if response.status != 200:
            raise RemoteMCPError("provider-http-failed")
        return _parse_json_response(response, request_id)

    def _request(self, method: str, params: dict[str, Any]) -> dict[str, Any]:
        request_id = self._next_id
        self._next_id += 1
        message = {"id": request_id, "jsonrpc": "2.0", "method": method, "params": params}
        response = self._post(message, request_id)
        if response is None:
            raise RemoteMCPError("provider-response-missing")
        return response["result"]

    def _initialize(self) -> None:
        if self._initialized:
            return
        initialized = self._request(
            "initialize",
            {
                "capabilities": {},
                "clientInfo": {"name": "harness-slack-broker", "version": broker.CONTRACT},
                "protocolVersion": PROTOCOL,
            },
        )
        if initialized.get("protocolVersion") != PROTOCOL:
            raise RemoteMCPError("provider-protocol-drift")
        self._post({"jsonrpc": "2.0", "method": "notifications/initialized"}, None)
        cursor: str | None = None
        for _page in range(self.profile["limits"]["max_pages"]):
            params = {} if cursor is None else {"cursor": cursor}
            listing = self._request("tools/list", params)
            tools = listing.get("tools")
            if not isinstance(tools, list):
                raise RemoteMCPError("provider-tools-invalid")
            for tool in tools:
                if not isinstance(tool, dict) or not isinstance(tool.get("name"), str):
                    raise RemoteMCPError("provider-tools-invalid")
                self._remote_tools.add(tool["name"])
            next_cursor = listing.get("nextCursor")
            if next_cursor is None:
                break
            if not isinstance(next_cursor, str) or not next_cursor or len(next_cursor) > 4096:
                raise RemoteMCPError("provider-cursor-invalid")
            cursor = next_cursor
        else:
            raise RemoteMCPError("provider-pages-exceeded")
        local_schema = broker.tool_schema(self.profile, "absent")
        local_tools = {tool["name"] for tool in local_schema["tools"]}
        unmapped = local_tools - {"slack_broker_status"} - set(REMOTE_TOOL)
        if unmapped:
            raise RemoteMCPError("provider-tool-map-missing")
        required = {REMOTE_TOOL[name][0] for name in local_tools if name in REMOTE_TOOL}
        if not required <= self._remote_tools:
            raise RemoteMCPError("provider-tool-drift")
        self._initialized = True

    def ready(self) -> bool:
        self._initialize()
        return True

    def _web_api(self, method: str, arguments: dict[str, Any]) -> dict[str, Any]:
        response = self._with_retry(
            lambda timeout: self._transport.web_api(
                method,
                arguments,
                self._token,
                timeout,
                self.profile["limits"]["max_bytes"],
            )
        )
        if response.status != 200:
            raise RemoteMCPError("provider-http-failed")
        content_type = (
            response.headers.get("content-type", "").split(";", 1)[0].strip().lower()
        )
        if content_type != "application/json":
            raise RemoteMCPError("provider-content-type-invalid")
        try:
            value = json.loads(response.body.decode("utf-8"))
        except (UnicodeError, json.JSONDecodeError):
            raise RemoteMCPError("provider-response-invalid") from None
        if not isinstance(value, dict) or value.get("ok") is not True:
            raise RemoteMCPError("provider-request-failed")
        return value

    def _prove_link(self, linked_from: str, resource: str) -> None:
        cursor: str | None = None
        seen = 0
        for _page in range(self.profile["limits"]["max_pages"]):
            remaining = self.profile["limits"]["max_items"] - seen
            if remaining <= 0:
                raise RemoteMCPError("provider-items-exceeded")
            arguments: dict[str, Any] = {
                "channel": linked_from,
                "limit": min(remaining, 200),
            }
            if cursor is not None:
                arguments["cursor"] = cursor
            value = self._web_api("conversations.history", arguments)
            messages = value.get("messages")
            if not isinstance(messages, list):
                raise RemoteMCPError("provider-link-proof-invalid")
            seen += len(messages)
            if seen > self.profile["limits"]["max_items"]:
                raise RemoteMCPError("provider-items-exceeded")
            for message in messages:
                if not isinstance(message, dict):
                    raise RemoteMCPError("provider-link-proof-invalid")
                files = message.get("files", [])
                if not isinstance(files, list):
                    raise RemoteMCPError("provider-link-proof-invalid")
                for item in files:
                    if not isinstance(item, dict):
                        raise RemoteMCPError("provider-link-proof-invalid")
                    if item.get("id") == resource:
                        return
            metadata = value.get("response_metadata", {})
            if not isinstance(metadata, dict):
                raise RemoteMCPError("provider-link-proof-invalid")
            next_cursor = metadata.get("next_cursor", "")
            if next_cursor == "":
                break
            if seen >= self.profile["limits"]["max_items"]:
                raise RemoteMCPError("provider-items-exceeded")
            if not isinstance(next_cursor, str) or len(next_cursor) > 4096:
                raise RemoteMCPError("provider-cursor-invalid")
            cursor = next_cursor
        else:
            raise RemoteMCPError("provider-pages-exceeded")
        raise RemoteMCPError("provider-link-not-proven")

    def __call__(self, name: str, arguments: dict[str, Any]) -> object:
        mapping = REMOTE_TOOL.get(name)
        if mapping is None:
            raise RemoteMCPError("provider-tool-denied")
        self._initialize()
        remote_name, argument_names = mapping
        if remote_name not in self._remote_tools:
            raise RemoteMCPError("provider-tool-drift")
        if name in LINK_PROOF_REQUIRED:
            self._prove_link(arguments["linked_from"], arguments["resource"])
        remote_arguments = {
            remote_key: arguments[local_key]
            for local_key, remote_key in argument_names.items()
        }
        if name in {"slack_read_channel", "slack_read_thread"}:
            remote_arguments["limit"] = min(self.profile["limits"]["max_items"], 100)
            remote_arguments["response_format"] = "concise"
        result = self._request(
            "tools/call", {"arguments": remote_arguments, "name": remote_name}
        )
        if result.get("isError") is True:
            raise RemoteMCPError("provider-tool-failed")
        if not isinstance(result.get("content"), list):
            raise RemoteMCPError("provider-tool-result-invalid")
        return result
