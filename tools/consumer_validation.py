"""Plan bounded repository consumer checks without granting authority."""

from __future__ import annotations

import json
import re
import sys
from pathlib import PurePosixPath

MAX_INPUT_BYTES = 16_384
MAX_CHANGES = 64
MAX_CHECKS = 32
MAX_PATH_LENGTH = 256
MAX_ID_LENGTH = 128
CHECKPOINTS = {"record-only", "implementation", "publication"}
CHANGE_CLASSES = {
    "record",
    "implementation",
    "unknown",
    "policy",
    "validator",
    "lifecycle",
    "credential",
    "external-write",
    "safety",
}
COMPLETE_CLASSES = CHANGE_CLASSES - {"record", "implementation"}
CHECK_NAME = re.compile(r"[a-z][a-z0-9-]{0,63}")
IDENTITY = re.compile(r"[A-Za-z0-9][A-Za-z0-9._:-]{0,127}")
TASK_RECORD = re.compile(r"docs/tasks/[A-Za-z0-9][A-Za-z0-9-]{0,63}[.]md")
REQUEST_FIELDS = {
    "checkpoint",
    "changes",
    "owning_checks",
    "skill_validators",
    "target_identity",
    "environment_contract",
    "acceptance_scope",
    "prior_evidence",
}
EVIDENCE_FIELDS = {
    "status",
    "target_identity",
    "environment_contract",
    "acceptance_scope",
    "owning_checks",
    "skill_validators",
}
EVIDENCE_STATUSES = {"failed", "pass"}
DESCRIBE_ARGUMENT = "--describe"
REPOSITORY_CHECKS = (
    "ledger-validation",
    "whitespace-unstaged",
    "whitespace-cached",
    "consumer-boundary",
)


class ValidationPlanError(ValueError):
    """A stable, value-free planner denial."""


def describe_validation() -> dict[str, object]:
    """Return the bounded request contract without inspecting repository state."""
    example = {
        "checkpoint": "record-only",
        "changes": [{"path": "docs/tasks/Per-000.md", "class": "record"}],
        "owning_checks": [],
        "skill_validators": [],
        "target_identity": "target",
        "environment_contract": "environment",
        "acceptance_scope": "scope",
        "prior_evidence": None,
    }
    return {
        "command": "python3 tools/consumer_validation.py --describe",
        "request_fields": sorted(REQUEST_FIELDS),
        "checkpoint_enum": sorted(CHECKPOINTS),
        "change": {
            "fields": ["class", "path"],
            "class_enum": sorted(CHANGE_CLASSES),
            "min_items": 1,
            "max_items": MAX_CHANGES,
            "path": "relative-posix",
            "path_max_chars": MAX_PATH_LENGTH,
        },
        "check_lists": {
            "fields": ["owning_checks", "skill_validators"],
            "item_pattern": CHECK_NAME.pattern,
            "max_items": MAX_CHECKS,
        },
        "identity_fields": {
            "fields": [
                "acceptance_scope",
                "environment_contract",
                "target_identity",
            ],
            "item_pattern": IDENTITY.pattern,
            "max_chars": MAX_ID_LENGTH,
        },
        "prior_evidence": {
            "nullable": True,
            "fields": sorted(EVIDENCE_FIELDS),
            "status_enum": sorted(EVIDENCE_STATUSES),
        },
        "input_max_bytes": MAX_INPUT_BYTES,
        "minimal_example": example,
    }


