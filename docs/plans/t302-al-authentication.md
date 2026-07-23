# T-302 AL authentication intervention plan

## Outcome and boundaries

Reduce owner intervention for the logical `al` target as far as CSCS policy
allows without weakening the harness security standard. Preserve CSCS MFA,
signed-certificate enforcement, the Ela jump-host route, personal/service
identity separation, and credential confidentiality.

Planning and interviewing are read-only except for this ledger. Never inspect,
print, hash, copy, generate, revoke, or overwrite an existing private key,
certificate, API key, agent identity, or MFA value. Never store an API key in
Git, shell startup files, SSH configuration, a command line, logs, or a global
environment variable. Account creation, project membership, secret-store
selection, and interactive MFA remain separate owner authority boundaries.

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
- Use a separate CSCS service account only when the workload is truly
  unattended automation.

Reject:

- Extending a personal certificate beyond one day: unsupported by CSCS.
- Automating personal MFA, scraping browser tokens, or retaining TOTP values.
- Putting a service API key in `.bashrc`, SSH config, Git, logs, or the global
  agent environment.
- Reusing the personal alias/key for a service account or silently switching
  interactive work to the service identity.

Inference to test:

- Because OpenSSH multiplexes later sessions over one already authenticated
  transport, an `al` master should continue to open multiplexed sessions after
  the certificate used to establish that transport expires. This follows the
  normal SSH session model and CSCS's explicit statement that service-account
  sessions remain alive after their one-minute certificate expires. It does
  not guarantee survival after a transport break and must be tested rather
  than assumed.

## Recommended design

Use a hybrid design when the owner needs both interactive and unattended work:

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
4. If unattended automation is required, create isolated aliases such as
   `al-sa` and `alps-login-sa` for a CSCS service account:
   - separate username and existing dedicated key path;
   - `IdentitiesOnly yes`, `ForwardAgent no`, isolated `%C` control path;
   - obtain a one-minute certificate immediately before a new transport;
   - reuse that transport for a bounded batch of commands;
   - fail closed when the externally supplied API-key path or secret mechanism
     is unavailable.
5. Keep the API key in an owner-approved external secret surface. Pass it only
   to `cscs-key` for the intended invocation and never expose it to shell
   startup, SSH configuration, logs, or repository state.
6. If personal-home access is approved, grant only execute traversal on the
   mode-0700 home and the minimum required permissions on one selected
   automation subtree. Do not grant service-account access to `.ssh`, agent
   state, shell history, client configuration, backup state, snapshots, or the
   whole home. Prefer a separate automation checkout over concurrent writes to
   the personal checkout.
7. Use a layered account model:
   - share canonical, non-secret repository content such as guidance, rules,
     skills, scripts, and documentation from `$HOME/harness`;
   - run the existing installer as the service identity so its discovery links
     point to that canonical content but are owned by the service identity;
   - keep identity-bound and mutable state separate, including `.ssh`,
     Codex/Claude authentication and sessions, agent sockets, transaction
     state, locks, caches, temporary state, histories, and credential helpers.
   Add mutable shared state later only as a dedicated exact directory with a
   defined owner, permissions, locking contract, and rollback. Never share or
   symlink entire `.ssh`, `.codex`, `.claude`, `.config`, or `.local` trees.
8. For SSH client configuration, keep service-owned canonical source bytes but
   materialize synchronized real files separately for each account. Each live
   `.ssh/config` and included `.ssh/config.d/*` file must be owned by that
   account (or root) and not group/world writable. Validate exact source parity,
   effective `ssh -G` output for both identities, atomic replacement, and
   rollback. A shared writable symlink target is not an OpenSSH-compatible
   implementation.

The personal helper improves convenience but cannot promise permanent access.
The service-account route can remove routine human authentication for
automation, but it is a separate identity with separate access and does not
automatically preserve the personal home-based workflow.

## Decision register

