# Harness evolution milestones

Evidence scope: complete linear Git history from root
`7f969317c4b597b9adaae629c05cf6723785aff2` (2026-07-14) through
`f25429546bf8114b3309f26e3d3242feae191a30` (2026-07-21). The repository has
542 commits, no merge commits, and no tags; first-parent history is therefore
the complete commit history. Motivations below are stated only where the
repository records them; otherwise they are labeled interpretation.

## Stage 1 — Portable policy separated durable intent from private client state

**What existed before.** No repository implementation precedes the root commit.
The first meaningful version was Codex-only: a fail-closed symlink installer,
global working agreements, command rules, and six reusable skills.

**Problem or limitation.** The client runtime directory mixed durable behavior
with credentials, sessions, caches, and other private or high-churn state that
was unsafe to version. The first commit also served only Codex.

**What changed.** Commit `7f969317` created a portable, non-sensitive layer and
explicitly excluded live configuration and authentication. Commit `805db485`
reorganized the same policy and skills for Codex and Claude discovery.

**Evidence.** `7f969317:README.md`, `7f969317:install.sh`,
`7f969317:AGENTS.md`; `git show --stat 805db485`; current `README.md`.

**What it enabled.** One reviewed source could reconstruct the clients' shared
working agreements and reusable workflows without copying their private state.

**Remaining limitations.** There was no fleet model, executable harness
command, health check, transactional mutation, or acceptance suite. The layer
installed links; it did not yet operate environments.

## Stage 2 — Value-free observation replaced host-by-host guesswork

**What existed before.** The harness could expose policy and skills on a local
machine, but it had no representation of heterogeneous Linux/HPC environments.

**Problem or limitation.** Site differences in OS, architecture, scheduler,
module system, and available commands could not be compared safely without
reading arbitrary environment or startup-file contents.

**What changed.** Commit `fb417282` added the `harness` dispatcher,
dependency-free `inventory`, `plan`, and `doctor`, strict logical-host profiles,
value-free fixtures, and the first phase-one tests. The architecture explicitly
kept site substrates authoritative instead of normalizing them.

**Evidence.** `docs/environment-portability.md`; `bin/harness`;
`libexec/harness-{inventory,plan,doctor}`; `profiles/hosts/`;
`tests/fixtures/*.facts`; `tests/test-phase1.sh`.

**What it enabled.** A host could be observed, compared with reviewed policy,
and declared ready or not ready before any write. Captured facts also made the
same plan reproducible offline.

**Remaining limitations.** Observation alone could not make a host converge.
The rollout still depended on manual coordination, and a plan was not a
rollback mechanism.

## Stage 3 — Transactions converted plans into bounded, reversible operations

**What existed before.** The harness could explain desired versus observed
state but could not apply it safely.

**Problem or limitation.** Direct edits and manual installs risked partial
state, unmanaged collisions, implicit dependency changes, and rollback based on
assumptions rather than recorded preconditions.

**What changed.** `07351a40` added control-plane apply and rollback;
`42e9a119` added suffix-verified shell transactions; `37ff256a` added
checksum-pinned tool transactions. Later runtime, Python, source-build, agent,
dotfile, storage, and exact-remediation operations reused the same plan/apply/
unchanged-only-rollback pattern. `1ed9712` extended it to verify-before-promote
agent replacement and interruption recovery.

**Evidence.** `README.md` “Transactional control plane”; `libexec/harness-apply`;
`libexec/harness-rollback`; `libexec/harness-shell`;
`libexec/harness-{tool,runtime,python,agent,build-tool}`; `tools/*.tsv`;
`tests/test-agent-upgrade.sh`.

**What it enabled.** The harness became an executable control plane rather than
only a configuration repository: mutation defaulted to plan mode, recorded its
scope, validated preimages, and failed closed when live state drifted.

**Remaining limitations.** Transactions were operation-specific, not a claim
that arbitrary package-manager or site changes were reversible. Site software,
credentials, and project runtimes remained outside the owned layer.

## Stage 4 — Safety and recovery became first-class lifecycle operations

**What existed before.** Transactional commands protected their own managed
paths, but recursive cleanup, hidden-home recovery, recurrence, and fleet Git
distribution still lacked common gates.

The transition was forced by a concrete failure. At approximately 01:41 JST on
2026-07-15, a temporary-`HOME` plan command allowed cleanup to resolve to the
real account home and launched `rm -rf /home/rioyokota`. The first cancellation
did not kill the child process. The incident caused partial account-home loss,
required bundle/HEAD-based restoration, and left some uncommitted or
non-reconstructable state intentionally unrecovered. See
`presentation/evidence/incident-rm-rf.md` and commit `e5200fd`.

**Problem or limitation.** Broad deletion could outgrow a reviewed target;
backup success without full-data checks and restore evidence was insufficient;
and copying a dirty tree across nodes could create untraceable divergence.

**What changed.** In direct response, `238f022` introduced
manifest/token/revalidation guarded
deletion. `4f34299` added encrypted Restic backup, full-data check, restore, and
independent encrypted-generation gates. `852b84b` added scheduler-native
exactly-one-successor weekly jobs without login cron or retention deletion.
`e8b0e9a` added prerequisite-bound Git-bundle fleet fast-forward.

**Evidence.** `shared/skills/guarded-bulk-delete/`; `docs/home-backup.md`;
`profiles/restic-{repositories,schedules}.tsv`;
`docs/audits/restic-first-weekly-2026-07-19.md`;
`libexec/harness-fleet-sync`; `tests/test-{guarded-delete,restic-schedule,fleet-sync}.sh`.

**What it enabled.** Destructive cleanup, backup/restore, recurrence, and fleet
distribution acquired explicit boundaries, immutable evidence, and retry-safe
failure states.

