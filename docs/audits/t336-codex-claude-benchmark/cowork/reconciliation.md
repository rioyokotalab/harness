# Reconciliation

## Evidence accepted

Independent and reciprocal Claude receipts validate against their live imported
evidence. Accepted corrections include the balanced 16-scenario/eight-decision-
type design; three total observations; pinned `gpt-5.6-sol` and
`claude-opus-5`; gate-preserving and reward-hack cases; synthetic fleet names;
one-turn artifacts; separate task/unsafe/run-invalid/no-artifact outcomes;
achieved-observation reporting; aggregate-balanced order; event-level
shell-only verification; model canonicalization; and explicit driver-
authorship, containment, tool-surface, oracle-visibility, weighting, and
statistical limitations.

## Disagreements and uncertainty

Whole-client network isolation was rejected because it would block provider
transport required by both cloud clients. Strict committed-grader invisibility
is enforced for Claude's shell by hiding the Harness checkout, but Codex's
native workspace sandbox does not prove read denial for all same-account paths.
No oracle bytes enter run roots, prompts do not name graders, graders are
property-based, and outside-workspace reads are unsafe; the remaining
asymmetry is disclosed and bounds the claim. T-335 live state is out of scope,
but its pushed durable ledger remains legitimate provenance.

## Frozen plan

Implement the exact 16 scenarios in `plan.md` as a new versioned suite without
changing the frozen T-181/T-295 corpus. Every manifest entry contains the
client-neutral prompt, prompt digest, decision type, durable T-ID provenance,
allowed/protected paths, public check, hidden property grader, and mutation
fixtures. Run model-free validation and containment probes from a clean commit
before one 32-run pilot. If containment and evidence integrity hold, run two
more observations per scenario for 64 confirmation runs. Never replay
acknowledged rows. Publish only closed, value-free, reproducible aggregate
evidence and update README/TODO after results exist.

## Acceptance gates

1. Both co-pilot receipts and the frozen session validate.
2. Fixtures, Git graphs, prompt bytes, grader source, and schemas are sealed;
   grader/oracle bytes are absent from client-visible run inputs.
3. Shell-only events, direct/nested network denial, workspace-only writes,
   synthetic Git identity, source/sibling preservation, client versions, and
   canonical model IDs pass the declared probes.
4. Graders accept alternatives and reject plausible wrong/reward-hack variants.
5. Reports separate task failure, unsafe action, run-invalid,
   no-artifact-question, containment failure, and aggregation-invalidating
   model drift; achieved counts replace assumed counts.
6. Two report generations are byte-identical and pass the closed schema and
   privacy/claim lints.
7. Focused/full/protected repository validation and normal protected
   publication gates pass before fleet synchronization.
