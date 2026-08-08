#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
MONITOR=$ROOT/libexec/harness-connection-monitor
# Darwin's per-user TMPDIR is too long for an ssh-agent Unix socket. Keep the
# whole guarded fixture under the canonical short system temporary root.
TEMP_BASE=$(CDPATH='' cd -- /tmp && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/hcm.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
AGENT_PID=

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -n "$AGENT_PID" ]; then
        kill "$AGENT_PID" 2>/dev/null || true
        wait "$AGENT_PID" 2>/dev/null || true
    fi
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded connection-monitor cleanup" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

STATE=$TEMP_DIR/state
FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$STATE" "$FAKE_BIN"
cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
all=" $* "
case "$all" in
    *' macos-tunnel-supervisor '*)
        if [ -n "${HARNESS_MONITOR_SUPERVISOR_LOG:-}" ]; then
            printf '%s\n' "$all" >>"$HARNESS_MONITOR_SUPERVISOR_LOG"
        fi
        case "$all" in
            *' --host aist --auth-status '*) auth_host=aist ;;
            *' --host office --auth-status '*) auth_host=office ;;
            *' --host riken --auth-status '*) auth_host=riken ;;
            *' --host home --auth-status '*) auth_host=home ;;
            *) auth_host= ;;
        esac
        if [ -n "$auth_host" ]; then
            [ -e "$HARNESS_MONITOR_STATE/$auth_host.auth" ]
            exit
        fi
        case "$all" in
            *' --host aist --recover-pair '*) primary=aist; secondary=aist2 ;;
            *' --host office --recover-pair '*) primary=office; secondary=office2 ;;
            *' --host riken --recover-pair '*) primary=riken; secondary=riken2 ;;
            *' --host home --recover-pair '*) primary=home; secondary=home2 ;;
            *) exit 1 ;;
        esac
        [ -e "$HARNESS_MONITOR_STATE/$primary.auth" ] || exit 1
        if [ -e "$HARNESS_MONITOR_STATE/$primary.up" ]; then
            : >"$HARNESS_MONITOR_STATE/$secondary.up"
        elif [ -e "$HARNESS_MONITOR_STATE/$secondary.up" ]; then
            : >"$HARNESS_MONITOR_STATE/$primary.up"
        else
            exit 1
        fi
        exit 0
        ;;
esac
route=
for candidate in aist aist2 office office2 riken riken2 home home2 abq abq2; do
    case "$all" in *" $candidate "*) route=$candidate; break ;; esac
done
[ -n "$route" ] || exit 1

if [ -n "${HARNESS_MONITOR_PROBE_LOG:-}" ]; then
    printf '%s\n' "$route" >>"$HARNESS_MONITOR_PROBE_LOG"
fi
[ -e "$HARNESS_MONITOR_STATE/$route.up" ] || exit 1
EOF
chmod 755 "$FAKE_BIN/ssh"

SSH_AUTH_SOCK=$TEMP_DIR/agent.sock
export SSH_AUTH_SOCK
ssh-agent -a "$SSH_AUTH_SOCK" -s >"$TEMP_DIR/agent.env"
AGENT_PID=$(sed -n 's/^SSH_AGENT_PID=\([0-9][0-9]*\);.*/\1/p' "$TEMP_DIR/agent.env")
[ -n "$AGENT_PID" ] || fail "test SSH agent PID"

for route in aist aist2 office office2 riken riken2 home home2 abq abq2; do
    : >"$STATE/$route.up"
done
for auth_host in aist office riken home; do
    : >"$STATE/$auth_host.auth"
done

PROBE_LOG=$TEMP_DIR/probes.log
SUPERVISOR_LOG=$TEMP_DIR/supervisor.log

PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once >"$TEMP_DIR/healthy.out"
[ "$(grep -c 'state=healthy action=none' "$TEMP_DIR/healthy.out")" -eq 5 ] ||
    fail "healthy pair classification"

unlink "$STATE/riken.up"
PATH="$FAKE_BIN:/usr/bin:/bin" \
    HARNESS_MONITOR_STATE="$STATE" \
    HARNESS_MONITOR_PROBE_LOG="$PROBE_LOG" \
    HARNESS_MONITOR_SUPERVISOR_LOG="$SUPERVISOR_LOG" \
    "$MONITOR" --once >"$TEMP_DIR/degraded.out"
