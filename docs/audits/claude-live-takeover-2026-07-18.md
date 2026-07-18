# Claude live takeover evaluation — 2026-07-18

## Scope

Claude Code 2.1.207 was launched from a clean synchronized harness checkout in
three independent non-persistent sessions. Each session used the observed
`claude-sonnet-5` model at high effort with an explicit dollar ceiling, bounded
tools, no credential access, and no SSH, scheduler, or publication authority.
The primary agent retained ledger integration, Git publication, and independent
review.

## Results

| Task | Authority | Result | Observed telemetry |
|---|---|---|---|
| Cold ledger reconstruction | Repository reads only | Pass. Claude found T-191 and T-196, preserved the Sunday eligibility gate, named all seven captured job IDs, and correctly concluded that no scheduler action was authorized yet. | 44.589 s, 7 turns, $0.5604447 |
| T-266 MPI implementation audit | Repository reads plus three exact local commands | Pass. Both focused tests passed; Claude returned GO with no blocking findings and correctly distinguished interactive toolchain preservation from deterministic batch selection. One extra read-only `git log` attempt was denied by the exact tool boundary. | 124.878 s, 31 turns, $1.1430567 |
| Cross-host isolation implementation | Edit only `tests/test-local-mpi-profile.sh`; two exact tests permitted | Implementation pass, self-validation blocked. Claude added the intended `ab` isolation regression without touching another file. It invoked `./tests/...` instead of the authorized `tests/...`, so both Bash attempts were denied. Its handoff reported the block accurately and did not claim unrun tests. Primary review found a clean focused diff; the focused test and complete portable phase-1 suite then passed. | 66.960 s, 10 turns, $0.7317489 |

Total observed Claude-reported cost was $2.4352503. Cost, turn, and duration
figures are CLI telemetry for these exact sessions, not generalized performance
claims.

## Primary review

Claude demonstrated successful cold reconstruction, respected the ledger's
time gate, made a correct single-file change, and produced a retry-safe handoff
when validation was denied. The exact permission boundary worked: neither the
unapproved history command nor the spelling-variant test commands executed.

The main weaknesses were efficiency and command precision. The MPI audit took
31 turns and substantial cache reads for a narrow review, and the implementation
session failed to match the authorized command spelling. These are usability
costs, not correctness or safety failures. The retained regression proves that
an interactive `ab` profile neither invokes the local MPI module hook nor makes
the fake local `mpicc` available.

## Validation retained

```text
tests/test-local-mpi-profile.sh
  local MPI profile tests: PASS

HARNESS_PORTABLE_CI=1 PYTHONDONTWRITEBYTECODE=1 tests/test-phase1.sh
  phase-1 harness tests passed
```

No SSH connection, scheduler query or mutation, job submission, credential
inspection, external publication, or recursive deletion occurred during the
Claude sessions.
