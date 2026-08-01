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
assert '"--open-worktree"' in source and '"--expected-main"' in source
assert '"--recover-worktree"' in source
assert '"--repo"' in source
assert 'choices=("all", "scratch", "branches", "remotes", "worktrees"' in source
assert '"--create-generation"' in source
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
HARNESS_TEST_EXPECT_GH_CWD=$REPO house --plan --routine branches >/dev/null ||
    fail "repository-explicit PR query did not run from the selected root"
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

# A generation receipt is published only after an independent bare restore
# proves its exact head set. Inventory re-audits the immutable inputs and
# bundle but exposes no generation creation or deletion route.
GENERATION_DIR=$STATE/generations
mkdir -m 700 "$GENERATION_DIR"
GENERATION_ID=generation-test
GEN_MAIN_REF=refs/harness-housekeeping/generation/$GENERATION_ID/main
GEN_TIP_REF=refs/harness-housekeeping/generation/$GENERATION_ID/tip
git -C "$REPO" update-ref "$GEN_MAIN_REF" "$BASE"
git -C "$REPO" update-ref "$GEN_TIP_REF" "$DRIFT"
GEN_BUNDLE=$GENERATION_DIR/$GENERATION_ID.bundle
git -C "$REPO" bundle create "$GEN_BUNDLE" "$GEN_MAIN_REF" "$GEN_TIP_REF"
chmod 600 "$GEN_BUNDLE"
GEN_RESTORE=$TEST_ROOT/generation-restore.git
git init -q --bare "$GEN_RESTORE"
git -C "$GEN_RESTORE" fetch -q "$GEN_BUNDLE" \
    "$GEN_MAIN_REF:$GEN_MAIN_REF" "$GEN_TIP_REF:$GEN_TIP_REF"
[ "$(git -C "$GEN_RESTORE" rev-parse "$GEN_MAIN_REF")" = "$BASE" ] ||
    fail "generation restore changed protected main"
[ "$(git -C "$GEN_RESTORE" rev-parse "$GEN_TIP_REF")" = "$DRIFT" ] ||
    fail "generation restore changed retained tip"
GEN_HEADSET=$(python3 -B - "$GEN_MAIN_REF" "$BASE" "$GEN_TIP_REF" "$DRIFT" <<'PY'
import hashlib
import json
import sys

rows = sorted(((sys.argv[1], sys.argv[2]), (sys.argv[3], sys.argv[4])))
print(hashlib.sha256(json.dumps(rows, separators=(",", ":")).encode()).hexdigest())
PY
)
GEN_RECEIPT=$GENERATION_DIR/$GENERATION_ID.json
ARCHIVE_NAME=$(basename "$ARCHIVE")
GC_NAME=$(basename "$GC_RECEIPT")
cat >"$GEN_RECEIPT" <<EOF
{"schema":"harness-housekeeping-generation-v1","generation":"$GENERATION_ID","created_utc":"2026-07-31T00:00:00Z","source_receipts":[{"name":"$ARCHIVE_NAME","sha256":"$(sha256sum "$ARCHIVE" | awk '{print $1}')"},{"name":"$GC_NAME","sha256":"$(sha256sum "$GC_RECEIPT" | awk '{print $1}')"}],"repositories":[{"repository_canonical":"$REPO","repository_id":[$(stat -c %d "$REPO"),$(stat -c %i "$REPO")],"protected_main":{"ref":"refs/remotes/origin/main","tip":"$BASE"},"bundle":"$GEN_BUNDLE","bundle_sha256":"$(sha256sum "$GEN_BUNDLE" | awk '{print $1}')","heads":[{"ref":"$GEN_MAIN_REF","tip":"$BASE"},{"ref":"$GEN_TIP_REF","tip":"$DRIFT"}],"restore_drill":{"method":"independent-bare-fetch-exact-heads-v1","verified_utc":"2026-07-31T00:01:00Z","headset_sha256":"$GEN_HEADSET"}}]}
EOF
chmod 600 "$GEN_RECEIPT"
printf 'archived tip %s\n' "$SQUASH" >>"$REPO/TODO.md"
git -C "$REPO" add TODO.md
git -C "$REPO" commit -qm 'reference archived tip'
git -C "$REPO" update-ref refs/remotes/origin/main "$(git -C "$REPO" rev-parse HEAD)"

