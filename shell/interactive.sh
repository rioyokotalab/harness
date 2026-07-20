# shellcheck shell=bash
# Portable interactive Bash behavior.
[ -n "${HARNESS_INTERACTIVE_LOADED:-}" ] && return 0
HARNESS_INTERACTIVE_LOADED=1

HISTCONTROL=ignoreboth:erasedups
HISTFILESIZE=
HISTSIZE=
export HISTCONTROL HISTFILESIZE HISTSIZE
if [ -n "${BASH_VERSION:-}" ]; then
    shopt -s histappend
fi
PS1='\u@\h:\W\$ '

if [ "$(uname -s)" = Darwin ]; then
    if { [ "${BASH_VERSINFO[0]:-0}" -gt 4 ] ||
        { [ "${BASH_VERSINFO[0]:-0}" -eq 4 ] &&
            [ "${BASH_VERSINFO[1]:-0}" -ge 2 ]; }; } &&
        [ -n "${HOMEBREW_PREFIX:-}" ] &&
        [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
        # shellcheck source=/dev/null
        . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
    fi

    activate() {
        if [ "$#" -ne 1 ]; then
            printf '%s\n' 'usage: activate NAME' >&2
            return 2
        fi
        case $1 in
            ''|.|..|*[!A-Za-z0-9._-]*)
                printf '%s\n' 'activate: environment name is invalid' >&2
                return 2
                ;;
        esac
        harness_activate_file=$UV_VENV_ROOT/$1/bin/activate
        if [ ! -r "$harness_activate_file" ]; then
            printf 'activate: environment is unavailable: %s\n' "$1" >&2
            unset harness_activate_file
            return 1
        fi
        # shellcheck source=/dev/null
        . "$harness_activate_file"
        unset harness_activate_file
    }
fi

if [ -r "$HOME/harness/shell/common-aliases.sh" ]; then
    . "$HOME/harness/shell/common-aliases.sh"
fi

if [ -r "$HOME/harness/shell/safety-guards.sh" ]; then
    . "$HOME/harness/shell/safety-guards.sh"
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
