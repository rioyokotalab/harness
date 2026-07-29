#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
RETEST=$ROOT/evaluation/development-v2/retest_fable_failures.py

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -x "$RETEST" ] || fail "missing executable Fable failure retest"

python3 - "$RETEST" <<'PY'
import ast
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
ast.parse(source, filename=sys.argv[1])
PY

"$RETEST" validate | grep -Fx \
    'VALID retest=t343-t336-fable-high-20260729-r1 cases=4 model=claude-fable-5 effort=high' \
    >/dev/null || fail "retest validation"
"$RETEST" selftest | grep -Fx \
    'SELFTEST retest=t343-t336-fable-high-20260729-r1 selected=code-coherence/o1,code-coherence/o2,code-coherence/o3,ci-gate-preserve/o2' \
    >/dev/null || fail "retest selection"

python3 - "$ROOT" <<'PY'
import hashlib
from pathlib import Path
import sys

root = Path(sys.argv[1])
expected = {
    root / "evaluation/results/t336-harness-development-v2-20260729-r7-pilot.json":
        "2694b7485f75efbb4b3280ac1e79b2e1b4d5c490c9b787e15a65b7bca6f54e8d",
    root / "evaluation/results/t336-harness-development-v2-20260729-r7-confirmation.json":
        "483e1f773e7989966ecef669d43b1bb8c12bf2018b5c49cc8c2dda404c6c06dc",
}
for path, digest in expected.items():
    if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        raise SystemExit("accepted report drift: {}".format(path.name))
PY

printf '%s\n' 'T-343 Fable failure retest tests passed'
