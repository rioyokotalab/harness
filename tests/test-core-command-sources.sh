#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
python3 - "$ROOT" <<'PY'
from pathlib import Path
import os
import sys

root = Path(sys.argv[1])
commands = {
    "harness-apply",
    "harness-build-tool",
    "harness-cache-bootstrap",
    "harness-common",
    "harness-doctor",
    "harness-dotfiles",
    "harness-plan",
    "harness-python",
    "harness-remediate",
    "harness-repository-fingerprint",
    "harness-rollback",
    "harness-runtime",
    "harness-shell",
}
changed = {
    Path(path).name
    for path in os.environ.get("HARNESS_CHANGED_PATHS", "").splitlines()
    if path.startswith("libexec/")
}
selected = sorted(commands & changed) if changed else sorted(commands)
assert selected
for name in selected:
    source = (root / "libexec" / name).read_text(encoding="utf-8")
    assert source.startswith("#!/bin/sh\n"), name
    if name != "harness-common":
        assert source.startswith("#!/bin/sh\nset -eu\n"), name
print(f"CORE_COMMAND_SOURCES status=pass commands={len(selected)}")
PY
