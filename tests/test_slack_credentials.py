from __future__ import annotations

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

CREDENTIAL_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_credentials", LIBEXEC / "harness_slack_credentials.py"
)
assert CREDENTIAL_SPEC is not None and CREDENTIAL_SPEC.loader is not None
CREDENTIALS = importlib.util.module_from_spec(CREDENTIAL_SPEC)
CREDENTIAL_SPEC.loader.exec_module(CREDENTIALS)


def profile(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "audit": {"max_bytes": 16777216, "retention_days": 30},
        "capabilities": [
            "canvas-read",
            "file-read",
            "private-channel-read",
            "profile-read",
            "public-channel-read",
            "thread-read",
        ],
        "clients": ["claude", "codex"],
        "contract": "harness-slack-broker-v1",
        "expected_scopes": [
            "canvases:read",
            "channels:history",
            "chat:write",
            "files:read",
            "groups:history",
            "users:read",
        ],
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
        "writes": "single-transaction",
    }
    value.update(overrides)
    return value


def plan(current_profile: dict[str, object], topology: str = "user-read-bot-write") -> dict[str, object]:
    if topology == "user-read-bot-write":
        read = {
            "credential": "slack-access-read",
            "kind": "user",
            "scopes": sorted(set(current_profile["expected_scopes"]) - {"chat:write"}),
        }
        write = {"credential": "slack-access-write", "kind": "bot", "scopes": ["chat:write"]}
        exposure = {
            "read_rotator": ["slack-client-secret", "slack-refresh-read"],
            "read_service": ["slack-access-read"],
            "write_rotator": ["slack-client-secret", "slack-refresh-write"],
            "write_transaction": ["slack-access-write"],
        }
        rotation = {
            "access_ttl_seconds": 43200,
            "enabled": True,
            "rollback_generations": 1,
            "rotate_after_seconds": 28800,
            "triggers": ["boot", "resume", "timer"],
        }
    elif topology == "bot-read":
        read = {
            "credential": "slack-access-read",
            "kind": "bot",
            "scopes": current_profile["expected_scopes"],
        }
        write = {"credential": None, "kind": "none", "scopes": []}
        exposure = {
            "read_rotator": ["slack-client-secret", "slack-refresh-read"],
            "read_service": ["slack-access-read"],
            "write_rotator": [],
            "write_transaction": [],
        }
        rotation = {
            "access_ttl_seconds": 43200,
            "enabled": True,
            "rollback_generations": 1,
            "rotate_after_seconds": 28800,
            "triggers": ["boot", "resume", "timer"],
        }
    else:
        read = write = {"credential": None, "kind": "none", "scopes": []}
        exposure = {key: [] for key in CREDENTIALS.EXPOSURE_KEYS}
        rotation = {
            "access_ttl_seconds": 0,
            "enabled": False,
            "rollback_generations": 0,
            "rotate_after_seconds": 0,
            "triggers": [],
        }
    return {
        "contract": "harness-slack-credentials-v1",
        "custodian": "root-systemd-creds",
        "exposure": exposure,
        "profile": current_profile["profile"],
        "profile_sha256": CREDENTIALS.profile_digest(current_profile),
        "read": read,
        "rotation": rotation,
        "schema": 1,
        "topology": topology,
        "write": write,
    }


class SlackCredentialTests(unittest.TestCase):
    def test_personal_separates_steady_read_and_transient_write(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile))
        self.assertEqual(accepted["read"]["kind"], "user")
        self.assertEqual(accepted["write"]["kind"], "bot")
        self.assertFalse(
            set(accepted["exposure"]["read_service"]).intersection(
                accepted["exposure"]["write_transaction"]
            )
        )

    def test_plan_is_pinned_to_exact_profile_bytes(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        candidate = plan(current_profile)
        candidate["profile_sha256"] = "0" * 64
        with self.assertRaisesRegex(BROKER.ContractError, "credential-profile-digest-mismatch"):
            CREDENTIALS.validate_plan(current_profile, candidate)

    def test_collapsed_personal_token_is_rejected(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        candidate = plan(current_profile)
        candidate["write"]["credential"] = "slack-access-read"
        with self.assertRaisesRegex(BROKER.ContractError, "credential-topology-profile-mismatch"):
            CREDENTIALS.validate_plan(current_profile, candidate)

    def test_swallow_bot_read_has_no_write_credential(self) -> None:
        current_profile = BROKER.validate_profile(
            profile(
                capabilities=[
                    "canvas-read",
                    "file-read",
                    "private-channel-read",
                    "public-channel-read",
                    "thread-read",
                ],
                expected_scopes=["canvases:read", "channels:history", "files:read", "groups:history"],
                profile="swallow",
                resource_policy="exact",
                resources=["project-channel"],
                service_identity="harness_slack_swallow",
                socket="/run/harness-slack-broker/swallow.sock",
                writes="disabled",
            )
        )
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile, "bot-read"))
        self.assertEqual(accepted["write"]["kind"], "none")
        self.assertEqual(accepted["exposure"]["write_transaction"], [])

    def test_students_external_adapter_has_no_slack_credential(self) -> None:
        current_profile = BROKER.validate_profile(
            profile(
                capabilities=["structured-mentoring"],
                expected_scopes=[],
                profile="students",
                provider_mode="external-runtime",
                resource_policy="none",
                resources=[],
                service_identity="harness_slack_students",
                socket="/run/harness-slack-broker/students.sock",
                writes="disabled",
            )
        )
        accepted = CREDENTIALS.validate_plan(
            current_profile, plan(current_profile, "external-structured")
        )
        self.assertTrue(all(not values for values in accepted["exposure"].values()))

    def test_boot_and_resume_recover_expired_access_once(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile))
        for trigger in ("boot", "resume"):
            result = CREDENTIALS.rotation_decision(
                accepted,
                "read",
                {
                    "access_age_seconds": 43200,
                    "access_state": "expired",
                    "refresh_state": "available",
                    "trigger": trigger,
                },
            )
            self.assertEqual(result["action"], "exchange-once")

    def test_current_access_does_not_rotate_early(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile))
        result = CREDENTIALS.rotation_decision(
            accepted,
            "read",
            {
                "access_age_seconds": 100,
                "access_state": "ready",
                "refresh_state": "available",
                "trigger": "boot",
            },
        )
        self.assertEqual(result["action"], "none")

    def test_ambiguous_refresh_stops_without_retry(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile))
        result = CREDENTIALS.rotation_decision(
            accepted,
            "write",
            {
                "access_age_seconds": 30000,
                "access_state": "ready",
                "refresh_state": "ambiguous",
                "trigger": "timer",
            },
        )
        self.assertEqual(result["action"], "stop-no-retry")

    def test_write_requires_fresh_bot_membership_readback(self) -> None:
        current_profile = BROKER.validate_profile(profile())
        accepted = CREDENTIALS.validate_plan(current_profile, plan(current_profile))
        state = {
            "bot_membership": False,
            "grant_matches": True,
            "provider_identity": True,
            "target_matches": True,
            "transaction_state": "fresh",
        }
        self.assertEqual(
            CREDENTIALS.write_preflight(accepted, state)["reason"], "write-bot-not-member"
        )
        state["bot_membership"] = True
        self.assertEqual(
            CREDENTIALS.write_preflight(accepted, state)["reason"],
            "consume-before-single-attempt",
        )


if __name__ == "__main__":
    unittest.main()
