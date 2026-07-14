# Portable login environment. Keep this file silent and side-effect free.
case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) PATH=${HOME}/.local/bin:${PATH} ;;
esac
export PATH
export EDITOR=vim
export VISUAL=vim
export PAGER=cat

case $- in
    *i*)
        if [ -r "$HOME/harness/shell/interactive.sh" ]; then
            . "$HOME/harness/shell/interactive.sh"
        fi
        ;;
esac
