# ABCI native HPC: `ab` and `ab2`

Use PBS Pro `qsub`, `qstat JOB_ID`, and `qdel JOB_ID`; `nodestatus` is
available for discovery. Consult the
[ABCI 3.0 User Guide](https://docs.abci.ai/v3/en/).

- Suppress PBS lifecycle email by default for every agent-run job. Put
  `#PBS -m n` in an agent-generated script, or add `-m n` to the printed native
  `qsub` command when submitting a script without that directive. Override only
  when the owner explicitly requests notifications for that job. Never carry
  this PBS-specific default to another scheduler by inference.
- Every compute request needs an explicit billing group and resource request.
  Ask the owner or use an already-reviewed project script. Do not submit even a
  one-minute smoke with guessed values.
- For exact-ID history, emit only the required job identity, state, exit, and
  timestamps through a status-checked filter; never print PBS `Variable_List`.
- Login nodes expose a compiler/MPI baseline. Run GPU or scaled MPI checks only
  through a reviewed PBS allocation.
- Login PATH exposes `cuda-gdb`, `nsys`, and `ncu`. Run GPU capture only inside
  a reviewed PBS allocation and selected CUDA environment; login `--version`
  output is capability discovery, not profiling evidence.
- Multi-node MPI requires the full-node `rt_HF` resource; the proven `rt_HC`
  CPU gate is limited to one node. Preserve `$PBS_NODEFILE`, require an explicit
  rank-per-node mapping, and treat `rt_HF` as a new resource/cost gate.
- Default CUDA 13.2 `nvcc` compiling the tracked kernel on a login node is not
  driver or kernel-execution evidence.
- Default HPC-X `mpicc` passes a singleton development smoke. Retain login-node
  UCX fabric warnings and validate multi-rank transport only in the allocation.
- Default GCC advertises sanitizers but lacks runtime targets. For a
  process-local sanitizer build, run `module load gcc/15.2.0` and set
  `ASAN_OPTIONS=detect_leaks=0` because LeakSanitizer cannot operate in the
  site's ptrace context. Do not change the default compiler globally.
- Default GCC 11.5 passes the tracked C++20 concepts and `std::span` smoke.
