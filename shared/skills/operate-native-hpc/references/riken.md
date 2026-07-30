# RIKEN RIKYU native HPC: `ri`

Use Slurm `srun`/`sbatch`, `squeue -j JOB_ID`, and `scancel JOB_ID`. Consult the
[official RIKYU announcement](https://www.riken.jp/en/news_pubs/news/2026/20260619_1/index.html).
No public user guide was found as of 2026-07-15; inspect site-local help and do
not substitute commands from another RIKEN system.

- A validated default one-minute compute route exposed NVIDIA GB200, driver
  580.159.03, and compute capability 10.0.
- The only visible partition is `gpu`. Site policy injects one GB200 and
  400 GiB even with `--gres=none`; do not describe a job as CPU-only or assume
  a no-GPU allocation.
- The base compute environment has no `nvcc` or MPI wrapper. Put CUDA,
  frameworks, and MPI dependencies in an explicit project image or environment;
  never install them globally.
- No login MPI compiler or module catalog is exposed. Run singleton and
  multi-rank gates inside the reviewed project container or environment.
- The login baseline intentionally does not expose Nsight CLI tools. Select
  debugging/profiling tools from the reviewed project image or environment;
  never install a generic global CUDA toolkit.
- Login context exposes Apptainer 1.4.5 compatibility and Slurm OCI flags.
  Inspect current help and the project image before choosing one.
- Architecture is AArch64. Require architecture-matching images and binaries.
- Default GCC passes the tracked ASan+UBSan, C++20 concepts, and `std::span`
  development smokes.
