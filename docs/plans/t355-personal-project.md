# T-355 Personal project plan

## Outcome

Create an independently operated Personal project at
`/mnt/nfs-03/safe/Users/rioyokota/projects/personal` for sensitive email,
calendar, and research-budget work. It must reconstruct its own policy and
durable task state after a cold start, discover the approved Harness commands
and skills without depending on chat history, and be developed and operated
from Harness without becoming a managed tmux, saved-root, phone, monitor, or
recovery target.

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
4. define and validate a Harness-operated execution context that preserves the
   frozen connector and policy boundary without a persistent Personal session;
   and
5. invite the administrative assistant only after an account and security
   prerequisites exist, at the frozen least-privilege role.

Out of scope unless separately selected:

- changing organization-wide access merely as an incidental repository setup;
- sending email, inviting calendar attendees, spending or transferring money,
  approving budgets, or making research-administration commitments;
- importing historical sensitive data into Git;
- weakening Harness, Students, or Swallow policy or availability;
- adding Personal to Harness's target map, launch sentinels, tmux topology,
  saved roots, phone mapping, monitor, helper, or recovery controller;
- promising a persistent or phone-visible Personal runtime; and
- treating a repository, tmux pane, saved root, or mode-0700 directory as an
  operating-system security boundary against the same Unix user.

## Authority model

Planning may perform read-only discovery and write only this durable planning
checkpoint. Execution requires a frozen decision register and an explicit
owner `go`.

After `go`, ordinary local Git and task-scoped remote Git operations are
standing-authorized. GitHub repository creation, organization settings,
rulesets, collaborator invitations, connector authorization, connector
writes, and any bounded Personal execution-context launch remain distinct
actions governed by the frozen plan. No credential contents may be read or
copied.

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
4. The administrative assistant has no GitHub account. The selected
   personal-account repository can invite only a GitHub account as a
   write-level collaborator; there is no read-only or `Triage` role.
5. Students and Swallow use repository-local instructions, task ledgers,
   project `.codex/config.toml`, static validation, private Git remotes, and
   Harness skill discovery. Students freezes copies of shared skills; Swallow
   follows absolute links to the live Harness skills.
6. The managed Local lifecycle is deliberately closed over exactly three
   targets and one `projects:0:codex` window with three horizontal panes.
   The owner selected no Personal target or pane, so this closed lifecycle must
   remain unchanged.
7. Project configuration can override trusted-project Codex settings and can
   declare project-scoped MCP servers. Plugin installation, connector
   authorization, tool policy, and runtime permissions are separate layers;
   a Codex process rooted at Harness does not gain Personal's project
   configuration merely because a tool command addresses the Personal path.
8. The no-session selection therefore conflicts with D-004 unless sensitive
   operations run in a bounded Personal-rooted process or D-004 is explicitly
   superseded. D-010a must resolve that execution context.

## Assumptions to validate before execution

- Research-budget source systems, file formats, retention rules, and delegated
  authority have not yet been identified.
- The owner has not yet chosen whether Harness should launch a bounded
  Personal-rooted process for sensitive operations or whether D-004 should be
  superseded so the existing Harness session performs them directly.
- Any bounded Personal-rooted process would likely use Sol/high, granular
  approvals, and disabled sandbox, but its exact defaults remain open.

## Dependencies and ordering

The access architecture (D-001) precedes remote creation. The security boundary
(D-002), data residency (D-003), and connector model (D-004) precede project
configuration or authentication. Domain-specific action authority (D-005
through D-007) precedes tool-policy tests. Assistant access (D-008 and D-009)
precedes any invitation. The no-session choice (D-010) makes D-010a's
execution context and D-011's cold-restart semantics prerequisites for
connector validation. Skill/client choices (D-012 and D-013) precede scaffold
links. Governance, retention, source classification, and external-data rules
(D-014 through D-017) precede publication. D-018 is resolved as not
applicable.

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

