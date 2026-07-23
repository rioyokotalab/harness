# T-302 AL authentication intervention plan

## Outcome and boundaries

Reduce owner intervention for the logical `al` target as far as CSCS policy
allows without weakening the harness security standard. Preserve CSCS MFA,
signed-certificate enforcement, the Ela jump-host route, and credential
confidentiality. Use only the existing personal account.

Planning and interviewing are read-only except for this ledger. Never inspect,
print, hash, copy, generate, revoke, or overwrite an existing private key,
certificate, agent identity, or MFA value. Interactive MFA remains an owner
authority boundary.

This task does not change scheduler accounts, submit jobs, access billing
resources, replace the personal `al` account, or claim that a live connection
can survive host, network, process, or site-enforced disconnection.

## Confirmed current state

- `profiles/hosts/al.conf` declares the supported SLES 15/AArch64 Slurm target
  and the logical alias resolves to `daint.alps.cscs.ch` through the
  `alps_login` Ela jump host.
- Local has `cscs-key 1.1.0`, a current-user-owned agent socket, and the shared
  30-second/15-second keepalive SSH defaults.
- A fresh `ControlMaster=no`, `BatchMode=yes` connection to `al` currently
  succeeds. No credential inventory or contents were queried.
- The `alps_login` control master is running, while the `al` control master is
  absent. Thus the current jump transport is reusable, but every new Daint
  transport still requires a currently valid personal certificate.
- Neither alias selects an explicit certificate file or `IdentitiesOnly yes`;
  authentication currently comes from the normal agent/default identity
  selection. No identity paths or agent contents were inspected.
- CSCS requires SSH keys signed by CSCS. For personal accounts, `cscs-key sign`
  supports only `1d` or `1min`, and CSCS documents one day as the normal
  validity limit with renewal when continued access is needed.
- CSCS supports browser OIDC and headless device authorization for personal
  signing. Both still require human authentication; they change the interface,
  not the one-day validity policy.
- CSCS service accounts are explicitly intended for programmatic,
  non-interactive project access. Their API key obtains a one-minute SSH
  certificate; a fresh certificate is required for each new SSH connection,
  while an already authenticated session stays alive after certificate expiry.
- CSCS instructs users to isolate a service account under a distinct username
  and SSH key and not to set `CSCS_API_KEY` globally. A service account has
  project-resource access, not an assumed right to the owner's personal home or
  existing personal harness checkout.
- The owner confirmed that a service account can be created in the relevant
  Waldur project, but requires the unattended identity to reach selected
  personal-home content.
- The owner selected the existing `$HOME/harness` checkout and requested
  `$HOME/.*`, with the expectation that paths can be added later. The exact
  checkout is accepted for planning; the blanket dotfile glob is rejected
  because it includes credential, authentication, history, cache, snapshot,
  and unrelated private state. Hidden paths remain open as an exact allowlist.
- Read-only AL metadata shows the personal home is a current-user-owned,
  real mode-0700 directory with no named/default ACL. `$HOME/harness` is a
  current-user-owned real directory with no named/default ACL, but its
  mode-0755 bytes remain unreachable through the mode-0700 parent. The declared
  `g177` project root already has named/default ACL policy; its entries were
  counted but not exposed.
- The current `install.sh` already implements a layered account model. It
  creates account-owned discovery links for public repository guidance, rules,
  skills, and the `harness` command while resolving `.codex`, `.claude`,
  `.agents`, and `.local/bin` under the invoking account's own home. It does
  not require two identities to share their mutable client-state directories.
- The owner requires the service identity to edit the existing
  `$HOME/harness` checkout and prefers a service-owned canonical dotfile/state
  tree linked into the personal account. This freezes writable cross-identity
  repository access as a requirement, but not a blanket link of either
  account's hidden directories. The exact shared paths and concurrency
  contracts remain open.
- The owner named `.ssh/config` and `.ssh/config.d` as the first exact shared
  paths and requested symlinks. OpenSSH resolves a configuration symlink,
  checks the opened target with `fstat`, and rejects it unless the target is
  owned by the invoking user or root and is not group/world writable. It
  applies the same ownership check to every user `Include` file. Therefore one
  service-owned target cannot be the live user configuration for a different
  Unix account. Directory ACLs do not change that target UID check.
- After seeing the required second-identity, ACL, Git-ownership, SSH
  configuration, and secret-lifecycle machinery, the owner questioned whether
  eliminating daily authentication is worth the operational complexity. No
  service-account or cross-account configuration has been applied.
- The owner selected the simpler personal-account-only design. The evaluated
  service-account, cross-account ACL, shared checkout, and dotfile/state
  sharing paths are retired from T-302.

## Evidence and interpretation

Primary sources:

- CSCS SSH guide: <https://docs.cscs.ch/access/ssh/>
- CSCS service-account guide:
  <https://docs.cscs.ch/access/service-accounts/>
- CSCS MFA guide: <https://docs.cscs.ch/access/mfa/>
- CSCS storage/ACL guide: <https://docs.cscs.ch/guides/storage/>
- OpenBSD `ssh_config(5)`:
  <https://man.openbsd.org/OpenBSD-current/man5/ssh_config>
- OpenSSH portable `readconf.c`:
  <https://github.com/openssh/openssh-portable/blob/master/readconf.c>
- Local OpenSSH client behavior and `cscs-key sign --help`

Adopt:

