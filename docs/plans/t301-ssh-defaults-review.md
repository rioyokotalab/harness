# T-301 canonical SSH-defaults review

## Outcome and boundaries

Review the shared `Host *` policy, freeze the owner's preferences, then make
one transactional public-source change and converge the installed fragment on
Local and all eleven managed remote checkouts. The desired result is secure,
predictable interactive SSH with bounded connection setup and idle-master
lifetime, while preserving intentional X11, agent, tunnel, and host-key
behavior.

Planning and interviewing are read-only except for this ledger. Execution must
not inspect or change credentials, identity contents, agent contents,
`known_hosts` entries, private host contracts, server-side SSH configuration,
or running tunnel ownership. It must not terminate active interactive SSH
sessions. The Mac tunnel command-line safety options and root-owned Local
authorization policy are out of scope.

## Confirmed current state

- `config/ssh/harness.conf` is the canonical source. Local's installed
  `~/.ssh/config.d/harness.conf` is a current-user-owned, real, mode-0600 copy
  with identical bytes.
- The current `Host *` block sets `AddKeysToAgent yes`, `ForwardAgent yes`,
  trusted X11 globally, `ServerAliveInterval 15`, opportunistic multiplexing,
  the human-readable `%r@%h-%p` socket path, and indefinite
  `ControlPersist yes`. The final commented `XauthLocation` line has no effect.
- The earlier startup-normalization contract deliberately places
  `ForwardAgent yes` in only Local's `ab`, `ab2`, `al`, `rc`, `ri`, and `t4`
  root stanzas and explicitly rejects it under `Host *`. The shared global
  `yes` currently defeats that boundary for GitHub, tunnel aliases, Mac routes,
  `web`, `login`, `abq`, unknown hosts, and every client on every managed node.
- The installed OpenSSH 9.6 manual warns that a privileged remote user can use
  a forwarded agent to authenticate with identities in that agent. It also
  warns that trusted X11 can permit keystroke monitoring and states that a
  multiplexed connection reuses the display and agent belonging to its master.
- `ControlPersist yes` means an idle master remains indefinitely. The
  value-free inventory found 16 mux sockets on Local, two on `ab`, one each on
  Office and Riken, and none elsewhere; it found no non-socket `cm-*` residue.
- `%C` expands correctly on every managed OpenSSH version (8.7 through 10.2)
  and incorporates local host, target, port, remote user, and jump route in a
  fixed-length hash. It avoids path-length and alternate-route collisions.
- Effective `HashKnownHosts` is currently `yes` only on Local and `ri`, and
  `no` elsewhere because system defaults differ. Every node currently resolves
  `ServerAliveCountMax 3`, `UpdateHostKeys yes`, `ConnectTimeout none`, and
  `ConnectionAttempts 1`.
- Xauth resolves correctly without the commented override: `/usr/bin/xauth`
  on Linux and `/opt/X11/bin/xauth` on all four Macs.
- The owner previously chose globally trusted X11 with explicit `no` for
  GitHub, `tunnel`, `tunnel2`, all eight Mac route aliases, and `web`. That is a
  settled historical choice but is reopened here because this request is an
  explicit security/defaults review.
- Live fragments on `t4`, `abq`, and all four Macs match the canonical source.
  `ab`, `ab2`, `ri`, `al`, and `rc` still have the preceding 23-line revision:
  their `Host *` defaults are identical, but they isolate `login login2`
  instead of `tunnel tunnel2` and lack the current X11 exception groups. This
  drift predates T-301 and must be converged during the eventual rollout.

## Recommended target

The current target, subject to the remaining decision register, is:

1. Retain `ForwardAgent yes` under `Host *`. The owner intentionally wants
   future Linux aliases to inherit agent forwarding without another policy
   change and accepts that the wildcard also enables it for every alias that
   does not override the setting. The existing six Local root-stanza entries
   become redundant but remain outside this shared-default change unless a
   focused cleanup is proven safe.
