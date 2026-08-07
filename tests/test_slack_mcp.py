from __future__ import annotations

import importlib.util
import io
import json
import os
from pathlib import Path
import socket
import sys
import tempfile
import threading
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
LIBEXEC = ROOT / "libexec"
sys.path.insert(0, str(LIBEXEC))

BROKER_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_broker", LIBEXEC / "harness_slack_broker.py"
)
assert BROKER_SPEC is not None and BROKER_SPEC.loader is not None
BROKER = importlib.util.module_from_spec(BROKER_SPEC)
sys.modules["harness_slack_broker"] = BROKER
BROKER_SPEC.loader.exec_module(BROKER)

MCP_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_mcp", LIBEXEC / "harness_slack_mcp.py"
)
assert MCP_SPEC is not None and MCP_SPEC.loader is not None
MCP = importlib.util.module_from_spec(MCP_SPEC)
MCP_SPEC.loader.exec_module(MCP)


def profile() -> dict[str, object]:
    return BROKER.validate_profile(
        {
            "audit": {"max_bytes": 16777216, "retention_days": 30},
            "capabilities": ["private-channel-read", "public-channel-read", "thread-read"],
            "clients": ["claude", "codex"],
            "contract": "harness-slack-broker-v1",
            "expected_scopes": ["channels:history", "groups:history"],
            "limits": {
                "max_bytes": 1048576,
                "max_items": 200,
                "max_pages": 8,
                "max_read_attempts": 3,
                "max_seconds": 30,
            },
            "profile": "research-read",
            "provider_mode": "web-api",
            "provider_schema": "slack-web-api-2026-08",
            "resource_policy": "exact",
            "resources": ["allowed-channel"],
            "schema": 1,
            "service_identity": "harness_slack_research",
            "socket": "/run/harness-slack-broker/research-read.sock",
            "writes": "disabled",
        }
    )


def request(identifier: int, method: str, params: dict[str, object] | None = None) -> dict[str, object]:
    value: dict[str, object] = {"id": identifier, "jsonrpc": "2.0", "method": method}
    if params is not None:
        value["params"] = params
    return value


