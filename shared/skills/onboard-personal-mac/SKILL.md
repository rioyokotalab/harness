---
name: onboard-personal-mac
description: Safely plan, execute, validate, roll back, and checkpoint onboarding of one personal macOS host into the repository-managed harness. Use when the owner asks Codex to onboard, configure, catch up, migrate, or finish setup of a personal Mac, including a newly reachable remaining Mac; Codex must run the native commands itself rather than hand shell scripts to the owner.
---

# Onboard one personal Mac

Operate exactly one Mac per invocation. Use repository Git and `TODO.md` as the
source of truth; never infer its state from `office` or another Mac.

## Reconstruct and plan

1. Read the closest `AGENTS.md`, `TODO.md`, `docs/personal-macos.md`,
   `docs/personal-macos-config-sync.md`, and the active personal-Mac sections of
   `docs/plans/personal-macos-fleet.md` completely.
2. Read [references/stages.md](references/stages.md) completely. Resolve the
   current published commit and applicable commands from the repository; the
   reference supplies ordering and refusal gates, not frozen versions.
3. Confirm the owner named one SSH/logical host. If not, ask for only that
   identifier. Never list private profiles or inspect SSH keys to discover it.
4. Perform value-free read-only discovery through recognizable native Git,
   SSH, macOS, and harness commands. Verify transport, logical identity,
   architecture, current-user ownership, public/private checkout cleanliness,
   native agent ownership, and absence of transaction/artifact collisions.
   For a private Mac logical ID, require the repository's private Mac validator;
   never substitute a fabricated public Linux host profile.
5. Checkpoint a host-specific plan in `TODO.md` with confirmed facts,
   assumptions, exact stages, blockers, rollback, validation, and the next
   command. Ask one material decision at a time. Set `ready-for-go` only when
   no decision remains, then wait for the owner's explicit `go`.

## Apply settled owner defaults

Do not ask about these choices again. Freeze them in the one-host plan and use
them automatically after `go`, while retaining every normal plan/refusal gate:

- Restore an absent strict private companion from the repository-declared SSH
  locator. If its host declaration is absent, create the baseline-only profile
  (`macos-cli-v1`, no capability groups, no extra formulae), validate it, and
  commit/push only in the private companion without printing its revision.
- Install only missing declared bootstrap prerequisites (`gh`, `tmux`, and a
  Homebrew Python providing `tomllib`) through the bounded dry-run/apply path.
  If GitHub API authentication is needed, run the native `gh` login flow and
  pause only for the unavoidable owner device/browser step. Prefer the already
  validated SSH Git transport when HTTPS has no credential helper.
- On first SSH agreement, when a fetched private payload exists and differs
  from the live file, use `--adopt-remote`; preserve the live preimage and run
  exact rollback/reapply. This preference does not resolve a later two-sided
  divergence.
- Adopt a strict Codex local body by preserving its allowed model, reasoning,
  and project-trust entries while adding the canonical public policy.
- When canonical `.bashrc` and a reviewed managed login file contain distinct
  valid local bodies, preserve both with `--merge-distinct-profile`: retain the
  existing login-only body first and append the login-file body after removing
  only its redundant `.bashrc` loader.
- After acceptance, retain `.bash_common` without another question whenever
  any live startup reference or open handle proves it active. Quarantine and
  exact-unlink only a zero-reference, zero-handle file that passes the full
  orphan test.

Ask one question only for a new material choice outside these defaults or for
state that a transactional adapter classifies unsafe, ambiguous, or divergent.

## Execute through Codex

After `go`, run every command with Codex's terminal tools. Do not tell the
owner to paste or execute a script. Print the resolved native command before a
remote, Git, package, or harness action. Revalidate immediately before each
apply and stop on the first refusal or drift.

- Fetch and integrate public/private Git without force-push or ambiguous
  overwrite. Keep private values and revisions out of public evidence.
- Run each applicable plan before its apply. Accept only the exact reviewed
  no-block plan and record local transaction identifiers privately.
- Never automate or solicit a password, credential content, Keychain secret,
  TCC response, recovery key, or passphrase. If macOS requires authentication,
  physical interaction, a reboot, or a privacy confirmation, pause and state
  the single owner action; resume by revalidating from the last checkpoint.
- Do not broaden package scope, alter the account shell, run `chsh`, change
  Terminal preferences, enable login items, reload an active shell/tmux
  session, or authorize plugins/connectors unless separately frozen.
- Preserve machine-local startup bytes and unrelated owner settings. Use
  transactional adapters and unchanged-only rollback; never edit live managed
  markers directly.

## Validate and close

1. Exercise plan/apply, fresh-session acceptance, exact rollback, and accepted
   reapply for every newly adopted transactional component.
2. Require a ready Mac doctor, clean/equal Git state, correct discovery links,
   official native Codex ownership, managed interactive routing, native batch
   routing, isolated tmux parsing/session behavior, SSH-only private agreement,
   and absence of transfer artifacts.
3. Only after complete onboarding acceptance, execute T-273's value-free
   `.bash_common` orphan test. Quarantine recoverably, repeat doctor and fresh
   shells, restore on any regression, and exact-unlink only a proven orphan.
4. Record outcomes, transaction locality, validation, exclusions, remaining
   authority, and the next Mac boundary in `TODO.md`. Publish generic changes
   through protected CI; never commit private facts. Mark the host complete
   only after rollback/reapply and fresh-session gates pass.

On interruption, leave the Mac in its last verified state and resume from the
ledger. A failed query is unknown state, not evidence that a component is
absent.
