#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
LOCK=$ROOT/profiles/pytorch-2.12.1-cu130.requirements.lock
BUILDER=$ROOT/tools/build-pytorch-wheelhouse.sh
DOC=$ROOT/docs/pytorch-framework-baseline.md

sh -n "$BUILDER"
grep -F -- '--require-hashes --no-deps' "$BUILDER" >/dev/null
grep -F 'wheel_count=29' "$BUILDER" >/dev/null
grep -F 'chmod 555 "$stage"' "$BUILDER" >/dev/null
grep -F 'PyTorch 2.13.0' "$DOC" >/dev/null
if grep -E 'rm[[:space:]]+(-[^[:space:]]*)*[rR]|--recursive|find[[:space:]].*-delete|rsync[[:space:]].*--delete' \
    "$BUILDER" >/dev/null; then
    printf '%s\n' 'FAIL: unsafe wheelhouse cleanup' >&2
    exit 1
fi

python3 - "$LOCK" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines()
assert "--index-url https://download.pytorch.org/whl/cu130" in lines
assert "--extra-index-url https://pypi.nvidia.com" in lines
assert "--only-binary=:all:" in lines
packages = {}
for number, line in enumerate(lines, 1):
    if not line or line.startswith("#") or line.startswith("--"):
        continue
    fields = line.split()
    assert re.fullmatch(r"[A-Za-z0-9_.-]+==[A-Za-z0-9.+-]+", fields[0]), number
    name, version = fields[0].split("==", 1)
    key = name.lower().replace("_", "-")
    assert key not in packages, number
    hashes = fields[1:]
    assert 1 <= len(hashes) <= 2, number
    assert all(re.fullmatch(r"--hash=sha256:[0-9a-f]{64}", item) for item in hashes), number
    assert len(set(hashes)) == len(hashes), number
    packages[key] = (version, hashes)
assert len(packages) == 29
assert packages["torch"][0] == "2.12.1+cu130"
assert packages["triton"][0] == "3.7.1"
assert len(packages["torch"][1]) == 2
assert len(packages["triton"][1]) == 2
assert packages["cuda-toolkit"][0] == "13.0.2"
assert packages["nvidia-cudnn-cu13"][0] == "9.20.0.48"
PY
printf '%s\n' 'PyTorch dual-architecture lock tests: PASS'