- Keep personal MFA and signed certificates for the personal `al` alias.
- Reuse a live authenticated transport to reduce repeat prompts without
  extending or bypassing credential validity.

Reject:

- Extending a personal certificate beyond one day: unsupported by CSCS.
- Automating personal MFA, scraping browser tokens, or retaining TOTP values.
- Adding a service account, API-key lifecycle, cross-account ACLs, or shared
  mutable account state for this convenience-only objective.

Inference to test:

- Because OpenSSH multiplexes later sessions over one already authenticated
  transport, an `al` master should continue to open multiplexed sessions after
  the certificate used to establish that transport expires. This follows the
  normal SSH session model and CSCS's explicit statement that service-account
  sessions remain alive after their one-minute certificate expires. It does
  not guarantee survival after a transport break and must be tested rather
  than assumed.

## Recommended design

Use a personal-account-only design:

1. Keep `al` and `alps_login` as personal aliases with CSCS MFA.
2. Add a value-free personal session helper that:
   - reports whether the existing `al` master is usable;
   - starts one only through the existing personal authentication path;
   - never signs, renews, lists, or reads credentials automatically;
   - reports `renewal-required` rather than retrying when no valid certificate
     exists;
   - uses `ssh -O check`/`stop`, not process killing or socket unlinking.
3. Run a bounded certificate-expiry experiment across an owner-authenticated
   day boundary. Confirm that new multiplexed sessions work through the same
   master after expiry, then confirm a forced fresh connection correctly fails
   until the owner renews. Do not intentionally disrupt the only working
   transport.

The personal helper improves convenience but cannot promise permanent access.
After a real transport loss, a fresh connection still requires a valid
certificate and owner authentication.

## Decision register

| ID | Decision | Recommended choice | Alternatives and consequence | State |
| --- | --- | --- | --- | --- |
| D1 | Required outcome | Retain personal `al` and improve transport reuse/status | The earlier hybrid service-account choice was superseded by D4 | **selected: personal only** |
| D2–D3 | Service-account scope, sharing, and API-key choices | No action | Historical interview choices are retained above as evidence but removed from execution | **retired** |
| D4 | Complexity reassessment | Drop the service-account branch and implement only personal transport reuse/status, accepting CSCS reauthentication after a real transport loss | Continuing the hybrid would retain the full second-identity maintenance surface | **selected: simplify** |

The interview is complete. Execution still requires the owner's explicit
`go`.

## Frozen execution sequence after interview and explicit go

1. Reconstruct Git, this plan, current route health, `cscs-key` version, agent
   socket validity, effective SSH policy, and the selected decisions.
2. Create focused, credential-free fixtures for personal-master status/start
   behavior.
3. Implement only value-free status and native-command surfaces. Never invoke
   personal signing in an unattended path.
4. Run `git diff --check`, focused SSH tests, relevant source-contract/public
   audit tests, and `tests/test-phase1.sh`; inspect the complete diff.
5. Publish through protected `main`, then guarded-sync only clean managed
   checkouts.
6. Apply any approved non-secret SSH/helper configuration transactionally.
7. Validate fresh personal access, master reuse, failure classification, and
   clean rollback without inspecting credential data.
8. Run the bounded expiry experiment across the next certificate boundary and
   record whether multiplex reuse actually reduces the daily prompt.

## Risks, rollback, and acceptance

- A persistent master is availability optimization, not authentication
  renewal. Network, process, login-node, or site-policy termination still
  requires a valid certificate and owner MFA.
- An auto-restarting personal service could repeatedly fail after certificate
  expiry and must not be installed.
- Rollback removes only new public helper/config declarations and stops only a
  task-owned master with `ssh -O stop`. Existing sessions, keys, certificates,
  agents, and aliases remain untouched.

Acceptance requires:

1. No weakening of CSCS MFA or certificate policy.
2. No credential value or identity content enters output, Git, logs, process
   arguments, shell startup, or global environment.
3. The personal helper accurately distinguishes live reuse from
   renewal-required state without retry loops.
4. No service account, API-key handling, home ACL, cross-user checkout, or
   shared dotfile/state change is introduced.
5. Focused, full local, protected CI, live route, rollback, repository
   cleanliness, and fleet-health checks pass.

## Next action

Execution began after the owner's explicit `go`.

Checkpoint:

- Preflight reconfirmed a clean branch, `cscs-key 1.1.0`, a valid
  current-user agent socket, indefinite multiplex persistence and positive
  keepalives for both aliases, a ready `alps_login` master, and no `al` master.
- `harness al-session` now provides value-free `--status`, one
  non-interactive `--start` attempt, and managed-only graceful `--stop`.
- A mode-0600 socket-identity receipt prevents the helper from stopping an
  unrelated master. Private failure output is classified without exposure and
  exact-unlinked.
- The focused fixture covers absent, authentication-required, unavailable,
  managed, idempotent, stopped, external-owner, and unsafe-receipt states.
  ShellCheck, shell syntax, the focused test, and `git diff --check` pass.
- Live read-only status is
  `target=absent ownership=none jump=ready action=start`.
- The public repository audit, source contract, and complete
  `tests/test-phase1.sh` suite pass. The full suite ran 68 focused shards plus
  its direct safety checks; only the documented undeclared-environment native
  MPI smoke was skipped.
- Git transport and the hosting API are independently available. The complete
  branch diff passes `git diff --check`.

Next: publish through the protected-main pull-request workflow, then perform
the live start/rollback/reapply drill and record the expiry-boundary checkpoint.
