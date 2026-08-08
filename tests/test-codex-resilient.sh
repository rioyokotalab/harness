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
grep -F 'run_codex "$first_launch" </dev/tty &' \
    "$ROOT/libexec/harness-codex-resilient" >/dev/null ||
    fail "remote TUI lost its controlling terminal"

fake_bin=$TEST_ROOT/fake-bin
runtime=$TEST_ROOT/runtime
managed_root=$TEST_ROOT/home/.local/opt/agents/codex/1/linux/node_modules/@openai/codex
mkdir -p "$fake_bin" "$runtime" "$managed_root"
chmod 700 "$runtime"

cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
set -eu
if [ "${1:-}" = -c ] && [ "$(/usr/bin/uname -s)" = Darwin ]; then
    case "$2" in
        %u) format=%u ;;
        %a) format=%Lp ;;
        %h) format=%l ;;
        *) exit 2 ;;
    esac
    shift 2
    [ "${1:-}" != -- ] || shift
    exec /usr/bin/stat -f "$format" "$@"
fi
if [ "${1:-}" = -f ]; then
    if [ "$(/usr/bin/uname -s)" = Darwin ]; then
        exec /usr/bin/stat "$@"
    fi
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
        managed-install)
            cat <<JSON
{
  "schemaVersion": 1,
  "checks": {
    "auth.credentials": {"status": "ok"},
    "config.load": {"status": "ok"},
    "installation": {
      "status": "fail",
      "summary": "npm install -g @openai/codex would update a different install",
      "details": {
        "managed package root": "$FAKE_MANAGED_ROOT",
        "running package root": "$FAKE_MANAGED_ROOT"
      }
    },
    "state.paths": {"status": "ok"}
  }
}
JSON
            ;;
        mismatched-managed-install)
            cat <<JSON
{
  "schemaVersion": 1,
  "checks": {
    "auth.credentials": {"status": "ok"},
    "config.load": {"status": "ok"},
    "installation": {
      "status": "fail",
      "summary": "npm install -g @openai/codex would update a different install",
      "details": {
        "managed package root": "$FAKE_MANAGED_ROOT",
        "running package root": "/fixture/.local/lib/node_modules/@openai/codex"
      }
    },
    "state.paths": {"status": "ok"}
  }
}
JSON
            ;;
        cross-check-install)
            cat <<JSON
{
  "schemaVersion": 1,
  "checks": {
    "auth.credentials": {"status": "ok"},
    "config.load": {"status": "ok"},
    "installation": {
      "status": "fail",
      "summary": "npm install -g @openai/codex would update a different install"
    },
    "updates.status": {
      "status": "fail",
      "details": {
        "managed package root": "$FAKE_MANAGED_ROOT",
        "running package root": "$FAKE_MANAGED_ROOT"
      }
    },
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
case ${FAKE_CODEX_HOLD:-0} in
    1)
        if [ -n "${FAKE_CODEX_PID_FILE:-}" ]; then
            printf '%s\n' "$$" >"$FAKE_CODEX_PID_FILE"
        fi
        trap 'exit 143' HUP INT TERM
        while :; do
            /bin/sleep 1
        done
        ;;
    short) /bin/sleep 2 ;;
esac
exit "$status"
EOF
chmod 755 "$fake_bin/codex-launcher"

cat >"$fake_bin/thread-recovery" <<'EOF'
#!/bin/sh
set -eu
original=$*
printf '%s\n' "$original" >>"$FAKE_RECOVERY_CALLS"
mode=$1
shift
name=
thread=
target=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --name) name=$2; shift 2 ;;
        --target) target=$2; shift 2 ;;
        --thread) thread=$2; shift 2 ;;
        *) exit 2 ;;
    esac
