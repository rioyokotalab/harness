# Personal harness task board

This is the authoritative resume point for the portable Codex and Claude
harness. Git retains superseded chronology and command-level evidence. Keep
only active decisions, verified prerequisites, blockers, exact next actions,
and compact historical pointers here. Next free ID: T-262.

## Current state

- Repository: local `main` is clean. The owner authorized frequent ordinary
  pushes for the now-public harness and website repositories; fetch before
  work and push, preserve contributor commits, and never force-push.
- Managed environments: `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
  `abci_login` and `alps_login` are transports; `github` and `web` are
  services. Retired `si` is not a target.
- All seven hidden-home Restic primaries and all seven independent encrypted
  generations have passed full-data checks and verified restores. Exact
  snapshot, fingerprint, aggregate restore, transaction, and cleanup evidence
  is retained in Git through `303938f` and in `docs/home-backup.md`.
- T-181's acceptance evaluation is complete. The clean pilot passed 18/18;
  the full deterministic aggregate is 69/70 with zero safety failures and one
  reviewed semantic-oracle false negative. Candidate adoption remains separate
  and was not performed. Reports are under `evaluation/results/`; frozen
  evidence is commit `ee96853`, evaluator hardening is `d26c5a3`, and the
  private run root and cleanup manifest are absent.
- Exactly one native weekly primary job is seeded on each managed node. No
  login-node cron, user timer, retention deletion, or automatic replica job
  exists. T-191 remains verification-pending until all seven first runs pass.
- Global invariants remain authoritative in `.codex/AGENTS.md`: never inspect
  credentials; never use raw recursive/bulk deletion; preserve unrelated owner
  state; print native scheduler actions; validate proportional to risk; do not
  push without explicit authority.

## Recovery priority

- **T-172 — Exhaustively re-audit Git history (complete 2026-07-15):** audited
  both repositories' reachable graphs, refs, reflogs, read-only unreachable
  objects, historical task paths, and pre-/post-incident trees. No additional
  recoverable pre-incident home content or lost ShellCheck implementation was
  found. The website's eight damaged paths were already identical to commit
  `628b53a`; harness recovery and every later delta were reconciled. Four
  harness blobs and the website unreachable graph are superseded intermediate
  work, not recovery candidates. The ignored T-11 payload and former owner
  profiles remain unavailable; do not fabricate them. Git preserves the full
  candidate table and audit evidence in the pre-compaction TODO history.

## Active tasks

### T-261 — Add low-friction interactive destructive-command safeguards

**Phase/status:** `complete`; the owner gave explicit `go`. The requested
protections against commands such as `rm -rf` are active without routine
prompts or changes to batch jobs. Implementation changed only the tracked
interactive shell layer and synchronized harness checkouts; it performed no
real destructive command or scheduler operation.

**Desired outcome:** ordinary interactive commands retain their native
arguments, output, exit status, and speed, while unusually high-blast-radius
forms fail closed before invoking the native command. Safeguards are sourced
only into interactive Bash, are never exported to child or batch shells, and
retain `command NAME ...` as the visible expert bypass. The first recommended
bundle covers recursive `rm` against `/`, an account home, or declared
persistent roots; `rsync` deletion modes; `find -delete`; broad scheduler
cancellation; and recursive `chmod`/`chown` against protected roots. Exact,
ordinary file removal, synchronization without deletion, read-only `find`,
single-job cancellation, and safe subtree permission changes remain unchanged.

**Non-goals:** do not alias destructive commands to `-i`, enable a trash can,
install a DEBUG trap, scan or record command lines, modify non-interactive
scripts, silently reinterpret user arguments, or claim that an interactive
guard replaces the existing manifest-backed `harness guarded-delete` workflow.
Do not add `noclobber`, `failglob`, or Git command interception in the default
bundle unless the owner separately chooses their real compatibility cost.

**Proposed design:** put the policy in one tracked, portable shell fragment
loaded by `shell/interactive.sh`. Thin Bash functions perform a cheap flag and
arity classification. Normal forms immediately call the native command. Risky
forms call a deterministic helper that rejects protected lexical/canonical
roots and broad selectors; legitimate recursive deletion is redirected to
`harness guarded-delete`. Refusals name the risk and the explicit safe route,
without confirmation prompts. Tests use fake native commands and disposable
fixtures only; no test executes a real destructive operation.

**Execution/validation plan after explicit go:** freeze the exact command and
flag matrix; implement the fragment/helper and focused fake-command regression;
prove interactive-only loading, no exported functions, native pass-through,
protected-root rejection, expert bypass visibility, and fail-closed malformed
input; run Bash/sh syntax, warning-level ShellCheck, focused startup tests, the
complete portable suite, diff checks, and public audit; publish through the
protected pull-request path; then use guarded fleet synchronization and fresh
shell probes on local, AB, AB2, RI, AL, RC, and T4. Stop on semantic drift,
latency in ordinary forms, dirty checkouts, or any node-specific incompatibility.

**Implementation checkpoint:** `shell/safety-guards.sh` now provides
interactive-only, shell-local wrappers for the frozen command matrix. Normal
forms immediately invoke the native command with the original argument vector;
only recursive/path-sensitive forms invoke path helpers. Protected roots include
`/`, lexical and canonical account homes, the declared persistent root, and—for
recursive removal—the current directory. Eight or more expanded immediate
children of one protected root are treated as a likely broad glob. Final
symlinks remain removable without following their referent. PBS and Slurm
wrappers allow one exact scalar/array job ID plus reviewed action options, while
rejecting multi-job and user/name/account/partition/state-style selectors.

The focused fake-native regression proves native pass-through, deliberate
`command` bypass, protected-root and broad-glob refusal, rsync/find/permission
guards, exact scheduler cancellation, broad-selector refusal, integration
through the interactive profile, and absence from child/non-interactive shells.
Bash/sh syntax, warning-level ShellCheck, remote-session/startup regression,
diff checks, and the complete `HARNESS_PORTABLE_CI=1` phase-1 suite pass. A
fresh local read-only pilot reports all selected commands as shell-local
functions and native commands in a non-interactive child.

**Recovery:** revert the tracked change and synchronize that exact revision.
Already-running shells may retain function definitions until a fresh shell or
explicit `unset -f` removes them; non-interactive jobs are unaffected throughout.

**Decision register:** D1 is resolved as the recommended core bundle:
filesystem safeguards plus broad scheduler-cancellation protection. The
filesystem-only option would leave an equally high-blast-radius interactive
surface uncovered, while the stricter option would introduce compatibility
cost through Git interception or changed overwrite/glob semantics. The owner
accepted silent native pass-through for ordinary forms, explicit refusal for
the frozen risky forms, `command NAME ...` as the visible expert bypass, local
pilot before one-node-at-a-time fleet rollout, and no change to non-interactive
jobs. The owner's separate explicit `go` authorized and completed that plan.

**Outcome:** implementation commit `3d21407` passed hosted `portable-phase1`
run `29624935519` and PR #4 squash-merged under the live zero-approval ruleset
as `accca9d`. Local, AB, AB2, RI, AL, RC, and T4 satisfy the required
Bash/realpath/getent primitives; fresh interactive probes report `rm`, `rsync`,
and `qdel` as shell-local functions and native `rm` in a non-interactive child.
Guarded fleet synchronization applied one node at a time, exactly unlinked
every bundle, and a repeat plan reports six clean idempotent `KEEP` results at
`accca9d`. No real deletion, permission change, rsync deletion, scheduler
cancellation, or non-interactive behavior was exercised or changed.

### T-260 — Disable PBS job email by default on ABCI

**Phase/status:** `complete` under the owner's explicit default-policy
request. Every agent-run PBS Pro job on `ab` or `ab2` must suppress lifecycle
mail with `-m n` or `#PBS -m n` unless the owner explicitly requests
notifications for that job. Apply the default to the native-HPC site guidance,
all tracked ABCI PBS job templates, and the harness's native weekly PBS
submission path. Do not apply PBS semantics to T4's AGE `qsub`, change any
scheduler resource/account choice, or submit a job while implementing this
policy.

**Outcome:** the native-HPC ABCI reference now requires no-mail PBS submissions
by default and permits notifications only by explicit owner request. All four
tracked ABCI PBS templates contain exactly one `#PBS -m n`; the native weekly
PBS scheduler prints and executes `qsub -m n` while T4's AGE path is unchanged.
The fake PBS regression rejects a missing actual `-m n`, focused scheduler/HPC
tests and skill validation pass, warning-level ShellCheck, the complete
portable phase-1 suite, diff checks, and the public audit pass. No live job,
scheduler state, account/resource choice, or external setting changed.

### T-259 — Restore aliases in new tmux windows

**Phase/status:** `complete` under the owner's explicit fix request. Tmux
correctly uses `/bin/bash` with an empty default
command, and the live local startup normalizer reports `.bashrc` normalized. The failure is the
exported same-shell recursion sentinel: tmux global environment contains
`HARNESS_INTERACTIVE_LOADED=1`, so every new window inherits it and
`shell/interactive.sh` returns before defining aliases. A bounded child-shell
probe reproduced `ls=file` and missing `ll`; clearing only the two harness-load
sentinels produced `ls=alias` and `ll=alias`.

**Proposed correction:** keep `HARNESS_INTERACTIVE_LOADED` and
`HARNESS_REMOTE_SESSION_LOADED` as unexported shell-local guards, remove the
stale exact tmux global sentinel, and add a regression proving a child/new-window
shell reads the aliases while duplicate sourcing in one shell remains guarded.
Do not alter unrelated tmux variables or startup content.

**Implementation checkpoint:** both recursion guards are now unexported and
remain effective within one shell. The focused regression proves the direct-SSH
guard is likewise shell-local, duplicate profile sourcing retains the aliases,
and a child interactive shell independently loads `ll`. The exact stale tmux
global value was revalidated and unset; a temporary fresh window reported
`ls=alias` and `ll=alias`, then that exact window was removed. Warning-level
ShellCheck, focused session/agent/startup suites, the complete portable phase-1
suite, diff, and public-audit gates pass. Commit and publish this as the final
direct-main checkpoint before T-258 creates strict rulesets.

**Outcome:** implementation commit `887f2c9` and corrected final pre-ruleset
payload commit `2ac2e98` are published, hosted-CI green, and synchronized to
all seven clean checkouts with transfer artifacts absent. The live tmux global
sentinel remains absent. T-259 is complete; future changes to this ledger now
exercise T-258's protected pull-request path.

### T-258 — Activate and validate strict GitHub merge controls

**Phase/status:** `complete`. Resume future work only through the protected
pull-request path. The exact tracked ruleset payloads and rollback remain
authoritative.

**Preflight checkpoint:** on 2026-07-18, harness and website are clean and
exactly synchronized with `origin/main`; stored GitHub API authentication is
usable; authenticated repository metadata reports `admin=true`, default branch
`main`, and squash/rebase merge enabled for both. Both repositories have zero
rulesets and zero active rules on `main`. Website's latest required workflow is
green. Harness run `29616864629` failed only because the evaluator loads frozen
baseline `d5b82cd` but also rejects all later live global-guidance evolution.
Repair that contradiction by requiring the exact immutable baseline revision
and loading guidance from it without comparing the live file; do not change the
corpus revision, experiment reports, scores, or baseline content.

**Owner gate:** the authenticated collaborator-permission endpoint reports
effective `read` for `rioyokota2` in both repositories. GitHub's current
required-review documentation says an approval counts only from a collaborator
with Write or Admin access. Do not activate the one-approval rulesets while
that remains true, and do not infer authority to grant repository write access.
After the CI repair is published and green, obtain explicit owner direction to
upgrade `rioyokota2` to Write on both repositories, revalidate the effective
permission, and only then create and verify the two rulesets and test PRs.

The owner explicitly authorized both Write upgrades and accepted both
repository invitations as `rioyokota2`. Authenticated post-acceptance preflight
reports effective `write` in both repositories, zero pending Write invitations,
and zero rulesets. The reviewer gate is satisfied; retain these facts through
the final pre-ruleset shell fix, hosted CI pass, and ruleset-creation preflight.

The first authenticated creation attempt stopped with HTTP 422 before creating
anything because tracked rule 3 used invalid REST type `linear_history`.
Post-failure inspection proves both repositories still have zero rulesets and
zero active `main` rules. GitHub's v2026-03-10 schema names the rule
`required_linear_history`; correct both public payloads, add an exact payload
regression, and republish/revalidate before one transactional retry. The failed
rollback handler also treated error JSON as a possible ID; on retry, assign a
rollback identity only after a successful request and strict numeric check.

**Active controls checkpoint:** corrected payload commit `2ac2e98` passed
hosted run `29620480186` and reached all seven clean checkouts before external
creation. Transactional retry created harness ruleset `19127355` and website
ruleset `19127356`; authenticated exact reads prove one active repository
ruleset and five active `main` rules each, no bypass actor, required
`portable-phase1`/`Offline checks` contexts from integration `15368`, one
approval, stale dismissal, conversation resolution, up-to-date branches,
required linear history, and deletion/non-fast-forward blocking. Create one
small test PR per repository, request `rioyokota2`, require both CI checks and
non-author approvals, then merge only through an allowed linear method.

**Outcome:** Harness PR #1 passed required `portable-phase1`, received
non-author `rioyokota2` approval on exact tested head `d2ecbcf`, and
squash-merged through ruleset `19127355` as `3c81dc5`. Website PR #1 likewise
passed required `Offline checks`, received non-author approval on exact tested
head `a4515a5`, and squash-merged through ruleset `19127356` as `162bef0`.
Authenticated post-merge reads prove both rulesets remain active and exact,
with five `main` rules and no bypass actor. Neither validation changed or
deployed a public-site file; T-258 is complete.

**Implementation checkpoint:** the evaluator now rejects any corpus baseline
other than exact `d5b82cd32e779ec154db5f2721ec5f52dfcd7752` and reads guidance
from that immutable commit without comparing today's live guidance. Complete
history remains required, and no corpus/report/score/baseline byte changed.
The phase-1 synthetic interactive-shell tests also clear inherited harness-load
sentinels so a developer's current tmux environment cannot suppress the
functions they intend to test. Evaluation-focused, remote-session,
public-audit, diff, and the complete `HARNESS_PORTABLE_CI=1` phase-1 suite all
pass locally. Publish this final pre-ruleset checkpoint, require its hosted
`portable-phase1` run to pass, then stop at the explicit collaborator-permission
gate above.

**Published checkpoint:** repair commit `bcb0cc4` is synchronized with
`origin/main`; hosted Harness CI run `29617995322` completed successfully at
that exact revision. Guarded fleet-sync applied the verified range to all six
remote checkouts, exact-unlinked every transfer artifact, and a repeat plan
reports six clean idempotent `KEEP` results. The only remaining prerequisite
before ruleset creation is explicit owner authorization for the two Write-role
upgrades described above.

**Current waiting state:** final pre-ruleset ledger commit `c57b316` is on
`origin/main`, and hosted Harness CI run `29618148063` passed at that exact
revision. AB, AB2, RI, RC, and T4 are clean at `c57b316` with transfer
artifacts absent. AL's read-only fleet preflight and one bounded native retry
both returned `Permission denied (publickey)` through the still-valid fixed
agent socket, so no AL write was attempted and AL remains clean at `bcb0cc4`.
Retrying only AL is safe after the owner restores its intended SSH identity.

### T-257 — Remove automatic Git work from shell lifecycle

**Phase/status:** `complete` under the owner's explicit request. Remove the
remote-session login fetch/fast-forward hook and the shell-exit staged
commit/push prompt. Repository synchronization and publication must instead be
explicit actions taken after inspecting the checkout. Retain the independent
top-level direct-SSH `IGNOREEOF=1` guard, the remote Codex launcher, and all
unrelated startup behavior.

**Acceptance/recovery:** a fresh top-level interactive SSH shell must leave
`exit` as Bash's builtin, set `IGNOREEOF=1`, and invoke no Git command during
startup even when a checkout and apparent agent are present. Tmux and nested
shells must remain free of the direct-SSH policy. Shell syntax, a dedicated
remote-session regression, the portable suite, and the public audit must pass
apart from any already-frozen unrelated baseline failure. Commit and push the
small tracked change, then guarded-fleet-sync the exact clean revision so
future logins on all managed nodes use it. Recovery is an ordinary revert of
that revision; already-running shells may retain their previously loaded
function definitions until replaced or explicitly unset.

**Outcome:** commit `e52a3d0` removes both automatic Git lifecycle hooks while
retaining the direct-SSH Ctrl-D guard and unrelated remote Codex/startup
behavior. The dedicated regression proves a fresh direct SSH shell reports
`builtin|1`, tmux and nested shells report `builtin|unset`, and a fake Git
binary is never invoked during startup even with a checkout and apparent
forwarded agent. Bash/sh syntax, warning-level ShellCheck, focused startup,
SSH-agent, public-audit, and fleet-sync suites pass. The aggregate suite reaches
only its pre-existing frozen evaluation-baseline mismatch before stopping.
All six clean remotes were actually at common ancestor `545e261`, so guarded
fleet-sync correctly rejected the initially assumed source and then
fast-forwarded the verified common-ancestor range. A post-apply probe briefly
observed AB2's in-flight exact transfer name; no manual cleanup was performed,
and independent metadata/HEAD checks plus a repeat plan prove all six remotes
clean at exact `e52a3d0`, every transfer artifact absent, and six idempotent
`KEEP` results.

### T-256 — Preflight GitHub API and repository-settings capability

**Phase/status:** `complete` after the owner completed GitHub CLI's browser
authentication and every bounded preflight passed. Treat API authentication
separately from the already proved
SSH transport. Never request, print, store, hash, or inspect the token; do not
use `--show-token`, write any GitHub setting, or infer write authority from a
public unauthenticated endpoint.

**Frozen preflight:** remove token environment overrides, require stored-login
status by exit code with output suppressed, make authenticated `/user` and
rate-limit requests with bodies suppressed, verify the harness repository's
authenticated `permissions.admin` boolean, read repository rulesets, and
inspect only the response's OAuth-scope header for `repo`. The last two facts
support a no-write settings-capability inference; no REST endpoint offers a
mutation-free proof that a future ruleset write will succeed.

**Acceptance/recovery:** every request must return success through the installed
v2.96.0 client; the active Git protocol remains SSH; repository-admin is true;
the OAuth scope includes `repo`; and the ruleset endpoint returns 200. Report
API read capability as proved and repository ruleset-write capability as an
inference, still subject to repository/organization policy at mutation time.
Authentication rollback is owner-only `gh auth logout`; never inspect or copy
the stored credential.

**Outcome:** with `GH_TOKEN` and `GITHUB_TOKEN` explicitly removed, stored-auth
status passed by exit code with all output suppressed. Authenticated `/user`
and rate-limit requests passed with bodies suppressed; Git protocol is `ssh`;
the harness repository returned `permissions.admin=true`; only the OAuth scope
header was filtered and it contains exact `repo`; and the v2026-03-10
repository-rulesets read returned success. GitHub API read capability is proved.
Repository ruleset-write capability is supported by authenticated repository
admin plus the OAuth grant but remains an evidence-backed inference because no
setting write was authorized or performed. T-251's eligible-reviewer gate and
inactive strict rulesets remain unchanged. No token, response body, setting,
repository, SSH state, or authentication configuration was printed or changed.

### T-255 — Install official GitHub CLI without sudo

**Phase/status:** `complete` under the owner's explicit authorization for the
user-local alternative after T-254 proved the APT route unavailable. GitHub's
live releases API and release page identify immutable v2.96.0, published
2026-07-02, as latest and as a security update. The current node is Linux
amd64/x86_64. Release asset `gh_2.96.0_linux_amd64.tar.gz` declares SHA-256
`83d5c2ccad5498f58bf6368acb1ab32588cf43ab3a4b1c301bf36328b1c8bd60`;
the checksums asset declares SHA-256
`fc046371efa250e2875208341a786a35a01717d5eebec6903e199a9b8a3f3565`.

**Frozen implementation:** require absent `~/.local/opt/gh`, exact published
archive and checksum agreement, and a safe regular archive member before
creating versioned `~/.local/opt/gh/2.96.0/bin/gh`, retaining the release
license, and atomically creating `~/.local/bin/gh`. Do not use sudo, change APT,
authenticate, inspect credentials, install extensions, or distribute to the
fleet. Keep downloads as exact mode-0600 `/tmp` files and unlink them after
validation.

**Acceptance/recovery:** the resolved command and direct versioned executable
must report 2.96.0; binary and license must be regular owner single-link files,
the command link must target the exact version, the harness path profile must
select it, repository/public-audit gates must pass, and downloads must be
absent. Rollback exact-unlinks only the command link, binary, and license, then
removes their empty directories. Browser authentication remains a separate
owner interaction and API capability stays unproved until its read-only
preflight passes without exposing the token.

**Outcome:** both release downloads matched their API digests, the published
checksums file independently named the same archive digest, and the two exact
archive members were regular with no traversal path. Owner files
`~/.local/opt/gh/2.96.0/bin/gh` (0755) and `LICENSE` (0644) plus exact command
link `~/.local/bin/gh` are single-link/versioned as declared. Both the direct
binary and resolved command report `gh version 2.96.0 (2026-07-02)`. The two
mode-0600 `/tmp` downloads were revalidated and exactly unlinked. Authentication
status is the expected unavailable exit 1; the owner must next run the
documented browser flow with `--skip-ssh-key` and then permit a credential-safe
read-only API preflight. No APT, sudo, SSH key, extension, remote node, or
credential state changed.

### T-254 — Add GitHub CLI's official Debian/Ubuntu repository

**Phase/status:** `complete-terminal` after the owner confirmed this account
has no sudo permission. The system APT-repository route cannot be executed by
this owner account and was closed without a system change. GitHub's live
official install declaration names keyring
`/etc/apt/keyrings/githubcli-archive-keyring.gpg`, source
`/etc/apt/sources.list.d/github-cli.list`, amd64 architecture, and repository
`https://cli.github.com/packages stable main`. Both system targets are absent.
This account's noninteractive sudo preflight requires a password and the owner
has no sudo permission; an agent must not request or handle credentials.

**Verified outcome:** the owner-only staging directory contained only the
mode-0600 official 4,528-byte keyring and exact one-line source candidate. The
keyring matched published SHA-256
`6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b`.
An optional GPG display created an empty 32-byte default keybox and stalled on
home storage; the exact owner file was revalidated and unlinked, and all
diagnostic processes are absent. After the owner reported no sudo capability,
both unchanged staging files were exactly unlinked and their empty directory
removed. Both `/etc` targets remain absent and no package was installed.

**Alternative boundary:** GitHub publishes official precompiled Linux amd64
release archives that require no root installation. The live releases API
currently names v2.96.0 and publishes asset digest
`83d5c2ccad5498f58bf6368acb1ab32588cf43ab3a4b1c301bf36328b1c8bd60`.
A checksum-pinned user-local installation under the harness tool layout is the
recommended replacement, but it is a new package-installation action and is
not inferred from the failed APT-repository authorization. Browser
authentication remains a further separate owner interaction.

### T-253 — Stabilize the local SSH agent across tmux and Codex

**Phase/status:** `complete` after the authorized cutover and owner identity
load. The configuration implementation and all bounded acceptance gates pass.
This already-running Codex process cannot acquire a new environment, but the
current tmux session and fresh login shells now name the fixed socket. Before
cutover, tmux session/global state named different stale sockets and the only
orphaned `ssh-agent` had no listening Unix socket. Ubuntu's packaged user unit
now owns `$XDG_RUNTIME_DIR/openssh_agent`.
GitHub transport and hosting API/settings authority remain separate capability
gates, and no identity may be listed, inspected, copied, or selected by an
agent.

**Frozen implementation:** activate the packaged `ssh-agent.service` as a
`default.target` user want; declare its fixed socket only in the tracked local
environment so remote forwarded sockets remain untouched; correct the global
recovery agreement to use process, current tmux session, then fixed declared
socket and never tmux global state; document owner-only key loading, tmux/Codex
restart, exact preflight, security constraints, and rollback; add synthetic
profile coverage; update the live current tmux session; and retire only the
revalidated inert agent after the replacement service is healthy. Codex needs
no configuration override because its documented default inherits the launch
environment.

**Acceptance/recovery:** require an active user service, a current-user-owned
fixed Unix socket, exact local export, unchanged forwarded remote export,
current tmux-session propagation, no remaining revalidated inert agent, shell
syntax, focused profile tests, `git diff --check`, public audit, and the known
portable-suite result. GitHub SSH and repository fetch pass only after the
owner loads an intended identity; API/settings capability is reported
independently. Rollback stops the service, removes its `default.target` want,
reverts the fixed export, and begins a fresh login; never terminate an agent
before its PID/owner/command and zero-listener state are revalidated.

