---
name: operate-native-hpc
description: Operate managed HPC work through each site's native scheduler, environment, modules, containers, and visible commands for allocations, MPI/GPU runs, diagnosis, or matched experiments.
---

# Operate Native HPC

Preserve native scheduler/account/resource/architecture/container semantics.

## Mandatory safety and routing

- Resolve the target through `~/harness/profiles/hosts/HOST.conf`. Reject an alias
  without a target profile. Never run workloads on proxy nodes `si`, `web`, or
  `github`.
- Before execution, print the fully resolved command prefixed with `NATIVE`.
  Report that command with its result. Put no hidden scheduler wrapper before
  `sbatch`, `srun`, `qsub`, `yrun`, `ybatch`, `uenv`, `apptainer`, or
  `singularity`.
- Stop when a required billing group or project account is missing; jobs remain
  chargeable.
- Never install a generic global framework to hide a site difference.
- Never read, print, record, or transmit credentials.
  Never capture a full environment dump.

Read [common.md](references/common.md) completely. Then read exactly one
selected site reference:

| Resolved target | Site reference |
|---|---|
| current node | [current.md](references/current.md) |
| `ab`, `ab2` | [abci.md](references/abci.md) |
| `abq` | [abciq.md](references/abciq.md) |
| `ri` | [riken.md](references/riken.md) |
| `al` | [alps.md](references/alps.md) |
| `rc` | [rccs.md](references/rccs.md) |
| `t4` | [tsubame.md](references/tsubame.md) |

Do not preload the aggregate `references/sites.md` or another site. If the
resolved target has no exact row, stop without probing or running a workload.

Read only the current phase reference:

| Current phase | Phase reference |
|---|---|
| scope and native planning | [planning.md](references/planning.md) |
| execute, monitor, cancel, or clean up | [execute-monitor.md](references/execute-monitor.md) |
| validate, compare, and record | [validation.md](references/validation.md) |

Do not preload later or completed phases. A phase change selects only the new
current phase; phase references never select one another.