- Personal may use the requested NFS path and be operated from Harness under
  the same user without a cross-user bridge; D-010 excludes a managed target;
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
- D-015 permits only minimum task-scoped sensitive results in the owner-facing
  Harness conversation and accepts applicable product-side retention; local
  source-system-only storage does not itself control that history.

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

Status: frozen on 2026-07-31.

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

Selected: after the assistant creates an account and enables two-factor
authentication, invite the exact verified username as a write collaborator.
The owner's exact answer was `1`.

Rationale and consequences:

- accept GitHub's personal-repository write permission because the assistant
  is the one intended exception to group exclusion;
- do not send an invitation until the owner supplies the exact username and
  confirms the two-factor-authentication prerequisite;
- protect `main` and route changes through pull requests, while recognizing
  that a collaborator may create branches and retain a local clone;
- keep repository content metadata-safe under D-003 and D-009 so repository
  access never grants source email, calendar, or budget content;
- grant no connector, credential, `rioyokotalab`, or Personal runtime access;
  and
- treat the future invitation as a separate non-retryable external write,
  deferred until its identity prerequisite is satisfied.

### D-009 — Collaboration content

Status: frozen on 2026-07-31 as a consequence of D-003 and D-008.

Selected: issues, pull requests, comments, and commits may contain
metadata-safe task descriptions, policy/code changes, checklists, opaque
source identifiers, and redacted decisions only. Sensitive email or calendar
content, attendee details, attachments, budget values, reports, exports,
credentials, and connector data remain in their source systems and must not be
pasted, uploaded, or committed. This is not a separate preference choice:
allowing sensitive collaboration content would contradict frozen D-003.

### D-010 — Local tmux topology

Status: frozen on 2026-07-31.

Selected in the owner's words: “In the same way that `~/projects/website` does
not have a dedicated session in tmux, personal does not need one. We can
continue its development from harness.”

Consequences:

- create no Personal tmux pane/window/session, saved root, phone-visible
  thread, monitor/helper target, recovery mapping, or app-server root;
- keep the accepted `projects:0:codex` three-pane topology and the exact
  Harness/Students/Swallow target map unchanged;
- perform repository development from the Harness session using explicit
  Personal paths and independent Git state;
- do not add Personal to launch sentinels as a managed target; D-010a may
  authorize one exact non-persistent path admission if a bounded process is
  selected; and
- resolve sensitive connector execution separately in D-010a because a
  Harness-rooted Codex process does not apply Personal project configuration.

#### D-010a — Sensitive-operation execution context

Status: frozen on 2026-07-31.

Selected: Harness remains the driver but launches one bounded, non-persistent
native agent process rooted at Personal for each sensitive Personal operation.
The owner selected Codex in D-010a option `1`; D-013 later expanded the
eligible native client to Codex or Claude under equivalent gates.

Consequences:

- the bounded process starts only from an explicit Harness operation with
  exact Personal cwd and task identity, reads Personal's project policy,
  ledger, skills, and effective connector configuration, then exits;
- permit at most one bounded Personal operation process across both native
  clients at a time and use an exact current-user lock so concurrent Harness
  work cannot duplicate it;
- give it no tmux pane/window/session, saved root, phone identity, monitor or
  helper role, recovery mapping, app-server root, or durable conversation
  dependency;
- add only the narrowly tested exact-path launch-sentinel admission needed for
  this non-managed process;
- write only a metadata-safe durable receipt and never persist source content
  or sensitive output under D-003;
- an ambiguous launch or connector write is never retried until exact process
  and source state are reconciled; and
- under D-015, return only the minimum task-scoped sensitive result to the
  owner-facing Harness conversation; never relay raw source dumps,
  attachments, or credentials.

### D-011 — Meaning of cold restart

Status: frozen on 2026-07-31.

Selected: split durable authority by domain without duplicating facts. The
owner's exact answer was `1`.

Rationale and consequences:

- Harness's ledger owns Personal setup/integration, exact path and repository
  identity, bounded launcher and lock contract, connector-boundary validation,
  and cross-repository blockers;