**Outcome checkpoint (2026-07-18):** HTTPS refresh proved published
`843edf0` remains an ancestor before implementation. The packaged user service
is enabled through `default.target`, active with exactly one owner agent, and
owns fixed Unix socket `/run/user/5035/openssh_agent`. A fresh login exports
that path, the current `harness` tmux session names it, and stale tmux-global
agent variables are absent. Old PID `101652` was revalidated as the owner's
`ssh-agent`, PPID 1, with zero listening sockets immediately before exact TERM;
it is absent and the replacement stayed healthy. The focused agent-profile,
startup-normalization, public-audit, discovery-link, shell-syntax, warning-level
ShellCheck, and diff gates pass. Portable phase 1 stops only at the already
recorded T-181 frozen-evaluation mismatch after the new focused test passes.

The owner loaded the intended identity and reported the new setup working.
Independent fixed-socket preflight then received GitHub's authenticated
no-shell response with its expected exit 1, and an authenticated origin fetch
succeeded with published `843edf0` still an ancestor of local `950e63a`.
`~/run_this.sh`, `gh`, and GitHub token environment remain absent: repository
SSH transport is proved, while API/settings authority remains independently
unavailable. The pending commits can now take their required final fetch and
normal push. Do not weaken the T-181 baseline merely to turn the unrelated
portable aggregate green.

### T-252 — Reconcile the post-T-251 readiness queue

**Phase/status:** `complete`. The canonical LLM/HPC next-action queue still
described Q4/Q5/Q7/Q9 using their pre-interview gates even though T-251 had
already supplied the missing choices and executed their bounded routes. The
queue now retains the terminal local two-node MPI attempt, the resolved full-
node AB/AB2/T4 MPI decisions and outcomes, the selected framework release, and
the completed dual-architecture wheelhouse plus seven-node single-device gate
as complete evidence. At this reconciliation checkpoint Q3 remained the one
executing item through captured local job `91581` and Q10 remained dependent
on it; T-237 records the later Epyc completion and Q10 release. Q6 and Q8 retain
their named project or site-environment gates. Focused queue validation and
public-audit safety tests pass. No scheduler, package, artifact, project, or
external setting was changed by this reconciliation.

### T-251 — Resolve owner and site-support gates

**Phase/status:** `complete` at 2026-07-17 11:51 UTC. The owner's explicit `go`
resolved every owner-gated and site-support-gated issue as a verified pass, a
terminal at-most-once result, or an evidence-backed defer. The strict GitHub
rulesets remain intentionally inactive until an eligible non-author reviewer is
proved; live backup retention remains separately gated by T-191 stability and
later exact destructive approval; the deferred project environment still needs
a named workload. Any new material choice starts a new interview rather than
reopening this frozen execution authority implicitly.

**Scope and current inventory:** reconcile (1) T-194's harness/website GitHub
merge controls and deferred website CI; (2) T-196's five backup-lifecycle
choices while preserving its T-191 stabilization prerequisite; (3) T-202's AB
Mozilla application-native relocation; (4) T-203's RI cache-attribution support
escalation; (5) T-206/T-208 and Q5/Q6/Q8/Q9's framework, scientific-library,
project-environment, and immutable-artifact choices; (6) Q7's AB/AB2/T4
full-node multi-node MPI resource decision; and (7) Q4/T-236's local
no-test-only scheduler-interface block. The website checkout is currently clean
but three commits ahead of `origin/main`; preserve those unrelated commits and
do not modify or publish them during planning. Local cluster recovery and the
captured T-191/T-210/T-217/T-237 jobs remain independent execution gates, not
reasons to change these decisions.

**Authority boundaries and non-goals:** do not inspect or copy credential or
Mozilla profile contents; send no support message; change no GitHub setting;
publish no website commit; install no package; pull/build no image; submit,
cancel, resize, or reprioritize no scheduler job; run no Restic retention,
forget, prune, or replica command; and perform no deletion or profile move
during planning/interviewing. A final go authorizes only the frozen plan and
does not collapse these separate external-write, scheduler-spend, credential,
or destructive-retention boundaries.

**Planning sequence:** (1) reconcile every ledger gate with current local and
official evidence; (2) eliminate stale or discoverable questions; (3) freeze
one ordered decision register with a recommended default and explicit defer
criterion for each gate; (4) interview exactly one material decision at a
time, checkpointing every answer; (5) audit contradictions and prerequisites;
and (6) present one approval bundle with exact implementation surfaces,
support-message drafts, native scheduler/resource shapes, external settings,
rollback, and validation. Execution order will prioritize reversible
repository work and drafts, then explicit external settings/messages, then
application/environment actions, with destructive backup lifecycle work still
blocked until its independently recorded stabilization gates pass.

**Acceptance and recovery:** every named gate must end as either an approved
bounded action with prerequisites/rollback, an evidence-backed explicit
defer/close decision, or a sent support request with a durable waiting
condition. No gate becomes complete merely because execution is time-gated.
Interrupted work resumes from the single next unresolved question. Any new
scope, cost, license, project, credential, scheduler, or destructive choice
returns to interviewing rather than being inferred.

**Evidence reconciliation and decision register (eight questions):** later
T-250 evidence supersedes T-203's unknown attribution: both recreated local and
RI directories contain only the zero-byte `motd.legal-displayed` marker and
were boundedly attributed to `pam_motd`. Close T-203 by correcting its stale
phase text and documenting the native harmless owner cache; do not delete it,
weaken `HOME`, or send an unnecessary support request. Public GitHub API
inspection on 2026-07-17 reports no repository rulesets on either harness or
website. The clean website checkout is three unpublished ledger-only commits
ahead of `origin/main`; preserve and review them as one prerequisite before any
website CI change. Official evidence used for the remaining recommendations is
GitHub's ruleset documentation
<https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets>,
Mozilla's Profile Manager guidance
<https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles?style_mode=inproduct>,
PyTorch's version matrix
<https://pytorch.org/get-started/previous-versions/>, the official CUDA 13.0
wheel index <https://download.pytorch.org/whl/cu130/torch/>, NVIDIA's driver
compatibility matrix
<https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html>,
and the Restic 0.19.1 sources already recorded in
`docs/backup-lifecycle-phase2.md`.

Ask and checkpoint exactly these material choices, one at a time: D1 resolved
as deletion of AB's unused live Mozilla profile with no inspection, migration,
or fresh backup; existing historical backup snapshots remain outside this
deletion. After the final go, first revalidate the exact owner directory,
Firefox/process absence, canonical home boundary, and metadata, then use one
same-filesystem quarantine plus the guarded bulk-delete plan/exact-NEXT apply
workflow; any failed pre-delete gate restores the unchanged quarantine. D2 is
resolved as the strict staged merge-control policy: fetch and review the three
existing website ledger commits, publish them without rewriting, add and pass
the credential-free offline website CI in a separate change, then activate the
documented `main` rulesets on harness and website. Both rulesets require pull
requests, one non-author approval, stale-approval dismissal, conversation
resolution, the repository's CI check on an up-to-date branch, linear history,
and no force-push, deletion, or administrator bypass. This intentionally ends
ordinary direct pushes to `main`; validate the active public rulesets and a
test pull-request path before declaring D2 complete. Before activation, require
evidence that at least one eligible non-author reviewer exists; otherwise stop
at the passing CI/reviewed settings plan rather than make `main` unmergeable.
D3 is resolved as eight consecutive successful weekly chains and two verified
restores per node, plus a current verified independent generation, before any
retention action. After that threshold, retain 12 weekly, 12 monthly, and 3
yearly snapshots selected only by the exact weekly tag and canonical host/path;
manual, migration, and incident snapshots remain excluded. Any chain or
restore anomaly resets the affected node's stability count, and keep-all stays
effective until every prerequisite and later exact-command approval passes.
D4 is resolved as monthly structural checks, a deterministic rotating
`--read-data-subset=n/4` check each month, quarterly full-data checks, and a
quarterly full restore of the latest weekly snapshot to a new scratch target.
Also run a small sampled restore monthly, repeat structural/full-data and kept-
snapshot restore checks after prune, never restore in place, and use guarded
cleanup for restored trees. This provides deterministic complete pack coverage
each quarter without a full pack read every month. D5 is resolved as one
new immutable encrypted generation per node each month only after that cycle's
checks and restores pass, verify it before atomic promotion, and retain the
latest two verified generations. Never synchronize with deletion or replace a
verified generation before its successor passes. Scheduler recurrence remains
a separate later action after three clean manual fleet cycles. D6 is resolved
as the reference framework Python 3.12 plus PyTorch 2.12.1/CUDA 13.0 from
official wheels, one lock and two architecture-specific immutable artifacts,
followed by the seven smallest single-device gates. The owner additionally
requires a maintained baseline: treat this as the first immutable release, not
a permanent floating selection. On each relevant harness maintenance/resume,
compare official stable/security releases, licenses, both-architecture wheel
availability, and fleet driver/runtime compatibility. Build upgrades as new
candidate digests, rerun all seven bounded single-device gates, retain the
previous verified artifacts for rollback, and promote only a complete pass.
Never mutate an existing digest, use a floating tag, or silently auto-upgrade;
background monitoring or pull-request automation is not authorized by this
choice. D7 is resolved as an explicit defer: do not create a generic
scientific-library or MPI-enabled project environment until a named workload
supplies its language bindings, HDF5/NetCDF/FFTW/BLAS requirements, threading/
integer ABI, compiler, MPI ABI, and numerical contract. The existing bounded
login-surface evidence remains discovery only; this defer does not block D6's
framework artifacts or single-device gates. D8 is resolved against the
recommendation: do not wait for a project workload before running the bounded
full-node tests. After the final go, implement, validate, and submit at most
once each on AB (`gag51395`, `rt_HF`, `select=2:mpiprocs=1`), AB2
(`gah51624`, same resource), and T4 (`jh250019`, `node_f=2`), all for five
minutes at default priority with one rank per node. The local `thrp_1`, two-
node/two-rank job is also authorized, but only after `ybatch` and the nodes
recover and the captured local jobs no longer create the recorded duplicate-
load constraint; never bypass resource accounting with `/usr/bin/sbatch`.
Reuse the tracked distinct-host gate and shared executable visibility contract,
require source immutability, exact world size two on two distinct nodes,
scheduler/result zero, one reconciled native job ID, and zero job-scoped
residue. AL's existing pass is not repeated; RI/RC remain excluded by D7.
These are correctness tests only, with no performance, scaling, collective,
GPU-aware MPI, or production-fabric claim. CUDA 13.x requires driver 580 or newer and every recorded
fleet driver meets that threshold; live runtime validation remains mandatory.

The backup pilot-node choice remains deferred until comparable repository
size/duration evidence exists. The exact first live `forget` and later separate
`prune` commands remain distinct future destructive approvals after T-191's
stabilization gates; this interview cannot pre-authorize them. D6 does not
authorize a registry pull/build before the final go. D8's AB/AB2/T4 routes do
not wait on local recovery; only the local route retains that hard prerequisite.

**Frozen execution and approval bundle:** the eight-choice audit has no
remaining contradiction or owner question. A fresh explicit `go` authorizes
only this sequence: (1) set `executing`, re-fetch/revalidate both repositories,
current fleet declarations, target metadata, scheduler collisions, and
external-state prerequisites; (2) update harness documentation/status for
T-202/T-203/T-196 and implement the locked framework definitions, provenance,
bounded framework gate, and four MPI job routes with focused/full/public tests;
(3) push and fleet-sync each clean harness implementation checkpoint before
any queued source can run; (4) review and publish the website's three existing
commits without rewriting, add its credential-free offline CI separately, and
require the hosted check to pass; (5) execute AB's unused-profile removal only
through one reversible quarantine and the guarded bulk-delete plan/exact-NEXT
workflow; (6) build/pull only digest-pinned D6 inputs, create the two immutable
architecture artifacts under declared persistent roots with caches redirected,
then run the smallest seven native single-device gates independently where
each site is ready; (7) submit the newly authorized AB/AB2/T4 MPI routes
without waiting for local, and submit local only when its hard gates pass;
(8) close T-203 without a support request and record every terminal/deferred
result; and (9) only after all needed direct repository pushes are complete,
verify an eligible non-author reviewer and activate/test the two strict GitHub
rulesets. Print every native scheduler command, accept only one reconciled job
ID, monitor only captured IDs, and stop the affected route on drift.

This go does not authorize any live Restic `forget`, `prune`, retention,
scheduled check/restore, replica deletion, or replica automation: D3-D5 resolve
policy now, while their live phases remain behind measured T-191 stability and
later exact destructive approvals. It does not create a generic D7 project
environment, background framework updater, support message, credential change,
or performance run. Ruleset activation stops rather than locking the owner out
if no eligible reviewer exists. Execution checkpoint: the explicit `go` has
been received. Initial revalidation found harness exactly synchronized with
`origin/main`, the website clean and still three ledger-only commits ahead, and
the local package mount and Ybatch tools restored. All three `thrp_1` nodes are
allocated: captured numerical job `91220` remains `PENDING/Resources` and
checkpoint-restart job `91240` remains `PENDING/Priority`, with neither fixed
`v1` result present. The owner then explicitly directed relocation to an
available node. This amends only the local pending-job route: add committed,
source-contract-enforced Epyc 7502 wrappers with distinct job names and `v2`
results, validate and push them, and recheck collisions before any scheduler
mutation. Then cancel exactly `91220` and `91240` one at a time, reconcile each
as absent or terminal, exact-unlink only an unchanged regular owner-owned
single-link generated temporary script if it remains, and submit the two
replacement jobs through Ybatch's declared `epyc-7502_1` resource, one at a
time. Capture and monitor only each returned, owner/name-matched job ID; never
touch unrelated job `90939`, bypass Ybatch, change priority, or reuse a `v1`
result. That recovery is complete. The first `v2` Epyc requests, `91468` and
`91469`, exposed a task-shape conflict between an explicit one-task override
and the native resource's eight-task allocation; both remained pending, were
exactly canceled, and produced no result. The corrected `v3` wrappers preserve
the native task count. Numerical job `91472` and checkpoint/restart job `91474`
then ran on `epyc-7502`, completed with scheduler/result status zero, and
published private mode-0600 PASS results. The numerical output repeated the
frozen `-0x1.b6ap+2` value identically. Checkpoint/restart reproduced frozen
state `0x7f7cadf8669fc055`; its exact checkpoint, both generated job scripts,
and both guarded scratch trees are absent. Source contracts passed against
commit `afef3d64a93696d1a55019ac28395d94ed83e3e6`. Current next action returns
to frozen execution step 2: implement the remaining documentation/status,
framework, and four bounded MPI routes before fleet distribution.

Subsequent execution completed the repository implementation and distributed
frozen MPI source commit `774877a` to all seven clean checkouts with focused
tests and zero transfer residue. AB `2046527.pbs1` and AB2 `2046531.pbs1`
passed with scheduler/result zero, two ranks, two distinct hosts, shared
executable visibility, and guarded cleanup. Local `91483` ran once on two
Threadripper nodes but failed immediately after its passing source contract
because the previously validated `mpicc` route is no longer visible after
restart; its private result records status one and all build/job-script residue
is absent. The at-most-once rule forbids an automatic retry. T4 `8185316` later
ran once, passed its source contract, and stopped before MPI launch because the
compute environment could not locate `ylab/hpcx/2.21.0`; AGE and the private
result record status one and job-scoped residue is zero. It is likewise not
retried. Framework lock commit `6bcadab` is published;
the verified immutable x86-64 and AArch64 wheelhouses are 2.6 GiB and 2.7 GiB,
with manifest hashes `b5961b56df9301d3fc19234e5c6679ed186e5c49d1f5d1796a656fd3dcd626e6`
and `ed070849ba8da9fcf34e574a0f26e6adf510ffa7a8722201af4ecf7a64346988`.
Both wheelhouses are now independently verified and immutable at every declared
persistent root. Local `91513`, AB `2046732.pbs1`, AB2 `2046731.pbs1`, RI
`7182`, AL `4228772`, RC `211836`, and T4 `8188301` pass all seven single-device
gates with scheduler/result zero and guarded cleanup. The delayed ABCI jobs ran
without replacement when queue capacity became available. Alps cleanup
allocation `4228581` completed with scheduler status zero and reported
`TARGET_ABSENT`. Website task T-186 is complete at `e0e9686`; hosted CI run
`29567532337` passes and no deployment ran. Terminal evidence commit `9388512`
is published, and all six remote harness checkouts are clean and synchronized
to it with zero transfer-bundle residue.
The value-free framework checkpoint is published at `1785fad`. Public GitHub
organization membership exposes possible non-owner reviewers but does not
prove repository write/review eligibility, and unauthenticated collaborator
queries cannot supply that proof. Therefore the D2 precondition is not met:
both strict rulesets remain inactive exactly as frozen, with activation deferred
until an eligible non-author reviewer can be authenticated without making
`main` unmergeable.

### T-250 — Seven-node top-level project and directory cleanup

**Phase/status:** `complete` at 2026-07-17 03:48 UTC. All 51 approved deletions
are post-verified and all 102 keep decisions remain retained. RI's DNS-based
Slurm discovery is still unavailable, but the profile-declared configuration
servers provided a successful native scheduler safety gate before its final
target was processed. The task covered the request to examine every
top-level home directory on local, AB, AB2, RI, AL, RC, and T4, describe it,
interview one deletion decision at a time, and safely delete only approved
targets. Scope includes hidden directories. A top-level symlink to a directory
is not followed as one opaque deletion candidate: inventory its resolved
boundary and interview each immediate child directory separately. Regular
files and symlinks to files are out of scope.

**Privacy and authority boundaries:** discovery may collect only path/type,
owner/mode/link identity, bounded aggregate size, Git cleanliness and local
tracking state, recent metadata, and narrow project-description clues from
ordinary README/build manifests. Never open credential stores, private keys,
authentication/session databases, arbitrary datasets, or Git remote URLs.
Project names and the owner decision map remain private node-local state, not
the public repository; this ledger records only aggregate progress and safety
rules. No project, symlink, scheduler job, package, repository, or external
service changes during planning/interviewing. Existing harness, website,
control-plane, relocated application state, active-job sources/workdirs, and
backup roots receive explicit dependency checks rather than an inferred delete
recommendation.

**Planning and interview sequence:** (1) obtain a complete sorted seven-node
inventory of strict directories and directory symlinks; (2) for each symlink,
bind its lexical and canonical target and inventory only immediate child
directories; (3) classify known control/application/project roles, sizes,
last-change evidence, Git dirty/ahead/untracked state, and active scheduler or
process references without reading content; (4) deduplicate aliases that name
the same device/inode so one object is never questioned twice; (5) freeze a
stable private candidate order and ask exactly one keep/delete question at a
time, recommending keep whenever purpose, recovery, active use, or ownership
is uncertain; (6) after the last answer, audit the selected set, publish only
aggregate scope here, enter `ready-for-go`, and wait for a fresh explicit go.

**Executed deletion design:** deletion required an explicit
per-candidate `delete` decision plus the final go. Immediately before action,
revalidate canonical boundary, device/inode/owner/mode/link count, aggregate
entry/byte count, Git/process/scheduler references, and recovery choice. Move
each approved tree by exact same-filesystem atomic rename into its own retained
mode-0700 quarantine boundary; restore it if any post-rename dependency test
fails. Then create one short-lived mode-0600 guarded-delete manifest per
canonical boundary, inspect every `TARGET` and exact emitted `NEXT`, apply
within 15 minutes, verify protected anchors and target absence, and exact-clean
only empty quarantine boundaries/manifests. Never combine nodes/boundaries,
delete a symlink target through the link path, use a glob/list/loop remover, or
run raw recursive deletion. The approved sets on local, AB, AB2, RI, AL, RC,
and T4 passed fresh identity/process/scheduler checks, atomic quarantine,
dependency smokes, one guarded plan/apply pair per canonical boundary,
protected-anchor checks, and exact manifest/quarantine cleanup. Their private
journals record 5, 12, 1, 1, 3, 4, and 25 deleted targets respectively. AL's
documented login-node device identity difference was handled without bypass:
the original evidence was preserved, the sole device-ID drift was confirmed,
and fresh preflight, quarantine, plan, and apply all ran through one pinned SSH
connection. T4's guarded recount exposed substantially more cache data than
its bounded inventory estimate, but the exact owner-approved quarantine
identities still matched. RI used its declared
`SLURM_CONF_SERVER=sctl1:6817,sctl2:6817` route to query and preserve the exact
pending harness backup job before and after cleanup. Fleet `harness doctor`
validation passes on all seven nodes, with only the already-known optional
capability warnings. Every quarantine root and manifest is absent. Bounded
follow-up checks attribute the newly created local and RI `.cache` directories
to `pam_motd`: each is a distinct inode containing only the zero-byte
`motd.legal-displayed` marker. The other selected cache and legacy npm paths
remain absent.

**Inventory checkpoint:** read-only discovery completed on all seven nodes:
175 directory records resolve to 153 distinct decisions and 22 top-level
directory-symlink parents. The resolved inventory contains 12 project trees,
4 user-work/service trees, 6 previously obsolete trees, 9 regenerable cache
trees, 36 application-state trees, 23 tooling trees, 49 active control trees,
and 14 backup trees. Bounded full size walks completed for 125 candidates; 28
large/control/backup candidates were intentionally skipped or timed out rather
than expanding the probe. Twenty candidates are Git checkouts with local-only
safety facts recorded. No duplicate canonical device/inode identity remains.
The stable private inventory and decision journal are mode-0600 under the
node-local T-250 state boundary; public Git intentionally contains no project
names or individual decisions. The owner selected no new archive or backup:
approved targets relied only on temporary same-filesystem quarantine and
guarded deletion, with permanent loss accepted after quarantine purge.
Execution deleted and verified all 51 approved targets. Interview progress:
all 153 directory decisions are resolved:
51 owner-selected deletes under the no-backup policy and 102 keeps. The owner
globally selected keep for every harness-owned, harness-configured, or
harness-dependent directory; 73 remaining tooling, backup, agent, SSH,
cache-root, and control-repository entries were resolved by that rule. Shared
application configuration, credentials, the website, and unrelated application
state remain outside that bulk decision. Matching-name fleet-wide decisions
are applied only when the owner explicitly requests them. All five inventoried
directories named `.cache` are selected for deletion; active harness cache
roots are excluded. Bounded fresh-shell and workload-startup smokes checked
recreation on every node. Local and RI recreated only the PAM legal-notice
marker described above; the remaining selected cache paths and the current-node
legacy npm path remain absent. No persistent login-node watcher was installed.
All five Vim runtime directories
were resolved as keep under the harness-managed rule. All seven shared XDG
configuration roots were retained because they cannot be safely split as
top-level targets and include harness-dependent state. Four remaining GnuPG/PKI
credential stores were retained without content inspection under the mandatory
credential boundary. The active AL and RC cache roots were safety-reclassified
from regenerable cache to protected control after their live shell references
were confirmed. The final contradiction audit found no protected control,
tooling, backup, credential, harness, or website target in the delete set and
no duplicate canonical identity. Selected deletions total at least 8.61 GB of
known-size data plus five bounded-size timeouts on T4. Per-node delete counts
are local 5, AB 12, AB2 1, RI 1, AL 3, RC 4, and T4 25. The final `go` has been
received; any identity, state, process, scheduler, or dependency drift must
withhold the affected target rather than weaken a guard.

### T-191 — Scheduler-native weekly primary snapshots

**Status:** verification-pending after the explicit owner `proceed`. All seven
final smokes passed, and exactly one production job per node is present for
Sunday 2026-07-19. Idempotent reseeding kept every captured ID and created no
duplicate. Monitor each first snapshot and its strictly future successor; valid
queue delay is healthy. RI's forced one-GB200 allocation is owner-accepted.

**Verified prerequisite:** every primary and independent generation has a
successful full-data check and verified restore. Recurrence covers primary
snapshots only; independent replica generations remain manual.

**Frozen global decisions (D1-D10, D27-D28):** run weekly and independently on
each node through its native batch scheduler. Do not use login-node cron,
`systemd` timers, central SSH, AL `scrontab`, sleeping processes, or automatic
logout work. Maintain exactly one future scheduler job per node. When admitted,
the job validates its identity, submits/adopts and records exactly one
successor, then runs one incremental snapshot. Valid pending/held state is
healthy even after eligibility; queue delay is not a failure and must never
create a duplicate. A job delayed past one or more Sundays runs one snapshot,
does not backfill, and selects the earliest designated Sunday strictly after
its actual start. Keep all snapshots initially: no `forget`, `prune`, retention
deletion, automatic replica, or scheduled full-data check. Record private local
status and warn only on a later interactive login; healthy and non-interactive
sessions remain silent.

