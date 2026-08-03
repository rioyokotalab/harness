#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-owner-alias-test.XXXXXX")

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
mkdir -m 700 "$STATE"

house() {
    selected_repo=$1
    shift
    HARNESS_TESTING=1 \
    HARNESS_TEST_HOUSEKEEPING_REPO="$selected_repo" \
    HARNESS_TEST_RECEIPT_DIR="$STATE" \
    HARNESS_TEST_WORKTREE_BOUNDARIES="$TEMP_BASE" \
        "$HARNESS" housekeeping "$@"
}

init_repo() {
    repository=$1
    remote=$2
    mkdir -p "$repository"
    git -C "$repository" init -q
    git -C "$repository" config user.email owner-alias@example.invalid
    git -C "$repository" config user.name owner-alias-test
    printf 'base\n' >"$repository/tracked"
    printf 'ledger\n' >"$repository/TODO.md"
    git -C "$repository" add tracked TODO.md
    git -C "$repository" commit -qm base
    git -C "$repository" branch -M main
    git -C "$repository" remote add origin "$remote"
    git -C "$repository" update-ref refs/remotes/origin/main \
        "$(git -C "$repository" rev-parse main)"
}

archive_one() {
    legacy=$1
    transaction=$2
    branch=$3
    git -C "$legacy" checkout -qb "$branch"
    printf '%s\n' "$transaction" >>"$legacy/tracked"
    git -C "$legacy" commit -qam "$transaction"
    tip=$(git -C "$legacy" rev-parse HEAD)
    items=$TEST_ROOT/$transaction.tsv
    printf '%s\t%s\n' "$branch" "$tip" >"$items"
    chmod 600 "$items"
    output=$(house "$legacy" --archive --items "$items" \
        --transaction "$transaction" --source owner-alias-test)
    printf '%s\n' "$output" | sed -n 's/.*receipt=\([^ ]*\).*/\1/p'
}

create_alias() {
    source=$1
    shift
    house "$COORDINATOR" --create-owner-alias \
        --source-receipt "$source" \
        --owner-repo "$OWNER" \
        --legacy-origin "$OWNER" \
        --mapping-evidence-commit "$EVIDENCE_COMMIT" \
        --mapping-evidence-path owner-map.tsv "$@"
}

COORDINATOR=$TEST_ROOT/coordinator
OWNER=$TEST_ROOT/owner
LEGACY=$TEST_ROOT/legacy
RELOC_OWNER=$TEST_ROOT/relocated-owner
RELOC_LEGACY=$TEST_ROOT/relocated-legacy
RETIRED_OWNER=$TEST_ROOT/retired-owner
init_repo "$COORDINATOR" git@github.com:example/coordinator.git
init_repo "$OWNER" git@github.com:example/archive-owner.git
init_repo "$RELOC_OWNER" git@github.com:example/relocated-owner.git
git clone -q "$OWNER" "$LEGACY"
git -C "$LEGACY" config user.email owner-alias@example.invalid
git -C "$LEGACY" config user.name owner-alias-test

cat >"$COORDINATOR/owner-map.tsv" <<EOF
legacy_repository	legacy_origin	owner_repository	method
$LEGACY	$OWNER	$OWNER	direct-local-origin-v1
$RELOC_LEGACY	$RETIRED_OWNER	$RELOC_OWNER	authorized-single-relocation-v1
EOF
git -C "$COORDINATOR" add owner-map.tsv
git -C "$COORDINATOR" commit -qm 'record owner map'
EVIDENCE_COMMIT=$(git -C "$COORDINATOR" rev-parse HEAD)
git -C "$COORDINATOR" update-ref refs/remotes/origin/main "$EVIDENCE_COMMIT"

RECEIPT_ONE=$(archive_one "$LEGACY" alias-one archived-one)
[ -f "$RECEIPT_ONE" ] || fail "first source receipt missing"

# Publication is fail-closed for origin mismatch, symlinks, main drift, and
# interruptions on either side of the atomic link.
OTHER=$TEST_ROOT/other-owner
init_repo "$OTHER" git@github.com:example/other-owner.git
git -C "$LEGACY" remote set-url origin "$OTHER"
if create_alias "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "changed local origin was accepted"
fi
git -C "$LEGACY" remote set-url origin ../owner
if create_alias "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "relative local origin was accepted"
fi
OWNER_LINK=$TEST_ROOT/owner-link
ln -s "$OWNER" "$OWNER_LINK"
git -C "$LEGACY" remote set-url origin "$OWNER_LINK"
if create_alias "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "symlinked local origin was accepted"
fi
git -C "$LEGACY" remote set-url origin "$OWNER"

if HARNESS_TEST_OWNER_ALIAS_MAIN_DRIFT=1 create_alias "$RECEIPT_ONE" \
    >/dev/null 2>&1; then
    fail "protected-main creation drift was accepted"
fi
if HARNESS_TEST_OWNER_ALIAS_INTERRUPT=before create_alias "$RECEIPT_ONE" \
    >/dev/null 2>&1; then
    fail "pre-publication interruption was accepted"
