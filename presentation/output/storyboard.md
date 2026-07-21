# Harness evolution storyboard

## Central thesis

**The harness evolved from a portable layer for non-sensitive agent policy into
a transactional, evidence-driven control plane by repeatedly making authority,
state, and system differences explicit.**

This is an interpretation grounded in the seven documented stages. The deck
does not claim that repository size, command count, or commit count measures
quality.

## Audience, timing, and visual system

- Audience: technical leaders, researchers, and engineers unfamiliar with the
  harness but comfortable with software-system diagrams.
- Main deck: 12 slides / approximately 18–20 minutes; appendix follows.
- Format: 16:9 editable PowerPoint with native text, shapes, connectors, and
  charts. Only the cover background may use generated raster artwork.
- Stage colors: foundation = blue; observation = cyan; transactions = teal;
  safety/recovery = amber; evidence/native execution = violet; cross-platform
  expansion = magenta; cowork/current = green.
- Claim encoding: solid cards/lines = repository fact; hatched or outlined card
  with “Interpretation” pill = synthesis; gray dashed boundary = deliberate
  exclusion or open question; amber “scope” callout = measurement limitation.
- Footer: abbreviated commit/path references on every substantive slide; full
  citations live in `sources.md`.

## Narrative dependency

Slides 1–4 establish the initial boundary. Slides 5–8 explain why each new
capability required a stronger control contract. Slides 9–10 compare the
resulting architecture and evidence. Slide 11 shows that subtraction and
reversal were part of the evolution. Slide 12 closes with the current system
and the next design question. The appendix preserves methods, detailed matrices,
and limitations without slowing the main narrative.

## Main deck

### Slide 1 — The harness became a control plane by making authority explicit

**Purpose.** State the central thesis and frame the story as an evolution of
control boundaries rather than a feature chronology.

**Evidence.** Root `README.md` at `7f969317`; observation at `fb417282`;
transactions at `07351a40`; current command surface at `f254295`.

**Proposed visual.** Dark cover with non-evidentiary generated artwork: one
thin blue thread becomes a structured network of bounded nodes, ending in a
clear green control loop. Add only native PowerPoint title/subtitle/date text.
No generated labels, logos, or technical claims.

**Speaker-note summary.** “This began as a safe way to version agent guidance.
In one week it became a control plane across heterogeneous Linux/HPC and Mac
systems. The through-line is not feature count: every major step made who may
change what, from which evidence, and with what rollback more explicit.”

**Sources.** `7f969317:README.md`; `fb417282`; `07351a40`; `README.md`; `bin/harness`.

### Slide 2 — The first harness protected portable intent—not machine state

**Purpose.** Explain the original problem and the first meaningful solution.

**Evidence.** Root commit: 18 tracked files, six skills, fail-closed symlink
installer; explicit exclusions for credentials, sessions, histories, caches,
plugins, and live configuration.

**Proposed visual.** Native “inside/outside” diagram. Left: versioned core with
Policy, Rules, Skills, Installer. Right: large gray excluded cloud with
Credentials, Sessions, Caches, Live config. A narrow arrow labeled “known
symlinks only” connects the core to one Codex client; a smaller added Claude
client badge shows the next `805db485` step.

**Speaker-note summary.** “The original harness was intentionally small. Its
achievement was choosing the boundary: durable, non-sensitive intent in Git;
private and high-churn runtime state outside. It reconstructed discovery links
and refused collisions, but it did not operate environments.”

**Sources.** `7f969317:README.md`; `7f969317:install.sh`; `7f969317:AGENTS.md`;
`805db485`.

### Slide 3 — Seven architectural shifts turned discovery into controlled execution

**Purpose.** Give the audience the complete historical map before drilling
into selected pivots.

**Evidence.** The 25-event timeline grouped into seven evidence-backed stages;
542 linear commits; no tags or merge commits.

**Proposed visual.** One horizontal native timeline from 14–21 July 2026 with
seven colored stage blocks, five labeled anchor commits, and three downward
“reversal” notches. Use brief stage verbs: Protect → Observe → Transact →
Recover → Measure → Expand → Collaborate. A small fact capsule reads
“542 linear commits • 0 tags • complete first-parent history.”

**Speaker-note summary.** “Because the history is fully linear, first-parent is
the complete story. I grouped only architectural consequences—not formatting,
dependency refreshes, or ledger-only churn—into seven stages.”

