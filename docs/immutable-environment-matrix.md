# Immutable training-environment transport matrix

## Scope and evidence

This is a read-only option matrix for T-206, not an environment selection.
Native discovery recorded only command presence, public paths and versions,
and Slurm's public container-flag availability. It did not run a container,
contact a registry or daemon, pull/build an image, inspect credentials, or
change a node. Accelerator and architecture facts come from the allocated
T-200 evidence in `audits/hpc-accelerator-readiness-2026-07-17.json`.

Official references confirm the supported mechanisms: [ABCI containers](https://docs.abci.ai/v3/en/containers/),
[CSCS uenv Slurm integration](https://docs.cscs.ch/software/uenv/using/),
[TSUBAME container guidance](https://www.t4.cii.isct.ac.jp/docs/handbook.en/pdf/handbook.en.pdf),
[Slurm OCI containers](https://slurm.schedmd.com/containers.html), and
[Apptainer NVIDIA support](https://apptainer.org/docs/user/main/gpu.html).
Native discovery remains authoritative for the currently visible version and
must be repeated immediately before a runtime gate.

## Current matrix

| Node | Compute arch | Native mechanism | Visible version/state | T-206 implication |
|---|---|---|---|---|
| current (`local`) | x86_64 | site Docker/Podman wrappers | both present; allocation-only by site declaration | OCI image, tested only inside Ybatch |
| AB | x86_64 | SingularityCE; Podman also visible | SingularityCE 4.4.1 | prefer immutable SIF for the first gate |
| AB2 | x86_64 | SingularityCE; Podman also visible | SingularityCE 4.4.1 | same artifact as AB after digest verification |
| RI | aarch64 | Apptainer/Singularity alias; Slurm OCI | Apptainer 1.4.5; `--container` flags visible in login context | prefer Arm SIF first; OCI bundle remains a tested alternative |
| AL | aarch64 | uenv; Slurm uenv/OCI integration | uenv 10.0.1; validated `prgenv-gnu/25.11:v1` | prefer a selected site-native uenv |
| RC | aarch64 on selected GH200 | SingularityCE; Slurm OCI | SingularityCE 4.5.0; `--container` flags visible | require an Arm compute allocation runtime gate |
| T4 | x86_64 | Apptainer/Singularity alias | Apptainer 1.4.0 | prefer immutable SIF and AGE allocation gate |

RI's runtime is exposed by its login environment rather than a bare direct
shell. Local's wrappers are intentionally not invoked on the login node. The
presence of Slurm `--container` flags proves CLI support only; it does not prove
that a particular OCI runtime, bundle, GPU mapping, or bind configuration works
on a selected compute partition.

## Artifact policy

One portable binary artifact cannot cover both x86_64 and aarch64. Use one
reviewed source definition and dependency lock to build two immutable artifacts
with separate digests:

- x86_64: current, AB, AB2, and T4;
- aarch64: RI, AL, and RC.

The two builds must pin the same framework/source versions while allowing only
architecture-specific wheels, compiler/runtime packages, and digests. Record
the builder identity, definition and lock revisions, build time, architecture,
CUDA user-runtime version, framework version, license evidence, image digest,
and verification command. Never use a floating tag as provenance.

Large SIF files or OCI bundles belong under each node's declared persistent
root, not quota-limited home and not Git. Build/pull/unpack caches belong under
the T-201 cache root. Harness may track only non-secret definitions, locks,
public source metadata, digests, and bounded smoke scripts. Registry tokens,
keyrings, and runtime authentication stay in application-native private stores
and are never copied into the repository or image.

## Gate sequence for T-206

1. Owner selects the framework/version and approves the build or pull source.
2. Freeze licenses, lockfiles, architecture pair, CUDA compatibility, and exact
   expected digests before touching a registry.
3. Place artifacts transactionally under the persistent root; verify digest,
   ownership, mode, available space, and cache redirection.
4. Run a CPU import/version test in the smallest native allocation.
5. Run the tracked one-device tiny-language-model forward/backward test, with
   the scheduler's device selection preserved and no model/data download.
6. Validate home isolation, bind paths, cache paths, and absence of unexpected
   top-level hidden state.
7. Only after all seven single-device gates pass, consider distributed launch,
   collectives, numerical comparison, or performance work.

Rollback is exact artifact unlink plus empty-directory removal only after
identity/digest revalidation; any expanded or recursive cleanup must use the
guarded bulk-delete workflow. No T-206 live action is authorized by this
document.