fi
[ ! -d "$STATE/owner-aliases" ] || \
    [ -z "$(find "$STATE/owner-aliases" -type f -print -quit)" ] ||
    fail "pre-publication failure left an alias"
if HARNESS_TEST_OWNER_ALIAS_INTERRUPT=after create_alias "$RECEIPT_ONE" \
    >/dev/null 2>&1; then
    fail "post-publication interruption was accepted"
fi
[ -z "$(find "$STATE/owner-aliases" -type f -print -quit)" ] ||
    fail "post-publication rollback left an alias"

OUT=$(create_alias "$RECEIPT_ONE") || fail "owner alias creation failed"
ALIAS_ONE=$(printf '%s\n' "$OUT" | sed -n 's/.*alias=\([^ ]*\).*/\1/p')
[ -f "$ALIAS_ONE" ] || fail "owner alias artifact missing"
[ "$(stat -c %a "$ALIAS_ONE")" = 600 ] || fail "owner alias mode changed"
[ "$(stat -c %h "$ALIAS_ONE")" = 1 ] || fail "owner alias link count changed"
if create_alias "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "duplicate owner alias publication was accepted"
fi
printf 'unknown\n' >"$STATE/owner-aliases/unknown.tmp"
chmod 600 "$STATE/owner-aliases/unknown.tmp"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "unknown owner-alias artifact was accepted"
fi
unlink "$STATE/owner-aliases/unknown.tmp"

mv "$LEGACY" "$LEGACY.hidden"
house "$OWNER" --audit --receipt "$RECEIPT_ONE" | grep -Fq 'status=pass' ||
    fail "absent-root alias audit failed"
OUT=$(house "$COORDINATOR" --plan --routine archives) ||
    fail "alias-aware archive report failed"
printf '%s\n' "$OUT" | grep -Fq 'aliases=1 unbound_aliases=0' ||
    fail "archive report alias counts changed"

# Immutable input, schema, mode, link, remote, fast-forward, and divergence
# invariants are revalidated on every fallback.
cp "$RECEIPT_ONE" "$TEST_ROOT/source.saved"
printf 'changed=yes\n' >>"$RECEIPT_ONE"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "changed source receipt was accepted"
fi
mv "$TEST_ROOT/source.saved" "$RECEIPT_ONE"
chmod 600 "$RECEIPT_ONE"

BUNDLE_ONE=$(sed -n 's/^bundle=//p' "$RECEIPT_ONE")
cp "$BUNDLE_ONE" "$TEST_ROOT/bundle.saved"
printf 'changed\n' >>"$BUNDLE_ONE"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "changed source bundle was accepted"
fi
mv "$TEST_ROOT/bundle.saved" "$BUNDLE_ONE"
chmod 600 "$BUNDLE_ONE"

