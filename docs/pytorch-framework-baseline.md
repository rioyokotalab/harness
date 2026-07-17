# PyTorch framework baseline

T-251 selects CPython 3.12, PyTorch 2.12.1, and the official CUDA 13.0 wheel
channel as the first immutable framework release. The single dual-architecture
lock is `profiles/pytorch-2.12.1-cu130.requirements.lock`; it pins all 29 direct
and transitive packages by version and SHA-256. Official CPython 3.12 Torch
wheels exist for both manylinux 2.28 x86-64 and AArch64. Their hashes are
`4bafc356fbb622e2756179406825c3a56c17b401196435a1487c5b40c657706c`
and `2d3e87d41ffb340ddf8c99e2a690a29feea9f5271459dd57621cd11317a434f2`.

The lock uses only the official PyTorch CUDA 13.0 index, NVIDIA's Python
package index for NVIDIA-published CUDA components, and exact transitive URLs
resolved through those indexes. PyTorch is BSD-3-Clause; NVIDIA CUDA packages
remain governed by their published NVIDIA license terms. The artifact contains
packages only and grants no redistribution or deployment claim beyond those
licenses.

`tools/build-pytorch-wheelhouse.sh` creates one immutable, offline wheelhouse
per architecture under an already declared persistent root. It requires Python
3.12, redirects pip cache to the declared cache root, uses `--require-hashes`
and `--no-deps`, requires exactly 29 wheels, verifies a sorted SHA-256 manifest,
records the lock digest, makes every artifact file read-only, and atomically
renames a collision-refusing staging directory. A failed staging directory is
preserved for diagnosis and must be removed only through guarded deletion.

The seven bounded single-device gates are: exact Python version; artifact and
lock digest; exact Torch/CUDA build versions; one scheduler-selected CUDA
device; finite tensor arithmetic; the tracked tiny-language-model
forward/backward/update gate; and cache/home isolation with zero job residue.
They prove only this tiny correctness surface, not performance, mixed
precision, model fit, distributed training, or production suitability.

PyTorch 2.13.0 is visible on the official CUDA 13.0 index as of 2026-07-17.
It is a future candidate, not an implicit baseline change. A maintained update
must freeze a new lock and two new artifact digests, confirm licenses and fleet
driver/runtime compatibility, rerun all seven gates, retain this verified
release for rollback, and promote only a complete pass. Floating tags,
in-place mutation, background updates, and silent upgrades are prohibited.
