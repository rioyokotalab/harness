#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CONTROL=$ROOT/libexec/harness-macos-control
FIXTURE=$ROOT/tests/fixtures/personal-macos/private-v1
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-macos-control-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$HARNESS" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded personal-Mac control cleanup" >&2
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

PUBLIC=$TEMP_DIR/public
mkdir -p "$PUBLIC/bin" "$PUBLIC/.codex/rules" "$PUBLIC/.claude" \
    "$PUBLIC/shared/skills/mac-test-skill" \
    "$PUBLIC/profiles/personal-macos"
cp "$ROOT/bin/harness" "$PUBLIC/bin/harness"
cp "$ROOT/.codex/AGENTS.md" "$PUBLIC/.codex/AGENTS.md"
cp "$ROOT/.codex/rules/default.rules" "$PUBLIC/.codex/rules/default.rules"
cp -L "$ROOT/.claude/CLAUDE.md" "$PUBLIC/.claude/CLAUDE.md"
cp "$ROOT/profiles/personal-macos/base.conf" \
    "$PUBLIC/profiles/personal-macos/base.conf"
printf '%s\n' 'synthetic control skill' > \
    "$PUBLIC/shared/skills/mac-test-skill/SKILL.md"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m 'synthetic public control plane'

FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$FAKE_BIN"
cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
[ "${1:-}" = -s ] && { echo Darwin; exit 0; }
exec /usr/bin/uname "$@"
EOF
cat >"$FAKE_BIN/stat" <<'EOF'
#!/bin/sh
case "${1:-}:${2:-}" in
    -f:%u) shift 2; [ "${1:-}" = -- ] && shift; exec /usr/bin/stat -c '%u' -- "$@" ;;
    -f:%Lp) shift 2; [ "${1:-}" = -- ] && shift; exec /usr/bin/stat -c '%a' -- "$@" ;;
    *) exec /usr/bin/stat "$@" ;;
esac
EOF
cat >"$FAKE_BIN/ln" <<'EOF'
#!/bin/sh
last=
for argument do last=$argument; done
if [ -n "${MACOS_TEST_FAIL_DEST:-}" ] && [ "$last" = "$MACOS_TEST_FAIL_DEST" ]; then
    echo "injected link failure" >&2
    exit 73
fi
exec /bin/ln "$@"
EOF
chmod 755 "$FAKE_BIN/uname" "$FAKE_BIN/stat" "$FAKE_BIN/ln"

make_home() {
    name=$1
    home=$TEMP_DIR/$name
    private=$home/.config/harness/private
    mkdir -p "$private/hosts"
    cp "$FIXTURE/companion.conf" "$private/companion.conf"
    cp "$FIXTURE/hosts/mac-test-pilot.conf" \
        "$private/hosts/mac-test-pilot.conf"
    chmod 700 "$home" "$home/.config" "$home/.config/harness" \
        "$private" "$private/hosts"
    chmod 600 "$private/companion.conf" \
        "$private/hosts/mac-test-pilot.conf"
    git -C "$private" init -q -b main
    git -C "$private" config user.name mac-test
    git -C "$private" config user.email mac-test.invalid
    git -C "$private" add companion.conf hosts/mac-test-pilot.conf
    git -C "$private" commit -q -m 'synthetic private control profile'
    chmod 700 "$private/.git"
    printf '%s\n' "$home"
}

run_control() {
    control_home=$1
    shift
    HOME="$control_home" HARNESS_ROOT="$PUBLIC" \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$CONTROL" "$@"
}

transaction_id() {
    sed -n 's/^TRANSACTION id=\([^ ]*\) status=complete.*/\1/p' "$1"
}

link_count=7
basic_home=$(make_home basic)
run_control "$basic_home" --host mac-test-pilot --plan >"$TEMP_DIR/basic.plan"
[ "$(grep -c '^CREATE link=' "$TEMP_DIR/basic.plan")" -eq "$link_count" ] ||
    fail "plan did not report the exact managed link set"
grep -F 'END macos_control blocked=0 changes=7 applied=no' \
    "$TEMP_DIR/basic.plan" >/dev/null || fail "plan completion summary"
[ ! -e "$basic_home/.local" ] && [ ! -L "$basic_home/.local" ] ||
    fail "plan mutated local state"

