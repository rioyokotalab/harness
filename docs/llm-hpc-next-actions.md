# LLM and scientific HPC next actions

The canonical queue is
[`audits/llm-hpc-next-actions-2026-07-17.json`](audits/llm-hpc-next-actions-2026-07-17.json).
It consolidates only unfinished or newly proposed readiness work after T-234.

First, preserve and monitor local jobs `91220` (numerical) and `91240`
(checkpoint/restart). Both remain validly captured; ordinary resource/priority
delay does not authorize duplication. Safe engineering that does not require an
owner choice is then limited to a scheduler cpuset/topology gate and a native
test-only review of the local two-node MPI request. T-236 subsequently found no
residue-free scheduler verification interface, so that second item is now
blocked until the site provides one or an actual submission is separately
authorized. T-237 has implemented and locally validated the first gate; its
source is immutable and its seven bounded routes are ready for collision-
checked native submission. Six remote jobs are now captured: RI, AL, and T4
pass; AB and AB2 are queued; and RC's diagnostic SMT placement failure has a
narrow `--hint=nomultithread` v2 correction. Local remains held behind its two
older pending jobs.

The next high-value execution branch needs an explicit framework/version and
architecture-matched immutable artifacts. After that choice, run one locked
single-device correctness gate before any training, distributed framework, or
performance work. Scientific libraries similarly need project requirements
(parallel versus serial HDF5, NetCDF language bindings, FFTW, BLAS ABI/threading,
and MPI/compiler compatibility) before selecting site modules, uenvs, or
containers.

AB, AB2, and T4 multi-node MPI remain full-node resource decisions; AL alone
has a bounded distinct-host pass. RI and RC require architecture-matched
project or site environments before CUDA/MPI claims. None of these gates should
be erased by ad hoc home-directory package installation.
