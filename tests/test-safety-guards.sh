#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-safety-guards-test.XXXXXX")
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
        printf '%s\n' 'FAIL: guarded safety-guard test cleanup' >&2
        status=1
    fi
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

home=$TEMP_DIR/home
persistent=$TEMP_DIR/persistent
fake_bin=$TEMP_DIR/bin
command_log=$TEMP_DIR/commands.log
mkdir -p "$home/harness/shell" "$persistent" "$fake_bin"
cp "$ROOT/shell/profile.sh" "$ROOT/shell/interactive.sh" \
    "$ROOT/shell/common-aliases.sh" "$ROOT/shell/safety-guards.sh" \
    "$home/harness/shell/"

for name in rm rsync find chmod chown qdel scancel; do
    sed "s/@COMMAND@/$name/g" >"$fake_bin/$name" <<'EOF'
#!/bin/sh
printf '@COMMAND@' >>"$HARNESS_SAFETY_COMMAND_LOG"
for arg in "$@"; do
    printf '|%s' "$arg" >>"$HARNESS_SAFETY_COMMAND_LOG"
done
printf '\n' >>"$HARNESS_SAFETY_COMMAND_LOG"
EOF
    chmod 755 "$fake_bin/$name"
done

noninteractive_type=$(env -u HARNESS_INTERACTIVE_LOADED \
    -u HARNESS_SAFETY_GUARDS_LOADED -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$home" PATH="$fake_bin:/usr/bin:/bin" \
    bash --noprofile --norc -c \
    '. "$HOME/harness/shell/profile.sh"; type -t rm')
[ "$noninteractive_type" = file ] || fail 'non-interactive shell received guards'

if ! env -u HARNESS_INTERACTIVE_LOADED -u HARNESS_SAFETY_GUARDS_LOADED \
    -u HARNESS_REMOTE_SESSION_LOADED \
    HOME="$home" HARNESS_PERSISTENT_ROOT="$persistent" \
    HARNESS_SAFETY_COMMAND_LOG="$command_log" PATH="$fake_bin:/usr/bin:/bin" \
    bash --noprofile --norc -ic '
        set -e
        . "$HOME/harness/shell/profile.sh"
        [ "$(type -t rm)" = function ]
        [ "$(type -t qdel)" = function ]
        [ "$(bash --noprofile --norc -c "type -t rm")" = file ]
        expect_refused() {
            set +e
            "$@"
            result=$?
            set -e
            [ "$result" -eq 64 ]
        }

        rm -- "$HOME/file with space"
        rm -rf "$HOME/safe-subtree"
        command rm -rf "$HOME"
        expect_refused rm -rf "$HOME"
        expect_refused rm -Rf /
        expect_refused rm --recursive "$HARNESS_PERSISTENT_ROOT"
        expect_refused rm -rf "$HOME/a" "$HOME/b" "$HOME/c" "$HOME/d" \
            "$HOME/e" "$HOME/f" "$HOME/g" "$HOME/h"

        rsync -a source/ destination/
        command rsync -a --delete source/ destination/
        expect_refused rsync -a --delete-after source/ destination/

        find "$HOME" -name core -print
        expect_refused find "$HOME" -name core -delete

        chmod 700 "$HOME/safe-subtree"
        chmod -R 700 "$HOME/safe-subtree"
        expect_refused chmod -R 700 "$HOME"
        chown -R owner:group "$HOME/safe-subtree"
        expect_refused chown --recursive owner:group "$HARNESS_PERSISTENT_ROOT"

        qdel -Wsuppress_email=-1 123.server
        qdel -W force 124.server
        expect_refused qdel 123.server 124.server
        scancel 456
        scancel -s TERM 457
        expect_refused scancel --user=owner
        expect_refused scancel -uowner 456
        expect_refused scancel 456 457
    ' >/dev/null 2>"$TEMP_DIR/refusals.err"; then
    sed -n '1,120p' "$TEMP_DIR/refusals.err" >&2
    fail 'interactive safety matrix'
fi

cat >"$TEMP_DIR/expected.log" <<EOF
rm|--|$home/file with space
rm|-rf|$home/safe-subtree
rm|-rf|$home
rsync|-a|source/|destination/
rsync|-a|--delete|source/|destination/
find|$home|-name|core|-print
chmod|700|$home/safe-subtree
chmod|-R|700|$home/safe-subtree
chown|-R|owner:group|$home/safe-subtree
qdel|-Wsuppress_email=-1|123.server
qdel|-W|force|124.server
scancel|456
scancel|-s|TERM|457
EOF
cmp "$command_log" "$TEMP_DIR/expected.log" >/dev/null ||
    fail 'native pass-through or refusal log'
[ "$(grep -c '^harness safety: refused ' "$TEMP_DIR/refusals.err")" -eq 12 ] ||
    fail 'refusal diagnostics'
grep -F 'use harness guarded-delete' "$TEMP_DIR/refusals.err" >/dev/null ||
    fail 'safe deletion route diagnostic'

printf '%s\n' 'PASS: interactive destructive-command safeguards'
