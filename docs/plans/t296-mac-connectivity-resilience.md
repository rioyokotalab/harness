# T-296 Mac connectivity resilience plan

## Control state

- Task: T-296, extended by the owner's five-hour nightly instruction.
- Phase: plan frozen; evidence collection and reversible implementation are
  authorized.
- Planning date: 2026-07-23.
- Driver: Codex on `local`.
- Mutation gate: satisfied by the owner's explicit instruction to establish a
  safe connection scheme, iterate, test, and execute autonomously for five
  hours.
- Collaboration: `codex-claude-cowork` remains excluded by the owner's prior
  direction for this connection task. The independent Codex on Aist may keep
  observing and restoring the existing services, but the new implementation
  must neither depend on it nor race it.

## Outcome and honest bound

Eliminate owner or controller intervention for every recoverable failure of a
Mac's managed SSH clients or Local's stale reverse-forward listeners. Retain
two independently routed, launchd-managed reverse tunnels per Mac and restore
them automatically after sleep, transient network loss, client termination,
or a stale fixed-port listener. No design can promise reachability while a Mac
is powered off, its network and both upstream routes are unavailable, or the
Local SSH service itself is unavailable; those are explicit external bounds,
not silent exceptions.

## Confirmed evidence

- All four Macs have two independent current-user launchd services using the
  existing dedicated restricted identity. Healthy peers report exactly one
  managed process and no external owner for each route.
- Repeated Aist outages preserve successful dedicated authentication while
  both launchd jobs are loaded but not running and both fixed reverse-listener
  ports remain occupied on Local.
- During the 2026-07-23 live recurrence, `aist` and `aist2` were both
  unreachable while Home, Office, and Riken remained independently healthy.
- Aist's local report shows that ordinary kick/retry attempts fail to bind the
  occupied reverse ports. Unloading both exact services, allowing the stale
  server sessions to drain, proving each real forward bind, and bootstrapping
  the services restored both routes without changing a key or SSH config.
- Local can observe the listener sockets but cannot unambiguously associate
  their root-owned sshd listener processes with a particular Mac. A
  controller-side process kill therefore fails the least-authority and exact-
  target gates.
- A new TCP port and a Unix-domain reverse listener both failed under the
  existing restricted authorization. Broadening key options or changing
  server-wide sshd policy would weaken the current boundary and is rejected.
