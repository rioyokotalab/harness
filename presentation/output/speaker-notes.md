# Harness evolution speaker notes

Talk target: 18–20 minutes for slides 1–12, followed by questions. Appendix
slides 13–18 are optional. Statements marked “interpretation” are synthesis,
not attributed motivation.

## Slide 1 — The harness became a control plane by making authority explicit

Open with the one-sentence thesis. The harness started as a safe way to version
agent guidance and became an operational control plane across heterogeneous
systems. The through-line is not feature count: every major step clarified who
may change what, from which evidence, and with what recovery path. Preview the
seven verbs: protect, observe, transact, recover, measure, expand, collaborate.

Transition: “To understand why this architecture grew, start with the boundary
the first commit chose.”

## Slide 2 — The first harness protected portable intent—not machine state

The root commit tracked only non-sensitive durable intent: working agreements,
rules, skills, and a fail-closed symlink installer. It explicitly excluded live
configuration, credentials, sessions, histories, caches, plugins, and other
runtime state. The numbers—18 files and six skills—describe scope, not quality.
Claude discovery arrived in the next commit, but the model was still links, not
environment operation.

Transition: “That boundary was durable; what changed was the control depth
inside it.”

## Slide 3 — Seven architectural shifts turned discovery into controlled execution

Explain that the repository has 542 total and 542 first-parent commits, no
merge commits, and no tags. The mainline is the complete history. The seven
stages exclude formatting, dependency refreshes without architectural effect,
and ledger-only churn. Point out the reversal notches: removal mattered too.

Transition: “The first architecture solved discovery—nothing more.”

## Slide 4 — Versioned links were a foundation, not yet an operating system

Walk left to right: repository, fail-closed installer, known symlinks, client
discovery. The private-state exclusion remains outside. Then name the four
missing capabilities: no inventory, desired-state comparison, mutation, or
verification. This is the limitation that produced the first execution layer.

Transition: “Before the harness could write safely, it had to observe safely.”

## Slide 5 — Value-free observation made heterogeneity actionable

Inventory emitted a constrained fact stream; plan compared facts with a logical
profile; doctor classified readiness. Captured facts made behavior testable
without reconnecting. Emphasize that native schedulers, modules, uenv, drivers,
and site policy remained authoritative. The harness standardized the control
grammar, not the machines.

Transition: “A correct plan still leaves one hard question: how do you change
state without turning a partial failure into a new mystery?”

## Slide 6 — Transactions replaced fragile manual coordination

Describe the shared loop: observe, plan, revalidate, apply atomically, verify,
record. Drift or failure stops or invokes an unchanged-only rollback. Give one
short example each: link collision, shell suffix, checksum-pinned tool, guarded
deletion manifest, verified Git-bundle fleet sync. Note that package managers,
site software, credentials, and projects remain outside generic rollback.

Transition: “Once writes were bounded, evidence could become more than a test
at the end—it could decide whether a change should exist at all.”

## Slide 7 — Evidence became a gate—not a post-hoc report

On the left, explain T-181: a frozen paired experiment evaluated a plausible
failure-capsule guidance change. The candidate produced no substantive
correctness gain and added cost, so it was rejected. Preserve the nuance:
69/70 is the canonical deterministic result; targeted review judged all 70
substantively acceptable; zero safety failures is corpus-specific. On the
right, native scheduler routes support bounded CPU/GPU/MPI readiness claims
without pretending sites are identical.

Transition: “The same explicit-boundary idea enabled a very different target
family: personal Macs.”

## Slide 8 — The public engine expanded without absorbing private Mac intent

The public repository owns reusable mechanics and non-secret policy. A strict
owner-controlled companion owns opaque identity, selected intent, and private
SSH payload. The resolver joins them locally and does not publish private
bytes. A later migration moved Bash hooks and tmux into the public shared layer,
leaving SSH as private intent. State at HEAD: three reachable Macs accepted,
one availability-gated.

