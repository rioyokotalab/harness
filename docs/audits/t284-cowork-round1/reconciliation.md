# Reconciliation

## Evidence accepted

Both clients independently reproduced the focused cowork suite at essentially
10 seconds (10.12s driver, 9.967s co-pilot). Driver measurement showed a clean
eight-worker full gate at 76.39s versus the initial four-worker 88.18s, but this
is only one unmatched-order sample and is not enough to change the default.

Accepted prompt-integrity finding: the driver created and materially changed
`artifacts/copilot-prompt.md` after staging while `stage.json` and its external
seal stayed byte-identical. Claude confirmed the current helper has no prompt
concept and the real reciprocal stage manifest omits its 1,796-byte prompt.
Thus the actual instructions seen by the co-pilot are outside the receipt's
transitive input commitment today.

Accepted monitoring finding: the default Claude independent call remained
reachable for 10m08s while its redirected candidate stayed at zero bytes, then
left only `Execution error` on interruption. Target, sandbox Git, protected
files, stage manifest, and seal stayed unchanged. The bounded Sonnet/medium
retry completed in about 70s and reciprocal in about 170s. Current monitoring
required separate process-table, `stat`, digest, stage, and receipt commands.
Claude demonstrated that session `check` rejects real stage layout; a status
surface must be stage-aware rather than pretending a stage is a session.

Accepted CI finding: GitHub PR #161's required job took 138s. The standalone
ShellCheck step took 22s, five standalone suites later repeated by phase one
took 15s, affinity took 9s, and phase one took 86s. Source comparison confirms
the ShellCheck pipeline is also repeated inside `test-phase1.sh` when the
available CI `shellcheck` binary is present. Claude independently traced the
five duplicate suites and corrected its initial literal-grep reasoning by
following `focused-suites.tsv`. The cowork suite itself runs once indirectly
through that manifest and affinity runs once outside phase one.

## Disagreements and uncertainty

Claude initially claimed the cowork suite was not inside phase one because its
literal path is absent from `test-phase1.sh`; reciprocal tracing corrected the
reasoning: the manifest includes it, so it runs exactly once. Claude proposed
retaining the standalone ShellCheck step without comparing it to phase one's
identical conditional block. The driver's direct source and historical step
timing resolve that conflict in favor of removing the duplicate standalone
step while retaining phase one's attributed failure output and capability
record.

Rejected for this round: an independently receipted base plus reciprocal
addendum. It could reduce model output bytes but requires a new submission/final
hash distinction and reconstructed recovery record. Neither client produced an
empirical benefit large enough to justify those semantics; keep complete
replacement evidence capped at 64 KiB.

Uncertain: how much of the 10m-to-70s client delta came from explicit
Sonnet/medium selection versus the bounded prompt. Record both commands and use
bounded evidence questions by default, but do not claim a product-wide model
speed ratio. PID reachability is vulnerable to reuse and candidate completeness
does not prove authorship, correctness, or cognitive progress. The eight-worker
local gain remains provisional until the reverse-direction round repeats
matched samples.

## Frozen plan

The owner's three-hour instruction is explicit go for this frozen repository
scope. Codex remains the only target-writing role.

1. Extend `stage` with optional `--prompt FILE`. Read a current-user-owned,
   single-link regular file through one descriptor, enforce bounded UTF-8 bytes,
   and finish this validation before creating a stage. New stage schema 3 copies
   it to fixed `artifacts/copilot-prompt.md`, stores `prompt_sha256` (or null for
   backward-compatible promptless synthetic stages), and has import recheck the
   fixed artifact before any live write. Continue to read stage schema 2. The
   existing external seal and receipt `stage_manifest_sha256` then transitively
   commit the prompt without changing seal or receipt schemas.
2. Add one read-only `status SESSION [--stage STAGE --seal FILE] [--pid PID]`
   JSON snapshot. Validate the live session normally and a supplied stage with
   its stage-aware validator; report roles, phase, exchange mode, receipt modes,
   next action, candidate bytes/state (`empty`, `unchanged`, `invalid`, or
   `ready`), input freshness, stage/seal hashes, and optional process
   reachability. Never write or wait. Mark PID reachability and candidate state
   advisory and fail closed on malformed protocol data.
3. Update the skill/reference native mappings to prepare a bounded prompt file
   before staging, pass it through `--prompt`, run the recognizable native
   client in the background when monitoring is useful, and sample `status`.
   Require task/time bounds and explicit supported effort/model choices in the
   recorded command; escalate effort only for unresolved material conflicts.
4. Expand focused tests for schema-2 stage compatibility, schema-3 prompt copy
   and digest binding, pre-creation rejection, post-stage prompt drift, status
   snapshots across independent/reciprocal candidate states, receipt/next-step
   summaries, advisory PID results, malformed stage refusal, and read-only
   behavior.
5. Remove CI's standalone ShellCheck and the five proven duplicate suite steps.
   Retain capability recording, affinity, and the full required phase-one gate;
   verify its existing per-suite/failure log attribution and ShellCheck failure
   label. Do not change the four-worker default in this round.
6. Run incremental syntax, canonical skill, focused cowork, Claude takeover,
   source, public-audit, and diff checks. Run the reverse Claude-driver round on
   the implemented candidate before freezing any worker-count change, then run
   clean full acceptance.

## Acceptance gates

Helper AST and CLI help pass; schema-2 predecessors remain readable; new stages,
seals, prompt hashes, imports, and receipts validate in both modes; status is
deterministic, parseable, non-mutating, stage-aware, and honest about advisory
signals. Both driver directions use the same workflow. The canonical skill
validator, focused cowork suite, Claude takeover, source contract,
public-repository audit, `git diff --check`, and clean `tests/test-phase1.sh`
pass. CI keeps the protected `portable-phase1` job name and complete assertions.
No credentials, private data, external settings, packages, services, remotes,
or publication change. Any material schema/recovery regression returns to
discussion instead of being rationalized as a speed tradeoff.
