# T-296 Mac connectivity resilience audit

## Status

T-296 is partially converged and remains open at the owner-credential gate.
Aist has the published Mac-local watchdog and recovered during several
controlled and natural dual-route losses while that watchdog was active. The
owner-launched Aist Codex also remained active, however, so those early live
results establish convergence rather than sole watchdog causation. A later
Aist outage exposed a real elapsed-time-bound defect and remained unresolved
after its stale listeners drained. Home and Office subsequently lost their last
established sessions; Riken retains two established routes but cannot create a
fresh one. Rollout and drills are therefore correctly blocked. No agent
inspected or changed a key, `authorized_keys`, SSH configuration, or sshd
configuration.

The frozen design and acceptance gates are in
[`docs/plans/t296-mac-connectivity-resilience.md`](../plans/t296-mac-connectivity-resilience.md).

## Root cause and rejected alternatives

Aist's repeated simultaneous outages preserve dedicated authentication while
both launchd jobs stop with exit 255 and both fixed reverse-listener ports stay
occupied on Local. Real forward-bind probes fail until the server releases the
old half-open SSH sessions. The former 15-second launchd retry loop repeatedly
attempted the same occupied ports and provided no bounded drain phase.

The controller can observe those root-owned sshd listeners but cannot map them
unambiguously to one Mac. Killing a server process was therefore rejected.
Additive TCP and Unix-socket reverse-listener probes were also rejected after
the existing restricted authorization refused them. The task did not broaden
`permitlisten`, add a key, weaken key restrictions, change server policy, or
introduce an external connectivity service.

The implemented recovery instead runs on the Mac, where it remains reachable
even when both inbound routes disappear. A transaction-owned launchd watchdog
serializes with controller recovery through a crash-recoverable private lease,
stops only failed exact services, polls real forward binds, and restores each
route independently. It leaves a healthy sibling untouched and restores the
launchd baseline on timeout or failure.

## Published control plane

| PR | Protected commit | Result |
| --- | --- | --- |
| #257 | `d188c3e9d0c045c185e6312cf43cddbc5b563064` | Transactional Mac-local watchdog, dual drain, stale-safe lease, documentation and synthetic rollback coverage. |
| #258 | `55693c581556446bb374fe2b32d64e700eae7aca` | Independent single-route drain and controller routing through the same recovery state machine. |
| #259 | `d91857b2ff11eaaf464136915bf23cfa089bba93` | Value-free fresh-auth status and healthy-but-at-risk classification. |
| #260 | `2ca91146021989014ed9b5108e99dfc8e67a0528` | Explicit primary/secondary authorization-blocked classification after a failed recovery. |
| #261 | `c0772af617fe9ddf884c104b7be54a63daf09d27` | Atomic mode-0600 last-run receipts with fixed value-free classifications and exact rollback. |
| #262 | `972988297d01a0c79d9df26a6796a059087abaa1` | True elapsed-time recovery deadline and immediate baseline restoration when authentication disappears mid-drain. |

Every PR passed protected `portable-phase1`. Clean local phase-one runs passed
all focused suites and guarded-delete tests before publication. Native macOS
probes on all four Macs proved the recovery lock's atomic noclobber behavior,
owner/mode/link gates, and stable PID/start identity. All temporary lock and
power-log probes were exact-cleaned.

Guarded fleet-sync advanced local, all managed remote Linux checkouts, and all
four Macs to `2ca91146021989014ed9b5108e99dfc8e67a0528`. One
overlapping fleet-sync retry observed an already-applied first target; the
subsequent all-host plan found every target clean/current and no transfer
artifact. Persistent monitor script replacement produced one NFS placeholder
held by exactly the two known tmux monitors; respawning only those panes onto
the new committed script released it automatically.

After PRs #261 and #262, Local, the managed Linux checkouts, and Riken advanced
cleanly to `972988297d01a0c79d9df26a6796a059087abaa1`. Aist, Home, and Office
became unreachable before their guarded preflight and remain at the earlier
commit; both failed plans stopped before mutation. Aist consequently does not
yet have the new receipt or elapsed-deadline code deployed.

## Aist pilot evidence

- Watchdog transaction: `20260722T160219Z-66174`.
- Healthy install: both routes stayed reachable, both tunnel services remained
  `managed=1 external=0`, and the watchdog's first run exited 0.