# Archive retention discovery audits every receipt but remains report-only and
# does not create another plan merely by observing the state directory.
printf 'legacy bundle identity only\n' >"$STATE/legacy.bundle"
printf 'legacy evidence identity only\n' >"$STATE/legacy.tar.gz"
chmod 600 "$STATE/legacy.bundle" "$STATE/legacy.tar.gz"
ARCHIVE_FILES_BEFORE=$(find "$STATE" -type f | wc -l)
OUT=$(house --plan --routine archives) || fail "archive inventory failed"
printf '%s\n' "$OUT" | grep -Fq \
    'routine=archives mode=report receipts=2 items=3 unique_tips=3' ||
    fail "archive inventory summary changed"
printf '%s\n' "$OUT" | grep -Fq \
    'archive_only=2 pr_equal=0 pr_unknown=1' ||
    fail "archive inventory classification changed"
printf '%s\n' "$OUT" | grep -Fq \
    'ledger_yes=1 ledger_unknown=0' ||
    fail "batched ledger inventory changed"
printf '%s\n' "$OUT" | grep -Fq \
    'candidates=0 apply=unavailable' ||
    fail "archive inventory exposed deletion"
printf '%s\n' "$OUT" | grep -Fq \
    'incomplete_applies=0 unbound_bundles=1 evidence_payloads=1' ||
    fail "archive auxiliary inventory changed"
printf '%s\n' "$OUT" | grep -Fq \
    'generations=1 generation_trigger=no' ||
    fail "archive generation trigger changed"
printf '%s\n' "$OUT" | grep -Fq 'audit=pass candidate=no' ||
    fail "archive inventory omitted receipt audit"
printf '%s\n' "$OUT" | grep -Fq \
    'type=unbound-bundle name=legacy.bundle' ||
    fail "archive inventory omitted unbound bundle"
printf '%s\n' "$OUT" | grep -Fq \
    'type=evidence-payload name=legacy.tar.gz' ||
    fail "archive inventory omitted evidence payload"
printf '%s\n' "$OUT" | grep -Fq \
    'type=generation name=generation-test.json' ||
    fail "archive inventory omitted verified generation"
ARCHIVE_FILES_AFTER=$(find "$STATE" -type f | wc -l)
[ "$ARCHIVE_FILES_BEFORE" -eq "$ARCHIVE_FILES_AFTER" ] ||
    fail "archive inventory created durable state"
chmod 640 "$GEN_RECEIPT"
if house --plan --routine archives >/dev/null 2>&1; then
    fail "archive inventory accepted mutable generation receipt identity"
fi
chmod 600 "$GEN_RECEIPT"
THRESHOLD_PAYLOAD=$STATE/threshold.tar.gz
truncate -s 537000000 "$THRESHOLD_PAYLOAD"
chmod 600 "$THRESHOLD_PAYLOAD"
OUT=$(house --plan --routine archives)
printf '%s\n' "$OUT" | grep -Fq 'generation_trigger=bytes' ||
    fail "archive byte trigger was not measured"
OUT=$(house --create-generation) || fail "triggered archive generation failed"
printf '%s\n' "$OUT" | grep -Fq \
    'routine=archives mode=create-generation' ||
    fail "archive generation result changed"
printf '%s\n' "$OUT" | grep -Fq \
    'repositories=1 heads=4' ||
    fail "archive generation head coverage changed"
printf '%s\n' "$OUT" | grep -Fq \
    'trigger=bytes' ||
    fail "archive generation omitted its trigger"
printf '%s\n' "$OUT" | grep -Fq \
    'restore=pass status=verified' ||
    fail "archive generation omitted its restore proof"
