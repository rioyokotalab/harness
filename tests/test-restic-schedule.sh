#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/restic-schedule-test.XXXXXX")

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

expect_failure() {
    expected=$1
    output=$2
    shift 2
    if "$@" >"$output" 2>&1; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -F "$expected" "$output" >/dev/null ||
        fail "missing failure evidence: $expected"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

schedule_map=$ROOT/profiles/restic-schedules.tsv
rows=$(awk -F'|' '
    $0 !~ /^#/ {
        if (NF != 10 || seen[$1]++) exit 1
        if ($3 != "Asia/Tokyo" && $3 != "Europe/Zurich") exit 1
        if ($4 != "Sun" || $10 != "default") exit 1
        count++
    }
    END { print count + 0 }
' "$schedule_map") || fail "schedule schema"
[ "$rows" -eq 7 ] || fail "schedule row count"
grep '^ri|slurm|Asia/Tokyo|Sun|02:00|rkp00015|none|' "$schedule_map" >/dev/null ||
    fail "RI explicit project account"

fake_bin=$TEST_ROOT/fake-bin
fake_sched=$TEST_ROOT/fake-scheduler
mkdir -p "$fake_bin" "$fake_sched"
printf '%s\n' 100 >"$fake_sched/counter"
: >"$fake_sched/jobs"

cat >"$fake_bin/fake-scheduler" <<'EOF'
#!/bin/sh
set -eu
command_name=${0##*/}
jobs=$FAKE_SCHED_DIR/jobs
counter=$FAKE_SCHED_DIR/counter
username=$(id -un)

next_id() {
    value=$(sed -n '1p' "$counter")
    value=$((value + 1))
    printf '%s\n' "$value" >"$counter"
    printf '%s\n' "$value"
}

add_job() {
    id=$1
    name=$2
    [ "${FAKE_NO_RECORD:-0}" = 1 ] || printf '%s|%s|PENDING\n' "$id" "$name" >>"$jobs"
}

cancel_job() {
    id=$1
    temp=$FAKE_SCHED_DIR/jobs.new
    awk -F'|' -v id="$id" '$1 != id' "$jobs" >"$temp"
    mv "$temp" "$jobs"
}

case "$command_name" in
    sbatch)
        name=
        for argument in "$@"; do
            case "$argument" in --job-name=*) name=${argument#--job-name=} ;; esac
        done
        [ -n "$name" ] || exit 2
        id=$(next_id)
        add_job "$id" "$name"
        if [ "${FAKE_HOSTILE:-0}" = 1 ]; then
            printf '%s\n' 'untrusted scheduler chatter'
        else
            printf '%s\n' "$id"
        fi
        ;;
    ybatch)
        script=$1
        name=$(sed -n 's/^#SBATCH --job-name=//p' "$script")
        [ -n "$name" ] || exit 2
        ybatch_line=$(grep -n '^#YBATCH ' "$script" | cut -d: -f1)
        executable_line=$(grep -n '^set -eu$' "$script" | cut -d: -f1)
        [ "$ybatch_line" -lt "$executable_line" ] || exit 2
        grep '^chmod 600 "$diagnostic"$' "$script" >/dev/null || exit 2
        grep '>>"$diagnostic" 2>&1$' "$script" >/dev/null || exit 2
        id=$(next_id)
        add_job "$id" "$name"
        printf 'Submitted batch job %s\n' "$id"
        ;;
    qsub)
        name=
        previous=
        for argument in "$@"; do
            if [ "$previous" = -N ]; then name=$argument; fi
            previous=$argument
        done
        [ -n "$name" ] || exit 2
        id=$(next_id)
        if [ "$FAKE_FAMILY" = pbs ]; then full_id=$id.server; else full_id=$id; fi
        add_job "$full_id" "$name"
        if [ "$FAKE_FAMILY" = pbs ]; then
            printf '%s\n' "$full_id"
        else
            printf 'Your job %s ("%s") has been submitted\n' "$id" "$name"
        fi
        ;;
    squeue)
        wanted_name=
        wanted_id=
        previous=
        for argument in "$@"; do
            [ "$previous" = -n ] && wanted_name=$argument
            [ "$previous" = -j ] && wanted_id=$argument
            previous=$argument
        done
        awk -F'|' -v name="$wanted_name" -v id="$wanted_id" -v user="$username" '
            (name != "" && $2 == name) { print $1 "|" $2 }
            (id != "" && $1 == id) { print $1 "|" $2 "|" $3 "|" user }
        ' "$jobs"
        ;;
    qstat)
        if [ "${1:-}" = -u ]; then
            if [ "$FAKE_FAMILY" = pbs ]; then
                awk -F'|' -v user="$username" '{ print $1, $2, user, "0", $3, "queue" }' "$jobs"
            else
                awk -F'|' -v user="$username" '{ print $1, "0", $2, user, "qw", "date", "time", "1" }' "$jobs"
            fi
        elif [ "${1:-}" = -f ]; then
            id=$2
            awk -F'|' -v id="$id" -v user="$username" '
                $1 == id {
                    print "Job Id: " $1
                    print "    Job_Name = " $2
                    print "    Job_Owner = " user "@fake"
                    print "    job_state = Q"
                    found=1
                }
                END { if (!found) exit 1 }
            ' "$jobs"
        elif [ "${1:-}" = -j ]; then
            id=$2
            awk -F'|' -v id="$id" -v user="$username" '
                $1 == id {
                    print "job_number: " $1
                    print "job_name: " $2
                    print "owner: " user
                    found=1
                }
                END { if (!found) exit 1 }
            ' "$jobs"
        else
            exit 2
        fi
        ;;
    scancel|qdel) cancel_job "$1" ;;
    *) exit 2 ;;
