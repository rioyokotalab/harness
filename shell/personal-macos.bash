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
unset harness_personal_bin harness_personal_path harness_personal_prefix \
    harness_personal_suffix
export PATH
