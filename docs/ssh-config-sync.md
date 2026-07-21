# Explicit SSH configuration synchronization

Two intentionally separate commands synchronize only complete OpenSSH config
files. A third command transactionally enforces the shared-fragment layout on
the current host. None is a fleet action, scheduler, timer, or credential
manager. They run only when the owner invokes them.

## Shared fragment layout on Linux and macOS

```bash
harness ssh-config-layout --host LOGICAL_ID --plan
harness ssh-config-layout --host LOGICAL_ID --apply
harness ssh-config-layout --host LOGICAL_ID --rollback TRANSACTION_ID
```

The canonical public source is `config/ssh/harness.conf`. The adapter accepts
only unambiguous top-level single-pattern `Host github` and `Host *` stanzas;
duplicate or multi-pattern forms, unmanaged `Match`, and unmanaged `Include`
directives fail closed. It preserves every other root byte and the root's safe
mode,
installs a regular current-user mode-0600
`~/.ssh/config.d/harness.conf` first, validates the combined OpenSSH grammar,
then atomically installs a root ending in the exact global-context trailer
`Match all` followed by `Include ~/.ssh/config.d/harness.conf`, with no selected
shared stanza. The context reset is required because a terminal include would
otherwise remain conditional on the preceding `Host` block.

Apply requires a clean committed harness checkout on `main`. Its private
transaction stores complete preimages and postimage identities for both files.
An interrupted second replacement restores the first, and rollback refuses if
either installed postimage changed. Existing SSH sessions are not restarted.
`harness dotfiles` routes SSH work through this same adapter instead of making
fragment symlinks.

The shared fragment places an exact `Host login login2` exception before the
global defaults and sets `ControlMaster no`, `ControlPath none`, and
`ControlPersist no`. It also sets `ExitOnForwardFailure yes`, so a dedicated
failover connection exits when any requested local, remote, dynamic, or tunnel
forward cannot be established instead of appearing healthy without its route.
OpenSSH uses the first obtained value for each option, so this ordering prevents
the two aliases from reusing or creating a multiplexed connection. GitHub and
ordinary targets continue to use the global `ControlMaster auto`, configured
control path, persistent master, and default non-failing forward policy.
Applying the fragment does not terminate an already-running master; the
exception takes effect for new clients. `ExitOnForwardFailure` covers initial
forward setup only: it does not prove that the ultimate forwarding destination
is reachable or detect a forward that fails later.

## Personal Macs: SSH-only desired state

`harness macos-ssh-sync --host LOGICAL_ID` supports the engine-1 legacy and
engine-3 per-Mac SSH-only routes. The
engine-2 atomic SSH/Bash/tmux bundle is retained only as a sleeping-Mac
migration source; Bash and tmux now use public shared configuration as
documented in
[`personal-macos-config-sync.md`](personal-macos-config-sync.md). The private companion
stores one `ssh/LOGICAL_ID.conf` payload per Mac; a root `ssh_config` remains
only during transition. The live destination is fixed to `~/.ssh/config`.
Only the selected Mac's payload participates in three-way comparison, so a
commit that changes another Mac's file is a safe Git/state refresh rather than
an SSH change. The current live file, fetched selected payload, and
private mode-0600 last-applied base determine the result:

| Local vs base | Remote vs base | Result |
| --- | --- | --- |
| equal | equal | current no-op; mode 0600 is enforced on apply |
| changed | equal | validate, commit, and normal-push the local candidate |
| equal | advanced | clean fast-forward, validate, and atomically apply |
| changed to the fetched bytes | advanced | converge to the agreeing revision |
| changed differently | advanced | `diverged`; preserve both for manual private merge |

