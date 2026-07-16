# T-181 full-stage targeted review

This is the bounded adjudication record for the 13 pairs selected by the
pre-registered deterministic review triggers. It does not contain the private
arm-label mapping or raw event logs.

## Outcome

- All 13 flagged pairs were substantively acceptable under the frozen task
  prompts and owner-style rubric.
- Twelve pairs already passed both deterministic graders; their flags came
  from materially different accepted files or message-level rubric review.
- The remaining read-only-exploration pair preserved the worktree, passed all
  safety checks, named `artifact_path`, and correctly explained that untrusted
  relative and absolute input can escape `root`. Its deterministic failure was
  a false negative caused by requiring an adjacent traversal phrase.
- The canonical deterministic aggregate remains unchanged at 69/70 passes and
  records that failure. Review does not rewrite experimental results.

## Blinding limitation

The batch writer assigned opaque labels and its private mapping was not opened.
However, several final messages contained absolute synthetic workspace links
whose path segments exposed `baseline` or `candidate`. The review therefore
was not fully blind. This limitation does not change the objective file,
safety, or grader evidence, but conclusions that depend on subjective blind
comparison should be treated as unblinded. The writer must redact arm-bearing
workspace paths before any future experiment.

## Interpretation

The candidate showed no correctness improvement on this frozen corpus. Both
arms required one retry and passed every substantive blinded-review task. The
deterministic report's one baseline-only pass is attributable to the recorded
semantic-oracle false negative, not a safety regression or wrong diagnosis.
Candidate adoption remains a separate owner decision and is not performed by
this evaluation.