esac
EOF
chmod 755 "$fake_bin/fake-scheduler"
for command_name in sbatch ybatch qsub squeue qstat scancel qdel; do
    ln -s fake-scheduler "$fake_bin/$command_name"
done

run_schedule() {
    host=$1
    family=$2
    home=$3
    shift 3
    env HOME="$home" PATH="$fake_bin:/usr/bin:/bin" \
        HARNESS_TESTING=1 HARNESS_LOGICAL_HOST="$host" \
        HARNESS_TESTING_ALLOW_UNSMOKED_SEED=1 \
        HARNESS_NOW_EPOCH=1784149200 FAKE_SCHED_DIR="$fake_sched" \
        FAKE_FAMILY="$family" "$HARNESS" restic-schedule "$@" --host "$host"
}

for declaration in 'local ybatch' 'ri slurm' 'ab pbs' 't4 age'; do
    set -- $declaration
    host=$1
    family=$2
    home=$TEST_ROOT/home-$host
    mkdir -p "$home"
    : >"$fake_sched/jobs"
    run_schedule "$host" "$family" "$home" seed >"$TEST_ROOT/$host.seed" 2>&1 ||
        fail "$host seed"
    grep "RESTIC_SCHEDULE_SEED host=$host" "$TEST_ROOT/$host.seed" >/dev/null ||
        fail "$host seed output"
    if [ "$host" = ri ]; then
        grep -- '--account=rkp00015' "$TEST_ROOT/$host.seed" >/dev/null ||
            fail "RI native account request"
    fi
    [ "$(wc -l <"$fake_sched/jobs" | tr -d ' ')" -eq 1 ] || fail "$host singleton"
    run_schedule "$host" "$family" "$home" status >"$TEST_ROOT/$host.status" ||
        fail "$host status"
    grep 'present=1' "$TEST_ROOT/$host.status" >/dev/null || fail "$host present"
    run_schedule "$host" "$family" "$home" warning >"$TEST_ROOT/$host.warning" 2>&1 ||
        fail "$host healthy warning"
    [ ! -s "$TEST_ROOT/$host.warning" ] || fail "$host healthy warning was noisy"
    run_schedule "$host" "$family" "$home" seed >"$TEST_ROOT/$host.reseed" 2>&1 ||
        fail "$host idempotent seed"
    [ "$(wc -l <"$fake_sched/jobs" | tr -d ' ')" -eq 1 ] || fail "$host reseed duplicate"
    run_schedule "$host" "$family" "$home" disable >"$TEST_ROOT/$host.disable" 2>&1 ||
        fail "$host exact disable"
    [ ! -s "$fake_sched/jobs" ] || fail "$host disable left job"
