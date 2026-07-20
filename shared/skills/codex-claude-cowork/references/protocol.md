# Cowork protocol reference

Read this reference for every cowork session. Paths below are conceptual; use
absolute, shell-safe paths resolved for the active repository.

## State machine and files

`scripts/cowork-session` permits only this forward sequence:

```text
planning -> discussing -> ready-for-execution -> executing -> validating -> complete
```

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

The validator rejects missing headings, untouched `TODO` markers, role mismatch,
skipped phases, backward transitions, and unsupported files at completion. It
does not prove factual correctness or filesystem confinement; both agents must
inspect those independently.

## Sandbox contract

Use two independently writable sandboxes derived from the same immutable Git
commit, source archive digest, snapshot, or fixture version. Record the exact
baseline and creation method in `charter.md` and both evidence files. A sandbox
must not contain credentials or automatically inherit authority to external
systems.

Permit network, package installation, schedulers, remote writes, or external
messages only if the owner's frozen task independently authorizes them and the
experiment cannot be made local. Otherwise deny them. Keep target checkout and
exchange ownership separate: the co-pilot writes only its sandbox and
`copilot-evidence.md` (plus an explicitly named raw log if required).

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

After both independent passes, expose both evidence files and request one
reciprocal critique. Ask each client to address the strongest contrary result,
not to restate its first answer. When results differ, rerun a matched test or
record the discrepancy unresolved.

## Native client mapping

The driver must construct a task-specific prompt file that names the sandbox,
exchange directory, owned evidence file, allowed actions, forbidden targets,
baseline, and required return format. Avoid interpolating untrusted task text
into a shell command; pass it on standard input.

When Codex drives Claude, run Claude from the Claude sandbox with noninteractive
print mode. Build the narrowest reviewed `--allowedTools` list from the frozen
experiment and use a non-prompting permission mode. Do not use
`--dangerously-skip-permissions`:

```text
claude --print --permission-mode dontAsk \
  --allowedTools REVIEWED_TOOL_LIST \
  --add-dir SESSION_DIR < COPILOT_PROMPT_FILE
```

When Claude drives Codex, run ephemeral Codex in the Codex sandbox. Use
workspace-write confinement, no interactive approvals, and only the exchange
directory as an additional writable path:

```text
codex exec --ephemeral --sandbox workspace-write --ask-for-approval never \
  --cd CODEX_SANDBOX --add-dir SESSION_DIR \
  --output-last-message CODEX_LAST_MESSAGE_FILE \
  - < COPILOT_PROMPT_FILE
```

Add `--skip-git-repo-check` only for an intentionally non-Git synthetic
sandbox. If the installed client rejects a documented option, capture its
version and error, inspect current `--help`, and revise the mapping explicitly;
never silently fall back to an unconfined invocation.

These templates do not supersede closer command policy. For example, an
environment may require an OS/container sandbox around Claude or disallow a
tool that the plan requested. Record the limitation and adapt the experiment,
not the safety boundary.

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

On interruption, a new driver of either product reads the target ledger and all
exchange files, validates the recorded current phase, and resumes the first
unverified action. Role transfer requires an explicit owner instruction and a
new session because file ownership and execution authority change.

A client failure is retry-safe only when its sandbox and owned files show no
ambiguous partial action. Record the exact error, files touched, and retry
precondition. Never interpret absent output as a successful review.