2. Retain global `ForwardX11 yes` and `ForwardX11Trusted yes` with the current
   explicit `no` exceptions for GitHub, `tunnel`, `tunnel2`, all eight Mac
   route aliases, and `web`. The owner wants future Linux aliases to inherit
   working trusted X11 without another policy edit and accepts the wildcard
   display-access scope.
3. Retain `AddKeysToAgent yes`. The owner prefers the current low-intervention
   behavior and accepts the agent's default, usually indefinite, lifetime for
   keys that SSH automatically loads from identity files.
4. Keep `ControlMaster auto` and change `ControlPath` to `~/.ssh/cm-%C`.
   Retain `ControlPersist yes`; the owner prefers indefinite background masters
   over the proposed 10-minute or non-persistent alternatives. Gracefully issue
   `ssh -S OLD_PATH -O stop` only to validated old-policy master sockets during
   the path transition; this stops new multiplex requests without terminating
   existing multiplexed sessions. New masters use collision-resistant `%C`
   paths and persist indefinitely.
5. Add `ConnectTimeout 30`, `ServerAliveCountMax 3`, `HashKnownHosts yes`, and
   `UpdateHostKeys yes` explicitly. The first bounds interactive connection
   setup; the remaining lines make the already intended liveness, privacy, and
   authenticated host-key-update behavior independent of OS defaults. Do not
   rewrite existing `known_hosts` entries.
6. Remove the inert commented `XauthLocation` line; platform defaults are
   already correct on every node.
7. Sort the directives within each managed stanza alphabetically. Preserve the
   required stanza ordering because OpenSSH uses the first obtained value.

The refrozen default block is therefore:

```sshconfig
Host *
	AddKeysToAgent yes
	ConnectTimeout 30
	ControlMaster auto
	ControlPath ~/.ssh/cm-%C
	ControlPersist yes
	ForwardAgent yes
	ForwardX11 yes
	ForwardX11Trusted yes
	HashKnownHosts yes
	ServerAliveCountMax 3
	ServerAliveInterval 15
	UpdateHostKeys yes
```

## Decision register

| ID | Decision | Recommended choice | Alternatives and consequence | State |
| --- | --- | --- | --- | --- |
| D1 | Agent-forwarding scope | Owner selected current global `yes` so future Linux nodes inherit forwarding; wildcard exposure and the startup-policy inconsistency are knowingly retained | Scoped six-host forwarding or disabling everywhere were rejected because new Linux aliases should work without another policy edit | **selected: global `yes`** |
| D2 | X11 scope and trust | Owner selected current global trusted policy with the existing GitHub/tunnel/Mac-route/web exclusions so future Linux aliases inherit working X11 | Scoped trusted X11 was rejected because each new Linux alias would require a policy edit; untrusted X11 may break HPC GUI tools and expires after 20 minutes | **selected: global trusted X11** |
| D3 | Automatic key addition | Owner selected current `yes`, retaining the agent's default lifetime for automatically added keys | An eight-hour lifetime, manual loading, and per-use confirmation were rejected in favor of minimum intervention | **selected: `yes`** |
| D4 | Multiplex policy | Owner selected `ControlMaster auto`, `ControlPath ~/.ssh/cm-%C`, `ControlPersist yes`, and graceful old-master drain with `-O stop` | Ten-minute persistence was withdrawn; explicit/default `no` was rejected because the owner prefers indefinite reuse | **selected: `%C`, indefinite** |
| D6 | Directive ordering | Sort directives alphabetically within every managed stanza while preserving stanza order | No semantic change; makes review and future additions predictable | **selected: alphabetical** |
| D5 | Deterministic fail-fast/privacy defaults | Owner selected the full bundle with global `ConnectTimeout 30`; matched live probes showed that 30 seconds accommodates the approved nested ABQ routes while remaining bounded | Keep 15 and accept repeated nested-route failures, use private host exceptions, or remove the timeout were rejected | **selected: global `30`** |

The decision audit found no unresolved choices or contradictions. D1–D3 and D4
retain the owner's low-intervention defaults while `%C` removes readable,
route-ambiguous socket naming. D5 makes connection and host-key behavior
explicit, and D6 requires alphabetical directives. Existing host-specific X11
exclusions, tunnel isolation, six redundant Local agent-forwarding lines, and
existing `known_hosts` bytes remain unchanged.

