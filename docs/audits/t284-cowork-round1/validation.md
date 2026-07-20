# Validation

## Checks

Helper AST parse and CLI help passed. Canonical skill quick validation passed.
Expanded `tests/test-codex-claude-cowork-skill.sh` passed in 11.56s;
`tests/test-claude-takeover.sh` passed in 0.50s; source contract passed in
0.35s; public-repository audit passed in 0.36s; focused-runner regression
passed; PyYAML parsed the edited CI workflow; and `git diff --check` passed.
Static tracing reconfirmed that every removed standalone CI assertion remains in
the phase-one script/manifest. The final helper also produced a valid read-only
snapshot of the retained stage-schema-2 reciprocal exchange.

After clean checkpoint `c1c322b`, `HARNESS_TEST_JOBS=4 tests/test-phase1.sh`
passed every runnable suite in 118.16s with only the declared native-MPI skip.
The run was slower than the initial 88.18s baseline because fleet-sync alone
took 41.515s, demonstrating substantial suite/runtime variance and reinforcing
the decision not to infer a default-worker change from one sample. Reverse-role
Claude-driver/Codex-co-pilot audit and matched worker-count samples remain for
the supervising T-284 task, not for round-1 completion.

## Outcome

Round-1 implementation passes every frozen incremental and full regression
gate. Both receipts validate and the session is ready to advance complete.

## Residual risks

Stage-schema 3 remains fail-closed but stage plus external seal is still a
two-file, non-cross-file-atomic creation. Status observes bytes and PID
reachability only. Same-UID replacement before a prompt descriptor opens is
outside its guarantee, as with the external seal. CI wall-time savings require
a real protected run; local removal only proves coverage topology. Eight-worker
default remains unresolved and unchanged.
