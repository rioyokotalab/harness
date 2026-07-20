# Explicit whole-file SSH configuration synchronization

Two intentionally separate commands synchronize only complete OpenSSH config
files. Neither is a general dotfile adapter, fleet action, scheduler, timer, or
credential manager. Both run only when the owner invokes them.

## Personal Macs: SSH-only desired state

`harness macos-ssh-sync --host LOGICAL_ID` is the engine-1 SSH-only route. The
engine-2 atomic SSH/Bash/tmux bundle is retained only as a sleeping-Mac
migration source; Bash and tmux now use public shared configuration as
documented in
[`personal-macos-config-sync.md`](personal-macos-config-sync.md). The private companion
stores the single root `ssh_config` payload; the live destination is fixed to
`~/.ssh/config`. The current live file, fetched `origin/main` payload, and
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
`Include` and `Match exec` are invalid for these payloads so grammar validation
cannot inspect another SSH file or execute an owner command; hostname
canonicalization is disabled during validation.
Potentially private Git and SSH diagnostics are captured only in short-lived
mode-0600 local files and exactly unlinked; public output contains no raw
diagnostic or configuration-derived value. Private keys, `known_hosts`, loaded
agent identities, remote URLs, Keychain entries, tokens, passwords, and every
other SSH file are outside both workflows.