CREATED_GENERATION=$(printf '%s\n' "$OUT" | sed -n 's/.*receipt=\([^ ]*\).*/\1/p')
[ -f "$CREATED_GENERATION" ] || fail "archive generation receipt missing"
OUT=$(house --plan --routine archives)
printf '%s\n' "$OUT" | grep -Fq \
    'generations=2 generation_trigger=no' ||
    fail "created archive generation did not re-audit"
printf '%s\n' "$OUT" | grep -Fq \
    'generation_trigger_basis=delta generation_uncovered=0' ||
    fail "created generation did not baseline covered receipts"
printf '%s\n' "$OUT" | grep -Fq \
    'archive_only=2' ||
    fail "generation refs masked archive-only tips"
if house --create-generation >/dev/null 2>&1; then
    fail "duplicate archive generation was accepted"
fi
if house --plan-archive-compaction --source-receipt "$GC_RECEIPT" >/dev/null 2>&1; then
    fail "single-generation archive compaction was accepted"
fi

# Two independently restored generations permit one exact source-bundle
# compaction. The immutable source receipt remains auditable, and later
# generations recover its tips from the retained generation bundles.
index=1
while [ "$index" -le 31 ]; do
    cp "$ARCHIVE" "$STATE/delta-before-compaction-$index.receipt"
    chmod 600 "$STATE/delta-before-compaction-$index.receipt"
    index=$((index + 1))
done
printf 'advance protected main for second generation\n' >>"$REPO/TODO.md"
git -C "$REPO" add TODO.md
git -C "$REPO" commit -qm 'advance generation proof'
git -C "$REPO" update-ref refs/remotes/origin/main "$(git -C "$REPO" rev-parse HEAD)"
OUT=$(house --create-generation) || fail "second covering generation failed"
printf '%s\n' "$OUT" | grep -Fq 'restore=pass status=verified' ||
    fail "second generation restore proof changed"
printf '%s\n' "$OUT" | grep -Fq \
    'trigger=receipts trigger_basis=delta uncovered=31' ||
    fail "second generation did not use uncovered-receipt growth"
GC_BUNDLE=$(sed -n 's/^bundle=//p' "$GC_RECEIPT")
[ -f "$GC_BUNDLE" ] || fail "compaction source bundle is missing"
OUT=$(house --plan-archive-compaction --source-receipt "$GC_RECEIPT") ||
    fail "archive compaction plan failed"
COMPACTION=$(receipt_from "$OUT")
COMPACTION_TOKEN=$(token_from "$OUT")
printf '%s\n' "$OUT" | grep -Fq 'generations=2 candidate=yes' ||
    fail "archive compaction omitted dual-generation proof"
house --apply-archive-compaction --receipt "$COMPACTION" \
    --token "$COMPACTION_TOKEN" | grep -Fq 'removed=1' ||
    fail "archive compaction apply failed"
[ ! -e "$GC_BUNDLE" ] || fail "compacted source bundle survived"
[ -f "$GC_RECEIPT" ] || fail "compaction removed source metadata"
OUT=$(house --audit --receipt "$GC_RECEIPT") ||
    fail "compacted archive audit failed"
printf '%s\n' "$OUT" | grep -Fq 'retired=1 generations=2' ||
    fail "compacted archive omitted generation coverage"
OUT=$(house --plan --routine archives) || fail "compacted inventory failed"
printf '%s\n' "$OUT" | grep -Fq 'retired_bundles=1' ||
    fail "compacted inventory omitted retired bundle"
printf '%s\n' "$OUT" | grep -Fq 'compactions=1' ||
    fail "compacted inventory omitted compaction receipt"
if house --plan-archive-compaction --source-receipt "$GC_RECEIPT" >/dev/null 2>&1; then
    fail "already compacted archive was accepted"
