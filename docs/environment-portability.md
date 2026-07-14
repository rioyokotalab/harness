# Capability-driven environment portability

## Goal

Make interactive work, agent behavior, common commands, and project entry
points predictable on every machine without pretending that the machines are
identical. The harness owns the portable user layer. Each site's operating
system, drivers, scheduler, modules, MPI, CUDA, and policy remain authoritative.

Success means that a newly connected host can answer four questions without
guesswork:

1. What machine and site capabilities are available?
2. Which portable harness revision and tools should be active?
3. Which intentional differences apply here?
4. Is the environment healthy, and how can the last change be rolled back?

## Evidence from the current fleet

The 2026-07-14 read-only inventory found the following login environments.
Versions are observations, not requirements.

The complete unification target set is the current node plus `ab`, `ab2`,
`ai4s`, `al`, `rc`, and `t4`. The aliases `si`, `web`, and `github` are out of
scope. `abci_login` and `alps_login` are transport-only proxy nodes, not
deployment targets.

| Logical host | Substrate | Shell/architecture | Site runtime | Harness |
| --- | --- | --- | --- | --- |
| current | Ubuntu 24.04 | Bash, x86_64 | modules, Docker/Podman, CUDA, local Slurm/`yrun` commands | installed |
| `ab`, `ab2` | RHEL 9.4 | Bash, x86_64 | modules, Singularity CE, Podman, CUDA | absent |
| `ai4s` | Rocky 9.6 | Bash, aarch64 | modules, Singularity CE, Slurm, NVIDIA GB200 | absent |
| `al` | SLES 15 SP6 | Bash, aarch64 | uenv/`ml`, Slurm, Docker/Podman, NVIDIA GH200 | absent |
| `rc` | Rocky 9.8 | Bash, x86_64 | modules, Singularity CE, Slurm | absent |
| `t4` | RHEL 9.4 | Bash, x86_64 | modules, PBS, Apptainer, CUDA command | absent |

All six in-scope cluster shells have Git, Bash, and Python 3. None had `uv`,
Node, Nix, Home Manager, or mise in the probed login environment. POSIX shell
plus Git remains the practical bootstrap floor, keeping recovery independent
of an optional language runtime.

The excluded aliases receive no harness profile, deployment, shell integration,
or fleet health check. Connectivity checks for proxies or restricted services
remain separate from environment unification.

The inventory intentionally did not read environment values, shell-file
contents, credentials, histories, project data, or caches. It made no remote
changes.

## Layer model

### 0. Site substrate: observe, never normalize

Record OS, architecture, libc/ABI where relevant, login shell, scheduler,
module/uenv commands, container runtime, GPU visibility, and basic network
constraints. Never install or replace kernels, drivers, system compilers, MPI,
CUDA, schedulers, or administrator module trees from this harness.

### 1. Portable control plane: identical source, capability-aware behavior

Keep these in the harness repository:

- global Codex/Claude instructions and shared skills;
- small shell-neutral executables under a user-owned bin directory;
- common Git, terminal, editor, prompt, and navigation policy where adopted;
- logical host profiles and site adapters;
- pinned tool declarations, checksums, and supported target triples;
- inventory, plan, apply, doctor, and rollback logic.

The same Git revision should be present everywhere. Generated state and host
facts live outside the repository under `~/.local/state/harness/`; optional
owner configuration lives under `~/.config/harness/`.

### 2. Portable tools: same interface where an artifact is supported

Install self-contained, checksum-verified releases into versioned directories
such as `~/.local/opt/TOOL/VERSION/TARGET`, with stable links in
`~/.local/bin`. A tool manifest must enumerate supported OS/architecture/ABI
targets; unsupported hosts are a reported skip, not a partially applied
installation.

`uv` is a useful optional Python and Python-CLI layer on supported Linux hosts:
its official documentation describes standalone installation, managed Python
builds, isolated tools, and universal lockfiles. It officially targets Linux,
macOS, and Windows, but it must not become the bootstrap dependency. Projects
still declare their own Python version and lockfile.

Do not introduce Nix, Home Manager, mise, or a dotfile manager merely to run the
bootstrap. None is currently present, and another mandatory control plane would
increase recovery surface. Reconsider one later only if a measured pilot solves
a concrete problem better than the small harness layer.

### 3. Site adapters: stable concepts, honest differences

A host profile declares capabilities and maps common concepts to native site
mechanisms. Examples include module initialization, uenv entry, scheduler type,
container command, scratch roots, and whether login-node GPU checks are valid.

Profiles must not hide important scheduler semantics behind misleading aliases.
Common project commands may dispatch to a Slurm, PBS, or local adapter only
when the project supplies the resource request explicitly. A profile should
fail with a useful explanation when a concept is unavailable.

Environment Modules are designed to modify each shell dynamically. The harness
should extend, not replace, the site's initial module environment. At CSCS,
uenv remains the site mechanism rather than being started unconditionally by
generic non-interactive shell startup.

### 4. Project runtimes: reproducible per project, not global

Projects own language lockfiles, compiler/MPI compatibility, container
definitions, tests, scheduler templates, and performance records. Linux HPC
workloads may use Apptainer/Singularity or the site's native container layer;
the personal harness should only provide discovery and consistent entry
commands.

Use a clean container environment when reproducibility requires isolation from
host module variables. GPU and MPI validation remains site-specific because a
container does not make the host driver, interconnect, or scheduler identical.