- Personal's compact ledger owns Personal operational tasks, metadata-safe
  source references, domain outcomes, and its first executable next action;
- each ledger stores an exact pointer to the other where needed, but does not
  copy the other's task details;
- after a cold Harness restart, read Harness `AGENTS.md`, `TODO.md`, and the
  routed Personal integration record, then read Personal `AGENTS.md`,
  `TODO.md`, and only its selected task record;
- each bounded child reconstructs from Personal repository state plus the
  exact current Harness request, never prior chat or child conversation state;
- update the ledger that owns a changed fact and only its pointer/acceptance
  receipt in the other repository; and
- no Personal TUI, saved root, phone, tmux, app-server, or host-reboot
  restoration is promised.

### D-012 — Harness skill coupling

Status: frozen on 2026-07-31.

Selected: expose every canonical Harness shared skill through live project
discovery links that Personal workflows treat as read-only, and use canonical
Harness commands directly. The owner's exact answer was `1`.

Rationale and consequences:

- track only discovery links and a thin compatibility manifest in Personal;
  do not copy shared `SKILL.md` contents or Harness command implementations;
- expose the skill catalog at cold start, but read a full skill only when its
  description matches the current task under the normal trigger rules;
- resolve each link to the exact canonical Harness shared-skill path and verify
  that Personal's own update or synchronization workflow never writes through
  it; D-002 means this is a workflow boundary, not same-user filesystem
  enforcement;
- invoke the installed canonical `harness` command and record its compatible
  interface/version without wrapping or vendoring it;
- fail closed with a precise Harness-path or compatibility error if a required
  skill or command is absent, rather than silently using stale copies; and
- accept that Personal intentionally depends on the canonical Harness checkout
  and receives validated Harness skill updates automatically.

### D-013 — Agent-client support

Status: frozen on 2026-07-31.

Selected: full Codex/Claude parity for bounded Personal operations. The owner's
exact answer was `2`.

Rationale and consequences:

- either native client may be the one task driver after independently passing
  exact-root, policy, skill, connector, permission, retention, and clean-exit
  validation;
- the one-at-a-time D-010a lock is shared across Codex and Claude, and a task
  names exactly one driver;
- create matching `AGENTS.md`/`CLAUDE.md`, `.agents/skills`/
  `.claude/skills`, and client-specific project configuration without
  duplicating shared policy;
- connector installation, authorization, effective tool inventory, and write
  gates are validated separately for each client; success in one never proves
  parity in the other;
- both clients obey D-003 through D-007, never rely on conversation history,
  Codex memory, or Claude auto-memory, and write only metadata-safe durable
  receipts;
- Claude uses Fable/high as primary and Opus/high only as its ordered native
  availability fallback;
- explicit collaboration, comparison, handoff, and every duration-specified
  job use the `codex-claude-cowork` protocol with one target driver, two native
  clients, an agreed benchmark before execution, isolated disposable
  sandboxes, reciprocal evidence critique, and driver-only target mutation;
  and
- cowork prompts, sandboxes, evidence, seals, receipts, and artifacts contain
  no credentials, private values, or live source content. Sensitive live
  operations remain a driver-only bounded step governed by the frozen domain
  authority.

### D-014 — Git governance and automation

Status: frozen on 2026-07-31.

Verified evidence on 2026-07-31:

- GitHub documents repository rulesets and protected branches for private
  personal-account repositories only with GitHub Pro (or a higher applicable
  plan):
  <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets>.
- The authenticated read-only user response did not expose the account plan,
  so current GitHub Pro eligibility is unknown rather than absent.

The already selected governance package is: private repository; protected
`main`; required pull request with required approvals exactly zero; linear
history; block deletion and force-push; preserve owner bypass; no required
status checks; no GitHub Actions or workflow files; and credential-free local
validation with a metadata-safe receipt.

Selected: create and publish the private repository owner-only, but make
protected `main` a hard prerequisite for the assistant invitation. The
owner's exact answer was `1`.

Consequences:

- create the owner-only private remote and push only the credential-free,
  metadata-safe scaffold;
