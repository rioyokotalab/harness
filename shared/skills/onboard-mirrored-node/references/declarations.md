# Tracked declaration contract

Read this contract before staging a new logical host. Replace `HOST` with the
validated SSH alias. A host is managed only after all declarations below are
coherent and the repository validation suite passes.

## Required declarations

- `profiles/hosts/HOST.conf`: a regular file containing each key exactly once:
  `schema=1`, `os_id`, `arch`, `scheduler`, `command_paths`,
  `scheduler_commands`, `module_commands`, `environment_commands`,
  `container_commands`, `debugger_commands`, `profiler_commands`,
  `persistent_root`, and `cache_root`. Use `none` for an empty command set.
  Roots and command paths must be confirmed absolute paths. Never guess them.
- `shell/environments/HOST.sh`: export the same confirmed
  `HARNESS_PERSISTENT_ROOT` and `HARNESS_CACHE_ROOT` values.
- `shell/bashrc.HOST.block` and `shell/bash_profile.HOST.block`: use the
  existing managed-block format, set and export `HARNESS_LOGICAL_HOST=HOST`,
  and source `$HOME/harness/shell/profile.sh` only when readable.
- `tests/fixtures/HOST.facts`: retain only the validated, value-free inventory
  facts. It must not contain paths, usernames, environment values, addresses,
  hostnames beyond the logical ID, or credential material.
- Append exactly one unique row to `profiles/home-layout.tsv` using the approved
  storage and hidden-state decisions.
- Append exactly one unique row to `profiles/restic-repositories.tsv`. Declare
  the password path literally as `~/.config/restic/home-control.password`.
  Remote nodes normally use transport `local` and an independent-replica root
  on current-node safe storage unless the owner selects another supported
  route.
- Update `docs/environment-portability.md` and other fleet documentation only
  with confirmed, non-secret facts.

Do not add a `profiles/restic-schedules.tsv` row during onboarding. Scheduling
is a separate owner-authorized workflow after manual backup and restore tests.

## Prohibited tracked content

Never commit SSH configuration, keys, tokens, password contents, credential
copies, private application state, a generated Restic password, or command
output that can expose those values. Never inspect a password file; validate
only its path, ownership, regular-file type, and mode when the owner reaches the
credential checkpoint.

## Consistency rules

Derive managed fleet membership from strict regular files under
`profiles/hosts/`. Every managed profile must have exactly one home-layout row,
one repository row, one environment declaration, both shell blocks, and one
value-free test fixture. Reject collisions rather than overwriting them. A
profile does not itself authorize package installation, scheduler submission,
deletion, credential handling, or publication.