First agreement is separately visible and directional. `--seed` publishes the
validated live file only when the private payload is absent. `--adopt-remote`
atomically replaces a differing live file only when the fetched private payload
exists and no local agreement state exists; its normal transaction preserves
the exact prior live file and state for unchanged-only rollback. A failed seed
push leaves the clean local candidate commit available for an ordinary retry. No route
rebases, resets, force-pushes, guesses a winner, or prints content, hashes,
revisions, remote URLs, endpoints, account names, or private paths. Output and
the local status surface use only `current`, `diverged`, `invalid`, `offline`,
or `auth-failed` plus yes/no agreement and a bounded action class.

Every replacement has an exact private prior-file image and prior state image.
`--rollback TRANSACTION_ID` first verifies the unchanged applied file and state,
then atomically restores both. Private Git remains current, so the next apply
reconciles forward again.

The one-time schema-3 cutover is deliberately split:

```bash
harness macos-ssh-sync --host LOGICAL_ID --migrate-per-host --plan
harness macos-ssh-sync --host LOGICAL_ID --migrate-per-host --apply
harness macos-ssh-sync --host LOGICAL_ID --finalize-per-host --plan
harness macos-ssh-sync --host LOGICAL_ID --finalize-per-host --apply
```

Migration requires the selected per-host path to be absent from fetched main,
then publishes the strictly validated live root only to that path. It never
overwrites another host. Finalization is a separate repository-wide gate that
requires exact `hosts/*.conf`/`ssh/*.conf` bijection, removes only the legacy
root payload, and raises the minimum engine to 3. Private history is
forward-only; interrupted pushes are retried from the narrow clean local
commit.

During the one-time shared-fragment migration, the sync engine recognizes a
narrow layout-only history advance. The bridge is active only when
`ssh-config-layout --plan` proves the live root and installed fragment are
already canonical. It deterministically removes only the selected shared
stanzas and managed include from the fetched and recorded-base payloads. If
those normalized bytes are equal, a clean behind private checkout may
fast-forward and publish the canonical live payload on top. Any normalized
remote difference, local-ahead history, or non-fast-forward still follows the
ordinary divergence refusal; the bridge never merges private SSH bytes.

## Linux: fixed one-way `local` to `t4`

Run only from a shell declaring `HARNESS_LOGICAL_HOST=local`:

```bash
harness ssh-config-mirror --plan
harness ssh-config-mirror --apply
harness ssh-config-mirror --rollback
```

There is no target option. The source is fixed to local `~/.ssh/config`, the
SSH alias is fixed to `t4`, and the remote destination is fixed to
`~/.ssh/config`. `ab`, `ab2`, `ri`, `al`, and `rc` are never candidates. The
adapter accepts only a regular current-user-owned, single-link, bounded,
syntax-valid source. It uses `BatchMode=yes`, a bounded connection timeout,
and only a current-user-owned Unix agent socket. Socket recovery checks the
process value, the current tmux session value, and then the host-declared fixed
runtime socket; it never reads tmux global state or lists agent identities.

Apply streams the source to a mode-0600 remote staging file, verifies its
content identity and OpenSSH grammar on `t4`, preserves exactly one mode-0600
prior image, and atomically replaces the destination only when different.
Rollback verifies the current and prior identities before atomically restoring
that one image. No operation pulls a `t4` edit back, touches another SSH file,
or contacts another Linux node.

## Failure and privacy contract

Invalid grammar, unsafe owner/type/mode/link count, dirty or divergent private
Git, non-fast-forward transport, unavailable authentication, offline targets,
and changed rollback destinations stop before overwriting a valid live file.
The whole-file Mac payload may end in one exact managed-fragment include;
validation strips that line through stdin before parsing it. Every other
`Include` and every `Match exec` remain invalid, so grammar validation cannot
inspect another SSH file or execute an owner command; hostname canonicalization
is disabled during validation.
Potentially private Git and SSH diagnostics are captured only in short-lived
mode-0600 local files and exactly unlinked; public output contains no raw
diagnostic or configuration-derived value. Private keys, `known_hosts`, loaded
agent identities, remote URLs, Keychain entries, tokens, passwords, and every
other SSH file are outside both workflows.