cp "$ALIAS_ONE" "$TEST_ROOT/alias.saved"
python3 -B - "$ALIAS_ONE" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
value = json.loads(path.read_text())
value["unknown"] = True
path.write_text(json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n")
PY
chmod 600 "$ALIAS_ONE"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "unknown owner alias field was accepted"
fi
mv "$TEST_ROOT/alias.saved" "$ALIAS_ONE"
chmod 600 "$ALIAS_ONE"
chmod 640 "$ALIAS_ONE"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "unsafe owner alias mode was accepted"
fi
chmod 600 "$ALIAS_ONE"
ln "$ALIAS_ONE" "$TEST_ROOT/alias-hardlink"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "hard-linked owner alias was accepted"
fi
unlink "$TEST_ROOT/alias-hardlink"

git -C "$OWNER" remote set-url origin git@github.com:example/wrong-owner.git
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "changed terminal remote was accepted"
fi
git -C "$OWNER" remote set-url origin git@github.com:example/archive-owner.git
printf 'fast-forward\n' >>"$OWNER/tracked"
git -C "$OWNER" commit -qam fast-forward
FAST_FORWARD=$(git -C "$OWNER" rev-parse HEAD)
git -C "$OWNER" update-ref refs/remotes/origin/main "$FAST_FORWARD"
house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null ||
    fail "protected-main fast-forward invalidated an alias"
OWNER_TREE=$(git -C "$OWNER" rev-parse 'HEAD^{tree}')
DIVERGED=$(printf 'diverged\n' | git -C "$OWNER" commit-tree "$OWNER_TREE")
git -C "$OWNER" update-ref refs/remotes/origin/main "$DIVERGED"
if house "$OWNER" --audit --receipt "$RECEIPT_ONE" >/dev/null 2>&1; then
    fail "protected-main divergence was accepted"
fi
git -C "$OWNER" update-ref refs/remotes/origin/main "$FAST_FORWARD"

# Generation creation and two-generation compaction continue through the same
# resolver after the pathname owner disappears.
touch -d '40 days ago' "$RECEIPT_ONE"
OUT=$(house "$COORDINATOR" --create-generation) ||
    fail "alias-backed generation creation failed"
printf '%s\n' "$OUT" | grep -Fq 'restore=pass status=verified' ||
    fail "alias-backed generation omitted restore proof"

mv "$LEGACY.hidden" "$LEGACY"
git -C "$LEGACY" checkout -q main
RECEIPT_TWO=$(archive_one "$LEGACY" alias-two archived-two)
OUT=$(create_alias "$RECEIPT_TWO") || fail "second owner alias creation failed"
ALIAS_TWO=$(printf '%s\n' "$OUT" | sed -n 's/.*alias=\([^ ]*\).*/\1/p')
[ -f "$ALIAS_TWO" ] || fail "second owner alias artifact missing"
mv "$LEGACY" "$LEGACY.hidden"
touch -d '40 days ago' "$RECEIPT_TWO"
OUT=$(house "$COORDINATOR" --create-generation) ||
    fail "second alias-backed generation failed"
printf '%s\n' "$OUT" | grep -Fq 'restore=pass status=verified' ||
    fail "second alias-backed generation omitted restore proof"

OUT=$(house "$OWNER" --plan-archive-compaction --source-receipt "$RECEIPT_ONE") ||
    fail "alias-backed compaction plan failed"
COMPACTION=$(printf '%s\n' "$OUT" | sed -n 's/^  RECEIPT path=\([^ ]*\) token=.*/\1/p')
TOKEN=$(printf '%s\n' "$OUT" | sed -n 's/^  RECEIPT path=[^ ]* token=\([0-9a-f]*\).*/\1/p')
house "$OWNER" --apply-archive-compaction --receipt "$COMPACTION" --token "$TOKEN" \
    | grep -Fq 'status=verified' || fail "alias-backed compaction apply failed"
[ ! -e "$BUNDLE_ONE" ] || fail "compacted alias source bundle survived"
OUT=$(house "$OWNER" --audit --receipt "$RECEIPT_ONE") ||
    fail "generation-only alias audit failed"
printf '%s\n' "$OUT" | grep -Fq 'retired=1 generations=2' ||
    fail "generation-only alias coverage changed"
OUT=$(house "$COORDINATOR" --plan --routine archives) ||
    fail "final mixed archive report failed"
printf '%s\n' "$OUT" | grep -Fq 'aliases=2 unbound_aliases=0' ||
    fail "final archive report alias counts changed"

# The owner-authorized bridge accepts exactly one retired predecessor and can
# publish from immutable mapping evidence after the legacy root is already
# absent. It never reconstructs or rewrites that root.
STATE=$TEST_ROOT/relocation-state
mkdir -m 700 "$STATE"
git clone -q "$RELOC_OWNER" "$RELOC_LEGACY"
git -C "$RELOC_LEGACY" config user.email owner-alias@example.invalid
git -C "$RELOC_LEGACY" config user.name owner-alias-test
git -C "$RELOC_LEGACY" remote set-url origin "$RETIRED_OWNER"
RELOC_RECEIPT_ONE=$(archive_one "$RELOC_LEGACY" relocate-one relocated-one)
OUT=$(house "$COORDINATOR" --create-owner-alias \
    --source-receipt "$RELOC_RECEIPT_ONE" \
    --owner-repo "$RELOC_OWNER" \
    --legacy-origin "$RETIRED_OWNER" \
    --mapping-evidence-commit "$EVIDENCE_COMMIT" \
    --mapping-evidence-path owner-map.tsv) ||
    fail "live-root relocation alias creation failed"
printf '%s\n' "$OUT" | grep -Fq 'method=authorized-single-relocation-v1' ||
    fail "relocation method changed"

git -C "$RELOC_LEGACY" checkout -q main
RELOC_RECEIPT_TWO=$(archive_one "$RELOC_LEGACY" relocate-two relocated-two)
mv "$RELOC_LEGACY" "$RELOC_LEGACY.hidden"
OUT=$(house "$COORDINATOR" --create-owner-alias \
    --source-receipt "$RELOC_RECEIPT_TWO" \
    --owner-repo "$RELOC_OWNER" \
    --legacy-origin "$RETIRED_OWNER" \
    --mapping-evidence-commit "$EVIDENCE_COMMIT" \
    --mapping-evidence-path owner-map.tsv) ||
    fail "absent-root relocation alias creation failed"
house "$RELOC_OWNER" --audit --receipt "$RELOC_RECEIPT_ONE" >/dev/null ||
    fail "live-proven relocation alias did not survive root absence"
house "$RELOC_OWNER" --audit --receipt "$RELOC_RECEIPT_TWO" >/dev/null ||
    fail "evidence-proven absent-root relocation alias failed"
OUT=$(house "$COORDINATOR" --plan --routine archives) ||
    fail "relocation alias report failed"
printf '%s\n' "$OUT" | grep -Fq 'aliases=2 unbound_aliases=0' ||
    fail "relocation alias report counts changed"

printf 'PASS: housekeeping owner aliases\n'
