---
name: reboot-recovery
description: Restore and validate managed tunnels, remote control, and standard Codex tmux state after an aist, home, office, or riken reboot or power loss.
---

# Recover a managed Mac after reboot

Recover exactly one owner-named Mac from Git, `TODO.md`, and the closest
instructions. Never infer readiness from a phone connection or prior chat.

## Mandatory boundaries

- Set `HOST` only to `aist`, `home`, `office`, or `riken`; unknown or ambiguous
  hosts stop.
- Never inspect, expose, copy, hash, generate, or modify credentials or SSH key
  material. Never read or capture tmux pane or transcript contents.
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

Classify the next action from durable, value-free state, then read exactly one
matching reference completely before acting:

| Current phase | Read completely |
| --- | --- |
| status, discovery, or owner checkpoint | [status-discovery.md](references/status-discovery.md) |
| recovery or tmux start | [recovery-start.md](references/recovery-start.md) |
| validation, handoff, or closeout | [validation-closeout.md](references/validation-closeout.md) |

References never select one another. On a phase change, return here and load
only the newly selected reference.