done
[ -n "$name" ] && [ -n "$target" ] || exit 2
effective_name=$target:$name
state=$HARNESS_TEST_RUNTIME_DIR/$effective_name.recovery.state
write_state() {
    phase=$1
    reason=$2
    owner=$3
    {
        printf 'schema=1\n'
        printf 'name=%s\n' "$effective_name"
        printf 'thread=%s\n' "$thread"
        printf 'owner_pid=%s\n' "$owner"
        printf 'phase=%s\n' "$phase"
        printf 'reason=%s\n' "$reason"
        printf 'recoveries=0\n'
        printf 'rolled_back=0\n'
    } >"$state"
    chmod 600 "$state"
}
print_state() {
    phase=$(sed -n 's/^phase=//p' "$state")
    reason=$(sed -n 's/^reason=//p' "$state")
    owner=$(sed -n 's/^owner_pid=//p' "$state")
    stored_thread=$(sed -n 's/^thread=//p' "$state")
    printf 'CODEX_THREAD_RECOVERY name=%s thread=%s phase=%s reason=%s recoveries=0 rolled_back=0 owner_pid=%s\n' \
        "$effective_name" "$stored_thread" "$phase" "$reason" "$owner"
}
case "$mode" in
    --check)
        [ -n "$thread" ] && [ -n "$target" ] || exit 2
        [ "${FAKE_RECOVERY_MODE:-watching}" != blocked-check ] || exit 2
        printf 'CODEX_THREAD_RECOVERY mode=check target=%s thread=%s status=ready thread_status=idle\n' \
            "$target" "$thread"
        ;;
    --recover)
        [ -n "$thread" ] && [ -n "$target" ] || exit 2
        if [ "${FAKE_RECOVERY_MODE:-watching}" = blocked ]; then
            write_state blocked unsafe-tail "$$"
            print_state
            exit 2
        fi
        write_state watching thread-idle "$$"
        print_state
        ;;
    --watch)
        [ -n "$thread" ] && [ -n "$target" ] || exit 2
        stop() {
            write_state stopped operator-stop "$$"
            exit 0
        }
        trap stop HUP INT TERM
        write_state watching thread-idle "$$"
        case ${FAKE_RECOVERY_MODE:-watching} in
            exit-after-ready)
                /bin/sleep 1
                exit 1
                ;;
            exit-once-after-ready)
                marker=$HARNESS_TEST_RUNTIME_DIR/$effective_name.recovery.once
                if [ ! -e "$marker" ]; then
                    : >"$marker"
                    /bin/sleep 1
                    exit 1
                fi
                ;;
        esac
        while :; do
            /bin/sleep 1
        done
        ;;
    --status)
        if [ ! -f "$state" ]; then
            printf 'CODEX_THREAD_RECOVERY name=%s phase=absent\n' "$effective_name"
        else
            print_state
        fi
        ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/thread-recovery"

cat >"$fake_bin/sleep" <<'EOF'
#!/bin/sh
set -eu
if [ "$1" = 1 ]; then
    /bin/sleep 0.05
    exit 0
fi
printf '%s\n' "$1" >>"$FAKE_SLEEP_CALLS"
EOF
chmod 755 "$fake_bin/sleep"

run_supervisor() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_CODEX_LAUNCHER="$fake_bin/codex-launcher" \
    HARNESS_TEST_THREAD_RECOVERY="$fake_bin/thread-recovery" \
    HARNESS_TEST_RUNTIME_DIR="$runtime" \
    HARNESS_TEST_JITTER=0 \
    FAKE_MANAGED_ROOT="$managed_root" \
    FAKE_CODEX_CALLS="$TEST_ROOT/codex.calls" \
    FAKE_RECOVERY_CALLS="$TEST_ROOT/recovery.calls" \
    FAKE_CODEX_STATUSES="$TEST_ROOT/codex.statuses" \
    FAKE_SLEEP_CALLS="$TEST_ROOT/sleep.calls" \
    FAKE_CODEX_PID_FILE="${FAKE_CODEX_PID_FILE:-}" \
    PATH="$fake_bin:/usr/bin:/bin" \
        "$HARNESS" codex-resilient "$@" && supervisor_status=0 ||
        supervisor_status=$?
    unset FAKE_CODEX_HOLD FAKE_CODEX_PID_FILE FAKE_DOCTOR_MODE \
        FAKE_RECOVERY_MODE HARNESS_TEST_DURATION_FILE HARNESS_TEST_PLATFORM
    return "$supervisor_status"
}

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/recovery.calls"
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
grep -F 'schema=2' "$runtime/harness/fresh.state" >/dev/null ||
    fail "target-scoped state schema"
grep -F 'target=harness' "$runtime/harness/fresh.state" >/dev/null ||
    fail "target identity is absent from state"
[ ! -e "$runtime/fresh.state" ] ||
    fail "new state used the legacy flat namespace"
run_supervisor --status --target students --name fresh \
    >"$TEST_ROOT/cross-target-status.out"
