# Charter

## Task

Adversarially compare the v3 direct-session co-pilot mapping with a symmetric
staged file exchange that gives the co-pilot no explicit live-session path or
write grant. Determine whether a deterministic stage/import protocol can reduce
authority while preserving blinded independent evidence, reciprocal critique,
takeover, and interruption recovery.

## Boundaries

Codex is driver and Claude is co-pilot. Both may experiment only in their
no-hardlink `/tmp/harness-t283-round3-{codex,claude}` clones and synthetic stage
directories. Claude receives copied inputs and writes a candidate evidence file
inside its sandbox; it is not told or granted the live exchange path. The Codex
driver alone may import candidate bytes into this session and later edit the
live target after reconciliation. No credentials, settings, packages, remotes,
network services beyond the required native model call, or external messages
are in scope. No raw recursive cleanup is permitted.

## Baseline and sandboxes

Both clones are detached at
`eb36df22821a85cfb3624efb1136c14e528d4857`. This session is a Codex-driver
successor of the completed Claude-driver round 2, recorded by
`init --predecessor`. The live target is the task branch in `~/harness` and is
clean apart from this declared round-3 exchange directory. Driver-held seals,
candidate outputs, and native stdout remain outside the live session until an
explicit validated import.

## Acceptance

Both agents must run concrete local tests and criticize the strongest opposing
claim. Evidence must establish whether staged exchange prevents accidental
session mutation, how candidate provenance and tamper/recovery work, and whether
both client mappings remain usable without `--add-dir SESSION_DIR`. Any frozen
implementation must have deterministic failure-atomic stage/import tests and
pass the canonical skill validator, focused cowork, Claude takeover, source,
public-audit, diff, and full phase-1 gates.
