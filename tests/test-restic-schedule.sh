#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/restic-schedule-test.XXXXXX")

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

expect_status() {
    expected_status=$1
    expected=$2
    output=$3
    shift 3
    actual_status=0
    "$@" >"$output" 2>&1 || actual_status=$?
    [ "$actual_status" -eq "$expected_status" ] ||
        fail "unexpected status $actual_status (wanted $expected_status): $*"
    grep -F "$expected" "$output" >/dev/null ||
        fail "missing status evidence: $expected"
}

expect_count() {
    expected=$1
    label=$2
    file=$3
    actual=$(wc -l <"$file" | tr -d ' ')
    [ "$actual" -eq "$expected" ] ||
        fail "$label count $actual (wanted $expected)"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
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
[ "$rows" -eq 8 ] || fail "schedule row count"
grep '^abq|abciq|Asia/Tokyo|Sun|03:30|qgai50157|none|rt_QC=1|' \
    "$schedule_map" >/dev/null || fail "ABCI-Q schedule declaration"
grep '^ri|slurm|Asia/Tokyo|Sun|02:00|rkp00015|none|' "$schedule_map" >/dev/null ||
    fail "RI explicit project account"

fake_bin=$TEST_ROOT/fake-bin
fake_sched=$TEST_ROOT/fake-scheduler
warning_instrument_bin=$TEST_ROOT/warning-instrument-bin
mkdir -p "$fake_bin" "$fake_sched" "$warning_instrument_bin"
RESTIC_TEST_PYTHON=$(command -v python3) || fail "python3 unavailable"
RESTIC_TEST_AWK=$(command -v awk) || fail "awk unavailable"
export RESTIC_TEST_PYTHON RESTIC_TEST_AWK
cat >"$fake_bin/date" <<'EOF'
#!/bin/sh
exec "$RESTIC_TEST_PYTHON" "$0.py" "$@"
EOF
cat >"$fake_bin/date.py" <<'EOF'
import datetime
import os
import re
import sys
from zoneinfo import ZoneInfo

args = sys.argv[1:]
if len(args) != 3 or args[0] != "-d" or not args[2].startswith("+"):
    raise SystemExit(2)
spec, output = args[1], args[2][1:]
zone = ZoneInfo(os.environ.get("TZ", "UTC"))
if spec.startswith("@"):
    value = datetime.datetime.fromtimestamp(int(spec[1:]), zone)
else:
    if spec.endswith("Z") and "T" in spec:
        value = datetime.datetime.fromisoformat(spec[:-1] + "+00:00")
    else:
        match = re.fullmatch(
            r"(\d{4}-\d{2}-\d{2})(?: \+(\d+) days)?(?: (\d{2}:\d{2}:\d{2}))?",
            spec,
        )
        if not match:
            raise SystemExit(2)
        day = datetime.date.fromisoformat(match.group(1))
        day += datetime.timedelta(days=int(match.group(2) or 0))
        clock = datetime.time.fromisoformat(match.group(3) or "00:00:00")
        value = datetime.datetime.combine(day, clock, zone)
if output == "%s":
    print(int(value.timestamp()))
else:
    print(value.strftime(output))
EOF
cat >"$fake_bin/stat" <<'EOF'
#!/bin/sh
case "$1:$2" in -c:%u) format=%u ;; -c:%a) format=%a ;; *) exec /usr/bin/stat "$@" ;; esac
shift 2; [ "${1:-}" != -- ] || shift
case $(/usr/bin/uname -s) in
    Darwin)
        [ "$format" != %a ] || format=%Lp
        exec /usr/bin/stat -f "$format" "$@"
        ;;
    *) exec /usr/bin/stat -c "$format" -- "$@" ;;
esac
EOF
cat >"$warning_instrument_bin/awk" <<'EOF'
#!/bin/sh
if [ -n "${WARNING_STATE_PARSE_LOG:-}" ] &&
    [ -n "${WARNING_STATE_FILE:-}" ]; then
    for argument in "$@"; do
        if [ "$argument" = "$WARNING_STATE_FILE" ]; then
            printf '%s\n' parse >>"$WARNING_STATE_PARSE_LOG"
        fi
    done
fi
exec "$RESTIC_TEST_AWK" "$@"
EOF
chmod 755 "$fake_bin/date" "$fake_bin/date.py" "$fake_bin/stat" \
    "$warning_instrument_bin/awk"
