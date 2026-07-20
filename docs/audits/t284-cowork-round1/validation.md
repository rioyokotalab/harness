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

Pending after a clean checkpoint: full `tests/test-phase1.sh`, reverse-role
Claude-driver/Codex-co-pilot audit, and any matched worker-count samples frozen
by that round.

## Outcome

Round-1 implementation passes all incremental gates and is ready for a clean
checkpoint plus full regression. The session remains at `validating`; it is not
yet complete.

## Residual risks

Stage-schema 3 remains fail-closed but stage plus external seal is still a
two-file, non-cross-file-atomic creation. Status observes bytes and PID
reachability only. Same-UID replacement before a prompt descriptor opens is
outside its guarantee, as with the external seal. CI wall-time savings require
a real protected run; local removal only proves coverage topology. Eight-worker
default remains unresolved and unchanged.
