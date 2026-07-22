# T-296 Mac connectivity resilience audit

## Status

T-296's five-hour nightly implementation and observation window is complete,
but the task remains open at the owner credential/admin gate.
Aist has the published Mac-local watchdog and recovered during several
controlled and natural dual-route losses while that watchdog was active. The
owner-launched Aist Codex also remained active, however, so those early live
results establish convergence rather than sole watchdog causation. A later
Aist outage exposed a real elapsed-time-bound defect and remained unresolved
after its stale listeners drained. Home and Office subsequently lost their last
established sessions; Riken retains two established routes but cannot create a
fresh one. Rollout and drills are therefore correctly blocked. No agent
inspected or changed a key or `authorized_keys`, and no SSH or sshd
configuration was changed. The audit read only non-credential sshd directives
needed to establish the Local include layout.

The job ended at 05:23:12 JST. Its dedicated observer ran from 00:40:09 through
05:23:10, 4h43m01s, and retained 431 value-free samples per node. Aist had nine
observed state epochs, or eight changes after its initial sample; Home and
Office each had three epochs, or two changes; Riken and ABQ each stayed in one
`ready/ready` epoch. At the endpoint Aist had remained `down/down` for at least
3h17m28s, Office for 2h46m03s, and Home for 2h45m26s. Riken and ABQ remained
`ready/ready` for the complete observer window. The temporary observer stopped
and its private mode-0600 log was exact-unlinked after these aggregates were
recorded; the permanent five-minute monitor remains alive.

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

## Final scheme and honest bounds

| Failure class | Detection and recovery | Security boundary | Expected bound after full rollout |
| --- | --- | --- | --- |
| One tunnel client exits or one upstream route fails | launchd plus the 30-second Mac watchdog restores only the failed route; the healthy sibling remains loaded | Existing dedicated identity, exact fixed listener, and zero external processes | Usually one watchdog interval plus connection and 20-second stabilization time |
| Both clients exit while old Local listeners are free | Mac watchdog serializes, probes both real binds, and restores primary then secondary | Same two restricted identities and listeners; no alternate port or identity | One watchdog interval plus sequential stabilization |
| Both clients disappear while Local retains half-open sessions | Server `15/3` encrypted-channel liveness releases listeners; Mac watchdog performs bounded drain and sequential restore | No sshd process kill and no broad `permitlisten` | Target under two minutes after matched live validation; without server liveness, stop starting probes at 1,200 elapsed seconds, then allow only the bounded in-flight probe/stabilization and one watchdog interval |
| Account-level ordinary authorization file is rewritten | Root-owned secondary `AuthorizedKeysFile` preserves the four exact tunnel entries | User agents cannot modify the root-owned file; ordinary keys remain separately managed | No outage from ordinary-file rewrite after admin rollout |
| Controller and watchdog overlap | Shared private lease permits one recovery owner; private last-run receipt identifies the watchdog result | Current-user mode-0700/0600 state with PID/start identity and exact schema | Immediate defer to the active owner, then next scheduled invocation |
| Mac is powered off, both upstream networks fail, Local or sshd is unavailable, or root-owned authorization is damaged | No SSH-only recovery path exists | Must not bypass authentication or create an unreviewed third party | Explicit external failure requiring power, network, controller, or admin repair |

The target bounds in this table are design targets until the server hardening
and all four matched live drills pass. “Never unreachable” cannot be an honest
absolute for power, network, controller, or root-policy loss; the implemented
goal is zero owner intervention for every recoverable client and stale-session
failure while retaining the current least-privilege boundary.

### Alternatives rejected

