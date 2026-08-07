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

    def test_personal_ready_service_receives_only_encrypted_read_access(self) -> None:
        text = (SYSTEMD / "harness-slack-personal-read.service.in").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "LoadCredentialEncrypted=slack-access-read:@@READ_CREDENTIAL_SOURCE@@", text
        )
        self.assertIn("--credential-state ready --provider slack-mcp", text)
        self.assertIn("--credential %d/slack-access-read", text)
        self.assertIn("--audit /var/log/harness-slack-personal/audit.jsonl", text)
        self.assertIn("LogsDirectory=harness-slack-personal", text)
        self.assertIn("LogsDirectoryMode=0700", text)
        self.assertIn("RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6", text)
        self.assertIn("CapabilityBoundingSet=\n", text)
        self.assertIn("ProtectProc=invisible", text)
        self.assertNotIn("Environment=", text)
        self.assertNotIn("slack-access-write", text)
        self.assertNotIn("slack-refresh", text)
        self.assertNotIn("slack-client-secret", text)

    def test_personal_rotation_is_root_custodied_and_profile_local(self) -> None:
        read_service = (SYSTEMD / "harness-slack-personal-rotate-read.service.in").read_text(
            encoding="utf-8"
        )
        write_service = (SYSTEMD / "harness-slack-personal-rotate-write.service.in").read_text(
            encoding="utf-8"
        )
        for role, service in (("read", read_service), ("write", write_service)):
            timer = (SYSTEMD / f"harness-slack-personal-rotate-{role}.timer.in").read_text(
                encoding="utf-8"
            )
            self.assertIn("User=root", service)
            self.assertIn("LoadCredentialEncrypted=slack-client-secret:", service)
            self.assertIn(f"LoadCredentialEncrypted=slack-refresh-{role}:", service)
            self.assertNotIn(f"slack-refresh-{'write' if role == 'read' else 'read'}:", service)
            self.assertNotIn("slack-access-read:", service)
            self.assertNotIn("slack-access-write:", service)
            self.assertIn("ReadWritePaths=@@CREDENTIAL_STORE@@", service)
            self.assertIn("OnUnitActiveSec=8h", timer)
            self.assertIn("Persistent=true", timer)
            self.assertIn(f"Unit=harness-slack-personal-rotate-{role}.service", timer)
            self.assertIn(f"--role {role}", service)
        self.assertIn("--restart-service harness-slack-personal.service", read_service)
        self.assertNotIn("--restart-service", write_service)

    def test_swallow_ready_service_uses_bot_web_api_without_write_credential(self) -> None:
        text = (SYSTEMD / "harness-slack-swallow-read.service.in").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "LoadCredentialEncrypted=slack-access-read:@@READ_CREDENTIAL_SOURCE@@", text
        )
        self.assertIn("--credential-state ready --provider slack-web-api", text)
        self.assertIn("--audit /var/log/harness-slack-swallow/audit.jsonl", text)
        self.assertIn("RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6", text)
        self.assertNotIn("slack-access-write", text)
        self.assertNotIn("slack-refresh", text)
        self.assertNotIn("slack-client-secret", text)

    def test_swallow_rotation_is_single_role_and_profile_pinned(self) -> None:
        service = (SYSTEMD / "harness-slack-swallow-rotate-read.service.in").read_text(
            encoding="utf-8"
        )
        timer = (SYSTEMD / "harness-slack-swallow-rotate-read.timer.in").read_text(
            encoding="utf-8"
        )
        self.assertIn("User=root", service)
        self.assertIn("--profile swallow --role read", service)
        self.assertIn("--restart-service harness-slack-swallow.service", service)
        self.assertNotIn("slack-access-write", service)
        self.assertNotIn("slack-refresh-write", service)
        self.assertIn("OnUnitActiveSec=8h", timer)
        self.assertIn("Persistent=true", timer)


if __name__ == "__main__":
    unittest.main()
