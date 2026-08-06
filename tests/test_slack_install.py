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
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_install", ROOT / "libexec" / "harness_slack_install.py"
)
assert SPEC is not None and SPEC.loader is not None
INSTALL = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_install"] = INSTALL
SPEC.loader.exec_module(INSTALL)

OAUTH_SPEC = importlib.util.spec_from_file_location(
    "harness_slack_oauth_for_install_test",
    ROOT / "libexec" / "harness_slack_oauth.py",
)
assert OAUTH_SPEC is not None and OAUTH_SPEC.loader is not None
OAUTH = importlib.util.module_from_spec(OAUTH_SPEC)
sys.modules["harness_slack_oauth_for_install_test"] = OAUTH
OAUTH_SPEC.loader.exec_module(OAUTH)


def bundle() -> dict[str, str]:
    return {name: f"fixture-{name}-value" for name in INSTALL.EXPECTED_FIELDS}


class SlackInstallTests(unittest.TestCase):
    def test_reenrollment_quarantine_is_exact_and_recoverable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            current = root / "current"
            quarantine = root / "quarantine-before-reenroll"
            current.mkdir(mode=0o700)
            for name in INSTALL.EXPECTED_FIELDS:
                path = current / name
                path.write_bytes(b"encrypted-fixture")
                path.chmod(0o600)
            actions: list[tuple[str, ...]] = []
            with (
                mock.patch.object(INSTALL, "CREDENTIAL_STORE", current),
                mock.patch.object(INSTALL, "QUARANTINE_STORE", quarantine),
                mock.patch.object(INSTALL, "protected_revision", return_value="a" * 40),
            ):
                INSTALL.quarantine_personal(
                    owner_uid=os.geteuid(),
                    systemctl_action=lambda *args: actions.append(args),
                )
            self.assertFalse(current.exists())
            self.assertEqual(set(path.name for path in quarantine.iterdir()), INSTALL.EXPECTED_FIELDS)
            self.assertEqual(
                actions,
                [
                    ("disable", "--now", "harness-slack-personal-rotate-read.timer"),
                    ("disable", "--now", "harness-slack-personal-rotate-write.timer"),
                    ("stop", "harness-slack-personal.service"),
                ],
            )

    def test_reenrollment_quarantine_accepts_valid_previous_generations(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            current = root / "current"
            quarantine = root / "quarantine-before-reenroll"
            current.mkdir(mode=0o700)
            for name in INSTALL.EXPECTED_FIELDS:
                path = current / name
                path.write_bytes(b"encrypted-fixture")
                path.chmod(0o600)
            for directory, access in INSTALL.PREVIOUS_FIELDS.items():
                previous = current / directory
                previous.mkdir(mode=0o700)
                path = previous / access
                path.write_bytes(b"encrypted-previous-fixture")
                path.chmod(0o600)
            with (
                mock.patch.object(INSTALL, "CREDENTIAL_STORE", current),
                mock.patch.object(INSTALL, "QUARANTINE_STORE", quarantine),
                mock.patch.object(INSTALL, "protected_revision", return_value="a" * 40),
            ):
                INSTALL.quarantine_personal(
                    owner_uid=os.geteuid(), systemctl_action=lambda *_args: None
                )
            self.assertFalse(current.exists())
            self.assertEqual(
                set(path.name for path in quarantine.iterdir()),
                INSTALL.EXPECTED_FIELDS | set(INSTALL.PREVIOUS_FIELDS),
            )
            for directory, access in INSTALL.PREVIOUS_FIELDS.items():
                self.assertEqual(
                    tuple(path.name for path in (quarantine / directory).iterdir()),
                    (access,),
                )

    def test_reenrollment_quarantine_rejects_extra_or_existing_target(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            current = root / "current"
            quarantine = root / "quarantine-before-reenroll"
            current.mkdir(mode=0o700)
            for name in INSTALL.EXPECTED_FIELDS | {"extra"}:
                path = current / name
                path.write_bytes(b"encrypted-fixture")
                path.chmod(0o600)
            with (
                mock.patch.object(INSTALL, "CREDENTIAL_STORE", current),
                mock.patch.object(INSTALL, "QUARANTINE_STORE", quarantine),
                mock.patch.object(INSTALL, "protected_revision", return_value="a" * 40),
            ):
                with self.assertRaisesRegex(
                    INSTALL.InstallError, "credential-store-entries-invalid"
                ):
                    INSTALL.quarantine_personal(owner_uid=os.geteuid())
            self.assertTrue(current.is_dir())
            self.assertFalse(quarantine.exists())

    def test_reenrollment_quarantine_rejects_invalid_previous_generation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            current = root / "current"
            quarantine = root / "quarantine-before-reenroll"
            current.mkdir(mode=0o700)
            for name in INSTALL.EXPECTED_FIELDS:
                path = current / name
                path.write_bytes(b"encrypted-fixture")
                path.chmod(0o600)
            previous = current / ".previous-write"
            previous.mkdir(mode=0o700)
            invalid = previous / "unexpected"
            invalid.write_bytes(b"encrypted-fixture")
            invalid.chmod(0o600)
            with (
                mock.patch.object(INSTALL, "CREDENTIAL_STORE", current),
                mock.patch.object(INSTALL, "QUARANTINE_STORE", quarantine),
                mock.patch.object(INSTALL, "protected_revision", return_value="a" * 40),
            ):
                with self.assertRaisesRegex(
                    INSTALL.InstallError, "credential-store-previous-invalid"
                ):
                    INSTALL.quarantine_personal(owner_uid=os.geteuid())
            self.assertTrue(current.is_dir())
            self.assertFalse(quarantine.exists())
    def test_bundle_is_exact_and_bounded(self) -> None:
        self.assertEqual(set(INSTALL.validate_bundle(bundle())), INSTALL.EXPECTED_FIELDS)
        extra = bundle()
        extra["unexpected"] = "fixture-value"
        with self.assertRaisesRegex(INSTALL.InstallError, "credential-bundle-invalid"):
            INSTALL.validate_bundle(extra)
        spaced = bundle()
        spaced["slack-client-secret"] = "private value"
        with self.assertRaisesRegex(INSTALL.InstallError, "credential-bundle-invalid"):
            INSTALL.validate_bundle(spaced)

    def test_ready_and_rotation_units_render_without_markers(self) -> None:
        replacements = {
            "CLIENT_USER": "fixture-user",
            "CREDENTIAL_STORE": "/fixture/credentials",
            "PROFILE": "personal",
            "PROFILE_SOURCE": "/fixture/profile",
            "READ_CREDENTIAL_SOURCE": "/fixture/credentials/slack-access-read",
            "RELEASE": "/fixture/release",
            "SERVICE_IDENTITY": "fixture-service",
        }
        templates = ROOT / "config" / "slack" / "systemd"
        for name in (
            "harness-slack-personal-read.service.in",
            "harness-slack-personal-rotate-read.service.in",
            "harness-slack-personal-rotate-read.timer.in",
            "harness-slack-personal-rotate-write.service.in",
            "harness-slack-personal-rotate-write.timer.in",
        ):
            value = INSTALL.render(templates / name, replacements)
            self.assertNotIn(b"@@", value)

    def test_release_file_set_is_slack_only(self) -> None:
        self.assertTrue(INSTALL.RELEASE_FILES)
        self.assertTrue(all("slack" in name for name in INSTALL.RELEASE_FILES))
        self.assertNotIn("harness-slack-oauth", INSTALL.RELEASE_FILES)
        self.assertNotIn("harness-slack-install", INSTALL.RELEASE_FILES)

    def test_enrollment_authenticates_root_before_starting_oauth(self) -> None:
        launcher = ROOT / "libexec" / "harness-slack-personal-enroll"
        text = launcher.read_text(encoding="utf-8")
        self.assertIn('[ "$(id -u)" = 0 ] || fail root-required', text)
        self.assertIn('/usr/sbin/runuser -u "$owner_name"', text)
        self.assertLess(text.index('"$sink" preflight'), text.index("serve-personal"))
        self.assertLess(
            text.index("serve-personal"),
            text.index('run_as_owner "$launcher" --browser-host'),
        )
        self.assertIn('--credential-socket "$socket_path"', text)
        self.assertIn('-M -N -T -S "$control_path"', text)
        self.assertIn('-o BatchMode=yes -o ControlPersist=no', text)
        self.assertIn('-S "$control_path" -O check', text)
        self.assertIn('-S "$control_path" -O exit', text)
        for phase in (
            "administrator-preflight",
            "protected-source-ready",
            "credential-sink-ready",
            "owner-worker-starting",
            "owner-preflight-ready",
            "callback-port-ready",
            "tunnel-starting",
            "tunnel-ready",
            "oauth-starting",
        ):
            self.assertIn(f"progress {phase}", text)
        for reason in (
            "oauth-runtime-dir-invalid",
            "oauth-control-path-conflict",
            "oauth-tunnel-log-failed",
            "oauth-tunnel-remote-bind-failed",
            "oauth-tunnel-authentication-failed",
            "oauth-tunnel-route-failed",
            "oauth-tunnel-master-exited",
            "oauth-tunnel-ready-timeout",
        ):
            self.assertIn(f"fail {reason}", text)
        self.assertNotIn("fail oauth-tunnel-failed", text)
        self.assertIn('tunnel_log=$(mktemp "$runtime_dir/harness-slack-oauth-XXXXXX.log")', text)
        self.assertIn('2>"$tunnel_log" &', text)
        self.assertIn('unlink "$tunnel_log"', text)
        self.assertNotIn("-O forward", text)
        self.assertNotIn("-O cancel", text)
        self.assertNotIn("sudo -v", text)
        self.assertNotIn("sudo \"$sink\"", text)
        self.assertNotIn("client-secret=", text)
        if os.geteuid() != 0:
            result = subprocess.run(
                [str(launcher), "--browser-host", "riken"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 2)
            self.assertEqual(
                result.stderr,
                "SLACK_ENROLL status=failed reason=root-required\n",
            )

    def test_one_shot_sink_authenticates_both_local_peers(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "sink.sock"
            captured: list[dict[str, str]] = []
            failures: list[BaseException] = []

            def serve() -> None:
                try:
                    INSTALL.receive_once(
                        path,
                        os.getuid(),
                        os.getgid(),
                        captured.append,
                        socket_uid=os.getuid(),
                    )
                except BaseException as exc:  # pragma: no cover - surfaced below
                    failures.append(exc)

            thread = threading.Thread(target=serve)
            thread.start()
            for _attempt in range(100):
                if (
                    path.exists()
                    and path.stat().st_uid == os.getuid()
                    and path.stat().st_gid == os.getgid()
                    and path.stat().st_mode & 0o777 == 0o660
                ):
                    break
                time.sleep(0.01)
            self.assertTrue(path.exists())
            OAUTH._sink_socket(
                bundle(), path, server_uid=os.getuid(), client_gid=os.getgid()
            )
            thread.join(timeout=5)
            self.assertFalse(thread.is_alive())
            self.assertEqual(failures, [])
            self.assertEqual(captured, [bundle()])
            self.assertFalse(path.exists())

    def test_sink_rejects_non_socket_path_before_bundle_delivery(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "not-a-socket"
            path.write_text("fixture", encoding="utf-8")
            path.chmod(0o660)
            with self.assertRaisesRegex(
                OAUTH.OAuthError, "oauth-credential-sink-invalid"
            ):
                OAUTH._sink_socket(
                    bundle(), path, server_uid=os.getuid(), client_gid=os.getgid()
                )


if __name__ == "__main__":
    unittest.main()
