"""Validate value-free consumer reports and producer confirmations."""

from __future__ import annotations

import argparse
import json
import re
import sys

REQUEST_ID = r"[a-z0-9][a-z0-9-]{0,63}"
REPORT_HEAD = re.compile(
    rf"\[Agent: Personal Codex\] request_id=({REQUEST_ID}) "
    r"status=(complete|blocked|rejected|failed) confirmation_required=yes"
)
CONTINUING_CONFIRMATION = re.compile(
    rf"confirmation request_id=({REQUEST_ID}) "
    rf"status=(accepted|changes-required) next_request_id=({REQUEST_ID})"
)
TERMINAL_ACCEPTED_CONFIRMATION = re.compile(
    rf"confirmation request_id=({REQUEST_ID}) status=(accepted)"
)
REJECTED_CONFIRMATION = re.compile(
    rf"confirmation request_id=({REQUEST_ID}) status=(rejected)"
)
REPORT_FIELDS = ("subtask", "result", "evidence", "next_action")
FORBIDDEN_VALUE = re.compile(
    r"(?i)(?:/home/|/mnt/|file://|private_(?:personal|students)_canary|"
    r"(?:credential|password|secret|token)\s*[:=])"
)
MAX_BYTES = 4096
SAFE_ACTION = re.compile(r"[a-z][a-z0-9-]{0,63}")
MAX_BATCH_STAGES = 32
STAGE_FIELDS = {
    "name",
    "authority",
    "risk",
    "source",
    "effect",
    "repository",
    "client",
    "boundary",
}
SOURCES = {"none", "live", "private"}
EFFECTS = {"none", "protected-publication", "external-write"}
BOUNDARIES = {
    "none",
    "owner-choice",
    "changed-input",
    "ambiguity",
    "independent-correction",
    "independent-review",
}


class ProtocolError(ValueError):
    """A stable, value-free protocol denial."""


def plan_owner_gate(
    safe_actions: tuple[str, ...] | list[str],
    *,
    partial_record_published: bool,
    packet_prepublication_checkpoint: bool,
) -> dict[str, object]:
    """Plan safe work or one reversible owner-gate checkpoint."""
    if (
        type(partial_record_published) is not bool
        or type(packet_prepublication_checkpoint) is not bool
        or not isinstance(safe_actions, (tuple, list))
    ):
        raise ProtocolError("gate-input-invalid")
    actions = tuple(safe_actions)
    if any(
        not isinstance(action, str) or SAFE_ACTION.fullmatch(action) is None
        for action in actions
    ) or len(set(actions)) != len(actions):
        raise ProtocolError("safe-action-invalid")

    common: dict[str, object] = {
        "receipt_required": False,
        "separate_parking_request": False,
        "owner_answer": "not-supplied",
        "authority": "unchanged",
        "scope": "unchanged",
    }
    if packet_prepublication_checkpoint:
        return {
            **common,
            "continuation": "packet-checkpoint",
            "actions": ("emit-checkpoint-report",),
            "publication_required": False,
            "report_required": True,
            "owner_choice_required": False,
        }
    if actions:
        return {
            **common,
            "continuation": "execute-safe-work",
            "actions": actions,
            "publication_required": False,
            "report_required": False,
            "owner_choice_required": False,
        }

    park_actions = [] if partial_record_published else ["publish-partial-record"]
    park_actions.append("emit-owner-gate-report")
    return {
        **common,
        "continuation": "publish-and-park",
        "actions": tuple(park_actions),
        "publication_required": not partial_record_published,
        "report_required": True,
        "owner_choice_required": True,
    }


