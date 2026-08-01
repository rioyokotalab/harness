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
- Exact-ID history or status evidence must expose only job ID, name, owner,
  state, exit status, and required timestamps. Filter with checked pipeline
  status; never print PBS `Variable_List`, environment, or unrelated jobs.
  Terminal `F` alone is not success when the site omits exit status; require
  separate accounting or private chain evidence.
- `rt_QC` is CPU-only and `rt_QG` is one shared H100. Multi-node work requires
  full-node `rt_QF`, explicit process placement, and a separately reviewed
  cost/resource decision.
- Treat login CUDA, MPI, and profiling as discovery; validate them in the
  selected allocation.
- Use the declared environment; never install a global replacement toolchain.
