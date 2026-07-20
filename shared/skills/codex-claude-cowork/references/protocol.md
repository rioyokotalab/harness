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
| `artifacts/` | shared, bounded | task prompts and public-safe raw logs named in evidence |
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

Create each stage inside the co-pilot sandbox and outside the live session:

```text
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode independent
scripts/cowork-session stage SESSION_DIR STAGE_DIR --mode reciprocal
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
task-specific prompt and bounded terminal output below the staged `artifacts/`
directory.

`stage` also prints `stage_sha256=...`. Before invoking the co-pilot, store that
exact hash outside the stage, live session, and co-pilot sandbox next to the
protected live manifest. Compare both after return. A stage is co-pilot-writable;
the hash recorded later in an import receipt binds bytes but is not an authentic
driver seal unless the external pre-window value also matches. When reporting a
seal deviation for reciprocal review, copy the bounded before/after manifests
into the reciprocal stage artifacts.

The driver tells the co-pilot only the sandbox and stage paths. After return,
the driver inspects the complete candidate and then runs:

```text
scripts/cowork-session import-copilot SESSION_DIR STAGE_DIR
```

Import refuses a stale or altered input, unexpected stage entry, linked or
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
candidate hash, and import time, with no filesystem paths. Independent must
precede reciprocal. Run `verify-receipts SESSION_DIR` after each import.

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

The driver must construct a task-specific prompt below staged `artifacts/` that
names the sandbox, stage, candidate file, allowed actions, forbidden targets,
baseline, and required return format. Do not disclose the live session. Avoid
interpolating untrusted task text into a shell command; pass it on standard
input.

When Codex drives Claude, run Claude from the Claude sandbox with noninteractive
print mode. Build the narrowest reviewed `--allowedTools` list from the frozen
experiment and use a non-prompting permission mode. Do not use
`--dangerously-skip-permissions`:

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

These templates do not supersede closer command policy. Codex workspace-write
provides an OS-enforced writable-root boundary. Claude Code's `--add-dir` and
tool permissions are not an OS filesystem sandbox: with Bash allowed, a
same-user process may discover and write other writable paths. For Claude,
staging removes explicit disclosure and the routine live write channel but
remains behavioral authority reduction unless an available platform sandbox is
applied. Record that residual or use the required environment-native wrapper;
never invent a non-portable command or claim equal enforcement.

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
