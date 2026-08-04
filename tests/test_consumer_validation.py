"""Focused synthetic tests for proportional consumer validation."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from consumer_validation import (
    CHANGE_CLASSES,
    CHECK_NAME,
    CHECKPOINTS,
    EVIDENCE_FIELDS,
    EVIDENCE_STATUSES,
    IDENTITY,
    MAX_CHANGES,
    MAX_CHECKS,
    MAX_ID_LENGTH,
    MAX_INPUT_BYTES,
    MAX_PATH_LENGTH,
    REPOSITORY_CHECKS,
    REQUEST_FIELDS,
    ValidationPlanError,
    describe_validation,
    plan_validation,
)
from local_skill_discovery import (
    MAX_DISCOVERY_ENTRIES,
    LocalSkillDiscoveryError,
    discover_local_skills,
)


def request(**updates: object) -> dict[str, object]:
    value: dict[str, object] = {
        "checkpoint": "implementation",
        "changes": [
            {"path": "tools/example.py", "class": "implementation"},
            {"path": "tests/test_example.py", "class": "implementation"},
        ],
        "owning_checks": ["example-tests"],
        "skill_validators": [],
        "target_identity": "target-one",
        "environment_contract": "environment-one",
        "acceptance_scope": "scope-one",
        "prior_evidence": None,
    }
    value.update(updates)
    return value


def evidence(**updates: object) -> dict[str, object]:
    value: dict[str, object] = {
        "status": "pass",
        "target_identity": "target-one",
        "environment_contract": "environment-one",
        "acceptance_scope": "scope-one",
        "owning_checks": ["example-tests"],
        "skill_validators": [],
    }
    value.update(updates)
    return value


class PlannerTests(unittest.TestCase):
    def assertDenied(self, reason: str, value: object) -> None:
        with self.assertRaisesRegex(ValidationPlanError, f"^{reason}$"):
            plan_validation(value)

    @staticmethod
    def run_cli(
        *arguments: str,
        input_value: object | None = None,
        raw_input: bytes | None = None,
    ) -> subprocess.CompletedProcess[bytes]:
        if raw_input is not None:
            payload = raw_input
        else:
            payload = (
                b"" if input_value is None else json.dumps(input_value).encode("utf-8")
            )
        return subprocess.run(
            [sys.executable, str(ROOT / "tools/consumer_validation.py"), *arguments],
            input=payload,
            capture_output=True,
            check=False,
        )

    def test_descriptor_is_bounded_deterministic_and_matches_parser(self) -> None:
        first = self.run_cli("--describe")
        second = self.run_cli("--describe")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stdout, second.stdout)
        self.assertLessEqual(len(first.stdout), 1_500)
        value = json.loads(first.stdout)
        self.assertEqual(value, describe_validation())
        self.assertEqual(set(value["request_fields"]), REQUEST_FIELDS)
        self.assertEqual(set(value["checkpoint_enum"]), CHECKPOINTS)
        self.assertEqual(set(value["change"]["class_enum"]), CHANGE_CLASSES)
        self.assertEqual(value["change"]["max_items"], MAX_CHANGES)
        self.assertEqual(value["change"]["path_max_chars"], MAX_PATH_LENGTH)
        self.assertEqual(value["check_lists"]["item_pattern"], CHECK_NAME.pattern)
        self.assertEqual(value["check_lists"]["max_items"], MAX_CHECKS)
        self.assertEqual(value["identity_fields"]["item_pattern"], IDENTITY.pattern)
        self.assertEqual(value["identity_fields"]["max_chars"], MAX_ID_LENGTH)
        self.assertEqual(set(value["prior_evidence"]["fields"]), EVIDENCE_FIELDS)
        self.assertEqual(set(value["prior_evidence"]["status_enum"]), EVIDENCE_STATUSES)
        self.assertEqual(value["input_max_bytes"], MAX_INPUT_BYTES)
        self.assertEqual(
            plan_validation(value["minimal_example"])["route"], "record-only"
        )

    def test_cli_rejects_arguments_and_malformed_input_value_free(self) -> None:
        for argument in ("--help", "--unknown", "describe"):
            with self.subTest(argument=argument):
                result = self.run_cli(argument, input_value=request())
                self.assertEqual(result.returncode, 1)
                self.assertEqual(
                    result.stderr,
                    b"CONSUMER_VALIDATION status=failed reason=arguments-invalid\n",
                )
        malformed = self.run_cli(raw_input=b"not-json")
        self.assertEqual(malformed.returncode, 1)
        self.assertEqual(
            malformed.stderr,
            b"CONSUMER_VALIDATION status=failed reason=input-invalid\n",
        )

    def test_normal_cli_output_remains_byte_compatible(self) -> None:
        result = self.run_cli(input_value=request())
        expected = (
            b'{"authority":"unchanged","check_classes":["owning-focused-tests",'
            b'"ledger-validation","whitespace-unstaged","whitespace-cached",'
            b'"consumer-boundary"],"complete_validation_required":false,'
            b'"evidence_reused":false,"external_write":"not-authorized",'
            b'"owning_checks":["example-tests"],"publication":"not-authorized",'
            b'"reuse_effect":"none","reuse_reason":"no-prior-evidence",'
            b'"route":"focused","scope":"unchanged","skill_validators":[],'
            b'"source_access":"not-authorized"}\n'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, expected)

    def test_record_only_selects_only_repository_checks(self) -> None:
        result = plan_validation(
            request(
                checkpoint="record-only",
                changes=[{"path": "docs/tasks/Per-999.md", "class": "record"}],
                owning_checks=[],
            )
        )
        self.assertEqual(result["route"], "record-only")
        self.assertEqual(result["check_classes"], REPOSITORY_CHECKS)
        self.assertFalse(result["complete_validation_required"])

    def test_record_checkpoint_with_consequential_input_escalates(self) -> None:
        result = plan_validation(
            request(
                checkpoint="record-only",
                changes=[{"path": "tools/example.py", "class": "implementation"}],
            )
        )
        self.assertEqual(result["route"], "complete")
        result = plan_validation(
            request(
                checkpoint="record-only",
                changes=[{"path": "docs/tasks/Per-999.md", "class": "record"}],
            )
        )
        self.assertEqual(result["route"], "complete")

    def test_implementation_selects_owning_and_skill_checks(self) -> None:
        result = plan_validation(
            request(
                changes=[
                    {"path": "skills/example/SKILL.md", "class": "implementation"},
                    {"path": "tests/test_example.py", "class": "implementation"},
                ],
                skill_validators=["example-skill"],
            )
        )
        self.assertEqual(
            result["check_classes"],
            ("owning-focused-tests", "local-skill-validators", *REPOSITORY_CHECKS),
        )

    def test_unknown_sensitive_and_obvious_policy_paths_escalate(self) -> None:
        for change_class in (
            "unknown",
            "policy",
            "validator",
            "lifecycle",
            "credential",
            "external-write",
            "safety",
        ):
            with self.subTest(change_class=change_class):
                result = plan_validation(
                    request(
                        changes=[
                            {"path": "tests/test_example.py", "class": change_class}
                        ]
                    )
                )
                self.assertEqual(result["route"], "complete")
        result = plan_validation(
            request(changes=[{"path": "AGENTS.md", "class": "implementation"}])
        )
        self.assertEqual(result["route"], "complete")

    def test_missing_owning_or_skill_checks_escalates(self) -> None:
        self.assertEqual(
            plan_validation(request(owning_checks=[]))["route"], "complete"
        )
        self.assertEqual(
            plan_validation(
                request(
                    changes=[
                        {"path": "skills/example/SKILL.md", "class": "implementation"}
                    ]
                )
            )["route"],
            "complete",
        )

    def test_exact_evidence_reuses_focused_results(self) -> None:
        result = plan_validation(request(prior_evidence=evidence()))
        self.assertEqual(result["route"], "record-only-reuse")
        self.assertEqual(result["check_classes"], REPOSITORY_CHECKS)
        self.assertTrue(result["evidence_reused"])
        self.assertEqual(result["reuse_reason"], "exact-evidence-match")

    def test_publication_still_selects_complete_without_duplicate_focus(self) -> None:
        result = plan_validation(
            request(checkpoint="publication", prior_evidence=evidence())
        )
        self.assertEqual(result["route"], "complete")
        self.assertTrue(result["evidence_reused"])
        self.assertEqual(
            result["check_classes"], ("complete-validation", *REPOSITORY_CHECKS)
        )
        self.assertNotIn("owning-focused-tests", result["check_classes"])

    def test_each_evidence_mismatch_invalidates_reuse(self) -> None:
        cases = (
            ("status", "failed", "prior-evidence-failed"),
            ("target_identity", "target-two", "target-bytes-changed"),
            ("environment_contract", "environment-two", "environment-contract-changed"),
            ("acceptance_scope", "scope-two", "acceptance-scope-changed"),
            ("owning_checks", ["other-tests"], "owning-checks-changed"),
            ("skill_validators", ["other-skill"], "skill-validators-changed"),
        )
        for field, changed, reason in cases:
            with self.subTest(field=field):
                result = plan_validation(
                    request(prior_evidence=evidence(**{field: changed}))
                )
                self.assertFalse(result["evidence_reused"])
                self.assertEqual(result["reuse_reason"], reason)
                self.assertIn("owning-focused-tests", result["check_classes"])

    def test_malformed_and_excessive_inputs_fail_closed(self) -> None:
        unknown = request()
        unknown["extra"] = True
        self.assertDenied("request-invalid", unknown)
        self.assertDenied(
            "path-invalid",
            request(changes=[{"path": "../outside", "class": "implementation"}]),
        )
        self.assertDenied(
            "path-invalid",
            request(
                changes=[{"path": "./tests/example.py", "class": "implementation"}]
            ),
        )
        for path in (".", "tests/\nexample.py"):
            with self.subTest(path=path):
                self.assertDenied(
                    "path-invalid",
                    request(changes=[{"path": path, "class": "implementation"}]),
                )
        self.assertDenied(
            "changes-invalid",
            request(
                changes=[
                    {"path": f"tests/test-{index}.py", "class": "implementation"}
                    for index in range(65)
                ]
            ),
        )
        malformed_evidence = evidence(status=[])
        self.assertDenied(
            "evidence-invalid", request(prior_evidence=malformed_evidence)
        )

    def test_output_is_deterministic_and_never_escalates_authority(self) -> None:
        first = plan_validation(request())
        second = plan_validation(request())
        self.assertEqual(
            json.dumps(first, sort_keys=True), json.dumps(second, sort_keys=True)
        )
        self.assertEqual(first["authority"], "unchanged")
        self.assertEqual(first["scope"], "unchanged")
        self.assertEqual(first["source_access"], "not-authorized")
        self.assertEqual(first["external_write"], "not-authorized")
        self.assertEqual(first["publication"], "not-authorized")


class LocalSkillDiscoveryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="local-skill-test-")
        self.root = Path(self.temporary.name)
        for path in (
            self.root / "skills",
            self.root / ".agents/skills",
            self.root / ".claude/skills",
        ):
            path.mkdir(parents=True)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def add_skill(self, name: str, body: str = "valid") -> Path:
        skill = self.root / "skills" / name
        skill.mkdir()
        (skill / "SKILL.md").write_text(body, encoding="utf-8")
        for client in (".agents", ".claude"):
            (self.root / client / "skills" / name).symlink_to(f"../../skills/{name}")
        return skill

    @staticmethod
    def validator(_root: Path, skill: Path) -> None:
        if (skill / "SKILL.md").read_text(encoding="utf-8") != "valid":
            raise LocalSkillDiscoveryError("malformed-skill")

    def assertDiscoveryDenied(self, reason: str) -> None:
        with self.assertRaisesRegex(LocalSkillDiscoveryError, f"^{reason}$"):
            discover_local_skills(self.root, self.validator)

    def test_valid_skills_are_sorted_and_all_validated(self) -> None:
        observed: list[str] = []
        self.add_skill("zeta")
        self.add_skill("alpha")

        def validator(root: Path, skill: Path) -> None:
            self.validator(root, skill)
            observed.append(skill.name)

        self.assertEqual(discover_local_skills(self.root, validator), ("alpha", "zeta"))
        self.assertEqual(observed, ["alpha", "zeta"])

    def test_missing_extra_symlinked_and_malformed_entries_fail_closed(self) -> None:
        self.assertDiscoveryDenied("skill-count-invalid")

        skill = self.add_skill("alpha")
        (self.root / ".agents/skills/alpha").unlink()
        self.assertDiscoveryDenied("local-link-missing")
        (self.root / ".agents/skills/alpha").symlink_to("../../skills/alpha")

        (self.root / ".agents/skills/extra").symlink_to(skill)
        self.assertDiscoveryDenied("local-link-extra")
        (self.root / ".agents/skills/extra").unlink()

        (self.root / ".agents/skills/extra").write_text("extra", encoding="utf-8")
        self.assertDiscoveryDenied("local-link-extra")
        (self.root / ".agents/skills/extra").unlink()

        expected_link = self.root / ".agents/skills/alpha"
        expected_link.unlink()
        expected_link.write_text("invalid", encoding="utf-8")
        self.assertDiscoveryDenied("discovery-entry-invalid")
        expected_link.unlink()
        expected_link.symlink_to("../../skills/alpha")

        (skill / "SKILL.md").write_text("malformed", encoding="utf-8")
        self.assertDiscoveryDenied("malformed-skill")

        for client in (".agents", ".claude"):
            (self.root / client / "skills/alpha").unlink()
        for child in skill.iterdir():
            child.unlink()
        skill.rmdir()
        target = self.root / "target"
        target.mkdir()
        (self.root / "skills/alpha").symlink_to(target)
        self.assertDiscoveryDenied("skill-entry-invalid")

    def test_malformed_and_unresolved_links_fail_closed(self) -> None:
        self.add_skill("alpha")
        link = self.root / ".agents/skills/alpha"
        link.unlink()
        link.symlink_to(self.root / "skills/alpha")
        self.assertDiscoveryDenied("local-link-malformed")
        link.unlink()
        link.symlink_to(self.root / "missing")
        self.assertDiscoveryDenied("local-link-unresolved")

    def test_discovery_directory_limit_precedes_entry_processing(self) -> None:
        self.add_skill("alpha")
        discovery = self.root / ".agents/skills"
        for index in range(MAX_DISCOVERY_ENTRIES):
            (discovery / f"extra-{index:03d}").symlink_to(self.root / "missing")
        self.assertDiscoveryDenied("discovery-count-invalid")


if __name__ == "__main__":
    unittest.main()