grep -F 'target=students phase=absent' \
    "$TEST_ROOT/cross-target-status.out" >/dev/null ||
    fail "cross-target runtime status leaked"

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
FAKE_RECOVERY_MODE=blocked-check \
    run_supervisor --run --name explicit-cross --session session-cross \
        >"$TEST_ROOT/explicit-cross.out" 2>&1 &&
    fail "cross-target explicit session was launched"
[ ! -s "$TEST_ROOT/codex.calls" ] ||
    fail "cross-target explicit session reached native Codex"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name remote-explicit \
    --remote-session session-remote >"$TEST_ROOT/remote-explicit.out"
[ "$(sed -n '1p' "$TEST_ROOT/codex.calls")" = \
    "resume --remote unix:// session-remote" ] ||
    fail "remote explicit first resume"
[ "$(sed -n '2p' "$TEST_ROOT/codex.calls")" = "doctor --json" ] ||
    fail "remote explicit native doctor"
[ "$(sed -n '3p' "$TEST_ROOT/codex.calls")" = \
    "resume --remote unix:// session-remote" ] ||
    fail "remote explicit recovery drifted"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 3 ] ||
    fail "remote explicit unexpected call count"
[ "$(sed -n '1p' "$TEST_ROOT/sleep.calls")" = 15 ] ||
    fail "remote explicit first retry delay"
grep -F -- '--recover --name remote-explicit --target harness --thread session-remote' \
    "$TEST_ROOT/recovery.calls" >/dev/null ||
    fail "remote explicit recovery preflight"
grep -F -- '--watch --name remote-explicit --target harness --thread session-remote' \
    "$TEST_ROOT/recovery.calls" >/dev/null ||
    fail "remote explicit recovery watcher"
grep -F 'phase=stopped' "$runtime/harness:remote-explicit.recovery.state" \
    >/dev/null || fail "remote explicit recovery watcher cleanup"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/recovery.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
FAKE_RECOVERY_MODE=exit-once-after-ready FAKE_CODEX_HOLD=short \
    run_supervisor --run --name watcher-restart \
        --remote-session session-watcher-restart \
        >"$TEST_ROOT/watcher-restart.out" 2>&1
grep -F 'status=watcher-restarted count=1' \
    "$TEST_ROOT/watcher-restart.out" >/dev/null ||
    fail "single watcher loss was not replaced"
grep -F 'reason=clean-exit' "$TEST_ROOT/watcher-restart.out" >/dev/null ||
    fail "replacement watcher did not preserve the Codex process"
[ "$(grep -c '^resume --remote unix:// session-watcher-restart$' \
    "$TEST_ROOT/codex.calls")" = 1 ] ||
    fail "watcher replacement relaunched Codex"
[ "$(grep -c '^--recover --name watcher-restart --target harness --thread session-watcher-restart$' \
    "$TEST_ROOT/recovery.calls")" = 2 ] ||
    fail "watcher replacement did not repeat safe-tail preflight once"
[ "$(grep -c '^--watch --name watcher-restart --target harness --thread session-watcher-restart$' \
    "$TEST_ROOT/recovery.calls")" = 2 ] ||
    fail "watcher replacement count"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/recovery.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
watcher_exit_pid_file=$TEST_ROOT/watcher-exit.pid
FAKE_RECOVERY_MODE=exit-after-ready FAKE_CODEX_HOLD=1 \
    FAKE_CODEX_PID_FILE=$watcher_exit_pid_file \
    run_supervisor --run --name watcher-exit \
        --remote-session session-watcher-exit \
        >"$TEST_ROOT/watcher-exit.out" 2>&1 &&
    fail "dead recovery watcher left Codex running"
grep -F 'reason=thread-recovery-blocked' \
    "$TEST_ROOT/watcher-exit.out" >/dev/null ||
    fail "dead recovery watcher classification"
[ "$(grep -c '^resume --remote unix:// session-watcher-exit$' \
    "$TEST_ROOT/codex.calls")" = 1 ] ||
    fail "dead recovery watcher relaunched Codex"
[ "$(grep -c '^--recover --name watcher-exit --target harness --thread session-watcher-exit$' \
    "$TEST_ROOT/recovery.calls")" = 4 ] ||
    fail "persistent watcher failure preflight was not bounded"
[ "$(grep -c '^--watch --name watcher-exit --target harness --thread session-watcher-exit$' \
    "$TEST_ROOT/recovery.calls")" = 4 ] ||
    fail "persistent watcher replacement was not bounded"
