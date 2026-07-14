---
name: research-engineering-validation
description: Develop, refactor, debug, or optimize distributed-training systems, scientific HPC codes, numerical algorithms, GPU kernels, and performance-critical research software. Use when correctness, reproducibility, scaling, numerical stability, or matched performance evidence is required.
---

# Research engineering validation

1. Freeze a correct baseline, representative workload, acceptance tolerance,
   and reproducible command before changing performance-sensitive code.
2. Capture hardware, topology, compiler/runtime/library versions, precision,
   seeds, data shape, process/thread/device mapping, warm-up, and measurement
   method. Do not compare unmatched environments.
3. Profile before optimizing. State the bottleneck hypothesis and the metric
   that could falsify it; distinguish compute, memory, communication, launch,
   synchronization, I/O, and load-imbalance costs.
4. Make one bounded change at a time. Preserve reference implementations and
   add deterministic unit, numerical, race, and edge-case checks appropriate to
   the algorithm.
5. For distributed work, verify single-rank/device correctness first, then
   weak/strong scaling, collective behavior, overlap claims, imbalance, and
   failure handling. For GPU kernels, check bounds, aliasing, synchronization,
   precision, occupancy/resource use, and host/device parity.
6. Report distributions or repeated matched runs, not isolated minima. Include
   correctness deltas, throughput/latency, memory, scaling efficiency, and
   regression thresholds; label noise and unmeasured claims.
7. Retain the smallest useful benchmark and profiler evidence. Revert or reject
   changes whose speedup is not reproducible or whose correctness cost exceeds
   the declared tolerance.
