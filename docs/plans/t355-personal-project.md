# T-355 Personal project plan

## Outcome

Create an independently operated Personal project at
`/mnt/nfs-03/safe/Users/rioyokota/projects/personal` for sensitive email,
calendar, and research-budget work. It must reconstruct its own policy and
durable task state after a cold start, discover the approved Harness commands
and skills without depending on chat history, and participate in managed
Codex recovery without disturbing Harness, Students, or Swallow.

The finished system must minimize disclosure and external side effects. A
private Git repository may contain policy, schemas, tests, and metadata-safe
task records, but never credentials or plaintext email, calendar, financial,
or research-budget content.

## Scope and non-goals

In scope:

1. freeze privacy, access, data-residency, agent-authority, connector,
   collaboration, lifecycle, and recovery preferences;
2. scaffold a private repository-native project with cold-start instructions,
   a compact ledger, focused validation, and approved skill discovery;
3. create and govern a private remote repository under the ownership model
   selected by the owner;
4. add Personal as an independent managed Harness target through protected,
   tested control-plane changes;
5. activate and validate a distinct Codex root, Local pane or window, and
   phone-visible thread; and
6. invite the administrative assistant only after an account and security
   prerequisites exist, at the frozen least-privilege role.

Out of scope unless separately selected:

- changing organization-wide access merely as an incidental repository setup;
- sending email, inviting calendar attendees, spending or transferring money,
  approving budgets, or making research-administration commitments;
- importing historical sensitive data into Git;
- weakening Harness, Students, or Swallow policy or availability;
- promising host-reboot tmux resurrection when only Codex cold-start
  reconstruction has been implemented; and
- treating a repository, tmux pane, saved root, or mode-0700 directory as an
  operating-system security boundary against the same Unix user.

## Authority model

Planning may perform read-only discovery and write only this durable planning
checkpoint. Execution requires a frozen decision register and an explicit
owner `go`.

After `go`, ordinary local Git and task-scoped remote Git operations are
standing-authorized. GitHub repository creation, organization settings,
rulesets, collaborator invitations, connector authorization, connector
writes, live app-server/root operations, tmux topology changes, and phone
promotion remain distinct actions governed by the frozen plan. No credential
contents may be read or copied.

## Confirmed facts

1. The requested target path is currently absent. Its parent is a
   current-user-owned, mode-0700 NFS directory mounted with `sec=sys`.
   Creation must use umask `077` and verify ownership and mode because the
   current interactive umask is `0002`.
2. No `rioyokotalab/personal` remote currently resolves.
3. The organization currently reports base repository permission `write`.
   Its 67 members therefore inherit write access to every organization
   repository, including private repositories; a lower repository role cannot
   subtract that inherited permission.
4. The administrative assistant has no GitHub account. An outside-collaborator
   invitation cannot become usable until an account with a matching verified
   address exists; invitations expire, and an outside collaborator consumes a
   Team-plan seat.
5. Students and Swallow use repository-local instructions, task ledgers,
   project `.codex/config.toml`, static validation, private Git remotes, and
   Harness skill discovery. Students freezes copies of shared skills; Swallow
   follows absolute links to the live Harness skills.
6. The managed Local lifecycle is deliberately closed over exactly three
   targets and one `projects:0:codex` window with three horizontal panes.
   Personal cannot be made durable by an ad hoc pane alone.
7. Project configuration can override trusted-project Codex settings and can
   declare project-scoped MCP servers. Plugin installation, connector
   authorization, tool policy, and runtime permissions are separate layers;
   effective isolation must be tested from both Personal and non-Personal
   roots.
8. The presently documented Local topology does not automatically recreate
   tmux state after a host reboot. Repository cold start, Codex saved-root
   recovery, and host-reboot recovery are different acceptance claims.

## Assumptions to validate before execution

- The owner wants operational independence and strict data handling, but has
  not yet chosen whether Personal must be confidential from other agents
  running as the same Unix user.
- Email and calendar should stay in their source systems unless the owner
  selects a narrowly encrypted cache.
- Research-budget source systems, file formats, retention rules, and delegated
  authority have not yet been identified.
- The assistant should not receive connector credentials or broad repository
  write access merely because collaboration is desired.
- Sol/high, granular approvals, and disabled sandbox are likely desired for
  the Personal Codex root, but sensitive-domain action boundaries may justify
  stricter tool policy.

## Dependencies and ordering

