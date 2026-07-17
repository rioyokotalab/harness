# shellcheck shell=bash
# Top-level interactive SSH policy. Repository synchronization and publication
# are deliberately explicit; this file only guards against accidental Ctrl-D.
case $- in *i*) ;; *) return 0 ;; esac
[ -n "${SSH_TTY:-}" ] || return 0
[ "${HARNESS_LOGICAL_HOST:-local}" != local ] || return 0
[ -z "${TMUX:-}" ] || return 0
[ "${SHLVL:-0}" -le 1 ] || return 0
[ -z "${HARNESS_REMOTE_SESSION_LOADED:-}" ] || return 0
HARNESS_REMOTE_SESSION_LOADED=1

IGNOREEOF=1
export IGNOREEOF