class SlackMCPTests(unittest.TestCase):
    def test_runtime_reason_preserves_only_stable_value_free_classes(self) -> None:
        self.assertEqual(
            MCP.stable_runtime_reason(MCP.MCPError("provider-tool-drift")),
            "provider-tool-drift",
        )
        self.assertEqual(
            MCP.stable_runtime_reason(MCP.MCPError("private value")),
            "runtime-unavailable",
        )

    def test_stdio_cli_accepts_only_socket_descriptor(self) -> None:
        with mock.patch.object(
            sys, "argv", ["harness_slack_mcp.py", "stdio", "--socket", "/tmp/test.sock"]
        ):
            args = MCP.parser().parse_args()
        self.assertEqual(args.socket, "/tmp/test.sock")
        with mock.patch.object(
            sys,
            "argv",
            ["harness_slack_mcp.py", "stdio", "--profile", "/tmp/profile.json"],
        ), mock.patch("sys.stderr", new=io.StringIO()):
            with self.assertRaises(SystemExit):
                MCP.parser().parse_args()

    def test_initialize_and_tool_listing_are_client_neutral(self) -> None:
        server = MCP.MCPServer(profile())
        initialized = server.handle(request(1, "initialize", {}))
        self.assertEqual(initialized["result"]["protocolVersion"], "2025-06-18")
        listing = server.handle(request(2, "tools/list", {}))
        names = [item["name"] for item in listing["result"]["tools"]]
        self.assertIn("slack_broker_status", names)
        self.assertNotIn("slack_send_once", names)

    def test_fail_closed_service_keeps_status_but_denies_reads(self) -> None:
        server = MCP.MCPServer(profile())
        status = server.handle(
            request(1, "tools/call", {"arguments": {}, "name": "slack_broker_status"})
        )
        status_value = json.loads(status["result"]["content"][0]["text"])
        self.assertEqual(status_value["status"], "renewal-required")
        denied = server.handle(
            request(
                2,
                "tools/call",
                {"arguments": {"resource": "allowed-channel"}, "name": "slack_read_channel"},
            )
        )
        self.assertTrue(denied["result"]["isError"])

    def test_provider_result_is_untrusted_and_cross_profile_read_is_denied(self) -> None:
        calls: list[tuple[str, dict[str, object]]] = []

        def provider(name: str, arguments: dict[str, object]) -> object:
            calls.append((name, arguments))
            return {"synthetic": "context"}

        server = MCP.MCPServer(profile(), "ready", provider)
        accepted = server.handle(
            request(
                1,
                "tools/call",
                {"arguments": {"resource": "allowed-channel"}, "name": "slack_read_channel"},
            )
        )
        accepted_value = json.loads(accepted["result"]["content"][0]["text"])
        self.assertEqual(accepted_value["trust"], "untrusted-context")
        self.assertEqual(len(calls), 1)
        denied = server.handle(
            request(
                2,
                "tools/call",
                {"arguments": {"resource": "other-channel"}, "name": "slack_read_channel"},
            )
        )
        self.assertTrue(denied["result"]["isError"])
        self.assertEqual(len(calls), 1)

    def test_provider_exception_is_value_free(self) -> None:
        def provider(_name: str, _arguments: dict[str, object]) -> object:
            raise RuntimeError("synthetic-private-provider-value")

        server = MCP.MCPServer(profile(), "ready", provider)
        result = server.handle(
            request(
                1,
                "tools/call",
                {"arguments": {"resource": "allowed-channel"}, "name": "slack_read_channel"},
            )
        )
        serialized = json.dumps(result)
        self.assertNotIn("synthetic-private-provider-value", serialized)
        self.assertIn("provider-failed", serialized)

    def test_audit_failure_suppresses_provider_result(self) -> None:
        class FailingAudit:
            def write(self, *_arguments: object) -> None:
                raise MCP.audit_log.AuditError("synthetic-audit-private-value")

        server = MCP.MCPServer(
            profile(),
            "ready",
            lambda _name, _arguments: {"synthetic": "private-provider-value"},
            FailingAudit(),
        )
        result = server.handle(
            request(
                1,
                "tools/call",
                {"arguments": {"resource": "allowed-channel"}, "name": "slack_read_channel"},
            )
        )
        serialized = json.dumps(result)
        self.assertIn("audit-unavailable", serialized)
        self.assertNotIn("private-provider-value", serialized)
        self.assertNotIn("synthetic-audit-private-value", serialized)

    def test_status_checks_provider_readiness_without_leaking_failure(self) -> None:
        class UnreadyProvider:
            def ready(self) -> bool:
                raise RuntimeError("synthetic-private-provider-value")

            def __call__(self, _name: str, _arguments: dict[str, object]) -> object:
                raise AssertionError("not called")

        server = MCP.MCPServer(profile(), "ready", UnreadyProvider())
        status = server.handle(
            request(1, "tools/call", {"arguments": {}, "name": "slack_broker_status"})
        )
        serialized = json.dumps(status)
        self.assertIn("repair-required", serialized)
        self.assertIn("provider-unavailable", serialized)
        self.assertNotIn("synthetic-private-provider-value", serialized)

    def test_status_preserves_only_known_provider_failure_class(self) -> None:
        class UnreadyProvider:
            def ready(self) -> bool:
                raise MCP.remote_mcp.RemoteMCPError("provider-tool-drift")

            def __call__(self, _name: str, _arguments: dict[str, object]) -> object:
                raise AssertionError("not called")

        server = MCP.MCPServer(profile(), "ready", UnreadyProvider())
        status = server.handle(
            request(1, "tools/call", {"arguments": {}, "name": "slack_broker_status"})
        )
        serialized = json.dumps(status)
        self.assertIn("repair-required", serialized)
        self.assertIn("provider-tool-drift", serialized)

    def test_stdio_bridge_relays_newline_delimited_json_rpc(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            socket_path = str(Path(directory) / "broker.sock")
            listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            listener.bind(socket_path)
            os.chmod(socket_path, 0o600)
            listener.listen(1)

            def serve_once() -> None:
                connection, _ = listener.accept()
                with connection:
                    stream = connection.makefile("rwb", buffering=0)
                    with stream:
                        message = MCP.read_message(stream)
                        MCP.write_message(stream, {"id": message["id"], "jsonrpc": "2.0", "result": {}})

            thread = threading.Thread(target=serve_once)
            thread.start()
            source = io.BytesIO((json.dumps(request(1, "ping")) + "\n").encode())
            destination = io.BytesIO()
            MCP.relay_stdio(socket_path, source, destination)
            thread.join(timeout=2)
            listener.close()
            self.assertFalse(thread.is_alive())
            self.assertEqual(json.loads(destination.getvalue()), {"id": 1, "jsonrpc": "2.0", "result": {}})


if __name__ == "__main__":
    unittest.main()
