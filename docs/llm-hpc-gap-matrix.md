# LLM and scientific HPC fleet gap matrix

This matrix consolidates validated evidence as of 2026-07-17. The canonical
machine-readable record is
[`audits/llm-hpc-gap-matrix-2026-07-17.json`](audits/llm-hpc-gap-matrix-2026-07-17.json).
It deliberately distinguishes a tested pass, a directly observed or declared
gap, an owner-gated choice, a captured pending job, and work that has not been
tested. “Not tested” never means unavailable.

| Node | CPU / storage / checkpoint / offline Python / frozen lock | CUDA kernel | MPI, 2 ranks / 1 node | Numerical | Debugger | Immutable image runtime | LLM framework |
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
T-227 additionally proves the same dependency-free frozen/offline project lock
on all seven login nodes, with identical lock digest and guarded cleanup.
T-230 proves one bounded two-node/two-rank distinct-host MPI route on AL; the
other six nodes retain their prior multi-node status.
The immutable transport mechanisms are designed in
[`immutable-environment-matrix.md`](immutable-environment-matrix.md), but no
immutable image runtime execution is claimed.

## What the matrix says to do next

1. Monitor only local numerical job `91220`; do not duplicate it. Its terminal
   evidence is the sole pending result in an otherwise six-node pass.
2. Monitor only local checkpoint/restart job `91240`; do not duplicate it. The
   other six nodes already pass the architecture-neutral restart-equivalence
   gate with guarded checkpoint cleanup.
3. T-200 already proved a two-thread OpenMP reduction on every node. A later
   CPU follow-up should therefore test scheduler cpuset/topology binding rather
   than repeat basic OpenMP arithmetic.
4. T-227 closes only the dependency-free frozen-lock control-plane gate.
   Third-party wheel availability and immutable image execution remain behind
   T-206's framework/artifact choice.
5. AL now passes the bounded two-node MPI correctness gate. Local still needs a
   wrapper dry-run; AB, AB2, and T4 require explicit full-node resource changes;
   RI and RC still need architecture-matched MPI environments.
6. Keep framework/image selection under T-206's owner gate. Once selected, run
   one locked, architecture-matched single-device LLM smoke before distributed
   or performance work.
7. Treat RI/RC CUDA and MPI routes plus ABCI ptrace as site-specific gaps; seek
   documented site support instead of installing ad hoc base-home packages or
   bypassing policy.

No row claims training throughput, multi-node fabric performance, GPU-aware MPI,
framework correctness, mixed precision, large-model memory fit, or scientific
application accuracy.
