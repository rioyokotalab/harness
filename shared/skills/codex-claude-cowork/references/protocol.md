# Cowork protocol reference

Read this reference for every cowork session. Paths below are conceptual; use
absolute, shell-safe paths resolved for the active repository.

## State machine and files

`scripts/cowork-session` permits only this forward sequence:

```text
planning -> discussing -> ready-for-execution -> executing -> validating -> complete
```

`init` writes session schema 2. Its default `exchange_mode=staged` uses the
receipt-backed workflow below. `init --exchange-mode direct` declares the
exceptional sealed live-session fallback up front and forbids staged commands
and receipts. The validator continues to read strict schema-1 predecessor
sessions under their original receipt-free layout.

The exchange directory contains:

| File | Owner | Required content |
| --- | --- | --- |
| `state.json` | validator | schema version, driver, co-pilot, phase, timestamps |
| `charter.md` | driver | task, boundaries, baseline and sandboxes, acceptance |
| `plan.md` | driver | steps, evidence questions, risks and recovery |
| `driver-evidence.md` | driver | independent run, results, critique, changes |
| `copilot-evidence.md` | co-pilot | independent run, results, critique, changes |
| `reconciliation.md` | driver | accepted evidence, disagreements, frozen plan, gates |
| `execution.md` | driver | target steps/results and deviations |
| `validation.md` | driver | final checks, outcome, residual risks |
| `artifacts/` | shared, bounded | tracked `.gitkeep`, task prompts, and public-safe raw logs named in evidence |
| `receipts/` | driver/validator | schema-2 staged import receipts; closed independent/reciprocal set |

The validator rejects missing headings, untouched standalone template `TODO`
markers, role mismatch, skipped or backward phases, symlinked or foreign-owned
protocol entries, hard-linked protocol files (any regular protocol file with a
link count other than one, which would alias content outside the session), and
any missing or unexpected top-level entry. New schema-2 sessions require real
current-user-owned `artifacts/` and `receipts/` directories; strict legacy
schema-1 sessions retain their old layout and forbid `receipts/`. It does not
prove factual correctness, client
authorship, or confinement of content below `artifacts/`, and it cannot by
itself detect a same-user overwrite of an already-valid file; both agents must
inspect those independently and the driver must seal digests (below).

`init` places an empty `artifacts/.gitkeep` in new sessions so the required
directory survives Git commits, clone-based sandboxes, and cross-client
takeover even when the session has no retained artifact. Keep that placeholder
in committed session ledgers; it is protocol structure, not evidence.

## Sandbox contract

Use two independently writable sandboxes derived from the same immutable Git
commit, source archive digest, snapshot, or fixture version. Record the exact
baseline and creation method in `charter.md` and both evidence files. A sandbox
must not contain credentials or automatically inherit authority to external
systems.

Permit network, package installation, schedulers, remote writes, or external
messages only if the owner's frozen task independently authorizes them and the
experiment cannot be made local. Otherwise deny them. Keep target checkout,
live exchange, and co-pilot stage separate. The co-pilot writes only inside its
sandbox; the driver imports its validated candidate into
`copilot-evidence.md`. Do not place auxiliary content at the session top level.

If sandbox cleanup can remove a tree or multiple paths, use the applicable
guarded-deletion workflow. Do not place raw recursive cleanup in prompts,
scripts, or handoffs.

## Independent evidence pass

Give each client only `charter.md`, `plan.md`, the common baseline, and its
owned evidence path. Require it to:

1. verify its sandbox identity and baseline;
2. execute the smallest experiment that can falsify each important plan claim;
3. capture commands or tool actions, exit status, and bounded output pointers;
4. label facts, inferences, uncertainties, and environmental differences;
5. propose a concrete edit to the plan for every confirmed flaw; and
6. leave the target and the other evidence file unchanged.

Finish and freeze the driver's independent evidence before opening the co-pilot
client window. Take the protected digest seal, and make no driver-owned live
write until its post-window comparison. This preserves blinding because an
independent stage does not contain driver evidence while keeping attribution
checkable. After both independent passes, expose both evidence files through a
fresh
reciprocal stage and request one reciprocal critique. Ask each client to address
the strongest contrary result, not to restate its first answer. The co-pilot
returns its complete evidence file, not a patch. When results differ, rerun a
matched test or record the discrepancy unresolved.

