#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-codex-resilient-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

grep -F 'harness codex-resilient --run --name harness --last' \
    "$ROOT/README.md" >/dev/null ||
    fail "owner-facing resilient launch documentation"
grep -F 'never blindly replay the prior prompt' "$ROOT/AGENTS.md" >/dev/null ||
    fail "durable transient-failure rule"

fake_bin=$TEST_ROOT/fake-bin
runtime=$TEST_ROOT/runtime
mkdir "$fake_bin" "$runtime"
chmod 700 "$runtime"

cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
set -eu
if [ "${1:-}" = -f ]; then
    case "$2" in
        %u) format=%u ;;
        %Lp) format=%a ;;
        %l) format=%h ;;
        *) exit 2 ;;
    esac
    shift 2
    exec /usr/bin/stat -c "$format" "$@"
fi
exec /usr/bin/stat "$@"
EOF
chmod 755 "$fake_bin/stat"

cat >"$fake_bin/codex-launcher" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$FAKE_CODEX_CALLS"

if [ "${1:-}" = doctor ]; then
    case ${FAKE_DOCTOR_MODE:-healthy} in
        healthy)
            cat <<'JSON'
{
  "schemaVersion": 1,
  "checks": {
    "auth.credentials": {"status": "ok"},
    "config.load": {"status": "ok"},
    "installation": {"status": "ok"},
    "state.paths": {"status": "ok"},
    "network.provider_reachability": {"status": "error"}
  }
}
JSON
            ;;
        auth)
            cat <<'JSON'
{
  "schemaVersion": 1,
  "checks": {
    "auth.credentials": {"status": "error"},
    "config.load": {"status": "ok"},
    "installation": {"status": "ok"},
    "state.paths": {"status": "ok"}
  }
}
JSON
            ;;
        failed) exit 1 ;;
        *) exit 2 ;;
    esac
    exit 0
fi

status=$(sed -n '1p' "$FAKE_CODEX_STATUSES")
[ -n "$status" ] || status=0
sed '1d' "$FAKE_CODEX_STATUSES" >"$FAKE_CODEX_STATUSES.next"
mv "$FAKE_CODEX_STATUSES.next" "$FAKE_CODEX_STATUSES"
exit "$status"
EOF
chmod 755 "$fake_bin/codex-launcher"

cat >"$fake_bin/sleep" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$1" >>"$FAKE_SLEEP_CALLS"
EOF
chmod 755 "$fake_bin/sleep"

run_supervisor() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_LAUNCHER="$fake_bin/codex-launcher" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_JITTER=0 \
    FAKE_CODEX_CALLS="$TEST_ROOT/codex.calls" \
    FAKE_CODEX_STATUSES="$TEST_ROOT/codex.statuses" \
    FAKE_SLEEP_CALLS="$TEST_ROOT/sleep.calls" \
    PATH="$fake_bin:/usr/bin:/bin" \
        "$HARNESS" codex-resilient "$@"
}

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name fresh --new >"$TEST_ROOT/fresh.out"
[ "$(sed -n '1p' "$TEST_ROOT/codex.calls")" = "" ] ||
    fail "fresh first launch changed"
[ "$(sed -n '2p' "$TEST_ROOT/codex.calls")" = "doctor --json" ] ||
    fail "native doctor was not used"
[ "$(sed -n '3p' "$TEST_ROOT/codex.calls")" = "resume --last" ] ||
    fail "fresh recovery did not resume without a prompt"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 3 ] ||
    fail "unexpected fresh recovery call count"
[ "$(sed -n '1p' "$TEST_ROOT/sleep.calls")" = 15 ] ||
    fail "first retry delay"
grep -F 'CODEX_RESILIENT status=stopped reason=clean-exit' \
    "$TEST_ROOT/fresh.out" >/dev/null || fail "clean exit status"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name explicit --session session-123 \
    >"$TEST_ROOT/explicit.out"
[ "$(sed -n '1p' "$TEST_ROOT/codex.calls")" = \
    "resume session-123" ] || fail "explicit first resume"
[ "$(sed -n '3p' "$TEST_ROOT/codex.calls")" = \
    "resume session-123" ] || fail "explicit recovery drifted"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
FAKE_DOCTOR_MODE=auth run_supervisor --run --name auth --last \
    >"$TEST_ROOT/auth.out" 2>&1 &&
    fail "authentication failure was retried"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 2 ] ||
    fail "authentication failure launched again"
[ ! -s "$TEST_ROOT/sleep.calls" ] ||
    fail "authentication failure slept"
grep -F 'reason=local-auth' "$TEST_ROOT/auth.out" >/dev/null ||
    fail "authentication failure classification"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '2\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name usage --last >"$TEST_ROOT/usage.out" 2>&1 &&
    fail "client usage failure was retried"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 1 ] ||
    fail "client usage failure launched again"
