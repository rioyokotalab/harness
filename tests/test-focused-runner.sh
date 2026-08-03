#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PHASE1=$ROOT/tests/test-phase1.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-focused-runner-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
        >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

grep -F 'focused_pid=$!' "$PHASE1" >/dev/null ||
    fail "phase-1 does not overlap focused and integration gates"
grep -F 'wait "$focused_pid"' "$PHASE1" >/dev/null ||
    fail "phase-1 does not join focused validation"
grep -F 'shellcheck_pid=$!' "$PHASE1" >/dev/null ||
    fail "phase-1 does not overlap ShellCheck and integration gates"
grep -F 'wait "$shellcheck_pid"' "$PHASE1" >/dev/null ||
    fail "phase-1 does not join ShellCheck validation"
grep -F '        focused_jobs=auto' "$PHASE1" >/dev/null &&
    grep -F '        focused_reserve=1' "$PHASE1" >/dev/null &&
    grep -F '[ "$visible_cpus" -le 2 ]' "$PHASE1" >/dev/null &&
    grep -F -- '--reserve-cpus "$focused_reserve"' "$PHASE1" >/dev/null ||
    fail "phase-1 does not reserve one CPU or serialize low-core gates"
grep -F '[ "$focused_status" -eq 0 ] || fail "focused suites"' \
    "$PHASE1" >/dev/null || fail "phase-1 loses focused-suite failure"
grep -F '[ "$shellcheck_status" -eq 0 ] || fail "ShellCheck warning/error gate"' \
    "$PHASE1" >/dev/null || fail "phase-1 loses ShellCheck failure"

python3 - "$PHASE1" <<'PY'
import pathlib
import sys

if not __debug__:
    raise SystemExit("focused-runner contract requires Python assertions")

text = pathlib.Path(sys.argv[1]).read_text()
shellcheck_start = text.index("shellcheck_pid=$!")
integration_start = text.index('"$ROOT/tests/test-guarded-delete.sh"')
shellcheck_join = text.rindex('wait "$shellcheck_pid"')
integration_end = text.index('artifact_dir=$test_home/.local/opt/fixture')
assert shellcheck_start < integration_start
assert shellcheck_join > integration_end
PY

fake=$TEMP_DIR/root
mkdir -p "$fake/tests"

for name in one two; do
    cat >"$fake/tests/$name.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
