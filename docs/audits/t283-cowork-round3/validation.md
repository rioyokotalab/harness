# Validation

## Checks

The canonical skill validator, expanded cowork focused test, Claude takeover,
source contract, public-repository audit, and `git diff --check` pass. The
focused suite includes both stage modes, deterministic path-free manifests,
mode enforcement, blinded round-trip import, protected-byte preservation,
stale/tampered input refusal, session-contained stage refusal, symlink/hardlink,
missing/out-of-order headings, standalone TODO, oversized/non-UTF-8 candidate,
unexpected stage content, exact live-evidence preservation after every refusal,
and both staged native mapping strings.

## Outcome

Validation is in progress. The reviewed v4 implementation and round-3 evidence
must be checkpointed before the full `tests/test-phase1.sh` run because the tmux
focused path intentionally requires a clean committed checkout. No individual
acceptance gate currently fails.

## Residual risks

The full clean-commit suite remains. Staging reduces normal authority but is not
an OS boundary for unwrapped Claude Bash; the protocol therefore retains a
driver-held digest plus recoverable preimage and explicitly records the product
difference. Hashes and staged copies prove byte equality/freshness, not model
authorship or driver honesty.
