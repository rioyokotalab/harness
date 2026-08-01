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
    [ -z "${LIVE_PID:-}" ] || kill "$LIVE_PID" 2>/dev/null || true
    [ -z "${OPEN_PID:-}" ] || kill "$OPEN_PID" 2>/dev/null || true
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

TOOL=$ROOT/libexec/harness_housekeeping.py
WRAPPER=$ROOT/libexec/harness-housekeeping
python3 -B - "$TOOL" "$WRAPPER" <<'PY'
import ast
import pathlib
import sys

for name in sys.argv[1:]:
    source = pathlib.Path(name).read_text()
    ast.parse(source)
    for forbidden in ("branch -D", "push --delete", "rm -r", "rm -rf", "shutil.rmtree"):
        assert forbidden not in source, forbidden
source = pathlib.Path(sys.argv[1]).read_text()
assert "update-ref" in source
assert "bundle" in source and "bundle_sha256" in source
assert "guarded-delete" in source
assert 'choices=("all", "scratch", "branches", "remotes", "worktrees"' in source
PY

STATE=$TEST_ROOT/state
mkdir -m 700 "$STATE"
HOME_DIR=$TEST_ROOT/home
mkdir "$HOME_DIR"
printf '#!/bin/sh\n' >"$HOME_DIR/t000_stale_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/t001_other_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/run_this.sh"

PR_DATA=$TEST_ROOT/pr-data.json
GH=$TEST_ROOT/gh
cat >"$GH" <<'SH'
#!/bin/sh
[ "${HARNESS_TEST_GH_FAIL:-0}" = 0 ] || exit 1
cat "$HARNESS_TEST_PR_DATA"
SH
chmod 700 "$GH"

init_repo() {
    repository=$1
    mkdir -p "$repository"
    git -C "$repository" init -q
    git -C "$repository" config user.email t@example.invalid
    git -C "$repository" config user.name test
    printf 'base\n' >"$repository/tracked"
    printf '*.ignored\n' >"$repository/.gitignore"
    printf '### T-1 example\n' >"$repository/TODO.md"
    git -C "$repository" add tracked .gitignore TODO.md
    git -C "$repository" commit -qm base
    git -C "$repository" branch -M main
    git -C "$repository" update-ref refs/remotes/origin/main "$(git -C "$repository" rev-parse main)"
}

