# Personal macOS harness

The personal-Mac target family is independent of the Linux/HPC fleet. It uses
the public harness as an engine and a separate owner-controlled private Git
companion for curated desired intent. No Mac identity, observed inventory,
configuration payload, transaction detail, or credential belongs in the
public repository.

## Codex-first bootstrap

After cloning the public harness on a Mac that does not yet have Codex, run:

```bash
./bin/harness macos-codex-bootstrap --host LOGICAL_ID --plan
./bin/harness macos-codex-bootstrap --host LOGICAL_ID --apply
```

Apply first uses the already-installed Homebrew to install only missing `gh`,
`tmux`, and `python` prerequisites; Python is required to import its standard
`tomllib`. It also creates an absent harness-owned Python-tools virtual
environment and installs pinned binary `PyYAML` there. An unexpected existing
environment is preserved and blocks rather than being replaced; Homebrew
Python's externally managed site-packages remain untouched. Automatic metadata
update, cleanup, analytics, and environment hints are disabled. It then
downloads the pinned official OpenAI installer to a
private temporary file, verifies its reviewed byte count, SHA-256 digest, and
shell syntax, and executes those exact bytes with explicit state and Homebrew
bin paths. Installing the visible command in Homebrew's already-active bin
makes `codex` survive a terminal restart without editing `.zprofile` or
`.bash_profile`. An older official `~/.local/bin/codex` link is exact-unlinked
only after both links resolve to the same standalone command.

The public bootstrap declaration also carries the credential-free private
companion SSH clone locator selected by the owner. Repository knowledge grants
no access; normal GitHub SSH authentication remains mandatory. The command
refuses another Codex owner, verifies official standalone ownership, and opens
Codex with the complete one-Mac onboarding task and companion locator. It
launches Codex with approval prompts disabled and full machine access so the
agent can run the native harness and Git commands itself, with the validated
Python-tools environment first on `PATH`. The assignment also
applies the owner's settled onboarding choices automatically: restore the
declared companion, use a baseline-only missing host profile, install only
declared missing prerequisites, prefer SSH Git transport when HTTPS is not
authenticated, adopt an existing first-agreement private SSH payload, preserve
strict Codex settings and both valid Bash local bodies, and retain a
live-referenced `.bash_common`. The explicit pre-mutation `go` gate remains;
authentication, password, TCC, reboot, physical interaction, and newly unsafe,
ambiguous, or divergent state remain owner-visible stop boundaries.

## Private profile validation

The v1 companion contract is defined in
`docs/schemas/personal-macos-private-v1.md`. From a Mac-local session, validate
one opaque profile without printing its values:

```bash
harness macos-profile --host LOGICAL_ID
```

The private checkout must be clean, owner-controlled, mode-restricted, and
contain only `companion.conf`, strict `hosts/*.conf` manifests, and the payload
set allowed by the selected engine contract. The current contract has one
`ssh/LOGICAL_ID.conf` per declared Mac; the legacy root `ssh_config` is allowed
only during migration. The
resolver validates every tracked host manifest, not only the selected one, and
refuses untracked or modified content.

The payload exception and its privacy boundary are defined in
[`personal-macos-private-v1.md`](schemas/personal-macos-private-v1.md). It is
absent before explicit first adoption and is never printed by the resolver.

## Value-minimized observation

`harness macos-inventory --host LOGICAL_ID` is Darwin-only and read-only. It
reports only the OS family, architecture class, native account-shell class,
Homebrew availability and prefix class, Command Line Tools availability,
strict private-profile status, public-checkout status, fixed discovery-link
kinds, and presence of the ten managed and two retired public-policy formulae.
It does not print
Homebrew or OS versions, actual prefixes, developer-tool paths, private group
or formula selections, other installed packages, hardware identifiers,
networks, user names, or file contents.

