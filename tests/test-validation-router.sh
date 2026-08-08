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
import platform
import runpy
import shutil
import subprocess
import sys
import tempfile
from dataclasses import replace
from types import SimpleNamespace

if not __debug__:
    raise SystemExit("validation-router test requires Python assertions")

validator = Path(sys.argv[1])
root = Path(sys.argv[2])
module = runpy.run_path(str(validator))
rules = module["load_rules"](root)
group_rules = module["load_group_rules"](root)
focused = module["load_focused_suites"](root, group_rules)
classify = module["classify"]
configured_git = module["test_environment"]()
configured_index = int(configured_git["GIT_CONFIG_COUNT"]) - 1
assert configured_git[f"GIT_CONFIG_KEY_{configured_index}"] == "maintenance.auto"
assert configured_git[f"GIT_CONFIG_VALUE_{configured_index}"] == "false"

cases = [
    (
        ["TODO.md", "docs/tasks/index.tsv"],
        "R1",
        [
            "tests/test-context-routing-benchmark.sh",
            "tests/test-harness-ledgers.sh",
        ],
        True,
    ),
    (
        ["docs/tasks/Har-196.md"],
        "R0",
        ["tests/test-harness-ledgers.sh"],
        True,
    ),
    (
        ["docs/tasks/Har-999.md"],
        "R0",
        ["tests/test-harness-ledgers.sh"],
        True,
    ),
    (
        ["docs/history/TODO-full-archive-2099-12-31.md"],
        "R0",
        ["tests/test-harness-ledgers.sh"],
        True,
    ),
    (
        ["NIGHTLY.md", "docs/nightly/config.json", "docs/nightly/index.tsv"],
        "R1",
        ["tests/test-harness-ledgers.sh"],
        True,
    ),
    (
        ["docs/nightly/tasks/Nit-001.md"],
        "R1",
        ["tests/test-harness-ledgers.sh"],
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
        ["shared/skills/remote-agent-communication/references/local-codex.md"],
        "R1",
        [
            "tests/test-remote-agent-communication.sh",
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
        ["tests/test-terminfo.sh"],
        "R3",
        ["tests/test-terminfo.sh"],
        False,
    ),
    (
        ["libexec/harness_housekeeping.py"],
        "R3",
        [
            "tests/test-housekeeping-owner-alias.sh",
            "tests/test-housekeeping.sh",
        ],
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
        ["tests/test-agent-policy-routing.sh"],
        False,
    ),
    (
        [".github/workflows/ci.yml"],
        "R3",
        ["tests/test-actions-sustainability.sh"],
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
        [],
        False,
    ),
]
for paths, tier, suites, cacheable in cases:
    result = classify(root, paths, rules, focused, group_rules)
    assert result["tier"] == tier, (paths, result)
    shell_selected = any(
        rule.suite == "tests/test-shellcheck.sh"
        and any(rule.regex.search(path) for path in paths)
        for rule in rules
    )
    assert (
        "tests/test-shellcheck.sh" in result["suites"]
    ) is shell_selected, (paths, result)
    assert [
        suite for suite in result["suites"]
        if suite != "tests/test-shellcheck.sh"
    ] == suites, (paths, result)
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
    peer_candidate = fixture / "peer.txt"
    peer_candidate.write_text("$HOME/" + "web" + "site\n", encoding="utf-8")
    subprocess.run(
        ["git", "add", "peer.txt"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    assert module["repository_independence_check"](
        fixture, ["peer.txt"]
    ) == 1
    peer_candidate.write_text("independent\n", encoding="utf-8")
    assert module["repository_independence_check"](
        fixture, ["peer.txt"]
    ) == 0
    link = fixture / "outside-link"
    link.symlink_to(fixture.parent, target_is_directory=True)
    subprocess.run(
        ["git", "add", "outside-link"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    assert module["repository_independence_check"](
        fixture, ["outside-link"]
    ) == 1
    broken = fixture / "broken-link"
    broken.symlink_to("missing")
    subprocess.run(
        ["git", "add", "broken-link"], cwd=fixture, check=True,
        stdin=subprocess.DEVNULL,
    )
    assert module["repository_independence_check"](
        fixture, ["broken-link"]
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
    "load_group_rules",
    "load_focused_suites",
    "changed_paths",
    "classify",
    "suites_for_stage",
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
    "estimated_seconds": 0,
    "final_required": False,
    "groups": [],
    "matches": [],
    "owner_gaps": [],
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
                full=False,
                jobs="auto",
                no_receipt=no_receipt,
                path=[],
                plan=False,
                receipt_dir=None,
                stage="repair",
                suite=None,
            ),
            "load_rules": lambda _root: [],
            "load_group_rules": lambda _root: [],
            "load_focused_suites": lambda _root, _groups: {},
            "changed_paths": lambda _root, _base: ["docs/test.md"],
            "classify": lambda _root, _paths, _rules, _focused, _groups: decision,
            "suites_for_stage": lambda *_args, **_kwargs: [],
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

protected_r3 = {
    ".github/workflows/ci.yml": "tests/test-actions-sustainability.sh",
    "tests/validation-impact.tsv": "tests/test-validation-router.sh",
    "tests/validation-groups.tsv": "tests/test-validation-router.sh",
    "tests/focused-suites.tsv": "tests/test-focused-runner.sh",
    "libexec/harness-validate": "tests/test-validation-router.sh",
    "tests/guarded-test-cleanup.sh": "tests/test-guarded-delete.sh",
    "config/tmux/tmux.conf": "tests/test-tmux-config.sh",
    "evaluation/evaluate.py": "tests/test-evaluation.sh",
    "libexec/harness-storage-readiness": "tests/test-storage-readiness.sh",
    "libexec/harness-codex-resilient": "tests/test-codex-resilient.sh",
    "libexec/harness-fleet-health": "tests/test-fleet-health.sh",
    "libexec/harness-restic": "tests/test-restic-schedule.sh",
    "libexec/harness-ssh-config-layout": "tests/test-ssh-config-layout.sh",
    "libexec/harness-agent-config": "tests/test-agent-config.sh",
    "shared/skills/onboard-mirrored-node/scripts/onboard-preflight": (
        "tests/test-onboard-mirrored-node.sh"
    ),
    "shared/skills/onboard-external-user/scripts/preflight": (
        "tests/test-onboard-external-user.sh"
    ),
    "shared/skills/reboot-recovery/scripts/recover-mac-after-reboot": (
        "tests/test-reboot-recovery-skill.sh"
    ),
    "shared/skills/remote-agent-communication/scripts/agent-message": (
        "tests/test-remote-agent-communication.sh"
    ),
    "shared/skills/remote-agent-communication/agents/openai.yaml": (
        "tests/test-remote-agent-communication.sh"
    ),
    "shared/skills/remote-agent-communication/references/reply.schema.json": (
        "tests/test-remote-agent-communication.sh"
    ),
    "shared/skills/fleet-repository-hardening/agents/openai.yaml": (
        "tests/test-fleet-repository-hardening-skill.sh"
    ),
    "shared/skills/onboard-personal-mac/agents/openai.yaml": (
        "tests/test-onboard-personal-mac-skill.sh"
    ),
    "tests/test-fleet-repository-hardening-skill.sh": (
        "tests/test-fleet-repository-hardening-skill.sh"
    ),
    "tests/test-onboard-personal-mac-skill.sh": (
        "tests/test-onboard-personal-mac-skill.sh"
    ),
    "tests/test-reboot-recovery-skill.sh": "tests/test-reboot-recovery-skill.sh",
    "tests/test-github-rulesets.sh": "tests/test-github-rulesets.sh",
    "tests/test-terminfo.sh": "tests/test-terminfo.sh",
}
for path, owner in protected_r3.items():
    result = classify(root, [path], rules, focused, group_rules)
    assert result["tier"] == "R3", (path, result)
    assert owner in result["suites"], (path, result)
    assert set(result["suites"]) <= {
        owner,
        "tests/test-shellcheck.sh",
    }, (path, result)
    assert result["cacheable"] is False, (path, result)

multi = classify(
    root,
    [
        "tests/smoke/debugger.c",
        "tests/fixtures/scientific-library-bin/h5cc",
    ],
    rules,
    focused,
    group_rules,
)
assert module["suites_for_stage"](
    multi, "repair", "tests/test-debugger-readiness.sh", execute=True
) == ["tests/test-debugger-readiness.sh"]
wrong_platform_focused = dict(focused)
wrong_platform_focused["tests/test-terminfo.sh"] = replace(
    focused["tests/test-terminfo.sh"],
    platforms=frozenset(
        {"Darwin"} if platform.system() == "Linux" else {"Linux"}
    ),
)
wrong_platform = classify(
    root,
    ["config/terminfo/tmux-256color.src"],
    rules,
    wrong_platform_focused,
    group_rules,
)
try:
    module["suites_for_stage"](
        wrong_platform, "repair", "tests/test-terminfo.sh", execute=True
    )
except ValueError:
    pass
else:
    raise AssertionError("wrong-platform repair owner was executable")
try:
    module["suites_for_stage"](multi, "repair", None, execute=True)
except ValueError:
    pass
else:
    raise AssertionError("multi-owner repair was accepted without --suite")
assert module["suites_for_stage"](
    multi, "discovery", None, execute=True
) == [
    "tests/test-debugger-readiness.sh",
    "tests/test-scientific-library-readiness.sh",
]
assert module["suites_for_stage"](multi, "final", None, execute=True) == [
    "tests/test-debugger-readiness.sh",
    "tests/test-scientific-library-readiness.sh",
]
assert module["suites_for_stage"](
    multi, "final", None, execute=True, full=True
) == [
    "tests/test-phase1.sh"
]
owner_gap = classify(root, ["unmapped/new-file"], rules, focused, group_rules)
try:
    module["suites_for_stage"](owner_gap, "final", None, execute=True)
except ValueError as error:
    assert "owner gaps" in str(error)
else:
    raise AssertionError("ownerless final validation was accepted")
try:
    module["suites_for_stage"](
        owner_gap, "final", None, execute=True, full=True
    )
except ValueError as error:
    assert "owner gaps" in str(error)
else:
    raise AssertionError("explicit full hid an owner gap")
mixed_gap = classify(
    root,
    ["config/terminfo/tmux-256color.src", "unmapped/new-file"],
    rules,
    focused,
    group_rules,
)
assert mixed_gap["suites"] == ["tests/test-terminfo.sh"]
assert mixed_gap["owner_gaps"] == ["unmapped/new-file"]
try:
    module["suites_for_stage"](mixed_gap, "final", None, execute=True)
except ValueError as error:
    assert "unmapped/new-file" in str(error)
else:
    raise AssertionError("mixed owner gap was hidden by a selected suite")
docs_only = classify(root, ["docs/ordinary.md"], rules, focused, group_rules)
assert docs_only["owner_gaps"] == []
assert module["suites_for_stage"](
    docs_only, "final", None, execute=True
) == []

with tempfile.TemporaryDirectory() as raw_discovery:
    discovery_root = Path(raw_discovery)
    (discovery_root / "tools").mkdir()
    (discovery_root / "tests").mkdir()
    shutil.copy2(
        root / "tools/run-focused-tests.py",
        discovery_root / "tools/run-focused-tests.py",
    )
    for name, body in (
        ("fail", "#!/bin/sh\nprintf 'known failure\\n'\nexit 7\n"),
        ("pass", "#!/bin/sh\nprintf 'later pass\\n'\n"),
    ):
        path = discovery_root / f"tests/{name}.sh"
        path.write_text(body, encoding="utf-8")
        path.chmod(0o755)
    (discovery_root / "tests/focused-suites.tsv").write_text(
        "tests/fail.sh|known failure|2\n"
        "tests/pass.sh|later pass|1\n",
        encoding="utf-8",
    )
    discovery_focused = {
        "tests/fail.sh": module["FocusedSuite"](
            1, "tests/fail.sh", "known failure", 2, "light", "fixture"
        ),
        "tests/pass.sh": module["FocusedSuite"](
            2, "tests/pass.sh", "later pass", 1, "light", "fixture"
        ),
    }
    discovery_decision = {
        "groups": [{"name": "fixture"}],
        "paths": ["fixture"],
        "suites": ["tests/fail.sh", "tests/pass.sh"],
    }
    original_run_validation = module["run_discovery"].__globals__["run_validation"]
    module["run_discovery"].__globals__["run_validation"] = (
        lambda *_args: [{"path": "diff", "seconds": 0.0, "status": 0}]
    )
    try:
        results, inventory_path = module["run_discovery"](
            discovery_root,
            "HEAD^",
            discovery_decision,
            "1",
            discovery_root,
            discovery_focused,
        )
        structural_results, structural_path = module["run_discovery"](
            discovery_root,
            "HEAD^",
            {"groups": [], "paths": ["docs/ordinary.md"], "suites": []},
            "1",
            discovery_root,
            discovery_focused,
        )
        _final_results, final_path = module["run_discovery"](
            discovery_root,
            "HEAD^",
            {
                "groups": [],
                "paths": ["docs/ordinary.md"],
                "stage": "final",
                "suites": [],
            },
            "1",
            discovery_root,
            discovery_focused,
        )
    finally:
        module["run_discovery"].__globals__["run_validation"] = (
            original_run_validation
        )
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    structural = json.loads(structural_path.read_text(encoding="utf-8"))
    final_inventory = json.loads(final_path.read_text(encoding="utf-8"))
    assert structural["status"] == "pass"
    assert structural["results"] == structural_results
    assert structural["failure_suites"] == []
    assert structural["not_run"] == []
    assert final_inventory["schema"] == "harness-validation-final-v1"
    assert inventory["schema"] == "harness-validation-discovery-v1"
    assert inventory["status"] == "fail"
    assert inventory["failure_suites"] == ["tests/fail.sh"]
    assert [row["state"] for row in inventory["results"][1:]] == [
        "fail",
        "pass",
    ]
    assert [row["status"] for row in results[1:]] == [7, 0]
    retained_logs = list(discovery_root.glob("discovery-*.logs/*.log"))
    assert len(retained_logs) == 1
    assert "known failure" in retained_logs[0].read_text(encoding="utf-8")
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
discovery_plan=$(plan --stage discovery --path config/terminfo/tmux-256color.src)
final_plan=$(plan --stage final --path config/terminfo/tmux-256color.src)
full_plan=$(plan --stage final --full --path config/terminfo/tmux-256color.src)

python3 - \
    "$docs_plan" "$skill_plan" "$ordinary_plan" "$unknown_plan" \
    "$discovery_plan" "$final_plan" "$full_plan" <<'PY'
import json
import platform
import sys

if not __debug__:
    raise SystemExit("validation-router plan test requires Python assertions")

docs, skill, ordinary, unknown, discovery, final, full = (
    json.loads(value) for value in sys.argv[1:]
)
assert docs["tier"] == "R1"
assert docs["owner_suites"] == [
    "tests/test-context-routing-benchmark.sh",
    "tests/test-harness-ledgers.sh",
]
assert skill["tier"] == "R1"
assert skill["owner_suites"] == [
    "tests/test-skill-catalog-budget.sh",
    "tests/test-skill-context-budgets.sh",
    "tests/test-skill-context-gates.sh",
]
assert ordinary["tier"] == "R2"
assert ordinary["owner_suites"] == [
    "tests/test-debugger-readiness.sh",
    "tests/test-scientific-library-readiness.sh",
    "tests/test-terminfo.sh",
]
assert unknown["tier"] == "R3"
assert unknown["owner_suites"] == []
assert unknown["owner_gaps"] == ["unknown/path"]
assert unknown["final_required"] is True
assert discovery["stage"] == "discovery"
assert discovery["groups"][0]["name"] == "macos-terminal"
assert discovery["execution_suites"] == (
    ["tests/test-terminfo.sh"] if platform.system() == "Linux" else []
)
assert final["stage"] == "final"
assert final["execution_suites"] == (
    ["tests/test-terminfo.sh"] if platform.system() == "Linux" else []
)
assert final["not_applicable_suites"] == (
    [] if platform.system() == "Linux" else ["tests/test-terminfo.sh"]
)
assert final["full_requested"] is False
assert full["execution_suites"] == ["tests/test-phase1.sh"]
assert full["full_requested"] is True
PY

if plan --full --path config/terminfo/tmux-256color.src >/dev/null 2>&1; then
    printf '%s\n' 'FAIL: --full accepted outside final stage' >&2
    exit 1
fi

printf '%s\n' 'VALIDATION_ROUTER status=pass'