**Sources.** `presentation/evidence/timeline.csv`; `milestones.md`; Git history
at `f254295`.

### Slide 4 — Versioned links were a foundation, not yet an operating system

**Purpose.** Make the initial architecture understandable without source code
and show exactly what it could not do.

**Evidence.** Root and dual-client installer layouts; no `bin/harness`,
profiles, facts, or tests before `fb417282`.

**Proposed visual.** Native architecture diagram: Git repo → fail-closed
installer → fixed symlinks → Codex/Claude discovery. Under the pipeline, four
gray missing blocks: no inventory, no desired-state comparison, no mutation,
no verification. Include a tiny “boundary preserved” callout around private
client state.

**Speaker-note summary.** “The first architecture solved portability of
instructions. It did not know which machine it was on, what differed, whether
the environment was healthy, or how to change it. That gap drove the next
pivot.”

**Sources.** `7f969317`; `805db485`; `fb417282` milestone diff.

### Slide 5 — Value-free observation made heterogeneity actionable

**Purpose.** Explain why inventory/plan/doctor was the first execution-layer
response and how it avoided false normalization.

**Evidence.** `fb417282` added dispatcher, inventory, plan, doctor, profiles,
fixtures, and tests. Environment architecture documents five layers and keeps
native schedulers/modules/uenv authoritative.

**Proposed visual.** Native three-step funnel: Host substrate → Value-free facts
→ Profile comparison → Doctor result. Across the bottom, seven differently
shaped host chips retain native labels (Slurm, PBS, AGE, ybatch) and feed the
same comparison grammar. A dashed red line blocks “environment values /
credentials / startup contents.”

**Speaker-note summary.** “The harness did not try to make the machines
identical. It made their differences explicit and parseable. Observation was
strictly separated from mutation, and the same captured facts could be tested
offline.”

**Sources.** `fb417282`; `docs/environment-portability.md`;
`libexec/harness-{inventory,plan,doctor}`; `profiles/hosts/`; fixtures/tests.

### Slide 6 — Transactions replaced fragile manual coordination

**Purpose.** Present the most important architectural pivot: a repeatable
control grammar for writes.

**Evidence.** Apply/rollback (`07351a40`), suffix-verified shell changes
(`42e9a119`), pinned artifacts (`37ff256a`), guarded deletion (`238f022`),
backup/restore (`4f34299`), fleet sync (`e8b0e9a`), and recoverable agent
replacement (`1ed9712`).

**Proposed visual.** Large editable control-loop diagram:
Observe → Plan → Revalidate → Apply atomically → Verify → Record; drift or
failure routes to Stop / unchanged-only rollback. Around it, four small domain
badges—links, tools, backups, fleet—show the same grammar reused. Use a dashed
outer “not owned” boundary for site software and credentials.

**Speaker-note summary.** “This is when the harness became a control plane.
Each operation kept its own exact contract, but the shared grammar was stable:
plan by default, revalidate immediately, mutate only owned paths, verify, and
refuse rollback if the world changed.”

**Sources.** milestone commits above; `README.md` transactional sections;
focused transaction and guarded-delete tests.

### Slide 7 — Evidence became a gate—not a post-hoc report

**Purpose.** Show how evaluation, CI, and native scheduler evidence changed
decision-making.

**Evidence.** Frozen paired evaluator at `05932762`; T-181 full result at
`ee968531`; rejection decision at `fd5c3b1`; portable CI at `f6b9909`;
CPU/accelerator/MPI audit JSON.

**Proposed visual.** Two-column native diagram. Left: “Candidate A” enters a
frozen paired experiment; measured output card shows “no substantive gain,
more cost” and a red “Reject” stamp. Right: seven native scheduler routes feed
bounded CPU/GPU/MPI checks; results retain Pass / Declared skip categories.
Center arrow: “Evidence changes the plan.”

**Speaker-note summary.** “The harness learned to say no. A plausible guidance
change was rejected because the measured corpus showed no benefit and more
cost. Likewise, native HPC checks support only bounded readiness claims—not
performance or universal equivalence.”

**Sources.** `evaluation/`; `docs/evaluation-follow-up.md`;
`.github/workflows/ci.yml`; `docs/hpc-readiness.md`; audit JSON.

### Slide 8 — The public engine expanded without absorbing private Mac intent

**Purpose.** Explain the cross-platform architectural pivot and privacy split.