### 5. Secrets and live client state: local injection only

Never commit or synchronize credential values, SSH private keys, authentication
state, agent sockets, client sessions, histories, caches, logs, databases, or
machine identifiers. The tracked manifest may name a required secret and its
consumer, but not its value. A host-local adapter may inject it from an approved
store at runtime.

`doctor` may report only `present`, `missing`, or `provider unavailable`. It
must not print, hash, compare, copy, or otherwise inspect secret values. The
known plaintext credential exposure on the current node must be rotated and
removed before any shell environment is synchronized.

## Proposed repository shape

The exact format should remain parseable without Python or Node:

```text
bin/harness                 # stable user command
libexec/harness-inventory   # read-only capability facts
libexec/harness-plan        # desired-versus-observed diff
libexec/harness-apply       # explicit transactional mutation
libexec/harness-doctor      # invariant and health checks
libexec/harness-rollback    # restore one recorded transaction
profiles/base.conf          # portable policy
profiles/hosts/*.conf       # logical site/host differences
shell/common.sh             # guarded POSIX/Bash behavior
tools/manifest.tsv          # version, target, URL, checksum
tests/fixtures/*            # captured, value-free host capabilities
```

Use a constrained line-oriented format with a strict parser rather than
executing profiles as shell code. Detection produces facts; profiles express
policy. A logical host ID is passed explicitly during first install and stored
outside Git, so ephemeral login-node hostnames do not select the wrong policy.

## Command contract

The eventual interface should make observation and mutation visibly distinct:

```text
harness inventory [--format text|json]
harness plan --host LOGICAL_ID
harness apply --host LOGICAL_ID
harness doctor [--host LOGICAL_ID]
harness rollback TRANSACTION_ID
```

- `inventory` is read-only, deterministic, value-redacted, and runs through an
  explicit `sh` or Bash process.
- `plan` is the default path. It reports creates, managed-link changes,
  unsupported optional tools, required owner decisions, and validation gates.
- `apply` requires an explicit logical host, a clean committed harness source,
  and a successful preflight. It never invokes root or a system package manager.
- `doctor` distinguishes required failures from optional skips and emits stable
  exit codes suitable for fleet checks.
- `rollback` restores only paths recorded in one transaction.

## Transaction and deployment rules

1. Refuse to operate from an uncommitted source tree.
2. Resolve and display the logical host profile and target triple.
3. Compute the full plan before mutation and reject unmanaged collisions.
4. Record prior link targets and metadata; back up any explicitly adopted
   regular file under a timestamped state directory.
5. Stage downloads, verify pinned cryptographic checksums, and rename into
   place atomically.
6. Apply only managed paths, then run host-specific doctor checks.
7. On failure, stop the fleet rollout and roll back that host's transaction.
8. Advance to the next host only after independent validation.

Until an explicit push is authorized, a clean committed revision can be moved
with a Git bundle over the already working SSH connection. This preserves
history without copying credentials or publishing the local-only harness
commits. A later remote-backed flow may fetch an explicitly published revision.
Do not rsync a dirty working tree and do not copy SSH keys; use the existing
agent and current proxy configuration.

## Shell integration

Do not symlink a complete `.bashrc` across sites. Keep site startup intact and
use a single guarded, managed hook only after inspection and owner approval.
The hook must be fast, silent for non-interactive sessions, and must not start
containers, contact the network, print environment values, or manage an SSH
agent.

Validate, per host:

- `ssh HOST true` is silent and succeeds;
- an interactive login preserves site modules and expected prompt behavior;
- batch submission starts from a declared project/site environment;
- agent discovery links resolve to the intended committed harness revision;
- repeated apply is a no-op;
- rollback returns the previous doctor result.

## Delivery phases

1. **Observe:** implement and fixture-test `inventory`; capture no values.
2. **Explain:** implement profiles, `plan`, and `doctor`; mutate nothing.
3. **Control plane pilot:** install one clean harness revision and discovery
   links on one low-risk host, validate, and roll back once deliberately.
4. **Shell pilot:** remediate known startup defects, add the minimal opt-in
   hook, and validate interactive, non-interactive, and batch contexts.
5. **Tool pilot:** add one checksum-pinned portable tool and optional `uv` on
   supported Linux targets; prove unsupported-target skips and offline errors.
6. **Fleet rollout:** proceed one host at a time with transaction records.
7. **Project adapters:** add project-owned scheduler/container entry points only
   when a concrete project requires them.

## Acceptance criteria

- One committed revision and one explicit logical profile explain every host.
- A fresh host needs only a POSIX shell, Git, and an existing authenticated
  transport to reach the observation/plan stage.
- Plan and doctor never reveal environment or credential values.
- System/site software is neither replaced nor silently shadowed.
- Unsupported tools produce intentional skips; required failures stop apply.
- Apply is idempotent and every mutation has a tested, bounded rollback.
- Non-interactive SSH, interactive login, and batch environments are validated
  independently on each host.
- No remote changes occur until its exact plan is reviewed.

## Primary references

- uv overview and supported operating systems:
  <https://docs.astral.sh/uv/>
- uv managed Python behavior:
  <https://docs.astral.sh/uv/guides/install-python/>
- Environment Modules model and shell support:
  <https://modules.readthedocs.io/en/stable/>
- Apptainer environment isolation and `--cleanenv`:
  <https://apptainer.org/docs/user/1.0/environment_and_metadata.html>