The access architecture (D-001) precedes remote creation. The security boundary
(D-002), data residency (D-003), and connector model (D-004) precede project
configuration or authentication. Domain-specific action authority (D-005
through D-007) precedes tool-policy tests. Assistant access (D-008 and D-009)
precedes any invitation. Topology and cold-restart semantics (D-010 and D-011)
precede Harness lifecycle implementation. Skill/client choices (D-012 and
D-013) precede scaffold links. Governance, retention, source classification,
and external-data rules (D-014 through D-017) precede publication. Phone
identity (D-018) precedes live activation.

T-354 remains independently blocked. Personal creation must not occupy or
mutate either T-354 source or destination. Existing Harness, Students, and
Swallow roots and processes remain authoritative throughout implementation.

## Decision register

Each answer is recorded as `open`, `frozen`, or `superseded`, with date,
reason, consequences, and any future approval gate.

### D-001 — Repository ownership and group exclusion

Status: frozen on 2026-07-31.

Selected: create `rioyokota/personal` as a private user-owned repository.
The owner's exact answer was `1`, selecting the recommended option.

Rationale and consequences:

- group exclusion and minimal blast radius take precedence over the original
  `rioyokotalab` ownership preference;
- do not change `rioyokotalab` base permissions or any existing repository;
- organization members receive no access merely through their organization
  membership;
- verify private visibility and the exact collaborator list before and after
  the first push; and
- assistant access, if later selected, must use the capabilities available to
  a personal-account repository rather than organization roles such as
  `Triage`.

### D-002 — Security isolation from other same-user agents

Status: frozen on 2026-07-31.

Selected: retain the existing `rioyokota` Unix identity and use tested
project-policy and configuration isolation. The owner's exact answer was `2`.

Rationale and consequences:

- Personal may use the requested NFS path and integrate as another managed
  target in the existing Local lifecycle without a cross-user bridge;
- do not persist plaintext sensitive payload locally, because another process
  running as `rioyokota` remains technically able to read same-user files and
  user-level product state;
- scope Personal connectors out of the effective tool inventory for Harness,
  Students, and Swallow and test that behavior, but describe the result as an
  operational guardrail rather than an operating-system security boundary;
- connector credentials still must not be committed, logged, copied, or
  exposed to project files; and
- if technical confidentiality from same-user agents becomes required, D-002
  must be superseded by a separately planned identity/runtime migration.

### D-003 — Sensitive-data residency

Status: frozen on 2026-07-31.

Selected: keep sensitive content in its source systems and persist only
metadata-safe local records. The owner's exact answer was `1`.

Rationale and consequences:

- allowed durable records are opaque source identifiers, status, dates,
  policy, and redacted outcomes needed to resume work;
- do not persist message bodies, attachments, attendee-sensitive notes,
  calendar descriptions, budget values, exports, or generated sensitive
  drafts in the repository, project directory, caches, or validation output;
- fetch selected content just in time through the approved connector and
  leave the authoritative copy in its source system;
- do not create an encrypted Personal data vault or a backup chain for
  sensitive source content; and
- Codex thread/context retention remains a separate D-015 decision because
  source-system-only storage does not by itself control product-side history.

### D-004 — Connector and authentication boundary

Status: frozen on 2026-07-31.

Selected: use project-scoped effective configuration first, with fail-closed
cross-root validation and no automatic fallback. The owner's exact answer was
`1`.

Rationale and consequences:

- declare or enable only the connectors and tools required by Personal through
  its trusted project configuration and supported plugin policy;
- do not enable a connector globally merely to satisfy Personal;
- before live data access, compare fresh Personal, Harness, Students, and
  Swallow effective tool inventories and require Personal-only advertisement
  and enablement for the selected connectors;
- if current Codex/plugin behavior cannot satisfy that contract, stop before
  authorization and return with a revised dedicated-profile/runtime plan;
- authorize only read capabilities initially and add domain writes only under
  the later frozen D-005 through D-007 contracts; and
- under D-002 this remains a tested operational guardrail rather than
  technical same-user isolation. Never commit connector state or tokens.

### D-005 — Email authority

Status: frozen on 2026-07-31.

Selected: autonomous email analysis and in-conversation drafting, with exact
owner confirmation for every enumerated batch of mailbox writes. The owner's
exact answer was `1`.

Rationale and consequences:

- Personal may autonomously search, read, summarize, triage, classify, extract
  actions, and prepare reply or forward text in the active conversation;
- creating or updating a Gmail draft is a mailbox write, distinct from
  presenting draft text in the conversation;
- sending, forwarding, creating Gmail drafts, archiving, deleting or
  trashing, labeling or moving, unsubscribing, and changing message state
  require exact owner confirmation;
