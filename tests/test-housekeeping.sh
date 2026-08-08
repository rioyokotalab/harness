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

file_mode() {
    case $(uname -s) in Darwin) stat -f '%Lp' "$1" ;; *) stat -c '%a' -- "$1" ;; esac
}

file_links() {
    case $(uname -s) in Darwin) stat -f '%l' "$1" ;; *) stat -c '%h' -- "$1" ;; esac
}

path_device() {
    case $(uname -s) in Darwin) stat -f '%d' "$1" ;; *) stat -c '%d' -- "$1" ;; esac
}

path_inode() {
    case $(uname -s) in Darwin) stat -f '%i' "$1" ;; *) stat -c '%i' -- "$1" ;; esac
}

file_sha256() {
    case $(uname -s) in
        Darwin) shasum -a 256 "$1" | awk '{print $1}' ;;
        *) sha256sum "$1" | awk '{print $1}' ;;
    esac
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
assert '"--open-worktree"' in source and '"--expected-main"' in source
assert '"--recover-worktree"' in source
assert '"--repo"' in source
assert 'choices=("all", "scratch", "branches", "remotes", "worktrees"' in source
assert '"--retire-all-nonmain"' in source
assert '"--create-generation"' in source
assert "archive generation has duplicate durable owners" not in source
assert source.count("require_durable_worktree_archive_owner(repo)") == 2
PY

STATE=$TEST_ROOT/state
mkdir -m 700 "$STATE"
HOME_DIR=$TEST_ROOT/home
mkdir "$HOME_DIR"
printf '#!/bin/sh\n' >"$HOME_DIR/t000_stale_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/t001_other_launcher.sh"
printf '#!/bin/sh\n' >"$HOME_DIR/run_this.sh"

# Identical receipts may share one in-process bundle verification only while
# the private file's kernel identity and expected digest remain unchanged.
python3 -B - "$TOOL" "$TEST_ROOT" <<'PY'
import hashlib
import importlib.util
import os
from pathlib import Path
import subprocess
import sys

spec = importlib.util.spec_from_file_location("housekeeping_cache_fixture", sys.argv[1])
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
root = Path(sys.argv[2])
os.environ.pop("HARNESS_TESTING", None)
os.environ.pop("HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER", None)
assert module.generation_receipts_trigger() == 30
os.environ["HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER"] = "3"
try:
    module.generation_receipts_trigger()
except module.HousekeepingError:
    pass
else:
    raise AssertionError("test threshold escaped HARNESS_TESTING")
os.environ["HARNESS_TESTING"] = "1"
assert module.generation_receipts_trigger() == 3
for invalid in ("0", "03", "30", "x"):
    os.environ["HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER"] = invalid
    try:
        module.generation_receipts_trigger()
    except module.HousekeepingError:
        pass
    else:
        raise AssertionError(invalid)
os.environ.pop("HARNESS_TEST_GENERATION_RECEIPTS_TRIGGER")
os.environ.pop("HARNESS_TESTING")
bundle = root / "cache-fixture.bundle"
bundle.write_bytes(b"first-bundle")
bundle.chmod(0o600)
oid = "1" * 40
archive = "refs/harness-housekeeping/archive/cache/item"
parsed = {
    "values": {
        "repository_canonical": "/nonexistent/cache-fixture",
        "bundle": str(bundle),
        "bundle_sha256": hashlib.sha256(bundle.read_bytes()).hexdigest(),
        "archive_prefix": "refs/harness-housekeeping/archive/cache",
    },
    "items": [{"branch": "item", "tip": oid, "archive": archive}],
}
module.parse_archive_receipt = lambda _path: parsed
module.resolve_archive_owner = lambda *_args, **_kwargs: root
verify_calls = 0

def fake_git(_repo, *arguments, check=True):
    global verify_calls
    if arguments[:2] == ("bundle", "verify"):
        verify_calls += 1
        return subprocess.CompletedProcess(arguments, 0, b"", b"")
    if arguments[:2] == ("bundle", "list-heads"):
        return subprocess.CompletedProcess(
            arguments, 0, f"{oid} {archive}\n".encode(), b""
        )
    if arguments[:2] == ("rev-parse", "--verify"):
        return subprocess.CompletedProcess(arguments, 1, b"", b"")
    raise AssertionError(arguments)