done

local_home=$TEST_ROOT/time-home
mkdir -p "$local_home"
next_output=$(env HOME="$local_home" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=local HARNESS_NOW_EPOCH=1784149200 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=ybatch \
    "$HARNESS" restic-schedule next --host local)
printf '%s\n' "$next_output" | grep 'local=2026-07-19T00:30:00+0900' >/dev/null ||
    fail "JST next Sunday"

al_home=$TEST_ROOT/al-time-home
mkdir -p "$al_home"
before_dst=$(date -d '2026-10-23T00:00:00Z' +%s)
next_output=$(env HOME="$al_home" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=al HARNESS_NOW_EPOCH="$before_dst" \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule next --host al)
printf '%s\n' "$next_output" | grep 'local=2026-10-25T01:00:00+0200' >/dev/null ||
    fail "Europe/Zurich DST eligibility"
exact_epoch=$(TZ=Europe/Zurich date -d '2026-10-25 01:00:00' +%s)
next_output=$(env HOME="$al_home" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=al HARNESS_NOW_EPOCH="$exact_epoch" \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule next --host al)
printf '%s\n' "$next_output" | grep 'local=2026-11-01T01:00:00+0100' >/dev/null ||
    fail "strictly future Europe/Zurich eligibility"

hostile_home=$TEST_ROOT/hostile-home
mkdir -p "$hostile_home"
: >"$fake_sched/jobs"
expect_failure 'seed requires a passed smoke' "$TEST_ROOT/unsmoked.out" \
    env HOME="$hostile_home" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149200 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule seed --host ri
expect_failure 'ambiguous scheduler submission result' "$TEST_ROOT/hostile.out" \
    env HOME="$hostile_home" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_TESTING=1 HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149200 \
    HARNESS_TESTING_ALLOW_UNSMOKED_SEED=1 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm FAKE_HOSTILE=1 \
    FAKE_NO_RECORD=1 "$HARNESS" restic-schedule seed --host ri
[ ! -e "$hostile_home/.local/state/harness/restic-chain/chain.state" ] ||
    fail "hostile output created chain state"

retry_home=$TEST_ROOT/retry-home
mkdir -p "$retry_home"
: >"$fake_sched/jobs"
env HOME="$retry_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149200 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule smoke --host ri >"$TEST_ROOT/retry.first" 2>&1 ||
    fail "missing-parent first smoke"
retry_state=$retry_home/.local/state/harness/restic-chain/smoke.state
retry_id=$(sed -n 's/^job_id=//p' "$retry_state")
FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm "$fake_bin/scancel" "$retry_id"
env HOME="$retry_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149260 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule smoke --host ri >"$TEST_ROOT/retry.second" 2>&1 ||
    fail "missing-parent reconciled smoke"
[ "$(wc -l <"$fake_sched/jobs" | tr -d ' ')" -eq 1 ] ||
    fail "missing-parent retry was not singleton"
grep 'event=smoke-parent-missing' \
    "$retry_home/.local/state/harness/restic-chain/events" >/dev/null ||
    fail "missing-parent event"

warning_home=$TEST_ROOT/warning-home
mkdir -p "$warning_home"
: >"$fake_sched/jobs"
run_schedule ri slurm "$warning_home" seed >/dev/null 2>&1 || fail "warning seed"
: >"$fake_sched/jobs"
run_schedule ri slurm "$warning_home" warning >"$TEST_ROOT/missing.warning" 2>&1 ||
    fail "missing warning command"
grep 'captured future job is missing' "$TEST_ROOT/missing.warning" >/dev/null ||
    fail "missing job warning"

primary_home=$TEST_ROOT/primary-home
primary_persistent=$TEST_ROOT/primary-persistent
primary_cache=$TEST_ROOT/primary-cache
primary_repo=$primary_persistent/restic/home-control
mkdir -p "$primary_home/.config/restic" "$primary_home/.alpha" \
    "$primary_persistent/home/.local" "$primary_cache" "$primary_repo"
