# Portable interactive Bash behavior.
[ -n "${HARNESS_INTERACTIVE_LOADED:-}" ] && return 0
HARNESS_INTERACTIVE_LOADED=1
export HARNESS_INTERACTIVE_LOADED

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=
HISTFILESIZE=
export HISTCONTROL HISTSIZE HISTFILESIZE
if [ -n "${BASH_VERSION:-}" ]; then
    shopt -s histappend
fi
PS1='\u@\h:\W\$ '

if [ -r "$HOME/harness/shell/common-aliases.sh" ]; then
    . "$HOME/harness/shell/common-aliases.sh"
fi

# Launch one in-scope remote Codex session with a PTY. The explicit -A agrees
# with the current node's per-host SSH policy and never copies key material.
harness_remote_codex() {
    if [ "$#" -ne 1 ]; then
        printf '%s\n' 'usage: harness_remote_codex LOGICAL_HOST' >&2
        return 2
    fi
    case $1 in
        local|''|[!a-z]*|*[!a-z0-9._-]*|*..*)
            printf 'harness_remote_codex: excluded host: %s\n' "$1" >&2
            return 2
            ;;
    esac
    host_profile=$HOME/harness/profiles/hosts/$1.conf
    if [ ! -f "$host_profile" ] || [ -L "$host_profile" ]; then
        printf 'harness_remote_codex: unmanaged host: %s\n' "$1" >&2
        unset host_profile
        return 2
    fi
    unset host_profile
    command ssh -A -t "$1" 'exec bash -lic '\''cd "$HOME" && exec codex'\'''
}

case ${HARNESS_LOGICAL_HOST:-} in
    ''|*[!A-Za-z0-9._-]*) ;;
    *)
        host_interactive=$HOME/harness/shell/hosts/$HARNESS_LOGICAL_HOST.sh
        if [ -r "$host_interactive" ]; then
            # shellcheck source=/dev/null
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
    ''|*[!A-Za-z0-9._-]*) ;;
    *)
        restic_schedule_map=$HOME/harness/profiles/restic-schedules.tsv
        if [ -f "$restic_schedule_map" ] && [ ! -L "$restic_schedule_map" ] &&
            awk -F'|' -v host="$HARNESS_LOGICAL_HOST" '
                $0 !~ /^#/ && $1 == host { count++ }
                END { exit count == 1 ? 0 : 1 }
            ' "$restic_schedule_map" &&
            [ -x "$HOME/harness/bin/harness" ]; then
            "$HOME/harness/bin/harness" restic-schedule warning \
                --host "$HARNESS_LOGICAL_HOST" 2>/dev/null || :
        fi
        unset restic_schedule_map
        ;;
esac
