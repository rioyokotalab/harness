# shellcheck shell=bash
# Low-friction safeguards for unusually destructive interactive commands.

case $- in
    *i*) ;;
    *) return 0 ;;
esac

[ -n "${HARNESS_SAFETY_GUARDS_LOADED:-}" ] && return 0
HARNESS_SAFETY_GUARDS_LOADED=1

_harness_safety_refuse() {
    printf 'harness safety: refused %s\n' "$1" >&2
    printf 'harness safety: use the named safe workflow, or deliberately bypass with: command COMMAND ...\n' >&2
    return 64
}

_harness_safety_same_or_descendant() {
    local candidate=$1
    local ancestor=$2

    [ "$candidate" = "$ancestor" ] && return 0
    if [ "$ancestor" = / ]; then
        case $candidate in
            /*) return 0 ;;
        esac
    else
        case $candidate in
            "$ancestor"/*) return 0 ;;
        esac
    fi
    return 1
}

_harness_safety_add_root() {
    local value=${1:-}
    local lexical resolved

    [ -n "$value" ] || return 0
    lexical=$(command realpath -ms -- "$value" 2>/dev/null) || return 1
    resolved=$(command realpath -m -- "$value" 2>/dev/null) || return 1
    _harness_safety_roots_lexical+=("$lexical")
    _harness_safety_roots_resolved+=("$resolved")
}

_harness_safety_any_path_dangerous() {
    local protect_cwd=$1
    shift
    local account_home='' root target target_lexical target_resolved parent
    local root_lexical root_resolved direct_children
    local -a _harness_safety_roots_lexical=()
    local -a _harness_safety_roots_resolved=()
    local -a target_lexicals=()
    local -a target_resolveds=()

    command -v realpath >/dev/null 2>&1 || return 0
    _harness_safety_add_root / || return 0
    _harness_safety_add_root "${HOME:-}" || return 0
    _harness_safety_add_root "${HARNESS_PERSISTENT_ROOT:-}" || return 0
    if command -v getent >/dev/null 2>&1 && command -v id >/dev/null 2>&1; then
        account_home=$(command getent passwd "$(command id -u)" 2>/dev/null |
            command awk -F: -v uid="$(command id -u)" '
                $3 == uid { home=$6; count++ }
                END { if (count == 1) print home }
            ') || account_home=
        _harness_safety_add_root "$account_home" || return 0
    fi
    if [ "$protect_cwd" = yes ]; then
        _harness_safety_add_root "$(command pwd -L)" || return 0
        _harness_safety_add_root "$(command pwd -P)" || return 0
    fi

    for target in "$@"; do
        target_lexical=$(command realpath -ms -- "$target" 2>/dev/null) || return 0
        if [ -L "$target" ]; then
            target_resolved=$target_lexical
        else
            target_resolved=$(command realpath -m -- "$target" 2>/dev/null) || return 0
        fi
        target_lexicals+=("$target_lexical")
        target_resolveds+=("$target_resolved")

        for root in "${!_harness_safety_roots_lexical[@]}"; do
            root_lexical=${_harness_safety_roots_lexical[$root]}
            root_resolved=${_harness_safety_roots_resolved[$root]}
            if _harness_safety_same_or_descendant "$root_lexical" "$target_lexical" ||
                _harness_safety_same_or_descendant "$root_resolved" "$target_resolved"; then
                return 0
            fi
        done
    done

    # A shell function sees expanded glob results, not the original `*`. Eight
    # or more immediate children of one protected root is therefore treated as
    # a likely broad-content deletion without disturbing ordinary subtree work.
    for root in "${!_harness_safety_roots_lexical[@]}"; do
        root_lexical=${_harness_safety_roots_lexical[$root]}
        direct_children=0
        for target_lexical in "${target_lexicals[@]}"; do
            parent=${target_lexical%/*}
            [ -n "$parent" ] || parent=/
            if [ "$parent" = "$root_lexical" ]; then
                direct_children=$((direct_children + 1))
                [ "$direct_children" -lt 8 ] || return 0
            fi
        done
    done
    return 1
}

_harness_safety_recursive_targets() {
    local arg short options=yes
    HARNESS_SAFETY_RECURSIVE=no
    HARNESS_SAFETY_TARGETS=()
    for arg in "$@"; do
        if [ "$options" = yes ]; then
            case $arg in
                --)
                    options=no
                    continue
                    ;;
                --recursive)
                    HARNESS_SAFETY_RECURSIVE=yes
                    continue
                    ;;
                --*) continue ;;
                -?*)
                    short=${arg#-}
                    case $short in
                        *r*|*R*) HARNESS_SAFETY_RECURSIVE=yes ;;
                    esac
                    continue
                    ;;
            esac
        fi
        HARNESS_SAFETY_TARGETS+=("$arg")
    done
}

rm() {
    _harness_safety_recursive_targets "$@"
    if [ "$HARNESS_SAFETY_RECURSIVE" = yes ] &&
        [ "${#HARNESS_SAFETY_TARGETS[@]}" -gt 0 ] &&
        _harness_safety_any_path_dangerous yes "${HARNESS_SAFETY_TARGETS[@]}"; then
        _harness_safety_refuse \
            'recursive rm that contains a protected root or broadly selects its children; use harness guarded-delete'
        return
    fi
    command rm "$@"
}

rsync() {
    local arg
    for arg in "$@"; do
        case $arg in
            --delete|--delete-*|--remove-source-files)
                _harness_safety_refuse \
                    'rsync deletion mode; review source/destination and use command rsync explicitly'
                return
                ;;
        esac
    done
    command rsync "$@"
}

find() {
    local arg
    for arg in "$@"; do
        if [ "$arg" = -delete ]; then
            _harness_safety_refuse \
                'find -delete; inspect the match set and use harness guarded-delete'
            return
        fi
    done
    command find "$@"
}

_harness_safety_recursive_permission_change() {
    local arg short
    HARNESS_SAFETY_RECURSIVE=no
    HARNESS_SAFETY_TARGETS=()
    for arg in "$@"; do
        case $arg in
            --recursive) HARNESS_SAFETY_RECURSIVE=yes ;;
            --*) ;;
            -?*)
                short=${arg#-}
                case $short in
                    *R*) HARNESS_SAFETY_RECURSIVE=yes ;;
                esac
                ;;
            *) HARNESS_SAFETY_TARGETS+=("$arg") ;;
        esac
    done
    [ "$HARNESS_SAFETY_RECURSIVE" = yes ] &&
        [ "${#HARNESS_SAFETY_TARGETS[@]}" -gt 0 ] &&
        _harness_safety_any_path_dangerous no "${HARNESS_SAFETY_TARGETS[@]}"
}

chmod() {
    if _harness_safety_recursive_permission_change "$@"; then
        _harness_safety_refuse \
            'recursive chmod that contains a protected root'
        return
    fi
    command chmod "$@"
}

chown() {
    if _harness_safety_recursive_permission_change "$@"; then
        _harness_safety_refuse \
            'recursive chown that contains a protected root'
        return
    fi
    command chown "$@"
}

_harness_safety_exact_job_id() {
    [[ $1 =~ ^[0-9]+(_[0-9]+|\[[0-9]+\])?([.][A-Za-z0-9._-]+)?$ ]]
}

_harness_safety_single_job() {
    local scheduler=$1
    shift
    local arg jobs=0 options=yes skip_value=no
    for arg in "$@"; do
        if [ "$skip_value" = yes ]; then
            skip_value=no
            continue
        fi
        if [ "$options" = yes ]; then
            case $arg in
                --)
                    options=no
                    continue
                    ;;
            esac
            if [ "$scheduler" = qdel ]; then
                case $arg in
                    -W) skip_value=yes; continue ;;
                    -W*|-x) continue ;;
                esac
            else
                case $arg in
                    -s|--signal|--clusters) skip_value=yes; continue ;;
                    -s?*|--signal=*|--clusters=*|-b|--batch|-f|--full|-i|--interactive|-Q|--quiet|-v|--verbose)
                        continue
                        ;;
                esac
            fi
        fi
        case $arg in
            -*) ;;
            *)
                _harness_safety_exact_job_id "$arg" || return 1
                jobs=$((jobs + 1))
                ;;
        esac
    done
    [ "$skip_value" = no ] && [ "$jobs" -eq 1 ]
}

qdel() {
    if [ "$#" -gt 0 ] && ! _harness_safety_single_job qdel "$@"; then
        _harness_safety_refuse \
            'broad qdel selector; cancel one explicit job ID at a time'
        return
    fi
    command qdel "$@"
}

scancel() {
    local arg
    for arg in "$@"; do
        case $arg in
            -u|-u?*|--user|--user=*|-n|-n?*|--name|--name=*|-A|-A?*|--account|--account=*|-p|-p?*|--partition|--partition=*|--state|--state=*|--reservation|--reservation=*|--wckey|--wckey=*)
                _harness_safety_refuse \
                    'broad scancel selector; cancel one explicit job ID at a time'
                return
                ;;
        esac
    done
    if [ "$#" -gt 0 ] && ! _harness_safety_single_job scancel "$@"; then
        _harness_safety_refuse \
            'broad scancel selector; cancel one explicit job ID at a time'
        return
    fi
    command scancel "$@"
}
