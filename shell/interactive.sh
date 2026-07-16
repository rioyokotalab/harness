# Portable interactive Bash behavior.
[ -n "${HARNESS_INTERACTIVE_LOADED:-}" ] && return 0
HARNESS_INTERACTIVE_LOADED=1
export HARNESS_INTERACTIVE_LOADED

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=50000
HISTFILESIZE=100000
export HISTCONTROL HISTSIZE HISTFILESIZE
if [ -n "${BASH_VERSION:-}" ]; then
    shopt -s histappend
fi

# Launch one in-scope remote Codex session with a PTY. Agent forwarding is
# explicit per invocation so ordinary SSH sessions keep the safer site default;
# it also gives the private-origin login sync and exit-time publish path access
# to the owner's already-running local agent without copying key material.
harness_remote_codex() {
    if [ "$#" -ne 1 ]; then
        printf '%s\n' 'usage: harness_remote_codex {ab|ab2|ri|al|rc|t4}' >&2
        return 2
    fi
    case $1 in
        ab|ab2|ri|al|rc|t4) ;;
        *)
            printf 'harness_remote_codex: excluded host: %s\n' "$1" >&2
            return 2
            ;;
    esac
    command ssh -A -t "$1" 'exec bash -lic '\''cd "$HOME" && exec codex'\'''
}

case ${HARNESS_LOGICAL_HOST:-} in
    ''|*[!A-Za-z0-9._-]*) ;;
    *)
        host_interactive=$HOME/harness/shell/hosts/$HARNESS_LOGICAL_HOST.sh
        if [ -r "$host_interactive" ]; then
            . "$host_interactive"
        fi
        unset host_interactive
        ;;
esac

if [ -r "$HOME/harness/shell/remote-session.sh" ]; then
    . "$HOME/harness/shell/remote-session.sh"
fi

# Read only the private node-local chain state. Healthy and unseeded state is
# silent; the helper performs no scheduler write, network operation, or prompt.
case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4)
        if [ -x "$HOME/harness/bin/harness" ]; then
            "$HOME/harness/bin/harness" restic-schedule warning \
                --host "$HARNESS_LOGICAL_HOST" 2>/dev/null || :
        fi
        ;;
esac
