#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-arg0-wrapper-test.XXXXXX")
locker=

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -n "$locker" ]; then
        kill "$locker" 2>/dev/null || true
        wait "$locker" 2>/dev/null || true
    fi
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" \
            >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

make_expected() {
    directory=$1
    mkdir "$directory"
    : >"$directory/.lock"
    for helper in apply_patch applypatch codex-execve-wrapper codex-linux-sandbox; do
        ln -s /bin/true "$directory/$helper"
    done
}

codex_home=$TEMP_DIR/codex-home
arg_root=$codex_home/tmp/arg0
mkdir -p "$arg_root"
chmod 700 "$codex_home/tmp" "$arg_root"
live=$arg_root/codex-arg0LIVE01
stale=$arg_root/codex-arg0OLD001
empty=$arg_root/codex-arg0EMPTY1
young=$arg_root/codex-arg0YOUNG1
unexpected=$arg_root/codex-arg0BAD001
make_expected "$live"
make_expected "$stale"
mkdir "$empty" "$young" "$unexpected"
printf '%s\n' unexpected >"$unexpected/foreign"
touch -d '10 minutes ago' "$stale" "$empty" "$unexpected"

ready=$TEMP_DIR/live-lock-ready
# shellcheck disable=SC2016
flock "$live/.lock" sh -c 'printf ready >"$1"; sleep 30' sh "$ready" &
locker=$!
attempt=0
while [ ! -f "$ready" ] && [ "$attempt" -lt 50 ]; do
    sleep 0.1
    attempt=$((attempt + 1))
done
[ -f "$ready" ] || fail "live lock did not start"

HARNESS_TESTING=1 CODEX_HOME="$codex_home" \
    "$HARNESS" codex-arg0-housekeeping --plan --root "$arg_root" \
    --grace-seconds 120 >"$TEMP_DIR/plan.out"
grep -F 'live=1 eligible=2 young=1 unexpected=1 removed=0' \
    "$TEMP_DIR/plan.out" >/dev/null || fail "housekeeping classification"

HARNESS_TESTING=1 CODEX_HOME="$codex_home" \
    "$HARNESS" codex-arg0-housekeeping --apply --root "$arg_root" \
    --grace-seconds 120 >"$TEMP_DIR/apply.out"
grep -F 'live=1 eligible=2 young=1 unexpected=1 removed=2' \
    "$TEMP_DIR/apply.out" >/dev/null || fail "housekeeping apply counts"
[ -d "$live" ] && [ -d "$young" ] && [ -d "$unexpected" ] ||
    fail "housekeeping removed protected state"
[ ! -e "$stale" ] && [ ! -e "$empty" ] || fail "housekeeping left eligible state"

baseline=$TEMP_DIR/baseline
find "$arg_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' >"$baseline"
chmod 600 "$baseline"
observed=$arg_root/codex-arg0NEW001
make_expected "$observed"
HARNESS_TESTING=1 CODEX_HOME="$codex_home" \
    "$HARNESS" codex-arg0-housekeeping --apply --root "$arg_root" \
    --grace-seconds 3600 --baseline "$baseline" >"$TEMP_DIR/observed.out"
grep -F 'live=1 eligible=1 young=1 unexpected=1 removed=1' \
    "$TEMP_DIR/observed.out" >/dev/null || fail "observed-exit classification"
[ ! -e "$observed" ] || fail "observed completed residue remains"

kill "$locker"
wait "$locker" 2>/dev/null || true
locker=

darwin_bin=$TEMP_DIR/darwin-bin
darwin_root=$TEMP_DIR/darwin-codex/tmp/arg0
mkdir -p "$darwin_bin" "$darwin_root"
cat >"$darwin_bin/uname" <<'EOF'
#!/bin/sh
[ "${1:-}" = -s ] && { printf 'Darwin\n'; exit 0; }
exec /usr/bin/uname "$@"
EOF
cat >"$darwin_bin/stat" <<'EOF'
#!/bin/sh
if [ "${1:-}" != -f ]; then exec /usr/bin/stat "$@"; fi
case "$2" in
    %u) format=%u ;;
    %Lp) format=%a ;;
    %l) format=%h ;;
    %d:%i) format=%d:%i ;;
    %m) format=%Y ;;
    *) exit 2 ;;
esac
shift 2
exec /usr/bin/stat -c "$format" -- "$@"
EOF
chmod 755 "$darwin_bin/uname" "$darwin_bin/stat"
make_darwin_expected() {
    directory=$1
    mkdir "$directory"
    : >"$directory/.lock"
    for helper in apply_patch applypatch codex-execve-wrapper; do
        ln -s /bin/true "$directory/$helper"
    done
}
darwin_live=$darwin_root/codex-arg0LIVE02
darwin_stale=$darwin_root/codex-arg0OLD002
make_darwin_expected "$darwin_live"
make_darwin_expected "$darwin_stale"
touch -d '10 minutes ago' "$darwin_stale"
darwin_ready=$TEMP_DIR/darwin-lock-ready
# A lock held by Linux flock must also be visible to Darwin's Perl flock path.
# shellcheck disable=SC2016
flock "$darwin_live/.lock" sh -c 'printf ready >"$1"; sleep 30' sh \
    "$darwin_ready" &
locker=$!
attempt=0
while [ ! -f "$darwin_ready" ] && [ "$attempt" -lt 50 ]; do
    sleep 0.1
    attempt=$((attempt + 1))