| Alternative | Why it is not the selected scheme |
| --- | --- |
| Add more fixed TCP reverse tunnels | They would share the same Mac, Local sshd, and authorization file, so they add no independence against the observed failures and create more stale-listener collisions. |
| Replace launchd with `autossh` | It can restart a client but cannot release a listener retained by Local's old sshd session; it duplicates native launchd supervision without changing the root cause. |
| Kill Local sshd children from the controller | The unprivileged account cannot attribute a root-owned listener safely to one Mac, so a kill could terminate unrelated sessions. |
| Switch to Unix-socket reverse forwards | A live probe was refused by the existing restricted authorization; permitting it would require broadening or redesigning the exact listener restriction. |
| Depend on phone remote control or a hosted overlay/VPN | This adds a separate service and trust/identity boundary. It may be useful as owner-operated out-of-band access, but it is not a security-equivalent replacement for the restricted harness tunnels. |
| Keep a user-writable canonical copy of `authorized_keys` | It duplicates credentials inside the same write boundary and can drift or be overwritten with the original. A root-owned secondary source isolates the failure instead. |

## Published control plane

| PR | Protected commit | Result |
| --- | --- | --- |
| #257 | `d188c3e9d0c045c185e6312cf43cddbc5b563064` | Transactional Mac-local watchdog, dual drain, stale-safe lease, documentation and synthetic rollback coverage. |
| #258 | `55693c581556446bb374fe2b32d64e700eae7aca` | Independent single-route drain and controller routing through the same recovery state machine. |
| #259 | `d91857b2ff11eaaf464136915bf23cfa089bba93` | Value-free fresh-auth status and healthy-but-at-risk classification. |
| #260 | `2ca91146021989014ed9b5108e99dfc8e67a0528` | Explicit primary/secondary authorization-blocked classification after a failed recovery. |
| #261 | `c0772af617fe9ddf884c104b7be54a63daf09d27` | Atomic mode-0600 last-run receipts with fixed value-free classifications and exact rollback. |
| #262 | `972988297d01a0c79d9df26a6796a059087abaa1` | True elapsed-time recovery deadline and immediate baseline restoration when authentication disappears mid-drain. |
| #263 | `d45555d55e9236f22685b8aed85b314cb71b6f9e` | Exact recovery-child signal forwarding, wait, lease release, and launchd baseline restoration. |
| #264 | `2375ec049aee107ac1501f5306aeed9237d4b144` | Direct watchdog launch and recovery isolation from unrelated branches or dirty work, with exact local-`main` runtime equivalence. |

Every PR passed protected `portable-phase1`. Clean local phase-one runs passed
all focused suites and guarded-delete tests before publication. Native macOS
probes on all four Macs proved the recovery lock's atomic noclobber behavior,
owner/mode/link gates, and stable PID/start identity. All temporary lock and
power-log probes were exact-cleaned.

After PR #264, Riken provided the only reachable native Mac validation. A
healthy `--recover-pair` invocation returned `action=none reason=route-running`;
the following status retained both routes at `managed=1 external=0`.

Guarded fleet-sync advanced local, all managed remote Linux checkouts, and all
four Macs to `2ca91146021989014ed9b5108e99dfc8e67a0528`. One
overlapping fleet-sync retry observed an already-applied first target; the
subsequent all-host plan found every target clean/current and no transfer
artifact. Persistent monitor script replacement produced one NFS placeholder
held by exactly the two known tmux monitors; respawning only those panes onto
the new committed script released it automatically.

After PRs #261 through #264, Local, the managed Linux checkouts, and Riken
advanced cleanly to `2375ec049aee107ac1501f5306aeed9237d4b144`. Aist, Home, and Office
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
- The deployed watchdog also required the entire shared `~/harness` checkout
  to be clean on branch `main`. The owner-launched Aist Codex used that same
  checkout, so unrelated branch or dirty work could disable recovery. Aist is
  unreachable, so this cannot be asserted as the cause of the current event.
  PR #264 nevertheless removes the latent defect: launchd invokes the watchdog
  directly, and recovery accepts unrelated work only when every critical
  runtime script and public profile exactly matches the local `main` ref.
  Synthetic unrelated-file and feature-branch cases pass; a critical-script
  difference fails closed.
- After the audit branch integrated current `main`, its first parallel phase-1
  run saw one load-sensitive signal-test miss. The same focused suite then
  passed once in isolation, four concurrent runs, the next complete phase-1
  run, and six further concurrent runs: twelve subsequent passes with no
  retained child or lock. Protected CI also passed. Because no cleanup defect
  reproduced, production behavior was not weakened to mask the single miss.
