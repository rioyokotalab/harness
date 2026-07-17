# Multi-node MPI route decision record

## Decision

T-207 proves two ranks on one node for current, AB, AB2, AL, and T4. It does
not establish inter-node launch or fabric behavior. T-229 froze candidate
shapes in
[`profiles/hpc-multinode-mpi-routes.tsv`](../profiles/hpc-multinode-mpi-routes.tsv)
without submitting anything; T-251 later authorized one at-most-once execution
of the local, AB, AB2, and T4 routes.

| Node | Decision | Candidate allocation and launch | Remaining gate |
|---|---|---|---|
| current | terminal environment failure | `thrp_1`; 2 nodes, 2 tasks, 1 task/node; Open MPI `ppr:1:node` | job `91483` passed its source contract but compute-start `mpicc` was absent; at-most-once, no retry |
| AB | validated pass | `rt_HF`, `select=2:mpiprocs=1`; HPC-X with `$PBS_NODEFILE`, 1 rank/node | job `2046527.pbs1` passed with two ranks on two distinct hosts |
| AB2 | validated pass | same as AB under group `gah51624` | job `2046531.pbs1` passed with two ranks on two distinct hosts |
| RI | no base route | none | architecture-matched MPI environment is not selected |
| AL | validated pass | normal, 2 nodes, 2 tasks, 1 task/node, validated uenv; `srun` | correctness gate complete; performance and GPU-aware MPI remain separate |
| RC | no base route | none | architecture-matched MPI environment is not selected |
| T4 | terminal environment failure | `node_f=2`; Open MPI with 1 rank/node | job `8185316` passed its source contract but the compute environment lacked `ylab/hpcx/2.21.0`; at-most-once, no retry |

ABCI's official job guide says `rt_HC` is limited to one node and multi-node
jobs use `rt_HF`; its MPI guide demonstrates `select=2`, `$PBS_NODEFILE`, and
one rank per node. The live `rt_HF` queue on both accounts reports a 128-node
maximum. See the official [ABCI job options](https://docs.abci.ai/v3/en/job-execution/)
and [MPI guide](https://docs.abci.ai/v3/en/mpi/).

CSCS documents two-node allocation and `srun` task placement, while its uenv
guide shows the programming environment propagating through multi-node Slurm
steps. The live `normal` partition accepts multiple nodes, and the already
present `prgenv-gnu/25.11:v1` remains the frozen candidate. See the official
[Alps Slurm guide](https://docs.cscs.ch/running/slurm/) and
[uenv usage guide](https://docs.cscs.ch/software/uenv/using/).

TSUBAME's official guide defines `node_f=N` as full nodes and gives Open MPI
multi-node examples using one explicit process count and `LD_LIBRARY_PATH`
forwarding. It also warns that versions in examples can lag the live module
catalog, so the future gate must preserve the already proven `ylab/hpcx/2.21.0`
or separately validate a reviewed replacement. See the official
[TSUBAME scheduler/MPI guide](https://www.t4.cii.isct.ac.jp/docs/handbook.en/jobs/).

## Future acceptance gate

A future execution task must use a new source/result/job name, capture the
exact source revision with T-221, require exactly two distinct hostnames plus
world size two, parse one native scheduler ID and immediately reconcile owner
and name, retain scheduler and private-result exit zero, and use default
priority with a five-minute limit. It must submit at most once per approved
route and make no throughput, scaling, GPU-aware MPI, or production-fabric
claim. RI and RC remain excluded until their project environments are chosen.

## T-230 AL execution

AL v1 job `4224814` proved why node-local build staging is invalid: rank 1
could not see the executable compiled under rank 0's `/tmp`. That terminal
failure is retained privately and is not MPI/fabric evidence. V2 compiled the
same tracked gate in a unique mode-0700 directory under shared private state.
Job `4224822` then completed with scheduler/result zero, two ranks, two distinct
processor identities, exact queued-source provenance, and no build/capture
residue. Processor names were compared in the allocation but never published.

## T-251 fleet execution

AB job `2046527.pbs1` and AB2 job `2046531.pbs1` completed with
scheduler/result zero, two ranks, two distinct hosts, shared executable
visibility, and guarded zero residue. AL's existing `4224822` pass was not
repeated. Local job `91483` and T4 job `8185316` each passed the immutable source
contract and then stopped before MPI launch: local had no compute-start `mpicc`,
while T4 could not locate the previously proven `ylab/hpcx/2.21.0` module.
Their scheduler/result status is one, their job-scoped residue is zero, and the
at-most-once contract forbids automatic retries. RI and RC remain excluded by
the deferred project-environment decision. The terminal machine-readable
record is `docs/audits/hpc-multinode-mpi-readiness-2026-07-17.json`; no result
claims performance, scaling, GPU-aware MPI, or fabric quality.
