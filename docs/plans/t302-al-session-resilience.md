# T-302 AL session restart resilience

**Phase:** executing  
**Driver:** Codex  
**Updated:** 2026-07-24 06:47 JST

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

The owner gave explicit `go`. Initial focused fixtures failed at the intended
runner gate. The runner, restart policy, schema-2 marked-unit ownership,
replacement-socket recovery, terminal classifications, schema-1 compatibility,
and marker-collision refusal are now implemented and the focused suite passes.
A disposable native user-systemd probe independently accepted and exposed
`Restart=on-failure`, `RestartUSec=1min`,
`RestartPreventExitStatus=77 78`, and an unlimited start interval. Next run the
static, public/source, focused-shard, and complete phase-one validations, then
publish before the one owner-assisted live AL renewal and restart drill.
