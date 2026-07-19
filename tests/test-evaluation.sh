#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
EVALUATE=$ROOT/evaluation/evaluate.py
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- /tmp && pwd -P)
TEST_ROOT=$(mktemp -d "/tmp/evaluation-test.XXXXXX")

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        printf '%s\n' 'FAIL: guarded evaluation-test cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' \
    "$EVALUATE" || fail "evaluation Python syntax"

fake_bin=$TEST_ROOT/bin
mkdir -p "$fake_bin"
cat >"$fake_bin/codex" <<'EOF'
#!/bin/sh
if [ "$#" -eq 1 ] && [ "$1" = --version ]; then
    printf '%s\n' 'codex-cli 0.144.5'
    exit 0
fi
printf '%s\n' "$*" >>"$FORBIDDEN_MODEL_LOG"
exit 97
EOF
chmod 700 "$fake_bin/codex"

FORBIDDEN_MODEL_LOG=$TEST_ROOT/model.log \
    PATH="$fake_bin:$PATH" python3 "$EVALUATE" validate \
    >"$TEST_ROOT/validate.out" || fail "evaluation validation"
grep -Fx 'VALID experiment=t181-failure-capsule-v1 tasks=7' \
    "$TEST_ROOT/validate.out" >/dev/null || fail "validation marker"

FORBIDDEN_MODEL_LOG=$TEST_ROOT/model.log \
    PATH="$fake_bin:$PATH" python3 "$EVALUATE" plan --stage pilot \
    >"$TEST_ROOT/pilot.plan" || fail "pilot plan"
[ "$(grep -c '^PAIR ' "$TEST_ROOT/pilot.plan")" -eq 9 ] ||
    fail "pilot pair count"
grep -Fx 'TOTAL pairs=9 primary_runs=18 retry_ceiling=18' \
    "$TEST_ROOT/pilot.plan" >/dev/null || fail "pilot run ceiling"

FORBIDDEN_MODEL_LOG=$TEST_ROOT/model.log \
    PATH="$fake_bin:$PATH" python3 "$EVALUATE" plan --stage full \
    >"$TEST_ROOT/full.plan" || fail "full plan"
[ "$(grep -c '^PAIR ' "$TEST_ROOT/full.plan")" -eq 35 ] ||
    fail "full pair count"
grep -Fx 'TOTAL pairs=35 primary_runs=70 retry_ceiling=70' \
    "$TEST_ROOT/full.plan" >/dev/null || fail "full run ceiling"

selftest_root=$TEST_ROOT/harness-eval-selftest
FORBIDDEN_MODEL_LOG=$TEST_ROOT/model.log \
    PATH="$fake_bin:$PATH" python3 "$EVALUATE" selftest \
    --root "$selftest_root" >"$TEST_ROOT/selftest.out" ||
    fail "evaluation adversarial selftests"
grep -Fx 'evaluation selftests passed' "$TEST_ROOT/selftest.out" >/dev/null ||
    fail "selftest marker"
[ ! -e "$TEST_ROOT/model.log" ] || fail "model invoked during model-free tests"

python3 "$EVALUATE" cleanup --root "$selftest_root" \
    >"$TEST_ROOT/cleanup.out" || fail "evaluation guarded cleanup"
grep -F 'VERIFIED protected_anchors=unchanged targets=absent' \
    "$TEST_ROOT/cleanup.out" >/dev/null || fail "guarded cleanup marker"
[ ! -e "$selftest_root" ] && [ ! -L "$selftest_root" ] ||
    fail "evaluation selftest root remains"
[ ! -e "$TEST_ROOT/.harness-eval-selftest.guarded-delete.manifest" ] ||
    fail "evaluation cleanup manifest remains"

if rg -n 'shutil\.rmtree|os\.removedirs' \
    "$EVALUATE" >/dev/null; then
    fail "evaluation runner contains an unguarded bulk remover"
fi

printf '%s\n' 'evaluation tests passed'