- Single-route unloads: both primary and secondary returned without owner
  interaction. The measured secondary recovery was 23 seconds. The active
  Aist Codex means the live actor cannot be attributed exclusively.
- Controlled simultaneous unload: both Local routes disappeared and both
  stale listener ports remained occupied. Both routes returned without a
  controller route, with the primary first and both routes in roughly seven
  minutes. Final ownership was exactly one managed process per route, zero
  external processes, and watchdog exit 0; the concurrently active Aist Codex
  prevents assigning that recovery solely to the watchdog.
- Natural soak recurrence at 01:36 JST: the 30-second observer recorded Aist
  `0/2` at 01:36:28; both routes were ready at 01:37:07, bounding that
  no-owner-interaction recovery sample to 39 seconds at observer resolution. Final supervisor status
  again showed `managed=1 external=0` for both routes and watchdog exit 0.
- Natural soak recurrence at 02:05:44: Aist entered `0/2` and stayed there.
  Both Local listeners were confirmed occupied at 02:15 and absent at 02:23,
  but neither route rebound. This separates successful stale-session drainage
  from failed post-drain reconnection. The deployed retry-count bound ignored
  up to two sequential SSH probe timeouts per iteration, so its nominal
  `80 * 15 seconds` bound could extend to roughly 41 minutes. PR #262 replaces
  that with a 1,200-second elapsed deadline and checks auth without a forward
  after every failed bind probe. A lost authorization now restores the exact
  launchd baseline immediately and records `authorization-blocked`; otherwise
  the real elapsed deadline records `drain-timeout`.
  Aist was still `0/2` at 02:47:35, more than 41 minutes after first detection,
  so the deployed loop did not restore reachability at its calculated edge.
- A two-hour power-log classification around the earlier recurrence found no
  Aist sleep or wake event. The private native log was never printed and was
  exact-unlinked.

The watchdog rollback is intentionally retained and removes only its unchanged
transaction-owned launch agent and private current pointer:

```bash
harness macos-tunnel-watchdog --rollback 20260722T160219Z-66174
```

Rollback is not indicated while the Aist soak remains healthy.

## Authorization drift discovered by soak

Fresh isolated dedicated-authentication checks produced this value-free state:

| Mac | Fresh primary | Fresh secondary | Established inbound state at discovery |
| --- | --- | --- | --- |
| Aist | ready | ready | `2/2` |
| Home | blocked | blocked | primary ready, secondary down |
| Office | blocked | blocked | initially `2/2`; primary later down |
| Riken | blocked | blocked | `2/2` |

Home's unread mode-0600 SSH trace classified both attempts as authorization
rejection, not DNS, TCP, route, or host-key failure, and was exact-unlinked.
The Local listener for Home2 was absent, distinguishing it from Aist's stale
listener failure. The new five-minute monitor now reports:

- Aist: `healthy action=none`.
- Office: `at-risk action=authorization-blocked-primary`.
- Riken: `at-risk action=authorization-blocked` while both old routes live.
- Home: `at-risk action=authorization-blocked-secondary`.

The warning became predictive during the same soak. Office's last established
route ended at 02:37:09 and Home's at 02:37:46; neither could replace its
session because both dedicated authorizations were already blocked. The live
state then became Aist `0/2`, Home `0/2`, Office `0/2`, and Riken `2/2` with
Riken still at risk. This is not repairable from Local without credential
handling or an already-live Mac route.

An established SSH session surviving removal of its authorization explains why
ordinary route probes had previously looked healthy. The new audit prevents
that false assurance, but software cannot repair missing credential state.

## Owner-only permanent hardening proposal

The least-intervention security-preserving server design is one root-owned
secondary `AuthorizedKeysFile` dedicated to the four restricted tunnel
entries. Keep the account's current ordinary key file in sshd's effective list
and add an absolute root-owned harness file. This isolates tunnel authorization
from ordinary user-level `authorized_keys` rewrites. Preserve the exact prior
per-Mac restrictions and listener bounds; do not reconstruct or broaden them.