## Staged exchange

Create each stage as a direct child of the co-pilot sandbox and outside the live
session, with a mandatory external seal:

```text
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode independent \
  --prompt DRIVER_PROMPT_FILE \
  --seal EXTERNAL_SEAL_FILE
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode reciprocal \
  --prompt DRIVER_PROMPT_FILE \
  --seal EXTERNAL_SEAL_FILE
```

An independent stage contains `charter.md`, `plan.md`, and a fail-closed
path-free projection of `state.json`; a reciprocal stage also contains both
evidence files. The staged `state.json` is not the raw file: `stage` whitelists
exactly the supported schema fields, drops `predecessor.path` (a local absolute path a
blinded co-pilot does not need), and refuses any unknown or missing key, so a
future field that might carry an absolute path cannot be exported silently and a
new field cannot silently drop out of the staleness comparison. Projection runs
before the stage directory is created, so a fail-closed refusal leaves no
partial stage; a legitimate additive state field cannot stage until the
projection classifies it, tied to `schema_version`. `stage.json` records the
mode, roles, phase, destination-before SHA-256, and SHA-256 of every copied input
(the projected bytes for state) without disclosing the live-session path. The
stage also contains a real
`artifacts/` directory and `candidate-copilot-evidence.md`. Put the
sealed task-specific prompt at the fixed
`artifacts/copilot-prompt.md` path and bounded terminal output elsewhere below
the staged `artifacts/` directory. Prepare the prompt in a driver-only path and
pass it through `stage --prompt`; do not add or replace it after sealing.

New stages use stage schema 3. `--prompt` descriptor-checks a current-user-owned,
single-link regular file, caps it at 32 KiB, requires UTF-8, and completes those
checks before creating the stage. It copies the exact bytes to the fixed prompt
path and records `prompt_sha256` in `stage.json`; the external seal commits that
manifest hash and import reopens and rechecks the prompt before any live write.
The reader retains stage-schema-2 compatibility. Schema 3 permits a null prompt
only for promptless synthetic stages and rejects a fixed-path prompt added later
without a hash.

`stage` also prints `stage_sha256=...`. Before invoking the co-pilot, store that
exact hash outside the stage, live session, and co-pilot sandbox next to the
protected live manifest. Compare both after return. A stage is co-pilot-writable;
the hash recorded later in an import receipt binds bytes but is not an authentic
driver seal unless the external pre-window value also matches. When reporting a
seal deviation for reciprocal review, copy the bounded before/after manifests
into the reciprocal stage artifacts.

For a schema-2 staged session `--seal` is required and turns that advisory hash
into an enforced anchor. `stage` resolves and pre-checks the seal path *before*
minting any stage bytes — refusing a seal resolved inside the live session or the
stage-parent sandbox, or an already-present seal path, so a bad seal leaves no
partial stage — then writes a real, mode-0600, path-free seal with exactly these
seven keys: `schema_version`, `driver`, `copilot`, `mode`, `phase`,
`destination_before_sha256`, and `stage_manifest_sha256` (the exact `stage.json`
SHA-256). The manifest hash transitively commits the stage schema, roles, mode,
phase, destination-before, every staged input hash, and the optional sealed
prompt hash, because those all live in `stage.json`; the duplicated
role/mode/phase/destination fields are explicit
consistency checks, not extra commitments. The seal binds stage *content*, not
identity or location: two byte-identical stages share one valid seal, which is
harmless. Writing the seal is a second file after `stage.json`: it is fail-closed
(a failed seal write leaves a sealless, import-refused stage) but not cross-file
atomic; retry with a fresh stage and seal after exact inspection. The
stage-parent refusal identifies the co-pilot sandbox only under the documented
precondition that `STAGE_DIR` is a direct child of that sandbox; a nested stage
would make the immediate parent too narrow, so keep stages direct children (or,
if a caller cannot, extend the helper with an explicit co-pilot-root argument).
Store the seal outside every co-pilot-writable tree; a path check is not OS
confinement and mode 0600 does not stop a same-UID process that can reach the
seal.

The driver tells the co-pilot only the sandbox and stage paths. After return,
the driver inspects the complete candidate and then runs:

```text
scripts/cowork-session import-copilot SESSION_DIR STAGE_DIR --seal EXTERNAL_SEAL_FILE
```

