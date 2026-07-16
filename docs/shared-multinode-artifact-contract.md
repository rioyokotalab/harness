# Shared multi-node executable contract

T-230 v1 compiled a correct MPI executable under the first AL node's private
`/tmp`; rank 1 failed before MPI startup because that path did not exist on the
second node. T-231 turns the lesson into a reusable gate.

For a multi-node job, a newly built executable and every required runtime input
must either live under an explicitly reviewed shared boundary or be staged and
verified separately on every node. Rank-local `TMPDIR` and `SLURM_TMPDIR` are
not shared evidence. Before the application launch, each node must require a
regular, non-symlink, executable path canonically below the boundary and verify
the same expected SHA-256. The controller must require exactly one pass record
per intended node/rank without publishing node identities.

[`shared-executable-visibility.sh`](../tests/smoke/jobs/shared-executable-visibility.sh)
implements the per-rank check. It is deliberately restricted to a caller-
declared build boundary and a newly built public executable; never point it at
credential, authentication, private-data, or unrelated owner paths. Digest
agreement proves byte visibility only, not ABI compatibility, launch success,
filesystem coherence under mutation, or application correctness.