- one confirmation may cover a batch only when it enumerates the mailbox,
  threads or messages, recipients where applicable, and exact actions;
- an ambiguous write result is never retried until current mailbox state is
  read back; and
- D-003 prohibits persisting fetched bodies or generated sensitive drafts in
  project files, Git, caches, logs, or validation output.

### D-006 — Calendar authority

Status: frozen on 2026-07-31.

Selected: balanced autonomy. The owner's exact answer was `2`.

Frozen portion:

- Personal may autonomously perform bounded reads, conflict and availability
  analysis, meeting preparation, room search, and exact change drafting;
- Personal may create or remove qualifying attendee-free transparent holds and
  modify personal reminders without a second confirmation under the fixed
  rule still to be selected in D-006a;
- every event change involving attendees, resources, busy time, recurrence,
  RSVPs, notifications, cancellation, or deletion other than a qualifying
  Personal-created hold requires exact owner confirmation; and
- ambiguous writes are never retried until the event and calendar are read
  back with exact date, time, timezone, and recurrence scope.

D-006a and D-006b below complete the trigger and bound this authority.

#### D-006a — Trigger for qualifying autonomous calendar writes

Status: frozen on 2026-07-31.

Selected: allow qualifying holds or reminders to be written proactively under
bounded rules. The owner's exact answer was `2`.

Consequences:

- every proactive write must remain on the exact Personal-managed calendar
  selected during setup, be private and metadata-minimal, non-recurring,
  attendee/resource/conference-free, and send no notification;
- holds remain transparent and Personal may remove only a qualifying hold that
  it created;
- reminder changes preserve every non-reminder event field; and
- no proactive write is allowed until D-006b's numeric and reminder limits are
  frozen and implemented as testable policy.

#### D-006b — Proactive calendar limits

Status: frozen on 2026-07-31.

Selected: the recommended proactive-holds-only package. The owner's exact
answer was `1`.

Frozen limits:

- at most three active Personal-created holds;
- each begins no more than 14 days ahead and lasts no more than two hours;
- each is transparent and private, uses a generic title, and has no
  description, location, conference, guest, resource, recurrence, or
  notification;
- remove an unaccepted hold within 48 hours, with exact state readback before
  any retry; and
- do not change reminders proactively. Reminder changes are allowed without a
  second confirmation only inside an explicit owner-requested calendar task
  and while preserving all non-reminder fields.

### D-007 — Research-budget authority

Status: frozen on 2026-07-31.

Selected: autonomous analysis with exact confirmation for non-binding source
edits or report submissions and a hard prohibition on agent-executed
financial commitments. The owner's exact answer was `1`.

Rationale and consequences:

- Personal may autonomously read bounded source data, reconcile records,
  identify anomalies, model scenarios, forecast, and draft reports in the
  active conversation;
- each non-binding source-system edit or report submission requires exact
  owner confirmation that enumerates the system, records, fields, proposed
  values or redacted diff, and action;
- Personal must never approve spending, place an order, execute a purchase,
  payment, transfer, or reimbursement, change bank/payee/tax/account details,
  attest or sign, accept terms, or otherwise represent a financial
  commitment;
- ambiguous writes or submissions are never retried until authoritative state
  is read back; and
- D-003 prohibits persisting budget values, exports, reports containing
  sensitive values, or live-data test fixtures in project state.

### D-008 — Administrative-assistant access

Status: open.

Verified evidence on 2026-07-31:

- GitHub documents only two permission levels for a personal-account
  repository: owner and collaborator. A collaborator on a private repository
  necessarily receives write access; read-only and `Triage` roles are
  unavailable:
  <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/permission-levels-for-a-personal-account-repository>.
- A collaborator can be invited after creating a GitHub account:
  <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/inviting-collaborators-to-a-personal-repository>.
- Removing a collaborator revokes remote access and deletes a private fork,
  but cannot retract a local clone already made.

Recommended default: after the assistant creates an account and enables
two-factor authentication, add the exact username as a collaborator only if
the owner wants the assistant to edit metadata-safe policy or task records.
Accept that this grants repository write access, protect `main`, keep all
sensitive content and connector authorization outside GitHub, and do not add
the assistant to `rioyokotalab`.

Alternative: give no repository access and collaborate through a separately
selected metadata-safe channel. If granular read-only or `Triage` GitHub
access is essential, D-001 must be superseded by a dedicated-organization
design; `rioyokotalab` remains unsuitable under its inherited group access.

### D-009 — Collaboration content

Status: open.

