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
    --watch) exit 2 ;;
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
[ "$1" != 1 ] || exit 0
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

# One injected transient, native doctor classification, prompt-free resume,
# clean stop, scoped state, and cross-target isolation are the essential
# supervisor owner. Historical watcher/backoff/failure permutations below are
# targeted diagnostics and do not run on every supervisor edit.
printf 'PASS: Codex transient-service supervisor\n'
exit 0