For a schema-2 staged session `--seal` is required. Before any target write,
import refuses a seal resolved inside the session or stage-parent tree; requires a
real, current-user-owned, single-link, non-symlink file; parses UTF-8 JSON with
exactly the seven seal keys and supported schema; and requires the seal `driver`,
`copilot`, `mode`, `phase`, and `destination_before_sha256` to match the stage
and the seal `stage_manifest_sha256` to equal the exact SHA-256 of the stage's
current `stage.json`. The regular-file, owner, link, content, and digest checks
use one opened file description, so `seal_sha256` binds the exact seal bytes
parsed by that import even if the leaf path is replaced afterward. Replacement
before open and reachable same-UID paths remain outside this byte-identity
guarantee. This closes the crash-then-relaunder path: because a
co-pilot can rewrite the stage's own `stage.json` (including
`destination_before_sha256`) after a crash-shaped evidence overwrite, only an
external seal the co-pilot cannot reach can detect that rewrite. Import also
refuses a stale or altered input, unexpected stage entry, linked or
foreign-owned file, candidate larger than 64 KiB, invalid UTF-8, missing or
out-of-order heading, or standalone TODO. It writes a temporary file inside the
live session filesystem, atomically replaces only `copilot-evidence.md`, and
revalidates the discussing session. Retain the stage through reconciliation so
the copied input and candidate bytes remain recoverable and reviewable.

Import applies the same `state.json` projection to the live session before its
freshness comparison, so freshness is equality of the projected, co-pilot-visible
state, not of the raw bytes. Import therefore does not detect a change confined
to a withheld field (such as `predecessor.path`) or a representation-only
reserialization; the out-of-session `digests` seal over full raw `state.json`
plus a recoverable preimage remains the control for those, and detects rather
than prevents or restores. Changes to any retained field (phase, timestamps,
roles, retained predecessor fields) are still stale-rejected with the live
`copilot-evidence.md` byte-identical.

New sessions use schema 2 and `exchange_mode=staged` unless initialized with the
exceptional `--exchange-mode direct`. A schema-2 stage binds the live
`copilot-evidence.md` hash as `destination_before_sha256`; import refuses drift
before mutation. A successful staged import creates exactly one closed receipt
for its mode under `receipts/`. Receipt fields bind roles, phase, projected input
hashes, full raw-state hash, exact stage-manifest hash, destination-before hash,
the external seal SHA-256, candidate hash, and import time, with no filesystem
paths. New receipts are written at receipt schema 2 (with the seal hash); the
reader also accepts schema-1 receipts, because a schema-2 staged session created
by a pre-seal helper may already hold schema-1 receipts, and rejecting them would
break an otherwise valid session. `verify-receipts SESSION_DIR` validates the
stored seal hash and the receipt/evidence chain, but does not reopen or re-hash
the external seal file; comparing retained seal bytes is a separate step.
Independent must precede reciprocal. Run `verify-receipts SESSION_DIR` after each
import.

Receipt creation writes and fsyncs a temporary on the session filesystem, then
atomically links the complete bytes to a no-overwrite final name and removes the
temporary. Ordinary exceptions remove only a receipt created by that invocation
and restore prior evidence. This is not cross-file crash atomicity: a crash
between evidence replacement and receipt creation leaves ambiguous live bytes,
but destination-before binding makes automatic retry fail closed. A crash can
also leave a detectable exact temporary or complete hard-linked receipt; stop
for reviewed exact cleanup rather than sweeping. `digests` enumerates existing
receipt files, and staged ready/later phases require both receipts plus a live
candidate match. Schema-2 direct sessions have no receipts; strict schema-1
sessions and predecessors retain legacy receipt-free rules.

The hashes prove byte equality and freshness at import; they do not prove that
the driver supplied honest inputs or that model prose was generated from those
inputs. Record the staged input hashes, candidate hash, resolved command,
blinding condition, and import result rather than claiming cryptographic
authorship.

## Native client mapping

The driver must construct a bounded task-specific prompt in a driver-only path
before staging it with `--prompt`. The sealed copy below staged `artifacts/`
names the sandbox, stage, candidate file, allowed actions, forbidden targets,
baseline, experiment/time budget, strongest open questions, and required return
format. Do not disclose the live session. Avoid
interpolating untrusted task text into a shell command; pass it on standard
input.

