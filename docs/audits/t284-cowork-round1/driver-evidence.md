# Driver evidence

## Sandbox and baseline

Independent sandbox `/tmp/harness-t284-r1-codex`, made by a no-local,
no-hardlink clone and detached at
`f7d5bf0d403bdc07079bb4c5e420a2aa9fbb4a02`. `git status --short --branch`
reported only `## HEAD (no branch)` before experiments. Target files and the
Claude sandbox were not written. Scratch session/stage files remain inside the
driver sandbox; timing logs and hashes are under the driver-only
`/tmp/harness-t284-r1-driver` directory.

## Commands and results

Observed baseline target timings: `/usr/bin/time
tests/test-codex-claude-cowork-skill.sh` passed in 10.12 seconds; clean
`HARNESS_TEST_JOBS=4 tests/test-phase1.sh` passed in 88.18 seconds. In the
matched driver sandbox, `HARNESS_TEST_JOBS=8 tests/test-phase1.sh` passed in
76.39 seconds with 493,620 KiB maximum RSS, 11.79 seconds (13.4%) faster than
the four-worker observation. Its 57 parallel suites accumulated 135.462
seconds; the slowest were config-sync 19.745s, SSH-sync 12.735s, cowork 12.067s,
Restic scheduling 10.406s, and macOS update 10.070s. This is one local sample,
not yet a portable default.

Static trace with `rg` confirmed CI invokes Restic scheduling, mirrored-node
onboarding, evaluation, public audit, and guarded-delete before the umbrella
gate; the first four also occur in `tests/focused-suites.tsv`, and
guarded-delete runs again later in `tests/test-phase1.sh`. Affinity is not
duplicated by the umbrella gate. Therefore five named CI steps are exact test
reruns, while the affinity step is independent coverage.

I initialized `scratch-session`, advanced it to discussion, then ran
`cowork-session stage ... scratch-stage --mode independent --seal
/tmp/harness-t284-r1-driver/scratch-seal.json`. I recorded SHA-256 for
`stage.json` and the external seal, created and materially changed
`scratch-stage/artifacts/copilot-prompt.md`, and re-hashed both protected files.
`diff` produced no output: neither digest changed. The prompt's own hash was
`083ad993...b5be`, and the session still validated. Observation: a prompt added
after staging is not committed by the current stage manifest or external seal.

Source tracing confirmed `load_stage` deliberately validates the stage's
closed top-level layout but only verifies that `artifacts/` is a real directory;
it does not enumerate or hash prompt content. The current helper has no status
subcommand. A driver can call `check`, hash files, inspect candidate size, and
probe a background PID separately, but must mentally combine those outputs.

The first native Claude call used default model/effort and the reviewed
`Bash,Read,Glob,Grep,Write,Edit` tool set. It remained reachable for 10 minutes
8 seconds but wrote no output or sandbox file, so the driver interrupted it at
the historical wall. Redirection then contained only `Execution error` (15
bytes). Target Git, sandbox Git, protected digests, `stage.json`, and the
external seal were unchanged; no receipt exists and import would reject the
candidate headings. This is a retry-safe client failure. The retry narrows work
to source inspection, the focused suite, at most one timing, and five minutes,
and selects Claude Sonnet at medium effort explicitly.

Read-only GitHub run evidence for PR #161 showed `portable-phase1` took 138
seconds. ShellCheck took 22s; the five duplicated named test steps took 15s;
affinity took 9s; and the umbrella gate took 86s. Thus removing only work
repeated inside the umbrella gate has a measured upper-bound saving of about
37s on that run while retaining the 9s independent affinity test.

## Critique

The plan's concurrency hypothesis is supported only by one 4-versus-8
comparison taken in different clean checkouts; load variation may explain some
of the 11.79-second delta. Repeat matched samples before changing the default.
Removing duplicate CI steps retains their assertions through the umbrella gate,
but loses named-step failure locality; the focused runner's per-suite PASS/FAIL
lines and retained failure logs appear to preserve attribution, which must be
tested in CI-compatible output.

The unsealed prompt is an information-integrity gap and a manual-step source,
not evidence that an actual co-pilot was misdirected. A `stage --prompt FILE`
input should copy a strict regular bounded UTF-8 file to a fixed artifact path,
bind its hash in `stage.json`, and revalidate it at import. It must not disclose
the live session path. Prompt-copy failure should occur before stage creation or
leave an import-refused partial stage.

A `status` command can accurately report session phase, receipt set, sealed
stage/input consistency, candidate byte count, and whether the candidate is
template/invalid/heading-complete. It cannot know cognitive progress,
authorship, or whether a PID has been reused. If it accepts a PID, label process
reachability advisory and keep status read-only. Do not add a mutable heartbeat
file unless experiments prove its extra writes and prompt burden improve
latency.

The proposed reciprocal-addendum design may save model output, but it changes
receipt semantics and recovery. A complete replacement is simpler and bounded
at 64 KiB. Require Claude to test whether the latency benefit justifies a new
submission/final hash distinction before accepting it.

## Proposed plan changes

1. Prioritize `stage --prompt FILE` plus a concise read-only `status` surface;
   make prompt bytes part of the sealed manifest and receipt's transitive
   commitment.
2. Keep process liveness and candidate completeness explicitly advisory; prefer
   one JSON snapshot usable by a human loop over an embedded long-blocking
   monitor.
3. Defer reciprocal addenda unless the co-pilot demonstrates a small,
   backward-readable receipt design with a meaningful output/latency reduction.
4. Repeat four/eight-worker measurements in Claude's matched sandbox. If eight
   remains faster with all checks passing, change the local default from four
   to eight while retaining an override and maximum of 16.
5. Remove only the five CI reruns proven to execute inside `test-phase1.sh`;
   retain ShellCheck, runner-capability output, affinity, and the complete
   umbrella gate. Confirm per-suite failure attribution remains visible.
