# T-293 connection self-healing execution audit

This value-minimized audit is the durable execution record for T-293. It omits
private SSH values, endpoints, account names, credential material, process
identifiers, and raw configuration or command lines.

## Frozen scope and evidence standard

- Codex on `local` is the sole driver. Claude and the cowork workflow are out
  of scope.
- Git and `TODO.md` are authoritative. The owner's `go` on 2026-07-22 activated
  the frozen plan.
- Installed `launchd.plist(5)`, `launchctl(1)`, and `ssh_config(5)` on Aist are
  the primary platform references. The observed client was OpenSSH 10.2p1 on
  macOS major release 26.
- A target route may be called healthy only from a fresh external probe. A
  process or loaded service alone is insufficient evidence.

## Initial reconstruction

Protected public Git was clean at
6700baf2c5aa246b26f3e99c09d8247774781627 with no open pull request. Aist was
Darwin arm64 with a valid engine-3 private profile. Its public checkout was
clean on `main` but behind the protected revision; both its local head and
fetched `origin/main` required catch-up before any future mutation.

Aist had exactly two alias-specific SSH tunnel processes. Neither belonged to
launchd: each had a distinct retry-loop parent under tmux. There was no matching
current-user launch agent and no `autossh` process. The effective aliases each
had one remote forward, isolated multiplexing, forwarding fail-fast behavior,
one connection attempt, and a 15-second/three-count encrypted server-alive
window. They had no bounded connect timeout.

The local monitor's retained pane history contained 182 Aist samples from
2026-07-21 13:24 JST through 2026-07-22 04:57 JST: 64 dual-ready, 22 degraded,
96 dual-down, and 62 state transitions. The same observation loop continued to
report the other three Mac pairs ready. This establishes recurrent Aist route
loss, not permanent Aist host loss. It does not by itself identify the network
or sleep event that initiates each loss.

The first combined Aist classification command had a quoting defect after its
profile check and stopped with an awk/shell syntax error. It performed no
mutation; retry through a literal stdin script was safe and produced the facts
above.

## Platform conclusions

The installed `launchd.plist(5)` states that `KeepAlive=true` keeps a job
running, implies initial launch, and throttles rapid exits; its default restart
throttle is ten seconds. It also states that `NetworkState` is unimplemented
and should not be used. `launchctl(1)` defines current-user GUI-domain
`bootstrap`, `bootout`, and `kickstart -k`, the latter replacing a running
instance. `ssh_config(5)` confirms that the observed server-alive settings
terminate an unresponsive encrypted session after approximately 45 seconds,
while `ExitOnForwardFailure` covers initial forward setup but not later
connections to the forwarding destination.

Adopt: two independent current-user launch agents, one per route, with
`KeepAlive`, bounded connection attempts, isolated multiplexing, encrypted
keepalives, forwarding fail-fast, and a 15-second launchd throttle.

Adapt: activation must be staged one route at a time and must refuse a live
external predecessor. Logs go to `/dev/null`; value-free status comes from
launchd/process classification and external route probes rather than unbounded
SSH diagnostics.

Experiment: an external controller monitor may use a healthy sibling to issue
`launchctl kickstart -k` through the transaction-aware harness command. Dual
loss must be left to independent Mac-local supervision.

Reject: `NetworkState`, Codex as a production watchdog, a single shared SSH
process, direct untracked restart commands, or treating process existence as
route health.

## Authentication gate

Aist's GUI launchd domain was available, but it exported no usable
`SSH_AUTH_SOCK`. Authentication attempts for both aliases from a launchd-like
minimal environment failed with forwarding disabled, both with the default
identity behavior and with Keychain use requested. The active tmux/session
route did authenticate. The confirmed conclusion is that unattended launchd
authentication is not currently available; whether the active route depends
on a forwarded agent or another session-only facility remains an inference.

