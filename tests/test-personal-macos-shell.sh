#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-personal-macos-shell-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "$TEMP_BASE" "$TEMP_DIR" \
            "$TEMP_BASE" >/dev/null || status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

home=$TEMP_DIR/home
fake_bin=$TEMP_DIR/bin
fake_prefix=$TEMP_DIR/homebrew
mkdir -p "$home/.local/bin" "$home/.venv/research/bin" "$fake_bin" \
    "$fake_prefix/bin" "$fake_prefix/etc/profile.d"
cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
[ "${1:-}" = -s ] || exit 2
echo Darwin
EOF
cat >"$fake_prefix/bin/brew" <<'EOF'
#!/bin/sh
[ "$1:$2" = shellenv:bash ] || exit 2
printf '%s\n' \
    "export HOMEBREW_PREFIX='$FAKE_PREFIX'" \
    "export PATH='$FAKE_PREFIX/bin':\"\$PATH\""
EOF
cat >"$fake_prefix/etc/profile.d/bash_completion.sh" <<'EOF'
HARNESS_TEST_COMPLETION=loaded
export HARNESS_TEST_COMPLETION
EOF
cat >"$home/.venv/research/bin/activate" <<'EOF'
HARNESS_TEST_ACTIVATE=research
export HARNESS_TEST_ACTIVATE
EOF
chmod 755 "$fake_bin/uname" "$fake_prefix/bin/brew"
chmod 600 "$fake_prefix/etc/profile.d/bash_completion.sh" \
    "$home/.venv/research/bin/activate"

# Replace only the fixed Apple-Silicon brew path in a private test image; all
# other profile bytes and the sourced interactive file remain repository data.
sed "s#/opt/homebrew/bin/brew#$fake_prefix/bin/brew#" \
    "$ROOT/shell/profile.sh" >"$TEMP_DIR/profile.sh"
profile_output=$(HOME="$home" FAKE_PREFIX="$fake_prefix" \
    PATH="$fake_bin:/usr/bin:/bin" bash --noprofile --norc -c '
        . "$1"
        printf "%s|%s|%s|%s\n" "$HOMEBREW_PREFIX" "$HOMEBREW_NO_ENV_HINTS" \
            "$LANG" "$UV_VENV_ROOT"
        case $PATH in "$HOME/.local/bin:"*) exit 0 ;; *) exit 1 ;; esac
    ' bash "$TEMP_DIR/profile.sh") || fail "Darwin profile behavior"
[ "$profile_output" = "$fake_prefix|1|en_US.UTF-8|$home/.venv" ] ||
    fail "Darwin profile values"

interactive_output=$(HOME="$home" UV_VENV_ROOT="$home/.venv" \
    HOMEBREW_PREFIX="$fake_prefix" PATH="$fake_bin:/usr/bin:/bin" \
    HARNESS_INTERACTIVE_LOADED='' \
    bash --noprofile --norc -c '
        . "$1"
        activate research
        printf "%s|%s\n" "$HARNESS_TEST_COMPLETION" "$HARNESS_TEST_ACTIVATE"
        if activate ../escape >/dev/null 2>&1; then exit 1; fi
    ' bash "$ROOT/shell/interactive.sh") || fail "Darwin interactive behavior"
[ "$interactive_output" = 'loaded|research' ] || fail "completion or activate behavior"

echo 'personal macOS shell tests: PASS'