**Evidence.** Mac engine at `a0b74a4`; public Bash/tmux and migration bridge at
`4209ee8`; portable client configuration at `6a7e177`; current three-accepted/
one-gated state in `TODO.md`.

**Proposed visual.** Native two-lane architecture. Public lane: engine, policy,
Bash hooks, tmux, client settings schema. Private lane: opaque Mac identity,
selected intent, SSH payload. A guarded resolver joins them locally; no arrow
returns private bytes to public Git. Small “historical private bundle” box
crosses a one-way migration bridge into public Bash/tmux + private SSH only.

**Speaker-note summary.** “The Mac expansion did not widen the public data
boundary. The public repository owns reusable mechanics and non-secret policy;
the owner-controlled companion owns identity and private intent. The design
also removed duplicated private Bash/tmux state.”

**Sources.** `a0b74a4`; `4209ee8`; `6a7e177`;
`docs/personal-macos*.md`; `docs/agent-client-config.md`; focused Mac tests.

### Slide 9 — The control loop grew; the ownership boundary stayed narrow

**Purpose.** Provide a visual before/after architecture comparison.

**Evidence.** Root architecture versus HEAD dispatcher, profiles, manifests,
transactions, tests, CI, backup, Mac split, and cowork protocol.

**Proposed visual.** Side-by-side editable diagrams using the same visual
grammar. 2026-07-14: repository → links → clients. HEAD: sources/policy at top;
observe/plan/doctor on the left; transactional executor and rollback in center;
Linux/HPC, Mac+private companion, and native clients on the right; evidence
loop from tests/audits/CI back to planning. A constant gray outer boundary
contains secrets/site substrate/project runtimes outside both versions.

**Speaker-note summary.** “The current diagram is larger, but the key constant
is the outer boundary. The harness expanded what it can explain and transact,
not what it is allowed to own.”

**Sources.** `7f969317`; `README.md`; `bin/harness`;
`docs/environment-portability.md`; current tests/manifests.

### Slide 10 — Measured outcomes improved confidence—not every number claims speed

**Purpose.** Present checked-in evidence of improvement without conflating
coverage, readiness, correctness, and performance.

**Evidence.** 7/7 CPU readiness; 7/7 accelerator driver/runtime readiness with
5 kernels and 2 declared skips; 69/70 deterministic evaluation with zero safety
failures and a 70/70 substantive review; 7/7 primary and independent backup
check/restore; matched focused runner median 29.69 s → 25.35 s (14.62%) on one
host.

**Proposed visual.** Four native evidence cards (Fleet, Recovery, Agent
evaluation, Validation speed). Each card has a metric and a scope label. Only
the speed card uses a two-bar chart; the others use categorical rings or
pass/skip matrices. A persistent amber footer reads “readiness ≠ performance;
corpus-specific ≠ general; one-host timing ≠ fleet benchmark.”

**Speaker-note summary.** “The evidence is heterogeneous by design. Backup
restore, native readiness, agent evaluation, and test-runner timing answer
different questions. The only speed claim here is the matched local runner
comparison, and it stays explicitly bounded.”

**Sources.** audit/evaluation JSON; backup docs/audit;
`docs/audits/t284-cowork-acceptance.md`; `metrics.csv`.

### Slide 11 — Reversals made the harness safer than accretion alone

**Purpose.** Make failures, reversals, and lessons a first-class part of the
story.

**Evidence.** Removed automatic Git shell hooks (`e52a3d0`); removed website
ownership (`f1b095c`); rejected T-181 candidate (`fd5c3b1`); migrated private
Bash/tmux duplication (`4209ee8`); restored native Codex ownership to local
installation (`d76575c`).

**Proposed visual.** Native five-row “Before → Evidence → After” table with
short phrases and subtraction icons. Example: “login fetch/publish → implicit
network/auth boundary → explicit Git operation.” The bottom contains an
outlined interpretation: “Maturity came from narrower ownership, not just more
automation.”

**Speaker-note summary.** “Several of the most important changes removed
behavior. When automation crossed an authority boundary or duplicated private
state, the design stepped back. That is why the current system is broader yet
more explicit.”

**Sources.** five reversal commits; related docs and focused tests;
`milestones.md` cross-stage reversals.

### Slide 12 — HEAD is broad; the next stage is disciplined reduction of coordination

**Purpose.** Summarize current capability and end on evidence-backed open
questions.