printf '%s\n' 'test-only-password-never-read-by-test' >"$primary_home/.config/restic/home-control.password"
chmod 600 "$primary_home/.config/restic/home-control.password"
ln -s "$primary_persistent/home/.local" "$primary_home/.local"
repository_map=$TEST_ROOT/restic-repositories.tsv
layout_map=$TEST_ROOT/home-layout.tsv
printf 'local|%s|%s/replica|~/.config/restic/home-control.password|local\n' \
    "$primary_repo" "$TEST_ROOT" >"$repository_map"
printf 'local|%s|%s|.local|none|none|none\n' \
    "$primary_persistent" "$primary_cache" >"$layout_map"
cat >"$fake_bin/restic" <<'EOF'
#!/bin/sh
set -eu
manifest=
previous=
mode=snapshots
for argument in "$@"; do
    [ "$previous" = --files-from-raw ] && manifest=$argument
    [ "$argument" = backup ] && mode=backup
    previous=$argument
done
if [ "$mode" = backup ]; then
    [ -f "$manifest" ] || exit 2
    tr '\000' '\n' <"$manifest" | grep -F "$EXPECT_HOME/.alpha" >/dev/null
    if [ -n "${EXPECT_TARGET:-}" ]; then
        tr '\000' '\n' <"$manifest" | grep -F "$EXPECT_TARGET" >/dev/null
    fi
    if [ -n "${EXPECT_JOB_COUNT:-}" ]; then
        [ "$(wc -l <"$FAKE_SCHED_DIR/jobs" | tr -d ' ')" -eq "$EXPECT_JOB_COUNT" ]
    fi
    printf '{"message_type":"summary","snapshot_id":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}\n'
else
    printf '%s\n' '[]'
fi
EOF
chmod 755 "$fake_bin/restic"
env HOME="$primary_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=local HARNESS_REPOSITORY_MAP="$repository_map" \
    HARNESS_HOME_LAYOUT_MAP="$layout_map" EXPECT_HOME="$primary_home" \
    EXPECT_TARGET="$primary_persistent/home/.local" \
    "$HARNESS" restic-primary check --host local >"$TEST_ROOT/primary.check" ||
    fail "primary check"
grep 'status=passed' "$TEST_ROOT/primary.check" >/dev/null || fail "primary check output"
env HOME="$primary_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=local HARNESS_REPOSITORY_MAP="$repository_map" \
    HARNESS_HOME_LAYOUT_MAP="$layout_map" EXPECT_HOME="$primary_home" \
    EXPECT_TARGET="$primary_persistent/home/.local" \
    "$HARNESS" restic-primary weekly --host local >"$TEST_ROOT/primary.weekly" ||
    fail "primary weekly"
grep 'snapshot=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa status=passed' \
    "$TEST_ROOT/primary.weekly" >/dev/null || fail "primary snapshot ID"

run_home=$TEST_ROOT/run-home
run_persistent=$TEST_ROOT/run-persistent
run_cache=$TEST_ROOT/run-cache
run_repo=$run_persistent/restic/home-control
mkdir -p "$run_home/.config/restic" "$run_home/.alpha" "$run_persistent" \
    "$run_cache" "$run_repo"
printf '%s\n' 'test-only-run-password' >"$run_home/.config/restic/home-control.password"
chmod 600 "$run_home/.config/restic/home-control.password"
run_repository_map=$TEST_ROOT/run-restic-repositories.tsv
run_layout_map=$TEST_ROOT/run-home-layout.tsv
printf 'ri|%s|%s/replica|~/.config/restic/home-control.password|local\n' \
    "$run_repo" "$TEST_ROOT" >"$run_repository_map"
printf 'ri|%s|%s|none|none|none|none\n' \
    "$run_persistent" "$run_cache" >"$run_layout_map"
: >"$fake_sched/jobs"
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149200 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule smoke --host ri >"$TEST_ROOT/run.smoke" 2>&1 ||
    fail "allocated smoke submit"
