# T-283 Codex–Claude cowork acceptance

Work began on 2026-07-20 and was accepted on 2026-07-21 from branch
`task/t-283-codex-claude-cowork`. This
document is an index; each linked round directory remains the authoritative raw
plan, evidence, reconciliation, execution, validation, and cleanup record.

## Product-direction and protocol matrix

| Round | Driver | Co-pilot | Main question exercised | Durable outcome |
| --- | --- | --- | --- | --- |
| [1](t283-cowork-round1/) | Codex | Claude | Can one neutral role contract drive real planning, sandbox criticism, and driver-only execution? | Initial symmetric skill, helper, protocol, and focused suite |
| [2](t283-cowork-round2/) | Claude | Codex | Does reverse direction expose attribution, hard-link, and takeover gaps? | Hard-link rejection, digest discipline, new-session takeover provenance |
| [3](t283-cowork-round3/) | Codex | Claude | Can discussion avoid granting the live exchange to the co-pilot? | Default staged exchange and validated atomic candidate import |
| [4](t283-cowork-round4/) | Claude | Codex | Can staged state remain path-free and takeover provenance remain validated? | Closed state projection and predecessor completeness validation |
| [5](t283-cowork-round5/) | Codex | Claude | Can imports leave a durable, replay-resistant chain? | Destination-before binding, independent/reciprocal receipts, direct-mode isolation |
| [6](t283-cowork-round6/) | Claude | Codex | Can a co-pilot rewrite stage metadata after a crash-shaped evidence overwrite? | External stage-manifest seals and receipt schema 2; two process deviations recorded |
| [7](t283-cowork-round7/) | Codex | Claude | Is the release candidate symmetric and usable without speculative hardening? | Matched no-code acceptance; retained residuals classified explicitly |
| [8](t283-cowork-round8/) | Codex | Claude | Does a receipt hash the exact seal bytes that authorized import? | One descriptor now supplies file validation, JSON bytes, and receipt digest |

Both native directions were therefore exercised repeatedly, not simulated by a
same-product subagent. Rounds alternate the driver through round 6; round 7 also
has Claude exercise complete sealed scratch sessions for both driver values.
Codex co-pilot runs used ephemeral workspace-write confinement; Claude co-pilot
runs used staged disclosure and restricted native tools, with the documented
same-UID behavioral-confinement residual.

## Accepted behavior

The active client is always the driver and the other native client is the
co-pilot. The driver owns the plan and target execution. Both sides independently
exercise important claims on matched immutable baselines before seeing the
other's conclusions, then run a reciprocal critique. The driver reconciles
evidence into a frozen plan and advances a forward-only state machine before
executing. A cross-product role transfer starts a new planning session with
validated predecessor provenance; it never inherits execution authority.

Staged exchange is the default. Schema-2 sessions project path-free state,
require a driver-held external seal over the exact stage manifest, import only a
fresh validated candidate, and create a closed independent/reciprocal receipt
chain. Direct mode is a separately declared exceptional fallback. The helper
continues to validate strict schema-1 historical sessions and already-written
schema-1 receipts without weakening new schema-2 writes.

## Acceptance evidence

- All eight tracked sessions validate as `complete` under the final helper.
- Both schema-2 sessions validate their full reciprocal receipt chains; rounds
  1–5 remain strict legacy fixtures.
- Clean `tests/test-phase1.sh` passed after the round-6 enforcement checkpoint
  and again after the round-7 release-candidate checkpoint. Every listed suite
  passed; native MPI smoke was the runner's declared environment-only skip.
- Focused cowork, Claude takeover, source-contract, public-repository audit,
  syntax, whitespace, discovery-link identity, Git worktree integrity, and
  protected-anchor cleanup checks passed.
- A final exact FIFO-leaf probe returned immediately under a five-second guard
  and was rejected as a non-real protocol file, confirming `O_NONBLOCK` avoids
  the special-file hang introduced by open-before-`fstat`. Static source scan
  found no subprocess, shell-eval, or recursive-deletion primitive in the helper.
- Claude 2.1.207 then performed a final read-only post-validation inspection of
  `66b80b7` and returned **no acceptance defect** after tracing descriptor
  lifetime/double-close paths, Linux/macOS flags, diagnostics, compatibility,
  exact-byte binding, focused assertions, and documentation scope. Its sole
  informational note—an uncaught rare regular-file read `OSError`—is unchanged
  from the prior path-based reader and is not a regression.
- Codex, Claude, and Agents discovery links resolve to the same canonical
  repository skill directory.
- The branch is clean, fetched, `0` commits behind and `26` commits ahead of
  `origin/main` at acceptance. Nothing was pushed.

## Known limits and deviations

- Hashes and receipts prove byte relationships, freshness, and chain structure;
  they do not prove model authorship, honest inputs, or OS confinement.
- Claude's native tool permissions are not an OS filesystem sandbox. External
  seal placement is load-bearing when Claude is co-pilot; Codex workspace-write
  provides the stronger enforced writable-root boundary.
- The seal-location check treats the stage parent as the sandbox root and is
  sound only under the mandatory direct-child layout.
- Receipt verification validates the stored seal digest but cannot discover and
  reopen a path-free retained seal after import. Retained-byte comparison is a
  separate audit/recovery action.
- The helper enforces its own phase transitions but cannot stop arbitrary editor
  writes. Phase ordering remains an audited process invariant.
- Round 8 removed a narrower receipt-provenance TOCTOU: seal file properties,
  parsed JSON, and `seal_sha256` now come from one opened file description.
  Same-UID replacement before that open and parent-path reachability remain the
  documented confinement residuals.
- Round 6 recorded, rather than concealed, one raw recursive cleanup of an
  already-disposable smoke directory and one target edit made before the
  `executing` transition. Neither affected credentials, user evidence, or the
  final accepted target, but round 6 is explicitly not process-clean. Round 7
  repeated the direction cleanly and did not erase that history.

All preserved round scratch was removed through guarded manifests with protected
anchors unchanged; exact prompt/marker/manifest files were separately unlinked.
Tracked session evidence and Git commits are the recovery surface.
The FIFO probe's generated Python cache was also guard-cleaned under token
`0ef1da4b…` (2 entries; 51,663 bytes) with protected anchors unchanged; the
spent manifest and exact FIFO were unlinked.
A final `/tmp` residue sweep found four spent mode-0600 manifests from rounds
3–5 (including the round-4 Python-cache manifest); their guarded targets were
already absent and cleanup evidence was tracked, so each exact file was unlinked
non-recursively. The subsequent task-name residue scan was empty.
A broader case-insensitive sweep then found 22 early-round prompt/output files
that were superseded by tracked audit artifacts. They were moved by explicit
exact paths (no glob) into one fresh bounded directory; guarded token
`8b08d7fa…` revalidated and deleted that directory (23 entries; 23,775 bytes)
with protected anchors unchanged. The spent manifest was exact-unlinked, and a
final top-level `/tmp` scan for every `t283` spelling returned empty.

## Handoff

The reusable skill lives at
`shared/skills/codex-claude-cowork/`; use its `SKILL.md` and read the protocol
reference completely for every session. The helper and focused test are the
executable contract. Remaining ideas—descriptor-bound reads, an explicit
co-pilot-root authority surface, retained-seal lookup, or an OS-enforced Claude
wrapper—need separate evidence and compatibility design; they are not unfinished
acceptance requirements.
