# Driver evidence

## Sandbox and baseline

Codex used `/tmp/harness-t283-round1-codex`, a no-hardlink clone detached at
`35ed1db478df4f15471fced4dfc1279f678e462d`. `git status` remained detached and
clean after the tracked focused test; the synthetic `probe-session/` was
untracked and confined to the clone.

## Commands and results

Fact: `tests/test-codex-claude-cowork-skill.sh` passed. A new Codex-driver probe
session was initialized, every template was filled with synthetic text, and all
six phases advanced successfully. After completion, an unexpected top-level
file was added; both `validation.md` and `state.json` were replaced with
symlinks to regular files in the same session. `cowork-session check --phase
complete` still exited 0 and printed `valid complete session`. This reproduces
a mismatch with `protocol.md`, which claims the validator rejects unsupported
files, and reveals that protocol file identity is not checked.

Fact: installed Claude Code 2.1.207 help lists `--print`, `--add-dir`,
`--allowedTools`, and `--permission-mode`, so every named option in the
Codex-driver mapping exists. The actual co-pilot command for this round is
`claude --print --permission-mode dontAsk --allowedTools Read Bash Write Edit
--add-dir SESSION_DIR`, with the prompt on standard input; the allowed paths and
actions are narrowed in that prompt.

Inference: same-directory symlinks did not escape this sandbox, but accepting
them makes a target-escape possible when a session file points elsewhere. An
unexpected top-level file is primarily an integrity/provenance issue. The
validator cannot prove which client wrote a file, so ownership must remain an
instructional and review gate rather than a claimed filesystem guarantee.

## Critique

Version 1 overstates validation in the reference while its focused test never
attempts adversarial file identity. The state machine tests phase order, but
not the identity of the files whose content authorizes target execution. This
undercuts the advertised durable boundary more than a missing prose detail.
The core workflow also says the co-pilot may use an explicitly named raw log,
while the reference claims all unsupported files are rejected; the intended
artifact location needs to be made explicit before enforcing a closed set.

## Reciprocal critique

Claude's strongest distinct finding is accepted and reproduced. In the Codex
sandbox, `codex exec --ask-for-approval never --help` exited 2 with `unexpected
argument '--ask-for-approval'`, while placing the global option before the
subcommand—`codex --ask-for-approval never exec --help`—exited 0 and displayed
the exec help. This is stronger than simply deleting the option: it preserves
the documented non-prompting boundary while correcting native argument order.

Claude independently reproduced the unexpected-file and symlink gaps, so there
is no conflicting result to arbitrate. I reject its recommended preference to
merely soften the unsupported-file claim: accepting unknown top-level content
weakens exchange provenance, while a closed protocol set plus an explicit real
`artifacts/` directory is small, testable, and compatible with the raw-log use
case. I accept narrowing the TODO statement rather than broadening its regex;
evidence can legitimately discuss strings such as `TODO:` and should not be
rejected after the initialized standalone placeholders are replaced.

## Proposed plan changes

1. Create an `artifacts/` directory at initialization and permit auxiliary
   prompts/logs only beneath it.
2. Require the session root, `state.json`, and every required protocol Markdown
   file to be current-user-owned regular files, never symlinks.
3. At every check, reject unexpected top-level entries; allow only the state,
   eight protocol Markdown files, and real `artifacts/` directory.
4. Add focused adversarial tests for extra files, symlinked state/evidence, and
   both driver directions, while stating accurately that authorship cannot be
   mechanically proven.

After reconciliation, the first `advance ... ready-for-execution` attempt
failed safely because Claude's wrapped prose contains an indented line beginning
`TODO marker`. This proves the v1 regex rejects more than untouched standalone
template markers. The exact fix is to match only `^\s*TODO\s*$`; the co-pilot
must repair its own evidence line before the phase can advance.
