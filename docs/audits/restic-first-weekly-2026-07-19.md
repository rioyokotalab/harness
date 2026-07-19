# First scheduler-native weekly snapshot acceptance — 2026-07-19

## Scope and safety

This read-only audit closed T-191's first-production-run gate on `local`, `ab`,
`ab2`, `ri`, `al`, `rc`, and `t4`. Published `main` and all six remote harness
checkouts were clean at `2816e1a` before scheduler inspection. The audit
queried only the seven captured first-run IDs, their seven recorded successors,
and the whitelisted fields in each mode-0600 chain state. It did not submit,
cancel, replace, resize, or reprioritize a job; invoke Restic; inspect a
credential; or change a scheduler, repository, snapshot, or startup file.

## First-run outcome

Each native history record is terminal-success. Each private chain state is
owned by the current user, mode 0600, `status=active`,
`last_result=success`, and contains the exact nonempty snapshot ID below.

| Host | First job | Native terminal result | Snapshot ID |
|---|---:|---|---|
| `local` | `90939` | Slurm `COMPLETED`, `0:0` | `8389c4900fcd1fb4b23c8cf01dad2d80bdd680098e815ecdcc7c9433df5157c9` |
| `ab` | `2044027.pbs1` | PBS `F`, `Exit_status=0` | `2b559796480c07b72388006820ee5b2c4de32ade8fe1fd704dd951551f2b7cb3` |
| `ab2` | `2044028.pbs1` | PBS `F`, `Exit_status=0` | `7c0bb4138eb1fbf4a7b52bcb19cd851fe5b8e95aaf54448c80bf7fcbea177ec0` |
| `ri` | `6862` | Slurm `COMPLETED`, `0:0` | `3b275d51df5831437dbd422044b82c3061ada2a0a1db080e12e0c97fcb7b2def` |
| `rc` | `210816` | Slurm `COMPLETED`, `0:0` | `6f6203aede6e80d98cfb0d1e275577a2b01e99262280e85a7daf38465ca82c4b` |
| `t4` | `8175651` | AGE `failed=0`, `exit_status=0` | `32568829a90dac0168017f430148756db338ec3b520d8bec31257e71a12de3b3` |
| `al` | `4221054` | Slurm `COMPLETED`, `0:0` | `f1c5552a4bc2c4a2f0f12e5b60b218bd21b76bb18b845ee2b4757f49c3e60ab6` |

The exact native history queries were:

```text
NATIVE local: sacct -j 90939 -X -n -P -o JobIDRaw,JobName,User,State,ExitCode,Start,End
NATIVE ab:    /opt/pbs/bin/qstat -xf 2044027.pbs1
NATIVE ab2:   /opt/pbs/bin/qstat -xf 2044028.pbs1
NATIVE ri:    sacct -j 6862 -X -n -P -o JobIDRaw,JobName,User,State,ExitCode,Start,End
NATIVE al:    sacct -j 4221054 -X -n -P -o JobIDRaw,JobName,User,State,ExitCode,Start,End
NATIVE rc:    sacct -j 210816 -X -n -P -o JobIDRaw,JobName,User,State,ExitCode,Start,End
NATIVE t4:    /apps/t4/rhel9/uge/latest/bin/lx-amd64/qacct -j 8175651
```

## Successor continuity

Every first job recorded exactly one strictly future successor. Exact-ID native
queries matched the expected owner and deterministic job name. Slurm successors
were `PENDING`, PBS successors were `W`, and the AGE successor exposed its
declared future execution time.

| Host | Successor | Expected name | Next eligibility |
|---|---:|---|---|
| `local` | `91840` | `hlocal2607260030` | 2026-07-26 00:30 JST |
| `ab` | `2048464.pbs1` | `hab2607260100` | 2026-07-26 01:00 JST |
| `ab2` | `2048468.pbs1` | `hab22607260130` | 2026-07-26 01:30 JST |
| `ri` | `7242` | `hri2607260200` | 2026-07-26 02:00 JST |
| `rc` | `212389` | `hrc2607260230` | 2026-07-26 02:30 JST |
| `t4` | `8194556` | `ht42607260300` | 2026-07-26 03:00 JST |
| `al` | `4238363` | `hal2607260100` | 2026-07-26 01:00 Europe/Zurich |

The exact successor queries were `squeue -j ID` on the four Slurm routes,
`/opt/pbs/bin/qstat -f ID` on AB and AB2, and
`/apps/t4/rhel9/uge/latest/bin/lx-amd64/qstat -j ID` on T4. A final
`harness restic-schedule warning --host HOST` returned exit zero with no
harness output on every host. RI and RC were repeated with `ssh -x` so the
transport emitted no unrelated X11 diagnostic.

## Acceptance and next gate

T-191 acceptance passed: all seven first snapshots succeeded, all seven
successors are identity-matched and strictly future, every private state is
consistent, and interactive warning checks are silent. The chains remain
active and must not be duplicated or replaced merely because a future job is
pending or delayed.

This establishes run 1 of the eight successful weekly runs required before
T-196 can advance. Keep-all remains effective. No retention deletion,
`forget`, `prune`, recurring check/restore, or automatic replica is authorized.