fi
printf 'advance protected main after compaction\n' >>"$REPO/TODO.md"
git -C "$REPO" add TODO.md
git -C "$REPO" commit -qm 'prove compacted generation source'
git -C "$REPO" update-ref refs/remotes/origin/main "$(git -C "$REPO" rev-parse HEAD)"
index=1
while [ "$index" -le 31 ]; do
    cp "$ARCHIVE" "$STATE/delta-after-compaction-$index.receipt"
    chmod 600 "$STATE/delta-after-compaction-$index.receipt"
    index=$((index + 1))
done
OUT=$(house --create-generation) ||
    fail "generation could not recover a compacted source"
printf '%s\n' "$OUT" | grep -Fq 'restore=pass status=verified' ||
    fail "post-compaction generation restore proof changed"
OUT=$(house --plan --routine archives)
printf '%s\n' "$OUT" | grep -Fq \
    'generation_trigger=no generation_trigger_basis=delta generation_uncovered=0' ||
    fail "latest generation did not turn off lifetime receipt trigger"
unlink "$THRESHOLD_PAYLOAD"
if house --create-generation >/dev/null 2>&1; then
    fail "archive generation ignored the measured trigger"
fi
if house --apply --routine archives >/dev/null 2>&1; then
    fail "archive inventory accepted apply"
fi
printf '%s\n' '{"schema":"unexpected"}' >"$STATE/plans/malformed.json"
chmod 600 "$STATE/plans/malformed.json"
if house --plan --routine archives >/dev/null 2>&1; then
    fail "archive inventory accepted malformed plan state"
fi
unlink "$STATE/plans/malformed.json"

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

# Opening a task worktree requires an exact clean primary main and produces a
# branch-bound isolated tree that the normal closeout transaction fully retires.
REPO=$TEST_ROOT/open-worktree
init_repo "$REPO"
BASE=$(git -C "$REPO" rev-parse main)
OPEN_PATH=$TEST_ROOT/opened-task
printf 'dirty\n' >>"$REPO/tracked"
if house --open-worktree --branch task/open-dirty --path "$OPEN_PATH" \
    --expected-main "$BASE" >/dev/null 2>&1; then
    fail "dirty reference checkout opened a worktree"
fi
git -C "$REPO" restore tracked
git -C "$REPO" switch -qc off-main
if house --open-worktree --branch task/open-off-main --path "$OPEN_PATH" \
    --expected-main "$BASE" >/dev/null 2>&1; then
    fail "off-main reference checkout opened a worktree"
fi
git -C "$REPO" switch -q main
if house --open-worktree --branch task/open-stale --path "$OPEN_PATH" \
    --expected-main 0000000000000000000000000000000000000000 \
    >/dev/null 2>&1; then
    fail "stale expected main opened a worktree"
fi
OUT=$(house --open-worktree --branch task/open --path "$OPEN_PATH" \
    --expected-main "$BASE") || fail "exact task worktree open failed"
printf '%s\n' "$OUT" | grep -Fq \
    "routine=worktree-open mode=apply branch=task/open tip=$BASE path=$OPEN_PATH" ||
    fail "task worktree open readback changed"
[ "$(git -C "$OPEN_PATH" branch --show-current)" = task/open ] ||
    fail "task worktree branch changed"
[ "$(git -C "$OPEN_PATH" rev-parse HEAD)" = "$BASE" ] ||
    fail "task worktree tip changed"
OTHER_OPEN_PATH=$TEST_ROOT/other-opened-task
git -C "$REPO" branch task/other-open "$BASE"
git -C "$REPO" worktree add -q "$OTHER_OPEN_PATH" task/other-open
printf '[]\n' >"$PR_DATA"
OUT=$(house --plan --routine worktrees --path "$OPEN_PATH")
printf '%s\n' "$OUT" | grep -Fq "selected=$OPEN_PATH" ||
    fail "exact worktree selection was not recorded"
printf '%s\n' "$OUT" | grep -Fq \
    "REPORT worktree=$OTHER_OPEN_PATH branch=task/other-open tip=$BASE reason=not-selected" ||
    fail "parallel clean worktree was not excluded"
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
OUT=$(house --apply --routine worktrees --receipt "$PLAN" --token "$TOKEN") ||
    fail "opened task worktree closeout failed"
