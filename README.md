# Personal Codex and Claude harness

This repository is the portable, non-sensitive control plane for the owner's
Codex, Claude Code, Linux/HPC, and personal macOS environments. It lives at
`~/harness`, keeps both agent clients under the same working agreements, and
provides value-free observation plus fail-closed transactional operations.

The repository is self-contained. Installation, CI, cleanup, and operation do
not depend on a sibling checkout.

## Task architecture

```text
repository/
├── AGENTS.md                     # Cold-start instructions
├── TODO.md                       # Ordinary Har-* active board
├── NIGHTLY.md                    # Separate Nit-* nightly queue and procedure
│
├── docs/
│   ├── tasks/                    # Ordinary direct-execution ledger
│   │   ├── config.json           # Har prefix, next ID, record bound
│   │   ├── index.tsv             # Ordinary task dispositions and lookup
│   │   └── Har-NNN.md            # Detailed execution state
│   ├── nightly/                  # Nightly-only direct-execution ledger
│   │   ├── config.json           # Nit prefix, next ID, record bound
│   │   ├── index.tsv             # Nightly task dispositions and lookup
│   │   └── tasks/
│   │       └── Nit-NNN.md         # Detailed nightly execution state
│   │
│   └── history/                  # Archived historical boards and chronology
│
└── tools/
    └── harness-ledgers.py        # Har/Nit namespace and schema validator
```

Harness executes both ledgers directly; it is not its own producer/consumer
pair. Ordinary work uses `Har-*`. Only an owner-started nightly run or an
explicit request to put work in the nightly ledger allocates `Nit-*`.
Repository-local producer/consumer ledgers remain available to independently
operated sibling projects and are coordinated from their own roots.

## Current operating model

As of 2026-08-05, Harness directly executes ordinary `Har-*` work and is the
only repository that starts portfolio nightlies. The current nightly queue is
selected from `NIGHTLY.md`; ordinary deferred work remains in `TODO.md`.
Personal, Students, Swallow, and Website retain independent repository-local
producer/consumer ledgers with trust-equivalent agents and protected
publication. Harness supplies shared workflows and portfolio coordination but
does not store their private task payloads or become a runtime dependency.

## Start here

For an existing managed checkout:

```bash
cd "$HOME/harness"
git status --short --branch
./install.sh
harness doctor --host local
```

`install.sh` is idempotent and creates only the `harness` command link plus
minimal Codex and Claude launch sentinels. It refuses regular-file collisions
and symlinks that point somewhere else. Policy, permission settings, rules, and
all skills are discovered from this checkout.

Legacy global client configuration is removed by a separate transaction:

```bash
harness agent-config --plan
harness agent-config --apply
```

It recognizes only the previous harness-managed settings/rule/skill paths,
preserves every credential and runtime-state file, and records rollback
preimages. It never installs or authorizes a plugin, marketplace, MCP server,
connector, or credential.

Ordinary work lives in [TODO.md](TODO.md); nightly work lives separately in
[NIGHTLY.md](NIGHTLY.md). Both route to compact matching execution records.
Completed command-level evidence lives in Git history and
[docs/audits/](docs/audits/). A cold-started agent reads the root `AGENTS.md`
or `CLAUDE.md`, selects the appropriate direct ledger, and reads only the
matching record. It reads the canonical
[fleet inventory](docs/fleet-inventory.md) only for fleet or host work.

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

Both clients reconstruct unfinished ordinary work from Git, [TODO.md](TODO.md),
and the selected `Har-*` record—not conversation history or client-local
memory. They read [NIGHTLY.md](NIGHTLY.md) only for an owner-started nightly or
an explicit nightly-ledger request:

```bash
cd "$HOME/harness"
git status --short --branch
git log -3 --oneline
```

Before changing a collaborative branch, fetch the protected remote and confirm
the active task. Before handoff, checkpoint verified facts, failures, files,
validation, and the next executable action in that task's record. Change
`TODO.md` only when the queue-level phase, order, summary, or pointer changes.

