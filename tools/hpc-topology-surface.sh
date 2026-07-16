#!/bin/sh
set -eu

case ${HARNESS_LOGICAL_HOST:-} in
    local|ab|ab2|ri|al|rc|t4) host=$HARNESS_LOGICAL_HOST ;;
    *) printf '%s\n' 'hpc-topology-surface: invalid HARNESS_LOGICAL_HOST' >&2; exit 2 ;;
esac

tool_state() {
    if command -v "$1" >/dev/null 2>&1; then printf present; else printf absent; fi
}

[ -r /proc/self/status ] || {
    printf '%s\n' 'hpc-topology-surface: process affinity metadata unavailable' >&2
    exit 1
}
[ -r /sys/devices/system/cpu/cpu0/topology/core_id ] || {
    printf '%s\n' 'hpc-topology-surface: CPU topology metadata unavailable' >&2
    exit 1
}
if ! lscpu_output=$(lscpu -p=NODE); then
    printf '%s\n' 'hpc-topology-surface: lscpu query failed' >&2
    exit 1
fi
if ! numa_nodes=$(printf '%s\n' "$lscpu_output" | awk -F ',' '
    !/^#/ && $1 ~ /^[0-9]+$/ { seen[$1] = 1 }
    END {
        for (node in seen) count++
        if (count == 0) exit 2
        print count
    }
'); then
    printf '%s\n' 'hpc-topology-surface: malformed lscpu topology output' >&2
    exit 1
fi

printf 'HPC_TOPOLOGY_SURFACE host=%s taskset=%s numactl=%s numastat=%s lscpu=%s hwloc_info=%s lstopo=%s likwid_pin=%s login_numa_nodes=%s status=pass\n' \
    "$host" "$(tool_state taskset)" "$(tool_state numactl)" \
    "$(tool_state numastat)" "$(tool_state lscpu)" \
    "$(tool_state hwloc-info)" "$(tool_state lstopo-no-graphics)" \
    "$(tool_state likwid-pin)" "$numa_nodes"
