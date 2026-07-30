# Status and discovery

1. Read the repository instructions and `TODO.md`, fetch the collaborative
   remote, and reconstruct the current published revision and fleet state.
2. From Local, run:

   ```sh
   shared/skills/reboot-recovery/scripts/recover-mac-after-reboot \
     --host HOST --status
   ```

   The helper probes both routes independently without multiplexing or
   forwarding and reports only value-free state.
3. If neither route works, ask the owner to log into the Mac locally and wait
   for the managed launchd tunnels. Do not recover through another identity.
4. If Codex remote control is absent, ask the owner to run this from the normal
   account's local Terminal:

   ```sh
   cd "$HOME/harness"
   "$HOME/.local/bin/harness-codex" remote-control start
   ```

   Existing pairing normally persists across reboot. Re-pair only when the
   native client explicitly requests it. Ask the owner to report completion,
   then rerun status.
5. If status reports any router blocker, stop and diagnose it separately. Use
   guarded fleet sync only for a clean managed checkout.
