# TSUBAME native HPC: `t4`

Use AGE `qsub`/`qrsh`, `qstat JOB_ID`, and `qdel JOB_ID`, not generic PBS
assumptions. Consult the
[TSUBAME4 documentation index](https://www.t4.cii.isct.ac.jp/docs/all/).

- Compute requests need an explicit group and resource. Ask the owner or use an
  already-reviewed project script; do not guess or consume points.
- Login CUDA/MPI commands and absent login driver state do not establish GPU
  readiness. Validate them inside the AGE allocation.
- Login PATH exposes `cuda-gdb`, `nsys`, and `ncu`. Run GPU capture only inside
  the AGE allocation and selected CUDA environment; login `--version` output is
  capability discovery, not profiling evidence.
- Default CUDA 12.8 `nvcc` compiling the tracked kernel is compiler evidence
  only until the binary runs in AGE.
- Default HPC-X `mpicc` passes a singleton development smoke. Validate
  multi-rank transport only inside AGE.
- Multi-node MPI uses full `node_f=N` resources and an explicit
  processes-per-node mapping. The proven fractional `cpu_4` gate must not be
  scaled into a multi-node claim; `node_f` is a separate points/resource
  decision.
- For a process-local sanitizer build, run `module load gcc/14.2.0`. The
  tracked ASan, UBSan, and LeakSanitizer smoke passes with that module; do not
  change the default compiler globally.
- Default GCC 11.5 passes the tracked C++20 concepts and `std::span` smoke.
