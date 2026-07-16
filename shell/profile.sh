# Portable login environment. Keep this file silent and side-effect free.
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
export VISUAL=vim
export PAGER=cat

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
