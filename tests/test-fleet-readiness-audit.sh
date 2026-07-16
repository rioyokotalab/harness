#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AUDIT=$ROOT/tools/fleet-readiness-audit.py
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/fleet-readiness-test.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" "${TMPDIR:-/tmp}" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

cat >"$TEST_ROOT/ssh" <<'EOF'
#!/bin/sh
printf '%s\n' x >>"$FAKE_SSH_LOG"
sed -n '1p' >/dev/null
printf '%s\n' \
  'SCHEMA	1' \
  'HOST	ab' \
  'HEAD	0123456789012345678901234567890123456789' \
  'DIRTY	0' \
  'INVENTORY	{"arch":"x86_64","logical_host":"ab","schema":"1"}' \
  'DOCTOR	SUMMARY host=ab failures=0 warnings=2' \
  'SCHEDULE	RESTIC_SCHEDULE_CHAIN host=ab status=active job=123.pbs name=hab eligible=1784388600 present=1 state=Q' \
  'CONTROL_PLANE	34	0	0' \
  'CONTROL	.codex/AGENTS.md	symlink	/home/test/harness/.codex/AGENTS.md' \
  'STORAGE	.local	symlink	/large/test/home-local' \
  'SMOKE	mpi.c	0123456789012345678901234567890123456789' \
  'VERSION	python	present	Python 3.12.3'
EOF
chmod 700 "$TEST_ROOT/ssh"
mkdir "$TEST_ROOT/out"
FAKE_SSH_LOG=$TEST_ROOT/calls python3 "$AUDIT" --host ab --ssh "$TEST_ROOT/ssh" \
    --output "$TEST_ROOT/out/report.json" >"$TEST_ROOT/stdout"
[ "$(wc -l <"$TEST_ROOT/calls" | tr -d ' ')" = 1 ] || exit 1
python3 - "$TEST_ROOT/out/report.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1]))
assert x['failures']=={}
assert list(x['nodes'])==['ab']
assert x['nodes']['ab']['head']=='0123456789012345678901234567890123456789'
assert x['nodes']['ab']['doctor']=={'failures':0,'warnings':2}
assert x['nodes']['ab']['schedule']['chain']['job']=='123.pbs'
assert x['nodes']['ab']['control_plane']=={'keep':34,'create':0,'block':0}
PY
printf '%s\n' 'fleet readiness audit tests passed'