Inventory invokes only `brew --version`, `brew --prefix`, and one scoped
`brew list --formula --versions FORMULA` query for each public formula. It
performs no update, install, upgrade, cleanup, service, tap, bundle, network,
or mutation operation. Private profile failures collapse to `invalid`; their
paths, values, and detailed errors remain suppressed. A live capture must be
written under `umask 077` to the private local harness state, never committed.
When directory-service lookup is available, account-shell classification uses
the current account's recorded `UserShell`; it falls back to the inherited
`SHELL` only when that value-minimized lookup is unavailable.

## Read-only plan and doctor

`harness macos-plan --host LOGICAL_ID [--facts FILE]` validates a mode-0600
fact snapshot, revalidates the strict private companion, refuses captured/live
formula or link drift, and renders collision-aware link actions. Its only live
Homebrew reads are scoped `brew list --formula --versions FORMULA` and
`brew outdated --formula --quiet FORMULA...` commands with automatic metadata
updates and analytics disabled. It never executes a rendered command.

The plan shows a separately authorized explicit metadata refresh, followed by
exact dry-run and apply commands for only missing or outdated managed formulae.
Install and upgrade commands disable automatic update and cleanup and use
Homebrew's formula-only and dry-run flags while explicitly unsetting
`HOMEBREW_ASK` for no-prompt execution. They do not set
`HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK`: Homebrew documents that disabling
that check can leave broken linkage. The later apply gate must instead inspect
dry-run scope and stop if an unmanaged dependent would change.

`harness macos-doctor --host LOGICAL_ID [--facts FILE]` emits a value-free
ready/not-ready result. It requires a supported architecture, usable Homebrew,
Command Line Tools, a valid private profile, the public checkout, the managed
Homebrew Bash account shell and one registry entry, exact managed link targets,
all ten public-policy formulae, no retired formulae, and all selected private formulae.
Private formula and capability names are reported only as counts.

Command behavior was frozen against the official Homebrew manpage and FAQ on
2026-07-18:

- <https://docs.brew.sh/Manpage>
- <https://docs.brew.sh/FAQ>
- <https://docs.brew.sh/Versions>

## Transactional discovery links

`harness macos-control --host LOGICAL_ID --plan` validates a canonical clean
public `main` checkout and the strict private profile, then reports only fixed
home-relative discovery-link actions. It manages the harness and Homebrew Bash
launchers, Codex and Claude guidance, Codex rules, and each public shared
skill's Codex, Agents, and Claude discovery links. The Bash launcher link does
not install the retired private Bash loader or edit startup files. It does not
replace regular files, directories, different symlinks, symlinked parents, or
paths owned by another account.

`harness macos-control --host LOGICAL_ID --apply` repeats every preflight,
creates only missing owner-private parent directories and absent links, and
records exactly what it created in a mode-0600 local transaction. Existing
correct links and existing personal directory modes are preserved. A partial
failure removes only links and directories created by that attempt; a second
successful apply is a no-op.

```bash
harness macos-control --rollback TRANSACTION_ID
```

Rollback first validates the entire private manifest, every recorded link,
every created directory, and the absence of non-transaction content. It then
unlinks only unchanged transaction-owned links and removes only now-empty
transaction-owned directories in reverse order. A changed link, directory,
owner, status, manifest, or unexpected file blocks rollback before mutation.
The transaction record remains local under `~/.local/state/harness`; neither
plan, apply, nor rollback touches packages, shell startup, Git remotes, or the
private repository's contents.

## Bounded Homebrew catch-up

Private `capability_groups` are classification labels and are never converted
into guessed package names. The frozen eight-formula `base.conf` and schema-2
formula policy remain byte-compatible with older updaters. Current desired state is the
separate schema-4 `formula-policy-v4.conf`: the complete reviewed cross-Mac
formula set, its full dependency closure, the reviewed retirement set, and any
selected private `extra_formulae`. The public selection is intentionally exact:
after a converged rollout, every personal Mac has the same public formula set.
Phase 1 refuses tapped formula names and tapped dependencies; support for a
private tap would need its own trust, update, and rollback design.

```bash
harness macos-homebrew --host LOGICAL_ID --plan
harness macos-homebrew --host LOGICAL_ID --apply
```

