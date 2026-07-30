# Validate and record

Read the closest project instructions and accepted plan. Use compute-node
evidence and match validation to the workload:

- CPU/build: configure out of tree, build, run tests, and record the compiler,
  architecture, and exact commands.
- GPU: validate the compute-node device, driver, runtime or kernel execution,
  and framework/device agreement. `nvidia-smi` alone is not toolkit readiness.
- MPI/distributed: require the intended world size and unique ranks. Treat
  singleton launches as failure even when every process exits zero.
- LLM training: require a bounded forward/backward or project smoke step,
  device placement, distributed initialization, checkpoint or output path, and
  finite loss before scaling.
- Performance: compare the frozen baseline with matched commands, inputs,
  resources, affinity, software environment, warmup, and repetitions. Preserve
  raw evidence and distinguish observation from inference.

Record the target, exact native commands, job ID, environment mechanism,
resource shape, correctness results, failures, narrow cleanup, and next action
in the project ledger or `~/harness/TODO.md`. Record neither credentials nor a
full environment dump.
