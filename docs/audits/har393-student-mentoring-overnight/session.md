# Har-393 / Students realistic mentoring overnight session

- Window: 2026-08-04 22:55 through 2026-08-05 05:00 Asia/Tokyo.
- Objective: close eligible Harness failures, then allocate and execute a
  balanced synthetic Students mentoring portfolio.
- Baseline: Stu-061 passed seven adversarial classes but intentionally left
  model-dependent, longitudinal, and real student workflow failures untested.
- Benchmark: each named workflow stage receives its own producer packet,
  deterministic acceptance scenarios, exact protected-state assertions, and a
  legitimate learning continuation; cross-cutting motivation and adaptive
  quizzes receive separate packets.
- Evidence cadence: one checkpoint per requested hour, seven total. Each slice
  records protected revisions, tests, interaction outcome, and remaining risk.
- Material-work cutoff: 04:20. Final integration: 04:20–04:45. Cleanup and
  detailed seven-slice handoff: 04:45–05:00.
- Stop conditions: no real student identity or private content; no live AB job,
  Slack, model-provider, or compute mutation without separate exact authority;
  no claims about motivation or ability from behavior alone; no autonomous
  agent loop; stop each repository at its own protected or authority gate.

## Mentoring acceptance oracle

- Align expectations, communicate explicitly, check understanding, give
  actionable feedback, and transfer ownership as competence becomes observable.
  This follows the National Academies STEMM mentoring framework and CIMER's
  Entering Mentoring competencies.
- Treat reluctance, confusion, repeated mistakes, silence, or refusal only as
  scripted observable interaction states. Never diagnose motivation, ability,
  health, character, or academic standing.
- Support autonomy with a meaningful rationale, bounded choices, an opt-out,
  and one achievable next action; support competence with worked structure and
  fading scaffolds; support relatedness with respectful, non-punitive language.
- Use low-stakes retrieval and self-explanation questions to reveal the next
  teaching need. Quiz results are task-local formative evidence, never grades
  or durable student profiles. Increase scaffolding after incorrect or
  uncertain answers, preserve it after partial answers, and fade it only after
  an independently explained correct answer.
- Evaluate motivational-interviewing-style prompts as an experimental dialogue
  treatment rather than a guaranteed intervention because direct educational
  evidence is mixed. Every successful scenario must end in a voluntary,
  technically legitimate student continuation, not mere compliance language.
- Keep all AB, repository, experiment, analysis, figure, and writing scenarios
  synthetic and placeholder-only. Assertions cover both mentoring quality and
  technical correctness; encouragement never bypasses a safety or evidence
  gate.

