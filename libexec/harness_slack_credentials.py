#!/usr/bin/env python3
"""Credential-free Slack credential topology and lifecycle decisions."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
from typing import Any

import harness_slack_broker as broker


CONTRACT = "harness-slack-credentials-v1"
TOPOLOGIES = {"bot-read", "external-structured", "user-read-bot-write"}
PLAN_KEYS = {
    "contract",
    "custodian",
    "exposure",
    "profile",
    "profile_sha256",
    "read",
    "rotation",
    "schema",
    "topology",
    "write",
}
ROLE_KEYS = {"credential", "kind", "scopes"}
ROTATION_KEYS = {
    "access_ttl_seconds",
    "enabled",
    "rollback_generations",
    "rotate_after_seconds",
    "triggers",
}
EXPOSURE_KEYS = {"read_rotator", "read_service", "write_rotator", "write_transaction"}


def fail(reason: str) -> None:
    raise broker.ContractError(reason)


def profile_digest(profile: dict[str, Any]) -> str:
    return hashlib.sha256(broker.canonical_json(profile).encode("utf-8")).hexdigest()


def validate_role(value: object, reason: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(reason)
    broker.exact_keys(value, ROLE_KEYS, reason)
    if value["kind"] not in {"bot", "none", "user"}:
        fail(reason)
    credential = value["credential"]
    if credential is not None and credential not in {
        "slack-access-read",
        "slack-access-write",
    }:
        fail(reason)
    scopes = value["scopes"]
    if (
        not isinstance(scopes, list)
        or scopes != sorted(set(scopes))
        or any(not isinstance(item, str) for item in scopes)
    ):
        fail(reason)
    if (value["kind"] == "none") != (credential is None and not scopes):
        fail(reason)
    return value


def validate_exposure(value: object, expected: dict[str, list[str]]) -> None:
    if not isinstance(value, dict):
        fail("credential-exposure-invalid")
    broker.exact_keys(value, EXPOSURE_KEYS, "credential-exposure-invalid")
    for key in sorted(EXPOSURE_KEYS):
        items = value[key]
        if not isinstance(items, list) or items != expected[key]:
            fail("credential-exposure-invalid")
    steady = set(value["read_service"])
    transient = set(value["write_transaction"])
    if steady.intersection(transient):
        fail("credential-exposure-overlap")


def validate_plan(profile: dict[str, Any], value: dict[str, Any]) -> dict[str, Any]:
    broker.exact_keys(value, PLAN_KEYS, "credential-plan-fields-invalid")
    if value["schema"] != 1 or value["contract"] != CONTRACT:
        fail("credential-plan-version-invalid")
    if value["profile"] != profile["profile"]:
        fail("credential-profile-mismatch")
    if value["profile_sha256"] != profile_digest(profile):
        fail("credential-profile-digest-mismatch")
    if value["custodian"] != "root-systemd-creds":
        fail("credential-custodian-invalid")
    topology = value["topology"]
    if topology not in TOPOLOGIES:
        fail("credential-topology-invalid")
    read = validate_role(value["read"], "credential-read-invalid")
    write = validate_role(value["write"], "credential-write-invalid")
    expected_scopes = set(profile["expected_scopes"])

    if topology == "user-read-bot-write":
        if (
            profile["provider_mode"] != "web-api"
            or profile["writes"] != "single-transaction"
            or read != {
                "credential": "slack-access-read",
                "kind": "user",
                "scopes": sorted(expected_scopes - {"chat:write"}),
            }
            or write != {
                "credential": "slack-access-write",
                "kind": "bot",
                "scopes": ["chat:write"],
            }
        ):
            fail("credential-topology-profile-mismatch")
        exposure = {
            "read_rotator": ["slack-client-secret", "slack-refresh-read"],
            "read_service": ["slack-access-read"],
            "write_rotator": ["slack-client-secret", "slack-refresh-write"],
            "write_transaction": ["slack-access-write"],
        }
    elif topology == "bot-read":
        if (
            profile["provider_mode"] != "web-api"
            or profile["writes"] != "disabled"
            or read != {
                "credential": "slack-access-read",
                "kind": "bot",
                "scopes": sorted(expected_scopes),
            }
            or write != {"credential": None, "kind": "none", "scopes": []}
        ):
            fail("credential-topology-profile-mismatch")
        exposure = {
            "read_rotator": ["slack-client-secret", "slack-refresh-read"],
            "read_service": ["slack-access-read"],
            "write_rotator": [],
            "write_transaction": [],
        }
    else:
        if (
            profile["provider_mode"] != "external-runtime"
            or read != {"credential": None, "kind": "none", "scopes": []}
            or write != {"credential": None, "kind": "none", "scopes": []}
        ):
            fail("credential-topology-profile-mismatch")
        exposure = {key: [] for key in EXPOSURE_KEYS}
    validate_exposure(value["exposure"], exposure)

    rotation = value["rotation"]
    if not isinstance(rotation, dict):
        fail("credential-rotation-invalid")
    broker.exact_keys(rotation, ROTATION_KEYS, "credential-rotation-invalid")
    expected_rotation = (
        {
            "access_ttl_seconds": 43200,
            "enabled": True,
            "rollback_generations": 1,
            "rotate_after_seconds": 28800,
            "triggers": ["boot", "resume", "timer"],
        }
        if topology != "external-structured"
        else {
            "access_ttl_seconds": 0,
            "enabled": False,
            "rollback_generations": 0,
            "rotate_after_seconds": 0,
            "triggers": [],
        }
    )
    if rotation != expected_rotation:
        fail("credential-rotation-invalid")
    return value


def rotation_decision(plan: dict[str, Any], role: str, state: dict[str, Any]) -> dict[str, Any]:
    broker.exact_keys(
        state,
        {"access_age_seconds", "access_state", "refresh_state", "trigger"},
        "credential-rotation-state-invalid",
    )
    if role not in {"read", "write"} or plan[role]["kind"] == "none":
        fail("credential-rotation-role-invalid")
    if state["trigger"] not in plan["rotation"]["triggers"]:
        fail("credential-rotation-trigger-invalid")
    age = broker.bounded_int(
        state["access_age_seconds"], 0, 7 * 24 * 60 * 60, "credential-access-age-invalid"
    )
    access = state["access_state"]
    refresh = state["refresh_state"]
    if access not in {"absent", "expired", "ready"}:
        fail("credential-access-state-invalid")
    if refresh not in {"absent", "ambiguous", "available", "consumed"}:
        fail("credential-refresh-state-invalid")
    if refresh == "ambiguous":
        action, status, reason = "stop-no-retry", "repair-required", "refresh-ambiguous"
    elif refresh == "consumed":
        action, status, reason = "stop-no-retry", "renewal-required", "refresh-consumed"
    elif access == "ready" and age < plan["rotation"]["rotate_after_seconds"]:
        action, status, reason = "none", "ready", "access-current"
    elif refresh == "available":
        action, status, reason = "exchange-once", "rotating", "rotation-due"
    else:
        action, status, reason = "stop-no-retry", "renewal-required", "refresh-unavailable"
    return {
        "action": action,
        "contract": CONTRACT,
        "profile": plan["profile"],
        "reason": reason,
        "role": role,
        "schema": 1,
        "status": status,
    }


def write_preflight(plan: dict[str, Any], state: dict[str, Any]) -> dict[str, Any]:
    broker.exact_keys(
        state,
        {"bot_membership", "grant_matches", "provider_identity", "target_matches", "transaction_state"},
        "credential-write-state-invalid",
    )
    if plan["topology"] != "user-read-bot-write":
        return write_result(plan, False, "write-credential-absent")
    for field in ("bot_membership", "grant_matches", "provider_identity", "target_matches"):
        if not isinstance(state[field], bool):
            fail("credential-write-state-invalid")
    if state["transaction_state"] != "fresh":
        return write_result(plan, False, "write-transaction-not-fresh")
    for field, reason in (
        ("provider_identity", "write-provider-identity-mismatch"),
        ("target_matches", "write-target-readback-mismatch"),
        ("bot_membership", "write-bot-not-member"),
        ("grant_matches", "write-grant-mismatch"),
    ):
        if not state[field]:
            return write_result(plan, False, reason)
    return write_result(plan, True, "consume-before-single-attempt")


def write_result(plan: dict[str, Any], ready: bool, reason: str) -> dict[str, Any]:
    return {
        "contract": CONTRACT,
        "profile": plan["profile"],
        "ready": ready,
        "reason": reason,
        "schema": 1,
    }


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="command", required=True)
    validate = commands.add_parser("validate-plan")
    validate.add_argument("--profile", required=True)
    validate.add_argument("--plan", required=True)
    rotate = commands.add_parser("rotation-decision")
    rotate.add_argument("--profile", required=True)
    rotate.add_argument("--plan", required=True)
    rotate.add_argument("--role", choices=("read", "write"), required=True)
    rotate.add_argument("--state", required=True)
    write = commands.add_parser("write-preflight")
    write.add_argument("--profile", required=True)
    write.add_argument("--plan", required=True)
    write.add_argument("--state", required=True)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        profile = broker.validate_profile(broker.load_json(args.profile))
        plan = validate_plan(profile, broker.load_json(args.plan))
        if args.command == "validate-plan":
            output: object = {
                "contract": CONTRACT,
                "profile": plan["profile"],
                "schema": 1,
                "status": "valid",
            }
        elif args.command == "rotation-decision":
            output = rotation_decision(plan, args.role, broker.load_json(args.state))
        elif args.command == "write-preflight":
            output = write_preflight(plan, broker.load_json(args.state))
        else:  # pragma: no cover
            fail("credential-command-invalid")
    except broker.ContractError as exc:
        print(f"SLACK_CREDENTIALS status=failed reason={exc}", file=sys.stderr)
        return 2
    print(broker.canonical_json(output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
