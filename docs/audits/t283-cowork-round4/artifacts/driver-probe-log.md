# Driver probe log (round 4)

Bounded raw output referenced from `driver-evidence.md`. Sandbox
`/tmp/harness-t283-round4-claude`, baseline `9fed369`. Helper under test is the
sandbox copy of `shared/skills/codex-claude-cowork/scripts/cowork-session`;
the prototype is `/tmp/harness-t283-round4-claude/proto-cowork-session`.

## H1 — staged state.json discloses an absolute predecessor path

- `init pred --driver codex`; `init succ --driver claude --predecessor pred`.
- Successor `state.json` contains `predecessor.path =
  /tmp/harness-t283-round4-claude/h1work/pred` (absolute).
- After filling charter/plan and advancing to `discussing`,
  `stage succ stage --mode independent` copied `state.json` verbatim; the staged
  `state.json` and `stage.json` both retained the absolute predecessor path.
- Control: a no-predecessor `init` produces `state.json` with no `predecessor`
  key, so the disclosure is isolated to the predecessor block.

## H2 — init --predecessor accepts a phase/content-inconsistent predecessor

- Built a predecessor, then rewrote its `state.json` phase to `complete` while
  `charter.md` still held 4 standalone `TODO` markers.
- `check --phase complete` FAILED: "charter.md still contains an unresolved
  TODO marker" — the content validator rejects the inconsistency.
- `init succ --driver claude --predecessor pred` SUCCEEDED and recorded
  `predecessor.phase = complete`, proving `predecessor_record` loads state but
  never calls `validate_files`.

## Prototype (both fixes) round-trip

- P1: staged `state.json` retained the `predecessor` block minus `path`; grep
  for the predecessor path across the whole stage found nothing.
- P2: `import-copilot` succeeded on a projected state; live `state.json`
  digest unchanged before/after import (freshness binding survived projection).
- P3: a staged `state.json` with a mutated `phase` was rejected
  ("staged input digest mismatch: state.json") with live `copilot-evidence.md`
  byte-identical.
- P4: `init --predecessor` against the inconsistent predecessor was rejected
  ("charter.md still contains an unresolved TODO marker"); the successor
  directory was never created (rejection precedes `root.mkdir`).
- P5: a legitimately advanced `complete` predecessor was still accepted.
