# Bash startup policy

The harness centralizes portable interactive behavior while retaining each
site's required startup structure. `shell/profile.sh` owns the default editor
and portable path/cache policy. `shell/interactive.sh` owns unlimited Bash
history, the prompt, and the sorted aliases in `shell/common-aliases.sh`.

AB, AB2, and T4 deliberately source `shell/module-stack.sh` from `.bashrc`
without an interactive-shell guard. Existing job scripts sometimes source
`.bashrc`, so this compatibility behavior remains until those jobs migrate to
the clearer source-only interface:

```bash
. "$HOME/harness/shell/module-stack.sh" "$HARNESS_LOGICAL_HOST"
```

The current node's local-only `al` alias stays in its live `.bashrc`. It is not
tracked, copied, hashed, or included in transaction state. Other safe aliases
are common across all nodes. Site-only aliases remain in the relevant live
`.bashrc` and are unique and alphabetic.

## Transactional normalization

`harness startup-normalize --host HOST --plan` validates strict regular-file
metadata, constructs only the reviewed replacements, checks Bash or SSH syntax,
and reports filenames and rule counts without printing file contents. `--apply`
requires a clean harness checkout, revalidates identities and bytes, preserves
modes, uses same-directory atomic replacement, and writes a mode-0600 manifest
containing only the public before/after rule blocks. It never stores a complete
startup file.

The apply transaction ID can be reversed while every managed replacement still
matches exactly:

```bash
harness startup-normalize --rollback TRANSACTION_ID
```

Rollback is surgical: it reverses only reviewed blocks and preserves unrelated
surrounding bytes. A changed managed block causes a refusal before any file is
modified.

On the current node only, normalization adds `ForwardAgent yes` to the existing
AB, AB2, AL, RC, RI, and T4 stanzas in `~/.ssh/config`. It does not add forwarding
under `Host *`, GitHub, proxy, or service stanzas. Remote startup files no longer
start their own `ssh-agent`; remote sessions use the current node's already
running agent through those six bounded stanzas.

## SSH agent lifecycle

The current Ubuntu node runs one packaged systemd user `ssh-agent` at
`$XDG_RUNTIME_DIR/openssh_agent`. The local environment declaration exports
that stable path before tmux or Codex starts. Keys are loaded interactively by
the owner into the live agent; the harness neither selects nor inspects them.
Do not start per-shell agents.

tmux keeps a separate environment for each session. New clients update the
current session, while global tmux state can be stale indefinitely. Recovery
therefore checks the process socket first, the current tmux session second, and
the fixed declared socket last. Every candidate must be a current-user-owned
Unix socket, and a recovered value is scoped to the one intended Git or SSH
command. See [SSH agent operation](ssh-agent.md) for activation, validation,
and rollback.

## Explicit repository lifecycle

Shell startup never fetches or merges the harness checkout, and shell exit
never commits or pushes it. Network availability, authentication, checkout
state, and publication decisions therefore cannot delay login or leaving a
shell. Inspect the worktree and run the intended fetch, integration, commit,
and pull-request workflow explicitly.

The independent `IGNOREEOF=1` guard remains enabled only in a fresh top-level
direct SSH shell to protect against accidental Ctrl-D. It does not override
Bash's `exit` builtin. Tmux, nested shells, non-interactive shells, and local
shells do not receive this direct-SSH guard.