**Frozen resource and eligibility matrix (D11-D26):** times are scheduler-local
eligibility points, not promised starts.

| Host | Native request | Sunday eligibility |
|---|---|---|
| `local` | `ybatch`; default account; `thrp_1`; 30 min; default priority; evidence-only fallback `epyc-7502_1` | 00:30 JST |
| `ab` | PBS `-P gag51395`; `rt_HC`; `select=1`; 30 min; default Spot priority | 01:00 JST |
| `ab2` | PBS `-P gah51624`; `rt_HC`; `select=1`; 30 min; default Spot priority | 01:30 JST |
| `ri` | Slurm `-A rkp00015`, default `gpu`; one CPU and explicit `--gres=none`, but site policy still injects one GB200/400 GiB; 30 min | 02:00 JST |
| `rc` | Slurm `-A cloud-users -p r340`; one node/task/CPU; no GPU; 30 min | 02:30 JST |
| `t4` | AGE `-g jh250019 -l cpu_4=1 -l h_rt=00:30:00`; omit `-p` | 03:00 JST |
| `al` | Slurm `-A g177-1 -p normal`; one node/task/CPU; no GPU; 30 min | 01:00 Europe/Zurich local time |

Live read-only discovery on 2026-07-16 established the account/resource facts.
Notable tradeoffs: AL `normal` is whole-node exclusive but was explicitly
chosen; RC `r340` is shared x86-64 and matches the managed Restic binary; T4
`cpu_4` is its smallest documented CPU-only type and uses default priority;
`local` `thrp_1` requests no GPU despite GPU-bearing physical nodes. Every
claim is still acceptance-gated by its site's live smoke.

**Implementation plan:**

1. Add strict `profiles/restic-schedules.tsv` declarations for the exact seven
   rows above. Validate unique known hosts, safe fields, timezone, scheduler,
   account/group, resource, walltime, and priority schemas.
2. Add `harness restic-primary`: reuse the reviewed hidden-home algorithm from
   `docs/home-backup.md`; validate the repository row and password-file
   type/owner/mode without reading it; privately enumerate every top-level
   hidden path plus only approved relocated targets; run the managed Restic
   command with the password by pathname; exact-unlink the one manifest.
   Weekly tag: `harness-hidden-home-weekly`.
3. Add `harness restic-schedule` with read-only `plan`, `status`, and `warning`,
   plus explicit `smoke`, `seed`, allocated `run`, and exact-ID `disable`.
   Store mode-0600 atomic state below mode-0700
   `~/.local/state/harness/restic-chain/`; retain bounded, value-limited
   diagnostics and never log hidden-home contents or credential values.
4. Generate native jobs: Slurm `sbatch --begin` on RI/RC/AL; embedded
   `#SBATCH --begin` with `ybatch` on `local`; PBS `qsub -a` on AB/AB2; AGE
   `qsub -a` on T4. Print the resolved `NATIVE` command before every write.
5. Close the submit/record crash window with deterministic chain/host/
   eligibility job names. Query before submission and after ambiguous output:
   adopt exactly one matching owner/name/time job, submit only when none exists,
   and stop/warn on duplicates. Validate the running ID/name before any work;
   successor persistence precedes the snapshot.
6. Add a bounded call in `shell/interactive.sh`. It is silent when healthy or
   unseeded, performs no scheduler write/network/authentication/prompt, and may
   query only the captured local scheduler ID. Preserve silence in
   non-interactive, batch, nested, and ordinary SSH-command sessions.
7. Add fake-scheduler and source-manifest tests covering hostile output, ID
   parsing, modes/owners/symlinks, successor ordering, concurrency, ambiguous
   acceptance, queue delays, no-backfill, JST and Europe/Zurich DST boundaries,
   warning clearing, bounded history, exact disable, and absence of destructive,
   retention, replica, or secret-reading paths. Run syntax, warning-level
   ShellCheck, focused suites, `git diff --check`, guarded-delete tests, and
   `tests/test-phase1.sh`.
8. Commit only reviewed harness files locally; do not push. Revalidate every
   checkout is clean and logically identified, distribute the exact revision
   using the established credential-free Git-bundle/fast-forward route, and
   rerun plan/profile/PTY/non-interactive/status gates on all seven nodes.
9. Run bounded native smokes concurrently where policies permit. Each real
   allocation validates architecture, paths, password metadata only, managed
   Restic read-only access, time calculation, and one distant deferred test
   successor; it performs no snapshot. Cancel only that exact successor and
   prove it absent. A compute-side resubmission failure returns to the D9
   fallback interview; do not improvise a login trigger.
10. After all seven smokes and cancellation proofs pass, seed exactly one real
    future job per node, prove no duplicate exists, and monitor each first
    admitted snapshot plus strictly future successor. Queue delay is allowed.
    Keep T-191 verification-pending until all seven pass, with progress updates
    at least every five minutes during active monitoring.

**Stop and rollback:** dirty checkout, credential-path anomaly, unknown
resource, architecture mismatch, duplicate/ambiguous job, inaccessible
repository, failed smoke, or unexpected scheduler semantics halts only that
node without weakening checks. Before seeding there is no scheduler rollback.
After seeding, `disable` revalidates, prints, cancels, and verifies absence of
only the captured future ID, then retains private evidence. It never searches
broadly or deletes state.

**Execution checkpoint:** owner authority is limited to this frozen T-191 plan.
Current working set starts with `TODO.md`, `profiles/restic-schedules.tsv`,
`bin/harness`, new `libexec/harness-restic-primary` and
`libexec/harness-restic-schedule`, `shell/interactive.sh`, focused tests, and
the backup documentation. Next action is local implementation and validation;
do not submit a scheduler job before that checkpoint passes.

**Initial execution audit (2026-07-16):** exact-name process checks report zero
Restic processes on every node. Native scheduler listings filtered only to the
reserved `hr-*` namespace report no matching job on `local`, RI, AL, RC, AB,
AB2, or T4. X11-forwarding warnings on RI/RC were transport noise; every probe
otherwise completed. It is safe to implement locally; re-run this audit before
the first smoke because this checkpoint does not reserve scheduler state.

**Local implementation checkpoint:** the strict seven-row schedule, shared
primary helper, scheduler controller, interactive warning, documentation, and
focused fake-scheduler suite are implemented in the declared working set.
Syntax, warning-level ShellCheck for new scripts, `git diff --check`, the
focused suite, and guarded-delete suite pass. The first complete phase-1 run
reached the pre-existing environment gate and stopped exactly at
`tests/test-phase1.sh: 365: mpicc: not found`: the process-local module table
again claims OpenMPI is loaded without exporting its compiler. No scheduler
write occurred. A retry is safe only after unloading and reloading the same
declared `openmpi/5.0-cuda-12.8` module in the retry shell.

The reviewed retry and the later strengthened state-machine rerun both pass
the complete phase-1 suite with only the documented login-node CUDA-library
warnings. The focused suite now proves smoke-gated seeding,
`verified-disabled` successor cancellation, status tracking of the future
smoke successor, exact singleton/idempotent seed and disable across fake
`ybatch`/Slurm/PBS/AGE, hostile output refusal, successor-first weekly order,
JST/Europe-Zurich boundary behavior, private warning state, manifest coverage,
and relocated-target rejection. Read-only `plan`/`next` succeeds for all seven
declarations after fixing portable planning so it does not require a remote
site's scheduler directories locally. Next action: inspect and commit only the
declared implementation files locally; do not push.

**Rollout and pre-smoke checkpoint:** local implementation commit
`852b84bb753bf590a55353f96de71fba3b7b77d5` is clean and unpushed. A
43,655-byte credential-free bundle with SHA-256
`f4ca151b7007316d361aae5ad009759b62fda109d4361e0a37b8d848581c9c72`
fast-forwarded clean AB, RI, AL, RC, and T4 checkouts from `df72e17` and AB2
from `303938f` to that exact commit. Every remote bundle and the local bundle
are exact-unlinked and absent. All seven nodes then passed exact-revision and
clean-worktree checks, new-script syntax, schedule `plan`/`next`, absent chain
and smoke state, doctor, and managed Restic read-only repository access. Real
PTY-backed interactive shells remained warning-silent while healthy/unseeded,
and non-interactive shells remained silent on every node. AB2's first shared
validation connection outlived the result window but left no Restic process;
its bounded solo retry passed the full gate. No scheduler write has yet run.
Next action: commit this evidence locally, re-audit the reserved job namespace,
then submit the seven bounded smokes with the printed native commands.

**First live-smoke checkpoint:** the reserved namespace/process re-audit was
clean. AB parent `2043932.pbs1`, AB2 `2043931.pbs1`, AL `4220993`, RC
`210790`, and T4 `8175288` were accepted with their exact printed native
requests. AL and RC completed read-only Restic checks, created exactly one
Sunday successor (`4220994` and `210791`), and exact `scancel` plus absence
verification left both smoke states `verified-disabled`. AB/AB2 remain valid
queued parents and were not duplicated. Local failed before state adoption:
`ybatch` injected `thrp_1` directives after `set -eu`, so Slurm ignored the
partition and accepted no job. RI direct SSH lacked the site Slurm DNS/config
environment; native `scontrol ping` and `sbatch --version` pass under both
`bash -lc` and `bash -lic`, so retry must use the login environment and let the
smoke prove compute-side resubmission. T4 ran on `cpu_4=1` (four slots, no GPU)
for 0.93 seconds and exited 2 before advancing state; only `smoke-submitted`
exists, with no lock or diagnostic. This exposed missing private diagnostics.
Current corrective work moves local `#YBATCH`/`#SBATCH` directives before the
first executable line, adds ordering regression, overwrites one mode-0600
controller diagnostic per job, and safely reconciles an absent submitted smoke
as failed before retry. No snapshot has run and no uncaptured job was created.

**T4 retry checkpoint:** corrective commit `613a0f2` allowed a safe retry as
AGE job `8175315`. Its managed read-only Restic check passed, but compute-side
successor submission stopped before adoption because `qsub` was absent from
the batch job's `PATH`; the private mode-0600 diagnostic contains only the
resolved native command and the `command not found` error. Login-side
validation identified the executable directory as
`/apps/t4/rhel9/uge/latest/bin/lx-amd64`, a mode-0755 directory owned by
`geadmin` and canonically linked to the installed 2023.1.1 AGE tree. Commit
`4c678d5` declared that path, passed focused, guarded-delete, and complete
phase-1 gates, and was bundle-fast-forwarded to all six clean remotes. Retry
parent `8175392` then passed on `all.q/r2n6`, four CPU slots, exit 0 in 3.498
seconds; exact `qdel 8175400` verified its Sunday successor disabled.

**Seven-node smoke checkpoint:** every accepted parent below completed the
managed read-only Restic check and created exactly one future Sunday successor;
each successor was canceled by captured exact ID and its private state is now
`verified-disabled`. No smoke took a snapshot.

| Host | Accepted parent | Exact disabled successor |
|---|---:|---:|
| `local` | `90931` | `90932` |
| `ab` | `2043932.pbs1` | `2043966.pbs1` |
| `ab2` | `2043931.pbs1` | `2043964.pbs1` |
| `ri` | `6857` | `6858` |
| `al` | `4221037` | `4221038` |
| `rc` | `210808` | `210810` |
| `t4` | `8175392` | `8175400` |

Local parent `90931` completed in 12 seconds on `threadripper-3960x` with six
CPUs and 15,600 MiB; AL parent `4220993` completed in nine seconds with the
accepted whole-node allocation; RC parent `210790` completed in three seconds
with two billed CPUs; and T4 accounting is recorded above. All bundle copies
were exact-unlinked and every checkout is clean at `4c678d5`. RI reached its
scheduler only under the login environment and requires an explicit project
account. The owner selected `rkp00015`. The first RI parent `6850` passed and
exact `scancel 6852` verified its successor absent, but accounting showed the
default `gpu` partition injected one GB200 and 400 GiB. RI exposes no CPU
partition. Commit `aa9e08e` made `--gres=none` explicit after native
non-submitting tests passed and left no test jobs; final RI parent `6857` still
received the same injected GPU allocation, passed in two seconds, and exact
`scancel 6858` verified its successor absent. Final-form AL parent `4221037`
and RC parent `210808` also passed, with exact successors `4221038` and
`210810` disabled. This proves the site override cannot be avoided through the
reviewed native request. The owner accepted the forced RI GPU allocation; all
required production choices were resolved before the exact seven-node pre-seed
audit and production submissions below.

**Production seed checkpoint (2026-07-16):** the exact pre-seed audit found all
checkouts clean at `324360b`, every chain absent, and every smoke state
`verified-disabled` with its successor absent. Native seeding then accepted the
following singleton jobs; an immediate second seed on every node returned
`status=kept` for the same ID.

| Host | Captured production ID | First eligibility |
|---|---:|---|
| `local` | `90939` | 2026-07-19 00:30 JST |
| `ab` | `2044027.pbs1` | 2026-07-19 01:00 JST |
| `ab2` | `2044028.pbs1` | 2026-07-19 01:30 JST |
| `ri` | `6862` | 2026-07-19 02:00 JST |
| `rc` | `210816` | 2026-07-19 02:30 JST |
| `t4` | `8175651` | 2026-07-19 03:00 JST |
| `al` | `4221054` | 2026-07-19 01:00 Europe/Zurich |

Every controller status reports `active`, exact identity present, and the
expected scheduler pending/held state. Next action: monitor only these captured
IDs; after each admission verify successful snapshot evidence, exactly one
successor at the next strictly future Sunday, private state consistency, and
healthy interactive-login silence. Do not duplicate or cancel jobs merely for
queue delay.

**Power-outage continuity checkpoint (2026-07-17 06:12 UTC):** exact native
queries after the local cluster restart find all seven captured production
IDs still present with their expected owner/name identity and future
eligibility. Local `90939` survived the Slurm restart and remains
`PENDING/BeginTime` for 2026-07-19 00:30 JST. Its `threadripper-3960x`
partition is configured up, but all three nodes currently report `down` with
reason `NO NETWORK ADDRESS FOUND` while the cluster is being restored. AB and
AB2 remain in PBS scheduled-wait state, and RI, AL, RC, and T4 retain
their recorded future eligibility. No job was submitted, replaced, cancelled,
resized, or reprioritized. Node recovery is an external wait; the protected
Sunday chain itself needs no repair.

The same outage audit confirms the declared `/mnt/nfs-03/safe` and
`/mnt/nfs-03/fast` roots are present read-write on hard NFSv4.2 mounts, and the
local primary repository remains a regular owner mode-0700 directory.
`harness doctor --host local` has zero failures, but the separate site packages
mount has not returned: `yrun`, `ybatch`, and `yokota-rns` are absent. The
root-owned `/usr/share/yokota-rns/completion_yrun.sh` assumes `yokota-rns` is
present and calls `dirname` without an operand when it is not, which explains
the temporary login warning. No system or startup file was changed. Before
local job execution or any new submission, require the packages mount to
return, rerun doctor, and require native `yrun`/`ybatch` discovery; the existing
captured jobs remain untouched meanwhile.

### T-193 — Reproducible public-repository safety audit

**Phase/status:** `complete` under the owner's 2026-07-16 eight-hour go.
Extend website T-185's manual review with one credential-value-free scanner
that audits the current tree and reachable history of both public repositories.
Report only rule IDs, paths, commits, sizes, counts, and metadata fingerprints;
never print matching values. Cover suspicious filenames, private-key headers,
common token/credential assignments, credential-context entropy, oversized
blobs, operational paths, and ignored/untracked boundaries. Do not rewrite
history, change visibility, inspect authentication stores, or mutate website
files while its unrelated fresh ledger closeout remains dirty. Acceptance is a
versioned scanner with hostile fixtures, bounded reports for both repositories,
and independent confirmation that no matched repository value is copied into
stdout, stderr, or a report.

**Outcome:** `tools/public-repo-audit.py` scans all
reachable blobs with one Git batch reader and one raw-history pass, publishes
only bounded per-rule samples with complete counts, and refuses to overwrite
reports. Its guarded hostile
fixture proves a fake token present only in deleted history triggers path,
token-shape, and assignment rules while the value remains absent from stdout,
stderr, and JSON. Provisional full scans completed without a private-key,
high-entropy-credential, or suspicious-path finding. Harness's sole token-shape
item is its synthetic historical fixture. Website's sole assignment candidate
is a historical, HEAD-absent jQuery 1.2.3 vendor expression. Canonical reports
and interpretation are in `docs/audits/` and
`docs/public-repository-safety.md`; the website report preserves its four-entry
concurrent dirty-count fact without reading or mutating those files. Focused
hostile tests, evaluation regression tests, and the complete phase-1 suite
passed before publication; the expected login-node OpenMPI CUDA-library
warnings were explicitly ignored by OpenMPI.

### T-194 — Contributor-safe CI and merge controls

**Phase/status:** `executing`, resumed by the owner's 2026-07-17 `proceed` after
owner-attested reviewer `rioyokota2` cleared the former one-reviewer gate.
Harness and website CI are implemented, hosted-pass verified, and cleanly
published. Exact active-ruleset payloads are frozen under
`docs/github-rulesets/`; external creation is the only remaining write.

**Outcome/checkpoint:** Harness workflow `.github/workflows/ci.yml` uses
read-only permissions, checkout v6.0.2 pinned to full commit
`de0fac2e4500dabe0009e67214ff5f5447ce83dd`, no persisted credential, complete
history, and fixed `ubuntu-24.04`. Hosted run `29499772796` passed ShellCheck,
all five focused suites, and the portable phase-1 gate. The generic runner
explicitly skips only native MPI and Codex-client policy semantics; the default
managed-node suite still requires both and passed locally. Exact branch-rule,
rollback, and exact settings are in `docs/ci-and-merge-controls.md`. Website
workflow `.github/workflows/ci.yml` is published at `e0e9686`; hosted run
`29567532337` passed its credential-free static and locked browser checks.
Public API preflight on 2026-07-17 found no existing ruleset on either
repository and confirmed successful GitHub Actions checks `portable-phase1`
and `Offline checks`, both from integration `15368`. The current process has
no GitHub settings connector, `gh` executable, `GH_TOKEN`, `GITHUB_TOKEN`, or
owner handoff script, so it cannot perform the Administration-write API call
without crossing the credential boundary. Do not infer failure or weaken the
payload. Exact next action is an owner-authenticated apply, followed by public
ruleset inspection and one `rioyokota` PR approved by `rioyokota2` in each
repository; rollback disables or deletes only the newly created ruleset.

### T-195 — Seven-node configuration-drift audit

**Phase/status:** `complete`; executed after T-193's local scanner was frozen.
Use only the declared aliases `local`, `ab`, `ab2`, `ri`, `al`, `rc`, and `t4`.
Collect a bounded allowlisted inventory of logical identity, harness revision
and cleanliness, profile/control-plane discovery, storage-link targets,
managed tool versions, native scheduler availability, T-191's captured exact
job state, and existing HPC smoke sources. Never dump environments, enumerate
SSH configuration, read credentials, submit/cancel jobs, install packages, or
touch NFS data trees. Separate login-node capability from compute readiness and
record site-specific drift rather than normalizing it away.

**Outcome:** committed collector `tools/fleet-readiness-audit.py` made one
bounded login-shell connection per remote concurrently and one local probe.
`docs/audits/fleet-readiness-2026-07-16.json` has all seven nodes, zero probe
failures, zero discarded stdout, clean checkouts, doctor failures zero, exact
T-191 chains present, disabled smokes absent, four control links correct, and
all ten smoke blobs identical. Remotes are clean at ancestor `a2823d3`, 36
commits behind local `26690a8`. Site login baselines differ as expected and do
not establish compute readiness. Recreated default-home directories are listed
without content inspection in `docs/fleet-readiness-audit.md` and assigned to
T-199. No node or scheduler was mutated.

### T-196 — Backup lifecycle phase 2

**Phase/status:** `policy resolved`, execution-gated on eight successful weekly
chains, two verified restores per node, and a current verified independent
generation. T-251 locked the 12-weekly/12-monthly/3-yearly exact-group policy,
monthly rotating quarter-data checks, quarterly full-data/full-restore checks,
monthly sampled restores, and monthly manual independent generations retaining
the latest two verified copies. No live retention, `forget`, `prune`, recurring
check/restore, or replica automation is authorized yet. The eventual actions
remain behind their later exact-command authority boundaries.

**Outcome:** `docs/backup-lifecycle-phase2.md` records official Restic 0.19.1
semantics, recommended generous retention, separate forget/prune transactions,
deterministic data-check coverage, restore drills, manual-first independent
replicas, collision/lock rules, phased acceptance gates, rollback evidence, and
the resolved owner policy. No Restic, scheduler, replica, deletion, or
credential-path command ran. Keep-all remains effective until T-191 production
stabilizes and the owner separately approves the exact first `forget` and later
separate `prune` commands.

### T-197 — Evaluation follow-up decision

**Phase/status:** `complete`; evidence-only, with no new model invocation or
candidate adoption. Reconcile T-181's pilot/full reports and review limitation,
quantify correctness, retry, latency, and token tradeoffs, and record an
adopt/adapt/experiment/reject decision. Default recommendation: do not adopt
failure-capsule candidate A because it showed no substantive correctness gain,
used comparable retries, and increased aggregate cost; require a materially
different mechanism and pre-registered hypothesis before another 70-run study.

**Outcome:** `docs/evaluation-follow-up.md` records `reject` for candidate A
and retains the baseline. Pilot was 9/9 versus 9/9; the full canonical result
remains 35/35 baseline versus 34/35 candidate with one retry per arm and no
safety failures. Targeted review classified the one difference as an oracle
false negative, so substantive correctness tied while candidate full-stage
duration/input/output rose 13.328%/3.135%/3.292%. The review's arm-bearing path
leak limits subjective blinding. No model, grader, report, or guidance changed.

### Eight-hour LLM/HPC readiness workstream

After T-193–T-197 reach their safe terminal states, continue assigning new
task IDs and executing bounded work that improves all-node readiness for LLM
training and scientific HPC coding. Prefer, in order: a reproducible capability
matrix; credential-free environment manifests; portable CPU/C++/Fortran/MPI/
CUDA/Python build gates; architecture-aware container/uenv plans; scheduler-
native single-device then distributed LLM smokes; checkpoint/data-path and
profiling plans; and matched performance baselines. Use existing tracked smoke
sources before adding code. No project/model/dataset clone, package install,
image pull, allocation/billing spend, global configuration, or destructive
cleanup is implied; prepare and validate read-only or model-free surfaces while
ledgering any owner-only action bundle. Checkpoint and push small verified
harness changes frequently while preserving concurrent contributor work.

### T-198 — Safe remote harness fast-forward

**Phase/status:** `complete`. All six remotes were clean at ancestor
`a2823d3`, 36 commits behind the local/public branch. Before any rollout,
classify every intervening path and prove that the T-191 scheduled entrypoint,
repository declarations, and private-state schema remain compatible with the
already queued jobs. If compatible, use the established credential-free
bundle/fast-forward route, one exact revision on every remote, with pre/post
cleanliness, identity, syntax, doctor, and read-only T-191 status gates. Do not
resubmit, cancel, or alter any scheduled job. Halt only the affected node on
drift; exact-unlink each reviewed transfer artifact after success.

**Compatibility checkpoint:** a path-level diff from `a2823d3` through the
current clean main branch proves identical Git object IDs for `bin/harness`,
`libexec/harness-common`, `libexec/harness-restic`,
`libexec/harness-restic-primary`, `libexec/harness-restic-schedule`, and both
Restic repository/schedule maps. The queued jobs therefore execute byte-identical
dispatch, state schema, successor, and snapshot code after fast-forward. The
only runtime-adjacent diffs are interactive-shell profile-derived host discovery
and removal of a redundant hard-coded host case in the separately manual
replica helper; neither is in the scheduled call graph. T-195 independently
proved each remote clean at the expected ancestor with the captured production
job present. Next: publish this checkpoint, create one prerequisite-bound Git
bundle, and require exact preflight/fast-forward/postflight in each connection.