done
[ -f "$darwin_ready" ] || fail "Darwin synthetic lock did not start"
HARNESS_TESTING=1 CODEX_HOME="$TEMP_DIR/darwin-codex" \
    PATH="$darwin_bin:/usr/bin:/bin" \
    "$HARNESS" codex-arg0-housekeeping --plan --root "$darwin_root" \
    --grace-seconds 120 >"$TEMP_DIR/darwin-plan.out"
grep -F 'live=1 eligible=1 young=0 unexpected=0 removed=0' \
    "$TEMP_DIR/darwin-plan.out" >/dev/null || fail "Darwin housekeeping classification"
kill "$locker"
wait "$locker" 2>/dev/null || true
locker=

fake_home=$TEMP_DIR/fake-home
release=$fake_home/.codex/packages/standalone/releases/0.145.0-test/bin
mkdir -p "$release" "$fake_home/.local/bin" "$fake_home/.codex/packages/standalone"
cat >"$release/codex" <<'EOF'
#!/bin/sh
set -eu
root=${CODEX_HOME:-$HOME/.codex}/tmp/arg0
mkdir -p "$root"
chmod 700 "${root%/*}" "$root"
directory=$(mktemp -d "$root/codex-arg0XXXXXX")
: >"$directory/.lock"
for helper in apply_patch applypatch codex-execve-wrapper codex-linux-sandbox; do
    ln -s "$0" "$directory/$helper"
done
printf 'fake-codex %s\n' "${1:-none}"
exit "${FAKE_CODEX_STATUS:-0}"
EOF
chmod 755 "$release/codex"
original_hash=$(sha256sum "$release/codex" | awk '{print $1}')
ln -s "${release%/bin}" "$fake_home/.codex/packages/standalone/current"
ln -s "$fake_home/.codex/packages/standalone/current/bin/codex" \
    "$fake_home/.local/bin/codex"
ln -s "$HARNESS" "$fake_home/.local/bin/harness"

HARNESS_TESTING=1 HOME="$fake_home" "$ROOT/libexec/harness-codex-arg0-wrapper" \
    --plan >"$TEMP_DIR/wrapper-plan.out"
grep -F 'state=unwrapped action=install' "$TEMP_DIR/wrapper-plan.out" >/dev/null ||
    fail "wrapper install plan"
HARNESS_TESTING=1 HOME="$fake_home" "$ROOT/libexec/harness-codex-arg0-wrapper" \
    --apply >"$TEMP_DIR/wrapper-apply.out"
grep -F 'action=installed' "$TEMP_DIR/wrapper-apply.out" >/dev/null ||
    fail "wrapper apply"
HARNESS_TESTING=1 HOME="$fake_home" "$ROOT/libexec/harness-codex-arg0-wrapper" \
    --doctor >"$TEMP_DIR/wrapper-doctor.out"
grep -F 'status=ready' "$TEMP_DIR/wrapper-doctor.out" >/dev/null || fail "wrapper doctor"
[ -x "$release/codex.real" ] || fail "official binary not preserved"

mkdir -p "$fake_home/.codex/tmp/arg0"
chmod 700 "$fake_home/.codex/tmp" "$fake_home/.codex/tmp/arg0"
HOME="$fake_home" CODEX_HOME="$fake_home/.codex" "$fake_home/.local/bin/codex" \
    --version >"$TEMP_DIR/fake-version.out"
grep -F 'fake-codex --version' "$TEMP_DIR/fake-version.out" >/dev/null ||
    fail "wrapped Codex output"
[ "$(find "$fake_home/.codex/tmp/arg0" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -eq 0 ] ||
    fail "wrapper left completed arg0 residue"

if HOME="$fake_home" CODEX_HOME="$fake_home/.codex" FAKE_CODEX_STATUS=7 \
    "$fake_home/.local/bin/codex" failure >"$TEMP_DIR/fake-failure.out"; then
    fail "wrapper lost official binary failure status"
else
    wrapped_status=$?
fi
[ "$wrapped_status" -eq 7 ] || fail "wrapper changed official binary exit status"
[ "$(find "$fake_home/.codex/tmp/arg0" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -eq 0 ] ||
    fail "wrapper failure path left arg0 residue"

HARNESS_TESTING=1 HOME="$fake_home" "$ROOT/libexec/harness-codex-arg0-wrapper" \
    --rollback >"$TEMP_DIR/wrapper-rollback.out"
grep -F 'action=restored' "$TEMP_DIR/wrapper-rollback.out" >/dev/null ||
    fail "wrapper rollback"
[ "$(sha256sum "$release/codex" | awk '{print $1}')" = "$original_hash" ] ||
    fail "rollback changed official binary"
[ ! -e "$release/codex.real" ] &&
    [ ! -e "$release/.harness-arg0-wrapper.state" ] || fail "rollback left wrapper state"

for failure_point in official-move wrapper-move state-move; do
    if HARNESS_TESTING=1 HARNESS_ARG0_FAIL_AFTER="$failure_point" HOME="$fake_home" \
        "$ROOT/libexec/harness-codex-arg0-wrapper" --apply \
        >"$TEMP_DIR/failure-$failure_point.out" 2>&1; then
        fail "injected wrapper transaction failure succeeded: $failure_point"
    fi
    [ "$(sha256sum "$release/codex" | awk '{print $1}')" = "$original_hash" ] ||
        fail "transaction failure changed official binary: $failure_point"
    [ ! -e "$release/codex.real" ] &&
        [ ! -e "$release/.harness-arg0-wrapper.state" ] ||
        fail "transaction failure left state: $failure_point"
done

echo 'Codex arg0 wrapper tests passed'
