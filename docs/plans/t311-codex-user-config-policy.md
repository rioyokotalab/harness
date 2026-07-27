# T-311 Codex product-owned user configuration

## Status and decision

- Phase: validating.
- Owner decision: permit Codex's supported user configuration layer while
  keeping Harness behavior, permissions, rules, instructions, and skills
  project-scoped.
- Decision ID: D-007.
- Working branch: `codex/t311-product-owned-user-config`.
- Working checkout: `/tmp/harness-t311-user-config/repo`.

The accepted user-layer states are deliberately value-free:

1. `~/.codex/config.toml` is absent; or
2. it is a mode-0600, current-user-owned, single-link regular file.

Harness does not own, parse, copy, hash, back up, delete, restore, or rewrite
that file. Symlinks, hard links, broader modes, wrong ownership, and
non-regular paths fail closed.

## Confirmed state

Value-free metadata probes on 2026-07-27 found safe mode-0600 regular files on
Local, T4, Aist, Home, Office, and Riken. AB, AB2, RI, AL, RC, and ABQ had no
file. No configuration bytes or credential values were read.

The schema-2 `agent-config` engine is the source of the remaining false
collision: it recognizes a narrow historical file grammar by reading the live
file, then proposes removal and records a rollback copy. That conflicts with
the new product-ownership boundary.

## Scope and non-goals

In scope:

- make `agent-config` expose `absent` or `product-owned` without reading bytes;
- preserve both accepted states during plan, apply, doctor, and rollback;
- retain project-local Codex policy validation;
- test metadata refusals and content preservation;
- update the T-304/T-311 operational and audit contracts;
- publish through protected CI and synchronize all managed checkouts.

Out of scope:

- inspecting or validating product-owned TOML contents;
- creating a user configuration on nodes where it is absent;
- changing providers, profiles, plugins, connectors, notifications, telemetry,
  authentication, sessions, histories, caches, or databases;
- stopping or reloading Codex;
- changing project `.codex/config.toml` or its reviewed public mirror.

## Execution sequence

1. Replace the `remove|codex-config` record with a value-free `preserve`
   record.
2. Classify only absent or private current-user single-link regular state as
   accepted.
3. Make apply, verification, failure recovery, and rollback leave the product
   path untouched even if Codex creates or removes it concurrently.
4. Remove the historical content parser and regular-file backup path for this
   record.
5. Add focused coverage for arbitrary opaque content, absence, private-mode
   preservation, broader-mode refusal, symlink refusal, hard-link refusal,
   apply, rollback, reapply, and doctor.
6. Run syntax, ShellCheck, focused agent configuration suites, diff hygiene,
   source contracts, and the complete phase-one suite from a clean commit.
7. Publish through protected `main`; guarded-sync all eleven remote checkouts.
8. Run value-free doctors on all twelve systems and verify that the six
   present files retain only their previously observed safe metadata.

## Risks and safety gates

- A product file must never enter a transaction backup. Static review and the
  focused preservation test are acceptance gates.
- A metadata race must fail closed or remain within the two accepted states;
  no rollback path may unlink or restore the product file.
- Existing schema-2 transaction rollback remains compatible because historical
  manifests contain only the old record kinds.
- A dirty checkout, unsafe metadata, divergent remote, failed CI, or ambiguous
  external result stops the rollout.
- Local's live supervisor-held `.nfs` placeholder remains untouched; all
  implementation and complete validation use the isolated checkout.

## Acceptance

- Both absent and safe product-owned states report doctor `status=ready`.
- Unsafe type, ownership, link count, or mode reports a blocked path without
  reading content.
- Apply/rollback/drill preserve arbitrary product bytes and metadata.
- Project Codex policy validation remains exact.
- Focused, full, and protected tests pass.
- All twelve value-free doctors pass after synchronization, with no live
  product file or active process changed.

## Validation checkpoint

Shell syntax, warning-level ShellCheck, focused agent configuration,
fleet-controller, source-contract, repository-independence, external-user
onboarding, Claude-takeover, and diff-hygiene checks pass. The focused
transaction proves opaque-byte preservation, no product backup, accepted
absence, non-recreation after product removal, and fail-closed mode, symlink,
and hard-link handling. Next: commit the exact implementation and run the
complete phase-one suite from that clean revision.