run_control "$basic_home" --host mac-test-pilot --apply >"$TEMP_DIR/basic.apply"
basic_tx=$(transaction_id "$TEMP_DIR/basic.apply")
[ -n "$basic_tx" ] || fail "apply emitted no transaction identifier"
basic_manifest=$basic_home/.local/state/harness/transactions/$basic_tx.macos-control.manifest
basic_status=$basic_home/.local/state/harness/transactions/$basic_tx.macos-control.status
[ "$(/usr/bin/stat -c '%a' "$basic_manifest")" = 600 ] ||
    fail "transaction manifest mode"
[ "$(/usr/bin/stat -c '%a' "$basic_status")" = 600 ] ||
    fail "transaction status mode"
[ "$(/usr/bin/stat -c '%a' "$basic_home/.local/state/harness")" = 700 ] ||
    fail "transaction state mode"
[ -L "$basic_home/.local/bin/harness" ] &&
    [ "$(readlink "$basic_home/.local/bin/harness")" = "$PUBLIC/bin/harness" ] ||
    fail "harness discovery link"
[ -L "$basic_home/.codex/skills/mac-test-skill" ] &&
    [ "$(readlink "$basic_home/.codex/skills/mac-test-skill")" = \
        "$PUBLIC/shared/skills/mac-test-skill" ] || fail "Codex skill link"

before_count=$(find "$basic_home/.local/state/harness/transactions" \
    -type f -name '*.macos-control.manifest' | wc -l | tr -d ' ')
run_control "$basic_home" --host mac-test-pilot --apply >"$TEMP_DIR/basic.second"
after_count=$(find "$basic_home/.local/state/harness/transactions" \
    -type f -name '*.macos-control.manifest' | wc -l | tr -d ' ')
[ "$before_count" = "$after_count" ] || fail "idempotent apply created a transaction"
grep -F 'END macos_control changes=none' "$TEMP_DIR/basic.second" >/dev/null ||
    fail "idempotent apply summary"

unlink "$basic_home/.local/bin/harness"
ln -s "$PUBLIC/.codex/AGENTS.md" "$basic_home/.local/bin/harness"
if run_control "$basic_home" --rollback "$basic_tx" \
    >"$TEMP_DIR/basic.changed" 2>&1; then
    fail "rollback accepted a changed link"
fi
grep -F 'rollback blocked by changed link' "$TEMP_DIR/basic.changed" >/dev/null ||
    fail "changed-link rollback refusal"
[ -L "$basic_home/.codex/AGENTS.md" ] ||
    fail "changed-link refusal mutated another link"
unlink "$basic_home/.local/bin/harness"
ln -s "$PUBLIC/bin/harness" "$basic_home/.local/bin/harness"
run_control "$basic_home" --rollback "$basic_tx" >"$TEMP_DIR/basic.rollback"
[ "$(sed -n '1p' "$basic_status")" = rolled-back ] || fail "rollback status"
[ ! -e "$basic_home/.local/bin/harness" ] &&
    [ ! -L "$basic_home/.local/bin/harness" ] || fail "rollback retained harness link"
[ ! -e "$basic_home/.codex" ] && [ ! -L "$basic_home/.codex" ] ||
    fail "rollback retained a created discovery directory"

keep_home=$(make_home preexisting)
mkdir -p "$keep_home/.codex"
chmod 700 "$keep_home/.codex"
ln -s "$PUBLIC/.codex/AGENTS.md" "$keep_home/.codex/AGENTS.md"
mkdir -p "$keep_home/.local/state"
chmod 755 "$keep_home/.local" "$keep_home/.local/state"
run_control "$keep_home" --host mac-test-pilot --apply >"$TEMP_DIR/keep.apply"
keep_tx=$(transaction_id "$TEMP_DIR/keep.apply")
[ -n "$keep_tx" ] || fail "pre-existing-link apply transaction"
keep_manifest=$keep_home/.local/state/harness/transactions/$keep_tx.macos-control.manifest
if grep -F "link|$keep_home/.codex/AGENTS.md|" "$keep_manifest" >/dev/null; then
    fail "transaction claimed a pre-existing correct link"
fi
[ "$(/usr/bin/stat -c '%a' "$keep_home/.local")" = 755 ] &&
    [ "$(/usr/bin/stat -c '%a' "$keep_home/.local/state")" = 755 ] ||
    fail "apply changed pre-existing personal directory modes"
run_control "$keep_home" --rollback "$keep_tx" >"$TEMP_DIR/keep.rollback"
[ -L "$keep_home/.codex/AGENTS.md" ] &&
    [ "$(readlink "$keep_home/.codex/AGENTS.md")" = "$PUBLIC/.codex/AGENTS.md" ] ||
    fail "rollback removed a pre-existing correct link"

