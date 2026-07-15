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

case ${HARNESS_LOGICAL_HOST:-} in
    ''|*[!A-Za-z0-9._-]*) ;;
    *)
        harness_environment=$HOME/harness/shell/environments/$HARNESS_LOGICAL_HOST.sh
        if [ -r "$harness_environment" ]; then
            . "$harness_environment"
        fi
        unset harness_environment
        if [ -r "$HOME/harness/shell/cache.sh" ]; then
            . "$HOME/harness/shell/cache.sh"
        fi
        ;;
esac

case $- in
    *i*)
        if [ -r "$HOME/harness/shell/interactive.sh" ]; then
            . "$HOME/harness/shell/interactive.sh"
        fi
        ;;
esac