name=${0##*/}
: >"$root/$name.started"
other=one.sh
[ "$name" = one.sh ] && other=two.sh
attempt=0
while [ ! -f "$root/$other.started" ]; do
    attempt=$((attempt + 1))
    [ "$attempt" -lt 100 ] || exit 9
    sleep 0.02
done
printf 'parallel=%s\n' "$name"
EOF
    chmod 755 "$fake/tests/$name.sh"
done
printf '%s\n' 'tests/one.sh|one' 'tests/two.sh|two' >"$fake/pass.tsv"
python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/pass-logs" --jobs 2 \
    >"$TEMP_DIR/pass.out" 2>"$TEMP_DIR/pass.err" || fail 'parallel pass'
[ ! -s "$TEMP_DIR/pass.err" ] || fail 'parallel pass emitted stderr'
if grep -q '^PASS suite=' "$TEMP_DIR/pass.out"; then
    fail 'compact pass emitted per-suite output'
fi
grep -E '^focused-tests: status=pass suites=2 seconds=[0-9]+\.[0-9]{3}$' \
    "$TEMP_DIR/pass.out" >/dev/null || fail 'compact pass summary'

for name in early priority late; do
    cat >"$fake/tests/$name.sh" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "${0##*/}" >>"$ORDER_FILE"
EOF
    chmod 755 "$fake/tests/$name.sh"
done
printf '%s\n' \
    'tests/early.sh|early|1' \
    'tests/priority.sh|priority|9' \
    'tests/late.sh|late|1' >"$fake/priority.tsv"
ORDER_FILE="$TEMP_DIR/priority.order" \
    python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/priority.tsv" --log-dir "$fake/priority-logs" --jobs 1 \
    --verbose \
    >"$TEMP_DIR/priority.out" 2>"$TEMP_DIR/priority.err" ||
    fail 'priority admission'
[ "$(cat "$TEMP_DIR/priority.order")" = "priority.sh
early.sh
late.sh" ] || fail 'priority admission order'
[ "$(sed -n 's/^PASS suite=\([^ ]*\).*/\1/p' "$TEMP_DIR/priority.out")" = \
    "early.sh
priority.sh
late.sh" ] || fail 'priority changed canonical output order'

PYTHONDONTWRITEBYTECODE=1 python3 - "$ROOT/tools/run-focused-tests.py" <<'PY'
import importlib.util
import pathlib
import sys

if not __debug__:
    raise SystemExit("focused-runner unit checks require Python assertions")

path = pathlib.Path(sys.argv[1])
spec = importlib.util.spec_from_file_location("focused_runner", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
assert module.default_jobs(1) == 4
assert module.default_jobs(7) == 4
assert module.default_jobs(8) == 8
assert module.default_jobs(64) == 8
assert module.auto_jobs(1, 1) == 1
assert module.auto_jobs(7, 1) == 4
assert module.auto_jobs(8, 1) == 7
assert module.auto_jobs(64, 1) == 8
PY
python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/auto-logs" --jobs auto \
    --verbose \
    >"$TEMP_DIR/auto.out" 2>"$TEMP_DIR/auto.err" || fail 'auto jobs pass'
[ ! -s "$TEMP_DIR/auto.err" ] || fail 'auto jobs emitted stderr'
grep -E '^focused-tests: jobs=([1-8]) visible_cpus=[0-9]+ mode=auto reserve_cpus=0$' \
    "$TEMP_DIR/auto.out" >/dev/null || fail 'missing auto jobs selection'
[ "$(grep -c '^PASS suite=' "$TEMP_DIR/auto.out")" -eq 2 ] ||
    fail 'auto jobs result count'

cat >"$fake/tests/fail.sh" <<'EOF'
#!/bin/sh
printf '%s\n' 'intentional focused failure'
exit 7
EOF
chmod 755 "$fake/tests/fail.sh"
printf '%s\n' 'tests/fail.sh|expected label' >"$fake/fail.tsv"
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/fail.tsv" --log-dir "$fake/fail-logs" --jobs 1 \
    >"$TEMP_DIR/fail.out" 2>"$TEMP_DIR/fail.err"; then
    fail 'runner accepted failing suite'
fi
grep -F 'FAIL: expected label; log=' "$TEMP_DIR/fail.err" >/dev/null ||
    fail 'failure label attribution'
grep -F 'intentional focused failure' "$TEMP_DIR/fail.err" >/dev/null ||
    fail 'failure log attribution'

if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/invalid-logs" --jobs 0 \
    >"$TEMP_DIR/invalid.out" 2>&1; then
    fail 'runner accepted zero jobs'
fi

printf '%s\n' 'tests/one.sh|one|unbounded' >"$fake/invalid-priority.tsv"
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/invalid-priority.tsv" \
    --log-dir "$fake/invalid-priority-logs" --jobs 1 \
    >"$TEMP_DIR/invalid-priority.out" 2>&1; then
    fail 'runner accepted an invalid admission estimate'
fi
grep -F 'focused-tests: invalid manifest line 1' \
    "$TEMP_DIR/invalid-priority.out" >/dev/null ||
    fail 'missing invalid admission estimate diagnostic'

if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/pass-logs" --jobs 2 \
    >"$TEMP_DIR/exists.out" 2>"$TEMP_DIR/exists.err"; then
    fail 'runner accepted an already-populated --log-dir'
fi
[ "$(cat "$TEMP_DIR/exists.out")" = "" ] || fail 'log-dir-exists run executed a suite'
grep -F "focused-tests: --log-dir already exists: $fake/pass-logs" \
    "$TEMP_DIR/exists.err" >/dev/null || fail 'missing log-dir-exists diagnostic'
if grep -F 'Traceback' "$TEMP_DIR/exists.err" >/dev/null; then
    fail 'log-dir-exists run printed a traceback'
fi

printf '%s\n' 'focused runner tests: PASS'
