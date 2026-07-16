#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SYNC=$ROOT/libexec/harness-fleet-sync
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/fleet-sync-test.XXXXXX")

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEST_ROOT" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

source_repo=$TEST_ROOT/source
remote_root=$TEST_ROOT/remotes
fake_bin=$TEST_ROOT/bin
mkdir -p "$source_repo" "$remote_root" "$fake_bin"
git -C "$source_repo" init -q
git -C "$source_repo" config user.name harness-test
git -C "$source_repo" config user.email harness-test.invalid
printf '%s\n' one >"$source_repo/payload"
git -C "$source_repo" add payload
git -C "$source_repo" commit -q -m one
old=$(git -C "$source_repo" rev-parse HEAD)
printf '%s\n' two >"$source_repo/payload"
git -C "$source_repo" commit -q -am two
new=$(git -C "$source_repo" rev-parse HEAD)

make_remote() {
    host=$1
    mkdir -p "$remote_root/$host"
    git clone -q --no-hardlinks "$source_repo" "$remote_root/$host/harness"
    git -C "$remote_root/$host/harness" checkout -q --detach "$old"
    mkdir -p "$remote_root/$host/.local/state/harness"
    chmod 700 "$remote_root/$host/.local/state/harness"
}
for host in n1 n2 n3 n4 n5; do make_remote "$host"; done

cat >"$fake_bin/ssh" <<'EOF'
#!/bin/sh
set -eu
while [ "$#" -gt 0 ]; do
    case "$1" in
        -o) shift 2 ;;
        -*) shift ;;
        *) host=$1; shift; break ;;
    esac
done
case ${host:-} in n1|n2|n3|n4|n5) ;; *) exit 2 ;; esac
HOME=$FAKE_FLEET_ROOT/$host
export HOME
[ "$#" -eq 1 ] || exit 2
exec /bin/sh -c "$1"
EOF
cat >"$fake_bin/cat" <<'EOF'
#!/bin/sh
set -eu
if [ "${FAKE_CAT_INTERRUPT:-0}" = 1 ]; then
    /bin/cat
    kill -TERM "$PPID"
    exit 143
fi
exec /bin/cat "$@"
EOF
chmod 755 "$fake_bin/ssh" "$fake_bin/cat"

run_sync() {
    env HARNESS_ROOT="$source_repo" FAKE_FLEET_ROOT="$remote_root" \
        PATH="$fake_bin:/usr/bin:/bin" "$SYNC" "$@"
}

run_sync --from "$old" --to "$new" --hosts n1,n2 --plan \
    >"$TEST_ROOT/plan.out"
[ "$(grep -c '^UPDATE host=' "$TEST_ROOT/plan.out")" -eq 2 ] ||
    fail "initial update plan"
grep -F 'transport=ssh-stream' "$TEST_ROOT/plan.out" >/dev/null ||
    fail "transparent transport plan"

run_sync --from "$old" --to "$new" --hosts n1,n2 --apply \
    >"$TEST_ROOT/apply.out"
for host in n1 n2; do
    [ "$(git -C "$remote_root/$host/harness" rev-parse HEAD)" = "$new" ] ||
        fail "remote did not fast-forward: $host"
    [ -z "$(git -C "$remote_root/$host/harness" status --porcelain=v1)" ] ||
        fail "remote became dirty: $host"
    artifact=$remote_root/$host/.local/state/harness/harness-transfer-$(printf '%s' "$old" | cut -c1-12)-$(printf '%s' "$new" | cut -c1-12).bundle
    [ ! -e "$artifact" ] && [ ! -L "$artifact" ] ||
        fail "remote transfer artifact remained: $host"
done
run_sync --from "$old" --to "$new" --hosts n1,n2 --plan \
    >"$TEST_ROOT/repeat.out"
[ "$(grep -c '^KEEP host=' "$TEST_ROOT/repeat.out")" -eq 2 ] ||
    fail "idempotent keep plan"

printf '%s\n' dirty >"$remote_root/n1/harness/dirty"
if run_sync --from "$old" --to "$new" --hosts n1 --plan \
    >"$TEST_ROOT/dirty.out" 2>&1; then
    fail "dirty remote was accepted"
fi
grep -F 'remote worktree is dirty: n1' "$TEST_ROOT/dirty.out" >/dev/null ||
    fail "dirty refusal evidence"
unlink "$remote_root/n1/harness/dirty"

git -C "$remote_root/n3/harness" config user.name harness-test
git -C "$remote_root/n3/harness" config user.email harness-test.invalid
printf '%s\n' divergent >"$remote_root/n3/harness/divergent"
git -C "$remote_root/n3/harness" add divergent
git -C "$remote_root/n3/harness" commit -q -m divergent
if run_sync --from "$old" --to "$new" --hosts n3 --plan \
    >"$TEST_ROOT/divergent.out" 2>&1; then
    fail "divergent remote was accepted"
fi
grep -F 'remote head is neither source nor target: n3' \
    "$TEST_ROOT/divergent.out" >/dev/null || fail "divergence refusal evidence"

artifact=$remote_root/n4/.local/state/harness/harness-transfer-$(printf '%s' "$old" | cut -c1-12)-$(printf '%s' "$new" | cut -c1-12).bundle
: >"$artifact"
chmod 600 "$artifact"
if run_sync --from "$old" --to "$new" --hosts n4 --plan \
    >"$TEST_ROOT/collision.out" 2>&1; then
    fail "remote artifact collision was accepted"
fi
grep -F 'remote transfer artifact already exists: n4' \
    "$TEST_ROOT/collision.out" >/dev/null || fail "collision refusal evidence"
unlink "$artifact"

if FAKE_CAT_INTERRUPT=1 run_sync --from "$old" --to "$new" --hosts n5 --apply \
    >"$TEST_ROOT/interrupted.out" 2>&1; then
    fail "interrupted transfer succeeded"
fi
[ "$(git -C "$remote_root/n5/harness" rev-parse HEAD)" = "$old" ] ||
    fail "interrupted transfer changed remote HEAD"
artifact=$remote_root/n5/.local/state/harness/harness-transfer-$(printf '%s' "$old" | cut -c1-12)-$(printf '%s' "$new" | cut -c1-12).bundle
[ ! -e "$artifact" ] && [ ! -L "$artifact" ] ||
    fail "interrupted transfer left remote artifact"
if find "$source_repo/.local/state/harness" -mindepth 1 -maxdepth 1 \
    -name '.fleet-sync-*' -print -quit 2>/dev/null | grep . >/dev/null; then
    fail "interrupted transfer left local state"
fi

printf '%s\n' 'fleet sync tests: PASS'
