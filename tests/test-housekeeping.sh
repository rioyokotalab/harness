#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-housekeeping-test.XXXXXX")

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

TOOL=$ROOT/libexec/harness-housekeeping

# --- source audit --------------------------------------------------------
python3 -B - "$TOOL" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
# Never raw recursive or wildcard deletion; scratch trees route to the
# guarded workflow instead.
for forbidden in ("rm -r", "rm -f", "rm -rf", "find ", "--delete", "rsync"):
    assert forbidden not in source, forbidden
assert "guarded-bulk-delete" in source
# Branch classification must be by pull-request state, never by diff.
assert "pr list" in source and "--state merged" in source
assert "git diff" not in source
PY

# --- synthetic repository -------------------------------------------------
REPO=$TEST_ROOT/repo
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email t@example.invalid
git -C "$REPO" config user.name test
: >"$REPO/TODO.md"
printf '### T-1 example\n' >>"$REPO/TODO.md"
git -C "$REPO" add TODO.md
git -C "$REPO" commit -qm base
git -C "$REPO" branch merged-one
git -C "$REPO" branch merged-two
git -C "$REPO" branch unmerged-one

BIN=$TEST_ROOT/bin
mkdir -p "$BIN"
cat >"$BIN/gh" <<'SH'
#!/bin/sh
# Only the merged pull requests, mirroring `gh pr list --state merged`.
printf 'merged-one\nmerged-two\n'
SH
chmod 700 "$BIN/gh"

HOME_DIR=$TEST_ROOT/home
mkdir -p "$HOME_DIR"
printf '#!/bin/sh\n' >"$HOME_DIR/t000_stale_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/t001_other_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/run_this.sh"

house() {
    HARNESS_TESTING=1 \
    HARNESS_TEST_HOUSEKEEPING_REPO="$REPO" \
    HARNESS_TEST_GH="$BIN/gh" \
    HARNESS_TEST_OWNER_HOME="$HOME_DIR" \
    HARNESS_TEST_RECEIPT_DIR="$TEST_ROOT/receipts" \
        "$HARNESS" housekeeping "$@"
}

# --- plan is read-only ----------------------------------------------------
OUT=$(house --plan) || fail "plan failed"
printf '%s\n' "$OUT" | grep -Fq 'routine=branches mode=plan candidates=2' ||
    fail "plan did not find both merged branches"
printf '%s\n' "$OUT" | grep -Fq 'restore="git branch merged-one' ||
    fail "plan did not record a restore command"
printf '%s\n' "$OUT" | grep -Fq 'routine=launchers mode=plan candidates=2' ||
    fail "plan did not find the stale launchers"
printf '%s\n' "$OUT" | grep -Fq 'route=guarded-bulk-delete' ||
    fail "scratch routine did not route to guarded deletion"
printf '%s\n' "$OUT" | grep -Fq 'routine=board mode=report' ||
    fail "board routine must be report-only"
printf '%s\n' "$OUT" | grep -Fq 'routine=evidence mode=report' ||
    fail "evidence routine must be report-only"

git -C "$REPO" show-ref --verify --quiet refs/heads/merged-one ||
    fail "plan deleted a branch"
[ -f "$HOME_DIR/t000_stale_launcher.sh" ] || fail "plan deleted a launcher"

# --- report-only routines refuse apply ------------------------------------
for routine in scratch board evidence; do
    if house --apply --routine "$routine" >/dev/null 2>&1; then
        fail "apply accepted the report-only routine $routine"
    fi
done
if house --apply >/dev/null 2>&1; then
    fail "apply accepted every routine at once"
fi

# --- an unmerged branch is never a candidate ------------------------------
printf '%s\n' "$OUT" | grep -Fq 'branch=unmerged-one' &&
    fail "an unmerged branch was offered as a candidate"

# --- a branch checked out in a worktree is protected ----------------------
git -C "$REPO" worktree add -q "$TEST_ROOT/wt" merged-two 2>/dev/null || true
OUT=$(house --plan --routine branches) || fail "worktree plan failed"
printf '%s\n' "$OUT" | grep -Fq 'branch=merged-two' &&
    fail "a branch checked out in a worktree was offered for deletion"
git -C "$REPO" worktree remove --force "$TEST_ROOT/wt" 2>/dev/null || true

# --- apply removes only merged branches and records restores --------------
OUT=$(house --apply --routine branches) || fail "branch apply failed"
printf '%s\n' "$OUT" | grep -Eq 'removed=[12] ' || fail "branch apply reported nothing"
RECEIPT=$(printf '%s\n' "$OUT" | sed -n 's/.*receipt=\([^ ]*\).*/\1/p')
[ -f "$RECEIPT" ] || fail "no branch receipt written"
grep -q 'restore=git branch merged-one' "$RECEIPT" ||
    fail "receipt lacks a restore command"
git -C "$REPO" show-ref --verify --quiet refs/heads/merged-one &&
    fail "merged branch survived apply"
git -C "$REPO" show-ref --verify --quiet refs/heads/unmerged-one ||
    fail "apply removed an unmerged branch"

# --- apply unlinks launchers but never the owner's run_this.sh ------------
OUT=$(house --apply --routine launchers) || fail "launcher apply failed"
printf '%s\n' "$OUT" | grep -Fq 'removed=2' || fail "launcher apply count wrong"
[ ! -f "$HOME_DIR/t000_stale_launcher.sh" ] || fail "stale launcher survived"
[ -f "$HOME_DIR/run_this.sh" ] || fail "run_this.sh must never be removed"

printf 'Routine housekeeping tests: PASS\n'
