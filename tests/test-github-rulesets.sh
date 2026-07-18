#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
expected_contexts = {
    "harness-main.json": "portable-phase1",
    "website-main.json": "Offline checks",
}
expected_types = [
    "deletion",
    "non_fast_forward",
    "required_linear_history",
    "pull_request",
    "required_status_checks",
]

for name, context in expected_contexts.items():
    path = root / "docs" / "github-rulesets" / name
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["name"] == "main-strict-review"
    assert data["target"] == "branch"
    assert data["enforcement"] == "active"
    assert data["bypass_actors"] == []
    assert data["conditions"] == {
        "ref_name": {"exclude": [], "include": ["refs/heads/main"]}
    }
    assert [rule["type"] for rule in data["rules"]] == expected_types
    pull_request = next(rule for rule in data["rules"] if rule["type"] == "pull_request")
    assert pull_request["parameters"] == {
        "allowed_merge_methods": ["squash", "rebase"],
        "dismiss_stale_reviews_on_push": True,
        "require_code_owner_review": False,
        "require_last_push_approval": False,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": True,
    }
    checks = next(rule for rule in data["rules"] if rule["type"] == "required_status_checks")
    assert checks["parameters"] == {
        "do_not_enforce_on_create": False,
        "required_status_checks": [
            {"context": context, "integration_id": 15368}
        ],
        "strict_required_status_checks_policy": True,
    }

print("GitHub ruleset payload tests passed")
PY
