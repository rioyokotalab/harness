#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATE=$ROOT/libexec/harness-validate

plan() {
    "$VALIDATE" --plan "$@"
}

python3 - "$VALIDATE" "$ROOT" <<'PY'
from pathlib import Path
import runpy
import sys

validator = Path(sys.argv[1])
root = Path(sys.argv[2])
module = runpy.run_path(str(validator))
rules = module["load_rules"](root)
classify = module["classify"]

cases = [
    (
        ["TODO.md", "docs/tasks/index.tsv"],
        "R0",
        ["tests/test-task-ledger-routing.sh"],
        True,
    ),
    (
        ["docs/tasks/T-196.md"],
        "R0",
        ["tests/test-task-ledger-routing.sh"],
        True,
    ),
    (
        ["shared/skills/codex-claude-cowork/SKILL.md"],
        "R1",
        [
            "tests/test-skill-context-budgets.sh",
            "tests/test-skill-context-gates.sh",
        ],
        False,
    ),
    (
        ["shared/skills/plan-interview-execute/references/execution.md"],
        "R1",
        [
            "tests/test-skill-context-budgets.sh",
            "tests/test-skill-context-gates.sh",
        ],
        True,
    ),
    (
        ["shared/skills/fleet-repository-hardening/references/execution.md"],
        "R1",
        [
            "tests/test-fleet-repository-hardening-skill.sh",
            "tests/test-skill-context-budgets.sh",
            "tests/test-skill-context-gates.sh",
        ],
        False,
    ),
    (
        ["libexec/harness-terminfo"],
        "R2",
        ["tests/test-terminfo.sh"],
        False,
    ),
    (
        ["AGENTS.md"],
        "R3",
        ["tests/test-phase1.sh"],
        False,
    ),
    (
        [".github/workflows/ci.yml"],
        "R3",
        ["tests/test-phase1.sh"],
        False,
    ),
    (
        ["unmapped/new-file"],
        "R3",
        ["tests/test-phase1.sh"],
        False,
    ),
]
for paths, tier, suites, cacheable in cases:
    result = classify(root, paths, rules)
    assert result["tier"] == tier, (paths, result)
    assert result["suites"] == suites, (paths, result)
    assert result["cacheable"] is cacheable, (paths, result)

canonical = module["canonical_json"]({"b": 2, "a": 1})
assert canonical == b'{"a":1,"b":2}\n'
assert module["normalize_paths"](["docs/b", "docs/a", "docs/a"]) == [
    "docs/a",
    "docs/b",
]
for unsafe in ("/absolute", "../escape", "./relative"):
    try:
        module["normalize_paths"]([unsafe])
    except ValueError:
        pass
    else:
        raise AssertionError(unsafe)
PY

docs_plan=$(plan --path TODO.md --path docs/tasks/index.tsv)
skill_plan=$(plan --path shared/skills/codex-claude-cowork/SKILL.md)
unknown_plan=$(plan --path unknown/path)

python3 - "$docs_plan" "$skill_plan" "$unknown_plan" <<'PY'
import json
import sys

docs, skill, unknown = (json.loads(value) for value in sys.argv[1:])
assert docs["tier"] == "R0"
assert docs["suites"] == ["tests/test-task-ledger-routing.sh"]
assert skill["tier"] == "R1"
assert skill["suites"] == [
    "tests/test-skill-context-budgets.sh",
    "tests/test-skill-context-gates.sh",
]
assert unknown["tier"] == "R3"
assert unknown["suites"] == ["tests/test-phase1.sh"]
PY

printf '%s\n' 'VALIDATION_ROUTER status=pass cases=11'
