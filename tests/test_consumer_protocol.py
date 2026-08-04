# ruff: noqa: FLY002, ISC004
"""Focused synthetic tests for consumer stage checkpoints."""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from consumer_protocol import (
    ProtocolError,
    authorize_next_stage,
    parse_confirmation,
    parse_report,
    plan_checkpoint_batches,
    plan_owner_gate,
)

REQUEST_ID = "fixture-stage-1"
NEXT_REQUEST_ID = "fixture-stage-2"
REPORT = "\n".join(
    (
        "[Agent: Personal Codex] request_id=fixture-stage-1 "
        "status=complete confirmation_required=yes",
        "subtask: Synthetic stage",
        "result: Bounded work completed.",
        "evidence: Focused checks passed.",
        "next_action: Wait for matching confirmation.",
    )
)
CONFIRMATION = "\n".join(
    (
        "[Agent: Local Codex]",
        "confirmation request_id=fixture-stage-1 status=accepted "
        "next_request_id=fixture-stage-2",
    )
)
TERMINAL_CONFIRMATION = "\n".join(
    (
        "[Agent: Local Codex]",
        "confirmation request_id=fixture-stage-1 status=accepted",
    )
)


def stage(
    name: str,
    *,
    authority: str = "packet",
    risk: str = "low",
    source: str = "none",
    effect: str = "none",
    repository: str = "personal",
    client: str = "claude",
    boundary: str = "none",
) -> dict[str, str]:
    return {
        "name": name,
        "authority": authority,
        "risk": risk,
        "source": source,
        "effect": effect,
        "repository": repository,
        "client": client,
        "boundary": boundary,
    }


def policy_text() -> str:
    text = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    routed = ROOT / "docs/agent-policy/producer-consumer.md"
    if routed.is_file() and not routed.is_symlink():
        text += "\n" + routed.read_text(encoding="utf-8")
    return text


