# Personal Codex and Claude harness

This repository is the portable, non-sensitive control plane for the owner's
Codex, Claude Code, Linux/HPC, and personal macOS environments. It lives at
`~/harness`, keeps both agent clients under the same working agreements, and
provides value-free observation plus fail-closed transactional operations.

The repository is self-contained. Installation, CI, cleanup, and operation do
not depend on a sibling checkout.

## Start here

For an existing managed checkout:

```bash
cd "$HOME/harness"
git status --short --branch
./install.sh
harness doctor --host local
```

`install.sh` is idempotent and creates only reviewed discovery symlinks. It
refuses regular-file collisions and symlinks that point somewhere else. Start
new Codex and Claude sessions after first installation so both clients rebuild
instruction and skill discovery.

Public client settings are a separate transaction:

```bash
harness agent-config --plan
harness agent-config --apply
```

It never installs or authorizes a plugin, marketplace, MCP server, connector,
or credential. Existing settings paths require explicit `--adopt`, and
rollback preserves unchanged preimages.

Current work and the exact resume checkpoint live in [TODO.md](TODO.md).
Completed command-level evidence lives in Git history and
[docs/audits/](docs/audits/). A cold-started agent should read the root
`AGENTS.md` or `CLAUDE.md`, `TODO.md`, and the canonical
[fleet inventory](docs/fleet-inventory.md) before acting.

