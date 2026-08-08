#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-housekeeping-interrupt.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" \
            >/dev/null || cleanup_failed=1
    fi
    [ "$status" -ne 0 ] || [ "$cleanup_failed" -eq 0 ] || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

STATE=$TEST_ROOT/state
HOME_DIR=$TEST_ROOT/home
REPO=$TEST_ROOT/repo
PR_DATA=$TEST_ROOT/pr-data.json
GH=$TEST_ROOT/gh
mkdir -m 700 "$STATE"
mkdir "$HOME_DIR" "$REPO"
printf '[]\n' >"$PR_DATA"
cat >"$GH" <<'SH'
#!/bin/sh
cat "$HARNESS_TEST_PR_DATA"
SH
chmod 700 "$GH"

git -C "$REPO" init -q
git -C "$REPO" config user.email t@example.invalid
git -C "$REPO" config user.name test
printf 'base\n' >"$REPO/tracked"
printf '### T-1 example\n' >"$REPO/TODO.md"
git -C "$REPO" add tracked TODO.md
git -C "$REPO" commit -qm base
git -C "$REPO" branch -M main
BASE=$(git -C "$REPO" rev-parse main)
git -C "$REPO" update-ref refs/remotes/origin/main "$BASE"

house() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER=3 \
    HARNESS_TEST_HOUSEKEEPING_REPO="$REPO" \
    HARNESS_TEST_GH="$GH" \
    HARNESS_TEST_PR_DATA="$PR_DATA" \
    HARNESS_TEST_OWNER_HOME="$HOME_DIR" \
    HARNESS_TEST_RECEIPT_DIR="$STATE" \
    HARNESS_TEST_WORKTREE_BOUNDARIES="$TEMP_BASE" \
        "$HARNESS" housekeeping "$@"
}

receipt_from() {
    printf '%s\n' "$1" | sed -n 's/^  RECEIPT path=\([^ ]*\) token=.*/\1/p'
}

token_from() {
    printf '%s\n' "$1" | sed -n 's/^  RECEIPT path=[^ ]* token=\([0-9a-f]*\).*/\1/p'
}

# Prove the durable checkpoint and recovery path after directory deletion.
WORKTREE=$TEST_ROOT/directory-stage
git -C "$REPO" branch interrupt-directory "$BASE"
git -C "$REPO" worktree add -q "$WORKTREE" interrupt-directory
OUT=$(house --plan --routine worktrees --path "$WORKTREE")
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
[ -n "$PLAN" ] && [ -n "$TOKEN" ] || fail 'directory-stage plan missing'
if (HARNESS_TEST_INTERRUPT_AFTER_WORKTREE=1 house --apply --routine worktrees \
    --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1); then
    fail 'directory-stage synthetic interruption unexpectedly succeeded'
fi
[ ! -e "$WORKTREE" ] || fail 'directory-stage interruption retained worktree'
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupt-directory ||
    fail 'directory-stage interruption removed branch early'
RECOVERY=$(grep -l "\"current\":\"$WORKTREE\"" \
    "$STATE"/worktree-apply-*.json | tail -1)
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail 'directory-stage recovery failed'
printf '%s\n' "$OUT" | grep -Fq 'status=recovered' ||
    fail 'directory-stage recovery status changed'
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupt-directory &&
    fail 'directory-stage recovery retained branch'

# Prove the later checkpoint after Git administration cleanup.
WORKTREE=$TEST_ROOT/admin-stage
git -C "$REPO" branch interrupt-admin "$BASE"
git -C "$REPO" worktree add -q "$WORKTREE" interrupt-admin
OUT=$(house --plan --routine worktrees --path "$WORKTREE")
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
[ -n "$PLAN" ] && [ -n "$TOKEN" ] || fail 'admin-stage plan missing'
if (HARNESS_TEST_INTERRUPT_AFTER_ADMIN=1 house --apply --routine worktrees \
    --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1); then
    fail 'admin-stage synthetic interruption unexpectedly succeeded'
fi
[ ! -e "$WORKTREE" ] || fail 'admin-stage interruption retained worktree'
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupt-admin ||
    fail 'admin-stage interruption removed branch early'
RECOVERY=$(grep -l "\"current\":\"$WORKTREE\"" \
    "$STATE"/worktree-apply-*.json | tail -1)
grep -Fq '"phase":"admin-deleted"' "$RECOVERY" ||
    fail 'admin-stage checkpoint missing'
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail 'admin-stage recovery failed'
printf '%s\n' "$OUT" | grep -Fq 'status=recovered' ||
    fail 'admin-stage recovery status changed'
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupt-admin &&
    fail 'admin-stage recovery retained branch'

printf 'Housekeeping interruption tests: PASS\n'
