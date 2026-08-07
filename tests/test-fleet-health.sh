#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HEALTH=$ROOT/libexec/harness-fleet-health
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-fleet-health-test.XXXXXX")
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
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

PUBLIC=$TEMP_DIR/public
FAKE_BIN=$TEMP_DIR/fake-bin
STATE=$TEMP_DIR/state
mkdir -p "$PUBLIC/bin" "$PUBLIC/libexec" "$PUBLIC/profiles" "$FAKE_BIN" "$STATE"
cp "$ROOT/bin/harness" "$PUBLIC/bin/harness"
cp "$ROOT/libexec/harness-inventory" "$PUBLIC/libexec/harness-inventory"
cp "$HEALTH" "$PUBLIC/libexec/harness-fleet-health"
cp "$ROOT/libexec/harness-t4-hub" "$PUBLIC/libexec/harness-t4-hub"
cp "$ROOT/profiles/fleet-status-sources.tsv" "$PUBLIC/profiles/"
cp "$ROOT/profiles/fleet-maintenance.tsv" "$PUBLIC/profiles/"
cp "$ROOT/profiles/t4-hub-routes.tsv" "$PUBLIC/profiles/"

cat >"$PUBLIC/libexec/harness-al-session" <<'EOF'
#!/bin/sh
printf '%s\n' al-session >>"$HARNESS_FLEET_HEALTH_STATE/calls"
[ ! -e "$HARNESS_FLEET_HEALTH_STATE/al-session.fail" ]
EOF
chmod 755 "$PUBLIC/libexec/harness-al-session"

cat >"$FAKE_BIN/ssh" <<'EOF'
#!/bin/sh
route=
for argument do
    case "$argument" in
        ab|ab2|ri|al|rc|t4|abq|abq2|aist|aist2|home|home2|office|office2|riken|riken2)
            route=$argument
            ;;
    esac
done
[ -n "$route" ] || exit 2

counter_lock=$HARNESS_FLEET_HEALTH_STATE/concurrency.lock
acquire_counter_lock() {
    while ! mkdir "$counter_lock" 2>/dev/null; do :; done
}
finish_probe() {
    probe_exit_status=$?
    trap - 0 HUP INT TERM
    acquire_counter_lock
    active=$(sed -n '1p' "$HARNESS_FLEET_HEALTH_STATE/active")
    active=$((active - 1))
    printf '%s\n' "$active" >"$HARNESS_FLEET_HEALTH_STATE/active"
    printf 'end %s\n' "$route" >>"$HARNESS_FLEET_HEALTH_STATE/events"
    rmdir "$counter_lock"
    exit "$probe_exit_status"
}

acquire_counter_lock
active=$(sed -n '1p' "$HARNESS_FLEET_HEALTH_STATE/active")
active=$((active + 1))
printf '%s\n' "$active" >"$HARNESS_FLEET_HEALTH_STATE/active"
maximum=$(sed -n '1p' "$HARNESS_FLEET_HEALTH_STATE/max-active")
if [ "$active" -gt "$maximum" ]; then
    printf '%s\n' "$active" >"$HARNESS_FLEET_HEALTH_STATE/max-active"
fi
printf 'start %s\n' "$route" >>"$HARNESS_FLEET_HEALTH_STATE/events"
rmdir "$counter_lock"
trap finish_probe 0

printf '%s %s\n' "$route" "$*" >>"$HARNESS_FLEET_HEALTH_STATE/calls"
if [ -f "$HARNESS_FLEET_HEALTH_STATE/$route.delay" ]; then
    sleep "$(sed -n '1p' "$HARNESS_FLEET_HEALTH_STATE/$route.delay")"
fi
if [ -e "$HARNESS_FLEET_HEALTH_STATE/$route.fail" ]; then
    echo 'PRIVATE-SSH-DIAGNOSTIC' >&2
    exit 1
fi
exit 0
EOF
chmod 755 "$FAKE_BIN/ssh"

SSH_AUTH_SOCK=$TEMP_DIR/agent.sock
export SSH_AUTH_SOCK
ssh-agent -a "$SSH_AUTH_SOCK" -s >"$TEMP_DIR/agent.env"
AGENT_PID=$(sed -n 's/^SSH_AGENT_PID=\([0-9][0-9]*\);.*/\1/p' "$TEMP_DIR/agent.env")
[ -n "$AGENT_PID" ] || fail "test SSH agent PID"

