# R-CCS cloud native HPC: `rc`

Use Slurm `srun`/`sbatch`, `squeue -j JOB_ID`, and `scancel JOB_ID`. Consult the
[R-CCS Cloud portal and manual](https://portal.cloud.r-ccs.riken.jp/).

- Partitions are heterogeneous. Validated probes found AArch64 GH200
  (480 GB, driver 610.43.02) and AArch64 FX700 compute nodes while the login
  node is x86-64.
- Select the partition explicitly from project intent. Never run the login
  node's x86-64 managed Python on an AArch64 compute node.
- Base compute images expose neither CUDA toolkit nor MPI wrappers. Use the
  partition-native module or architecture-matched project container after
  inspecting current help.
- The login baseline intentionally does not expose Nsight CLI tools. Select
  debugging/profiling tools from the reviewed project image or module rather
  than installing a generic global CUDA toolkit.
- The login module catalog has no CUDA compiler. Do not install a generic login
  CUDA toolkit.
- Login-only `module load mpi/mpich-x86_64` passes a singleton development
  smoke but is incompatible with AArch64 compute partitions. Select and
  validate their native module or project container in the allocation.
- Login GCC cannot link its missing sanitizer runtimes, and no alternate GCC
  module, Clang, or static sanitizer archive was found. Record the site gap and
  run sanitizers in the reviewed project environment.
- Login GCC 11.5 passes C++20 concepts and `std::span`; revalidate on the
  selected compute architecture when the binary will not run on x86-64 login.
