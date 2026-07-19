# Personal-Mac onboarding stages

Use this as an ordering checklist after reading the repository's current docs
and task ledger. A stage is applicable only when the current profile and plan
select it. Always invoke `./bin/harness` from the verified public checkout; do
not create a convenience script that hides these commands.

1. **Transport and Git preflight**
   - Resolve the exact declared SSH route and logical host.
   - Verify current-user-owned agent socket for any authenticated Git/SSH
     command.
   - Fetch public and private origins independently; require clean compatible
     branches and no ambiguous contributor work.
2. **Value-free aggregate plan**
   - `macos-pilot-plan --host HOST`
   - Stop at every `BLOCK`, schema mismatch, unexpected prompt, or private
     curation boundary.
3. **Public control plane**
   - `macos-control --host HOST --plan|--apply`
   - Validate Codex, Claude, agent-skill, launcher, and repository links without
     replacing an owner path.
4. **Selected Homebrew baseline**
   - `macos-homebrew --host HOST --plan|--apply`
   - Formula-only allowlist; no casks, services, taps, cleanup, removal, blanket
     upgrade, or implicit metadata refresh.
5. **Bash startup**
   - Use the current published Mac startup adapter (`macos-bash-hooks` or its
     documented successor) in plan/apply mode.
   - Preserve opaque local bytes and validate login, non-login, nested, and
     noninteractive scope. Never change the native account shell.
6. **Shared tmux**
   - `tmux-config --host HOST --plan|--apply`
   - Parse without executing plugins/network/includes; do not reload an active
     server automatically.
7. **Private SSH-only configuration**
   - Existing agreement: `macos-ssh-sync --host HOST --plan|--apply`.
   - First seed: use only the documented `--seed` plan/apply route after its
     separate reviewed decision.
   - Legacy schema: use `macos-config-migrate` only when the current ledger and
     private profile select the migration path.
8. **Codex and Claude configuration**
   - `agent-config-catch-up --host HOST --adopt --plan|--apply` when adoption is
     selected.
   - Keep the official installer/runtime as native Codex owner; the harness
     owns only its declared wrapper, managed prefix, and allowlisted private
     suffix reconciliation.
9. **Acceptance and drills**
   - Run `macos-doctor --host HOST`, fresh managed Bash, native/batch command
     resolution, fresh isolated tmux, and private-agreement checks.
   - Roll back each new transaction unchanged-only, repeat acceptance, reapply
     the identical plan, and repeat acceptance.
10. **Post-onboarding orphan cleanup**
    - Follow T-273 for `.bash_common`; never combine it with the onboarding
      transaction or batch it with another Mac.

Every command above is run by Codex through its tools. The owner supplies only
decisions and unavoidable physical/authentication interaction.