printf '%s\n' 0 >"$STATE/active"
printf '%s\n' 0 >"$STATE/max-active"
: >"$STATE/events"
# These delayed routes occupied the first, second, and third former batches.
# Batch barriers therefore imposed a fixture-only lower bound of 4500 ms.
printf '%s\n' 1.5 >"$STATE/ab.delay"
printf '%s\n' 0.3 >"$STATE/ab2.delay"
printf '%s\n' 0.3 >"$STATE/ri.delay"
printf '%s\n' 0.3 >"$STATE/al.delay"
printf '%s\n' 1.5 >"$STATE/rc.delay"
printf '%s\n' 1.5 >"$STATE/aist.delay"
queue_start_ns=$(python3 -c 'import time; print(time.monotonic_ns())')
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1785312000 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" >"$TEMP_DIR/healthy.out"
queue_end_ns=$(python3 -c 'import time; print(time.monotonic_ns())')
queue_elapsed_ms=$(((queue_end_ns - queue_start_ns) / 1000000))
max_active=$(sed -n '1p' "$STATE/max-active")
[ "$max_active" -le 4 ] || fail "probe queue exceeded concurrency cap"
[ "$max_active" -eq 4 ] || fail "probe queue did not fill available slots"
[ "$(sed -n '1p' "$STATE/active")" -eq 0 ] ||
    fail "probe queue left an active fake probe"
[ "$queue_elapsed_ms" -lt 3500 ] ||
    fail "probe queue exceeded former-batch critical-path bound"
ab_end_line=$(sed -n '/^end ab$/{=;q;}' "$STATE/events")
rc_start_line=$(sed -n '/^start rc$/{=;q;}' "$STATE/events")
aist_start_line=$(sed -n '/^start aist$/{=;q;}' "$STATE/events")
[ -n "$ab_end_line" ] && [ -n "$rc_start_line" ] &&
    [ "$rc_start_line" -lt "$ab_end_line" ] ||
    fail "former second batch did not overlap the delayed first batch"
[ -n "$ab_end_line" ] && [ -n "$aist_start_line" ] &&
    [ "$aist_start_line" -lt "$ab_end_line" ] ||
    fail "former third batch did not overlap the delayed first batch"
printf 'fleet health queue fixture: elapsed_ms=%s former_barrier_min_ms=4500 max_concurrency=%s\n' \
    "$queue_elapsed_ms" "$max_active"
unlink "$STATE/ab.delay"
unlink "$STATE/ab2.delay"
unlink "$STATE/ri.delay"
unlink "$STATE/al.delay"
unlink "$STATE/rc.delay"
unlink "$STATE/aist.delay"

expected='local ab ab2 ri al rc t4 abq aist home office riken'
observed=$(sed -n 's/^FLEET_HEALTH node=\([^ ]*\).*/\1/p' "$TEMP_DIR/healthy.out" |
    tr '\n' ' ' | sed 's/ $//')
[ "$observed" = "$expected" ] || fail "fleet result order"
grep -F -x 'Fleet: Linux pass; Macs pass.' "$TEMP_DIR/healthy.out" >/dev/null ||
    fail "healthy compact summary"

grep '^al ' "$STATE/calls" | grep -F 'ControlMaster=' >/dev/null &&
    fail "AL probe overrode ControlMaster"
grep '^al ' "$STATE/calls" | grep -F 'ControlPath=' >/dev/null &&
    fail "AL probe overrode ControlPath"
[ "$(grep -c '^al-session$' "$STATE/calls")" -eq 1 ] ||
    fail "AL managed status was not checked"
for route in \
    ab ab2 ri al rc t4 abq abq2 \
    aist aist2 home home2 office office2 riken riken2; do
    [ "$(grep -c "^$route " "$STATE/calls")" -eq 1 ] ||
        fail "route was not probed exactly once: $route"
done
for excluded in login login2 abci_login alps_login web; do
    grep -F "$excluded" "$STATE/calls" >/dev/null &&
        fail "excluded transport was probed"
