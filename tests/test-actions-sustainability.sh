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
if grep -F -x '  push:' "$WORKFLOW" >/dev/null; then
    fail 'duplicate main push trigger restored'
fi

grep -F -x '  contents: read' "$WORKFLOW" >/dev/null ||
    fail 'workflow token is not read-only'
grep -F 'github.event_name' "$WORKFLOW" >/dev/null ||
    fail 'event-scoped concurrency missing'
grep -F -x '  cancel-in-progress: true' "$WORKFLOW" >/dev/null ||
    fail 'superseded-run cancellation missing'
grep -F 'portable-phase1' "$WORKFLOW" >/dev/null ||
    fail 'required check missing'
grep -F 'HARNESS_PORTABLE_CI: "1"' "$WORKFLOW" >/dev/null ||
    fail 'portable gate contract missing'

grep -F 'duplicate `main` push runner' "$DOC" >/dev/null ||
    fail 'owner documentation does not explain trigger routing'
grep -F 'v7.0.1' "$DOC" >/dev/null ||
    fail 'checkout documentation is stale'
grep -F '678 observed public duplicate runs' "$AUDIT" >/dev/null ||
    fail 'public-run evidence missing'

printf '%s\n' 'ACTIONS_SUSTAINABILITY status=pass harness_push=absent weekly=present manual=present'