for route in aist aist2 office office2 riken riken2 home home2 abq abq2; do
    [ "$(grep -cx "$route" "$PROBE_LOG")" -eq 1 ] ||
        fail "initial snapshot did not probe $route exactly once"
done
[ ! -s "$SUPERVISOR_LOG" ] ||
    fail "snapshot attempted unintended recovery or authorization"
grep -F 'pair=riken/riken2' "$TEMP_DIR/degraded.out" |
    grep -F 'primary=down secondary=ready state=degraded action=recovery-disabled' \
        >/dev/null ||
    fail "delayed down-route classification"
[ "$(grep -c 'state=healthy action=none' "$TEMP_DIR/degraded.out")" -eq 4 ] ||
    fail "degraded snapshot changed healthy classifications"
: >"$STATE/riken.up"

unlink "$STATE/home.auth"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once --recover >"$TEMP_DIR/auth-drift.out"
grep -F 'pair=home/home2' "$TEMP_DIR/auth-drift.out" |
    grep -F 'state=at-risk action=authorization-blocked' >/dev/null ||
    fail "authorization drift classification"
: >"$STATE/home.auth"

unlink "$STATE/abq.up"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once --recover >"$TEMP_DIR/abq-failover.out"
grep -F 'pair=abq/abq2' "$TEMP_DIR/abq-failover.out" |
    grep -F 'state=degraded action=use-secondary' >/dev/null ||
    fail "ABQ secondary failover classification"
[ ! -e "$STATE/abq.up" ] || fail "ABQ observer attempted supervisor recovery"
: >"$STATE/abq.up"
unlink "$STATE/abq2.up"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once >"$TEMP_DIR/abq-primary.out"
grep -F 'pair=abq/abq2' "$TEMP_DIR/abq-primary.out" |
    grep -F 'state=degraded action=use-primary' >/dev/null ||
    fail "ABQ primary failover classification"
unlink "$STATE/abq.up"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once >"$TEMP_DIR/abq-unavailable.out"
grep -F 'pair=abq/abq2' "$TEMP_DIR/abq-unavailable.out" |
    grep -F 'state=unrecoverable action=routes-unavailable' >/dev/null ||
    fail "ABQ dual-route loss classification"
: >"$STATE/abq.up"
: >"$STATE/abq2.up"

unlink "$STATE/aist.up"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once >"$TEMP_DIR/degraded.out"
grep -F 'pair=aist/aist2' "$TEMP_DIR/degraded.out" |
    grep -F 'state=degraded action=recovery-disabled' >/dev/null ||
    fail "degraded pair classification"

PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once --recover >"$TEMP_DIR/recovered.out"
grep -F 'pair=aist/aist2' "$TEMP_DIR/recovered.out" |
    grep -F 'state=healthy action=recovered-primary' >/dev/null ||
    fail "supervised route recovery"
[ -e "$STATE/aist.up" ] || fail "recovery did not restore primary route"

unlink "$STATE/aist.up"
unlink "$STATE/aist.auth"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once --recover >"$TEMP_DIR/degraded-auth-drift.out"
grep -F 'pair=aist/aist2' "$TEMP_DIR/degraded-auth-drift.out" |
    grep -F 'state=at-risk action=authorization-blocked-primary' >/dev/null ||
    fail "degraded authorization drift classification"
[ ! -e "$STATE/aist.up" ] || fail "blocked authentication invented recovery"
: >"$STATE/aist.up"
: >"$STATE/aist.auth"

unlink "$STATE/aist.up"
unlink "$STATE/aist2.up"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once --recover >"$TEMP_DIR/unrecoverable.out"
grep -F 'pair=aist/aist2' "$TEMP_DIR/unrecoverable.out" |
    grep -F 'state=unrecoverable action=await-supervisor' >/dev/null ||
    fail "dual-route loss classification"

if env -u SSH_AUTH_SOCK -u TMUX_PANE -u XDG_RUNTIME_DIR \
    PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_MONITOR_STATE="$STATE" \
    "$MONITOR" --once >"$TEMP_DIR/no-agent.out" 2>&1; then
    fail "monitor accepted no safe SSH agent socket"
fi
grep -F 'connection monitor has no safe SSH agent socket' "$TEMP_DIR/no-agent.out" >/dev/null ||
    fail "missing agent refusal"

echo 'connection monitor tests: PASS'