done
for route in abq abq2 aist aist2 home home2 office office2 riken riken2; do
    grep "^$route " "$STATE/calls" | grep -F 'ControlMaster=no' >/dev/null ||
        fail "independent route contract missing for $route"
    grep "^$route " "$STATE/calls" | grep -F 'ControlPath=none' >/dev/null ||
        fail "independent route path contract missing for $route"
done

: >"$STATE/calls"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=t4 HARNESS_T4_HUB_HOSTNAME=login1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1785312000 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    --hub t4 --login-node login1 >"$TEMP_DIR/hub.out"
grep -F -x \
    'FLEET_HEALTH node=local class=linux status=excluded routes=skipped reason=local-outage hub=t4' \
    "$TEMP_DIR/hub.out" >/dev/null || fail "hub Local exclusion"
grep -F -x \
    'FLEET_HEALTH node=t4 class=linux status=pass routes=local hub=t4 login_node=login1' \
    "$TEMP_DIR/hub.out" >/dev/null || fail "hub local t4 result"
grep -F -x 'FLEET_HEALTH node=riken class=mac status=pass routes=1 hub=login1' \
    "$TEMP_DIR/hub.out" >/dev/null || fail "hub Mac route result"
grep -F -x 'Fleet: Linux pass excluded nodes=local; Macs pass.' \
    "$TEMP_DIR/hub.out" >/dev/null || fail "hub compact summary"
for route in ab ab2 ri al rc abq aist home office riken; do
    [ "$(grep -c "^$route " "$STATE/calls")" -eq 1 ] ||
        fail "hub route was not probed exactly once: $route"
done
for excluded in t4 abq2 aist2 home2 office2 riken2; do
    grep "^$excluded " "$STATE/calls" >/dev/null &&
        fail "hub probed excluded route: $excluded"
done
grep -F -x 'al-session' "$STATE/calls" >/dev/null &&
    fail "hub used Local AL session state"

: >"$STATE/calls"
: >"$STATE/abq.fail"
: >"$STATE/abq2.fail"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1785200400 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/maintenance.out"
grep -F -x \
    'FLEET_HEALTH node=abq class=linux status=maintenance routes=skipped/2 maintenance_end=2026-07-29T17:00:00+09:00 status_url=https://unit.aist.go.jp/g-quat/HowToUse/abci_q/#status' \
    "$TEMP_DIR/maintenance.out" >/dev/null ||
    fail "ABQ maintenance status"
grep -F -x 'Fleet: Linux maintenance nodes=abq; Macs pass.' \
    "$TEMP_DIR/maintenance.out" >/dev/null ||
    fail "maintenance compact summary"
grep -E '^abq2? ' "$STATE/calls" >/dev/null &&
    fail "ABQ was probed during scheduled maintenance"
unlink "$STATE/abq.fail"
unlink "$STATE/abq2.fail"

: >"$STATE/calls"
: >"$STATE/ab.fail"
: >"$STATE/ab2.fail"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1787274000 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/ab-maintenance.out"
grep -F -x \
    'FLEET_HEALTH node=ab class=linux status=maintenance routes=skipped/1 maintenance_end=2026-08-28T13:00:00+09:00 status_url=https://abci.ai/en/about_abci/info.html' \
    "$TEMP_DIR/ab-maintenance.out" >/dev/null ||
    fail "AB maintenance status"
grep -F -x \
    'FLEET_HEALTH node=ab2 class=linux status=maintenance routes=skipped/1 maintenance_end=2026-08-28T13:00:00+09:00 status_url=https://abci.ai/en/about_abci/info.html' \
    "$TEMP_DIR/ab-maintenance.out" >/dev/null ||
    fail "AB2 maintenance status"
grep -F -x 'Fleet: Linux maintenance nodes=ab,ab2; Macs pass.' \
    "$TEMP_DIR/ab-maintenance.out" >/dev/null ||
    fail "AB maintenance compact summary"
grep -E '^ab2? ' "$STATE/calls" >/dev/null &&
    fail "ABCI 3.0 was probed during scheduled maintenance"
unlink "$STATE/ab.fail"
unlink "$STATE/ab2.fail"

: >"$STATE/ab.fail"
: >"$STATE/ab2.fail"
: >"$STATE/ri.fail"
: >"$STATE/al-session.fail"
: >"$STATE/rc.fail"
: >"$STATE/t4.fail"
: >"$STATE/abq2.fail"
: >"$STATE/riken.fail"
if PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1787889600 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/failed.out" 2>"$TEMP_DIR/failed.err"; then
    fail "fleet health accepted failed routes"
