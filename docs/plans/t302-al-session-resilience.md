# T-302 AL session restart resilience

**Phase:** validating
**Driver:** Codex
**Updated:** 2026-07-24 07:34 JST

## Outcome

Keep the personal AL SSH master usable across ordinary transient transport
losses without weakening CSCS MFA or automating certificate signing. Stop
retrying when authentication is required, report only value-free state, and
retain managed-only stop/ownership guarantees.

## Scope and boundaries

In scope:

- the Local-only `harness al-session` helper;
- one tracked, value-free runner for the existing transient user-systemd unit;
- restart-aware receipt ownership and status;
- focused fixtures, full phase-one regression coverage, documentation, live
  restart validation, protected publication, and guarded fleet sync.

Out of scope:

- reading, listing, copying, signing, or renewing credentials;
- bypassing CSCS MFA or extending the one-day personal certificate;
- service accounts, ACLs, shared personal state, permanent user-unit files, or
  system configuration;
- scheduler allocations, jobs, billing, or workload changes;
- changing the `al` or `alps_login` SSH configuration.

## Confirmed evidence

- The managed master entered active service at 2026-07-23 15:00:56 JST and its
  SSH process exited 255 at 22:35:32. Systemd recorded an exit-code failure.
- Certificate expiry does not terminate an established SSH session, so the
  exit was a transport/process loss, not the daily certificate boundary.
- The exact cause is unavailable because the deliberately private unit output
  was sent to null.
- The unit has `Restart=no`. No component attempted recovery while a valid
  certificate could still have authenticated a fresh connection.
- Effective AL keepalives are 15 seconds × 3 missed replies; a roughly
  45-second unresponsive interval can terminate the master.
- At 2026-07-24 06:18 JST, `alps_login` was ready, AL was absent, and a fresh
  non-interactive attempt correctly returned `renewal-required`.
- The original certificate-boundary experiment is invalidated because the
  receipt-matched master did not survive to its time gate.

## Design

1. Add a Local-only runner that launches the existing foreground
   `ssh -M -N al` command with `BatchMode=yes`, captures stderr only in a
   current-user mode-0600 temporary file, classifies the exit, exact-unlinks
   the file, and returns distinct value-free statuses:
   - success/managed stop;
   - authentication required, which must never restart;
   - availability/transport failure, which may restart under the selected
     policy;
   - permanent local safety/configuration failure, which must never restart.
2. Launch that runner in the existing transient user-systemd unit with
   `Restart=on-failure`, an explicit restart delay, and
   `RestartPreventExitStatus` for authentication and permanent failures.
3. Replace socket-inode-only receipt ownership with schema 2:
   - expected alias, control path, unit name, and a random per-unit marker;
   - the marker is stored mode 0600 and matched to the live transient unit;
   - a restarted socket is accepted only while that exact marked unit is
     active and the socket is current-user-owned, real, contained, and usable.
   Continue to recognize schema-1 receipts so rollback and pre-upgrade state
   fail safely.
4. Report `recovering` while the marked unit is between transport attempts.
   Report `renewal-required` after the runner classifies authentication
   failure. Preserve refusal to stop external or ambiguous masters.
5. Extend fixtures for transient failure → restart → new socket, authentication
   failure → no restart, permanent failure → no restart, schema migration,
   recovering status, managed stop, and unsafe/colliding unit markers.
6. Update README, T-302 evidence, source-contract tests, and rollback notes.

## Execution sequence

1. Freeze the retry decision below and wait for explicit owner `go`.
2. Set T-302 to executing; add failing focused fixtures first.
3. Implement the runner and restart-aware helper/receipt behavior.
4. Pass shell syntax, ShellCheck, focused AL tests, source/public audits,
   `git diff --check`, and complete `tests/test-phase1.sh`.
5. Publish through protected Git in small verified commits.
6. Ask the owner once to renew the normal one-day certificate if AL remains
   unavailable; never perform or inspect that renewal.
7. Run the live start and exact restart drill:
   - verify the marked unit and managed socket;
   - terminate only the identity-checked runner-owned SSH child to simulate a
     transport loss;
   - require systemd restart, a new safe socket, managed ownership, and
     `ssh al true`;
   - on failure, stop only the marked unit and restore the pre-drill absent
     state.
8. Merge after protected CI, then use guarded `harness fleet-sync` plan/apply
   on clean managed checkouts and verify no transfer residue.
9. Record the new certificate-boundary experiment from the restarted master;
   do not claim expiry-boundary success until the time gate is actually met.

## Acceptance gates

- No credential content or identity is read, listed, logged, hashed, or
  modified by Harness.
- Authentication failure causes zero further retries.
- A simulated transport failure recovers automatically with a new safe socket
  while the normal certificate is valid.
- Status and stop accept only the receipt-matched marked unit; external masters
  remain untouched.
- Private diagnostics are always mode 0600 and exact-unlinked.
- Focused and complete regression suites plus protected CI pass.
- Local and every clean managed checkout converge to the merged revision.

## Rollback

Stop only a receipt-matched managed unit, remove only its receipt after exact
validation, and revert the functional commit through protected Git. The prior
helper behavior remains available at `7965d41`: no automatic retry and
socket-inode schema-1 ownership. Never remove or replace an external master.

## Decision register

