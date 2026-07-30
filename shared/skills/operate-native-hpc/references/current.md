# Current-node native HPC

Use the local `yrun`/`ybatch` interface over Slurm. Query the returned job with
`squeue -j JOB_ID`; cancel only that captured ID with `scancel JOB_ID`. Run
native `yrun --help` and `ybatch --help` for the live interface.

- The validated GPU/MPI smoke is
  `~/harness/tests/smoke/jobs/local.slurm`.
- Login PATH exposes `cuda-gdb`, `nsys`, and `ncu`. Run GPU capture only inside
  the native allocation and selected CUDA environment; a login `--version` is
  capability discovery, not profiling evidence.
- `ybatch` submits asynchronously and treats later CLI arguments as script
  arguments, not scheduler options. Keep scheduler directives in the job
  script.
- `ybatch` has returned zero when underlying `sbatch` rejected a directive.
  Accept only its exact `Submitted batch job ID` line and immediately require
  `squeue -j ID` to match expected owner and job name. Otherwise reconcile by
  exact name/result and treat the attempt as having no captured job.
- A bare output name can be misclassified as a directory. Use tracked
  `.harness-smoke/%j.out`, monitor only the parsed ID, and remove only that
  output plus the empty `.harness-smoke` directory.
- Inside a one-node allocation, the validated two-rank route is
  `mpirun -n 2`; `srun -n 2` previously formed two rank-one singletons.
- The current Slurm/ybatch surface has no residue-free test-only mode. Direct
  `sbatch` is refused, native `/usr/bin/sbatch` exposes no verify option, and
  `ybatch -d` exits before cleaning its generated temporary script. Do not
  claim a multi-node dry run or bypass `ybatch` resource accounting.
- The reviewed `openmpi/5.0-cuda-12.8` module supplies `mpicc` and `mpirun`.
  Managed interactive shells load it only when no MPI compiler is selected;
  tracked jobs source `shell/module-stack.sh local`. Login initialization can
  report missing allocation-only `libcuda.so.1`; retain that diagnostic.
- The site-owned Docker/Podman wrapper requires its Slurm runtime directory.
  Invoke it only inside `yrun`/`ybatch`; do not bypass storage flags with
  `/usr/bin/podman` or select/pull an image implicitly.
- Default CUDA 12.8 `nvcc` compiling the tracked kernel is compiler evidence
  only; kernel execution still requires the native allocation smoke.
- Default GCC passes the tracked ASan+UBSan, C++20 concepts, and `std::span`
  development smokes.
