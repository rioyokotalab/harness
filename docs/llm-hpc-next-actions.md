# LLM and scientific HPC next actions

The canonical queue is
[`audits/llm-hpc-next-actions-2026-07-17.json`](audits/llm-hpc-next-actions-2026-07-17.json).
It consolidates only unfinished or newly proposed readiness work after T-234.

The two formerly pending local gates are complete after the owner's T-251
relocation direction. Old Threadripper jobs `91220` (numerical) and `91240`
(checkpoint/restart) were exactly canceled. Corrected native Epyc jobs `91472`
and `91474` completed with scheduler/result zero, private PASS artifacts, and
zero job-scoped residue. Do not repeat them. Safe engineering that does not require an
owner choice is then limited to a scheduler cpuset/topology gate and a native
test-only review of the local two-node MPI request. T-236 subsequently found no
residue-free scheduler verification interface, so that second item is now
blocked until the site provides one or an actual submission is separately
authorized. T-237 has implemented and locally validated the first gate; its
source is immutable and its seven bounded routes are ready for collision-
checked native submission. Six remote jobs are now captured: RI, AL, and T4
pass; AB and AB2 are queued; and RC's diagnostic SMT placement failure has a
narrow `--hint=nomultithread` v2 correction. The former local hold is cleared.

T-240 adds one explicitly deferred successor: after T-237 finishes, validate
allocation-level NUMA memory policy/locality without turning it into a
benchmark. Login-surface tool presence is recorded now, but no login NUMA
count is a compute-node placement claim.

The next high-value execution branch needs an explicit framework/version and
architecture-matched immutable artifacts. After that choice, run one locked
single-device correctness gate before any training, distributed framework, or
performance work. Scientific libraries similarly need project requirements
(parallel versus serial HDF5, NetCDF language bindings, FFTW, BLAS ABI/threading,
and MPI/compiler compatibility) before selecting site modules, uenvs, or
containers.

T-241 supplies the value-free schema and one-question-at-a-time PIE interview
for both choices. The completed manifest belongs in the workload project; it
does not belong in this public fleet repository and does not itself authorize
downloads, a new billing route, publication, or scaling.

AB, AB2, and T4 multi-node MPI remain full-node resource decisions; AL alone
has a bounded distinct-host pass. RI and RC require architecture-matched
project or site environments before CUDA/MPI claims. None of these gates should
be erased by ad hoc home-directory package installation.
