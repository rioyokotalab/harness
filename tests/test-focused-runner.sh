#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PHASE1=$ROOT/tests/test-phase1.sh
ORCHESTRATOR=$ROOT/tests/test-phase1-orchestrator.sh
SHELLCHECK=$ROOT/tests/test-shellcheck.sh
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

grep -F 'exec "$ROOT/tests/test-phase1-orchestrator.sh"' "$PHASE1" >/dev/null ||
    fail 'phase-1 does not delegate final orchestration'
grep -F 'tools/run-focused-tests.py' "$ORCHESTRATOR" >/dev/null &&
    grep -F -- '--timings-file "$TIMINGS"' "$ORCHESTRATOR" >/dev/null &&
    grep -F -- '--manifest "$ROOT/tests/focused-suites.tsv"' \
        "$ORCHESTRATOR" >/dev/null ||
    fail 'phase-1 orchestrator does not retain one attributed runner'
grep -F 'shellcheck --severity=warning' "$SHELLCHECK" >/dev/null ||
    fail 'phase-1 ShellCheck gate is not independently runnable'
for suite in tests/test-shellcheck.sh tests/test-guarded-delete.sh; do
    grep -F "$suite|" "$ROOT/tests/focused-suites.tsv" >/dev/null ||
        fail "phase-1 component is outside the complete manifest: $suite"
done

fake=$TEMP_DIR/root
mkdir -p "$fake/tests"

for name in one two; do
    cat >"$fake/tests/$name.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