**Evidence.** HEAD has 12 shared skills, 43 user commands, 57 focused suites,
seven Linux profiles, three accepted reachable Macs, one remaining Mac,
keep-all backup policy, open HPC route gaps, and bounded cowork limitations.

**Proposed visual.** Left: compact current-system capability wheel with seven
segments matching the stage colors. Right: three dashed open-question cards:
1) reduce coordination without weakening authority; 2) close only project-
required HPC/retention gaps; 3) strengthen cross-client provenance without
claiming authorship or confinement. Bottom thesis restatement in one line.

**Speaker-note summary.** “The harness now coordinates policy, machines,
recovery, validation, and two native agent clients. The next stage is not
unbounded automation. It is removing avoidable coordination while keeping
authority, provenance, and native-system differences visible.”

**Sources.** `README.md`; `TODO.md`; `bin/harness`; `tests/focused-suites.tsv`;
T-283/T-284 acceptance limits; `history_metrics.py --check`.

## Technical appendix

### Slide 13 — Every claim resolves to Git, code, tests, or a labeled interpretation

**Purpose.** Make the research method auditable.

**Evidence.** Complete history analysis, milestone diffs, deleted/replaced
implementations, source map, and reproducible metrics.

**Proposed visual.** Native evidence pipeline: Claim → commit/path → test/result
→ scope/limit → slide. Include a small “no tags; full linear history” badge.

**Speaker-note summary.** Explain first-parent equivalence, milestone selection,
and contradiction resolution.

**Sources.** evidence pack; Git commands in `sources.md`.

### Slide 14 — Milestone commits anchor the complete linear history

**Purpose.** Preserve more detail than the main timeline.

**Evidence.** The 25 rows in `timeline.csv`.

**Proposed visual.** Two-row native timeline with commit abbreviations, stage
colors, and explicit reversal arrows. No prose paragraphs.

**Speaker-note summary.** Point to complete CSV for dates, paths, and confidence.

**Sources.** `timeline.csv`; milestone commits.

### Slide 15 — Native readiness distinguishes pass, skip, failure, and exclusion

**Purpose.** Prevent the common misreading of readiness evidence.

**Evidence.** CPU 7 pass; accelerator 7 driver/runtime with 5 kernel passes and
2 toolkit skips; single-node MPI 5 pass / 2 no route; multi-node MPI 3 pass / 2
environment failures / 2 excluded.

**Proposed visual.** Native stacked categorical matrix with legend and exact
counts; no performance axes.

**Speaker-note summary.** Explain why explicit gaps are evidence, not failures
to be hidden.

**Sources.** HPC audit JSON and `docs/hpc-readiness.md`.

### Slide 16 — Safety evolved from collision refusal to revalidated lifecycle controls

**Purpose.** Show safety depth across stages.

**Evidence.** Root link collision refusal; transactional preimages; guarded
delete manifests; backup restore; fleet-sync ancestry; cowork seals/receipts.

**Proposed visual.** Native layered shield/timeline with six controls and the
failure each prevents.

**Speaker-note summary.** Emphasize that each control is bounded to its threat
model and none is a universal security claim.

**Sources.** root installer; transaction code/tests; guarded-delete skill;
backup/fleet/cowork acceptance.

### Slide 17 — Current commands follow one plan–apply–verify grammar

**Purpose.** Make the 43-command surface legible without listing everything.

**Evidence.** Current dispatcher and help text.

**Proposed visual.** Native taxonomy: Observe (inventory/plan/doctor), Control
(apply/shell/tool/runtime/etc.), Recover (rollback/backup/replica), Distribute
(fleet-sync/Mac catch-up), Collaborate (skills/cowork), Safety (guarded-delete).
Use representative commands, not all 43 labels.

**Speaker-note summary.** The breadth is organized by control grammar; internal
helpers are not user commands.

**Sources.** `bin/harness`; `README.md`; `history_metrics.py`.

### Slide 18 — Evidence limits define what this deck does not claim

**Purpose.** End the appendix with a precise limitations register.

**Evidence.** Source-map reconciliations and per-domain acceptance limits.

**Proposed visual.** Six native “Claim / Not claimed” pairs: readiness /
performance; deterministic score / universal agent quality; hashes / authorship;
workspace-write / read confidentiality; restore pass / retention automation;
current checked-in state / future external state.

**Speaker-note summary.** Use this slide for Q&A when a result is being
generalized beyond its evidence.

**Sources.** `source-map.md`; evaluation, HPC, backup, and cowork limitations.
