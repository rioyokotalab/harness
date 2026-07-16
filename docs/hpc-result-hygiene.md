# HPC result metadata hygiene

T-233 audits only metadata for the harness's private HPC readiness results
under `~/.local/state/harness/hpc-readiness`. It never reads result contents.
Every matching `tNNN-*.out` path must be a regular non-symlink owned by the
current account, mode 0600, single-linked after publication, and no larger than
1 MiB. The containing state directory must be owner mode 0700.

Unique `.tNNN*` entries are counted separately as temporary captures/builds.
Their presence is not automatically a failure because a captured scheduler job
may be running; the owner must reconcile them against exact job IDs before any
cleanup. This probe never deletes or changes a path, and it does not establish
the semantic correctness of a result or replace scheduler accounting.

## 2026-07-17 fleet result

All seven metadata-only probes passed with state mode/owner valid, zero invalid
results, and zero temporary entries. Valid result counts were: local 6, AB 10,
AB2 10, RI 6, AL 9, RC 7, and T4 8. Different counts reflect route-specific
passes, skips, and preserved retries; they are not parity defects.
