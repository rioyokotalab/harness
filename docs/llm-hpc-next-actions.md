# LLM and scientific HPC next actions

The canonical queue is
[`audits/llm-hpc-next-actions-2026-07-17.json`](audits/llm-hpc-next-actions-2026-07-17.json).
It consolidates only unfinished or newly proposed readiness work after T-234.

The two formerly pending local gates are complete after the owner's T-251
relocation direction. Old Threadripper jobs `91220` (numerical) and `91240`
(checkpoint/restart) were exactly canceled. Corrected native Epyc jobs `91472`
and `91474` completed with scheduler/result zero, private PASS artifacts, and
zero job-scoped residue. Do not repeat them. Safe engineering that did not
require an owner choice was then limited to a scheduler cpuset/topology gate
and a native test-only review of the local two-node MPI request. T-236 found no
residue-free scheduler verification interface; T-251 later authorized one
bounded actual submission instead. That local attempt passed its source
contract but stopped at the unavailable post-restart `mpicc` route and is not
retried. T-237's six remote routes now pass, including RC's narrow
`--hint=nomultithread` v2 correction. The former local hold is cleared, and
exact local job `91581` is captured pending for resources.

T-240 adds one explicitly deferred successor: after T-237 finishes, validate
allocation-level NUMA memory policy/locality without turning it into a
benchmark. Login-surface tool presence is recorded now, but no login NUMA
count is a compute-node placement claim.

T-251 selected CPython 3.12 plus PyTorch 2.12.1/CUDA 13.0 as the first
framework release. Two immutable architecture-matched wheelhouses and all
seven locked single-device correctness gates pass; retain them without repeat
or floating upgrades. Scientific libraries still need project requirements
(parallel versus serial HDF5, NetCDF language bindings, FFTW, BLAS ABI/threading,
and MPI/compiler compatibility) before selecting site modules, uenvs, or
containers.

T-241 supplies the value-free schema and one-question-at-a-time PIE interview
for both choices. The completed manifest belongs in the workload project; it
does not belong in this public fleet repository and does not itself authorize
downloads, a new billing route, publication, or scaling.

AB and AB2's authorized full-node two-node MPI routes pass. T4's at-most-once
full-node route stopped before launch because its compute environment could not
locate the declared HPC-X module, while local stopped at its unavailable MPI
compiler; neither is retried. AL retains its bounded distinct-host pass. RI and
RC require architecture-matched project or site environments before MPI
claims. None of these gates should be erased by ad hoc home-directory package
installation.