- A two-hour power-log classification around the earlier recurrence found no
  Aist sleep or wake event. The private native log was never printed and was
  exact-unlinked.

The watchdog rollback is intentionally retained and removes only its unchanged
transaction-owned launch agent and private current pointer:

```bash
harness macos-tunnel-watchdog --rollback 20260722T160219Z-66174
```

Rollback is not indicated while Aist is stranded: the transaction restores its
launchd baseline on failure, and removing the only installed local recovery
authority would not repair authorization or upstream connectivity.

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

Home later recovered temporary inbound reachability without changing an
authorization. One surviving current-user `login` ControlMaster accepted both
configured reverse-forward requests through multiplex control operations, so
`home` and `home2` both appeared reachable but shared the primary transport.
Both launchd services remained loaded and stopped with `managed=0 external=0`,
and fresh dedicated authentication remained blocked. This is useful rescue
access, not independent-route acceptance. The permanent handover must first
restore dedicated authorization, then cancel and replace one exact temporary
forward at a time while preserving its sibling; the ordinary ControlMaster
must not be terminated merely to remove the forwards.

Office later used its surviving ordinary `login` ControlMaster to repair only
its existing restricted entry in Local's user-level authorization file. The
transaction preserved unrelated lines, used the existing identity and complete
effective forwarding contracts, and retained exact `permitopen` and
`permitlisten` restrictions. A first portable-validation attempt stopped
before remote mutation; its corrected successor completed and exact-unlinked
its private preimage, expected postimage, logs, helper, and transaction state.
Fresh dedicated authentication then returned `auth_blocked=0`; both independent
inbound probes passed and both launchd services reported
`loaded=yes running=yes managed=1 external=0`. This supersedes Office's `0/2`
endpoint but remains temporary because JumpCloud can reconcile the user-level
file again; the root-owned secondary file is still required.

Office also has an additional pre-existing `Match all` before its private
tunnel stanzas. Effective tunnel settings work, but the public layout planner
correctly rejects the unmanaged Match. It was not changed during authorization
recovery and remains a separate cleanup item after durable reachability.

Aist later used the same rescue pattern from a newly created ordinary `login`
ControlMaster: it attached both exact reverse-forward requests and Local proved
both inbound aliases, but the routes shared one transport. Both launchd
services remained loaded and stopped with `managed=0 external=0`, fresh
dedicated authentication remained blocked, and the installed watchdog's latest
receipt remained `authorization-blocked`. The ordinary master then ended and
both routes disappeared before Local could confirm a detached full-restriction
restage. No authorization, service, or repository state changed. Aist's
canonical staging helper must therefore run from its persistent local terminal
or Codex session, not through the rescue forward whose lifetime it is trying to
outlive.

An established SSH session surviving removal of its authorization explains why
ordinary route probes had previously looked healthy. The new audit prevents
that false assurance, but software cannot repair missing credential state.

## JumpCloud-aware permanent hardening

