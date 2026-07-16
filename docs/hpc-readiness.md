# Scheduler-native HPC readiness

The first matched compute-node gate passed on all seven managed nodes. The
machine-readable evidence is
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

This is a correctness and environment gate, not a benchmark. It does not yet
claim CUDA or accelerator runtime health, framework availability, MPI launch,
collective correctness, multi-node behavior, numerical equivalence across
architectures, or performance. RC's sanitizer runtime also remains a declared
gap. Those capabilities require separate smaller gates with explicit native
resource and environment routes.