[ ! -s "$TEST_ROOT/sleep.calls" ] || fail "client usage failure slept"
grep -F 'reason=client-usage' "$TEST_ROOT/usage.out" >/dev/null ||
    fail "client usage failure classification"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n1\n1\n1\n1\n1\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name backoff --last-all >"$TEST_ROOT/backoff.out"
expected_delays='15
30
60
120
240
300'
[ "$(cat "$TEST_ROOT/sleep.calls")" = "$expected_delays" ] ||
    fail "exponential retry schedule"
run_count=$(grep -c '^resume --last --all$' "$TEST_ROOT/codex.calls")
[ "$run_count" = 7 ] || fail "global resume selector changed"
[ "$(grep -c '^doctor --json$' "$TEST_ROOT/codex.calls")" = 6 ] ||
    fail "doctor count"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n1\n1\n0\n' >"$TEST_ROOT/codex.statuses"
printf '0\n0\n900\n0\n' >"$TEST_ROOT/durations"
HARNESS_TEST_DURATION_FILE="$TEST_ROOT/durations" \
    run_supervisor --run --name reset --last >"$TEST_ROOT/reset.out"
expected_reset_delays='15
30
15'
[ "$(cat "$TEST_ROOT/sleep.calls")" = "$expected_reset_delays" ] ||
    fail "healthy-runtime backoff reset"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '130\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name signal --last >"$TEST_ROOT/signal.out" 2>&1 &&
    fail "operator signal returned success"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 1 ] ||
    fail "operator signal retried"
[ ! -s "$TEST_ROOT/sleep.calls" ] || fail "operator signal slept"

run_supervisor --status --name backoff >"$TEST_ROOT/status.out"
grep -F 'CODEX_RESILIENT mode=status name=backoff phase=stopped' \
    "$TEST_ROOT/status.out" >/dev/null || fail "status output"

run_supervisor --plan --name planned --last >"$TEST_ROOT/plan.out"
grep -F 'CODEX_RESILIENT mode=plan name=planned selector=last status=ready' \
    "$TEST_ROOT/plan.out" >/dev/null || fail "plan output"
HARNESS_TEST_PLATFORM=Darwin run_supervisor --plan --name darwin --last \
    >"$TEST_ROOT/darwin.out"
grep -F 'name=darwin selector=last status=ready' \
    "$TEST_ROOT/darwin.out" >/dev/null || fail "Darwin plan portability"

mkdir "$runtime/locked.lock"
chmod 700 "$runtime/locked.lock"
printf '%s\n' "$$" >"$runtime/locked.lock/pid"
chmod 600 "$runtime/locked.lock/pid"
: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name locked --last >"$TEST_ROOT/locked.out" 2>&1 &&
    fail "live lock was ignored"
grep -F 'reason=already-running' "$TEST_ROOT/locked.out" >/dev/null ||
    fail "live lock classification"

mkdir "$runtime/stale-lock.lock"
chmod 700 "$runtime/stale-lock.lock"
printf '99999999\n' >"$runtime/stale-lock.lock/pid"
chmod 600 "$runtime/stale-lock.lock/pid"
: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name stale-lock --last \
    >"$TEST_ROOT/stale-lock.out"
grep -F 'reason=clean-exit' "$TEST_ROOT/stale-lock.out" >/dev/null ||
    fail "stale lock recovery"
[ ! -e "$runtime/stale-lock.lock" ] ||
    fail "stale lock residue"

cat >"$runtime/stale-state.state" <<'EOF'
schema=1
name=stale-state
phase=running
selector=last
supervisor_pid=99999999
attempt=2
delay=0
reason=active
EOF
chmod 600 "$runtime/stale-state.state"
run_supervisor --status --name stale-state >"$TEST_ROOT/stale-state.out"
grep -F 'phase=stale' "$TEST_ROOT/stale-state.out" >/dev/null ||
    fail "stale owner status"
grep -F 'reason=owner-absent' "$TEST_ROOT/stale-state.out" >/dev/null ||
    fail "stale owner classification"

printf 'unexpected\n' >"$runtime/unsafe.state"
chmod 644 "$runtime/unsafe.state"
run_supervisor --status --name unsafe >"$TEST_ROOT/unsafe.out" 2>&1 &&
    fail "unsafe state was accepted"
grep -F 'state file is unsafe' "$TEST_ROOT/unsafe.out" >/dev/null ||
    fail "unsafe state classification"
unlink "$runtime/unsafe.state"

for state in "$runtime"/*.state; do
    [ -f "$state" ] || continue
    case $(uname -s) in
        Darwin) mode=$(stat -f %Lp "$state") ;;
        *) mode=$(stat -c %a "$state") ;;
    esac
    [ "$mode" = 600 ] || fail "state mode"
    grep -E 'prompt|transcript|diagnostic|error_message' "$state" >/dev/null &&
        fail "state captured private output"
done

printf 'PASS: Codex transient-service supervisor\n'
