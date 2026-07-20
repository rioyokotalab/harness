# shellcheck shell=bash
# Portable login environment. Keep this file silent and side-effect free.
if [ "$(uname -s)" = Darwin ]; then
    harness_brew=
    for harness_brew_candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$harness_brew_candidate" ] && [ ! -L "$harness_brew_candidate" ]; then
            harness_brew=$harness_brew_candidate
            break
        fi
    done
    if [ -n "$harness_brew" ]; then
        HOMEBREW_NO_ENV_HINTS=1
        export HOMEBREW_NO_ENV_HINTS
        eval "$("$harness_brew" shellenv bash)"
    fi
    LANG=en_US.UTF-8
    UV_VENV_ROOT=$HOME/.venv
    export LANG UV_VENV_ROOT
    unset harness_brew harness_brew_candidate
fi

# Move the managed command directory to the front even if site startup already
# inserted it later in PATH, and remove duplicate entries without running an
# external command.
harness_user_bin=$HOME/.local/bin
harness_path=:$PATH:
while :; do
    case $harness_path in
        *:"$harness_user_bin":*)
            harness_prefix=${harness_path%%:"$harness_user_bin":*}
            harness_suffix=${harness_path#*:"$harness_user_bin":}
            harness_path=$harness_prefix:$harness_suffix
            ;;
        *) break ;;
    esac
done
harness_path=${harness_path#:}
harness_path=${harness_path%:}
PATH=$harness_user_bin${harness_path:+:$harness_path}
unset harness_user_bin harness_path harness_prefix harness_suffix
export PATH
export EDITOR=vim
export PAGER=cat
export VISUAL=vim

if [ -r "$HOME/harness/shell/early-cache.sh" ]; then
    . "$HOME/harness/shell/early-cache.sh"
fi

case $- in
    *i*)
        if [ -r "$HOME/harness/shell/interactive.sh" ]; then
            . "$HOME/harness/shell/interactive.sh"
        fi
        ;;
esac
