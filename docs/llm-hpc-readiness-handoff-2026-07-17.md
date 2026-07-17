# LLM/HPC readiness window handoff

This capsule is the durable resume point for the 2026-07-16/17 eight-hour
workstream. It supplements the detailed task records in `TODO.md` and the
canonical queue in `docs/audits/llm-hpc-next-actions-2026-07-17.json`.

## Captured work still active

| Node | Task | Job | Current state | Fixed private result |
|---|---|---|---|---|
| local | T-210 numerical | `91220` | pending: Resources, start unknown | `t210-numerical-local-v1.out` absent |
| local | T-217 checkpoint/restart | `91240` | pending: Priority, start unknown | `t217-checkpoint-restart-local-v1.out` absent |

Never replace, duplicate, reprioritize, cancel, or broaden these requests merely
because they are delayed. Query only the captured ID. A terminal claim requires
native scheduler accounting plus the regular, mode-0600 fixed result and zero
job-scoped capture temp. The queued T-210/T-217 source paths remain immutable.

The local T-237 affinity route has not been submitted. Hold it until both older
local readiness jobs are terminal; then run the fail-closed preflight for exact
name `t237alocal`, result `t237-affinity-local-v1.out`, and temp prefix
`.t237-affinity-local-v1` before one native `ybatch` submission. The wrapper has
no residue-free dry-run mode.

## T-237 completed evidence

AB `2045152.pbs1`, AB2 `2045153.pbs1`, RI `7020`, AL `4225162`, RC correction
`211079`, and T4 `8182351` have terminal scheduler/result status zero. The AB
and AB2 results additionally pass the frozen source contract and leave zero
capture temporaries. RC v1 `211077` is intentionally preserved as a diagnostic
status-2 result: two allocated logical CPUs exposed one physical core. V2
added `--hint=nomultithread`, exposed two physical cores, and passed. Do not
delete or overwrite either RC result.

## Readiness layers completed in this window

- T-226–T-234 hardened fail-closed fleet control identity, frozen/offline
  environments, scientific-library discovery, AL two-node MPI, shared
  executable visibility, complete smoke-tree identity, and private-result
  hygiene.
- T-235/T-236 consolidated the priority queue and proved the local multi-node
  MPI route has no safe test-only interface.
- T-237 added the non-benchmark allocation affinity/topology gate; all six
  remote nodes pass and the local route remains held behind two older jobs.
- T-238 added a cross-scheduler fail-closed collision preflight after a real RI
  DNS/config transient demonstrated why unchecked status pipelines are unsafe.
- T-239 found all seven nodes clean, control-plane 34/0/0, identical smoke-tree
  identity, valid private results, and zero capture temps.
- T-240 recorded the seven-node topology login surface without turning login
  NUMA counts into compute claims.
- T-241–T-245 added a one-question-at-a-time, closed project intake schema and
  a dependency-free, Python-3.6-compatible, fail-closed validator. Its complete
  synthetic suite passes on every node's default Python.

## Next safe order

1. Poll only the two active IDs above. Reconcile any terminal job immediately
   against its fixed result; preserve failures for diagnosis.
2. Close T-210/T-217 when local accounting and results agree. Only then submit
   the held local T-237 route after its fresh collision preflight.
3. Close T-237/Q3 after local passes or retain an explicit diagnosed gap. Q10
   (allocation-level NUMA memory-policy correctness) remains blocked until
   then and is not a benchmark.
4. For a real workload, use `docs/hpc-project-intake.md` through PIE and validate
   the project-owned manifest with
   `tools/hpc-project-intake-validate.py --require-ready`. Q5/Q6 remain owner or
   project gated until that interview supplies framework/library/artifact
   choices.
5. Keep multi-node AB/AB2/T4 resource changes, RI/RC project environments,
   retention/prune, and external settings behind their existing explicit
   gates. Never erase a site difference with an ad hoc home install.

Protected T-191 Sunday jobs remain local `90939`, AB `2044027.pbs1`, AB2
`2044028.pbs1`, RI `6862`, AL `4221054`, RC `210816`, and T4 `8175651`.
Do not cancel or duplicate them. Website's unrelated dirty driver files were
not inspected, mutated, staged, or committed during this workstream.
