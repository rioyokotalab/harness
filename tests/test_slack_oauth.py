from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import os
import pty
import select
import subprocess
import tempfile
import time
import unittest
import urllib.parse


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_oauth", ROOT / "libexec" / "harness_slack_oauth.py"
)
assert SPEC is not None and SPEC.loader is not None
OAUTH = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_oauth"] = OAUTH
SPEC.loader.exec_module(OAUTH)


def response(**overrides: object) -> dict[str, object]:
    value: dict[str, object] = {
        "ok": True,
        "access_token": "xoxe.xoxb-fixture-access",
        "expires_in": 43200,
        "refresh_token": "xoxe-fixture-bot-refresh",
        "scope": "chat:write",
        "token_type": "bot",
        "authed_user": {
            "access_token": "xoxe.xoxp-fixture-access",
            "expires_in": 43200,
            "refresh_token": "xoxe-fixture-user-refresh",
            "scope": ",".join(OAUTH.USER_SCOPES),
            "token_type": "user",
        },
    }
    value.update(overrides)
    return value


class SlackOAuthTests(unittest.TestCase):
    def test_hidden_prompt_uses_inherited_tty_without_echo(self) -> None:
        script = f"""
import importlib.util
spec = importlib.util.spec_from_file_location('oauth_prompt_test', {str(ROOT / 'libexec' / 'harness_slack_oauth.py')!r})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
value = module._hidden_prompt('Fixture hidden prompt: ')
raise SystemExit(0 if value == 'fixture-private-value' else 3)
"""
        master, slave = pty.openpty()
        process: subprocess.Popen[bytes] | None = None
        try:
            process = subprocess.Popen(
                [sys.executable, "-B", "-c", script],
                stdin=slave,
                stdout=slave,
                stderr=slave,
                start_new_session=True,
                close_fds=True,
            )
            os.close(slave)
            slave = -1
            output = bytearray()
            sent = False
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                ready, _writable, _errors = select.select([master], [], [], 0.1)
                if ready:
                    try:
                        chunk = os.read(master, 4096)
                    except OSError:
                        chunk = b""
                    output.extend(chunk)
                if not sent and b"Fixture hidden prompt: " in output:
                    os.write(master, b"fixture-private-value\n")
                    sent = True
                if process.poll() is not None:
                    break
            self.assertTrue(sent)
            self.assertEqual(process.wait(timeout=1), 0)
            self.assertNotIn(b"fixture-private-value", output)
        finally:
            if process is not None and process.poll() is None:
                process.terminate()
                process.wait(timeout=1)
            if slave >= 0:
                os.close(slave)
            os.close(master)

    def test_hidden_prompt_fails_closed_without_tty(self) -> None:
        result = subprocess.run(
            [
                str(ROOT / "libexec" / "harness-slack-oauth"),
                "--browser-helper",
                "/fixture/browser-helper",
                "--credential-socket",
                "/fixture/credential-socket",
            ],
            input=b"fixture-private-value\n",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        self.assertEqual(result.returncode, 2)
        self.assertEqual(
            result.stderr,
            b"SLACK_OAUTH status=failed reason=oauth-hidden-prompt-unavailable\n",
        )
        self.assertNotIn(b"fixture-private-value", result.stdout + result.stderr)

    def test_callback_wait_loop_ignores_unaccepted_requests(self) -> None:
        class Server:
            timeout = 0.0
            calls = 0

            def handle_request(self) -> None:
                self.calls += 1

        server = Server()
        OAUTH._handle_until(server, lambda: server.calls == 3, OAUTH.time.monotonic() + 1, "failed")
        self.assertEqual(server.calls, 3)

    def test_authorization_url_requests_exact_split_scopes(self) -> None:
        parsed = urllib.parse.urlparse(OAUTH.authorization_url("fixture.client", "fixture-state"))
        query = urllib.parse.parse_qs(parsed.query)
        self.assertEqual(f"{parsed.scheme}://{parsed.netloc}{parsed.path}", OAUTH.AUTH_ENDPOINT)
        self.assertEqual(query["redirect_uri"], [OAUTH.REDIRECT_URI])
        self.assertEqual(query["scope"], [",".join(OAUTH.BOT_SCOPES)])
        self.assertEqual(query["user_scope"], [",".join(OAUTH.USER_SCOPES)])
        self.assertEqual(query["state"], ["fixture-state"])
        self.assertNotIn("code_challenge", query)

    def test_combined_rotating_response_maps_to_isolated_credentials(self) -> None:
        bundle = OAUTH.validate_token_response(
            response(), "fixture.client", "fixture-client-secret"
        )
        self.assertEqual(set(bundle), OAUTH.BUNDLE_FIELDS)
        self.assertNotEqual(bundle["slack-access-read"], bundle["slack-access-write"])
        self.assertNotEqual(bundle["slack-refresh-read"], bundle["slack-refresh-write"])

    def test_scope_drift_fails_closed(self) -> None:
        with self.assertRaisesRegex(OAUTH.OAuthError, "oauth-bot-scope-invalid"):
            OAUTH.validate_token_response(
                response(scope="chat:write,files:read"),
                "fixture.client",
                "fixture-client-secret",
            )
        changed = response()
        changed["authed_user"] = dict(changed["authed_user"], scope="channels:history")
        with self.assertRaisesRegex(OAUTH.OAuthError, "oauth-user-scope-invalid"):
            OAUTH.validate_token_response(
                changed, "fixture.client", "fixture-client-secret"
            )

    def test_missing_refresh_and_wrong_ttl_fail_closed(self) -> None:
        with self.assertRaisesRegex(OAUTH.OAuthError, "oauth-bot-token-invalid"):
            OAUTH.validate_token_response(
                response(expires_in=3600), "fixture.client", "fixture-client-secret"
            )
        with self.assertRaisesRegex(OAUTH.OAuthError, "oauth-bot-refresh-invalid"):
            OAUTH.validate_token_response(
                response(refresh_token=None),
                "fixture.client",
                "fixture-client-secret",
            )

    def test_provider_failure_is_value_free(self) -> None:
        with self.assertRaisesRegex(OAUTH.OAuthError, "oauth-exchange-rejected"):
            OAUTH.validate_token_response(
                {"ok": False, "error": "private-provider-detail"},
                "fixture.client",
                "fixture-client-secret",
            )

    def test_browser_helper_accepts_only_exact_google_or_slack_origins(self) -> None:
        helper = ROOT / "libexec" / "harness-oauth-browser-open"
        with tempfile.TemporaryDirectory() as temporary:
            fake_ssh = Path(temporary) / "ssh"
            fake_ssh.write_text("#!/bin/sh\ncat >/dev/null\n", encoding="utf-8")
            fake_ssh.chmod(0o700)
            environment = dict(os.environ)
            environment.update(
                {
                    "HARNESS_OAUTH_BROWSER_HOST": "office",
                    "HARNESS_TESTING": "1",
                    "HARNESS_TEST_SSH": str(fake_ssh),
                }
            )
            accepted = subprocess.run(
                [str(helper)],
                input=b"https://slack.com/oauth/v2/authorize?fixture=1",
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=environment,
                check=False,
            )
            self.assertEqual(accepted.returncode, 0)
            rejected = subprocess.run(
                [str(helper)],
                input=b"https://slack.com.evil.invalid/oauth/v2/authorize?fixture=1",
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=environment,
                check=False,
            )
            self.assertEqual(rejected.returncode, 2)

    def test_oauth_flow_probes_the_fixed_reverse_tunnel_before_browser(self) -> None:
        source = (ROOT / "libexec" / "harness_slack_oauth.py").read_text(
            encoding="utf-8"
        )
        self.assertIn("/usr/bin/curl", source)
        self.assertLess(source.index("_probe_tunnel(server"), source.index("_open_browser(authorization_url"))


if __name__ == "__main__":
    unittest.main()
