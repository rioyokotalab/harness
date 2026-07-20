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

Validation passed. Commit `8c53888` made the reviewed v4 implementation and
round-3 evidence a clean checkpoint; `tests/test-phase1.sh` then passed every
runnable suite, including the expanded cowork suite, guarded-delete, and the
umbrella gate. The native MPI smoke test was correctly skipped because this was
not a declared MPI environment. The completed session passes `cowork-session
check`.

## Residual risks

Staging reduces normal authority but is not an OS boundary for unwrapped Claude
Bash; the protocol therefore retains a driver-held digest plus recoverable
preimage and explicitly records the product difference. Hashes and staged
copies prove byte equality/freshness, not model authorship or driver honesty.
The next round should test the reverse staged direction and whether copying raw
`state.json` discloses predecessor paths that are unnecessary to co-pilot work.