name=${0##*/}
: >"$root/$name.started"
if [ "$name" = one.sh ]; then
    IFS= read -r signal <"$root/parallel.gate"
    [ "$signal" = ready ]
else
    printf '%s\n' ready >"$root/parallel.gate"
fi
printf 'parallel=%s\n' "$name"
EOF
    chmod 755 "$fake/tests/$name.sh"
done
mkfifo "$fake/parallel.gate"
printf '%s\n' 'tests/one.sh|one' 'tests/two.sh|two' >"$fake/pass.tsv"
python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/pass-logs" --jobs 2 \
    --timings-file "$TEMP_DIR/pass-timings.json" \
    >"$TEMP_DIR/pass.out" 2>"$TEMP_DIR/pass.err" || fail 'parallel pass'
[ ! -s "$TEMP_DIR/pass.err" ] || fail 'parallel pass emitted stderr'
if grep -q '^PASS suite=' "$TEMP_DIR/pass.out"; then
    fail 'compact pass emitted per-suite output'
fi
grep -E '^focused-tests: status=pass suites=2 seconds=[0-9]+\.[0-9]{3}$' \
    "$TEMP_DIR/pass.out" >/dev/null || fail 'compact pass summary'
python3 - "$TEMP_DIR/pass-timings.json" <<'PY'
import json
import pathlib
import sys

receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert receipt["schema"] == "harness-focused-timings-v1"
assert receipt["platform"] in {"Darwin", "Linux"}
assert receipt["status"] == "pass"
assert receipt["suites_total"] == 2
assert len(receipt["results"]) == 2
assert receipt["not_run"] == []
assert all(row["state"] == "pass" and row["seconds"] >= 0 for row in receipt["results"])
PY

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

ORDER_FILE="$TEMP_DIR/selected.order" \
    python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/priority.tsv" --log-dir "$fake/selected-logs" --jobs 1 \
    --suite tests/priority.sh --timings-file "$TEMP_DIR/selected-timings.json" \
    >"$TEMP_DIR/selected.out" 2>"$TEMP_DIR/selected.err" ||
    fail 'single-suite selection'
[ "$(cat "$TEMP_DIR/selected.order")" = priority.sh ] ||
    fail 'single-suite selection admitted unrelated work'
python3 - "$TEMP_DIR/selected-timings.json" <<'PY'
import json
import pathlib
import sys

receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert receipt["suites_total"] == 1
assert [row["suite"] for row in receipt["results"]] == ["tests/priority.sh"]
PY
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/priority.tsv" --log-dir "$fake/missing-suite-logs" \
    --jobs 1 --suite tests/missing.sh >"$TEMP_DIR/missing-suite.out" 2>&1; then
    fail 'runner accepted a suite outside its manifest'
fi
grep -F 'focused-tests: suite is outside the manifest: tests/missing.sh' \
    "$TEMP_DIR/missing-suite.out" >/dev/null ||
    fail 'missing selected-suite diagnostic'

PYTHONDONTWRITEBYTECODE=1 python3 - "$ROOT/tools/run-focused-tests.py" <<'PY'
import importlib.util
import os
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
assert module.resolve_heavy_jobs("auto", 1, "Darwin") == 1
assert module.resolve_heavy_jobs("auto", 4, "Darwin") == 2
assert module.resolve_heavy_jobs("auto", 7, "Darwin") == 3
assert module.resolve_heavy_jobs("auto", 8, "Darwin") == 4
assert module.resolve_heavy_jobs("auto", 4, "Linux") == 4
original_count = os.environ.get("GIT_CONFIG_COUNT")
try:
    os.environ["GIT_CONFIG_COUNT"] = "1"
    configured = module.test_environment()
    assert configured["GIT_CONFIG_COUNT"] == "2"
    assert configured["GIT_CONFIG_KEY_1"] == "maintenance.auto"
    assert configured["GIT_CONFIG_VALUE_1"] == "false"
finally:
    if original_count is None:
        os.environ.pop("GIT_CONFIG_COUNT", None)
    else:
        os.environ["GIT_CONFIG_COUNT"] = original_count
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

cat >"$fake/tests/fail-fast-fail.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
: >"$root/fail-fast-fail.started"
IFS= read -r signal <"$root/fail-fast-ready.gate"
[ "$signal" = ready ]
printf '%s\n' 'intentional fail-fast failure'
exit 7
EOF
cat >"$fake/tests/fail-fast-slow.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cleanup() { : >"$root/fail-fast-slow.cleaned"; }
trap cleanup EXIT HUP INT TERM
: >"$root/fail-fast-slow.started"
printf '%s\n' ready >"$root/fail-fast-ready.gate"
IFS= read -r _signal <"$root/fail-fast-hold.gate"
EOF
cat >"$fake/tests/fail-fast-never.sh" <<'EOF'
#!/bin/sh
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
: >"$root/fail-fast-never.started"
EOF
chmod 755 "$fake/tests/fail-fast-"*.sh
mkfifo "$fake/fail-fast-ready.gate" "$fake/fail-fast-hold.gate"
printf '%s\n' \
    'tests/fail-fast-fail.sh|fail fast|9' \
    'tests/fail-fast-slow.sh|slow cleanup|8' \
    'tests/fail-fast-never.sh|must not start|1' >"$fake/fail-fast.tsv"
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/fail-fast.tsv" --log-dir "$fake/fail-fast-logs" \
    --jobs 2 --timings-file "$TEMP_DIR/fail-fast-timings.json" \
    >"$TEMP_DIR/fail-fast.out" 2>"$TEMP_DIR/fail-fast.err"; then
    fail 'fail-fast runner accepted failure'
fi
[ -f "$fake/fail-fast-slow.cleaned" ] || fail 'fail-fast skipped suite cleanup'
[ ! -e "$fake/fail-fast-never.started" ] || fail 'fail-fast admitted later suite'
grep -E '^focused-tests: status=fail suites=2/3 cancelled=1 not_run=1 seconds=' \
    "$TEMP_DIR/fail-fast.out" >/dev/null || fail 'fail-fast summary changed'
python3 - "$TEMP_DIR/fail-fast-timings.json" <<'PY'
import json
import pathlib
import sys

receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert receipt["mode"] == "fail-fast"
assert receipt["status"] == "fail"
assert [row["state"] for row in receipt["results"]] == ["fail", "cancelled"]
assert receipt["not_run"] == ["tests/fail-fast-never.sh"]
PY

cat >"$fake/tests/keep-fail.sh" <<'EOF'
#!/bin/sh
exit 7
EOF
cat >"$fake/tests/keep-pass.sh" <<'EOF'
#!/bin/sh
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
: >"$root/keep-pass.started"
EOF
chmod 755 "$fake/tests/keep-"*.sh
printf '%s\n' 'tests/keep-fail.sh|keep failure|2' \
    'tests/keep-pass.sh|keep pass|1' >"$fake/keep.tsv"
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/keep.tsv" --log-dir "$fake/keep-logs" --jobs 1 \
    --keep-going >"$TEMP_DIR/keep.out" 2>"$TEMP_DIR/keep.err"; then
    fail 'keep-going runner accepted failure'
fi
[ -f "$fake/keep-pass.started" ] || fail 'keep-going stopped later admission'
grep -E '^focused-tests: status=fail suites=2/2 cancelled=0 not_run=0 seconds=' \
    "$TEMP_DIR/keep.out" >/dev/null || fail 'keep-going summary changed'

for name in heavy-one heavy-two; do
    cat >"$fake/tests/$name.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
lock=$root/heavy.lock
mkdir "$lock" || exit 12
cleanup() { rmdir "$lock"; }
trap cleanup EXIT HUP INT TERM
if [ "${0##*/}" = heavy-one.sh ]; then
    IFS= read -r signal <"$root/heavy.gate"
    [ "$signal" = ready ]
fi
EOF
    chmod 755 "$fake/tests/$name.sh"
done
cat >"$fake/tests/heavy-light.sh" <<'EOF'
#!/bin/sh
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
printf '%s\n' ready >"$root/heavy.gate"
EOF
cat >"$fake/tests/linux-only.sh" <<'EOF'
#!/bin/sh
exit 9
EOF
chmod 755 "$fake/tests/heavy-light.sh" "$fake/tests/linux-only.sh"
mkfifo "$fake/heavy.gate"
printf '%s\n' \
    'tests/heavy-one.sh|heavy one|3|heavy' \
    'tests/heavy-two.sh|heavy two|2|heavy' \
    'tests/heavy-light.sh|light|1|light' \
    'tests/linux-only.sh|not on Darwin|1|light|Linux' >"$fake/heavy.tsv"
python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/heavy.tsv" --log-dir "$fake/heavy-logs" --jobs 3 \
    --platform Darwin --heavy-jobs 1 \
    --timings-file "$TEMP_DIR/heavy-timings.json" \
    >"$TEMP_DIR/heavy.out" 2>"$TEMP_DIR/heavy.err" ||
    fail 'Darwin heavy-resource admission'
python3 - "$TEMP_DIR/heavy-timings.json" <<'PY'
import json
import pathlib
import sys

receipt = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert receipt["platform"] == "Darwin"
assert receipt["heavy_jobs"] == 1
assert [row["resource"] for row in receipt["results"]] == ["heavy", "heavy", "light"]
assert receipt["not_applicable"] == ["tests/linux-only.sh"]
PY

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

printf '%s\n' 'tests/one.sh|one|1|unbounded' >"$fake/invalid-resource.tsv"
if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/invalid-resource.tsv" \
    --log-dir "$fake/invalid-resource-logs" --jobs 1 \
    >"$TEMP_DIR/invalid-resource.out" 2>&1; then
    fail 'runner accepted an invalid resource class'
fi
grep -F 'focused-tests: invalid manifest line 1' \
    "$TEMP_DIR/invalid-resource.out" >/dev/null ||
    fail 'missing invalid resource diagnostic'

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