Recommended default: issues and pull requests may contain metadata-safe task
descriptions, redacted decisions, and policy changes only. Sensitive source
content remains in the source system and is referenced by opaque identifier.

### D-010 — Local tmux topology

Status: open.

Recommended default: add a second window, `projects:1:personal`, with one pane.
This preserves the established equal-width three-pane operational window and
gives sensitive work a clearer visual boundary. A fourth pane or separate tmux
session remains possible but requires different monitor and recovery semantics.

### D-011 — Meaning of cold restart

Status: open.

Recommended default: require repository-policy reconstruction and
saved-root/TUI recovery after Codex restart, plus explicit post-host-reboot
recovery validation; do not promise unattended tmux resurrection unless the
owner separately selects and accepts a persistent service.

### D-012 — Harness skill coupling

Status: open.

Recommended default: read-only project discovery links to the canonical
Harness shared skills, with a pinned compatibility manifest and startup
validation. This stays current across cold starts. Frozen copies improve
repository independence but drift and increase unrelated text and maintenance.

### D-013 — Agent-client support

Status: open.

Recommended default: Codex-only at first to minimize connector exposure and
policy surfaces. Add Claude only after equivalent discovery, connector,
permission, and no-memory-leak validation exists.

### D-014 — Git governance and automation

Status: open.

Recommended default: private repository; protected `main`; linear history;
block deletion and force-push; pull-request workflow with required approvals
set to zero and owner/admin bypass preserved; no GitHub Actions. Run local
credential-free checks and store only a metadata-safe validation receipt.

### D-015 — Retention, logs, and backup

Status: open.

Frozen D-003 prohibits a local sensitive-data vault and source-content backup.
Recommended direction: no plaintext sensitive logs or transcripts in the
project; minimize local caches; redact command output; retain Git only for
policy, code, and metadata-safe records. This decision still must freeze Codex
thread/history handling and any backup needed for non-sensitive runtime state.

### D-016 — Budget sources and classification

Status: open.

Recommended default: inventory source systems and classify fields before
connecting anything. Record the system of record, owner, sensitivity,
retention, read/write interface, and authoritative reconciliation rule without
copying values into the plan.

### D-017 — External research and disclosure

Status: open.

Recommended default: allow public-web research without sending private query
context; prohibit uploading or disclosing email, calendar, budget, attachment,
or identity data to unapproved external services.

### D-018 — Phone-visible identity and notifications

Status: open.

Recommended default: one distinct saved root and phone label `Personal`,
mapped one-to-one to its exact Local pane. Require physical phone visibility
confirmation before promotion and keep sensitive notification previews
disabled where configurable.

## Execution stages

### 0. Finish PIE and freeze the contract

Ask one material question at a time, give a recommendation and consequences,
record each answer durably, reconcile dependencies, and present the complete
frozen plan. Wait for explicit `go`. Revalidate GitHub policy, target
absence/identity, Harness branch, live lifecycle, and connector capability
before any mutation.

### 1. Establish the selected access boundary

Create only the private personal-account repository
`rioyokota/personal`. Verify private visibility and the exact collaborator
list before the first push and again afterward. Do not change
`rioyokotalab`, transfer ownership, or invite the assistant at this stage.

### 2. Scaffold the private local project

Create the exact real directory with umask `077`, current-user ownership, and
mode `0700`. Initialize a clean Git repository with:

- compact `AGENTS.md`, `CLAUDE.md` only if selected, `README.md`, `.gitignore`,
  and project `.codex/config.toml`;
- `TODO.md`, `docs/tasks/`, and a small task index sufficient for cold-start
  recovery;
- narrowly routed policy modules for Git, sensitive data, email, calendar,
  budget, connectors, and external actions;
- credential-free static checks and a single local validation command; and
- no Actions workflows, sample private data, account identifiers, or secrets.

Use Sol/high only if frozen. Apply the chosen approval and sandbox policy
without silently inheriting broader connector capability.

### 3. Install skill and command discovery

Expose only the selected Harness shared skills through repository discovery,
plus Personal-specific routing skills created only where repeated expertise is
needed. Keep root instructions compact and route domain work to focused files
so unrelated skills are not read. Validate links, cold-start discovery,
read-only boundaries, and behavior after a clean process restart.

### 4. Publish and harden the remote

Create the private remote under the selected owner. Before pushing, read back
visibility, base/inherited access, teams, collaborators, fork settings, and
default branch. Push the credential-free scaffold, install the frozen
ruleset without changing approval count from zero, and confirm Actions has no
triggerable workflow. Re-read effective access afterward.

