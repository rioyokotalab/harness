# Silent, side-effect-free cache bootstrap for the first lines of Bash startup.
# It sets variables only: no target or home directory is created.
case ${HARNESS_LOGICAL_HOST:-} in
    ''|*[!A-Za-z0-9._-]*) ;;
    *)
        harness_early_environment=$HOME/harness/shell/environments/$HARNESS_LOGICAL_HOST.sh
        if [ -r "$harness_early_environment" ]; then
            . "$harness_early_environment"
            if [ -r "$HOME/harness/shell/cache.sh" ]; then
                . "$HOME/harness/shell/cache.sh"
            fi
        fi
        unset harness_early_environment
        ;;
esac
