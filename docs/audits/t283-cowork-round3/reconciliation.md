# Reconciliation

## Evidence accepted

Both agents independently demonstrated that staged input/output files preserve
blinding and allow a valid co-pilot evidence import while leaving every
protected session digest unchanged. Claude's eight-case prototype battery
showed stale, hardlinked, symlinked, oversized, non-UTF-8, TODO-bearing,
heading-deficient, and unexpected-layout candidates can be refused with the
session byte-identical. Its cross-filesystem probe proved atomic import must
write the temp beside the live destination before `os.replace`.

Both also confirmed v3's digest seal detects but cannot restore overwritten
uncommitted bytes. Reciprocal evidence corrected the strongest overclaim:
removing `--add-dir SESSION_DIR` gives Codex's workspace-write co-pilot a
mechanically enforced smaller writable set, but Claude with Bash can still
discover and write other same-UID paths. For Claude it removes explicit path
disclosure and the routine write channel—valuable accidental-authority
reduction—while an external seal plus recoverable preimage remains the primary
backstop unless a platform OS/container sandbox is available.

## Disagreements and uncertainty

The only initial disagreement was whether staging mechanically closes the live
write vector for Claude. Claude withdrew that claim after reproducing an
out-of-checkout Bash write without `--add-dir`; both sides now distinguish
Codex OS enforcement from Claude behavioral policy. The seal's weight is
therefore product-dependent: defense in depth for workspace-confined Codex,
primary post-window detection for unwrapped Claude.

Staging binds copied bytes to the current session at import time but cannot
cryptographically prove to the co-pilot that the driver supplied honest copies
or that model prose was generated from them. This is an unavoidable role-trust
limit, not a blocker: the driver is already authoritative for charter/plan and
must record input and candidate hashes for later review. True enforcement parity
for Claude depends on a separately available platform sandbox; the skill must
not invent or require a non-portable wrapper.

## Frozen plan

Codex remains the only live-target writer. The owner's original instruction is
the go for exactly these v4 edits:

1. Add `cowork-session stage SESSION_DIR STAGE_DIR --mode
   independent|reciprocal`. It requires a valid `discussing` session and a fresh
   real external stage directory, refuses a stage inside the session, and
   writes mode-0600 copies plus `stage.json`, a real `artifacts/`, and a
   candidate evidence file. Independent input is state/charter/plan;
   reciprocal input additionally includes both evidence files. `stage.json`
   records schema, mode, roles, phase, and sorted SHA-256 input hashes without
   disclosing the live path.
2. Add `cowork-session import-copilot SESSION_DIR STAGE_DIR`. It requires the
   exact mode-specific stage layout; current-user-owned real single-link files;
   manifest/copy/current-session hash equality; unchanged discussing roles and
   phase; candidate size at most 64 KiB, UTF-8, required headings in order, and
   no standalone TODO. After driver review, it writes a mode-0600 temp inside
   the live session, fsyncs, `os.replace`s only `copilot-evidence.md`, and
   revalidates. Every refusal must leave live bytes unchanged.
3. Make staged exchange the default native mapping. Place the stage inside the
   co-pilot sandbox, pass only its prompt on stdin, and collect the complete
   candidate locally; remove the normal `--add-dir SESSION_DIR`. Repeat with a
   reciprocal stage and full-file candidate. Record stage/candidate hashes,
   blinding, resolved command, and import result.
4. State the product difference precisely: Codex `workspace-write` enforces the
   reduced writable set; Claude without an outer OS/container sandbox relies on
   behavioral policy despite the reduced explicit authority. Around Claude,
   retain external digest comparison and a recoverable protected preimage
   (commit or external copy); around Codex, keep the seal as defense in depth.
   Describe v3 direct-session write as an exceptional sealed fallback, never the
   default, and describe hashes as detection rather than prevention/recovery.
5. Add focused tests for both stage modes, manifest determinism and blinding,
   round-trip import, all refusal cases, same-filesystem atomic replacement,
   exact stage/session preservation, and both revised native command strings.
   Do not weaken existing hard-link, takeover, state, or mapping tests.

Rejected changes: claiming equal OS confinement, requiring a guessed portable
Claude wrapper, deleting the useful digest command, importing informal copies,
or accepting a co-pilot-supplied manifest as authority.

## Acceptance gates

The canonical quick validator, expanded cowork focused test, Claude takeover,
source contract, public-repository audit, `git diff --check`, and full
`tests/test-phase1.sh` must pass. This session must complete using the new
importer for its reciprocal evidence already staged manually, and a synthetic
round trip must prove failure atomicity. Final review must show no settings,
credentials, packages, remotes, external systems, or non-driver target changes.
All round-3 scratch remains for guarded cleanup until evidence is committed.