Creating, copying, loading, or authorizing a key is a credential boundary and
is not authorized by T-293's `go`. Therefore Aist mutation remains prohibited
until the owner either provisions unattended local authentication or approves
one exact credential plan. This blocker does not prevent public control-plane
implementation, fixture validation, Linux auditing, or observation.

## Implemented local control plane

- `macos-ssh-supervisor` plans and stages exact private transactions, proves
  launchd-like authentication, activates/deactivates one alias at a time,
  refuses duplicate external ownership, performs launchd-native kick recovery,
  exposes value-free status, and rolls back only unchanged inactive state.
- `connection-monitor` uses a current-user-owned SSH agent socket, fresh
  non-multiplexed probes, explicit healthy/degraded/unrecoverable states, and
  sibling-mediated supervisor recovery. Dual loss is recorded as
  `await-supervisor` rather than hidden by an unsafe fallback.
- Focused fixtures cover authentication refusal and drift, external-process
  refusal, stage-only apply, activation, kick, active rollback refusal,
  deactivation, exact rollback, destination collision, healthy/degraded/dual
  loss classification, sibling recovery, and missing-agent refusal.

## Published checkpoint

Focused supervisor, monitor, source-contract, shell syntax, ShellCheck, and
diff checks passed. The first full phase-one invocation
passed 59 focused suites but the existing tmux fixture rejected the deliberately
uncommitted task checkout; it made no target mutation and is safe to retry from
the required clean commit. The clean-commit retry passed every phase-one suite;
native MPI remained the declared environment-only skip. A subsequent
post-amend rerun briefly raced Git's automatic background packing while an
existing Bash fixture copied `.git/objects`; only that fixture failed, full
`git fsck` passed, packing became idle, and the unchanged safe retry passed.

Protected `portable-phase1` passed and PR #191 squash-merged the control plane
at 4777c7fcf2ef299a26aa08d0cf6fa478c2158e38. Guarded fleet synchronization
advanced all six clean Linux mirrors. Aist's clean public/private checkouts then
advanced through updater transaction `20260721T203627Z-61158`; package and live
SSH state were unchanged.

The published Aist supervisor plan failed closed with both aliases classified
`reason=unattended-auth`, two external predecessors, zero created managed paths,
and zero loaded managed services. Value-free probes on Office, riken, and Home
also found zero of two launchd-like authentication successes and no managed
service. Office and Home each had two alias-ending external predecessors;
riken had one despite two healthy externally observed routes, so its launcher
topology remains a later per-host classification task.

The credential precondition is fleet-wide. Agents must not create, inspect,
copy, load, or authorize credentials, so the next step requires owner-managed
provisioning. The recommended design is one dedicated unattended identity per
Mac, authorized only for that Mac's two reverse-forward aliases; after the
owner reports provisioning complete, rerun Aist plan and proceed only if both
isolated authentication checks pass. Until then the prior tmux launchers and
existing observer remain unchanged.

## Owner provisioning handoff

The supervisor now fail-closes on one fixed local identity path,
`~/.ssh/harness-reverse`. Its value-free safety check requires a regular,
non-symlink, current-user-owned, single-link mode-0600 file. Both the isolated
probe and generated launch agents set `IdentitiesOnly=yes` and select that path,
so authorization does not depend on a session agent and no private SSH config
bytes need to change. The owner requested a reviewable Aist-local helper. The
driver may place `~/run_this.sh` on Aist after this revision reaches protected
`main`, but must not execute it or inspect any key it generates. The helper
must default to a non-mutating plan, require an explicit interactive apply,
restrict the new authorization while re-enabling port forwarding, validate both
aliases using only the new identity, run the value-free supervisor plan, and
attempt exact rollback of its own additions on failure.