smoke_state=$run_home/.local/state/harness/restic-chain/smoke.state
smoke_id=$(sed -n 's/^job_id=//p' "$smoke_state")
smoke_epoch=$(sed -n 's/^eligibility_epoch=//p' "$smoke_state")
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=$((smoke_epoch + 60)) \
    HARNESS_REPOSITORY_MAP="$run_repository_map" \
    HARNESS_HOME_LAYOUT_MAP="$run_layout_map" FAKE_SCHED_DIR="$fake_sched" \
    FAKE_FAMILY=slurm SLURM_JOB_ID="$smoke_id" EXPECT_HOME="$run_home" \
    EXPECT_TARGET= "$HARNESS" restic-schedule run --host ri --kind smoke \
    >"$TEST_ROOT/run.smoke-allocated" 2>&1 || fail "allocated smoke run"
[ "$(sed -n 's/^status=//p' "$smoke_state")" = successor-pending ] ||
    fail "smoke successor state"
FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm "$fake_bin/scancel" "$smoke_id"
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule status --host ri >"$TEST_ROOT/run.smoke-status" ||
    fail "smoke successor status"
grep 'RESTIC_SCHEDULE_SMOKE.*status=successor-pending.*present=1' \
    "$TEST_ROOT/run.smoke-status" >/dev/null || fail "smoke status follows successor"
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule disable --smoke --host ri \
    >"$TEST_ROOT/run.smoke-disable" 2>&1 || fail "smoke successor disable"
[ "$(sed -n 's/^status=//p' "$smoke_state")" = verified-disabled ] ||
    fail "smoke proof state"
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH=1784149200 \
    FAKE_SCHED_DIR="$fake_sched" FAKE_FAMILY=slurm \
    "$HARNESS" restic-schedule seed --host ri >"$TEST_ROOT/run.seed" 2>&1 ||
    fail "smoke-gated allocated-run seed"
run_state=$run_home/.local/state/harness/restic-chain/chain.state
current_id=$(sed -n 's/^job_id=//p' "$run_state")
current_epoch=$(sed -n 's/^eligibility_epoch=//p' "$run_state")
run_epoch=$((current_epoch + 60))
env HOME="$run_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=ri HARNESS_NOW_EPOCH="$run_epoch" \
    HARNESS_REPOSITORY_MAP="$run_repository_map" \
    HARNESS_HOME_LAYOUT_MAP="$run_layout_map" FAKE_SCHED_DIR="$fake_sched" \
    FAKE_FAMILY=slurm SLURM_JOB_ID="$current_id" EXPECT_HOME="$run_home" \
    EXPECT_TARGET= EXPECT_JOB_COUNT=2 \
    "$HARNESS" restic-schedule run --host ri --kind weekly \
    >"$TEST_ROOT/run.out" 2>&1 || fail "allocated weekly run"
[ "$(sed -n 's/^last_result=//p' "$run_state")" = success ] ||
    fail "allocated run result"
[ "$(sed -n 's/^job_id=//p' "$run_state")" != "$current_id" ] ||
    fail "allocated run did not adopt successor"
successor_line=$(grep -n 'event=successor-recorded' \
    "$run_home/.local/state/harness/restic-chain/events" | tail -n 1 | cut -d: -f1)
snapshot_line=$(grep -n 'event=snapshot-passed' \
    "$run_home/.local/state/harness/restic-chain/events" | tail -n 1 | cut -d: -f1)
[ "$successor_line" -lt "$snapshot_line" ] || fail "successor-first event order"

outside=$TEST_ROOT/outside
mkdir -p "$outside"
unlink "$primary_home/.local"
ln -s "$outside" "$primary_home/.local"
expect_failure 'relocated target is outside declared roots' "$TEST_ROOT/outside.out" \
    env HOME="$primary_home" PATH="$fake_bin:/usr/bin:/bin" HARNESS_TESTING=1 \
    HARNESS_LOGICAL_HOST=local HARNESS_REPOSITORY_MAP="$repository_map" \
    HARNESS_HOME_LAYOUT_MAP="$layout_map" "$HARNESS" restic-primary check --host local

printf '%s\n' 'restic schedule tests: PASS'
