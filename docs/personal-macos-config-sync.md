# Atomic personal-Mac configuration synchronization

`harness macos-config-sync` is an explicit, owner-started equal-writer
reconciler for the four personal Macs. It is pull-based and has no login hook,
timer, `launchd` job, remote controller, or automatic active-session reload.
The public engine contains only validators and transaction logic; all desired
bytes remain in the private companion and owner-only local state.

## Payload and live-file contract

Engine-schema-2 adoption requires exactly one private revision containing all
three ordinary mode-100644 Git blobs:

| Private payload | Live destination | Runtime behavior |
| --- | --- | --- |
| `ssh_config` | `~/.ssh/config` | Complete OpenSSH config; no other SSH file is touched |
| `bashrc` | `~/.config/harness/managed/personal-macos-private.bash` | Private fragment sourced by the existing thin `.bashrc` loader in a new managed interactive Bash |
| `tmux.conf` | `~/.tmux.conf` | The one complete live tmux config; there is no loader or second runtime config |

The companion must set `minimum_engine_schema=2`. No partial payload set is
valid. The engine-1 absent and SSH-only layouts remain readable for backward
compatibility. Migrating an SSH-only layout requires `--seed` and exact
agreement between its SSH payload and the current live SSH config before the
Bash and tmux candidates may join it.

Each payload is at most 1 MiB, current-user-owned, regular, single-linked, and
mode 0600 in the private checkout. Private-key markers and credential-like
assignments are rejected. OpenSSH validation disables hostname
canonicalization and rejects `Include` and `Match exec`. Bash uses
`bash --noprofile --norc -n`, which reads syntax without executing the file.

Tmux validation starts a disposable isolated server with `/bin/sleep` as its
fixed inert pane command, then uses `source-file -n`. Tmux documents that `-n`
parses a file without executing any commands, so `run-shell`, plugins, nested
sources, formats, and network-capable commands in the candidate are not run by
validation. The server, socket, and private temporary directory are removed
immediately. This behavior is present in the official tmux 3.1c manual and in
the current upstream configuration guide:

- <https://raw.githubusercontent.com/tmux/tmux/3.1c/tmux.1>
- <https://github.com/tmux/tmux/wiki/Advanced-Use#checking-configuration-files>

The managed Homebrew baseline is newer than that validator floor. Synthetic
coverage also exercises the local tmux 3.4 parser, including an inert
`run-shell` sentinel and an invalid-command refusal. The private payload is not
shared with Linux/HPC nodes; their site-local tmux and Bash contracts remain
unchanged.

## Reconciliation states

The private mode-0600 base records the last applied private revision and one
identity for each payload. After a prompt-free fetch, the command compares the
complete live set, recorded base, and fetched set:

| Live set | Fetched set | Result |
| --- | --- | --- |
| equal to base | equal to base | no-op; destination modes are normalized only on apply |
| changed | equal to base | validate, commit all desired live bytes, and normal-push |
| equal to base | changed | fast-forward private Git and apply the fetched set |
| equal to fetched | changed | same-content convergence |
| changed differently | changed | `diverged`; preserve both and stop |

Changes to different payloads on two Macs are still a concurrent bundle
advance and stop for an explicit private merge. The engine never guesses by
timestamp or host, automatically merges, rebases, resets, force-pushes, or
prints configuration content, identities, revisions, URLs, or private paths.
Failed prompt-free fetch/push is `auth-failed` and preserves the live set and
recorded base. A local candidate commit left by a failed push is recognized
and can be pushed by an ordinary retry.

## Adoption and operation

Before publishing or adopting the first bundle, fast-forward the public
harness checkout on each available Mac to engine 2. A sleeping Mac that later
returns on engine 1 uses the public-only fast-forward bootstrap documented in
[`personal-macos.md`](personal-macos.md), then runs the current updater. This
preserves direct catch-up from an old public state even after the private
companion requires engine 2.

The pilot first prepares and reviews all three live candidates. The Bash
candidate is a deliberately curated private fragment; the engine never copies
or tries to infer common commands from the rest of `.bashrc`.

The first pilot can perform the complete safe preparation and seed-plan stage
with one interactive command from the public harness root:

```bash
./bin/harness macos-pilot-plan --host LOGICAL_ID
```

The helper promptlessly fetches and clean-fast-forwards public `main`, then
hands off to the fetched helper. It requires the private companion already
clean and current; it fetches but never merges private Git. It opens `.bashrc`
and the private shared fragment side-by-side in an isolated Vim without user
plugins, swap, or history. The owner moves only settings shared by all four
Macs, preserving the exact managed loader and machine-local settings in
`.bashrc`. The helper then validates the complete SSH, Bash, and tmux live set
and runs `--seed --plan`. It has no apply option and never commits, pushes, or
applies the private bundle. Bash curation itself changes the two owner files
and affects only subsequently started managed Bash processes.

```bash
harness macos-config-sync --host LOGICAL_ID --plan
harness macos-config-sync --host LOGICAL_ID --seed --plan
harness macos-config-sync --host LOGICAL_ID --seed --apply
```

Plan performs fetch, layout, metadata, privacy, syntax, ancestry, and
divergence checks but does not change private Git or a live configuration. Seed
apply raises `minimum_engine_schema`, commits and normal-pushes the complete
bundle, then applies it transactionally. Private companion writes have their
own preimages and unwind fully if a staged replacement fails.

A Mac without bundle state never overwrites its local files implicitly. It
reports `adopt-required`; after private review, adoption is explicit:

```bash
harness macos-config-sync --host LOGICAL_ID --adopt --plan
harness macos-config-sync --host LOGICAL_ID --adopt --apply
```

Normal later operation omits both flags:

```bash
harness macos-config-sync --host LOGICAL_ID --plan
harness macos-config-sync --host LOGICAL_ID --apply
```

## Transaction, rollback, and activation

Apply validates all three candidates and every destination immediately before
mutation. It stages each new mode-0600 file in its destination filesystem,
records exact prior images and state, and replaces SSH, Bash, tmux, then state.
An injected failure at any replacement restores every earlier file and the
prior state before returning failure. A complete transaction exposes one
identifier without exposing private values.

Rollback prevalidates all three unchanged applied images, all prior images,
and the current state before restoring any file:

```bash
harness macos-config-sync --rollback TRANSACTION_ID
```

A changed file or state refuses rollback without partial restoration. Rollback
does not rewind private Git; the next apply catches forward to its current
revision.

Catch-up apply does not source the Bash fragment or run `tmux source-file` on a
live server. A new managed interactive Bash reads the updated fragment. Tmux
reads `~/.tmux.conf` only when a new server starts. Reloading an existing shell
or tmux server is a separate explicit owner action.

## Privacy and stop conditions

Public output contains only bounded state/action classes, agreement, payload
count, and transaction availability. Short-lived Git diagnostics are private
mode 0600 and exactly unlinked. Public tests use only synthetic values.

Stop before mutation on unsafe parents, owners, types, modes, or link counts;
unknown or incomplete private paths; dirty or non-fast-forward Git; unavailable
authentication; incompatible engine requirements; invalid grammar; credential
markers; divergence; changed transaction targets; or any failure to prove that
all three files can converge as one set.
