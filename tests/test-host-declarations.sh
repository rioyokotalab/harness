#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
python3 - "$ROOT" <<'PY'
from pathlib import Path
import os
import re
import sys

root = Path(sys.argv[1])
candidates = sorted((root / "profiles/hosts").glob("*.conf"))
facts = sorted((root / "tests/fixtures").glob("*.facts"))
expected = {"local", "ab", "ab2", "abq", "al", "rc", "ri", "t4"}
assert {path.stem for path in candidates} == expected
assert {path.stem for path in facts} == expected
candidates += facts
changed = set(os.environ.get("HARNESS_CHANGED_PATHS", "").splitlines())
selected = [path for path in candidates if str(path.relative_to(root)) in changed]
if not selected:
    selected = candidates
assert selected
for path in selected:
    assert path.is_file() and not path.is_symlink(), path
    rows = [line for line in path.read_text(encoding="utf-8").splitlines() if line]
    pairs = [line.split("=", 1) for line in rows]
    assert all(len(pair) == 2 and all(pair) for pair in pairs), path
    keys = [pair[0] for pair in pairs]
    assert all(re.fullmatch(r"[a-z][a-z0-9_]*", key) for key in keys), path
    assert len(keys) == len(set(keys)), path
    assert dict(pairs).get("schema") == "1", path
print(f"HOST_DECLARATIONS status=pass files={len(selected)}")
PY
