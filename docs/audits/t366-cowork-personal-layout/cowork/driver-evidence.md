# Driver evidence

## Sandbox and baseline

Codex inspected the detached sandbox `/tmp/harness-t366-driver-sandbox` at
exact baseline `3d96125514281ef071ba7ce0303185b6e3e8660e`. The sandbox was
separate from the target and live tmux state. No pane, transcript, credential,
network write, package, or target mutation was used.

## Commands and results

Eight baseline focused suites were invoked independently. Seven passed:
`test-codex-targets`, both tmux monitors, Codex recovery helper, process-
preserving projects pane layout, remote agent communication, and safety guards.
The requested `tests/test-claude-targets.sh` path exited 127 because no such
standalone suite exists; Claude target coverage is embedded in the Claude
monitor/recovery suites. This is an evidence-route correction, not a product
failure.

A synthetic three-row target profile replaced Swallow with Personal while
mapping both Harness and Personal to `@HARNESS_ROOT@`. Baseline
`harness_codex_targets.py validate-all` exited 2 with `Codex target profile is
not the closed canonical map`; `harness codex-resilient --plan --name personal
--target personal --last` independently exited 2 because Personal is outside
the managed target map. Static inspection confirms both failures are expected:
`TARGET_NAMES` is frozen to `(harness, students, swallow)`, repository values
must be unique, and the launcher resolves target solely from cwd before
comparing `--target`.

The first isolated tmux choreography attempted to move the already-index-0
window to index 0 and failed deterministically with `same index: 0`, before any
live action. A changed synthetic transaction kept the source at index 0,
created temporary windows at 91–95, joined exact pane IDs, moved only the
remaining product windows to 1 and 2, and renamed last. It produced exactly
`0:cowork:2`, `1:codex:2`, `2:claude:2`; pane IDs `%0`–`%5` and their six PIDs
were unchanged. This proves the process-preserving primitive and exposes the
same-index guard required by the implementation.

Native help confirms Claude supports `--session-id <uuid>`, exact
`--resume [value]`, `--name`, and `--remote-control [name]`. Baseline recovery
uses cwd-scoped `--continue`; that selector is ambiguous once Harness and
Personal share a cwd. Codex already has exact `--remote-session ID`, scoped
supervisor state, and watcher recovery, but its target resolver likewise needs
an explicit-target path that validates the target/cwd pair without requiring
repository uniqueness.

## Critique

The user-visible topology alone is insufficient. Merely changing profile rows
would either reject Personal or make Harness/Personal indistinguishable. Merely
moving panes would leave monitors and message selectors hard-coded to
`projects`, while merely changing Claude recovery to `--resume` without a
runtime-bound UUID would replace one ambiguity with another. A generic
directory-based map should not be stretched to infer same-root role identity.

The benchmark currently says both Personal clients must be phone-visible
before Swallow retirement. Codex remote roots already expose exact IDs through
the supervised argv. Claude's existing Harness pane does not expose its session
UUID in argv and may have enabled remote control interactively. Runtime
activation therefore needs a content-blind identity acquisition gate for
Harness Claude, or must preserve it without claiming exact restart capability.
That is the strongest unresolved point for Claude review.

## Proposed plan changes

Represent target location explicitly as window index/name plus pane index,
separate from repository. Add an explicit `repository-for-target` validation
path so Personal can intentionally share Harness cwd while implicit launches
continue to resolve Harness. Bind Claude exact session UUID in a pane-local
option established at launch or by verified metadata, and recover with exact
`--resume UUID`; never use `--continue` for same-root roles. Build a tested
plan/apply/rollback layout command that skips same-index moves and records exact
IDs. Require a content-blind runtime method and owner phone confirmation for
remote-control acceptance before retiring either Swallow pane.
