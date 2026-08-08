#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT/libexec/harness-macos-homebrew" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
for contract in (
    "private profile changed before managed Homebrew apply",
    "managed Homebrew plan changed before apply",
    "automatic rollback is unavailable",
    "managed Homebrew post-state did not converge",
    "END macos_homebrew applied=yes rollback=manual-review-only",
):
    assert contract in source, contract
for state in ("prepared", "failed", "complete"):
    assert f"printf '%s\\n' {state} >\"$status_file\"" in source, state
assert source.count('chmod 600 "$status_file"') >= 1
PY

echo 'personal macOS Homebrew apply contract: PASS'
