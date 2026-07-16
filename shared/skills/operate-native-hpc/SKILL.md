---
name: operate-native-hpc
description: Plan, execute, monitor, validate, and clean up LLM training, GPU, MPI, and HPC development work through each configured system's visible native scheduler, environment, module, uenv, and container commands. Use for workload readiness, allocations, job submission, distributed runs, accelerator or MPI smoke tests, project environment entry, scheduler diagnosis, and matched performance experiments on the current node or the in-scope ab, ab2, ri, al, rc, and t4 targets.
---

# Operate Native HPC

Use native site interfaces without normalizing away scheduler, account,
resource, architecture, or container semantics. Print the exact resolved command
before executing it and report the same command with its result.

## Reconstruct scope

1. Read the closest project instructions and durable ledger. Treat an
   already-present project as the workload owner; never clone a project, model,
   or dataset implicitly.
2. Resolve the logical target through `~/harness/profiles/hosts/HOST.conf`.
   Reject aliases without a profile. Never deploy or run workloads on proxy
   nodes, `si`, `web`, or `github`.
3. Read [references/sites.md](references/sites.md) for the selected target.
4. Identify the requested correctness gate, resource shape, duration, project
   environment, output paths, and whether the operation can consume allocation
   or billing points.

## Form the native plan

- Inspect native help or an existing project job script when syntax is not
  already evidenced. Do not guess account, group, partition, queue, resource,
  image, or module names.
- Show the fully resolved command prefixed with `NATIVE` before execution.
  Place no hidden scheduler wrapper between the user and `sbatch`, `srun`,
  `qsub`, `yrun`, `ybatch`, `uenv`, `apptainer`, or `singularity`.
- Stop for the owner when a required billing group or project account is
  missing. A cheap job is still chargeable.
- Separate login-node checks from compute-node evidence. Never interpret a
  missing login driver or an exposed login GPU as workload readiness.
- Keep CUDA, ROCm, MPI, compilers, numerical libraries, modules, uenvs, and
  containers site- or project-native. Never install a generic global framework
  to erase an intentional site difference.

For a Python project, prefer its lockfile and an isolated environment. Use
`uv sync --frozen` only when the checked-out project declares that workflow.
Install Git LFS hooks only inside an in-scope repository with an explicit
`git lfs install --local`; never alter global filters implicitly.

## Execute and monitor

1. Freeze a correctness baseline before optimization. Use the tracked
   `~/harness/tests/smoke/` sources only for environment validation, not as a
   substitute for project tests.
   For a queued version-controlled job, capture the submitted revision and
   verify the declared job/source paths are unchanged when compute starts;
   repository HEAD alone is too strict for unrelated successors and too weak
   when relevant working-tree bytes drift.
2. Submit or launch the exact native command. Require the scheduler family's
   exact success grammar for one returned job ID, then immediately query that
   ID and match its owner/name before treating submission as accepted. A zero
   wrapper exit status without a parseable, queryable ID is a rejected or
   indeterminate submission, never success. Capture the exact output path
   without scraping unrelated jobs.
3. Monitor only that job with the site's native status command. Report state
   changes and meaningful output; unchanged queued state is normal.
4. Cancel only the captured job ID when cancellation is requested or a verified
   safety condition requires it. Never use broad user-wide cancellation.
5. Remove only job-scoped temporary builds and output created for the smoke
   test. Preserve project logs, scheduler evidence, and unrelated files.

## Validate the result

Match validation to the workload:

- CPU/build: configure out of tree, build, run tests, and record compiler,
  architecture, and exact commands.
- GPU: validate compute-node device, driver, runtime/kernel execution, and
  framework/device agreement. Do not claim toolkit readiness from
  `nvidia-smi` alone.
- MPI/distributed: require the intended world size and rank uniqueness. Treat
  singleton launches as failure even when every process exits zero.
- LLM training: validate a bounded forward/backward or project smoke step,
  device placement, distributed initialization, checkpoint/output path, and
  finite loss before scaling.
- Performance: compare matched commands, inputs, resources, affinity, software
  environment, warmup, and repetitions. Preserve raw evidence and distinguish
  observation from inference.

Record the target, native commands, job ID, environment mechanism, resource
shape, correctness results, failures, cleanup, and next action in the project
ledger or `~/harness/TODO.md`. Never record credential values or full
environment dumps.
