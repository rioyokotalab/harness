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
- common Git, terminal, editor, prompt, and navigation policy;
- logical host profiles and site adapters;
- pinned tool declarations, checksums, and supported target triples;
- inventory, plan, apply, doctor, and rollback logic.

The same Git revision should be present everywhere. Generated state and host
facts live outside the repository under `~/.local/state/harness/`; optional
owner configuration lives under `~/.config/harness/`.

The harness also owns the portable, non-secret Git, Vim, and tmux configuration.
Expose tracked common fragments through thin live include/source hooks rather
than cloning an opaque dotfile. Keep Git identity, signing, credentials, URL or
machine-specific paths, and mandatory site overrides in untracked host-local
configuration. Vim and tmux local overrides follow the same model. This choice
does not itself authorize plugin installation or plugin-manager network access;
those are separate tool-manifest actions.

### 2. Portable tools: same interface where an artifact is supported

Install self-contained, checksum-verified releases into versioned directories
such as `~/.local/opt/TOOL/VERSION/TARGET`, with stable links in
`~/.local/bin`. A tool manifest must enumerate supported OS/architecture/ABI
targets; unsupported hosts are a reported skip, not a partially applied
installation.

The selected initial tool scope is:

- core interfaces: Git, Vim, tmux, ripgrep, jq, tree, rsync, curl/wget, htop,
  and SQLite;
- Python: `uv` and managed Python 3.12;
- agents and JavaScript: Node 24/npm, Codex CLI, and Claude Code;
- documents and transfer: rclone, lftp, and Tectonic.

For every entry, declare either a host-provided feature/version floor or a
checksum-pinned user-space artifact. A host command that passes its doctor check
need not be shadowed merely to make version strings identical. The initial
scope excludes new shell/Git enhancements and extra editor configurations that
were not selected. Configuration or state containing rclone or agent
credentials is never synchronized.

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
Do not expose normalized scheduler wrapper commands. An agentic workflow may
use the profile to select and construct the appropriate native Slurm, PBS, or
`yrun`/`ybatch` command, but it must show the resolved command before execution
and report the same command with its result. Project resource requests remain
explicit, native commands remain available, and unavailable operations fail
with a useful explanation.

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

The owner has authorized changes to any file their account can edit on `ab`,
`ab2`, `ai4s`, `al`, `rc`, and `t4` when necessary for this environment
unification. This includes shell startup files, the harness checkout, discovery
links, and evidence-backed user configuration. It does not broaden the task to
excluded aliases, unrelated projects or personal data, credential or
authentication material, external services, or destructive cleanup. A shared
or system-wide file with wider impact must be identified explicitly in the host
plan.

Do not symlink a complete `.bashrc` across sites. Keep site startup intact and
use a single guarded, marked harness block. The hook must be fast, silent for
non-interactive sessions, and must not start containers, contact the network,
print environment values, or manage an SSH agent.

The owner selected all portable, non-sensitive shell-convenience categories for
unification. The harness therefore owns the common prompt, aliases, functions,
history policy, navigation helpers, and editor/pager defaults. Host profiles
may override only an evidence-backed site requirement. Exact behavior should be
reconciled into tracked fragments rather than copied wholesale from any one
startup file, and credential values must never be read or migrated.

Preserve the existing file around the managed block. Record a restorable backup
and original permissions before first mutation; update only the marked block on
later applies. Structural inspection and plans must not print startup-file
contents or environment values.

Bash login precedence requires special care: it reads the first available file
among `.bash_profile`, `.bash_login`, and `.profile`. If `.bash_profile` does
not exist, the plan must identify any file it would supersede and show how that
file's behavior remains in the source chain before creating `.bash_profile`.
The managed login block should arrange for the interactive `.bashrc` path
without duplicating initialization or changing non-interactive behavior.

Validate, per host:

- `ssh HOST true` is silent and succeeds;
- an interactive login preserves site modules and expected prompt behavior;
- file ownership and permissions match their pre-change state;
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
7. **Project workflows:** add project-owned agent workflows that construct,
   display, and execute native scheduler/container commands only when a
   concrete project requires them.

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
