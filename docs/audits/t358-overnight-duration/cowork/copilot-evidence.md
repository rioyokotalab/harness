# Co-pilot evidence

## Sandbox and baseline

This reciprocal pass remained read-only inside `/home/rioyokota/harness/.t358-copilot-sandbox`. The repository root resolved to the admitted `/home/rioyokota/harness`.

No tmux server, network, external path, credential, target worktree, or Git mutation was accessed. I re-read `AGENTS.md`, `charter.md`, `plan.md`, `benchmark.md`, and the copied duration, managed-Codex, and repository-Git policies completely.

Current amended-file SHA-256 values:

- `charter.md`: `10a9106c6106551a5bfbecc98f9c84f4cfdbd0d244e263ca8920563eb68ca77a`
- `plan.md`: `dacb21c74e40ec6f60ac6e830403c66a603f7f30e7bf0166681e164453e4fd0b`
- `benchmark.md`: `694fdc3ea8aac880c6f5d6cae66a4e0c124a9af8d4cfb4823dd8cd21d17a09ea`

## Commands and results

- `date '+%H:%M:%S'` supplied fresh progress timestamps.
- `pwd` and `git rev-parse --show-toplevel` confirmed the sandbox and admitted repository root.
- `rg --files` found the seven expected sandbox inputs.
- `wc -l -c` measured 447 lines and 26,119 bytes across those inputs.
- `sed -n` read every selected file completely.
- `sha256sum` recorded the amended document identities above.
- Targeted `rg -n` confirmed immutable pane-ID targeting, `/proc` launch-argument verification, the quiet barrier, C3’s one-shot/no-ambiguous-retry rule, conditional coherent-PR economy, configured—not proven—fallback semantics, and exactly seven C7 intervals.

## Critique

The two evidence sets now substantially agree. The driver’s experiment provides useful direct evidence that:

- The tested 152×40 scratch window divides into three equal 50-column panes.
- The exact Claude CLI flags are accepted by version 2.1.220 and reach an interactive prompt.
- `/model fable` works at a known idle prompt and persists the new default.

The independent pass remains necessary because those results do not prove unattended safety at an unknown later TUI state, weekly-limit fallback semantics, or application consumption from a successful `tmux send-keys`. The amended charter, plan, and benchmark now correctly preserve these distinctions.

The strongest remaining conflict is P1. An unconditional second fire at 04:40 contradicts C3’s “never retried on ambiguity” rule. Idempotence of `/model fable` after confirmed application consumption does not make terminal-input injection idempotent when the pane may contain a draft, modal, or buffered input. A second send is acceptable only for a pane that was conclusively skipped before any keys were delivered at 04:25, followed by a fresh readiness and identity preflight. It must not repeat an attempted or ambiguously delivered command.

The cheapest matched test, if unconditional P1 is still proposed, is an exact-version disposable Claude pane with an inert unsent draft present: deliver `/model fable` and Enter twice at shortened equivalent intervals and inspect only that scratch experiment. Any concatenated or unintended submission rejects P1. The driver’s existing idle-prompt test does not cover this state. Even a successful idle repetition would not justify an unattended production retry without proving equivalent readiness.

P2 is useful but insufficient when implemented solely as `pane_current_command=claude|node`. A generic `node` classification is not Claude identity. The guard should remain conjunctive: original immutable pane ID, expected path, live pane, recorded process birth identity, and `/proc` command line consistent with the launch-time Claude process. A generic shell or unrelated Node process must fail closed.

P3 is acceptable only as a compatibility rule for the advisory `pane_current_command` field. C1 must continue to require exact launch arguments from `/proc/PID/cmdline`; merely observing `claude` or `node` is not acceptance evidence.

## Proposed plan changes

1. Reject unconditional P1. Keep one attempted delivery per pane at 04:25. At 04:40, observe and report only, except that a pane conclusively skipped before sending may receive its first attempt after fresh identity and readiness checks.
2. Accept P2 as one guard layer, strengthened with fixed pane ID, expected path, process birth identity, and `/proc` argv verification. Do not accept `node` alone.
3. Accept P3 only for `pane_current_command`; retain C1’s exact `/proc` argument requirement.
4. Add the pre-fire readiness result to C3. If a known empty prompt cannot be established without prohibited content inspection, skip delivery and report the model as unknown.
5. With those clarifications, I explicitly accept the benchmark as amended.

benchmark-verdict: accepted
agreement: role=copilot client=codex benchmark-accepted