| ID | Decision | Recommended choice | Alternatives and consequence | State |
| --- | --- | --- | --- | --- |
| D1 | Required outcome | Owner selected the hybrid: retain personal `al` for interactive work and add a service-account route for unattended Codex/automation | Personal transport reuse only reduces prompts until disconnect; accepting daily renewal makes no configuration change | **selected: hybrid** |
| D2 | Service-account eligibility and base scope | Owner confirmed service-account eligibility and requires selected personal-home access in addition to project resources | Project-only access was rejected because the unattended workflow needs personal-home content | **selected: personal-home required** |
| D2a | Exact personal-home subtree | Owner selected the existing `$HOME/harness` checkout; execute-only traversal on the home and no sibling access remain required | A dedicated checkout was recommended; other exact paths may be added later | **selected: existing harness** |
| D2b | Harness checkout access | Owner requires the service identity to edit the existing `$HOME/harness` checkout | This requires inherited ACLs plus Git worktree/index locking and ownership validation; read-only access was rejected | **selected: writable** |
| D2c | SSH configuration sharing | Owner selected exact paths `.ssh/config` and `.ssh/config.d`; use service-owned canonical sources with synchronized account-owned live copies | Direct symlinks to one service-owned target fail OpenSSH's resolved-owner check; root-owned symlink targets would prevent direct service-account editing | **paused pending D4** |
| D3 | API-key secret surface | If a service account is selected, use an owner-approved non-repository secret mechanism and a path/value-pass contract that the agent never reads | Global environment or shell startup storage is rejected | **conditional** |
| D4 | Complexity reassessment | Drop the service-account branch and implement only personal transport reuse/status, accepting CSCS reauthentication after a real transport loss | Continuing the hybrid can remove routine MFA for automation but retains the full second-identity maintenance surface | **open** |

Ask exactly one open decision at a time. Ask D4 next. Resume D2c and D3 only if
the owner retains the service-account branch.

## Frozen execution sequence after interview and explicit go

1. Reconstruct Git, this plan, current route health, `cscs-key` version, agent
   socket validity, effective SSH policy, and the selected decisions.
2. Create focused, credential-free fixtures for personal-master status/start
   behavior and, if selected, isolated service aliases and one-minute
   certificate refresh orchestration.
3. Implement only value-free status and native-command surfaces. Never invoke
   personal signing in an unattended path.
4. Run `git diff --check`, focused SSH tests, relevant source-contract/public
   audit tests, and `tests/test-phase1.sh`; inspect the complete diff.
5. Publish through protected `main`, then guarded-sync only clean managed
   checkouts.
6. Apply any approved non-secret SSH/helper configuration transactionally.
   Account creation and secret placement remain owner steps.
7. Validate fresh personal access, master reuse, failure classification, and
   clean rollback without inspecting credential data.
8. If selected and externally provisioned, validate the service identity only
   against its declared project scope using one non-chargeable login command.
   Do not submit scheduler work.
9. Run the bounded expiry experiment across the next certificate boundary and
   record whether multiplex reuse actually reduces the daily prompt.

## Risks, rollback, and acceptance

- A persistent master is availability optimization, not authentication
  renewal. Network, process, login-node, or site-policy termination still
  requires a valid certificate and owner MFA.
- An auto-restarting personal service could repeatedly fail after certificate
  expiry and must not be installed.
- A service API key is a high-value credential. Any ambiguous storage or
  propagation path stops execution.
- Service-account permissions and filesystem identity may differ from the
  personal account; do not infer access from successful login.
- Home ACLs can unintentionally expose unrelated personal data or cause
  cross-identity Git ownership/lock conflicts. Require exact paths,
  transactional ACL preimages, inheritance tests, and negative access checks
  for excluded siblings.
- Rollback removes only new public helper/config declarations and stops only a
  task-owned master with `ssh -O stop`. Existing sessions, keys, certificates,
  agents, and aliases remain untouched.

Acceptance requires:

1. No weakening of CSCS MFA or certificate policy.
2. No credential value or identity content enters output, Git, logs, process
   arguments, shell startup, or global environment.
3. Personal and service identities are unambiguous and cannot silently fall
   back to each other.
4. The personal helper accurately distinguishes live reuse from
   renewal-required state without retry loops.
5. Any unattended route uses a CSCS service account and refreshes only
   short-lived certificates through the approved secret surface.
6. Focused, full local, protected CI, live route, rollback, repository
   cleanliness, and fleet-health checks pass.

## Next action

Ask D4: whether to drop the service-account branch and keep only the simple
personal-account transport-reuse/status improvement.