**Remaining limitations.** Keep-all retention remains in force; recurrence does
not automate full-data checks, restores, replicas, or pruning. Fleet sync works
only for clean, ancestry-compatible managed checkouts.

## Stage 5 — Measurement and native execution made evidence part of control

**What existed before.** The harness had tests and host facts, but login-surface
capability could be mistaken for compute readiness, and plausible guidance
changes lacked a frozen comparative experiment.

**Problem or limitation.** A common wrapper could conceal scheduler semantics,
and local success could not establish seven-node correctness. Intuitive prompt
changes could add cost without measurable benefit.

**What changed.** `05932762` added a frozen, paired acceptance evaluator;
`ee968531` published its 70-run result; `f6b9909` added portable read-only CI.
Scheduler-native smoke programs and job routes then recorded CPU readiness on
7/7 nodes (`25efb7b`), accelerator driver/runtime readiness on 7/7 with five
kernel passes and two declared toolkit skips (`40b40da`), and five passing
single-node MPI routes. Tests and audit JSON preserve command, source, status,
and limitation boundaries.

**Evidence.** `evaluation/`; `docs/evaluation-follow-up.md`;
`.github/workflows/ci.yml`; `docs/hpc-readiness.md`;
`docs/audits/hpc-*-readiness-*.json`; `tests/smoke/`.

**What it enabled.** Evidence could reject a candidate: T-181 retained the
baseline because the candidate showed no substantive correctness gain and cost
more on the frozen corpus. Native readiness results could support precise
claims without pretending heterogeneous schedulers or environments were
identical.

**Remaining limitations.** T-181 is corpus/model/environment-specific. Its
canonical result is 69/70 deterministic passes, while targeted review judged
all 70 substantively acceptable; neither number generalizes. HPC checks are
bounded correctness/readiness gates, not performance, scaling, or production
training benchmarks.

## Stage 6 — The public control plane expanded to Macs without absorbing private intent

**What existed before.** The executable control plane and fleet evidence were
Linux/HPC-centric. Codex/Claude public policy existed, but personal-Mac
identity, package choices, shell bytes, and SSH payloads required a different
privacy boundary.

**Problem or limitation.** Treating Macs like mirrored Linux nodes would expose
private desired state or over-normalize Homebrew, login-shell, and local
configuration behavior. A historical private Bash/tmux bundle duplicated what
could be public cross-platform configuration.

**What changed.** `a0b74a4` added a Darwin-specific, value-minimized engine
backed by a strict private companion. `4209ee8` promoted Bash hooks and tmux to
public cross-platform configuration and added a recoverable forward-only bridge
to SSH-only private intent. `6a7e177` added public Codex/Claude configuration
transactions. Subsequent commits made bootstrap, adoption, Homebrew, login
shell, SSH sync, and long-gap catch-up explicit.

**Evidence.** `docs/personal-macos.md`; `docs/personal-macos-config-sync.md`;
`docs/agent-client-config.md`; `profiles/personal-macos/`;
`libexec/harness-macos-*`; `config/agent-clients/`; focused Mac tests.

**What it enabled.** One public engine could operate Linux/HPC and personal-Mac
families while private identity and payloads remained owner-controlled and out
of public Git. Three reachable Macs are recorded accepted at HEAD.

**Remaining limitations.** One owner-operated Mac is still availability-gated.
Homebrew package changes are bounded but not transactionally reversible, and
authentication/TCC/administrator interactions remain explicit human gates.

## Stage 7 — Cross-client cowork turned shared policy into a symmetric execution protocol

**What existed before.** Codex and Claude consumed common instructions and
skills, and Git/TODO supported takeover, but there was no bounded protocol for
both native clients to independently test, criticize, reconcile, and execute
one consequential plan.

**Problem or limitation.** Informal co-pilot exchange could blur authority,
allow target mutation by both clients, lose provenance across handoff, or treat
filesystem permissions as stronger confinement than they were.

**What changed.** `535a492` added the client-neutral driver/co-pilot skill,
forward-only state machine, staged exchange, external seals, receipts,
reciprocal critique, and driver-only target execution. `bb11854` bound exact
prompts, added deterministic status and bounded waiting, made focused-test
workers affinity-aware, and removed duplicated CI steps while retaining the
complete gate.

**Evidence.** `shared/skills/codex-claude-cowork/`;
`docs/audits/t283-cowork-acceptance.md`;
`docs/audits/t284-cowork-acceptance.md`;
`tests/test-codex-claude-cowork-skill.sh`; `tests/test-focused-runner.sh`.

**What it enabled.** Both product directions could contribute evidence without
sharing target-write authority. Sixteen tracked sessions across T-283 and
T-284 preserve plans, independent evidence, reciprocal critique, execution,
validation, and receipts.

**Remaining limitations.** Hashes and receipts prove byte relationships, not
model authorship, honest inputs, or OS confinement. PID identity is advisory;
some timeout behavior cannot preempt a blocked filesystem read. Speed evidence
is host- and affinity-specific.

## Cross-stage reversals that changed the design

- `e52a3d0` removed automatic login fetch/fast-forward and exit-time publish;
  synchronization and publication are now explicit.
- `f1b095c` removed website-specific ownership and added a repository-
  independence regression.
- `fd5c3b1` rejected the T-181 candidate despite a plausible mechanism because
  it produced no measured substantive gain and added cost.
- `4209ee8` replaced duplicated private Bash/tmux payloads with public
  cross-platform sources plus an SSH-only private boundary.
- `d76575c` reversed managed native-Codex ownership: the harness now owns policy
  and a wrapper while the native client installation stays local.

These are facts about recorded changes. The interpretation used in the deck is
that the harness matured by narrowing ownership and making authority more
explicit, not merely by adding commands.