The owner confirmed that Local is the only JumpCloud-managed node. On Local,
`jcagent.service` and `ssh.service` are active, the managed global directive is
`AuthorizedKeysFile .ssh/authorized_keys`, and neither that live file nor the
empty `.ssh/authorized_keys.jcorig` contains any of the four restricted tunnel
entries. This reconciles the earlier apparently spontaneous authorization
loss: JumpCloud's management of the account-level file is the probable drift
source. The `.jcorig` behavior is not used as a security boundary because it is
empty here and is not isolated from account-level maintenance.
[JumpCloud's SSH configuration guidance](https://jumpcloud.com/support/configure-ssh-settings)
documents that its agent ignores settings inside a conditional `Match` block;
that documented exception is the persistence mechanism used below.

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

This change requires owner/admin handling because it changes system sshd policy
and credential authorization. The owner explicitly authorized a reviewed
value-free helper that passes each existing identity only by its file path and
executes the privileged Local changes after an exact confirmation. The helper
does not display, log, hash, generate, or alter an identity.

Local is Ubuntu 24.04 with `ssh.service` active. Its current
`/etc/ssh/sshd_config` sets `AuthorizedKeysFile .ssh/authorized_keys` at line
3, before `Include /etc/ssh/sshd_config.d/*.conf` at line 19. OpenSSH's server
configuration schema marks `AuthorizedKeysFile` for Match-time copying, so a
matching later block can safely replace that global value for this user. The
privileged helper still treats this as a runtime assertion: it must prove the
two-path value using `sshd -T -C` before and after reload or roll back. An
unprivileged query cannot access a host key, so both checks use the installed
service privileges.

### One-time owner/admin sequence

Perform this on Local from a separately preserved administrative session. The
exact filesystem locations and reload command must follow Local's installed
OpenSSH service; do not paste guessed paths into production.

1. Stage one entry from each owning Mac. Use its existing dedicated identity
   and effective `tunnel` / `tunnel2` listener contracts; do not generate an
   identity, display any key material, remove unrelated authorizations, or
   broaden any key option.
2. Create `/etc/ssh/harness_tunnel_authorized_keys` as root:root mode 0644 and
   place only those four exact entries in it. Mode 0644 is required because
   OpenSSH temporarily uses the target user's UID when opening authorized-key
   files. The entries are public keys; root ownership and the root-owned parent
   prevent account-level modification.
3. Add a Local-only drop-in containing `Match User rioyokota`, both
   `.ssh/authorized_keys` and the root-owned tunnel path, and
   `ClientAliveInterval 15` / `ClientAliveCountMax 3`, followed by `Match all`.
   OpenSSH explicitly reprocesses and copies `AuthorizedKeysFile` from a
   matching block, so this overrides the earlier JumpCloud-managed global
   value without editing it. JumpCloud's documented exception for settings in
   a conditional Match block prevents its agent from removing this scope.
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

This is one bundled intervention on Local only. Once complete, ordinary
user-level rewrites of `.ssh/authorized_keys` cannot remove the restricted
tunnel entries, and server liveness releases abandoned listener sockets on a
short, documented bound.

## Remaining acceptance sequence

1. Owner verifies all four exact restricted entries and restores any missing
   Aist, Home, Office, or Riken entry; optionally move all four entries into the
   root-owned secondary file.
2. Require `auth_blocked=0` on all four Macs; then restore all missing routes
   through the published bounded recovery.
3. Upgrade Aist to the current direct-launch watchdog transaction, then install
   the watchdog on Home, Office, and Riken one at a time.
4. After each install, run primary-only, secondary-only, and simultaneous-loss
   drills, retaining a healthy sibling whenever possible and validating both
   inbound routes plus `managed=1 external=0`.
5. Run a post-hardening acceptance soak with all four Macs, retain the
   five-minute recovery monitor, and close T-296 only after all four pass.

## Current runtime state

- `harness-connection-monitor`: five-minute recovery and fresh-auth audit.
- `t296-night-watch`: stopped after the five-hour endpoint; its private log was
  summarized value-free and exact-unlinked.
- The owner-launched Codex process remained present on Aist during the early
  drills, so watchdog exit 0 does not by itself exclude concurrent Codex
  intervention. Its two historical tunnel tmux panes were both dead. Local
  queued an explicit observe-only coordination request to the live Codex pane
  and interrupted one active TUI turn with Ctrl-C while trying to deliver it.
  The Codex process was not killed, but no acknowledgement arrived and the
  interruption may have stopped its separate monitoring turn. An independent
  post-acknowledgement recovery sample remains required for sole-attribution
  evidence.
- Credential and SSH configuration bytes remain outside repository evidence.
- At the final endpoint, only Riken's two Mac routes remained reachable; the
  other three Mac pairs were `0/2`. ABQ remained `2/2`. The recovering
  five-minute monitor remains alive on Local.
- Routine arg0 housekeeping preserved three live invocations, removed six
  eligible residues through guarded deletion, and ended with zero eligible or
  unexpected candidates.