## Frozen execution sequence after interview and explicit go

1. Reconstruct `main`, TODO, this plan, live fragment identity, fragment drift,
   route health, and all selected decisions. Stop on new drift or ambiguity.
2. Create a task branch. Update `config/ssh/harness.conf`, its structural
   expectations, focused tests, and `docs/ssh-config-sync.md`. Add exact
   `ssh -G` assertions for affected and unaffected aliases on Linux and macOS
   fixture layouts.
3. Run `git diff --check`, `tests/test-ssh-config-layout.sh`, relevant Mac SSH
   tests, and `tests/test-phase1.sh` from a clean checkpoint. Inspect the diff
   independently.
4. Fetch again, publish through a protected pull request, wait for CI, merge
   without force, and guarded-sync the exact protected-main revision to all
   eleven clean managed checkouts.
5. Before changing a live fragment, inventory its exact state and old-policy
   mux sockets without reading agent or key contents. Run
   `harness ssh-config-layout --host LOGICAL_ID --plan` separately on Local,
   the seven remote Linux accounts, and four Macs. Stop if any plan is
   ambiguous or touches private host bytes beyond the declared layout.
6. Apply one node at a time, retain its transaction ID, and verify the selected
   effective defaults plus the host-specific exceptions with `ssh -G` before
   proceeding. On failure, rollback that node's exact transaction and stop.
7. If D4 selects a new path, validate each old socket as a current-user-owned
   Unix socket and send only `-O stop`; never use `-O exit`, unlink a live
   socket, or terminate an SSH process. Confirm new connections select `%C` and
   that existing sessions remain usable.
8. After each Mac, validate both fresh inbound routes, both managed launchd
   tunnel services, watchdog health, and `managed=1 external=0`. After each
   Linux host, validate a fresh non-multiplexed inbound probe.
9. Run final fleet-wide `ssh -G` assertions, public/live byte comparisons,
   focused tests, connection monitoring, repository cleanliness checks, and a
   compact health snapshot. Close T-301 only when all nodes pass.

## Failure, rollback, and interruption policy

- Each live layout apply is an atomic transaction with exact preimages. A
  failed node is rolled back before stopping; already validated nodes remain
  documented and safe to resume.
- Publication precedes live rollout so every target has the rollback-capable
  implementation. Repository rollback, if required, is a normal reviewed
  follow-up change rather than history rewriting.
- `-O stop` is deliberately non-destructive to active multiplexed sessions.
  If socket identity or ownership is ambiguous, leave it untouched and record
  it for later review.
- Do not convert or remove existing known-host entries, inspect agent contents,
  restart tunnels, or reload active shells. New client processes acquire the
  new defaults; existing transport processes retain their starting policy.
- Checkpoint every interview answer, published commit, node transaction, and
  validation result in `TODO.md`. Resume from the first unverified node.

## Acceptance gates

- The canonical and every installed shared fragment are byte-identical,
  current-user-owned real files with their required safe mode.
- Each decision has an exact `ssh -G` assertion on representative ordinary,
  HPC, GitHub, tunnel, Mac-route, web, and unknown aliases.
- No private SSH host stanza, credential surface, `known_hosts` entry, agent,
  server policy, or active session was changed outside the frozen plan.
- Full phase-one and protected CI pass; Local and all eleven remote checkouts
  are clean/current; all managed Linux probes and every Mac route pair are
  healthy.

The owner gave explicit `go`. Execution started from clean/current public main
`f654a374311ca2bb62c65c4b4aa5b514eebdc547`; only this plan and its T-301 TODO
checkpoint were uncommitted. On `t301-ssh-defaults`, the canonical fragment,
operator documentation, and focused layout test now implement the frozen
policy; the test requires alphabetic directives and verifies every new
effective default including the 40-hex `%C` expansion. `git diff --check`,
layout, Mac SSH sync, Mac plan/doctor, and SSH mirror tests pass. No live SSH
file has changed. Next action: checkpoint the implementation, run full phase-one
validation from a clean commit, then publish before any live rollout.

