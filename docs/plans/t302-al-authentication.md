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

## Evidence and interpretation

Primary sources:

- CSCS SSH guide: <https://docs.cscs.ch/access/ssh/>
- CSCS service-account guide:
  <https://docs.cscs.ch/access/service-accounts/>
- CSCS MFA guide: <https://docs.cscs.ch/access/mfa/>
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

The personal helper improves convenience but cannot promise permanent access.
The service-account route can remove routine human authentication for
automation, but it is a separate identity with separate access and does not
automatically preserve the personal home-based workflow.

## Decision register

| ID | Decision | Recommended choice | Alternatives and consequence | State |
| --- | --- | --- | --- | --- |
| D1 | Required outcome | Owner selected the hybrid: retain personal `al` for interactive work and add a service-account route for unattended Codex/automation | Personal transport reuse only reduces prompts until disconnect; accepting daily renewal makes no configuration change | **selected: hybrid** |
| D2 | Service-account eligibility and scope | If D1 selects unattended access, confirm the owner can create a service account in the relevant Waldur project and that it may access the intended project storage | Without project authorization, stop at the personal helper | **conditional** |
| D3 | API-key secret surface | If a service account is selected, use an owner-approved non-repository secret mechanism and a path/value-pass contract that the agent never reads | Global environment or shell startup storage is rejected | **conditional** |

Ask exactly one open decision at a time. D1 selected unattended access, so D2
is next; ask D3 only after service-account eligibility and storage scope are
confirmed.

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

Ask D2: whether the owner can create a service account in the relevant Waldur
project and agrees that the service identity should operate only in declared
shared project storage rather than the personal account home.
