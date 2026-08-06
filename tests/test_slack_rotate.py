from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest


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
            with self.assertRaisesRegex(ROTATE.RotationError, "rotation-scope-invalid"):
                ROTATE.validate_response(role, response(role, scope="extra:read"))

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
