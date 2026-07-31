# Validation and closeout

Require both aliases to pass fresh independent probes. On the recovered Mac,
run value-free checks:

- `macos-ssh-supervisor --host HOST --auth-status`
- `macos-ssh-supervisor --host HOST --status`
- `macos-tunnel-watchdog --status`
- `macos-doctor`
- `codex-arg0-housekeeping --plan`

Keep arg0 housekeeping separate from reboot recovery. Apply it only to
eligible tracked residue through its guarded workflow.

Without reading pane content, confirm exactly one detached, live
`harness-codex-resume` session with one Codex pane rooted at `~/harness`. The
pane may report `codex`, `codex.real`, `sh`, `bash`, or `sleep` while running,
diagnosing, or backing off. Whenever its foreground command is not Codex,
require the live value-free supervisor receipt to match the tmux pane owner.

Finish with a fresh compact `harness fleet-health` check and report
failing node names. Checkpoint unresolved state in the selected task record;
change the active board only when its routing summary changes.
