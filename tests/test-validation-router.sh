#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VALIDATE=$ROOT/libexec/harness-validate

plan() {
    "$VALIDATE" --plan "$@"
}

python3 - "$VALIDATE" "$ROOT" <<'PY'
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
from types import SimpleNamespace

if not __debug__:
    raise SystemExit("validation-router test requires Python assertions")

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
        ["docs/tasks/T-999.md"],
        "R0",
        ["tests/test-task-ledger-routing.sh"],
        True,
    ),
    (
        ["docs/history/TODO-full-archive-2099-12-31.md"],
        "R0",
        ["tests/test-task-ledger-routing.sh"],
        True,
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
        ["shared/skills/operate-native-hpc/references/execute-monitor.md"],
        "R1",
        [
            "tests/test-skill-context-budgets.sh",
            "tests/test-skill-context-gates.sh",
        ],
        False,
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
        ["shared/skills/onboard-personal-mac/references/bash-startup.md"],
        "R1",
        [
            "tests/test-onboard-personal-mac-skill.sh",
            "tests/test-skill-context-budgets.sh",
            "tests/test-skill-context-gates.sh",
        ],
        False,
    ),
    (
        ["shared/skills/onboard-mirrored-node/references/planning-interview.md"],
        "R1",
        ["tests/test-onboard-mirrored-node.sh"],
        False,
    ),
    (
        ["shared/skills/onboard-external-user/references/acceptance.md"],
        "R1",
        ["tests/test-onboard-external-user.sh"],
        True,
    ),
    (
        ["shared/skills/reboot-recovery/references/status-discovery.md"],
        "R1",
        ["tests/test-reboot-recovery-skill.sh"],
        False,
    ),
    (
        ["libexec/harness-terminfo"],
        "R2",
        ["tests/test-terminfo.sh"],
        False,
    ),
    (
        ["tests/test-terminfo.sh"],
        "R3",
        ["tests/test-phase1.sh"],
        False,
    ),
    (
        ["config/terminfo/tmux-256color.src"],
        "R2",
        ["tests/test-terminfo.sh"],
        False,
    ),
    (
        ["tests/smoke/debugger.c"],
        "R2",
        ["tests/test-debugger-readiness.sh"],
        False,
    ),
    (
        [
            "tests/fixtures/scientific-library-bin/h5cc",
            "tests/fixtures/scientific-library-bin/nc-config",
            "tests/fixtures/scientific-library-bin/pkg-config",
        ],
        "R2",
        ["tests/test-scientific-library-readiness.sh"],
        False,
    ),
    (
        [
            "config/terminfo/tmux-256color.src",
            "tests/smoke/debugger.c",
            "tests/fixtures/scientific-library-bin/h5cc",
        ],
        "R2",
        [
            "tests/test-debugger-readiness.sh",
            "tests/test-scientific-library-readiness.sh",
            "tests/test-terminfo.sh",
        ],
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
        ["docs/ci-and-merge-controls.md"],
        "R1",
        ["tests/test-actions-sustainability.sh"],
        True,
    ),
    (
        ["docs/audits/t351-autonomy-efficiency/actions-transition.md"],
        "R1",
        ["tests/test-actions-sustainability.sh"],
        True,
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

original_tmpdir = os.environ.get("TMPDIR")
try:
    os.environ["TMPDIR"] = "/tmp/validation-contract-a"
    environment_a = module["environment_contract"]("auto")
    os.environ["TMPDIR"] = "/tmp/validation-contract-b"
    environment_b = module["environment_contract"]("auto")
finally:
    if original_tmpdir is None:
        os.environ.pop("TMPDIR", None)
    else:
        os.environ["TMPDIR"] = original_tmpdir
assert environment_a["tmpdir_sha256"] != environment_b["tmpdir_sha256"]
assert set(
    (
        "home_sha256",
        "lang_sha256",
        "lc_all_sha256",
        "path_sha256",
        "pythonoptimize_sha256",
        "tmpdir_sha256",
    )
) <= set(environment_a)
assert "/tmp/validation-contract-a" not in json.dumps(environment_a)
original_optimize = os.environ.get("PYTHONOPTIMIZE")
try:
    os.environ["PYTHONOPTIMIZE"] = "1"
    try:
        module["validate_python_mode"]()
    except ValueError:
        pass
    else:
        raise AssertionError("optimized Python mode was accepted")
finally:
    if original_optimize is None:
        os.environ.pop("PYTHONOPTIMIZE", None)
    else:
        os.environ["PYTHONOPTIMIZE"] = original_optimize

with tempfile.TemporaryDirectory() as raw_receipts:
    receipt_dir = Path(raw_receipts)
    identity = {"cacheable": True, "identity_sha256": "a" * 64}
    payload = {"identity": identity, "result": {"status": "pass"}}
    data = module["canonical_json"](payload)
    digest = hashlib.sha256(data).hexdigest()
    receipt = receipt_dir / f"{identity['identity_sha256']}--{digest}.json"
    receipt.write_bytes(data)
    receipt.chmod(0o600)
    assert module["cached_receipt"](receipt_dir, identity) == receipt
    wrong_name = receipt_dir / (
        f"{identity['identity_sha256']}--{'b' * 64}.json"
    )
    receipt.rename(wrong_name)
    assert module["cached_receipt"](receipt_dir, identity) is None

with tempfile.TemporaryDirectory() as raw_repo:
    fixture = Path(raw_repo)
    subprocess.run(
        ["git", "init", "-q"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    candidate = fixture / "new.txt"
    candidate.write_text("clean\n", encoding="utf-8")
    assert module["untracked_whitespace_check"](
        fixture, ["new.txt"]
    ) == 0
    candidate.write_text("trailing whitespace \n", encoding="utf-8")
    assert module["untracked_whitespace_check"](
        fixture, ["new.txt"]
    ) == 1
    deleted_candidate = fixture / "deleted.txt"
    deleted_candidate.write_text("tracked\n", encoding="utf-8")
    subprocess.run(
        ["git", "add", "deleted.txt"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    subprocess.run(
        [
            "git", "-c", "user.name=Harness Validator",
            "-c", "user.email=validator@invalid", "commit", "-qm",
            "fixture",
        ],
        cwd=fixture,
        check=True,
        stdin=subprocess.DEVNULL,
    )
    deleted_candidate.unlink()
    subprocess.run(
        ["git", "add", "-u", "deleted.txt"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    assert module["untracked_whitespace_check"](
        fixture, ["deleted.txt"], "HEAD"
    ) == 0
    assert module["untracked_whitespace_check"](
        fixture, ["deleted.txt"]
    ) == 1
    (fixture / ".gitignore").write_text(
        "*\n!.gitignore\n", encoding="utf-8"
    )
    subprocess.run(
        ["git", "add", ".gitignore"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    candidate.unlink()
    ignored_candidate = fixture / "unexpected-top-level.sh"
    ignored_candidate.write_text("opaque\n", encoding="utf-8")
    assert module["ignored_top_level_files"](fixture) == [
        "unexpected-top-level.sh"
    ]
    assert module["untracked_whitespace_check"](
        fixture, ["unexpected-top-level.sh"]
    ) == 1

validator_globals = module["main"].__globals__
patched_names = (
    "parse_args",
    "load_rules",
    "changed_paths",
    "classify",
    "clean_tree_identity",
    "private_receipt_dir",
    "cached_receipt",
    "run_validation",
    "publish_receipt",
)
originals = {name: validator_globals[name] for name in patched_names}
identity = {
    "cacheable": True,
    "identity_sha256": "c" * 64,
}
drifted = {
    "cacheable": True,
    "identity_sha256": "d" * 64,
}
decision = {
    "cacheable": True,
    "full": False,
    "matches": [],
    "paths": ["docs/test.md"],
    "suites": [],
    "tier": "R0",
}


def identity_scenario(sequence, *, cache_hit, no_receipt=False):
    remaining = iter(sequence)

    def unexpected_receipt_call(*_args):
        raise AssertionError("receipt function called with --no-receipt")

    validator_globals.update(
        {
            "parse_args": lambda: SimpleNamespace(
                base="HEAD^",
                jobs="auto",
                no_receipt=no_receipt,
                path=[],
                plan=False,
                receipt_dir=None,
            ),
            "load_rules": lambda _root: [],
            "changed_paths": lambda _root, _base: ["docs/test.md"],
            "classify": lambda _root, _paths, _rules: decision,
            "clean_tree_identity": lambda *_args: next(remaining),
            "private_receipt_dir": (
                unexpected_receipt_call
                if no_receipt
                else (lambda *_args: Path("/tmp"))
            ),
            "cached_receipt": (
                unexpected_receipt_call
                if no_receipt
                else (
                    (lambda *_args: Path("/tmp/cached.json"))
                    if cache_hit
                    else (lambda *_args: None)
                )
            ),
            "run_validation": lambda *_args: [
                {"path": "fixture", "seconds": 0.0, "status": 0}
            ],
            "publish_receipt": (
                unexpected_receipt_call
                if no_receipt
                else lambda *_args: Path(
                    "/tmp/nonexistent-validation-receipt"
                )
            ),
        }
    )
    stdout = io.StringIO()
    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(
        io.StringIO()
    ):
        status = module["main"]()
    return status, stdout.getvalue()


try:
    assert identity_scenario([identity, drifted], cache_hit=True)[0] == 2
    assert identity_scenario([identity, drifted], cache_hit=False)[0] == 2
    assert identity_scenario(
        [identity, identity, drifted], cache_hit=False
    )[0] == 2
    status, output = identity_scenario(
        [identity, identity], cache_hit=False, no_receipt=True
    )
    assert status == 0
    assert "receipt=none-disabled" in output
finally:
    validator_globals.update(originals)

protected_r3 = [
    ".github/workflows/ci.yml",
    "tests/validation-impact.tsv",
    "tests/focused-suites.tsv",
    "libexec/harness-validate",
    "tests/guarded-test-cleanup.sh",
    "config/tmux/tmux.conf",
    "tests/smoke/debugger-readiness.sh",
    "tests/smoke/scientific-library-readiness.sh",
    "tests/fixtures/offline-project/uv.lock",
    "evaluation/evaluate.py",
    "libexec/harness-storage-readiness",
    "libexec/harness-codex-resilient",
    "libexec/harness-fleet-health",
    "libexec/harness-restic",
    "libexec/harness-ssh-config-layout",
    "libexec/harness-agent-config",
    "shared/skills/onboard-mirrored-node/scripts/onboard-preflight",
    "shared/skills/onboard-external-user/scripts/preflight",
    "shared/skills/reboot-recovery/scripts/recover-mac-after-reboot",
    "shared/skills/fleet-repository-hardening/agents/openai.yaml",
    "shared/skills/onboard-personal-mac/agents/openai.yaml",
    "tests/test-fleet-repository-hardening-skill.sh",
    "tests/test-onboard-personal-mac-skill.sh",
    "tests/test-reboot-recovery-skill.sh",
    "tests/test-task-ledger-routing.sh",
    "tests/test-github-rulesets.sh",
    "tests/test-terminfo.sh",
]
for path in protected_r3:
    result = classify(root, [path], rules)
    assert result["tier"] == "R3", (path, result)
    assert result["suites"] == ["tests/test-phase1.sh"], (path, result)
    assert result["cacheable"] is False, (path, result)
print(
    f"VALIDATION_ROUTER_CLASSIFY status=pass cases={len(cases)} "
    f"protected={len(protected_r3)}"
)
PY

docs_plan=$(plan --path TODO.md --path docs/tasks/index.tsv)
skill_plan=$(plan --path shared/skills/plan-interview-execute/SKILL.md)
ordinary_plan=$(plan \
    --path config/terminfo/tmux-256color.src \
    --path tests/smoke/debugger.c \
    --path tests/fixtures/scientific-library-bin/h5cc)
unknown_plan=$(plan --path unknown/path)

python3 - "$docs_plan" "$skill_plan" "$ordinary_plan" "$unknown_plan" <<'PY'
import json
import sys

if not __debug__:
    raise SystemExit("validation-router plan test requires Python assertions")

docs, skill, ordinary, unknown = (json.loads(value) for value in sys.argv[1:])
assert docs["tier"] == "R0"
assert docs["suites"] == ["tests/test-task-ledger-routing.sh"]
assert skill["tier"] == "R1"
assert skill["suites"] == [
    "tests/test-skill-context-budgets.sh",
    "tests/test-skill-context-gates.sh",
]
assert ordinary["tier"] == "R2"
assert ordinary["suites"] == [
    "tests/test-debugger-readiness.sh",
    "tests/test-scientific-library-readiness.sh",
    "tests/test-terminfo.sh",
]
assert unknown["tier"] == "R3"
assert unknown["suites"] == ["tests/test-phase1.sh"]
PY

printf '%s\n' 'VALIDATION_ROUTER status=pass'
