#!/usr/bin/env python3
"""Revision-pinned Slack broker MCP service and Unix-socket stdio bridge."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import socket
import stat
import sys
from typing import Any, BinaryIO, Callable

import harness_slack_broker as broker


MCP_PROTOCOL = "2025-06-18"
MAX_MESSAGE_BYTES = broker.MAX_JSON_BYTES
TOOL_OPERATION = {
    "slack_read_channel": "read_channel",
    "slack_read_thread": "read_thread",
    "slack_read_linked_canvas": "read_canvas",
    "slack_read_linked_file": "read_file",
    "slack_read_profile": "read_profile",
    "slack_structured_context": "structured_context",
}


class MCPError(ValueError):
    """Stable value-free MCP failure."""


def fail(reason: str) -> None:
    raise MCPError(reason)


def response(request_id: object, result: object) -> dict[str, object]:
    return {"id": request_id, "jsonrpc": "2.0", "result": result}


def error_response(request_id: object, reason: str, code: int = -32600) -> dict[str, object]:
    return {
        "error": {"code": code, "message": reason},
        "id": request_id,
        "jsonrpc": "2.0",
    }


def tool_result(value: object, is_error: bool = False) -> dict[str, object]:
    return {
        "content": [
            {
                "text": broker.canonical_json(value),
                "type": "text",
            }
        ],
        "isError": is_error,
    }


def request_for_tool(profile: dict[str, Any], name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    operation = TOOL_OPERATION.get(name)
    if operation is None:
        fail("tool-unavailable")
    request: dict[str, Any] = {
        "operation": operation,
        "profile": profile["profile"],
        "schema": 1,
    }
    if operation == "structured_context":
        if arguments:
            fail("tool-arguments-invalid")
        return request
    if operation in {"read_channel", "read_profile", "read_thread"}:
        request["resource"] = arguments.get("resource")
    if operation == "read_thread":
        request["thread"] = arguments.get("thread")
    if operation in {"read_canvas", "read_file"}:
        request["linked_from"] = arguments.get("linked_from")
        request["resource"] = arguments.get("resource")
    return request


class MCPServer:
    def __init__(
        self,
        profile: dict[str, Any],
        credential_state: str = "absent",
        provider: Callable[[str, dict[str, Any]], object] | None = None,
    ) -> None:
        if credential_state not in {"absent", "ready"}:
            fail("credential-state-invalid")
        self.profile = profile
        self.credential_state = credential_state
        self.provider = provider
        self.schema = broker.tool_schema(profile, "absent")
        self.tools = {item["name"]: item for item in self.schema["tools"]}

    def handle(self, message: object) -> dict[str, object] | None:
        if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
            return error_response(None, "request-invalid")
        request_id = message.get("id")
        method = message.get("method")
        if not isinstance(method, str):
            return error_response(request_id, "method-invalid")
        if method.startswith("notifications/"):
            return None
        params = message.get("params", {})
        if not isinstance(params, dict):
            return error_response(request_id, "params-invalid", -32602)
        if method == "initialize":
            return response(
                request_id,
                {
                    "capabilities": {"tools": {"listChanged": False}},
                    "protocolVersion": MCP_PROTOCOL,
                    "serverInfo": {"name": "harness-slack-broker", "version": broker.CONTRACT},
                },
            )
        if method == "ping":
            return response(request_id, {})
        if method == "tools/list":
            return response(request_id, {"tools": list(self.tools.values())})
        if method != "tools/call":
            return error_response(request_id, "method-unavailable", -32601)
        if set(params) != {"arguments", "name"}:
            return error_response(request_id, "tool-call-invalid", -32602)
        name = params["name"]
        arguments = params["arguments"]
        if not isinstance(name, str) or not isinstance(arguments, dict) or name not in self.tools:
            return error_response(request_id, "tool-unavailable", -32602)
        if name == "slack_broker_status":
            status = "ready" if self.credential_state == "ready" and self.provider else "renewal-required"
            reason = "accepted" if status == "ready" else "credential-unavailable"
            return response(
                request_id,
                tool_result(
                    {
                        "contract": broker.CONTRACT,
                        "profile": self.profile["profile"],
                        "reason": reason,
                        "schema": 1,
                        "status": status,
                    }
                ),
            )
        if self.credential_state != "ready" or self.provider is None:
            return response(
                request_id,
                tool_result({"reason": "credential-unavailable", "status": "failed"}, True),
            )
        try:
            provider_request = request_for_tool(self.profile, name, arguments)
            decision = broker.authorize(self.profile, provider_request)
            if not decision["allowed"]:
                return response(request_id, tool_result(decision, True))
            result = self.provider(name, arguments)
        except (broker.ContractError, MCPError):
            return response(
                request_id,
                tool_result({"reason": "request-denied", "status": "failed"}, True),
            )
        except Exception:
            return response(
                request_id,
                tool_result({"reason": "provider-failed", "status": "failed"}, True),
            )
        return response(
            request_id,
            tool_result({"trust": "untrusted-context", "value": result}),
        )


def read_message(stream: BinaryIO) -> object | None:
    line = stream.readline(MAX_MESSAGE_BYTES + 1)
    if not line:
        return None
    if len(line) > MAX_MESSAGE_BYTES or not line.endswith(b"\n"):
        fail("message-size-invalid")
    try:
        return json.loads(line.decode("utf-8"))
    except (UnicodeError, json.JSONDecodeError):
        fail("message-json-invalid")


def write_message(stream: BinaryIO, message: dict[str, object]) -> None:
    payload = (broker.canonical_json(message) + "\n").encode("utf-8")
    if len(payload) > MAX_MESSAGE_BYTES:
        fail("response-size-invalid")
    stream.write(payload)
    stream.flush()


def serve_connection(server: MCPServer, stream: BinaryIO) -> None:
    while True:
        try:
            message = read_message(stream)
        except MCPError as exc:
            write_message(stream, error_response(None, str(exc)))
            return
        if message is None:
            return
        result = server.handle(message)
        if result is not None:
            write_message(stream, result)


def serve_listener(server: MCPServer, listener: socket.socket, expected_uid: int) -> None:
    while True:
        connection, _ = listener.accept()
        with connection:
            if hasattr(socket, "SO_PEERCRED"):
                peer = connection.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12)
                peer_uid = int.from_bytes(peer[4:8], sys.byteorder)
                if peer_uid != expected_uid:
                    continue
            stream = connection.makefile("rwb", buffering=0)
            with stream:
                serve_connection(server, stream)


def validate_socket(path: str) -> None:
    try:
        info = os.lstat(path)
    except OSError:
        fail("socket-unavailable")
    if (
        not stat.S_ISSOCK(info.st_mode)
        or info.st_uid != os.getuid()
        or stat.S_IMODE(info.st_mode) != 0o600
    ):
        fail("socket-metadata-invalid")


def relay_stdio(socket_path: str, source: BinaryIO, destination: BinaryIO) -> None:
    validate_socket(socket_path)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.connect(socket_path)
        peer = connection.makefile("rwb", buffering=0)
        with peer:
            while True:
                message = read_message(source)
                if message is None:
                    return
                write_message(peer, message)
                if isinstance(message, dict) and str(message.get("method", "")).startswith("notifications/"):
                    continue
                reply = read_message(peer)
                if not isinstance(reply, dict):
                    fail("service-response-invalid")
                write_message(destination, reply)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)
    service = commands.add_parser("service")
    service.add_argument("--profile", required=True)
    service.add_argument("--client-uid", type=int, required=True)
    service.add_argument("--credential-state", choices=("absent",), default="absent")
    bridge = commands.add_parser("stdio")
    bridge.add_argument("--profile", required=True)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        profile = broker.validate_profile(broker.load_json(args.profile))
        if args.command == "stdio":
            relay_stdio(profile["socket"], sys.stdin.buffer, sys.stdout.buffer)
        else:
            if args.client_uid < 0:
                fail("client-uid-invalid")
            listener = socket.socket(fileno=3)
            serve_listener(MCPServer(profile, args.credential_state), listener, args.client_uid)
    except (broker.ContractError, MCPError, OSError):
        print("SLACK_MCP status=failed reason=runtime-unavailable", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