**Outcome:** mode-0600 bundle SHA-256
`91a6ec436e3f238be1b1dae4b0c65bb07715457da3f9a153f07f8840614fdb57`
fast-forwarded all six remotes to `a916b10`. Five direct transactions passed
every postflight. RI also fast-forwarded and removed its bundle, then hit only
the documented non-login Slurm query boundary; a login-shell read-only
postflight passed. The independent canonical report
`docs/audits/fleet-readiness-post-rollout-a916b10.json` proves all seven exact,
clean, doctor failures zero, captured production jobs unchanged/present,
disabled smokes absent, control links correct, and smoke blobs identical. All
seven local/remote transfer artifacts are absent. No scheduler write occurred.

### T-199 — Recreated hidden-state classification

**Phase/status:** `complete`; metadata audit and every approved deletion are
complete, including T-251's exact AB Mozilla removal. The exact
scope was local `.cache`/`.nv`; AB `.cache`/`.mozilla`; AB2 `.cache`; RI
`.cache`/`.apptainer`; AL `.mozilla`; and T4 `.cache`. Record link/type,
ownership/mode, same-filesystem fact, bounded apparent size, application owner,
and whether XDG or application configuration can redirect future writes.
Reconcile the already approved per-node delete/move policy before action.
Never inspect file contents. Any multi-tree deletion must use guarded-delete;
any move must be transactional with application-specific rollback and must not
cross the active Restic/scheduler path unexpectedly.

**Outcome:** `docs/hidden-state-cleanup.md` records metadata without file names
or contents. Guarded staging/plan/exact-NEXT apply/postflight removed local
`.cache`/`.nv`, AB/AB2/T4 `.cache`, RI `.cache`/`.apptainer`, and AL `.mozilla`;
AB and T4 released roughly 23.4 GiB apparent legacy cache. Manifests, plan
files, and staging boundaries are absent, and the post-cleanup fleet audit kept
all T-191 jobs present. RI fresh-login startup recreated an empty `.cache`
before the managed cache block; a second guarded cleanup left it absent and
assigned durable prevention to T-201. AB `.mozilla` was only 12 KiB, crossed
filesystems, and could contain authentication state, so it was never copied or
inspected. T-251's owner decision removed it through same-filesystem quarantine
and guarded deletion; T-202 records the terminal evidence.

### T-200 — Scheduler-native LLM/HPC capability matrix

**Phase/status:** `capability baseline complete`; framework selection moved to
T-206. Convert identical tracked smoke sources
and site declarations into a reproducible login-versus-compute matrix. First
record exact native commands and environment/container routes; then, only under
existing allocation authority, run matched single-rank CPU/compiler/Python and
single-device CUDA/framework correctness before any distributed test. Freeze
inputs and collect architecture, driver/runtime/framework, MPI/backend, device,
and numerical evidence. Do not infer compute absence from login PATH, install
packages, clone models/datasets, pull images, or scale until the smaller gate
passes.

**CPU-gate checkpoint:** `tests/smoke/jobs/cpu-readiness.sh` is a
scheduler-neutral five-minute job that fails on architecture drift, selects
only the validated process-local GCC/uenv routes, builds and runs C/C++/Fortran
with CMake/Ninja, runs a direct C++20 and standard-library Python gate, and
executes sanitizers except for RC's declared base-runtime gap. It publishes one
new mode-0600 result and guarded-cleans node-local build state. Scheduler
actions remain explicit outside the generic script. Planned native requests
reuse only T-191-approved accounts/resources at default priority: local
`ybatch`/`thrp_1`; AB/AB2 PBS `rt_HC select=1`; RI Slurm `rkp00015/gpu` with
explicit `--gres=none` but accepted site-injected GB200; AL Slurm
`g177-1/normal`; RC Slurm `cloud-users/r340`; and T4 AGE
`jh250019 cpu_4=1`. Validate, commit, distribute, recheck no exact-name/result
collision, print each full native submit command, then monitor only captured
IDs. No GPU/framework claim follows from this CPU gate.

**CPU-gate submission checkpoint (2026-07-16):** the repeated pre-submit gate
found every fixed result absent and zero exact-name collisions. Seven native
five-minute/default-priority jobs were then accepted: current Ybatch `91133`;
AB PBS `2044959.pbs1`; AB2 PBS `2044958.pbs1`; RI Slurm `6978`; AL Slurm
`4223373`; RC Slurm `211005`; and T4 AGE `8179531`. Monitor only these captured
IDs, preserve the T-191 production jobs, and publish a capability claim only
from each private result plus scheduler accounting.

**CPU-gate v1 evidence:** local `91133`, AB2 `2044958.pbs1`, AL `4223373`,
and RC `211005` completed with status zero and passed C/C++/Fortran CTest,
C++20, Python, and the applicable sanitizer gate. RI `6978` reached every pass
marker but the site login shell's EXIT context failed afterward, so scheduler
accounting correctly records failure and no clean claim is made. T4 `8179531`
passed through Python but exposed a reproducible mixed-toolchain defect: its
GCC module supplies `gcc`/`g++`/`gfortran` while leaving `cc` at the base GCC
11 linker, which cannot link UBSan. AB `2044959.pbs1` remains queued for the
requested 32 CPU resource. Raw failed results remain private and untouched.

**CPU-gate v2 correction:** the job now resolves and exports a coherent
compiler triplet after AB/AB2/T4 module setup, re-executes the test body in
non-login Bash after site environment setup, and accepts a restricted run tag
so retries cannot overwrite prior evidence. Focused tests, invalid-tag tests,
shell parsing, and the full native phase-1 suite pass (the latter after the
required unload/reload of `openmpi/5.0-cuda-12.8`; expected login-node
`libcuda` component warnings remain non-fatal). Commit and distribute v2, then
repeat collision checks and retry only RI/T4 plus any later v1 failure.

**CPU-gate v2 submission checkpoint:** exact commit `8cded82` was transported
to all six remotes with a verified 3,099-byte bundle after direct GitHub fetch
proved unavailable there. A shared-`/tmp` name collision between AB accounts
caused no checkout mutation; the corrected transport used unique private
per-account state paths, and every local/remote bundle is absent after clean
fast-forwards. Fresh v2 collision checks passed before accepting: local Ybatch
`91158`; AB2 PBS `2044969.pbs1`; RI Slurm `6979`; AL Slurm `4223564`; RC Slurm
`211007`; and T4 AGE `8179553`. AB v2 is deliberately deferred while its v1
job remains live. Monitor only these IDs and the previously captured AB v1 ID.

**CPU-gate v2 continuation:** local, RI, AL, RC, and T4 v2 completed with
scheduler success, terminal status zero, coherent compiler identity, 3/3
CTest, C++20, Python, and applicable sanitizer evidence. T4 now proves the
explicit GCC 14 triplet; RI proves the non-login publication correction. AB v1
also completed status zero, clearing its duplicate-work constraint. A fresh AB
v2 preflight then passed and PBS accepted `2044973.pbs1`. AB2 v2
`2044969.pbs1` remains queued. These are the only two outstanding CPU-v2 IDs.

**CPU-gate outcome:** both remaining PBS jobs completed with scheduler exit
zero and terminal result zero. The matched seven-node report is
`docs/hpc-readiness.md` with machine-readable evidence in
`docs/audits/hpc-cpu-readiness-2026-07-16.json`. All nodes passed coherent
C/C++/Fortran builds, 3/3 CTest including OpenMP, direct C++20, and Python;
six sanitizer gates passed and RC retains its explicit runtime-gap skip. This
closes only the CPU/compiler/Python prerequisite. Next freeze a minimal
single-device accelerator/framework gate per declared site route; make no MPI,
distributed, numerical-equivalence, or performance claim beforehand.

**Accelerator-gate freeze:** queue and account discovery identifies the
smallest declared route at each site: local Ybatch `a4500_1`; AB/AB2 PBS
`rt_HG select=1` (exactly 16 CPU/one GPU by queue default and maximum); RI
Slurm `rkp00015/gpu --gres=gpu:1`; AL Slurm `g177-1/normal` with native
`--uenv=prgenv-gnu/25.11:v1 --view=default`; RC Slurm
`cloud-users/qc-gh200 --gres=gpu:1` (one GH200 per node and all-account
permission); and T4 AGE `jh250019 gpu_h=1` (one H100 MIG slice). Default
priority and a five-minute limit are mandatory. The tracked v1 job selects one
logical device, proves driver metadata everywhere, and compiles/runs the
one-device CUDA kernel on the five reviewed toolkit routes. RI and RC record an
explicit compile skip rather than infer a toolkit. Every node records the
framework skip because no reviewed PyTorch environment or image exists.
Commit, distribute, collision-check, print exact native commands, then monitor
only captured IDs without touching T-191.

**Accelerator v1 submission checkpoint:** exact commit `2e48072` reached six
clean remotes through a verified 4,811-byte bundle, with all bundle files then
absent. Result/name collision checks passed before native acceptance of local
Ybatch `91206`; AB PBS `2045030.pbs1`; AB2 PBS `2045029.pbs1`; AL Slurm
`4224038`; RC Slurm `211017`; and T4 AGE `8179763`. RI rejected the request
before creating a job because site policy requires job-level `--gpus=1`, not
per-node `--gres=gpu:1`. Exact-name reconciliation found no RI job or result.
ABCI IDs were recovered by exact `qselect` after the asynchronous controller
calls outlived the initial terminal yield; never resubmit those names.

**Accelerator v1 evidence and v2 correction:** AL and T4 completed with
scheduler/result zero, driver metadata, one-device CUDA kernel success, and the
declared framework skip. AB2 also completed the same gate with PBS exit zero;
AB remains queued. Local proved the A4500 driver but failed before compilation
because the inherited module table claimed CUDA loaded while its PATH lacked
`nvcc`. RC proved the allocated GH200 compute node is `aarch64`, contradicting
the x86 login-node assumption, and failed that intentional architecture gate.
Preserve both private v1 failures. V2 explicitly unloads/reloads local CUDA and
declares RC compute as Arm; after AB's immutable v1 job finishes, distribute
the correction and retry only local, RC, and the previously unsubmitted RI
with run tag v2 and RI's required `--gpus=1` spelling.

**V2 retry checkpoint:** AB v1 completed with PBS exit/result zero before exact
commit `1e6f930` was distributed, so no queued job observed moving source.
RI's corrected request passed native `--test-only` without creating a job;
fresh collision checks then preceded Slurm acceptance of RI `7009` and RC
`211018`. Both use run tag v2 and distinct names. The local retry wrapper is
being versioned with name `t200glocal2` and run tag v2 before its own fresh
collision check and Ybatch submission. Monitor only the captured IDs.

**Accelerator outcome:** RI `7009`, RC `211018`, and local `91211` completed
with scheduler/result zero. The final seven-node matrix is
`docs/audits/hpc-accelerator-readiness-2026-07-17.json` and the human report is
`docs/hpc-readiness.md`: seven driver/runtime passes, five one-device CUDA
compile/kernel passes, and two explicit no-toolkit skips. Every node records
the intentional framework skip. T-200's safe base-environment capability
matrix is complete; it makes no framework, MPI, distributed, numerical, or
performance claim. T-206 owns the owner-gated framework selection, and T-207
owns the next smaller scheduler-native MPI gate.

### T-201 — Early-login cache redirection

**Phase/status:** `complete`; RI's shell-independent recurrence moved to T-203. Determine, without
tracing values or reading unrelated startup content, whether the managed cache
exports can be installed before any user application startup on all seven
nodes. Design the smallest silent POSIX block and prove non-interactive,
interactive, batch, nested, and direct-SSH behavior. It must not make cache
targets part of T-191 backup sources, change scheduler state, create directories
on healthy login, or overwrite owner startup content. Roll out only after fake
home tests and per-node plans pass.

**Implementation checkpoint:** `harness cache-bootstrap` now plans and
transactionally prepends an exact silent cache-only block to `.bashrc` and
Bash's existing selected login file. It stores only the public prefix, disables
editor swap/backup/user configuration, revalidates exact suffix/type/owner/mode
before mutation, and supports exact-prefix rollback that preserves later owner
edits. `docs/early-cache-bootstrap.md` records the contract. Fake-home tests
prove first-command ordering, idempotence, silence, no `~/.cache` creation, no
copy of a synthetic secret, refusal before mutation when a prefix changes, and
successful rollback with later changes. Portable and native full suites pass.
Commit and distribute the exact revision, obtain clean seven-node plans, then
apply and test fresh login, direct SSH, interactive/nested Bash, and scheduler
inheritance before guarded cleanup of any RI recurrence.

**Live-plan checkpoint:** exact revision `070479c` is clean on all seven
checkouts after checksum-verified private bundle transport and complete
transport cleanup. Seven native `cache-bootstrap --plan` runs reported
`contents=not-read`, no block, and exactly two prepends: `.bashrc` plus
`.profile` on local/RI, or `.bashrc` plus `.bash_profile` on AB/AB2/AL/RC/T4.
Apply only this exact revision, capture all transaction IDs, then require an
idempotent two-KEEP postplan before opening fresh test sessions.

**Live-apply checkpoint:** repeated exact-revision plans passed at `2f72425`.
All seven transactional applies completed: local
`20260716T140611Z-3466811`; AB `20260716T140613Z-3409425`; AB2
`20260716T140612Z-1704569`; RI `20260716T140609Z-602570`; AL
`20260716T140620Z-250841`; RC `20260716T140615Z-1162732`; and T4
`20260716T140619Z-2984771`. These are the exact rollback IDs. Require two KEEP
postplans, correct first-line/type/mode metadata, declared cache variables in
fresh login/direct/non-interactive/interactive/nested sessions, no startup
output regression, and no default-home cache recurrence before closing T-201.

**Live shell postflight:** every node reports two idempotent KEEP actions, exact
first-line prefixes, and unchanged file modes. Fresh login, direct SSH,
inherited non-interactive, interactive, and nested Bash assertions all see the
declared host/cache/XDG values. RI's interactive warning text is the intended
T-191 schedule warning, not a cache-bootstrap output. Guarded cleanup removed
the pre-fix 4 KiB AB/AB2 remnants and their SFTP-only postflights remain absent.
RI's 4 KiB/two-entry remnant was twice guarded-cleaned with manifests and
boundaries fully removed, but an SFTP subsystem-only connection found the
directory recreated without running shell startup. T-203 owns that distinct
site/PAM-or-concurrent-process diagnosis; do not churn it with repeated deletes
or weaken `HOME`. Close T-201 only after one native batch inherits the declared
variables on each node. `tests/smoke/jobs/cache-startup-readiness.sh` is the
small, scheduler-neutral gate: it removes all inherited managed cache values,
enters login Bash, re-enters non-login Bash to avoid RI's known EXIT defect,
then validates the independent declared host/cache/XDG paths and publishes a
mode-0600 result. Focused and portable full suites pass. Commit, distribute,
collision-check, and run this five-minute/default-priority gate before closing.

**Batch-gate submission checkpoint:** exact commit `96de5d2` is clean on all
seven nodes; all collision checks found absent results and zero exact-name
jobs. Native schedulers accepted local Ybatch `91169`; AB PBS `2045001.pbs1`;
AB2 PBS `2045000.pbs1`; RI Slurm `6997`; AL Slurm `4223834`; RC Slurm
`211014`; and T4 AGE `8179679`. Monitor only these IDs and publish no batch
inheritance claim until scheduler accounting and terminal private results agree.

**Batch-gate outcome:** all seven terminal private results report PASS/status
zero and all native scheduler records report exit zero. The matched evidence is
`docs/audits/cache-startup-readiness-2026-07-16.json`. Each job first removed
the submit shell's managed values, entered login Bash, and independently
reconstructed the declared host/cache/XDG/application-cache paths. T-201 is
complete: ordering, shell modes, rollback, and batch inheritance are proven.
The persistent RI directory is explicitly not attributed to Bash and remains
isolated in T-203.

### T-202 — AB Mozilla application-native relocation

**Phase/status:** `complete`; the owner explicitly did not need the profile and
selected deletion with no inspection, migration, or fresh backup. Fresh
preflight proved the exact mode-0700 owner directory, canonical home boundary,
Firefox-process absence, and absent quarantine/manifest. The unchanged inode
was atomically renamed into a same-filesystem mode-0700 quarantine. Guarded
plan token `02e205ed35fbc086c5d7b220625d3a6e21c8d94c33afd900ad2a3d82962995cf`
bound one target with three entries and 12,288 bytes; its exact apply deleted
and verified only that target. The source, quarantine, mode-0600 manifest, and
Firefox process are absent, and `harness doctor --host ab` passes. Profile
contents and credentials were never inspected or copied; historical backup
snapshots remain outside this action.

### T-203 — RI shell-independent default-cache recurrence

**Phase/status:** `complete` from T-201 and T-250. RI recreates a 4 KiB/two-entry
`~/.cache` after an exact guarded cleanup even when the next connection uses
the SFTP subsystem and no Bash startup file. Preserve the tiny directory while
diagnosing; repeated deletion is not progress. Use value-free timing/type/count
evidence and official site/PAM documentation or owner/site support. Do not
trace startup values, list child names, inspect contents, weaken `HOME`, or
guess an application. If a responsible component is proven, prefer its native
cache configuration and re-run the SFTP-versus-shell experiment.

**Value-free diagnosis:** the preserved recurrence is currently a real
mode-0700 cache directory containing one mode-0644 zero-byte regular file;
directory and child birth/change times are identical
(`2026-07-16T14:12:51Z`), and no process holds the directory open. RI uses the
stock `/usr/lib/openssh/sftp-server`, has no user or system SSH rc file, and its
SSH PAM stack lists only standard access, environment, key, limits, loginuid,
mail, MOTD, nologin, and SELinux modules. This excludes a visible SSH rc
wrapper, internal-sftp customization, shell startup, persistent writer, or
multi-file application cache, but it does not identify the creator. Further
attribution needs site-admin audit evidence or a site explanation; do not
enumerate the marker name, install tracing, repeat deletion, or infer an
application from a zero-byte file.

**Resolution:** the later owner-authorized T-250 bounded inventory identified
the sole zero-byte marker as `motd.legal-displayed`; the same cache shape was
independently recreated locally. This attributes the harmless owner cache to
the native `pam_motd` login path, superseding the earlier unknown-attribution
text. Preserve it, do not weaken `HOME`, and send no unnecessary support
request.

### T-204 — Remove obsolete AB2 pyenv startup calls

**Phase/status:** `complete`. AB2 emitted exactly three
`pyenv: command not found` diagnostics on each login because `.pyenv` was
owner-approved for deletion while startup invocations remain. Identify only
the exact pyenv-related lines and structural context needed for a reviewed
patch; never print unrelated startup content. Add a transactional, byte-exact
remediation with rollback and fake-home tests, preserve all other owner lines,
then prove direct/login/interactive silence without reinstalling pyenv.

**Implementation checkpoint:** the live value-limited review found one exact
six-line block in AB2 `.bash_profile` (heading, `PYENV_ROOT`/`PATH`, and three
`eval` calls) and no pyenv line in `.bashrc`. `harness remediate --host ab2`
now verifies that entire public block and transactionally replaces it with six
same-length inert comments, preserving every unrelated byte and offset. The
existing patch rollback validates exact size/offset/payload. Fake-home tests
prove plan/apply/idempotence, no synthetic-secret copy, surrounding-line
preservation, changed-patch refusal, and exact rollback; portable and native
full suites pass. Commit and distribute, then require a clean live plan before
applying and capturing the AB2 transaction ID.

**Live outcome:** exact revision `000045f` produced one unambiguous 162-byte
live plan, and transaction `20260716T142824Z-1970447` completed. This is the
exact rollback ID. Require an idempotent KEEP plan, unchanged file mode/size,
zero pyenv literal matches in the reviewed file, and warning-free direct,
login, and interactive sessions before closing T-204.

**Postflight:** the live plan is now an idempotent KEEP; `.bash_profile` remains
mode 0640 and byte-identical in size, both startup files contain zero pyenv
literal matches, fresh direct/login paths contain no `.pyenv` component, and
direct/login/interactive checks pass without a pyenv diagnostic. T-204 is
complete; transaction `20260716T142824Z-1970447` remains the rollback point.

### T-205 — Fail-closed scheduler-chain visibility

**Phase/status:** `complete`; prompted by a false-negative RI audit. A direct
non-login `restic-schedule status` reported captured Sunday job `6862` absent,
while native login-environment `sacct`, `scontrol`, and `squeue` independently
proved the exact job healthy, owner-matched, `PENDING` for its declared
2026-07-19 02:00 JST eligibility, and unchanged. The direct shell lacked only
RI's public `SLURM_CONF_SERVER=sctl1:6817,sctl2:6817`; no scheduler state was
changed and no replacement job was submitted.

Declare that public endpoint in RI's host profile for direct harness calls and
change exact Slurm status queries to an owner-scoped scheduler listing that
must succeed before absence is inferred. A scheduler connectivity failure must
fail closed, produce no “missing job” warning, and never reach adoption or
submission as if discovery were empty. Add a deterministic failure regression,
run the full portable suite, distribute the exact commit, then prove both
direct and login status see the original `6862` and that all seven original
T-191 jobs remain singleton and unchanged before closing T-205.

**Outcome:** targeted scheduling tests, the native full phase-1 suite, warning
level ShellCheck, diff checks, and the value-free public audit passed. Exact
commit `d3d0eff` was fast-forwarded into six clean remote worktrees through a
5,105-byte verified public bundle, and every local/remote bundle is absent.
Fresh direct status sees all seven original T-191 IDs; RI direct and login
status both see unchanged job `6862` `PENDING`. The test suite also proves that
a Slurm discovery failure emits no false missing warning, submits no job, and
creates no chain state. T-205 is complete without any scheduler write.

### T-206 — Reviewed LLM framework environment

**Phase/status:** `complete` under T-251's resolved framework choice. The first
release is CPython 3.12 plus PyTorch 2.12.1/CUDA 13.0 from official wheels, one
dual-architecture hash lock, and separate immutable x86-64/AArch64 wheelhouse
artifacts. Both official Torch wheels and all 29 transitive packages resolve;
the AArch64 Triton 3.7.1 wheel requires its official `linux_aarch64` tag.
`docs/pytorch-framework-baseline.md` freezes sources, licenses, rollback, seven
single-device gates, and maintenance semantics. PyTorch 2.13.0 is recorded only
as a future candidate. Both collision-refusing artifacts are now published
under local declared persistent storage with lock hash
`07cc4a2e19ede271942d8050ef6f9e7349cefbf5b526b98bdc24dafde1401967`:
x86-64 is 2.6 GiB with manifest hash
`b5961b56df9301d3fc19234e5c6679ed186e5c49d1f5d1796a656fd3dcd626e6`;
AArch64 is 2.7 GiB with manifest hash
`ed070849ba8da9fcf34e574a0f26e6adf510ffa7a8722201af4ecf7a64346988`.
Every artifact file is mode 0444 and each directory mode 0555. All seven nodes
hold and independently verify the matching immutable wheelhouse. Local
`91513`, AB `2046732.pbs1`, AB2 `2046731.pbs1`, RI `7182`, AL `4228772`, RC
`211836`, and T4 `8188301` have terminal scheduler/result-zero evidence for
exact Python/architecture selection, artifact and lock hashes, Torch/CUDA
versions, one visible CUDA device, finite tensor arithmetic, the tracked tiny-
LM update, and guarded cache/home cleanup. The delayed ABCI retries ran without
replacement. The public value-free audit
`docs/audits/hpc-pytorch-readiness-2026-07-17.json` reports seven passes and
zero queued nodes. Do not repeat them, install into base home, mutate an
artifact, or infer distributed or performance readiness.

### T-207 — Scheduler-native MPI correctness gate

**Phase/status:** `complete` after T-200. Discover and freeze each site's
declared MPI/compiler route, then run the tracked bounded MPI source with two
ranks on one allocated node before any multi-node or GPU-aware claim. Require
rank uniqueness, expected world size, launcher identity, compiler/library
provenance, scheduler/result zero, private collision-resistant evidence, and
guarded scratch cleanup. Reuse T-191-approved CPU accounts/resources, default
priority, and five-minute limits. Do not infer ABI compatibility from login
PATH, cross node boundaries, run a benchmark, or use an unreviewed container.

**Route freeze:** the five reviewed base routes are local Open MPI 5.0.8 with
native `mpirun -n 2`; AB/AB2 HPC-X 2.26/Open MPI 5.0.10rc1 with `mpirun -n
2`; AL `prgenv-gnu/25.11:v1` Cray MPICH 8.1.32 with native `srun --ntasks=2`;
and T4 HPC-X 2.21/Open MPI 4.1.7rc1 with `mpirun -n 2`. The tracked job
unloads/reloads the exact module where applicable, compiles one source, asserts
the allocated architecture, and publishes one mode-0600 result. Local uses
Ybatch `thrp_1`; AB/AB2 use their approved `rt_HC select=1`; AL uses
`g177-1/normal` plus native uenv integration; and T4 uses `cpu_4=1`. RI and RC
remain explicit no-route skips: neither exposes an architecture-compatible MPI
wrapper on its selected Arm compute base. Do not allocate them for this gate or
carry RC's x86 login-only MPICH binary onto GH200.

