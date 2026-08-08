#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW=$ROOT/.github/workflows/ci.yml
DOC=$ROOT/docs/ci-and-merge-controls.md
AUDIT=$ROOT/docs/audits/t351-autonomy-efficiency/actions-transition.md

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

for path in "$WORKFLOW" "$DOC" "$AUDIT"; do
    [ -f "$path" ] && [ ! -L "$path" ] ||
        fail "missing regular Actions contract: $path"
done

grep -F -x '  pull_request:' "$WORKFLOW" >/dev/null ||
    fail 'pull-request trigger missing'
grep -F -x '  schedule:' "$WORKFLOW" >/dev/null ||
    fail 'weekly trigger missing'
grep -F -x '    - cron: "11 19 * * 6"' "$WORKFLOW" >/dev/null ||
    fail 'weekly trigger changed'
grep -F -x '  workflow_dispatch:' "$WORKFLOW" >/dev/null ||
    fail 'manual full trigger missing'
python3 - "$WORKFLOW" <<'PY'
from pathlib import Path
import re
import sys

if not __debug__:
    raise SystemExit("Actions contract parser requires Python assertions")


def validate(text: str) -> None:
    lines = text.splitlines()
    semantic = [line.split("#", 1)[0].rstrip() for line in lines]
    if any(
        re.search(r"(^|[\s,{])push\s*:", line)
        for line in semantic
        if line.strip()
    ):
        raise ValueError("duplicate main push trigger restored")

    if semantic.count("on:") != 1:
        raise ValueError("workflow does not have one canonical event block")
    event_keys = []
    for line in semantic[semantic.index("on:") + 1 :]:
        if line and not line[0].isspace():
            break
        match = re.fullmatch(r"  ([a-z_]+):", line)
        if match:
            event_keys.append(match.group(1))
    if event_keys != ["pull_request", "schedule", "workflow_dispatch"]:
        raise ValueError("workflow has an undeclared event trigger")

    declarations = [
        (number, line)
        for number, line in enumerate(semantic)
        if re.match(r"^\s*permissions\s*:", line)
    ]
    if declarations != [(semantic.index("permissions:"), "permissions:")]:
        raise ValueError("workflow has noncanonical or job-level permissions")
    start = declarations[0][0] + 1
    block = []
    for line in semantic[start:]:
        if line and not line[0].isspace():
            break
        if line.strip():
            block.append(line)
    if block != ["  contents: read"]:
        raise ValueError("workflow token is not exactly contents: read")

    step_contracts = (
        (
            "      - name: Discover all affected-group failures for pull requests",
            [
                "        if: github.event_name == 'pull_request'",
                '        run: bin/harness validate --stage discovery --base "${{ github.event.pull_request.base.sha }}"',
            ],
        ),
        (
            "      - name: Run credential-free portable full backstop",
            [
                "        if: github.event_name != 'pull_request'",
                "        run: tests/test-phase1.sh",
            ],
        ),
    )

    for heading, expected in step_contracts:
        if semantic.count(heading) != 1:
            raise ValueError(f"workflow step is not unique: {heading.strip()}")
        start = semantic.index(heading) + 1
        block = []
        for line in semantic[start:]:
            if line.startswith("      - name: "):
                break
            if line.strip():
                block.append(line)
        if block != expected:
            raise ValueError(f"workflow step contract changed: {heading.strip()}")


workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
try:
    validate(workflow)
except ValueError as error:
    raise SystemExit(f"FAIL: {error}") from error

mutations = (
    workflow.replace(
        "on:\n",
        "on: {push: {branches: [main]}, pull_request: null}\nlegacy-on:\n",
        1,
    ),
    workflow.replace(
        "  portable-phase1:\n",
        "  portable-phase1:\n    permissions: write-all\n",
        1,
    ),
    workflow.replace(
        "  workflow_dispatch:\n",
        "  pull_request_target:\n  workflow_dispatch:\n",
        1,
    ),
    workflow.replace(
        "github.event.pull_request.base.sha",
        "github.sha",
        1,
    ),
    workflow.replace(
        "github.event_name != 'pull_request'",
        "always()",
        1,
    ),
    workflow.replace("--stage discovery", "--stage repair", 1),
)
for mutation in mutations:
    try:
        validate(mutation)
    except ValueError:
        continue
    raise SystemExit("FAIL: Actions parser accepted a prohibited mutation")
PY

grep -F 'github.event_name' "$WORKFLOW" >/dev/null ||
    fail 'event-scoped concurrency missing'
grep -F -x '  cancel-in-progress: true' "$WORKFLOW" >/dev/null ||
    fail 'superseded-run cancellation missing'
grep -F 'portable-phase1' "$WORKFLOW" >/dev/null ||
    fail 'required check missing'
grep -F 'HARNESS_PORTABLE_CI: "1"' "$WORKFLOW" >/dev/null ||
    fail 'portable gate contract missing'
grep -F -x "        if: github.event_name == 'pull_request'" "$WORKFLOW" >/dev/null ||
    fail 'pull-request selector condition missing'
grep -F -x '        run: bin/harness validate --stage discovery --base "${{ github.event.pull_request.base.sha }}"' "$WORKFLOW" >/dev/null ||
    fail 'pull-request discovery selector changed'
grep -F -x "        if: github.event_name != 'pull_request'" "$WORKFLOW" >/dev/null ||
    fail 'weekly/manual full-backstop condition missing'
grep -F -x '        run: tests/test-phase1.sh' "$WORKFLOW" >/dev/null ||
    fail 'weekly/manual full backstop changed'

grep -F 'duplicate `main` push runner' "$DOC" >/dev/null ||
    fail 'owner documentation does not explain trigger routing'
grep -F 'v7.0.1' "$DOC" >/dev/null ||
    fail 'checkout documentation is stale'
grep -F '678 observed public duplicate runs' "$AUDIT" >/dev/null ||
    fail 'public-run evidence missing'

printf '%s\n' 'ACTIONS_SUSTAINABILITY status=pass harness_push=absent weekly=present manual=present'