- OpenSSH supports Unix-socket remote forwards and a server-side unlink option,
  but that option is not enabled by the current server contract. The relevant
  primary documentation is the OpenBSD
  [`ssh_config(5)`](https://man.openbsd.org/OpenBSD-current/man5/ssh_config.5)
  and [`sshd(8)`](https://man.openbsd.org/sshd.8). Apple's archived launchd
  guidance confirms that `KeepAlive` jobs are relaunched, which explains why a
  15-second failed bind loop can prevent a clean drain:
  [Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).

## Frozen decisions

1. Do not inspect, copy, restore, generate, or modify any credential or
   `authorized_keys` content. The repository and runtime evidence remain
   value-free.
2. Retain the existing `tunnel` and `tunnel2` aliases, fixed listener ports,
   dedicated identity paths, restricted server authorization, and separate
   upstream routes.
3. Add one independent current-user launchd watchdog per Mac. It runs locally,
   so simultaneous loss of both inbound routes does not strand recovery.
4. The watchdog shares an atomic private lock with controller-requested kicks.
   It changes only the two transaction-owned launchd services after validating
   checkout, transaction, plist hashes, identity metadata, SSH contracts, and
   exclusive process ownership.
5. A confirmed single-route failure enters bounded drain recovery for only the
   failed job while its healthy sibling remains untouched. A confirmed dual
   failure applies the same state machine to both exact jobs. In either case,
   wait and perform real value-free forward-bind probes, then bootstrap and
   stabilize each route as soon as its listener becomes free.
6. Never kill an sshd or arbitrary SSH process, edit sshd policy, weaken
   authorization restrictions, add a third identity, or depend on the owner's
   Codex clients.
7. Roll out Aist first, one reversible transaction at a time. Proceed to Home,
   Office, and Riken only after Aist passes matched single-route and dual-route
   drills.
8. Keep the existing five-minute recovering Local monitor. During the nightly
   work, add a separate 30-second observe-only monitor so measurement cannot
   race recovery.
9. Make the recovering monitor verify fresh dedicated authentication through
   a healthy route and classify authorization drift as `at-risk`. Detection is
   value-free and non-mutating; credential repair remains outside agent
   authority.
10. Retain one atomic, mode-0600 last-run receipt in the private watchdog state
    directory. Record only a fixed outcome/classification, attempt count, and
    UTC completion time; never retain raw SSH or supervisor output. This makes
    a watchdog recovery distinguishable from concurrent human or agent action.

The live soak proved that established connections can outlive removal of their
server authorizations: Aist remained `2/2` fresh-auth ready, while Home, Office,
and Riken were `0/2` despite several live old routes. Software recovery cannot
repair that credential state. The preferred owner-managed hardening is a
separate sshd `AuthorizedKeysFile` containing only the four Macs' restricted
tunnel entries, isolated from ordinary account-key maintenance. That one-time
server change requires owner/admin review and credential handling and is not
part of autonomous execution.

## Watchdog state machine

1. Acquire a current-user-owned mode-0700 atomic lock or report `busy`.
2. Revalidate the public checkout, private Mac profile, current supervisor
   transaction, both plist hashes and active markers, dedicated identity
   metadata, exactly one remote forward per alias, and zero external tunnel
   processes.
3. Sample both launchd services twice. If both are stably running, take no
   action. Classify each stopped route independently and preserve every healthy
   sibling.
4. For each loaded, stopped route with zero managed/external processes and a
   passing dedicated authentication probe, boot out only its exact label.
5. Poll real forward-bind probes for both aliases on a bounded schedule. A
   successful short probe must exit cleanly; bootstrap that alias only after
   its probe releases. Require one managed process, no external process, and a
   stabilization interval before declaring the route restored. If a bind probe
   fails, recheck authentication without the forward: continue draining only
   when authentication still succeeds, otherwise restore the baseline and
   classify authorization drift immediately.
6. Continue independently for the other alias. On timeout or ambiguity,
   restore the exact launchd baseline where safe, emit only value-free state,
   and retry on the next scheduled watchdog invocation. Enforce the timeout by
   elapsed wall time rather than retry count so SSH connection timeouts cannot
   silently extend the recovery bound. Never broaden scope.
7. The Local monitor supplies independent end-to-end inbound validation and
   recovery latency. The Mac watchdog never claims route reachability solely
   from process existence.
8. Atomically replace the private last-run receipt after every invocation and
   exact-unlink it during transaction rollback. A malformed or unexpectedly
   typed receipt fails closed.

## Execution order

1. Preserve a clean Git baseline and start the 30-second observe-only night
   watch.
2. Add focused synthetic tests for healthy, single-dead, ambiguous ownership,
   authentication failure, dual-dead drain, staggered listener release,
   timeout, lock contention, interrupted recovery, private run receipts, exact
   rollback, and output privacy.
3. Implement the public watchdog command and transactional launchd lifecycle;
   add lock coordination to the existing kick path and route controller
   recovery through the bounded state machine.
4. Run `git diff --check`, all focused suites, and `tests/test-phase1.sh`.
5. Publish through protected `main`, guarded-sync clean managed checkouts, and
   install the watchdog on Aist without disturbing the existing two tunnels.
6. Run controlled Aist primary, secondary, and simultaneous-loss drills. Stop
   and roll back the watchdog transaction if any ownership, authentication,
   unrelated-config, or recovery invariant fails.
7. Install and drill Home, Office, and Riken one at a time. Verify all eight
   inbound routes after each host.
8. Observe repeated 30-second samples for the remaining nightly window,
   compare any outage/recovery events, remove only reviewed temporary probe
   state, and publish a durable audit and TODO handoff.

## Acceptance

- Synthetic and full repository validation pass, followed by protected merge
  and clean fleet synchronization.
- Every Mac has exactly two existing tunnel services plus one transaction-
  owned watchdog; all files and state have exact owner/type/mode validation and
  rollback.
- Primary-only, secondary-only, and simultaneous-loss drills recover without
  owner action on Aist and then on each peer, with measured recovery times and
  no credential or SSH configuration change.
- End state is eight independently reachable routes, `managed=1 external=0`
  for every tunnel, watchdog healthy on all four Macs, and no unexplained
  working-tree or temporary-state residue.
- The audit distinguishes demonstrated recoverable failures from unavoidable
  power, network, upstream-provider, and controller-service bounds.
