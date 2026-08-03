# Repository Git policy

Read completely before the matching root-`AGENTS.md` action.

## Collaborative Git and publication

- Task-scoped fetch, branch, commit, rebase, push, PR, and merge are
  standing-authorized. They exclude hosting administration—including settings,
  rulesets, billing, and organization administration—plus workflow dispatch,
  deployments, messages, cleanup, and credentials. Publish Harness only through
  protected `main`.
- In an owner-authorized repository, fetch before edits and push. Integrate
  non-conflicting work and publish verified checkpoints through one protected
  task PR, never a ledger-only PR. Never force-push or overwrite ambiguity.
- When another linked worktree holds the base, run server-side merge with
  explicit `--repo` outside both checkouts, then fetch/fast-forward the
  canonical base. This avoids remote-success/local-checkout ambiguity.
- Git transport and hosting API/administration are separate capabilities;
  preflight and report each independently. Fetch or push never proves settings
  authority.
- During hardening, a live required pull-request approval count of zero is
  owner-selected accepted policy. Do not report or change it without separate
  authorization for the exact repository and ruleset.
- Local validation receipts are same-trust-root self-attestation. Protected
  hosted CI remains authoritative wherever configured.

## Authentication and native commands

- For agent authentication, `SSH_AUTH_SOCK` must name a current-user-owned Unix
  socket. If unusable under tmux, try only that session's exact socket, then a
  host-declared fixed socket—never tmux's global environment. Bind recovery to
  the intended command and otherwise fail closed. Never list, inspect, copy, or
  request SSH keys or passphrases.
- Prefer recognizable native platform commands over opaque wrappers. Keep
  portability mapping in the workflow and report the resolved native command.