def _json(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def _identity(value: object) -> str:
    if not isinstance(value, str) or len(value) > MAX_ID_LENGTH:
        raise ValidationPlanError("identity-invalid")
    if IDENTITY.fullmatch(value) is None:
        raise ValidationPlanError("identity-invalid")
    return value


def _checks(value: object) -> tuple[str, ...]:
    if not isinstance(value, list) or len(value) > MAX_CHECKS:
        raise ValidationPlanError("checks-invalid")
    if any(
        not isinstance(item, str) or CHECK_NAME.fullmatch(item) is None
        for item in value
    ):
        raise ValidationPlanError("checks-invalid")
    if len(set(value)) != len(value):
        raise ValidationPlanError("checks-invalid")
    return tuple(sorted(value))


def _path(value: object) -> str:
    if not isinstance(value, str) or not value or len(value) > MAX_PATH_LENGTH:
        raise ValidationPlanError("path-invalid")
    if "\\" in value or "//" in value or any(ord(char) < 32 for char in value):
        raise ValidationPlanError("path-invalid")
    path = PurePosixPath(value)
    if (
        path.is_absolute()
        or not path.parts
        or path.as_posix() != value
        or any(part in {"", ".", ".."} for part in path.parts)
    ):
        raise ValidationPlanError("path-invalid")
    return value


def _record_path(path: str) -> bool:
    return path == "TODO.md" or TASK_RECORD.fullmatch(path) is not None


def _obviously_complete(path: str) -> bool:
    exact = {
        "AGENTS.md",
        "CLAUDE.md",
        "PRODUCER.md",
        "bin/validate",
        "tools/consumer_validation.py",
        "tools/local_skill_discovery.py",
        "tools/producer-ledger.py",
        "tools/consumer_protocol.py",
        "tools/validate-skill.py",
    }
    prefixes = (
        ".codex/",
        ".github/",
        "config/",
        "docs/policy/",
        "docs/producer/",
        "docs/consumer/receipts/",
    )
    return path in exact or path.startswith(prefixes)


def _recognized_implementation(path: str) -> bool:
    return (
        (path.startswith("tests/") and path.endswith(".py"))
        or (path.startswith("tools/") and path.endswith(".py"))
        or path.startswith("skills/")
    )


def _changes(value: object) -> tuple[tuple[str, str], ...]:
    if not isinstance(value, list) or not value or len(value) > MAX_CHANGES:
        raise ValidationPlanError("changes-invalid")
    normalized: list[tuple[str, str]] = []
    for item in value:
        if not isinstance(item, dict) or set(item) != {"path", "class"}:
            raise ValidationPlanError("change-invalid")
        path = _path(item["path"])
        change_class = item["class"]
        if not isinstance(change_class, str) or change_class not in CHANGE_CLASSES:
            raise ValidationPlanError("change-class-invalid")
        normalized.append((path, change_class))
    if len({path for path, _ in normalized}) != len(normalized):
        raise ValidationPlanError("changes-invalid")
    return tuple(sorted(normalized))


def _prior(value: object) -> dict[str, object] | None:
    if value is None:
        return None
    if not isinstance(value, dict) or set(value) != EVIDENCE_FIELDS:
        raise ValidationPlanError("evidence-invalid")
    if not isinstance(value["status"], str) or value["status"] not in EVIDENCE_STATUSES:
        raise ValidationPlanError("evidence-invalid")
    return {
        "status": value["status"],
        "target_identity": _identity(value["target_identity"]),
        "environment_contract": _identity(value["environment_contract"]),
        "acceptance_scope": _identity(value["acceptance_scope"]),
        "owning_checks": _checks(value["owning_checks"]),
        "skill_validators": _checks(value["skill_validators"]),
    }


def _reuse(
    prior: dict[str, object] | None,
    *,
    target: str,
    environment: str,
    scope: str,
    owning: tuple[str, ...],
    skills: tuple[str, ...],
) -> tuple[bool, str]:
    if prior is None:
        return False, "no-prior-evidence"
    comparisons = (
        (prior["status"] == "pass", "prior-evidence-failed"),
        (prior["target_identity"] == target, "target-bytes-changed"),
        (prior["environment_contract"] == environment, "environment-contract-changed"),
        (prior["acceptance_scope"] == scope, "acceptance-scope-changed"),
        (prior["owning_checks"] == owning, "owning-checks-changed"),
        (prior["skill_validators"] == skills, "skill-validators-changed"),
    )
    for matches, reason in comparisons:
        if not matches:
            return False, reason
    return True, "exact-evidence-match"


def plan_validation(request: object) -> dict[str, object]:
    """Return a deterministic check plan for one normalized checkpoint."""
    if not isinstance(request, dict) or set(request) != REQUEST_FIELDS:
        raise ValidationPlanError("request-invalid")
    checkpoint = request["checkpoint"]
    if not isinstance(checkpoint, str) or checkpoint not in CHECKPOINTS:
        raise ValidationPlanError("checkpoint-invalid")
    changes = _changes(request["changes"])
    owning = _checks(request["owning_checks"])
    skills = _checks(request["skill_validators"])
    target = _identity(request["target_identity"])
    environment = _identity(request["environment_contract"])
    scope = _identity(request["acceptance_scope"])
    prior = _prior(request["prior_evidence"])

    reuse, reason = _reuse(
        prior,
        target=target,
        environment=environment,
        scope=scope,
        owning=owning,
        skills=skills,
    )
    requires_complete = checkpoint == "publication"
    requires_complete = requires_complete or any(
        change_class in COMPLETE_CLASSES
        or _obviously_complete(path)
        or (change_class == "record" and not _record_path(path))
        or (change_class == "implementation" and not _recognized_implementation(path))
        for path, change_class in changes
    )
    if checkpoint == "record-only" and any(
        change_class != "record" or not _record_path(path)
        for path, change_class in changes
    ):
        requires_complete = True
    if checkpoint == "record-only" and (owning or skills):
        requires_complete = True
    if checkpoint == "implementation" and not requires_complete and (
        not owning
        or any(path.startswith("skills/") for path, _ in changes) and not skills
    ):
        requires_complete = True

    if requires_complete:
        check_classes = ("complete-validation", *REPOSITORY_CHECKS)
        route = "complete"
    elif checkpoint == "implementation":
        focused: list[str] = []
        if not reuse:
            focused.append("owning-focused-tests")
            if skills:
                focused.append("local-skill-validators")
        check_classes = (*focused, *REPOSITORY_CHECKS)
        route = "focused" if focused else "record-only-reuse"
    else:
        check_classes = REPOSITORY_CHECKS
        route = "record-only"

    return {
        "route": route,
        "check_classes": check_classes,
        "owning_checks": owning,
        "skill_validators": skills,
        "evidence_reused": reuse,
        "reuse_reason": reason,
        "reuse_effect": "focused-results-only" if reuse else "none",
        "complete_validation_required": requires_complete,
        "authority": "unchanged",
        "scope": "unchanged",
        "source_access": "not-authorized",
        "external_write": "not-authorized",
        "publication": "not-authorized",
    }


def main() -> None:
    arguments = sys.argv[1:]
    if arguments == [DESCRIBE_ARGUMENT]:
        print(_json(describe_validation()))
        return
    if arguments:
        raise SystemExit("CONSUMER_VALIDATION status=failed reason=arguments-invalid")
    raw = sys.stdin.buffer.read(MAX_INPUT_BYTES + 1)
    if not raw or len(raw) > MAX_INPUT_BYTES:
        raise SystemExit("CONSUMER_VALIDATION status=failed reason=input-size-invalid")
    try:
        request = json.loads(raw)
        result = plan_validation(request)
    except (UnicodeError, json.JSONDecodeError):
        raise SystemExit(
            "CONSUMER_VALIDATION status=failed reason=input-invalid"
        ) from None
    except ValidationPlanError as error:
        raise SystemExit(f"CONSUMER_VALIDATION status=failed reason={error}") from error
    print(_json(result))


if __name__ == "__main__":
    main()
