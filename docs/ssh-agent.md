# SSH agent operation

The current Ubuntu node uses the distribution's `ssh-agent.service` as the
single agent owner. It listens at the fixed user-runtime path
`$XDG_RUNTIME_DIR/openssh_agent`; `shell/environments/local.sh` exports that
path before tmux and Codex start. Cluster sessions preserve their inherited
forwarded socket and never launch a second agent.

## Activate and load

Activate the packaged unit once for the user:

```bash
systemctl --user unset-environment SSH_AUTH_SOCK SSH_AGENT_PID SSH_AGENT_LAUNCHER
systemctl --user add-wants default.target ssh-agent.service
systemctl --user start ssh-agent.service
```

In the current shell, select the fixed socket and load only the intended key.
The key choice and any passphrase remain an owner interaction:

```bash
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/openssh_agent"
ssh-add -t 8h ~/.ssh/NAME_OF_INTENDED_PRIVATE_KEY
```

`-t` limits the identity lifetime. Optional `ssh-add` constraints such as
confirmation (`-c`) or destination restrictions (`-h`) can reduce exposure
further when they fit the workflow. Do not run `ssh-agent` from `.bashrc`, a
tmux hook, or each Codex launch.

## Refresh tmux and Codex

Update only the current tmux session, then create a new pane or restart Codex:

```bash
tmux set-environment SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
tmux show-environment SSH_AUTH_SOCK
```

An already-running process cannot have its environment changed from the
outside. Restart Codex from a new pane after the session value is updated.
`update-environment` keeps future attaches current, but tmux's global
environment is not a recovery source.

## Validate without enumerating keys

These checks verify service, socket ownership, tmux propagation, and the
specific GitHub authentication capability without listing agent identities:

```bash
systemctl --user is-active --quiet ssh-agent.service
test -S "$XDG_RUNTIME_DIR/openssh_agent"
test "$(stat -c %u "$XDG_RUNTIME_DIR/openssh_agent")" -eq "$(id -u)"
test "$SSH_AUTH_SOCK" = "$XDG_RUNTIME_DIR/openssh_agent"
test "$(tmux show-environment SSH_AUTH_SOCK)" = \
  "SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/openssh_agent"
ssh -o BatchMode=yes -o ConnectTimeout=10 -T github
GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10' \
  git -C "$HOME/harness" fetch --dry-run origin main
```

GitHub's SSH greeting deliberately exits nonzero because it provides no shell;
the greeting must identify the expected GitHub account. A successful Git fetch
proves repository transport separately. Hosting API or settings access is a
different capability and must be preflighted independently with its own client
and authorization.

For forwarded cluster use, open a fresh connection through one of the six
host-specific forwarding stanzas and run only `test -S "$SSH_AUTH_SOCK"` on
that remote. Do not print or enumerate identities there.

## Recovery and rollback

For one command whose process socket is unusable, consider candidates in this
order: the process value, the current tmux session value from
`tmux show-environment SSH_AUTH_SOCK`, then
`$XDG_RUNTIME_DIR/openssh_agent`. Accept only a current-user-owned Unix socket
and bind it only to that command. Never fall back to `tmux show-environment -g`.

To disable the setup:

```bash
systemctl --user stop ssh-agent.service
systemctl --user remove-wants default.target ssh-agent.service
```

Then remove the local fixed-socket export from the managed environment and
start a new login session. Stopping the agent immediately invalidates its
socket for every client.
