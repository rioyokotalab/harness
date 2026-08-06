from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest


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

REMOTE_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_mcp_remote", LIBEXEC / "harness_slack_mcp_remote.py"
)
assert REMOTE_SPEC is not None and REMOTE_SPEC.loader is not None
REMOTE = importlib.util.module_from_spec(REMOTE_SPEC)
sys.modules["harness_slack_mcp_remote"] = REMOTE
REMOTE_SPEC.loader.exec_module(REMOTE)


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


def linked_profile() -> dict[str, object]:
    value = profile()
    value["capabilities"] = [
        "file-read",
        "private-channel-read",
        "public-channel-read",
        "thread-read",
    ]
    value["expected_scopes"] = ["channels:history", "files:read", "groups:history"]
    return BROKER.validate_profile(value)


def response(identifier: int, result: dict[str, object], **headers: str) -> object:
    return REMOTE.HTTPResponse(
        200,
        {"content-type": "application/json", **headers},
        json.dumps({"id": identifier, "jsonrpc": "2.0", "result": result}).encode(),
    )


class ScriptedTransport:
    def __init__(self, replies: list[object], web_replies: list[object] | None = None) -> None:
        self.replies = replies
        self.web_replies = web_replies or []
        self.calls: list[dict[str, object]] = []
        self.web_calls: list[dict[str, object]] = []

    def post(
        self,
        body: bytes,
        token: str,
        session_id: str | None,
        timeout: int,
        max_bytes: int,
    ) -> object:
        self.calls.append(
            {
                "body": json.loads(body),
                "session_id": session_id,
                "timeout": timeout,
                "max_bytes": max_bytes,
                "token_matches": token == "synthetic-token-value",
            }
        )
        reply = self.replies.pop(0)
        if isinstance(reply, Exception):
            raise reply
        return reply

    def web_api(
        self,
        method: str,
        arguments: dict[str, object],
        token: str,
        timeout: int,
        max_bytes: int,
    ) -> object:
        self.web_calls.append(
            {
                "arguments": arguments,
                "method": method,
                "token_matches": token == "synthetic-token-value",
                "timeout": timeout,
                "max_bytes": max_bytes,
            }
        )
        reply = self.web_replies.pop(0)
        if isinstance(reply, Exception):
            raise reply
        return reply


