#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/harness-startup-test.XXXXXX")
CLEANUP=$ROOT/tests/guarded-test-cleanup.sh

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    cleanup_failed=0
    if [ -d "$TEMP_DIR" ]; then
        "$CLEANUP" "$ROOT/bin/harness" "${TMPDIR:-/tmp}" "$TEMP_DIR" \
            "${TMPDIR:-/tmp}" >/dev/null || cleanup_failed=1
    fi
    if [ "$status" -eq 0 ] && [ "$cleanup_failed" -ne 0 ]; then
        echo 'FAIL: guarded startup-normalize cleanup' >&2
        status=1
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

file_mode() {
    case $(uname -s) in
        Darwin) stat -f %Lp "$1" ;;
        *) stat -c %a "$1" ;;
    esac
}

repo=$TEMP_DIR/repo
home=$TEMP_DIR/home
mkdir -p "$repo/bin" "$repo/libexec" "$home/.ssh"
cp "$ROOT/bin/harness" "$repo/bin/"
cp "$ROOT/libexec/harness-startup-normalize" "$repo/libexec/"
cp "$ROOT/libexec/harness-inventory" "$repo/libexec/"
git -C "$repo" init -q
git -C "$repo" config user.name harness-test
git -C "$repo" config user.email harness-test.invalid
git -C "$repo" add bin libexec
git -C "$repo" commit -qm baseline

cat >"$home/.bashrc" <<'EOF'
# >>> harness early managed >>>
HARNESS_LOGICAL_HOST=local
# <<< harness early managed <<<

# Aliases
alias a='./a.out'
alias al='PRIVATE-SENTINEL-MUST-STAY-LOCAL'
alias ducks='du -cks * | sort -rn | head -11'
alias grep='grep --binary-files=without-match --color=auto'
alias la='ls -ah'
alias ll='ls -hl'
alias lla='ls -ahl'
alias ls='ls --color=auto'
alias v='vim'

# Default editor
export EDITOR='vim'
# Unlimited bash history in .bash_history
export HISTFILESIZE=
# Unlimited bash history in memory
export HISTSIZE=

# Prompt
PS1='\u@\h:\W\$ '

# Set global install path
export FS=$HOME

# Local installs
export PATH=$FS/.local/bin:$PATH
export CPATH=$FS/.local/include:$CPATH
export LIBRARY_PATH=$FS/.local/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$FS/.local/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$FS/.local/lib/pkgconfig

# >>> harness managed >>>
HARNESS_LOGICAL_HOST=local
export HARNESS_LOGICAL_HOST
if [ -r "$HOME/harness/shell/profile.sh" ]; then
    . "$HOME/harness/shell/profile.sh"
fi
# <<< harness managed <<<
EOF
chmod 664 "$home/.bashrc"

cat >"$home/.ssh/config" <<'EOF'
Host ab
    HostName ab.invalid
Host ab2
    HostName ab2.invalid
Host al
    HostName al.invalid
Host rc
    HostName rc.invalid
Host ri
    HostName ri.invalid
Host t4
    HostName t4.invalid
Host github
    HostName github.com
Host *
    ServerAliveInterval 60
EOF
chmod 600 "$home/.ssh/config"
cp "$home/.bashrc" "$TEMP_DIR/bashrc.before"
cp "$home/.ssh/config" "$TEMP_DIR/ssh.before"

HOME="$home" "$repo/bin/harness" startup-normalize --host local --plan \
    >"$TEMP_DIR/plan.out"
grep -F 'UPDATE file=.bashrc rules=2' "$TEMP_DIR/plan.out" >/dev/null ||
    fail 'local Bash plan'
grep -F 'UPDATE file=.ssh/config rules=6' "$TEMP_DIR/plan.out" >/dev/null ||
    fail 'local SSH plan'

HOME="$home" "$repo/bin/harness" startup-normalize --host local --apply \
    >"$TEMP_DIR/apply.out"
transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\) .*/\1/p' "$TEMP_DIR/apply.out")
[ -n "$transaction" ] || fail 'transaction id'
[ "$(file_mode "$home/.bashrc")" = 664 ] || fail 'Bash mode preservation'
[ "$(file_mode "$home/.ssh/config")" = 600 ] || fail 'SSH mode preservation'
grep -F "alias al='PRIVATE-SENTINEL-MUST-STAY-LOCAL'" "$home/.bashrc" >/dev/null ||
    fail 'local-only alias preservation'
if grep -R -F 'PRIVATE-SENTINEL-MUST-STAY-LOCAL' \
    "$home/.local/state/harness/transactions" >/dev/null; then
    fail 'private local alias leaked into transaction state'
fi
[ "$(grep -ic '^[[:space:]]*ForwardAgent[[:space:]]\+yes' "$home/.ssh/config")" -eq 6 ] ||
    fail 'SSH forwarding count'

HOME="$home" "$repo/bin/harness" startup-normalize --host local --plan \
    >"$TEMP_DIR/idempotent.out"
grep -F 'KEEP file=.bashrc state=normalized' "$TEMP_DIR/idempotent.out" >/dev/null ||
    fail 'Bash idempotence'
grep -F 'KEEP file=.ssh/config state=normalized' "$TEMP_DIR/idempotent.out" >/dev/null ||
    fail 'SSH idempotence'

HOME="$home" "$repo/bin/harness" startup-normalize --rollback "$transaction" \
    >"$TEMP_DIR/rollback.out"
cmp "$TEMP_DIR/bashrc.before" "$home/.bashrc" >/dev/null || fail 'Bash rollback'
cmp "$TEMP_DIR/ssh.before" "$home/.ssh/config" >/dev/null || fail 'SSH rollback'

HOME="$home" "$repo/bin/harness" startup-normalize --host local --apply \
    >"$TEMP_DIR/reapply.out"
transaction=$(sed -n 's/^TRANSACTION id=\([^ ]*\) .*/\1/p' "$TEMP_DIR/reapply.out")
case $(uname -s) in
    Darwin) sed -i '' '1,/ForwardAgent yes/s/ForwardAgent yes/ForwardAgent no/' "$home/.ssh/config" ;;
    *) sed -i '0,/ForwardAgent yes/s//ForwardAgent no/' "$home/.ssh/config" ;;
esac
if HOME="$home" "$repo/bin/harness" startup-normalize --rollback "$transaction" \
    >"$TEMP_DIR/refused.out" 2>&1; then
    fail 'rollback accepted changed managed block'
fi

alias_names=$(sed -n 's/^alias \([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' \
    "$ROOT/shell/common-aliases.sh")
[ "$alias_names" = "$(printf '%s\n' "$alias_names" | LC_ALL=C sort -u)" ] ||
    fail 'common aliases are not unique and alphabetic'
sudo_alias=$(bash -c '. "$1"; alias sudo' _ "$ROOT/shell/common-aliases.sh")
[ "$sudo_alias" = "alias sudo='sudo '" ] ||
    fail 'common sudo alias lost trailing-space alias expansion'

echo 'PASS: startup normalization transaction'
