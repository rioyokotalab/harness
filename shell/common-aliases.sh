# shellcheck shell=bash
# Portable interactive aliases. Keep definitions alphabetic by command name.
alias a='./a.out'
codex() { command harness-codex "$@"; }
alias ducks='du -cks * | sort -rn | head -11'
alias grep='grep --binary-files=without-match --color=auto'
alias la='ls -ah'
alias ll='ls -hl'
alias lla='ls -ahl'
alias ls='ls --color=auto'
alias v='vim'
