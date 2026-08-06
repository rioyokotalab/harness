from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
LIBEXEC = ROOT / "libexec"
sys.path.insert(0, str(LIBEXEC))
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_audit", LIBEXEC / "harness_slack_audit.py"
)
assert SPEC is not None and SPEC.loader is not None
AUDIT = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_audit"] = AUDIT
SPEC.loader.exec_module(AUDIT)


def profile(max_bytes: int = 4096, retention_days: int = 30) -> dict[str, object]:
    return {
        "audit": {"max_bytes": max_bytes, "retention_days": retention_days},
        "capabilities": ["public-channel-read"],
        "clients": ["claude", "codex"],
        "contract": "harness-slack-broker-v1",
        "expected_scopes": ["channels:history"],
        "limits": {
            "max_bytes": 1048576,
            "max_items": 200,
            "max_pages": 8,
            "max_read_attempts": 3,
            "max_seconds": 30,
        },
        "profile": "personal",
        "provider_mode": "web-api",
        "provider_schema": "slack-web-api-2026-08",
        "resource_policy": "workspace-visible",
        "resources": [],
        "schema": 1,
        "service_identity": "harness_slack_personal",
        "socket": "/run/harness-slack-broker/personal.sock",
        "writes": "disabled",
    }


class SlackAuditTests(unittest.TestCase):
    def test_writer_records_only_exact_value_free_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            directory.chmod(0o700)
            path = directory / "audit.jsonl"
            writer = AUDIT.AuditLog(profile(), str(path))
            writer.write("read-channel", "complete", "accepted", time.monotonic())
            value = json.loads(path.read_text(encoding="ascii"))
            self.assertEqual(
                set(value),
                {"attempt", "capability", "item_count", "latency_ms", "outcome", "reason", "schema", "time"},
            )
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_writer_truncates_at_age_or_total_size_ceiling(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            directory.chmod(0o700)
            path = directory / "audit.jsonl"
            writer = AUDIT.AuditLog(profile(), str(path))
            writer.write("read-channel", "complete", "accepted", time.monotonic())
            with path.open("a", encoding="ascii") as stream:
                stream.write("x" * 4000)
            writer.write("read-channel", "complete", "accepted", time.monotonic())
            self.assertLess(path.stat().st_size, 4096)
            first = json.loads(path.read_text(encoding="ascii"))
            first["time"] = "2020-01-01T00:00:00Z"
            path.write_text(json.dumps(first, separators=(",", ":")) + "\n", encoding="ascii")
            path.chmod(0o600)
            writer.write("read-channel", "complete", "accepted", time.monotonic())
            self.assertEqual(len(path.read_text(encoding="ascii").splitlines()), 1)


if __name__ == "__main__":
    unittest.main()
