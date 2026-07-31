# T-352 pane-native Local Codex projects

## Outcome

Replace Local's three canonical one-pane windows with one canonical window
containing three independently supervised Codex panes:

| Target | Pane | Canonical repository |
| --- | --- | --- |
| Harness | `projects:0.0`, title `harness` | `/home/rioyokota/harness` |
| Students | `projects:0.1`, title `students` | `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/students` |
| Swallow | `projects:0.2`, title `swallow` | `/mnt/nfs-03/safe/Users/rioyokota/codex-workspaces/swallow` |

The sole window is `projects:0:codex`. Its initial layout is
`main-vertical`; Harness is the main pane. `Ctrl-b z` toggles the selected
pane's zoom without changing target identity.

## Scope and boundaries

T-352 changes Local topology recognition, ordering, blocked-root recovery
identity, phone-mirror mapping, controller selection, documentation, and
focused tests. It performs one process-preserving live cutover only after
protected publication.

It does not inspect pane contents, alter saved-root metadata, start a new
interactive root, restart the shared app server, execute Students or Swallow
work, or promise Local host-reboot resurrection. Managed-Mac
`harness-codex-resume` remains a separate one-pane contract.

## Confirmed facts

1. The live project panes are healthy and already have the desired target
   repository cwd.
2. `join-pane` and `break-pane` preserve the pane process and immutable pane
   ID; source one-pane windows disappear only after their pane is moved.
3. Current monitor health and order code requires exactly three named windows
   with one pane each.
4. Current helper and phone-mirror mapping use window index/name/ID as target
   identity.
5. The remote-agent controller selector requires window `0:harness`.
6. The tmux server currently binds `Ctrl-b z` to `resize-pane -Z`, but the
   tracked configuration does not state that preference explicitly.
7. No tmux-resurrect, continuum, or persistent Local tmux recreation unit is
   configured in the inspected repository, tmux options, or user services.

## Execution

### 1. Model one canonical window and three panes

1. Keep the closed target ordering in
   `profiles/codex-session-targets.tsv`, documenting its ordinal as a pane
   index.
2. Add shared canonical session/window constants beside the target map.
3. Change monitor snapshots from one row per window to one row per pane,
   requiring exact window index/name/ID, pane-local `@harness_target` role,
   pane index, cwd, dead state, supervisor target, runtime, watcher, TUI, and
   app-server identity. Treat application-owned title as presentation only;
   render stable border labels from the pane-local role.
4. Order only an otherwise exact topology with native `tmux swap-pane -d`.
   Freeze attached clients' selected pane IDs before and after ordering.
5. Record pane ID/index in durable monitor mappings and blocked-root events.

### 2. Adapt recovery and phone mirroring

1. Change helper tmux mapping to the same exact pane contract.
2. Bind each phone root to target, thread, cwd, pane ID/index, and the shared
   canonical window.
3. Treat a target as attached when any `projects` client has that target pane
   selected. An inactive sibling pane may remain eligible for bounded
   auto-recovery.
4. Preserve bridge-first recovery: create and accept a distinct provisional
   root/window/runtime, then move only its accepted pane into the canonical
   window during promotion. Preserve the old pane until acceptance and retain
   exact rollback metadata.
5. Update recovery-worker instructions to use pane-native identity and never
   replay a rejected prompt.

### 3. Adapt controller transport and tmux configuration

1. Select the Local Harness controller by exact session/window, pane-local
   role/index, cwd, TTY, and sole Codex process.
2. Leave the managed-Mac one-pane selector unchanged.
3. Track the native `bind-key z resize-pane -Z` binding explicitly.
4. Update operator documentation from window replacement to pane replacement
   and state the host-reboot boundary accurately.

### 4. Validate before publication

1. Extend monitor tests for canonical panes, wrong title/cwd/window, duplicate
   title, dead/missing/extra panes, safe reordering, client preservation,
   active-pane attachment, recovery candidates, and mapping.
2. Extend helper tests for pane mapping, phone parity, blocked identities, and
   pane-native worker instructions.
3. Extend remote-agent and tmux configuration tests.
4. Use a disposable tmux server to prove that joining and breaking panes
   preserve pane IDs and process PIDs and that zoom toggles on/off.
5. Run all owning suites, `git diff --check`, `harness validate`, and final
   `tests/test-phase1.sh`. Independently inspect the complete diff.

### 5. Publish and activate

1. Fetch and integrate non-conflicting remote work.
2. Commit and push small verified checkpoints.
3. Open one protected task pull request, wait for required checks, and merge
   normally without force-push or workflow dispatch.
4. Freeze live session, pane, process, client, supervisor, watcher, app-server,
   thread, cwd, monitor, and helper identities without reading panes.
5. Pause only monitor/helper loops in their exact tmux panes.
6. Apply the process-preserving cutover:
   rename `@87` to `codex`; assign frozen pane-local roles and titles to
   `%87`, `%99`, `%100`; join `%99` and `%100` into `@87`; require pane
   indices `0`, `1`, `2`; apply `main-vertical` and stable role-based border
   labels; preserve the attached client and active Harness pane.
7. Run the published monitor/helper checks against the new topology. On any
   failure, use the frozen pane IDs with `break-pane -d` to reconstruct exact
   `0:harness`, `1:students`, `2:swallow` windows before restarting the old
   control loops.
8. Fast-forward the Local primary checkout only after proving no tracked or
   untracked collision with the preserved `.nfs` inode. Restart only the
   monitor/helper panes with published code.
9. Apply guarded fleet synchronization only to eligible clean managed
   checkouts and issue required safe context refreshes.

## Acceptance gates

- One attached `projects` session, one `0:codex` window, and exactly three live
  panes role-marked and indexed `harness/0`, `students/1`, `swallow/2`, with
  stable role-based border labels.
- Original project pane IDs, pane PIDs, supervisor identities, TUI identities,
  saved threads, app-server identity, cwd, and attached client are unchanged.
- `Ctrl-b z` changes `window_zoomed_flag` from `0` to `1` and back to `0`.
- Two interval-separated receipts report monitor `healthy=3`,
  `phone_mirror=healthy`, and helper idle.
- Controller-message selection resolves only the Harness pane; Mac selection
  remains unchanged.
- No app-server write, root launch/name/archive action, project work, prompt
  replay, or pane-content read occurs.
- Focused and full validation pass on the published bytes.
- Git, managed checkout, and fleet postconditions are explicitly reported.

## Rollback and interruption

- Before live mutation, record immutable IDs and exact commands in this task
  record. Do not rely on chat history.
- Before publication, discard no user work and leave the live session
  untouched.
- If only one join succeeds, `break-pane -d` that exact pane back to its old
  index/name; restore `@87` to `harness`.
- If both joins succeed but validation fails, break `%99` and `%100` back into
  windows `1:students` and `2:swallow`, restore window and pane titles, and
  restart the original monitor/helper commands.
- Never retry an ambiguous tmux write. Re-read immutable IDs and current
  topology first.
- If interrupted after successful cutover, preserve the accepted panes and
  resume from the first unverified activation gate in `docs/tasks/T-352.md`.
