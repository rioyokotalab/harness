# Scope and native planning

1. Read the closest project instructions and durable ledger. Treat an
   existing project as the workload owner; never clone a project, model, or
   dataset implicitly.
2. Identify the requested correctness gate, resource shape, duration, project
   environment, output paths, and whether the operation consumes allocation
   or billing points.
3. Inspect native help or an existing project job script when syntax is not
   already evidenced. Never guess an account, group, partition, queue,
   resource, image, module, or container.
4. Separate login-node discovery from compute-node evidence. A missing login
   driver or exposed login GPU proves neither failure nor workload readiness.
5. Keep CUDA, ROCm, MPI, compilers, numerical libraries, modules, uenvs, and
   containers site- or project-native.
6. Freeze a correct baseline before optimization. Harness smoke sources
   validate the environment; they never replace project correctness tests.

For Python, prefer the project's lockfile and an isolated environment. Use
`uv sync --frozen` only when that checked-out project declares the workflow.
Install Git LFS hooks only inside an in-scope repository with explicit
`git lfs install --local`; never change global filters implicitly.
