# Cowork native client commands

Read this file completely before launching either native co-pilot client. Also
read `evidence-exchange.md` before opening the client window.

Prepare a bounded task-specific prompt in a driver-only path, then stage it with
`--prompt`. The sealed prompt must name the sandbox, stage, candidate path,
allowed actions, forbidden targets, baseline, experiment/time budget, strongest
open questions, and required headings. Do not disclose the live session or
interpolate untrusted task text into a shell command.

## Codex drives Claude

Run Claude from its sandbox in noninteractive print mode. Use the narrowest
reviewed `--allowedTools` list and a non-prompting permission mode. Do not use
`--dangerously-skip-permissions`. Confirm model and effort flags in the
installed native help. Default to
`--model fable --effort high --fallback-model opus` unless the frozen
benchmark requires another supported pairing:

```text
claude --print --permission-mode dontAsk \
  --model fable --effort high --fallback-model opus \
  --allowedTools REVIEWED_TOOL_LIST \
  < STAGE_DIR/artifacts/copilot-prompt.md \
  > STAGE_DIR/candidate-copilot-evidence.md
```

For a no-tools prose critique, use the documented `--tools ""`; an empty
`--allowedTools` is not an equivalent denial:

```text
claude --print --permission-mode dontAsk \
  --model fable --effort high --fallback-model opus --tools "" \
  < STAGE_DIR/artifacts/copilot-prompt.md \
  > STAGE_DIR/candidate-copilot-evidence.md
```

The same project profile keeps Fable/high primary and Opus/high as the sole
ordered fallback when Claude is the driver. Native fallback applies only when
the primary is overloaded, unavailable, or returns another eligible server
error, and only for that turn. Authentication, billing, rate-limit,
request-size, transport, and shared session or weekly usage-limit failures are
not fallback-eligible. Preserve those failures and their reset information;
do not launch a second client or replay the prompt. Record the fallback notice
and resolved model evidence when the native output exposes them, and otherwise
do not infer that a switch occurred.

## Claude drives Codex

Run ephemeral Codex from its sandbox with workspace-write confinement and no
interactive approvals:

```text
codex --ask-for-approval never exec --ephemeral --sandbox workspace-write \
  --cd CODEX_SANDBOX \
  --output-last-message STAGE_DIR/candidate-copilot-evidence.md \
  - < STAGE_DIR/artifacts/copilot-prompt.md
```

Add `--skip-git-repo-check` only for an intentionally non-Git synthetic
sandbox. If the installed client rejects an option, capture its version and
error, inspect current native help, and revise the mapping explicitly. Never
silently fall back to an unconfined invocation.

For a long window, run the recognizable native command in the background and
use the driver-only `status`/`wait-copilot` surface from the evidence reference.
Record the exact resolved command and native options.

Codex workspace-write limits writes, not reads. Claude tool permissions and
`--add-dir` are not an OS filesystem sandbox; a same-user Bash process can
reach other writable paths. Staging removes routine path disclosure and live
write authority but does not establish equivalent confinement. Record the
residual boundary or use an available environment-native sandbox; never claim
Claude/Codex confinement equivalence.