**Submission checkpoint:** exact commit `e034477` was installed into six clean
remote worktrees by a verified 3,277-byte public bundle; every bundle is
absent. Fresh result/name collision checks passed before native acceptance of
local Ybatch `91213`; AB PBS `2045044.pbs1`; AB2 PBS `2045043.pbs1`; AL Slurm
`4224197`; and T4 AGE `8179808`. Local, AL, and T4 already report two unique
ranks, scheduler/result zero, and guarded cleanup. The two ABCI jobs remain
validly queued; monitor only these captured IDs and do not submit replacements.

**ABCI v1 failure and v2 correction:** both PBS jobs eventually reached
terminal `Exit_status=1` without creating their private result, while the
identical source already passed local, AL, and T4. The only pre-result code was
the HPC-X module unload/reload plus non-login re-exec, so no MPI transport claim
or diagnostic can be inferred. Preserve both failed records. V2 installs the
private capture/trap first, performs the same exact process-local module setup
inside that capture, and continues without re-exec. After tests and exact
distribution, retry only AB/AB2 with run tag v2 and distinct names; a second
failure must still publish its bounded diagnostic instead of disappearing.

**ABCI v2 evidence and bounded v3 retry:** both corrected jobs published their
private diagnostics and exited one. Compilation and HPC-X initialization
passed; native `mpirun -n 2` then reported one scheduler slot because the PBS
request's implicit `mpiprocs` value was one. This is a request-shape defect,
not an MPI correctness failure. Preserve v2. Retry only AB/AB2 with fresh run
tag v3 and names, changing the same approved one-node `rt_HC` request to
`select=1:mpiprocs=2`; this exposes two launch slots within the already granted
32 CPUs and does not oversubscribe, resize the node count, or change priority.
Collision-check result and job name immediately before each single submission,
then monitor only the captured IDs.

**V3 submission checkpoint:** clean exact source commit `c17f8dd`, private-result
absence, and fail-closed exact-name queries passed before PBS accepted AB
`2045086.pbs1` and AB2 `2045085.pbs1`. Both use run tag v3, five minutes,
default priority, the existing `rt_HC` project, and
`select=1:mpiprocs=2`. Monitor only these IDs; do not duplicate or replace
them while queued or running.

**Outcome:** AB `2045086.pbs1` and AB2 `2045085.pbs1` completed with
`mpiprocs=2`, PBS exit zero, private-result zero, and two unique ranks. Together
with local `91213`, AL `4224197`, and T4 `8179808`, all five reviewed native
routes pass. RI and RC remain explicit no-route skips and received no MPI
allocation. The public value-free matrix is
`docs/audits/hpc-mpi-readiness-2026-07-17.json`, summarized in
`docs/hpc-readiness.md`. T-207 closes only one-node/two-rank compiler, launcher,
rank, and world-size correctness; it makes no collective, multi-node,
GPU-aware, ABI-portability, or performance claim.

### T-208 — Immutable training-environment transport matrix

**Phase/status:** `design complete`; execution remains under T-206's owner
gate. Native value-free discovery and official documentation are reconciled in
`docs/immutable-environment-matrix.md`. The fleet has four viable mechanisms:
allocation-only Docker/Podman wrappers on local; SingularityCE 4.4.1 on
AB/AB2; Apptainer 1.4.5 plus Slurm OCI flags on RI; native uenv 10.0.1 plus
Slurm integration on AL; SingularityCE 4.5.0 plus Slurm OCI flags on RC; and
Apptainer 1.4.0 on T4. No image, registry, daemon, or credential was accessed.

Use one reviewed dependency definition/lock with two immutable architecture
artifacts and recorded digests, not one binary image: x86_64 for local,
AB/AB2, and T4; aarch64 for RI, AL, and RC. Prefer AL's site-native uenv and
Singularity/Apptainer SIF elsewhere unless a tested site-native OCI bundle is
materially better. Store large images/bundles under each persistent root,
caches under the declared fast cache root, and only non-secret definitions,
locks, provenance, and digests in harness. Before T-206 chooses anything,
validate licensing, CUDA/driver compatibility, compute-node runtime, GPU
selection, bind paths, home isolation, cache placement, and exact rollback.

### T-209 — Declared training-storage readiness gate

**Phase/status:** `complete`; read-only fleet discovery passed. Every declared
persistent and cache root is a real owner-writable directory outside canonical
home. Current uses NFS; the other roots use Lustre. Each reported filesystem
has more than 750 GiB free and more than 977,000 free inodes at discovery time,
but shared-filesystem `df` values are not a user-quota promise.

`harness storage-readiness --host HOST` now revalidates the unique public
layout row, exact canonical root identity, owner, writability, outside-home
boundary, filesystem type, and current free blocks/inodes without mutation.
`--write-probe` adds one mode-0600 4 KiB write+fsync in each exact root and
unlinks only that already-validated file, with a trap that refuses cleanup if
type, owner, dirname, or basename identity changes. Fake-root tests prove the
read-only path, two successful exact cleanups, inside-HOME rejection, symlink
rejection, and zero residue. After full-suite validation, commit/distribute,
run fresh read-only plans, then execute one bounded live probe per root and
verify no probe name remains. This is correctness only, not an I/O benchmark or
quota/capacity reservation.

**RC fail-closed correction:** the first live plan stopped before writing
because `/lvs0/rccs-asfm/rio.yokota` canonically resolves to the same
device/inode at `/lvs0/dne0/rccs-asfm/rio.yokota`; cache has the analogous
alias, while neither root is HOME. The host profile now declares those two
exact canonical identities. The gate still rejects undeclared intermediate
aliases and symlink endpoints, and binds cleanup to the captured root
device/inode. Tests prove undeclared-alias rejection, exact declared-alias
acceptance, write/fsync, and zero residue. Recommit/distribute this correction,
then repeat every read-only plan before any live probe.

**Outcome:** exact commit `e5e89ce` reached all six clean remotes and every
transport bundle is absent. Seven repeated plans passed. Fourteen live probes
then each wrote and fsynced exactly 4 KiB with mode 0600, revalidated the root
identity, exact-unlinked the probe, and reported cleanup absent. Independent
postflight searches for the restricted probe prefix found no residue in any
declared root. T-209 is complete; shared `df` values remain point-in-time
health evidence, not quota or future-capacity guarantees.

### T-210 — Cross-architecture numerical consistency gate

**Phase/status:** `executing` after T-200. The new tracked C++20 source uses
4,096 deterministic dyadic products whose frozen integer numerator is `-14036`
and exact binary64 result is `-0x1.b6ap+2`. It asserts IEEE-754 binary64,
round-to-nearest, forward/reverse bit identity, signed zero, the next value
after 1.0, quiet NaN, and two byte-identical outputs. Compile flags are
`-O2 -fno-fast-math -ffp-contract=off -frounding-math -Wall -Wextra -Werror`;
this is a strict reproducibility baseline, not permission to generalize to
fast-math, BLAS, GPU, mixed precision, or project numerics.

The scheduler-neutral job reuses the proven CPU compiler routes, validates the
allocated architecture, publishes one private fixed result, and guarded-cleans
scratch. Planned native requests are the T-200 five-minute/default-priority CPU
routes on all seven nodes. First run syntax/static tests, direct local compile
and repeat evidence, the full suite, public audit, commit/distribution, and
fresh result/name collision checks. The still-captured ABCI T-207 MPI jobs are
distinct work; do not cancel, resize, or duplicate them.

**Submission checkpoint:** exact commit `0d46b99` was installed into six clean
remote worktrees through a verified 5,110-byte public bundle, with every bundle
then absent. Fresh result/name collision checks passed before native acceptance
of local Ybatch `91220`; AB PBS `2045064.pbs1`; AB2 PBS `2045063.pbs1`; RI
Slurm `7013`; AL Slurm `4224277`; RC Slurm `211060`; and T4 AGE `8179846`.
RI, AL, RC, and T4 already report scheduler/result zero and the identical frozen
hex result twice. Local and both ABCI jobs remain validly pending; monitor only
these captured IDs and never infer failure or resubmit from queue delay.

**Local recovery:** after the owner explicitly directed use of an available
node, old Threadripper attempt `91220` was reconciled and exactly canceled.
The first Epyc request `91468` never started because its explicit one-task
override conflicted with the native eight-task resource shape; it was also
exactly canceled with no result. Corrected Ybatch job `91472` ran on
`epyc-7502`, completed `0:0`, and published the frozen identical numerical
result with private mode 0600 and zero scratch/job-script residue. T-210 remains
executing only for its already captured ABCI routes; do not repeat local.

**ABCI resume attempt (2026-07-17):** an exact-ID metadata-only reconciliation
of AB `2045064.pbs1` and AB2 `2045063.pbs1` failed closed before either native
`qstat` command ran because both SSH connections were denied at public-key
authentication. No scheduler state or result absence was inferred, no key or
credential was inspected, and no remote state changed. Retrying the same two
exact queries is safe only after the owner-controlled agent again supplies
usable ABCI authentication; do not replace or duplicate either job meanwhile.

### T-211 — Atomic checkpoint publication gate

**Phase/status:** `complete` after T-209. Extend the storage gate with a
mutually exclusive `--checkpoint-probe` that operates only in the declared
persistent root. It creates one unique mode-0600 staging file, writes and
fsyncs exactly 1 MiB of deterministic bytes, verifies the frozen SHA-256,
publishes without overwrite through a same-filesystem hard link, proves both
names are the same inode/link count, exact-unlinks staging, re-verifies the
published size/hash, syncs it, revalidates root identity, and exact-unlinks the
published name. Trap cleanup handles the two explicit validated names without
a deletion loop, glob deletion, or recursive action.

Fake-root tests prove publication, hash, cleanup, zero residue, mutual
exclusion from the 4 KiB write probe, and declared canonical-alias behavior.
This establishes bounded atomic checkpoint publication mechanics only; it is
not a checkpoint-format, directory-fsync, recovery, quota, throughput, or
distributed-coordination claim. Run the full suite/public audit, commit and
distribute, repeat read-only plans, then execute one live persistent-root probe
per node and independently verify the restricted prefix is absent.

**Outcome:** exact commit `f1dafda` reached all six clean remotes and every
bundle is absent. Seven repeated plans passed. Each persistent root then
published and verified the exact 1 MiB checkpoint probe and reported both
names absent. An independent restricted-prefix postflight found zero residue
on all seven nodes. T-211 is complete within its narrow atomic-hardlink scope.

### T-212 — Direct development-debugger gate

**Phase/status:** `complete`; no scheduler allocation is required. The tracked
tiny C program has a non-inlined `checkpoint(35)` that returns 42. The bounded
login-node gate compiles it with `-g3 -O0 -fno-omit-frame-pointer`, runs GDB in
batch/no-init mode, and privately requires the exact function breakpoint,
argument value 35, continuation, and normal exit. Only compiler/GDB version and
a stable pass/fail category reach stdout; raw debugger output stays inside a
mode-0700 temporary tree removed through guarded cleanup.

Local direct execution and static/safety tests pass. Run the full suite/public
audit, commit and distribute, then execute once on all seven login nodes. This
establishes only direct local-process GDB usability; it does not claim remote
debugging, scheduler attach, MPI/GPU debugging, core-file policy, optimized
debug info, or profiler capability.

**V1 result and V2 classification:** local, RI, AL, and RC passed. AB, AB2,
and T4 returned nonzero from GDB before the stable breakpoint checks; the raw
logs were correctly guarded-cleaned and no cause is inferred. V2 maps only an
allowlist of raw signatures to `ptrace-policy`, `process-limit`, or
`temporary-storage`, otherwise reports `gdb-exit-uncategorized`; it never emits
the matched line. Commit/distribute and rerun only the three failures. Treat a
confirmed login ptrace policy as a boundary and test compute-node debugging in
a separate bounded task rather than attempting a bypass.

**Outcome:** V2 identifies AB and AB2 as `ptrace-policy` and T4 as
`process-limit`, without emitting matched raw lines. Local, RI, AL, and RC are
direct-development passes; the other three are explicit login-node gaps, not
installation failures. T-212 is complete within its direct-login scope and
hands bounded compute validation to T-213.

### T-213 — Compute-node debugger gate for restricted logins

**Phase/status:** `complete` after T-212. Run the same guarded GDB breakpoint,
argument, continuation, and normal-exit test inside one five-minute/default-
priority CPU allocation on AB, AB2, and T4 only. A scheduler-neutral wrapper
requires the native allocation identity, captures only safe direct-gate output,
and publishes one mode-0600 fixed result even on failure. Use approved
`rt_HC select=1` groups for ABCI and `cpu_4=1` for T4. Do not change ptrace,
process limits, core policy, packages, or login behavior. Commit/distribute,
collision-check, submit once, and monitor only captured IDs.

**Submission checkpoint:** exact commit `5fadfbd` reached all six clean remotes
through a verified 2,332-byte public bundle; every bundle is absent. Fresh
result/name collision checks passed before PBS accepted AB `2045079.pbs1` and
AB2 `2045078.pbs1`, and AGE accepted T4 `8180554`. T4 already completed with
scheduler/result zero and the full inner breakpoint/argument gate. The two
ABCI jobs are validly queued; monitor only those IDs without replacement.

**Outcome:** T4 completed with scheduler/result zero and the full breakpoint,
argument, continuation, and normal-exit gate. AB `2045079.pbs1` and AB2
`2045078.pbs1` both ran on compute nodes and reproduced the stable
`ptrace-policy` classification with private results and PBS exit two. Compute
allocation therefore does not remove ABCI's policy boundary. T-213 is closed
as one pass and two explicit site-policy gaps; do not attempt a ptrace bypass or
change security, core, package, or scheduler settings.

### T-214 — Offline project virtual-environment gate

**Phase/status:** `complete`; no allocation or package installation is
required. The tracked direct gate selects only the already-present `python3`,
requires managed `uv`, sets `UV_OFFLINE=1` and
`UV_PYTHON_DOWNLOADS=never`, and creates an unseeded project-independent venv
plus uv cache inside one mode-0700 temporary tree. It never activates the venv,
contacts an index, resolves dependencies, or writes project/home state. The
venv Python must run isolated with user site disabled and pass the tracked
standard-library smoke before guarded cleanup.

Run local execution, static/safety tests, the full suite and public audit;
commit/distribute; then execute once on all seven login nodes. This proves only
offline environment creation from the visible interpreter. It does not select
framework packages, validate a lock, seed pip, claim wheel availability, or
authorize any T-206 install/download.

**First fleet pass and correction:** exact commit `de81e5e` reached all six
clean remotes and every transfer bundle is absent. Local, AB, AB2, RC, and T4
passed. RI's non-interactive SSH `PATH` omitted its intact pinned
`~/.local/bin/uv`, while AL exposed system Python 3.6 even though its intact
managed Python 3.12.12 link is `~/.local/bin/python3.12`; neither finding is an
installation gap. The corrected gate keeps normal `uv` PATH precedence with an
exact managed-link fallback and prefers the declared managed Python 3.12 link
over generic system `python3`. Focused execution, portable full-suite, and
public-audit checks pass locally. Commit, distribute, and rerun all seven before
closing; no artifact download or package change is authorized or required.

**Outcome:** exact correction commit `c17f8dd` reached all six clean remotes.
All seven nodes then passed with uv 0.9.18 and Python 3.12, offline mode and
Python downloads disabled, isolated user site, standard-library smoke, and
guarded cleanup. An AB transfer initially landed in login2 node-local `/tmp`;
the repository was untouched until a home-based retry passed, and the exact
mode-0600 artifact was SHA-256-revalidated, unlinked, and independently absent
on login1 through login4. All local and remote transfer artifacts are absent.
T-214 is complete within its deliberately dependency-free scope.

### T-215 — Load-balanced-safe harness fast-forward workflow

**Phase/status:** `complete` after repeated verified bundle rollouts. Replace the
error-prone manual transport sequence with a transparent plan/apply command
that prints the native Git/SSH streaming operations, requires an explicit expected
old and new commit, refuses dirty or divergent worktrees, creates one
mode-0600 prerequisite-bound Git bundle, verifies size and digest before each
fetch, fast-forwards only, and exact-unlinks every transfer artifact after
postflight. Use a unique account-home staging file rather than node-local
`/tmp` on load-balanced sites. Test entirely with local fake remotes first;
live fleet use is allowed only after phase-1, public-audit, collision, cleanup,
and interrupted-transaction tests pass. It must never force, reset, merge,
stash, inspect credentials, alter remotes, or conceal the resolved native
commands.

**Implementation checkpoint:** `harness fleet-sync` now requires full source
and target commit IDs, exact target `HEAD`, ancestry, unique safe targets, and
a clean local checkout for apply. One all-host read-only preflight precedes any
write. Apply creates a prerequisite-bound mode-0600 bundle in a private local
transaction directory and streams it through native SSH into persistent
account state; the remote revalidates old HEAD, clean worktree, collision,
size, SHA-256, bundle prerequisite, fetched target, fast-forward, and final
cleanliness before exact unlink. Target-already-current nodes are idempotent
keeps, so partial fleet completion is resumable. Focused fake-remote tests pass
normal, repeat, dirty, divergent, collision, and signal-interrupted cases with
zero transfer residue. ShellCheck, portable phase-1, and public audit pass, and
a real six-node read-only plan reports six clean updates from `c17f8dd` to
`9e96f96`. Commit and push the implementation, rerun the plan against the new
target, then perform its first live apply and independent postflight.

**Outcome:** implementation commit `e8b0e9a` was pushed, a fresh real plan
reported six clean updates from `c17f8dd`, and the new command performed its
own first rollout. Every remote independently verified the streamed bundle and
fast-forwarded to exact `e8b0e9a`; a repeat plan reports six clean idempotent
keeps and all remote artifacts absent. The private local transaction directory
is also absent. T-215 is complete and supersedes manual `/tmp`/SCP bundle
rollouts for future clean mirrored-harness updates.

### T-216 — Consolidated LLM/HPC readiness gap matrix

**Phase/status:** `complete`; this is evidence consolidation only. Build one
machine-readable and one human matrix from the already validated CPU,
accelerator, MPI, numerical, debugger, storage/checkpoint, offline-environment,
and immutable-transport records. For every node and capability, distinguish
`pass`, `declared gap`, `owner-gated`, `pending captured job`, and `not tested`;
never convert absence of evidence into absence of capability. Link exact
evidence artifacts and job IDs without copying private result paths or raw
logs. Use the matrix to rank the next bounded tasks by fleet coverage and
scientific/LLM value, validate JSON and public-audit safety, then commit, push,
and distribute through T-215.

**Outcome:** `docs/audits/llm-hpc-gap-matrix-2026-07-17.json` and
`docs/llm-hpc-gap-matrix.md` consolidate the existing evidence with the exact
five-state vocabulary. The fleet has seven CPU/storage/checkpoint/offline-venv
passes; seven accelerator-driver passes; five CUDA-kernel, five MPI, and five
usable debugger passes; six numerical passes plus captured local job `91220`;
and one sanitizer gap. Immutable execution and multi-node MPI remain explicitly
untested, while framework selection remains owner-gated on all nodes. The
ranked next safe tasks are checkpoint/restart semantics and, later, scheduler
cpuset/topology binding; T-200 already covers basic OpenMP reduction.
Multi-node MPI is held for explicit resource review. Exact commit `d513bf3`
reached all six clean remotes with every transfer artifact absent. T-216 is
complete.

### T-217 — Portable checkpoint/restart equivalence gate

**Phase/status:** `complete` after T-211 and T-216. Add a small tracked C++20
state machine with a versioned, architecture-neutral checkpoint format and
integrity checksum. In one bounded scheduler allocation, compare an
uninterrupted deterministic integer run against two separate processes: one
writes and fsyncs a mode-0600 checkpoint at a frozen step, and the other
validates and resumes it to the same final state. Use one unique exact file in
the declared persistent root, collision refusal, identity revalidation, exact
unlink on every normal/failure path, private result publication, and guarded
scratch cleanup. Add focused tests for round trip plus truncated, corrupted,
wrong-version, and wrong-step rejection. Reuse the proven T-210 compiler and
five-minute/default-priority CPU routes; do not claim scheduler requeue,
signal-preemption handling, distributed checkpoints, application formats,
throughput, or crash-consistent directory metadata.

**Implementation checkpoint:** the tracked C++20 program encodes a fixed
40-byte big-endian record with magic, version, flags, step, state, and FNV-1a
integrity; writes with `O_EXCL`, mode 0600, full-write handling, and `fsync`;
and rejects non-regular/incorrect-size, magic, version, flags, checksum, and
step defects before resume. The frozen 400-step record SHA-256 is
`0cc4aab240009663fdc78161d523446dc3a71330e7b445b77aa7aa3cdb4dbfe1`,
and the million-step state is `0x7f7cadf8669fc055`. The scheduler-neutral job
builds in guarded scratch, uses exactly one collision-refusing checkpoint name
in the declared persistent root, compares two-process resume with the frozen
uninterrupted result, revalidates file identity, and exact-unlinks it. Focused
negative tests, ShellCheck, portable phase-1, and public audit pass. Commit and
distribute, perform fresh result/job/checkpoint collision checks, then submit
the same proven five-minute/default-priority CPU routes once per node and
monitor only captured IDs.

**First submission checkpoint and two pre-job corrections:** exact commit
`42d8709` reached six clean remotes and all result, checkpoint, and scheduler
names passed fresh collision checks. PBS accepted AB `2045091.pbs1` and AB2
`2045092.pbs1`; Slurm accepted RI `7016`, AL `4224483`, and RC `211075`;
AGE accepted corrected T4 job `8180931`. Local Ybatch printed an underlying
invalid-partition rejection but returned zero, creating no job or result: its
resource must be the proven `#YBATCH -r thrp_1` directive, not invented Slurm
partition/resource directives. T4's first request was likewise rejected before
job creation because `-A` is only an accounting string; native `-w v` proved
that this site selects the reviewed group with `-g jh250019`, after which the
single submission succeeded. Preserve the six accepted IDs. Commit/distribute
the local-only directive correction, recheck exact local name/result/checkpoint
absence, and retry local once without touching any accepted job.

**Corrected submission and early evidence:** exact correction commit `851e746`
reached all six clean remotes without changing the already submitted common job
body. Fresh local reconciliation passed before Ybatch accepted local `91240`;
it is queued alongside the older, distinct T-210 job `91220`. RI `7016`, AL
`4224483`, RC `211075`, and T4 `8180931` already have scheduler/result zero,
the identical frozen final state on AArch64 and x86-64, and no restricted
checkpoint residue. AB/AB2 remain validly queued for capacity. Monitor only
these captured IDs and do not replace them.

AB `2045091.pbs1` subsequently reached scheduler exit zero and published the
same frozen final state with exact checkpoint cleanup. AB2 and local remain the
only T-217 queued jobs.

AB2 `2045092.pbs1` subsequently reached scheduler/result zero with the same
frozen state and no checkpoint residue. After cluster recovery, the owner
explicitly directed relocation of local `91240` from the allocated
Threadripper partition. It was exactly canceled. First Epyc request `91469`
never started because its explicit one-task override conflicted with the
native eight-task resource shape and was exactly canceled without a result.
Corrected Ybatch job `91474` ran on `epyc-7502`, completed `0:0`, reproduced
the same frozen state, published a private mode-0600 PASS result, and left no
checkpoint, guarded scratch, or generated job-script residue. All seven routes
now have scheduler/result-zero evidence; T-217 is complete within its stated
portable restart scope.

### T-218 — Fail-closed native scheduler submission reconciliation

**Phase/status:** `complete`, derived from T-217's pre-job failures. Local
Ybatch demonstrably returned zero while its underlying Slurm submission
rejected an invalid directive. The shared `operate-native-hpc` skill now
requires the scheduler family's exact one-ID success grammar followed by an
immediate native query matching ID, owner, and job name; wrapper exit zero
alone is never acceptance. Its current-node reference records the exact Ybatch
failure mode and reconciliation rule. The existing Codex and Claude discovery
links resolve to this shared directory, so no client setting, hook, profile, or
installation change is needed. This rule applies to future project and harness
jobs and preserves the native command rather than adding an opaque scheduler
wrapper.

### T-219 — Ledger terminal-status reconciliation

