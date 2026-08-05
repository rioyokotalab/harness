#!/usr/bin/env python3
"""Focused synthetic tests for Harness's independent Har and Nit ledgers."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "tools/harness-ledgers.py"


class HarnessLedgersTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="harness-ledgers-test-")
        self.root = Path(self.temporary.name)
        for directory in ("tools", "docs/tasks", "docs/nightly/tasks"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        shutil.copy2(SOURCE, self.root / "tools/harness-ledgers.py")
        (self.root / "docs/tasks/config.json").write_text(
            json.dumps({"schema": 1, "repository": "harness", "prefix": "Har",
                        "next_id": 2, "max_active_record_words": 900}) + "\n",
            encoding="utf-8",
        )
        (self.root / "docs/tasks/index.tsv").write_text(
            "task\tstate\tsummary\tsource\n"
            "Har-001\tactive\tordinary work\tTODO.md;docs/tasks/Har-001.md\n",
            encoding="utf-8",
        )
        (self.root / "docs/tasks/Har-001.md").write_text(
            "task: Har-001\nstatus: active\nupdated: 2026-08-05\n---\n# Work\n",
            encoding="utf-8",
        )
        (self.root / "TODO.md").write_text(
            "Next free ID: Har-002.\n\n### Har-001 — Work\n",
            encoding="utf-8",
        )
        (self.root / "docs/nightly/config.json").write_text(
            json.dumps({"schema": 1, "repository": "harness", "prefix": "Nit",
                        "next_id": 1, "max_active_record_words": 900}) + "\n",
            encoding="utf-8",
        )
        (self.root / "docs/nightly/index.tsv").write_text(
            "task\tstate\tpriority\tcreated\trecord\tsummary\n",
            encoding="utf-8",
        )
        (self.root / "NIGHTLY.md").write_text(
            "Next free ID: Nit-001.\n\n"
            "| Task | State | Priority | Record |\n"
            "| --- | --- | ---: | --- |\n",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def run_tool(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, "-B", str(self.root / "tools/harness-ledgers.py"), *arguments],
            cwd=self.root, text=True, capture_output=True, check=False,
        )

    def add_nightly(self, state: str = "ready") -> None:
        (self.root / "docs/nightly/config.json").write_text(
            json.dumps({"schema": 1, "repository": "harness", "prefix": "Nit",
                        "next_id": 2, "max_active_record_words": 900}) + "\n",
            encoding="utf-8",
        )
        (self.root / "docs/nightly/index.tsv").write_text(
            "task\tstate\tpriority\tcreated\trecord\tsummary\n"
            f"Nit-001\t{state}\t10\t2026-08-05\tdocs/nightly/tasks/Nit-001.md\tnightly work\n",
            encoding="utf-8",
        )
        (self.root / "docs/nightly/tasks/Nit-001.md").write_text(
            f"task: Nit-001\nstatus: {state}\nupdated: 2026-08-05\n---\n# Nightly work\n",
            encoding="utf-8",
        )
        board_row = ""
        if state in {"ready", "active", "gated", "blocked"}:
            board_row = "| Nit-001 | " + state + " | 10 | `docs/nightly/tasks/Nit-001.md` |\n"
        (self.root / "NIGHTLY.md").write_text(
            "Next free ID: Nit-002.\n\n"
            "| Task | State | Priority | Record |\n"
            "| --- | --- | ---: | --- |\n" + board_row,
            encoding="utf-8",
        )

    def test_empty_nightly_and_active_ordinary_validate(self) -> None:
        result = self.run_tool("validate")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ordinary=1 nightly=0", result.stdout)
        self.assertIn("task=Har-001", self.run_tool("next-task").stdout)
        self.assertIn("status=idle", self.run_tool("next-nightly").stdout)

    def test_next_ids_are_independent(self) -> None:
        self.assertIn("id=Har-002", self.run_tool("next-id", "task").stdout)
        self.assertIn("id=Nit-001", self.run_tool("next-id", "nightly").stdout)

    def test_ready_nightly_is_selected_without_changing_ordinary(self) -> None:
        self.add_nightly()
        result = self.run_tool("next-nightly")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("task=Nit-001", result.stdout)
        self.assertIn("task=Har-001", self.run_tool("next-task").stdout)

    def test_nightly_record_and_board_must_agree(self) -> None:
        self.add_nightly("active")
        record = self.root / "docs/nightly/tasks/Nit-001.md"
        record.write_text(record.read_text().replace("status: active", "status: ready"))
        self.assertIn("reason=nightly-record-parity", self.run_tool("validate").stderr)

    def test_nightly_namespace_cannot_enter_ordinary_index(self) -> None:
        index = self.root / "docs/tasks/index.tsv"
        index.write_text(index.read_text() + "Nit-001\tactive\tbad\tTODO.md\n")
        self.assertIn("reason=ordinary-id", self.run_tool("validate").stderr)

    def test_retired_self_consumer_path_fails(self) -> None:
        (self.root / "PRODUCER.md").write_text("retired\n", encoding="utf-8")
        self.assertIn("reason=self-consumer-infrastructure", self.run_tool("validate").stderr)


if __name__ == "__main__":
    unittest.main()
