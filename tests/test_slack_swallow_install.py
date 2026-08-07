from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
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


class SlackSwallowInstallTests(unittest.TestCase):
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

    def test_one_shot_sink_accepts_only_exact_swallow_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "swallow.sock"
            bundle = {
                name: f"fixture-{name}-value" for name in INSTALL.EXPECTED_FIELDS
            }
            captured: list[dict[str, str]] = []
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    INSTALL.common.receive_once(
                        path,
                        os.getuid(),
                        os.getgid(),
                        captured.append,
                        socket_uid=os.getuid(),
                        validator=INSTALL.validate_bundle,
                    )
                except BaseException as exc:  # pragma: no cover - surfaced below
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            for _attempt in range(100):
                if path.exists() and path.stat().st_mode & 0o777 == 0o660:
                    break
                time.sleep(0.01)
            OAUTH._sink_socket(
                bundle,
                path,
                expected_fields=OAUTH.SWALLOW_BUNDLE_FIELDS,
                server_uid=os.getuid(),
                client_gid=os.getgid(),
            )
            thread.join(timeout=5)
            self.assertFalse(thread.is_alive())
            self.assertEqual(failures, [])
            self.assertEqual(captured, [bundle])


if __name__ == "__main__":
    unittest.main()