real_jq=$(command -v jq) || fail "jq unavailable"
ln -s "$real_jq" "$fake_bin/jq"
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
        mail_points=
        previous=
        script=
        for argument in "$@"; do
            if [ "$previous" = -N ]; then name=$argument; fi
            if [ "$previous" = -m ]; then mail_points=$argument; fi
            previous=$argument
            script=$argument
        done
        [ -n "$name" ] || exit 2
        id=$(next_id)
        if [ "$FAKE_FAMILY" = pbs ]; then
            [ "$mail_points" = n ] || exit 2
            full_id=$id.server
        elif [ "$FAKE_FAMILY" = abciq ]; then
            [ -z "$mail_points" ] || exit 2
            grep -F -x 'TMPDIR=/tmp' "$script" >/dev/null || exit 2
            grep -F -x 'export TMPDIR' "$script" >/dev/null || exit 2
            full_id=$id.server
        else
            full_id=$id
        fi
        add_job "$full_id" "$name"
        if [ "$FAKE_FAMILY" = pbs ] || [ "$FAKE_FAMILY" = abciq ]; then
            printf '%s\n' "$full_id"
        else
            printf 'Your job %s ("%s") has been submitted\n' "$id" "$name"
        fi
        ;;
    squeue)
        if [ -n "${FAKE_QUERY_LOG:-}" ]; then
            printf '%s\n' squeue >>"$FAKE_QUERY_LOG"
        fi
        [ "${FAKE_QUERY_FAIL:-0}" != 1 ] || exit 2
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
            (name == "" && id == "") { print $1 "|" $2 "|" $3 "|" user }
        ' "$jobs"
        ;;
    qstat)
        if [ -n "${FAKE_QUERY_LOG:-}" ]; then
            printf '%s\n' qstat >>"$FAKE_QUERY_LOG"
        fi
        if [ "${1:-}" = -u ]; then
            if [ "$FAKE_FAMILY" = pbs ] || [ "$FAKE_FAMILY" = abciq ]; then
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
    schedule_path=$fake_bin:/usr/bin:/bin
    if [ -n "${WARNING_STATE_PARSE_LOG:-}" ]; then
        schedule_path=$warning_instrument_bin:$schedule_path
    fi
    env HOME="$home" PATH="$schedule_path" \
        HARNESS_TESTING=1 HARNESS_LOGICAL_HOST="$host" \
        HARNESS_TESTING_ALLOW_UNSMOKED_SEED=1 \
        HARNESS_NOW_EPOCH=1784149200 FAKE_SCHED_DIR="$fake_sched" \
        FAKE_FAMILY="$family" FAKE_QUERY_LOG="${FAKE_QUERY_LOG:-}" \
        FAKE_QUERY_FAIL="${FAKE_QUERY_FAIL:-0}" \
        WARNING_STATE_FILE="${WARNING_STATE_FILE:-}" \
        WARNING_STATE_PARSE_LOG="${WARNING_STATE_PARSE_LOG:-}" \
        "$HARNESS" restic-schedule "$@" --host "$host"
}

    host=ri
    family=slurm
    home=$TEST_ROOT/home-$host
    mkdir -p "$home"
    : >"$fake_sched/jobs"
    run_schedule "$host" "$family" "$home" seed >"$TEST_ROOT/$host.seed" 2>&1 ||
        { sed -n '1,80p' "$TEST_ROOT/$host.seed" >&2; fail "$host seed"; }
    grep "RESTIC_SCHEDULE_SEED host=$host" "$TEST_ROOT/$host.seed" >/dev/null ||
        fail "$host seed output"
    grep -- '--account=rkp00015' "$TEST_ROOT/$host.seed" >/dev/null ||
        fail "RI native account request"
    grep -- '--gres=none' "$TEST_ROOT/$host.seed" >/dev/null ||
        fail "Slurm explicit no-GRES request"
    [ "$(wc -l <"$fake_sched/jobs" | tr -d ' ')" -eq 1 ] || fail "$host singleton"
    run_schedule "$host" "$family" "$home" status >"$TEST_ROOT/$host.status" ||
        fail "$host status"
    grep 'present=1' "$TEST_ROOT/$host.status" >/dev/null || fail "$host present"
    WARNING_STATE_FILE=$home/.local/state/harness/restic-chain/chain.state
    WARNING_STATE_PARSE_LOG=$TEST_ROOT/$host.warning-state-parses
    FAKE_QUERY_LOG=$TEST_ROOT/$host.warning-scheduler-queries
    : >"$WARNING_STATE_PARSE_LOG"
    : >"$FAKE_QUERY_LOG"
    run_schedule "$host" "$family" "$home" warning >"$TEST_ROOT/$host.warning" 2>&1 ||
        { sed -n '1,80p' "$TEST_ROOT/$host.warning" >&2;
          fail "$host healthy warning"; }
    [ ! -s "$TEST_ROOT/$host.warning" ] || fail "$host healthy warning was noisy"
    expect_count 1 "$host warning state parse" "$WARNING_STATE_PARSE_LOG"
    expect_count 1 "$host warning scheduler query" "$FAKE_QUERY_LOG"
    unset WARNING_STATE_FILE WARNING_STATE_PARSE_LOG FAKE_QUERY_LOG
    run_schedule "$host" "$family" "$home" seed >"$TEST_ROOT/$host.reseed" 2>&1 ||
        fail "$host idempotent seed"
    [ "$(wc -l <"$fake_sched/jobs" | tr -d ' ')" -eq 1 ] || fail "$host reseed duplicate"
    run_schedule "$host" "$family" "$home" disable >"$TEST_ROOT/$host.disable" 2>&1 ||
        fail "$host exact disable"
    [ ! -s "$fake_sched/jobs" ] || fail "$host disable left job"
echo 'Restic scheduling essential contract: PASS'
exit 0