### 5. Extend Harness's managed lifecycle

In an isolated Harness feature worktree, expand the closed target model and
both launch sentinels. Update target parsing, project config, monitor, helper,
recovery controller, remote-agent selection, phone mapping, tmux topology,
documentation, and owning tests according to D-010 and D-018. Preserve exact
Harness/Students/Swallow identities and availability. Run focused tests,
`harness validate`, and `tests/test-phase1.sh`; publish through protected
`main` with no force-push or workflow dispatch.

### 6. Activate bridge-first

Freeze the live three-target topology without reading panes or transcripts.
Create a distinct provisional Personal root/runtime/pane using exact cwd and
frozen project config. Validate model, reasoning level, approval mode,
sandbox, tool inventory, connector restrictions, task-ledger reconstruction,
and absence of duplicate roots. Require separate physical phone visibility
confirmation. Promote by rename/move only after acceptance; preserve the old
three targets and never retry an ambiguous start or promotion.

### 7. Connect domains incrementally

For each selected source, authorize the minimum capability, run a synthetic or
owner-selected non-sensitive read test, then verify it is not advertised or
enabled in fresh non-Personal roots. Record that this validates the
configuration boundary selected in D-002, not technical same-user isolation.
If the cross-root contract fails, do not enable the connector or silently
switch to global configuration; pause with a dedicated-profile/runtime
proposal as required by D-004.
Enable writes only after the corresponding action contract and confirmation
UX pass. Fetch live content only just in time for an owner task, never as a
test fixture, and persist only the metadata-safe result selected in D-003.

### 8. Add the assistant

Wait for the assistant's account and frozen security prerequisite. Invite the
exact verified username once, at the frozen outside-collaborator role. Treat an
ambiguous invitation as non-retryable until read back. Verify no organization,
team, connector, secret, or sensitive-content access was added indirectly.

### 9. Acceptance and recovery rehearsal

From a clean process with no chat context, prove that Personal discovers its
instructions, task ledger, skills, command, exact root, and effective
permissions. Rehearse the selected Codex-restart and host-reboot recovery
claims. Validate repository access from authorized and unauthorized
perspectives without exposing data. Record a redacted acceptance receipt and
the exact rollback state.

## Validation and acceptance

Completion requires all of the following:

- the exact canonical path is a real current-user-owned mode-0700 directory
  and a clean repository on protected `main`;
- remote visibility and effective access match D-001; no group member inherits
  access contrary to the frozen contract;
- assistant access, if activated, is the one exact account and role selected;
- Git history, fixtures, logs, task records, and validation output contain no
  credentials or sensitive payload;
- no GitHub Actions workflow consumes hosted minutes;
- a context-free cold start finds only the routed policy and skills needed for
  the task and reconstructs the first durable next action;
- connector capabilities and writes match D-004 through D-007 and are proven
  absent elsewhere to the degree promised by D-002;
- Harness, Students, and Swallow retain their exact accepted roots, processes,
  threads, phone mappings, and healthy monitor state;
- Personal has exactly one accepted root and Local mapping, with physical
  phone confirmation before promotion;
- focused Personal checks, owning Harness tests, `harness validate`,
  `tests/test-phase1.sh`, and `git diff --check` pass on published bytes; and
- the recovery rehearsal proves only the cold-restart guarantees actually
  claimed.

## Failure handling and rollback

- Before remote creation or settings writes, record immutable owner/name,
  effective access, and exact rollback. Delete no repository as automated
  rollback; disable access and stop for owner direction if creation is wrong.
- Before any organization-wide access change, capture every affected
  repository's intended grants and prove a reversible restoration plan.
- Before connector mutation, capture only non-secret capability metadata.
  Revoke the newly added capability on failed isolation; never print tokens.
- Before live activation, capture pane/root/process/thread/phone identities.
  Reject the provisional root on failure and leave the three accepted targets
  untouched.
- Never replay a rejected prompt or retry an ambiguous app-server, GitHub,
  invitation, connector, send, calendar, or financial write.
- If interrupted, resume from `docs/tasks/T-355.md` and the first unverified
  numbered stage; do not infer completion from chat history.

## Checkpoint cadence

During the interview, checkpoint each frozen material answer. During
execution, checkpoint after access-boundary proof, local scaffold validation,
remote governance readback, protected Harness publication, Personal root
acceptance, each connector domain, assistant invitation, and final recovery
rehearsal. Each checkpoint records facts, failures, retry safety, modified
surfaces, validation, remaining authority, and one exact next action.