collision_home=$(make_home collision)
mkdir -p "$collision_home/.local/bin"
chmod 700 "$collision_home/.local" "$collision_home/.local/bin"
printf '%s\n' occupied >"$collision_home/.local/bin/harness"
if run_control "$collision_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/collision.out" 2>&1; then
    fail "plan accepted an existing regular destination"
fi
grep -F 'reason=existing-path' "$TEMP_DIR/collision.out" >/dev/null ||
    fail "existing-path refusal"
[ ! -e "$collision_home/.local/state" ] || fail "blocked plan mutated state"

wrong_home=$(make_home wrong-link)
mkdir -p "$wrong_home/.local/bin"
chmod 700 "$wrong_home/.local" "$wrong_home/.local/bin"
ln -s "$PUBLIC/.codex/AGENTS.md" "$wrong_home/.local/bin/harness"
if run_control "$wrong_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/wrong.out" 2>&1; then
    fail "apply accepted a different symlink"
fi
grep -F 'reason=different-symlink' "$TEMP_DIR/wrong.out" >/dev/null ||
    fail "different-symlink refusal"
[ ! -e "$wrong_home/.local/state" ] || fail "blocked apply created state"

parent_home=$(make_home parent-link)
mkdir -p "$parent_home/elsewhere"
chmod 700 "$parent_home/elsewhere"
ln -s "$parent_home/elsewhere" "$parent_home/.agents"
if run_control "$parent_home" --host mac-test-pilot --plan \
    >"$TEMP_DIR/parent.out" 2>&1; then
    fail "plan accepted a symlinked parent"
fi
grep -F 'parent path is unsafe' "$TEMP_DIR/parent.out" >/dev/null ||
    fail "symlink-parent refusal"

content_home=$(make_home unexpected-content)
run_control "$content_home" --host mac-test-pilot --apply >"$TEMP_DIR/content.apply"
content_tx=$(transaction_id "$TEMP_DIR/content.apply")
[ -n "$content_tx" ] || fail "unexpected-content apply transaction"
printf '%s\n' owner-data >"$content_home/.agents/skills/owner-note"
if run_control "$content_home" --rollback "$content_tx" \
    >"$TEMP_DIR/content.refused" 2>&1; then
    fail "rollback accepted unexpected directory content"
fi
grep -F 'rollback blocked by non-transaction content' \
    "$TEMP_DIR/content.refused" >/dev/null || fail "unexpected-content refusal"
[ -L "$content_home/.local/bin/harness" ] ||
    fail "unexpected-content refusal mutated links"
unlink "$content_home/.agents/skills/owner-note"
run_control "$content_home" --rollback "$content_tx" >"$TEMP_DIR/content.rollback"

state_link_home=$(make_home state-link)
mkdir -p "$state_link_home/.local" "$state_link_home/elsewhere-state"
chmod 700 "$state_link_home/.local" "$state_link_home/elsewhere-state"
ln -s "$state_link_home/elsewhere-state" "$state_link_home/.local/state"
if run_control "$state_link_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/state-link.out" 2>&1; then
    fail "apply accepted a symlinked transaction-state path"
fi
grep -F 'state path is unsafe' "$TEMP_DIR/state-link.out" >/dev/null ||
    fail "symlinked state-path refusal"
[ ! -e "$state_link_home/.local/bin/harness" ] &&
    [ ! -L "$state_link_home/.local/bin/harness" ] ||
    fail "state-path refusal created a managed link"
[ ! -e "$state_link_home/elsewhere-state/harness" ] ||
    fail "symlinked state path was followed"

partial_home=$(make_home partial-failure)
if MACOS_TEST_FAIL_DEST="$partial_home/.agents/skills/mac-test-skill" \
    run_control "$partial_home" --host mac-test-pilot --apply \
    >"$TEMP_DIR/partial.out" 2>&1; then
    fail "injected partial apply succeeded"
fi
grep -F 'injected link failure' "$TEMP_DIR/partial.out" >/dev/null ||
    fail "injected partial failure was not reached"
[ ! -e "$partial_home/.local/bin/harness" ] &&
    [ ! -L "$partial_home/.local/bin/harness" ] ||
    fail "partial failure retained a managed link"
[ ! -e "$partial_home/.codex" ] && [ ! -L "$partial_home/.codex" ] ||
    fail "partial failure retained a created discovery directory"
partial_status=$(find "$partial_home/.local/state/harness/transactions" \
    -type f -name '*.macos-control.status')
[ -n "$partial_status" ] && [ "$(sed -n '1p' "$partial_status")" = failed ] ||
    fail "partial failure transaction status"

echo "personal macOS control tests: PASS"
