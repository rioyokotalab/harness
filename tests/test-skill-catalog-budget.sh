#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
expected = {
    "bounded-agent-delegation": ("policy permits", "dispatch and review"),
    "evidence-first-research": ("primary-source provenance",),
    "fleet-repository-hardening": ("repository-local LIFO",),
    "guarded-bulk-delete": ("multi-path deletion", "post-delete checks"),
    "long-running-task-ledger": ("chat history",),
    "onboard-external-user": ("first-time external user",),
    "onboard-mirrored-node": ("newly configured SSH alias",),
    "onboard-personal-mac": ("exactly one personal Mac",),
    "onboard-project-repository": (
        "repository-native producer/consumer",
        "project-specific policy",
    ),
    "operate-native-hpc": ("native scheduler", "matched experiments"),
    "plan-interview-execute": ("fully frozen authorized execution",),
    "reboot-recovery": (
        "aist, home, office, or riken",
        "loss of its normal Codex session",
    ),
    "recover-codex-unsafe-tail": ("Request blocked", "never replay"),
    "remote-agent-communication": ("without reading panes", "producer-consumer checkpoints"),
    "research-engineering-validation": ("matched benchmarks",),
    "research-presentation-workflow": ("sourced research",),
    "research-program-management": ("humane boundaries",),
}

observed = {}
for path in sorted((root / "shared" / "skills").glob("*/SKILL.md")):
    assert path.is_file() and not path.is_symlink(), path
    text = path.read_text(encoding="utf-8")
    frontmatter = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    assert frontmatter, path
    names = re.findall(r"^name:\s*(\S+)\s*$", frontmatter.group(1), re.MULTILINE)
    descriptions = re.findall(
        r"^description:\s*(\S.*)$", frontmatter.group(1), re.MULTILINE
    )
    assert names == [path.parent.name], (path, names)
    assert len(descriptions) == 1, (path, descriptions)
    description = descriptions[0]
    word_count = len(description.split())
    assert 8 <= word_count <= 32, (path.parent.name, word_count)
    observed[path.parent.name] = (description, word_count)

assert set(observed) == set(expected), (set(observed), set(expected))
for name, markers in expected.items():
    description = observed[name][0]
    for marker in markers:
        assert marker in description, (name, marker)

total = sum(count for _, count in observed.values())
assert total <= 400, total
print(
    f"SKILL_CATALOG status=pass skills={len(observed)} "
    f"description_words={total} ceiling=400"
)
PY
