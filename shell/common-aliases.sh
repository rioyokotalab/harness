# shellcheck shell=bash
# Portable interactive aliases. Keep definitions alphabetic by command name.
alias a='./a.out'
# `att` attaches this host's canonical agent session. Local runs the
# multi-repository `projects` session; every managed Mac runs the unified
# `harness` session, so that is the portable default. Frozen at shell start,
# matching the `ls` option below.
case "${HARNESS_LOGICAL_HOST:-}" in
    local) harness_attach_session=projects ;;
    *) harness_attach_session=harness ;;
esac
# shellcheck disable=SC2139
alias att="tmux attach -t $harness_attach_session"
unset harness_attach_session
alias co='harness codex-resilient --run --name harness --last'
alias ducks='du -cks * | sort -rn | head -11'
alias grep='grep --binary-files=without-match --color=auto'
alias la='ls -ah'
alias ll='ls -hl'
alias lla='ls -ahl'
case "$(uname -s)" in
    Darwin) harness_ls_color_option=-G ;;
    *) harness_ls_color_option=--color=auto ;;
esac
# Freeze the host-specific option when this interactive shell starts.
# shellcheck disable=SC2139
alias ls="ls $harness_ls_color_option"
unset harness_ls_color_option
alias sudo='sudo '
alias v='vim'