def plan_checkpoint_batches(
    stages: tuple[dict[str, object], ...] | list[dict[str, object]],
) -> dict[str, object]:
    """Batch only adjacent source-free stages with an identical frozen scope."""
    if not isinstance(stages, (tuple, list)) or not 0 < len(stages) <= MAX_BATCH_STAGES:
        raise ProtocolError("batch-stages-invalid")

    normalized: list[dict[str, str]] = []
    names: set[str] = set()
    for stage in stages:
        if not isinstance(stage, dict) or set(stage) != STAGE_FIELDS:
            raise ProtocolError("batch-stage-invalid")
        if any(not isinstance(value, str) for value in stage.values()):
            raise ProtocolError("batch-stage-invalid")
        value = dict(stage)
        for field in ("name", "authority", "risk", "repository", "client"):
            if SAFE_ACTION.fullmatch(value[field]) is None:
                raise ProtocolError(f"batch-{field}-invalid")
        if value["name"] in names:
            raise ProtocolError("batch-name-invalid")
        names.add(value["name"])
        if value["source"] not in SOURCES:
            raise ProtocolError("batch-source-invalid")
        if value["effect"] not in EFFECTS:
            raise ProtocolError("batch-effect-invalid")
        if value["boundary"] not in BOUNDARIES:
            raise ProtocolError("batch-boundary-invalid")
        normalized.append(value)

    batches: list[list[dict[str, str]]] = []
    current: list[dict[str, str]] = []
    current_scope: tuple[str, ...] | None = None
    isolated: list[str] = []

    def flush() -> None:
        nonlocal current, current_scope
        if current:
            batches.append(current)
            current = []
            current_scope = None

    for stage in normalized:
        scope = tuple(
            stage[field]
            for field in ("authority", "risk", "repository", "client")
        )
        hard_boundary = (
            stage["source"] != "none"
            or stage["effect"] == "external-write"
            or stage["boundary"] != "none"
        )
        if hard_boundary:
            flush()
            batches.append([stage])
            isolated.append(stage["name"])
            continue
        if current_scope is not None and scope != current_scope:
            flush()
        if not current:
            current_scope = scope
        current.append(stage)
    flush()

    legacy_publications = sum(
        stage["effect"] == "protected-publication" for stage in normalized
    )
    planned_publications = sum(
        any(stage["effect"] == "protected-publication" for stage in batch)
        for batch in batches
    )
    return {
        "checkpoints": tuple(
            tuple(stage["name"] for stage in batch) for batch in batches
        ),
        "isolated": tuple(isolated),
        "legacy_confirmations": len(normalized),
        "planned_confirmations": len(batches),
        "confirmations_saved": len(normalized) - len(batches),
        "legacy_publications": legacy_publications,
        "planned_publications": planned_publications,
        "publications_saved": legacy_publications - planned_publications,
        "legacy_report_budget_bytes": len(normalized) * MAX_BYTES,
        "planned_report_budget_bytes": len(batches) * MAX_BYTES,
        "round_trips_saved": len(normalized) - len(batches),
        "authority": "unchanged",
        "scope": "unchanged",
        "source_access": "not-authorized",
        "external_write": "not-authorized",
    }


def _safe_text(text: str) -> None:
    try:
        encoded = text.encode("utf-8")
    except UnicodeError as error:
        raise ProtocolError("encoding-invalid") from error
    if not encoded or len(encoded) > MAX_BYTES:
        raise ProtocolError("size-invalid")
    if "\r" in text or "\x00" in text or FORBIDDEN_VALUE.search(text):
        raise ProtocolError("value-not-safe")


def parse_report(text: str, expected_request_id: str) -> dict[str, str]:
    """Parse exactly five lines and bind the report to one expected request."""
    _safe_text(text)
    lines = text.splitlines()
    if len(lines) != 5:
        raise ProtocolError("report-line-count")
    match = REPORT_HEAD.fullmatch(lines[0])
    if match is None:
        raise ProtocolError("report-header-invalid")
    request_id, status = match.groups()
    if request_id != expected_request_id:
        raise ProtocolError("request-id-mismatch")
    values = {"request_id": request_id, "status": status}
    for line, field in zip(lines[1:], REPORT_FIELDS):
        prefix = f"{field}: "
        if not line.startswith(prefix) or not line[len(prefix) :].strip():
            raise ProtocolError(f"report-field-invalid:{field}")
        values[field] = line[len(prefix) :]
    values["confirmation_required"] = "yes"
    return values


