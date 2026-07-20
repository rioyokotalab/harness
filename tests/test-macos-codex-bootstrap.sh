#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
out=$(mktemp "${TMPDIR:-/tmp}/harness-bootstrap-test.XXXXXX")
trap 'unlink "$out"' EXIT HUP INT TERM

HARNESS_BOOTSTRAP_TESTING=1 "$ROOT/bin/harness" macos-codex-bootstrap --host mac-test-home --plan >"$out"
grep -F 'INSTALLER_URL=https://chatgpt.com/codex/install.sh' "$out" >/dev/null || fail 'official URL'
grep -F 'INSTALL_DIR=' "$out" >/dev/null || fail 'explicit install path'
grep -F 'CODEX_HOME=' "$out" >/dev/null || fail 'explicit state path'
grep -F 'PREREQUISITE_FORMULAE=' "$out" >/dev/null || fail 'prerequisite plan'
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
