# Repository Git policy

Read this file completely before the matching action selected by root
`AGENTS.md`.

## Collaborative Git and publication

- Ordinary Git operations inside the active task are standing-authorized,
  including fetch, branch, commit, rebase, push, task pull-request, and merge.
  They do not authorize hosting administration, workflow dispatch,
  deployments, messages, cleanup, or credential access.
- For an owner-authorized collaborative repository, fetch before work and
  again before pushing. Integrate non-conflicting contributor commits and push
  small verified branch checkpoints. Use one coherent protected pull request
  for the task; do not open or wait on a PR merely to publish a ledger
  checkpoint. Never force-push or overwrite ambiguous remote work.
- Treat authenticated Git transport and hosting API or administration as
  separate capabilities. Preflight and report them independently; successful
  fetch or push never proves settings authority.
- During hardening, a live required pull-request approval count of zero is
  owner-selected accepted policy. Do not report or change it without separate
  authorization for the exact repository and ruleset.
- Publish Harness through protected `main`. Ordinary Git authorization does
  not include workflow dispatch, deployment, repository settings, rulesets,
  billing, or organization administration.
- Local validation receipts are same-trust-root self-attestation. Protected
  hosted CI remains authoritative wherever configured.

## Authentication and native commands

- When Git or SSH needs agent authentication, require `SSH_AUTH_SOCK` to name a
  current-user-owned Unix socket. If the process socket is unusable under tmux,
  recover only from that session's exact socket and then a host-declared fixed
  socket; never use tmux's global environment. Bind recovery only to the
  intended command and otherwise fail closed. Never list, inspect, copy, or
  request SSH keys or passphrases.
- Prefer recognizable native platform commands over opaque wrappers. Keep
  portability mapping in the workflow and report the resolved native command.