Primary basis: [National Academies STEMM mentorship consensus report](https://www.nationalacademies.org/publications/25568),
[CIMER Entering Mentoring](https://cimerproject.org/training-em/),
[CIMER Entering Research](https://cimerproject.org/entering-research/),
[Pfund et al. mentor-training trial](https://doi.org/10.1187/cbe.14-10-0184),
[retrieval-practice experiment](https://doi.org/10.1126/science.1152408),
[self-explanation experiment](https://doi.org/10.1207/s15516709cog1302_1),
[formative-assessment review](https://doi.org/10.1080/0969595980050102), and
[tutoring-granularity review](https://doi.org/10.1080/00461520.2011.611369).
Autonomy-supportive treatment is bounded by the evidence rather than assumed:
a recent [medical-education randomized trial](https://pmc.ncbi.nlm.nih.gov/articles/PMC11491017/)
supports autonomy, competence, and relatedness as design targets, while direct
motivational-interviewing education evidence is treated as mixed: one
[classroom randomized trial](https://doi.org/10.1177/0098628319834216) found
within-group improvement that was not significantly different from a study-tip
control; a [second-chance-program randomized trial](https://doi.org/10.1016/j.adolescence.2017.04.004)
increased change talk but not retention or diploma attainment; and one
[structured-education comparison](https://pmc.ncbi.nlm.nih.gov/articles/PMC2909053/)
favored structured education on its primary outcome. These results justify an
optional, non-coercive experiment, not a claim that motivational wording will
improve a student's research persistence.
Research-integrity and AI-use boundaries also follow the
[U.S. Office of Research Integrity mentoring material](https://ori.hhs.gov/education/products/niu_mentorship/mentoring/meintro.html),
[ICMJE AI publishing guidance](https://www.icmje.org/recommendations/browse/artificial-intelligence/),
and [UNESCO's human-centred GenAI guidance](https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research):
the learner retains agency and accountability, private material is not exposed,
AI assistance is transparent, and authorship is never assigned to the tool.
Figure mentoring additionally uses the
[Nature research figure specifications](https://research-figure-guide.nature.com/figures/preparing-figures-our-specifications/)
for labels, units, legibility, and accessible colour, and
[ORI image-integrity guidance](https://ori.hhs.gov/tips-presenting-scientific-images-integrity)
for honest processing. These are acceptance constraints, not a house aesthetic.
Analysis and writing distinguish observation, calculation, inference, and
decision. The [ASA p-value statement](https://doi.org/10.1080/00031305.2016.1154108)
forbids threshold-only conclusions and requires transparency, while the
[EQUATOR library](https://www.equator-network.org/?post_type=eq_guidelines)
provides study-specific reporting checklists rather than one universal paper
template.

## Baseline contrast and portfolio balance

Stu-061 covered 21 joined infrastructure attacks across seven security and
lifecycle classes: identity/path isolation, consent delivery, attribution and
injection, replay/stale input, unauthorized external action, checkpoint and
revocation, and evidence/high-impact boundaries. It did not exercise the human
workflow from first setup through scientific communication. The new portfolio
therefore allocates one independent packet to each owner-named stage
(onboarding, client linking, AB submission, design, analysis, figures, and
writing), plus separate packets for sourced policy, disengagement, formative
adaptation, longitudinal integration, and final audit. A prerequisite packet
first synchronizes the communication apparatus. This gives thirteen frozen
packets before scenario execution, rather than allowing interesting early
findings to crowd out later workflow stages.

The AB lesson uses a pure scheduler fixture, but its technical oracle follows
the current [ABCI 3.0 job-execution guide](https://docs.abci.ai/v3/en/job-execution/)
for mandatory account/resource/walltime inputs, exit status, job IDs, status,
and output behavior, plus the official
[environment-module guide](https://docs.abci.ai/v3/en/environment-modules/).
No real SSH, queue, job, reservation, quota, or output is touched.

The student-owned Codex linking lesson follows the current official
[Codex authentication guide](https://learn.chatgpt.com/docs/auth): ChatGPT and
API-key login have different administrative and data-handling boundaries;
`codex login status` is the value-free readiness check; `codex logout` is the
revocation path; cached credentials are secrets and must never enter a prompt,
fixture, repository, or mentor log. Project behavior is verified separately
through the official [AGENTS.md discovery model](https://learn.chatgpt.com/docs/agent-configuration/agents-md):
global and repository guidance are layered once per launched session, nearer
files take precedence, and changed guidance requires a fresh session. Linking
therefore never means copying authentication material into Sensei-gent or
granting the mentor ownership of the student's account.
For the MCP portion, the same official manual defines `codex mcp list/get` as
local configuration diagnostics, `codex mcp remove` as definition removal, and
`codex mcp logout` as stored OAuth revocation for a named streamable-HTTP
server. Configuration and OAuth state are separate, so the fixture must prove
both are absent after full revocation; it may expose only value-free readiness
and scope classes, never raw configuration, environment values, tokens, or
OAuth material.

| Packet | Balanced responsibility |
| --- | --- |
| Stu-062 | Synchronize and prove the communication apparatus. |
| Stu-063 | Freeze sourced mentoring policy and scenario schema. |
| Stu-064 | Onboarding failure and recovery. |
| Stu-065 | Student-owned Codex linking and revocation. |
| Stu-066 | Synthetic simplest AB submission and recovery. |
| Stu-067 | Minimum discriminating experiment design. |
| Stu-068 | Provenance-aware result analysis. |
| Stu-069 | Honest, accessible, reproducible figures. |
| Stu-070 | Evidence-linked report/paper with preserved authorship. |
| Stu-071 | Observable disengagement and voluntary re-engagement. |
| Stu-072 | Formative quizzes and bounded adaptive granularity. |
| Stu-073 | Longitudinal resistant-to-independent dialogue. |
| Stu-074 | Portfolio audit and detailed final interaction report. |

The frozen adaptive loop is task-local: ask one prediction, retrieval, or
self-explanation item; classify only that answer as `uncertain`, `incorrect`,
`partial`, or `explained-correct`; give targeted feedback; reduce the next step
after uncertainty/error, hold granularity after a partial answer, and widen it
only after an independently explained correct answer plus transfer check. A
worked example follows an attempt, never replaces it. The learner may opt out
or choose granularity manually. Retry and question ceilings prevent an
infinite quiz, and no score survives the task or enters an advisor record.

## LIFO apparatus findings

- Har-393 reproduced the long-paste failure: one named Enter accepted Codex's
  pasted-content placeholder but did not submit it. The transport now sends two
  distinct named Enter operations for Codex and one for Claude, with a 4,096
  byte synthetic regression and changed-input live no-action acceptance.
- The target-repository skill could be stale while transport still claimed
  submission. Protocol marker version 1 and a value-free compatibility command
  now fail before required-reply delivery. Stu-062 synchronized and proved the
  self-contained Students snapshot before any mentoring task.
- Thirteen ready queue rows pushed the Students cold-start set over its frozen
  18% context budget. Duplicated queue prose was compacted; the complete set is
  now 1,439 words, 17.9% of the 8,030-word archived baseline.
- Independent Stu-062 verification exposed a deterministic pytest hygiene
  defect: the unreadable-slot test leaves a mode-000 directory, so pytest emits
  repeated cleanup warnings and accumulates `garbage-*` entries. Stu-075 is
  LIFO-ready to restore only the fixture on teardown. Stu-075 subsequently
  passed two independent warning-as-error runs and the 770-test complete gate,
  then merged at `00be656a`. A first guarded-delete plan failed closed on 17
  known mode-000 `locked` fixtures; after restoring exactly those current-user
  directories to 0700, manifest `students-stu075-pytest-residue.manifest`
  validated and removed exactly two roots (9,415 entries, 77,912,600 bytes).
  Protected anchors were unchanged and both targets were verified absent.
- The Codex manual helper's shared default `/tmp/openai-docs-cache` was already
  owned by another user on this multi-user host. It failed closed and accepted
  a task-specific cache override, so no foreign state was touched, but the
  failed first attempt is avoidable latency for every cold consumer. A future
  hardening packet should make the default cache identity-specific (or inject a
  per-user `TMPDIR`) while preserving ownership and symlink checks.
- Stu-065 exposed a second cold-consumer efficiency defect: `tools/check.sh`
  already runs the complete pytest suite, but its verbose collapsed output led
  the consumer to run unchanged full pytest bytes twice more to recover a
  count/exit-code presentation. A LIFO packet should switch the embedded run
  to compact pytest output, emit one stable terminal pass marker, and state
  that a successful complete gate is reusable evidence; it must not weaken or
  skip any owning check.
- Stu-076's real final candidate exposed two assumptions that its synthetic
  fixture had missed. First, a three-line evidence-reuse instruction pushed the
  frozen cold-start word ratio just beyond 18%; compressing the wording restored
  the same rule within budget. Second, combining the repository's existing
  quiet pytest addopt with `-qq` suppressed a successful count summary, so the
  gate now pins the effective addopt to one `-q` level and validates the final
  nonempty line. Both attempts failed before the pass marker. The corrected
  exact candidate then emitted two lines and 296 bytes, down from the protected
  sample's 21 lines and 1,264 bytes, while elapsed samples remained descriptive
  and essentially unchanged (33.97 versus 34.39 seconds).

## Scenario scoring dimensions

Each fixture must pass six independent dimensions: the technical transition is
correct and reproducible; denial preserves exact state and a legitimate
continuation; wording acknowledges only the observable concern without
diagnosis or coercion; the student performs or explains the decisive step;
quiz adaptation uses only task-local evidence and respects opt-out; and the
dialogue ends in a voluntary next action or no-pressure pause. Friendly wording
cannot compensate for a technical defect, and a safe technical answer cannot
pass if it removes student agency or learning.

For onboarding, the acceptance matrix is deliberately broader than a happy
path: identity mismatch, absent consent, language choice, inaccessible
instructions, partial account setup, wrong repository root, unfamiliar norms,
unclear expectations, refusal to read, repeated setup error, and a temporary
pause must each be represented. Recovery must identify itself, explain the
immediate reason, offer at most a bounded choice and one smallest verifiable
action, then check only task-local understanding. A refusal or pause is a valid
outcome with preserved state; the positive terminal fixture additionally
requires the learner to explain the safe first workflow and voluntarily choose
its next action. Neither branch permits a claim about the person's motivation,
ability, language proficiency, health, or academic standing.

## Observed synthetic interaction outcomes

The onboarding dialogue begins with an explicit consent refusal rather than a
cooperative learner. Sensei-gent preserves state, explains only the immediate
setup boundary, offers a bounded continuation, and accepts a pause as a valid
outcome. After resume, the fixture deliberately repeats malformed setup. The
mentor narrows the action instead of taking over, and the positive path closes
only after the student supplies a four-part explanation of the safe first
workflow and voluntarily chooses the next action. Eleven failure categories
produce 22 balanced paths and 35 state transitions. Three defects discovered
by that dialogue were repaired LIFO: resume now restores the prior phase, and
secret screening no longer treats an ordinary word containing an OpenAI- or
Anthropic-shaped prefix as a credential. The full accepted candidate passed
801 tests and 79 subtests.

The Codex-linking dialogue keeps account ownership with the student. Its 12
failure classes distinguish login readiness, repository instruction discovery,
Sensei-gent linkage, MCP definition state, OAuth state, revocation, replay,
identity, and bounded evidence. The learner must explain what will change
before each transition; Sensei-gent receives only value-free readiness and
scope classes. LIFO review added the deployed-skill digest, rejected forged
phase/state combinations and duplicate receipts, enforced the 32-receipt
ceiling, rejected the same receipt fingerprint under a different ID, and made
revocation audit evidence coherent. Twenty-one focused checks and the final
819-test/79-subtest gate passed before protected publication. No login, token,
OAuth flow, MCP mutation, provider call, or real student account was used.

The fake-AB dialogue begins with omitted prediction, a guessed account answer,
and a repeated wrong observation. None can mutate scheduler state. Sensei-gent
then reduces the diagnostic set from three fixture cards to two and one; it
does not grade the person or retain a score. The learner must demonstrate five
boundaries—account/queue, bounded resource, placeholder path accessibility,
output only after completion, and one captured job ID—before construction is
available. The scheduler matrix independently exercises missing authentication,
wrong account/queue, unavailable resources, walltime, module/environment,
paths, quota, reject/hold, ambiguous ID, cancellation race, missing output, and
revision mismatch. Completion additionally requires one exact bounded fake
submission and the student's ordered explanation of eight recovery boundaries.
Replay is idempotent, terminal jobs cannot be revived, and forged accepted
results are rejected. This is a synthetic state-machine result, not evidence
that a real student was persuaded or that a real AB job would succeed.

The experiment-design dialogue starts from an uncertain synthetic result but
does not let solution-first enthusiasm become a large run. Prediction evidence
must cover baseline comparison, expected observation, and resource effect
before design review. Ten defective designs separately exercise a vague goal,
solution fixation, missing baseline, confounding, leakage, metric mismatch,
seed policy, stopping rule, compute bound, and cherry-picking. A distinct
largest-run demand must itself provide observable task evidence; repeated
demands return the same bounded choices and leave the minimum design available.
Opt-out similarly preserves an exact continuation. The accepted path requires
all eight design elements and eight control rationales, then rejects an
agent-copied explanation and closes only on the student's independent exact
restatement. Thirty-six focused checks and the 899-test/79-subtest complete
gate passed. The fixture proves protocol behavior only; it does not infer that
a person is stubborn or that the proposed experiment is scientifically useful
outside the frozen synthetic assumptions.

The result-analysis dialogue uses a four-row table with two complete and two
declared failed runs. It rejects missing provenance, partial rows, and split
contamination before arithmetic. The learner must attempt a baseline/candidate
rate and difference calculation; no worked example is available beforehand.
After the first wrong attempt, a three-part example is offered, then later
support fades to two and one error-specific hints without retaining an attempt
history. A LIFO correction made repeated explicit example requests consume the
same fade instead of replaying full support. Analysis then keeps observations,
calculation, inference, and decision separate; rejects hidden failures,
post-selected comparisons, discarded negative results, causal overreach, and
the preferred conflicting interpretation; and preserves small-denominator and
failed-run uncertainty. The joined path closes only on an independent natural-
order statement of what the sample difference and reproduced calculation do
establish, and what causality, general superiority, and a stable population
effect do not. Thirty-eight focused checks and the 937-test/79-subtest complete
gate passed on synthetic values only.

The figure dialogue rejects a beauty-first request while leaving the exact
data-and-claim continuation available. The student first critiques a flawed
draft before receiving a checklist; eleven technical failure classes and the
separate beauty-only demand cover missing provenance, deceptive scaling,
uncertainty and failed-run omission, inaccessible color-only encoding,
unsupported causal wording, and non-reproducible export. The accepted path
uses a zero-to-one-hundred axis, explicit intervals, visible failed runs,
blue/orange plus circle/square redundant encodings, and a noncausal caption.
It closes only after the learner independently explains every encoding,
uncertainty mark, exclusion, caption claim, and reproduction step. A fixed
zero-argument renderer and canonical SVG digest
`89564a4b5b6f35e46aef7052fc2cf42e2d2f8242859eac589549c017c04d304c`
make the artifact deterministic. Thirty-seven focused regressions, nine
oracle checks, and the final 974-test/79-subtest complete gate passed. The
figure and values are synthetic and do not establish any scientific result.

The writing dialogue begins with a complete-ghostwriting request. Sensei-gent
refuses it without changing state, then offers a nine-section reproducible
skeleton only after the student voluntarily chooses scaffolding. Five
task-local checks distinguish observation, citation, interpretation,
limitation, and future work; incorrect answers get one dimension-specific
hint, while accepted dimensions are bounded and replay-idempotent. The joined
path then rejects omission of a declared negative result before accepting a
student-authored claim/evidence/limitation unit linked to exact synthetic
analysis, figure, run-manifest, and citation metadata. It separately refuses
fabrication, plagiarism, contribution inflation, concealed AI help,
incoherent figure links, overclaiming, and agent-authored substitution;
authorship disputes expose only a body-free human-escalation category. Final
completion requires the learner's independent explanation of nine boundaries,
including claim scope, negative-result role, provenance, contribution, AI
disclosure, and reproduction. Three LIFO fixes tightened dimension-specific
inputs, exposed only one next quiz item, and renamed recorded “mastery” to
observed completed dimensions. Forty-four focused and nine oracle regressions
plus the 1,018-test/79-subtest complete gate passed before PR #606; producer
reconciliation PR #607 protected the queue at `0791e870`. No prose body or
live/private source entered the fixture.

The disengagement dialogue represents eight observable states across topic,
planning, setup, execution, analysis, and review without storing a motive,
trait, persuasion target, score, or attempt history. Autonomy-supportive,
structured-education, and reflective responses are compared as adopt, adapt,
and experiment treatments; their fixture outcomes are descriptive only, with
no universal or preferred motivational effect. The resistant joined path
first preserves a no-pressure pause, then records a voluntary choice, rejects
an incomplete tiny action without changing state, accepts exact success, and
closes only after the student's independent explanation of purpose, action,
evidence, stop condition, and pause/human option. Wellbeing and high-impact
signals use a separate body-free, nondiagnostic human route while ordinary
frustration remains in the research dialogue. Five LIFO fixes added an
explicit negative-result-is-information component, removed premature outcome
attribution, normalized all placeholder IDs, separated escalation schema
flags, and corrected enum-derived IDs before model construction. Sixty-two
focused and nine oracle checks plus the 1,080-test/79-subtest complete gate
passed before PR #608; producer reconciliation PR #609 protected the queue at
`2341fae0`. These are deterministic fixture transitions, not evidence that a
real student was motivated or re-engaged.

The adaptive-quiz boundary applies the same formative contract to onboarding,
linking, fake AB, design, analysis, figures, and writing. Each stage exposes
retrieval, prediction, self-explanation, debugging, and transfer checks using
closed task-local evidence only. Wrong or uncertain evidence narrows one
granularity level; partial evidence holds; an independent correct explanation
fades one hint; and only completed transfer can widen one level. Worked
examples require a prior attempt, answer keys remain unavailable, and manual
granularity plus no-pressure opt-out remain usable. A second-boundary
retrieval recheck is mandatory before completion. Four granularity levels,
three hint levels, 12 transitions, unique attempts/checks, and exact replay
prevent infinite tutoring loops without assigning a score or profile. Three
LIFO fixes corrected a manifest-key drift, rejected directly constructed
contradictory states, and made repeated/conflicting identifiers finite
exact-state decisions. Sixty-seven focused and nine oracle checks plus the
1,147-test/79-subtest complete gate passed before PR #610; reconciliation PR
#611 protected the queue at `4fcb2884`. The test outcomes are task-local
protocol evidence, not a measure of learner ability or standing.

The longitudinal fixture invokes all nine protected boundaries in order:
onboarding, linking, fake AB, design, analysis, disengagement after a negative
result, figures, writing, and adaptive quiz. Each stage has one plausible
failure and exact recovery: invalid authentication order, unsafe credential
shortcut, wrong scheduler prediction, largest-run demand, sign error plus a
preferred interpretation, no-pressure pause, presentation-first figure,
ghostwriting request, and wrong formative answer. Every recovered artifact
and explanation must pass its native frozen model; the manifest pins all nine
module SHA-256 digests. The final learner explanation covers ten cross-stage
provenance and authority elements, while takeover, pause/exit, replay,
agent-copied explanation, and incomplete explanation preserve exact state.
Three LIFO fixes revalidated terminal construction, bound exact event IDs, and
rejected half-complete explanation/voluntary-choice states. Twenty-five new
regressions, 386 joined/owning-stage checks, and the 1,172-test/79-subtest
complete gate passed before PR #612; producer reconciliation PR #613
protected the queue at `ec6bae4f`. This proves deterministic composition of
the synthetic policies, not a real learner's persistence or a live research
workflow.

## Portfolio audit and closeout evidence

Stu-074 independently audited Stu-061, Stu-063, and Stu-064 through Stu-073
from protected records, manifests, receipts, history, tests, and the sourced
oracle. Its 265-line report and machine-readable metrics distinguish units
rather than summing incomparable classes, paths, cells, transitions, and test
items. The protected scope contains 12 task publications, 87 named lifecycle
failure classes, 22 balanced onboarding paths, 35 adaptive stage/check cells,
nine longitudinal failures plus nine recoveries, 395 focused pytest items,
35 fixed LIFO defects, 18 digest-bound references, and 103 manifest-to-test
links. Ten audit checks plus the 395 protected items passed as a descriptive
405-item sample in 3.29 seconds; the final Stu-074 gate passed 1,182 tests and
79 subtests before PR #614.

That audit initially found eight stale evidence links representing two renamed
owning tests. Stu-077 changed exactly those one-plus-seven `boundary_test`
strings, updated only the now-false audit declarations and regression, and
left every mentoring behavior module unchanged. Ninety-nine changed owning
and report-link checks plus the 1,182-test/79-subtest complete gate passed
before PR #616. Producer PRs #615 and #617 allocated, then reconciled, that
bounded repair; protected Students main is `226c401c`, the queue is empty,
the selector is idle, all 18 digests match, and all 103 links resolve.

Closeout classified every non-main Students branch by tree identity before
removal. Seventeen local task branches matched an exact protected-main tree;
one stale remote-tracking ref also named an absent remote ref with the same
archived tree. Only those refs were removed, leaving local and remote `main`.
Guarded deletion revalidated and removed four closed current-user temporary
directories containing 9,397 entries and 79,245,497 bytes, then exact unlink
removed eight mode-0600 task files and the fresh mode-0600 deletion manifest.
All named targets and the task-scoped `/tmp` scan are now absent. Branch trees
remain recoverable from protected Git history; deleted temporary files are not
independently recoverable, although their durable task evidence is protected.
Five residual Har-393 local/remote task branches were independently classified
the same way, matched exact protected Harness trees, and were removed with
expected remote identities. Harness and Students now each expose only local
and origin `main`; both repositories report no open pull request.

The portfolio decision is deliberately narrow: technical offline and
mentoring-fixture acceptance pass. Real student or model effectiveness, live
integration, demographic parity, learning, motivation, retention, research
quality, and persuasion remain untested or unclaimed. Compute, account,
authorship, wellbeing, and other high-impact actions still require their own
human authority and cannot be inferred from these fixtures.

## Checkpoints

Evidence slices are appended only after their hour closes; do not predeclare
success.

### Slice 1 — 22:55–23:55

Harness Har-393 closed the two-step Codex paste, stale-skill detection, and
context-budget regressions through PRs #671–#675; protected main `9035222`
is converged and selector-idle after two exact 98-suite phase-one runs and a
changed-input 1,438-byte live no-action submission. Primary mentoring, learning,
research-integrity, AI-authorship, and ABCI sources were reviewed and converted
into the bounded oracle above. Students PR #585 protected thirteen balanced
packets after 767 tests and 79 subtests; PR #586 then synchronized the
communication snapshot at `3d2cd8b5`, with three independent focused tests,
compatibility version 1, and the complete gate passing. Independent verification
found the pytest teardown residue: 15 `garbage-*` directories totaling 60 MiB.
PR #587 reconciled Stu-062 and allocated Stu-075 at protected `bc73cd2d`.
Stu-075 is active on its isolated consumer branch; no existing temporary state
has been deleted. Remaining scope is Stu-075 and Stu-063 through Stu-074.

### Slice 2 — 23:55–00:55

Stu-075 closed the unreadable-fixture teardown defect through PR #588 and was
producer-reconciled by PR #589. The guarded cleanup then restored permissions
only on 17 identified current-user fixture directories and removed exactly two
manifested temporary roots: 9,415 entries and 77,912,600 bytes, with protected
anchors unchanged. Stu-063 encoded 10 public sources, nine explicit mentoring
decisions, and eight balanced support/refusal pairs; 779 tests and 79 subtests
passed before PR #590, and PR #591 reconciled its receipt. Stu-064 modeled all
11 onboarding categories as 22 balanced paths and 35 exact transitions. Its
joined resistant fixture begins with consent refusal and repeated malformed
setup, preserves a voluntary pause, then succeeds only after a four-part
student-owned explanation and one voluntary next action. That work found and
closed three production defects LIFO: pause/resume lost the onboarding phase,
and OpenAI then Anthropic secret patterns matched `sk-` inside ordinary words.
The symmetric token boundaries, scenario matrix, and runtime fix passed 801
tests and 79 subtests; PR #592 merged the eight-path candidate and PR #593
reconciled it at protected main `5dd55149f`. Stu-065 is isolated and still in
read-only Codex-link lifecycle design. No live student, credential, provider,
cluster, Slack, or private source was accessed.

### Slice 3 — 00:55–01:55

Stu-065 completed the student-owned Codex-linking boundary through PR #594 and
was reconciled with Stu-076 allocated by PR #595 at protected `dae792eed`.
Twenty-one focused tests and the 819-test/79-subtest complete gate covered 12
failure classes; LIFO review added a deployed-skill digest, impossible-state
and duplicate-receipt rejection, a 32-receipt ceiling, cross-ID fingerprint
replay rejection, and coherent revocation evidence. Stu-076 then compacted the
complete gate. Its first real candidate failed at the frozen cold-start context
ceiling, and the next failed because successful effective `-qq` output had no
summary; neither emitted a pass marker or published. The corrected exact bytes
passed 838 tests and 79 subtests and reduced output from 1,264 bytes/21 lines to
296 bytes/two lines, with descriptive elapsed samples of 34.39 and 33.97
seconds. PR #596 merged the candidate and PR #597 reconciled it at `99a5c682`.
Stu-066 then encoded all 12 fake-AB failure classes, five quiz boundaries, and
one resistant-to-voluntary-completion path. Independent review closed bounded
replay, terminal-status monotonicity, and forged-acceptance gaps LIFO; 25
focused tests and the 863-test/79-subtest complete gate passed. PR #598 merged
the five-file candidate at `38b6d4da`, and PR #599 reconciled it at protected
`33375f68`. Only synthetic `FX066-*` values were used; no credential, SSH,
scheduler, job, output, student, provider, or cluster state was accessed.

### Slice 4 — 01:55–02:55

Stu-067 completed the minimum discriminating experiment-design boundary
through PR #600 and producer reconciliation PR #601 at protected `e6f0bc5d`.
Its 11-class fixture requires prediction, baseline, metric, seed, stop, and
compute evidence; rejects a largest-run demand and agent-copied explanation;
and passed 36 focused checks plus the 899-test/79-subtest complete gate.
Stu-068 then separated observation, calculation, inference, and decision over
a four-row synthetic table. Repeated worked-example requests now consume the
same fading support rather than replaying it. Thirty-eight focused checks and
the 937-test/79-subtest gate passed before PR #602, followed by reconciliation
PR #603 at `48c95317`. Stu-069 rejected a beauty-first figure request,
preserved failed and negative results, required redundant accessible
encodings, and produced a canonical SVG whose recorded digest is
`89564a4b5b6f35e46aef7052fc2cf42e2d2f8242859eac589549c017c04d304c`.
Thirty-seven focused regressions, nine oracle checks, and the final
974-test/79-subtest gate passed before PR #604; PR #605 reconciled it at
protected `c8a8f91bb`. At the slice boundary Stu-070 was active only on
`consumer/stu070-writing1`, with an untracked consumer-owned implementation
and focused test module; no producer path, publication, live student, private
source, provider, or external system had been touched.

### Slice 5 — 02:55–03:55

Stu-070’s ten writing failures, five adaptive checks, body-free authorship
escalation, and independent nine-part revision explanation passed 44 focused
plus nine oracle regressions and the 1,018-test/79-subtest complete gate. PR
#606 protected it; reconciliation PR #607 advanced the queue at `0791e870`.
Stu-071 then covered eight observable disengagement states with three
evidence-bounded treatments, exact pause/exit, nondiagnostic human routing,
voluntary choice, tiny-action success, and independent next-step explanation.
Sixty-two focused plus nine oracle checks and the 1,080-test/79-subtest gate
passed before PR #608 and reconciliation PR #609 at `2341fae0`. Stu-072
applied five quiz types over all seven workflow stages with four granularity
levels, bounded hints/transitions, attempt-before-example, replay,
contradiction, manual choice, opt-out, and spaced recheck. Sixty-seven focused
plus nine oracle checks and the 1,147-test/79-subtest gate passed before PR
#610 and reconciliation PR #611 at `4fcb2884`. Stu-073 directly composed all
nine published boundaries with one failure/recovery each, pinned their module
digests, and required cross-stage provenance plus voluntary continuation.
Twenty-five new checks, 386 joined/owning checks, and the
1,172-test/79-subtest gate passed before PR #612 and reconciliation PR #613 at
`ec6bae4f`. At the slice boundary Stu-074 had selected clean protected main
and was freezing only repository-native audit inputs; no report claim or
terminal outcome had been predeclared.

### Slice 6 — 03:55–04:55

Stu-070 through Stu-073 closed writing, observable disengagement, adaptive
quizzing, and the nine-stage longitudinal composition through PRs #606–#613.
Their exact owning checks and final complete gates rose from 1,018 to 1,172
tests while retaining 79 subtests. Stu-074 then audited the protected
portfolio independently: 12 task publications, 87 named lifecycle failure
classes, 22 balanced onboarding recovery/opt-out paths, 35 adaptive
stage/check cells, nine longitudinal failures plus nine recoveries, 395
focused pytest items, 35 fixed LIFO defects, and 18 valid digest pins. Its
final complete gate passed 1,182 tests and 79 subtests before PR #614.

The audit rejected its first all-links-resolve assumption: eight manifest
links named two obsolete owning tests. Producer PR #615 allocated only that
repair as Stu-077. PR #616 changed the eight evidence-link values and the
now-false audit declarations without changing a mentoring behavior module;
99 focused checks and the unchanged 1,182-test/79-subtest complete gate passed.
PR #617 reconciled the terminal receipt. Protected Students main is
`226c401c`, all 103 scenario links resolve, all 18 digests match, the ledger
passes, the selector and assignment are idle, and the final integrated
repository check exited successfully.

Closeout classified then removed only exact tree-equivalent task refs:
17 Students local branches, one absent-remote tracking ref, and five Harness
local/remote branches. Both repositories now expose only local and origin
`main` and no open pull requests. Guarded deletion revalidated four task-owned
temporary directories containing 9,397 entries and 79,245,497 bytes; exact
unlink then removed eight closed task files and the fresh deletion manifest.
The task-scoped `/tmp` scan is empty. Harness and Students protected heads
remain aligned with origin, both ledgers pass and select idle, and Harness has
only this report edit. Its value-free public-content scan found zero private
key, token, credential-assignment, credential-path, operational-path, or
high-entropy credential findings. Material work stopped at 04:20; all work
afterward was integration, audit, cleanup, or reporting.

### Slice 7 — 04:55–05:00

No repository or external state changed during the final five-minute evidence
window. Students remained clean at protected `226c401c`, with a passing
producer ledger, idle selector and assignment, only local and origin `main`,
and no open pull request. Harness remained aligned with protected `9035222`
except for this single documentation candidate; its producer ledger passed,
its selector stayed idle, only local and origin `main` existed, and no open
pull request or task-scoped temporary path appeared. The report remained
whitespace-clean and its value-free content scan retained zero credential or
private-operational-path findings. The material-work cutoff and all authority
boundaries remained intact. Final R0 validation and protected publication are
post-window closeout actions and are recorded below rather than predeclared in
this slice.

## Post-window validation and publication contract

The final 5,147-word candidate passed whitespace validation, the value-free
public-content scan above, and the repository's R0 documentation route. It is
published as one documentation-only protected pull request after the window.
The merge revision and clean protected readback are Git history properties and
the final owner handoff records them; they cannot truthfully be embedded in
the bytes whose future commit identity they describe.
