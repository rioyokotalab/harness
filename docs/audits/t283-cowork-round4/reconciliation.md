# Reconciliation

## Evidence accepted

Both agents independently reproduced the two round-3 hypotheses on matched
sandboxes at baseline `9fed369`. (1) `cowork-session stage` copies `state.json`
verbatim; when the session was created with `init --predecessor`, the staged
`state.json` discloses the absolute `predecessor.path`
(`…/docs/audits/t283-cowork-round3` in this live session), while `stage.json`
carries only its SHA-256. (2) `init --predecessor` snapshots the predecessor's
`phase` from `state.json` but never validates that phase's required Markdown, so
it accepts a `complete` predecessor whose `charter.md` still holds template
`TODO`s, even though `check --phase complete` rejects the same directory.

Codex's reciprocal pass turned the disclosure fix from a blacklist into a
demonstrably stronger design. It executed a patched helper and showed that a
whitelist projection that fails closed on unknown keys (a) round-trips the
complete current schema with and without a predecessor in both stage modes,
retaining `phase` and timestamps for staleness detection, and (b) refuses a
future absolute-path field (`audit_path`) that a `predecessor.path`-only
blacklist would still export. The driver then reproduced the full battery
(driver-evidence/artifacts and the T1–T10 run): staged state is path-free;
projected import round-trips; unknown top-level/predecessor keys and a benign
additive field fail closed with no partial stage; a path-only live mutation is
invisible to projected import but caught by the external `digests` seal; a
retained-field mutation is stale-rejected with the destination unchanged; a
formatting-only change imports (canonicalized) but the seal detects it; and
`validate_files` in `predecessor_record` rejects an inconsistent predecessor
(before `mkdir`) while still accepting a genuinely completed one.

## Disagreements and uncertainty

Two positions changed under evidence and are preserved here. The driver's
independent evidence overclaimed that both staged `state.json` and `stage.json`
carry the absolute path; Codex refuted this by direct inspection — only staged
`state.json` does — and the driver accepts the correction. The driver's initial
minimal fix (drop only `predecessor.path`, a blacklist) was superseded by
Codex's whitelist-fail-closed after Codex reproduced the blacklist's future-key
leak; the driver accepts the whitelist as the frozen design.

Remaining, deliberately conservative points: (a) whitelist-fail-closed imposes a
real forward-compatibility cost — a legitimate additive state field cannot stage
until the projection classifies it and tests are updated; this is accepted and
documented, tied to `schema_version`. (b) Projected import defines freshness as
equality of the co-pilot-visible projected state, so it no longer detects
changes confined to withheld fields or representation-only reserialization; the
out-of-session `digests` seal over full raw `state.json` plus a recoverable
preimage remains the control for those, and detects rather than prevents or
restores. (c) The provenance fix validates present protocol completeness, not
historical authorship or a transactional multi-file snapshot; a same-user
TOCTOU window between load/validate/hash is unchanged and not broadened. No
unresolved disagreement blocks execution.

## Frozen plan

Claude is the sole live-target writer. The owner's round-4 instruction is the go
for exactly these edits to the cowork skill surfaces; a new material choice
returns to owner review.

1. Add `project_stage_state(raw) -> bytes` to `scripts/cowork-session`: parse
   `state.json`; require exactly the schema-1 top-level keys
   (`schema_version, driver, copilot, phase, created_at, updated_at`) plus an
   optional `predecessor`; if present require exactly
   `driver, path, phase, state_sha256`; emit all retained fields except
   `predecessor.path`; `fail(...)` on any unknown or missing key; serialize with
   the canonical `json.dumps(indent=2, sort_keys=True)+"\n"`.
2. In `stage_session`, compute the projection from live `state.json` **before**
   resolving/creating the stage directory, so a fail-closed refusal leaves no
   partial stage; write the projected bytes as the staged `state.json` and hash
   those bytes into `stage.json`.
3. In `import_copilot`, project the live `state.json` with the same function
   before the equality/digest comparison, preserving projected-semantic
   freshness binding.
4. In `predecessor_record`, call `validate_files(pred_root, pred_state["phase"])`
   immediately after `load_state`, before any successor directory is created.
5. Update `references/protocol.md` and `SKILL.md`: describe the staged
   `state.json` as a fail-closed path-free projection tied to `schema_version`;
   state that import freshness is projected-semantic (withheld fields and
   representation-only changes are outside import and covered by the external
   `digests` seal plus recoverable preimage); note that `init --predecessor` now
   validates the predecessor's phase-required content.
6. Add focused adversarial tests to the cowork focused test covering T1–T10:
   path-free predecessor stage, no-predecessor and reciprocal round trips,
   fail-closed unknown top-level/predecessor/benign-additive keys with no
   partial stage, path-only mutation (import passes, digests detects),
   retained-field stale refusal with unchanged destination, formatting-only
   canonicalization, and predecessor validate_files accept/reject/atomicity.
   Do not weaken existing stage/import, hard-link, takeover, state, or mapping
   assertions.

Rejected changes and why: the `predecessor.path`-only blacklist (Codex
reproduced a future-key leak); a silent whitelist that discards unknown keys
(would blind staleness comparison); adding a second full-state commitment inside
the stage (an unsalted full-state hash permits guessing low-entropy paths and
needs an explicit confidentiality decision — out of scope); removing the
predecessor block entirely or hashing whole predecessor sessions (broader than
the confirmed defect); and any claim of cross-file transactional provenance.

## Acceptance gates

The canonical quick validator, expanded cowork focused test, Claude takeover,
source contract, public-repository audit, and `git diff --check` must pass under
the driver in this round. Every stage/import refusal must leave live bytes
unchanged, and the frozen implementation must reproduce T1–T10. The
clean-checkout full `tests/test-phase1.sh` and advance to `complete` are left to
the supervising Codex reviewer. Final review must show no settings, credentials,
packages, remotes, external systems, or non-driver target changes. All round-4
scratch, stages, and seals remain for guarded cleanup until evidence is
committed.
