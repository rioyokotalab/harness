# Final Mac SSH migration and housekeeping acceptance

This audit is the durable, value-minimized execution record for T-288 through
T-292. It intentionally excludes private SSH payload bytes and identities,
endpoints, credentials, process/network detail, and owner configuration values.

## Scope and invariants

- Managed systems were local, ab, ab2, ri, al, rc, t4, Aist, Office, riken,
  and Home. Transport aliases were not treated as managed targets.
- The four Macs retained distinct non-shared SSH bytes. The migration changed
  private desired-state structure and selected state, not live SSH bytes.
- The canonical shared fragment remained the terminal include on all eleven
  systems. The private companion advanced to schema 3 with exactly four
  per-host payloads and no legacy payload.
- No credential, private payload value, package, active session, backup, or
  unknown residue was selected for change.

## Aist migration and schema finalization

After both Aist routes returned, fresh non-multiplexed probes proved one clean
host. The isolated migration plan reported `action=migrate-per-host`. A
mode-0600 comparison preimage proved the publication left live SSH bytes
unchanged.

The first wrapper parsed an obsolete transaction-output prefix and stopped
only after successful transaction `20260721T114617Z-97647`. Exact rollback was
therefore safe and passed. Ordinary reapply selected `action=pull`; transaction
`20260721T114643Z-99628` again preserved live bytes.

The four-payload gate then reported `action=finalize-per-host`. Its separate
forward-only apply removed the legacy payload, raised the minimum engine to 3,
preserved Aist's live bytes, and passed the strict private profile. Selected
agreement state was refreshed without live-byte changes on:

| Mac | Transaction |
| --- | --- |
| Aist | `20260721T114744Z-6555` |
| Office | `20260721T114802Z-42746` |
| riken | `20260721T114829Z-77750` |
| Home | `20260721T114842Z-98002` |

Final SSH acceptance proved schema 3, four per-host payloads, absent legacy
payload, `agreement=yes action=none`, current canonical layouts, ready Mac and
agent doctors, and clean/current public and private Git. All eight fresh Mac
routes passed during this acceptance.

## T-288 final housekeeping

Aist's updater/startup plans, managed non-login/login shells, both doctors, and
Git state passed. Five old unopened, current-owner regular single-link
formula-policy temporaries remained. They totaled 785 bytes and were moved
content-blind with identity checks into fresh target
`formula-policy.N5SijR`. Guarded-delete revalidated six entries and 1,009 bytes,
deleted the target, and proved protected anchors unchanged. The mode-0600
manifest was exact-unlinked and the verified-empty staging boundary removed;
final residue was zero. An initial planner call used the wrong working
directory and failed before manifest creation or deletion; retry with the
absolute harness path was safe.

Office and riken each passed clean/current public and private Git, current
updater/startup/SSH plans, managed non-login/login shells, both doctors, and
zero residue. A first acceptance wrapper supplied display-case identifiers for
Aist, Office, and Home; strict profile validation rejected those invocations
before mutation. The corrected lowercase identifiers passed.

Home reproduced the previously proven 99-byte Codex-installer profile tail and
duplicate local Codex symlink. The explicit plan again classified
`profile_local_bytes=99`, `bashrc_local_bytes=1`, and zero `.bash_common` bytes.
The duplicate link and managed executable had equal bytes and versions. Only
the current-owner duplicate link was exact-unlinked. The established
preservation transaction reapplied as `20260721T120836Z-38540`; startup, both
managed shell modes, both doctors, link absence, and zero residue then passed.

## T-290 compaction

The value-free diagnosis remains route oscillation followed by the configured
keepalive failure window, rather than authentication or local SSH-port refusal.
The unpublished raw checkpoint changed only `TODO.md` and was reachable only
from `refs/preserve/t-290-aist-forward-diagnosis`. Once fail-fast rollout and
eight-route acceptance superseded its diagnostic value, that exact ref was
deleted. No raw process or network evidence was copied into public history.

## Repository validation and publication

The focused `tests/test-personal-macos-ssh-sync.sh` and
`tests/test-ssh-config-layout.sh` suites passed. `git diff --check` and the full
`tests/test-phase1.sh` gate passed; native MPI was the declared environment-only
skip. Protected `portable-phase1` passed, and PR #185 squash-merged the
functional closeout as `b59ce7bc04f0ad4dbe8596684770c216e113b771`.
PR #186 then protected and published this durable audit as
`4d9b2ad0370bc6804233f978191b47dacdf58590`.