Both modes require Darwin, a canonical clean committed public `main`, a valid
private profile, and one active regular `brew` executable matching its reported
prefix. Because the policy requires exact cross-Mac equality, one local
formula-only version inventory establishes the actual installed keg names and
rejects anything outside the selected, dependency, private-extra, or reviewed
retirement sets. It does not inventory casks. This avoids Homebrew's ambiguous
canonical output when old and current versioned formula names are queried
together. The command resolves only the selected dependency closure and checks
installed dependents of every explicitly selected root. An installed dependent
outside the selected roots blocks plan acceptance and apply unless that
dependent is itself in the reviewed retirement set or a policy-declared legacy
name resolves to a selected replacement. Packages that merely share a dependency
remain unmanaged; Homebrew's installed-dependent linkage checks stay enabled to
protect them.

Plan runs exact formula-only install and upgrade dry-runs with automatic update,
cleanup, analytics, prompts, and environment hints disabled. It refuses empty
or incomplete dry-run evidence and output that indicates a cask, service,
`sudo`, license, tap, cleanup, uninstall, or autoremove scope. Metadata refresh
remains the separately displayed `brew update` authority; this command does not
run it implicitly.

Apply repeats the checkout, private profile, prefix, selected and retirement
action sets, dependency closure, installed-dependent, and dry-run gates
immediately before mutation. It installs missing selected formulae and upgrades
outdated selected formulae first. A second linkage checkpoint must then prove
that every selected formula is current and no dependent remains outside the
reviewed retirement set. Only then does it uninstall installed formulae on the
public retirement list. Ordinary retirements use exact formula-only forced
uninstall only after the independent dependent check, because non-forced
Homebrew uninstall leaves older installed kegs behind. The declared legacy
`icu4c` name shares its Cellar with selected `icu4c@78`, so it instead requires
a scoped cleanup dry-run that proves an old keg exists, followed by cleanup of
that one selected formula. This ordering migrates old linkage before removal and
permits one bounded operation to retire an interdependent package family while
still protecting every unreviewed installed dependent. Homebrew has no
uninstall dry-run, so this exact reviewed allowlist is reported separately and
no broad cleanup, autoremove, or ignored-dependent option is used.
Because Homebrew retirement can remove or expose an outdated selected
dependency, apply then recomputes exact state. Any missing or outdated selected
formula receives a new exact dry-run and scoped install or upgrade before the
final inventory/dependency/dependent acceptance check.
Finally, a selected formula with multiple installed keg versions receives its
own scoped cleanup dry-run and cleanup command. The last acceptance pass
requires one version per selected formula, so equality covers both package names
and versions rather than merely the current linked keg.
Homebrew may update their dependency closure, but
the command does not disable installed-dependent linkage checks because the
official guidance warns that doing so can leave broken linkage. It uses no
cleanup, removal, cask, service, tap, bundle, or whole-machine upgrade command.

Every non-no-op apply records mode-0600 local intent, pre-state, post-state,
dependency delta, command output, and complete/failed status. Homebrew package
changes are not transactionally reversible: failure evidence is retained, and
any downgrade, reinstall, uninstall, or dependency removal remains a separate
exact reviewed recovery action. A converged second apply is a no-op and creates
no transaction.

## Managed Homebrew Bash

`~/.local/bin/harness-bash` is a stable, network-free launcher. It resolves the
active regular `brew`, verifies that the command matches its reported prefix,
checks that the selected `bash` formula is installed, and resolves the Bash
executable inside Homebrew's physical Bash cellar. With no arguments it enters
an interactive login Bash; otherwise it passes the supplied arguments through
unchanged. Its only Homebrew operations are local prefix and named-formula
reads. It never updates metadata, installs or upgrades a package, edits startup
files, or changes the account login shell.

The original `macos-bash` command installed a compatibility loader for the
historical private bundle. Current Macs use the public Linux hook layout
through `macos-bash-hooks`: Bash's selected login file and `.bashrc` contain the
exact public early hook, untouched machine-local bytes, and the exact public
post hook. Transactional apply preserves local bytes and mode; unchanged-only
rollback restores the complete prior images. The explicit `--empty-local`
curation mode is accepted only for an already canonical `.bashrc`; it replaces
only its local middle with an empty login-only section, normalizes mode 0600,
and leaves the selected safe login file byte-for-byte unchanged.