[ ! -e "$OPEN_PATH" ] || fail "opened task worktree survived closeout"
git -C "$REPO" show-ref --verify --quiet refs/heads/task/open &&
    fail "opened task branch survived closeout"
[ -d "$OTHER_OPEN_PATH" ] || fail "parallel clean worktree was removed"
git -C "$REPO" worktree remove "$OTHER_OPEN_PATH"
git -C "$REPO" update-ref -d refs/heads/task/other-open "$BASE"

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
git -C "$REPO" show-ref --verify --quiet refs/heads/clean &&
    fail "worktree apply retained its branch"
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
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupted ||
    fail "interruption removed the task branch before admin cleanup"
ADMIN=$(git -C "$REPO" worktree list --porcelain | awk -v path="$TEST_ROOT/wt-interrupted" '
    $1 == "worktree" { selected=($2 == path) }
    selected && $1 == "branch" { print $2; exit }
')
[ -n "$ADMIN" ] || fail "interruption did not retain stale admin metadata"
grep -R '"phase":"directory-deleted"' "$STATE" >/dev/null || fail "interruption checkpoint missing"
RECOVERY=$(grep -l '"phase":"directory-deleted"' \
    "$STATE"/worktree-apply-*.json | grep -v 'worktree-apply-unsafe.json$' | tail -1)
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail "directory-stage recovery failed"
printf '%s\n' "$OUT" | grep -Fq 'status=recovered' ||
    fail "directory-stage recovery status changed"
[ ! -e "$TEST_ROOT/wt-interrupted" ] ||
    fail "directory-stage recovery restored the worktree"
git -C "$REPO" worktree list --porcelain | grep -Fq "$TEST_ROOT/wt-interrupted" &&
    fail "directory-stage recovery retained administration metadata"
git -C "$REPO" show-ref --verify --quiet refs/heads/interrupted &&
    fail "directory-stage recovery retained the branch"
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail "completed recovery was not idempotent"
printf '%s\n' "$OUT" | grep -Fq 'status=no-op' ||
    fail "completed recovery did not report a no-op"

# Interruption after admin cleanup leaves the archived exact-old branch for
# deterministic branch reconciliation and records the later phase precisely.
git -C "$REPO" branch admin-interrupted "$BASE"
git -C "$REPO" worktree add -q "$TEST_ROOT/wt-admin-interrupted" admin-interrupted
OUT=$(house --plan --routine worktrees)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
if HARNESS_TEST_INTERRUPT_AFTER_ADMIN=1 house --apply --routine worktrees \
    --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1; then
    fail "admin-stage synthetic interruption unexpectedly succeeded"
fi
[ ! -e "$TEST_ROOT/wt-admin-interrupted" ] ||
    fail "admin-stage interruption retained the worktree directory"
git -C "$REPO" show-ref --verify --quiet refs/heads/admin-interrupted ||
    fail "admin-stage interruption removed the branch"
grep -R '"phase":"admin-deleted"' "$STATE" >/dev/null ||
    fail "admin-stage interruption checkpoint missing"
RECOVERY=$(grep -l '"phase":"admin-deleted"' \
    "$STATE"/worktree-apply-*.json | tail -1)
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail "admin-stage recovery failed"
printf '%s\n' "$OUT" | grep -Fq 'status=recovered' ||
    fail "admin-stage recovery status changed"
git -C "$REPO" show-ref --verify --quiet refs/heads/admin-interrupted &&
    fail "admin-stage recovery retained the branch"
grep -Fq '"phase":"complete"' "$RECOVERY" ||
    fail "admin-stage recovery did not complete durable state"

# A changed exact-old branch is rejected before remaining administration is
# removed, and a symlink cannot substitute for the private recovery receipt.
git -C "$REPO" branch changed-interrupted "$BASE"
git -C "$REPO" worktree add -q "$TEST_ROOT/wt-changed-interrupted" \
    changed-interrupted
OUT=$(house --plan --routine worktrees)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
if HARNESS_TEST_INTERRUPT_AFTER_WORKTREE=1 house --apply --routine worktrees \
    --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1; then
    fail "changed-tip interruption unexpectedly succeeded"
fi
RECOVERY=$(grep -l '"current":"'$TEST_ROOT'/wt-changed-interrupted"' \
    "$STATE"/worktree-apply-*.json | tail -1)
CHANGED=$(printf 'changed recovery fixture\n' | \
    git -C "$REPO" commit-tree "$BASE^{tree}" -p "$BASE")
git -C "$REPO" update-ref refs/heads/changed-interrupted "$CHANGED" "$BASE"
if house --recover-worktree --receipt "$RECOVERY" >/dev/null 2>&1; then
    fail "changed-tip recovery unexpectedly succeeded"
fi
git -C "$REPO" worktree list --porcelain | \
    grep -Fq "$TEST_ROOT/wt-changed-interrupted" ||
    fail "changed-tip rejection removed administration metadata"
UNSAFE_RECEIPT=$STATE/worktree-apply-unsafe.json
ln -s "$RECOVERY" "$UNSAFE_RECEIPT"
if house --recover-worktree --receipt "$UNSAFE_RECEIPT" >/dev/null 2>&1; then
    fail "symlink recovery receipt unexpectedly succeeded"
fi
RECOVERY_PLAN=$(sed -n 's/.*"plan":"\([^"]*\)".*/\1/p' "$RECOVERY")
printf ' ' >>"$RECOVERY_PLAN"
if ERROR=$(house --recover-worktree --receipt "$RECOVERY" 2>&1); then
    fail "changed recovery plan unexpectedly succeeded"
fi
printf '%s\n' "$ERROR" | grep -Fq 'plan digest changed' ||
    fail "changed recovery plan did not fail at its digest"

# If a bulk closeout stops on its first candidate, recovery finishes only that
# exact candidate and leaves every unstarted candidate for a fresh normal plan.
REPO=$TEST_ROOT/worktrees-multi-recovery
init_repo "$REPO"
BASE=$(git -C "$REPO" rev-parse main)
for name in multi-a multi-b; do
    git -C "$REPO" branch "$name" "$BASE"
    git -C "$REPO" worktree add -q "$TEST_ROOT/wt-$name" "$name"
done
printf '[]\n' >"$PR_DATA"
OUT=$(house --plan --routine worktrees)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
if HARNESS_TEST_INTERRUPT_AFTER_WORKTREE=1 house --apply --routine worktrees \
    --receipt "$PLAN" --token "$TOKEN" >/dev/null 2>&1; then
    fail "multi-candidate interruption unexpectedly succeeded"
fi
RECOVERY=$(grep -l '"current":"'$TEST_ROOT'/wt-multi-' \
    "$STATE"/worktree-apply-*.json | tail -1)
OUT=$(house --recover-worktree --receipt "$RECOVERY") ||
    fail "multi-candidate recovery failed"
printf '%s\n' "$OUT" | grep -Fq 'remaining_replan=1' ||
    fail "multi-candidate recovery did not preserve unstarted work"
remaining=0
for name in multi-a multi-b; do
    [ ! -d "$TEST_ROOT/wt-$name" ] || remaining=$((remaining + 1))
done
[ "$remaining" -eq 1 ] || fail "multi-candidate recovery changed extra worktrees"
OUT=$(house --plan --routine worktrees)
PLAN=$(receipt_from "$OUT")
TOKEN=$(token_from "$OUT")
OUT=$(house --apply --routine worktrees --receipt "$PLAN" --token "$TOKEN") ||
    fail "fresh plan did not retire the remaining multi-candidate worktree"
printf '%s\n' "$OUT" | grep -Fq 'removed=1' ||
    fail "fresh multi-candidate plan removed the wrong count"
for name in multi-a multi-b; do
    git -C "$REPO" show-ref --verify --quiet "refs/heads/$name" &&
        fail "multi-candidate branch survived recovery: $name"
done

printf 'Routine housekeeping tests: PASS\n'
