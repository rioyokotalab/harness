from __future__ import annotations

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SYSTEMD = ROOT / "config" / "slack" / "systemd"


class SlackSystemdTests(unittest.TestCase):
    def test_fail_closed_service_uses_exact_release_and_service_manager_profile(self) -> None:
        text = (SYSTEMD / "harness-slack-profile.service.in").read_text(encoding="utf-8")
        self.assertIn("ExecStart=@@RELEASE@@/libexec/harness-slack-mcp-service", text)
        self.assertIn("LoadCredential=profile:@@PROFILE_SOURCE@@", text)
        self.assertIn("--credential-state absent", text)
        self.assertNotIn("slack-access", text)
        self.assertNotIn("Environment=", text)
        self.assertNotIn("EnvironmentFile=", text)
        for directive in (
            "NoNewPrivileges=yes",
            "ProtectSystem=strict",
            "ProtectHome=yes",
            "RestrictAddressFamilies=AF_UNIX",
        ):
            self.assertIn(directive, text)

    def test_socket_is_owner_only_and_profile_local(self) -> None:
        text = (SYSTEMD / "harness-slack-profile.socket.in").read_text(encoding="utf-8")
        self.assertIn("ListenStream=/run/harness-slack-broker/@@PROFILE@@.sock", text)
        self.assertIn("SocketMode=0600", text)
        self.assertIn("SocketUser=@@CLIENT_USER@@", text)
        self.assertIn("Service=harness-slack-@@PROFILE@@.service", text)


if __name__ == "__main__":
    unittest.main()
