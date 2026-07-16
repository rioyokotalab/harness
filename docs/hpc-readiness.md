# Scheduler-native HPC readiness

The CPU/compiler/Python compute-node gate passed on all seven managed nodes.
Its machine-readable evidence is
[`audits/hpc-cpu-readiness-2026-07-16.json`](audits/hpc-cpu-readiness-2026-07-16.json).
Each run used a visible native scheduler request, a five-minute limit, default
priority, one rank, versioned identical smoke sources, and a private mode-0600
result. Scheduler accounting and the terminal result both report zero.

| Node | Architecture | Coherent compiler | Python | CTest | Sanitizer |
|---|---|---|---|---|---|
| current (`local`) | x86_64 | GCC 13.3.0 | 3.12.3 | 3/3 pass | pass |
| AB | x86_64 | GCC 15.2.0 | 3.12.8 | 3/3 pass | pass |
| AB2 | x86_64 | GCC 15.2.0 | 3.9.25 | 3/3 pass | pass |
| RI | aarch64 | GCC 13.3.0 | 3.12.3 | 3/3 pass | pass |
| AL | aarch64 | GCC 14.2.0 uenv | 3.14.0 | 3/3 pass | pass |
| RC | x86_64 | GCC 11.5.0 | 3.12.9 | 3/3 pass | declared skip |
| T4 | x86_64 | GCC 14.2.0 | 3.9.25 | 3/3 pass | pass |

The v1 run was diagnostically useful: RI exposed a site login-shell EXIT defect,
and T4 plus the AB systems exposed modules that add named GCC drivers while
leaving `cc` at the base compiler. Gate v2 resolves and exports one compiler
triplet after site environment setup, then executes its test body in non-login
Bash. The matched v2 rerun proves both corrections.

## Single-device accelerator gate

The bounded accelerator gate also passed on all seven nodes, with evidence in
[`audits/hpc-accelerator-readiness-2026-07-17.json`](audits/hpc-accelerator-readiness-2026-07-17.json).
It used the smallest declared site route, default priority, a five-minute
limit, one task, and one selected logical device. Scheduler accounting and the
private terminal result both report zero for every final run.

| Node | Compute architecture | Accelerator | Driver | CUDA kernel |
|---|---|---|---|---|
| current (`local`) | x86_64 | RTX A4500 (CC 8.6) | 595.58.03 | CUDA 12.8 pass |
| AB | x86_64 | H200 (CC 9.0) | 580.105.08 | CUDA 13.2 pass |
| AB2 | x86_64 | H200 (CC 9.0) | 580.105.08 | CUDA 13.2 pass |
| RI | aarch64 | GB200 (CC 10.0) | 580.159.03 | declared toolkit skip |
| AL | aarch64 | GH200 120GB (CC 9.0) | 590.48.01 | CUDA 12.9 pass |
| RC | aarch64 | GH200 480GB (CC 9.0) | 610.43.02 | declared toolkit skip |
| T4 | x86_64 | H100 MIG (CC 9.0) | 580.105.08 | CUDA 12.8 pass |

The v1 gate exposed two real route assumptions without broadening scope:
local's inherited module table needed an explicit CUDA unload/reload, and RC's
GH200 compute partition is Arm although its CPU baseline partition is x86.
Those exact v2 corrections passed. RI's scheduler also requires job-level
`--gpus=1`; its rejected per-node GRES attempt created no job.

These are correctness and environment gates, not benchmarks. They do not
claim framework availability, MPI launch, collective correctness, multi-node
behavior, cross-architecture numerical equivalence, or performance. RI and RC
still need a reviewed CUDA toolkit route, every node still needs a selected
and locked LLM framework environment or image, and RC's CPU sanitizer runtime
remains a declared gap.
