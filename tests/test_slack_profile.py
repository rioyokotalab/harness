from __future__ import annotations

import copy
import importlib.util
from pathlib import Path
import sys
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

PROFILE_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_profile", LIBEXEC / "harness_slack_profile.py"
)
assert PROFILE_SPEC is not None and PROFILE_SPEC.loader is not None
PROFILE = importlib.util.module_from_spec(PROFILE_SPEC)
PROFILE_SPEC.loader.exec_module(PROFILE)


def declaration(policy: str = "workspace-visible") -> dict[str, object]:
    value: dict[str, object] = {
        "audit": {"max_bytes": 16777216, "retention_days": 30},
        "capabilities": ["private-channel-read", "public-channel-read"],
        "clients": ["claude", "codex"],
        "contract": "harness-slack-broker-v1",
        "credential_domain": "synthetic-owner-workspace",
        "expected_scopes": ["channels:history", "groups:history"],
        "harness_module_sha256": PROFILE.hashlib.sha256(
            Path(BROKER.__file__).read_bytes()
        ).hexdigest(),
        "harness_revision": "0" * 40,
        "limits": {
            "max_bytes": 1048576,
            "max_items": 200,
            "max_pages": 8,
            "max_read_attempts": 3,
            "max_seconds": 30,
        },
        "migration": "synthetic-only",
        "profile": "synthetic",
        "provider_mode": "web-api",
        "provider_schema": "slack-web-api-2026-08",
        "resource_binding": "workspace-visible-at-runtime",
        "resource_policy": policy,
        "schema": 1,
        "service_identity": "harness_slack_synthetic",
        "socket": "/run/harness-slack-broker/synthetic.sock",
        "writes": "disabled",
    }
    if policy == "exact":
        value["resource_binding"] = "owner-state-exact"
    return value


class SlackRuntimeProfileTests(unittest.TestCase):
    def test_workspace_declaration_renders_no_resource_values(self) -> None:
        runtime = PROFILE.fail_closed_profile(declaration())
        self.assertEqual(runtime["resource_policy"], "workspace-visible")
        self.assertEqual(runtime["resources"], [])
        for key in PROFILE.METADATA_KEYS:
            self.assertNotIn(key, runtime)

    def test_exact_declaration_renders_only_public_unbound_sentinel(self) -> None:
        runtime = PROFILE.fail_closed_profile(declaration("exact"))
        self.assertEqual(runtime["resources"], ["deployment-unbound"])

    def test_metadata_and_module_drift_fail_closed(self) -> None:
        for field, changed in (
            ("harness_module_sha256", "f" * 64),
            ("migration", "live"),
            ("resource_binding", "wrong"),
        ):
            with self.subTest(field=field):
                candidate = copy.deepcopy(declaration())
                candidate[field] = changed
                with self.assertRaises(BROKER.ContractError):
                    PROFILE.fail_closed_profile(candidate)

    def test_unknown_declaration_field_fails_closed(self) -> None:
        candidate = declaration()
        candidate["private_target"] = "synthetic-secret"
        with self.assertRaisesRegex(BROKER.ContractError, "declaration-fields-invalid"):
            PROFILE.fail_closed_profile(candidate)


if __name__ == "__main__":
    unittest.main()
