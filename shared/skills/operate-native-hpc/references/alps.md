# CSCS Alps native HPC: `al`

Use Slurm `srun`/`sbatch`, `squeue -j JOB_ID`, and `scancel JOB_ID`. Consult the
[CSCS Alps documentation](https://docs.cscs.ch/alps/).

- Separate SSH invocations can land on different Daint login nodes with
  different device/inode identities for the same shared lexical home. Keep a
  guarded-delete plan/apply pair in one persistent SSH connection; never weaken
  account-home identity validation for load balancing.
- Slurm requires an explicit project account (`-A`). Ask for it; never infer it
  from files or past output.
- Use uenv explicitly. Automated commands use `uenv run`; Slurm jobs use native
  uenv integration. Never put `uenv start` in non-interactive startup.
- The login baseline intentionally does not expose Nsight CLI tools. Select
  debugging/profiling tools from the reviewed project uenv or image rather than
  installing a generic global CUDA toolkit.
- The locally present validated image is `prgenv-gnu/25.11:v1`; do not replace
  or pull it merely to chase a newer tag. A project may select another reviewed
  uenv.
- Bare login GCC 7.5 does not accept C++20. The validated process-local route is
  `uenv run prgenv-gnu/25.11:v1 --view=default -- c++`; its GCC 14.2 passes
  concepts and `std::span`. Keep selection explicit.
- The same uenv exposes `mpicc` and passes a singleton development smoke.
  Multi-rank validation still requires native Slurm allocation and selected
  uenv integration.
- Multi-node work uses explicit nodes, total tasks, and tasks-per-node with
  native `srun`; preserve uenv through Slurm rather than login inheritance.
- The same uenv exposes CUDA 12.9 `nvcc` and compiles the tracked kernel.
  Execute it only inside the native allocation with that uenv.
- Compute architecture is AArch64. Validate CUDA/MPI in the chosen uenv and
  allocation.
- Default GCC passes the tracked ASan+UBSan smoke directly.
