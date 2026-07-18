# shellcheck shell=bash
# Thin, silent personal-macOS interactive Bash environment.
case $- in
    *i*) ;;
    *) return 0 ;;
esac
[ -z "${HARNESS_PERSONAL_MACOS_LOADER_LOADED:-}" ] || return 0
HARNESS_PERSONAL_MACOS_LOADER_LOADED=1
export HARNESS_PERSONAL_MACOS_LOADER_LOADED
HARNESS_PERSONAL_MACOS_BASH=1
export HARNESS_PERSONAL_MACOS_BASH

harness_personal_bin=$HOME/.local/bin
harness_personal_path=:$PATH:
while :; do
    case $harness_personal_path in
        *:"$harness_personal_bin":*)
            harness_personal_prefix=${harness_personal_path%%:"$harness_personal_bin":*}
            harness_personal_suffix=${harness_personal_path#*:"$harness_personal_bin":}
            harness_personal_path=$harness_personal_prefix:$harness_personal_suffix
            ;;
        *) break ;;
    esac
done
harness_personal_path=${harness_personal_path#:}
harness_personal_path=${harness_personal_path%:}
PATH=$harness_personal_bin${harness_personal_path:+:$harness_personal_path}

harness_personal_private_bash=$HOME/.config/harness/managed/personal-macos-private.bash
if [ -f "$harness_personal_private_bash" ] &&
    [ ! -L "$harness_personal_private_bash" ]; then
    # Config sync owns this private mode-0600 runtime fragment. Only a new
    # managed interactive Bash process loads it.
    # shellcheck disable=SC1090
    . "$harness_personal_private_bash"
fi
unset harness_personal_bin harness_personal_path harness_personal_prefix \
    harness_personal_suffix harness_personal_private_bash
export PATH