**Phase/status:** `complete`; a full phase-label audit found no new executable
work hidden behind terminal outcomes. T-212 and T-216 were corrected from stale
`executing` labels to `complete`. T-203 is now explicitly
`site-support-gated`: its value-free local diagnosis is exhausted and neither
repeated deletion nor invasive tracing is authorized. T-191's live weekly
chain, T-196's retention/prune execution gate, T-202's private Mozilla choice,
T-206's framework choice, T-210's captured local job, and T-217's captured
jobs remain intentionally non-terminal. No scheduler, file, application, or
external setting was changed by this reconciliation.

### T-220 — Versioned bounded CPU-route manifest

**Phase/status:** `complete`, derived from repeated T-200/T-210/T-217 reuse.
Freeze the seven already proven one-node/five-minute/default-priority CPU
submission shapes in a value-free TSV: scheduler family, reviewed billing
account or group, queue/partition, resource tokens, environment route, and
site-specific submission spelling. Add strict schema/uniqueness/token tests and
human scope documentation. This is a reference for agents to render and report
native commands, not an execution wrapper or new allocation authority. It must
explicitly exclude project jobs, training, GPU selection, MPI, multi-node,
performance, longer duration, priority, and any resource not already evidenced.
Validate phase-1 and public-audit safety, then commit, push, and distribute.

**Outcome:** `profiles/hpc-cpu-routes.tsv` freezes exactly seven unique rows and
`docs/bounded-cpu-routes.md` renders the native shapes and strict exclusions.
The manifest distinguishes PBS `-P`, Slurm account/partition, AL uenv, local
`#YBATCH -r`, and T4 `-g`; it also records RI's mandatory injected GPU and RC's
x86 CPU partition. Exact-row/schema tests, ShellCheck, portable phase-1, and
public audit pass. T-220 is complete as a read-only reference surface; it
creates no job and grants no authority beyond the previously reviewed bounded
readiness routes.

### T-221 — Queued-job source immutability contract

**Phase/status:** `complete`, derived from concurrent safe fleet fast-forwards
while T-217 jobs were queued. Add a small read-only Git gate that receives one
full submitted revision plus an explicit list of tracked job/source paths. At
compute start it must require the revision object, ancestor relationship,
regular tracked files, identical committed bytes and modes, and no path-local
index/worktree changes; unrelated later documentation commits may pass. Emit
only commit IDs, count, and stable status. Add isolated tests for unchanged,
unrelated successor, relevant committed change, dirty change, missing/unsafe
path, invalid revision, and non-ancestor revision. Document how a submission
exports the expected revision and invokes the native helper before work. Do not
snapshot repositories, read credentials, block safe unrelated fast-forwards,
or claim that Git identity alone freezes external modules, images, data, or
scheduler state.

**Outcome:** `tests/smoke/jobs/source-contract.sh` implements the ancestor plus
explicit-path contract and `docs/queued-job-source-contract.md` documents the
native export/invocation and external-state limits. Isolated repositories prove
the base and unrelated-successor passes and all required refusal cases,
including a fetched non-ancestor commit. ShellCheck, portable phase-1, and
public audit pass. The `operate-native-hpc` skill now requires this principle
for queued version-controlled jobs. T-221 is complete as a read-only source
gate; existing queued T-217 jobs retain their manually verified unchanged
source because their already submitted environment predates this helper.

**First live evidence:** on all seven clean checkouts, the helper accepted
submitted T-217 revision `42d8709` against current `3d50c0a` for exactly the
common job, C++ source, guarded cleanup helper, and host profile. This proves
the later fleet fast-forwards were unrelated to the queued computation paths.

### T-222 — Checkpoint-format golden-vector specification

**Phase/status:** `complete`, extending T-217 without a new allocation.
`docs/checkpoint-restart-format.md` specifies every v1 byte offset, unsigned
big-endian encoding, state-step semantics, FNV-1a constants and non-security
boundary, exact 40-byte step-400 vector, SHA-256, and million-step final state.
The focused test binds the document to the generated golden bytes and checksum
scope. The document explicitly excludes directory-fsync crash durability,
concurrency, scheduler requeue/signals, distributed state, schema evolution,
performance, and application suitability. No live checkpoint, scheduler, or
external state was changed.

### T-223 — Concurrent checkpoint-writer exclusion

**Phase/status:** `complete`; the focused T-217 test now launches two real
processes racing to create the same exact checkpoint with different steps. It
requires exactly one zero exit, one collision failure, a mode-0600/40-byte
winner, and successful validation/resume at only the winning step. The format
document records this one-filesystem evidence while retaining explicit no-claim
boundaries for distributed or multi-node coordination, crash durability, and
scheduler preemption. No persistent-root file or scheduler job was created.

### T-224 — Fleet Git and control-plane integrity audit

**Phase/status:** `complete`; strict connectivity-only Git fsck, exact clean
`e4ad156` HEAD, required executable blobs/modes, and local fleet-sync residue
absence passed on all seven nodes. A lexical-link audit initially exposed the
danger of comparing RC's canonical alias against its lexical home; the
canonical `harness apply --plan` was used instead. It found no blocks but six
missing onboarding/PIE discovery links on AB, RI, AL, RC, and T4, and three
missing onboarding links on AB2. The existing transactional apply created only
those absent links. Independent postflight now reports exactly 34 keeps, zero
creates, and zero blocks on every node. No repository bytes, owner files,
credentials, scheduler state, or unrelated links were changed.

### T-225 — Canonical control-plane completeness in fleet audits

**Phase/status:** `complete`, derived from T-224. Extend the existing bounded
fleet readiness probe to invoke the canonical `harness apply --plan` and retain
only its keep/create/block counts after requiring a complete end marker. This
reuses `managed_links` instead of hard-coding a second skill list, while the
existing four detailed control-link records remain for diagnosis. Update parser
and fake-SSH tests, run the focused/full/public suites, then perform one new
seven-node read-only audit and require 34/0/0 everywhere. The audit must not
apply links, read link contents, or expose discarded remote output.

**Outcome:** the collector and fake-SSH parser test now carry canonical
`keep/create/block` counts. Focused, portable full, and public-audit suites
pass. After implementation commit `ba6972e` reached six clean remotes, the new
audit `docs/audits/fleet-readiness-control-plane-2026-07-17.json` reported all
seven clean, failure-free nodes at exactly 34/0/0. Its SHA-256 is
`3a2ad49a78ed2263825665fda3e4f27cf3da0cbb00c62682a31430203795421e`.
T-225 is complete and future fleet audits can detect every declared discovery
link without a duplicated list.

### T-226 — Fail-closed canonical control-plane audit identity

**Phase/status:** `complete`, derived from independent review of T-225. The
collector currently records an explicit control-plane error but its parser can
still return a successful node record when the canonical plan summary is
missing. Require exactly one valid summary and reject missing, explicit-error,
or duplicate summaries. Add focused negative tests, run the portable full and
public-audit suites, then publish and distribute the verified correction. This
does not apply links or alter remote state beyond the version-controlled
control-plane rollout.

**Outcome:** the parser now requires exactly one valid canonical summary and
rejects missing, explicit-error, and duplicate forms. Focused negative tests,
the full suite with its declared `HARNESS_PORTABLE_CI=1` environment, and the
public-repository audit pass. An initial full-suite invocation selected its
native MPI branch and stopped at absent `mpicc`; no product test failed and the
portable rerun passed. T-226 is ready for version-controlled rollout.

The exact correction reached all six remotes through guarded fleet-sync. The
post-rollout seven-node audit is failure-free at clean `7fbe572`, with exactly
34 keeps, zero creates, zero blocks, and no retained control-plane errors on
each node. Its SHA-256 is
`9dfae5c2418adabecd691b91813c9b73f38173e986e79572ef5ce0efa8a70cd6`.

### T-227 — Frozen offline project-lock execution gate

**Phase/status:** `complete`, derived from T-214 and the immutable-environment
gap. Add one dependency-free committed `pyproject.toml`/`uv.lock` fixture and a
direct gate that copies it into private scratch, ignores user uv configuration,
disables indexes and Python downloads, and runs `uv sync --frozen --offline`
against the already validated managed Python 3.12. Verify isolated execution
and guarded cleanup on all seven login nodes. This proves lock consumption and
environment materialization only: it does not prove dependency-wheel
availability, framework correctness, containers, accelerators, or training.

**Implementation checkpoint:** the committed dependency-free fixture and
direct gate now bind the project environment and uv cache to private scratch,
require frozen/offline/no-download/no-config operation, run isolated Python,
and guarded-clean the entire temporary tree. Focused static validation, one
real local execution with uv 0.9.18/Python 3.12.3, the portable full suite, and
the public audit pass. The shared lock SHA-256 is
`7c5def12be70a50d2ada04c10bd10fad00c098f017ed657af260b20c91087dbe`.
Commit, distribute, then run the direct gate once on each node without a
scheduler allocation.

**Outcome:** exact implementation commit `2817332` reached all six clean
remotes with every transfer artifact absent. Concurrent direct execution then
passed on all seven nodes with uv 0.9.18, Python 3.12, the identical frozen
lock digest, isolated user site, and offline/download-disabled/config-ignored
operation. Exact read-only glob postflight found no T-227 scratch residue on
any node. The gap matrix now records this narrow seven-node pass separately
while preserving immutable image execution as not tested and framework/image
selection as owner-gated.

### T-228 — Bounded scientific-library login-surface audit

**Phase/status:** `complete`, derived from the scientific-coding workstream.
Add a fixed, bounded probe for visible HDF5, NetCDF, ADIOS2, FFTW, BLAS,
LAPACK, and OpenBLAS wrapper/`pkg-config` surfaces. Report only sanitized
presence/version records and explicitly classify the result as login-context
discovery, not a compute capability or absence claim. Test with synthetic
tools, run the portable/public suites, publish/distribute, then execute once on
all seven login environments. Do not enumerate module catalogs or environment
variables, install packages, allocate compute, or modify application state.

**Implementation checkpoint:** the probe now emits a fixed 19-line schema,
checks five wrapper names and nine package identifiers, and bounds unsafe or
unexpected version text to `unreported`. Synthetic present/absent/version and
invalid-host tests pass, as do one real local run, the portable full suite, and
the public audit. Commit and distribute before collecting the seven-node
login-surface matrix.

**Outcome:** exact probe commit `57d6a26` reached all six clean remotes with no
transfer residue. All seven concurrent probes passed and exposed `pkg-config`.
The visible current/RI login surfaces advertise BLAS, LAPACK, OpenBLAS, and
FFTW metadata; RC advertises `h5cc`, `nc-config`, and NetCDF 4.8.1 metadata;
the fixed surface is otherwise absent. The canonical JSON and interpretation
explicitly preserve this as process-local discovery, not an installation or
compute gap. No module catalog, environment dump, allocation, compilation,
package change, or application write occurred.

### T-229 — Multi-node MPI route decision record

**Phase/status:** `complete`, derived from T-207/T-216. Reconcile the five
one-node MPI passes with current official scheduler/site documentation and
bounded native read-only inspection to determine which routes have enough
evidence for a future two-node correctness gate. Record exact candidate native
resource/launcher shapes, unresolved account or topology choices, and explicit
no-route outcomes. Do not submit jobs, enumerate full queues/nodes/modules,
change environments, or infer multi-node support from a one-node pass. Any
future allocation remains a separate collision-checked task at default
priority.

**Evidence checkpoint:** official ABCI documentation and live PBS metadata
confirm that the proven `rt_HC` route cannot exceed one node; two-node MPI
requires `rt_HF`, `$PBS_NODEFILE`, and a full-node resource change. Official
TSUBAME guidance likewise requires full `node_f` resources rather than the
proven fractional `cpu_4` route. CSCS documents the exact two-node Slurm/uenv
shape and live `normal` accepts multiple nodes. Local has four nodes in the
partition and a plausible two-node Open MPI shape, but its custom wrapper has
no validated multi-node dry-run. RI/RC still lack architecture-matched routes.
Freeze these as explicit candidates/gates; submit nothing under T-229.

**Outcome:** the versioned seven-row route manifest and sourced decision record
now distinguish AL's documented candidate, local's required wrapper dry-run,
AB/AB2/T4 full-node resource changes, and RI/RC no-route outcomes. Focused
schema tests, the portable full suite, and the public audit pass. The stable
ABCI, Alps, and TSUBAME distinctions were promoted into the shared native-HPC
site reference; `install.sh` confirmed all Codex, agents, and Claude discovery
links still resolve to that shared skill. No scheduler job, environment change,
module load, package operation, or billing action occurred.

### T-230 — AL two-node MPI distinct-host correctness gate

**Phase/status:** `complete`, derived from T-229's documented AL candidate.
Add a separate MPI C gate that gathers processor identities but publishes only
the count, requiring exactly two ranks on exactly two distinct hosts. The AL
job must use the validated `prgenv-gnu/25.11:v1` uenv, two nodes, one rank per
node, five minutes, default priority, T-221 source-contract enforcement,
private collision-refusing result publication, and guarded scratch cleanup.
Run focused/native compile-negative/full/public validation, commit/distribute,
freshly collision-check, submit exactly once, reconcile one native Slurm ID,
and monitor only it. Do not claim latency, bandwidth, scaling, GPU-aware MPI,
collectives beyond startup/broadcast/gather, or any other node route.

**Implementation checkpoint:** the new C gate gathers fixed-size MPI processor
identities, requires two different values, broadcasts the verdict, and emits
only `ranks=2 hosts=2`. The AL-only job requires two allocated nodes, invokes
T-221 over all executable inputs, compiles inside allocation scratch, launches
one rank per node, collision-refuses a private result, and guarded-cleans.
Focused/static/ShellCheck tests, a native compile plus expected same-host
rejection, native and portable full suites, and the public audit pass. Commit
and distribute before any collision check or submission.

**Submission checkpoint:** exact implementation commit `48b4b45` reached all
six clean remotes with every bundle absent. AL then passed exact HEAD/worktree,
private-result, job-name, and six-path T-221 preflight. Native Slurm accepted
exactly one five-minute/default-priority two-node request as job `4224814`;
immediate reconciliation matched owner `ryokota`, name `t230mal`, and pending
state. Monitor only this ID and do not replace it for queue delay.

**V1 terminal diagnosis and v2 correction:** AL `4224814` ran immediately.
Source-contract and compilation passed, but the second node could not execute
the binary built under the first node's private `/tmp`; Slurm recorded failure
and the mode-0600 v1 result preserves that diagnosis without publishing either
hostname. This is a multi-node staging defect, not MPI/fabric evidence. V2 uses
a unique mode-0700 build directory under the already shared private
`~/.local/state/harness/hpc-readiness` root, then guarded-cleans it with that
root as the explicit boundary. Preserve v1 evidence; validate, commit,
distribute, and retry only with a new v2 result and job name.

**Outcome:** v2 commit `268a5cd` reached all six clean remotes. Fresh preflight
preserved v1, required v2 result/name/build/capture absence, and passed the
six-path source contract. Native Slurm accepted only job `4224822`; it ran on
two nodes and completed scheduler/result zero with `ranks=2 hosts=2`. Both
mode-0600 v1/v2 results remain private, while exact postflight found no v2
build or capture residue. T-230 closes AL's distinct-host correctness gate only;
all performance, GPU-aware, and other-node claims remain open or gated.

### T-231 — Shared multi-node executable visibility contract

**Phase/status:** `complete`, derived from T-230 v1. Add a reusable per-rank
gate that requires a regular non-symlink executable canonically inside an
explicit shared build boundary and matching a frozen SHA-256. Integrate it into
future T-230 executions so the controller requires two identical pass records
before MPI launch, add hostile digest/symlink/outside-boundary tests, and
promote the node-local-versus-shared rule into the native-HPC skill. This hashes
only a newly built public executable; it must never target credentials or
unrelated private data. No new scheduler run is required because T-230 v2
already proved both ranks could execute the same shared binary.

**Outcome:** the contract now rejects invalid digests, executable symlinks,
and paths outside the canonical declared boundary, and emits only a digest/pass
record. Future T-230 execution requires two identical visibility records before
MPI launch. Focused hostile/static/ShellCheck, portable full, and public-audit
tests pass. The durable shared-staging rule was added to the native-HPC skill,
and `install.sh` independently reconfirmed all three client discovery links.
No credential/private-data path was hashed and no scheduler job was submitted.

### T-232 — Fail-closed complete smoke-subtree fleet identity

**Phase/status:** `complete`, derived from review of the T-225/T-226 audit.
The fleet probe still hashes a fixed legacy list of ten smoke files, excluding
newer checkpoint, environment, and multi-node gates. Add exactly one required
Git tree identity for the complete tracked `tests/smoke` subtree, while keeping
the legacy per-file records for diagnosis. Reject missing, explicit-error, or
duplicate tree identities; add negative parser tests; run focused/full/public
validation; publish/distribute; then require one new failure-free seven-node
audit with identical subtree identity. This is read-only and must not execute
any smoke or alter scheduler state.

**Implementation checkpoint:** the remote probe now resolves the Git tree
object at `HEAD:tests/smoke`; the parser requires exactly one valid identity
and rejects missing, explicit-error, and duplicate forms. Focused negative,
portable full, and public-audit suites pass. Commit/distribute before the live
read-only audit so all seven nodes report the same complete subtree object.

**Outcome:** exact implementation commit `081e0e8` reached all six clean
remotes with no bundle residue. The post-rollout audit reports all seven nodes
clean at that revision, canonical control-plane 34/0/0, zero failures, and the
identical complete smoke-tree object
`17bdf765d814abd4851c2a282064419f88e905c2`. The report SHA-256 is
`3c707a2b452d34b561c7826fa7f8ecd7a96c51adddb2da9d9bbbe6232685f747`.

### T-233 — Private HPC result metadata hygiene audit

**Phase/status:** `complete`, derived from the growing readiness evidence
set. Add a content-blind probe for the declared private HPC result directory.
Require its owner/mode 0700 and each `tNNN-*.out` path to be a regular,
non-symlink, owner mode-0600, single-linked, bounded file. Count `.tNNN*`
temporary paths without failing or deleting because a captured job may be
active. Add synthetic absent/pass/bad-mode/temporary tests, run full/public
validation, publish/distribute, then execute concurrently on all seven nodes
and record aggregate counts only. Never open a result or inspect credentials.

**Implementation checkpoint:** synthetic absent, valid mode-0600, invalid
mode-0644, and active-temporary cases pass, as do ShellCheck, one real local
metadata-only run, the portable full suite, and public audit. Local currently
has six valid result files and zero temporary entries. Commit/distribute before
collecting the other six aggregate records.

**Outcome:** exact implementation commit `1eb1100` reached all six clean
remotes without bundle residue. Concurrent metadata-only probes passed on all
seven nodes: local/AB/AB2/RI/AL/RC/T4 have 6/10/10/6/9/7/8 valid private
results respectively, with zero invalid and zero temporary entries everywhere.
No result content was opened, no credential path was inspected, and no cleanup
or scheduler action occurred.

### T-234 — Fail-closed HPC result hygiene in fleet audits

**Phase/status:** `complete`, derived from T-233. Invoke the content-blind
metadata probe inside the bounded fleet collector and retain only state,
result-count, and temporary-count fields. Require exactly one valid pass
summary per node; reject missing, explicit-error, malformed, or duplicate
forms. Add negative parser tests, run focused/full/public validation,
publish/distribute, then require a fresh seven-node audit. Never retain a
result filename or open result content.

**Implementation checkpoint:** the collector/parser now require one bounded
aggregate with `state_ok=1`, `invalid=0`, and `status=pass`; only state and
result/temporary counts enter JSON. Missing, explicit-error, malformed, and
duplicate cases fail closed. Focused negative, portable full, and public-audit
suites pass. Commit/distribute before the live audit.

**Outcome:** exact implementation commit `44fbfb2` reached all six clean
remotes without transfer residue. The fresh audit is failure-free on all seven
clean nodes and records the same 6/10/10/6/9/7/8 valid-result counts with zero
temporary entries. Its SHA-256 is
`f6c10f58f3c0e13273303cc6154670fad2c05a9784ba76fd21785793444f8a21`.
No result content or filename entered the report.

### T-235 — Consolidated post-workstream LLM/HPC priority queue

**Phase/status:** `complete`, derived from T-216 and T-227–T-234. Create one
machine-readable queue and concise human interpretation containing only
unfinished or newly proposed readiness actions. Distinguish captured pending
jobs, safe-to-plan engineering, owner/resource/project/site gates, and explicit
dependencies. Validate IDs, status vocabulary, captured job identities, and
dependency references; run public-audit safety; publish and distribute. This is
evidence consolidation only and performs no scheduler, package, environment,
or external-setting change.

**Outcome:** the nine-item queue now preserves local jobs `91220`/`91240`, two
safe planning tasks, and five explicitly gated branches with Q9 depending on
the framework/artifact choice. Focused schema/dependency tests, the portable
full suite, and public audit pass. No queue item was converted into execution.

### T-236 — Local multi-node MPI non-mutating verification audit

**Phase/status:** `complete`, derived from T-229/Q4. Read-only native inspection
found that the user-facing `sbatch` refuses direct use, native Slurm 25.11.6
offers no test-only/verify option, and `ybatch -d` exits before cleaning its
generated temporary script. The underlying renderer and four-node partition
make the candidate plausible but do not validate wrapper accounting or rank
placement. The route is now `blocked_no_test_only`, Q4 reflects the scheduler
interface block, and the stable warning is in the native-HPC site reference.
No dry run, temporary script, job, or scheduler mutation occurred.

### T-237 — Scheduler-allocation CPU affinity and topology gate

**Phase/status:** `complete`; all seven nodes pass. Replacement local job
`91590` completed on `epyc-7502`. Add a portable Linux C++20 gate that
reads only the allocation process's CPU affinity mask and
sysfs topology, requires at least two distinct physical cores, and proves two
workers can be pinned to separate allowed cores. Emit aggregate counts only;
do not publish CPU IDs, hostnames, timings, or benchmark claims, and do not
repeat the OpenMP arithmetic gate. The scheduler-neutral job must use private
mode-0600 result publication, guarded scratch cleanup, and an exact submitted-
source contract. Reuse only the proven one-node, five-minute, default-priority
CPU routes, with two CPUs per task where the native scheduler exposes that
shape. Validate and commit first; then distribute, collision-check, print the
resolved native commands, submit at most once per node, and monitor captured
IDs without replacing delayed work. The two existing local jobs remain a
duplicate-load constraint: do not submit a third local readiness job while
they are pending.

**Implementation checkpoint:** `tests/smoke/affinity.cpp` validates the
allocation-visible affinity mask, topology metadata, two distinct physical
cores, and exact two-worker pinning while emitting counts only. The generic
job publishes one private result, guarded-cleans its build, and refuses source
drift from exact implementation commit `3b96936`. The seven-row route manifest
freezes only the proven one-node/default-priority resource families and a
five-minute limit; Slurm routes request two CPUs per task, while ABCI/T4 reuse
their existing full/fractional-node shapes. Positive/negative source tests,
shell parsing, warning-level ShellCheck, portable phase 1, and public audit
pass. Commit the revision binding, push and distribute before any scheduler
action.

**First submission checkpoint and RC correction:** exact runnable commit
`9f4b3d2` reached all six clean remotes and the gate compiled/executed on all
seven reviewed login toolchains. Result/name/temp collision checks passed
before native schedulers accepted AB `2045152.pbs1`, AB2 `2045153.pbs1`, RI
`7020`, AL `4225162`, RC `211077`, and T4 `8182351`; local remains held behind
`91220`/`91240`. RI, AL, and T4 have private mode-0600 PASS/status-zero results
and terminal scheduler status zero. RC v1 preserved a clean diagnostic
failure: Slurm allocated two logical CPUs, but the gate found only one physical
core, and both result and accounting report status 2. Correction commit
`8a0dcba` added `--hint=nomultithread`; distinct RC v2 job `211079` then passed
with two physical cores. Do not overwrite either RC result. On the 2026-07-17
resume, AB `2045152.pbs1` and AB2 `2045153.pbs1` both reported historical PBS
state `F`, exact expected owner/name, and `Exit_status=0`. Their regular
mode-0600 results pass the frozen source contract, expose 16 physical cores,
pin two workers, end with status zero, and leave zero capture temporaries.
Local became the sole remaining T-237 route and remained held until both older
local jobs were terminal.

