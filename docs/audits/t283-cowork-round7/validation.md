# Validation

## Checks

- Live `cowork-session check` at `validating` — PASS.
- Live `cowork-session verify-receipts` — PASS; reciprocal receipt matches live
  co-pilot evidence SHA-256
  `82742111d863bdd7ad38422f22363e310bb3ba43983447104e3e2982e887df03`.
- Pre/post protected manifests and independent/reciprocal `stage.json` and seal
  hashes — exact matches; both Claude processes exited 0.
- `tests/test-codex-claude-cowork-skill.sh` — PASS.
- `tests/test-source-contract.sh` — PASS.
- `tests/test-claude-takeover.sh` — PASS.
- `tests/test-public-repo-audit.sh` — PASS.
- `git diff --check` — PASS.
- Codex, Claude, and Agents discovery links all resolve to the same canonical
  repository `shared/skills/codex-claude-cowork` directory — PASS.
- Clean full `tests/test-phase1.sh` — pending the audit checkpoint because its
  clean-checkout suite correctly rejects the current untracked session.

## Outcome

The seventh self-hosted audit supports a no-code release-candidate outcome.
Both agents independently and reciprocally agree that no helper, protocol, or
test change adds justified enforcement now. The staged seal flow works in both
driver directions, while its Claude behavioral-confinement boundary, nested
stage precondition, retained-seal comparison, and arbitrary-editor phase limit
remain explicit rather than overstated. The session is validating; scratch is
retained until the clean full gate and completion checkpoint.

## Residual risks

- Claude co-pilot permissions are not an OS filesystem sandbox. A same-UID seal
  that Claude can discover/reach is protected by placement and behavior; this
  run demonstrates compliance, not authorship or confinement.
- The stage-parent boundary is sound only for the mandated direct-child layout.
- Receipt verification cannot locate or reopen a path-free external seal after
  import; retained-byte comparison remains a separate operator audit action.
- A generic session helper cannot prevent arbitrary repository editors from
  writing before `executing`; phase ordering is validated for helper transitions
  and audited as process evidence.
- Claude left exact scratch roots under `/tmp` for guarded cleanup after final
  acceptance; no raw recursive deletion was used in round 7.
