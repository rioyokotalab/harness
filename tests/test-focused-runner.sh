#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
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
fake=$TEMP_DIR/root
mkdir -p "$fake/tests"

for name in one two; do
    cat >"$fake/tests/$name.sh" <<'EOF'
#!/bin/sh
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
name=${0##*/}
: >"$root/$name.started"
other=one.sh
[ "$name" = one.sh ] && other=two.sh
attempt=0
while [ ! -f "$root/$other.started" ]; do
    attempt=$((attempt + 1))
    [ "$attempt" -lt 100 ] || exit 9
    sleep 0.02
done
printf 'parallel=%s\n' "$name"
EOF
    chmod 755 "$fake/tests/$name.sh"
done
printf '%s\n' 'tests/one.sh|one' 'tests/two.sh|two' >"$fake/pass.tsv"
python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/pass-logs" --jobs 2 \
    >"$TEMP_DIR/pass.out" 2>"$TEMP_DIR/pass.err" || fail 'parallel pass'
[ ! -s "$TEMP_DIR/pass.err" ] || fail 'parallel pass emitted stderr'
[ "$(grep -c '^PASS suite=' "$TEMP_DIR/pass.out")" -eq 2 ] ||
    fail 'parallel result count'

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

if python3 "$ROOT/tools/run-focused-tests.py" --root "$fake" \
    --manifest "$fake/pass.tsv" --log-dir "$fake/invalid-logs" --jobs 0 \
    >"$TEMP_DIR/invalid.out" 2>&1; then
    fail 'runner accepted zero jobs'
fi

printf '%s\n' 'focused runner tests: PASS'
