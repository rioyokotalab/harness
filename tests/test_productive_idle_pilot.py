#!/usr/bin/env python3
"""Normative Har-383 synthetic productive-idle pilot tests."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("productive_idle_pilot", ROOT / "tools/productive_idle_pilot.py")
assert SPEC and SPEC.loader
pilot = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = pilot
SPEC.loader.exec_module(pilot)

NOW = datetime(2026, 8, 3, tzinfo=timezone.utc)
UNTIL = NOW + timedelta(hours=10)
RUN = "run-0000000000000001"


def run(command: list[str], cwd: Path) -> str:
    result = subprocess.run(command, cwd=cwd, text=True, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    return result.stdout.strip()


class Fixture:
    def __init__(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="har383-")
        self.root = Path(self.temporary.name)
        run(["git", "init", "-q"], self.root)
        run(["git", "config", "user.name", "Har383 Pilot"], self.root)
        run(["git", "config", "user.email", "pilot.invalid@example.invalid"], self.root)
        self.rows: list[tuple[str, str]] = []

    def close(self) -> None:
        self.temporary.cleanup()

    def add_card(
        self,
        number: int,
        *,
        lane: str = "reserve",
        priority: int = 10,
        authority: str = "repository-local",
        privacy: str = "public",
        state: str = "ready",
        p10: str = "unknown",
        p50: str = "30",
        p90: str = "60",
        matched: int = 0,
        validation: str = "5",
        publication: str = "5",
        conflict: str | None = None,
        predicate_key: str | None = None,
        independent: str = "true",
        target_content: bytes | None = None,
    ) -> str:
        opportunity_id = f"opp-{number:016x}"
        packet = f"docs/producer/nightly/cards/{opportunity_id}.md"
        target = f"targets/{opportunity_id}.txt"
        target_path = self.root / target
        target_path.parent.mkdir(parents=True, exist_ok=True)
        content = target_content if target_content is not None else f"target-{number}\n".encode()
        target_path.write_bytes(content)
        values = {
            "opportunity_id": opportunity_id,
            "lane": lane,
            "priority": str(priority),
            "expires_at": pilot.format_time(UNTIL + timedelta(days=1)),
            "authority": authority,
            "conflict_key": conflict or f"key-{number}",
            "privacy": privacy,
            "predicate_key": predicate_key or f"predicate-{number}",
            "predicate_identity": pilot.digest_bytes(content),
            "predicate_state": state,
            "p10_minutes": p10,
            "p50_minutes": p50,
            "p90_minutes": p90,
            "matched_receipts": str(matched),
            "validation_minutes": validation,
            "publication_minutes": publication,
            "independent_value": independent,
            "target_path": target,
        }
        card_path = self.root / packet
        card_path.parent.mkdir(parents=True, exist_ok=True)
        card_path.write_bytes(pilot.encode_metadata(pilot.CARD_FIELDS, values))
        self.rows.append((opportunity_id, packet))
        self.write_index()
        return opportunity_id

    def write_index(self) -> None:
        path = self.root / "docs/producer/nightly/index.tsv"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(pilot.encode_tsv(pilot.CATALOG_HEADER, self.rows))

    def initialize_empty(self) -> None:
        self.write_index()
        self.commit("empty catalog")

    def commit(self, message: str) -> str:
        run(["git", "add", "-A"], self.root)
        run(["git", "commit", "-q", "-m", message], self.root)
        return run(["git", "rev-parse", "HEAD"], self.root)

    def repository(self):
        return pilot.PilotRepository(self.root)

    def admit(self, repository=None):
        selected = repository or self.repository()
        selected.admit(RUN, NOW, UNTIL)
        self.commit("freeze admission")
        return selected

    def start(self, repository, *, discovery_used: bool = True) -> dict[str, object]:
        candidate = repository.next_candidate(RUN, NOW, discovery_used=discovery_used)
        if candidate.get("status") != "ready":
            raise AssertionError(candidate)
        result = repository.start(RUN, str(candidate["candidate"]), NOW, discovery_used=discovery_used)
        self.commit("checkpoint selection")
        return {**candidate, **result}


class ProductiveIdlePilotTests(unittest.TestCase):
    def setUp(self) -> None:
        self.fixtures: list[Fixture] = []

    def tearDown(self) -> None:
        for fixture in reversed(self.fixtures):
            fixture.close()

    def fixture(self) -> Fixture:
        value = Fixture()
        self.fixtures.append(value)
        return value

    def assert_rejected(self, reason: str, function, *args, **kwargs) -> None:
        with self.assertRaises(pilot.Rejected) as context:
            function(*args, **kwargs)
        self.assertEqual(str(context.exception), reason)

    def test_normative_scenarios(self) -> None:
        covered: set[str] = set()

        with self.subTest("mandatory-ready"):
            fixture = self.fixture()
            reserve = fixture.add_card(1, priority=0)
            mandatory = fixture.add_card(2, lane="mandatory", priority=99)
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = repository.next_candidate(RUN, NOW, discovery_used=True)
            self.assertEqual(selected["opportunity_id"], mandatory)
            self.assertNotEqual(selected["opportunity_id"], reserve)
            covered.add("mandatory-ready")

        with self.subTest("reserve-fits"):
            fixture = self.fixture()
            opportunity = fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["opportunity_id"], opportunity)
            covered.add("reserve-fits")

        with self.subTest("reserve-too-large"):
            fixture = self.fixture()
            fixture.add_card(1, p50="500", p90="1000")
            fixture.commit("catalog")
            repository = fixture.admit()
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "wait")
            covered.add("reserve-too-large")

        with self.subTest("authority-blocked"):
            fixture = self.fixture()
            fixture.add_card(1, authority="owner-gated")
            fixture.commit("catalog")
            self.assert_rejected("invalid-authority", fixture.repository().load_catalog)
            self.assertEqual(pilot.authority_decision("protected-publication", {"read-only"}), "skipped-blocked-receipt")
            covered.add("authority-blocked")

        with self.subTest("writer-conflict"):
            fixture = self.fixture()
            fixture.add_card(1, conflict="held")
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = repository.next_candidate(RUN, NOW, discovery_used=True, held_conflicts={"held"})
            self.assertEqual(selected["status"], "wait")
            covered.add("writer-conflict")

        with self.subTest("private-from-public"):
            self.assert_rejected("cross-repository-value-exposure", pilot.rotate_repository, ["ready:priority=1"], 0)
            covered.add("private-from-public")

        with self.subTest("stale-base"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            target = next((fixture.root / "targets").iterdir())
            target.write_text("changed\n", encoding="utf-8")
            fixture.commit("change target")
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "wait")
            covered.add("stale-base")

        with self.subTest("cached-read"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.repository()
            card = repository.load_catalog()[0]
            self.assertTrue(repository.target_ready(card))
            cache = dict(repository._freshness_cache)
            self.assertTrue(repository.target_ready(card))
            self.assertEqual(repository._freshness_cache, cache)
            covered.add("cached-read")

        with self.subTest("empty-unscanned"):
            fixture = self.fixture()
            fixture.initialize_empty()
            repository = fixture.admit()
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=False)["status"], "discovery")
            covered.add("empty-unscanned")

        with self.subTest("empty-scanned"):
            fixture = self.fixture()
            fixture.initialize_empty()
            repository = fixture.admit()
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "wait")
            covered.add("empty-scanned")

        with self.subTest("wake-event"):
            token = "a" * 64
            self.assertEqual(pilot.wake_decision(now=NOW, finalize_at=UNTIL, supplied_token=token, recorded_token=token, changed_input=True, owner_amendment=False), "reselect")
            covered.add("wake-event")

        with self.subTest("owner-interrupt"):
            token = "b" * 64
            self.assertEqual(pilot.wake_decision(now=NOW, finalize_at=UNTIL, supplied_token=token, recorded_token=token, changed_input=False, owner_amendment=True), "amend-and-reselect")
            covered.add("owner-interrupt")

        with self.subTest("card-overrun"):
            self.assertEqual(pilot.overrun_action(46, 30), "checkpoint-readmit")
            self.assertEqual(pilot.overrun_action(45, 30), "continue")
            covered.add("card-overrun")

        with self.subTest("equal-priority"):
            statuses = ["ready", "ready", "idle"]
            self.assertEqual([pilot.rotate_repository(statuses, cursor) for cursor in (2, 0)], [0, 1])
            covered.add("equal-priority")

        with self.subTest("task-local-defect"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            fixture.start(repository)
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "recover")
            covered.add("task-local-defect")

        with self.subTest("terminal-card"):
            fixture = self.fixture()
            opportunity = fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = fixture.start(repository)
            repository.receive(RUN, opportunity, "complete", str(selected["candidate"]), "c" * 64, NOW)
            fixture.commit("terminal receipt")
            self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "wait")
            covered.add("terminal-card")

        with self.subTest("dirty-admission"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.repository()
            repository.admit(RUN, NOW, UNTIL)
            self.assert_rejected("dirty-frozen-input", repository.next_candidate, RUN, NOW, discovery_used=True)
            covered.add("dirty-admission")

        with self.subTest("manifest-rewrite"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            path = fixture.root / repository.admission_path(RUN)
            path.write_bytes(path.read_bytes() + b"\n")
            fixture.commit("rewrite admission")
            self.assert_rejected("admission-rewritten", repository.load_admission, RUN)
            covered.add("manifest-rewrite")

        with self.subTest("late-catalog-card"):
            fixture = self.fixture()
            first = fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            late = fixture.add_card(2, priority=0)
            fixture.commit("late card")
            selected = repository.next_candidate(RUN, NOW, discovery_used=True)
            self.assertEqual(selected["opportunity_id"], first)
            self.assertNotEqual(selected["opportunity_id"], late)
            covered.add("late-catalog-card")

        with self.subTest("short-plan"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            self.assertEqual(fixture.repository().plan(NOW, UNTIL)["status"], "shortfall")
            covered.add("short-plan")

        with self.subTest("work-conserving"):
            fixture = self.fixture()
            opportunity = fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = repository.next_candidate(RUN, NOW, discovery_used=False)
            self.assertEqual((selected["status"], selected["opportunity_id"]), ("ready", opportunity))
            covered.add("work-conserving")

        with self.subTest("crash-after-selection"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = fixture.start(repository)
            recovery = repository.next_candidate(RUN, NOW, discovery_used=True)
            self.assertEqual((recovery["status"], recovery["candidate"]), ("recover", selected["candidate"]))
            covered.add("crash-after-selection")

        with self.subTest("duplicate-receipt"):
            fixture = self.fixture()
            opportunity = fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            selected = fixture.start(repository)
            first = repository.receive(RUN, opportunity, "complete", str(selected["candidate"]), "d" * 64, NOW)
            retry = repository.receive(RUN, opportunity, "complete", str(selected["candidate"]), "d" * 64, NOW)
            self.assertEqual((first["status"], retry["status"]), ("received", "unchanged"))
            self.assert_rejected("changed-duplicate-receipt", repository.receive, RUN, opportunity, "blocked", str(selected["candidate"]), "d" * 64, NOW)
            covered.add("duplicate-receipt")

        with self.subTest("late-wake"):
            token = "e" * 64
            self.assertEqual(pilot.wake_decision(now=UNTIL, finalize_at=UNTIL, supplied_token=token, recorded_token=token, changed_input=True, owner_amendment=False), "finalize")
            covered.add("late-wake")

        with self.subTest("lower-tail-shortage"):
            fixture = self.fixture()
            for number in range(1, 13):
                fixture.add_card(number, p10="1", p50="50", p90="100", matched=20)
            fixture.commit("catalog")
            plan = fixture.repository().plan(NOW, UNTIL)
            self.assertEqual(plan["status"], "covered")
            self.assertLess(plan["p10_minutes"], plan["usable_minutes"])
            covered.add("lower-tail-shortage")

        with self.subTest("admission-headroom"):
            fixture = self.fixture()
            for number in range(1, 13):
                fixture.add_card(number)
            fixture.commit("catalog")
            result = fixture.repository().admit(RUN, NOW, UNTIL)
            self.assertEqual(result["cards"], 12)
            covered.add("admission-headroom")

        with self.subTest("cross-repository-privacy"):
            fixture = self.fixture()
            fixture.add_card(1, privacy="private")
            fixture.commit("catalog")
            repository = fixture.admit()
            self.assertEqual(repository.public_status(RUN, NOW, discovery_used=True), {"status": "ready"})
            covered.add("cross-repository-privacy")

        with self.subTest("discovery-scope"):
            selected = pilot.discovery_scope(promotion_slot="docs/consumer/promotion.md", changed_receipts=["docs/consumer/receipts/a.md"], linked_evidence="docs/audits/a.tsv")
            self.assertEqual(len(selected), 3)
            self.assert_rejected("broad-discovery-forbidden", pilot.discovery_scope, promotion_slot="../tmp/all", changed_receipts=[], linked_evidence=None)
            covered.add("discovery-scope")

        with self.subTest("event-rewrite"):
            fixture = self.fixture()
            fixture.add_card(1)
            fixture.commit("catalog")
            repository = fixture.admit()
            fixture.start(repository)
            path = fixture.root / repository.events_path(RUN)
            path.write_text(path.read_text(encoding="utf-8").replace("\tselected\t", "\twait\t"), encoding="utf-8")
            fixture.commit("rewrite event")
            self.assert_rejected("event-prefix-rewritten", repository.next_candidate, RUN, NOW, discovery_used=True)
            covered.add("event-rewrite")

        expected = {
            row["scenario"]
            for row in pilot.parse_tsv(
                (ROOT / "docs/audits/har381-producer-lifecycle-closeout/productive-idle-scenarios.tsv").read_bytes(),
                ("scenario", "input", "decision", "invariant"),
            )
        }
        self.assertEqual(covered, expected)

    def test_schema_path_and_privacy_hostility(self) -> None:
        fixture = self.fixture()
        fixture.add_card(1)
        fixture.commit("catalog")
        index = fixture.root / "docs/producer/nightly/index.tsv"
        index.write_text("opportunity_id\tpacket\nopp-0000000000000001\t../../outside\n", encoding="utf-8")
        self.assert_rejected("invalid-catalog-identity", fixture.repository().load_catalog)

        fixture = self.fixture()
        fixture.add_card(1, predicate_key="private-canary")
        fixture.commit("canary")
        self.assert_rejected("public-privacy-canary", fixture.repository().load_catalog)

    def test_sixty_card_latency_and_value_free_rotation(self) -> None:
        repositories = []
        cards = []
        for repository_number in range(5):
            fixture = self.fixture()
            for offset in range(12):
                fixture.add_card(repository_number * 12 + offset + 1, priority=offset)
            fixture.commit("catalog")
            repository = fixture.repository()
            repositories.append(repository)
            cards.append(repository.load_catalog())
        samples: list[float] = []
        finalize = pilot.PilotRepository.finalize_at(NOW, UNTIL)
        for iteration in range(21):
            started = time.perf_counter_ns()
            statuses = ["ready" if repository.eligible(repository_cards, NOW, finalize) else "idle" for repository, repository_cards in zip(repositories, cards, strict=True)]
            self.assertIsNotNone(pilot.rotate_repository(statuses, 4))
            elapsed = (time.perf_counter_ns() - started) / 1_000_000
            if iteration:
                samples.append(elapsed)
        p95 = sorted(samples)[int(0.95 * (len(samples) - 1))]
        self.assertLessEqual(p95, 100.0, p95)
        print(f"HAR383_BENCHMARK cards=60 runs=20 p95_ms={p95:.3f}")

    def test_har381_replay_has_one_durable_wait_and_no_repeat_read(self) -> None:
        commits = run(["git", "rev-list", "--reverse", "c508483^..6870218"], ROOT).splitlines()
        self.assertEqual(len(commits), 4)
        changed = run(["git", "diff", "--name-only", "c508483", "6870218"], ROOT).splitlines()
        self.assertEqual(changed, ["docs/audits/har381-producer-lifecycle-closeout/time-slices.md"])

        fixture = self.fixture()
        fixture.initialize_empty()
        repository = fixture.admit()
        self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=False)["status"], "discovery")
        repository.checkpoint_discovery(RUN, NOW)
        fixture.commit("bounded discovery checkpoint")
        self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=False)["status"], "wait")
        receipt = repository.checkpoint_wait(RUN, NOW, discovery_used=False)
        fixture.commit("one durable wait")
        self.assertEqual(receipt["status"], "wait")
        self.assertEqual(len(repository._freshness_cache), 0)
        self.assert_rejected("duplicate-wait", repository.checkpoint_wait, RUN, NOW, discovery_used=True)
        self.assertEqual(
            pilot.wake_decision(
                now=NOW + timedelta(hours=1),
                finalize_at=pilot.PilotRepository.finalize_at(NOW, UNTIL),
                supplied_token=receipt["token"],
                recorded_token=receipt["token"],
                changed_input=False,
                owner_amendment=True,
            ),
            "amend-and-reselect",
        )

    def test_finalization_and_receipt_immutability_are_one_way(self) -> None:
        fixture = self.fixture()
        opportunity = fixture.add_card(1)
        fixture.commit("catalog")
        repository = fixture.admit()
        selected = fixture.start(repository)
        repository.receive(RUN, opportunity, "complete", str(selected["candidate"]), "f" * 64, NOW)
        fixture.commit("receipt")
        receipt_path = fixture.root / repository.receipt_path(RUN, opportunity)
        receipt_path.write_text(receipt_path.read_text(encoding="utf-8").replace("complete", "blocked"), encoding="utf-8")
        fixture.commit("rewrite receipt")
        self.assert_rejected("receipt-rewritten", repository.next_candidate, RUN, NOW, discovery_used=True)

        fixture = self.fixture()
        fixture.initialize_empty()
        repository = fixture.admit()
        final_time = pilot.PilotRepository.finalize_at(NOW, UNTIL)
        repository.checkpoint_wait(RUN, final_time, discovery_used=True)
        fixture.commit("begin finalization")
        self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True), {"status": "finalize", "reason": "one-way"})

    def test_closed_schema_caps_atomicity_and_no_change_deduplication(self) -> None:
        fixture = self.fixture()
        for number in range(1, 14):
            fixture.add_card(number)
        fixture.commit("oversized catalog")
        self.assert_rejected("catalog-cap-exceeded", fixture.repository().load_catalog)

        fixture = self.fixture()
        fixture.add_card(1)
        fixture.commit("catalog")
        repository = fixture.repository()
        with mock.patch.object(pilot.os, "replace", side_effect=OSError("synthetic interruption")):
            with self.assertRaises(OSError):
                repository.admit(RUN, NOW, UNTIL)
        self.assertFalse((fixture.root / repository.admission_path(RUN)).exists())

        fixture = self.fixture()
        content = b"same predicate\n"
        first = fixture.add_card(1, priority=1, predicate_key="same", target_content=content)
        second = fixture.add_card(2, priority=2, predicate_key="same", target_content=content)
        fixture.commit("duplicate predicates")
        repository = fixture.admit()
        selected = fixture.start(repository)
        self.assertEqual(selected["opportunity_id"], first)
        repository.receive(RUN, first, "no-change", str(selected["candidate"]), "1" * 64, NOW)
        fixture.commit("no change")
        self.assertEqual(repository.next_candidate(RUN, NOW, discovery_used=True)["status"], "wait")
        self.assertNotEqual(first, second)

    def test_acceptance_table_has_behavioral_evidence(self) -> None:
        rows = pilot.parse_tsv(
            (ROOT / "docs/audits/har381-producer-lifecycle-closeout/productive-idle-acceptance.tsv").read_bytes(),
            ("measure", "matched_baseline", "pilot_acceptance", "evidence"),
        )
        expected = {row["measure"] for row in rows}
        evidence = {
            "accepted_primary_outputs", "wait_interval_commits", "duplicate_archive_reads",
            "unchanged-runtime-revalidation", "always_read_bytes", "selector_routed_bytes",
            "card_packet_bytes", "admitted_cards", "open_catalog_cards", "selector_latency_60_cards",
            "normative_scenarios", "private_value_exposure", "writer_boundary_violations",
            "prompt_replays_after_wake", "pilot_extra_protected_transitions",
            "rollout_preparation_transitions", "billable_hosted_minutes_increase",
            "final_integrated_validation", "coverage_false_positives", "wait_with_fit_card",
            "target_replays_after_unreceipted_selection", "lower_tail_false_coverage",
            "eligible_cards_omitted_before_cap", "cross_repository_card_metadata_exposure",
            "unrelated_discovery_reads", "event_journal_rewrites",
        }
        self.assertEqual(evidence, expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
