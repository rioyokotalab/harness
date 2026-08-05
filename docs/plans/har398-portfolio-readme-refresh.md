# Har-398 portfolio README refresh

| Repository | Protected base | Task | Scope |
| --- | --- | --- | --- |
| Harness | `a395d794` | Har-398 | direct Har/Nit model and portfolio status |
| Personal | `4f014aac` | Per-039 | metadata-safe bounded automation and active consumer model |
| Students | `4a0c7310` | Stu-079 | Sensei-gent runtime, mentoring coverage, and idle selector |
| Swallow | `5d13c172` | Swa-050 | validated site matrix, idle selector, and HPC boundaries |
| Website | `b0b863ed` | Web-223 | static-site workflow, gated maintenance, and current clients |

All changes are README and ledger documentation only. Each repository keeps an
independent branch, validator, protected pull request, readback, and cleanup.
Personal's pre-existing dirty consumer files are unrelated and must remain
untouched.

## Result

| Repository | Pull request | Protected result | Validation |
| --- | ---: | --- | --- |
| Students | 619 | `f63dfa0a` | complete gate: 1,182 tests and 81 subtests |
| Swallow | 169 | `f93cdda6` | complete render-only static gate |
| Website | 61 | `8c768737` | local complete security gate and hosted browser rerun |
| Personal | 153 | `b89fa15f` | 130-test complete validator body in isolated checkout |

Every protected sibling tree matched its reviewed candidate. Personal's
canonical checkout was fast-forwarded after merge with the consumer's unrelated
Per-017 and Per-018 changes still present and unmodified.
