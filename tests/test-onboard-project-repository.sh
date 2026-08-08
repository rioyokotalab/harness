#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SKILL=$ROOT/shared/skills/onboard-project-repository
SCAFFOLD=$SKILL/assets/scaffold

python3 - "$SKILL/SKILL.md" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()
assert lines[0] == "---"
end = lines.index("---", 1)
fields = dict(line.split(": ", 1) for line in lines[1:end])
assert fields == {
    "name": "onboard-project-repository",
    "description": fields["description"],
}
assert fields["description"].strip()
assert any(line.strip() for line in lines[end + 1 :])
PY
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
