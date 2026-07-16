# Seven-node readiness and drift audit

## Method

`tools/fleet-readiness-audit.py` launched one non-interactive login-shell probe
on each of `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`; the six SSH probes
ran concurrently. Each probe was bounded to declared inventory JSON, Git
revision and dirty count, doctor summary, four exact control-plane paths,
eleven exact storage paths, ten tracked smoke-source blob IDs, fixed version
commands, and `restic-schedule status`. It did not enumerate an environment or
SSH configuration, walk a data tree, inspect a credential, submit/cancel a job,
or write a node.

The canonical machine-readable result is
`docs/audits/fleet-readiness-2026-07-16.json`. It was generated after the
collector was committed, so the local checkout also reports clean. Unexpected
stdout is discarded and counted; every node recorded zero discarded lines.
Transport stderr was present but deliberately not captured on AB2, RI, and RC.

## Confirmed invariants

| Host | Arch | Declared scheduler | Doctor failures/warnings | Production job state |
|---|---|---|---:|---|
| local | x86-64 | ybatch | 0 / 5 | `90939`, pending, present |
| AB | x86-64 | PBS Pro | 0 / 0 | `2044027.pbs1`, waiting, present |
| AB2 | x86-64 | PBS Pro | 0 / 0 | `2044028.pbs1`, waiting, present |
| RI | AArch64 | Slurm | 0 / 0 | `6862`, pending, present |
| AL | AArch64 | Slurm | 0 / 0 | `4221054`, pending, present |
| RC | x86-64 | Slurm | 0 / 0 | `210816`, pending, present |
| T4 | x86-64 | AGE | 0 / 0 | `8175651`, present |

Every T-191 chain is `active`; each captured smoke job is absent with private
state `verified-disabled`. The local five doctor warnings are the already
declared login/compute boundary for containers, CUDA debugger, and profilers,
not failures.

All checkouts were clean. Local was at collector revision `26690a8`; every
remote was at `a2823d3` (`Record weekly Restic production jobs`), an ancestor
36 commits behind. Every node had symlinks for Codex guidance, Codex deletion
rules, Claude guidance, and `.vimrc`. All ten tracked C/C++/Fortran/CUDA/MPI/
Python/LLM smoke sources had identical Git blob IDs across all nodes.

Managed baseline versions were consistent where intended: Node 24.16.0,
Claude Code 2.1.207, and Restic 0.19.1 on every node; Restic architecture was
amd64 except on AArch64 RI/AL. Codex was 0.144.5 locally and 0.144.4 remotely.
System compiler, Python, CMake, and Ninja versions remain site-specific. AL's
system Python 3.6.15 is too old for a modern LLM environment, but this is a
login baseline, not a requirement to replace the site interpreter.

AB, AB2, and T4 expose CUDA and MPI compiler commands in the login baseline.
Local, RI, AL, and RC do not. This must not be interpreted as compute absence:
those sites require their declared module, uenv, container, or allocation
route. T-200 will collect matched scheduler-native compute evidence before any
readiness claim.

## Drift requiring follow-up

The following exact top-level directories exist at default home paths despite
the storage policy. No contents or sizes were inspected during this audit:

- local: `.cache`, `.nv`
- AB: `.cache`, `.mozilla`
- AB2: `.cache`
- RI: `.cache`, `.apptainer`
- AL: `.mozilla`
- T4: `.cache`
- RC: none among the eleven audited paths

Some may be harmless recreations by applications that ignore XDG/cache
settings; `.mozilla` and `.apptainer` may contain state rather than disposable
cache. T-199 will first collect metadata-only size/ownership/mount evidence and
map each path to the already approved delete/move policy. Any multi-tree
deletion will use guarded manifests and revalidation; this audit authorizes no
cleanup.

## Interpretation boundary

This report proves login/control-plane consistency and preserves exact T-191
job state. It does not prove GPU type, driver/runtime compatibility, framework
imports, collectives, filesystem throughput, or multi-node training. Those
claims require scheduler-native allocated tests in site-declared environments,
starting with single-device/rank correctness before scale.
