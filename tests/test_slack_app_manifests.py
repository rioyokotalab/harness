from __future__ import annotations

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MANIFESTS = ROOT / "config" / "slack"


class SlackManifestTests(unittest.TestCase):
    def load(self, name: str) -> dict[str, object]:
        return json.loads((MANIFESTS / name).read_text(encoding="utf-8"))

    def assert_common(self, manifest: dict[str, object]) -> None:
        self.assertEqual(
            set(manifest), {"display_information", "features", "oauth_config", "settings"}
        )
        settings = manifest["settings"]
        self.assertEqual(
            settings,
            {
                "org_deploy_enabled": False,
                "socket_mode_enabled": False,
                "token_rotation_enabled": True,
            },
        )
        self.assertNotIn("event_subscriptions", settings)
        self.assertNotIn("incoming_webhooks", manifest["features"])

    def test_personal_splits_user_read_from_bot_write(self) -> None:
        manifest = self.load("personal-app-manifest.json")
        self.assert_common(manifest)
        self.assertEqual(
            manifest["oauth_config"]["redirect_urls"],
            ["http://localhost:53683/slack/oauth/callback"],
        )
        self.assertNotIn("pkce_enabled", manifest["oauth_config"])
        scopes = manifest["oauth_config"]["scopes"]
        self.assertEqual(scopes["bot"], ["chat:write"])
        self.assertEqual(
            scopes["user"],
            [
                "canvases:read",
                "channels:history",
                "files:read",
                "groups:history",
                "users:read",
            ],
        )
        self.assertNotIn("chat:write", scopes["user"])

    def test_swallow_has_only_bounded_read_scopes(self) -> None:
        manifest = self.load("swallow-app-manifest.json")
        self.assert_common(manifest)
        scopes = manifest["oauth_config"]["scopes"]
        self.assertEqual(set(scopes), {"bot"})
        self.assertEqual(
            scopes["bot"],
            ["canvases:read", "channels:history", "files:read", "groups:history"],
        )
        self.assertTrue(all("write" not in scope for scope in scopes["bot"]))


if __name__ == "__main__":
    unittest.main()
