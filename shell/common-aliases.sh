# shellcheck shell=bash
# Portable interactive aliases. Keep definitions alphabetic by command name.
alias a='./a.out'
alias att='tmux attach -t harness'
alias codex='harness codex-resilient --run --name harness --last'
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
