# Validation

## Checks

Run by the Claude driver on the live target after the frozen edits:

- Canonical skill validator: `cowork-session check docs/audits/t283-cowork-round4`
  reports a valid session at each advanced phase.
- Expanded cowork focused test: `sh tests/test-codex-claude-cowork-skill.sh`
  passes, including the new round-4 block (path-free predecessor staging,
  projected round-trip import with unchanged protected entries, fail-closed
  unknown top-level and predecessor fields with no partial stage,
  withheld-field-only change accepted by projected import but detected by the
  external seal, retained-field stale refusal with unchanged destination, and
  `init --predecessor` reject-inconsistent-atomically plus accept-valid).
- `sh tests/test-claude-takeover.sh`, `sh tests/test-source-contract.sh`, and
  `sh tests/test-public-repo-audit.sh` all pass.
- `git diff --check` reports no whitespace errors.
- Live helper reproduces the T1–T10 behaviors on throwaway sessions.

## Outcome

Validation passed for the driver-scoped gates. Modified tracked files are the
frozen skill surfaces only: `shared/skills/codex-claude-cowork/SKILL.md`,
`references/protocol.md`, `scripts/cowork-session`, and
`tests/test-codex-claude-cowork-skill.sh`; the sole untracked path is this
round-4 exchange directory. No settings, credentials, packages, remotes, or
external systems were touched, and only the Claude driver edited the target. The
The supervising Codex reviewer checkpointed the reviewed diff at `4eac82a` and
ran clean-checkout `tests/test-phase1.sh`; every runnable suite passed, including
the expanded cowork suite and guarded-delete integration. Native MPI was
correctly skipped outside a declared MPI environment. The session then advanced
to `complete` and passes `cowork-session check`.

## Residual risks

Whitelist-fail-closed staging imposes a real forward-compatibility cost: a
legitimate additive `state.json` field cannot stage until `project_stage_state`
classifies it and these tests are updated; this is intentional and tied to
`schema_version`. Projected import defines freshness as equality of the
projected co-pilot-visible state, so it does not detect a change confined to a
withheld field (e.g. `predecessor.path`) or a representation-only
reserialization; the out-of-session `digests` seal over full raw `state.json`
plus a recoverable preimage remains the control, and detects rather than
prevents or restores. The predecessor content check asserts present protocol
completeness, not historical authorship or a transactional multi-file snapshot;
a same-user TOCTOU window between load/validate/hash is unchanged and not
broadened. All round-4 sandboxes, stages, and seals remain for guarded cleanup
until this evidence is committed.
After validation, both retained stage candidates lost only their final newline;
the imported live bytes stayed intact and the before/after protected seals
stayed equal. The independent import is recoverable from the reciprocal stage's
manifest-pinned input, while the final reciprocal import is pinned only by the
recorded importer hash and current live evidence. A subsequent round should test
a driver-held import receipt rather than silently assuming the stage remains an
immutable recovery source.