class ConsumerProtocolTests(unittest.TestCase):
    def assertDenied(self, reason: str, call) -> None:
        with self.assertRaisesRegex(ProtocolError, f"^{reason}$"):
            call()

    def test_exact_report_shape_is_value_free_and_bound(self) -> None:
        value = parse_report(REPORT, REQUEST_ID)
        self.assertEqual(value["request_id"], REQUEST_ID)
        self.assertEqual(value["confirmation_required"], "yes")
        self.assertEqual(
            set(value),
            {
                "request_id",
                "status",
                "confirmation_required",
                "subtask",
                "result",
                "evidence",
                "next_action",
            },
        )

    def test_report_rejects_shape_request_and_sensitive_values(self) -> None:
        cases = {
            "report-line-count": REPORT + "\nextra: no",
            "request-id-mismatch": REPORT,
            "value-not-safe": REPORT.replace(
                "Focused checks passed.", "token=synthetic"
            ),
            "report-field-invalid:evidence": REPORT.replace(
                "evidence: Focused checks passed.", "proof: passed"
            ),
        }
        for reason, value in cases.items():
            with self.subTest(reason=reason):
                expected = (
                    "different-stage" if reason == "request-id-mismatch" else REQUEST_ID
                )
                self.assertDenied(
                    reason,
                    lambda value=value, expected=expected: parse_report(
                        value, expected
                    ),
                )

    def test_request_id_uses_exact_local_transport_grammar(self) -> None:
        invalid = (
            "Fixture-stage-1",
            "fixture.stage-1",
            "a" * 65,
        )
        for request_id in invalid:
            with self.subTest(request_id=request_id):
                value = REPORT.replace(REQUEST_ID, request_id)
                self.assertDenied(
                    "report-header-invalid",
                    lambda value=value: parse_report(value, REQUEST_ID),
                )

    def test_next_stage_stops_without_confirmation(self) -> None:
        self.assertDenied(
            "confirmation-required",
            lambda: authorize_next_stage(REPORT, None, REQUEST_ID, NEXT_REQUEST_ID),
        )

    def test_accepted_and_changes_required_bind_new_report_id(self) -> None:
        for status, continuation in (
            ("accepted", "advance"),
            ("changes-required", "correct"),
        ):
            with self.subTest(status=status):
                envelope = CONFIRMATION.replace("accepted", status)
                value = authorize_next_stage(
                    REPORT, envelope, REQUEST_ID, NEXT_REQUEST_ID
                )
                self.assertEqual(value["continuation"], continuation)
                self.assertEqual(value["next_request_id"], NEXT_REQUEST_ID)
                self.assertEqual(value["report_request_id"], NEXT_REQUEST_ID)

    def test_terminal_accepted_stops_without_authorizing_another_action(self) -> None:
        value = parse_confirmation(TERMINAL_CONFIRMATION, REQUEST_ID, None)
        self.assertEqual(
            value,
            {
                "request_id": REQUEST_ID,
                "status": "accepted",
                "continuation": "stopped",
                "authority": "unchanged",
                "scope": "unchanged",
            },
        )
        self.assertDenied(
            "confirmation-terminal",
            lambda: authorize_next_stage(
                REPORT, TERMINAL_CONFIRMATION, REQUEST_ID, None
            ),
        )
        self.assertDenied(
            "confirmation-invalid",
            lambda: parse_confirmation(
                TERMINAL_CONFIRMATION + " extra=yes", REQUEST_ID, None
            ),
        )

    def test_continuing_confirmation_cli_output_is_byte_compatible(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tools/consumer_protocol.py"),
                "confirmation",
                "--request-id",
                REQUEST_ID,
                "--next-request-id",
                NEXT_REQUEST_ID,
            ],
            input=CONFIRMATION.encode("utf-8"),
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            b"CONSUMER_PROTOCOL status=confirmation-valid "
            b"request_id=fixture-stage-1 continuation=advance "
            b"next_request_id=fixture-stage-2 authority=unchanged "
            b"scope=unchanged\n",
        )

    def test_confirmation_rejects_missing_invalid_changed_or_extra_next_id(
        self,
    ) -> None:
        cases = {
            "next-request-id-required": CONFIRMATION.replace(
                " next_request_id=fixture-stage-2", ""
            ),
            "confirmation-invalid-invalid": CONFIRMATION.replace(
                NEXT_REQUEST_ID, "Fixture.stage-2"
            ),
            "next-request-id-mismatch": CONFIRMATION.replace(
                NEXT_REQUEST_ID, "fixture-stage-3"
            ),
            "confirmation-invalid-extra": CONFIRMATION + " extra=yes",
        }
        for label, envelope in cases.items():
            with self.subTest(label=label):
                reason = (
                    label
                    if label
                    in {
                        "next-request-id-required",
                        "next-request-id-mismatch",
                    }
                    else "confirmation-invalid"
                )
                self.assertDenied(
                    reason,
                    lambda envelope=envelope: parse_confirmation(
                        envelope, REQUEST_ID, NEXT_REQUEST_ID
                    ),
                )

    def test_confirmation_must_match_old_request(self) -> None:
        self.assertDenied(
            "request-id-mismatch",
            lambda: parse_confirmation(
                CONFIRMATION, "different-stage", NEXT_REQUEST_ID
            ),
        )

    def test_rejected_forbids_next_and_cannot_continue(self) -> None:
        rejected = "\n".join(
            (
                "[Agent: Local Codex]",
                "confirmation request_id=fixture-stage-1 status=rejected",
            )
        )
        value = parse_confirmation(rejected, REQUEST_ID, None)
        self.assertEqual(value["continuation"], "stopped")
        rejected_with_next = rejected + " next_request_id=fixture-stage-2"
        self.assertDenied(
            "confirmation-invalid",
            lambda: parse_confirmation(rejected_with_next, REQUEST_ID, None),
        )
        self.assertDenied(
            "confirmation-rejected",
            lambda: authorize_next_stage(REPORT, rejected, REQUEST_ID, NEXT_REQUEST_ID),
        )

    def test_matching_confirmation_does_not_escalate_authority(self) -> None:
        value = authorize_next_stage(REPORT, CONFIRMATION, REQUEST_ID, NEXT_REQUEST_ID)
        self.assertEqual(value["authority"], "unchanged")
        self.assertEqual(value["scope"], "unchanged")

    def test_accepted_confirmation_is_the_continuation_prompt(self) -> None:
        value = authorize_next_stage(REPORT, CONFIRMATION, REQUEST_ID, NEXT_REQUEST_ID)
        self.assertEqual(value["continuation"], "advance")
        self.assertEqual(value["report_request_id"], NEXT_REQUEST_ID)
        instructions = policy_text()
        self.assertIn("itself the continuation prompt", instructions)
        self.assertIn("task-specific message", instructions)
        self.assertIn("terminal checkpoint", instructions)
        self.assertIn("stops without action", instructions)

    def test_cold_start_policy_preserves_generic_protocol_groups(self) -> None:
        policy = policy_text()
        groups = {
            "selector": (
                "PRODUCER.md",
                "python3 tools/producer-ledger.py next-ready",
                "terminal receipt",
            ),
            "writers": (
                "trust-equivalent repository agents",
                "PRODUCER.md",
                "docs/producer/",
                "role-aware diff command",
            ),
            "owner-gate": (
                "safe work",
                "reversible owner",
                "no terminal receipt",
            ),
            "record": ("within 900 words",),
            "checkpoint": (
                "tools/consumer_protocol.py",
                "continuation prompt",
                "terminal checkpoint",
            ),
            "validation": (
                "tools/consumer_validation.py",
                "proportional",
                "check-consumer-diff --base origin/main",
            ),
        }
        for group, markers in groups.items():
            with self.subTest(group=group):
                for marker in markers:
                    self.assertIn(marker, policy)

    def test_safe_work_executes_before_owner_gate(self) -> None:
        value = plan_owner_gate(
            ("implement-parameterized-skill", "run-synthetic-tests"),
            partial_record_published=False,
            packet_prepublication_checkpoint=False,
        )
        self.assertEqual(value["continuation"], "execute-safe-work")
        self.assertEqual(
            value["actions"],
            ("implement-parameterized-skill", "run-synthetic-tests"),
        )
        self.assertFalse(value["report_required"])
        self.assertFalse(value["owner_choice_required"])

    def test_true_gate_publishes_and_reports_in_one_checkpoint(self) -> None:
        value = plan_owner_gate(
            (),
            partial_record_published=False,
            packet_prepublication_checkpoint=False,
        )
        self.assertEqual(value["continuation"], "publish-and-park")
        self.assertEqual(
            value["actions"],
            ("publish-partial-record", "emit-owner-gate-report"),
        )
        self.assertTrue(value["publication_required"])
        self.assertTrue(value["report_required"])
        self.assertFalse(value["receipt_required"])
        self.assertFalse(value["separate_parking_request"])

    def test_published_partial_record_is_not_republished(self) -> None:
        value = plan_owner_gate(
            (),
            partial_record_published=True,
            packet_prepublication_checkpoint=False,
        )
        self.assertEqual(value["actions"], ("emit-owner-gate-report",))
        self.assertFalse(value["publication_required"])

    def test_explicit_packet_checkpoint_precedes_safe_work_and_publication(
        self,
    ) -> None:
        value = plan_owner_gate(
            ("run-synthetic-tests",),
            partial_record_published=False,
            packet_prepublication_checkpoint=True,
        )
        self.assertEqual(value["continuation"], "packet-checkpoint")
        self.assertEqual(value["actions"], ("emit-checkpoint-report",))
        self.assertFalse(value["publication_required"])
        self.assertTrue(value["report_required"])

    def test_source_free_packet_batches_confirmations_and_publications(self) -> None:
        value = plan_checkpoint_batches(
            [
                stage("plan"),
                stage("implement"),
                stage("validate"),
                stage("publish", effect="protected-publication"),
                stage("receipt", effect="protected-publication"),
            ]
        )
        self.assertEqual(
            value["checkpoints"],
            (("plan", "implement", "validate", "publish", "receipt"),),
        )
        self.assertEqual(value["legacy_confirmations"], 5)
        self.assertEqual(value["planned_confirmations"], 1)
        self.assertEqual(value["confirmations_saved"], 4)
        self.assertEqual(value["legacy_publications"], 2)
        self.assertEqual(value["planned_publications"], 1)
        self.assertEqual(value["publications_saved"], 1)
        self.assertEqual(value["legacy_report_budget_bytes"], 20_480)
        self.assertEqual(value["planned_report_budget_bytes"], 4_096)
        self.assertEqual(value["round_trips_saved"], 4)

    def test_independent_correction_remains_its_own_checkpoint(self) -> None:
        value = plan_checkpoint_batches(
            [
                stage("plan"),
                stage("implement"),
                stage("correct", boundary="independent-correction"),
                stage("validate"),
                stage("publish", effect="protected-publication"),
                stage("receipt", effect="protected-publication"),
            ]
        )
        self.assertEqual(
            value["checkpoints"],
            (
                ("plan", "implement"),
                ("correct",),
                ("validate", "publish", "receipt"),
            ),
        )
        self.assertEqual(value["isolated"], ("correct",))
        self.assertEqual(value["planned_confirmations"], 3)
        self.assertEqual(value["planned_publications"], 1)

    def test_every_frozen_boundary_isolated_and_scope_changes_split(self) -> None:
        values = [stage("start")]
        values.extend(
            (
                stage("owner", boundary="owner-choice"),
                stage("changed", boundary="changed-input"),
                stage("unknown", boundary="ambiguity"),
                stage("correction", boundary="independent-correction"),
                stage("review", boundary="independent-review"),
                stage("live", source="live"),
                stage("private", source="private"),
                stage("write", effect="external-write"),
            )
        )
        values.extend(
            (
                stage("other-authority", authority="other"),
                stage("other-risk", authority="other", risk="high"),
                stage(
                    "other-repository",
                    authority="other",
                    risk="high",
                    repository="students",
                ),
                stage(
                    "other-client",
                    authority="other",
                    risk="high",
                    repository="students",
                    client="codex",
                ),
            )
        )
        value = plan_checkpoint_batches(values)
        self.assertEqual(
            value["isolated"],
            (
                "owner",
                "changed",
                "unknown",
                "correction",
                "review",
                "live",
                "private",
                "write",
            ),
        )
        self.assertEqual(value["planned_confirmations"], len(values))
        self.assertEqual(value["authority"], "unchanged")
        self.assertEqual(value["source_access"], "not-authorized")
        self.assertEqual(value["external_write"], "not-authorized")

    def test_batch_planner_rejects_unbounded_or_malformed_claims(self) -> None:
        cases = (
            ("batch-stages-invalid", []),
            ("batch-stages-invalid", [stage(f"s-{index}") for index in range(33)]),
            ("batch-stage-invalid", [{"name": "partial"}]),
            ("batch-source-invalid", [stage("bad-source", source="cached")]),
            ("batch-effect-invalid", [stage("bad-effect", effect="network")]),
            ("batch-boundary-invalid", [stage("bad-boundary", boundary="maybe")]),
            ("batch-name-invalid", [stage("same"), stage("same")]),
        )
        for reason, stages in cases:
            with self.subTest(reason=reason):
                self.assertDenied(
                    reason,
                    lambda stages=stages: plan_checkpoint_batches(stages),
                )

    def test_batch_plan_cli_reports_only_bounded_metrics(self) -> None:
        payload = {
            "stages": [
                stage("plan"),
                stage("publish", effect="protected-publication"),
                stage("receipt", effect="protected-publication"),
            ]
        }
        result = subprocess.run(
            [
                sys.executable,
                str(ROOT / "tools/consumer_protocol.py"),
                "batch-plan",
            ],
            input=json.dumps(payload).encode("utf-8"),
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            b"CONSUMER_PROTOCOL status=batch-plan-valid "
            b"legacy_confirmations=3 planned_confirmations=1 "
            b"legacy_publications=2 planned_publications=1 "
            b"authority=unchanged scope=unchanged\n",
        )

    def test_gate_plan_never_supplies_answer_or_authority(self) -> None:
        for value in (
            plan_owner_gate(
                ("run-synthetic-tests",),
                partial_record_published=False,
                packet_prepublication_checkpoint=False,
            ),
            plan_owner_gate(
                (),
                partial_record_published=False,
                packet_prepublication_checkpoint=False,
            ),
        ):
            self.assertEqual(value["owner_answer"], "not-supplied")
            self.assertEqual(value["authority"], "unchanged")
            self.assertEqual(value["scope"], "unchanged")
            self.assertFalse(value["receipt_required"])


if __name__ == "__main__":
    unittest.main()