When Codex drives Claude, run Claude from the Claude sandbox with noninteractive
print mode. Build the narrowest reviewed `--allowedTools` list from the frozen
experiment and use a non-prompting permission mode. Do not use
`--dangerously-skip-permissions`. For routine bounded critique, select explicit
model/effort options only after confirming them in the installed `--help`, and
record them; escalate only for an unresolved material claim:

```text
claude --print --permission-mode dontAsk \
  --allowedTools REVIEWED_TOOL_LIST \
  < STAGE_DIR/artifacts/copilot-prompt.md \
  > STAGE_DIR/candidate-copilot-evidence.md
```

When Claude drives Codex, run ephemeral Codex in the Codex sandbox. Use
workspace-write confinement and no interactive approvals. Keep the stage below
that sandbox so no additional writable path is needed:

```text
codex --ask-for-approval never exec --ephemeral --sandbox workspace-write \
  --cd CODEX_SANDBOX \
  --output-last-message STAGE_DIR/candidate-copilot-evidence.md \
  - < STAGE_DIR/artifacts/copilot-prompt.md
```

Add `--skip-git-repo-check` only for an intentionally non-Git synthetic
sandbox. If the installed client rejects a documented option, capture its
version and error, inspect current `--help`, and revise the mapping explicitly;
never silently fall back to an unconfined invocation.

For a long client window, keep the command recognizable, launch it in the
background, and sample the driver-only read surface rather than manually
combining process, candidate, stage, seal, and receipt checks:

```text
COPILOT_NATIVE_COMMAND ... &
COPILOT_PID=$!
scripts/cowork-session status SESSION_DIR --stage STAGE_DIR \
  --seal EXTERNAL_SEAL_FILE --pid "$COPILOT_PID"
scripts/cowork-session wait-copilot SESSION_DIR --stage STAGE_DIR \
  --seal EXTERNAL_SEAL_FILE --pid "$COPILOT_PID" \
  --timeout-seconds CLIENT_BUDGET_SECONDS
wait "$COPILOT_PID"
```

`status` emits deterministic JSON with roles, phase, receipts, next action,
stage/input freshness, prompt/stage/seal hashes, candidate bytes and state, and
optional PID reachability. It never writes or waits. `empty`, `unchanged`,
`invalid`, or `ready` describes only observed candidate bytes; PID reachability
is vulnerable to reuse. Neither signal proves authorship, semantic progress,
correctness, or success. Always inspect the final candidate and compare the
protected manifests before import.

When `--stage` is given, `status` also emits an advisory
`stage.mechanical_import_preconditions` object:
`candidate_structurally_ready` (true iff `candidate_state == "ready"`),
`inputs_fresh`, `destination_fresh`, their conjunction as `all_satisfied`,
`advisory: true`, and `authorization: "none"`. It summarizes the three
existing byte/freshness observations already present as sibling fields and
adds no new information; it must never be read as, or renamed to,
`import_ready`. It closes the risk of a caller reading `candidate_state:
ready` alone and importing a candidate staged against live inputs the driver
has since changed. It covers only candidate/freshness bytes — not seal
validation, stage mode/receipt sequencing, process exit, protected digests,
semantic review, or `import-copilot`/`verify-receipts` success. Only
`import-copilot` is the authoritative mechanical gate.

`wait-copilot` reuses that same snapshot on a monotonic, explicitly bounded
poll loop (finite `0 < --timeout-seconds <= 1800`, finite
`1 <= --poll-seconds <= 60`) and
prints exactly one final JSON object. It returns `ready`/0 only for the full
three-fact conjunction, `not-importable`/2 only after an observed process loss
and one immediate final snapshot, or `timeout`/4. Without `--pid`, only ready
or timeout can terminate the wait. Empty or structurally invalid bytes can be
a transient editor write and do not terminate while the PID is reachable. A
ready-but-stale candidate never returns ready. `wait_observation` always says
`advisory: true`, `authorization: "none"`, and
`pid_identity_authenticated: false`; PID reachability is vulnerable to reuse.
The waiter never imports or writes. Inspect semantics, native process exit,
protected digests, and receipts separately.
Each completed snapshot is classified against the monotonic deadline before
ready or not-importable can be returned. The timeout does not preempt a
synchronous filesystem read already in progress, so it bounds polling
classification rather than guaranteeing a hard wall-clock interrupt.

