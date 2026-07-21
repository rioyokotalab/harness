# 2026-07-15 `rm -rf` incident evidence brief

## Resolved claim

At approximately 01:41 JST on 2026-07-15, an agent used a temporary-`HOME`
plan command whose command-scoped assignment expired before cleanup. Cleanup
therefore resolved to the real account home and launched
`rm -rf /home/rioyokota`. The incident record explicitly classifies this as an
agent error rather than a harness transaction.

Primary evidence: commit
`e5200fd3ae3aa5b6b326205b6475af2047d21929`, historical `TODO.md`, T-171.

## Containment and impact

- The first tool cancellation did not terminate the child deletion process. A
  later process audit found the child still running; the child and launching
  shell were explicitly terminated, and a fresh audit confirmed that no
  matching deletion process remained.
- `~/harness` was restored from a previously verified complete Git bundle at
  commit `5f6382b9fe641a969235bf0fc0f46dbc2ef8cfea`.
- Eight tracked paths in the surviving website checkout were restored exactly
  from its clean HEAD. The incident record does not claim that every deleted
  untracked path was recoverable.
- The first audit found shell profiles, SSH configuration, user-local tool and
  harness state, discovery links, and additional top-level paths missing. The
  list was explicitly non-exhaustive. Credential contents were not inspected
  and credential recovery was not attempted.
- Uncommitted ShellCheck transaction work after the restored harness revision
  was lost. The retired `si` configuration and `sshservice-cli` were later
  recorded as non-reconstructable and were not guessed back into existence.

Primary evidence: `e5200fd` and the consolidated historical recovery record at
`d726f0deb222416457659c01c5511ba970c590d6`.

## Architectural response

Commit `238f0224e6f5ac51ffcb1b47ba5308c97377df3e` added a reusable autonomous
bulk-deletion control instead of relying on an approval prompt:

1. raw recursive `rm` forms became forbidden by client policy;
2. deletion requires a retained canonical boundary and explicit absolute
   targets;
3. a mode-0600 manifest binds identities, entry/byte counts, ownership, a
   token, and a 15-minute freshness window;
4. apply revalidates the home, working directory, repository, boundary,
   parents, and targets before deletion;
5. deletion stays on each target filesystem and verifies target absence plus
   protected-anchor survival afterward;
6. adversarial tests cover protected roots, unreadable trees, overlapping
   targets, token mismatch, and target drift.

Primary evidence: the guarded-delete skill, script, client rules, and
`tests/test-guarded-delete.sh` at `238f022`.

## Interpretation used in the Japanese deck

The incident did not merely add another safety rule. It changed the harness's
definition of autonomous action: authority became a short-lived, reviewable,
revalidated capability bound to exact objects. This is an interpretation of
the incident and the resulting implementation, not an attributed statement of
developer motivation.

## Limitations

- The repository records the observed impact, not a forensic proof of every
  path affected before termination.
- Restored or reconstructed state is not equivalent to proof that every prior
  byte was recovered.
- The guard is a bounded deletion control, not a universal security boundary.
