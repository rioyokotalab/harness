# Recovery and tmux start

Start only after status proves both routes, clean/current `main`, both tunnel
supervisors, the watchdog, and two service-owned remote-control daemons ready:

```sh
shared/skills/reboot-recovery/scripts/recover-mac-after-reboot \
  --host HOST --start-tmux
```

The helper creates the standard detached session only when it is absent:

```sh
tmux new-session -d -s harness-codex-resume -c "$HOME/harness" \
  "exec \"$HOME/harness/bin/harness\" codex-resilient --run \
    --name harness-codex-resume --last"
```

The foreground supervisor never reconstructs or replays a prompt. If Codex
exits nonzero while its redacted native doctor still reports healthy local
authentication, configuration, installation, and state, resume the saved chat
after bounded exponential backoff. Permanent local failures and operator exits
stop. Retain an already healthy legacy or supervised session unchanged.
