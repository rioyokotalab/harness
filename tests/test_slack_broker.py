from __future__ import annotations

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "libexec" / "harness_slack_broker.py"
SPEC = importlib.util.spec_from_file_location("harness_slack_broker", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
BROKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BROKER)


def profile(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "audit": {"max_bytes": 16777216, "retention_days": 30},
        "capabilities": [
            "canvas-read",
            "file-read",
            "private-channel-read",
            "public-channel-read",
            "thread-read",
        ],
        "clients": ["claude", "codex"],
        "contract": "harness-slack-broker-v1",
        "expected_scopes": [
            "canvases:read",
            "channels:history",
            "files:read",
            "groups:history",
        ],
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
        "resources": ["channel-one"],
        "schema": 1,
        "service_identity": "harness_slack_research",
        "socket": "/run/harness-slack-broker/research-read.sock",
        "writes": "disabled",
    }
    value.update(overrides)
    return value


class BrokerContractTests(unittest.TestCase):
    def test_profile_requires_client_parity_and_minimal_scopes(self) -> None:
        accepted = BROKER.validate_profile(profile())
        self.assertEqual(accepted["clients"], ["claude", "codex"])
        for change, reason in (
            ({"clients": ["codex"]}, "client-parity-invalid"),
            ({"expected_scopes": ["channels:history"]}, "expected-scopes-not-minimal"),
        ):
            with self.subTest(reason=reason), self.assertRaisesRegex(
                BROKER.ContractError, reason
            ):
                BROKER.validate_profile(profile(**change))

    def test_external_runtime_cannot_expose_raw_slack_reads(self) -> None:
        with self.assertRaisesRegex(BROKER.ContractError, "external-runtime-raw-read"):
            BROKER.validate_profile(
                profile(
                    capabilities=["public-channel-read"],
                    expected_scopes=[],
                    provider_mode="external-runtime",
                    resource_policy="none",
                    resources=[],
                )
            )

    def test_tool_schema_is_identical_for_both_clients_and_hides_write(self) -> None:
        accepted = BROKER.validate_profile(profile())
        schema = BROKER.tool_schema(accepted, "absent")
        self.assertEqual(schema["clients"], ["claude", "codex"])
        names = [tool["name"] for tool in schema["tools"]]
        self.assertNotIn("slack_send_once", names)
        self.assertTrue(all(tool["inputSchema"]["additionalProperties"] is False for tool in schema["tools"]))
        self.assertTrue(all("untrusted" in tool["description"].lower() for tool in schema["tools"]))

    def test_single_transaction_write_is_exact_and_no_retry(self) -> None:
        accepted = BROKER.validate_profile(
            profile(
                expected_scopes=[
                    "canvases:read",
                    "channels:history",
                    "chat:write",
                    "files:read",
                    "groups:history",
                ],
                writes="single-transaction",
            )
        )
        payload = "synthetic message"
        request = {
            "grant": {
                "payload_sha256": hashlib.sha256(payload.encode()).hexdigest(),
                "state": "fresh",
                "target": "channel-one",
                "transaction_id": "owner-transaction-1",
            },
            "operation": "send_once",
            "payload": payload,
            "profile": "research-read",
            "schema": 1,
            "target": "channel-one",
        }
        self.assertTrue(BROKER.authorize(accepted, request)["allowed"])
        request["target"] = "channel-two"
        self.assertEqual(BROKER.authorize(accepted, request)["reason"], "write-grant-mismatch")
        self.assertEqual(BROKER.retry_plan(accepted, "write", 503, 1, None)["reason"], "write-no-retry")

    def test_exact_channel_and_provider_link_proof(self) -> None:
        accepted = BROKER.validate_profile(profile())
        denied = BROKER.authorize(
            accepted,
            {"operation": "read_channel", "profile": "research-read", "resource": "other", "schema": 1},
        )
        self.assertFalse(denied["allowed"])
        linked = BROKER.authorize(
            accepted,
            {
                "linked_from": "channel-one",
                "operation": "read_file",
                "profile": "research-read",
                "resource": "provider-file-id",
                "schema": 1,
            },
        )
        self.assertEqual(linked["reason"], "provider-link-proof-required")

    def test_read_retry_is_bounded(self) -> None:
        accepted = BROKER.validate_profile(profile())
        self.assertEqual(BROKER.retry_plan(accepted, "read", 429, 1, 17)["wait_seconds"], 17)
        self.assertEqual(BROKER.retry_plan(accepted, "read", 503, 2, None)["wait_seconds"], 2)
        self.assertFalse(BROKER.retry_plan(accepted, "read", 503, 3, None)["retry"])

    def test_doctor_classifies_profile_local_failures(self) -> None:
        accepted = BROKER.validate_profile(profile())
        state = {
            "actual_scopes": accepted["expected_scopes"],
            "audit": "ready",
            "credential": "ready",
            "provider_schema": accepted["provider_schema"],
            "schema": 1,
            "socket": "ready",
        }
        self.assertEqual(BROKER.doctor(accepted, state)["status"], "ready")
        state["credential"] = "expired"
        self.assertEqual(BROKER.doctor(accepted, state)["status"], "renewal-required")
        state["credential"] = "ready"
        state["actual_scopes"] = []
        self.assertEqual(BROKER.doctor(accepted, state)["reason"], "scope-drift")

    def test_rotation_stops_on_ambiguous_exchange(self) -> None:
        accepted = BROKER.validate_profile(profile())
        result = BROKER.rotation_plan(
            accepted,
            {"phase": "exchange-ambiguous", "prior_access_valid": True, "staged_valid": False},
        )
        self.assertEqual(result["action"], "stop-no-retry")

    def test_audit_is_value_free_and_bounded(self) -> None:
        accepted = BROKER.validate_profile(profile())
        event = {
            "attempt": 1,
            "capability": "read-channel",
            "item_count": 2,
            "latency_ms": 10,
            "outcome": "complete",
            "reason": "accepted",
            "schema": 1,
            "time": "2026-08-06T15:00:00Z",
        }
        self.assertEqual(BROKER.validate_audit(accepted, event)["retention_days"], 30)
        event["content"] = "forbidden"
        with self.assertRaisesRegex(BROKER.ContractError, "audit-fields-invalid"):
            BROKER.validate_audit(accepted, event)

    def test_config_loader_rejects_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "profile.json"
            target.write_text(json.dumps(profile()), encoding="utf-8")
            target.chmod(0o600)
            link = Path(directory) / "link.json"
            link.symlink_to(target)
            with self.assertRaisesRegex(BROKER.ContractError, "file-metadata-unsafe"):
                BROKER.load_json(str(link))

    def test_cli_returns_value_free_failure(self) -> None:
        result = subprocess.run(
            [str(ROOT / "libexec" / "harness-slack-broker"), "validate-profile", "--config", "/definitely/absent"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stderr.strip(), "SLACK_BROKER status=failed reason=file-unavailable")


if __name__ == "__main__":
    unittest.main()