`harness macos-login-shell --host LOGICAL_ID --plan|--apply` separately manages
one exact Homebrew Bash entry in `/etc/shells` and the current account's shell.
It requires the default architecture-specific Homebrew prefix, an installed
physical Bash formula target, strict `/etc/shells` metadata, a clean public
`main`, and a valid private profile. Apply refuses to prompt by default:
`sudo -n` must already succeed, otherwise it stops before mutation. An owner
running the command directly in a local terminal may explicitly add
`--allow-sudo-prompt` to apply or rollback; this opt-in route requires a
terminal and permits native `sudo` to prompt. Agents and remote unattended
routes must retain the default. A private transaction
captures the complete registry preimage and prior account shell; unchanged-only
rollback restores both. Zsh files, Terminal preferences, Keychain, login items,
and running sessions remain untouched.

On Darwin, the shared profile evaluates the fixed-prefix Homebrew `shellenv`,
suppresses environment hints, selects `LANG=en_US.UTF-8`, and defines
`UV_VENV_ROOT=~/.venv` before restoring canonical `~/.local/bin` precedence.
The interactive hook loads `bash-completion@2` only for compatible Bash and
provides `activate NAME` for a validated environment name. Linux behavior is
unchanged.

`bash-startup-unify` also accepts the narrow partial-current case where
`.bashrc` is already canonical and the reviewed login-file local middle exactly
matches its existing login-only section. It then changes only the login file to
the thin loader; any byte mismatch or additional managed marker still blocks.
When both distinct local bodies must be retained, the separately reviewed
`--merge-distinct-profile` plan preserves the existing login-only body first
and appends the login-file body after removing only a redundant `.bashrc`
loader. The flag is accepted only for that partial-current mismatch and remains
invalid during rollback.

For the narrower post-convergence drift where `.bash_profile` begins with the
exact canonical thin loader but has an opaque appended tail, the explicit
`--merge-thin-profile-tail` route moves only that tail into `.bashrc`'s
login-only section and restores the exact thin loader. It refuses any other
profile shape. When the owner has separately declared `.bash_common`
redundant, `--remove-bash-common-reference` may be combined with that route to
remove exactly one reviewed four-line guarded source block from the local
`.bashrc` body. Missing, duplicate, malformed, or additional references block;
both startup files remain one unchanged-only rollback transaction. Retirement
of the now-unreferenced `.bash_common` file remains a later recoverable
quarantine, acceptance retest, and exact-unlink step.

## Explicit private configuration synchronization

Engine schema 2 was the historical atomic private configuration bundle. It is
accepted only as a long-gap migration source. The current companion is
SSH-only, while Bash and tmux are public:

```bash
harness macos-pilot-plan --host LOGICAL_ID
harness macos-config-migrate --host LOGICAL_ID --plan
harness macos-config-migrate --host LOGICAL_ID --apply
harness macos-config-migrate --rollback TRANSACTION_ID
```

Owner curation must leave the old private Bash fragment empty. The bridge
publishes only the SSH-only private state, installs public Bash hooks, links
the public complete tmux file, and retires the compatibility loader/bundle
state. Local rollback is exact and private Git stays forward-only. Catch-up
never sources a shell or reloads a running tmux server. The full safety
contract and staged rollout are in
[`personal-macos-config-sync.md`](personal-macos-config-sync.md).

## Explicit long-gap update

The SSH-only reconciler is the current private configuration stage of an
explicit owner-started catch-up:

```bash
harness macos-ssh-sync --host LOGICAL_ID --plan
harness macos-ssh-sync --host LOGICAL_ID --apply
```

