# HPC topology login surface

The canonical bounded record is
[`audits/hpc-topology-login-surface-2026-07-17.json`](audits/hpc-topology-login-surface-2026-07-17.json).
Every managed login surface exposes Linux process-affinity metadata, sysfs CPU
topology, `taskset`, and `lscpu`. Local, RI, AL, RC, and T4 also expose
`numactl`/`numastat`; AB and AB2 do not. All except RC expose the inspected
hwloc commands. LIKWID is absent everywhere.

The observed login NUMA-domain counts are local 1, AB 2, AB2 2, RI 2, AL 4,
RC 2, and T4 2. These values describe only the login process and must not be
copied into a compute job, rank map, or performance claim. Compute nodes can
have different architectures, socket layouts, cgroup masks, SMT policies, and
accelerator locality.

T-237 deliberately uses the Linux affinity API and sysfs rather than requiring
an optional topology package, so missing `numactl` on ABCI or hwloc on RC does
not erase CPU-placement readiness. A future NUMA memory-policy gate should run
only after T-237's queued routes finish, inside the same native allocation,
and should verify placement/locality correctness before measuring bandwidth.
If a project requires libnuma, hwloc, or LIKWID, select it through the project's
locked/site-native environment instead of installing it globally.