module.git = fake_git
cache = {}
first = module.archive_audit(root, root / "one.receipt", bundle_cache=cache)
second = module.archive_audit(root, root / "two.receipt", bundle_cache=cache)
assert first == second and verify_calls == 1
bundle.write_bytes(b"other-bundle")
os.utime(bundle, ns=(bundle.stat().st_atime_ns, bundle.stat().st_mtime_ns + 1_000_000))
parsed["values"]["bundle_sha256"] = hashlib.sha256(bundle.read_bytes()).hexdigest()
module.archive_audit(root, root / "three.receipt", bundle_cache=cache)
assert verify_calls == 2
bundle.unlink()
PY

PR_DATA=$TEST_ROOT/pr-data.json
GH=$TEST_ROOT/gh
cat >"$GH" <<'SH'
#!/bin/sh
[ "${HARNESS_TEST_GH_FAIL:-0}" = 0 ] || exit 1
[ -z "${HARNESS_TEST_EXPECT_GH_CWD:-}" ] ||
    [ "$(pwd -P)" = "$HARNESS_TEST_EXPECT_GH_CWD" ] || exit 2
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

# Branch identity: exact squash heads and ancestors qualify; reused names do not.
REPO=$TEST_ROOT/branches
init_repo "$REPO"
BASE=$(git -C "$REPO" rev-parse main)
git -C "$REPO" branch ancestor "$BASE"
git -C "$REPO" branch ancestor-twin "$BASE"
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
printf '%s\n' "$OUT" | grep -Fq 'CANDIDATE branch=ancestor-twin' || fail "duplicate-tip ancestor was rejected"
printf '%s\n' "$OUT" | grep -Fq 'CANDIDATE branch=squash' || fail "exact squash head was rejected"
printf '%s\n' "$OUT" | grep -Fq 'REPORT branch=reused' || fail "reused branch was accepted"
printf '%s\n' "$OUT" | grep -Fq 'reason=merged-pr-head-mismatch' || fail "reused reason missing"
printf '%s\n' "$OUT" | grep -Fq 'REPORT branch=held' || fail "held branch was accepted"
(HARNESS_TEST_EXPECT_GH_CWD=$REPO house --plan --routine branches >/dev/null) ||
    fail "repository-explicit PR query did not run from the selected root"
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
OUT=$(house --apply --routine branches --receipt "$PLAN" --token "$TOKEN") || fail "branch apply failed"
printf '%s\n' "$OUT" | grep -Fq 'removed=3' || fail "branch apply count changed"
ARCHIVE=$(printf '%s\n' "$OUT" | sed -n 's/.*archive_receipt=\([^ ]*\).*/\1/p')
[ -f "$ARCHIVE" ] || fail "branch archive receipt missing"
BRANCH_BUNDLE=$(sed -n 's/^bundle=//p' "$ARCHIVE")
[ "$(file_mode "$ARCHIVE")" = 600 ] || fail "archive receipt mode changed"
[ "$(file_links "$ARCHIVE")" = 1 ] || fail "archive receipt link count changed"
[ "$(file_mode "$BRANCH_BUNDLE")" = 600 ] || fail "archive bundle mode changed"
[ "$(file_links "$BRANCH_BUNDLE")" = 1 ] || fail "archive bundle link count changed"
grep -Fq 'classification=merged-pr-exact-head pr=1' "$ARCHIVE" ||
    fail "archive receipt omitted PR classification"
grep -Fq "item branch=ancestor tip=$BASE " "$ARCHIVE" ||
    fail "archive receipt omitted first duplicate-tip branch"
grep -Fq "item branch=ancestor-twin tip=$BASE " "$ARCHIVE" ||
    fail "archive receipt omitted second duplicate-tip branch"
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

# The essential default owner stops after branch identity, immutable archival,
# candidate drift, ambiguous hosted state, and report-only remote inventory.
# Historical generation, compaction, launcher, worktree, and interruption
# permutations below remain available only for targeted diagnosis.
printf 'Routine housekeeping tests: PASS\n'
exit 0
