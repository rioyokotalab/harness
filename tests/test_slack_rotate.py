from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
LIBEXEC = ROOT / "libexec"
sys.path.insert(0, str(LIBEXEC))
SPEC = importlib.util.spec_from_file_location(
    "harness_slack_rotate", LIBEXEC / "harness_slack_rotate.py"
)
assert SPEC is not None and SPEC.loader is not None
ROTATE = importlib.util.module_from_spec(SPEC)
sys.modules["harness_slack_rotate"] = ROTATE
SPEC.loader.exec_module(ROTATE)


def response(role: str, **overrides: object) -> dict[str, object]:
    policy = ROTATE.ROLE[role]
    value: dict[str, object] = {
        "ok": True,
        "access_token": f"xoxe.fixture-{role}-access",
        "expires_in": 43200,
        "refresh_token": f"xoxe.fixture-{role}-refresh",
        "scope": ",".join(sorted(policy["scopes"])),
        "token_type": policy["kind"],
    }
    value.update(overrides)
    return value


class SlackRotationTests(unittest.TestCase):
    def test_scope_doctor_reports_only_public_capability_identifiers(self) -> None:
        actual = set(ROTATE.ROLE["read"]["scopes"]) | {"channels:read"}
        value = ROTATE.diagnose_scopes(
            "read",
            Path("/fixture/credentials"),
            read_credential=lambda _path: "fixture-access-token",
            verify_scopes=lambda _token: actual,
        )
        self.assertEqual(
            value,
            "SLACK_SCOPE status=drift role=read missing=none "
            "additional=channels:read",
        )

    def test_effective_scope_readback_uses_only_the_fixed_header(self) -> None:
        class Result:
            status = 200
            headers = {
                "X-OAuth-Scopes": "channels:history,files:read,groups:history"
            }

            def __enter__(self) -> "Result":
                return self

            def __exit__(self, *_args: object) -> None:
                return None

        with mock.patch.object(ROTATE.SCOPE_OPENER, "open", return_value=Result()) as call:
            scopes = ROTATE.verify_access_scopes_once("fixture-access-token")
        self.assertEqual(
            scopes, {"channels:history", "files:read", "groups:history"}
        )
        request = call.call_args.args[0]
        self.assertEqual(request.full_url, ROTATE.SCOPE_ENDPOINT)
        self.assertEqual(call.call_args.kwargs, {"timeout": 30})

    def test_each_role_requires_exact_kind_scope_and_bounded_ttl(self) -> None:
        for role in ROTATE.ROLE:
            for ttl in (
                ROTATE.MIN_ROTATING_TTL_SECONDS,
                43199,
                43200,
                ROTATE.MAX_ROTATING_TTL_SECONDS,
            ):
                access, refresh = ROTATE.validate_response(
                    role, response(role, expires_in=ttl)
                )
                self.assertIn(role, access)
                self.assertIn(role, refresh)
            for ttl in (3599, ROTATE.MAX_ROTATING_TTL_SECONDS + 1, True, "43200"):
                with self.assertRaisesRegex(
                    ROTATE.RotationError, "rotation-expiry-invalid"
                ):
                    ROTATE.validate_response(role, response(role, expires_in=ttl))
            with self.assertRaisesRegex(ROTATE.RotationError, "rotation-scope-drift"):
                ROTATE.validate_response(role, response(role, scope="extra:read"))

    def test_scope_mismatch_uses_effective_header_once_before_store(self) -> None:
        stored: list[tuple[str, str, str]] = []
        verified: list[str] = []

        ROTATE.rotate_role(
            "read",
            Path("/fixture/credentials"),
            Path("/fixture/store"),
            exchange=lambda *_args: response("read", scope="extra:read"),
            verify_scopes=lambda token: (
                verified.append(token) or set(ROTATE.ROLE["read"]["scopes"])
            ),
            read_credential=lambda _path: "fixture-credential-value",
            store_action=lambda _store, role, access, refresh: stored.append(
                (role, access, refresh)
            ),
        )
        self.assertEqual(len(verified), 1)
        self.assertEqual(len(stored), 1)

    def test_effective_scope_mismatch_is_classified_before_store(self) -> None:
        stored: list[tuple[str, str, str]] = []
        cases = (
            ({"channels:history"}, "rotation-scope-missing"),
            (
                set(ROTATE.ROLE["read"]["scopes"]) | {"extra:read"},
                "rotation-scope-additional",
            ),
            ({"channels:history", "extra:read"}, "rotation-scope-drift"),
        )
        for effective, reason in cases:
            with self.subTest(reason=reason):
                with self.assertRaisesRegex(ROTATE.RotationError, reason):
                    ROTATE.rotate_role(
                        "read",
                        Path("/fixture/credentials"),
                        Path("/fixture/store"),
                        exchange=lambda *_args: response("read", scope="extra:read"),
                        verify_scopes=lambda _token, value=effective: value,
                        read_credential=lambda _path: "fixture-credential-value",
                        store_action=lambda _store, role, access, refresh: stored.append(
                            (role, access, refresh)
                        ),
                    )
        self.assertEqual(stored, [])

    def test_rotation_shape_failures_are_precise_and_value_free(self) -> None:
        cases = (
            ({"token_type": "other"}, "rotation-token-type-invalid"),
            ({"access_token": None}, "rotation-access-token-invalid"),
            ({"refresh_token": None}, "rotation-refresh-token-invalid"),
        )
        for changes, reason in cases:
            with self.subTest(reason=reason):
                with self.assertRaisesRegex(ROTATE.RotationError, reason):
                    ROTATE.validate_response("read", response("read", **changes))

    def test_explicit_provider_denial_requires_renewal(self) -> None:
        with self.assertRaisesRegex(ROTATE.RotationError, "rotation-refresh-rejected"):
            ROTATE.validate_response("read", {"ok": False, "error": "fixture-private"})

    def test_restart_contract_is_validated_before_rotation(self) -> None:
        ROTATE.validate_restart("read", "harness-slack-personal.service")
        ROTATE.validate_restart("write", None)
        for role, service in (
            ("read", None),
            ("read", "other.service"),
            ("write", "harness-slack-personal.service"),
        ):
            with self.assertRaisesRegex(ROTATE.RotationError, "rotation-restart-invalid"):
                ROTATE.validate_restart(role, service)

    def test_store_commits_refresh_before_access_and_retains_only_old_access(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            store = Path(temporary)
            os.chmod(store, 0o700)
            (store / "slack-access-read").write_text("old-access", encoding="utf-8")
            (store / "slack-refresh-read").write_text("old-refresh", encoding="utf-8")
            for path in store.iterdir():
                path.chmod(0o600)

            def encrypt(name: str, value: str, output: Path) -> None:
                output.write_text(f"encrypted:{name}:{value}", encoding="utf-8")
                output.chmod(0o600)

            ROTATE.store_pair(
                store,
                "read",
                "new-access-value-1",
                "new-refresh-value-1",
                encrypt,
                os.geteuid(),
            )
            self.assertIn("new-access", (store / "slack-access-read").read_text())
            self.assertIn("new-refresh", (store / "slack-refresh-read").read_text())
            previous = store / ".previous-read"
            self.assertTrue((previous / "slack-access-read").is_file())
            self.assertFalse((previous / "slack-refresh-read").exists())


if __name__ == "__main__":
    unittest.main()
