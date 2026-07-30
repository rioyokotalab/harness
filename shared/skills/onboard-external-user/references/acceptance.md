# Acceptance, rollback, and handoff

Run preflight again and require `status=ready`, `collisions=0`, and
`links_absent=0`. Then verify:

- `harness help` and `harness version` succeed;
- every installed sentinel/command link still points to the selected checkout;
- both project settings retain the reviewed non-interactive permissions;
- `.agents/skills/` and `.claude/skills/` expose every canonical skill through
  exact repository-relative symlinks;
- a newly started installed client can discover `onboard-external-user`;
- no remote host, storage root, backup repository, scheduler, plugin,
  authentication, or external-service state was created; and
- rerunning `./install.sh` changes nothing.

Do not claim owner-specific fleet profiles are usable on this machine. If the
user later supplies one explicit SSH alias and asks to manage it, hand that
separate task to `onboard-mirrored-node`.

There is no broad uninstall. For rollback, inventory the exact links created
by the selected checkout and exact-unlink only links that still point there.
Preserve changed or colliding paths and never recursively remove client
directories. Delete a clone only through a separately reviewed
`guarded-bulk-delete` workflow.

Report the commit, OS/architecture, prerequisite state, link totals, installed
client presence, validation, retained collisions or owner actions, and exact
next step. Never record usernames, home paths, credentials, or machine
identifiers in a shared artifact.