Scope server-side liveness to this account with `ClientAliveInterval 15` and
`ClientAliveCountMax 3`, symmetric with the managed clients. Responsive idle
sessions remain connected, while a Mac that disappears without a TCP close is
disconnected by sshd after roughly 45 seconds, releasing its listeners before
the watchdog reconnects. The tradeoff
is that any genuinely unresponsive SSH session for this account is discarded
sooner. Validate the effective `Match User` configuration with `sshd -T -C`,
validate syntax with `sshd -t`, and reload rather than restart sshd so current
sessions remain available.

OpenSSH documents that `AuthorizedKeysFile` accepts multiple whitespace-
separated files and that server client-alive messages are sent through the
encrypted channel. Primary references:

- [OpenBSD `sshd_config(5)`](https://man.openbsd.org/sshd_config)
- [OpenBSD `sshd(8)`](https://man.openbsd.org/sshd.8)

This proposal requires owner/admin handling because it changes system sshd
policy and credential authorization. The agent must not create the root file,
read/copy the entries, or edit either authorization source.

### One-time owner/admin sequence

Perform this on Local from a separately preserved administrative session. The
exact filesystem locations and reload command must follow Local's installed
OpenSSH service; do not paste guessed paths into production.

1. Preserve the current sshd configuration and authorization files with
   root-only owner, mode, and rollback metadata. Obtain the exact four prior
   restricted tunnel entries from the owner's trusted source. Do not derive a
   new entry, remove unrelated authorizations, or broaden any key option.
2. Create a root-owned mode-0600 secondary authorization file outside the
   account-writable `.ssh` tree and place only those four exact entries in it.
3. At the effective first-value position for this account, set
   `AuthorizedKeysFile` to both the existing ordinary authorization path and
   the new root-owned tunnel file. Scope `ClientAliveInterval 15` and
   `ClientAliveCountMax 3` to `Match User rioyokota`; terminate conditional
   scope explicitly with `Match all` where the installed include layout
   requires it.
4. Use `sshd -T -C user=rioyokota,host=localhost,addr=127.0.0.1` to prove the
   effective authorization-file list and `15/3` liveness values. Use `sshd -t`
   for full syntax validation. Any mismatch aborts and restores the preserved
   files.
5. Reload—not restart—the native sshd service and keep the administrative
   session open. Re-run the effective query, then require both fresh dedicated
   auth probes from every Mac. The expected aggregate is `auth_blocked=0` on
   Aist, Home, Office, and Riken.
6. Let the already-loaded supervisors reconnect. Verify all eight inbound
   routes, exact `managed=1 external=0` ownership, and zero external tunnel
   processes before closing the administrative session.

This is one bundled intervention. Once complete, ordinary user-level rewrites
of `.ssh/authorized_keys` cannot remove the restricted tunnel entries, and
server liveness releases abandoned listener sockets on a short, documented
bound.

## Remaining acceptance sequence

1. Owner verifies all four exact restricted entries and restores any missing
   Aist, Home, Office, or Riken entry; optionally move all four entries into the
   root-owned secondary file.
2. Require `auth_blocked=0` on all four Macs; then restore all missing routes
   through the published bounded recovery.
3. Install the watchdog transaction on Home, Office, and Riken one at a time.
4. After each install, run primary-only, secondary-only, and simultaneous-loss
   drills, retaining a healthy sibling whenever possible and validating both
   inbound routes plus `managed=1 external=0`.
5. Complete the nightly soak, publish final event counts/recovery bounds, stop
   the temporary 30-second observer, retain the five-minute recovery monitor,
   and close T-296 only after all four Macs pass.

## Current runtime state

- `harness-connection-monitor`: five-minute recovery and fresh-auth audit.
- `t296-night-watch`: temporary 30-second route-only observer; no recovery, so
  it cannot race the watchdog.
- The owner-launched Codex process remained present on Aist during the early
  drills, so watchdog exit 0 does not by itself exclude concurrent Codex
  intervention. Its two historical tunnel tmux panes were both dead. Local
  queued an explicit observe-only coordination request to the live Codex pane;
  an independent post-acknowledgement recovery sample remains required for
  sole-attribution evidence.
- Credential and SSH configuration bytes remain outside repository evidence.
- At the latest checkpoint, only Riken's two Mac routes remained reachable;
  the other three Mac pairs were `0/2`. The recovering five-minute monitor and
  30-second observer both remained alive on Local.
