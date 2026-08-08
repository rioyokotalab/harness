from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
LIBEXEC = ROOT / "libexec"
sys.path.insert(0, str(LIBEXEC))
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_swallow_install", LIBEXEC / "harness_slack_swallow_install.py"
)
assert SPEC is not None and SPEC.loader is not None
INSTALL = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_swallow_install"] = INSTALL
SPEC.loader.exec_module(INSTALL)
OAUTH_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_oauth_for_swallow_install_test",
    LIBEXEC / "harness_slack_oauth.py",
)
assert OAUTH_SPEC is not None and OAUTH_SPEC.loader is not None
OAUTH = importlib.util.module_from_spec(OAUTH_SPEC)
OAUTH_SPEC.loader.exec_module(OAUTH)


def unbound_profile() -> dict[str, object]:
    return {
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
        "profile": "swallow",
        "provider_mode": "web-api",
        "provider_schema": "slack-web-api-2026-08",
        "resource_policy": "exact",
        "resources": ["deployment-unbound"],
        "schema": 1,
        "service_identity": "harness_slack_swallow",
        "socket": "/run/harness-slack-broker/swallow.sock",
        "writes": "disabled",
    }


class SlackSwallowInstallTests(unittest.TestCase):
    def test_resource_binding_is_hidden_atomic_exact_and_stable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            profile = Path(temporary) / "swallow.json"
            profile.write_text(json.dumps(unbound_profile()) + "\n", encoding="utf-8")
            profile.chmod(0o644)
            actions: list[tuple[str, ...]] = []
            sleeps: list[float] = []
            with (
                mock.patch.object(INSTALL, "PROFILE_SOURCE", profile),
                mock.patch.object(
                    INSTALL.common, "protected_revision", return_value="a" * 40
                ),
            ):
                INSTALL.bind_resource(
                    "C12345678",
                    systemctl_action=lambda *args: actions.append(args),
                    sleeper=sleeps.append,
                    owner_uid=os.geteuid(),
                )
            value = json.loads(profile.read_text(encoding="utf-8"))
            self.assertEqual(value["resources"], ["C12345678"])
            self.assertEqual(profile.stat().st_mode & 0o777, 0o600)
            self.assertEqual(
                actions,
                [
                    ("restart", "harness-slack-swallow.service"),
                    ("is-active", "--quiet", "harness-slack-swallow.service"),
                    ("is-active", "--quiet", "harness-slack-swallow.service"),
                ],
            )
            self.assertEqual(sleeps, [1.0])

    def test_resource_binding_rejects_invalid_and_non_unbound_state(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            profile = Path(temporary) / "swallow.json"
            original = json.dumps(unbound_profile()) + "\n"
            profile.write_text(original, encoding="utf-8")
            with (
                mock.patch.object(INSTALL, "PROFILE_SOURCE", profile),
                mock.patch.object(
                    INSTALL.common, "protected_revision", return_value="a" * 40
                ),
            ):
                with self.assertRaisesRegex(INSTALL.SwallowInstallError, "resource-invalid"):
                    INSTALL.bind_resource("private/value", owner_uid=os.geteuid())
                value = unbound_profile()
                value["resources"] = ["C12345678"]
                profile.write_text(json.dumps(value) + "\n", encoding="utf-8")
                with self.assertRaisesRegex(INSTALL.SwallowInstallError, "profile-invalid"):
                    INSTALL.bind_resource("C87654321", owner_uid=os.geteuid())
            self.assertIn("C12345678", profile.read_text(encoding="utf-8"))

    def test_resource_binding_rolls_back_if_service_dies_after_restart(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            profile = Path(temporary) / "swallow.json"
            original = json.dumps(unbound_profile()) + "\n"
            profile.write_text(original, encoding="utf-8")
            profile.chmod(0o644)
            active_checks = 0

            def systemctl_action(*args: str) -> None:
                nonlocal active_checks
                if args[:2] == ("is-active", "--quiet"):
                    active_checks += 1
                    if active_checks == 2:
                        raise INSTALL.common.InstallError("service-manager-failed")

            with (
                mock.patch.object(INSTALL, "PROFILE_SOURCE", profile),
                mock.patch.object(
                    INSTALL.common, "protected_revision", return_value="a" * 40
                ),
            ):
                with self.assertRaisesRegex(
                    INSTALL.common.InstallError, "service-manager-failed"
                ):
                    INSTALL.bind_resource(
                        "G12345678",
                        systemctl_action=systemctl_action,
                        sleeper=lambda _seconds: None,
                        owner_uid=os.geteuid(),
                    )
            self.assertEqual(profile.read_text(encoding="utf-8"), original)
            self.assertEqual(profile.stat().st_mode & 0o777, 0o644)

    def test_bundle_contains_only_bot_read_rotation_material(self) -> None:
        bundle = {name: f"fixture-{name}-value" for name in INSTALL.EXPECTED_FIELDS}
        self.assertEqual(set(INSTALL.validate_bundle(bundle)), INSTALL.EXPECTED_FIELDS)
        self.assertNotIn("slack-access-write", bundle)
        self.assertNotIn("slack-refresh-write", bundle)
        with self.assertRaisesRegex(
            INSTALL.SwallowInstallError, "credential-bundle-invalid"
        ):
            INSTALL.validate_bundle(dict(bundle, unexpected="fixture"))

    def test_unit_replacements_are_profile_local(self) -> None:
        values = INSTALL.replacements(Path("/fixture/release"))
        self.assertEqual(values["PROFILE"], "swallow")
        self.assertEqual(values["SERVICE_IDENTITY"], "harness_slack_swallow")
        self.assertIn("/swallow/", values["READ_CREDENTIAL_SOURCE"])
        self.assertNotIn("personal", " ".join(values.values()))

    def test_enrollment_wrapper_selects_swallow_without_copying_flow(self) -> None:
        wrapper = (LIBEXEC / "harness-slack-swallow-enroll").read_text(
            encoding="utf-8"
        )
        self.assertIn("HARNESS_SLACK_PROFILE=swallow", wrapper)
        self.assertIn("harness-slack-personal-enroll", wrapper)
        self.assertNotIn("client-secret", wrapper)

    def test_quarantine_is_exact_recoverable_and_profile_local(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            current = root / "current"
            quarantine = root / "quarantine"
            current.mkdir(mode=0o700)
            for name in INSTALL.EXPECTED_FIELDS:
                path = current / name
                path.write_bytes(b"encrypted-fixture")
                path.chmod(0o600)
            actions: list[tuple[str, ...]] = []
            with (
                mock.patch.object(INSTALL, "CREDENTIAL_STORE", current),
                mock.patch.object(INSTALL, "QUARANTINE_STORES", (quarantine,)),
                mock.patch.object(INSTALL.common, "protected_revision", return_value="a" * 40),
            ):
                INSTALL.quarantine(
                    owner_uid=os.geteuid(),
                    systemctl_action=lambda *args: actions.append(args),
                )
            self.assertFalse(current.exists())
            self.assertEqual(set(path.name for path in quarantine.iterdir()), INSTALL.EXPECTED_FIELDS)
            self.assertEqual(
                actions,
                [
                    ("disable", "--now", "harness-slack-swallow-rotate-read.timer"),
                    ("stop", "harness-slack-swallow.service"),
                ],
            )

    def test_scope_doctor_is_profile_pinned_and_credential_projected(self) -> None:
        calls: list[list[str]] = []

        def run(arguments: list[str], **_kwargs: object) -> subprocess.CompletedProcess[bytes]:
            calls.append(arguments)
            return subprocess.CompletedProcess(arguments, 0)

        with (
            mock.patch.object(INSTALL.common, "protected_revision", return_value="a" * 40),
            mock.patch.object(INSTALL.common, "install_release", return_value=Path("/release")),
        ):
            INSTALL.diagnose_read_scopes(run)
        self.assertEqual(len(calls), 1)
        command = calls[0]
        self.assertIn("--profile", command)
        self.assertEqual(command[command.index("--profile") + 1], "swallow")
        self.assertIn(
            "--property=LoadCredentialEncrypted=slack-access-read:"
            "/etc/harness-slack-broker/credentials/swallow/current/slack-access-read",
            command,
        )

    @unittest.skipUnless(hasattr(socket, "SO_PEERCRED"), "requires peer credentials")
    def test_one_shot_sink_accepts_only_exact_swallow_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "swallow.sock"
            bundle = {
                name: f"fixture-{name}-value" for name in INSTALL.EXPECTED_FIELDS
            }
            captured: list[dict[str, str]] = []
            failures: list[BaseException] = []
            ready = threading.Event()

            def serve() -> None:
                try:
                    INSTALL.common.receive_once(
                        path,
                        os.getuid(),
                        os.getgid(),
                        captured.append,
                        socket_uid=os.getuid(),
                        validator=INSTALL.validate_bundle,
                        ready=ready.set,
                    )
                except BaseException as exc:  # pragma: no cover - surfaced below
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            ready.wait()
            self.assertEqual(path.stat().st_mode & 0o777, 0o660)
            OAUTH._sink_socket(
                bundle,
                path,
                expected_fields=OAUTH.SWALLOW_BUNDLE_FIELDS,
                server_uid=os.getuid(),
                client_gid=os.getgid(),
            )
            thread.join()
            self.assertEqual(failures, [])
            self.assertEqual(captured, [bundle])


if __name__ == "__main__":
    unittest.main()
