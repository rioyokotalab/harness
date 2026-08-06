from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_install", ROOT / "libexec" / "harness_slack_install.py"
)
assert SPEC is not None and SPEC.loader is not None
INSTALL = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_install"] = INSTALL
SPEC.loader.exec_module(INSTALL)


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
        text = (ROOT / "libexec" / "harness-slack-personal-enroll").read_text(
            encoding="utf-8"
        )
        self.assertLess(text.index("sudo -v"), text.index('"$oauth" --browser-helper'))
        self.assertLess(text.index('"$sink" preflight'), text.index('"$oauth" --browser-helper'))
        self.assertLess(text.index("git -C"), text.index("sudo -v"))
        self.assertNotIn("client-secret=", text)


if __name__ == "__main__":
    unittest.main()