The first Mac instead uses `--seed --plan` and `--seed --apply` after reviewing
its current config. The reconciler fetches the private companion with prompts
disabled, compares the live file and fetched selected-host payload to the
private recorded base, and takes only a clean no-op, local-only publish,
remote-only pull, or
same-content convergence. A simultaneous unequal local edit and remote advance
is `diverged`; no timestamp, machine priority, force-push, reset, or automatic
merge chooses a winner. Fetch or push authentication failure leaves both the
live file and recorded base unchanged.

Apply syntax-validates a bounded regular single-link source, publishes only
after the companion is clean and current, and atomically replaces only
`~/.ssh/config` at mode 0600. It records a private mode-0600 transaction and
last-applied revision/content identity. Exact rollback is allowed only while
both the applied file and local state remain unchanged:

```bash
harness macos-ssh-sync --rollback TRANSACTION_ID
```

Rollback never rewinds private Git. Re-running apply therefore catches the
file up to the current private revision. The command never reads or copies
keys, `known_hosts`, agent state, credentials, or another `~/.ssh` entry, and
it installs no `launchd` task or other background job. Detailed protocol and
the separate fixed Linux mirror are documented in
[`ssh-config-sync.md`](ssh-config-sync.md).

To preserve distinct Mac roots while replacing the historical shared payload,
first update every Mac to engine 3. Then run `--migrate-per-host` for each Mac;
the command adds only that logical ID's absent file and keeps the legacy root.
After all declared Macs are present, run `--finalize-per-host` to validate the
exact host/payload pairing, remove the legacy root, and raise the private
minimum engine to 3. Ordinary apply on each Mac then refreshes its recorded
revision without changing equal live bytes.

Fetching is a separate, explicit step. After fetching `origin/main` in both
clean checkouts, resolve each target to its full commit ID locally and review a
read-only plan:

```bash
harness macos-update --host LOGICAL_ID \
  --public-target PUBLIC_COMMIT --private-target PRIVATE_COMMIT --plan
```

## Dedicated reverse-SSH supervision

`harness macos-tunnel-supervisor` manages the current `tunnel` and `tunnel2`
launch agents. These aliases are reserved for launchd and carry the reverse
forwards; ordinary interactive `login` carries no forward and `login2` is not
installed. Keeping the two roles separate prevents simultaneous interactive
sessions from competing for fixed forwarding ports.

The plan, apply, activate, status, kick, deactivate, and rollback interface is
the same as the legacy command below, with `tunnel|tunnel2` as the aliases. It
uses an independent state root, so a migration can stage both new agents while
the legacy agents remain live. Cut over one route at a time: deactivate its
legacy agent, activate its tunnel replacement, and verify inbound health before
changing the sibling route. If validation fails, deactivate the replacement
and reactivate the unchanged legacy agent. Retire the legacy transaction only
after both new routes pass.

```bash
harness macos-tunnel-supervisor --host LOGICAL_ID --plan
harness macos-tunnel-supervisor --host LOGICAL_ID --apply
harness macos-tunnel-supervisor --activate TRANSACTION_ID --alias tunnel
harness macos-tunnel-supervisor --activate TRANSACTION_ID --alias tunnel2
harness macos-tunnel-supervisor --host LOGICAL_ID --status
```

## Legacy reverse-SSH supervision

`harness macos-ssh-supervisor` manages two current-user launch agents for the
historical private `login` and `login2` reverse-forward aliases during the
bounded migration above. Do not use it for a new installation. It never embeds
or emits a host name, port, identity path, key, or other private SSH value. The
agents invoke the platform `/usr/bin/ssh` with batch mode, a bounded connection
attempt, isolated multiplexing, fail-fast forwarding, encrypted server
keepalives, and launchd throttling. Output is discarded rather than accumulated
in unbounded log files.

Plan validates the clean public checkout, strict private profile, live SSH
configuration, exactly one remote forward per alias, absent managed plist
destinations, a safe current-user mode-0600 `~/.ssh/harness-reverse` regular
file with one link, and an authentication attempt from a launchd-like minimal
environment with forwarding disabled. Both the probe and the generated service
select only that dedicated identity; neither inherits a session agent or edits
managed SSH configuration. Failure of the identity gate or either isolated
authentication test blocks before creating transaction state or launch agents.