class SlackRemoteMCPTests(unittest.TestCase):
    def test_initialize_session_inventory_and_channel_mapping(self) -> None:
        transport = ScriptedTransport(
            [
                response(1, {"protocolVersion": "2025-06-18"}, **{"mcp-session-id": "session-1"}),
                REMOTE.HTTPResponse(202, {"mcp-session-id": "session-1"}, b""),
                response(
                    2,
                    {
                        "tools": [
                            {"name": "slack_read_channel"},
                            {"name": "slack_read_thread"},
                            {"name": "slack_send_message"},
                        ]
                    },
                ),
                response(3, {"content": [{"text": "synthetic", "type": "text"}]}),
            ]
        )
        provider = REMOTE.SlackRemoteMCP(
            profile(), "synthetic-token-value", transport=transport
        )
        result = provider("slack_read_channel", {"resource": "allowed-channel"})
        self.assertEqual(result["content"][0]["text"], "synthetic")
        self.assertEqual(
            [call["session_id"] for call in transport.calls],
            [None, "session-1", "session-1", "session-1"],
        )
        self.assertTrue(all(call["token_matches"] for call in transport.calls))
        tool_call = transport.calls[-1]["body"]
        self.assertEqual(tool_call["params"]["name"], "slack_read_channel")
        self.assertEqual(
            tool_call["params"]["arguments"],
            {"channel_id": "allowed-channel", "limit": 100, "response_format": "concise"},
        )

    def test_missing_required_upstream_tool_fails_closed(self) -> None:
        transport = ScriptedTransport(
            [
                response(1, {"protocolVersion": "2025-06-18"}),
                REMOTE.HTTPResponse(202, {}, b""),
                response(2, {"tools": [{"name": "slack_read_channel"}]}),
            ]
        )
        provider = REMOTE.SlackRemoteMCP(
            profile(), "synthetic-token-value", transport=transport
        )
        with self.assertRaisesRegex(REMOTE.RemoteMCPError, "provider-tool-drift"):
            provider("slack_read_channel", {"resource": "allowed-channel"})

    def test_linked_read_requires_structured_web_api_proof_before_mcp_call(self) -> None:
        transport = ScriptedTransport(
            [
                response(1, {"protocolVersion": "2025-06-18"}),
                REMOTE.HTTPResponse(202, {}, b""),
                response(
                    2,
                    {"tools": [
                        {"name": "slack_read_channel"},
                        {"name": "slack_read_file"},
                        {"name": "slack_read_thread"},
                    ]},
                ),
                response(3, {"content": [{"text": "synthetic-file", "type": "text"}]}),
            ],
            [
                REMOTE.HTTPResponse(
                    200,
                    {"content-type": "application/json"},
                    json.dumps(
                        {
                            "messages": [{"files": [{"id": "file-1"}]}],
                            "ok": True,
                            "response_metadata": {"next_cursor": ""},
                        }
                    ).encode(),
                )
            ],
        )
        provider = REMOTE.SlackRemoteMCP(
            linked_profile(), "synthetic-token-value", transport=transport
        )
        result = provider(
            "slack_read_linked_file",
            {"linked_from": "allowed-channel", "resource": "file-1"},
        )
        self.assertEqual(result["content"][0]["text"], "synthetic-file")
        self.assertEqual(transport.web_calls[0]["method"], "conversations.history")
        self.assertEqual(
            transport.web_calls[0]["arguments"],
            {"channel": "allowed-channel", "limit": 200},
        )

    def test_unstructured_text_cannot_satisfy_link_proof(self) -> None:
        transport = ScriptedTransport(
            [
                response(1, {"protocolVersion": "2025-06-18"}),
                REMOTE.HTTPResponse(202, {}, b""),
                response(2, {"tools": [
                    {"name": "slack_read_channel"},
                    {"name": "slack_read_file"},
                    {"name": "slack_read_thread"},
                ]}),
            ],
            [REMOTE.HTTPResponse(
                200,
                {"content-type": "application/json"},
                json.dumps({
                    "messages": [{"files": [], "text": "untrusted file-1 mention"}],
                    "ok": True,
                    "response_metadata": {"next_cursor": ""},
                }).encode(),
            )],
        )
        provider = REMOTE.SlackRemoteMCP(
            linked_profile(), "synthetic-token-value", transport=transport
        )
        with self.assertRaisesRegex(REMOTE.RemoteMCPError, "provider-link-not-proven"):
            provider(
                "slack_read_linked_file",
                {"linked_from": "allowed-channel", "resource": "file-1"},
            )
        self.assertEqual(len(transport.calls), 3)

    def test_link_proof_stops_before_fetching_beyond_item_ceiling(self) -> None:
        bounded = linked_profile()
        bounded["limits"]["max_items"] = 1
        transport = ScriptedTransport(
            [
                response(1, {"protocolVersion": "2025-06-18"}),
                REMOTE.HTTPResponse(202, {}, b""),
                response(2, {"tools": [
                    {"name": "slack_read_channel"},
                    {"name": "slack_read_file"},
                    {"name": "slack_read_thread"},
                ]}),
            ],
            [REMOTE.HTTPResponse(
                200,
                {"content-type": "application/json"},
                json.dumps({
                    "messages": [{"files": []}],
                    "ok": True,
                    "response_metadata": {"next_cursor": "more"},
                }).encode(),
            )],
        )
        provider = REMOTE.SlackRemoteMCP(
            bounded, "synthetic-token-value", transport=transport
        )
        with self.assertRaisesRegex(REMOTE.RemoteMCPError, "provider-items-exceeded"):
            provider(
                "slack_read_linked_file",
                {"linked_from": "allowed-channel", "resource": "file-1"},
            )
        self.assertEqual(len(transport.web_calls), 1)

    def test_rate_limit_uses_bounded_read_retry_plan(self) -> None:
        waits: list[float] = []
        transport = ScriptedTransport(
            [
                REMOTE.HTTPFailure(429, 2),
                response(1, {"protocolVersion": "2025-06-18"}),
                REMOTE.HTTPResponse(202, {}, b""),
                response(
                    2,
                    {"tools": [{"name": "slack_read_channel"}, {"name": "slack_read_thread"}]},
                ),
                response(3, {"content": []}),
            ]
        )
        provider = REMOTE.SlackRemoteMCP(
            profile(), "synthetic-token-value", transport=transport, sleeper=waits.append
        )
        provider("slack_read_channel", {"resource": "allowed-channel"})
        self.assertEqual(waits, [2])

    def test_rate_limit_cannot_exceed_total_time_budget(self) -> None:
        waits: list[float] = []
        transport = ScriptedTransport([REMOTE.HTTPFailure(429, 30)])
        provider = REMOTE.SlackRemoteMCP(
            profile(), "synthetic-token-value", transport=transport, sleeper=waits.append
        )
        with self.assertRaisesRegex(
            REMOTE.RemoteMCPError, "provider-time-budget-exceeded"
        ):
            provider("slack_read_channel", {"resource": "allowed-channel"})
        self.assertEqual(waits, [])

    def test_sse_response_is_bounded_and_selects_matching_id(self) -> None:
        payload = (
            'event: message\ndata: {"jsonrpc":"2.0","method":"notifications/progress"}\n\n'
            'event: message\ndata: {"id":7,"jsonrpc":"2.0","result":{}}\n\n'
        ).encode()
        parsed = REMOTE._parse_json_response(
            REMOTE.HTTPResponse(200, {"content-type": "text/event-stream"}, payload), 7
        )
        self.assertEqual(parsed["result"], {})

    def test_credential_reader_rejects_symlink_and_permissive_mode(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "token"
            target.write_text("synthetic-token-value", encoding="utf-8")
            os.chmod(target, 0o600)
            self.assertEqual(REMOTE.read_credential(str(target)), "synthetic-token-value")
            os.chmod(target, 0o640)
            with self.assertRaisesRegex(REMOTE.RemoteMCPError, "credential-metadata-unsafe"):
                REMOTE.read_credential(str(target))
            os.chmod(target, 0o600)
            link = Path(directory) / "link"
            link.symlink_to(target)
            with self.assertRaisesRegex(REMOTE.RemoteMCPError, "credential-unavailable"):
                REMOTE.read_credential(str(link))

    def test_remote_errors_never_preserve_provider_values(self) -> None:
        body = json.dumps(
            {
                "error": {"code": -32000, "message": "synthetic-private-value"},
                "id": 1,
                "jsonrpc": "2.0",
            }
        ).encode()
        with self.assertRaisesRegex(REMOTE.RemoteMCPError, "provider-request-failed") as caught:
            REMOTE._parse_json_response(
                REMOTE.HTTPResponse(200, {"content-type": "application/json"}, body), 1
            )
        self.assertNotIn("synthetic-private-value", str(caught.exception))

    def test_url_transport_pins_origin_and_protocol_headers(self) -> None:
        class FakeResponse:
            status = 200
            headers = {"Content-Type": "application/json"}

            def __enter__(self) -> object:
                return self

            def __exit__(self, *_args: object) -> None:
                return None

            def read(self, _limit: int) -> bytes:
                return b"{}"

        class FakeOpener:
            def __init__(self) -> None:
                self.request: object | None = None

            def open(self, request: object, timeout: int) -> object:
                self.request = request
                self.timeout = timeout
                return FakeResponse()

        transport = REMOTE.URLTransport()
        opener = FakeOpener()
        transport.opener = opener
        transport.post(b"{}", "synthetic-token-value", "session-1", 7, 1024)
        self.assertEqual(opener.request.full_url, "https://mcp.slack.com/mcp")
        self.assertEqual(opener.request.get_method(), "POST")
        self.assertEqual(opener.request.get_header("Authorization"), "Bearer synthetic-token-value")
        self.assertEqual(opener.request.get_header("Mcp-session-id"), "session-1")
        self.assertEqual(opener.request.get_header("Mcp-protocol-version"), "2025-06-18")

    def test_url_transport_rejects_unapproved_web_api_method(self) -> None:
        transport = REMOTE.URLTransport()
        with self.assertRaisesRegex(REMOTE.RemoteMCPError, "provider-web-method-denied"):
            transport.web_api(
                "chat.postMessage", {}, "synthetic-token-value", 7, 1024
            )


if __name__ == "__main__":
    unittest.main()
