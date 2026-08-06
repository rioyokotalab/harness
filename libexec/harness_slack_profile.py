#!/usr/bin/env python3
"""Validate repository declarations and render credential-free runtime profiles."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import sys
from typing import Any

import harness_slack_broker as broker


DECLARATION_KEYS = (broker.PROFILE_KEYS - {"resources"}) | {
    "credential_domain",
    "harness_module_sha256",
    "harness_revision",
    "migration",
    "resource_binding",
}
METADATA_KEYS = DECLARATION_KEYS - (broker.PROFILE_KEYS - {"resources"})
UNBOUND_RESOURCE = "deployment-unbound"


def fail(reason: str) -> None:
    raise broker.ContractError(reason)


def validate_declaration(value: dict[str, Any]) -> dict[str, Any]:
    broker.exact_keys(value, DECLARATION_KEYS, "declaration-fields-invalid")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", value["credential_domain"]):
        fail("declaration-credential-domain-invalid")
    if not re.fullmatch(r"[0-9a-f]{40}", value["harness_revision"]):
        fail("declaration-revision-invalid")
    expected_digest = hashlib.sha256(Path(broker.__file__).read_bytes()).hexdigest()
    if value["harness_module_sha256"] != expected_digest:
        fail("declaration-module-mismatch")
    if value["migration"] != "synthetic-only":
        fail("declaration-migration-invalid")
    expected_binding = {
        "exact": "owner-state-exact",
        "workspace-visible": "workspace-visible-at-runtime",
    }.get(value["resource_policy"])
    if value["resource_binding"] != expected_binding:
        fail("declaration-resource-binding-invalid")
    return value


def fail_closed_profile(declaration: dict[str, Any]) -> dict[str, Any]:
    validated = validate_declaration(declaration)
    runtime = {
        key: value for key, value in validated.items() if key not in METADATA_KEYS
    }
    runtime["resources"] = (
        [UNBOUND_RESOURCE] if runtime["resource_policy"] == "exact" else []
    )
    return broker.validate_profile(runtime)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--declaration", required=True)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        declaration = broker.load_json(args.declaration)
        output = fail_closed_profile(declaration)
    except (OSError, broker.ContractError):
        print("SLACK_PROFILE status=failed reason=declaration-invalid", file=sys.stderr)
        return 2
    print(broker.canonical_json(output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
