# Repository Git policy

Read this file completely before the matching action selected by root
`AGENTS.md`.

## Collaborative Git and publication

- Task-scoped fetch, branch, commit, rebase, push, PR, and merge are
  standing-authorized; this excludes hosting administration, workflow dispatch,
  deployments, messages, cleanup, and credentials.
- In an owner-authorized repository, fetch before work and push. Integrate
  non-conflicting commits and publish verified checkpoints. Use one protected
  task PR, not one solely for a ledger checkpoint. Never force-push or
  overwrite ambiguous remote work.
- When another linked worktree holds the base, run server-side merge with
  explicit `--repo` outside both checkouts, then fetch/fast-forward the
  canonical base. This avoids remote-success/local-checkout ambiguity.
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
