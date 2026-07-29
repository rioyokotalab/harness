# Driver evidence

## Sandbox and baseline

Codex used detached clean clone `/tmp/t343-codex-box/repo` at exact baseline
`333d67b2179906dbaea5c7ea7e763613851e52b8`. The target worktree and Claude
sandbox were not modified by the independent pass. Native clients are Codex
CLI 0.146.0 and Claude Code 2.1.220. `claude --help` directly confirms
Fable, high effort, plan/dontAsk modes, explicit `--tools ""`,
project-setting source selection, JSON output, and nonpersistent print mode.

## Commands and results

- `tests/test-codex-claude-cowork-skill.sh`: pass.
- `tests/test-claude-takeover.sh`: pass.
- `tests/test-agent-config.sh`: pass.
- `tests/test-client-comparison.sh`: pass.
- `tests/test-development-evaluation.sh`: pass.
- `git status --short --branch`: detached clean baseline.
- Both tracked Claude setting mirrors have SHA-256
  `5adf2a8b2b0bccb75614d7d8168bc284e1bf08387b74e4e01c111b41e50e97c6`.
- Accepted T-336 `-r7` pilot and confirmation SHA-256 values are respectively
  `2694b7485f75efbb4b3280ac1e79b2e1b4d5c490c9b787e15a65b7bca6f54e8d`
  and
  `483e1f773e7989966ecef669d43b1bb8c12bf2018b5c49cc8c2dda404c6c06dc`.
- Native `harness agent-config --doctor` reports schema 2 ready, 17 skills,
  and zero failures.
- Live ruleset 19127355 readback is active with owner/admin bypass, strict
  `portable-phase1`, and zero required approvals.
- Canonical fleet health passes every declared route except both ABQ routes.
  The official page independently reports System H `サービス停止中`, updated
  2026-07-28, with the scheduled 2026-07-29 17:00 end still marked planned.

## Critique

1. The current takeover test proves static instruction/config discovery and
   installer behavior, but never starts a fresh Claude process and therefore
   cannot prove cold durable task recovery, exact next-action selection, or
   absence of auto-memory dependence.
2. The tracked Claude profile intentionally gives ordinary interactive
   sessions `bypassPermissions` and suppresses its dangerous-mode prompt.
   T-342's Cowork invocation used narrower task-local permissions and an
   environment sandbox, but there is no reusable handoff command that binds
   those safer options to a task identity. Documentation calling the general
   file “reviewed permissions” is accurate provenance but not least-authority
   evidence.
3. The schema-3 Cowork helper strongly binds staged discussion evidence, but
   its protocol stops at driver-only execution. A later fresh Claude takeover
   has no machine-readable handoff packet binding task ID, repository root,
   baseline, phase, intended authority, checks, and expiry.
4. Existing T-336 evaluation can retest the four frozen failure capsules, but
   those capability cases do not test takeover/session/authority mechanics.
   They must remain one benchmark case, not substitute for the other seven.
5. ABQ's registry end has passed while the official status still says stopped.
   This is external maintenance drift, not a Claude-handoff target. Excluding
   ABQ avoids converting a known external stop into unrelated run work.

## Proposed plan changes

1. Add a focused `t343` handoff fixture and machine-readable packet/validator
   only if matched evidence confirms the gap. Bind task ID, repository root,
   baseline, phase, model/effort intent, authority class, allowed working
   paths, checks, and expiry; reject stale/cross-task/root/baseline drift.
2. Prefer an explicit task-scoped native Claude launch mapping using
   nonpersistent Fable/high plus plan or dontAsk and an exact reviewed tool
   set. Do not globally narrow or broaden the interactive project profile
   until an empirical compatibility test demonstrates that a global change is
   both necessary and safe.
3. Add a true fresh-process cold-takeover test, interruption/partial-output
   fixtures, and protected-digest assertions around the target and unrelated
   paths.
4. Keep the four T-336 capsules unchanged and execute their Fable/high retest
   under a separate versioned result identity after the handoff mechanics are
   fixed.
5. Preserve the frozen cutoff, protected publication path, zero-review policy,
   ABQ exclusion, and 16-slice summary contract without expansion.
