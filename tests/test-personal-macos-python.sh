#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
HARNESS=$ROOT/bin/harness
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEMP_DIR=$(mktemp -d "$TEMP_BASE/harness-macos-python-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEMP_DIR" "$TEMP_BASE" >/dev/null || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
fail() { echo "FAIL: $*" >&2; exit 1; }

PUBLIC=$TEMP_DIR/public
HOME_DIR=$TEMP_DIR/home
PRIVATE=$HOME_DIR/.config/harness/private
FAKE_BIN=$TEMP_DIR/fake-bin
mkdir -p "$PUBLIC" "$HOME_DIR/.ssh" "$PRIVATE/hosts" "$FAKE_BIN"
cp -R "$ROOT/bin" "$ROOT/libexec" "$ROOT/profiles" "$ROOT/tools" "$ROOT/shared" "$PUBLIC/"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/companion.conf" "$PRIVATE/companion.conf"
cp "$ROOT/tests/fixtures/personal-macos/private-v1/hosts/mac-test-pilot.conf" \
    "$PRIVATE/hosts/mac-test-pilot.conf"
chmod 700 "$HOME_DIR" "$HOME_DIR/.ssh" "$HOME_DIR/.config" \
    "$HOME_DIR/.config/harness" "$PRIVATE" "$PRIVATE/hosts"
chmod 600 "$PRIVATE/companion.conf" "$PRIVATE/hosts/mac-test-pilot.conf"
git -C "$PRIVATE" init -q -b main
git -C "$PRIVATE" config user.name mac-test
git -C "$PRIVATE" config user.email mac-test.invalid
git -C "$PRIVATE" add .
git -C "$PRIVATE" commit -q -m private
chmod 700 "$PRIVATE/.git"
git -C "$PUBLIC" init -q -b main
git -C "$PUBLIC" config user.name mac-test
git -C "$PUBLIC" config user.email mac-test.invalid
git -C "$PUBLIC" add .
git -C "$PUBLIC" commit -q -m public

cat >"$FAKE_BIN/uname" <<'EOF'
#!/bin/sh
case "${1:-}" in -s) echo Darwin ;; -m) echo arm64 ;; *) echo Darwin ;; esac
EOF
cat >"$FAKE_BIN/stat" <<'EOF'
#!/bin/sh
case "${1:-}:${2:-}" in
    -f:%u) format=%u ;; -f:%Lp) format=%a ;; -f:%l) format=%h ;;
    -f:%z) format=%s ;; -f:%d:%i) format=%d:%i ;;
    *) exec /usr/bin/stat "$@" ;;
esac
shift 2; [ "${1:-}" != -- ] || shift
exec /usr/bin/stat -c "$format" -- "$@"
EOF
cat >"$FAKE_BIN/find" <<'EOF'
#!/bin/sh
[ "${1:-}" != -x ] || shift
exec /usr/bin/find "$@"
EOF
cat >"$FAKE_BIN/dscacheutil" <<'EOF'
#!/bin/sh
printf 'dir: %s\n' "$HOME"
EOF
FAKE_PYTHON=$TEMP_DIR/python-fixture
cat >"$FAKE_PYTHON" <<'EOF'
#!/bin/sh
case "$0" in *python3.11) version=3.11.15 ;; *) version=3.12.13 ;; esac
case "${2:-}" in
    *platform.python_version*) echo "$version" ;;
    *platform.machine*) echo arm64 ;;
    *) exit 0 ;;
esac
EOF
cat >"$FAKE_BIN/uv" <<'EOF'
#!/bin/sh
if [ "${1:-}" = --version ]; then echo 'uv 0.11.31 (Homebrew fixture)'; exit 0; fi
printf '%s\n' "$@" >"$UV_ARGS_LOG"
install_dir=
minor=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --install-dir) install_dir=$2; shift 2 ;;
        3.11.15) minor=3.11; shift ;;
        3.12.13) minor=3.12; shift ;;
        *) shift ;;
    esac
done
[ -n "$install_dir" ] && [ -n "$minor" ]
case "$minor" in 3.11) patch=3.11.15 ;; *) patch=3.12.13 ;; esac
target=$install_dir/cpython-$patch-macos-aarch64-none/bin
mkdir -p "$target"
cp "$FIXTURE_PYTHON" "$target/python$minor"
chmod 755 "$target/python$minor"
EOF
chmod 755 "$FAKE_BIN"/* "$FAKE_PYTHON"

run_python() {
    HOME="$HOME_DIR" HARNESS_ROOT="$PUBLIC" FIXTURE_PYTHON="$FAKE_PYTHON" \
        UV_ARGS_LOG="$TEMP_DIR/macos-python-uv-args.log" \
        PATH="$FAKE_BIN:/usr/bin:/bin" "$PUBLIC/bin/harness" macos-python \
        --host mac-test-pilot "$@"
}

run_python --minor 3.11 --plan >"$TEMP_DIR/plan.out"
grep 'INSTALL python_tree=' "$TEMP_DIR/plan.out" >/dev/null || fail "Mac Python plan"
run_python --minor 3.11 --apply >"$TEMP_DIR/apply.out"
grep -Fx '3.11.15' "$TEMP_DIR/macos-python-uv-args.log" >/dev/null ||
    fail "Mac Python apply did not request the exact declared patch"
transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\).*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail "Mac Python transaction"
[ "$("$HOME_DIR/.local/bin/python3.11" -c 'import platform; print(platform.python_version())')" = 3.11.15 ] ||
    fail "Mac Python installed version"
run_python --minor 3.11 --plan >"$TEMP_DIR/repeat.out"
grep 'KEEP python=3.11 source=managed-python' "$TEMP_DIR/repeat.out" >/dev/null ||
    fail "Mac Python repeat plan"
HOME="$HOME_DIR" HARNESS_ROOT="$PUBLIC" PATH="$FAKE_BIN:/usr/bin:/bin" \
    "$PUBLIC/bin/harness" rollback "$transaction" >"$TEMP_DIR/rollback.out"
[ ! -e "$HOME_DIR/.local/bin/python3.11" ] &&
    [ ! -L "$HOME_DIR/.local/bin/python3.11" ] || fail "Mac Python rollback link"
[ ! -e "$HOME_DIR/.local/opt/python/3.11/darwin-aarch64" ] ||
    fail "Mac Python rollback tree"

echo 'personal macOS Python tests: PASS'