- read back whether private branch protection/rulesets are supported and apply
  the fixed package when available;
- if unavailable, keep the repository owner-only, record the assistant
  invitation as deferred, and ask the owner to enable an eligible GitHub plan;
- never purchase, upgrade, downgrade, or otherwise alter billing;
- do not substitute an unprotected collaborator repository or weaken the
  protection package; and
- after protection is active, the assistant invitation still waits for the
  exact username and two-factor-authentication prerequisite from D-008.

### D-015 — Retention, logs, and backup

Status: frozen on 2026-07-31.

Frozen D-003 prohibits a local sensitive-data vault and source-content backup.
Official product documentation establishes:

- Codex saves local session transcripts under `CODEX_HOME` by default, but
  supports `[history] persistence = "none"`:
  <https://developers.openai.com/codex/config-advanced#history-persistence>.
- Claude Code stores plaintext local session transcripts for 30 days by
  default. For a bounded `-p` process it supports
  `--no-session-persistence`; `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` disables
  transcript writes; `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` disables auto-memory;
  and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` disables nonessential
  telemetry, error-reporting, feedback, and survey traffic:
  <https://code.claude.com/docs/en/data-usage>,
  <https://code.claude.com/docs/en/settings>, and
  <https://code.claude.com/docs/en/memory>.
- Local controls do not establish provider-side zero retention. ChatGPT chats
  remain in the account until deleted and are then scheduled for deletion
  within 30 days, subject to stated exceptions:
  <https://help.openai.com/en/articles/8983778-chat-and-file-retention-policies-in-chatgpt>.
  Anthropic documents 30-day retention for consumer Claude Code when model
  improvement is off, five years when it is on, 30 days for standard
  commercial use, and qualified-account zero-data-retention options. The
  exact OpenAI and Anthropic account types and privacy settings in use remain
  unknown and must be verified before live sensitive work.

Selected: permit only the minimum task-scoped sensitive result in the
owner-facing Harness conversation. The owner's exact answer was `1`.

Consequences:

- accept the applicable provider-side retention and require the effective
  model-improvement controls to be off for both providers before first live
  sensitive use;
- if Claude drives, accept that live source content goes to Anthropic and the
  minimum sensitive result relayed into Harness also goes to OpenAI;
- never relay raw source dumps, attachments, credentials, or unnecessarily
  broad content;
- disable child-side Codex history and Claude session persistence, prompt
  history, auto-memory, nonessential traffic, feedback, and resume behavior;
- create no plaintext sensitive logs, retained temporary output, local
  sensitive cache, or source-content backup; and
- allow Git and normal backup to contain only policy, code, and metadata-safe
  records.

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

Status: frozen as not applicable on 2026-07-31 by D-010.

Personal receives no phone-visible root, thread, notification identity, or
Local pane mapping. Existing Harness, Students, and Swallow phone mappings
remain unchanged.

## Execution stages

### 0. Finish PIE and freeze the contract

Ask one material question at a time, give a recommendation and consequences,
record each answer durably, reconcile dependencies, and present the complete
frozen plan. Wait for explicit `go`. Revalidate GitHub policy, target
absence/identity, Harness branch, unchanged three-target lifecycle, and
connector capability before any mutation.

### 1. Establish the selected access boundary

Create only the private personal-account repository
`rioyokota/personal`. Verify private visibility and the exact collaborator
list before the first push and again afterward. Do not change
`rioyokotalab`, transfer ownership, or invite the assistant at this stage.

### 2. Scaffold the private local project

Create the exact real directory with umask `077`, current-user ownership, and
mode `0700`. Initialize a clean Git repository with:

- compact `AGENTS.md`, a compact `CLAUDE.md` that imports it, `README.md`,
  `.gitignore`, and client-specific Codex and Claude project configuration;
- `TODO.md`, `docs/tasks/`, and a small task index sufficient for cold-start
  recovery;
- narrowly routed policy modules for Git, sensitive data, email, calendar,
  budget, connectors, and external actions;
- credential-free static checks and a single local validation command; and
- no Actions workflows, sample private data, account identifiers, or secrets.

Use Sol/high only if frozen. Apply the chosen approval and sandbox policy
without silently inheriting broader connector capability.

### 3. Install skill and command discovery

Expose every canonical Harness shared skill through repository discovery, plus
Personal-specific routing skills created only where repeated expertise is
needed. Keep root instructions and the catalog compact; route domain work to
focused files and read full skill instructions only on a matching trigger.
Validate links, compatibility, cold-start discovery, read-only boundaries, and
behavior after a clean process restart.

### 4. Publish and harden the remote

Create the private remote under the selected owner. Before pushing, read back
visibility, base/inherited access, teams, collaborators, fork settings, and
default branch. Push the credential-free scaffold, install the frozen
ruleset without changing approval count from zero, and confirm Actions has no
triggerable workflow. If private protection is unavailable, keep the
repository owner-only and defer only the assistant invitation. Re-read
effective access afterward.

### 5. Preserve Harness's three-target lifecycle

Do not change the target map, tmux topology, app server, saved roots, phone
mappings, monitor, helper, recovery controller, or remote-agent selector. If
D-010a selects a bounded process, add only an exact non-persistent Personal
path admission to the launch sentinels without adding a managed target. Keep
T-355 and the Personal repository ledger sufficient for the Harness session to
find the project and resume its exact next action. Run focused ledger,
sentinel, and repository-routing tests; run broader Harness validation only
for actual Harness code or policy changes.

### 6. Validate the selected non-persistent execution context

Implement D-010a without creating a managed target. Launch one bounded
Personal-rooted native process only through an explicit Harness operation and
an exact cross-client current-user lock. Independently validate Codex and
Claude exact cwd, project policy, model/config, effective tool inventory,
connector restrictions, metadata-safe handoff, and clean exit. Prove there is
no concurrent Personal process, tmux pane, saved root, phone identity, monitor
role, app-server root, or durable conversation dependency. Never replay or
blindly retry an ambiguous child launch.

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
exact verified username once, as the frozen write collaborator. Treat an
ambiguous invitation as non-retryable until read back. Verify no organization,
team, connector, secret, or sensitive-content access was added indirectly.

### 9. Acceptance and recovery rehearsal

From a clean Harness process with no chat context, prove that T-355 routes to
the exact Personal root and that the Personal ledger, instructions, approved
skills, command, and first next action are reconstructed without a Personal
session. Validate the selected bounded execution context, repository access
from authorized and unauthorized perspectives, and only the cold-restart
claims frozen in D-011. Record a redacted acceptance receipt and exact rollback
state.

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
- Personal has no managed root, tmux pane/window/session, saved root, phone
  mapping, monitor/helper role, recovery mapping, or app-server root;
- a clean Harness restart reconstructs Personal's exact path, policy, ledger,
  approved skills, and next action without chat history;
- Harness and Personal ledgers contain one owner for each fact, exact
  cross-repository pointers, and no duplicated operational task narrative;
- focused Personal checks, owning Harness tests, `harness validate`,
  `tests/test-phase1.sh`, and `git diff --check` pass where proportional to the
  surfaces actually changed; and
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
- Before any bounded Personal process, verify the three accepted targets are
  unchanged. On failure, terminate only the exact bounded process after
  revalidation and leave the three-target lifecycle untouched.
- Never replay a rejected prompt or retry an ambiguous app-server, GitHub,
  invitation, connector, send, calendar, or financial write.
- If interrupted, resume from `docs/tasks/T-355.md` and the first unverified
  numbered stage; do not infer completion from chat history.

## Checkpoint cadence

During the interview, checkpoint each frozen material answer. During
execution, checkpoint after access-boundary proof, local scaffold validation,
remote governance readback, non-persistent execution-context validation, each
connector domain, assistant invitation, and final cold-start rehearsal. Each
checkpoint records facts, failures, retry safety, modified surfaces,
validation, remaining authority, and one exact next action.
