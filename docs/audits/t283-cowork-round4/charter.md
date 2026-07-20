# Charter

## Task

Refine the v4 cowork protocol on two confidentiality/provenance gaps recorded at
the close of round 3. First, `cowork-session stage` copies raw `state.json` into
the co-pilot bundle; that state carries an absolute `predecessor.path` (and, for
any future field, could carry other absolute paths), disclosing the live audit
directory layout that a blinded co-pilot does not need. Second,
`init --predecessor` snapshots a predecessor's phase from its `state.json` but
never validates that phase's required Markdown, so it can record a
phase/content-inconsistent provenance (e.g. a `complete` predecessor whose
`charter.md` still holds a template `TODO`). Determine empirically whether narrow
changes can close these without weakening blinding, freshness binding, staged
atomicity, takeover semantics, or the existing refusal battery.

## Boundaries

Claude is driver and Codex is co-pilot. Both may experiment only in their
no-hardlink `/tmp/harness-t283-round4-{claude,codex}` clones and synthetic stage
or session directories built there. Codex receives copied inputs and writes a
candidate evidence file inside its own sandbox; it is not told or granted the
live exchange path. The Claude driver alone may import candidate bytes into this
session and later edit the live target after reconciliation. No credentials,
settings, packages, remotes, network services beyond the required native model
call, or external messages are in scope. No raw recursive cleanup is permitted;
sandboxes remain for guarded cleanup.

## Baseline and sandboxes

Both clones are detached at `9fed369bcdfd96c15914683820f6113b6a5bb898` with no
hard links. This session is a Claude-driver successor of the completed
Codex-driver round 3, recorded by `init --predecessor`. The live target is the
task branch in `~/harness`, clean apart from this declared round-4 exchange
directory. Driver-held seals, candidate outputs, and native stdout stay outside
the live session until an explicit validated import.

## Acceptance

Both agents must run concrete local tests and criticize the strongest opposing
claim. Evidence must establish whether staged `state.json` really discloses an
absolute predecessor/live path, whether `init --predecessor` accepts a
phase/content-inconsistent predecessor, and what the minimal deterministic fix
for each is without breaking freshness binding or the reciprocal round trip. Any
frozen implementation must have deterministic failure-atomic tests and pass the
canonical skill validator, focused cowork, Claude takeover, source contract,
public-repository audit, and `git diff --check`. The clean-checkout full
`tests/test-phase1.sh` and advance to `complete` are left to the supervising
Codex reviewer.