watcher_exit_pid=$(sed -n '1p' "$watcher_exit_pid_file")
case "$watcher_exit_pid" in
    ''|*[!0-9]*) fail "dead recovery watcher client PID was not recorded" ;;
esac
if kill -0 "$watcher_exit_pid" 2>/dev/null; then
    fail "dead recovery watcher orphaned its Codex client"
fi

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
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
HARNESS_TEST_PLATFORM=Linux FAKE_DOCTOR_MODE=managed-install \
    run_supervisor --run --name managed-install --last \
    >"$TEST_ROOT/managed-install.out"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 3 ] ||
    fail "managed Linux installation mismatch blocked recovery"
grep -F 'reason=clean-exit' "$TEST_ROOT/managed-install.out" >/dev/null ||
    fail "managed Linux installation recovery status"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
HARNESS_TEST_PLATFORM=Darwin FAKE_DOCTOR_MODE=managed-install \
    run_supervisor --run --name unmanaged-install --last \
    >"$TEST_ROOT/unmanaged-install.out" 2>&1 &&
    fail "non-Linux installation mismatch was retried"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 2 ] ||
    fail "non-Linux installation mismatch launched again"
grep -F 'reason=local-installation' \
    "$TEST_ROOT/unmanaged-install.out" >/dev/null ||
    fail "non-Linux installation failure classification"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
HARNESS_TEST_PLATFORM=Linux FAKE_DOCTOR_MODE=mismatched-managed-install \
    run_supervisor --run --name mismatched-managed-install --last \
    >"$TEST_ROOT/mismatched-managed-install.out" 2>&1 &&
    fail "mismatched managed installation was retried"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 2 ] ||
    fail "mismatched managed installation launched again"
grep -F 'reason=local-installation' \
    "$TEST_ROOT/mismatched-managed-install.out" >/dev/null ||
    fail "mismatched managed installation failure classification"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n0\n' >"$TEST_ROOT/codex.statuses"
HARNESS_TEST_PLATFORM=Linux FAKE_DOCTOR_MODE=cross-check-install \
    run_supervisor --run --name cross-check-install --last \
    >"$TEST_ROOT/cross-check-install.out" 2>&1 &&
    fail "installation parser borrowed later check details"
[ "$(wc -l <"$TEST_ROOT/codex.calls" | tr -d ' ')" = 2 ] ||
    fail "cross-check installation launched again"
grep -F 'reason=local-installation' \
    "$TEST_ROOT/cross-check-install.out" >/dev/null ||
    fail "cross-check installation failure classification"

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
if run_supervisor --run --name global --last-all \
    >"$TEST_ROOT/global.out" 2>&1; then
    fail "global resume entered target-scoped supervision"
fi
[ ! -s "$TEST_ROOT/codex.calls" ] ||
    fail "rejected global resume reached native Codex"
grep -F 'outside target-scoped supervision' "$TEST_ROOT/global.out" \
    >/dev/null || fail "global resume rejection reason"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '1\n1\n1\n1\n1\n1\n0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name backoff --last >"$TEST_ROOT/backoff.out"
expected_delays='15
30
60
120
240
300'
[ "$(cat "$TEST_ROOT/sleep.calls")" = "$expected_delays" ] ||
    fail "exponential retry schedule"
run_count=$(grep -c '^resume --last$' "$TEST_ROOT/codex.calls")
[ "$run_count" = 7 ] || fail "repository resume selector changed"
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

run_supervisor --status --target harness --name backoff >"$TEST_ROOT/status.out"
grep -F 'CODEX_RESILIENT mode=status name=backoff target=harness phase=stopped' \
    "$TEST_ROOT/status.out" >/dev/null || fail "status output"
run_supervisor --status --name remote-explicit \
    >"$TEST_ROOT/remote-status.out"
grep -F 'CODEX_THREAD_RECOVERY name=harness:remote-explicit' \
    "$TEST_ROOT/remote-status.out" >/dev/null ||
    fail "remote recovery status output"

run_supervisor --plan --name planned --last >"$TEST_ROOT/plan.out"
grep -F 'CODEX_RESILIENT mode=plan name=planned target=harness selector=last status=ready' \
    "$TEST_ROOT/plan.out" >/dev/null || fail "plan output"
HARNESS_TEST_PLATFORM=Darwin run_supervisor --plan --name darwin --last \
    >"$TEST_ROOT/darwin.out"
grep -F 'name=darwin target=harness selector=last status=ready' \
    "$TEST_ROOT/darwin.out" >/dev/null || fail "Darwin plan portability"
