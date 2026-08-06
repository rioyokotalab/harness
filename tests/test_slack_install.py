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
                if path.exists():
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
