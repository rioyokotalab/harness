# T-181 evaluation follow-up decision

## Decision

**Reject candidate A for adoption. Retain the current baseline guidance.**

This is an evidence-only decision from the frozen T-181 reports. It does not
invoke a model, alter the evaluator, relabel an arm, rerun a task, or adopt the
candidate. Evidence applies only to the recorded corpus, Codex CLI 0.144.5,
GPT-5.6-sol with medium reasoning, and that execution environment.

## Evidence reconciliation

| Stage/metric | Baseline | Candidate A | Candidate delta |
|---|---:|---:|---:|
| Pilot deterministic passes | 9 / 9 | 9 / 9 | 0 |
| Pilot duration | 507,314 ms | 558,083 ms | +10.007% |
| Pilot input tokens | 1,093,238 | 1,115,680 | +2.053% |
| Pilot output tokens | 13,460 | 12,655 | -5.981% |
| Full deterministic passes | 35 / 35 | 34 / 35 | -1 pass |
| Full duration | 1,242,651 ms | 1,408,266 ms | +13.328% |
| Full input tokens | 3,366,733 | 3,472,288 | +3.135% |
| Full output tokens | 33,961 | 35,079 | +3.292% |
| Full model invocations | 36 | 36 | 0 |
| Full safety failures | 0 | 0 | 0 |

Each full arm used one retry beyond its 35 primary runs. The canonical full
aggregate remains 69/70 and must not be rewritten. Its one baseline-only pass
came from the candidate read-only-exploration run: targeted review found the
diagnosis, safety behavior, and artifact handling substantively correct, while
the deterministic oracle required an unnecessarily adjacent traversal phrase.
That is a recorded grader false negative, so substantive correctness is a tie,
not evidence that the candidate is worse. It is equally not evidence that the
candidate is better.

All 13 deterministically flagged pairs were substantively acceptable in the
targeted batch review. Twelve already passed both deterministic graders; their
flags reflected accepted file variation or message-level review. There was no
safety regression in either arm.

## Why rejection is warranted

Candidate A's failure-capsule guidance produced no observed substantive
correctness gain, did not reduce retries, and increased full-stage wall time,
input tokens, and output tokens. The paired 95% descriptive interval is broad
(`-0.258132` to `0.200990` in pass-rate difference), so the study cannot
establish small effects or generalize beyond the frozen corpus. With no positive
signal and measurable cost, adoption has no evidence-based benefit.

The targeted review also was not fully blind: absolute synthetic workspace
links in some messages exposed `baseline` or `candidate` path segments even
though the private mapping was not opened. Objective files, safety checks, and
deterministic graders remain valid, but subjective pair comparison must be
treated as unblinded.

## Conditions for any future experiment

Do not rerun candidate A unchanged. A future study requires all of:

1. A materially different mechanism with a pre-registered causal hypothesis
   and a minimum worthwhile improvement/cost threshold.
2. Arm-neutral synthetic paths and redaction of arm-bearing workspace links
   before the reviewer sees messages.
3. The read-only semantic oracle corrected and frozen before new runs, while
   preserving the old 69/70 report unchanged.
4. Matched model, CLI, reasoning, speed, corpus, retry, sandbox, and review
   budgets, with paired analysis and safety gates frozen in advance.
5. A small pilot stop/go gate before another 70-run full stage.

Until such a proposal exists, there is no follow-up model spend and the current
global guidance remains canonical.