### Survive transient Codex service failures

Run the foreground resilience supervisor explicitly to resume the repository's
most recent chat. The unaliased `codex` command remains available for native
subcommands such as `codex --version`:

```bash
codex --version
harness codex-resilient --plan --name harness --last
harness codex-resilient --run --name harness --last
```

Use `--session ID` instead of `--last` when multiple Codex chats can be started
from the same repository. Before every exact-ID launch, the supervisor requires
the saved thread's persisted CWD to match the current managed target. `--new`
creates a new chat on the first launch and resumes the repository's most recent
chat thereafter. The target-scoped supervisor rejects global `--last-all`;
use `harness-codex resume --last --all` only for an intentional unsupervised
global resume. `harness-codex` remains the explicit direct launcher for a fresh
or intentionally unsupervised client.

For a phone-visible chat owned by the local remote-control app server, preserve
both the remote transport and exact root ID on every retry:

```bash
harness codex-resilient --run --name harness \
  --remote-session 01900000-0000-7000-8000-000000000000
```

`--remote-session` always relaunches as
`resume --remote unix:// ID`; it never falls back to `--last` or replays a
prompt. That selector also owns a thread-status watcher. Before launching the
TUI and every five seconds while it remains live, the watcher reads only the
exact app-server thread and value-free rollout structure. An unexpectedly
exited watcher may be replaced without relaunching the same live TUI, but only
after the same safe-tail preflight and at most three consecutive times; five
minutes of watcher stability resets that budget. Failed replacement remains
fail-closed. If the status is `systemError`, the helper rolls back at most
eight consecutive completed turns only when each has user input but no
assistant response, tool use, command, file change, web action, external
action, or unknown event. It revalidates the thread and rollout under the
shared agent-message lock immediately before the single rollback request. Any
active turn, unsafe event, identity drift, or ambiguous acknowledgement fails
closed. Rollback changes model-visible history; it does not undo filesystem
or external effects, and the removed prompt is never replayed.

Plan or inspect the value-free recovery receipt independently:

```bash
harness codex-thread-recovery --plan --name harness --target harness --thread ID
harness codex-thread-recovery --status --name harness --target harness
```

For an intentional per-thread cold reconnect, do not restart the shared
remote-control app server. Quit Codex normally if you are inside the target
TUI; exit status zero is terminal and the supervisor will not respawn it. From
another project pane, first list immutable pane IDs and select a different
pane. Remove only the exact target pane, then split the canonical window with
the exact repository, target, and remote root:

```bash
tmux list-panes -s -t projects \
  -F '#{pane_index} #{pane_id} #{pane_title} #{pane_active}'
tmux select-pane -t %UNAFFECTED_PANE_ID
tmux kill-pane -t %EXACT_TARGET_PANE_ID
tmux split-window -d -P -F '#{pane_id}' -t projects:0 \
  -c /absolute/project/repository \
  'exec "$HOME/harness/bin/harness" codex-resilient --run --name project --target project --remote-session 01900000-0000-7000-8000-000000000000'
tmux set-option -p -t %NEW_PANE_ID @harness_target project
tmux select-pane -t %NEW_PANE_ID -T project
tmux swap-pane -d -s %NEW_PANE_ID -t projects:0.TARGET_INDEX
tmux select-layout -t projects:0 even-horizontal
```

Replace `project` and the example IDs, pane index, repository, and remote root
with one exact declared target. The pane-local `@harness_target` option is its
stable automation identity; the title is its presentation label. Never
substitute `--last` for a phone-visible remote root:
it selects the most recent local saved session for the launch directory and
can make two panes display the same chat. A transient nonzero exit needs no
manual restart; leave the pane in place and let the supervisor retry the
same exact root. Restarting the shared app server is a separate fleet-wide
operation because it interrupts every remote-controlled thread.

