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

`llm_torch.py` is a bounded framework gate for an already-selected project or
site PyTorch environment. A single process runs a tiny language-model
forward/backward step, requires finite nonzero gradients, verifies an optimizer
update and device placement, and emits no checkpoint. Under native `torchrun`,
it also initializes the process group and requires unique ranks. Example native
commands, after entering the reviewed environment, are
`python tests/smoke/llm_torch.py --device cuda --require-world-size 1` and
`torchrun --standalone --nproc-per-node=2 tests/smoke/llm_torch.py --device cuda
--require-world-size 2`. The script never resolves or installs PyTorch.

For the common CPU/build path, configure out of tree with the native command
`cmake -S tests/smoke -B BUILD -G Ninja`, then run `cmake --build BUILD` and
`ctest --test-dir BUILD --output-on-failure`. The MPI and CUDA sources are not
part of that login-node build because their environment and execution route are
site-specific.

`sanitizer.c` checks the native C compiler and AddressSanitizer/UBSan runtime.
Build it in a temporary directory with `cc -O1 -g
-fsanitize=address,undefined -fno-omit-frame-pointer tests/smoke/sanitizer.c -o
BUILD/sanitizer`, then execute `BUILD/sanitizer`. A zero exit plus
`sanitizer=pass` is the gate; compiler success alone is insufficient.

`cpp20.cpp` checks a real C++20 concepts-and-span compile and execution. Use the
native `c++ -std=c++20 -O2 tests/smoke/cpp20.cpp -o BUILD/cpp20`, then execute
`BUILD/cpp20` and require `cpp20=pass`. An old site default is not a reason to
install or globally select a new compiler; enter the reviewed module, uenv, or
project toolchain and report that exact native command.

`jobs/local.slurm` is the current node's native `ybatch` smoke. It requests the
smallest A4500 resource and validates CUDA runtime, two-rank MPI, and Python.
The site wrapper submits asynchronously and does not forward later scheduler
options before its temporary script, so the job declares a job-ID-scoped output
file under `.harness-smoke/` itself. Including a directory component is
intentional: `ybatch` otherwise mistakes a bare output filename for a directory.
The agent parses the submitted ID, monitors only that job, validates the output,
and removes both it and the empty output directory. The script does not
normalize or conceal the generated Slurm commands. The current node's
site-owned Docker/Podman wrapper deliberately redirects rootless storage and
its runtime directory for Slurm. Its native `--version` path fails on the login
node but is checked inside this allocation before the CUDA and MPI gates; image
selection and execution remain project-specific.