This design follows the upstream OpenSSH contracts: `IdentityFile` accepts
tilde paths and works with `IdentitiesOnly`, `IdentityAgent=none` disables agent
use, and the `restrict,port-forwarding` authorized-key combination retains the
forwarding capability while disabling the other restricted capabilities. See
the OpenBSD [`ssh_config(5)`](https://man.openbsd.org/ssh_config) and
[`sshd(8)`](https://man.openbsd.org/sshd) manuals.

PR #193 passed protected `portable-phase1` and merged at
`f66e26eb1a5f56bc29173805acdf45d067284875`. Aist's clean public checkout
advanced through updater transaction `20260721T205722Z-66505`; private Git and
live tunnel state were unchanged. The driver atomically placed the reviewed
mode-0700 helper at Aist `~/run_this.sh`, verified SHA-256
`8c48372f1e428057dc7507779702435d51bfd3d1c2c0cb9a9cb3c651253fda7c`, did not
execute it, and exact-unlinked the local transfer source. Final review added a
forced `/usr/bin/true` command to `restrict,port-forwarding`, preventing general
command use while retaining forwarding and the `true` authentication probe.
Credential creation and authorization remain pending the owner's local
`--apply` invocation.

At 06:08 JST, the final managed-fleet probe caught Home's primary route down
with `home2` healthy. Its existing tmux `%0` process was an `ssh login` command
that had restarted but remained stuck for more than 30 seconds. The driver used
the owner's standing single-route reconnect path, native
`tmux respawn-pane -k -t %0 'ssh login'`, through `home2`; the primary route
passed the second three-second probe. The sibling stayed ready throughout.
This bounded incident supplies live evidence of the manual launcher's hanging
failure mode and changed no Aist or credential state.

## First owner-helper attempt

The owner's `--plan` completed with every preflight ready. The first `--apply`
created and authorized the dedicated identity, but its final read-only
supervisor plan found that effective `login` had zero remote forwards and
failed the exact-one-forward contract. The helper reported a complete rollback;
subsequent metadata checks confirmed both local identity paths absent. No
managed service or supervisor transaction was created.

The owner then disclosed that they had temporarily disabled forwarding for the
first check. A value-free live/canonical diff classified exactly four changed
lines: live-commented and canonical-active `LocalForward` and `RemoteForward`
directives. Canonical `login` and `login2` each produced one remote forward.
Because ordinary `macos-ssh-sync` correctly classified the live-only edit as
`action=publish`, the driver did not apply it. Under the owner's standing SSH
config authority, the driver restored the exact canonical per-host payload in
mode-0600 transaction `20260721T212129Z-73841`, retaining its unchanged-only
backup and manifest. Both aliases then resolved to one remote forward and
authenticated with forwards cleared; `macos-ssh-sync` returned
`agreement=yes action=none`. The credential state remains absent, and retrying
the owner helper is safe.

The owner's second `~/run_this.sh --apply` completed successfully. The helper
created and authorized the dedicated identity, proved both aliases with the
agent disabled, and ran a value-free supervisor plan in which each alias was
`stage=create unattended_auth=ready external=1`; the blocked count was zero.
Independent metadata-only revalidation confirmed the identity is a regular,
non-symlink, single-link, current-user-owned mode-0600 file; its contents were
not read. Supervisor status remained `loaded=no running=no managed=0
external=1` for each alias. Thus credential provisioning is complete while
live process ownership is unchanged. The next safe mutation is stage-only
supervisor apply from current protected `main`, followed by transaction
verification before any one-route migration.

## Aist single-route pilot

PR #198 merged the credential checkpoint at
`925761ff743cd6c1c188f6716b039ea10058c293`, and Aist advanced through updater
transaction `20260721T213111Z-78719` without package or live-tunnel changes. A
combined plan/apply invocation returned no output; the driver did not infer an
outcome. Fresh checks found both routes ready, both predecessors external, and
no supervisor transaction, plist, or service, proving a no-op. A standalone
retry staged transaction `20260721T213202Z-82311` with zero services, then
passed exact inactive rollback. Current reapply transaction
`20260721T213306Z-85543` again staged two services before migration.

Through fresh `aist2`, the driver mapped tmux pane `%5` to `login`, replaced
only that predecessor, and activated the managed service. Ownership became one
managed and zero external processes while `login2` stayed externally owned.
Three native supervisor kicks restored the route in 4, 15, and 4 seconds. A
native `launchctl kill SIGTERM` then simulated unexpected process exit; launchd
restored one process and the usable route in 5 seconds without a manual kick.

With managed `aist` fresh, the driver mapped `%6` to `login2`, replaced only
that predecessor, and activated the second service. Both aliases reached
`loaded=yes running=yes managed=1 external=0`. Three `login2` kicks restored
both fresh routes in 4, 14, and 14 seconds. Its unexpected `SIGTERM` recovered
in 2 seconds. Every drill preserved the sibling route and returned exact
single-process ownership with no external duplicate. These results satisfy the
frozen precondition for a bounded dual-route drill; fleet rollout remains
prohibited until that drill and its post-state checks pass.

## Aist dual-route drill

PR #199 merged the single-route checkpoint at
`5b858a8bc6161c4053f7480eeab57457bb33f5f9`, and updater transaction
`20260721T214154Z-97235` made Aist clean/current without affecting its services.
The driver captured both managed process generations without publishing their
values, then dispatched two delayed, self-terminating native
`launchctl kill SIGTERM` actions locally on Aist. From `local`, fresh parallel
probes observed both routes ready at 1 second, both down at 3 seconds, and both
ready at 4 seconds. Both post-recovery generations differed from their
pre-drill values. Final status was `loaded=yes running=yes managed=1
external=0` for each alias, and complete validation took 6 seconds. No manual
or sibling-mediated recovery ran. This passes the bounded dual-loss gate; Aist
still requires the frozen sequential active rollback/reapply drill and a
meaningful soak before fleet rollout.

## Aist active rollback and reapply

Managed `login` deactivated correctly, but the historical tmux server had
already exited, so `%5` could not be respawned. A newly named temporary session
running plain `ssh login` produced an external process but no usable route after
its creating session ended, independently reproducing session-bound
authentication. The driver replaced only that session with the same dedicated,
agent-disabled SSH invocation as the managed service; `aist` recovered while
managed `aist2` remained ready. `login2` then deactivated and a symmetric named
dedicated predecessor restored it. Both routes were usable with zero managed
and one external process per alias.

Transaction `20260721T213306Z-85543` then rolled back exactly. Aist advanced
through updater transaction `20260721T214844Z-4393`; new supervisor transaction
`20260721T214904Z-6974` staged two inactive services. The driver removed each
named temporary predecessor only while its sibling was fresh and reactivated
`login`, then `login2`. Both reached `loaded=yes running=yes managed=1
external=0`, and one post-reapply kick per alias passed. No temporary rollback
session remains. Aist now passes inactive and active rollback/reapply, repeated
single-route restart, unexpected-exit recovery, and observed dual-route
recovery gates. It enters soak while Office, riken, and Home remain unchanged
pending owner-managed dedicated identities and per-host rollout classification.

## Remaining-Mac owner handoff

Office, riken, and Home each passed clean public/private Git, canonical
`macos-ssh-sync agreement=yes action=none`, absent identity/helper paths, and
exactly one effective remote forward per alias. They advanced to protected
`88e6c4419efabfec0dbc1f7ef1fd7d10579f64d0` through updater transactions
`20260721T215509Z-6673`, `20260721T215523Z-37906`, and
`20260721T215527Z-94774`, respectively, without package or tunnel-process
changes.

The driver added a pre-credential exact-one-forward check to the owner helper,
validated three host-pinned variants with Bash syntax and ShellCheck, and
atomically placed each mode-0700 `~/run_this.sh` without executing it. The
verified SHA-256 values are Office
`b5b8589c57525f3d043e35d921bfa43cba94071936c7a12e90c1131f2a89e197`, riken
`ac1298ca42e6213f0d0929826a630d25a3fc398629eceec9b12b1cc5bc2f7789`, and Home
`d0d10b6e43fb2d9a3cf7688e1bdacae3300ac773d2a4d22d885cd5b6390ffb6b`. All
local transfer sources were exact-unlinked. Owner execution and credential
creation remain pending independently on each Mac; no supervisor rollout may
begin on a host until its helper succeeds and the driver revalidates it.

## Office rollout

The owner completed the reviewed Office helper. Independent metadata-only
validation confirmed the dedicated identity's required type, ownership,
single-link status, and mode without reading it. Both aliases passed isolated
unattended authentication. Office advanced cleanly to protected
`ef97b55cf8170508c40eae2c52c339296eba0e12` through updater transaction
`20260721T221819Z-14095`; packages and tunnel processes were unchanged.

Supervisor transaction `20260721T221839Z-16624` staged two inactive plists and
passed exact inactive rollback. Reapply transaction
`20260721T221945Z-19326` replaced only tmux panes `%0`/PID `8694` and `%3`/PID
`8701`, one alias at a time through a fresh sibling. Each route was usable on
the first one-second observation. Each alias passed three kick generations
with observed recovery of 1, 2, and 1 seconds; independent native `SIGTERM`
recovery took 2 seconds per alias.

The first dual-route observation was rejected as inconclusive: one-second full
SSH probes alternated false negatives and never captured simultaneous loss,
although both process generations changed and fresh post-state was healthy.
The unchanged two-`SIGTERM` injection was repeated with a high-frequency local
listener probe. It observed both routes ready at 9 ms, both down at 2144 ms,
and both ready at 2462 ms. Full SSH, new generations, and exclusive managed
ownership then passed for both aliases without sibling or manual recovery.

Active rollback deactivated each service through its healthy sibling and used
only short-lived, agent-disabled temporary predecessors referencing the
dedicated identity by path. Transaction `20260721T221945Z-19326` rolled back
exactly with both external routes healthy. Fresh transaction
`20260721T223035Z-31774` staged and reactivated both aliases one at a time;
each returned in one second and passed a final generation-changing kick in one
second. Final status is `loaded=yes running=yes managed=1 external=0` for both
aliases. Public/private Git are clean/current, temporary sessions are absent,
and the hash-revalidated spent Office helper was exact-unlinked. Riken and Home
remain unchanged pending their independent owner provisioning and host-specific
classification.

## Riken rollout

The owner completed the reviewed riken helper. Independent metadata-only
validation confirmed the dedicated identity's required type, ownership,
single-link status, and mode without reading it, and both aliases passed
isolated unattended authentication. Riken advanced cleanly to protected
`860d99808f0c09f72acb3f23a223de1d2b897acb` through updater transaction
`20260721T224851Z-46598`; packages and tunnel processes were unchanged.

Supervisor transaction `20260721T224916Z-49105` staged two inactive plists and
rolled back exactly. Reapply transaction `20260721T225003Z-51286` initially
encountered a legacy topology unlike the visible process list: a PID-1-orphaned
pre-isolation SSH ControlMaster owned both effective reverse forwards, while
the visible tmux-era `ssh login` process was multiplexed through it. Exact
termination of the stale master therefore dropped both routes. Neither route
returned during ten fresh observations over 30 seconds, confirming that the
controller-side monitor cannot recover a simultaneously unreachable pair.

The owner asked a separate riken-side Codex to restore the connections. It
created two bounded retry loops: the primary established forwarding, while the
secondary used `ClearAllForwardings=yes` and could not restore its listener.
After fresh process classification, the driver removed only the secondary
child and activated managed `login2`, which held one generation with full SSH
at every two-second sample through 20 seconds. Through that proven sibling,
the driver removed only the external primary child and activated managed
`login`, which passed the same stability gate. Both aliases then reported
exclusive managed ownership.

Each alias passed three generation-changing kicks with route recovery in 1–2
seconds and one independent native `SIGTERM` recovery in 2 seconds. The
high-frequency dual-route drill observed both listeners ready at 7 ms, both
down at 2138 ms, and both ready at 2350 ms. Full SSH, changed generations, and
exclusive managed ownership passed afterward without manual or sibling
recovery.

The first active-rollback attempt exposed the still-running riken-side parent
retry loops: they respawned the external clients and interfered with temporary
predecessor ownership. The driver stopped, identified each exact Bash parent
and its sole child, removed the secondary loop before restoring managed
`login2`, then removed the primary loop through that healthy sibling and
restored managed `login`. No broad process cleanup was used.

The repeated active rollback then passed. Each service was deactivated through
its healthy sibling and replaced by a short-lived, agent-disabled temporary
predecessor referencing the dedicated identity by path. Transaction
`20260721T225003Z-51286` rolled back exactly with both external routes healthy.
Fresh transaction `20260721T231434Z-66963` staged and reactivated both aliases
one at a time; each route returned on the first one-second observation. One
final kick per alias changed its process generation and recovered in one
second.

Final status is `loaded=yes running=yes managed=1 external=0` for both aliases.
Public/private Git are clean/current, both temporary sessions and both retry
loops are absent, and the hash-revalidated spent riken helper was
exact-unlinked. Home remains unchanged pending its independent owner
provisioning and host-specific rollout.

## Home preflight

Home advanced cleanly to protected
`d83eee0a0ff63f61351c9125734b4d0401c9843c` through updater transaction
`20260721T232259Z-2338`; the private checkout remained current, and package and
tunnel processes were unchanged. Fresh validation passed clean/current
public/private Git, the reviewed mode-0700 helper at its recorded hash, absent
dedicated identity, absent supervisor state, and both external predecessors.
The supervisor plan reported exactly two blocked aliases, both solely because
the dedicated identity has not yet been owner-provisioned. Home is ready for
the same reviewed owner helper and independent post-provisioning validation
used for Office and riken.

## Home rollout

The owner completed the reviewed Home helper. Independent metadata-only
validation confirmed the dedicated identity's required type, ownership,
single-link status, and mode without reading it, and both aliases passed
isolated unattended authentication. Home advanced cleanly to protected
`47b354b70f60b62c9a14156b950718f2306c51df` through updater transaction
`20260721T232905Z-8341`; packages and tunnel processes were unchanged.

Supervisor transaction `20260721T232913Z-10344` staged two inactive plists and
rolled back exactly. Reapply transaction `20260721T232932Z-12522` staged with
zero services. Initial classification found live tmux pane `%6` directly owned
the external `login2`, while the visible `login` process belonged to a separate
interactive session and historical pane `%0` was dead. Exact termination of
only `%6` unexpectedly removed both routes before activation could run. Neither
route recovered during ten fresh observations over 20 seconds, so the driver
stopped without inferring unreachable state.

The owner asked a separate Home-side Codex to restart the connections. Fresh
inspection showed it restored direct tmux pane `%0` for `login` and pane `%8`
for `login2`, without changing the staged transaction or loading either
service. Both exact processes and both routes remained unchanged through ten
two-second observations. Through external `home2`, the driver then replaced
only `%0` with managed `login`; its route and generation held for 20 seconds.
Through that proven managed sibling, the driver replaced only `%8` with
managed `login2`, which passed the same gate. One local quoting error prevented
a combined observation but mutated nothing; the exact retry passed.

Each alias passed three confirmed generation-changing kicks with route recovery
in 1–2 seconds and one independent native `SIGTERM` recovery in 2 seconds.
One immediate PID comparison raced the third restart on each alias and was
rejected; unchanged retries with bounded generation polling passed. The
high-frequency dual-route drill then observed both listeners ready at 1 ms,
both down at 2035 ms, and both ready at 2381 ms. Full SSH, changed generations,
and exclusive managed ownership passed afterward without owner, sibling, or
controller-monitor recovery.

Active rollback replaced each managed service, one at a time through its
healthy sibling, with a short-lived agent-disabled predecessor referencing the
dedicated identity by path. Transaction `20260721T232932Z-12522` rolled back
exactly with both external routes healthy. Fresh transaction
`20260721T234337Z-26177` staged and reactivated both aliases one at a time;
each route returned in one second and passed a final generation-changing kick
in one second.

Final status is `loaded=yes running=yes managed=1 external=0` for both aliases.
Public/private Git are clean/current, both temporary sessions are absent, and
the hash-revalidated spent Home helper was exact-unlinked. All four Macs now
use the same managed current-user supervisor design and have independently
passed rollback, single-route failure, simultaneous-route failure, and
post-reapply acceptance gates.

## Final pre-publication fleet validation

The driver identity-matched the persistent `harness-connection-monitor` tmux
pane and respawned only that pane with the already protected monitor command.
The new process emits explicit `host`, `state`, and `action` fields; its first
cycles at 08:46 and 08:51 JST classified all four Mac pairs healthy with no
action. A separate current-code observer sampled every 30 seconds for 11 cycles
from 08:47:05 through 08:52:45 JST. All 44 pair observations were healthy and
none invoked recovery.

Fresh status on Aist, Office, riken, and Home reported
`loaded=yes running=yes managed=1 external=0` for both aliases. Both routes on
every Mac passed full SSH, and each public/private checkout was clean. Fresh
agent-backed connections to ab, ab2, ri, al, rc, and t4 explicitly disabled
multiplexing and control paths, retained the bounded keepalive settings, and
passed; every remote Linux checkout was clean on `main`. This validates the
direct-route design without imposing the Mac reverse-tunnel supervisor on
Linux targets or depending on any possibly stale shared control socket.

Focused supervisor, connection-monitor, public-repository audit, and diff
checks passed. The initial full phase-one run passed 58 of 59 focused suites;
only the tmux configuration fixture intentionally rejected the uncommitted
documentation checkpoint. It changed no target state. The exact clean-commit
retry then passed all 59 focused suites and guarded-delete; native MPI remained
the declared environment-only skip.

## Publication and final convergence

Protected PR #206 passed `portable-phase1` and squash-merged the Home/fleet
checkpoint at `97162ef3c554a80a29c63a4b83d39d292ad4fb14`; its task branch was
removed locally and remotely. The guarded bundle-transfer plan and apply then
advanced the six clean Linux mirrors from
`460bbca2cbac5f54f264d5e94001d77b17b2f4f5` to the protected commit. Each
remote verified the bundle, updated `origin/main`, fast-forwarded, exact-unlinked
the transfer artifact, and finished clean/current.

All four Mac updater plans reported public fast-forward and private current.
The applies completed with no package actions in transactions Aist
`20260722T000131Z-17830`, Office `20260722T000135Z-41041`, riken
`20260722T000132Z-74727`, and Home `20260722T000128Z-33115`. Final independent
acceptance proved local plus all six remote Linux checkouts clean/current with
fresh non-multiplexed routes; all four Mac public/private checkouts
clean/current; all eight Mac routes ready; and every Mac alias
`loaded=yes running=yes managed=1 external=0`.

A final current-code monitor cycle from 09:02:07 through 09:02:10 JST
classified all four pairs `state=healthy action=none`. T-293 therefore meets
its finite engineering acceptance gates: persistent native supervision,
automatic recovery for tested single- and simultaneous-route process failures,
bounded state-aware observation, duplicate exclusion, exact rollback/reapply,
clean fleet convergence, full local regression, and protected CI. This does
not claim immunity from Mac power loss, sleep policies, local network loss, or
external provider failure; those remain explicitly outside the guarantee.