The canonical Local layout is one `projects:0:codex` window with panes
`0:harness`, `1:students`, and `2:swallow`, spaced evenly from left to right.
`Ctrl-b z` toggles the selected pane between the overview and full-window
zoom. The visible border labels use the stable pane-local role because
applications may change terminal titles. Resilient supervisors recover Codex
failures while tmux remains alive; this
is not a Local host-reboot session-restoration service.

On Linux, the supervisor launches Codex through `harness codex-login`, which
sets `RAYON_NUM_THREADS=8` and `TOKIO_WORKER_THREADS=8` for login-node
politeness. The command leaves macOS unrestricted and does not install global
environment settings.

After a nonzero Codex exit, the supervisor runs the native redacted doctor. It
stops on local authentication, configuration, installation, or state failure.
Otherwise it resumes without a prompt after bounded exponential backoff and
jitter. It never captures the terminal transcript or automatically replays the
failed turn, because a 503 can arrive after a tool or external side effect
already succeeded. Inspect its value-free state from another shell:

```bash
harness codex-resilient --status --name harness
```

The supervisor stays in the foreground and installs no service. Tmux, launchd,
systemd, or the operator remains its explicit lifetime owner. A deployed
supervisor adopts new recovery code only on a deliberate TUI restart; updating
the checkout never signals or replaces a running client.

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
harness fleet-health
```

During a declared Local outage, t4 can act as a bounded on-demand bastion
without installing a server or auto-restart process on its shared login nodes.
From a remotely controlled Mac, preserve its existing Local tunnel and open one
additional route to a pinned TSUBAME login node for at most nine minutes:

```bash
harness t4-hub --host riken --login-node login1 --plan
harness t4-hub --host riken --login-node login1 --apply
harness t4-hub --host riken --login-node login1 --status
harness t4-hub --host riken --login-node login1 --rollback
```

Use `aist`, `home`, `office`, or `riken` as the exact Mac identity. The
`login2` route derives only from that Mac's existing secondary tunnel and is a
separate bounded transaction. On the matching pinned t4 node, keep the incoming
current-user agent forwarding and use the declared global Linux routes or the
active Mac reverse route:

```bash
harness t4-hub --doctor --login-node login1
harness t4-hub --connect ri --login-node login1
harness t4-hub --connect riken --login-node login1
harness fleet-health --hub t4 --login-node login1
```

The hub command never copies keys or edits the existing SSH root. It preserves
Local's routes, uses a private control socket, suppresses private SSH
diagnostics, verifies each loopback Mac endpoint with a private one-command
host-key file, removes that file immediately, and schedules an unconditional
bounded stop after 540 seconds. Run rollback after use; a stale receipt must be
reconciled before another apply.

Routine health reports cover the managed Linux nodes and both routes for every
Mac. Transport-only `abci_login` and `alps_login` are omitted unless the
transport itself is under investigation. Use `harness connection-monitor
--once` separately when diagnosing or recovering Mac tunnel pairs.

To reduce repeated CSCS authentication while retaining the personal `al`
account and MFA policy, keep one multiplexed Daint transport alive:

```bash
harness al-session --status
harness al-session --start
```

`--start` makes one non-interactive attempt using the existing signed
certificate. It never signs or renews credentials and reports
`renewal-required` when owner authentication is needed. `--stop` stops only a
receipt-matched managed unit; it refuses unrelated masters. On Local, the
foreground master runs in a marked transient user-systemd unit so it survives
the command session that launched it. A transport failure is retried every
60 seconds while authentication remains usable; an authentication or permanent
local configuration failure stops retries. `--status` reports `retrying`,
`renewal-required`, or `repair-required` without exposing diagnostics. No
permanent unit file or automatic authentication path is installed. After a
hard SSH-process crash, the runner removes an unusable stale control socket
only when its safe file properties, path, and per-unit marker match the
protected managed receipt. Private diagnostic descriptors originate in the
validated current-user runtime directory on tmpfs, not in an NFS-backed home,
and their temporary pathname is unlinked before SSH starts.

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

Eight Linux nodes—`local`, `ab`, `ab2`, `ri`, `al`, `rc`, `t4`, and
`abq`—have encrypted hidden-home primaries and independent generations that
passed full-data checks and verified restores. Exactly one scheduler-native
weekly primary job exists per node. Keep-all remains in force: no scheduled
`forget`, `prune`, replica, full-data check, login-node cron job, or user
timer exists.

The current successor gate is in
[the Har-196 record](docs/tasks/Har-196.md). Recovery procedures and the reviewed
topology are in [docs/home-backup.md](docs/home-backup.md).

## Codex and Claude use the same harness

Codex reads root [AGENTS.md](AGENTS.md). Claude reads root
[CLAUDE.md](CLAUDE.md), which imports the same project rules. Reviewed
permissions live in `.codex/config.toml` and `.claude/settings.json`. All 17
shared skills are linked inside the repository:

- `.agents/skills/` for Codex;
- `.claude/skills/` for Claude.

The only global client files retained by the harness are minimal sentinels at
`~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`. Outside `~/harness`, they
refuse task work and give the exact restart command.

Inside Harness, the root router loads only policy modules matching the next
action. Each selected skill likewise routes only its current phase, site, or
mode references; unrelated workflows and completed task history are not
preloaded.

This gives both clients the same start, planning, safety, validation,
publication, fleet-sync, and handoff expectations. Cross-client communication
is task-directed and optional; duration and nightly work do not require a
second client.

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
cleanliness, sentinel/command link state, and aggregate project discovery
state. It validates the tracked permission files and both project skill trees,
and refuses dirty checkouts or collisions before installation. System
prerequisites, client installation or authentication, collision adoption, and
every remote-node action remain separate owner decisions.

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

Selected manifest versions include ripgrep 15.2.0, uv 0.11.32, rclone 1.74.4,
Restic 0.19.1, Ninja 1.13.2, ShellCheck 0.11.0, Claude Code 2.1.220,
Tectonic 0.16.9, Git LFS 3.7.1, Node 24.16.0/npm 11.13.0, the Linux Codex
agent 0.145.0, SQLite 3.53.3, Tree 2.3.2, tmux 3.6b, and htop 3.5.1. Every
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

The current Harness-development comparison (2026-07-29) uses 16
repository-shaped scenarios balanced across eight decision types. It pins Codex
`gpt-5.6-sol` and Claude `claude-opus-5` at high effort, gives each client
three fresh observations per scenario, counterbalances order, disables task
network access, hides owner-home content from task shells, and grades
artifacts, protected paths, and safety invariants independently. A model-free
mutation audit also proves that the same graders accept 32 independently
constructed valid variants and reject 48 plausible wrong variants, including
four protected-gate reward hacks.

| Client | CLI | Requested/observed model | Accepted | Task failures | Unsafe | Invalid |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| Codex | 0.145.0 | GPT-5.6 Sol / not emitted | 48/48 | 0 | 0 | 0 |
| Claude Code | 2.1.220 | Claude Opus 5 / Claude Opus 5 | 44/48 | 4 | 0 | 0 |

The separate pilot passed 16/16 for Codex and 15/16 for Claude. Across the
cumulative three-observation confirmation result, Claude accepted boolean reply
counts in three observations, additionally missed upper reply-count bounds in
one of them, and mishandled one protected root-route normalization edge. Codex
passed every observation. Neither client produced an unsafe, invalid,
no-artifact, or containment outcome.

This establishes that current Claude can perform the represented Harness
development work under the controlled benchmark, while Codex was more
consistent on the strengthened properties in this sample. It does not establish
general product or model superiority: native edit surfaces, vendor effort
controls, token accounting, and real task frequencies are not equivalent.
Codex JSONL also did not emit a resolved model identifier, so its model is
reported as requested-only.

The accepted `-r7` aggregates are the
[pilot](evaluation/results/t336-harness-development-v2-20260729-r7-pilot.json)
and
[confirmation](evaluation/results/t336-harness-development-v2-20260729-r7-confirmation.json).
The `-r5` observations remain exploratory because their graders lacked the
declared mutation challenge. The `-r6` aggregates remain invalid calibration
evidence because their adapter rejected a conventional `TypeError`; neither is
combined with the accepted result.

The earlier dated pilot (2026-07-22) used the same nine tasks, medium effort,
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
- `.codex/AGENTS.md`: minimal global Codex launch sentinel source.
- `.codex/config.toml` and `.claude/settings.json`: reviewed project
  permissions and Codex new-session model defaults.
- `.codex/rules/default.rules`: project Codex command rules.
- `config/agent-clients/`: public Codex and Claude settings plus reviewed
  sentinel/component declarations.
- `shared/skills/`: 17 canonical workflows exposed through `.agents/skills/`
  and `.claude/skills/`.
- `bin/harness` and `libexec/`: observation and transactional operations.
- `profiles/`: logical host, tool, scheduler, storage, backup, and runtime
  declarations.
- `shell/`: public shell integration and accidental-use safeguards.
- `evaluation/`: deterministic cross-agent acceptance corpus.
- `tests/`: focused suites, fixtures, and native smoke sources.
- `docs/`: architecture, operating instructions, plans, and audit evidence.
- `TODO.md`: compact active queue; `docs/tasks/`: selected active-task records
  and the completed-task index.

## Validation

Use the deterministic impact selector during ordinary work:

```bash
harness validate --plan --path PATH
harness validate --stage discovery --base origin/main
harness validate --stage repair --suite tests/OWNING-SUITE.sh --base origin/main
```

Documentation and ledger changes run their contracts, routed skills run budget
and gate fixtures, and mapped components run their owning suite. Workflow,
policy, selector, manifest, safety, lifecycle, cleanup, credential, and unknown
changes retain their high-risk classification without forcing the full suite
during development. Discovery runs every suite in each affected group in
keep-going mode and records one durable failure inventory. Repair accepts one
owning suite at a time; if several owners are selected, the plan lists the
individual `--suite` commands instead of running unrelated tests. Exact
clean-tree R0/R1 repair results may reuse a content-addressed local receipt;
that receipt is owner self-attestation, not independent CI. Recorded validation
is also reused when the target bytes, environment contract, and acceptance
scope are unchanged: resuming a session alone does not trigger another run.

After discovery failures have each passed their individual owning suite, run
the complete portable suite exactly once on the final integrated tree:

```bash
harness validate --stage final --base origin/main
```

The retired fixed Darwin preflight is no longer part of the workflow: affected
selection is smaller and cannot drift from the complete manifest. Validation
plans report owning suites, groups, and estimated serial cost. Timing receipts
record the platform, resource class, status, and duration of every admitted
suite. The focused runner fails fast for final validation and uses keep-going
only for discovery. On Darwin, automatic admission retains a light-work lane
on smaller machines and caps process-heavy concurrency.

Documentation-only changes must at least pass `git diff --check` and the
relevant focused tests. Protected CI remains authoritative.

Protected Harness pull requests run affected-group discovery against the
event's exact base revision, including owner-authored changes. This reports all
group failures in one run instead of exposing them serially after each repair.
Weekly and manual events remain unconditional full portable backstops.

For private Students and Swallow work, repository-local policy controls any
owner-authored pull-request shortcut. Harness runs affected-group discovery for
every pull request and avoids only the redundant post-merge `main` run. Weekly
and manual hosted runs provide an independent full backstop. The earlier
measured cost model, trust boundary, and alternatives are recorded in
[`docs/audits/t351-autonomy-efficiency/actions-transition.md`](docs/audits/t351-autonomy-efficiency/actions-transition.md).

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
