#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
HARNESS=$ROOT/bin/harness
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh
TEMP_BASE=$(CDPATH='' cd -- "${TMPDIR:-/tmp}" && pwd -P)
TEST_ROOT=$(mktemp -d "$TEMP_BASE/harness-bootstrap-test.XXXXXX")
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEST_ROOT" ]; then
        "$CLEANUP" "$HARNESS" "$TEMP_BASE" "$TEST_ROOT" "$TEMP_BASE" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then status=1; fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

fake_commands=$TEST_ROOT/commands
fake_prefix=$TEST_ROOT/homebrew
mkdir -p "$fake_commands" "$fake_prefix/bin"
printf '%s\n' '#!/bin/sh' 'exit 0' >"$fake_prefix/bin/codex"
chmod 755 "$fake_prefix/bin/codex"
cat >"$fake_commands/brew" <<'EOF'
#!/bin/sh
set -eu
[ "${1:-}" = --prefix ] || exit 2
printf '%s\n' "$HARNESS_TEST_BREW_PREFIX"
EOF
chmod 755 "$fake_commands/brew"
out=$TEST_ROOT/out

HARNESS_BOOTSTRAP_TESTING=1 HARNESS_TEST_BREW_PREFIX=$fake_prefix \
    PATH="$fake_commands:$fake_prefix/bin:$PATH" "$ROOT/bin/harness" \
    macos-codex-bootstrap --host mac-test-home --plan >"$out"
grep -F 'INSTALLER_URL=https://chatgpt.com/codex/install.sh' "$out" >/dev/null || fail 'official URL'
grep -F 'INSTALL_DIR=' "$out" >/dev/null || fail 'explicit install path'
grep -F 'CODEX_HOME=' "$out" >/dev/null || fail 'explicit state path'
grep -F 'PREREQUISITE_FORMULAE=' "$out" >/dev/null || fail 'prerequisite plan'
if grep -F 'harness-mac.git' "$out" >/dev/null; then fail 'companion locator leaked in plan output'; fi
formulae=$(awk -F= '$1=="PREREQUISITE_FORMULAE" {print $2}' "$out")
case " $formulae " in
    *'  '*|*[!A-Za-z0-9_@.+\ -]*) fail 'unsafe prerequisite plan' ;;
esac
for formula in $formulae; do
    case "$formula" in none|gh|python|tmux) ;; *) fail 'unbounded prerequisite formula' ;; esac
done
grep -F 'CODEX_NON_INTERACTIVE=1' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'noninteractive installer'
# shellcheck disable=SC2016
grep -F 'PATH="$install_dir:$PATH"' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'profile-edit prevention'
grep -F 'packages/standalone' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'standalone ownership check'
grep -F 'do not ask me to execute shell scripts' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'autonomous prompt'
grep -F 'HOMEBREW_NO_INSTALL_CLEANUP=1' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'Homebrew cleanup suppression'
grep -F -- "-c 'import tomllib'" "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'tomllib requirement'
grep -F 'private_companion_url=git@github.com:' "$ROOT/config/codex-standalone-installer.conf" >/dev/null || fail 'credential-free companion locator'
grep -F 'LEGACY_CODEX_LINK=removed' "$ROOT/libexec/harness-macos-codex-bootstrap" >/dev/null || fail 'legacy link convergence'
/bin/sh -n "$ROOT/libexec/harness-macos-codex-bootstrap" || fail 'shell syntax'
printf '%s\n' 'personal Mac Codex bootstrap tests: PASS'
