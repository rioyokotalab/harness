#!/bin/sh
set -eu
platform=$(uname -s)
state_metadata() {
    case "$platform" in Darwin) stat -f '%Lp %u' "$1" ;; *) stat -c '%a %u' -- "$1" ;; esac
}
result_metadata() {
    case "$platform" in
        Darwin) stat -f '%Lp %u %l %z' "$1" ;;
        *) stat -c '%a %u %h %s' -- "$1" ;;
    esac
}

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'hpc-result-hygiene: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

state=$HOME/.local/state/harness/hpc-readiness
if [ ! -e "$state" ] && [ ! -L "$state" ]; then
    printf 'HPC_RESULT_HYGIENE host=%s state=absent state_ok=1 results=0 invalid=0 temporary=0 status=pass\n' "$host"
    exit 0
fi
[ -d "$state" ] && [ ! -L "$state" ] || {
    printf 'HPC_RESULT_HYGIENE host=%s state=invalid state_ok=0 results=0 invalid=1 temporary=0 status=fail\n' "$host"
    exit 1
}

owner=$(id -u)
IFS=' ' read -r state_mode state_owner <<EOF
$(state_metadata "$state")
EOF
if [ "$state_mode" = 700 ] && [ "$state_owner" = "$owner" ]; then state_ok=1; else state_ok=0; fi
results=0
invalid=0
temporary=0
for path in "$state"/t[0-9][0-9][0-9]-*.out; do
    [ -e "$path" ] || [ -L "$path" ] || continue
    results=$((results + 1))
    if [ ! -f "$path" ] || [ -L "$path" ]; then
        invalid=$((invalid + 1))
        continue
    fi
    IFS=' ' read -r mode path_owner links bytes <<EOF
$(result_metadata "$path")
EOF
    if [ "$mode" != 600 ] || [ "$path_owner" != "$owner" ] || [ "$links" != 1 ] || [ "$bytes" -gt 1048576 ]; then
        invalid=$((invalid + 1))
    fi
done
for path in "$state"/.t[0-9]*; do
    [ -e "$path" ] || [ -L "$path" ] || continue
    temporary=$((temporary + 1))
done
if [ "$state_ok" -eq 1 ] && [ "$invalid" -eq 0 ]; then status=pass; code=0; else status=fail; code=1; fi
printf 'HPC_RESULT_HYGIENE host=%s state=present state_ok=%s results=%s invalid=%s temporary=%s status=%s\n' \
    "$host" "$state_ok" "$results" "$invalid" "$temporary" "$status"
exit "$code"
