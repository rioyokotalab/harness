---
name: reboot-recovery
description: Restore and validate managed tunnels, remote control, and standard Codex tmux state after an aist, home, office, or riken reboot, power loss, or loss of its normal Codex session.
---

# Recover a managed Mac after reboot

Recover one named Mac from Git, the active board, selected record, and closest
instructions. Never infer readiness from phone or chat.

## Mandatory boundaries

- Set `HOST` only to `aist`, `home`, `office`, or `riken`; unknown or ambiguous
  hosts stop.
- Never inspect, expose, copy, hash, generate, or modify credentials or SSH key
  material. The sole portfolio producer may inspect task-relevant owner tmux
  panes under managed policy.
  Other agents: Never read or capture tmux pane or transcript contents.
- Routine recovery must not change SSH configuration, tunnel authorization,
  launchd definitions, pairing, or repository files. Do not clean the
  repository or remove, ignore, or specially classify `.DS_Store`.
- Dirty, divergent, or non-current Git state; an unavailable route pair;
  missing managed services; unexpected remote-control topology; or unknown
  ownership stops recovery as a separate task. Conflicting tmux state stops
  recovery. Never hide a blocker, guess ownership, or manufacture a
  replacement service.
- A failed query is unknown state, not evidence of absence or readiness.

## Route only the current phase

Classify from durable, value-free state, then read one matching reference:

| Current phase | Read completely |
| --- | --- |
| status, discovery, or owner checkpoint | [status-discovery.md](references/status-discovery.md) |
| recovery or tmux start | [recovery-start.md](references/recovery-start.md) |
| validation, handoff, or closeout | [validation-closeout.md](references/validation-closeout.md) |

References never select one another. On phase change, return and load only the
new reference.
