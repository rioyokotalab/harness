#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
RULES=$ROOT/.codex/rules/default.rules
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/guarded-delete-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

fail() {
    echo "FAIL: $*" >&2
    exit 1
}
file_mode() {
    case $(uname -s) in Darwin) stat -f %Lp "$1" ;; *) stat -c %a "$1" ;; esac
}

token_from() {
    sed -n 's/^TOKEN sha256=//p' "$1"
}

expect_failure() {
    expected=$1
    output=$2
    shift 2
    if "$@" >"$output" 2>&1; then
        fail "command unexpectedly succeeded: $*"
    fi
    grep -F -- "$expected" "$output" >/dev/null ||
        fail "missing failure evidence '$expected': $*"
}

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" \
            "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo "FAIL: guarded-delete suite cleanup" >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

sh -n "$ROOT/shared/skills/guarded-bulk-delete/scripts/guarded-delete" ||
    fail "guarded-delete shell syntax"
grep -F 'never pipe them directly to a shell' \
    "$ROOT/shared/skills/guarded-bulk-delete/SKILL.md" >/dev/null ||
    fail "guarded-delete installer provenance gate"
grep -F 'Owner approval alone is insufficient.' \
    "$ROOT/shared/skills/guarded-bulk-delete/SKILL.md" >/dev/null ||
    fail "guarded-delete installer approval boundary"
sh -n "$CLEANUP" || fail "guarded test cleanup shell syntax"

# Exercise the Darwin adapter shapes on Linux CI without weakening production
# platform detection.  These fakes translate BSD command forms back to the
# GNU fixture tools while preserving the guard's plan/apply behavior.
if [ "$(uname -s)" != Darwin ]; then
darwin_bin=$TEST_ROOT/darwin-bin
mkdir -p "$darwin_bin" "$TEST_ROOT/root/darwin-target/nested"
printf '%s\n' delete >"$TEST_ROOT/root/darwin-target/nested/file"
cat >"$darwin_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' Darwin
EOF
cat >"$darwin_bin/dscacheutil" <<'EOF'
#!/bin/sh
printf 'dir: %s\n' "$HOME"
EOF
cat >"$darwin_bin/realpath" <<'EOF'
#!/bin/sh
exec /usr/bin/realpath -e -- "$1"
EOF
cat >"$darwin_bin/stat" <<'EOF'
#!/bin/sh
[ "$1" = -f ] || exit 2
format=$2
path=$3
case "$format" in
    %d:%i) exec /usr/bin/stat -Lc '%d:%i' -- "$path" ;;
    %u) exec /usr/bin/stat -c '%u' -- "$path" ;;
    %Lp) exec /usr/bin/stat -c '%a' -- "$path" ;;
    %z) exec /usr/bin/stat -c '%s' -- "$path" ;;
    *) exit 2 ;;
esac
EOF
cat >"$darwin_bin/find" <<'EOF'
#!/bin/sh
[ "$1" = -x ] || exit 2
target=$2
shift 2
case "$*" in
    '-exec stat -f %z {} +') exec /usr/bin/find "$target" -xdev -printf '%s\n' ;;
    '-depth -delete') exec /usr/bin/find "$target" -xdev -depth -delete ;;
    *) exit 2 ;;