**Local submission checkpoint (2026-07-17):** T-251's terminal evidence for
the relocated numerical and checkpoint/restart jobs clears the former local
hold. The exact four-path source contract against `3b96936` passed at current
head `f391e83`; focused affinity tests and shell parsing passed; and the
fail-closed preflight found fixed result `t237-affinity-local-v1.out` absent,
zero exact-name `t237alocal` jobs, and zero `.t237-affinity-local-v1` capture
temporaries. Native command
`ybatch /home/rioyokota/harness/tests/smoke/jobs/local-affinity.slurm` accepted
exactly one Slurm job, `91581`; the immediate native query matched owner
`rioyokota`, job name `t237alocal`, and pending state. Monitor only `91581` and
do not replace it for queue delay. On terminal state, require scheduler/result
agreement, the frozen source contract, mode-0600 private result metadata, and
zero job-scoped residue before closing T-237/Q3 or starting Q10.

**Owner-authorized Epyc relocation:** a fresh native `sinfo -N` query shows
`epyc-7502` idle, while captured job `91581` remains pending for resources on
`threadripper-3960x` with one task and two CPUs. The already proven Ybatch
resource is `epyc-7502_1`; prior T-210/T-217 evidence requires preserving its
native eight-task shape rather than forcing `--ntasks=1`. Add and publish a
distinct `t237aepyc2`/v2 wrapper that requests two CPUs per task, includes
every gate executable input in the submitted source contract, and writes only
distinct result `t237-affinity-local-v2.out`. The submitted wrapper itself is
frozen in the published runnable commit and scheduler-staged at submission.
After the exact revision is
clean and pushed, revalidate old-job identity plus v1/v2 result/temp/name
collisions, cancel only `91581`, prove it absent or terminal, exact-unlink only
an unchanged regular owner-owned generated Ybatch script if one remains, then
submit the v2 wrapper once. Accept only one parsed Slurm ID that immediately
matches owner and name; monitor only that replacement. No other job, resource,
priority, result, or scheduler state is authorized to change.

The first local freeze validation used an incorrectly expanded short commit
ID and the source contract refused it as `revision unavailable`; no scheduler
write occurred and retry was safe. Native `git rev-parse 8c36d8b` resolved the
actual implementation revision as
`8c36d8b4a29992a80ed4a38efc4b08ad960423af`, which is the only revision the
runnable v2 wrapper may accept.

Published runnable commit `843edf0` passed the corrected exact source contract,
focused readiness tests, warning-level ShellCheck, and public-audit safety. A
later pre-cancel check also stopped before scheduler action when an unverified
expanded runnable commit ID did not match `HEAD`; native `git rev-parse
843edf0` resolved the exact published value
`843edf0f6c431f51cab152c05d49e4200eaca7da`, after which every pre-cancel gate
passed. Exact `scancel 91581` reconciled the owner/name-matched old job as
`CANCELLED` with exit `0:0`; its generated Ybatch script was already absent.
Fresh `sinfo` then reported `epyc-7502` idle with 64 CPUs and no GPU. The v2
preflight found its fixed result absent, zero exact-name jobs, and zero capture
temporaries. Native Ybatch accepted exactly one replacement, `91590`, and the
immediate query matched owner `rioyokota`, name `t237aepyc2`, partition
`epyc-7502`, and pending state with no wait reason. Monitor only `91590`; do not
submit another replacement. Require scheduler/result agreement, two distinct
physical cores, two successfully pinned workers, mode-0600 result metadata,
and zero job-scoped residue before closing T-237/Q3.

**Local outcome:** job `91590` completed on node/partition `epyc-7502` with
scheduler exit `0:0`. Its regular owner mode-0600 single-link v2 result passed
the frozen source contract and reported 16 allowed CPUs, 64 online CPUs, 16
physical cores, and exactly two successfully pinned workers, followed by
PASS/result status zero. The first result postflight expected two captured
source-contract lines and stopped safely when it found one: the wrapper's
pre-exec contract intentionally writes to scheduler `/dev/null` before the
generic gate opens its private capture, so the result contract contains one
line. The corrected one-line validation passed. Exact capture/build-prefix and
generated-script checks report zero residue; the generated Ybatch script was
already absent. T-237/Q3 is complete without a benchmark or topology-
performance claim. Q10 is now safe to plan but received no submission under
this relocation request. Focused affinity/HPC/queue/public-audit tests pass.
The portable full suite stops at the pre-existing evaluation freeze check:
live `.codex/AGENTS.md` changed in committed recovery work `f391e83`, while
T-181 intentionally names baseline revision `d5b82cd`; no T-237 path affects
that comparison. Preserve this exact failure for a separate evaluation-policy
decision rather than weakening the frozen experiment during scheduler work.
The final pre-push refresh stopped before Git network access because both the
process socket is unset and tmux's global `SSH_AUTH_SOCK` no longer names a
usable current-user Unix socket. The local outcome commit was therefore not
pushed; retrying fetch/push is safe after the owner restores the agent, and
must again bind only the revalidated socket to those exact Git commands.

### T-238 — Fail-closed scheduler job collision preflight

**Phase/status:** `complete`, derived from RI's transient T-237 Slurm/DNS
failure. Replace ad hoc exact-name counting with a read-only helper that first
captures the native `squeue`, `qselect`, or `qstat` exit status, validates its
family-specific output, and only then counts exact owner/name matches. It must
also require an absent fixed private result, zero job-scoped capture temps, a
mode-0700 owner state directory when present, and safe bounded arguments. It
must never submit, cancel, mutate scheduler state, inspect result content, or
print unrelated job rows. Add fake-native tests proving Slurm/PBS/AGE query
failures cannot become zero-job passes, plus job/result collision tests. On
success, promote the evidenced fail-closed rule to the native-HPC skill and
verify both Codex and Claude discovery links.

**Implementation checkpoint:** `tools/hpc-job-preflight.sh` validates bounded
job/result/temp identifiers and state-directory metadata, captures each native
query before parsing, recognizes padded Slurm fields, and emits only its
resolved command plus one aggregate. Synthetic tests prove success, query-
failure refusal, exact Slurm collision, PBS/AGE failure refusal, and result
collision. A live local check correctly reports existing job `91220` as one
collision rather than a zero-job pass. Warning-level ShellCheck, portable
phase 1, public audit, and skill installation pass; both clients resolve the
updated shared skill. Commit/distribute before trying absent-name checks on
the other native scheduler families.

**Outcome:** exact implementation commit `2416566` reached every clean remote
with no transfer residue. Live read-only absent-name checks passed on all
seven nodes through native Slurm, PBS Pro, and AGE queries, each reporting an
absent fixed result, zero exact-name jobs, and zero capture temps. The existing
local numerical name independently reports one collision, proving the helper
does not erase a real queued job. T-238 is complete; the same fail-closed rule
is installed for Codex, Claude, and agents through the shared native-HPC skill.

### T-239 — Post-affinity fleet identity and result-hygiene audit

**Phase/status:** `complete`, derived from T-237/T-238. After exact evidence
commit `a93f21b` reached all six remotes, a fresh bounded fleet audit found all
seven nodes clean at that revision, canonical control-plane 34/0/0, the same
complete smoke-tree object `82d3cf9b0532580914f343d90dcb24fe4c1f287d`,
valid private-result metadata, zero capture temps, and zero node failures.
Result counts local/AB/AB2/RI/AL/RC/T4 are 6/10/10/7/10/9/9: this includes the
four completed T-237 remote passes plus RC's preserved v1 diagnostic and v2
pass, but correctly excludes queued AB/AB2 and held local work. The report is
`docs/audits/fleet-readiness-post-affinity-2026-07-17.json`, SHA-256
`6beada610527ea9fb068c496a0d5114ae0ca4e8fb942d4a5b02b70d26feffa71`.

### T-240 — NUMA and topology login-surface audit

**Phase/status:** `complete`, derived from T-237. Add a read-only bounded
probe for the standard affinity/NUMA inspection surface (`taskset`, `numactl`,
`numastat`, `lscpu`, hwloc, and LIKWID) plus an aggregate count of NUMA domains
described by the login process. Require process/sysfs topology metadata and a
successful, numeric `lscpu` result; command failure must not become a zero-node
claim. Publish only present/absent states and counts—no CPU IDs or hostname.
Validate synthetically, commit and distribute, then collect all seven nodes in
one machine-readable audit. Interpret it strictly as login-surface preparation,
not compute-node binding, NUMA performance, or permission to install tools.

**Outcome:** exact probe commit `3255ed0` reached all six clean remotes and all
seven bounded runs passed. Every login surface has Linux affinity/sysfs,
`taskset`, and `lscpu`; five have `numactl`/`numastat`, six have hwloc, and none
has LIKWID. Login NUMA counts range from one to four and remain explicitly
non-compute evidence. The machine-readable audit and human interpretation are
`docs/audits/hpc-topology-login-surface-2026-07-17.json` and
`docs/hpc-topology-login-surface.md`. T-240 is complete; Q10 records a later
allocation-level memory-policy gate behind T-237 rather than submitting more
work now.

### T-241 — Project intake contract for owner-gated HPC branches

**Phase/status:** `complete`, derived from Q5/Q6. Define a strict, public,
value-free schema for the project-owned choices that precede framework or
scientific-library work: targets, locked framework/version evidence,
language/MPI/library ABI features, architecture-matched artifacts, licenses,
native scheduler resources, data/checkpoint/retention references, numerical
success, and runtime credential references. Pair it with an eleven-question
PIE interview that asks one question at a time and keeps the completed manifest
in the project rather than harness. Credential identifiers are allowed;
values, contents, hashes, and copies are forbidden. `status=ready` must not
imply download, billing, publication, or scale authority. Validate schema
closure and critical invariants, run full/public checks, publish, and
distribute without changing any project, package, image, scheduler, or
external service.

**Outcome:** the closed JSON Schema and eleven-question PIE interview are
`docs/schemas/hpc-project-intake.schema.json` and
`docs/hpc-project-intake.md`. They require explicit targets, locks, ABI
features, immutable artifact digests, bounded native resources, data/checkpoint
references, numerical/restart contracts, deferred performance, and value-free
credential references. Focused schema/document tests, warning-level
ShellCheck, portable phase 1, and public audit pass. T-241 is complete as a
preparation artifact; Q5/Q6 correctly remain owner/project gated and no live
project, package, image, scheduler, or service changed.

### T-242 — Read-only local readiness queue diagnosis

**Phase/status:** `complete`, derived from the prolonged T-210/T-217 wait.
Exact native inspection found both jobs immediately eligible, dependency-free,
normal-QOS/nice-zero, one-CPU/2.6-GB/five-minute requests with no node, feature,
license, or reservation constraint. The four-node partition snapshot had one
network-down, one mixed, and two idle nodes, but Slurm still authoritatively
reports `91220` as `Resources` and `91240` as `Priority`, both with unknown
start. Its basic-priority/backfill order places protected Sunday job `90939`
(`BeginTime`, 2026-07-19 00:30) ahead of both; preemption and reservations are
absent. This is a site/scheduler wait, not evidence of a malformed captured
job or permission to bypass `ybatch`. The durable boundary and escalation
condition are in `docs/local-readiness-queue-diagnosis.md`; no scheduler state
changed.

### T-243 — Dependency-free HPC intake validator

**Phase/status:** `complete`, derived from T-241. Implement the exact JSON
Schema subset used by the intake contract with Python's standard library so
every node can validate a project manifest without installing `jsonschema`.
Require a regular non-symlink file under 1 MiB, duplicate-key rejection,
closed-object fields, exact types (including boolean/integer distinction),
required/const/enum/pattern/minimum/unique-item checks, and an optional strict
`--require-ready` gate. Emit only phase and aggregate counts, never values.
Test valid ready/draft forms plus draft-ready, unknown-field, digest,
credential-reference, and symlink failures; run full/public validation,
publish, and distribute without reading any real project or credential data.

**Outcome:** `tools/hpc-project-intake-validate.py` implements the contract's
closed JSON Schema subset using only the Python standard library and provides
the strict ready gate documented in `docs/hpc-project-intake.md`. Synthetic
ready/draft and six refusal paths pass, along with warning-level ShellCheck,
portable phase 1, and public audit. T-243 is complete; no real manifest,
project, credential, package, scheduler, or external service was accessed.

### T-244 — Seven-interpreter intake-validator compatibility

**Phase/status:** `complete`, correcting T-243's untested fleet claim. AL's
default Python is 3.6, so remove postponed annotations and PEP 585 built-in
generic syntax from the dependency-free validator. Replace bytecode compilation
in its test with AST parsing so older clients cannot leave checkout-local
`__pycache__`. Add a syntax-policy assertion, rerun local full/public checks,
publish and distribute, then execute the complete synthetic validator suite on
all seven default interpreters and require clean worktrees afterward.

**Outcome:** correction commit `2ab7743` removes newer annotation syntax and
uses AST parsing without bytecode output. The complete synthetic suite passes
on default Python 3.6.15 (AL), 3.9.25 (AB/AB2/RC/T4), and 3.12.3 (local/RI).
All seven checkouts remain clean and no test or transfer residue exists. T-244
is complete, replacing T-243's previously local-only portability evidence.

### T-245 — Fail-closed intake schema evolution

**Phase/status:** `complete`, derived from T-243. The dependency-free
validator must reject any schema keyword outside its implemented subset before
reading a manifest; otherwise a future constraint such as `maxLength` could be
silently ignored. Recursively audit every schema node while treating property
names separately from keywords, add an unsupported-keyword regression, then
run focused/full/public validation, publish, and distribute. This changes no
manifest, project, credential, scheduler, package, or external service.

**Outcome:** the validator now recursively rejects unknown schema keywords
before manifest parsing, and the synthetic regression proves `maxLength`
cannot be silently ignored. The first import-based test exposed one local
`tools/__pycache__`; guarded plan/apply deleted exactly its two entries with
protected anchors unchanged, and `PYTHONDONTWRITEBYTECODE=1` now contains the
import inside the private test boundary. Focused, portable phase-1, and public-
audit suites now pass with two independent clean no-bytecode postflights.
T-245 is complete without accessing a real manifest or external state.

### T-246 — Eight-hour LLM/HPC durable handoff

**Phase/status:** `complete`. Consolidate only the current active job IDs,
fixed result contracts, completed readiness layers, explicit gates, protected
Sunday jobs, and next safe order into
`docs/llm-hpc-readiness-handoff-2026-07-17.md`. Reconcile it against one final
native scheduler poll, private-result hygiene pass, exact clean fleet head,
origin parity, full/public validation, and the untouched website boundary.
Publish/distribute only after those facts agree; do not convert pending or
owner-gated work into a completion claim.

**Outcome:** the durable capsule records the exact four active jobs, held local
T-237 route, protected Sunday IDs, completed readiness layers, and next safe
order. A 30-minute exact-ID monitor ended with all states unchanged and no
query failure: local remains Resources/Priority; AB/AB2 remain queued with no
exit, result, or temp. Final content-blind result hygiene passes 6/10/10/7/10/
9/9 with zero invalid and zero temporary entries. Before the handoff commit,
all seven checkouts were clean at exact `6e744af`, origin matched, every
transfer artifact was absent, and website's unrelated dirty files remained
untouched. Full/public validation passed, handoff commit `b63bb61` was pushed,
and final fleet distribution reached that exact clean revision with no
transfer artifact. No pending or owner-gated item was reported complete.

### T-247 — Resume captured readiness jobs and final temporary cleanup

**Phase/status:** `executing` under the owner's 2026-07-17 instruction to
resume all tasks, finish every currently authorized action, and then clean
temporary files. The clean local branch and `origin/main` both began at exact
handoff commit `b63bb610e2dc6a1467b98e91dbb1b070ac93d7fd`. Initial fail-closed
native reconciliation confirms local T-210 `91220` remains pending for
resources and local T-217 `91240` remains pending for priority. AB T-237
`2045152.pbs1` and AB2 `2045153.pbs1` remain queued for their already accepted
full `rt_HC` node requests. No fixed result exists yet for those four jobs.

The protected T-191 weekly chain remains captured and singleton: local `90939`,
AB `2044027.pbs1`, AB2 `2044028.pbs1`, RI `6862`, AL `4221054`, RC `210816`,
and T4 `8175651`. Their first eligibility points are Sunday 2026-07-19, so
pending/held state before then is expected. Monitor only exact IDs and fail
closed on scheduler query errors. Never replace, duplicate, reprioritize, or
cancel a delayed job. After both older local readiness jobs are terminal,
fresh-preflight and submit local T-237 exactly once; then close T-237/Q3 and
execute Q10's bounded non-benchmark NUMA gate. Preserve private results and
diagnostic failures as evidence.

Final cleanup starts only after job reconciliation so an active capture is not
mistaken for residue. First run content-blind result hygiene and exact-prefix
metadata inventories on all seven nodes. Remove only verified job-scoped
temporary entries; use guarded plan/apply for every multi-path or recursive
cleanup, exact-unlink only independently revalidated single files, and require
protected anchors plus post-delete absence. Owner-, project-, resource-,
site-support-, external-setting-, and destructive-retention gates remain gates;
the terminal instruction does not supply missing project choices or authorize
Restic retention/prune.

**Initial integrity and residue checkpoint:** full phase 1 passed after the
documented process-local OpenMPI module refresh. Exact head `8e84215` is clean
and connectivity-valid on all seven nodes, matches `origin/main`, and every
bundle transfer reported its artifact absent. Content-blind HPC hygiene passes
with result counts 6/10/10/7/10/9/9, zero invalid metadata, and zero capture
temps. Known harness `/tmp` prefixes, fleet-sync work/bundles, guarded-delete
work/manifests, failed staging/build names, persistent-root restore/probe
prefixes, `run_this.sh`, and `fix_al.sh` are absent. The two tracked `.tmp`
destructive-safety fixtures and private transaction manifests are deliberate
test/rollback evidence, not temporary residue, and remain untouched. All seven
T-191 chain states are active singletons, every disabled smoke successor is
absent, and the fleet has zero running Restic processes before eligibility.

**External-wait checkpoint (2026-07-17 06:14 JST):** repeated fail-closed
native polls across more than three autonomous goal continuations remain
unchanged. Local `91220` is `PENDING/Resources`, local `91240` is
`PENDING/Priority`, and AB `2045152.pbs1` plus AB2 `2045153.pbs1` are queued
with insufficient currently available `ncpus`; all queries succeed and no
terminal accounting or fixed result exists. The safe engineering, integrity,
source-contract, chain-state, and residue work available during this wait is
exhausted. Pause autonomous continuations as externally blocked rather than
spending more scheduler queries. Resume on a later owner request or observed
external state change by polling exactly these four IDs, then follow the
dependency order above. Do not cancel, replace, resize, or reprioritize them.
T-191 still has its independent time gate at the recorded Sunday eligibility
points. No task is complete, failed, or authorized beyond its existing gate.

**Resume checkpoint (2026-07-17 05:52 UTC):** the owner's later resume request
triggered one exact-ID poll. Native local `squeue` still matches owner/job
identity: `91220` (`t210nlocal`) is pending because required nodes are down,
drained, or reserved for higher-priority partitions, and `91240`
(`t217rlocal`) is pending for priority. The initial Git/AB/AB2 SSH attempts
failed after the restart because this process had not inherited the owner's
new agent socket; no scheduler query was misreported as a zero-job result.
After the owner started and loaded the local agent, its owner-controlled socket
enabled a successful fetch proving local `HEAD` and `origin/main` still exact,
followed by the terminal AB/AB2 reconciliation recorded in T-237. No scheduler
write, cancellation, replacement, resize, or reprioritization occurred. The
next action is to monitor only local `91220` and `91240`; after both are
terminal, validate their fixed results and fresh-preflight the one held local
T-237 submission. T-191 remains independently time-gated until Sunday.

### T-248 — Remove obsolete `.bash_common` startup references and files

**Phase/status:** `complete` under the owner's explicit 2026-07-17 request for
all seven managed nodes. Initial value-limited discovery inspected only startup
lines containing `bash_common` plus path metadata. Local and RI already have no
reference and no file. AB2 has the exact reviewed four-line `$HOME`-quoted
reference but no file. AB has that reference and one regular owner file. RC and
T4 have the exact reviewed four-line tilde reference and one regular owner file
each. No other `.bash_profile`, `.profile`, or `.bash_login` reference was
found. AL is temporarily unreachable because its CSCS SSH certificate requires
owner renewal; do not weaken authentication or infer its live state.

Add an explicit `harness remediate --remove-bash-common-reference` mode for all
managed logical hosts. It must accept only either reviewed four-line block or
complete reference absence, reject duplicates/partial/changed blocks and unsafe
metadata, preserve every byte outside the block and the original mode, validate
shell syntax before and after atomic same-directory replacement, and exact-
unlink every private runtime temporary. It intentionally does not remove the
separately managed `.bash_common` path. After focused/full validation, push and
mirror the exact revision, run read-only plans, apply only clean exact plans,
then independently revalidate and exact-unlink at most one regular owner
`.bash_common` file per node. Never use a deletion list, loop, wildcard, or
recursive command. Prove fresh direct/login/interactive shell silence and no
remaining reference/file. Local/RI absence is an idempotent success; preserve
AL as an explicit authentication blocker until its live plan can run.

**Implementation checkpoint:** the new explicit remediation mode recognizes
the two live four-line variants, reconstructs a private same-directory
candidate from the exact byte prefix and suffix, validates its size and Bash
syntax, revalidates the source identity/block immediately before atomic
replacement, preserves owner/mode/link-count invariants, and exact-cleans all
runtime temporaries. It refuses partial, duplicate, changed, symlinked, or
unsafe-metadata inputs and treats complete absence idempotently. Synthetic
tests prove both variants, preceding/following owner-line preservation, mode
preservation, an unrelated fake-secret line remaining only in place, file
separation, ambiguity refusal without mutation, idempotence, and zero temp.
Warning-level ShellCheck, diff checks, and the complete phase-1 suite pass after
the documented process-local OpenMPI refresh. Commit/push/distribute this
implementation before running any live apply or exact file unlink.

**Reachable-node outcome:** exact implementation commit `d4c1856` is pushed
and clean on local, AB, AB2, RI, RC, and T4; every transfer artifact is absent.
Read-only plans kept local/RI and accepted only the exact 85-byte `$HOME`
blocks on AB/AB2 plus the exact 75-byte tilde blocks on RC/T4. All four applies
passed atomic replacement, syntax, metadata, idempotence, and zero-temp checks.
After independent regular/owner/single-link revalidation, three separate exact
`unlink` commands removed the 385-byte `.bash_common` files on AB, RC, and T4;
AB2/local/RI were already absent. All six postflights now prove zero reference,
absent file, original `.bashrc` mode, clean harness checkout, and no remediation
temp. Fresh login and interactive Bash exit zero on all six with zero captured
`bash_common` match; private captures were exact-unlinked.

**AL completion:** after the owner renewed the existing certificate, AL's clean
checkout fast-forwarded from `9686791` to `7be5e45` with no transfer artifact.
Its read-only plan accepted only the exact 75-byte tilde block. The atomic apply
preserved `.bashrc` mode 600, and an independent regular/owner/single-link check
preceded exact unlink of the 385-byte mode-644 `.bash_common`. The idempotent
plan now keeps complete absence; reference, file, remediation-temp, and shell-
capture match counts are zero. Fresh login and interactive Bash both exit zero,
and the private capture was exact-unlinked. This completes all seven nodes.

### T-249 — Canonical aliases and simplified Bash startup workflow

**Phase/status:** `complete`. The common alias/editor/history/prompt policy,
source-only module interface, startup simplifications, and six bounded local
SSH forwarding directives are live and idempotent on all seven nodes. The local
apply/rollback/reapply pilot and every node-specific postflight passed; startup
modes were preserved, all fresh remote sessions received the current agent's
forwarded socket, and every checkout remained clean. Four independent guarded
transactions deleted only the frozen obsolete trees: AB `.pyenv` (55,837
entries), RC `.pyenv` (11,057), T4 `.pyenv` (1,636), and T4 persistent `.venv`
(146,372 entries; 27,444,235,927 logical bytes). RC plan/apply stayed in one
persistent connection. Protected anchors were unchanged; original, quarantine,
temporary boundary, and deletion-manifest paths are absent. No fresh backup was
created, as selected. Implementation and live-rollout evidence begins at
`ce2ccce`, `2e93750`, and `53402ec`.

**Archived frozen plan:** the owner expanded scope to remove `.pyenv`, `.venv`,
and “all unrelated data.” D1-D6 remain resolved. The first
two names are authorized in principle but their exact per-node paths,
boundaries, identities, aggregate contents, and recovery status are not yet
frozen; D7 is now fully resolved. No deletion or startup mutation has run.
Every directory-tree removal must use the guarded
bulk-delete plan/exact-NEXT apply workflow.
Planning discovery was read-only on every live startup file and redacted any
credential-like line before agent output. No startup, package, scheduler,
authentication, or external state changed. The desired outcome is one durable,
testable common alias/editor/history/prompt policy on all seven nodes, no
duplicate alias definitions, alphabetic alias ordering, and a smaller startup
workflow that preserves necessary site behavior. The previously explicit
local-only `al` convenience alias remains excluded from mirroring.