The driver, which retains the live-session and external-seal paths, runs
`status` during and after the native co-pilot window. The blinded co-pilot
reports only stage-local observations. Neither candidate state nor PID
reachability authorizes import.

These templates do not supersede closer command policy. Codex workspace-write
provides an OS-enforced writable-root boundary; it limits writes, not reads,
so it does not by itself prevent a confined process from reading outside that
root. Claude Code's `--add-dir` and tool permissions are not an OS filesystem sandbox:
with Bash allowed, a same-user process may discover and write other writable
paths. For Claude, staging removes explicit disclosure and the routine live
write channel but remains behavioral authority reduction unless an available
platform sandbox is applied. Record that residual or use the required
environment-native wrapper; never invent a non-portable command or claim equal
enforcement. No claim of equivalent Claude/Codex confinement is made anywhere
in this reference.

## Protecting driver-owned files across a co-pilot window

Staging is the default and removes the normal reason to grant live-session
write. A direct `--add-dir SESSION_DIR` grants the co-pilot write over the entire
exchange directory, so as the same user it can overwrite any driver-owned file.
Use it only when a recorded experiment cannot use staging. File ownership and
mode `0600` do not establish authorship or integrity, and a co-pilot can
re-`chmod` a read-only file before writing it. Read-only mode is therefore only
an advisory accidental-write tripwire.

Before every Claude co-pilot window—and as defense in depth for Codex—the driver
runs `scripts/cowork-session digests SESSION_DIR` and stores the manifest
**outside** both `SESSION_DIR` and the co-pilot sandbox. `digests` covers
`state.json` and the driver Markdown, excluding `copilot-evidence.md` and shared
artifacts; schema-2 receipt files are included when present. Preserve a
recoverable preimage too, such as a reviewed commit or an
external protected-file copy; hashes detect change but cannot restore bytes.
After the client returns, re-run and compare digests before candidate import.
Any protected change is a stop condition that returns the session to owner
review. Apply the same seal plus recoverable preimage around an exceptional
direct-session fallback.

Freeze `driver-evidence.md` before taking the pre-window seal. Do not edit any
driver-owned live file while the co-pilot process runs. Seal the freshly created
`stage.json` separately as described above. A known driver write still makes the
window comparison noisy and must be recorded as a deviation, not rationalized
as an unchanged co-pilot window.

## Reconciliation rules

Rank support in this order: reproducible observed result on a matched baseline;
primary source or repository contract; deterministic static analysis; explicit
inference; unsupported opinion. More evidence can outweigh this order only
when relevance or test validity differs, and the reconciliation must say why.

The frozen plan must include:

- exact ordered steps and the one target-writing role;
- accepted and rejected changes with evidence pointers;
- unresolved uncertainty and its conservative treatment;
- preconditions, rollback, stop conditions, and authority boundaries;
- per-step checks and final acceptance; and
- the owner go status and next executable action.

Do not erase minority evidence. If disagreement affects safety, scope,
correctness, irreversible state, or acceptance, resolve it empirically or ask
the owner before target execution.

## Takeover and failure

Distinguish two interruption cases. In **same-role process recovery** — the same
client resumes its own driver session — a new process reads the target ledger and
all exchange files, validates the recorded current phase, and resumes the first
unverified action in place. In **cross-product role transfer** — the other
client becomes driver — file ownership and execution authority change, so it
requires an explicit owner instruction and a *new* session that starts at
`planning`; it cannot resume the predecessor's recorded phase. The helper offers
no in-place takeover operation by design. To keep provenance without inheriting
authority, initialize the new session with
`scripts/cowork-session init NEW_DIR --driver ROLE --predecessor OLD_DIR`, which
records the predecessor's path, driver, phase, and validated state digest under a
`predecessor` block while still beginning at `planning`. `init --predecessor`
validates the predecessor's phase-required Markdown before snapshotting it and
before creating the new session, so a recorded phase cannot describe a
predecessor whose content never satisfied it; the check is refused atomically
with no partial successor. This asserts present protocol completeness, not
historical authorship or a transactional multi-file snapshot.

A client failure is retry-safe only when its sandbox and owned files show no
ambiguous partial action. Record the exact error, files touched, and retry
precondition. Never interpret absent output as a successful review.
