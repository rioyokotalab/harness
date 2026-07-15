# Interactive remote-session behavior. Never run network or prompt logic in a
# non-interactive shell, local session, nested shell, or tmux shell.
case $- in *i*) ;; *) return 0 ;; esac
[ -n "${SSH_TTY:-}" ] || return 0
[ "${HARNESS_LOGICAL_HOST:-local}" != local ] || return 0
[ -z "${TMUX:-}" ] || return 0
[ "${SHLVL:-0}" -le 1 ] || return 0
[ -z "${HARNESS_REMOTE_SESSION_LOADED:-}" ] || return 0
HARNESS_REMOTE_SESSION_LOADED=1
export HARNESS_REMOTE_SESSION_LOADED

harness_login_sync() {
    harness_repo=$HOME/harness
    [ -d "$harness_repo/.git" ] || return 0
    command -v git >/dev/null 2>&1 || return 0
    command -v timeout >/dev/null 2>&1 || return 0
    if [ -n "$(git -C "$harness_repo" status --porcelain 2>/dev/null)" ]; then
        printf '%s\n' 'harness: login sync skipped because the checkout is dirty' >&2
        return 0
    fi
    if ! timeout 12 git -C "$harness_repo" fetch --quiet origin main; then
        printf '%s\n' 'harness: login fetch failed; continuing with the local revision' >&2
        return 0
    fi
    if git -C "$harness_repo" merge-base --is-ancestor HEAD origin/main; then
        if [ "$(git -C "$harness_repo" rev-parse HEAD)" != \
            "$(git -C "$harness_repo" rev-parse origin/main)" ]; then
            git -C "$harness_repo" merge --ff-only --quiet origin/main ||
                printf '%s\n' 'harness: login fast-forward failed' >&2
        fi
    elif ! git -C "$harness_repo" merge-base --is-ancestor origin/main HEAD; then
        printf '%s\n' 'harness: local and origin/main diverged; login sync did not merge' >&2
    fi
    unset harness_repo
}

harness_publish_staged() {
    harness_repo=$HOME/harness
    if git -C "$harness_repo" diff --cached --quiet; then
        printf '%s\n' 'harness: nothing staged; stage intended files before publishing' >&2
        return 1
    fi
    git -C "$harness_repo" diff --check --cached || return 1
    timeout 12 git -C "$harness_repo" fetch --quiet origin main || return 1
    git -C "$harness_repo" merge-base --is-ancestor origin/main HEAD || {
        printf '%s\n' 'harness: origin/main is not an ancestor; sync before publishing' >&2
        return 1
    }
    git -C "$harness_repo" commit -m \
        "Publish staged harness changes from ${HARNESS_LOGICAL_HOST}" || return 1
    timeout 20 git -C "$harness_repo" push origin HEAD:main
}

exit() {
    harness_exit_status=${1:-$?}
    harness_repo=$HOME/harness
    if [ -d "$harness_repo/.git" ] &&
        { ! git -C "$harness_repo" diff --quiet ||
          ! git -C "$harness_repo" diff --cached --quiet ||
          [ -n "$(git -C "$harness_repo" ls-files --others --exclude-standard)" ]; }; then
        git -C "$harness_repo" status --short
        while :; do
            printf '%s' 'Publish staged harness changes before exit? [y/N/c] '
            IFS= read -r harness_reply || harness_reply=n
            case $harness_reply in
                y|Y|yes|YES)
                    if harness_publish_staged; then
                        break
                    fi
                    printf '%s\n' 'harness: publish failed; exit cancelled' >&2
                    unset harness_exit_status harness_repo harness_reply
                    return 1
                    ;;
                c|C|cancel|CANCEL)
                    unset harness_exit_status harness_repo harness_reply
                    return 0
                    ;;
                n|N|no|NO|'') break ;;
                *) printf '%s\n' 'Please answer y, n, or c.' ;;
            esac
        done
    fi
    unset harness_repo harness_reply
    builtin exit "$harness_exit_status"
}

IGNOREEOF=1
export IGNOREEOF
harness_login_sync