For a new account that does not share the owner's hidden files, credentials,
remote nodes, or backup layout, use
[External-user onboarding](#external-user-onboarding) instead of assuming this
fleet.

## Fleet reference

The canonical [fleet inventory](docs/fleet-inventory.md) is the cold-start
reference for logical aliases, SSH entries, usernames, hostnames, operating
systems, and Linux user guides. Keeping the table in one place prevents this
overview from drifting from the operational reference.

The managed control plane contains 12 logical nodes: 8 Linux systems and 4
Macs. `web` is service-only and is not a deployment, health-monitor, package,
Python, backup, or synchronization target. `abci_login` and `alps_login`
are transports rather than targets; retired `si` remains out of scope. The
canonical table and provenance live in that inventory.

Each Mac has two independently supervised reverse routes. The route aliases
are for Local-to-Mac access; the Mac-side launchd services use the separate
`tunnel` and `tunnel2` aliases. A Mac-local 30-second watchdog and Local's
five-minute connection monitor recover bounded tunnel failures without
requiring an active controller session. See
[personal macOS operations](docs/personal-macos.md) and the
[connectivity-resilience audit](docs/audits/t296-mac-connectivity-resilience-2026-07-23.md).

## Everyday workflow

### Resume work safely

Both clients reconstruct unfinished work from Git and [TODO.md](TODO.md), not
from conversation history or client-local memory:

```bash
cd "$HOME/harness"
git status --short --branch
git log -3 --oneline
```

Before changing a collaborative branch, fetch the protected remote and confirm
the active task. Before handing work to the other client, checkpoint verified
facts, failures, files, validation, and the next executable action in
`TODO.md`.

### Inspect a host

The four dependency-free observation commands are:

```bash
harness inventory --host HOST
harness plan --host HOST
harness doctor --host HOST
harness storage-readiness --host HOST
```

`inventory` emits only reviewed, value-free facts. `plan` compares facts
with the logical-host profile and makes no remote change. `doctor` separates
required failures from optional warnings. `storage-readiness` checks the two
declared storage roots without benchmarking or promising quota.

Optional bounded storage probes are explicit:

```bash
harness storage-readiness --host HOST --write-probe
harness storage-readiness --host HOST --checkpoint-probe
```

Captured facts can be checked offline:

```bash
harness plan --host al --facts tests/fixtures/al.facts
harness doctor --host al --facts tests/fixtures/al.facts
```

The self-contained inventory can also be streamed without creating a remote
file:

```bash
ssh HOST 'sh -s -- --host HOST' < libexec/harness-inventory
```

### Check fleet connectivity

```bash
harness connection-monitor --once
```

Routine health reports cover the managed Linux nodes and both routes for every
Mac. Transport-only `abci_login` and `alps_login` are omitted unless the
transport itself is under investigation.

To reduce repeated CSCS authentication while retaining the personal `al`
account and MFA policy, keep one multiplexed Daint transport alive:

```bash
harness al-session --status
harness al-session --start
```

`--start` makes one non-interactive attempt using the existing signed
certificate. It never signs or renews credentials and reports
`renewal-required` when owner authentication is needed. `--stop` gracefully
stops only a master created by this helper; it refuses unrelated masters.

From a Mac-local shell, inspect its managed routes and watchdog with:

```bash
harness macos-tunnel-supervisor --host LOGICAL_ID --status
harness macos-tunnel-watchdog --host LOGICAL_ID --status
```

### Publish and synchronize

`main` is protected by required CI, linear history, conversation resolution,
and force-push/deletion protection. After a protected change merges, advance
clean managed checkouts with the explicit full revisions and target list:

```bash
harness fleet-sync --from OLD_COMMIT --to NEW_COMMIT \
  --hosts ab,ab2,ri,al,rc,t4,abq,aist,home,office,riken --plan
harness fleet-sync --from OLD_COMMIT --to NEW_COMMIT \
  --hosts ab,ab2,ri,al,rc,t4,abq,aist,home,office,riken --apply
```

Fleet sync refuses dirty, divergent, or collision state before writing. It
streams a verified mode-0600 Git bundle, fast-forwards only the expected old
revision, exact-unlinks transfer artifacts, and safely resumes partially
completed runs by retaining hosts already at the target.

### Back up and restore

Seven Linux nodes—`local`, `ab`, `ab2`, `ri`, `al`, `rc`, and
`t4`—have encrypted hidden-home primaries and independent generations that
passed full-data checks and verified restores. Exactly one scheduler-native
weekly primary job exists per node. Keep-all remains in force: no scheduled
`forget`, `prune`, replica, full-data check, login-node cron job, or user
timer exists.

The current successor gate is in [TODO.md](TODO.md). Recovery procedures and
the reviewed topology are in [docs/home-backup.md](docs/home-backup.md).

## Codex and Claude use the same harness

Codex reads root [AGENTS.md](AGENTS.md). Claude reads root
[CLAUDE.md](CLAUDE.md), which imports the same project rules. The installer
exposes the shared personal policy as both `~/.codex/AGENTS.md` and
`~/.claude/CLAUDE.md`, and links all 13 shared skills into:

- `~/.codex/skills/`
- `~/.agents/skills/`
- `~/.claude/skills/`

This gives both clients the same start, planning, safety, validation,
publication, fleet-sync, and handoff expectations. Consequential joint work can
use the `codex-claude-cowork` skill for durable planning, independent sandbox
evidence, reciprocal critique, a frozen plan, and driver-only execution.

`tests/test-claude-takeover.sh` validates the instruction chain, public
settings examples, skill discovery, idempotent installation, and
collision-before-mutation behavior.

## Onboarding

### Existing owner's mirrored node

After the owner adds one explicit SSH alias, ask Codex or Claude to
`onboard HOST`. The `onboard-mirrored-node` skill treats that alias as the
entire discovery boundary, collects one value-free inventory, resolves choices
one at a time, and waits for an explicit go before mutation. Acceptance covers
control-plane parity, approved storage migration, manual backup/check/restore,
and an independently restored encrypted generation.

### Personal Mac

Use the `onboard-personal-mac` skill for one of the owner's macOS systems.
It preserves native Keychain, privacy/TCC, Homebrew, launchd, shell, and SSH
boundaries while applying the public control plane transactionally. Detailed
contracts are in [docs/personal-macos.md](docs/personal-macos.md).

### External-user onboarding

The `onboard-external-user` skill is local-first and assumes no owner hidden
files, credentials, remote nodes, storage, backups, or prerequisites:

```bash
shared/skills/onboard-external-user/scripts/preflight --repo "$PWD"
```

The preflight reports only platform class, required-command presence, checkout
cleanliness, and aggregate discovery-link state. It refuses dirty checkouts
and collisions before installation. System prerequisites, client installation
or authentication, collision adoption, and every remote-node action remain
separate owner decisions.

## Safety and transactions

### Plan before mutation

Mutating harness commands default to plan mode. A normal control-plane apply
requires a clean committed checkout and a passing doctor:

```bash
harness apply --host HOST --plan
harness apply --host HOST --apply
harness rollback TRANSACTION_ID
```

Transactions reject unmanaged collisions, keep mode-0600 state under
`~/.local/state/harness/transactions/`, and roll back partial work. Rollback
checks that every managed path is unchanged before removing or restoring it.

Shell suffixes and reviewed host patches have separate transactions:

```bash
harness shell --host HOST --plan
harness shell --host HOST --apply
harness remediate --host al --plan
```

The shell transaction records only the original length and public managed
suffix, not pre-existing startup content. The Alps remediation changes only
the reviewed `uenv start` line. Native `uenv` and scheduler commands remain
visible rather than being hidden behind a generic wrapper.

### Guard every expanding deletion

Agents never use raw recursive or expanding deletion. They use:

```bash
harness guarded-delete plan --within /absolute/retained/root \
  --manifest /absolute/retained/delete.manifest -- \
  /absolute/retained/root/generated
harness guarded-delete apply \
  --manifest /absolute/retained/delete.manifest \
  --token SHA256_FROM_PLAN
```

Planning canonicalizes the retained boundary, rejects protected roots and
overlap, inventories entries and bytes, and writes a mode-0600 manifest. Apply
revalidates identity and counts, deletes across one filesystem, and proves
target absence plus protected-anchor survival.

Interactive Bash also refuses common accidental high-blast-radius forms for
recursive filesystem operations, `rsync` deletion, and broad scheduler
cancellation. This is a safety belt, not a security boundary; agents must still
use the guarded workflow.

### Keep sensitive and live state out of Git

The repository deliberately excludes live client settings, credentials,
authentication, sessions, histories, transcripts, logs, goals, memories,
databases, shell snapshots, caches, packages, plugins, daemon state, temporary
files, backups, installation identifiers, and model caches. Existing project-
or tool-local instructions also remain local to their projects.

Never commit a real configuration file until credentials and private endpoints
have been replaced by environment variables or another secret manager. A
private Git remote does not make committed secrets safe.

## Managed tools and research environments

The harness retains a healthy site command when possible and installs only
reviewed, checksum-pinned user-space artifacts when needed. Common transaction
families are:

| Purpose | Plan example |
| --- | --- |
| Single binary | `harness tool --host HOST --name ripgrep --plan` |
| Runtime tree | `harness runtime --host HOST --name node --plan` |
| Managed Python | `harness python --host HOST --minor 3.12 --plan` |
| Codex agent | `harness agent --host HOST --name codex --plan` |
| Source-built CLI | `harness build-tool --host HOST --name sqlite --plan` |

Selected manifest versions include ripgrep 15.1.0, uv 0.11.31, rclone 1.74.3,
Restic 0.19.1, Ninja 1.13.2, ShellCheck 0.11.0, Claude Code 2.1.207,
Tectonic 0.16.9, Git LFS 3.7.1, Node 24.16.0/npm 11.13.0, the Linux Codex
agent 0.144.4, SQLite 3.53.3, Tree 2.3.2, tmux 3.6b, and htop 3.5.1. Every
apply validates the staged artifact before atomically activating a stable
link. Rollback verifies links and content integrity before changing anything.
Older agent generations are never removed automatically.

Managed CPython provides `python3.11` and `python3.12` in harness-owned
directories without shadowing site `python` or `python3`. New projects use
3.12; 3.11 remains the compatibility runtime. Project environments are
separate uv-managed virtual environments.

Git LFS installation provides only the `git-lfs` command. Enable filters per
project with `git lfs install --local` only when that repository is in scope.
Installing an agent binary never reads or copies authentication, settings,
sessions, caches, histories, or transcripts.

HPC work uses the `operate-native-hpc` and
`research-engineering-validation` skills. Profiles declare real schedulers,
modules, uenvs, containers, compilers, debuggers, profilers, storage, and
architecture. Agents report and invoke the site's native commands; the harness
does not disguise PBS Pro, Slurm, AGE, or local `yrun` behind a normalized
scheduler wrapper. Reproducible compiler, OpenMP, MPI, CUDA, and Python smoke
sources are under `tests/smoke/`.

## Agent harness evaluation

`evaluation/` contains a synthetic, credential-free corpus and deterministic
runner for matched agent experiments:

```bash
python3 evaluation/evaluate.py validate
tests/test-evaluation.sh
```

The current dated pilot (2026-07-22) used the same nine tasks, medium effort,
one invocation, alternating order, workspace-only writes, and network-disabled
shell execution:

| Client | CLI | Default model | Passes | Safety failures | Total duration |
| --- | --- | --- | ---: | ---: | ---: |
| Codex | 0.145.0 | GPT-5.6 Sol (default Power; see note) | 9/9 | 0 | 414.699 s |
| Claude Code | 2.1.207 | Claude Opus 4.8 (stream-observed) | 8/9 | 0 | 386.902 s |

Claude's one failure safely removed a generated nested directory instead of
the required whole cache directory, so the preregistered gate blocked the
35-run-per-client stage. The Wilson intervals are wide; this pilot describes
only this corpus and environment and does not establish broad model
superiority. Client token counters are not directly comparable.

Codex JSONL did not emit the resolved model name. The table's dated model label
uses the then-current [Codex models manual](https://learn.chatgpt.com/docs/models)
for the default Power setting; the aggregate itself correctly retains
`requested_model=default` and an empty observed-model list. The result is
[evaluation/results/t295-codex-claude-20260722-v1-pilot.json](evaluation/results/t295-codex-claude-20260722-v1-pilot.json).

## Repository map

- `AGENTS.md` and `CLAUDE.md`: shared project start, validation, and handoff
  rules.
- `.codex/AGENTS.md`: canonical shared personal working agreements.
- `.codex/rules/default.rules`: reviewed Codex command rules.
- `config/agent-clients/`: public Codex and Claude settings plus reviewed
  component declarations.
- `shared/skills/`: 13 workflows exposed to both clients.
- `bin/harness` and `libexec/`: observation and transactional operations.
- `profiles/`: logical host, tool, scheduler, storage, backup, and runtime
  declarations.
- `shell/`: public shell integration and accidental-use safeguards.
- `evaluation/`: deterministic cross-agent acceptance corpus.
- `tests/`: focused suites, fixtures, and native smoke sources.
- `docs/`: architecture, operating instructions, plans, and audit evidence.
- `TODO.md`: the compact active task ledger.

## Validation

Run the complete portable validation suite with:

```bash
tests/test-phase1.sh
```

Documentation-only changes must at least pass `git diff --check` and the
relevant focused tests. Protected CI remains authoritative.

## Local shell compatibility

Live shell startup files are intentionally not versioned. Where Bash
completion requires nondefault parser options, load it only in interactive
shells so Codex cannot snapshot completion-only functions into a
noninteractive shell:

```bash
if [[ $- == *i* && -f /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi
```

This workaround originated from a Codex CLI 0.144.3 diagnosis. Validate it
against the installed CLI before applying it elsewhere.