esac
EOF
chmod 700 "$darwin_bin"/*
darwin_manifest=$TEST_ROOT/darwin.manifest
env PATH="$darwin_bin:$PATH" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$darwin_manifest" -- \
    "$TEST_ROOT/root/darwin-target" >"$TEST_ROOT/darwin.plan"
darwin_token=$(token_from "$TEST_ROOT/darwin.plan")
[ -n "$darwin_token" ] || fail "Darwin plan token"
env PATH="$darwin_bin:$PATH" "$HARNESS" guarded-delete apply \
    --manifest "$darwin_manifest" --token "$darwin_token" \
    >"$TEST_ROOT/darwin.apply"
[ ! -e "$TEST_ROOT/root/darwin-target" ] || fail "Darwin target remains"
grep 'VERIFIED protected_anchors=unchanged targets=absent' \
    "$TEST_ROOT/darwin.apply" >/dev/null || fail "Darwin verification marker"
fi

mkdir -p "$TEST_ROOT/internal/fake-home/delete-me/nested" "$TEST_ROOT/internal/state"
printf '%s\n' delete >"$TEST_ROOT/internal/fake-home/delete-me/nested/file"
env HOME="$TEST_ROOT/internal/fake-home" HARNESS_ROOT="$ROOT" sh -c '
    . "$1"
    guarded_delete_tree "$2" "$3" "$4"
' sh "$ROOT/libexec/harness-common" "$TEST_ROOT/internal/fake-home" \
    "$TEST_ROOT/internal/fake-home/delete-me" "$TEST_ROOT/internal/state" \
    >"$TEST_ROOT/internal-delete.out"
[ ! -e "$TEST_ROOT/internal/fake-home/delete-me" ] ||
    fail "internal guarded deletion left its target"
[ -d "$TEST_ROOT/internal/fake-home" ] ||
    fail "internal guarded deletion removed fake HOME"
grep 'VERIFIED protected_anchors=unchanged targets=absent' \
    "$TEST_ROOT/internal-delete.out" >/dev/null ||
    fail "internal guarded deletion verification marker"

expect_failure 'target is or contains current HOME' \
    "$TEST_ROOT/internal-home.out" env HOME="$TEST_ROOT/internal/fake-home" \
    HARNESS_ROOT="$ROOT" sh -c '
        . "$1"
        guarded_delete_tree "$2" "$3" "$4"
    ' sh "$ROOT/libexec/harness-common" "$TEST_ROOT/internal" \
    "$TEST_ROOT/internal/fake-home" "$TEST_ROOT/internal/state"
[ -d "$TEST_ROOT/internal/fake-home" ] ||
    fail "internal guarded deletion removed fake HOME on refusal"

home_parent=${HOME%/*}
[ -n "$home_parent" ] || home_parent=/
expect_failure '--within is too broad and contains a protected anchor' \
    "$TEST_ROOT/cleanup-home.out" "$CLEANUP" "$HARNESS" "$home_parent" "$HOME" \
    "${TMPDIR:-/tmp}"
[ -d "$HOME" ] || fail "adversarial cleanup removed the account home"

case ${HARNESS_PORTABLE_CI:-0} in
    0)
        for command in \
            'rm -rf /home/rioyokota' \
            'rm -r generated' \
            'rm -f -r cache' \
            '/bin/rm -Rf build' \
            '/usr/bin/rm --recursive output'
        do
            # These fixed test strings contain no expansion and are split intentionally.
            # shellcheck disable=SC2086
            set -- $command
            codex execpolicy check --pretty --rules "$RULES" -- "$@" \
                >"$TEST_ROOT/rule.out" 2>/dev/null || fail "execpolicy check: $command"
            grep '"decision": "forbidden"' "$TEST_ROOT/rule.out" >/dev/null ||
                fail "execpolicy did not forbid: $command"
        done
        codex execpolicy check --pretty --rules "$RULES" -- rm -f exact-file \
            >"$TEST_ROOT/rule-safe.out" 2>/dev/null || fail "non-recursive execpolicy check"
        if grep '"decision": "forbidden"' "$TEST_ROOT/rule-safe.out" >/dev/null; then
            fail "execpolicy forbade exact non-recursive removal"
        fi
        ;;
    1)
        printf '%s\n' 'SKIP Codex exec-policy smoke: portable CI has no declared Codex client'
        ;;
    *)
        fail "HARNESS_PORTABLE_CI must be 0 or 1"
        ;;
esac

mkdir -p "$TEST_ROOT/root/success target/nested" "$TEST_ROOT/root/keep"
printf '%s\n' delete >"$TEST_ROOT/root/success target/nested/file"
printf '%s\n' keep >"$TEST_ROOT/root/keep/file"
success_manifest="$TEST_ROOT/success manifest"
(cd "$ROOT" && "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$success_manifest" -- \
    "$TEST_ROOT/root/success target") >"$TEST_ROOT/success.plan"
success_token=$(token_from "$TEST_ROOT/success.plan")
[ -n "$success_token" ] || fail "success plan token"
[ "$(file_mode "$success_manifest")" = 600 ] || fail "manifest mode"
grep -F "NEXT harness guarded-delete apply --manifest '$success_manifest' --token $success_token" \
    "$TEST_ROOT/success.plan" >/dev/null || fail "shell-quoted next command"
(cd "$ROOT" && "$HARNESS" guarded-delete apply \
    --manifest "$success_manifest" --token "$success_token") \
    >"$TEST_ROOT/success.apply"
[ ! -e "$TEST_ROOT/root/success target" ] || fail "success target remains"
[ -f "$TEST_ROOT/root/keep/file" ] || fail "success removed retained sibling"
grep 'VERIFIED protected_anchors=unchanged targets=absent' \
    "$TEST_ROOT/success.apply" >/dev/null || fail "success verification marker"

expect_failure 'HOME differs from the account database' "$TEST_ROOT/home.out" \
    env HOME=/tmp "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/home.manifest" -- \
    "$TEST_ROOT/root/keep"
[ ! -e "$TEST_ROOT/home.manifest" ] || fail "HOME mismatch created manifest"

mkdir -p "$TEST_ROOT/fake-bin" "$TEST_ROOT/aliased-real/account" \
    "$TEST_ROOT/aliased-real/account/child" "$TEST_ROOT/aliased-other/account" \
    "$TEST_ROOT/root/alias-success" \
    "$TEST_ROOT/root/alias-drift"
ln -s "$TEST_ROOT/aliased-real" "$TEST_ROOT/aliased-home-root"
printf '%s\n' \
    '#!/bin/sh' \
    'if [ "$1" = passwd ]; then' \
    '    printf "fake:x:%s:1:fake:%s:/bin/sh\\n" "$(id -u)" "$FAKE_ACCOUNT_HOME"' \
    'else' \
    '    exec /usr/bin/getent "$@"' \
    'fi' >"$TEST_ROOT/fake-bin/getent"
cat >"$TEST_ROOT/fake-bin/dscacheutil" <<'EOF'
#!/bin/sh
printf 'dir: %s\n' "$FAKE_ACCOUNT_HOME"
EOF
chmod 700 "$TEST_ROOT/fake-bin/getent" "$TEST_ROOT/fake-bin/dscacheutil"
alias_home=$TEST_ROOT/aliased-home-root/account
alias_path=$TEST_ROOT/fake-bin:$PATH

alias_manifest=$TEST_ROOT/alias.manifest
env PATH="$alias_path" HOME="$alias_home" FAKE_ACCOUNT_HOME="$alias_home" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$alias_manifest" -- "$TEST_ROOT/root/alias-success" \
    >"$TEST_ROOT/alias.plan"
alias_token=$(token_from "$TEST_ROOT/alias.plan")
env PATH="$alias_path" HOME="$alias_home" FAKE_ACCOUNT_HOME="$alias_home" \
    "$HARNESS" guarded-delete apply --manifest "$alias_manifest" \
    --token "$alias_token" >"$TEST_ROOT/alias.apply"
[ ! -e "$TEST_ROOT/root/alias-success" ] || fail "aliased-home apply left target"

expect_failure '--within is too broad and contains a protected anchor' \
    "$TEST_ROOT/alias-protected.out" env PATH="$alias_path" HOME="$alias_home" \
    FAKE_ACCOUNT_HOME="$alias_home" "$HARNESS" guarded-delete plan \
    --within "$alias_home" --manifest "$TEST_ROOT/alias-protected.manifest" -- \
    "$alias_home/child"

alias_drift_manifest=$TEST_ROOT/alias-drift.manifest
env PATH="$alias_path" HOME="$alias_home" FAKE_ACCOUNT_HOME="$alias_home" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$alias_drift_manifest" -- "$TEST_ROOT/root/alias-drift" \
    >"$TEST_ROOT/alias-drift.plan"
alias_drift_token=$(token_from "$TEST_ROOT/alias-drift.plan")
unlink "$TEST_ROOT/aliased-home-root"
ln -s "$TEST_ROOT/aliased-other" "$TEST_ROOT/aliased-home-root"
expect_failure 'canonical account home changed since plan' \
    "$TEST_ROOT/alias-drift.out" env PATH="$alias_path" HOME="$alias_home" \
    FAKE_ACCOUNT_HOME="$alias_home" "$HARNESS" guarded-delete apply \
    --manifest "$alias_drift_manifest" --token "$alias_drift_token"
[ -d "$TEST_ROOT/root/alias-drift" ] || fail "aliased-home drift deleted target"

expect_failure '--within is too broad and contains a protected anchor' \
    "$TEST_ROOT/protected-home.out" "$HARNESS" guarded-delete plan \
    --within "$home_parent" --manifest "$TEST_ROOT/protected-home.manifest" -- "$HOME"
[ -d "$HOME" ] || fail "protected home disappeared"

expect_failure 'target is not a strict descendant of --within' \
    "$TEST_ROOT/root-equality.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/root-equality.manifest" -- \
    "$TEST_ROOT/root"

mkdir -p "$TEST_ROOT/root/cwd-target/inside"
expect_failure 'target is or contains a protected anchor' "$TEST_ROOT/cwd.out" \
    sh -c 'cd "$1" && exec "$2" guarded-delete plan --within "$3" --manifest "$4" -- "$5"' \
    sh "$TEST_ROOT/root/cwd-target/inside" "$HARNESS" "$TEST_ROOT/root" \
    "$TEST_ROOT/cwd.manifest" "$TEST_ROOT/root/cwd-target"

mkdir -p "$TEST_ROOT/root/manifest-target"
expect_failure 'manifest cannot be stored inside a deletion target' \
    "$TEST_ROOT/manifest-inside.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/root/manifest-target/delete.manifest" -- \
    "$TEST_ROOT/root/manifest-target"

# A quota-exhausted or faulty destination may accept creation but persist zero
# bytes. Even when the copy command itself reports success, planning must reject
# the byte/hash mismatch and must never publish a destination manifest.
mkdir -p "$TEST_ROOT/root/persist-failure" "$TEST_ROOT/fake-persist-bin"
cat >"$TEST_ROOT/fake-persist-bin/cp" <<'EOF'
#!/bin/sh
case "$1" in --) shift ;; esac
: >"$2"
exit 0
EOF
chmod 700 "$TEST_ROOT/fake-persist-bin/cp"
expect_failure 'persisted manifest differs from planned content' \
    "$TEST_ROOT/persist-failure.out" env \
    PATH="$TEST_ROOT/fake-persist-bin:$PATH" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/persist-failure.manifest" -- \
    "$TEST_ROOT/root/persist-failure"
[ ! -e "$TEST_ROOT/persist-failure.manifest" ] ||
    fail "failed persistence published a manifest"
[ -d "$TEST_ROOT/root/persist-failure" ] ||
    fail "failed persistence removed its target"

mkdir -p "$TEST_ROOT/root/real-target"
ln -s "$TEST_ROOT/root/real-target" "$TEST_ROOT/root/symlink-target"
expect_failure 'symlink directories are not recursive-delete targets' \
    "$TEST_ROOT/symlink.out" "$HARNESS" guarded-delete plan \
    --within "$TEST_ROOT/root" --manifest "$TEST_ROOT/symlink.manifest" -- \
    "$TEST_ROOT/root/symlink-target"

mkdir -p "$TEST_ROOT/root/unreadable-target/private"
printf '%s\n' hidden >"$TEST_ROOT/root/unreadable-target/private/file"
chmod 000 "$TEST_ROOT/root/unreadable-target/private"
expect_failure 'cannot inventory every target entry' "$TEST_ROOT/unreadable.out" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/unreadable.manifest" -- \
    "$TEST_ROOT/root/unreadable-target"
chmod 700 "$TEST_ROOT/root/unreadable-target/private"
[ ! -e "$TEST_ROOT/unreadable.manifest" ] || fail "partial inventory created manifest"

mkdir -p "$TEST_ROOT/root/overlap/child"
expect_failure 'overlapping deletion targets are forbidden' "$TEST_ROOT/overlap.out" \
    "$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$TEST_ROOT/overlap.manifest" -- \
    "$TEST_ROOT/root/overlap" "$TEST_ROOT/root/overlap/child"

mkdir -p "$TEST_ROOT/root/token-target"
token_manifest=$TEST_ROOT/token.manifest
"$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$token_manifest" -- "$TEST_ROOT/root/token-target" \
    >"$TEST_ROOT/token.plan"
expect_failure 'manifest token mismatch; re-plan' "$TEST_ROOT/token.out" \
    "$HARNESS" guarded-delete apply --manifest "$token_manifest" \
    --token 0000000000000000000000000000000000000000000000000000000000000000
[ -d "$TEST_ROOT/root/token-target" ] || fail "bad token deleted target"

mkdir -p "$TEST_ROOT/root/drift-target"
drift_manifest=$TEST_ROOT/drift.manifest
"$HARNESS" guarded-delete plan --within "$TEST_ROOT/root" \
    --manifest "$drift_manifest" -- "$TEST_ROOT/root/drift-target" \
    >"$TEST_ROOT/drift.plan"
drift_token=$(token_from "$TEST_ROOT/drift.plan")
printf '%s\n' changed >"$TEST_ROOT/root/drift-target/new-file"
expect_failure 'target entry count changed; re-plan' "$TEST_ROOT/drift.out" \
    "$HARNESS" guarded-delete apply --manifest "$drift_manifest" \
    --token "$drift_token"
[ -f "$TEST_ROOT/root/drift-target/new-file" ] || fail "drift failure deleted target"

echo 'guarded-delete tests: PASS'
