# Initial plan

## Confirmed facts and assumptions

Confirmed: version 1 is committed at `35ed1db`; the canonical quick validator
and initial focused tests pass; Codex CLI 0.144.6 and Claude Code 2.1.207 are
installed; both clones resolve to the same commit. Assumption to falsify: the
file validator enforces every behavior claimed by `protocol.md`. Assumption to
inspect: each native invocation mapping is both safe and usable in a
noninteractive cowork pass.

## Steps

1. Independently inspect the skill, reference, validator, and focused test.
2. Run the focused test and targeted adversarial sessions in the assigned
   sandbox. Probe phase skipping, extra files, symlinked protocol files, role
   reversal, and incomplete evidence without touching the live target.
3. Inspect the installed native client's current `--help` for the mapping used
   by the opposite driver direction. Do not change configuration or auth.
4. Record observed results, strongest criticism, and exact proposed edits in
   the owned evidence file without reading the other agent's evidence.
5. After both passes, read both evidence files, reproduce the strongest
   conflicting result, and append a reciprocal critique.
6. Reconcile only evidenced fixes into a frozen target-edit and validation plan.

## Evidence questions

- Does `cowork-session` reject every phase skip and unfinished required file?
- Does it reject symlinked protocol files and unexpected top-level files as the
  reference claims?
- Can both driver role initializations reach the same states under the same
  requirements?
- Do the documented Claude and Codex command options exist in the installed
  clients, and do they avoid bypass flags?
- Can file ownership and independent-result withholding be enforced or only
  instructed, and is that limitation stated accurately?

## Risks and recovery

Experiments could accidentally target the live checkout, leak private context,
or leave clone trees. Every command must resolve its working directory first;
use only synthetic/public files; stop on path mismatch. The no-hardlink clones
make source edits independent. A failed client call is retry-safe only after
checking its owned evidence and sandbox status. Remove clone trees only through
the guarded manifest workflow; otherwise retain them with exact paths.
