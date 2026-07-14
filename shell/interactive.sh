# Portable interactive Bash behavior.
[ -n "${HARNESS_INTERACTIVE_LOADED:-}" ] && return 0
HARNESS_INTERACTIVE_LOADED=1
export HARNESS_INTERACTIVE_LOADED

HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
export HISTCONTROL HISTSIZE HISTFILESIZE
if [ -n "${BASH_VERSION:-}" ]; then
    shopt -s histappend
fi

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
