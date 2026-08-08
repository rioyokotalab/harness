#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT/libexec/harness-macos-config-migrate" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
for contract in (
    '"$SELF_DIR/harness-macos-ssh-sync" --host "$logical_host" --apply',
    '"$SELF_DIR/harness-macos-bash-hooks" --host "$logical_host" --apply',
    '"$SELF_DIR/harness-tmux-config" --adopt --apply',
    '"$SELF_DIR/harness-tmux-config" --rollback "$tmux_transaction"',
    '"$SELF_DIR/harness-macos-bash-hooks" --rollback "$bash_transaction"',
    '"$SELF_DIR/harness-macos-ssh-sync" --rollback "$ssh_transaction"',
    "rollback=available private_history=forward-only",
):
    assert contract in source, contract
for state in ("prepared", "failed", "complete", "rolled-back"):
    assert state in source, state
PY

echo 'personal macOS configuration migration apply contract: PASS'
