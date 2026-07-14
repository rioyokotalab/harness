# Native LLM/HPC smoke sources

These tiny deterministic programs let an agent validate each site's native
compiler, build, MPI, accelerator, and Python path without cloning a project or
hiding scheduler semantics behind a harness wrapper. Build outputs belong in a
temporary directory. MPI and CUDA programs run only through the site's native
allocation command; the agent must report that exact command before execution.

The CPU programs perform closed-form-checked reductions. The MPI program checks
the rank sum. The CUDA program checks a device kernel and synchronization. The
Python program uses only the standard library and is suitable for a fresh uv
virtual environment. Project-specific PyTorch, CUDA, MPI, and numerical-library
versions remain in project lockfiles or site environments.

For the common CPU/build path, configure out of tree with the native command
`cmake -S tests/smoke -B BUILD -G Ninja`, then run `cmake --build BUILD` and
`ctest --test-dir BUILD --output-on-failure`. The MPI and CUDA sources are not
part of that login-node build because their environment and execution route are
site-specific.

`jobs/local.slurm` is the current node's native `ybatch` smoke. It requests the
smallest A4500 resource and validates CUDA runtime, two-rank MPI, and Python.
The site wrapper submits asynchronously and does not forward later scheduler
options before its temporary script, so the job declares a job-ID-scoped output
file itself. The agent parses the submitted ID, monitors only that job, validates
the output, and removes it. The script does not normalize or conceal the
generated Slurm commands.
