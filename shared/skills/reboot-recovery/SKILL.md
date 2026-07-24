---
name: reboot-recovery
description: Restore and validate the repository-managed tunnels, Codex remote control, and standard Codex tmux session after aist, home, office, or riken reboots. Use when a managed personal Mac has restarted, returned after power loss, lost its normal Codex session, or needs a post-reboot readiness check from Local.
---

# Recover a managed Mac after reboot

Recover one named Mac at a time. Treat Git, `TODO.md`, and the closest
instructions as authoritative. Do not infer readiness from a phone connection
or an earlier conversation.

## Boundaries

- Limit this workflow to `aist`, `home`, `office`, or `riken`.
- Never inspect, print, copy, hash, generate, or modify credentials or SSH key
  material.
- Never read or capture tmux pane contents.
- Do not change SSH configuration, tunnel authorization, launchd definitions,
  pairing, or repository files as part of routine reboot recovery.
- Do not perform repository cleanup. Never remove, ignore, or specially classify
  `.DS_Store`; any dirty checkout is a blocker for separate housekeeping.
- Stop on an unavailable route pair, divergent or dirty checkout, missing
  managed service, unexpected remote-control topology, or conflicting tmux
  state. Do not guess ownership or manufacture a replacement service.

## Recover

1. Read the repository instructions and `TODO.md`, fetch the collaborative
   remote, and reconstruct the current published revision and fleet state.
2. From Local, run:

   ```sh
   shared/skills/reboot-recovery/scripts/recover-mac-after-reboot \
     --host HOST --status
   ```

   The helper probes both routes independently without multiplexing or
   forwarding, then reports only value-free state. If neither route works,
   ask the owner to log into the Mac locally and wait for the managed launchd
   tunnels. Do not attempt recovery through an unrelated identity.
3. If the Mac has not restored Codex remote control, ask the owner to run this
   from that Mac's Terminal after logging into the normal account:

   ```sh
   cd "$HOME/harness"
   "$HOME/.local/bin/harness-codex" remote-control start
   ```

   Existing pairing normally persists across reboot. Re-pair only when the
   native client explicitly requests it. Ask the owner to report completion,
   then rerun status.
4. If status reports a dirty or non-current checkout, missing tunnel/watchdog
   service, or other ambiguity, stop recovery and diagnose that condition as a
   separate task. Use guarded fleet sync only for a clean managed checkout;
   never hide a blocker to make recovery continue.
5. Once both routes, clean/current `main`, both tunnel supervisors, watchdog,
   and the two service-owned remote-control daemons are ready, run:

   ```sh
   shared/skills/reboot-recovery/scripts/recover-mac-after-reboot \
     --host HOST --start-tmux
   ```

   This creates the standard detached session only when it is absent:

   ```sh
   tmux new-session -d -s harness-codex-resume -c "$HOME/harness" \
     "$HOME/.local/bin/harness-codex resume --last"
   ```

   An already healthy session is retained unchanged.

## Validate

Require both aliases to pass fresh independent probes. Through the recovered
Mac, run the repository's current value-free checks for:

- `macos-ssh-supervisor --host HOST --auth-status`
- `macos-ssh-supervisor --host HOST --status`
- `macos-tunnel-watchdog --status`
- `macos-doctor`
- `codex-arg0-housekeeping --plan`

Apply arg0 housekeeping only to eligible tracked residue through its guarded
workflow; do not conflate it with reboot recovery. Confirm exactly one
detached, live `harness-codex-resume` session with one Codex pane rooted at
`~/harness`, without reading the pane. Finish with a fresh compact fleet
health check and report only failing node names.

Checkpoint any unresolved state in `TODO.md`. A failed query is unknown state,
not proof that a service is absent.