fi
grep -F -x \
    'Fleet: Linux fail nodes=ab,ab2,ri,al,rc,t4,abq; Macs fail nodes=riken.' \
    "$TEMP_DIR/failed.out" >/dev/null || fail "failed compact summary"
for expected_failure in \
    'node=ab class=linux status=fail routes=1 status_url=https://abci.ai/en/about_abci/info.html' \
    'node=ab2 class=linux status=fail routes=1 status_url=https://abci.ai/en/about_abci/info.html' \
    'node=ri class=linux status=fail routes=1 status_url=https://docs.r-ccs.riken.jp/rikyu/en/contact/' \
    'node=al class=linux status=fail routes=managed status_url=https://status.cscs.ch/' \
    'node=rc class=linux status=fail routes=1 status_url=https://portal.cloud.r-ccs.riken.jp/' \
    'node=t4 class=linux status=fail routes=1 status_url=https://www.t4.cii.isct.ac.jp/' \
    'node=abq class=linux status=fail routes=2 status_url=https://unit.aist.go.jp/g-quat/HowToUse/abci_q/#status'; do
    grep -F -x "FLEET_HEALTH $expected_failure" "$TEMP_DIR/failed.out" >/dev/null ||
        fail "remote Linux failure source: $expected_failure"
done
grep -F 'PRIVATE-SSH-DIAGNOSTIC' "$TEMP_DIR/failed.out" "$TEMP_DIR/failed.err" \
    >/dev/null && fail "private SSH diagnostic escaped"
for failed_route in ab ab2 ri al-session rc t4 abq2 riken; do
    unlink "$STATE/$failed_route.fail"
done

printf '%s\n' \
    'ab|1790000000|1790001000|2026-09-21T23:30:00+09:00|https://abci.ai/en/about_abci/info.html|scheduled-service-stop' \
    >>"$PUBLIC/profiles/fleet-maintenance.tsv"
PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1787889600 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/non-overlap.out"
grep -F -x 'Fleet: Linux pass; Macs pass.' "$TEMP_DIR/non-overlap.out" \
    >/dev/null || fail "non-overlapping maintenance windows"

cp "$PUBLIC/profiles/fleet-status-sources.tsv" \
    "$PUBLIC/profiles/fleet-status-sources.saved"
printf '%s\n' 'ab|https://duplicate.invalid/|public-status' \
    >>"$PUBLIC/profiles/fleet-status-sources.tsv"
: >"$STATE/calls"
if PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1787889600 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/bad-source.out" 2>"$TEMP_DIR/bad-source.err"; then
    fail "fleet health accepted a duplicate status source"
fi
[ ! -s "$STATE/calls" ] || fail "malformed source registry reached probes"
mv "$PUBLIC/profiles/fleet-status-sources.saved" \
    "$PUBLIC/profiles/fleet-status-sources.tsv"

printf '%s\n' \
    'ab|1787275000|1787276000|2026-08-21T10:33:20+09:00|https://abci.ai/en/about_abci/info.html|scheduled-service-stop' \
    >>"$PUBLIC/profiles/fleet-maintenance.tsv"
: >"$STATE/calls"
if PATH="$FAKE_BIN:/usr/bin:/bin" HARNESS_ROOT="$PUBLIC" HARNESS_TESTING=1 \
    HARNESS_FLEET_HEALTH_NOW_EPOCH=1787889600 \
    HARNESS_FLEET_HEALTH_STATE="$STATE" "$HEALTH" \
    >"$TEMP_DIR/overlap.out" 2>"$TEMP_DIR/overlap.err"; then
    fail "fleet health accepted overlapping maintenance windows"
fi
[ ! -s "$STATE/calls" ] || fail "overlapping registry reached probes"

POLICY=$ROOT/docs/agent-policy/fleet.md
grep -F 'Run fresh `harness fleet-health` for fleet/runtime work' \
    "$POLICY" >/dev/null || fail "risk-bounded fleet health policy"
grep -F 'consult that system'\''s official' "$POLICY" >/dev/null ||
    fail "official maintenance lookup policy"

echo "fleet health tests: PASS"
