# Common native HPC rules

Read this file completely after resolving an in-scope logical profile, then
read exactly one site reference selected by `SKILL.md`.

- Inspect the project script or native help before adding scheduler or runtime
  options. Replace every placeholder before printing or executing a command.
- Require the scheduler family's exact success grammar for one job ID, then
  query that ID and match its owner and name. A zero exit without a parseable,
  queryable ID is rejected or indeterminate.
- Capture and check the exit status of every collision/status query before
  parsing its output. Never convert a scheduler, DNS, or transport failure into
  a false empty result through an unchecked pipeline.
- Monitor or cancel only the captured job ID. Never use broad user-wide
  cancellation.
- The reviewed one-node/five-minute CPU routes in
  `~/harness/profiles/hpc-cpu-routes.tsv` and
  `~/harness/docs/bounded-cpu-routes.md` apply only to their stated readiness
  scope; they are not project, training, billing, or scaling authority.
- The selected target exposes native GDB and strace plus at least one of
  Valgrind or perf. Use project compiler flags, preserve bounded raw
  diagnostics, and reproduce compute failures inside the native allocation
  rather than inferring them from a login node.
- Run GPU profiling only inside the selected native allocation and project
  environment. A login-node tool version is capability discovery, not
  accelerator evidence.
- Select absent debugging, profiling, compiler, CUDA, MPI, module, uenv, or
  container support from the reviewed project environment. Never install a
  generic global toolchain to erase a site difference.
