# Personal-Mac onboarding stages

Use this as an ordering checklist after reading the repository's current docs
and task ledger. A stage is applicable only when the current profile and plan
select it. On a Mac without Codex, start from the verified public checkout:

```bash
./bin/harness macos-codex-bootstrap --host HOST --apply
```

This installs missing `gh`, `tmux`, and Python-with-`tomllib` prerequisites,
places the checksum-pinned official standalone client in Homebrew's visible
bin without editing shell profiles, supplies the declared credential-free
private companion locator, and opens Codex with the complete onboarding
assignment under `approval_policy=never` and `danger-full-access`.
Thereafter always invoke `./bin/harness` from the verified public checkout.

1. **Transport and Git preflight**
   - Resolve the exact declared SSH route and logical host.
   - Verify current-user-owned agent socket for any authenticated Git/SSH
     command.
   - Fetch public and private origins independently; require clean compatible
     branches and no ambiguous contributor work.
   - Restore an absent declared companion automatically after `go`; create a
     missing host declaration as baseline-only. Use SSH Git transport when
     HTTPS lacks credentials. Pause only for native authentication interaction.
2. **Value-free aggregate plan**
   - `macos-pilot-plan --host HOST`
   - Stop at every `BLOCK`, schema mismatch, unexpected prompt, or private
     curation boundary.
3. **Public control plane**
   - `macos-control --host HOST --plan|--apply`
   - Validate Codex, Claude, agent-skill, repository, and Homebrew Bash launcher
     links without replacing an owner path.
4. **Selected Homebrew baseline**
   - `macos-homebrew --host HOST --plan|--apply`
   - Formula-only allowlist; no casks, services, taps, cleanup, removal, blanket
     upgrade, or implicit metadata refresh.
5. **Bash startup**
   - Establish the public pre/local/post layout with `macos-bash-hooks` when
     onboarding starts from an older Mac layout.
   - Converge the current layout with
     `bash-startup-unify --host HOST --plan|--apply`: `.bashrc` becomes the
     canonical owner file and `.bash_profile` the public thin loader.
   - For a valid partial-current mismatch, preserve both local bodies with
     `bash-startup-unify --host HOST --merge-distinct-profile --plan|--apply`.
   - Preserve opaque local bytes and validate login, non-login, nested, and
     noninteractive scope. Never change the native account shell.
6. **Shared tmux**
   - `tmux-config --host HOST --plan|--apply`
   - Parse without executing plugins/network/includes; do not reload an active
     server automatically.
7. **Private SSH-only configuration**
   - Existing agreement: `macos-ssh-sync --host HOST --plan|--apply`.
   - First agreement: when an existing private payload differs, default to the
     reviewed `--adopt-remote` private-to-local route. Use `--seed` only when
     the private payload is absent.
   - Legacy schema: use `macos-config-migrate` only when the current ledger and
     private profile select the migration path.
8. **Codex and Claude configuration**
   - `agent-config-catch-up --host HOST --adopt --plan|--apply` when adoption is
     selected.
   - Preserve every strict allowed local model/reasoning/trust entry; block
     rather than replace an unsupported body.
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
    - A live reference or open handle proves the file active: retain it without
      asking. Quarantine only a zero-reference, zero-handle candidate.

Every command above is run by Codex through its tools. The owner supplies only
decisions and unavoidable physical/authentication interaction.
