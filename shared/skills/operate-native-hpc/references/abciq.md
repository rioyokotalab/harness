# ABCI-Q native HPC: `abq`

Use PBS Pro `qsub`, `qstat JOB_ID`, and `qdel JOB_ID`. Consult the official
[ABCI-Q status page](https://unit.aist.go.jp/g-quat/HowToUse/abci_q/#status)
and [System H user guide](https://g-quat-abciq.github.io/abciq-docs/ja/job-execution/).

- Check the status page before contacting the site. If a current service stop
  or maintenance interval covers the attempt, report maintenance and do not
  probe either SSH route.
- Every submission requires the declared System H group and resource type.
  Use an already-reviewed project/profile value; never infer either from
  account output. A zero exit is insufficient unless `qsub` returns exactly one
  `JOB_ID.qjcm`, followed by an owner/name-matched `qstat` result.
- Exact-job evidence emits only ID, name, owner, state, exit status, and needed
  timestamps. Use checked filters; never print PBS `Variable_List`, environment,
  or unrelated jobs. If text omits exit status, request exact-job JSON and parse
  remotely so unfiltered data never crosses SSH. `F` alone is not success;
  require `Exit_status=0` or private chain evidence.
- `rt_QC` is CPU-only and `rt_QG` is one shared H100. Multi-node work requires
  full-node `rt_QF`, explicit process placement, and a separately reviewed
  cost/resource decision.
- Treat login CUDA, MPI, and profiling as discovery; validate them in the
  selected allocation.
- Use the declared environment; never install a global replacement toolchain.
