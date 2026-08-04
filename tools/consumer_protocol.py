"""Validate value-free consumer reports and producer confirmations."""

from __future__ import annotations

import argparse
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
    for line, field in zip(lines[1:], REPORT_FIELDS, strict=True):
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
    parser.add_argument("kind", choices=("report", "confirmation"))
    parser.add_argument("--request-id", required=True)
    parser.add_argument("--next-request-id")
    args = parser.parse_args()
    text = sys.stdin.read()
    try:
        if args.kind == "report":
            value = parse_report(text, args.request_id)
            print(
                "CONSUMER_PROTOCOL status=report-valid "
                f"request_id={value['request_id']} confirmation_required=yes"
            )
        else:
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
