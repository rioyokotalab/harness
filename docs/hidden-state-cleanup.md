# Recreated hidden-state classification and cleanup

## Metadata-only classification

No filename or file content was inspected. Each exact path was checked for
type, owner/group, mode, filesystem device, apparent size under a 15-second
bound, and the three relevant managed redirect variables.

| Host/path | Mode | Apparent size | Existing redirect | Decision/result |
|---|---:|---:|---|---|
| local `.cache` | 0700 | 9,079 KiB | `XDG_CACHE_HOME` on fast storage | guarded-delete verified |
| local `.nv` | 0700 | 73,697 KiB | `CUDA_CACHE_PATH` on fast storage | guarded-delete verified |
| AB `.cache` | 0700 | 21,366,239 KiB | `XDG_CACHE_HOME` on project cache | guarded-delete verified |
| AB `.mozilla` | 0700 | 12 KiB | no general Firefox profile redirect | retained; cross-filesystem/credential boundary |
| AB2 `.cache` | 0700 | 4 KiB | `XDG_CACHE_HOME` on project cache | guarded-delete verified |
| RI `.cache` | 0700 | 1,065 KiB initially | `XDG_CACHE_HOME` on data cache | guarded-delete verified twice; see recurrence |
| RI `.apptainer` | 0700 | 0 KiB | `APPTAINER_CACHEDIR` on data cache | guarded-delete verified |
| AL `.mozilla` | 0700 | 4 KiB | no general Firefox profile redirect | guarded-delete verified per approved delete policy |
| T4 `.cache` | 0755 | 3,209,403 KiB | `XDG_CACHE_HOME` on fast storage | guarded-delete verified |

All paths were owned by the account running the transaction and initially on
the same filesystem as that account's home, enabling reversible atomic staging
before deletion. The configured redirect roots were already outside the
quota-limited home paths. The AB and T4 legacy cache trees were the material
quota risks; together they accounted for roughly 23.4 GiB apparent size.

## Guarded execution

For each node, the exact top-level targets were renamed into a new mode-0700
same-home staging boundary. `harness guarded-delete plan` then produced a
mode-0600 manifest under the retained home boundary. Automation checked the
canonical `PLAN`, every exact `TARGET`, `MANIFEST`, and single `NEXT` line,
then ran that exact emitted apply command. Every apply reported
`VERIFIED protected_anchors=unchanged targets=absent`. Each manifest/plan was
exact-unlinked and each empty staging boundary removed. Independent postflight
confirmed target and temporary absence on every node.

RI printed a Bash internal context error only after its cleanup success record,
so its result was treated as unknown until a separate connection independently
proved both targets and all temporary paths absent. No raw recursive deletion,
wildcard cleanup, scheduler write, or Restic command was used.

`docs/audits/fleet-readiness-post-cleanup-t199.json` subsequently confirmed all
captured production jobs still present and every checkout/doctor clean. It also
caught RI `.cache` recreated as a zero-apparent-size directory during that fresh
login audit. A second guarded cleanup followed by bounded command isolation
showed that nested login, inventory, doctor, scheduler status, Codex, Claude,
and Restic do not recreate it after the managed profile is active. The likely
boundary is earlier fresh-login startup before the appended harness block sets
`XDG_CACHE_HOME`; no file names were inspected. The directory is absent again,
but another fresh RI login may recreate an empty shell.

## Deferred AB Mozilla relocation

AB's 12 KiB `.mozilla` directory and its intended fast-storage parent are on
different filesystem devices, so an atomic rename is impossible. Firefox was
not running, and the destination was absent. A Mozilla profile can contain
authentication state; the global agent policy therefore forbids silently
copying it across filesystems or inspecting it to select files. It remains in
place, small and protected by the existing encrypted home backup.

The safe follow-up is application-native creation of a new profile on the fast
filesystem, selective owner-controlled migration of non-secret state, and
reauthentication into the new profile. Only after launch/rollback tests pass
should `.mozilla` become a symlink. That is T-202 and requires an owner choice;
it is not a quota emergency.

## Policy implication

The existing cache variables redirect compliant applications, but variables
set in a late managed profile block cannot protect against programs invoked by
earlier startup lines. T-201 will design an early, silent, non-interactive-safe
cache bootstrap without changing the T-191 backup source semantics. Until that
is validated, do not declare absence of every default `.cache` path a stable
invariant; monitor size and redirect correctness instead.
