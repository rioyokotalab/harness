# T-334 remote Linux maintenance sources

## Outcome and scope

Extend T-333's maintenance-aware fleet-health contract from ABQ to the six
other managed remote Linux logical nodes: `ab`, `ab2`, `ri`, `al`, `rc`, and
`t4`. Keep `local`, the managed Macs, transport-only aliases, scheduler state,
credentials, authenticated portal contents, and partial service degradation
outside the automatic skip decision.

The runtime remains credential-free and does not scrape mutable websites.
Agents consult the reviewed official source when a route unexpectedly fails.
Protected repository changes freeze only exact, independently reviewed
full-route service-stop windows. Partial maintenance remains visible through
the source but does not suppress a logical-node probe.

## Evidence frozen on 2026-07-28

| Nodes | Official source | Readback | Decision |
| --- | --- | --- | --- |
| `ab`, `ab2` | <https://abci.ai/en/about_abci/info.html> | ABCI 3.0 is available. The future suspension schedule says all services will be unavailable from 2026-08-21 10:00 through 2026-08-28 13:00 JST for power, cooling, and system maintenance. | Register the exact half-open full-service window for both logical nodes. |
| `ri` | <https://docs.r-ccs.riken.jp/rikyu/en/contact/> | The official RIKYU guide directs users to R-CCS ticket support. No public status or maintenance feed was found. | Record the official support page for failure reconciliation; freeze no maintenance window. A failed or inaccessible lookup is unknown. |
| `al` | <https://status.cscs.ch/> | Official CSCS documentation directs users to this status page. Its RSS feed reports no active or upcoming Daint maintenance; the latest Daint monthly maintenance ended 2026-07-15 12:00 CEST. | Record the public status page; freeze no current window. |
| `rc` | <https://portal.cloud.r-ccs.riken.jp/> | The official R-CCS Cloud service portal links its authenticated support manual. No public status or maintenance feed was found. | Record the official service portal for failure reconciliation; freeze no maintenance window. An unavailable portal is unknown. |
| `t4` | <https://www.t4.cii.isct.ac.jp/> | The official status page returned to normal operation at 2026-07-28 15:45 JST. Its announcement says the two login nodes were maintained separately and all work ended at 15:55. | Record the public status page; freeze no current window because the partial route work is complete and never stopped the whole logical service. |
| `abq` | <https://unit.aist.go.jp/g-quat/HowToUse/abci_q/#status> | T-333's exact service stop remains active through 2026-07-29 17:00 JST. | Preserve the existing two-route skip unchanged. |

Negative searches are not proof that a private or newly published notice does
not exist. Before incident classification, agents must re-read the recorded
official source and may add a new exact window only through reviewed protected
Git.

## Frozen implementation

1. Add a reviewed source registry containing exactly one official URL and
   source class for every remote Linux logical node.
2. Generalize the maintenance registry validator to allow multiple
   non-overlapping windows per node, reject malformed/duplicate/overlapping
   records, and select at most one active half-open window.
3. Before starting each remote Linux probe, resolve its active reviewed window.
   Skip only that logical node's declared route contract and emit
   `status=maintenance`, `routes=skipped/N`, exact end, and exact source.
4. On an ordinary remote Linux failure, emit the node's official source URL.
   Preserve raw SSH diagnostic suppression, AL's managed-session contract,
   ABQ's two-route requirement, result order, compact summary, and exit
   semantics.
5. Add failing-first deterministic coverage for simultaneous `ab`/`ab2`
   maintenance, preserved ABQ skipping, exclusive-end probing, per-node
   failure URLs, malformed source data, overlapping windows, and unrelated
   Mac behavior.
6. Run syntax, ShellCheck, diff hygiene, focused fleet-health, the complete
   clean phase-one suite, protected exact-head CI, guarded clean-checkout
   synchronization, required Mac context refreshes, and final canonical fleet
   health.

The owner's direct request to “do the same for the other remote Linux nodes”
is the execution authorization for this exact frozen scope. No unresolved
owner decision remains.

## Failure, rollback, and acceptance

Any unknown source, malformed registry, overlapping active window, missing
required row, or test-time override outside `HARNESS_TESTING=1` fails before
network probes. An official page that cannot be read is unknown, not
maintenance. A partial maintenance notice never suppresses the whole logical
node.

Rollback is a protected revert of the source registry, generalized
maintenance selector, ABCI 3.0 future rows, tests, documentation, and ledger.
Acceptance requires zero probe calls for every active reviewed node, ordinary
probing at each exclusive end, source-bearing failures for all seven remote
Linux logical nodes, unchanged target-specific route contracts, protected CI,
an idempotent fleet rollout, and fresh value-free health.
