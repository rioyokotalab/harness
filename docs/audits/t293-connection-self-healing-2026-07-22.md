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

## Current checkpoint

No live Mac launcher, process, SSH configuration, credential, or system state
has been changed by this run. The public implementation is local on
`task/t-293-self-healing`; focused supervisor, monitor, source-contract, shell
syntax, ShellCheck, and diff checks pass. The first full phase-one invocation
passed 59 focused suites but the existing tmux fixture rejected the deliberately
uncommitted task checkout; it made no target mutation and is safe to retry from
the required clean commit. The clean-commit retry passed every phase-one suite;
native MPI remained the declared environment-only skip. A subsequent
post-amend rerun briefly raced Git's automatic background packing while an
existing Bash fixture copied `.git/objects`; only that fixture failed, full
`git fsck` passed, packing became idle, and the unchanged safe retry passed.
Next: publish through
protected `main`, synchronize clean
managed checkouts, then run Aist's new read-only supervisor plan. Its expected
safe result is an unattended-authentication refusal unless external credential
state changes first.