```bash
harness macos-ssh-supervisor --host LOGICAL_ID --plan
harness macos-ssh-supervisor --host LOGICAL_ID --apply
```

Apply only stages two mode-0600 plists and a private transaction; it loads no
service and leaves existing tunnel processes unchanged. Migration activates one
alias at a time, only after its predecessor process is separately stopped while
the sibling route remains healthy:

```bash
harness macos-ssh-supervisor --activate TRANSACTION_ID --alias login
harness macos-ssh-supervisor --activate TRANSACTION_ID --alias login2
harness macos-ssh-supervisor --host LOGICAL_ID --status
```

Activation revalidates unattended authentication, refuses any non-launchd
process for that alias, bootstraps only its exact transaction plist, and
requires the service to remain running. `--kick login|login2` performs a
launchd-native forced restart for an already active transaction. Rollback is
deliberately staged: deactivate each service while its sibling or predecessor
route remains available, then remove only unchanged transaction-owned files.

```bash
harness macos-ssh-supervisor --deactivate TRANSACTION_ID --alias login
harness macos-ssh-supervisor --deactivate TRANSACTION_ID --alias login2
harness macos-ssh-supervisor --rollback TRANSACTION_ID
```

From the declared `local` controller, `harness connection-monitor --once`
classifies each Mac pair as `healthy`, `degraded`, or `unrecoverable` using
fresh non-multiplexed probes. `--recover` asks the healthy sibling route to
kick only the failed alias's active supervisor. When both routes are down it
records `await-supervisor`; it never invents a third path or starts an
untracked SSH process. `--interval 300 --recover` supplies the persistent loop
used by the existing tmux monitor session.

The same loop also probes the independent `abq` and `abq2` routes. Because
those are nested cluster paths rather than launchd-supervised Mac tunnels, a
single-route failure reports `use-primary` or `use-secondary` and a dual loss
reports `routes-unavailable`; `--recover` never sends a supervisor command for
ABQ.

The updater requires the expected `main` branch, exactly one `origin`, normal
`origin/main` tracking, a clean worktree, an explicit full target equal to the
fetched `origin/main`, and ancestry from the current revision. It validates the
public engine contract and every file in the private target tree before any
fast-forward. It never rebases, resets, force-updates, autostashes, cleans,
removes packages, or infers desired state from installed tools.

There is one deliberate bootstrap rule for a Mac still running the published
engine-1 updater after the private companion has adopted an engine-2
configuration bundle. Engine 1 validates the private target before its public
handoff and therefore cannot read that newer target. On that Mac, first fetch
and fast-forward only the clean public checkout with ordinary Git, then invoke
the now-current updater for the public/private pair:

```bash
git -C /path/to/harness fetch origin main
git -C /path/to/harness merge --ff-only refs/remotes/origin/main
```

This direct public fast-forward may cross any number of missed releases and
does not touch private Git, packages, links, or live configuration. The public
baseline remains byte-compatible with engine 1 specifically so this bootstrap
is accepted. Do not bypass a dirty, detached, locally advanced, or
non-fast-forward checkout; stop and review it instead.

Apply repeats every gate, fast-forwards the public checkout first, hands off to
the target engine, then fast-forwards the private checkout and writes only a
mode-0600 local schema-v1 state record:

```bash
harness macos-update --host LOGICAL_ID \
  --public-target PUBLIC_COMMIT --private-target PRIVATE_COMMIT --apply
```

If the second fast-forward fails after the public update, local machine state
is unchanged and rerunning the same targets is safe. No package, shell, link,
or background action is part of this command. A second successful apply is a
no-op.

Each state change creates a private transaction ID. This command restores only
the prior local state record; it deliberately leaves both Git checkouts at
their current fast-forwarded revisions:

```bash
harness macos-update --rollback TRANSACTION_ID
```

Rollback refuses a changed state record or backup. Reapplying the same target
after rollback is supported. Future schema releases must retain synthetic
fixtures and direct migrations from every previously released schema beginning
with v1; missed deployment events are never replayed.