Implementation checkpoint `c368b60` passed the complete phase-one suite from a
clean checkout, including startup normalization, layout, mirror, Mac profile,
Mac SSH sync, supervisor, doctor, and fleet-sync coverage. Next action: publish
through protected CI and synchronize the exact merged revision; live SSH files
remain unchanged until that succeeds.

PR #274's first protected run `29975574360` failed in an unchanged watchdog
signal-cleanup timing test: after waiting five seconds it still observed a
recovery child or lock. Every T-301 layout/mirror/config test passed in that
same run. The supervisor suite immediately passed standalone locally, and the
complete local phase-one run had also passed it, so retry is safe and no live
state was touched. This task will checkpoint the failure through normal Git and
require a fresh protected run; a repeated failure would stop rollout and
require separate diagnosis rather than being dismissed.

The fresh protected run `29975671674` passed and PR #274 merged as
`5897e24896e4f75fde6f75522e75d8879c899399`; all eleven remote repositories
guarded-synced cleanly. Local transaction
`20260723T030031Z-3024814` applied and passed effective-default checks. Sixteen
validated old readable-path masters were sent `-O stop`; no process or socket
was killed or unlinked. `ab` transaction `20260723T030342Z-541548` then applied,
but the first fresh non-multiplexed `ab` probe failed with
`Connection to UNKNOWN port 65535 timed out`. Local was exactly rolled back;
after the proxied route recovered, `ab` was exactly rolled back too. No other
live fragment changed. Retry is not yet authorized by evidence: the route was
intermittent after rollback and old stopped proxy masters may still have active
clients. Next action is read-only matched route probing, followed by a revised
sequence that validates new paths before draining old masters.

Three matched rollback-state `ab` probes then passed in 3, 0, and 1 seconds.
The rollout sequence is revised to leave old masters untouched until every new
fragment and route passes. A Local retry plan was clean, but apply correctly
refused the dirty ledger checkout with
`SSH layout migration requires a clean committed checkout`; no live state
changed. Next action: preserve this checkpoint on a pushed task branch, return
to clean merged main, and retry only Local before any remote apply.

The safer ordering succeeded for Local transaction
`20260723T030937Z-3043593`: three fresh `ab` probes passed in one second each,
and old masters were not drained. Transactions then applied and validated on
`ab` (`20260723T031027Z-208556`), `ab2`
(`20260723T031050Z-211604`), `ri` (`20260723T031119Z-3416259`), `al`
(`20260723T031133Z-225268`), `rc` (`20260723T031141Z-2207960`), and `t4`
(`20260723T031143Z-2096912`). `abq` failed during proxy banner exchange before
apply emitted a transaction, so it and all four Macs remain unchanged.

This second bounded timeout reopened only D5's 15-second value. A 30-second
command-line override reached `abq` in 11 seconds, then two matched probes on
each of `abq` and `abq2` passed in 4/1 and 4/0 seconds. The recommended revision
was global `ConnectTimeout 30`: it remains fail-fast but accommodates the
approved nested routes without private per-host exceptions. The owner selected
that revision. The plan is refrozen with no unresolved decisions; execution
requires a fresh explicit `go` because D5 changed after the prior authorization.
Already validated nodes remain on the published 15-second policy and retain
exact rollback transactions.

The owner then selected global `ConnectTimeout 30` and issued a fresh `go`.
The canonical fragment, documentation, and effective-policy test were updated
in commit `afd0562`. The focused layout, mirror, macOS SSH-sync, and macOS
supervisor tests passed independently, followed by a complete local
`tests/test-phase1.sh` pass. Protected run `29976860740` failed only the
unchanged watchdog signal timing assertion in
`test-personal-macos-ssh-supervisor.sh`; every SSH-layout assertion passed.
This is the same previously observed CI-only race and is unrelated to the
three-line timeout correction. A normal ledger checkpoint push will obtain a
fresh protected run; no workflow dispatch or live rollout occurs before that
run passes.