house() {
    HARNESS_TESTING=1 \
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

# Branch identity: exact squash heads and ancestors qualify; reused names do not.
REPO=$TEST_ROOT/branches
init_repo "$REPO"
BASE=$(git -C "$REPO" rev-parse main)
git -C "$REPO" branch ancestor "$BASE"
git -C "$REPO" checkout -qb squash
printf 'squash\n' >>"$REPO/tracked"
git -C "$REPO" commit -qam squash
SQUASH=$(git -C "$REPO" rev-parse HEAD)
git -C "$REPO" checkout -q main
git -C "$REPO" checkout -qb reused
printf 'old\n' >>"$REPO/tracked"
git -C "$REPO" commit -qam old
REUSED_OLD=$(git -C "$REPO" rev-parse HEAD)
printf 'new\n' >>"$REPO/tracked"
git -C "$REPO" commit -qam new
REUSED_NEW=$(git -C "$REPO" rev-parse HEAD)
git -C "$REPO" checkout -q main
git -C "$REPO" checkout -qb open-one
printf 'open\n' >>"$REPO/tracked"
git -C "$REPO" commit -qam open
OPEN=$(git -C "$REPO" rev-parse HEAD)
git -C "$REPO" checkout -q main
git -C "$REPO" branch held "$BASE"
git -C "$REPO" worktree add -q "$TEST_ROOT/held" held
cat >"$PR_DATA" <<EOF
[
 {"number":1,"state":"MERGED","headRefName":"squash","headRefOid":"$SQUASH","baseRefName":"main","mergedAt":"2026-08-01T00:00:00Z"},
 {"number":2,"state":"MERGED","headRefName":"reused","headRefOid":"$REUSED_OLD","baseRefName":"main","mergedAt":"2026-08-01T00:00:00Z"},
 {"number":3,"state":"OPEN","headRefName":"open-one","headRefOid":"$OPEN","baseRefName":"main","mergedAt":null}
]
EOF

OUT=$(house --plan --routine branches) || fail "branch plan failed"
printf '%s\n' "$OUT" | grep -Fq 'CANDIDATE branch=ancestor' || fail "ancestor was rejected"
printf '%s\n' "$OUT" | grep -Fq 'CANDIDATE branch=squash' || fail "exact squash head was rejected"
printf '%s\n' "$OUT" | grep -Fq 'REPORT branch=reused' || fail "reused branch was accepted"
printf '%s\n' "$OUT" | grep -Fq 'reason=merged-pr-head-mismatch' || fail "reused reason missing"
printf '%s\n' "$OUT" | grep -Fq 'REPORT branch=held' || fail "held branch was accepted"
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
OUT=$(house --apply --routine branches --receipt "$PLAN" --token "$TOKEN") || fail "branch apply failed"
printf '%s\n' "$OUT" | grep -Fq 'removed=2' || fail "branch apply count changed"
ARCHIVE=$(printf '%s\n' "$OUT" | sed -n 's/.*archive_receipt=\([^ ]*\).*/\1/p')
[ -f "$ARCHIVE" ] || fail "branch archive receipt missing"
BRANCH_BUNDLE=$(sed -n 's/^bundle=//p' "$ARCHIVE")
[ "$(stat -c %a "$ARCHIVE")" = 600 ] || fail "archive receipt mode changed"
[ "$(stat -c %h "$ARCHIVE")" = 1 ] || fail "archive receipt link count changed"
[ "$(stat -c %a "$BRANCH_BUNDLE")" = 600 ] || fail "archive bundle mode changed"
[ "$(stat -c %h "$BRANCH_BUNDLE")" = 1 ] || fail "archive bundle link count changed"
grep -Fq 'classification=merged-pr-exact-head pr=1' "$ARCHIVE" ||
    fail "archive receipt omitted PR classification"
house --audit --receipt "$ARCHIVE" | grep -Fq 'status=pass' || fail "branch archive audit failed"
git -C "$REPO" show-ref --verify --quiet refs/heads/ancestor && fail "ancestor branch survived"
git -C "$REPO" show-ref --verify --quiet refs/heads/squash && fail "squash branch survived"
git -C "$REPO" show-ref --verify --quiet refs/heads/reused || fail "reused branch was removed"

# Candidate drift aborts the whole transaction before deleting a stable peer.
git -C "$REPO" branch stable "$BASE"
git -C "$REPO" branch drift "$BASE"
printf '[]\n' >"$PR_DATA"
OUT=$(house --plan --routine branches)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
TREE=$(git -C "$REPO" rev-parse 'main^{tree}')
DRIFT=$(printf 'drift\n' | git -C "$REPO" commit-tree "$TREE" -p "$BASE")
git -C "$REPO" update-ref refs/heads/drift "$DRIFT" "$BASE"
if house --apply --routine branches --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1; then
    fail "branch drift was accepted"
fi
git -C "$REPO" show-ref --verify --quiet refs/heads/stable || fail "stable peer was partially deleted"

# API failure and ambiguous exact PR state are report-only.
OUT=$(HARNESS_TEST_GH_FAIL=1 house --plan --routine branches)
printf '%s\n' "$OUT" | grep -Fq 'candidates=0' || fail "API failure yielded a candidate"
OUT=$(HARNESS_TEST_REMOTE_MAIN="$DRIFT" house --plan --routine branches)
printf '%s\n' "$OUT" | grep -Fq 'candidates=0' || fail "stale origin/main yielded a candidate"
git -C "$REPO" branch ambiguous "$DRIFT"
cat >"$PR_DATA" <<EOF
[
 {"number":10,"state":"MERGED","headRefName":"ambiguous","headRefOid":"$DRIFT","baseRefName":"main","mergedAt":"2026-08-01T00:00:00Z"},
 {"number":11,"state":"MERGED","headRefName":"ambiguous","headRefOid":"$DRIFT","baseRefName":"main","mergedAt":"2026-08-01T00:01:00Z"}
]
EOF
OUT=$(house --plan --routine branches)
printf '%s\n' "$OUT" | grep -Fq 'reason=ambiguous-exact-merged-pr' || fail "ambiguous PR was accepted"

# Remote inventory has no apply path and detects advanced merged names.
git -C "$REPO" update-ref refs/remotes/origin/reused "$REUSED_NEW"
OUT=$(house --plan --routine remotes)
printf '%s\n' "$OUT" | grep -Fq 'apply=unavailable' || fail "remote inventory exposed apply"
if house --apply --routine remotes >/dev/null 2>&1; then
    fail "remote apply was accepted"
fi

# A bundle remains sufficient after archive refs and unreachable objects are pruned.
ORPHAN=$(printf 'orphan\n' | git -C "$REPO" commit-tree "$TREE")
ITEMS=$STATE/orphan-items.tsv
printf 'orphan-tip\t%s\n' "$ORPHAN" >"$ITEMS"
chmod 600 "$ITEMS"
OUT=$(house --archive --items "$ITEMS" --transaction orphan-gc-proof --source synthetic)
GC_RECEIPT=$(printf '%s\n' "$OUT" | sed -n 's/.*receipt=\([^ ]*\).*/\1/p')
git -C "$REPO" update-ref -d refs/harness-housekeeping/archive/orphan-gc-proof/orphan-tip "$ORPHAN"
git -C "$REPO" reflog expire --expire=now --all
git -C "$REPO" gc --prune=now --quiet
OUT=$(house --audit --receipt "$GC_RECEIPT")
printf '%s\n' "$OUT" | grep -Fq 'live=0 bundled=1 status=pass' || fail "bundle did not survive GC"
HARDLINK=$STATE/archive-hardlink
ln "$GC_RECEIPT" "$HARDLINK"
if house --audit --receipt "$GC_RECEIPT" >/dev/null 2>&1; then
    fail "hard-linked receipt was accepted"
fi
rm "$HARDLINK"
ITEM_LINK=$STATE/orphan-items-link.tsv
ln -s "$ITEMS" "$ITEM_LINK"
if house --archive --items "$ITEM_LINK" --transaction symlink-items --source synthetic >/dev/null 2>&1; then
    fail "symlinked archive item input was accepted"
fi
if house --archive --items "$ITEMS" --transaction orphan-gc-proof --source synthetic >/dev/null 2>&1; then
    fail "existing archive transaction was replaced"
fi
house --audit --receipt "$GC_RECEIPT" | grep -Fq 'status=pass' || fail "repeat rejection changed archive"

# Launcher behavior remains exact and preserves run_this.sh.
OUT=$(house --plan --routine launchers)
printf '%s\n' "$OUT" | grep -Fq 'candidates=2' || fail "launcher plan changed"
if house --apply --routine launchers >/dev/null 2>&1; then
    fail "launcher apply accepted a non-exact candidate set"
fi
OUT=$(house --apply --routine launchers --launcher "$HOME_DIR/t000_stale_launcher.sh")
printf '%s\n' "$OUT" | grep -Fq 'removed=1' || fail "exact launcher apply changed"
OUT=$(house --apply --routine launchers --launcher "$HOME_DIR/t001_other_launcher.sh")
printf '%s\n' "$OUT" | grep -Fq 'removed=1' || fail "second exact launcher apply changed"
[ -f "$HOME_DIR/run_this.sh" ] || fail "run_this.sh was removed"

# Worktree planning rejects every residue and liveness class.
REPO=$TEST_ROOT/worktrees
init_repo "$REPO"
BASE=$(git -C "$REPO" rev-parse main)
for name in clean dirty untracked ignored nested submodule locked live openfile; do
    git -C "$REPO" branch "$name" "$BASE"
    git -C "$REPO" worktree add -q "$TEST_ROOT/wt-$name" "$name"
done
printf 'dirty\n' >>"$TEST_ROOT/wt-dirty/tracked"
printf 'untracked\n' >"$TEST_ROOT/wt-untracked/new-file"
printf 'ignored\n' >"$TEST_ROOT/wt-ignored/data.ignored"
mkdir -p "$TEST_ROOT/wt-nested/child/.git"
printf '[submodule "x"]\n' >"$TEST_ROOT/wt-submodule/.gitmodules"
git -C "$REPO" worktree lock "$TEST_ROOT/wt-locked"
(cd "$TEST_ROOT/wt-live" && exec sleep 30) &
LIVE_PID=$!
sh -c 'exec 3<"$1"; sleep 30' sh "$TEST_ROOT/wt-openfile/tracked" &
OPEN_PID=$!
printf '[]\n' >"$PR_DATA"
OUT=$(house --plan --routine worktrees) || fail "worktree plan failed"
printf '%s\n' "$OUT" | grep -Fq 'CANDIDATE worktree='"$TEST_ROOT/wt-clean" || fail "clean worktree was rejected"
for reason in tracked-residue untracked-residue ignored-residue nested-repository submodule locked live-process-or-open-file primary-worktree; do
    printf '%s\n' "$OUT" | grep -Fq "$reason" || fail "missing worktree rejection: $reason"
done
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
OUT=$(house --apply --routine worktrees --receipt "$PLAN" --token "$TOKEN") || fail "guarded worktree apply failed"
printf '%s\n' "$OUT" | grep -Fq 'removed=1' || fail "worktree apply count changed"
[ ! -e "$TEST_ROOT/wt-clean" ] || fail "clean worktree directory survived"
git -C "$REPO" show-ref --verify --quiet refs/heads/clean || fail "worktree apply removed its branch"
for name in dirty untracked ignored nested submodule locked live openfile; do
    [ -d "$TEST_ROOT/wt-$name" ] || fail "blocked worktree was removed: $name"
done

# Interruption after directory deletion leaves a durable recoverable admin record.
git -C "$REPO" branch interrupted "$BASE"
git -C "$REPO" worktree add -q "$TEST_ROOT/wt-interrupted" interrupted
OUT=$(house --plan --routine worktrees)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
if HARNESS_TEST_INTERRUPT_AFTER_WORKTREE=1 house --apply --routine worktrees --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1; then
    fail "synthetic interruption unexpectedly succeeded"
fi
[ ! -e "$TEST_ROOT/wt-interrupted" ] || fail "interruption did not follow directory stage"
ADMIN=$(git -C "$REPO" worktree list --porcelain | awk -v path="$TEST_ROOT/wt-interrupted" '
    $1 == "worktree" { selected=($2 == path) }
    selected && $1 == "branch" { print $2; exit }
')
[ -n "$ADMIN" ] || fail "interruption did not retain stale admin metadata"
grep -R '"phase":"directory-deleted"' "$STATE" >/dev/null || fail "interruption checkpoint missing"

printf 'Routine housekeeping tests: PASS\n'
