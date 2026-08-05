#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL=$ROOT/shared/skills/onboard-project-repository
SCAFFOLD=$SKILL/assets/scaffold

python3 /home/rioyokota/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$SKILL"
test -f "$SKILL/references/protocol.md"
test -f "$SCAFFOLD/PRODUCER.md.tmpl"
test -f "$SCAFFOLD/docs/producer/config.json.tmpl"
test -f "$SCAFFOLD/tools/producer-ledger.py"
test -f "$SCAFFOLD/tools/consumer_protocol.py"
test -f "$SCAFFOLD/tools/consumer_validation.py"
grep -F 'Do not install this protocol into Harness itself' "$SKILL/SKILL.md" >/dev/null
grep -F 'not authority for a target consumer to start a nightly run' \
  "$SKILL/SKILL.md" >/dev/null
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=$SCAFFOLD/tools \
  python3 -m unittest discover -s "$SCAFFOLD/tests" -p 'test_*.py'

grep -F 'safe-work-first' "$SKILL/references/protocol.md" >/dev/null
grep -F 'reconciliation-pending' "$SKILL/references/protocol.md" >/dev/null
grep -F 'untracked' "$SKILL/references/protocol.md" >/dev/null
grep -F '900 words' "$SKILL/references/protocol.md" >/dev/null
grep -F 'proportional validation' "$SKILL/references/protocol.md" >/dev/null

echo 'onboard-project-repository: OK'
