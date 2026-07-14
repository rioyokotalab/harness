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