Transition: “With the pieces in place, compare what changed—and what did not.”

## Slide 9 — The control loop grew; the ownership boundary stayed narrow

Use the same outer boundary on both diagrams. In 2026-07-14 the internal flow
was repository to links to clients. At HEAD it includes observation, profiles,
transactions, recovery, native execution, Mac-private resolution, evaluation,
CI, and cowork. The interpretation is that the harness expanded what it can
explain and transact, not what it is allowed to own.

Transition: “A larger architecture is not evidence of improvement; checked-in
outcomes are.”

## Slide 10 — Measured outcomes improved confidence—not every number claims speed

Treat each card as a different question. Fleet readiness: bounded native
correctness. Recovery: full-data check and verified restore. Agent evaluation:
frozen corpus behavior. Validation speed: a matched local timing comparison.
The 14.62% reduction is the only speed claim and applies to one eight-CPU-
visible host. Do not generalize readiness to performance or the corpus to
universal agent quality.

Transition: “The design also improved by removing things that crossed the wrong
boundary.”

## Slide 11 — Reversals made the harness safer than accretion alone

Walk through the five rows quickly. Automatic login fetch and exit publish
became explicit Git operations. Website ownership was removed. An evaluated
candidate was rejected. Private Bash/tmux duplication moved public while SSH
stayed private. Native Codex ownership returned to the local installation while
the harness retained policy and a wrapper. The final statement is explicitly
an interpretation: maturity came from narrower ownership, not only more
automation.

Transition: “That leaves a broad current system—and a deliberately narrow next
question.”

## Slide 12 — HEAD is broad; the next stage is disciplined reduction of coordination

Summarize the current capability wheel. The counts—12 skills, 43 user commands,
57 focused suites, seven Linux profiles—show breadth, not quality. Then state
the open questions: reduce avoidable human coordination without weakening
authority; close only project-required HPC and retention gaps; strengthen
cross-client provenance without claiming model authorship or OS confinement.
Restate the thesis and stop.

## Slide 13 — Every claim resolves to Git, code, tests, or a labeled interpretation

Appendix method. First-parent equals complete history. Important deleted and
replaced implementations were inspected directly. Every substantive slide
claim maps to a commit/path plus a test, checked-in result, or reproduction
command. Conflicts were resolved by date and scope, not blended.

## Slide 14 — Milestone commits anchor the complete linear history

Use this when someone asks for chronology beyond the seven-stage summary. The
complete 25-row CSV contains date, full SHA, subsystem, description, evidence
paths, and confidence. Reversal arrows are part of the narrative, not noise.

## Slide 15 — Native readiness distinguishes pass, skip, failure, and exclusion

Explain the categories. CPU passed on seven. Accelerator driver/runtime passed
on seven; five kernels passed and two toolkits were declared skips. Single-node
MPI passed on five; two had no reviewed route. Multi-node passed on three; two
ended in environment failures and two were excluded. None is a scaling result.

## Slide 16 — Safety evolved from collision refusal to revalidated lifecycle controls

Each layer answers a different failure mode: collision refusal protects
unmanaged paths; preimages protect rollback; manifests protect deletion scope;
restore proves recovery; ancestry protects fleet distribution; seals/receipts
protect cowork provenance. No layer is a universal security boundary.

## Slide 17 — Current commands follow one plan–apply–verify grammar

The command surface is large but organized. Observation commands do not write;
transactional commands plan by default; recovery commands require unchanged
state; distribution commands preserve ancestry; safety commands have separate
revalidation. Internal helpers are not counted as user commands.

## Slide 18 — Evidence limits define what this deck does not claim

Use during Q&A to stop overgeneralization. Readiness is not performance;
deterministic scoring is not universal quality; hashes do not prove authorship;
workspace-write does not imply read confidentiality; restore success does not
authorize retention deletion; and checked-in state does not predict future
external state.