def parse_confirmation(
    text: str,
    expected_request_id: str,
    expected_next_request_id: str | None,
) -> dict[str, str]:
    """Parse one exact envelope without broadening scope or authority."""
    _safe_text(text)
    lines = text.splitlines()
    if lines[:1] != ["[Agent: Local Codex]"] or len(lines) != 2:
        raise ProtocolError("confirmation-shape-invalid")
    continuing = CONTINUING_CONFIRMATION.fullmatch(lines[1])
    terminal_accepted = TERMINAL_ACCEPTED_CONFIRMATION.fullmatch(lines[1])
    rejected = REJECTED_CONFIRMATION.fullmatch(lines[1])
    if continuing is None and terminal_accepted is None and rejected is None:
        raise ProtocolError("confirmation-invalid")
    if continuing is not None:
        request_id, status, next_request_id = continuing.groups()
    elif terminal_accepted is not None:
        request_id, status = terminal_accepted.groups()
        next_request_id = None
    else:
        if rejected is None:
            raise ProtocolError("confirmation-invalid")
        request_id, status = rejected.groups()
        next_request_id = None
    if request_id != expected_request_id:
        raise ProtocolError("request-id-mismatch")
    if status == "accepted" and next_request_id is None:
        if expected_next_request_id is not None:
            raise ProtocolError("next-request-id-required")
        return {
            "request_id": request_id,
            "status": status,
            "continuation": "stopped",
            "authority": "unchanged",
            "scope": "unchanged",
        }
    if status == "rejected":
        return {
            "request_id": request_id,
            "status": status,
            "continuation": "stopped",
            "authority": "unchanged",
            "scope": "unchanged",
        }
    if expected_next_request_id is None:
        raise ProtocolError("next-request-id-required")
    if next_request_id != expected_next_request_id:
        raise ProtocolError("next-request-id-mismatch")
    if next_request_id == request_id:
        raise ProtocolError("next-request-id-not-new")
    return {
        "request_id": request_id,
        "status": status,
        "next_request_id": next_request_id,
        "report_request_id": next_request_id,
        "continuation": "advance" if status == "accepted" else "correct",
        "authority": "unchanged",
        "scope": "unchanged",
    }


def authorize_next_stage(
    report_text: str,
    confirmation_text: str | None,
    expected_request_id: str,
    expected_next_request_id: str | None,
) -> dict[str, str]:
    """Bind permitted continuation and its next report to the new request."""
    parse_report(report_text, expected_request_id)
    if confirmation_text is None:
        raise ProtocolError("confirmation-required")
    value = parse_confirmation(
        confirmation_text, expected_request_id, expected_next_request_id
    )
    if value["status"] == "rejected":
        raise ProtocolError("confirmation-rejected")
    if value["continuation"] == "stopped":
        raise ProtocolError("confirmation-terminal")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=("report", "confirmation", "batch-plan"))
    parser.add_argument("--request-id")
    parser.add_argument("--next-request-id")
    args = parser.parse_args()
    text = sys.stdin.read()
    try:
        if args.kind == "batch-plan":
            if args.request_id is not None or args.next_request_id is not None:
                raise ProtocolError("batch-argument-invalid")
            try:
                payload = json.loads(text)
            except (UnicodeError, json.JSONDecodeError) as error:
                raise ProtocolError("batch-input-invalid") from error
            if not isinstance(payload, dict) or set(payload) != {"stages"}:
                raise ProtocolError("batch-input-invalid")
            value = plan_checkpoint_batches(payload["stages"])
            print(
                "CONSUMER_PROTOCOL status=batch-plan-valid "
                f"legacy_confirmations={value['legacy_confirmations']} "
                f"planned_confirmations={value['planned_confirmations']} "
                f"legacy_publications={value['legacy_publications']} "
                f"planned_publications={value['planned_publications']} "
                "authority=unchanged scope=unchanged"
            )
        elif args.kind == "report":
            if args.request_id is None:
                raise ProtocolError("request-id-required")
            value = parse_report(text, args.request_id)
            print(
                "CONSUMER_PROTOCOL status=report-valid "
                f"request_id={value['request_id']} confirmation_required=yes"
            )
        else:
            if args.request_id is None:
                raise ProtocolError("request-id-required")
            value = parse_confirmation(text, args.request_id, args.next_request_id)
            continuation = value["continuation"]
            next_value = value.get("next_request_id", "none")
            print(
                "CONSUMER_PROTOCOL status=confirmation-valid "
                f"request_id={value['request_id']} continuation={continuation} "
                f"next_request_id={next_value} authority=unchanged scope=unchanged"
            )
    except ProtocolError as error:
        raise SystemExit(f"CONSUMER_PROTOCOL status=failed reason={error}") from error


if __name__ == "__main__":
    main()
