# Personal Mac Bash, tmux, and private-state migration

The current design keeps only SSH desired state in the private companion.
Bash policy and tmux configuration are public, reviewed harness assets shared
with the Linux fleet. The older engine-2 SSH/Bash/tmux bundle remains readable
only so an occasionally used Mac can fast-forward directly through this
migration; it is not the target representation.

## Current representation

- The private companion tracks `ssh_config`, `companion.conf`, and opaque host
  declarations. `minimum_engine_schema=1` is the current SSH-only layout.
- Bash's selected login startup file and `.bashrc` begin with the exact public
  `harness early managed` hook, retain owner-local bytes in the middle, and end
  with the exact public `harness managed` hook. There is no private Bash
  fragment or public thin-loader link after migration.
- [`config/tmux/tmux.conf`](../config/tmux/tmux.conf) is one complete,
  deliberately non-sensitive tmux configuration. The only live file is
  `~/.tmux.conf`, a symlink to that tracked file. `~/tmux.conf` and
  `~/.config/tmux/tmux.conf` must be absent.
- No apply sources an active shell or reloads a running tmux server. Bash
  changes activate in new Bash processes and tmux changes in new servers.

The canonical tmux file contains only the reviewed session-name status,
next/previous-session bindings, and full hierarchy browser binding selected in
T-268. Validation starts a disposable isolated server and uses parse-only
`source-file -n`; it never sends the configuration to an active server.

## Pilot owner curation

Start from a clean, current public `main` checkout on the pilot Mac:

```bash
./bin/harness macos-pilot-plan --host LOGICAL_ID
```

The helper fetches both repositories, fast-forwards only public `main`, and
requires private `main` to be current and clean. It opens `.bashrc` and the
private Bash fragment side by side in isolated Vim. Move every machine-local
setting back into `.bashrc`, remove only settings already supplied by the
public hooks, and leave the private fragment empty. Credentials must not be
moved into either synchronized surface. Saving a nonempty fragment stops the
plan.

The helper does not apply the migration. It refuses a nonempty existing tmux
file for separate owner curation and refuses either alternate tmux path. After
curation it runs only:

```bash
./bin/harness macos-config-migrate --host LOGICAL_ID --plan
```

Apply remains a distinct authority boundary:

```bash
./bin/harness macos-config-migrate --host LOGICAL_ID --apply
```

## Recoverable bridge

The bridge validates the empty-fragment gate, the exact legacy loader, both
clean checkouts, private tracking, SSH syntax, public Bash candidates, and the
tmux candidate before mutation. It then:

1. normally commits and pushes the private companion forward from the
   engine-2 bundle to the engine-1 SSH-only layout;
2. adopts the unchanged live SSH file into the SSH-only state machine;
3. wraps the selected login file and `.bashrc` with public pre/post hooks while
   retaining the local middle;
4. replaces the reviewed regular/absent `~/.tmux.conf` with the canonical
   public symlink;
5. retires the empty private fragment, legacy loader link, and bundle state.

Every local child operation has a mode-0600 transaction and unchanged-only
rollback. A composite failure rolls completed local children back in reverse
order. A completed bridge reports one composite transaction:

```bash
./bin/harness macos-config-migrate --rollback TRANSACTION_ID
```

Rollback restores the prior startup files, prior regular/absent tmux state,
empty fragment, legacy loader, and bundle state only if their expected
post-images are unchanged. It never rewinds or force-pushes private Git. A
subsequent apply catches forward from the already-published SSH-only revision.
A failed private push likewise leaves a clean forward-only commit that the
next run may identify and retry; no force push is used.

Fetch/push logs are private mode-0600 temporary files and are exact-unlinked.
An SSH private origin requires `SSH_AUTH_SOCK` to name a current-user-owned Unix
socket. No command lists keys, requests passphrases, or prints private payload
bytes, hashes, paths, or revisions.

## Shared tmux adapter

All Macs and Linux nodes use the same command:

```bash
./bin/harness tmux-config --plan
./bin/harness tmux-config --apply
./bin/harness tmux-config --rollback TRANSACTION_ID
```

An existing strict regular `~/.tmux.conf` is classified but not replaced
without reviewed adoption:

```bash
./bin/harness tmux-config --adopt --plan
./bin/harness tmux-config --adopt --apply
```

Plan/apply require a clean committed checkout; production apply also requires
`main`. Unsafe types, foreign ownership, hard links, different symlinks, and
alternate config paths stop. Rollback validates the unchanged canonical link
before restoring the exact absent or regular preimage and its mode.

## Staged rollout

Generic publication precedes every live operation. Then validate in this
order, retaining separate authority at each gate:

1. pilot curation and migration plan;
2. pilot apply, explicit rollback, reapply, no-op plan, and doctor;
3. local Linux tmux plan/apply/rollback/reapply plus disposable-server check;
4. read-only plans for the six remote Linux nodes, one reviewed authority
   bundle, and sequential apply stopping at the first failure;
5. each remaining Mac independently, stopping for owner curation if its tmux
   file is nonempty.

Never reload an active shell or tmux server automatically.