### D1 — Availability retry duration

- **Recommended:** retry classified availability failures every 60 seconds
  indefinitely; stop immediately on authentication or permanent local errors.
  This best survives long network/server outages and cannot prompt or sign.
  Tradeoff: one bounded SSH attempt per minute while the route is unavailable.
- **Bounded:** retry five times, then stop. Lower background traffic, but an
  outage longer than about five minutes again requires owner intervention even
  with a valid certificate.
- **Minimal:** retry three times over about two minutes, then stop. Smallest
  retry surface and weakest resilience.

**Selected:** retry classified availability failures every 60 seconds
indefinitely. Stop immediately on authentication or permanent local errors.
The owner selected option 1 to maximize resilience while retaining CSCS MFA
and non-interactive failure behavior.

## Next action

The owner gave explicit `go`. Commit `180d432` implements the runner, restart
policy, schema-2 marked-unit ownership, replacement-socket recovery, terminal
classifications, schema-1 compatibility, and marker-collision refusal. A
disposable native user-systemd probe independently accepted and exposed
`Restart=on-failure`, `RestartUSec=1min`,
`RestartPreventExitStatus=77 78`, and an unlimited start interval, then
unloaded without residue.

Shell syntax, warning/error-level ShellCheck, `git diff --check`, and the
focused AL suite pass. A first sequential all-shard run passed 67/68 and saw
one unrelated watchdog signal-timing failure; its immediate isolated rerun
passed. The authoritative complete `tests/test-phase1.sh` run then passed all
68 parallel focused shards, the guarded-delete gates, and every remaining
phase-one integration check. Next publish through the protected workflow,
then request the one owner-assisted AL renewal and perform the live exact
restart drill.

PR #281 passed its first protected CI run. After owner renewal, live `TERM`
drills correctly produced graceful success and no restart. The exact `KILL`
drill then proved `NRestarts=1` and a new runner process, but also exposed a
real crash edge: the killed OpenSSH process left its old Unix socket, so the
new OpenSSH process could not publish a usable control master. The bounded
drill failed and rollback was completed manually after exact receipt, unit,
socket owner, link-count, and unusable-master validation; current AL state is
absent with no receipt or socket. A new failing fixture now requires the runner
to exact-unlink only a safe, unusable socket whose schema-2 receipt marker and
control path match that runner generation. That recovery and restart-window
status handling are now implemented; the focused suite passes with matched
cleanup, mismatched-marker preservation, and stale-socket `retrying` coverage.
Managed stop now also removes only that same safe, unusable receipt-matched
socket after stopping the marked unit, so a rollback during the retry window
returns to absent state. The focused stop fixture passes. Commit the
correction, rerun the complete phase-one and protected checks, then repeat the
exact `KILL` drill.

The protected correction passed again. The next live `KILL` drill reached
`NRestarts=1`, replaced both process generations, and transitioned the stale
socket to a usable managed master. Its final cleanup gate rejected the active
session because the mode-0600 diagnostic file retained a pathname for the
lifetime of SSH; rollback returned to absent state. Add a failing fixture that
requires the runner to open private read/write descriptors and exact-unlink the
pathname before launching SSH, while retaining post-exit classification. That
anonymous-diagnostic behavior is now implemented, and all four exit classes
plus pathname absence pass the focused suite. Revalidate locally and in
protected CI before the final live drill.

Commit `2b4bc9e` passed the complete phase-one suite and protected CI. The
final live hard-crash drill passed at 2026-07-24 07:34 JST:

- only the exact receipt- and parent-validated OpenSSH child received `KILL`;
- the unusable stale-socket state was observed;
- systemd reported one restart after the configured 60-second delay;
- both the runner and SSH process generations changed;
- the socket transitioned from unusable to a safe usable managed master;
- `harness al-session --status` and `ssh al true` passed;
- no named private diagnostic path existed before or after recovery.

The recovered unit is active/running with `NRestarts=1` and entered its current
active generation at 2026-07-24 07:33:47 JST. Next commit this evidence, pass
the documentation-only protected check, merge PR #281, guarded-sync the clean
fleet checkouts, and schedule the certificate-boundary observation no earlier
than 2026-07-25 07:35 JST without replacing the master.

PR #281 merged as `0fa3949`. The merge replaced the live runner's NFS inode and
exposed a value-free platform fact: unlinking an open file under the NFS-backed
checkout or `~/.ssh` creates visible `.nfs…` placeholders. The managed session
was stopped cleanly, releasing its repository and diagnostic placeholders;
the repository is clean. Existing unrelated live `.ssh/.nfs…` placeholders
were left untouched. A new failing fixture requires diagnostic descriptors to
originate under the validated current-user runtime directory rather than the
NFS-backed SSH directory. Implement this correction on
`t302-al-session-runtime-log`, then repeat all validation and the live drill.

The Local runtime directory is current-user-owned, mode 0700, and backed by
tmpfs. The helper and runner now both require those properties, pass the exact
runtime path to the transient unit, create the mode-0600 diagnostic there, and
unlink its pathname before SSH starts. Focused fixtures prove the diagnostic
descriptor's runtime origin and all exit classifications. Next commit, run the
complete suite and protected CI, then perform one final hard-crash drill and
confirm no runner-held `.nfs…` path before merging the correction.
