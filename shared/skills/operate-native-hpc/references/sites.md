# Configured native HPC sites

Use this reference only after resolving an in-scope logical profile. Facts here
are validated baselines, not permission to guess a project's resource choices.

## Common status and cancellation

| Target | Scheduler | Submit/launch | Status | Cancel |
|---|---|---|---|---|
| current | local `yrun`/`ybatch` over Slurm | `yrun`, `ybatch` | native returned Slurm ID and `squeue` | `scancel JOB_ID` |
| `ab`, `ab2` | PBS Pro | `qsub` | `qstat JOB_ID` | `qdel JOB_ID` |
| `ri`, `al`, `rc` | Slurm | `srun` or `sbatch` | `squeue -j JOB_ID` | `scancel JOB_ID` |
| `t4` | AGE | `qsub` or `qrsh` | `qstat JOB_ID` | `qdel JOB_ID` |

Always inspect the project script or native help before adding options. Replace
every placeholder before printing and executing a command.

## Debugging and profiling

- Every target has native GDB and strace plus at least one of Valgrind or perf.
  Use the project's compiler flags and preserve raw diagnostics; never infer a
  compute-node failure from a login-only reproduction.
- Current, `ab`, `ab2`, and `t4` expose `cuda-gdb`, Nsight Systems (`nsys`), and
  Nsight Compute (`ncu`) on the login path. Run GPU capture only inside the
  site's native allocation and selected CUDA environment. A successful
  login-node `--version` is capability discovery, not GPU profiling evidence.
- `ri`, `al`, and `rc` intentionally do not expose the Nsight CLI baseline.
  Select debugging/profiling tools from the reviewed project image, module, or
  uenv rather than installing a generic global CUDA toolkit.

## Current node

- Use the native `yrun`/`ybatch` interface. The validated GPU/MPI smoke is
  `~/harness/tests/smoke/jobs/local.slurm`.
- `ybatch` submits asynchronously and treats later CLI arguments as script
  arguments, not scheduler options. Keep scheduler directives inside the job
  script.
- A bare output name can be misclassified as a directory. Use the tracked
  `.harness-smoke/%j.out`, parse the returned job ID, monitor only that ID, and
  remove only its output plus the empty `.harness-smoke` directory.
- Inside the one-node allocation, the validated two-rank route is native
  `mpirun -n 2`; `srun -n 2` previously formed two rank-one singletons.
- The site-owned Docker/Podman wrapper expects its Slurm runtime directory and
  is unusable on the login node. Invoke it only inside `yrun`/`ybatch`; do not
  bypass its storage flags with `/usr/bin/podman`. The tracked job checks both
  native entry points before GPU/MPI work without selecting or pulling an image.
- The default GCC passes the tracked ASan+UBSan smoke directly.
- The default GCC passes the tracked C++20 concepts and `std::span` smoke.

## ABCI: `ab` and `ab2`

- Use PBS Pro `qsub`, `qstat`, and `qdel`; `nodestatus` is available for site
  discovery.
- Every compute request needs an explicit billing group and resource request.
  Ask the owner for both or use an already-reviewed project script. Do not
  submit even a one-minute smoke with guessed values.
- Login nodes expose a native compiler/MPI baseline. Run GPU or scaled MPI
  checks only through a reviewed PBS allocation.
- The default GCC advertises sanitizers but cannot link its missing runtime
  targets. For a process-local sanitizer build, run native `module load
  gcc/15.2.0`, compile with GCC, and set `ASAN_OPTIONS=detect_leaks=0` because
  LeakSanitizer cannot operate under this site's ptrace context. ASan and UBSan
  are validated; do not change the default compiler globally.
- The default GCC 11.5 passes the tracked C++20 concepts and `std::span` smoke.

## RIKEN Rikyu: `ri`

- Slurm has a validated default one-minute compute route. A compute probe saw
  NVIDIA GB200, driver 580.159.03, and compute capability 10.0.
- The base compute environment has no `nvcc` or MPI wrapper. Put CUDA toolkit,
  framework, and MPI user dependencies in the project's explicit image or
  environment; do not install them globally.
- Login context exposes Apptainer 1.4.5 compatibility and Slurm OCI flags.
  Inspect current native help and the project's image before choosing one.
- Architecture is AArch64. Use architecture-matching images and binaries.
- The default GCC passes the tracked ASan+UBSan smoke directly.
- The default GCC passes the tracked C++20 concepts and `std::span` smoke.

## CSCS Alps: `al`

- Slurm requires an explicit project account (`-A`). Ask for it; never infer it
  from local files or past output.
- Use uenv explicitly. Automated commands use native `uenv run`; Slurm jobs use
  the site's native uenv integration. Never put `uenv start` in non-interactive
  startup.
- The locally present validated image is `prgenv-gnu/25.11:v1`; it is large and
  should not be replaced or pulled merely to chase a newer tag. A project may
  select a different reviewed uenv.
- The bare login GCC 7.5 does not accept `-std=c++20`. The validated
  process-local route is `uenv run prgenv-gnu/25.11:v1 --view=default -- c++`;
  its Spack GCC 14.2 passes the tracked concepts and `std::span` smoke. Keep the
  uenv selection explicit rather than changing the login compiler globally.
- Compute architecture is AArch64. Validate CUDA/MPI inside the chosen uenv and
  allocation, not from the login baseline.
- The default GCC passes the tracked ASan+UBSan smoke directly.

## R-CCS cloud: `rc`

- Slurm partitions are heterogeneous. Validated probes found AArch64 GH200
  (480 GB, driver 610.43.02) and AArch64 FX700 compute nodes while the login
  node is x86-64.
- Select the partition explicitly from project intent. Never run the login
  node's x86-64 managed Python on an AArch64 compute node.
- Base compute images expose neither CUDA toolkit nor MPI wrappers. Use the
  partition's native module or an architecture-matched project container after
  inspecting current site help.
- The login default GCC cannot link its missing sanitizer runtime targets; no
  alternate GCC module, Clang, or static sanitizer archive was found. Record
  this as a site gap and run sanitizers in the reviewed project environment.
- The login default GCC 11.5 passes the tracked C++20 concepts and `std::span`
  smoke. Revalidate on the selected compute architecture when the built binary
  will not run on the x86-64 login node.

## TSUBAME: `t4`

- Use AGE `qsub`, `qstat`, `qdel`, and `qrsh`, not generic PBS assumptions.
- Compute requests need an explicit group and resource. Ask the owner or use an
  already-reviewed project script; do not guess and consume points.
- Login CUDA/MPI commands and absent login driver state do not establish GPU
  readiness. Validate them inside the AGE allocation.
- For a process-local sanitizer build, run native `module load gcc/14.2.0`.
  The tracked ASan, UBSan, and LeakSanitizer smoke passes with that module; do
  not change the default compiler globally.
- The default GCC 11.5 passes the tracked C++20 concepts and `std::span` smoke.