run_supervisor --plan --name remote-plan \
    --remote-session session-remote >"$TEST_ROOT/remote-plan.out"
grep -F 'name=remote-plan target=harness selector=remote-explicit status=ready' \
    "$TEST_ROOT/remote-plan.out" >/dev/null ||
    fail "remote explicit plan"
grep -F 'THREAD_RECOVERY action=watch rollback=safe-tail-only' \
    "$TEST_ROOT/remote-plan.out" >/dev/null ||
    fail "remote explicit recovery plan"
run_supervisor --plan --name explicit-target --target harness --last \
    >"$TEST_ROOT/explicit-target.out"
grep -F 'name=explicit-target target=harness selector=last status=ready' \
    "$TEST_ROOT/explicit-target.out" >/dev/null ||
    fail "explicit target plan"
run_supervisor --plan --name wrong-target --target students --last \
    >"$TEST_ROOT/wrong-target.out" 2>&1 &&
    fail "mismatched repository target was accepted"
grep -F 'target does not match its repository' \
    "$TEST_ROOT/wrong-target.out" >/dev/null ||
    fail "mismatched repository target classification"

: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
FAKE_RECOVERY_MODE=blocked \
    run_supervisor --run --name recovery-blocked \
        --remote-session session-blocked \
        >"$TEST_ROOT/recovery-blocked.out" 2>&1 &&
    fail "unsafe thread recovery tail was accepted"
[ ! -s "$TEST_ROOT/codex.calls" ] ||
    fail "unsafe thread recovery launched Codex"
grep -F 'reason=thread-recovery-blocked' \
    "$TEST_ROOT/recovery-blocked.out" >/dev/null ||
    fail "unsafe thread recovery classification"

mkdir "$runtime/legacy-live.lock"
chmod 700 "$runtime/legacy-live.lock"
printf '%s\n' "$$" >"$runtime/legacy-live.lock/pid"
chmod 600 "$runtime/legacy-live.lock/pid"
: >"$TEST_ROOT/codex.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name legacy-live --last \
    >"$TEST_ROOT/legacy-live.out" 2>&1 &&
    fail "target-scoped supervisor bypassed a live legacy lock"
grep -F 'reason=legacy-already-running' \
    "$TEST_ROOT/legacy-live.out" >/dev/null ||
    fail "live legacy lock classification"
unlink "$runtime/legacy-live.lock/pid"
rmdir "$runtime/legacy-live.lock"

mkdir "$runtime/legacy-stale.lock"
chmod 700 "$runtime/legacy-stale.lock"
printf '99999999\n' >"$runtime/legacy-stale.lock/pid"
chmod 600 "$runtime/legacy-stale.lock/pid"
: >"$TEST_ROOT/codex.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name legacy-stale --last \
    >"$TEST_ROOT/legacy-stale.out"
grep -F 'reason=clean-exit' "$TEST_ROOT/legacy-stale.out" >/dev/null ||
    fail "stale legacy lock was not recovered"
[ ! -e "$runtime/legacy-stale.lock" ] ||
    fail "stale legacy lock residue"

mkdir "$runtime/harness/locked.lock"
chmod 700 "$runtime/harness/locked.lock"
printf '%s\n' "$$" >"$runtime/harness/locked.lock/pid"
chmod 600 "$runtime/harness/locked.lock/pid"
: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name locked --last >"$TEST_ROOT/locked.out" 2>&1 &&
    fail "live lock was ignored"
grep -F 'reason=already-running' "$TEST_ROOT/locked.out" >/dev/null ||
    fail "live lock classification"

mkdir "$runtime/harness/stale-lock.lock"
chmod 700 "$runtime/harness/stale-lock.lock"
printf '99999999\n' >"$runtime/harness/stale-lock.lock/pid"
chmod 600 "$runtime/harness/stale-lock.lock/pid"
: >"$TEST_ROOT/codex.calls"
: >"$TEST_ROOT/sleep.calls"
printf '0\n' >"$TEST_ROOT/codex.statuses"
run_supervisor --run --name stale-lock --last \
    >"$TEST_ROOT/stale-lock.out"
grep -F 'reason=clean-exit' "$TEST_ROOT/stale-lock.out" >/dev/null ||
    fail "stale lock recovery"
[ ! -e "$runtime/harness/stale-lock.lock" ] ||
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

for state in "$runtime"/*.state "$runtime"/*/*.state; do
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
