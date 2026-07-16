# LLM and scientific HPC fleet gap matrix

This matrix consolidates validated evidence as of 2026-07-17. The canonical
machine-readable record is
[`audits/llm-hpc-gap-matrix-2026-07-17.json`](audits/llm-hpc-gap-matrix-2026-07-17.json).
It deliberately distinguishes a tested pass, a directly observed or declared
gap, an owner-gated choice, a captured pending job, and work that has not been
tested. “Not tested” never means unavailable.

| Node | CPU / storage / checkpoint / offline Python | CUDA kernel | MPI, 2 ranks / 1 node | Numerical | Debugger | Immutable environment | LLM framework |
|---|---|---|---|---|---|---|---|
| current (`local`) | pass | pass | pass | pending `91220` | direct pass | not tested | owner-gated |
| AB | pass | pass | pass | pass | ptrace-policy gap | not tested | owner-gated |
| AB2 | pass | pass | pass | pass | ptrace-policy gap | not tested | owner-gated |
| RI | pass | no reviewed toolkit | no reviewed route | pass | direct pass | not tested | owner-gated |
| AL | pass | pass | pass | pass | direct pass | not tested | owner-gated |
| RC | pass; sanitizer gap | no reviewed toolkit | no reviewed route | pass | direct pass | not tested | owner-gated |
| T4 | pass | pass | pass | pass | compute pass; login limit | not tested | owner-gated |

The evidence sources are the [scheduler-native CPU and accelerator report](hpc-readiness.md),
the [MPI audit](audits/hpc-mpi-readiness-2026-07-17.json), the T-210 numerical
records, the T-212/T-213 debugger records, the T-209/T-211 storage and
checkpoint records, and the T-214 offline-environment record in `TODO.md`.
The immutable transport mechanisms are designed in
[`immutable-environment-matrix.md`](immutable-environment-matrix.md), but no
image or environment execution is claimed.

## What the matrix says to do next

1. Monitor only local numerical job `91220`; do not duplicate it. Its terminal
   evidence is the sole pending result in an otherwise six-node pass.
2. Add a bounded scheduler-native OpenMP thread/reduction gate. It exercises a
   common scientific-HPC execution mode with existing compilers and no package,
   image, credential, or owner-setting change.
3. Add a bounded checkpoint/restart application gate on the already validated
   persistent-storage primitive. This should prove restart semantics, not just
   atomic publication.
4. Plan multi-node MPI separately on the five supported routes. It needs
   explicit two-node resource review and must not be inferred from the current
   one-node evidence.
5. Keep framework/image selection under T-206's owner gate. Once selected, run
   one locked, architecture-matched single-device LLM smoke before distributed
   or performance work.
6. Treat RI/RC CUDA and MPI routes plus ABCI ptrace as site-specific gaps; seek
   documented site support instead of installing ad hoc base-home packages or
   bypassing policy.

No row claims training throughput, multi-node fabric behavior, GPU-aware MPI,
framework correctness, mixed precision, large-model memory fit, or scientific
application accuracy.
