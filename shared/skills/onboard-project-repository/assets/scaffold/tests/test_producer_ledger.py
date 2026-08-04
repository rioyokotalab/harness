#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "tools/producer-ledger.py"
GIT = shutil.which("git")
if GIT is None:
    raise RuntimeError("git is required for producer-ledger tests")


class ProducerLedgerTests(unittest.TestCase):
    @staticmethod
    def queue_text(*tasks: str, next_id: int = 2) -> str:
        rows = "".join(
            f"| {task} | ready | 10 | `docs/producer/tasks/{task}.md` |\n"
            for task in tasks
        )
        return (
            "# Fixture producer queue\n\n"
            f"Next free ID: Fix-{next_id:03d}.\n\n"
            "## Queue\n\n"
            "| Task | State | Priority | Packet |\n"
            "| --- | --- | ---: | --- |\n"
            f"{rows}\n"
            "## Writer contract\n\nSynthetic fixture policy.\n"
        )

    def write_queue(
        self, root: Path, *tasks: str, next_id: int = 2
    ) -> None:
        (root / "PRODUCER.md").write_text(
            self.queue_text(*tasks, next_id=next_id), encoding="utf-8"
        )

    def fixture(self, *, public: bool = False) -> Path:
        root = Path(tempfile.mkdtemp(prefix="producer-ledger-test-"))
        self.addCleanup(shutil.rmtree, root)
        (root / "tools").mkdir()
        (root / "docs/producer/tasks").mkdir(parents=True)
        (root / "docs/consumer/receipts").mkdir(parents=True)
        (root / "docs/tasks").mkdir(parents=True)
        shutil.copy2(SOURCE, root / "tools/producer-ledger.py")
        config = {
            "schema": 1,
            "repository": "fixture",
            "prefix": "Fix",
            "next_id": 2,
            "public": public,
            "max_packet_bytes": 4096,
        }
        (root / "docs/producer/config.json").write_text(
            json.dumps(config), encoding="utf-8"
        )
        self.write_queue(root, "Fix-001")
        (root / "docs/producer/index.tsv").write_text(
            "task\tstate\tpriority\tcreated\tpacket\n"
            "Fix-001\tready\t10\t2026-08-02\tdocs/producer/tasks/Fix-001.md\n",
            encoding="utf-8",
        )
        (root / "docs/producer/NIGHTLY.md").write_text(
            "# Owner-started nightly contract\n", encoding="utf-8"
        )
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tactive\n", encoding="utf-8"
        )
        (root / "docs/tasks/Fix-001.md").write_text("# record\n", encoding="utf-8")
        (root / "TODO.md").write_text("# Board\n\nFix-001\n", encoding="utf-8")
        (root / "docs/producer/tasks/Fix-001.md").write_text(
            "task: Fix-001\n"
            "repository: fixture\n"
            "state: ready\n"
            "priority: 10\n"
            "created: 2026-08-02\n"
            "consumer: any\n"
            "record: docs/tasks/Fix-001.md\n"
            "authority: packet-scope-plus-closer-gates\n"
            "---\n# Objective\n\nComplete the fixture task.\n",
            encoding="utf-8",
        )
        return root

    def run_tool(self, root: Path, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(  # noqa: S603
            [sys.executable, str(root / "tools/producer-ledger.py"), *args],
            cwd=root,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def write_receipt(self, root: Path, *, status: str = "complete") -> None:
        (root / "docs/consumer/receipts/Fix-001.md").write_text(
            "task: Fix-001\n"
            f"status: {status}\n"
            "updated: 2026-08-03\n"
            "validation: pass\n"
            "---\nTerminal fixture evidence.\n",
            encoding="utf-8",
        )

    def reconcile_terminal(
        self, root: Path, *, state: str = "complete", receipt: str = "complete"
    ) -> None:
        index = root / "docs/producer/index.tsv"
        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tready\t10", f"Fix-001\t{state}\t999"
            ),
            encoding="utf-8",
        )
        (root / "TODO.md").write_text("# Board\n", encoding="utf-8")
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tidle\n", encoding="utf-8"
        )
        self.write_queue(root)
        self.write_receipt(root, status=receipt)

    def mutate_packet(self, root: Path, transform) -> None:
        path = root / "docs/producer/tasks/Fix-001.md"
        path.write_text(transform(path.read_text(encoding="utf-8")), encoding="utf-8")

    def init_git(self, root: Path) -> None:
        commands = [
            [GIT, "init", "-q"],
            [GIT, "config", "user.name", "Fixture"],
            [GIT, "config", "user.email", "fixture@example.invalid"],
            [GIT, "add", "."],
            [GIT, "commit", "-qm", "baseline"],
        ]
        for command in commands:
            subprocess.run(command, cwd=root, check=True)  # noqa: S603

    def test_valid_contract(self) -> None:
        result = self.run_tool(self.fixture(), "validate")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("reconciliation_pending=0", result.stdout)

    def test_queue_parity_rejects_omitted_duplicate_unknown_and_stale(self) -> None:
        cases = [
            ("producer-queue-omitted:Fix-001", lambda root: self.write_queue(root)),
            (
                "producer-queue-duplicate:Fix-001",
                lambda root: self.write_queue(root, "Fix-001", "Fix-001"),
            ),
            (
                "producer-queue-unknown:Fix-999",
                lambda root: self.write_queue(root, "Fix-001", "Fix-999"),
            ),
            (
                "producer-queue-stale-terminal:Fix-001",
                lambda root: (
                    self.reconcile_terminal(root),
                    self.write_queue(root, "Fix-001"),
                ),
            ),
        ]
        for reason, mutate in cases:
            with self.subTest(reason=reason):
                root = self.fixture()
                mutate(root)
                result = self.run_tool(root, "validate")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(reason, result.stdout)

    def test_queue_table_is_exact_and_descriptive_prose_is_not_authority(self) -> None:
        root = self.fixture()
        producer = root / "PRODUCER.md"
        producer.write_text(
            producer.read_text(encoding="utf-8")
            + "\nDescriptive history mentions Fix-999 without queue authority.\n",
            encoding="utf-8",
        )
        self.assertEqual(self.run_tool(root, "validate").returncode, 0)

        producer.write_text(
            producer.read_text(encoding="utf-8").replace(
                "| Task | State | Priority | Packet |",
                "| Task | State | Packet |",
            ),
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("producer-queue-format", result.stdout)

    def test_cancelled_task_is_a_stale_queue_entry(self) -> None:
        root = self.fixture()
        index = root / "docs/producer/index.tsv"
        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tready", "Fix-001\tcancelled"
            ),
            encoding="utf-8",
        )
        (root / "TODO.md").write_text("# Board\n", encoding="utf-8")
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tidle\n", encoding="utf-8"
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("producer-queue-stale-terminal:Fix-001", result.stdout)

    def test_active_record_word_ceiling_preserves_terminal_history(self) -> None:
        root = self.fixture()
        record = root / "docs/tasks/Fix-001.md"
        record.write_text(
            "task: Fix-001\nstatus: active\nupdated: 2026-08-04\n---\n"
            + ("synthetic " * 901),
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("active-record-words:Fix-001", result.stdout)

        record.write_text(
            "task: Fix-001\nstatus: active\nupdated: 2026-08-04\n---\n"
            "Compact synthetic recovery index.\n",
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)

        record.write_text(
            "task: Fix-001\nstatus: complete\nupdated: 2026-08-04\n---\n"
            + ("historical " * 901),
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_terminal_receipt_is_not_selected_while_reconciliation_pends(self) -> None:
        root = self.fixture()
        self.write_receipt(root)
        (root / "TODO.md").write_text("# Board\n", encoding="utf-8")
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("reconciliation_pending=1", result.stdout)
        strict = self.run_tool(root, "validate", "--require-converged")
        self.assertNotEqual(strict.returncode, 0, strict.stdout)
        self.assertIn("receipt-disposition", strict.stdout)
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=idle", selection.stdout)

    def test_terminal_handoff_must_match_active_assignment_client(self) -> None:
        root = self.fixture()
        self.write_receipt(root)
        (root / "TODO.md").write_text("# Board\n", encoding="utf-8")
        self.mutate_packet(
            root, lambda text: text.replace("consumer: any", "consumer: codex")
        )
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nclaude\tfixture\tactive\n", encoding="utf-8"
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("assignment-without-executable-task", result.stdout)

    def test_terminal_reconciliation_preserves_published_packet(self) -> None:
        root = self.fixture()
        packet = root / "docs/producer/tasks/Fix-001.md"
        before = hashlib.sha256(packet.read_bytes()).hexdigest()
        self.reconcile_terminal(root)
        result = self.run_tool(root, "validate", "--require-converged")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(hashlib.sha256(packet.read_bytes()).hexdigest(), before)

    def test_terminal_disposition_requires_matching_receipt(self) -> None:
        root = self.fixture()
        self.reconcile_terminal(root)
        (root / "docs/consumer/receipts/Fix-001.md").unlink()
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("terminal-receipt", result.stdout)

    def test_reconciled_terminal_assignment_must_be_idle(self) -> None:
        root = self.fixture()
        self.reconcile_terminal(root)
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tactive\n", encoding="utf-8"
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("assignment-without-executable-task", result.stdout)
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tidle\n", encoding="utf-8"
        )
        result = self.run_tool(root, "validate", "--require-converged")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_next_ready_ignores_terminal_receipts(self) -> None:
        root = self.fixture()
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=ready task=Fix-001", selection.stdout)
        self.write_receipt(root, status="blocked")
        (root / "TODO.md").write_text("# Board\n", encoding="utf-8")
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nany\tfixture\tidle\n", encoding="utf-8"
        )
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=idle", selection.stdout)

    def test_reversible_gate_is_queue_local_and_preserves_partial_record(self) -> None:
        root = self.fixture()
        config_path = root / "docs/producer/config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        config["next_id"] = 3
        config_path.write_text(json.dumps(config), encoding="utf-8")
        self.write_queue(root, "Fix-001", "Fix-002", next_id=3)
        (root / "docs/producer/index.tsv").write_text(
            "task\tstate\tpriority\tcreated\tpacket\n"
            "Fix-001\tready\t10\t2026-08-02\tdocs/producer/tasks/Fix-001.md\n"
            "Fix-002\tready\t20\t2026-08-03\tdocs/producer/tasks/Fix-002.md\n",
            encoding="utf-8",
        )
        (root / "docs/producer/tasks/Fix-002.md").write_text(
            "task: Fix-002\n"
            "repository: fixture\n"
            "state: ready\n"
            "priority: 20\n"
            "created: 2026-08-03\n"
            "consumer: any\n"
            "record: docs/tasks/Fix-002.md\n"
            "authority: packet-scope-plus-closer-gates\n"
            "---\n# Objective\n\nComplete the second fixture task.\n",
            encoding="utf-8",
        )
        (root / "docs/tasks/Fix-002.md").write_text(
            "# second record\n", encoding="utf-8"
        )
        (root / "TODO.md").write_text(
            "# Board\n\nFix-001\nFix-002\n", encoding="utf-8"
        )
        first_record = root / "docs/tasks/Fix-001.md"
        receipt = root / "docs/consumer/receipts/Fix-001.md"
        before = first_record.read_bytes()

        index = root / "docs/producer/index.tsv"
        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tready", "Fix-001\tgated"
            ),
            encoding="utf-8",
        )
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=ready task=Fix-002", selection.stdout)
        self.assertFalse(receipt.exists())
        self.assertEqual(first_record.read_bytes(), before)

        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tgated", "Fix-001\tready"
            ),
            encoding="utf-8",
        )
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=ready task=Fix-001", selection.stdout)
        self.assertFalse(receipt.exists())
        self.assertEqual(first_record.read_bytes(), before)

        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tready", "Fix-001\tgated"
            ),
            encoding="utf-8",
        )
        self.write_receipt(root, status="blocked")
        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tgated", "Fix-001\tready"
            ),
            encoding="utf-8",
        )
        (root / "TODO.md").write_text(
            "# Board\n\nFix-002\n", encoding="utf-8"
        )
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("status=ready task=Fix-002", selection.stdout)
        self.assertNotIn("task=Fix-001", selection.stdout)

    def test_ready_packet_may_await_consumer_record(self) -> None:
        root = self.fixture()
        packet = root / "docs/producer/tasks/Fix-001.md"
        packet.write_text(
            packet.read_text(encoding="utf-8").replace(
                "record: docs/tasks/Fix-001.md", "record: pending"
            ),
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_index_is_current_disposition_and_packet_state_is_publication_only(self) -> None:
        root = self.fixture()
        self.mutate_packet(
            root, lambda text: text.replace("state: ready", "state: gated")
        )
        self.assertEqual(self.run_tool(root, "validate").returncode, 0)
        selection = self.run_tool(root, "next-ready")
        self.assertEqual(selection.returncode, 0, selection.stdout)
        self.assertIn("disposition_source=docs/producer/index.tsv", selection.stdout)
        self.assertIn("packet_state=publication-only", selection.stdout)

    def test_claimed_disposition_uses_deterministic_record_without_packet_rewrite(self) -> None:
        root = self.fixture()
        packet = root / "docs/producer/tasks/Fix-001.md"
        packet.write_text(
            packet.read_text(encoding="utf-8")
            .replace("state: ready", "state: claimed")
            .replace("record: docs/tasks/Fix-001.md", "record: pending"),
            encoding="utf-8",
        )
        index = root / "docs/producer/index.tsv"
        index.write_text(
            index.read_text(encoding="utf-8").replace(
                "Fix-001\tready", "Fix-001\tclaimed"
            ),
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)
        (root / "docs/tasks/Fix-001.md").unlink()
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("task-record", result.stdout)

    def test_packet_failures_close(self) -> None:
        cases = {
            "sensitive-field": lambda text: text.replace(
                "task: Fix-001", "secret: hidden\ntask: Fix-001"
            ),
            "cross-repository-path": lambda text: text + "\n/home/other/repo\n",
            "assignment-coupling": lambda text: text + "\nharness:codex.0\n",
            "oversized": lambda text: text + ("x" * 5000),
        }
        for reason, transform in cases.items():
            with self.subTest(reason=reason):
                root = self.fixture()
                self.mutate_packet(root, transform)
                result = self.run_tool(root, "validate")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(reason, result.stdout)

    def test_public_privacy_canary_fails(self) -> None:
        root = self.fixture(public=True)
        self.mutate_packet(root, lambda text: text + "\nPRIVATE_PERSONAL_CANARY\n")
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("public-privacy-canary", result.stdout)

    def test_assignment_change_preserves_packet_bytes(self) -> None:
        root = self.fixture()
        packet = root / "docs/producer/tasks/Fix-001.md"
        before = hashlib.sha256(packet.read_bytes()).hexdigest()
        (root / "docs/producer/assignment.tsv").write_text(
            "client\tslot\tstate\nclaude\treplacement\tactive\n",
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(hashlib.sha256(packet.read_bytes()).hexdigest(), before)

    def test_unproduced_board_goal_fails(self) -> None:
        root = self.fixture()
        (root / "TODO.md").write_text("Fix-001\nFix-002\n", encoding="utf-8")
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("unproduced-board-task", result.stdout)

    def test_receipt_cannot_grant_authority(self) -> None:
        root = self.fixture()
        (root / "docs/consumer/receipts/Fix-001.md").write_text(
            "task: Fix-001\nstatus: blocked\nupdated: 2026-08-02\n"
            "validation: not-run\n---\nauthority granted: yes\n",
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("receipt-authority", result.stdout)

    def test_receipt_filename_must_match_task(self) -> None:
        root = self.fixture()
        (root / "docs/consumer/receipts/Fix-002.md").write_text(
            "task: Fix-001\nstatus: blocked\nupdated: 2026-08-03\n"
            "validation: not-run\n---\nBlocked fixture evidence.\n",
            encoding="utf-8",
        )
        result = self.run_tool(root, "validate")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("receipt-identity", result.stdout)

    def test_writer_boundaries(self) -> None:
        producer_root = self.fixture()
        self.init_git(producer_root)
        (producer_root / "PRODUCER.md").write_text(
            "# changed\nNext free ID: Fix-002.\n", encoding="utf-8"
        )
        self.assertEqual(
            self.run_tool(
                producer_root, "check-producer-diff", "--base", "HEAD"
            ).returncode,
            0,
        )
        result = self.run_tool(
            producer_root, "check-consumer-diff", "--base", "HEAD"
        )
        self.assertNotEqual(result.returncode, 0, result.stdout)

        consumer_root = self.fixture()
        self.init_git(consumer_root)
        (consumer_root / "TODO.md").write_text("Fix-001\nupdated\n", encoding="utf-8")
        self.assertEqual(
            self.run_tool(consumer_root, "check-consumer-diff", "--base", "HEAD").returncode,
            0,
        )
        result = self.run_tool(consumer_root, "check-producer-diff", "--base", "HEAD")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_producer_cannot_change_a_published_packet(self) -> None:
        root = self.fixture()
        self.init_git(root)
        self.mutate_packet(root, lambda text: text + "\nchanged\n")
        result = self.run_tool(root, "check-producer-diff", "--base", "HEAD")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("producer-immutable-packet", result.stdout)

    def test_producer_may_add_a_new_packet(self) -> None:
        root = self.fixture()
        self.init_git(root)
        packet = root / "docs/producer/tasks/Fix-002.md"
        packet.write_text("new packet\n", encoding="utf-8")
        subprocess.run(  # noqa: S603
            [GIT, "add", str(packet.relative_to(root))], cwd=root, check=True
        )
        result = self.run_tool(root, "check-producer-diff", "--base", "HEAD")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_consumer_cannot_allocate_task_record(self) -> None:
        root = self.fixture()
        self.init_git(root)
        (root / "docs/tasks/Fix-002.md").write_text("# unauthorized\n", encoding="utf-8")
        subprocess.run(  # noqa: S603
            [GIT, "add", "docs/tasks/Fix-002.md"], cwd=root, check=True
        )
        subprocess.run(  # noqa: S603
            [GIT, "commit", "-qm", "unauthorized task"],
            cwd=root,
            check=True,
        )
        result = self.run_tool(root, "check-consumer-diff", "--base", "HEAD^")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("consumer-writer-boundary", result.stdout)

    def test_consumer_diff_includes_untracked_nonignored_path(self) -> None:
        root = self.fixture()
        self.init_git(root)
        (root / "consumer-note.md").write_text("synthetic\n", encoding="utf-8")
        result = self.run_tool(root, "check-consumer-diff", "--base", "HEAD")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("role=consumer paths=1", result.stdout)

        (root / "consumer-note.md").unlink()
        producer_path = root / "docs/producer/untracked.tsv"
        producer_path.write_text("synthetic\n", encoding="utf-8")
        result = self.run_tool(root, "check-consumer-diff", "--base", "HEAD")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("consumer-writer-boundary", result.stdout)
        self.assertIn("docs/producer/untracked.tsv", result.stdout)

    def test_disjoint_producer_and_consumer_changes_merge(self) -> None:
        root = self.fixture()
        self.init_git(root)
        base = subprocess.run(  # noqa: S603
            [GIT, "branch", "--show-current"], cwd=root, check=True,
            text=True, stdout=subprocess.PIPE,
        ).stdout.strip()
        subprocess.run(  # noqa: S603
            [GIT, "checkout", "-qb", "producer"], cwd=root, check=True
        )
        assignment = root / "docs/producer/assignment.tsv"
        assignment.write_text(
            "client\tslot\tstate\nclaude\treplacement\tactive\n",
            encoding="utf-8",
        )
        subprocess.run(  # noqa: S603
            [GIT, "add", "docs/producer/assignment.tsv"], cwd=root, check=True
        )
        subprocess.run(  # noqa: S603
            [GIT, "commit", "-qm", "producer update"], cwd=root, check=True
        )
        subprocess.run(  # noqa: S603
            [GIT, "checkout", "-q", base], cwd=root, check=True
        )
        (root / "TODO.md").write_text("Fix-001\nconsumer update\n", encoding="utf-8")
        subprocess.run(  # noqa: S603
            [GIT, "add", "TODO.md"], cwd=root, check=True
        )
        subprocess.run(  # noqa: S603
            [GIT, "commit", "-qm", "consumer update"], cwd=root, check=True
        )
        result = subprocess.run(  # noqa: S603
            [GIT, "merge", "--no-edit", "producer"], cwd=root, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