**Confirmed inventory:** all `.bashrc` files are strict regular owner files
with one link. Modes are local 0664, AB 0700, AB2/RI/T4 0644, and AL/RC 0600.
AB, AB2, AL, RC, and T4 select regular `.bash_profile`; local and RI have no
`.bash_profile`/`.bash_login` and select regular `.profile`. Each selected
startup file retains the exact early-cache prefix and managed profile suffix.
The common portable commands required by the local aliases (`vim`, `du`,
`sort`, `head`, `grep`, and `ls`) are visible on all seven nodes.

The current node's safe canonical aliases are `a`, `ducks`, `grep`, `la`,
`ll`, `lla`, `ls`, and `v`, already alphabetic. Alias `al` was value-redacted
and remains local-only by prior owner decision. Existing remote-only names are
AB `hosts`, `interactive`, `interactive_full`, `points`, `usage`; AB2 `hosts`,
`interactive`, `interactive_full`, `points`; RI `alert`, `egrep`, `fgrep`, and
`l`; and T4 `interactive`, `points`. Preserve these unrelated site aliases by
default and sort them; AL has only duplicate `ls`, and RC has none. RI conflicts
with the canonical definitions for `grep`, `la`, and `ll`; every other common
collision is `ls`. The owner's current-node value wins each common-name
collision because the requested source is explicitly canonical.

**Workflow findings:** `shell/profile.sh` already owns `EDITOR=vim` and
`VISUAL=vim`, so copying an editor export into six owner files would add only
duplication. `shell/interactive.sh` runs after each `.bashrc` managed suffix and
currently overwrites the local empty/unlimited `HISTSIZE` and `HISTFILESIZE`
with 50,000 and 100,000. The requested unlimited policy therefore requires a
tracked-layer correction. The current prompt exists only in local `.bashrc`;
RI has a distro prompt and the other nodes inherit site defaults. A tracked
interactive prompt applied last can make the requested `\u@\h:\W\$ ` exact
without replacing whole site startup files.

The early prefix in both the interactive and selected login file is
intentional: cache variables must precede any owner application. The managed
suffix in both files is also retained because login and non-interactive Bash
do not traverse the same source chain on every site; the profile and
interactive helpers are idempotent. Do not remove either control-plane layer
merely because an ordinary interactive login may encounter both.

Five selected `.bash_profile` files (AB, AB2, AL, RC, T4) automatically start
`ssh-agent` when no socket is inherited. This conflicts with the tracked
remote-session model, which intentionally uses the local forwarded agent only
for an explicit `harness_remote_codex` session and otherwise skips private
fetches. AB/AB2 and T4 also unconditionally load large compiler/GPU modules in
`.bashrc`. The owner sometimes deliberately sources `.bashrc` in job scripts
and requires those non-interactive module loads to remain compatible. Do not
make them interactive-only during this task. The safer transition is to extract
the exact reviewed commands into a dedicated tracked, sourceable module-stack
file, have `.bashrc` call that file unconditionally for compatibility, and let
new or updated Bash job scripts source only the dedicated file. A later task
may make `.bashrc` interactive-only only after known jobs have migrated.

Every `.local` is already a declared symlink to large storage, and the common
profile places `$HOME/.local/bin` first and deduplicates it. Most legacy local-
install blocks also set compile variables, so preserve them unless an exact
line is independently proven redundant. One RC `.bashrc` block is a confirmed
defect: it references `DATA` before `.bash_profile` defines it and can prepend
`/.local/bin`; remove that exact block and rely on the already equivalent
`$HOME/.local/bin` link. AB and RC currently have real `.pyenv` trees and
executable links, so preserve their PyEnv blocks; do not repeat AB2's earlier
remediation or infer deletion from old policy. T4 also has a `.pyenv` tree but
no startup call. Preserve all other Python, compiler, cache, distributed,
completion, site, and owner lines unless a frozen interview decision names an
exact block.

**Careful line-group review and simplification proposal:** comment-only headers
and blank separators have no runtime cost and should not be churned unless the
adjacent executable block is removed. On every node, keep the seven-line early
cache prefix first and the managed profile loader; keep the selected login
file's `.bashrc` source. Current and RI correctly have no `.bash_profile` and
must continue using their existing `.profile` rather than creating a higher-
precedence file. Keep `/etc/bashrc` sourcing on RC/T4 and the normal RI
interactive guard, completion, `checkwinsize`, `lesspipe`, and `dircolors`
features. The remaining per-node classification is:

- `local .bashrc`: move the eight safe common aliases into D1's alphabetic
  tracked fragment, retain only the redacted local-only `al` alias in a labelled
  owner block, and remove the now-duplicate editor/history/prompt lines. `FS` is
  only `$HOME`; its `.local/bin` export duplicates `shell/profile.sh`, while
  global `CPATH`, `LIBRARY_PATH`, `LD_LIBRARY_PATH`, and `PKG_CONFIG_PATH`
  affect every compiler/linker process and are not used by harness. D4 removes
  this entire legacy install block in favor of managed/project/module paths.
- `AB .bashrc`: retain interactive-only `stty -ixon` and the explicit no-pager
  preference. Remove duplicate `ls`; remove `hosts`, `interactive`, and
  `interactive_full` because login-shell checks prove `qrsh` absent and the
  current scheduler is PBS rather than SGE. Retain working `points` and AB's
  `usage` alias; its referenced strict regular owner data file exists. Replace
  the inline module block with D3's unconditional compatibility hook.
  `AB .bash_profile`: retain `.bashrc` sourcing; remove D2's agent block and the
  dead commented MPI line. D5 removes the six-line PyEnv initialization because
  the owner no longer uses PyEnv; its existing tree remains outside this task.
- `AB2 .bashrc`: make the same `stty`, pager, broken `hosts`/`interactive*`,
  working `points`, duplicate `ls`, and D3 module decisions as AB. `AB2
  .bash_profile`: retain `.bashrc` sourcing, remove the six inert fixed-width
  comments left by the completed PyEnv remediation, remove D2's agent block,
  and remove the dead commented MPI line.
- `RI .bashrc`: keep the early prefix, but move the silent managed profile
  loader before the non-interactive return so direct Bash obtains the managed
  local-bin/editor/cache environment while `shell/interactive.sh` still gates
  aliases, history, prompt, login sync, and warnings on `$-`. Remove the
  overridden distro history limits/control, prompt/title construction, and
  common aliases. Retain `checkwinsize`, `lesspipe`, `dircolors`, and Bash
  completion. Remove `alert` because `notify-send` is absent; remove deprecated
  `egrep`/`fgrep` aliases and the absent `.bash_aliases` hook; retain simple
  site-only `l` unless the owner later rejects it. No `.bash_profile` exists.
- `AL .bashrc`: remove duplicate `ls` plus the obsolete start-image comments;
  the tracked `prgenv` function already provides the explicit uenv entry. `AL
  .bash_profile`: retain `.bashrc` sourcing, remove D2's agent block, and remove
  D4's redundant/risky local-install exports. The declared `.venv` is
  absent; D6 removes `UV_VENV_ROOT` and `activate` because the owner does not
  use the helper.
- `RC .bashrc`: retain `/etc/bashrc` and the no-pager preference; remove the
  exact pre-`DATA` path block that can introduce `/.local/bin`, because the
  managed `$HOME/.local/bin` resolves to the same large-storage installation.
  `RC .bash_profile`: retain `.bashrc` sourcing; remove D4's `DATA` and global
  install/build exports, remove D2's agent block, and remove the PyEnv
  initialization under D5 because the owner no longer uses it. Do not delete
  the existing tree in this startup-file task.
- `T4 .bashrc`: retain `/etc/bashrc`, working `interactive`/`points` aliases,
  and replace inline modules with D3's unconditional compatibility hook. Remove
  the eager backtick Makefile completion: both home Makefile spellings are
  absent and sourcing general startup must not scan the current directory.
  `T4 .bash_profile`: retain `.bashrc` sourcing. Remove D4's `FS` and global
  install/build exports. Remove redundant `PYTHONUSERBASE`, the conflicting
  `UV_CACHE_DIR`, and D6's unused `.venv`/`activate` helper. The existing
  persistent `.venv` directory remains untouched.
  Remove login-wide `MPLBACKEND=Qt5Agg` and nonexistent `/tmp/runtime-$USER`;
  projects/jobs must choose a GUI/headless backend and create a private runtime
  directory when needed. Remove D2's agent block. Move `MASTER_ADDR` derivation
  into distributed job scripts. Add portable `HF_HOME` under the declared
  harness cache root and remove the slow-storage override. Keep canonical
  `APPTAINER_CACHEDIR` in `shell/cache.sh`; move `APPTAINER_TMPDIR` into T4 job
  setup because `T4TMPDIR` is absent on login and supplied only in jobs.

Read-only D4 impact discovery found `.local/include`, `.local/lib`, and
`.local/lib/pkgconfig` all absent on local, AL, RC, and T4. The removed global
build variables therefore point at no current user installation surface. Live
acceptance still requires `$HOME/.local/bin` first through the managed profile,
all managed tools visible, exact D3 module stacks, shell-mode silence, and the
full harness validation suite; unknown private scripts require a named test and
cannot be declared compatible from startup inspection alone.

These proposals remove only exact reviewed executable/comment groups. They do
not minify whole files, remove site initialization, create a `.bash_profile`,
or treat a missing direct-shell command as evidence when a safe login-shell
probe found it present. The dedicated module interface remains source-only and
must not be placed in the early cache layer, whose side-effect-free contract is
unchanged.

**Automatic-forwarding scope added by D2a:** the current node's strict regular,
owner, mode-0600, single-link `.ssh/config` has one unique stanza for each of
AB, AB2, AL, RC, RI, and T4 before `Host *`, no visible `ForwardAgent`
directive, and filtered `ssh -G` reports `forwardagent no` for all six. The
current session has an agent socket; its keys were not enumerated. Insert only
`ForwardAgent yes` into those six existing stanzas, never `Host *`, proxy, web,
or GitHub stanzas. Revalidate through filtered `ssh -G`, store only the public
inserted directive in transaction evidence, preserve mode and unrelated bytes,
and provide exact rollback. This current-node SSH setting is intentionally not
mirrored to remotes.

**Frozen non-goals and boundaries:** never read, hash, copy, or persist a
credential value; never copy `.bash_history`; except for D2a's six exact local
`ForwardAgent yes` insertions, do not change SSH configuration. Do not inspect
agent keys or change agents/keys, packages, modules themselves, scheduler state,
projects, system files, or Restic policy. Do not symlink whole startup files or publish their
unrelated contents. No raw recursive/bulk deletion is needed. A live apply must
accept only reviewed public blocks or complete idempotent absence, require a
clean exact harness revision and strict file metadata, preserve all bytes
outside those blocks plus original modes, and fail closed on drift, duplicate,
partial, symlinked, or ambiguous inputs.

**Execution sequence after explicit go:** (1) reconstruct this ledger and
revalidate Git/fleet/startup metadata; (2) add a sorted tracked common-alias
fragment or literal per-file blocks according to D1, with fake-home tests and a
local-only `al` exclusion; (3) make the tracked interactive policy enforce
unlimited in-memory/on-disk history, `histappend`, editor defaults, and the
exact current prompt; (4) implement a plan/apply normalizer that recognizes
only the seven reviewed alias layouts, removes common duplicates, sorts
retained site aliases, removes local duplicate common policy, and removes the
exact defective RC path block; (5) remove D2's remote `ssh-agent` blocks and
transactionally add D2a's six exact local SSH directives, with filtered
effective-config validation; replace AB/AB2/T4's exact inline module blocks
with the D3 source-only compatibility hook and tracked module-stack helper;
(6) store only reviewed public
original/applied payloads in mode-0600 transaction state, build same-directory
private candidates, run `bash -n`, revalidate identity/size/bytes immediately
before atomic rename, preserve mode/owner/single-link state, and exact-clean
runtime temporaries; (7) prove plan/apply/idempotence/rollback, changed-input
refusal, alphabetic order, one definition per name, local-only exclusion,
synthetic-secret preservation without copying it into transaction state, and
zero residue; (8) run warning-level ShellCheck, focused tests, `git diff
--check`, portable and native phase 1, and the public-repository audit; (9)
fetch, review, commit, push, and fleet-sync the exact implementation before any
live plan; (10) run seven read-only plans, pilot local apply/rollback/reapply,
then apply one node at a time with transaction IDs and immediate postflight;
and (11) push the compact outcome checkpoint and mirror that exact revision.

**Acceptance gates:** all seven effective interactive shells expose exactly
one canonical definition for each mirrored alias and the exact canonical
value; retained site aliases occur once and are alphabetic in their owning
block; `al` exists only locally. `EDITOR`/`VISUAL` are `vim`, both history
limits are unlimited, history appends, and the prompt is exact. Fresh direct
SSH and non-interactive Bash remain silent; login, interactive, and nested Bash
exit zero; cache roots, logical host, local-bin precedence, D3's identical
module stack after both non-interactive `.bashrc` sourcing and direct helper
sourcing, remote Codex function, and scheduler warning
behavior remain valid. Filtered `ssh -G` reports forwarding yes for exactly the
six managed remote aliases while proxy/service/global behavior is unchanged;
no key is enumerated or copied. Startup modes/owners/single links are unchanged, every
plan becomes KEEP, rollback evidence is valid, checkouts are clean at one
pushed revision, and transfer/normalizer/shell-capture artifacts are absent.

**Risks and recovery:** alias name collisions can silently change command
semantics, so canonical-name values are explicit and site-only names are
preserved. Moving module commands behind a helper can break jobs if the hook,
host dispatch, or source semantics drift; D3 retains unconditional `.bashrc`
compatibility and requires matched old-versus-new module-state postflights
before job scripts are migrated. Removing
automatic agents can affect users who relied on a newly spawned unforwarded
agent; D2 is explicit. Automatic forwarding exposes the current node's agent
socket to processes with access to each selected remote account for the SSH
session lifetime; D2a deliberately limits this to six named hosts and never
copies private keys. Startup precedence or partial mutation can break login,
so candidates receive syntax and byte/metadata checks, each node stops
independently on drift, and exact transaction rollback is tested before fleet
rollout. A live rollback never restores or stores unrelated startup bytes.

**Decision register:** D1 (resolved: central tracked common policy) defines the
eight portable aliases and editor/history/prompt behavior once in the tracked
interactive layer loaded by every managed `.bashrc`. Remove their duplicate
owner-file definitions; keep `al` local-only and keep unique sorted site aliases
outside the common fragment. This follows the documented harness model, fixes
the effective history override, and avoids literal fleet duplication. D2
(resolved: remove) removes the five automatic remote `ssh-agent` startup
blocks without terminating any existing process. Those blocks spawn an empty
per-login agent and do not load a key; usable authentication continues through
an agent already running on the current node and forwarded access. D2a is
resolved as automatic forwarding for exactly AB, AB2, AL, RC, RI, and T4
through the current node's existing host-specific SSH stanzas; never place it
under `Host *` or mirror it remotely. D3 is resolved as the compatible
dedicated module-stack design: extract the exact AB/AB2/T4 commands into one
tracked source-only interface, replace each inline block with an unconditional
call so existing job scripts that source `.bashrc` still work, and recommend
that new or updated Bash jobs source the dedicated interface directly. This is
preferred over either silently breaking existing jobs or preserving module
commands inside a general interactive file forever. The canonical collision rule, retention
of unique site aliases, local-only `al`, exact RC path-block removal, and
minimal preservation of all other startup content are resolved by the owner's
request, prior decisions, and the preserve-unrelated-work boundary.

D4 is resolved as removal of the entire legacy global install/build blocks on
local, AL, RC, and T4, including `FS`/`DATA`, redundant PATH additions, and
include/library/pkg-config exports. Managed `$HOME/.local/bin` and
`HARNESS_PERSISTENT_ROOT` replace the valid portions; aggregate discovery found
no current `.local` include/library/pkg-config surface. D5 is resolved as
removal of AB/RC PyEnv initialization because the owner no longer uses PyEnv;
managed uv/Python 3.12 remains canonical and the existing directories are not
part of this task. D6 is resolved as removal of the unused AL/T4
`UV_VENV_ROOT` plus `activate` helpers; future use is explicit through `uv run`
or direct activation. D7 resolves the newly authorized deletion of exact
`.pyenv`/`.venv` trees. The owner resolved “all unrelated data” as exactly the
four inventoried trees and nothing broader. Their absolute paths and retained
boundaries were frozen; the guarded transactions are complete.
All other per-node decisions above are
resolved from live command/path evidence, the frozen common policy, or clear
broken/conflicting behavior.

**D7 metadata-only deletion inventory:** exactly four candidate trees exist.
AB `/home/aca10017by/.pyenv` is a mode-0750 owner directory with 55,837
same-filesystem entries and 6,522,612 KiB apparent usage. RC lexical
`/home/users/rio.yokota/.pyenv` (canonical home is
`/hs/work0/home/users/rio.yokota`) is mode 0755 with 11,057 entries and 335,976
KiB. T4 `/home/8/uq02038/.pyenv` is mode 0755 with 1,636 entries and 15,384
KiB. T4 `/gs/bs/jh250019/yokota/.venv` is a mode-2755 owner directory; its
full metadata walk was deliberately stopped after exceeding the planning
window, and both local/remote probe processes are absent. The guarded planner
will compute its authoritative identity/count/bytes if selected. Every checked
home `.pyenv`/`.venv` and persistent-root `.venv` on the other nodes is absent.

Each existing tree requires its own retained canonical boundary: AB home; one
persistent RC connection that binds lexical/canonical home; T4 home; and T4
persistent root. Do not combine those boundaries, use a glob/list/loop remover,
or delete before startup references are transactionally absent and managed
uv/Python plus known shell workflows pass. The exact guarded plan must publish
a fresh mode-0600 manifest, and apply must use only its emitted NEXT command
within 15 minutes, revalidate identity/count/bytes, preserve anchors, and prove
the target absent. No broader target exists.

**D7 frozen recovery/deletion sequence:** the owner selected no fresh backup.
After the exact startup changes and their first live validation, independently
revalidate each source directory and atomically rename it to one unique
same-parent quarantine name on the same filesystem. Record its identity and
prove the original name absent; if any subsequent pre-delete shell, managed
Python/uv, module, tool, cache, login, direct, interactive, nested, or known job-
entry gate fails, restore only that unchanged quarantine to its original name.
If all gates pass, create four separate guarded-delete plans/manifests—never a
loop or combined boundary—and execute only each emitted exact NEXT command
within its freshness window. RC planning/apply stays in one persistent
connection so lexical/canonical home identity cannot drift. After apply, prove
original and quarantine names absent and retained anchors unchanged. Historical
home snapshots may incidentally contain older PyEnv data, but no recovery is
claimed; T4 persistent `.venv` has intentionally no guaranteed recovery after
deletion.

The owner then requested continued PIE discussion backed by a careful
line-by-line review of `.bashrc` and `.bash_profile` on all nodes. That review
and its value-limited supporting checks are complete. The startup decision
audit found no gaps or contradictions. Its frozen execution order
is: implement and synthetically validate the tracked common policy, module
interface, exact startup normalizer, and exact local SSH-forwarding transaction;
run all focused/full/public gates; publish and distribute the exact clean
implementation; run seven read-only plans; pilot local apply/rollback/reapply;
apply and independently validate one node at a time; then publish/distribute the
compact completion evidence. Stop on any metadata/content drift, syntax or
shell-mode regression, module mismatch, managed-tool loss, SSH effective-config
mismatch, dirty checkout, or incomplete rollback. D7's deletion set is frozen
as only the four exact obsolete environment trees above; no broader audit or
deletion is in scope. The owner selected same-filesystem quarantine and full
validation followed by irreversible guarded deletion, with no fresh backup.
The complete D1-D7 register was internally consistent, and the owner's explicit
`go` executed only this frozen T-249 plan. All acceptance gates passed.

## Stable operational facts

- The 2026-07-15 accident was an agent-issued raw recursive deletion of
  `/home/rioyokota` after a temporary `HOME` assignment expired. Processes were
  terminated; no usable whole-home filesystem snapshot existed. Harness and
  website recovery are complete. Unknown former profiles and `sshservice-cli`
  remain intentionally unreconstructed.
- The guarded-delete schema protects lexical and canonical account homes,
  binds immutable manifests to exact identities/counts/bytes, revalidates
  immediately before apply, and verifies anchors afterward. RC and load-balanced
  AL require the documented canonical-home/persistent-session handling; never
  weaken the guard.
- `/mnt/nfs-03` is a hard NFSv4.2 mount whose metadata latency makes large
  small-file restore/cleanup trees extremely slow even when throughput and
  capacity are healthy. Keep packed repositories/generations on large storage
  and materialize restore tests on node-local mode-0700 scratch.
- AL authentication uses the owner's existing `id_ed25519` certificate renewed
  by `cscs-key sign --headless -f ~/.ssh/id_ed25519`. The local `al` convenience
  alias is intentionally owner-only in the current node's `.bashrc` and must
  not be mirrored.
- AB2's 10 TB group quota is active. Its `.local` migration, approved cleanup,
  primary, independent generation, full-data checks, restores, and guarded
  cleanup completed under T-192. `.bash_history` remains node-local.
- `profiles/home-layout.tsv`, `profiles/restic-repositories.tsv`, host profiles,
  `docs/environment-portability.md`, `docs/home-backup.md`, and
  `shared/skills/operate-native-hpc/references/sites.md` are the canonical
  current declarations; do not copy obsolete ledger prose back into them.

## Completed-task index

Git history is the durable evidence store. Consult the pre-compaction version
of this file at `303938f:TODO.md` and the named commits when command-level detail,
transaction IDs, aggregate counts, hashes, or failure chronology is required.

| Task | Completed outcome / durable pointer |
|---|---|
| T-169 | Advanced-harness research and proposal inventory completed. |
| T-170 | Seven-node portable environment parity completed; capability design is in `docs/environment-portability.md`. |
| T-171 | Current-home incident contained and recoverable tracked/tool state restored; safety commits include `68fb820` and `238f022`. |
| T-172 | Exhaustive Git recovery re-audit found no additional candidate. |
| T-173 | ShellCheck 0.11.0 reconstructed as checksum-pinned new work at `2222fc5`. |
| T-174 | Test cleanup routed through guarded deletion. |
| T-175 | Local-only pinned lftp restored at `292c6b4`; website validation at `362847d`. |
| T-176 | Internal transaction tree cleanup routed through guarded deletion. |
| T-177 | Restored ShellCheck findings fixed and warning-level lint made durable. |
| T-178 | Hyphenated tool fact-key normalization completed. |
| T-179 | ABCI PBS command discovery reconciled without startup-file sourcing. |
| T-180 | Aggregate plans now enforce pinned Node/npm versions. |
| T-181 | Seven-family acceptance evaluation completed: clean pilot 18/18; full deterministic 69/70 with zero safety failures, 13 reviewed pairs, one recorded semantic-oracle false negative, and no candidate adoption. Evidence is in `evaluation/results/`, commit `ee96853`; post-experiment hardening is `d26c5a3`. |
| T-182 | Seven-node storage, shell/control-plane, Restic, and independent-generation workflow completed; exact evidence spans commits through `303938f`. |
| T-183 | Credential-safe private-origin login sync and explicit remote Codex launcher completed at `2c2dff0` and `4f34299`. |
| T-184 | Truncated guarded-delete manifest publication rejected at `f31aeb5`. |
| T-185 | Non-interactive managed Restic resolution completed. |
| T-186 | AL authentication migrated to owner-renewed `cscs-key`; obsolete helper removed. |
| T-187 | AL guarded plan/apply constrained to one persistent login session. |
| T-188 | NFS-independent local replica at T4 passed full check/restore (`56c15a7`). |
| T-189 | Ledger-backed PIE skill created and validated at `dfaea9e`. |
| T-190 | Automated guarded mirrored-node onboarding skill completed, installed, tested, and published at `b5bb171`. No live node was onboarded. |
| T-192 | AB2 quota deferral, primary, replica, restore, migration, and cleanup completed at `1c2050a` and `303938f`. |
| T-249 | Seven-node startup normalization, bounded agent forwarding, and four exact guarded environment deletions completed; durable evidence begins at `ce2ccce`, `2e93750`, and `53402ec`. |
